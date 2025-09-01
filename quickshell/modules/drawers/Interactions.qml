import "root:/services"
import "root:/config"
import "root:/modules/bar/popouts" as BarPopouts
import "root:/modules/osd" as Osd
import Quickshell
import QtQuick

MouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property PersistentProperties visibilities
    required property Panels panels
    required property Item bar

    property bool osdHovered
    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive
    property bool utilitiesShortcutActive
    property bool dockShortcutActive

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = Config.border.thickness + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const panelX = bar.implicitWidth + panel.x;
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > bar.implicitWidth + panel.x && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, x: real, y: real): bool {
        return y < Config.border.thickness + panel.y + panel.height && withinPanelWidth(panel, x, y);
    }

    function inBottomPanel(panel: Item, x: real, y: real): bool {
        return y > root.height - Config.border.thickness - panel.height - Config.border.rounding && withinPanelWidth(panel, x, y);
    }

    function inBottomCenterDock(x: real, y: real): bool {
        const dockWidth = panels.dock.implicitWidth || 200; // fallback width
        const centerX = root.width / 2;
        const dockLeft = centerX - dockWidth / 2;
        const dockRight = centerX + dockWidth / 2;
        
        // If dock is visible, include its actual area plus hover zone
        // If dock is hidden, just use bottom hover zone
        const dockHeight = panels.dock.implicitHeight || 0;
        const launcherHeight = panels.launcher.height || 0;
        const bottomMargin = launcherHeight + Config.border.rounding;
        const hoverZoneHeight = 60;
        
        const dockTop = visibilities.dock 
            ? root.height - bottomMargin - dockHeight - hoverZoneHeight
            : root.height - Config.border.thickness - hoverZoneHeight;
        
        return x >= dockLeft && x <= dockRight && y >= dockTop;
    }

    anchors.fill: parent
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                visibilities.osd = false;
                osdHovered = false;
            }
            if (!dashboardShortcutActive) {
                visibilities.dashboard = false;
            }
            if (!utilitiesShortcutActive) {
                visibilities.utilities = false;
            }
            if (!dockShortcutActive) {
                visibilities.dock = false;
            }
            popouts.hasCurrent = false;

            if (Config.bar.showOnHover)
                bar.isHovered = false;
        }
    }

    onPositionChanged: event => {
        const x = event.x;
        const y = event.y;

        // Show bar in non-exclusive mode on hover
        if (!visibilities.bar && Config.bar.showOnHover && x < bar.implicitWidth) {
            bar.isHovered = true;
        }

        // Show/hide bar on drag
        if (pressed && dragStart.x < bar.implicitWidth) {
            const dragX = x - dragStart.x;
            if (dragX > Config.bar.dragThreshold) {
                visibilities.bar = true;
            } else if (dragX < -Config.bar.dragThreshold) {
                visibilities.bar = false;
            }
        }

        // Show osd on hover
        const showOsd = inRightPanel(panels.osd, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!osdShortcutActive) {
            visibilities.osd = showOsd;
            osdHovered = showOsd;
        } else if (showOsd) {
            // If hovering over OSD area while in shortcut mode, transition to hover control
            osdShortcutActive = false;
            osdHovered = true;
        }

        // Show/hide session on drag
        if (pressed && inRightPanel(panels.session, dragStart.x, dragStart.y) && withinPanelHeight(panels.session, x, y)) {
            const dragX = x - dragStart.x;
            if (dragX < -Config.session.dragThreshold)
                visibilities.session = true;
            else if (dragX > Config.session.dragThreshold)
                visibilities.session = false;
        }

        // Show/hide launcher on drag
        if (pressed && inBottomPanel(panels.launcher, dragStart.x, dragStart.y) && withinPanelWidth(panels.launcher, x, y)) {
            const dragY = y - dragStart.y;
            if (dragY < -Config.launcher.dragThreshold)
                visibilities.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                visibilities.launcher = false;
        }

        // Show dashboard on hover
        const showDashboard = inTopPanel(panels.dashboard, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!dashboardShortcutActive) {
            visibilities.dashboard = showDashboard;
        } else if (showDashboard) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control
            dashboardShortcutActive = false;
        }

        // Show utilities on hover
        const showUtilities = inBottomPanel(panels.utilities, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!utilitiesShortcutActive) {
            visibilities.utilities = showUtilities;
        } else if (showUtilities) {
            // If hovering over utilities area while in shortcut mode, transition to hover control
            utilitiesShortcutActive = false;
        }

        // Show dock on hover
        const showDock = inBottomCenterDock(x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!dockShortcutActive) {
            visibilities.dock = showDock;
        } else if (showDock) {
            // If hovering over dock area while in shortcut mode, transition to hover control
            dockShortcutActive = false;
        }

        // Show popouts on hover
        const popout = panels.popouts;
        if (x < bar.implicitWidth + popout.width) {
            if (x < bar.implicitWidth)
                // Handle like part of bar
                bar.checkPopout(y);
            else
                // Keep on hover
                popouts.hasCurrent = withinPanelHeight(popout, x, y);
        } else
            popouts.hasCurrent = false;
    }

    // Monitor individual visibility changes
    Connections {
        target: root.visibilities

        function onLauncherChanged() {
            // If launcher is hidden, clear shortcut flags for dashboard, OSD, and dock
            if (!root.visibilities.launcher) {
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;
                root.utilitiesShortcutActive = false;
                root.dockShortcutActive = false;

                // Also hide dashboard, OSD, and dock if they're not being hovered
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                const inOsdArea = root.inRightPanel(root.panels.osd, root.mouseX, root.mouseY);
                const inDockArea = root.inBottomCenterDock(root.mouseX, root.mouseY);

                if (!inDashboardArea) {
                    root.visibilities.dashboard = false;
                }
                if (!inOsdArea) {
                    root.visibilities.osd = false;
                    root.osdHovered = false;
                }
                if (!inDockArea) {
                    root.visibilities.dock = false;
                }
            }
        }

        function onDashboardChanged() {
            if (root.visibilities.dashboard) {
                // Dashboard became visible, immediately check if this should be shortcut mode
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                if (!inDashboardArea) {
                    root.dashboardShortcutActive = true;
                }
            } else {
                // Dashboard hidden, clear shortcut flag
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.visibilities.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inRightPanel(root.panels.osd, root.mouseX, root.mouseY);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        function onUtilitiesChanged() {
            if (root.visibilities.utilities) {
                // Utilities became visible, immediately check if this should be shortcut mode
                const inUtilitiesArea = root.inBottomPanel(root.panels.utilities, root.mouseX, root.mouseY);
                if (!inUtilitiesArea) {
                    root.utilitiesShortcutActive = true;
                }
            } else {
                // Utilities hidden, clear shortcut flag
                root.utilitiesShortcutActive = false;
            }
        }

        function onDockChanged() {
            if (root.visibilities.dock) {
                // Dock became visible, immediately check if this should be shortcut mode
                const inDockArea = root.inBottomCenterDock(root.mouseX, root.mouseY);
                if (!inDockArea) {
                    root.dockShortcutActive = true;
                }
            } else {
                // Dock hidden, clear shortcut flag
                root.dockShortcutActive = false;
            }
        }
    }

    Osd.Interactions {
        screen: root.screen
        visibilities: root.visibilities
        hovered: root.osdHovered
    }
}
