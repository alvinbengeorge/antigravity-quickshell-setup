#!/usr/bin/env python3
"""
Antigravity Hyprlock Dynamic Theme Syncer
Synchronizes ~/.config/hypr/hyprlock-colors.conf with the active Quickshell theme & wallpaper.
"""

import os
import sys
import json

STATE_DIR = os.path.expanduser("~/.local/state/quickshell/user")
THEME_FILE = os.path.join(STATE_DIR, "antigravity-theme.json")
CUSTOM_THEMES_FILE = os.path.join(STATE_DIR, "antigravity-custom-themes.json")
TEMP_THEME_FILE = os.path.join(STATE_DIR, "temp-wallpaper-theme.json")
WALLPAPER_FILE = os.path.join(STATE_DIR, "antigravity-wallpaper.json")

HYPR_DIR = os.path.expanduser("~/.config/hypr")
HYPRLOCK_COLORS_CONF = os.path.join(HYPR_DIR, "hyprlock-colors.conf")

BUILT_IN_PALETTES = {
    "arythmatic": {
        "name": "Arythmatic",
        "wallpaper": "/home/alvin/Pictures/Wallpapers/arythmatic-obsidian.png",
        "bgBase": "#080B10",
        "bgCard": "#171F2E",
        "bgHover": "#222C40",
        "borderActive": "#FFAA00",
        "accentSky": "#FFAA00",
        "accentViolet": "#FFAA00",
        "accentCyan": "#FFC533",
        "accentRose": "#F43F5E",
        "textPrimary": "#F8FAFC",
        "textSecondary": "#CBD5E1",
        "textMuted": "#8E9EB5",
    },
    "askmeidentity": {
        "name": "AskMeIdentity",
        "wallpaper": "/home/alvin/Pictures/Wallpapers/fedora-neon-blue-black.jpg",
        "bgBase": "#080B11",
        "bgCard": "#172338",
        "bgHover": "#223352",
        "borderActive": "#2962FF",
        "accentSky": "#2962FF",
        "accentViolet": "#60B01C",
        "accentCyan": "#00F0FF",
        "accentRose": "#F43F5E",
        "textPrimary": "#F8FAFC",
        "textSecondary": "#CBD5E1",
        "textMuted": "#8295AD",
    },
    "deepspace": {
        "name": "Deep Space",
        "wallpaper": "/home/alvin/Pictures/Wallpapers/fedora-neon-blue-black.jpg",
        "bgBase": "#090D14",
        "bgCard": "#131C2E",
        "bgHover": "#1E2B43",
        "borderActive": "#6366F1",
        "accentSky": "#38BDF8",
        "accentViolet": "#A78BFA",
        "accentCyan": "#22D3EE",
        "accentRose": "#FB7185",
        "textPrimary": "#F8FAFC",
        "textSecondary": "#CBD5E1",
        "textMuted": "#94A3B8",
    },
    "catppuccin": {
        "name": "Catppuccin Mocha",
        "wallpaper": "/home/alvin/Pictures/Wallpapers/wallhaven-rqyoo1.png",
        "bgBase": "#11111B",
        "bgCard": "#24273A",
        "bgHover": "#363A4F",
        "borderActive": "#CBA6F7",
        "accentSky": "#74C7EC",
        "accentViolet": "#DDB6F2",
        "accentCyan": "#89DCEB",
        "accentRose": "#F38BA8",
        "textPrimary": "#CDD6F4",
        "textSecondary": "#BAC2DE",
        "textMuted": "#A6ADC8",
    },
    "tokyonight": {
        "name": "Tokyo Night",
        "wallpaper": "/home/alvin/Pictures/Wallpapers/fedora-neon.jpg",
        "bgBase": "#16161E",
        "bgCard": "#24283B",
        "bgHover": "#2F3549",
        "borderActive": "#7AA2F7",
        "accentSky": "#2AC3DE",
        "accentViolet": "#C0CAF5",
        "accentCyan": "#7DCFFF",
        "accentRose": "#F7768E",
        "textPrimary": "#C0CAF5",
        "textSecondary": "#A9B1D6",
        "textMuted": "#787C99",
    },
    "nord": {
        "name": "Nord Frost",
        "wallpaper": "/home/alvin/Pictures/Wallpapers/wallhaven-nrd9oj.jpg",
        "bgBase": "#242933",
        "bgCard": "#383F4D",
        "bgHover": "#434C5E",
        "borderActive": "#88C0D0",
        "accentSky": "#88C0D0",
        "accentViolet": "#D0A8C7",
        "accentCyan": "#8FBCBB",
        "accentRose": "#BF616A",
        "textPrimary": "#ECEFF4",
        "textSecondary": "#E5E9F0",
        "textMuted": "#98A2B3",
    },
    "cyberpunk": {
        "name": "Cyberpunk Neon",
        "wallpaper": "/home/alvin/Pictures/Wallpapers/wallhaven-95kpwx.jpg",
        "bgBase": "#08040C",
        "bgCard": "#1E1035",
        "bgHover": "#2C174D",
        "borderActive": "#FF0055",
        "accentSky": "#00F0FF",
        "accentViolet": "#BD00FF",
        "accentCyan": "#00F0FF",
        "accentRose": "#FF0055",
        "textPrimary": "#FFFFFF",
        "textSecondary": "#E2D9F3",
        "textMuted": "#9D8BAF",
    },
    "gruvbox": {
        "name": "Gruvbox Warm",
        "wallpaper": "/home/alvin/Pictures/Wallpapers/wallhaven-1353qg.jpg",
        "bgBase": "#1D2021",
        "bgCard": "#32302F",
        "bgHover": "#3C3836",
        "borderActive": "#FABD2F",
        "accentSky": "#83A598",
        "accentViolet": "#D3869B",
        "accentCyan": "#8EC07C",
        "accentRose": "#FB4934",
        "textPrimary": "#FBF1C7",
        "textSecondary": "#EBDBB2",
        "textMuted": "#A89984",
    },
}

def hex_to_rgb(hex_code):
    if not hex_code:
        return "rgb(255, 170, 0)"
    clean = hex_code.lstrip('#')
    if len(clean) == 8:
        clean = clean[2:] if clean.startswith(('ff', 'FF', '00')) else clean[:6]
    if len(clean) == 3:
        clean = ''.join(c * 2 for c in clean)
    try:
        r = int(clean[0:2], 16)
        g = int(clean[2:4], 16)
        b = int(clean[4:6], 16)
        return f"rgb({r}, {g}, {b})"
    except Exception:
        return "rgb(255, 170, 0)"

def hex_to_rgba(hex_code, alpha=0.70):
    if not hex_code:
        return f"rgba(255, 170, 0, {alpha:.2f})"
    clean = hex_code.lstrip('#')
    if len(clean) == 8:
        clean = clean[2:] if clean.startswith(('ff', 'FF', '00')) else clean[:6]
    if len(clean) == 3:
        clean = ''.join(c * 2 for c in clean)
    try:
        r = int(clean[0:2], 16)
        g = int(clean[2:4], 16)
        b = int(clean[4:6], 16)
        return f"rgba({r}, {g}, {b}, {alpha:.2f})"
    except Exception:
        return f"rgba(255, 170, 0, {alpha:.2f})"

def hex_clean(hex_code):
    if not hex_code:
        return "8E9EB5"
    clean = hex_code.lstrip('#')
    if len(clean) == 8:
        clean = clean[2:]
    return clean.upper()

def resolve_palette(theme_key):
    # 1. Built-in
    if theme_key in BUILT_IN_PALETTES:
        return BUILT_IN_PALETTES[theme_key]

    # 2. Temp wallpaper theme
    if theme_key in ("temp_wallpaper", "from_wp") and os.path.exists(TEMP_THEME_FILE):
        try:
            with open(TEMP_THEME_FILE, "r") as f:
                data = json.load(f)
                obj = data.get("theme", data)
                if obj and ("borderActive" in obj or "accentSky" in obj):
                    return obj
        except Exception:
            pass

    # 3. Custom themes
    if os.path.exists(CUSTOM_THEMES_FILE):
        try:
            with open(CUSTOM_THEMES_FILE, "r") as f:
                data = json.load(f)
                custom = data.get("themes", {}).get(theme_key)
                if custom:
                    return custom
        except Exception:
            pass

    # 4. Fallback to current state file
    if os.path.exists(THEME_FILE):
        try:
            with open(THEME_FILE, "r") as f:
                cur = json.load(f).get("currentTheme")
                if cur and cur != theme_key:
                    return resolve_palette(cur)
        except Exception:
            pass

    return BUILT_IN_PALETTES["arythmatic"]

def resolve_wallpaper(palette):
    # 1. Check manual wallpaper in WallpaperService state
    if os.path.exists(WALLPAPER_FILE):
        try:
            with open(WALLPAPER_FILE, "r") as f:
                wp_data = json.load(f)
                if wp_data.get("mode") == "manual" and wp_data.get("manualWallpaper"):
                    p = wp_data["manualWallpaper"]
                    if os.path.exists(p):
                        return p
        except Exception:
            pass

    # 2. Check palette's own wallpaper
    p = palette.get("wallpaper")
    if p and os.path.exists(p):
        return p

    # 3. Fallback to screenshot
    return "screenshot"

def apply_hyprlock_theme(theme_key=None):
    if not theme_key:
        if os.path.exists(THEME_FILE):
            try:
                with open(THEME_FILE, "r") as f:
                    theme_key = json.load(f).get("currentTheme", "arythmatic")
            except Exception:
                theme_key = "arythmatic"
        else:
            theme_key = "arythmatic"

    palette = resolve_palette(theme_key)
    wallpaper = resolve_wallpaper(palette)

    name = palette.get("name", theme_key.capitalize())
    active_accent = palette.get("borderActive") or palette.get("accentSky") or "#FFAA00"
    secondary_accent = palette.get("accentViolet") or active_accent
    bg_base = palette.get("bgBase") or "#080B10"
    bg_card = palette.get("bgCard") or "#171F2E"
    bg_hover = palette.get("bgHover") or "#222C40"
    text_primary = palette.get("textPrimary") or "#F8FAFC"
    text_secondary = palette.get("textSecondary") or "#CBD5E1"
    text_muted = palette.get("textMuted") or "#8E9EB5"
    rose = palette.get("accentRose") or "#F43F5E"

    conf_content = f"""# ==============================================================================
# ANTIGRAVITY DYNAMIC HYPRLOCK PALETTE
# Auto-generated by Antigravity Theme Engine
# Active Theme: {name} ({theme_key})
# ==============================================================================

$themeName = {name}
$lockWallpaper = {wallpaper}

$bgBase = {hex_to_rgb(bg_base)}
$bgCard = {hex_to_rgba(bg_card, 0.70)}
$bgCardHover = {hex_to_rgba(bg_hover, 0.85)}

$accentActive = {hex_to_rgb(active_accent)}
$accentSecondary = {hex_to_rgb(secondary_accent)}
$accentCyan = {hex_to_rgb(palette.get("accentCyan", active_accent))}
$accentRose = {hex_to_rgb(rose)}

$borderOuter = {hex_to_rgba(active_accent, 0.38)}
$borderGlow = {hex_to_rgba(active_accent, 0.50)}
$avatarBorder = {hex_to_rgba(active_accent, 0.45)}

$textPrimary = {hex_to_rgb(text_primary)}
$textSecondary = {hex_to_rgb(text_secondary)}
$textMuted = {hex_to_rgb(text_muted)}

$placeholderColor = ##{hex_clean(text_muted)}
$failColor = {hex_to_rgb(rose)}
"""

    os.makedirs(HYPR_DIR, exist_ok=True)
    with open(HYPRLOCK_COLORS_CONF, "w") as f:
        f.write(conf_content)

    print(f"[HYPRLOCK THEME] Synced lock screen to '{name}' ({theme_key}), wallpaper: {wallpaper}")
    return True

if __name__ == "__main__":
    key = sys.argv[1] if len(sys.argv) > 1 else None
    apply_hyprlock_theme(key)
