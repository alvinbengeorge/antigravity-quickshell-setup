pragma Singleton
import QtQuick

QtObject {
    id: theme

    // Palette - Deep Space & Google DeepMind Antigravity Aesthetics
    // Note: QML hex format is #AARRGGBB
    readonly property color bgBase: "#090D14"
    readonly property color bgSurface: "#0F172A"
    readonly property color bgSurfaceGlass: "#F20B0F17" // 95% solid obsidian glass (deep black)
    readonly property color bgModal: "#0D1322"          // Solid dark modal surface
    readonly property color bgCard: "#131C2E"           // Slightly raised card surface
    readonly property color bgPill: "#141D2D"           // Sleek dark pill background
    readonly property color bgHover: "#1E2B43"          // Hover state
    readonly property color bgActive: "#28395A"         // Active pressed state

    readonly property color borderDim: "#1E293B"
    readonly property color borderGlow: "#4038BDF8"
    readonly property color borderActive: "#6366F1"

    // Neon Accents
    readonly property color accentViolet: "#8B5CF6"
    readonly property color accentIndigo: "#6366F1"
    readonly property color accentCyan: "#06B6D4"
    readonly property color accentSky: "#38BDF8"
    readonly property color accentEmerald: "#10B981"
    readonly property color accentAmber: "#F59E0B"
    readonly property color accentRose: "#F43F5E"

    // Text Colors
    readonly property color textPrimary: "#F8FAFC"
    readonly property color textSecondary: "#94A3B8"
    readonly property color textMuted: "#64748B"
    readonly property color textOnAccent: "#FFFFFF"

    // Dimensions
    readonly property int barHeight: 44
    readonly property int pillRadius: 22
    readonly property int cardRadius: 16
    readonly property int smallRadius: 8

    // Fonts
    readonly property string fontFamily: "Google Sans, Inter, system-ui, sans-serif"
    readonly property string fontMono: "Adwaita Mono, Noto Sans Mono, monospace"
}
