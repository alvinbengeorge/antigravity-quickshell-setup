#!/usr/bin/env python3
"""
Antigravity Quickshell System Resource Monitor Telemetry & Control Engine
Extracts fine-grained CPU, RAM, SWAP, Application Groups, and Process-level metrics.
Optimized for ultra-low overhead (<10ms) and self-filtering.
"""

import os
import sys
import json
import signal
import subprocess
import multiprocessing

def get_system_telemetry():
    my_pid = os.getpid()

    # 1. Read /proc/meminfo
    meminfo = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    meminfo[parts[0].strip()] = int(parts[1].strip().split()[0])
    except Exception:
        pass

    total_ram_kb = meminfo.get("MemTotal", 1)
    free_ram_kb = meminfo.get("MemFree", 0)
    avail_ram_kb = meminfo.get("MemAvailable", 0)
    buffers_kb = meminfo.get("Buffers", 0)
    cached_kb = meminfo.get("Cached", 0)
    shmem_kb = meminfo.get("Shmem", 0)
    used_ram_kb = max(0, total_ram_kb - avail_ram_kb)

    total_swap_kb = meminfo.get("SwapTotal", 0)
    free_swap_kb = meminfo.get("SwapFree", 0)
    used_swap_kb = max(0, total_swap_kb - free_swap_kb)

    # Load averages
    try:
        load_1, load_5, load_15 = os.getloadavg()
    except Exception:
        load_1, load_5, load_15 = 0.0, 0.0, 0.0

    # 2. Query processes via ps
    try:
        ps = subprocess.check_output(
            ["ps", "-eo", "pid,user,%cpu,rss,comm,args", "--sort=-rss"]
        ).decode("utf-8").splitlines()[1:]
    except Exception:
        ps = []

    groups = {}
    all_procs = []

    for idx, line in enumerate(ps):
        parts = line.strip().split(None, 5)
        if not parts or len(parts) < 5:
            continue
        try:
            pid = int(parts[0])
        except ValueError:
            continue

        comm = parts[4]
        args = parts[5] if len(parts) > 5 else comm

        # Self-filtering: exclude telemetry script, ps, and direct runners
        if pid == my_pid or comm in ["ps", "system_monitor.py"] or "system_monitor.py" in args:
            continue

        user = parts[1]
        try:
            cpu = float(parts[2])
        except ValueError:
            cpu = 0.0
        rss = int(parts[3])

        # Read Swap only for top 25 heavy processes to minimize I/O
        swap_kb = 0
        if idx < 25:
            try:
                with open(f"/proc/{pid}/status") as sf:
                    for sl in sf:
                        if sl.startswith("VmSwap:"):
                            swap_kb = int(sl.split()[1])
                            break
            except Exception:
                pass

        # Classification / Grouping
        if "chrome" in comm or "chrome" in args:
            if "openwa" in args or "puppeteer" in args:
                cat, icon = "OpenWA (WhatsApp Bot)", "message-square"
            else:
                cat, icon = "Google Chrome", "globe"
        elif "zapzap" in comm or "zapzap" in args or ("QtWebEngineProcess" in comm and "zapzap" in args):
            cat, icon = "ZapZap (WhatsApp)", "message-square"
        elif "agy" in comm or "antigravity" in comm:
            cat, icon = "Antigravity CLI", "sparkles"
        elif "qs" in comm or "quickshell" in comm:
            cat, icon = "Quickshell Shell", "layers"
        elif "mcp" in args or "graphify" in args or "playwright" in args:
            cat, icon = "MCP Tool Servers", "cpu"
        elif "docker" in comm or "containerd" in comm:
            cat, icon = "Docker Engine", "hard-drive"
        elif "node" in comm and "antigravity-remote" in args:
            cat, icon = "Antigravity Remote", "smartphone"
        elif "hypr" in comm or "waybar" in comm:
            cat, icon = "Hyprland Desktop", "monitor"
        elif "pipewire" in comm or "wireplumber" in comm:
            cat, icon = "PipeWire Audio", "volume-2"
        elif "easyeffects" in comm:
            cat, icon = "EasyEffects", "sliders"
        elif "kitty" in comm or "kitten" in comm:
            cat, icon = "Kitty Terminal", "terminal"
        elif "code" in comm or "cursor" in comm:
            cat, icon = "Code Editor", "code"
        elif comm in ["systemd", "dbus-broker", "systemd-journal", "systemd-logind"]:
            cat, icon = "System Daemons", "settings"
        else:
            cat, icon = comm.capitalize(), "activity"

        if cat not in groups:
            groups[cat] = {
                "name": cat,
                "icon": icon,
                "count": 0,
                "rss_kb": 0,
                "swap_kb": 0,
                "cpu": 0.0
            }
        groups[cat]["count"] += 1
        groups[cat]["rss_kb"] += rss
        groups[cat]["swap_kb"] += swap_kb
        groups[cat]["cpu"] += cpu

        cmd_short = comm
        if comm in ["python", "python3", "node", "ruby", "perl"] and len(parts) > 5:
            tokens = args.split()
            for t in tokens[1:]:
                if not t.startswith("-"):
                    cmd_short = os.path.basename(t)
                    break

        all_procs.append({
            "pid": pid,
            "user": user,
            "name": cmd_short,
            "category": cat,
            "cpu": cpu,
            "rss_mb": round(rss / 1024, 1),
            "swap_mb": round(swap_kb / 1024, 1),
            "command": args[:85]
        })

    group_list = sorted(groups.values(), key=lambda g: g["rss_kb"], reverse=True)[:15]
    for g in group_list:
        g["rss_mb"] = round(g["rss_kb"] / 1024, 1)
        g["swap_mb"] = round(g["swap_kb"] / 1024, 1)
        g["percent_ram"] = round((g["rss_kb"] / total_ram_kb) * 100, 1)
        g["cpu"] = round(g["cpu"], 1)
        del g["rss_kb"]
        del g["swap_kb"]

    top_by_mem = sorted(all_procs, key=lambda p: p["rss_mb"], reverse=True)[:30]
    top_by_cpu = sorted(all_procs, key=lambda p: p["cpu"], reverse=True)[:30]
    top_by_swap = sorted([p for p in all_procs if p["swap_mb"] > 0], key=lambda p: p["swap_mb"], reverse=True)[:30]

    cores = multiprocessing.cpu_count()
    total_cpu = round(sum(p["cpu"] for p in all_procs) / max(1, cores), 1)

    return {
        "cpu": {
            "percent": min(100, total_cpu),
            "cores": cores,
            "load_1": round(load_1, 2),
            "load_5": round(load_5, 2),
            "load_15": round(load_15, 2)
        },
        "ram": {
            "total_mb": round(total_ram_kb / 1024),
            "used_mb": round(used_ram_kb / 1024),
            "free_mb": round(free_ram_kb / 1024),
            "avail_mb": round(avail_ram_kb / 1024),
            "cached_mb": round(cached_kb / 1024),
            "shmem_mb": round(shmem_kb / 1024),
            "used_percent": round(used_ram_kb / total_ram_kb * 100),
            "avail_percent": round(avail_ram_kb / total_ram_kb * 100),
        },
        "swap": {
            "total_mb": round(total_swap_kb / 1024),
            "used_mb": round(used_swap_kb / 1024),
            "free_mb": round(free_swap_kb / 1024),
            "used_percent": round(used_swap_kb / total_swap_kb * 100) if total_swap_kb else 0,
        },
        "groups": group_list,
        "top_by_mem": top_by_mem,
        "top_by_cpu": top_by_cpu,
        "top_by_swap": top_by_swap
    }

def kill_process(pid_str, force=False):
    try:
        pid = int(pid_str)
        sig = signal.SIGKILL if force else signal.SIGTERM
        os.kill(pid, sig)
        return {"success": True, "pid": pid, "signal": sig}
    except Exception as e:
        return {"success": False, "pid": pid_str, "error": str(e)}

def drop_caches():
    try:
        subprocess.run(["sync"], check=True)
        with open("/proc/sys/vm/drop_caches", "w") as f:
            f.write("3\n")
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}

def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "data"

    if action == "data":
        telemetry = get_system_telemetry()
        print(json.dumps(telemetry))
    elif action == "kill":
        if len(sys.argv) < 3:
            print(json.dumps({"success": False, "error": "Missing PID"}))
            sys.exit(1)
        force = len(sys.argv) > 3 and (sys.argv[3] in ["1", "true", "force", "-9"])
        res = kill_process(sys.argv[2], force=force)
        print(json.dumps(res))
    elif action == "drop_caches":
        res = drop_caches()
        print(json.dumps(res))
    else:
        print(json.dumps({"error": f"Unknown action {action}"}))

if __name__ == "__main__":
    main()
