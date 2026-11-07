pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    // Active Theme Management
    readonly property var builtInKeys: ["deepspace", "askmeidentity", "arythmatic", "catppuccin", "tokyonight", "nord", "cyberpunk", "gruvbox"]
    property var customPalettes: ({})
    property var customThemeKeys: []

    readonly property var themeKeys: {
        return builtInKeys.concat(customThemeKeys || []);
    }

    property int currentThemeIndex: 0
    property string currentThemeKey: (themeKeys && themeKeys.length > currentThemeIndex) ? themeKeys[currentThemeIndex] : "deepspace"
    property bool isLoaded: false

    property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/user"
    property string stateFile: stateDir + "/antigravity-theme.json"
    property string customThemesFile: stateDir + "/antigravity-custom-themes.json"

    Timer {
        id: fileWriteTimer
        interval: 50
        repeat: false
        onTriggered: {
            themeFileView.writeAdapter();
        }
    }

    FileView {
        id: themeFileView
        path: theme.stateFile

        watchChanges: false
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: {
            if (themeAdapter.currentTheme) {
                const idx = theme.themeKeys.indexOf(themeAdapter.currentTheme);
                if (idx !== -1) {
                    theme.currentThemeIndex = idx;
                }
            }
            theme.isLoaded = true;
            theme.syncKitty();
            theme.syncSystemTheme();
            theme.syncHyprlock();
        }
        onLoadFailed: error => {
            console.log("Antigravity theme state not found or error, creating default:", error);
            theme.isLoaded = true;
            theme.syncKitty();
            theme.syncSystemTheme();
            theme.syncHyprlock();
            themeAdapter.currentTheme = theme.currentThemeKey;
            fileWriteTimer.restart();
        }

        adapter: JsonAdapter {
            id: themeAdapter
            property string currentTheme: "deepspace"
        }
    }

    // Custom themes file loader
    Timer {
        id: customThemesWriteTimer
        interval: 50
        repeat: false
        onTriggered: {
            customThemesFileView.writeAdapter();
        }
    }

    FileView {
        id: customThemesFileView
        path: theme.customThemesFile
        watchChanges: true
        onAdapterUpdated: customThemesWriteTimer.restart()
        onLoaded: {
            try {
                if (customThemesAdapter.themes) {
                    theme.customPalettes = customThemesAdapter.themes;
                    theme.customThemeKeys = Object.keys(customThemesAdapter.themes);
                    if (themeAdapter.currentTheme) {
                        const idx = theme.themeKeys.indexOf(themeAdapter.currentTheme);
                        if (idx !== -1) {
                            theme.currentThemeIndex = idx;
                        }
                    }
                }
            } catch(e) {
                console.log("Error loading custom themes:", e);
            }
        }
        onLoadFailed: error => {
            theme.customPalettes = {};
            theme.customThemeKeys = [];
        }

        adapter: JsonAdapter {
            id: customThemesAdapter
            property var themes: ({})
        }
    }

    // Auto-cycle every 5 minutes (300,000 ms)
    property bool autoCycle: false
    property int cycleInterval: 300000

    property var cycleTimer: Timer {
        interval: theme.cycleInterval
        running: theme.autoCycle
        repeat: true
        onTriggered: theme.nextTheme()
    }

    function syncKitty() {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/apply_kitty_theme.py", theme.currentThemeKey]);
    }

    function syncSystemTheme() {
        // apply_system_theme.py internally also runs apply_hyprlock_theme.py
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/apply_system_theme.py", theme.currentThemeKey]);
    }

    // Note: syncHyprlock is NOT called separately; apply_system_theme.py handles it
    // to avoid double-invocation of apply_hyprlock_theme.py
    function syncHyprlock() {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/apply_hyprlock_theme.py", theme.currentThemeKey]);
    }

    onCurrentThemeKeyChanged: {
        if (theme.isLoaded) {
            themeAdapter.currentTheme = theme.currentThemeKey;
            fileWriteTimer.restart();
        }
        theme.syncKitty();
        theme.syncSystemTheme(); // hyprlock is updated inside this
    }
    function nextTheme() {
        theme.currentThemeIndex = (theme.currentThemeIndex + 1) % theme.themeKeys.length;
    }

    function prevTheme() {
        theme.currentThemeIndex = (theme.currentThemeIndex - 1 + theme.themeKeys.length) % theme.themeKeys.length;
    }

    property bool fromWallpaperActive: false
    property var tempWallpaperPalette: null
    property bool isExtractingWallpaper: false

    onFromWallpaperActiveChanged: {
        if (theme.fromWallpaperActive) {
            theme.extractTemporaryWallpaperTheme("");
        } else {
            theme.tempWallpaperPalette = null;
            Quickshell.execDetached(["rm", "-f", theme.stateDir + "/temp-wallpaper-theme.json"]);
            theme.syncKitty();
            theme.syncSystemTheme(); // hyprlock updated inside
            Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Theme Mode", "Reverted to saved theme: " + theme.themeName]);
        }
    }

    function toggleFromWallpaper(wallpaperPath) {
        if (!theme.fromWallpaperActive && wallpaperPath) {
            theme.fromWallpaperActive = true;
            theme.extractTemporaryWallpaperTheme(wallpaperPath);
        } else {
            theme.fromWallpaperActive = !theme.fromWallpaperActive;
        }
    }

    function setTheme(name) {
        if (theme.fromWallpaperActive) {
            theme.fromWallpaperActive = false;
        }
        const idx = theme.themeKeys.indexOf(name);
        if (idx !== -1) {
            theme.currentThemeIndex = idx;
        }
    }

    function isCustomTheme(key) {
        return Boolean(theme.customPalettes && theme.customPalettes[key]);
    }

    function addCustomTheme(themeObj) {
        if (!themeObj || !themeObj.id) return;
        const current = Object.assign({}, theme.customPalettes);
        current[themeObj.id] = themeObj;
        theme.customPalettes = current;
        theme.customThemeKeys = Object.keys(current);
        customThemesAdapter.themes = current;
        customThemesWriteTimer.restart();
    }

    function deleteCustomTheme(key) {
        if (!theme.customPalettes || !theme.customPalettes[key]) return;
        const current = Object.assign({}, theme.customPalettes);
        delete current[key];
        theme.customPalettes = current;
        theme.customThemeKeys = Object.keys(current);
        customThemesAdapter.themes = current;
        customThemesWriteTimer.restart();
        if (theme.currentThemeKey === key) {
            theme.setTheme("deepspace");
        }
    }

    // Process to extract temporary theme from current wallpaper (not saved)
    Process {
        id: wpTempExtractProc
        stdout: StdioCollector {
            onStreamFinished: {
                theme.isExtractingWallpaper = false;
                try {
                    const newTheme = JSON.parse(text.trim());
                    if (newTheme && newTheme.id) {
                        theme.tempWallpaperPalette = newTheme;
                        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/apply_kitty_theme.py", "temp_wallpaper"]);
                        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/apply_system_theme.py", "temp_wallpaper"]);
                        // hyprlock sync is handled inside apply_system_theme.py — no separate call needed
                        Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Wallpaper Theme (Live)", "Adapted temporary palette to wallpaper."]);
                    }
                } catch(e) {
                    console.log("Error extracting temporary wallpaper theme:", e);
                }
            }
        }
    }

    function extractTemporaryWallpaperTheme(wallpaperPath) {
        theme.isExtractingWallpaper = true;
        const wp = wallpaperPath || "";
        wpTempExtractProc.command = [
            "python3",
            Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/extract_wallpaper_theme.py",
            wp,
            "--temp"
        ];
        wpTempExtractProc.running = true;
    }

    // Process to extract and permanently save theme from wallpaper
    Process {
        id: wpExtractProc
        stdout: StdioCollector {
            onStreamFinished: {
                theme.isExtractingWallpaper = false;
                try {
                    const newTheme = JSON.parse(text.trim());
                    if (newTheme && newTheme.id) {
                        theme.addCustomTheme(newTheme);
                        theme.setTheme(newTheme.id);
                        Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Theme Saved", "Saved '" + newTheme.name + "' into custom themes."]);
                    }
                } catch(e) {
                    console.log("Error extracting wallpaper theme:", e);
                }
            }
        }
    }

    function createThemeFromCurrentWallpaper(wallpaperPath) {
        theme.isExtractingWallpaper = true;
        const wp = wallpaperPath || "";
        wpExtractProc.command = [
            "python3",
            Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/extract_wallpaper_theme.py",
            wp
        ];
        wpExtractProc.running = true;
    }

    // Process to create custom theme
    Process {
        id: customCreateProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const newTheme = JSON.parse(text.trim());
                    if (newTheme && newTheme.id) {
                        theme.addCustomTheme(newTheme);
                        theme.setTheme(newTheme.id);
                        Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Theme Created", "Theme '" + newTheme.name + "' created and applied."]);
                    }
                } catch(e) {
                    console.log("Error creating custom theme:", e);
                }
            }
        }
    }

    function createCustomTheme(name, primaryHex, secondaryHex, baseDarkHex) {
        customCreateProc.command = [
            "python3",
            Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/create_custom_theme.py",
            "--name", name || "Custom Theme",
            "--primary", primaryHex || "#38BDF8",
            "--secondary", secondaryHex || "#A78BFA",
            "--base", baseDarkHex || "#090D14"
        ];
        customCreateProc.running = true;
    }

    readonly property var builtInPalettes: ({
        "arythmatic": {
            "name": "Arythmatic",
            "wallpaper": "/home/alvin/Pictures/Wallpapers/arythmatic-obsidian.png",
            "gtkTheme": "Obsidian-flow-yellow-dark",
            "bgBase": "#080B10",
            "bgSurface": "#0E131C",
            "bgSurfaceGlass": "#F20E131C",
            "bgModal": "#131926",
            "bgCard": "#171F2E",
            "bgPill": "#141B29",
            "bgHover": "#222C40",
            "bgActive": "#2D3A54",
            "borderDim": "#1C2536",
            "borderGlow": "#45FFAA00",
            "borderActive": "#FFAA00",
            "accentViolet": "#FFAA00",
            "accentIndigo": "#FF8C00",
            "accentCyan": "#FFC533",
            "accentSky": "#FFAA00",
            "accentEmerald": "#00C758",
            "accentAmber": "#FFAA00",
            "accentRose": "#F43F5E",
            "textPrimary": "#F8FAFC",
            "textSecondary": "#CBD5E1",
            "textMuted": "#8E9EB5",
            "textOnAccent": "#000000"
        },
        "askmeidentity": {
            "name": "AskMeIdentity",
            "wallpaper": "/home/alvin/Pictures/Wallpapers/fedora-neon-blue-black.jpg",
            "gtkTheme": "Obsidian-flow-blue-dark",
            "bgBase": "#080B11",
            "bgSurface": "#0E1522",
            "bgSurfaceGlass": "#F20E1522",
            "bgModal": "#131D2E",
            "bgCard": "#172338",
            "bgPill": "#141F32",
            "bgHover": "#223352",
            "bgActive": "#2E446D",
            "borderDim": "#1C2B42",
            "borderGlow": "#452962FF",
            "borderActive": "#2962FF",
            "accentViolet": "#60B01C",
            "accentIndigo": "#1965D8",
            "accentCyan": "#00F0FF",
            "accentSky": "#2962FF",
            "accentEmerald": "#60B01C",
            "accentAmber": "#F59E0B",
            "accentRose": "#F43F5E",
            "textPrimary": "#F8FAFC",
            "textSecondary": "#CBD5E1",
            "textMuted": "#8295AD",
            "textOnAccent": "#FFFFFF"
        },
        "deepspace": {
            "name": "Deep Space",
            "wallpaper": "/home/alvin/Pictures/Wallpapers/fedora-neon-blue-black.jpg",
            "gtkTheme": "Obsidian-flow-blue-dark",
            "bgBase": "#090D14",
            "bgSurface": "#0F172A",
            "bgSurfaceGlass": "#F20B0F17",
            "bgModal": "#0D1322",
            "bgCard": "#131C2E",
            "bgPill": "#141D2D",
            "bgHover": "#1E2B43",
            "bgActive": "#28395A",
            "borderDim": "#1E293B",
            "borderGlow": "#4038BDF8",
            "borderActive": "#6366F1",
            "accentViolet": "#A78BFA",
            "accentIndigo": "#818CF8",
            "accentCyan": "#22D3EE",
            "accentSky": "#38BDF8",
            "accentEmerald": "#34D399",
            "accentAmber": "#FBBF24",
            "accentRose": "#FB7185",
            "textPrimary": "#F8FAFC",
            "textSecondary": "#CBD5E1",
            "textMuted": "#94A3B8",
            "textOnAccent": "#FFFFFF"
        },
        "catppuccin": {
            "name": "Catppuccin Mocha",
            "wallpaper": "/home/alvin/Pictures/Wallpapers/wallhaven-rqyoo1.png",
            "gtkTheme": "Obsidian-flow-purple-dark",
            "bgBase": "#11111B",
            "bgSurface": "#181825",
            "bgSurfaceGlass": "#F2181825",
            "bgModal": "#1E1E2E",
            "bgCard": "#24273A",
            "bgPill": "#26283D",
            "bgHover": "#363A4F",
            "bgActive": "#494D64",
            "borderDim": "#313244",
            "borderGlow": "#40CBA6F7",
            "borderActive": "#CBA6F7",
            "accentViolet": "#DDB6F2",
            "accentIndigo": "#B4BEFE",
            "accentCyan": "#89DCEB",
            "accentSky": "#74C7EC",
            "accentEmerald": "#A6E3A1",
            "accentAmber": "#F9E2AF",
            "accentRose": "#F38BA8",
            "textPrimary": "#CDD6F4",
            "textSecondary": "#BAC2DE",
            "textMuted": "#A6ADC8",
            "textOnAccent": "#FFFFFF"
        },
        "tokyonight": {
            "name": "Tokyo Night",
            "wallpaper": "/home/alvin/Pictures/Wallpapers/fedora-neon.jpg",
            "gtkTheme": "Obsidian-flow-blue-dark",
            "bgBase": "#16161E",
            "bgSurface": "#1A1B26",
            "bgSurfaceGlass": "#F21A1B26",
            "bgModal": "#1F2335",
            "bgCard": "#24283B",
            "bgPill": "#222638",
            "bgHover": "#2F3549",
            "bgActive": "#3B4261",
            "borderDim": "#292E42",
            "borderGlow": "#407AA2F7",
            "borderActive": "#7AA2F7",
            "accentViolet": "#C0CAF5",
            "accentIndigo": "#7AA2F7",
            "accentCyan": "#7DCFFF",
            "accentSky": "#2AC3DE",
            "accentEmerald": "#9ECE6A",
            "accentAmber": "#E0AF68",
            "accentRose": "#F7768E",
            "textPrimary": "#C0CAF5",
            "textSecondary": "#A9B1D6",
            "textMuted": "#787C99",
            "textOnAccent": "#FFFFFF"
        },
        "nord": {
            "name": "Nord Frost",
            "wallpaper": "/home/alvin/Pictures/Wallpapers/wallhaven-nrd9oj.jpg",
            "gtkTheme": "Obsidian-flow-gray-dark",
            "bgBase": "#242933",
            "bgSurface": "#2E3440",
            "bgSurfaceGlass": "#F22E3440",
            "bgModal": "#3B4252",
            "bgCard": "#383F4D",
            "bgPill": "#333A47",
            "bgHover": "#434C5E",
            "bgActive": "#4C566A",
            "borderDim": "#434C5E",
            "borderGlow": "#4088C0D0",
            "borderActive": "#88C0D0",
            "accentViolet": "#D0A8C7",
            "accentIndigo": "#5E81AC",
            "accentCyan": "#8FBCBB",
            "accentSky": "#88C0D0",
            "accentEmerald": "#A3BE8C",
            "accentAmber": "#EBCB8B",
            "accentRose": "#BF616A",
            "textPrimary": "#ECEFF4",
            "textSecondary": "#E5E9F0",
            "textMuted": "#98A2B3",
            "textOnAccent": "#FFFFFF"
        },
        "cyberpunk": {
            "name": "Cyberpunk Neon",
            "wallpaper": "/home/alvin/Pictures/Wallpapers/wallhaven-95kpwx.jpg",
            "gtkTheme": "Obsidian-flow-red-dark",
            "bgBase": "#08040C",
            "bgSurface": "#0F0A1C",
            "bgSurfaceGlass": "#F20F0A1C",
            "bgModal": "#18122B",
            "bgCard": "#21193D",
            "bgPill": "#1E1735",
            "bgHover": "#322353",
            "bgActive": "#462F76",
            "borderDim": "#2D1F4E",
            "borderGlow": "#50FF007F",
            "borderActive": "#FF007F",
            "accentViolet": "#FF79C6",
            "accentIndigo": "#BD93F9",
            "accentCyan": "#00F0FF",
            "accentSky": "#38BDF8",
            "accentEmerald": "#10E599",
            "accentAmber": "#FFE600",
            "accentRose": "#FF007F",
            "textPrimary": "#FFF0FA",
            "textSecondary": "#F1B7EE",
            "textMuted": "#BA93B9",
            "textOnAccent": "#FFFFFF"
        },
        "gruvbox": {
            "name": "Gruvbox Warm",
            "wallpaper": "/home/alvin/Pictures/Wallpapers/wallhaven-48wlq2.jpg",
            "gtkTheme": "Obsidian-flow-yellow-dark",
            "bgBase": "#1D2021",
            "bgSurface": "#282828",
            "bgSurfaceGlass": "#F2282828",
            "bgModal": "#32302F",
            "bgCard": "#3C3836",
            "bgPill": "#32302F",
            "bgHover": "#504945",
            "bgActive": "#665C54",
            "borderDim": "#3C3836",
            "borderGlow": "#40FABD2F",
            "borderActive": "#FABD2F",
            "accentViolet": "#E095AA",
            "accentIndigo": "#83A598",
            "accentCyan": "#8EC07C",
            "accentSky": "#83A598",
            "accentEmerald": "#B8BB26",
            "accentAmber": "#FABD2F",
            "accentRose": "#FB4934",
            "textPrimary": "#EBDBB2",
            "textSecondary": "#D5C4A1",
            "textMuted": "#A89984",
            "textOnAccent": "#FFFFFF"
        }
    })

    readonly property var palettes: {
        const merged = Object.assign({}, builtInPalettes);
        if (theme.customPalettes) {
            for (const k in theme.customPalettes) {
                merged[k] = theme.customPalettes[k];
            }
        }
        return merged;
    }

    readonly property var currentPalette: {
        if (theme.fromWallpaperActive && theme.tempWallpaperPalette) {
            return theme.tempWallpaperPalette;
        }
        return palettes[currentThemeKey] || palettes["deepspace"];
    }

    // Dynamic Reactive Colors
    readonly property color bgBase: currentPalette.bgBase
    readonly property color bgSurface: currentPalette.bgSurface
    readonly property color bgSurfaceGlass: currentPalette.bgSurfaceGlass
    readonly property color bgModal: currentPalette.bgModal
    readonly property color bgCard: currentPalette.bgCard
    readonly property color bgPill: currentPalette.bgPill
    readonly property color bgHover: currentPalette.bgHover
    readonly property color bgActive: currentPalette.bgActive

    readonly property color borderDim: currentPalette.borderDim
    readonly property color borderGlow: currentPalette.borderGlow
    readonly property color borderActive: currentPalette.borderActive

    // Neon Accents
    readonly property color accentViolet: currentPalette.accentViolet
    readonly property color accentIndigo: currentPalette.accentIndigo
    readonly property color accentCyan: currentPalette.accentCyan
    readonly property color accentSky: currentPalette.accentSky
    readonly property color accentEmerald: currentPalette.accentEmerald
    readonly property color accentAmber: currentPalette.accentAmber
    readonly property color accentRose: currentPalette.accentRose

    // Text Colors
    readonly property color textPrimary: currentPalette.textPrimary
    readonly property color textSecondary: currentPalette.textSecondary
    readonly property color textMuted: currentPalette.textMuted
    readonly property color textOnAccent: currentPalette.textOnAccent

    // Dimensions
    readonly property int barHeight: 44
    readonly property int pillRadius: 22
    readonly property int cardRadius: 16
    readonly property int smallRadius: 8

    // Fonts
    readonly property string fontFamily: "Google Sans, Inter, system-ui, sans-serif"
    readonly property string fontMono: "Adwaita Mono, Noto Sans Mono, monospace"

    // Theme metadata
    readonly property string themeName: currentPalette.name
    readonly property string currentWallpaper: currentPalette.wallpaper || ""

    // Liquid Glass Design Tokens (Apple Style)
    readonly property color glassSpecular: Qt.rgba(1, 1, 1, 0.45)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.28)
    readonly property color glassFillTop: Qt.rgba(1, 1, 1, 0.12)
    readonly property color glassFillBottom: Qt.rgba(1, 1, 1, 0.03)
}
