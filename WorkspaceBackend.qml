import QtQuick
import qs.Services

// Compositor-agnostic workspace source. Picks a backend for the running compositor.
//
// Backend contract (each file in backends/ must provide):
//   readonly property var workspaces   list of workspace entries. Regular workspaces come
//                                      first, sorted by id; special workspaces follow.
//       id            number   compositor workspace id (null for special workspaces)
//       key           string   unique, stable identifier used to focus the workspace
//       name          string   display name
//       special       bool     workspace is a special (scratchpad-style) workspace
//       outputName    string   output (monitor) name the workspace lives on
//       screen        object   Quickshell screen for outputName (may be null)
//       outputX/outputY/outputW/outputH  output geometry in logical px
//       reserved      object { left, top, right, bottom } edge insets in logical px
//                     claimed by exclusive layer surfaces (bars, docks)
//       focused       bool     workspace is the globally focused one
//       onVisibleSpace bool    workspace is the active one on its output
//       urgent        bool     a window on the workspace is requesting attention
//       windows       list of { address, wayland, appId, x, y, w, h, floating, active }
//                     address is a stable compositor id for the window
//                     x/y are relative to the output origin, logical px
//                     active is true for the globally focused window
//   readonly property var decorations  window decoration settings, logical px:
//       borderWidth   number   border thickness (0 when borders are off)
//       rounding      number   corner radius
//       activeColor   string   "#AARRGGBB" border colour for the active window
//       inactiveColor string   "#AARRGGBB" border colour for other windows
//   function focusWorkspace(key)  activate the workspace with this key; a special is toggled
//                                 (shown or hidden), a regular workspace is focused
//   function focusedIndex()       index of the focused workspace in workspaces, or -1
Item {
    id: root

    property string outputFilter: ""

    readonly property var allWorkspaces: loader.item ? loader.item.workspaces : []
    readonly property var workspaces: outputFilter === "" ? allWorkspaces
        : allWorkspaces.filter(ws => ws.outputName === outputFilter)
    readonly property bool available: loader.item !== null
    readonly property var decorations: loader.item ? loader.item.decorations
        : ({ borderWidth: 0, rounding: 0, activeColor: "", inactiveColor: "" })

    function focusWorkspace(key) {
        if (loader.item)
            loader.item.focusWorkspace(key);
    }

    Loader {
        id: loader
        source: CompositorService.isHyprland ? "backends/HyprlandBackend.qml" : ""
    }
}
