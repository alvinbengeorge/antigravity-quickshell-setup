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
    property bool omnibarOpen: false
    property string omnibarInitialQuery: ""
    property bool clipboardOpen: false
    property bool controlCenterOpen: false
    property bool wallpaperThemeDialogOpen: false
    property string wallpaperThemeTab: "wallpapers"
    property bool dockerOpen: false
    property bool runnerOpen: false
    property bool windowSwitcherOpen: false
    property bool whatsappOpen: false
    property bool pieMenuOpen: false
    property int pieInitialSlice: -1
    property bool systemMonitorOpen: false
    property bool mediaCardOpen: false
    property bool workspacePreviewOpen: false
    property bool workspacePreviewHovered: false
    property int hoveredWorkspace: 0
    property real hoveredWorkspaceGlobalX: 16
    property string systemMonitorInitialTab: "ram"
    property bool desktopClockVisible: true
    property bool desktopAntigravityVisible: true
    property bool desktopPullRequestsVisible: true
    property bool desktopJiraVisible: true
    property real antigravityWidgetHeight: 496
    property bool use24Hour: false
    property bool clockShowCalendar: true
    property string fontPreset: "cupertino"
    property bool skyboxEnabled: false
    property bool dockEnabled: true
    property bool dockAutoHide: false
    property bool liteMode: false
    property bool plasticMode: true
    property alias glassButtons: root.plasticMode
    readonly property bool plasticEnabled: plasticMode && !liteMode
    readonly property alias glassEnabled: root.plasticEnabled

    // ── Settings persistence ──────────────────────────────────────────────
    readonly property string shellSettingsPath: Quickshell.env("HOME") + "/.local/state/quickshell/user/shell-settings.json"

    // Save whenever relevant settings change
    onLiteModeChanged: {
        if (root.liteMode) {
            Quickshell.execDetached(["systemctl", "--user", "stop", "antigravity-remote"]);
            Quickshell.execDetached(["pkill", "-f", "audio_beat_tracker.py"]);
        } else {
            Quickshell.execDetached(["systemctl", "--user", "start", "antigravity-remote"]);
        }
        Qt.callLater(root.saveShellSettings);
    }
    onUse24HourChanged:         Qt.callLater(root.saveShellSettings)
    onClockShowCalendarChanged: Qt.callLater(root.saveShellSettings)
    onGlassButtonsChanged:      Qt.callLater(root.saveShellSettings)
    onSkyboxEnabledChanged:     Qt.callLater(root.saveShellSettings)
    onDockEnabledChanged:       Qt.callLater(root.saveShellSettings)
    onDockAutoHideChanged:      Qt.callLater(root.saveShellSettings)
    onFontPresetChanged: {
        Theme.fontPreset = root.fontPreset;
        Qt.callLater(root.saveShellSettings);
    }

    function saveShellSettings() {
        const payload = JSON.stringify({
            liteMode: root.liteMode,
            use24Hour: root.use24Hour,
            showCalendar: root.clockShowCalendar,
            glassButtons: root.glassButtons,
            fontPreset: root.fontPreset,
            skyboxEnabled: root.skyboxEnabled,
            dockEnabled: root.dockEnabled,
            dockAutoHide: root.dockAutoHide
        }, null, 2);
        Quickshell.execDetached([
            "python3",
            "-c",
            "import sys, os; os.makedirs(os.path.dirname(sys.argv[1]), exist_ok=True); open(sys.argv[1], 'w').write(sys.argv[2])",
            root.shellSettingsPath,
            payload
        ]);
    }

    // Load on startup
    Process {
        id: shellSettingsLoader
        running: true
        command: ["cat", root.shellSettingsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const raw = text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        if (typeof data.liteMode === "boolean")     root.liteMode = data.liteMode;
                        if (typeof data.use24Hour === "boolean")    root.use24Hour = data.use24Hour;
                        if (typeof data.showCalendar === "boolean") root.clockShowCalendar = data.showCalendar;
                        if (typeof data.glassButtons === "boolean") root.glassButtons = data.glassButtons;
                        if (typeof data.fontPreset === "string")   root.fontPreset = data.fontPreset;
                        if (typeof data.skyboxEnabled === "boolean") root.skyboxEnabled = data.skyboxEnabled;
                        if (typeof data.dockEnabled === "boolean")   root.dockEnabled = data.dockEnabled;
                        if (typeof data.dockAutoHide === "boolean")  root.dockAutoHide = data.dockAutoHide;
                    }
                } catch (e) { /* first run or corrupt – use defaults */ }
            }
        }
    }
    // ─────────────────────────────────────────────────────────────────────

    function toggleLiteMode() {
        root.liteMode = !root.liteMode;
        Quickshell.execDetached([
            "notify-send",
            "-a", "Antigravity",
            root.liteMode ? "Lite Mode Active" : "Standard Mode Active",
            root.liteMode ? "Desktop widgets unloaded, animations stopped. Max graphics performance enabled." : "Desktop widgets and full visual effects restored."
        ]);
    }

    function togglePlasticMode() {
        root.plasticMode = !root.plasticMode;
        Quickshell.execDetached([
            "notify-send",
            "-a", "Antigravity",
            root.plasticMode ? "Apple Plastic Mode Active" : "Flat Style Active",
            root.plasticMode ? "Translucent glossy plastic shaders and depth curvature enabled." : "Standard flat interface mode active."
        ]);
    }

    function setPlasticMode(val: bool) {
        if (root.plasticMode === val) return;
        root.plasticMode = val;
        Quickshell.execDetached([
            "notify-send",
            "-a", "Antigravity",
            root.plasticMode ? "Apple Plastic Mode Active" : "Flat Style Active",
            root.plasticMode ? "Translucent glossy plastic shaders and depth curvature enabled." : "Standard flat interface mode active."
        ]);
    }

    function toggleGlassButtons() {
        root.togglePlasticMode();
    }

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

    function toggleDesktopJira() {
        root.desktopJiraVisible = !root.desktopJiraVisible;
    }

    function toggleControlCenter() {
        root.controlCenterOpen = !root.controlCenterOpen;
        if (root.controlCenterOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.launcherOpen = false;
            root.dockerOpen = false;
            NetworkService.refresh();
        }
    }

    function toggleAntigravityPanel() {
        root.antigravityPanelOpen = !root.antigravityPanelOpen;
        if (root.antigravityPanelOpen) {
            root.sessionDialogOpen = false;
            root.launcherOpen = false;
            root.controlCenterOpen = false;
            root.dockerOpen = false;
        }
    }

    function toggleSessionDialog() {
        root.sessionDialogOpen = !root.sessionDialogOpen;
        if (root.sessionDialogOpen) {
            root.antigravityPanelOpen = false;
            root.launcherOpen = false;
            root.controlCenterOpen = false;
            root.dockerOpen = false;
        }
    }

    function toggleLauncher() {
        root.launcherOpen = !root.launcherOpen;
        if (root.launcherOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
            root.clipboardOpen = false;
            root.dockerOpen = false;
            root.omnibarOpen = false;
        }
    }

    function toggleOmnibar() {
        root.omnibarOpen = !root.omnibarOpen;
        if (root.omnibarOpen) {
            root.closeAll();
            root.omnibarOpen = true;
        }
    }

    function toggleClipboard() {
        root.clipboardOpen = !root.clipboardOpen;
        if (root.clipboardOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
            root.launcherOpen = false;
            root.wallpaperThemeDialogOpen = false;
            root.dockerOpen = false;
        }
    }

    function toggleWallpaperThemeDialog() {
        root.wallpaperThemeDialogOpen = !root.wallpaperThemeDialogOpen;
        if (root.wallpaperThemeDialogOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
            root.launcherOpen = false;
            root.clipboardOpen = false;
            root.dockerOpen = false;
        }
    }

    function toggleDocker() {
        root.dockerOpen = !root.dockerOpen;
        if (root.dockerOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
            root.launcherOpen = false;
            root.clipboardOpen = false;
            root.wallpaperThemeDialogOpen = false;
            root.runnerOpen = false;
            root.windowSwitcherOpen = false;
            DockerService.refresh();
        }
    }

    function toggleRunner() {
        root.runnerOpen = !root.runnerOpen;
        if (root.runnerOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
            root.launcherOpen = false;
            root.clipboardOpen = false;
            root.wallpaperThemeDialogOpen = false;
            root.dockerOpen = false;
            root.windowSwitcherOpen = false;
            TaskRunnerService.refresh();
        }
    }

    function toggleWindowSwitcher() {
        root.windowSwitcherOpen = !root.windowSwitcherOpen;
        if (root.windowSwitcherOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
            root.launcherOpen = false;
            root.clipboardOpen = false;
            root.wallpaperThemeDialogOpen = false;
            root.dockerOpen = false;
            root.runnerOpen = false;
            root.whatsappOpen = false;
            WindowService.refresh();
        }
    }

    function toggleWhatsApp() {
        root.whatsappOpen = !root.whatsappOpen;
        if (root.whatsappOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.controlCenterOpen = false;
            root.launcherOpen = false;
            root.clipboardOpen = false;
            root.wallpaperThemeDialogOpen = false;
            root.dockerOpen = false;
            root.runnerOpen = false;
            root.windowSwitcherOpen = false;
            root.systemMonitorOpen = false;
            WhatsAppService.refresh();
        }
    }

    function toggleSystemMonitor(initialTab) {
        if (root.systemMonitorOpen && (!initialTab || root.systemMonitorInitialTab === initialTab)) {
            root.systemMonitorOpen = false;
        } else {
            root.closeAll();
            if (initialTab) root.systemMonitorInitialTab = initialTab;
            root.systemMonitorOpen = true;
        }
    }

    function closeAll() {
        root.antigravityPanelOpen = false;
        root.sessionDialogOpen = false;
        root.launcherOpen = false;
        root.omnibarOpen = false;
        root.controlCenterOpen = false;
        root.clipboardOpen = false;
        root.wallpaperThemeDialogOpen = false;
        root.dockerOpen = false;
        root.runnerOpen = false;
        root.windowSwitcherOpen = false;
        root.whatsappOpen = false;
        root.systemMonitorOpen = false;
        root.mediaCardOpen = false;
        root.pieMenuOpen = false;
    }

    function togglePieMenu() {
        root.pieMenuOpen = !root.pieMenuOpen;
        if (root.pieMenuOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.launcherOpen = false;
            root.omnibarOpen = false;
            root.controlCenterOpen = false;
            root.clipboardOpen = false;
            root.wallpaperThemeDialogOpen = false;
            root.dockerOpen = false;
            root.runnerOpen = false;
            root.windowSwitcherOpen = false;
            root.whatsappOpen = false;
            root.systemMonitorOpen = false;
            root.mediaCardOpen = false;
        }
    }

    function toggleMediaCard() {
        root.mediaCardOpen = !root.mediaCardOpen;
        if (root.mediaCardOpen) {
            root.antigravityPanelOpen = false;
            root.sessionDialogOpen = false;
            root.launcherOpen = false;
            root.omnibarOpen = false;
            root.controlCenterOpen = false;
            root.clipboardOpen = false;
        }
    }

    function toggleDock() {
        root.dockEnabled = !root.dockEnabled;
    }

    // Hyprland / CLI IPC Handlers
    IpcHandler {
        target: "dock"
        function toggle(): void { root.toggleDock(); }
        function enable(): void { root.dockEnabled = true; }
        function disable(): void { root.dockEnabled = false; }
        function status(): string { return root.dockEnabled ? "enabled" : "disabled"; }
    }
    IpcHandler {
        target: "plastic"
        function toggle(): void { root.togglePlasticMode(); }
        function enable(): void { root.setPlasticMode(true); }
        function disable(): void { root.setPlasticMode(false); }
        function status(): string { return root.plasticMode ? "enabled" : "disabled"; }
    }

    IpcHandler {
        target: "glass"
        function toggle(): void { root.togglePlasticMode(); }
        function enable(): void { root.setPlasticMode(true); }
        function disable(): void { root.setPlasticMode(false); }
        function status(): string { return root.plasticMode ? "enabled" : "disabled"; }
    }

    IpcHandler {
        target: "omnibar"
        function toggle(): void { root.toggleOmnibar(); }
        function show(): void { root.closeAll(); root.omnibarOpen = true; }
        function hide(): void { root.omnibarOpen = false; }
        function query(val: string): void { root.closeAll(); root.omnibarInitialQuery = val; root.omnibarOpen = true; }
    }

    IpcHandler {
        target: "pie"
        function toggle(): void { root.togglePieMenu(); }
        function show(): void { root.closeAll(); root.pieMenuOpen = true; }
        function hide(): void { root.pieMenuOpen = false; }
        function select(idx: int): void {
            root.closeAll();
            root.pieInitialSlice = idx;
            root.pieMenuOpen = true;
        }
    }

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
        target: "media"
        function playPause(): void { MediaService.playPause(); }
        function next(): void { MediaService.next(); }
        function previous(): void { MediaService.previous(); }
    }

    IpcHandler {
        target: "mediacard"
        function toggle(): void { root.toggleMediaCard(); }
        function show(): void { root.mediaCardOpen = true; }
        function hide(): void { root.mediaCardOpen = false; }
    }

    IpcHandler {
        target: "workspacePreview"
        function openWs1(): void {
            root.hoveredWorkspace = 1;
            root.hoveredWorkspaceGlobalX = 80;
            root.workspacePreviewOpen = true;
            WindowService.refresh();
        }
        function openWs2(): void {
            root.hoveredWorkspace = 2;
            root.hoveredWorkspaceGlobalX = 100;
            root.workspacePreviewOpen = true;
            WindowService.refresh();
        }
        function close(): void {
            root.workspacePreviewOpen = false;
        }
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
        function refresh(): void { GithubService.refresh(true); }
    }

    IpcHandler {
        target: "jira"
        function toggle(): void { root.toggleDesktopJira(); }
        function show(): void { root.desktopJiraVisible = true; }
        function hide(): void { root.desktopJiraVisible = false; }
        function refresh(): void { JiraService.refresh(true); }
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { NotificationService.toggleDnd(); }
        function dndOn(): void { if (!NotificationService.dnd) NotificationService.toggleDnd(); }
        function dndOff(): void { if (NotificationService.dnd) NotificationService.toggleDnd(); }
        function clear(): void { NotificationService.clearAll(); }
    }

    IpcHandler {
        target: "theme"
        function next(): void { Theme.nextTheme(); }
        function prev(): void { Theme.prevTheme(); }
        function set(name: string): void { Theme.setTheme(name); }
        function cycleToggle(): void { Theme.autoCycle = !Theme.autoCycle; }
        function cycleOn(): void { Theme.autoCycle = true; }
        function cycleOff(): void { Theme.autoCycle = false; }
        function fromWallpaper(): void { Theme.toggleFromWallpaper(WallpaperService.currentWallpaper); }
        function fromWallpaperToggle(): void { Theme.toggleFromWallpaper(WallpaperService.currentWallpaper); }
    }

    IpcHandler {
        target: "wallpaperTheme"
        function toggle(): void { root.toggleWallpaperThemeDialog(); }
        function show(): void { root.wallpaperThemeDialogOpen = true; }
        function hide(): void { root.wallpaperThemeDialogOpen = false; }
        function themes(): void {
            root.wallpaperThemeTab = "themes";
            root.wallpaperThemeDialogOpen = true;
        }
        function wallpapers(): void {
            root.wallpaperThemeTab = "wallpapers";
            root.wallpaperThemeDialogOpen = true;
        }
    }

    IpcHandler {
        target: "wallpaperSelector"
        function toggle(): void { root.toggleWallpaperThemeDialog(); }
        function show(): void { root.wallpaperThemeDialogOpen = true; }
        function hide(): void { root.wallpaperThemeDialogOpen = false; }
    }

    IpcHandler {
        target: "wallpaper"
        function next(): void { WallpaperService.nextWallpaper(); }
        function prev(): void { WallpaperService.prevWallpaper(); }
        function set(path: string): void { WallpaperService.setWallpaper(path); }
        function mode(newMode: string): void { WallpaperService.setMode(newMode); }
        function themeMode(): void { WallpaperService.setMode("theme"); }
        function gradientMode(): void { WallpaperService.setMode("gradient"); }
        function toggleGradient(): void { WallpaperService.toggleGradient(); }
    }

    IpcHandler {
        target: "docker"
        function toggle(): void { root.toggleDocker(); }
        function show(): void { root.closeAll(); root.dockerOpen = true; }
        function hide(): void { root.dockerOpen = false; }
    }

    IpcHandler {
        target: "whatsapp"
        function toggle(): void { root.toggleWhatsApp(); }
        function show(): void { root.closeAll(); root.whatsappOpen = true; }
        function hide(): void { root.whatsappOpen = false; }
        function refresh(): void { WhatsAppService.refresh(); }
        function reconnect(): void { WhatsAppService.reconnectSession(); }
        function startGateway(): void { WhatsAppService.startGateway(); }
    }

    IpcHandler {
        target: "runner"
        function toggle(): void { root.toggleRunner(); }
        function show(): void { root.closeAll(); root.runnerOpen = true; TaskRunnerService.refresh(); }
        function hide(): void { root.runnerOpen = false; }
    }

    IpcHandler {
        target: "windowSwitcher"
        function toggle(): void { root.toggleWindowSwitcher(); }
        function show(): void { root.closeAll(); root.windowSwitcherOpen = true; WindowService.refresh(); }
        function hide(): void { root.windowSwitcherOpen = false; }
    }

    IpcHandler {
        target: "liteMode"
        function toggle(): void { root.toggleLiteMode(); }
        function enable(): void { if (!root.liteMode) root.toggleLiteMode(); }
        function disable(): void { if (root.liteMode) root.toggleLiteMode(); }
        function status(): string { return root.liteMode ? "enabled" : "disabled"; }
    }

    IpcHandler {
        target: "systemMonitor"
        function toggle(): void { root.toggleSystemMonitor("ram"); }
        function cpu(): void { root.toggleSystemMonitor("cpu"); }
        function ram(): void { root.toggleSystemMonitor("ram"); }
        function swap(): void { root.toggleSystemMonitor("swap"); }
        function groups(): void { root.toggleSystemMonitor("groups"); }
        function show(): void { root.closeAll(); root.systemMonitorOpen = true; }
        function hide(): void { root.systemMonitorOpen = false; }
    }

    IpcHandler {
        target: "brightness"
        function up(): void { BrightnessService.increase(); }
        function down(): void { BrightnessService.decrease(); }
        function refresh(): void { BrightnessService.refresh(); }
        function set(val: string): void { BrightnessService.setPercent(parseInt(val)); }
    }

    IpcHandler {
        target: "osd"
        function volume(val: string): void { OsdService.showVolume(parseFloat(val), false); }
        function brightness(val: string): void { OsdService.showBrightness(parseInt(val)); }
    }

    IpcHandler {
        target: "font"
        function cupertino(): void { root.fontPreset = "cupertino"; Theme.fontPreset = "cupertino"; }
        function nordic(): void { root.fontPreset = "nordic"; Theme.fontPreset = "nordic"; }
        function google(): void { root.fontPreset = "google"; Theme.fontPreset = "google"; }
        function set(name: string): void { root.fontPreset = name; Theme.fontPreset = name; }
        function next(): void {
            const list = ["cupertino", "nordic", "google"];
            const idx = list.indexOf(root.fontPreset);
            const nxt = list[(idx + 1) % list.length];
            root.fontPreset = nxt;
            Theme.fontPreset = nxt;
        }
    }

    IpcHandler {
        target: "skybox"
        function toggle(): void { root.skyboxEnabled = !root.skyboxEnabled; }
        function on(): void { root.skyboxEnabled = true; }
        function off(): void { root.skyboxEnabled = false; }
    }
}
