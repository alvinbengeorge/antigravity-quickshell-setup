pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: theme

    // Active Theme Management
    property var themeKeys: ["deepspace", "catppuccin", "tokyonight", "nord", "cyberpunk", "gruvbox"]
    property int currentThemeIndex: 0
    property string currentThemeKey: themeKeys[currentThemeIndex]

    // Auto-cycle every 10 seconds
    property bool autoCycle: false
    property int cycleInterval: 10000

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
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/apply_system_theme.py", theme.currentThemeKey]);
    }

    onCurrentThemeKeyChanged: {
        theme.syncKitty();
        theme.syncSystemTheme();
    }

    property var initTimer: Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            theme.syncKitty();
            theme.syncSystemTheme();
        }
    }

    function nextTheme() {
        theme.currentThemeIndex = (theme.currentThemeIndex + 1) % theme.themeKeys.length;
    }

    function prevTheme() {
        theme.currentThemeIndex = (theme.currentThemeIndex - 1 + theme.themeKeys.length) % theme.themeKeys.length;
    }

    function setTheme(name) {
        const idx = theme.themeKeys.indexOf(name);
        if (idx !== -1) {
            theme.currentThemeIndex = idx;
        }
    }

    readonly property var palettes: ({
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

    readonly property var currentPalette: palettes[currentThemeKey] || palettes["deepspace"]

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
}
