#!/usr/bin/env python3
"""
OpenWA Status & Chat Provider for Antigravity Quickshell
Fetches live WhatsApp connection status, unread counts, recent chats, QR code,
and handles reconnection & gateway control.
"""

import sys
import os
import json
import base64
import subprocess
import urllib.request
import urllib.error
from datetime import datetime

API_BASE = os.environ.get("OPENWA_BASE_URL", "http://localhost:2785/api")
API_KEY = os.environ.get("OPENWA_API_KEY", "abcd")
COMPOSE_FILE = "/home/alvin/Downloads/OpenWA/docker-compose.yml"
CACHE_FILE = os.path.expanduser("~/.local/state/quickshell/user/openwa-cache.json")
QR_IMG_PATH = "/tmp/openwa_qr.png"

HEADERS = {
    "x-api-key": API_KEY,
    "Content-Type": "application/json"
}

def format_timestamp(ts):
    if not ts:
        return ""
    try:
        if ts > 1e11:  # milliseconds to seconds
            ts = ts / 1000.0
        dt = datetime.fromtimestamp(ts)
        now = datetime.now()
        if dt.date() == now.date():
            return dt.strftime("%I:%M %p").lstrip("0")
        elif (now.date() - dt.date()).days == 1:
            return "Yesterday"
        elif (now.date() - dt.date()).days < 7:
            return dt.strftime("%a")
        else:
            return dt.strftime("%b %d")
    except Exception:
        return ""

def clean_body(lm):
    if not lm:
        return ""
    if isinstance(lm, dict):
        body = lm.get("body") or ""
        mtype = lm.get("type", "")
        if not body:
            if mtype == "image": return "📷 Photo"
            if mtype == "video": return "🎥 Video"
            if mtype in ("audio", "ptt"): return "🎵 Voice message"
            if mtype == "document": return "📄 Document"
            if mtype == "sticker": return "✨ Sticker"
            if mtype == "location": return "📍 Location"
            return ""
        return body.replace("\n", " ").strip()
    return str(lm).replace("\n", " ").strip()

def api_request(endpoint, method="GET", data=None, timeout=3.5):
    url = f"{API_BASE}{endpoint}"
    payload = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=payload, headers=HEADERS, method=method)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))

def reconnect_session(session_id="5e24dc37-3676-48a7-9c50-35559fefbed6"):
    try:
        res = api_request(f"/sessions/{session_id}/start", method="POST", timeout=6.0)
        return {"status": "reconnecting", "result": res}
    except Exception as e:
        return {"status": "error", "error": str(e)}

def disconnect_session(session_id="5e24dc37-3676-48a7-9c50-35559fefbed6"):
    """Gracefully stop the WhatsApp session engine without deleting credentials.
    The session can be reconnected without QR re-authentication."""
    try:
        res = api_request(f"/sessions/{session_id}/stop", method="POST", timeout=6.0)
        return {"status": "disconnected", "result": res}
    except Exception as e:
        return {"status": "error", "error": str(e)}

def start_gateway():
    try:
        subprocess.run(["docker", "compose", "-f", COMPOSE_FILE, "up", "-d", "openwa-api"], check=True, capture_output=True)
        return {"status": "gateway_starting"}
    except Exception as e:
        return {"status": "error", "error": str(e)}

def send_message(session_id, chat_id, text):
    try:
        res = api_request(f"/sessions/{session_id}/messages", method="POST", data={"chatId": chat_id, "text": text}, timeout=8.0)
        return {"status": "sent", "result": res}
    except Exception as e:
        return {"status": "error", "error": str(e)}

def fetch_status():
    try:
        sessions = api_request("/sessions", timeout=2.5)
    except urllib.error.URLError:
        return {
            "status": "offline",
            "error": "Gateway offline (http://localhost:2785)",
            "chats": [],
            "unread_total": 0,
            "session": None,
            "qr_path": None,
            "last_updated": datetime.now().strftime("%I:%M %p").lstrip("0")
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "chats": [],
            "unread_total": 0,
            "session": None,
            "qr_path": None,
            "last_updated": datetime.now().strftime("%I:%M %p").lstrip("0")
        }

    if not sessions or not isinstance(sessions, list):
        return {
            "status": "no_session",
            "error": "No WhatsApp sessions configured",
            "chats": [],
            "unread_total": 0,
            "session": None,
            "qr_path": None,
            "last_updated": datetime.now().strftime("%I:%M %p").lstrip("0")
        }

    s = sessions[0]
    session_id = s.get("id")
    s_status = s.get("status", "disconnected")

    chats_out = []
    unread_total = 0
    qr_path = None

    if s_status == "ready":
        try:
            raw_chats = api_request(f"/sessions/{session_id}/chats?limit=25", timeout=4.0)
            if isinstance(raw_chats, list):
                for c in raw_chats[:20]:
                    unread = c.get("unreadCount", 0) or 0
                    unread_total += unread
                    lm = c.get("lastMessage")
                    body = clean_body(lm)
                    ts = c.get("timestamp")
                    if not ts and isinstance(lm, dict):
                        ts = lm.get("timestamp")

                    chats_out.append({
                        "id": c.get("id", ""),
                        "name": c.get("name") or c.get("pushName") or "Unknown",
                        "isGroup": bool(c.get("isGroup")),
                        "unreadCount": unread,
                        "timestamp": ts or 0,
                        "timeStr": format_timestamp(ts),
                        "lastMessage": body[:90]
                    })
        except Exception as e:
            # If chats call timed out, fallback to status
            pass
    elif s_status == "qr_ready":
        try:
            qr_data = api_request(f"/sessions/{session_id}/qr", timeout=3.0)
            b64 = qr_data.get("qrCode", "")
            if "base64," in b64:
                b64 = b64.split("base64,")[1]
            with open(QR_IMG_PATH, "wb") as f:
                f.write(base64.b64decode(b64))
            qr_path = QR_IMG_PATH
        except Exception:
            qr_path = None

    result = {
        "status": s_status,
        "session": {
            "id": session_id,
            "name": s.get("name", "default"),
            "phone": s.get("phone", ""),
            "pushName": s.get("pushName", "Alvin"),
            "status": s_status,
            "connectedAt": s.get("connectedAt")
        },
        "unread_total": unread_total,
        "chats": chats_out,
        "qr_path": qr_path,
        "last_updated": datetime.now().strftime("%I:%M %p").lstrip("0")
    }

    # Cache successful read
    try:
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(result, f, indent=2)
    except Exception:
        pass

    return result

def main():
    if "--reconnect" in sys.argv:
        sid = sys.argv[2] if len(sys.argv) > 2 else "5e24dc37-3676-48a7-9c50-35559fefbed6"
        res = reconnect_session(sid)
        print(json.dumps(res))
    elif "--disconnect" in sys.argv:
        sid = sys.argv[2] if len(sys.argv) > 2 else "5e24dc37-3676-48a7-9c50-35559fefbed6"
        res = disconnect_session(sid)
        print(json.dumps(res))
    elif "--start-gateway" in sys.argv:
        res = start_gateway()
        print(json.dumps(res))
    elif "--send" in sys.argv:
        if len(sys.argv) >= 4:
            sid = "5e24dc37-3676-48a7-9c50-35559fefbed6"
            target = sys.argv[2]
            msg = sys.argv[3]
            res = send_message(sid, target, msg)
            print(json.dumps(res))
        else:
            print(json.dumps({"error": "Usage: --send <chat_id> <message>"}))
    else:
        status = fetch_status()
        print(json.dumps(status))

if __name__ == "__main__":
    main()
