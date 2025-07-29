pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/services"
import "root:/config"
import Quickshell
import QtQuick

StyledRect {
    id: root

    required property PersistentProperties visibilities

    implicitWidth: row.implicitWidth + Config.border.rounding * 2
    implicitHeight: row.implicitHeight + Config.border.rounding * 2

    color: Colours.palette.m3surfaceContainer
    radius: Config.border.rounding

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Config.border.rounding

        // Steam
        AppIcon {
            iconName: "steam"
            appName: "Steam"
            command: ["steam"]
        }

        // Firefox
        AppIcon {
            iconName: "firefox"
            appName: "Firefox"
            command: ["firefox"]
        }

        // Thunar (File Manager)
        AppIcon {
            iconName: "folder"
            appName: "Files"
            command: ["thunar"]
        }

        // Volume Control
        AppIcon {
            iconName: "volume_up"
            appName: "Volume"
            command: ["pavucontrol"]
        }
    }
}