import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root

    WorkspaceBackend {
        id: backend
        outputFilter: root.showAllMonitors || !root.parentScreen ? "" : root.parentScreen.name
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
    readonly property string iconMode: setting("iconMode", "anchored")
    readonly property int iconSize: intSetting("iconSize", 14, 8, 32)
    readonly property int maxIcons: intSetting("maxIcons", 4, 1, 10)
    readonly property bool wrapScroll: boolSetting("wrapScroll", true)
    readonly property bool hideEmpty: boolSetting("hideEmpty", false)
    readonly property bool showAllMonitors: boolSetting("showAllMonitors", true)
    readonly property bool excludeReservedZones: boolSetting("excludeReservedZones", true)
    readonly property bool live: surfaceLive !== false

    readonly property var visibleWorkspaces: hideEmpty
        ? backend.workspaces.filter(ws => ws.windows.length > 0 || ws.focused || ws.onVisibleSpace)
        : backend.workspaces

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
        Row {
            spacing: Theme.spacingXS

            WheelHandler {
                onWheel: event => {
                    root.handleWheel(event.angleDelta.y);
                    event.accepted = true;
                }
            }

            Repeater {
                model: root.visibleWorkspaces

                delegate: WorkspaceItem {
                    required property var modelData
                    ws: modelData
                    thumbHeight: root.thumbnailHeight
                    live: root.live
                    iconMode: root.iconMode
                    iconSize: root.iconSize
                    maxIcons: root.maxIcons
                    excludeReserved: root.excludeReservedZones
                    vertical: false
                    onActivated: backend.focusWorkspace(modelData.id)
                }
            }

            Text {
                visible: !backend.available
                text: I18n.tr("Unsupported compositor")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            WheelHandler {
                onWheel: event => {
                    root.handleWheel(event.angleDelta.y);
                    event.accepted = true;
                }
            }

            Repeater {
                model: root.visibleWorkspaces

                delegate: WorkspaceItem {
                    required property var modelData
                    ws: modelData
                    thumbHeight: root.thumbnailHeight
                    live: root.live
                    iconMode: root.iconMode
                    iconSize: root.iconSize
                    maxIcons: root.maxIcons
                    excludeReserved: root.excludeReservedZones
                    vertical: true
                    onActivated: backend.focusWorkspace(modelData.id)
                }
            }
        }
    }
}
