import QtQuick
import qs.Services

// Compositor-agnostic workspace source. Picks a backend for the running compositor.
//
// Backend contract (each file in backends/ must provide):
//   readonly property var workspaces   list of workspace entries, sorted by id:
//       id            number   compositor workspace id
//       name          string   display name
//       outputName    string   output (monitor) name the workspace lives on
//       screen        object   Quickshell screen for outputName (may be null)
//       outputX/outputY/outputW/outputH  output geometry in logical px
//       reserved      object { left, top, right, bottom } edge insets in logical px
//                     claimed by exclusive layer surfaces (bars, docks)
//       focused       bool     workspace is the globally focused one
//       onVisibleSpace bool    workspace is the active one on its output
//       windows       list of { address, wayland, appId, x, y, w, h, floating }
//                     address is a stable compositor id for the window
//                     x/y are relative to the output origin, logical px
//   function focusWorkspace(id)   switch to workspace id
//   function focusedIndex()       index of the focused workspace in workspaces, or -1
Item {
    id: root

    property string outputFilter: ""

    readonly property var allWorkspaces: loader.item ? loader.item.workspaces : []
    readonly property var workspaces: outputFilter === "" ? allWorkspaces
        : allWorkspaces.filter(ws => ws.outputName === outputFilter)
    readonly property bool available: loader.item !== null

    function focusWorkspace(id) {
        if (loader.item)
            loader.item.focusWorkspace(id);
    }

    function scroll(step, wrap) {
        const list = workspaces;
        if (list.length === 0)
            return;
        let current = -1;
        for (let i = 0; i < list.length; i++) {
            if (list[i].focused) {
                current = i;
                break;
            }
        }
        if (current < 0)
            current = 0;
        let target = current + step;
        if (wrap)
            target = ((target % list.length) + list.length) % list.length;
        else
            target = Math.max(0, Math.min(list.length - 1, target));
        if (target !== current)
            focusWorkspace(list[target].id);
    }

    Loader {
        id: loader
        source: CompositorService.isHyprland ? "backends/HyprlandBackend.qml" : ""
    }
}
