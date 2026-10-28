import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Services

// Hyprland implementation of the WorkspaceBackend contract.
QtObject {
    id: root

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

        const result = [];
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id <= 0)
                continue;
            const mon = ws.monitor;
            const out = logicalOutput(mon);
            const activeId = mon?.activeWorkspace ? mon.activeWorkspace.id : -1;

            const windows = [];
            for (const tl of toplevels) {
                if (!tl.workspace || tl.workspace.id !== ws.id || !tl.wayland)
                    continue;
                const ipc = tl.lastIpcObject;
                if (!ipc)
                    continue;
                windows.push({
                    wayland: tl.wayland,
                    appId: ipc.class ?? "",
                    x: ipc.at[0] - (out ? out.x : 0),
                    y: ipc.at[1] - (out ? out.y : 0),
                    w: ipc.size[0],
                    h: ipc.size[1],
                    floating: !!ipc.floating
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
