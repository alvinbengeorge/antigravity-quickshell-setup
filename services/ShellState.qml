pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Singleton {
    id: root

    property bool antigravityPanelOpen: false
    property bool sessionDialogOpen: false
    property bool launcherOpen: false
    property bool clipboardOpen: false
    property bool controlCenterOpen: false
    property bool desktopClockVisible: true
    property bool desktopAntigravityVisible: true
    property bool desktopPullRequestsVisible: true
    property bool use24Hour: false

    function toggleTimeFormat() {
        root.use24Hour = !root.use24Hour;
    }

    // Auto-detect system clock format preference (12h vs 24h)
    Process {
        id: clockFormatDetect
        running: true
        command: ["gsettings", "get", "org.gnome.desktop.interface", "clock-format"]
        stdout: StdioCollector {
            onStreamFinished: {
                const cleaned = text.trim().replace(/['"]/g, "");
                if (cleaned === "24h") {
                    root.use24Hour = true;
                } else if (cleaned === "12h") {
                    root.use24Hour = false;
                }
            }
        }
    }

    function toggleDesktopClock() {
        root.desktopClockVisible = !root.desktopClockVisible;
    }

    function toggleDesktopAntigravity() {
        root.desktopAntigravityVisible = !root.desktopAntigravityVisible;
    }

    function toggleDesktopPullRequests() {
        root.desktopPullRequestsVisible = !root.desktopPullRequestsVisible;
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
            root.clipboardOpen = false;
        }
    }

    function toggleClipboard() {
        root.clipboardOpen = !root.clipboardOpen;
        if (root.clipboardOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
            root.launcherOpen = false;
        }
    }

    function closeAll() {
        root.antigravityPanelOpen = false;
        root.sessionDialogOpen = false;
        root.launcherOpen = false;
        root.controlCenterOpen = false;
        root.clipboardOpen = false;
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
        function clipboardToggle(): void { root.toggleClipboard(); }
        function emojisToggle(): void { root.toggleLauncher(); }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.toggleClipboard(); }
        function show(): void { root.clipboardOpen = true; }
        function hide(): void { root.clipboardOpen = false; }
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
        function toggleFormat(): void { root.toggleTimeFormat(); }
        function set12(): void { root.use24Hour = false; }
        function set24(): void { root.use24Hour = true; }
    }

    IpcHandler {
        target: "antigravityWidget"
        function toggle(): void { root.toggleDesktopAntigravity(); }
        function show(): void { root.desktopAntigravityVisible = true; }
        function hide(): void { root.desktopAntigravityVisible = false; }
    }

    IpcHandler {
        target: "pullRequests"
        function toggle(): void { root.toggleDesktopPullRequests(); }
        function show(): void { root.desktopPullRequestsVisible = true; }
        function hide(): void { root.desktopPullRequestsVisible = false; }
    }

    IpcHandler {
        target: "theme"
        function next(): void { Theme.nextTheme(); }
        function prev(): void { Theme.prevTheme(); }
        function set(name: string): void { Theme.setTheme(name); }
        function cycleToggle(): void { Theme.autoCycle = !Theme.autoCycle; }
        function cycleOn(): void { Theme.autoCycle = true; }
        function cycleOff(): void { Theme.autoCycle = false; }
    }

    IpcHandler {
        target: "wallpaper"
        function next(): void { WallpaperService.nextWallpaper(); }
        function prev(): void { WallpaperService.prevWallpaper(); }
        function set(path: string): void { WallpaperService.setWallpaper(path); }
        function mode(newMode: string): void { WallpaperService.setMode(newMode); }
        function themeMode(): void { WallpaperService.setMode("theme"); }
        function gradientMode(): void { WallpaperService.setMode("gradient"); }
    }
}
