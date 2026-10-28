import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common

// One workspace in the pill: a live thumbnail plus optional app icons.
Item {
    id: root

    required property var ws
    property int thumbHeight: 24
    property bool live: true
    property string iconMode: "anchored"
    property int iconSize: 14
    property int maxIcons: 4
    property bool vertical: false
    property bool excludeReserved: true

    signal activated()

    // Insets (logical px) hiding bars/docks that reserve screen edges.
    readonly property var insets: (excludeReserved && ws.reserved)
        ? ws.reserved
        : { left: 0, top: 0, right: 0, bottom: 0 }
    readonly property real usableW: Math.max(1, ws.outputW - insets.left - insets.right)
    readonly property real usableH: Math.max(1, ws.outputH - insets.top - insets.bottom)

    readonly property real aspect: (ws.outputW > 0 && ws.outputH > 0) ? usableW / usableH : 16 / 9
    readonly property int thumbW: Math.max(1, Math.round(thumbHeight * aspect))
    readonly property int thumbH: thumbHeight
    readonly property real scaleFactor: ws.outputW > 0 ? thumbW / usableW : 1
    readonly property int gap: 2

    readonly property var appIds: {
        const seen = [];
        for (const w of ws.windows)
            if (w.appId && seen.indexOf(w.appId) < 0)
                seen.push(w.appId);
        return seen;
    }

    readonly property bool iconsInline: iconMode === "before" || iconMode === "after"
    readonly property bool iconsColumn: iconsInline && !vertical
    readonly property bool iconsRow: iconMode === "anchored" || (iconsInline && vertical)
    readonly property bool showIcons: iconMode !== "off" && appIds.length > 0

    readonly property int lengthAvailable: iconsRow ? thumbW : thumbH
    readonly property int iconCap: Math.max(1, Math.min(maxIcons, Math.floor((lengthAvailable + iconSize / 2) / (iconSize + 1))))
    readonly property int shownCount: appIds.length > iconCap ? iconCap - 1 : appIds.length
    readonly property var shownIds: appIds.slice(0, shownCount)
    readonly property int overflowCount: appIds.length - shownCount

    readonly property real leadX: (iconMode === "before" && iconsColumn && showIcons) ? iconSize + gap : 0
    readonly property real leadY: (iconMode === "before" && iconsRow && iconsInline && showIcons) ? iconSize + gap : 0
    readonly property real trailY: (iconMode === "after" && iconsRow && iconsInline && showIcons) ? iconSize + gap : 0
    readonly property real anchoredOverhang: (iconMode === "anchored" && showIcons) ? iconSize / 2 : 0

    implicitWidth: thumbW + leadX + (iconsColumn && iconMode === "after" && showIcons ? iconSize + gap : 0)
    implicitHeight: thumbH + leadY + trailY + anchoredOverhang

    readonly property bool activeOnOutput: ws.onVisibleSpace && ws.screen !== null

    // Hyprland slides the output during a workspace switch. Per-window captures
    // are unaffected by that slide, so use them until the animation has finished.
    property bool outputSettled: false
    onActiveOnOutputChanged: {
        outputSettled = false;
        settleTimer.restart();
    }
    Component.onCompleted: settleTimer.restart()

    Timer {
        id: settleTimer
        interval: 2000
        onTriggered: root.outputSettled = true
    }

    readonly property bool useOutputCapture: activeOnOutput && outputSettled

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

            // Captures the whole output; offset and oversize it so the usable area
            // fills the frame and the reserved edges fall outside the clip.
            ScreencopyView {
                x: -root.insets.left * root.scaleFactor
                y: -root.insets.top * root.scaleFactor
                width: root.ws.outputW * root.scaleFactor
                height: root.ws.outputH * root.scaleFactor
                visible: root.useOutputCapture
                captureSource: root.ws.screen
                live: root.live
            }

            Repeater {
                model: root.useOutputCapture ? [] : root.ws.windows

                delegate: ScreencopyView {
                    required property var modelData
                    x: (modelData.x - root.insets.left) * root.scaleFactor
                    y: (modelData.y - root.insets.top) * root.scaleFactor
                    width: modelData.w * root.scaleFactor
                    height: modelData.h * root.scaleFactor
                    captureSource: modelData.wayland
                    live: root.live
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.ws.windows.length === 0 && !root.useOutputCapture
                text: root.ws.name
                color: Theme.surfaceText
                font.pixelSize: Math.max(8, root.thumbH * 0.4)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: root.ws.focused ? 2 : (root.ws.onVisibleSpace ? 1 : 0)
            border.color: root.ws.focused ? Theme.primary : Theme.outline
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activated()
        }
    }

    WorkspaceIcons {
        id: iconStrip
        visible: root.showIcons
        appIds: root.shownIds
        overflow: root.overflowCount
        iconSize: root.iconSize
        rowLayout: root.iconsRow
        x: {
            if (root.iconsRow)
                return root.leadX + (root.thumbW - width) / 2;
            return root.iconMode === "before" ? 0 : root.leadX + root.thumbW + root.gap;
        }
        y: {
            if (root.iconsRow && root.iconMode === "anchored")
                return root.leadY + root.thumbH - root.iconSize / 2;
            if (root.iconsRow)
                return root.iconMode === "before" ? 0 : root.leadY + root.thumbH + root.gap;
            return root.leadY + (root.thumbH - height) / 2;
        }
    }
}
