# Workspace Preview

A DankMaterialShell (DMS) bar widget that shows your workspaces as live thumbnails, with optional app icons.

## Features

- Live thumbnails of every workspace, composed from each window's own capture. Compositor animations such as workspace slides and three-finger swipes don't appear in the thumbnails. Layer surfaces aren't shown.
- Each monitor's DMS wallpaper is drawn behind the windows, using the same fill mode as DMS. Window borders are approximated from Hyprland's active and inactive border colours and size.
- Left-click a thumbnail to switch to that workspace.
- Workspaces with a window that needs attention (urgent) pulse a coloured border until you switch to them.
- Mouse wheel over the widget steps through workspaces (wheel up = previous, wheel down = next). Special workspaces are skipped.
- Optional special (scratchpad) workspaces, shown after the regular ones. Clicking one toggles it: shown when hidden, hidden when shown. Shown specials get a coloured border.
- Optional app icons per workspace, in four modes:
  - **Off**
  - **Overlap top edge**, **Overlap bottom edge**, **Overlap left edge** or **Overlap right edge**: icons sit centered on that edge, overlapping the thumbnail.
  - **Before thumbnail**
  - **After thumbnail**
- Icons are capped per workspace, with overflow shown as `+N`.

## Requirements

- DankMaterialShell 2.0 or newer.
- Hyprland. Other compositors are not implemented yet (see [Adding a compositor](#adding-a-compositor)).

## Settings

| Setting | Default | Description |
|---|---|---|
| Thumbnail sizing | Fit container | `Fit container` sizes thumbnails to fill the widget's content area inside its bar or dock pill (height on horizontal bars and docks, width on vertical bars). `Fixed height` uses the Thumbnail height setting. |
| Fill container | 100 | In Fit container mode, the percentage (50–100) of the bar or dock's thickness that thumbnails fill. |
| Thumbnail height | 24 | Height of each thumbnail in pixels (12–64). Used in Fixed height mode. |
| App icons | Overlap bottom edge | Off, overlap top, bottom, left or right edge, before thumbnail, or after thumbnail. |
| Icon size | 14 | Icon size in pixels (8–32). |
| Maximum icons per workspace | 4 | Extra apps collapse into a `+N` badge (1–10). |
| Wrap scrolling | On | Scrolling past the last workspace wraps to the first, and vice versa. |
| Hide empty workspaces | Off | Hide workspaces with no windows, unless focused or visible. |
| Show workspaces from all monitors | On | When off, only workspaces on this bar's monitor are shown. |
| Exclude reserved zones | On | Hide bars, docks and other edge panels from thumbnails, so only the usable workspace area is shown. |
| Add placeholder after last workspace | Off | Show a `+` thumbnail after the last workspace. Clicking it switches to a new workspace with the next id. Only shown when the last workspace has windows. |
| Show special workspaces | Off | Show special (scratchpad) workspaces after the placeholder, or after the last workspace if there is no placeholder. Clicking one toggles it shown or hidden. Wheel scrolling skips them. |
| Square highlight | Off | Draw the focus and visible-workspace outline as a sharp rectangle instead of rounded corners. |
| Show wallpaper | On | Draw each monitor's DMS wallpaper behind the windows in its thumbnail. |
| Show window borders | On | Draw an approximation of Hyprland's window borders around each window. |
| Flash urgent workspaces | On | Pulse a border on unfocused workspaces that have a window needing attention. The border clears when you switch to the workspace. |
| Urgent border colour | Red (`#ff0000`) | Colour of the flashing urgent border. |
| Visible special border colour | Gold (`#ffd700`) | Border colour for special workspaces that are currently shown. |

## Architecture

Compositor-specific code is isolated behind a single contract:

- `WorkspaceBackend.qml` selects a backend for the running compositor and exposes a common interface: `workspaces` (each with `key`, a `special` flag, `reserved` edge insets and an `urgent` flag), `decorations` (border width, rounding and colours), `focusWorkspace(key)`, and `scroll(step, wrap)`.
- `backends/HyprlandBackend.qml` implements that contract for Hyprland.
- `WorkspaceItem.qml`, `WorkspaceIcons.qml`, and `WorkspaceSwitcherWidget.qml` only use the common contract, so they work unchanged with any backend.

### Adding a compositor

1. Add `backends/<Name>Backend.qml` that provides the properties and functions described at the top of `WorkspaceBackend.qml`.
2. Add a branch to the `source` expression in `WorkspaceBackend.qml` that selects it.

## Limitations

- Hyprland only.
- Fit container sizes thumbnails from the widget's thickness on the bar or dock. The widget can't read the length of its section, so thumbnails in a long vertical stack are not shortened to fit the bar; use Fixed height mode if that matters.
- Thumbnails rely on Wayland screencopy, captured per window. With "Exclude reserved zones" on, windows and the wallpaper are offset so bars and docks are cropped out. Empty workspaces show their name.
- Window borders are approximations. Each border is drawn at least one device pixel wide, and drawn corners are square at thumbnail size. Shadows and blur are not drawn. Border colours and sizes are read when the widget loads and when Hyprland reloads its config.
- The wallpaper is taken from DMS. If another tool changes the wallpaper, the thumbnail follows DMS's setting, not the actual background. "Scrolling" fill mode is drawn as "Fill".