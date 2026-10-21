#!/usr/bin/env python3
import sys
import subprocess
import json
import re

def get_active_profile():
    try:
        out = subprocess.check_output(
            ["busctl", "call", "com.redhat.tuned", "/Tuned", "com.redhat.tuned.control", "active_profile"],
            text=True,
            stderr=subprocess.DEVNULL
        ).strip()
        if '"' in out:
            return out.split('"')[1]
    except Exception:
        pass
    
    # Fallback to tuned-adm active
    try:
        out = subprocess.check_output(["tuned-adm", "active"], text=True, stderr=subprocess.DEVNULL)
        for line in out.splitlines():
            if ":" in line:
                return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return "unknown"

def get_profiles():
    primary_meta = {
        "powersave": {
            "name": "Power Saver",
            "icon": "leaf",
            "color": "#10B981",
            "summary": "Low power consumption & cool temps",
            "order": 1
        },
        "balanced": {
            "name": "Balanced",
            "icon": "gauge",
            "color": "#06B6D4",
            "summary": "Dynamic responsive desktop balance",
            "order": 2
        },
        "balanced-battery": {
            "name": "Balanced (Battery)",
            "icon": "gauge",
            "color": "#06B6D4",
            "summary": "Balanced with power-saving bias",
            "order": 3
        },
        "desktop": {
            "name": "Desktop",
            "icon": "monitor",
            "color": "#3B82F6",
            "summary": "Workstation responsiveness tuning",
            "order": 4
        },
        "throughput-performance": {
            "name": "Performance",
            "icon": "zap",
            "color": "#F59E0B",
            "summary": "Maximum multi-core CPU throughput",
            "order": 5
        },
        "latency-performance": {
            "name": "Low Latency",
            "icon": "flame",
            "color": "#EF4444",
            "summary": "Deterministic minimal latency & audio/gaming",
            "order": 6
        },
        "accelerator-performance": {
            "name": "Accelerator",
            "icon": "sparkles",
            "color": "#8B5CF6",
            "summary": "High throughput without deep STOP states",
            "order": 7
        }
    }

    profiles = []
    try:
        out = subprocess.check_output(
            ["busctl", "call", "com.redhat.tuned", "/Tuned", "com.redhat.tuned.control", "profiles2"],
            text=True,
            stderr=subprocess.DEVNULL
        )
        matches = re.findall(r'"([^"]*)"', out)
        for i in range(0, len(matches), 2):
            pid = matches[i]
            desc = matches[i+1] if i + 1 < len(matches) else ""
            meta = primary_meta.get(pid, {
                "name": pid.replace("-", " ").title(),
                "icon": "sliders",
                "color": "#94A3B8",
                "summary": desc,
                "order": 100
            })
            profiles.append({
                "id": pid,
                "name": meta["name"],
                "icon": meta["icon"],
                "color": meta["color"],
                "summary": meta.get("summary", desc),
                "description": desc,
                "isPrimary": pid in ["powersave", "balanced", "throughput-performance", "latency-performance"],
                "order": meta.get("order", 100)
            })
    except Exception:
        # Fallback list if busctl fails
        for pid, meta in primary_meta.items():
            profiles.append({
                "id": pid,
                "name": meta["name"],
                "icon": meta["icon"],
                "color": meta["color"],
                "summary": meta["summary"],
                "description": meta["summary"],
                "isPrimary": pid in ["powersave", "balanced", "throughput-performance", "latency-performance"],
                "order": meta["order"]
            })

    profiles.sort(key=lambda x: (x["order"], x["id"]))
    return profiles

def status():
    active = get_active_profile()
    available = (active != "unknown")
    profiles = get_profiles()
    active_obj = next((p for p in profiles if p["id"] == active), {
        "id": active,
        "name": active.replace("-", " ").title(),
        "icon": "zap",
        "color": "#F59E0B",
        "summary": "Active TuneD profile"
    })
    
    result = {
        "available": available,
        "activeProfile": active,
        "activeMeta": active_obj,
        "profiles": profiles
    }
    print(json.dumps(result))

def switch(profile_name):
    try:
        res = subprocess.run(
            ["busctl", "call", "com.redhat.tuned", "/Tuned", "com.redhat.tuned.control", "switch_profile", "s", profile_name],
            capture_output=True,
            text=True
        )
        success = (res.returncode == 0 and "true" in res.stdout)
        print(json.dumps({"success": success, "profile": profile_name, "output": res.stdout.strip()}))
    except Exception as e:
        print(json.dumps({"success": False, "error": str(e)}))

if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "switch":
        switch(sys.argv[2])
    else:
        status()
