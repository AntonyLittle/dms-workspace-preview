import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Services

// Hyprland implementation of the WorkspaceBackend contract.
Item {
    id: root
    visible: false

    property real borderSize: 0
    property real roundingPx: 0
    property string activeBorderColor: ""
    property string inactiveBorderColor: ""

    readonly property var decorations: ({
        borderWidth: borderSize,
        rounding: roundingPx,
        activeColor: activeBorderColor,
        inactiveColor: inactiveBorderColor
    })

    function parseOption(text) {
        try {
            return JSON.parse(text);
        } catch (e) {
            return null;
        }
    }

    // Hyprland reports colours as AARRGGBB, optionally followed by an angle for gradients.
    function colorFromOption(o) {
        const raw = String(o?.gradient ?? o?.color ?? "").trim().split(" ")[0];
        if (!/^[0-9a-fA-F]{6,8}$/.test(raw))
            return "";
        return "#" + (raw.length === 6 ? "ff" + raw : raw);
    }

    function refreshDecorations() {
        borderProc.running = true;
        roundingProc.running = true;
        activeBorderProc.running = true;
        inactiveBorderProc.running = true;
    }

    Component.onCompleted: refreshDecorations()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.refreshDecorations();
        }
    }

    Process {
        id: borderProc
        command: ["hyprctl", "-j", "getoption", "general:border_size"]
        stdout: StdioCollector {
            onStreamFinished: root.borderSize = Number(root.parseOption(text)?.int ?? 0)
        }
    }

    Process {
        id: roundingProc
        command: ["hyprctl", "-j", "getoption", "decoration:rounding"]
        stdout: StdioCollector {
            onStreamFinished: root.roundingPx = Number(root.parseOption(text)?.int ?? 0)
        }
    }

    Process {
        id: activeBorderProc
        command: ["hyprctl", "-j", "getoption", "general:col.active_border"]
        stdout: StdioCollector {
            onStreamFinished: root.activeBorderColor = root.colorFromOption(root.parseOption(text))
        }
    }

    Process {
        id: inactiveBorderProc
        command: ["hyprctl", "-j", "getoption", "general:col.inactive_border"]
        stdout: StdioCollector {
            onStreamFinished: root.inactiveBorderColor = root.colorFromOption(root.parseOption(text))
        }
    }

    function logicalOutput(mon) {
        const ipc = mon?.lastIpcObject;
        if (!ipc)
            return null;
        const scale = ipc.scale > 0 ? ipc.scale : 1;
        const odd = (ipc.transform % 2) === 1;
        const pw = odd ? ipc.height : ipc.width;
        const ph = odd ? ipc.width : ipc.height;
        const r = ipc.reserved ?? [0, 0, 0, 0];
        return {
            name: mon.name,
            x: ipc.x,
            y: ipc.y,
            w: pw / scale,
            h: ph / scale,
            reserved: {
                left: r[0] ?? 0,
                top: r[1] ?? 0,
                right: r[2] ?? 0,
                bottom: r[3] ?? 0
            }
        };
    }

    readonly property var workspaces: {
        const toplevels = Hyprland.toplevels.values;
        const screens = Quickshell.screens;
        const focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        const activeAddress = Hyprland.activeToplevel ? Hyprland.activeToplevel.address : "";

        const result = [];
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id <= 0)
                continue;
            const mon = ws.monitor;
            const out = logicalOutput(mon);
            const activeId = mon?.activeWorkspace ? mon.activeWorkspace.id : -1;

            const windows = [];
            let urgent = false;
            for (const tl of toplevels) {
                if (!tl.workspace || tl.workspace.id !== ws.id)
                    continue;
                if (tl.urgent)
                    urgent = true;
                if (!tl.wayland)
                    continue;
                const ipc = tl.lastIpcObject;
                if (!ipc)
                    continue;
                windows.push({
                    address: ipc.address ?? "",
                    wayland: tl.wayland,
                    appId: ipc.class ?? "",
                    x: ipc.at[0] - (out ? out.x : 0),
                    y: ipc.at[1] - (out ? out.y : 0),
                    w: ipc.size[0],
                    h: ipc.size[1],
                    floating: !!ipc.floating,
                    active: !!activeAddress && activeAddress === (ipc.address ?? "")
                });
            }
            // Tiled windows first so floating ones draw on top.
            windows.sort((a, b) => (a.floating === b.floating) ? 0 : (a.floating ? 1 : -1));

            let screen = null;
            if (out)
                for (const s of screens)
                    if (s.name === out.name) {
                        screen = s;
                        break;
                    }

            result.push({
                id: ws.id,
                name: ws.name,
                outputName: out ? out.name : "",
                screen: screen,
                outputX: out ? out.x : 0,
                outputY: out ? out.y : 0,
                outputW: out ? out.w : 16,
                outputH: out ? out.h : 9,
                reserved: out ? out.reserved : { left: 0, top: 0, right: 0, bottom: 0 },
                focused: ws.id === focusedId,
                onVisibleSpace: ws.id === activeId,
                urgent: urgent,
                windows: windows
            });
        }
        result.sort((a, b) => a.id - b.id);
        return result;
    }

    function focusWorkspace(id) {
        HyprlandService.focusWorkspace(id);
    }
}
