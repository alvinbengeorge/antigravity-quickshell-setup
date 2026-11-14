#!/usr/bin/env python3
"""
Wallpaper Theme Generator for Antigravity Quickshell
Extracts color palette from the wallpaper and builds a cohesive dark theme.
"""

import os
import sys
import json
import re
import colorsys
import subprocess
from PIL import Image

STATE_DIR = os.path.expanduser("~/.local/state/quickshell/user")
CUSTOM_THEMES_FILE = os.path.join(STATE_DIR, "antigravity-custom-themes.json")
THEME_STATE_FILE = os.path.join(STATE_DIR, "antigravity-theme.json")
WALLPAPER_STATE_FILE = os.path.join(STATE_DIR, "antigravity-wallpaper.json")
TEMP_THEME_FILE = os.path.join(STATE_DIR, "temp-wallpaper-theme.json")

def to_hex(r, g, b):
    return f"#{int(max(0, min(255, r))):02X}{int(max(0, min(255, g))):02X}{int(max(0, min(255, b))):02X}"

def hsl_to_hex(h, s, l):
    r, g, b = colorsys.hls_to_rgb(h % 1.0, max(0.0, min(1.0, l)), max(0.0, min(1.0, s)))
    return to_hex(r * 255, g * 255, b * 255)

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 6:
        return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
    return (128, 128, 128)

def get_current_wallpaper_path():
    if os.path.exists(WALLPAPER_STATE_FILE):
        try:
            with open(WALLPAPER_STATE_FILE, "r") as f:
                data = json.load(f)
                manual = data.get("manualWallpaper", "")
                if manual and os.path.exists(manual):
                    return manual
        except Exception:
            pass

    # Check theme state
    if os.path.exists(THEME_STATE_FILE):
        try:
            with open(THEME_STATE_FILE, "r") as f:
                data = json.load(f)
                cur = data.get("currentTheme", "deepspace")
                # default wallpapers
                defaults = {
                    "deepspace": os.path.expanduser("~/Pictures/Wallpapers/fedora-neon-blue-black.jpg"),
                    "catppuccin": os.path.expanduser("~/Pictures/Wallpapers/wallhaven-rqyoo1.png"),
                    "tokyonight": os.path.expanduser("~/Pictures/Wallpapers/fedora-neon.jpg"),
                    "nord": os.path.expanduser("~/Pictures/Wallpapers/wallhaven-nrd9oj.jpg"),
                    "cyberpunk": os.path.expanduser("~/Pictures/Wallpapers/wallhaven-95kpwx.jpg"),
                    "gruvbox": os.path.expanduser("~/Pictures/Wallpapers/wallhaven-48wlq2.jpg")
                }
                if cur in defaults and os.path.exists(defaults[cur]):
                    return defaults[cur]
        except Exception:
            pass

    # Fallback to any wallpaper in ~/Pictures/Wallpapers
    wp_dir = os.path.expanduser("~/Pictures/Wallpapers")
    if os.path.isdir(wp_dir):
        files = [os.path.join(wp_dir, f) for f in sorted(os.listdir(wp_dir)) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp'))]
        if files:
            return files[0]

    return ""

def extract_palette(image_path, theme_name=None):
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Image not found: {image_path}")

    im = Image.open(image_path).convert("RGB")
    im.thumbnail((160, 160))

    # Quantize to 32 colors
    q = im.quantize(colors=32, method=Image.Quantize.MEDIANCUT)
    palette_data = q.getpalette()[:96]
    rgbs = [palette_data[i*3:i*3+3] for i in range(32)]

    # Count occurrences
    counts = {}
    pixel_data = getattr(q, "get_flattened_data", q.getdata)()
    for p in pixel_data:
        counts[p] = counts.get(p, 0) + 1

    color_stats = []
    for idx, rgb in enumerate(rgbs):
        if idx in counts:
            r, g, b = rgb
            h, l, s = colorsys.rgb_to_hls(r/255.0, g/255.0, b/255.0)
            color_stats.append({
                "rgb": rgb, "h": h, "s": s, "l": l, "count": counts[idx]
            })

    # Identify base dark tone
    dark_tones = [c for c in color_stats if c["l"] < 0.28]
    if not dark_tones:
        dark_tones = sorted(color_stats, key=lambda c: c["l"])[:4]
    dark_tones.sort(key=lambda c: c["count"], reverse=True)
    base = dark_tones[0]

    base_h = base["h"]
    base_s = min(0.30, max(0.08, base["s"]))

    bg_base = hsl_to_hex(base_h, base_s, 0.05)
    bg_surface = hsl_to_hex(base_h, base_s, 0.08)
    bg_surface_glass = "#F2" + bg_surface.lstrip("#")
    bg_modal = hsl_to_hex(base_h, base_s, 0.11)
    bg_card = hsl_to_hex(base_h, base_s, 0.14)
    bg_pill = hsl_to_hex(base_h, base_s, 0.16)
    bg_hover = hsl_to_hex(base_h, base_s, 0.22)
    bg_active = hsl_to_hex(base_h, base_s, 0.28)
    border_dim = hsl_to_hex(base_h, base_s, 0.18)

    # Identify vibrant accent candidates
    # Sort by saturation & brightness
    accents_cand = [c for c in color_stats if 0.15 < c["l"] < 0.85 and c["s"] > 0.15]
    if len(accents_cand) < 3:
        accents_cand = sorted(color_stats, key=lambda c: c["s"], reverse=True)[:6]

    # Cluster accents by hue so they are distinct
    distinct_accents = []
    for c in sorted(accents_cand, key=lambda x: x["s"] * (0.6 + x["l"]), reverse=True):
        too_close = False
        for a in distinct_accents:
            diff = abs(c["h"] - a["h"])
            if min(diff, 1.0 - diff) < 0.08:
                too_close = True
                break
        if not too_close:
            distinct_accents.append(c)

    # Ensure at least 4 distinct vibrant accents
    primary_h = distinct_accents[0]["h"] if distinct_accents else base_h
    acc_sky = hsl_to_hex(primary_h, 0.85, 0.65)
    
    sec_h = distinct_accents[1]["h"] if len(distinct_accents) > 1 else (primary_h + 0.15) % 1.0
    acc_violet = hsl_to_hex(sec_h, 0.80, 0.68)
    
    third_h = distinct_accents[2]["h"] if len(distinct_accents) > 2 else (primary_h + 0.33) % 1.0
    acc_cyan = hsl_to_hex(third_h, 0.85, 0.62)

    acc_indigo = hsl_to_hex((primary_h + 0.05) % 1.0, 0.75, 0.65)
    acc_emerald = hsl_to_hex(0.35, 0.75, 0.62)
    acc_amber = hsl_to_hex(0.12, 0.88, 0.60)
    acc_rose = hsl_to_hex(0.97, 0.85, 0.66)

    # Try to fill specific semantic colors from candidate list if match exists
    for c in distinct_accents:
        ch = c["h"]
        if 0.25 <= ch <= 0.45:
            acc_emerald = hsl_to_hex(ch, max(0.65, c["s"]), 0.62)
        elif 0.07 <= ch <= 0.20:
            acc_amber = hsl_to_hex(ch, max(0.70, c["s"]), 0.60)
        elif ch >= 0.90 or ch <= 0.05:
            acc_rose = hsl_to_hex(ch, max(0.75, c["s"]), 0.65)

    # Determine closest GTK theme
    gtk_theme = "Obsidian-flow-blue-dark"
    if 0.50 <= primary_h <= 0.66:
        gtk_theme = "Obsidian-flow-blue-dark"
    elif 0.67 <= primary_h <= 0.85:
        gtk_theme = "Obsidian-flow-purple-dark"
    elif primary_h >= 0.90 or primary_h <= 0.06:
        gtk_theme = "Obsidian-flow-red-dark"
    elif 0.07 <= primary_h <= 0.20:
        gtk_theme = "Obsidian-flow-yellow-dark"
    elif 0.21 <= primary_h <= 0.45:
        gtk_theme = "Obsidian-flow-green-dark"

    # Friendly name
    if not theme_name:
        base_name = os.path.splitext(os.path.basename(image_path))[0]
        # Clean up filename (e.g. "fedora-neon-blue-black" -> "Fedora Neon Blue Black")
        clean_name = re.sub(r"[_\-]+", " ", base_name).strip().title()
        theme_name = f"{clean_name} (WP)"

    # Theme ID
    clean_id = "wp_" + re.sub(r"[^a-zA-Z0-9]+", "_", os.path.splitext(os.path.basename(image_path))[0].lower()).strip("_")

    theme_obj = {
        "id": clean_id,
        "name": theme_name,
        "wallpaper": image_path,
        "isCustom": True,
        "isWallpaperTheme": True,
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

def save_temp_theme(theme_obj):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(TEMP_THEME_FILE, "w") as f:
        json.dump({"theme": theme_obj}, f, indent=2)

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
    image_path = None
    theme_name = None
    save = True
    is_temp = False
    apply_now = False

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--apply":
            apply_now = True
        elif arg == "--temp":
            is_temp = True
            save = False
        elif arg == "--no-save":
            save = False
        elif arg == "--name" and i + 1 < len(args):
            theme_name = args[i + 1]
            i += 1
        elif not arg.startswith("--") and image_path is None:
            image_path = arg
        i += 1

    if not image_path:
        image_path = get_current_wallpaper_path()

    if not image_path:
        print(json.dumps({"error": "No wallpaper image found"}))
        sys.exit(1)

    theme_obj = extract_palette(image_path, theme_name)
    if is_temp:
        theme_obj["id"] = "temp_wallpaper"
        theme_obj["name"] = "From Wallpaper (Live)"
        theme_obj["isTemporary"] = True

    if is_temp:
        save_temp_theme(theme_obj)
    elif save:
        save_custom_theme(theme_obj)

    if apply_now:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        if is_temp:
            subprocess.run(["python3", os.path.join(script_dir, "apply_kitty_theme.py"), "temp_wallpaper"], capture_output=True)
            subprocess.run(["python3", os.path.join(script_dir, "apply_system_theme.py"), "temp_wallpaper"], capture_output=True)
        else:
            os.makedirs(STATE_DIR, exist_ok=True)
            theme_state = {"currentTheme": theme_obj["id"]}
            with open(THEME_STATE_FILE, "w") as f:
                json.dump(theme_state, f, indent=2)
            subprocess.run(["python3", os.path.join(script_dir, "apply_kitty_theme.py"), theme_obj["id"]], capture_output=True)
            subprocess.run(["python3", os.path.join(script_dir, "apply_system_theme.py"), theme_obj["id"]], capture_output=True)
            subprocess.run(["qs", "-c", "antigravity", "ipc", "call", "theme", "set", theme_obj["id"]], capture_output=True)

    print(json.dumps(theme_obj))

if __name__ == "__main__":
    main()
