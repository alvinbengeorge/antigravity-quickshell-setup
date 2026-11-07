#!/usr/bin/env python3
"""
Custom Theme Creator for Antigravity Quickshell
Generates a complete, harmonized dark theme palette from user-specified accent and base colors.
"""

import os
import sys
import json
import re
import colorsys
import subprocess

STATE_DIR = os.path.expanduser("~/.local/state/quickshell/user")
CUSTOM_THEMES_FILE = os.path.join(STATE_DIR, "antigravity-custom-themes.json")
THEME_STATE_FILE = os.path.join(STATE_DIR, "antigravity-theme.json")

def to_hex(r, g, b):
    return f"#{int(max(0, min(255, r))):02X}{int(max(0, min(255, g))):02X}{int(max(0, min(255, b))):02X}"

def hsl_to_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h % 1.0, max(0.0, min(1.0, l)), max(0.0, min(1.0, s)))
    return to_hex(r * 255, g * 255, b * 255)

def hex_to_hsl(hex_str):
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 6:
        r, g, b = (int(hex_str[i:i+2], 16) / 255.0 for i in (0, 2, 4))
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        return h, s, l
    return 0.6, 0.7, 0.5

def build_custom_theme(name, primary_hex, secondary_hex=None, base_hex="#090D14", wallpaper=None):
    if not name or not name.strip():
        name = "Custom Theme"
    name = name.strip()

    pri_h, pri_s, pri_l = hex_to_hsl(primary_hex)
    if secondary_hex:
        sec_h, sec_s, sec_l = hex_to_hsl(secondary_hex)
    else:
        sec_h, sec_s, sec_l = (pri_h + 0.15) % 1.0, 0.75, 0.65

    base_h, base_s, base_l = hex_to_hsl(base_hex)
    # Ensure base saturation is subtle
    base_s = min(0.32, max(0.06, base_s))

    # Tonal Dark Background Scale
    bg_base = hsl_to_hex(base_h, base_s, 0.05)
    bg_surface = hsl_to_hex(base_h, base_s, 0.08)
    bg_surface_glass = "#F2" + bg_surface.lstrip("#")
    bg_modal = hsl_to_hex(base_h, base_s, 0.11)
    bg_card = hsl_to_hex(base_h, base_s, 0.14)
    bg_pill = hsl_to_hex(base_h, base_s, 0.16)
    bg_hover = hsl_to_hex(base_h, base_s, 0.22)
    bg_active = hsl_to_hex(base_h, base_s, 0.28)
    border_dim = hsl_to_hex(base_h, base_s, 0.18)

    # Vibrant Accents
    # Boost primary and secondary for vivid dark theme visibility
    acc_sky = hsl_to_hex(pri_h, max(0.70, pri_s), 0.65)
    acc_violet = hsl_to_hex(sec_h, max(0.65, sec_s), 0.68)
    acc_cyan = hsl_to_hex((pri_h + 0.10) % 1.0, 0.80, 0.62)
    acc_indigo = hsl_to_hex((sec_h + 0.05) % 1.0, 0.75, 0.65)
    acc_emerald = hsl_to_hex(0.35, 0.75, 0.62)
    acc_amber = hsl_to_hex(0.12, 0.88, 0.60)
    acc_rose = hsl_to_hex(0.97, 0.85, 0.66)

    # Determine closest GTK theme
    gtk_theme = "Obsidian-flow-blue-dark"
    if 0.50 <= pri_h <= 0.66:
        gtk_theme = "Obsidian-flow-blue-dark"
    elif 0.67 <= pri_h <= 0.85:
        gtk_theme = "Obsidian-flow-purple-dark"
    elif pri_h >= 0.90 or pri_h <= 0.06:
        gtk_theme = "Obsidian-flow-red-dark"
    elif 0.07 <= pri_h <= 0.20:
        gtk_theme = "Obsidian-flow-yellow-dark"
    elif 0.21 <= pri_h <= 0.45:
        gtk_theme = "Obsidian-flow-green-dark"

    clean_id = "custom_" + re.sub(r"[^a-zA-Z0-9]+", "_", name.lower()).strip("_")

    theme_obj = {
        "id": clean_id,
        "name": name,
        "wallpaper": wallpaper or "",
        "isCustom": True,
        "isWallpaperTheme": False,
        "gtkTheme": gtk_theme,
        "bgBase": bg_base,
        "bgSurface": bg_surface,
        "bgSurfaceGlass": bg_surface_glass,
        "bgModal": bg_modal,
        "bgCard": bg_card,
        "bgPill": bg_pill,
        "bgHover": bg_hover,
        "bgActive": bg_active,
        "borderDim": border_dim,
        "borderGlow": "#40" + acc_sky.lstrip("#"),
        "borderActive": acc_sky,
        "accentViolet": acc_violet,
        "accentIndigo": acc_indigo,
        "accentCyan": acc_cyan,
        "accentSky": acc_sky,
        "accentEmerald": acc_emerald,
        "accentAmber": acc_amber,
        "accentRose": acc_rose,
        "textPrimary": "#F8FAFC",
        "textSecondary": "#CBD5E1",
        "textMuted": "#94A3B8",
        "textOnAccent": "#FFFFFF"
    }

    return theme_obj

def save_custom_theme(theme_obj):
    os.makedirs(STATE_DIR, exist_ok=True)
    custom_themes = {}
    if os.path.exists(CUSTOM_THEMES_FILE):
        try:
            with open(CUSTOM_THEMES_FILE, "r") as f:
                data = json.load(f)
                custom_themes = data.get("themes", {})
        except Exception:
            custom_themes = {}

    theme_id = theme_obj["id"]
    custom_themes[theme_id] = theme_obj

    with open(CUSTOM_THEMES_FILE, "w") as f:
        json.dump({"themes": custom_themes}, f, indent=2)

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Create a custom theme for Antigravity Quickshell")
    parser.add_argument("--name", default="Custom Theme", help="Theme display name")
    parser.add_argument("--primary", default="#38BDF8", help="Primary accent hex code")
    parser.add_argument("--secondary", default="#A78BFA", help="Secondary accent hex code")
    parser.add_argument("--base", default="#090D14", help="Base dark background hex code")
    parser.add_argument("--wallpaper", default="", help="Wallpaper image path")
    parser.add_argument("--apply", action="store_true", help="Immediately activate theme")
    parser.add_argument("--no-save", action="store_true", help="Do not persist to disk")

    args = parser.parse_args()

    theme_obj = build_custom_theme(args.name, args.primary, args.secondary, args.base, args.wallpaper)

    if not args.no_save:
        save_custom_theme(theme_obj)

    if args.apply:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(THEME_STATE_FILE, "w") as f:
            json.dump({"currentTheme": theme_obj["id"]}, f, indent=2)

        script_dir = os.path.dirname(os.path.abspath(__file__))
        subprocess.run(["python3", os.path.join(script_dir, "apply_kitty_theme.py"), theme_obj["id"]], capture_output=True)
        subprocess.run(["python3", os.path.join(script_dir, "apply_system_theme.py"), theme_obj["id"]], capture_output=True)
        subprocess.run(["qs", "-c", "antigravity", "ipc", "call", "theme", "set", theme_obj["id"]], capture_output=True)

    print(json.dumps(theme_obj))

if __name__ == "__main__":
    main()
