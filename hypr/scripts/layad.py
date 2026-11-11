#!/usr/bin/env python3
"""
layad - Resident Laya System 1 Daemon
Keeps Laya decision weights warm in memory and serves desktop intent requests
over a local UNIX domain socket ($XDG_RUNTIME_DIR/laya.sock).
"""

import os
import sys
import re
import time
import json
import signal
import socket
import subprocess

# PyTorch CPU optimization
import torch
torch.set_num_threads(4)
torch.set_grad_enabled(False)

import laya

SOCKET_PATH = os.path.join(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"), "laya.sock")

QUESTIONS = {
    "intent": {
        "type": "choice",
        "instructions": "What desktop action does the user want in `cmd`?",
        "criteria": {
            "volume": "change, mute, or adjust audio volume",
            "brightness": "change screen display brightness",
            "workspace": "switch workspace or navigate windows",
            "hud_ai": "open Antigravity HUD, Gemini AI, or desktop utility panels",
            "app_launch": "open an app like terminal, browser, or files",
            "system": "lock, reboot, screenshot, or power"
        }
    }
}

def notify(title, message):
    try:
        subprocess.run(["notify-send", "-a", "Laya AI", title, message], check=False)
    except Exception:
        pass

def run_command(cmd_list):
    try:
        return subprocess.run(cmd_list, capture_output=True, text=True, check=False)
    except Exception:
        return None

def execute_action(intent, prompt, num):
    cmd_desc = ""
    cmd_exec = []
    p = prompt.lower()

    if intent == "hud_ai":
        if any(w in p for w in ("docker", "container")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "docker", "toggle"]]
            cmd_desc = "Toggled Docker Manager Panel"
        elif any(w in p for w in ("whatsapp", "chat", "message")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "whatsapp", "toggle"]]
            cmd_desc = "Toggled WhatsApp Panel"
        elif any(w in p for w in ("clipboard", "clip", "history")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "clipboard", "toggle"]]
            cmd_desc = "Toggled Clipboard Manager"
        elif any(w in p for w in ("monitor", "ram", "cpu", "stats", "task")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "systemMonitor", "toggle"]]
            cmd_desc = "Toggled System Monitor"
        elif any(w in p for w in ("theme", "wallpaper")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "wallpaperTheme", "toggle"]]
            cmd_desc = "Toggled Wallpaper & Theme Dialog"
        elif any(w in p for w in ("control", "settings", "toggle")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "controlCenter", "toggle"]]
            cmd_desc = "Toggled Control Center"
        else:
            # Default for HUD, Gemini, Antigravity, or AI assistant
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "antigravity", "toggle"]]
            cmd_desc = "Opened Antigravity HUD (Gemini Assistant)"
        notify("Laya Desktop", cmd_desc)

    elif intent == "volume":
        if "mute" in p and "unmute" not in p:
            cmd_exec = [["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1"]]
            cmd_desc = "Muted audio output"
            notify("Laya Audio", cmd_desc)
        elif "unmute" in p:
            cmd_exec = [["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]]
            cmd_desc = "Unmuted audio output"
            notify("Laya Audio", cmd_desc)
        elif num is not None:
            pct = min(150, max(0, num))
            cmd_exec = [
                ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{pct/100:.2f}"],
                ["qs", "-c", "antigravity", "ipc", "call", "osd", "volume", str(pct)]
            ]
            cmd_desc = f"Set volume to {pct}%"
            notify("Laya Audio", cmd_desc)
        elif any(w in p for w in ("down", "lower", "quiet", "decrease")):
            cmd_exec = [
                ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "10%-"],
                ["qs", "-c", "antigravity", "ipc", "call", "osd", "volume", "40"]
            ]
            cmd_desc = "Decreased volume (-10%)"
            notify("Laya Audio", cmd_desc)
        else:
            cmd_exec = [
                ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "10%+"],
                ["qs", "-c", "antigravity", "ipc", "call", "osd", "volume", "60"]
            ]
            cmd_desc = "Increased volume (+10%)"
            notify("Laya Audio", cmd_desc)

    elif intent == "brightness":
        if num is not None:
            pct = min(100, max(1, num))
            cmd_exec = [
                ["brightnessctl", "set", f"{pct}%"],
                ["qs", "-c", "antigravity", "ipc", "call", "osd", "brightness", str(pct)]
            ]
            cmd_desc = f"Set screen brightness to {pct}%"
            notify("Laya Display", cmd_desc)
        elif any(w in p for w in ("dim", "down", "darker", "decrease", "lower")):
            cmd_exec = [
                ["brightnessctl", "set", "10%-"],
                ["qs", "-c", "antigravity", "ipc", "call", "osd", "brightness", "30"]
            ]
            cmd_desc = "Dimmed brightness (-10%)"
            notify("Laya Display", cmd_desc)
        else:
            cmd_exec = [
                ["brightnessctl", "set", "10%+"],
                ["qs", "-c", "antigravity", "ipc", "call", "osd", "brightness", "70"]
            ]
            cmd_desc = "Increased brightness (+10%)"
            notify("Laya Display", cmd_desc)

    elif intent == "workspace":
        if num is not None:
            cmd_exec = [["hyprctl", "dispatch", f"hl.dsp.focus({{ workspace = {num} }})"]]
            cmd_desc = f"Switched to Workspace {num}"
            notify("Laya Workspace", cmd_desc)
        elif any(w in p for w in ("right", "next")):
            cmd_exec = [["hyprctl", "dispatch", 'hl.dsp.layout("move +col")']]
            cmd_desc = "Scrolled ribbon to next column"
            notify("Laya Ribbon", cmd_desc)
        elif any(w in p for w in ("left", "prev", "previous")):
            cmd_exec = [["hyprctl", "dispatch", 'hl.dsp.layout("move -col")']]
            cmd_desc = "Scrolled ribbon to previous column"
            notify("Laya Ribbon", cmd_desc)
        else:
            cmd_exec = [["hyprctl", "dispatch", "hl.dsp.focus({ workspace = 7 })"]]
            cmd_desc = "Switched to Scrolling Ribbon Workspace (7)"
            notify("Laya Workspace", cmd_desc)

    elif intent == "app_launch":
        if any(w in p for w in ("chrome", "browser")):
            subprocess.Popen(["google-chrome"])
            cmd_desc = "Launched Google Chrome"
        elif "scratch" in p:
            subprocess.Popen([os.path.expanduser("~/.config/hypr/scripts/scratchpad.sh")])
            cmd_desc = "Toggled Quake Scratchpad"
        elif any(w in p for w in ("file", "nautilus")):
            subprocess.Popen(["nautilus"])
            cmd_desc = "Opened Nautilus File Manager"
        elif any(w in p for w in ("term", "terminal", "kitty", "bash", "shell")):
            subprocess.Popen(["kitty"])
            cmd_desc = "Launched Kitty Terminal"
        elif any(w in p for w in ("docker", "container")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "docker", "toggle"]]
            cmd_desc = "Toggled Docker Manager Panel"
        elif any(w in p for w in ("whatsapp", "chat")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "whatsapp", "toggle"]]
            cmd_desc = "Toggled WhatsApp Panel"
        elif any(w in p for w in ("hud", "gemini", "antigravity", "ai")):
            cmd_exec = [["qs", "-c", "antigravity", "ipc", "call", "antigravity", "toggle"]]
            cmd_desc = "Opened Antigravity HUD (Gemini Assistant)"
        else:
            cmd_desc = f"Unrecognized app in prompt: '{prompt}'"
            notify("Laya AI", cmd_desc)
        if cmd_desc and not cmd_desc.startswith("Unrecognized"):
            notify("Laya Application", cmd_desc)

    elif intent == "system":
        if "lock" in p:
            subprocess.Popen(["hyprlock"])
            cmd_desc = "Locked screen with Hyprlock"
        elif any(w in p for w in ("screenshot", "snip")):
            subprocess.Popen(["bash", "-c", 'grim -g "$(slurp)" - | wl-copy'])
            cmd_desc = "Captured screenshot to clipboard"
            notify("Laya Screenshot", cmd_desc)
        elif "reboot" in p:
            cmd_exec = [["systemctl", "reboot"]]
            cmd_desc = "Rebooting system"
            notify("Laya System", cmd_desc)
        else:
            cmd_desc = "System action requested"

    for c in cmd_exec:
        run_command(c)

    return cmd_desc, cmd_exec

def cleanup(*args):
    try:
        if os.path.exists(SOCKET_PATH):
            os.unlink(SOCKET_PATH)
    except Exception:
        pass
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    print(f"[{time.strftime('%X')}] Starting layad daemon...")
    print(f"[{time.strftime('%X')}] Loading Laya checkpoint into RAM...")
    t0 = time.time()
    agent = laya.load("convaiinnovations/laya")
    print(f"[{time.strftime('%X')}] Laya model loaded in {time.time() - t0:.2f}s. Performing warm-up...")
    agent.system_one("warmup query", QUESTIONS)
    print(f"[{time.strftime('%X')}] Warm-up complete. Ready for instant inference.")

    if os.path.exists(SOCKET_PATH):
        try:
            os.unlink(SOCKET_PATH)
        except OSError:
            pass

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    os.chmod(SOCKET_PATH, 0o700)
    server.listen(5)
    print(f"[{time.strftime('%X')}] Listening on {SOCKET_PATH}")

    while True:
        try:
            conn, _ = server.accept()
            with conn:
                raw_data = conn.recv(4096)
                if not raw_data:
                    continue
                req = json.loads(raw_data.decode("utf-8"))
                prompt = req.get("prompt", "").strip()
                if not prompt:
                    conn.sendall(json.dumps({"error": "empty prompt"}).encode("utf-8"))
                    continue

                t_infer = time.time()
                res = agent.system_one(prompt, QUESTIONS)
                infer_dt = (time.time() - t_infer) * 1000

                intent = res["answers"]["intent"]["choice"]
                conf = res["answers"]["intent"]["confidence"]
                probs = res["answers"]["intent"]["probabilities"]

                numbers = re.findall(r"\b(\d{1,3})\b", prompt)
                num = int(numbers[0]) if numbers else None

                cmd_desc, cmd_exec = execute_action(intent, prompt, num)

                response = {
                    "status": "ok",
                    "prompt": prompt,
                    "intent": intent,
                    "confidence": conf,
                    "probabilities": probs,
                    "action_desc": cmd_desc,
                    "action_exec": cmd_exec,
                    "inference_ms": round(infer_dt, 1)
                }

                print(f"[{time.strftime('%X')}] '{prompt}' -> {intent} ({conf:.2f}) [{infer_dt:.1f}ms] -> {cmd_desc}")
                conn.sendall(json.dumps(response).encode("utf-8"))
        except Exception as e:
            print(f"Error handling request: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
