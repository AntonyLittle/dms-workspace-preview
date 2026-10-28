# Workspace Preview

A DankMaterialShell (DMS) bar widget that shows your workspaces as live thumbnails, with optional app icons.

## Features

- Live thumbnails of every workspace, composed from each window's own capture. Compositor animations such as workspace slides and three-finger swipes don't appear in the thumbnails. The wallpaper and layer surfaces aren't shown.
- Left-click a thumbnail to switch to that workspace.
- Mouse wheel over the widget steps through workspaces (wheel up = previous, wheel down = next).
- Optional app icons per workspace, in four modes:
  - **Off**
  - **Overlap thumbnail edge**: icons sit centered on the bottom edge, overlapping the thumbnail.
  - **Before thumbnail**
  - **After thumbnail**
- Icons are capped per workspace, with overflow shown as `+N`.

## Requirements

- DankMaterialShell 2.0 or newer.
- Hyprland. Other compositors are not implemented yet (see [Adding a compositor](#adding-a-compositor)).

## Install

Copy or symlink this directory into your DMS plugins folder:

```sh
ln -s "$PWD" ~/.config/dms/plugins/workspacePreview
```

Then add the **Workspace Preview** widget to a bar from the DMS bar settings.

Dock placement is not supported yet. The widget is built for bars only.

## Settings

| Setting | Default | Description |
|---|---|---|
| Thumbnail height | 24 | Height of each thumbnail in pixels (12–64). |
| App icons | Overlap thumbnail edge | Off, overlap thumbnail edge, before thumbnail, or after thumbnail. |
| Icon size | 14 | Icon size in pixels (8–32). |
| Maximum icons per workspace | 4 | Extra apps collapse into a `+N` badge (1–10). |
| Wrap scrolling | On | Scrolling past the last workspace wraps to the first, and vice versa. |
| Hide empty workspaces | Off | Hide workspaces with no windows, unless focused or visible. |
| Show workspaces from all monitors | On | When off, only workspaces on this bar's monitor are shown. |
| Exclude reserved zones | On | Hide bars, docks and other edge panels from thumbnails, so only the usable workspace area is shown. |
| Square highlight | Off | Draw the focus and visible-workspace outline as a sharp rectangle instead of rounded corners. |

## Architecture

Compositor-specific code is isolated behind a single contract:

- `WorkspaceBackend.qml` selects a backend for the running compositor and exposes a common interface: `workspaces` (each with `reserved` edge insets), `focusWorkspace(id)`, and `scroll(step, wrap)`.
- `backends/HyprlandBackend.qml` implements that contract for Hyprland.
- `WorkspaceItem.qml`, `WorkspaceIcons.qml`, and `WorkspaceSwitcherWidget.qml` only use the common contract, so they work unchanged with any backend.

### Adding a compositor

1. Add `backends/<Name>Backend.qml` that provides the properties and functions described at the top of `WorkspaceBackend.qml`.
2. Add a branch to the `source` expression in `WorkspaceBackend.qml` that selects it.

## Limitations

- Hyprland only.
- Thumbnails rely on Wayland screencopy, captured per window. With "Exclude reserved zones" on, windows are offset so bars and docks are cropped out. Empty workspaces show their name.