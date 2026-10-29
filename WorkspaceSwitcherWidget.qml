import QtQuick
import Quickshell
import Quickshell.Wayland
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
    readonly property string hoverMode: ["none", "popout", "magnify"].includes(setting("hoverMode", "none"))
        ? setting("hoverMode", "none") : "none"
    readonly property int hoverSize: intSetting("hoverSize", 120, 48, 400)
    readonly property int hoverDelay: intSetting("hoverDelay", 120, 0, 500)
    readonly property bool wrapScroll: boolSetting("wrapScroll", true)
    readonly property bool hideEmpty: boolSetting("hideEmpty", false)
    readonly property bool showAllMonitors: boolSetting("showAllMonitors", true)
    readonly property bool excludeReservedZones: boolSetting("excludeReservedZones", true)
    readonly property bool squareHighlight: boolSetting("squareHighlight", false)
    readonly property bool showWallpaper: boolSetting("showWallpaper", true)
    readonly property bool showDecorations: boolSetting("showDecorations", true)
    readonly property bool flashUrgent: boolSetting("flashUrgent", true)
    readonly property var themeColors: ({
        primary: Theme.primary,
        secondary: Theme.secondary,
        tertiary: Theme.tertiary,
        error: Theme.error,
        outline: Theme.outline
    })

    // Each colour is either a theme token ("theme") or a custom hex ("custom").
    function resolveColor(key, defaultSource, defaultToken, defaultHex) {
        if (setting(key + "Source", defaultSource) === "theme")
            return themeColors[setting(key + "ThemeColor", defaultToken)] ?? Theme.primary;
        return setting(key + "Color", defaultHex) || Theme.primary;
    }

    readonly property color urgentColor: resolveColor("urgent", "custom", "error", "#ff0000")
    readonly property color specialColor: resolveColor("special", "custom", "tertiary", "#ffd700")
    readonly property color focusColor: resolveColor("focus", "theme", "primary", "")
    readonly property bool live: surfaceLive !== false
    property var hoveredWorkspace: null
    property var hoverCandidate: null
    property point hoveredGlobalPosition: Qt.point(0, 0)
    property int hoveredBaseThumbHeight: thumbnailHeight
    property bool hoverPendingRemoval: false

    readonly property bool trailingPlaceholder: boolSetting("trailingPlaceholder", false)
    readonly property bool showSpecialWorkspaces: boolSetting("showSpecialWorkspaces", false)

    function updateWorkspaceHover(ws, entered, globalPosition, baseThumbHeight) {
        if (hoverMode === "none")
            return;

        if (entered) {
            hoverCandidate = ws;
            hoveredGlobalPosition = globalPosition;
            hoveredBaseThumbHeight = baseThumbHeight;
            hoverPendingRemoval = false;
        } else if (hoverCandidate === ws || hoveredWorkspace === ws) {
            if (hoverCandidate === ws)
                hoverCandidate = null;
            hoverPendingRemoval = true;
        }
        hoverTimer.restart();
    }

    function clearHover() {
        hoverTimer.stop();
        hoverCandidate = null;
        hoveredWorkspace = null;
        hoverPendingRemoval = false;
    }

    onHoverModeChanged: {
        if (hoverMode === "none")
            clearHover();
    }

    Timer {
        id: hoverTimer
        interval: root.hoverDelay
        onTriggered: {
            if (root.hoverCandidate) {
                root.hoveredWorkspace = root.hoverCandidate;
                root.hoverCandidate = null;
                root.hoverPendingRemoval = false;
            } else if (root.hoverPendingRemoval) {
                root.hoveredWorkspace = null;
                root.hoverPendingRemoval = false;
            }
        }
    }

    // DMS creates both pills and hides the unused one, so the popout lives here to stay single.
    Loader {
        active: root.hoverMode === "popout" && root.hoveredWorkspace !== null && root.parentScreen !== null
        sourceComponent: hoverPreviewWindow
    }

    Component {
        id: hoverPreviewWindow

        PanelWindow {
            id: popout

            readonly property bool vertical: root.isVertical

            readonly property real gap: 8
            readonly property real padding: 6
            readonly property real localX: screen ? root.hoveredGlobalPosition.x - screen.x : 0
            readonly property real localY: screen ? root.hoveredGlobalPosition.y - screen.y : 0
            readonly property bool popupBelow: screen ? localY < screen.height - localY : true
            readonly property bool popupRight: screen ? localX < screen.width - localX : true

            function clamp(value, maximum) {
                return Math.max(0, Math.min(value, Math.max(0, maximum)));
            }

            screen: root.parentScreen
            visible: root.hoverMode === "popout" && root.hoveredWorkspace !== null
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            WlrLayershell.namespace: "dms:plugins:workspacePreview:hover-" + (screen ? screen.name : "unknown") + (vertical ? "-vertical" : "-horizontal")
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {}

            Item {
                id: popup
                width: preview.implicitWidth + popout.padding * 2
                height: preview.implicitHeight + popout.padding * 2
                readonly property real desiredX: popout.vertical
                    ? (popout.popupRight
                        ? popout.localX + root.hoveredBaseThumbHeight / 2 + popout.gap
                        : popout.localX - width - root.hoveredBaseThumbHeight / 2 - popout.gap)
                    : popout.localX - width / 2
                readonly property real desiredY: popout.vertical
                    ? popout.localY - height / 2
                    : (popout.popupBelow
                        ? popout.localY + root.hoveredBaseThumbHeight / 2 + popout.gap
                        : popout.localY - height - root.hoveredBaseThumbHeight / 2 - popout.gap)
                x: screen ? popout.clamp(desiredX, screen.width - width) : 0
                y: screen ? popout.clamp(desiredY, screen.height - height) : 0

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadius + popout.padding
                    color: Theme.surfaceContainer
                    border.width: 1
                    border.color: Theme.outline
                }

                WorkspaceItem {
                    id: preview
                    x: popout.padding
                    y: popout.padding
                    ws: root.hoveredWorkspace
                    thumbHeight: root.hoverSize
                    fitContainer: false
                    capturesEnabled: popout.visible
                    live: true
                    iconMode: "off"
                    excludeReserved: root.excludeReservedZones
                    showWallpaper: root.showWallpaper
                    showDecorations: root.showDecorations
                    decorations: backend.decorations
                    flashUrgent: root.flashUrgent
                    urgentColor: root.urgentColor
                    specialColor: root.specialColor
                    focusColor: root.focusColor
                    urgentPulse: root.urgentPulse
                    onActivated: {}
                }
            }
        }
    }

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
        WorkspaceStrip {
            widget: root
            workspaceBackend: backend
            model: workspaceModel
            vertical: false
            anchorEdge: root.axis ? root.axis.edge : "top"
        }
    }

    verticalBarPill: Component {
        WorkspaceStrip {
            widget: root
            workspaceBackend: backend
            model: workspaceModel
            vertical: true
            anchorEdge: root.axis ? root.axis.edge : "left"
        }
    }
}
