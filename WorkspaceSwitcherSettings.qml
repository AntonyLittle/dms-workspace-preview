import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "workspacePreview"

    readonly property var colourTokenOptions: [
        { label: I18n.tr("Primary"), value: "primary" },
        { label: I18n.tr("Secondary"), value: "secondary" },
        { label: I18n.tr("Tertiary"), value: "tertiary" },
        { label: I18n.tr("Error"), value: "error" },
        { label: I18n.tr("Outline"), value: "outline" }
    ]

    SelectionSetting {
        settingKey: "sizeMode"
        label: I18n.tr("Thumbnail sizing")
        description: I18n.tr("Fit container sizes thumbnails from the bar or dock they are in. Fixed height uses the height below.")
        defaultValue: "fit"
        options: [
            { label: I18n.tr("Fit container"), value: "fit" },
            { label: I18n.tr("Fixed height"), value: "fixed" }
        ]
    }

    SliderSetting {
        settingKey: "fillPercent"
        label: I18n.tr("Fill container")
        description: I18n.tr("In Fit container mode, the share of the bar or dock's thickness that thumbnails fill.")
        defaultValue: 100
        minimum: 50
        maximum: 100
    }

    SliderSetting {
        settingKey: "thumbnailHeight"
        label: I18n.tr("Thumbnail height")
        description: I18n.tr("Height of each workspace thumbnail in pixels. Used in Fixed height mode.")
        defaultValue: 24
        minimum: 12
        maximum: 64
    }

    SelectionSetting {
        settingKey: "hoverMode"
        label: I18n.tr("Hover behaviour")
        description: I18n.tr("Choose what happens when the pointer rests over a workspace thumbnail.")
        defaultValue: "none"
        options: [
            { label: I18n.tr("None"), value: "none" },
            { label: I18n.tr("Popout preview"), value: "popout" },
            { label: I18n.tr("Dock magnification"), value: "magnify" }
        ]
    }

    SliderSetting {
        settingKey: "hoverSize"
        label: I18n.tr("Hover thumbnail size")
        description: I18n.tr("Height in pixels of the enlarged preview or the largest magnified thumbnail.")
        defaultValue: 120
        minimum: 48
        maximum: 400
    }

    SliderSetting {
        settingKey: "hoverDelay"
        label: I18n.tr("Hover delay")
        description: I18n.tr("Time before the popout preview appears or switches to another workspace.")
        defaultValue: 120
        minimum: 0
        maximum: 500
    }

    SelectionSetting {
        settingKey: "iconMode"
        label: I18n.tr("App icons")
        description: I18n.tr("Where app icons appear relative to each thumbnail.")
        defaultValue: "bottom"
        options: [
            { label: I18n.tr("Off"), value: "off" },
            { label: I18n.tr("Overlap top edge"), value: "top" },
            { label: I18n.tr("Overlap bottom edge"), value: "bottom" },
            { label: I18n.tr("Overlap left edge"), value: "left" },
            { label: I18n.tr("Overlap right edge"), value: "right" },
            { label: I18n.tr("Before thumbnail"), value: "before" },
            { label: I18n.tr("After thumbnail"), value: "after" }
        ]
    }

    SliderSetting {
        settingKey: "iconSize"
        label: I18n.tr("Icon size")
        description: I18n.tr("Size of app icons in pixels.")
        defaultValue: 14
        minimum: 8
        maximum: 32
    }

    SliderSetting {
        settingKey: "maxIcons"
        label: I18n.tr("Maximum icons per workspace")
        description: I18n.tr("Extra apps are collapsed into a +N badge.")
        defaultValue: 4
        minimum: 1
        maximum: 10
    }

    ToggleSetting {
        settingKey: "wrapScroll"
        label: I18n.tr("Wrap scrolling")
        description: I18n.tr("Scrolling past the last thumbnail continues from the first workspace. Scrolling back past the first continues from the last workspace, skipping the placeholder.")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "hideEmpty"
        label: I18n.tr("Hide empty workspaces")
        description: I18n.tr("Hide workspaces that have no windows, unless they are focused or visible.")
        defaultValue: false
    }

    ToggleSetting {
        id: showAllMonitors
        settingKey: "showAllMonitors"
        label: I18n.tr("Show workspaces from all monitors")
        description: I18n.tr("When off, only workspaces on the monitor this bar is on are shown.")
        defaultValue: true
    }

    ToggleSetting {
        id: groupByOutput
        settingKey: "groupByOutput"
        label: I18n.tr("Group workspaces by monitor")
        description: I18n.tr("Show each monitor's workspaces together in physical order, with a separator between groups. Each group gets its own placeholder, and special workspaces form a final group.")
        visible: showAllMonitors.value
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "thisOutputFirst"
        label: I18n.tr("This monitor's group first")
        description: I18n.tr("Put the group for the monitor this bar is on at the start.")
        visible: showAllMonitors.value && groupByOutput.value
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "dimOtherOutputs"
        label: I18n.tr("Dim other monitors' workspaces")
        description: I18n.tr("Fade workspaces that are on a different monitor from this bar.")
        visible: showAllMonitors.value
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "scrollThisOutput"
        label: I18n.tr("Scroll only this monitor's workspaces")
        description: I18n.tr("Wheel scrolling only moves between workspaces on the monitor this bar is on.")
        visible: showAllMonitors.value
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "excludeReservedZones"
        label: I18n.tr("Exclude reserved zones")
        description: I18n.tr("Hide bars, docks and other edge panels from thumbnails so only the usable workspace area is shown.")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "trailingPlaceholder"
        label: I18n.tr("Add placeholder after last workspace")
        description: I18n.tr("Show a \"+\" thumbnail after the last workspace that adds a new one when clicked or scrolled onto. Only shown when the last workspace has windows.")
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "showSpecialWorkspaces"
        label: I18n.tr("Show special workspaces")
        description: I18n.tr("Show special (scratchpad) workspaces after the regular ones. Clicking one toggles it shown or hidden; wheel scrolling skips them.")
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "squareHighlight"
        label: I18n.tr("Square highlight")
        description: I18n.tr("Draw the focus and visible-workspace outline as a sharp rectangle instead of rounded corners.")
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "showWallpaper"
        label: I18n.tr("Show wallpaper")
        description: I18n.tr("Draw each monitor's DMS wallpaper behind the windows in its thumbnail.")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showDecorations"
        label: I18n.tr("Show window borders")
        description: I18n.tr("Draw an approximation of Hyprland's window borders around each window in its thumbnail.")
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "thumbnailShadow"
        label: I18n.tr("Thumbnail shadow")
        description: I18n.tr("Drop shadow under each thumbnail and the popout preview. It lifts on hover or magnification. Colour, intensity and direction follow the DMS shadow settings, and shadows are hidden when DMS shadows are off.")
        defaultValue: "off"
        options: [
            { label: I18n.tr("Off"), value: "off" },
            { label: I18n.tr("Subtle"), value: "subtle" },
            { label: I18n.tr("Medium"), value: "medium" },
            { label: I18n.tr("Strong"), value: "strong" }
        ]
    }

    ToggleSetting {
        settingKey: "flashUrgent"
        label: I18n.tr("Flash urgent workspaces")
        description: I18n.tr("Pulse a border on workspaces with a window that needs attention, until you switch to that workspace.")
        defaultValue: true
    }

    SelectionSetting {
        id: urgentSource
        settingKey: "urgentSource"
        label: I18n.tr("Urgent border colour source")
        description: I18n.tr("Use a theme colour or a custom colour for the flashing urgent border.")
        defaultValue: "custom"
        options: [
            { label: I18n.tr("Theme colour"), value: "theme" },
            { label: I18n.tr("Custom colour"), value: "custom" }
        ]
    }

    SelectionSetting {
        settingKey: "urgentThemeColor"
        label: I18n.tr("Urgent border theme colour")
        description: I18n.tr("Theme colour used for the flashing urgent border.")
        visible: urgentSource.value === "theme"
        defaultValue: "error"
        options: colourTokenOptions
    }

    ColorSetting {
        settingKey: "urgentColor"
        label: I18n.tr("Urgent border colour")
        description: I18n.tr("Custom colour of the flashing border on workspaces that need attention.")
        visible: urgentSource.value === "custom"
        defaultValue: "#ff0000"
    }

    SelectionSetting {
        id: specialSource
        settingKey: "specialSource"
        label: I18n.tr("Visible special border colour source")
        description: I18n.tr("Use a theme colour or a custom colour for the border of shown special workspaces.")
        defaultValue: "custom"
        options: [
            { label: I18n.tr("Theme colour"), value: "theme" },
            { label: I18n.tr("Custom colour"), value: "custom" }
        ]
    }

    SelectionSetting {
        settingKey: "specialThemeColor"
        label: I18n.tr("Visible special theme colour")
        description: I18n.tr("Theme colour of the border on special workspaces that are currently shown.")
        visible: specialSource.value === "theme"
        defaultValue: "tertiary"
        options: colourTokenOptions
    }

    ColorSetting {
        settingKey: "specialColor"
        label: I18n.tr("Visible special border colour")
        description: I18n.tr("Custom colour of the border on special workspaces that are currently shown.")
        visible: specialSource.value === "custom"
        defaultValue: "#ffd700"
    }

    SelectionSetting {
        id: focusSource
        settingKey: "focusSource"
        label: I18n.tr("Focus border colour source")
        description: I18n.tr("Use a theme colour or a custom colour for the focused workspace outline.")
        defaultValue: "theme"
        options: [
            { label: I18n.tr("Theme colour"), value: "theme" },
            { label: I18n.tr("Custom colour"), value: "custom" }
        ]
    }

    SelectionSetting {
        settingKey: "focusThemeColor"
        label: I18n.tr("Focus border theme colour")
        description: I18n.tr("Theme colour of the focused workspace outline.")
        visible: focusSource.value === "theme"
        defaultValue: "primary"
        options: colourTokenOptions
    }

    ColorSetting {
        settingKey: "focusColor"
        label: I18n.tr("Focus border colour")
        description: I18n.tr("Custom colour of the focused workspace outline.")
        visible: focusSource.value === "custom"
        defaultValue: Theme.primary
    }
}
