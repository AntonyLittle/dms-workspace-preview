import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    WorkspaceBackend {
        id: backend
        outputFilter: root.showAllMonitors || !root.parentScreen ? "" : root.parentScreen.name
    }

    // Keyed by workspace key so delegates persist and only update when the list changes.
    ScriptModel {
        id: workspaceModel
        values: root.visibleWorkspaces
        objectProp: "key"
    }

    function setting(key, fallback) {
        const v = pluginData ? pluginData[key] : undefined;
        return (v === undefined || v === null || v === "") ? fallback : v;
    }

    function boolSetting(key, fallback) {
        const v = setting(key, fallback);
        return typeof v === "string" ? v === "true" : !!v;
    }

    function intSetting(key, fallback, lo, hi) {
        const n = Math.round(Number(setting(key, fallback)));
        return Math.max(lo, Math.min(hi, isNaN(n) ? fallback : n));
    }

    readonly property int thumbnailHeight: intSetting("thumbnailHeight", 24, 12, 64)
    readonly property bool fitContainer: setting("sizeMode", "fit") !== "fixed"
    readonly property int fillPercent: intSetting("fillPercent", 100, 50, 100)
    readonly property real contentThickness: Math.max(0, widgetThickness - 2 * (barConfig?.widgetPadding ?? 8) * (widgetThickness / 30))
    readonly property real fitContainerSize: contentThickness * fillPercent / 100
    // "anchored" was the bottom-edge option before the edges were split out; keep saved values working.
    readonly property string iconMode: setting("iconMode", "bottom") === "anchored" ? "bottom" : setting("iconMode", "bottom")
    readonly property int iconSize: intSetting("iconSize", 14, 8, 32)
    readonly property int maxIcons: intSetting("maxIcons", 4, 1, 10)
    readonly property bool wrapScroll: boolSetting("wrapScroll", true)
    readonly property bool hideEmpty: boolSetting("hideEmpty", false)
    readonly property bool showAllMonitors: boolSetting("showAllMonitors", true)
    readonly property bool excludeReservedZones: boolSetting("excludeReservedZones", true)
    readonly property bool squareHighlight: boolSetting("squareHighlight", false)
    readonly property bool showWallpaper: boolSetting("showWallpaper", true)
    readonly property bool showDecorations: boolSetting("showDecorations", true)
    readonly property bool flashUrgent: boolSetting("flashUrgent", true)
    readonly property color urgentColor: setting("urgentColor", "#ff0000")
    readonly property color specialColor: setting("specialColor", "#ffd700")
    readonly property bool live: surfaceLive !== false

    readonly property bool trailingPlaceholder: boolSetting("trailingPlaceholder", false)
    readonly property bool showSpecialWorkspaces: boolSetting("showSpecialWorkspaces", false)

    readonly property var realWorkspaces: {
        const regular = backend.workspaces.filter(ws => !ws.special);
        return hideEmpty
            ? regular.filter(ws => ws.windows.length > 0 || ws.focused || ws.onVisibleSpace)
            : regular;
    }

    // Special workspaces are never hidden by hideEmpty. They follow the regular list.
    readonly property var specialWorkspaces: showSpecialWorkspaces
        ? backend.workspaces.filter(ws => ws.special)
        : []

    // Offers a new workspace after the last one, but only when that last one is in use.
    // It copies the last workspace's output geometry so it sizes like its neighbours.
    // Special workspaces are listed after the placeholder, or after the last regular workspace.
    readonly property var visibleWorkspaces: {
        const list = realWorkspaces;
        if (!trailingPlaceholder || list.length === 0 || list[list.length - 1].windows.length === 0)
            return list.concat(specialWorkspaces);
        const last = list[list.length - 1];
        const placeholder = Object.assign({}, last, {
            key: String(last.id + 1),
            id: last.id + 1,
            name: String(last.id + 1),
            special: false,
            windows: [],
            focused: false,
            onVisibleSpace: false,
            urgent: false,
            placeholder: true
        });
        return list.concat([placeholder], specialWorkspaces);
    }

    readonly property bool anyUrgent: flashUrgent && visibleWorkspaces.some(ws => ws.urgent && !ws.focused)

    // One shared pulse drives every urgent thumbnail so they flash in step. It only runs while needed.
    property real urgentPulse: 1

    SequentialAnimation {
        running: root.anyUrgent
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "urgentPulse"; to: 0.2; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "urgentPulse"; to: 1; duration: 600; easing.type: Easing.InOutSine }
    }

    // Wheel: up = previous workspace, down = next. Accumulates one notch (120 units) per step.
    property real wheelAccumulator: 0

    function handleWheel(delta) {
        if (delta === 0)
            return;
        if (wheelAccumulator !== 0 && Math.sign(delta) !== Math.sign(wheelAccumulator))
            wheelAccumulator = 0;
        wheelAccumulator += delta;
        const notches = Math.trunc(wheelAccumulator / 120);
        if (notches === 0)
            return;
        wheelAccumulator -= notches * 120;
        backend.scroll(-notches, wrapScroll);
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: strip.implicitWidth
            implicitHeight: strip.implicitHeight

            Row {
                id: strip
                spacing: Theme.spacingXS

            Repeater {
                model: workspaceModel

                delegate: WorkspaceItem {
                    required property var modelData
                    ws: modelData
                    thumbHeight: root.thumbnailHeight
                    fitContainer: root.fitContainer
                    containerSize: root.fitContainerSize
                    live: root.live
                    iconMode: root.iconMode
                    iconSize: root.iconSize
                    maxIcons: root.maxIcons
                    excludeReserved: root.excludeReservedZones
                    squareHighlight: root.squareHighlight
                    showWallpaper: root.showWallpaper
                    showDecorations: root.showDecorations
                    decorations: backend.decorations
                    flashUrgent: root.flashUrgent
                    urgentColor: root.urgentColor
                    specialColor: root.specialColor
                    urgentPulse: root.urgentPulse
                    vertical: false
                    onActivated: backend.focusWorkspace(modelData.key)
                }
            }

            Text {
                visible: !backend.available
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
                    root.handleWheel(event.angleDelta.y);
                    event.accepted = true;
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: strip.implicitWidth
            implicitHeight: strip.implicitHeight

            Column {
                id: strip
                spacing: Theme.spacingXS

            Repeater {
                model: workspaceModel

                delegate: WorkspaceItem {
                    required property var modelData
                    ws: modelData
                    thumbHeight: root.thumbnailHeight
                    fitContainer: root.fitContainer
                    containerSize: root.fitContainerSize
                    live: root.live
                    iconMode: root.iconMode
                    iconSize: root.iconSize
                    maxIcons: root.maxIcons
                    excludeReserved: root.excludeReservedZones
                    squareHighlight: root.squareHighlight
                    showWallpaper: root.showWallpaper
                    showDecorations: root.showDecorations
                    decorations: backend.decorations
                    flashUrgent: root.flashUrgent
                    urgentColor: root.urgentColor
                    specialColor: root.specialColor
                    urgentPulse: root.urgentPulse
                    vertical: true
                    onActivated: backend.focusWorkspace(modelData.key)
                }
            }
            }

            MouseArea {
                z: -1
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                cursorShape: Qt.ArrowCursor
                onWheel: event => {
                    root.handleWheel(event.angleDelta.y);
                    event.accepted = true;
                }
            }
        }
    }
}
