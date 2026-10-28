import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "workspacePreview"

    SliderSetting {
        settingKey: "thumbnailHeight"
        label: I18n.tr("Thumbnail height")
        description: I18n.tr("Height of each workspace thumbnail in pixels.")
        defaultValue: 24
        minimum: 12
        maximum: 64
    }

    SelectionSetting {
        settingKey: "iconMode"
        label: I18n.tr("App icons")
        description: I18n.tr("Where app icons appear relative to each thumbnail.")
        defaultValue: "anchored"
        options: [
            { label: I18n.tr("Off"), value: "off" },
            { label: I18n.tr("Overlap thumbnail edge"), value: "anchored" },
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
        description: I18n.tr("Scrolling past the last workspace continues from the first, and vice versa.")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "hideEmpty"
        label: I18n.tr("Hide empty workspaces")
        description: I18n.tr("Hide workspaces that have no windows, unless they are focused or visible.")
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "showAllMonitors"
        label: I18n.tr("Show workspaces from all monitors")
        description: I18n.tr("When off, only workspaces on the monitor this bar is on are shown.")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "excludeReservedZones"
        label: I18n.tr("Exclude reserved zones")
        description: I18n.tr("Hide bars, docks and other edge panels from thumbnails so only the usable workspace area is shown.")
        defaultValue: true
    }
}
