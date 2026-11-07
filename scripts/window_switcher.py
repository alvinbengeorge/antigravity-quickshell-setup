#!/usr/bin/env python3
"""
Window Switcher & Mission Control Backend for Hyprland & Antigravity Quickshell
"""
import sys
import json
import subprocess

def get_icon_and_color(cls_name):
    c = (cls_name or "").lower()
    if "kitty" in c or "terminal" in c or "alacritty" in c:
        return {"icon": "code", "glyph": "💻", "color": "#38BDF8", "label": "TERMINAL"}
    elif "firefox" in c:
        return {"icon": "globe", "glyph": "🦊", "color": "#FB923C", "label": "BROWSER"}
    elif "chrome" in c or "chromium" in c or "brave" in c:
        return {"icon": "globe", "glyph": "🌐", "color": "#38BDF8", "label": "BROWSER"}
    elif "teams" in c:
        return {"icon": "activity", "glyph": "💬", "color": "#A78BFA", "label": "TEAMS"}
    elif "code" in c or "vsc" in c:
        return {"icon": "code", "glyph": "⚡", "color": "#60A5FA", "label": "IDE"}
    elif "software" in c:
        return {"icon": "layers", "glyph": "📦", "color": "#34D399", "label": "STORE"}
    elif "nautilus" in c or "files" in c:
        return {"icon": "folder", "glyph": "📁", "color": "#FBBF24", "label": "FILES"}
    elif "spotify" in c or "music" in c:
        return {"icon": "headphones", "glyph": "🎵", "color": "#34D399", "label": "AUDIO"}
    return {"icon": "monitor", "glyph": "🪟", "color": "#94A3B8", "label": "APP"}

def get_windows():
    try:
        clients_raw = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=2).stdout
        clients = json.loads(clients_raw) if clients_raw.strip() else []
    except Exception:
        clients = []

    try:
        active_raw = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=1).stdout
        active = json.loads(active_raw) if active_raw.strip() else {}
        active_addr = active.get("address", "")
    except Exception:
        active_addr = ""

    windows = []
    for c in clients:
        # Ignore unmapped / empty windows
        if not c.get("mapped", True) and not c.get("title", ""):
            continue
        addr = c.get("address", "")
        cls_name = c.get("class") or c.get("initialClass") or "Application"
        title = c.get("title") or c.get("initialTitle") or cls_name
        ws = c.get("workspace", {})
        ws_id = ws.get("id", 1)
        ws_name = ws.get("name", str(ws_id))
        monitor = c.get("monitor", 0)

        meta = get_icon_and_color(cls_name)

        windows.append({
            "address": addr,
            "title": title,
            "class": cls_name,
            "workspace_id": ws_id,
            "workspace_name": ws_name,
            "monitor": monitor,
            "floating": c.get("floating", False),
            "size": c.get("size", [0, 0]),
            "at": c.get("at", [0, 0]),
            "pid": c.get("pid", 0),
            "is_active": (addr == active_addr),
            "icon": meta["icon"],
            "glyph": meta["glyph"],
            "accent_color": meta["color"],
            "category_label": meta["label"]
        })

    # Sort so active window is first, or by workspace
    windows.sort(key=lambda w: (0 if w["is_active"] else 1, w["workspace_id"]))
    return windows

def focus_window(address):
    if not address:
        return {"status": "error"}
    code = f'return hl.dispatch(hl.dsp.focus({{ window = hl.get_window("address:{address}") }}))'
    res = subprocess.run(["hyprctl", "eval", code], capture_output=True, text=True)
    return {"status": "ok" if "ok" in res.stdout else "error"}

def close_window(address):
    if not address:
        return {"status": "error"}
    code = f'return hl.dispatch(hl.dsp.window.close({{ window = hl.get_window("address:{address}") }}))'
    res = subprocess.run(["hyprctl", "eval", code], capture_output=True, text=True)
    return {"status": "ok" if "ok" in res.stdout else "error"}

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "list":
        print(json.dumps(get_windows()))
    elif sys.argv[1] == "focus" and len(sys.argv) > 2:
        print(json.dumps(focus_window(sys.argv[2])))
    elif sys.argv[1] == "close" and len(sys.argv) > 2:
        print(json.dumps(close_window(sys.argv[2])))
    else:
        print(json.dumps(get_windows()))

if __name__ == "__main__":
    main()
