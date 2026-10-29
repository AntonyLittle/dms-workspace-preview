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
        const peak = Math.max(1, widget.hoverSize / item.thumbH);
        return 1 + (peak - 1) * strength * (0.5 + 0.5 * Math.cos(Math.PI * distance / reach));
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
        spacing: Theme.spacingXS

        Repeater {
            model: strip.model

            delegate: WorkspaceItem {
                id: item
                required property var modelData

                readonly property real magnification: strip.scaleFor(item)
                readonly property real shift: strip.strength > 0
                    ? strip.extraBefore(strip.startOf(item)) - strip.pointerExtra : 0

                z: magnification
                transform: [
                    Scale {
                        origin.x: strip.vertical && strip.anchorEdge === "right" ? item.width : 0
                        origin.y: !strip.vertical && strip.anchorEdge === "bottom" ? item.height : 0
                        xScale: item.magnification
                        yScale: item.magnification
                    },
                    Translate {
                        x: strip.vertical ? 0 : item.shift
                        y: strip.vertical ? item.shift : 0
                    }
                ]

                ws: modelData
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
                onHoverChanged: (hovered, globalPosition, baseThumbHeight) =>
                    strip.widget.updateWorkspaceHover(modelData, hovered, globalPosition, baseThumbHeight)
                onActivated: strip.workspaceBackend.focusWorkspace(modelData.key)
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
