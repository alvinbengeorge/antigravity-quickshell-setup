#!/usr/bin/env python3
"""
AI Command Engine powered by FunctionGemma (via Ollama)
Translates natural language user prompts into Hyprland, Quickshell IPC, and system actions.
"""

import sys
import os
import re
import json
import subprocess
import urllib.request
import urllib.error

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "set_volume",
            "description": "Adjust or set audio volume level, or toggle mute",
            "parameters": {
                "type": "object",
                "properties": {
                    "level": {"type": "integer", "description": "Volume percentage from 0 to 100"},
                    "action": {"type": "string", "enum": ["up", "down", "mute", "unmute", "set"], "description": "Action type"}
                }
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "set_brightness",
            "description": "Adjust or set screen display brightness level",
            "parameters": {
                "type": "object",
                "properties": {
                    "percent": {"type": "integer", "description": "Brightness percentage from 1 to 100"},
                    "action": {"type": "string", "enum": ["up", "down", "set"], "description": "Relative or absolute adjustment"}
                }
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "media_playback",
            "description": "Control currently playing media or music",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {"type": "string", "enum": ["play", "pause", "play_pause", "next", "previous", "stop"]}
                },
                "required": ["action"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "switch_workspace",
            "description": "Switch Hyprland active desktop workspace",
            "parameters": {
                "type": "object",
                "properties": {
                    "workspace_id": {"type": "integer", "description": "Target workspace number (1-9)"}
                },
                "required": ["workspace_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "window_layout",
            "description": "Control Hyprland window tiling, layout, or state",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": [
                            "fullscreen", "float", "close", "scroll_right", "scroll_left",
                            "swap_right", "swap_left", "promote_column"
                        ]
                    }
                },
                "required": ["action"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "launch_app",
            "description": "Launch an application or system utility",
            "parameters": {
                "type": "object",
                "properties": {
                    "app": {
                        "type": "string",
                        "enum": ["terminal", "browser", "files", "scratchpad", "task_runner", "docker", "whatsapp", "system_monitor"]
                    }
                },
                "required": ["app"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "system_power",
            "description": "Perform system lock, logout, reboot, or screenshot",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {"type": "string", "enum": ["lock", "screenshot", "reboot", "poweroff", "logout"]}
                },
                "required": ["action"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "quickshell_panel",
            "description": "Toggle a Quickshell HUD or management panel",
            "parameters": {
                "type": "object",
                "properties": {
                    "panel": {
                        "type": "string",
                        "enum": ["docker", "clipboard", "wallpaper_theme", "system_monitor", "control_center", "session", "antigravity", "lite_mode"]
                    }
                },
                "required": ["panel"]
            }
        }
    }
]

def notify(title, message):
    try:
        subprocess.run(["notify-send", "-a", "AI Command Bar", title, message], check=False)
    except Exception:
        pass

def run_cmd(cmd_list):
    try:
        subprocess.run(cmd_list, check=False)
    except Exception as e:
        print(f"Error running {cmd_list}: {e}", file=sys.stderr)

def execute_tool(name, args):
    print(f"Executing tool: {name} with args: {args}")

    if name == "set_volume":
        action = args.get("action", "")
        level = args.get("level")
        if action == "mute" or (level == 0 and action != "up"):
            run_cmd(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1"])
            notify("Audio", "Muted audio output")
        elif action == "unmute":
            run_cmd(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
            notify("Audio", "Unmuted audio output")
        elif action == "up":
            delta = f"{level or 5}%+"
            run_cmd(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", delta])
            notify("Volume", f"Increased volume ({delta})")
        elif action == "down":
            delta = f"{level or 5}%-"
            run_cmd(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", delta])
            notify("Volume", f"Decreased volume ({delta})")
        elif level is not None:
            pct = min(150, max(0, int(level)))
            run_cmd(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{pct/100:.2f}"])
            run_cmd(["qs", "-c", "antigravity", "ipc", "call", "osd", "volume", str(pct)])
            notify("Volume", f"Set volume to {pct}%")
        return True

    elif name == "set_brightness":
        action = args.get("action", "")
        pct = args.get("percent")
        if action == "up":
            run_cmd(["brightnessctl", "set", "5%+"])
            notify("Brightness", "Increased display brightness")
        elif action == "down":
            run_cmd(["brightnessctl", "set", "5%-"])
            notify("Brightness", "Decreased display brightness")
        elif pct is not None:
            pct = min(100, max(1, int(pct)))
            run_cmd(["brightnessctl", "set", f"{pct}%"])
            run_cmd(["qs", "-c", "antigravity", "ipc", "call", "osd", "brightness", str(pct)])
            notify("Brightness", f"Set display brightness to {pct}%")
        return True

    elif name == "media_playback":
        action = args.get("action", "play_pause")
        action_map = {
            "play": "play", "pause": "pause", "play_pause": "play-pause",
            "next": "next", "previous": "previous", "stop": "stop"
        }
        sub_act = action_map.get(action, "play-pause")
        run_cmd(["playerctl", sub_act])
        notify("Media", f"Media {sub_act}")
        return True

    elif name == "switch_workspace":
        ws = args.get("workspace_id", 1)
        # Use native Hyprland Lua dispatcher
        run_cmd(["hyprctl", "dispatch", f"hl.dsp.focus({{ workspace = {ws} }})"])
        notify("Workspace", f"Switched to Workspace {ws}")
        return True

    elif name == "window_layout":
        action = args.get("action")
        if action == "fullscreen":
            run_cmd(["hyprctl", "dispatch", "hl.dsp.window.fullscreen({ action = 'toggle' })"])
        elif action == "float":
            run_cmd(["hyprctl", "dispatch", "hl.dsp.window.float({ action = 'toggle' })"])
        elif action == "close":
            run_cmd(["hyprctl", "dispatch", "hl.dsp.window.close()"])
        elif action == "scroll_right":
            run_cmd(["hyprctl", "dispatch", 'hl.dsp.layout("move +col")'])
        elif action == "scroll_left":
            run_cmd(["hyprctl", "dispatch", 'hl.dsp.layout("move -col")'])
        elif action == "swap_right":
            run_cmd(["hyprctl", "dispatch", 'hl.dsp.layout("swapcol r")'])
        elif action == "swap_left":
            run_cmd(["hyprctl", "dispatch", 'hl.dsp.layout("swapcol l")'])
        elif action == "promote_column":
            run_cmd(["hyprctl", "dispatch", 'hl.dsp.layout("promote")'])
        notify("Window Layout", f"Action: {action}")
        return True

    elif name == "launch_app":
        app = args.get("app")
        app_map = {
            "terminal": ["kitty"],
            "browser": ["google-chrome"],
            "files": ["nautilus"],
            "scratchpad": [os.path.expanduser("~/.config/hypr/scripts/scratchpad.sh")],
            "task_runner": ["qs", "-c", "antigravity", "ipc", "call", "runner", "toggle"],
            "docker": ["qs", "-c", "antigravity", "ipc", "call", "docker", "toggle"],
            "whatsapp": ["qs", "-c", "antigravity", "ipc", "call", "whatsapp", "toggle"],
            "system_monitor": ["qs", "-c", "antigravity", "ipc", "call", "systemMonitor", "toggle"]
        }
        cmd = app_map.get(app)
        if cmd:
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            notify("Application", f"Launched {app}")
            return True

    elif name == "system_power":
        action = args.get("action")
        if action == "lock":
            subprocess.Popen(["hyprlock"])
        elif action == "screenshot":
            subprocess.Popen(["bash", "-c", 'grim -g "$(slurp)" - | wl-copy'])
            notify("Screenshot", "Selected area copied to clipboard")
        elif action == "reboot":
            run_cmd(["systemctl", "reboot"])
        elif action == "poweroff":
            run_cmd(["systemctl", "poweroff"])
        elif action == "logout":
            run_cmd(["hyprctl", "dispatch", "hl.dsp.exit()"])
        return True

    elif name == "quickshell_panel":
        panel = args.get("panel")
        panel_map = {
            "docker": "docker", "clipboard": "clipboard", "wallpaper_theme": "wallpaperTheme",
            "system_monitor": "systemMonitor", "control_center": "controlCenter",
            "session": "session", "antigravity": "antigravity", "lite_mode": "liteMode"
        }
        target = panel_map.get(panel)
        if target:
            run_cmd(["qs", "-c", "antigravity", "ipc", "call", target, "toggle"])
            notify("Quickshell", f"Toggled {panel}")
            return True

    return False

def fast_tier0(query):
    """Instant regex match (<1ms) for common short commands."""
    q = query.strip().lower()

    # Audio mute / unmute
    if q in ("mute", "mute audio", "mute sound", "silence"):
        return execute_tool("set_volume", {"action": "mute"})
    if q in ("unmute", "unmute audio", "unmute sound"):
        return execute_tool("set_volume", {"action": "unmute"})

    # Volume percentage: e.g. "vol 60", "volume 80%"
    m_vol = re.match(r"^(?:vol|volume)\s*(\d{1,3})%?$", q)
    if m_vol:
        return execute_tool("set_volume", {"level": int(m_vol.group(1)), "action": "set"})

    # Brightness: e.g. "bright 50", "brightness 70%"
    m_bri = re.match(r"^(?:bri|bright|brightness)\s*(\d{1,3})%?$", q)
    if m_bri:
        return execute_tool("set_brightness", {"percent": int(m_bri.group(1)), "action": "set"})

    # Workspace: e.g. "ws 7", "workspace 3"
    m_ws = re.match(r"^(?:ws|workspace)\s*(\d+)$", q)
    if m_ws:
        return execute_tool("switch_workspace", {"workspace_id": int(m_ws.group(1))})

    # Scratchpad: e.g. "scratch", "scratchpad"
    if q in ("scratch", "scratchpad", "terminal dropdown", "drop terminal"):
        return execute_tool("launch_app", {"app": "scratchpad"})

    # Lock: e.g. "lock", "lock screen"
    if q in ("lock", "lock screen", "lock laptop"):
        return execute_tool("system_power", {"action": "lock"})

    # Ribbon scroll
    if q in ("ribbon right", "scroll right", "next column"):
        return execute_tool("window_layout", {"action": "scroll_right"})
    if q in ("ribbon left", "scroll left", "prev column", "previous column"):
        return execute_tool("window_layout", {"action": "scroll_left"})

    # Fullscreen / Float / Close
    if q in ("fullscreen", "toggle fullscreen", "maximize"):
        return execute_tool("window_layout", {"action": "fullscreen"})
    if q in ("float", "toggle float", "floating"):
        return execute_tool("window_layout", {"action": "float"})
    if q in ("close", "close window", "kill window"):
        return execute_tool("window_layout", {"action": "close"})

    # Media controls
    if q in ("play", "pause", "play-pause", "toggle music"):
        return execute_tool("media_playback", {"action": "play_pause"})
    if q in ("next song", "next track", "skip track"):
        return execute_tool("media_playback", {"action": "next"})
    if q in ("prev song", "previous song", "prev track"):
        return execute_tool("media_playback", {"action": "previous"})

    return False

def query_functiongemma(query):
    """Send natural language query to FunctionGemma in Ollama."""
    payload = {
        "model": "functiongemma",
        "messages": [{"role": "user", "content": query}],
        "tools": TOOLS,
        "stream": False
    }
    req = urllib.request.Request(
        "http://localhost:11434/api/chat",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        msg = data.get("message", {})
        tool_calls = msg.get("tool_calls", [])
        if tool_calls:
            fn = tool_calls[0].get("function", {})
            name = fn.get("name")
            args = fn.get("arguments", {})
            return name, args

        # Fallback check for raw function call tokens in content if parser missed it
        content = msg.get("content", "")
        m = re.search(r"(?:model:|<start_function_call>call:)(\w+)(\{.*?\})", content)
        if m:
            fname = m.group(1)
            fargs_str = m.group(2)
            try:
                fargs = json.loads(fargs_str)
            except Exception:
                fargs = {}
            return fname, fargs

        return None, None
    except Exception as e:
        print(f"Error querying FunctionGemma: {e}", file=sys.stderr)
        return None, None

def main():
    if len(sys.argv) < 2:
        print("Usage: ai_command_engine.py '<natural language command>'")
        sys.exit(1)

    query = " ".join(sys.argv[1:]).strip()
    if not query:
        sys.exit(0)

    # 1. Try Tier 0 Fast Path (<1ms)
    if fast_tier0(query):
        sys.exit(0)

    # 2. Query FunctionGemma
    name, args = query_functiongemma(query)
    if name:
        if execute_tool(name, args):
            sys.exit(0)

    # 3. Fallback: If not handled as a tool call, execute via shell or open Antigravity
    notify("AI Command", f"Could not map: '{query}'. Opening Antigravity HUD.")
    run_cmd(["qs", "-c", "antigravity", "ipc", "call", "antigravity", "toggle"])

if __name__ == "__main__":
    main()
