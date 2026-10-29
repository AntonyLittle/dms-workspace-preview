import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common

// One workspace in the pill: a live thumbnail plus optional app icons.
Item {
    id: root

    required property var ws
    property int thumbHeight: 24
    property bool fitContainer: false
    property real containerSize: 0
    property bool hoverEnabled: false
    property bool capturesEnabled: true
    property bool live: true
    property string iconMode: "bottom"
    property int iconSize: 14
    property int maxIcons: 4
    property bool vertical: false
    property bool excludeReserved: true
    property bool squareHighlight: false
    property bool showWallpaper: true
    property bool showDecorations: true
    property var decorations: ({ borderWidth: 0, rounding: 0, activeColor: "", inactiveColor: "" })
    property bool flashUrgent: true
    property color urgentColor: "#ff0000"
    property color specialColor: "#ffd700"
    property color focusColor: Theme.primary
    property real urgentPulse: 1

    signal activated()
    signal hoverChanged(bool hovered, point globalPosition, int baseThumbHeight)

    // Insets (logical px) hiding bars/docks that reserve screen edges.
    readonly property var insets: (excludeReserved && ws.reserved)
        ? ws.reserved
        : { left: 0, top: 0, right: 0, bottom: 0 }
    readonly property real usableW: Math.max(1, ws.outputW - insets.left - insets.right)
    readonly property real usableH: Math.max(1, ws.outputH - insets.top - insets.bottom)

    readonly property real aspect: (ws.outputW > 0 && ws.outputH > 0) ? usableW / usableH : 16 / 9

    // Fit mode: containerSize is the cross-axis space the pill offers. Horizontal bars constrain
    // height, so top/bottom icons (which overhang that edge) reserve half their size. Vertical bars
    // constrain width, so left/right icons reserve half their size on the width instead.
    readonly property real fitOverhang: (!vertical && (iconMode === "top" || iconMode === "bottom")) ? iconSize / 2 : 0
    readonly property real sideOverhang: (vertical && (iconMode === "left" || iconMode === "right")) ? iconSize / 2 : 0
    readonly property int thumbH: fitContainer
        ? Math.max(1, Math.floor(vertical
            ? (containerSize - sideOverhang) / aspect
            : containerSize - fitOverhang))
        : thumbHeight
    readonly property int thumbW: Math.max(1, Math.round(thumbH * aspect))
    readonly property real scaleFactor: ws.outputW > 0 ? thumbW / usableW : 1
    readonly property int gap: 2

    // Wallpaper comes from DMS (per output). A "#rrggbb" value means a solid colour.
    readonly property string wallpaperPath: ws.outputName ? (SessionData.getMonitorWallpaper(ws.outputName) ?? "") : ""
    readonly property bool wallpaperIsColor: wallpaperPath.startsWith("#")
    readonly property bool hasWallpaper: showWallpaper && wallpaperPath !== ""
    readonly property string wallpaperFillMode: ws.outputName ? SessionData.getMonitorWallpaperFillMode(ws.outputName) : "Fill"
    readonly property bool wallpaperTiled: wallpaperFillMode.startsWith("Tile")
    readonly property string wallpaperUrl: wallpaperIsColor ? "" : "file://" + wallpaperPath.split("/").map(s => encodeURIComponent(s)).join("/")

    // Hyprland draws borders outside each window's box. The thumbnail is too small for
    // sub-pixel borders to show, so the border is at least one device pixel.
    readonly property real borderPx: (showDecorations && decorations.borderWidth > 0)
        ? Math.max(1, decorations.borderWidth * scaleFactor) : 0
    readonly property real roundingPx: showDecorations ? decorations.rounding * scaleFactor : 0

    readonly property var appIds: {
        const seen = [];
        for (const w of ws.windows)
            if (w.appId && seen.indexOf(w.appId) < 0)
                seen.push(w.appId);
        return seen;
    }

    readonly property bool iconsInline: iconMode === "before" || iconMode === "after"
    readonly property bool iconsColumn: iconsInline && !vertical
    readonly property bool iconsRow: iconMode === "top" || iconMode === "bottom" || (iconsInline && vertical)
    readonly property bool showIcons: iconMode !== "off" && appIds.length > 0

    readonly property int lengthAvailable: iconsRow ? thumbW : thumbH
    // Icons and the 1px gaps between them must fit inside the thumbnail's length (WorkspaceIcons spacing).
    readonly property int iconCap: Math.max(1, Math.min(maxIcons, Math.floor((lengthAvailable + 1) / (iconSize + 1))))
    readonly property int shownCount: appIds.length > iconCap ? iconCap - 1 : appIds.length
    readonly property var shownIds: appIds.slice(0, shownCount)
    readonly property int overflowCount: appIds.length - shownCount

    // Edge-overlapping icons reserve half their size on that side so they can straddle the edge.
    // The reserve depends only on the mode, so empty workspaces (such as the placeholder) line up with occupied ones.
    readonly property real leadX: (iconMode === "before" && iconsColumn && showIcons) ? iconSize + gap
        : (iconMode === "left" ? iconSize / 2 : 0)
    readonly property real leadY: (iconMode === "before" && iconsRow && iconsInline && showIcons) ? iconSize + gap
        : (iconMode === "top" ? iconSize / 2 : 0)
    readonly property real trailX: (iconMode === "after" && iconsColumn && showIcons) ? iconSize + gap
        : (iconMode === "right" ? iconSize / 2 : 0)
    readonly property real trailY: (iconMode === "after" && iconsRow && iconsInline && showIcons) ? iconSize + gap
        : (iconMode === "bottom" ? iconSize / 2 : 0)

    implicitWidth: thumbW + leadX + trailX
    implicitHeight: thumbH + leadY + trailY

    Rectangle {
        id: frame
        x: root.leadX
        y: root.leadY
        width: root.thumbW
        height: root.thumbH
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.6)
        clip: true

        Item {
            id: content
            anchors.fill: parent

            // Wallpaper sits under the windows and is offset by the same insets, so it lines
            // up with the captured area. The frame clips anything outside it.
            Item {
                id: wallpaper
                visible: root.hasWallpaper
                x: -root.insets.left * root.scaleFactor
                y: -root.insets.top * root.scaleFactor
                width: root.ws.outputW * root.scaleFactor
                height: root.ws.outputH * root.scaleFactor

                Rectangle {
                    anchors.fill: parent
                    visible: root.hasWallpaper && root.wallpaperIsColor
                    color: root.wallpaperPath
                }

                Image {
                    anchors.fill: parent
                    visible: root.hasWallpaper && !root.wallpaperIsColor
                    source: root.wallpaperUrl
                    fillMode: Theme.getFillMode(root.wallpaperFillMode)
                    asynchronous: true
                    smooth: true
                    sourceSize: root.wallpaperTiled ? Qt.size(0, 0) : Qt.size(wallpaper.width * 2, wallpaper.height * 2)
                }
            }

            // Keyed by window address so each capture survives focus and move updates.
            ScriptModel {
                id: windowModel
                values: root.ws.windows
                objectProp: "address"
            }

            // Each window is captured on its own, so compositor animations such as
            // workspace slides and swipe gestures never appear in the thumbnail.
            Repeater {
                model: windowModel

                delegate: Item {
                    id: windowTile
                    required property var modelData
                    property bool hasFrame: false
                    property bool captureActive: true

                    y: (windowTile.modelData.y - root.insets.top) * root.scaleFactor
                    width: windowTile.modelData.w * root.scaleFactor
                    height: windowTile.modelData.h * root.scaleFactor

                    // Approximates the compositor border, which is drawn outside the window box.
                    Rectangle {
                        visible: root.borderPx > 0
                        x: -root.borderPx
                        y: -root.borderPx
                        width: parent.width + 2 * root.borderPx
                        height: parent.height + 2 * root.borderPx
                        radius: root.roundingPx + root.borderPx
                        color: (windowTile.modelData.active ? root.decorations.activeColor : root.decorations.inactiveColor) || "transparent"
                    }

                    // Shown until a frame arrives, or when a capture has stopped and is being retried.
                    Rectangle {
                        anchors.fill: parent
                        visible: !windowTile.hasFrame
                        color: Theme.withAlpha(Theme.surfaceText, 0.08)

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 4
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: windowTile.modelData.appId
                            font.pixelSize: Math.max(6, Math.min(12, parent.height * 0.4))
                            color: Theme.outline
                            visible: text !== "" && parent.width > 24
                        }
                    }

                    // A stopped capture is recreated after a short pause, rather than left empty.
                    Loader {
                        anchors.fill: parent
                        active: windowTile.captureActive && root.capturesEnabled
                        sourceComponent: ScreencopyView {
                            captureSource: windowTile.modelData.wayland
                            live: root.live
                            onHasContentChanged: windowTile.hasFrame = hasContent
                            onStopped: {
                                windowTile.hasFrame = false;
                                windowTile.captureActive = false;
                            }
                        }
                    }

                    Timer {
                        interval: 1000
                        running: !windowTile.captureActive
                        onTriggered: windowTile.captureActive = true
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.ws.windows.length === 0
                text: root.ws.placeholder ? "+" : root.ws.name
                color: root.ws.placeholder ? Theme.outline : Theme.surfaceText
                font.pixelSize: Math.max(8, root.thumbH * 0.4)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.squareHighlight ? 0 : parent.radius
            color: "transparent"
            // A visible special gets its own selected border so it reads as shown, not as a regular workspace.
            border.width: (root.ws.special && root.ws.onVisibleSpace) ? 2
                : (root.ws.focused ? 2 : (root.ws.onVisibleSpace ? 1 : 0))
            border.color: (root.ws.special && root.ws.onVisibleSpace) ? root.specialColor
                : (root.ws.focused ? root.focusColor : Theme.outline)
        }

        // Pulses on unfocused workspaces that have a window asking for attention.
        Rectangle {
            anchors.fill: parent
            visible: root.flashUrgent && !root.ws.placeholder && root.ws.urgent && !root.ws.focused
            radius: root.squareHighlight ? 0 : parent.radius
            color: "transparent"
            border.width: 2
            border.color: root.urgentColor
            opacity: root.urgentPulse
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: root.hoverEnabled
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activated()
            onEntered: root.hoverChanged(true, frame.mapToGlobal(frame.width / 2, frame.height / 2), root.thumbH)
            onExited: root.hoverChanged(false, Qt.point(0, 0), root.thumbH)
        }
    }

    WorkspaceIcons {
        id: iconStrip
        visible: root.showIcons
        appIds: root.shownIds
        overflow: root.overflowCount
        iconSize: root.iconSize
        rowLayout: root.iconsRow
        onActivated: root.activated()
        x: {
            if (root.iconsRow)
                return root.leadX + (root.thumbW - width) / 2;
            if (root.iconMode === "left")
                return root.leadX - root.iconSize / 2;
            if (root.iconMode === "right")
                return root.leadX + root.thumbW - root.iconSize / 2;
            return root.iconMode === "before" ? 0 : root.leadX + root.thumbW + root.gap;
        }
        y: {
            if (root.iconMode === "top")
                return root.leadY - root.iconSize / 2;
            if (root.iconMode === "bottom")
                return root.leadY + root.thumbH - root.iconSize / 2;
            if (root.iconsRow)
                return root.iconMode === "before" ? 0 : root.leadY + root.thumbH + root.gap;
            return root.leadY + (root.thumbH - height) / 2;
        }
    }
}
