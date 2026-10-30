import QtQuick
import qs.Common

// The row (horizontal bar) or column (vertical bar) of workspace thumbnails.
// Dock magnification never changes the layout: each thumbnail keeps its normal slot and is
// scaled and shifted with transforms. The pointer is read against that fixed layout, so
// magnifying can't move things under the pointer and feed back into itself.
Item {
    id: strip

    required property var widget
    required property var workspaceBackend
    required property var model
    property bool vertical: false
    // Bar edge the thumbnails are attached to. Magnified thumbnails grow away from it.
    property string anchorEdge: vertical ? "left" : "top"

    property real pointer: -1
    property real strength: 0

    Behavior on strength {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    function startOf(item) {
        return vertical ? item.y : item.x;
    }

    function lengthOf(item) {
        return vertical ? item.height : item.width;
    }

    function scaleFor(item) {
        if (strength <= 0 || pointer < 0)
            return 1;
        const length = lengthOf(item);
        const reach = length * 2.5;
        const distance = Math.abs(pointer - (startOf(item) + length / 2));
        if (distance >= reach)
            return 1;
        const peak = peakFor(item);
        return 1 + (peak - 1) * strength * (0.5 + 0.5 * Math.cos(Math.PI * distance / reach));
    }

    function peakFor(item) {
        return Math.max(1, widget.hoverSize / item.thumbH);
    }

    // How far a thumbnail is towards its peak magnification (0-1), used to lift its shadow.
    function liftFor(item, magnification) {
        const peak = peakFor(item);
        return peak > 1 ? (magnification - 1) / (peak - 1) : 0;
    }

    // Extra length added by magnification between the start of the strip and pos.
    function extraBefore(pos) {
        let extra = 0;
        for (let i = 0; i < layout.children.length; i++) {
            const child = layout.children[i];
            if (child.thumbH === undefined)
                continue;
            const start = startOf(child);
            if (pos <= start)
                continue;
            extra += (Math.min(pos, start + lengthOf(child)) - start) * (scaleFor(child) - 1);
        }
        return extra;
    }

    // The point under the pointer stays put; thumbnails either side are pushed away from it.
    readonly property real pointerExtra: strength > 0 ? extraBefore(pointer) : 0

    HoverHandler {
        enabled: strip.widget.hoverMode === "magnify"
        onPointChanged: {
            if (hovered)
                strip.pointer = strip.vertical ? point.position.y : point.position.x;
        }
        onHoveredChanged: {
            if (hovered)
                strip.pointer = strip.vertical ? point.position.y : point.position.x;
            strip.strength = hovered ? 1 : 0;
        }
    }

    Grid {
        id: layout
        rows: strip.vertical ? 0 : 1
        columns: strip.vertical ? 1 : 0
        spacing: strip.widget.shadowLevel > 0 ? Theme.spacingS : Theme.spacingXS

        Repeater {
            model: strip.model

            // Wraps either a workspace thumbnail or a group separator. Separators report no
            // thumbH, so magnification shifts them along with their neighbours but never scales them.
            delegate: Item {
                id: entry
                required property var modelData
                readonly property bool isSeparator: !!modelData.separator
                readonly property var thumbH: isSeparator ? undefined : loader.item?.thumbH

                readonly property real magnification: isSeparator ? 1 : strip.scaleFor(entry)
                readonly property real shift: strip.strength > 0
                    ? strip.extraBefore(strip.startOf(entry)) - strip.pointerExtra : 0

                implicitWidth: loader.implicitWidth
                implicitHeight: loader.implicitHeight
                width: implicitWidth
                height: implicitHeight
                z: magnification
                opacity: strip.widget.isDimmed(modelData) ? 0.45 : 1
                transform: [
                    Scale {
                        origin.x: strip.vertical && strip.anchorEdge === "right" ? entry.width : 0
                        origin.y: !strip.vertical && strip.anchorEdge === "bottom" ? entry.height : 0
                        xScale: entry.magnification
                        yScale: entry.magnification
                    },
                    Translate {
                        x: strip.vertical ? 0 : entry.shift
                        y: strip.vertical ? entry.shift : 0
                    }
                ]

                Loader {
                    id: loader
                    sourceComponent: entry.isSeparator ? separatorComponent : workspaceComponent
                }

                Component {
                    id: separatorComponent
                    WorkspaceSeparator {
                        vertical: strip.vertical
                        crossSize: strip.vertical ? layout.width : layout.height
                    }
                }

                Component {
                    id: workspaceComponent
                    WorkspaceItem {
                        ws: entry.modelData
                        vertical: strip.vertical
                        hoverEnabled: strip.widget.hoverMode === "popout"
                        capturesEnabled: strip.vertical === strip.widget.isVertical
                        thumbHeight: strip.widget.thumbnailHeight
                        fitContainer: strip.widget.fitContainer
                        containerSize: strip.widget.fitContainerSize
                        live: strip.widget.live
                        iconMode: strip.widget.iconMode
                        iconSize: strip.widget.iconSize
                        maxIcons: strip.widget.maxIcons
                        excludeReserved: strip.widget.excludeReservedZones
                        squareHighlight: strip.widget.squareHighlight
                        showWallpaper: strip.widget.showWallpaper
                        showDecorations: strip.widget.showDecorations
                        decorations: strip.workspaceBackend.decorations
                        flashUrgent: strip.widget.flashUrgent
                        urgentColor: strip.widget.urgentColor
                        specialColor: strip.widget.specialColor
                        focusColor: strip.widget.focusColor
                        urgentPulse: strip.widget.urgentPulse
                        shadowLevel: strip.widget.shadowLevel
                        shadowDirection: strip.widget.shadowDirectionFor(strip.anchorEdge)
                        liftOnHover: strip.widget.hoverMode !== "magnify"
                        lift: strip.widget.hoverMode === "magnify" && thumbH > 0
                            ? strip.liftFor(entry, entry.magnification) : 0
                        onHoverChanged: (hovered, frame) =>
                            strip.widget.updateWorkspaceHover(entry.modelData, hovered, frame)
                        onActivated: strip.widget.activateWorkspace(entry.modelData)
                    }
                }
            }
        }

        Text {
            visible: !strip.workspaceBackend.available && !strip.vertical
            text: I18n.tr("Unsupported compositor")
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    MouseArea {
        z: -1
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        onWheel: event => {
            strip.widget.handleWheel(event.angleDelta.y);
            event.accepted = true;
        }
    }
}
