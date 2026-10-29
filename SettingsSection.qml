import QtQuick
import qs.Common
import qs.DCommon.Widgets

// Collapsible heading between groups of plugin settings, styled like DMS's own section labels.
// It is a plain item rather than a container: DMS only reloads values on the settings that are
// direct children of PluginSettings, so the settings stay flat and bind their visibility to `expanded`.
Item {
    id: root

    required property string title
    property bool expanded: true
    property bool first: false
    readonly property real topGap: first ? Theme.spacingXS : Theme.spacingL
    readonly property real bottomGap: Theme.spacingXS

    signal toggleRequested()

    width: parent?.width ?? 0
    height: Math.max(label.implicitHeight, caret.height) + topGap + bottomGap

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: title
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.toggleRequested();
            event.accepted = true;
        }
    }

    Rectangle {
        id: hit
        anchors.fill: parent
        anchors.topMargin: root.topGap - Theme.spacingXS
        anchors.bottomMargin: root.bottomGap - Theme.spacingXS
        radius: Theme.cornerRadiusS
        color: "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.primary

        StateLayer {
            stateColor: Theme.primary
            cornerRadius: hit.radius
            onClicked: root.toggleRequested()
        }
    }

    StyledText {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingS
        anchors.right: caret.left
        anchors.rightMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (root.topGap - root.bottomGap) / 2
        text: root.title
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Theme.fontWeightMedium
        color: Theme.primary
        wrapMode: Text.WordWrap
    }

    DIcon {
        id: caret
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingS
        anchors.verticalCenter: label.verticalCenter
        name: "expand_more"
        size: Theme.iconSize
        color: Theme.surfaceVariantText
        rotation: root.expanded ? 180 : 0

        Behavior on rotation {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }
}
