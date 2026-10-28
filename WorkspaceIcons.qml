import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Common
import qs.Services

// A strip of app icons for one workspace. Overflow is shown as "+N".
Item {
    id: root

    property var appIds: []
    property int overflow: 0
    property int iconSize: 14
    property bool rowLayout: true
    property real spacing: 1

    readonly property int cellCount: appIds.length + (overflow > 0 ? 1 : 0)
    implicitWidth: rowLayout ? cellCount * (iconSize + spacing) - spacing : iconSize
    implicitHeight: rowLayout ? iconSize : cellCount * (iconSize + spacing) - spacing

    Grid {
        anchors.centerIn: parent
        columns: root.rowLayout ? root.cellCount : 1
        spacing: root.spacing

        Repeater {
            model: root.appIds

            delegate: Item {
                required property string modelData
                width: root.iconSize
                height: root.iconSize

                Rectangle {
                    anchors.fill: parent
                    radius: Math.round(root.iconSize / 4)
                    color: Theme.surfaceContainerHighest
                }

                IconImage {
                    anchors.fill: parent
                    anchors.margins: 1
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    source: {
                        const entry = DesktopEntries.heuristicLookup(modelData);
                        return Paths.getAppIcon(modelData, entry);
                    }
                }
            }
        }

        Item {
            visible: root.overflow > 0
            width: root.iconSize
            height: root.iconSize

            Text {
                anchors.centerIn: parent
                text: "+" + root.overflow
                color: Theme.surfaceText
                font.pixelSize: Math.max(8, root.iconSize - 4)
                font.weight: Font.Medium
            }
        }
    }
}
