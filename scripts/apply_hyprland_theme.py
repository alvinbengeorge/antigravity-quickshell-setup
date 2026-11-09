#!/usr/bin/env python3
"""
Antigravity Hyprland Dynamic Theme Syncer
Synchronizes Hyprland's active window borders and shadow glow with Quickshell's active theme.
"""

import os
import re
import sys
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

try:
    from apply_hyprlock_theme import resolve_palette
except ImportError:
    def resolve_palette(k): return {}

HYPR_DIR = os.path.expanduser("~/.config/hypr")
HYPR_CONF = os.path.join(HYPR_DIR, "hyprland.conf")
HYPR_LUA = os.path.join(HYPR_DIR, "hyprland.lua")

def apply_hyprland_theme(theme_key):
    palette = resolve_palette(theme_key)
    if not palette:
        return

    primary = palette.get("borderActive", "#2962FF").lstrip("#")[:6].lower()
    secondary = palette.get("accentCyan", palette.get("accentSky", "#00F0FF")).lstrip("#")[:6].lower()
    dim = palette.get("borderDim", palette.get("bgCard", "#1C2B42")).lstrip("#")[:6].lower()

    # 1. Update running compositor in real-time via Lua eval
    lua_cmd = f'''
    hl.config({{
        general = {{
            col = {{
                active_border = {{
                    colors = {{"rgba({primary}ee)", "rgba({secondary}ee)"}},
                    angle = 45
                }},
                inactive_border = "rgba({dim}aa)"
            }}
        }},
        decoration = {{
            shadow = {{
                enabled = true,
                range = 28,
                render_power = 4,
                color = "rgba({primary}44)",
                color_inactive = "rgba(00000044)"
            }}
        }}
    }})
    '''

    try:
        subprocess.run(["hyprctl", "eval", lua_cmd], capture_output=True, timeout=2)
    except Exception:
        pass

    # 2. Persist to hyprland.lua
    if os.path.exists(HYPR_LUA):
        try:
            with open(HYPR_LUA, "r") as f:
                content = f.read()

            content = re.sub(
                r'active_border\s*=\s*\{\s*colors\s*=\s*\{[^}]+\}\s*,\s*angle\s*=\s*\d+\s*\}',
                f'active_border   = {{ colors = {{"rgba({primary}ee)", "rgba({secondary}ee)"}}, angle = 45 }}',
                content
            )
            content = re.sub(
                r'inactive_border\s*=\s*"[^"]+"',
                f'inactive_border = "rgba({dim}aa)"',
                content
            )
            content = re.sub(
                r'shadow\s*=\s*\{[^}]*?color\s*=\s*"[^"]+"',
                lambda m: re.sub(r'color\s*=\s*"[^"]+"', f'color = "rgba({primary}44)"', m.group(0)),
                content,
                flags=re.DOTALL
            )

            with open(HYPR_LUA, "w") as f:
                f.write(content)
        except Exception:
            pass

    # 3. Persist to hyprland.conf
    if os.path.exists(HYPR_CONF):
        try:
            with open(HYPR_CONF, "r") as f:
                conf = f.read()

            conf = re.sub(
                r'col\.active_border\s*=\s*[^\n]+',
                f'col.active_border = rgba({primary}ee) rgba({secondary}ee) 45deg',
                conf
            )
            conf = re.sub(
                r'col\.inactive_border\s*=\s*[^\n]+',
                f'col.inactive_border = rgba({dim}aa)',
                conf
            )
            conf = re.sub(
                r'shadow\s*\{[^}]*?color\s*=\s*[^\n]+',
                lambda m: re.sub(r'color\s*=\s*[^\n]+', f'color = rgba({primary}44)', m.group(0)),
                conf,
                flags=re.DOTALL
            )

            with open(HYPR_CONF, "w") as f:
                f.write(conf)
        except Exception:
            pass

def main():
    theme_key = sys.argv[1] if len(sys.argv) > 1 else "askmeidentity"
    apply_hyprland_theme(theme_key)

if __name__ == "__main__":
    main()
