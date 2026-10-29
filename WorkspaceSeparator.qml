import QtQuick
import qs.Common

// A thin line between groups of workspace thumbnails. It has no cross-axis size of its own,
// so it never affects the strip's thickness; crossSize is the thickness it is drawn across.
Item {
    id: root

    property bool vertical: false
    property real crossSize: 0
    readonly property real lineThickness: 2
    readonly property real margin: Theme.spacingXS

    implicitWidth: vertical ? 0 : lineThickness + 2 * margin
    implicitHeight: vertical ? lineThickness + 2 * margin : 0

    Rectangle {
        readonly property real length: Math.round(root.crossSize * 0.7)
        x: root.vertical ? (root.crossSize - length) / 2 : root.margin
        y: root.vertical ? root.margin : (root.crossSize - length) / 2
        width: root.vertical ? length : root.lineThickness
        height: root.vertical ? root.lineThickness : length
        radius: root.lineThickness / 2
        color: Theme.withAlpha(Theme.outline, 0.6)
    }
}
