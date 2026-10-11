#!/usr/bin/env python3
import subprocess
import json
import sys

def get_network_info():
    # WiFi Enabled status
    wifi_enabled = True
    try:
        radio_out = subprocess.check_output(["nmcli", "radio", "wifi"], text=True, stderr=subprocess.DEVNULL).strip()
        wifi_enabled = (radio_out == "enabled")
    except Exception:
        pass

    # Connected SSID
    active_ssid = ""
    active_bssid = ""
    try:
        active_out = subprocess.check_output(["nmcli", "-t", "-f", "ACTIVE,SSID,BSSID", "dev", "wifi"], text=True, stderr=subprocess.DEVNULL)
        for line in active_out.strip().split("\n"):
            if line.startswith("yes:"):
                parts = line.split(":")
                if len(parts) >= 2:
                    active_ssid = parts[1]
                if len(parts) >= 3:
                    active_bssid = ":".join(parts[2:])
                break
    except Exception:
        pass

    # WiFi list
    networks = []
    seen = set()
    try:
        out = subprocess.check_output(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY,BARS", "dev", "wifi", "list"], text=True, stderr=subprocess.DEVNULL)
        for line in out.strip().split("\n"):
            if not line:
                continue
            parts = line.split(":")
            if len(parts) >= 5:
                in_use = (parts[0] == "*")
                ssid = parts[1]
                signal = int(parts[2]) if parts[2].isdigit() else 0
                security = parts[3]
                bars = parts[4]
                if ssid and ssid not in seen:
                    seen.add(ssid)
                    networks.append({
                        "ssid": ssid,
                        "signal": signal,
                        "security": security if security else "Open",
                        "bars": bars,
                        "inUse": in_use
                    })
    except Exception:
        pass

    # Bluetooth status
    bt_powered = False
    bt_devices = []
    try:
        show_out = subprocess.check_output(["bluetoothctl", "show"], text=True, stderr=subprocess.DEVNULL)
        bt_powered = "Powered: yes" in show_out

        dev_out = subprocess.check_output(["bluetoothctl", "devices"], text=True, stderr=subprocess.DEVNULL)
        for line in dev_out.strip().split("\n"):
            if not line:
                continue
            parts = line.split(" ", 2)
            if len(parts) >= 3 and parts[0] == "Device":
                mac = parts[1]
                name = parts[2]
                connected = False
                try:
                    info_out = subprocess.check_output(["bluetoothctl", "info", mac], text=True, stderr=subprocess.DEVNULL)
                    connected = "Connected: yes" in info_out
                except Exception:
                    pass
                bt_devices.append({
                    "mac": mac,
                    "name": name,
                    "connected": connected
                })
    except Exception:
        pass

    return {
        "wifiEnabled": wifi_enabled,
        "activeSsid": active_ssid,
        "networks": networks,
        "btPowered": bt_powered,
        "btDevices": bt_devices
    }

if __name__ == "__main__":
    data = get_network_info()
    print(json.dumps(data))
