#!/usr/bin/env python3
import os
import sys
import json
import subprocess

STATE_DIR = os.path.expanduser("~/.local/state/quickshell/user/generated/terminal")
THEME_CONF = os.path.join(STATE_DIR, "kitty-theme.conf")

THEMES = {
    "arythmatic": {
        "bg": "#080B10",
        "fg": "#F8FAFC",
        "cursor": "#FFAA00",
        "sel_bg": "#222C40",
        "sel_fg": "#F8FAFC",
        "colors": [
            "#0E131C", "#F43F5E", "#00C758", "#FFAA00", "#FF8C00", "#FFC533", "#00C758", "#8E9EB5",
            "#171F2E", "#FB7185", "#05DF72", "#FFC533", "#FFAA00", "#FFD266", "#38E1FF", "#F8FAFC"
        ],
        "starship": {
            "255": "#FFAA00", "254": "#FF8C00", "253": "#FFC533", "252": "#1C2536",
            "251": "#00C758", "250": "#05DF72", "249": "#F43F5E", "248": "#0E131C",
            "232": "#080B10", "233": "#F8FAFC", "234": "#141B29", "235": "#171F2E",
            "236": "#FFAA00", "237": "#00C758", "238": "#F43F5E", "239": "#FB7185",
            "240": "#080B10", "243": "#FFAA00", "244": "#FFC533", "245": "#8E9EB5"
        }
    },
    "askmeidentity": {
        "bg": "#080B11",
        "fg": "#F8FAFC",
        "cursor": "#00F0FF",
        "sel_bg": "#1C2B42",
        "sel_fg": "#F8FAFC",
        "colors": [
            "#0E1522", "#F43F5E", "#60B01C", "#F59E0B", "#2962FF", "#60B01C", "#00F0FF", "#8295AD",
            "#172338", "#FB7185", "#78D32E", "#FBBF24", "#3D7BFF", "#8AE63D", "#38E1FF", "#F8FAFC"
        ],
        "starship": {
            "255": "#2962FF", "254": "#1965D8", "253": "#00F0FF", "252": "#1C2B42",
            "251": "#60B01C", "250": "#78D32E", "249": "#F43F5E", "248": "#0E1522",
            "232": "#080B11", "233": "#F8FAFC", "234": "#141F32", "235": "#172338",
            "236": "#2962FF", "237": "#60B01C", "238": "#F43F5E", "239": "#FB7185",
            "240": "#080B11", "243": "#2962FF", "244": "#00F0FF", "245": "#8295AD"
        }
    },
    "deepspace": {
        "bg": "#090D14",
        "fg": "#F8FAFC",
        "cursor": "#8B5CF6",
        "sel_bg": "#1E2B43",
        "sel_fg": "#F8FAFC",
        "colors": [
            "#141D2D", "#F43F5E", "#10B981", "#F59E0B", "#38BDF8", "#8B5CF6", "#06B6D4", "#94A3B8",
            "#1E293B", "#FB7185", "#34D399", "#FBBF24", "#60A5FA", "#A78BFA", "#22D3EE", "#F8FAFC"
        ],
        "starship": {
            "255": "#8B5CF6", "254": "#6366F1", "253": "#38BDF8", "252": "#1E2B43",
            "251": "#06B6D4", "250": "#10B981", "249": "#F43F5E", "248": "#141D2D",
            "232": "#090D14", "233": "#F8FAFC", "234": "#1E293B", "235": "#1E2B43",
            "236": "#8B5CF6", "237": "#6366F1", "238": "#F43F5E", "239": "#FB7185",
            "240": "#090D14", "243": "#8B5CF6", "244": "#F43F5E", "245": "#64748B"
        }
    },
    "catppuccin": {
        "bg": "#1E1E2E",
        "fg": "#CDD6F4",
        "cursor": "#F5E0DC",
        "sel_bg": "#45475A",
        "sel_fg": "#CDD6F4",
        "colors": [
            "#45475A", "#F38BA8", "#A6E3A1", "#F9E2AF", "#89B4FA", "#F5C2E7", "#94E2D5", "#BAC2DE",
            "#585B70", "#F38BA8", "#A6E3A1", "#F9E2AF", "#89B4FA", "#F5C2E7", "#94E2D5", "#A6ADC8"
        ],
        "starship": {
            "255": "#CBA6F7", "254": "#B4BEFE", "253": "#74C7EC", "252": "#313244",
            "251": "#89DCEB", "250": "#A6E3A1", "249": "#F38BA8", "248": "#181825",
            "232": "#11111B", "233": "#CDD6F4", "234": "#313244", "235": "#45475A",
            "236": "#CBA6F7", "237": "#B4BEFE", "238": "#F38BA8", "239": "#F5C2E7",
            "240": "#11111B", "243": "#CBA6F7", "244": "#F38BA8", "245": "#A6ADC8"
        }
    },
    "tokyonight": {
        "bg": "#1A1B26",
        "fg": "#C0CAF5",
        "cursor": "#C0CAF5",
        "sel_bg": "#283457",
        "sel_fg": "#C0CAF5",
        "colors": [
            "#15161E", "#F7768E", "#9ECE6A", "#E0AF68", "#7AA2F7", "#BB9AF7", "#7DCFFF", "#A9B1D6",
            "#414868", "#F7768E", "#9ECE6A", "#E0AF68", "#7AA2F7", "#BB9AF7", "#7DCFFF", "#C0CAF5"
        ],
        "starship": {
            "255": "#BB9AF7", "254": "#7AA2F7", "253": "#7DCFFF", "252": "#292E42",
            "251": "#2AC3DE", "250": "#9ECE6A", "249": "#F7768E", "248": "#1F2335",
            "232": "#16161E", "233": "#C0CAF5", "234": "#292E42", "235": "#343B58",
            "236": "#BB9AF7", "237": "#7AA2F7", "238": "#F7768E", "239": "#FF9E64",
            "240": "#16161E", "243": "#BB9AF7", "244": "#F7768E", "245": "#565F89"
        }
    },
    "nord": {
        "bg": "#2E3440",
        "fg": "#ECEFF4",
        "cursor": "#D8DEE9",
        "sel_bg": "#434C5E",
        "sel_fg": "#ECEFF4",
        "colors": [
            "#3B4252", "#BF616A", "#A3BE8C", "#EBCB8B", "#81A1C1", "#B48EAD", "#88C0D0", "#E5E9F0",
            "#4C566A", "#BF616A", "#A3BE8C", "#EBCB8B", "#81A1C1", "#B48EAD", "#8FBCBB", "#ECEFF4"
        ],
        "starship": {
            "255": "#88C0D0", "254": "#81A1C1", "253": "#8FBCBB", "252": "#3B4252",
            "251": "#5E81AC", "250": "#A3BE8C", "249": "#BF616A", "248": "#2E3440",
            "232": "#242933", "233": "#ECEFF4", "234": "#3B4252", "235": "#434C5E",
            "236": "#88C0D0", "237": "#B48EAD", "238": "#BF616A", "239": "#EBCB8B",
            "240": "#242933", "243": "#88C0D0", "244": "#BF616A", "245": "#98A2B3"
        }
    },
    "cyberpunk": {
        "bg": "#0F0A1C",
        "fg": "#FFF0FA",
        "cursor": "#FF007F",
        "sel_bg": "#322353",
        "sel_fg": "#00F0FF",
        "colors": [
            "#18122B", "#FF007F", "#10E599", "#FFE600", "#38BDF8", "#D946EF", "#00F0FF", "#E0B0DF",
            "#462F76", "#FF3399", "#33FFBB", "#FFFF33", "#60A5FA", "#E879F9", "#38BDF8", "#FFFFFF"
        ],
        "starship": {
            "255": "#FF007F", "254": "#D946EF", "253": "#00F0FF", "252": "#21193D",
            "251": "#10E599", "250": "#FFE600", "249": "#FF007F", "248": "#18122B",
            "232": "#08040C", "233": "#FFF0FA", "234": "#21193D", "235": "#322353",
            "236": "#FF007F", "237": "#D946EF", "238": "#FF007F", "239": "#FFE600",
            "240": "#08040C", "243": "#FF007F", "244": "#FF007F", "245": "#9F7B9E"
        }
    },
    "gruvbox": {
        "bg": "#282828",
        "fg": "#EBDBB2",
        "cursor": "#EBDBB2",
        "sel_bg": "#504945",
        "sel_fg": "#EBDBB2",
        "colors": [
            "#282828", "#CC241D", "#98971A", "#D79921", "#458588", "#B16286", "#689D6A", "#A89984",
            "#928374", "#FB4934", "#B8BB26", "#FABD2F", "#83A598", "#D3869B", "#8EC07C", "#EBDBB2"
        ],
        "starship": {
            "255": "#FABD2F", "254": "#FE8019", "253": "#8EC07C", "252": "#3C3836",
            "251": "#83A598", "250": "#B8BB26", "249": "#FB4934", "248": "#32302F",
            "232": "#1D2021", "233": "#EBDBB2", "234": "#32302F", "235": "#504945",
            "236": "#FABD2F", "237": "#D3869B", "238": "#FB4934", "239": "#FE8019",
            "240": "#1D2021", "243": "#FABD2F", "244": "#FB4934", "245": "#A89984"
        }
    }
}

CUSTOM_THEMES_FILE = os.path.expanduser("~/.local/state/quickshell/user/antigravity-custom-themes.json")
TEMP_THEME_FILE = os.path.expanduser("~/.local/state/quickshell/user/temp-wallpaper-theme.json")

def palette_to_kitty(p):
    bg = p.get("bgBase", "#090D14")
    fg = p.get("textPrimary", "#F8FAFC")
    acc_sky = p.get("accentSky", "#38BDF8")
    acc_violet = p.get("accentViolet", "#A78BFA")
    acc_cyan = p.get("accentCyan", "#22D3EE")
    acc_emerald = p.get("accentEmerald", "#34D399")
    acc_amber = p.get("accentAmber", "#FBBF24")
    acc_rose = p.get("accentRose", "#FB7185")
    bg_pill = p.get("bgPill", "#141D2D")
    bg_hover = p.get("bgHover", "#1E2B43")
    border_dim = p.get("borderDim", "#1E293B")
    return {
        "bg": bg,
        "fg": fg,
        "cursor": acc_violet,
        "sel_bg": bg_hover,
        "sel_fg": fg,
        "colors": [
            bg_pill, acc_rose, acc_emerald, acc_amber, acc_sky, acc_violet, acc_cyan, p.get("textMuted", "#94A3B8"),
            border_dim, acc_rose, acc_emerald, acc_amber, acc_sky, acc_violet, acc_cyan, fg
        ],
        "starship": {
            "255": acc_violet, "254": p.get("accentIndigo", acc_sky), "253": acc_sky, "252": bg_hover,
            "251": acc_cyan, "250": acc_emerald, "249": acc_rose, "248": bg_pill,
            "232": bg, "233": fg, "234": border_dim, "235": bg_hover,
            "236": acc_violet, "237": p.get("accentIndigo", acc_sky), "238": acc_rose, "239": acc_rose,
            "240": bg, "243": acc_violet, "244": acc_rose, "245": p.get("textMuted", "#94A3B8")
        }
    }

def generate_conf(theme_key):
    t = None
    if theme_key in ("temp_wallpaper", "from_wp") and os.path.exists(TEMP_THEME_FILE):
        try:
            with open(TEMP_THEME_FILE, "r") as f:
                data = json.load(f)
                temp_obj = data.get("theme", data)
                if temp_obj:
                    t = palette_to_kitty(temp_obj)
        except Exception:
            pass
    if not t:
        t = THEMES.get(theme_key)
    if not t and os.path.exists(CUSTOM_THEMES_FILE):
        try:
            with open(CUSTOM_THEMES_FILE, "r") as f:
                data = json.load(f)
                custom = data.get("themes", {}).get(theme_key)
                if custom:
                    t = palette_to_kitty(custom)
        except Exception:
            pass
    if not t:
        t = THEMES["deepspace"]
    lines = []
    lines.append(f"# Generated by Antigravity Quickshell - Theme: {theme_key}")
    lines.append(f"background            {t['bg']}")
    lines.append(f"foreground            {t['fg']}")
    lines.append(f"cursor                {t['cursor']}")
    lines.append(f"selection_background  {t['sel_bg']}")
    lines.append(f"selection_foreground  {t['sel_fg']}")
    lines.append("")
    for i, c in enumerate(t["colors"]):
        lines.append(f"color{i:<17} {c}")
    lines.append("")
    lines.append("# Starship prompt colors")
    for k, v in t["starship"].items():
        lines.append(f"color{k:<17} {v}")
    lines.append("")
    return "\n".join(lines)

def main():
    theme_key = sys.argv[1] if len(sys.argv) > 1 else "deepspace"
    os.makedirs(STATE_DIR, exist_ok=True)
    content = generate_conf(theme_key)
    with open(THEME_CONF, "w") as f:
        f.write(content)

    # Signal kitty instances to reload config
    subprocess.run(["pkill", "-SIGUSR1", "kitty"], capture_output=True)

if __name__ == "__main__":
    main()
