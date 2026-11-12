#!/usr/bin/env python3
import subprocess
import json
import sys
import re
import os

CACHE_FILE = "/tmp/quickshell_network_cache.json"

def get_wifi_details():
    wifi_enabled = False
    try:
        r = subprocess.check_output(["nmcli", "radio", "wifi"], text=True, stderr=subprocess.DEVNULL).strip()
        wifi_enabled = (r == "enabled")
    except Exception:
        pass

    active_info = {
        "ssid": "",
        "signal": 0,
        "freq": "",
        "security": "",
        "rate": "",
        "ip": "",
        "bars": ""
    }

    networks = []
    seen = {}

    if wifi_enabled:
        try:
            ip_out = subprocess.check_output(["ip", "-4", "route", "show", "default"], text=True, stderr=subprocess.DEVNULL)
            dev_match = re.search(r"dev\s+(\w+)", ip_out)
            if dev_match:
                wlan_dev = dev_match.group(1)
                ip_addr_out = subprocess.check_output(["ip", "-4", "addr", "show", wlan_dev], text=True, stderr=subprocess.DEVNULL)
                ip_match = re.search(r"inet\s+([\d\.]+)", ip_addr_out)
                if ip_match:
                    active_info["ip"] = ip_match.group(1)
        except Exception:
            pass

        try:
            raw_lines = subprocess.check_output(
                ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,FREQ,SECURITY,RATE,BARS", "dev", "wifi"],
                text=True, stderr=subprocess.DEVNULL
            ).strip().split("\n")

            for line in raw_lines:
                if not line:
                    continue
                parts = line.split(":")
                if len(parts) >= 6:
                    is_active = (parts[0].lower() == "yes")
                    ssid = parts[1].strip()
                    if not ssid:
                        continue
                    try:
                        signal = int(parts[2])
                    except Exception:
                        signal = 0
                    freq_raw = parts[3].strip()
                    freq = "5 GHz" if "5" in freq_raw[:2] else "2.4 GHz"
                    sec = parts[4].strip() or "Open"
                    rate = parts[5].strip()
                    bars = parts[6].strip() if len(parts) >= 7 else ""

                    if is_active:
                        active_info["ssid"] = ssid
                        active_info["signal"] = signal
                        active_info["freq"] = freq
                        active_info["security"] = sec
                        active_info["rate"] = rate
                        active_info["bars"] = bars

                    if ssid not in seen or signal > seen[ssid]["signal"]:
                        seen[ssid] = {
                            "ssid": ssid,
                            "signal": signal,
                            "freq": freq,
                            "security": sec,
                            "rate": rate,
                            "bars": bars,
                            "inUse": is_active
                        }

            networks = list(seen.values())
            for n in networks:
                if n["ssid"] == active_info["ssid"]:
                    n["inUse"] = True
            networks.sort(key=lambda x: (not x["inUse"], -x["signal"]))
        except Exception:
            pass

    return wifi_enabled, active_info, networks

def get_bluetooth_details():
    bt_powered = False
    devices = []
    try:
        show_out = subprocess.check_output(["bluetoothctl", "show"], text=True, stderr=subprocess.DEVNULL)
        bt_powered = "Powered: yes" in show_out

        dev_out = subprocess.check_output(["bluetoothctl", "devices"], text=True, stderr=subprocess.DEVNULL)
        for line in dev_out.strip().split("\n"):
            if not line.startswith("Device"):
                continue
            parts = line.split(" ", 2)
            if len(parts) < 3:
                continue
            mac = parts[1]
            name = parts[2].strip()

            connected = False
            paired = True
            battery = -1
            icon = "bluetooth"

            n_low = name.lower()
            if any(k in n_low for k in ["buds", "airpods", "headset", "earbuds", "wh-", "wf-"]):
                icon = "headphones"
            elif any(k in n_low for k in ["soundbar", "speaker", "audio"]):
                icon = "speaker"
            elif any(k in n_low for k in ["pixel", "iphone", "phone", "galaxy", "oneplus"]):
                icon = "smartphone"
            elif "mouse" in n_low:
                icon = "mouse"
            elif "keyboard" in n_low:
                icon = "keyboard"

            try:
                info_out = subprocess.check_output(["bluetoothctl", "info", mac], text=True, stderr=subprocess.DEVNULL)
                connected = "Connected: yes" in info_out
                paired = "Paired: yes" in info_out

                # Check icon from BlueZ
                icon_match = re.search(r"Icon:\s+([\w\-]+)", info_out)
                if icon_match:
                    raw_icon = icon_match.group(1).lower()
                    if "headset" in raw_icon or "audio" in raw_icon:
                        icon = "headphones"
                    elif "phone" in raw_icon:
                        icon = "smartphone"

                # Check battery
                bat_match = re.search(r"Battery Percentage:\s*(?:0x[0-9a-fA-F]+\s*)?\((\d+)\)", info_out)
                if bat_match:
                    battery = int(bat_match.group(1))
            except Exception:
                pass

            devices.append({
                "mac": mac,
                "name": name,
                "connected": connected,
                "paired": paired,
                "battery": battery,
                "icon": icon
            })

        # Sort: connected first, then by name
        devices.sort(key=lambda x: (not x["connected"], x["name"].lower()))
    except Exception:
        pass

    return bt_powered, devices

def get_network_info():
    w_enabled, w_active, w_networks = get_wifi_details()
    bt_powered, bt_devices = get_bluetooth_details()

    connected_bt = [d for d in bt_devices if d["connected"]]

    return {
        "status": "ok",
        "wifiEnabled": w_enabled,
        "activeSsid": w_active["ssid"],
        "activeWifi": w_active,
        "networks": w_networks,
        "btPowered": bt_powered,
        "btDevices": bt_devices,
        "connectedBtCount": len(connected_bt),
        "primaryConnectedBt": connected_bt[0] if connected_bt else None
    }

def handle_actions():
    args = sys.argv[1:]
    if not args:
        return False

    cmd = args[0]
    if cmd == "--toggle-wifi":
        w_en, _, _ = get_wifi_details()
        target = "off" if w_en else "on"
        subprocess.run(["nmcli", "radio", "wifi", target], stderr=subprocess.DEVNULL)
        return True
    elif cmd == "--toggle-bt":
        if len(args) > 1:
            mac = args[1]
            try:
                info = subprocess.check_output(["bluetoothctl", "info", mac], text=True, stderr=subprocess.DEVNULL)
                action = "disconnect" if "Connected: yes" in info else "connect"
                subprocess.run(["bluetoothctl", action, mac], stderr=subprocess.DEVNULL)
            except Exception:
                subprocess.run(["bluetoothctl", "connect", mac], stderr=subprocess.DEVNULL)
        else:
            show = subprocess.check_output(["bluetoothctl", "show"], text=True, stderr=subprocess.DEVNULL)
            target = "off" if "Powered: yes" in show else "on"
            subprocess.run(["bluetoothctl", "power", target], stderr=subprocess.DEVNULL)
        return True
    elif cmd == "--connect-wifi":
        if len(args) > 1:
            ssid = args[1]
            cmd_conn = ["nmcli", "device", "wifi", "connect", ssid]
            if len(args) > 2 and args[2]:
                cmd_conn.extend(["password", args[2]])
            subprocess.run(cmd_conn, stderr=subprocess.DEVNULL)
        return True
    elif cmd == "--disconnect-wifi":
        try:
            ip_out = subprocess.check_output(["ip", "-4", "route", "show", "default"], text=True, stderr=subprocess.DEVNULL)
            dev_match = re.search(r"dev\s+(\w+)", ip_out)
            dev = dev_match.group(1) if dev_match else "wlo1"
            subprocess.run(["nmcli", "device", "disconnect", dev], stderr=subprocess.DEVNULL)
        except Exception:
            subprocess.run(["nmcli", "device", "disconnect", "wlo1"], stderr=subprocess.DEVNULL)
        return True
    elif cmd == "--rescan-wifi":
        subprocess.run(["nmcli", "device", "wifi", "rescan"], stderr=subprocess.DEVNULL)
        return True
    return False

if __name__ == "__main__":
    if handle_actions():
        data = get_network_info()
        print(json.dumps(data))
    else:
        data = get_network_info()
        print(json.dumps(data))
