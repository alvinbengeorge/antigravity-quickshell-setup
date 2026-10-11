pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool antigravityPanelOpen: false
    property bool sessionDialogOpen: false
    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool desktopClockVisible: true
    property bool desktopAntigravityVisible: true

    function toggleDesktopClock() {
        root.desktopClockVisible = !root.desktopClockVisible;
    }

    function toggleDesktopAntigravity() {
        root.desktopAntigravityVisible = !root.desktopAntigravityVisible;
    }

    function toggleControlCenter() {
        root.controlCenterOpen = !root.controlCenterOpen;
        if (root.controlCenterOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.launcherOpen = false;
            NetworkService.refresh();
        }
    }

    function toggleAntigravityPanel() {
        root.antigravityPanelOpen = !root.antigravityPanelOpen;
        if (root.antigravityPanelOpen) {
            root.sessionDialogOpen = false;
            root.launcherOpen = false;
            root.controlCenterOpen = false;
        }
    }

    function toggleSessionDialog() {
        root.sessionDialogOpen = !root.sessionDialogOpen;
        if (root.sessionDialogOpen) {
            root.antigravityPanelOpen = false;
            root.launcherOpen = false;
            root.controlCenterOpen = false;
        }
    }

    function toggleLauncher() {
        root.launcherOpen = !root.launcherOpen;
        if (root.launcherOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
        }
    }

    function closeAll() {
        root.antigravityPanelOpen = false;
        root.sessionDialogOpen = false;
        root.launcherOpen = false;
        root.controlCenterOpen = false;
    }

    // Hyprland / CLI IPC Handlers
    IpcHandler {
        target: "antigravity"
        function toggle(): void { root.toggleAntigravityPanel(); }
        function show(): void { root.antigravityPanelOpen = true; }
        function hide(): void { root.antigravityPanelOpen = false; }
    }

    IpcHandler {
        target: "search"
        function toggle(): void { root.toggleLauncher(); }
        function workspacesToggle(): void { root.toggleLauncher(); }
        function keybindsToggle(): void { root.toggleLauncher(); }
        function clipboardToggle(): void { root.toggleLauncher(); }
        function emojisToggle(): void { root.toggleLauncher(); }
    }

    IpcHandler {
        target: "controlCenter"
        function toggle(): void { root.toggleControlCenter(); }
        function show(): void { root.controlCenterOpen = true; }
        function hide(): void { root.controlCenterOpen = false; }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { root.toggleSessionDialog(); }
    }

    IpcHandler {
        target: "sidebarLeft"
        function toggle(): void { root.toggleAntigravityPanel(); }
    }

    IpcHandler {
        target: "sidebarRight"
        function toggle(): void { root.toggleAntigravityPanel(); }
    }

    IpcHandler {
        target: "island"
        function toggle(): void { root.toggleAntigravityPanel(); }
    }

    IpcHandler {
        target: "clock"
        function toggle(): void { root.toggleDesktopClock(); }
        function show(): void { root.desktopClockVisible = true; }
        function hide(): void { root.desktopClockVisible = false; }
    }

    IpcHandler {
        target: "antigravityWidget"
        function toggle(): void { root.toggleDesktopAntigravity(); }
        function show(): void { root.desktopAntigravityVisible = true; }
        function hide(): void { root.desktopAntigravityVisible = false; }
    }
}
