#!/usr/bin/env python3
"""
Docker Container Manager Backend
Provides JSON telemetry and action orchestration for Antigravity Quickshell.
"""
import sys
import json
import subprocess
import os

STATS_CACHE = "/tmp/docker_stats_cache.json"

def get_stats_cache():
    if os.path.exists(STATS_CACHE):
        try:
            with open(STATS_CACHE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def update_stats_cache():
    """Runs docker stats and writes to cache."""
    try:
        res = subprocess.run(
            ["docker", "stats", "--no-stream", "--format", "{{json .}}"],
            capture_output=True, text=True, timeout=5
        )
        if res.returncode == 0:
            stats_map = {}
            for line in res.stdout.strip().split("\n"):
                if not line.strip():
                    continue
                try:
                    data = json.loads(line)
                    cid = data.get("ID", "")
                    name = data.get("Name", "")
                    st = {
                        "cpu": data.get("CPUPerc", "0.00%"),
                        "mem": data.get("MemUsage", "0B"),
                        "mem_perc": data.get("MemPerc", "0.00%"),
                        "net": data.get("NetIO", "0B / 0B"),
                        "pids": data.get("PIDs", "0")
                    }
                    if cid:
                        stats_map[cid] = st
                    if name:
                        stats_map[name] = st
                except Exception:
                    continue
            with open(STATS_CACHE, "w") as f:
                json.dump(stats_map, f)
            return stats_map
    except Exception:
        pass
    return {}

def get_docker_data():
    # 1. Check daemon status
    ping = subprocess.run(["docker", "info", "--format", "{{json .ServerErrors}}"], capture_output=True, text=True)
    if ping.returncode != 0:
        return {
            "daemon_running": False,
            "error": "Docker daemon is not running or socket is inaccessible.",
            "containers": [],
            "images": [],
            "summary": {"total": 0, "running": 0, "stopped": 0, "paused": 0, "images_count": 0}
        }

    stats_cache = get_stats_cache()

    # 2. Query containers
    ps_res = subprocess.run(
        ["docker", "ps", "-a", "--format", "{{json .}}"],
        capture_output=True, text=True
    )

    containers = []
    running_count = 0
    stopped_count = 0
    paused_count = 0

    if ps_res.returncode == 0:
        for line in ps_res.stdout.strip().split("\n"):
            if not line.strip():
                continue
            try:
                raw = json.loads(line)
                cid = raw.get("ID", "")
                name = raw.get("Names", "").lstrip("/")
                state = raw.get("State", "unknown").lower()
                status = raw.get("Status", "")
                image = raw.get("Image", "")
                ports_raw = raw.get("Ports", "")
                created = raw.get("RunningFor", "")
                labels_str = raw.get("Labels", "")

                # Parse compose project / service
                compose_project = ""
                compose_service = ""
                if labels_str:
                    for part in labels_str.split(","):
                        if "com.docker.compose.project=" in part:
                            compose_project = part.split("=", 1)[1]
                        elif "com.docker.compose.service=" in part:
                            compose_service = part.split("=", 1)[1]

                # Format ports into short readable pills (e.g. "8002:8000, 5433:5432")
                clean_ports = []
                if ports_raw:
                    for p in ports_raw.split(","):
                        p = p.strip()
                        # e.g. 0.0.0.0:8004->8000/tcp or [::]:8004->8000/tcp
                        if "->" in p:
                            host_part, cont_part = p.split("->", 1)
                            host_port = host_part.split(":")[-1]
                            cont_port = cont_part.split("/")[0]
                            entry = f"{host_port}:{cont_port}"
                            if entry not in clean_ports:
                                clean_ports.append(entry)
                        elif "/" in p:
                            clean_ports.append(p.split("/")[0])
                ports_display = ", ".join(clean_ports) if clean_ports else ""

                # Stats from cache
                cid_short = cid[:12] if len(cid) >= 12 else cid
                st = stats_cache.get(cid_short) or stats_cache.get(name) or {}
                cpu_perc = st.get("cpu", "") if state == "running" else ""
                mem_usage = st.get("mem", "") if state == "running" else ""
                mem_perc = st.get("mem_perc", "") if state == "running" else ""

                if state == "running":
                    running_count += 1
                elif state == "paused":
                    paused_count += 1
                else:
                    stopped_count += 1

                containers.append({
                    "id": cid_short,
                    "name": name,
                    "image": image,
                    "state": state,
                    "status": status,
                    "ports": ports_display,
                    "compose_project": compose_project,
                    "compose_service": compose_service,
                    "created": created,
                    "cpu_perc": cpu_perc,
                    "mem_usage": mem_usage,
                    "mem_perc": mem_perc
                })
            except Exception:
                continue

    # 3. Query images
    img_res = subprocess.run(
        ["docker", "images", "--format", "{{json .}}"],
        capture_output=True, text=True
    )
    images = []
    if img_res.returncode == 0:
        for line in img_res.stdout.strip().split("\n"):
            if not line.strip():
                continue
            try:
                raw = json.loads(line)
                repo = raw.get("Repository", "")
                tag = raw.get("Tag", "")
                if repo == "<none>" and tag == "<none>":
                    continue
                images.append({
                    "id": raw.get("ID", "")[:12],
                    "repository": repo,
                    "tag": tag,
                    "size": raw.get("Size", ""),
                    "created": raw.get("CreatedSince", ""),
                    "containers": int(raw.get("Containers", "0")) if raw.get("Containers", "").isdigit() else 0
                })
            except Exception:
                continue

    return {
        "daemon_running": True,
        "containers": containers,
        "images": images,
        "summary": {
            "total": len(containers),
            "running": running_count,
            "stopped": stopped_count,
            "paused": paused_count,
            "images_count": len(images)
        }
    }

def perform_action(action, target=""):
    """Executes a container or image management action."""
    action = action.lower()
    if action in ["start", "stop", "restart", "pause", "unpause"]:
        if not target:
            return {"status": "error", "message": "No target container specified."}
        res = subprocess.run(["docker", action, target], capture_output=True, text=True)
        return {"status": "ok" if res.returncode == 0 else "error", "output": res.stdout or res.stderr}

    elif action == "remove":
        if not target:
            return {"status": "error", "message": "No target container specified."}
        res = subprocess.run(["docker", "rm", "-f", target], capture_output=True, text=True)
        return {"status": "ok" if res.returncode == 0 else "error", "output": res.stdout or res.stderr}

    elif action == "remove_image":
        if not target:
            return {"status": "error", "message": "No target image specified."}
        res = subprocess.run(["docker", "rmi", target], capture_output=True, text=True)
        return {"status": "ok" if res.returncode == 0 else "error", "output": res.stdout or res.stderr}

    elif action == "prune_containers":
        res = subprocess.run(["docker", "container", "prune", "-f"], capture_output=True, text=True)
        return {"status": "ok" if res.returncode == 0 else "error", "output": res.stdout or res.stderr}

    elif action == "prune_images":
        res = subprocess.run(["docker", "image", "prune", "-f"], capture_output=True, text=True)
        return {"status": "ok" if res.returncode == 0 else "error", "output": res.stdout or res.stderr}

    elif action == "start_all":
        # Start all exited containers
        cmd = "docker start $(docker ps -a -q -f status=exited)"
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return {"status": "ok" if res.returncode == 0 else "error", "output": res.stdout or res.stderr}

    elif action == "stop_all":
        # Stop all running containers
        cmd = "docker stop $(docker ps -q)"
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return {"status": "ok" if res.returncode == 0 else "error", "output": res.stdout or res.stderr}

    elif action == "logs":
        lines = "100"
        if len(sys.argv) > 3 and sys.argv[3].isdigit():
            lines = sys.argv[3]
        res = subprocess.run(["docker", "logs", "--tail", lines, target], capture_output=True, text=True)
        return {"status": "ok", "logs": res.stdout + ("\n" + res.stderr if res.stderr else "")}

    elif action == "terminal":
        # Spawn an interactive Kitty terminal running shell inside container
        cmd = f'kitty --title "Docker Exec: {target}" bash -c "docker exec -it {target} /bin/bash || docker exec -it {target} /bin/sh || (echo Container shell unavailable; read -p Press_Enter)"'
        subprocess.Popen(cmd, shell=True)
        return {"status": "ok", "message": f"Terminal opened for {target}"}

    elif action == "live_logs":
        # Spawn an interactive Kitty terminal following logs
        cmd = f'kitty --title "Docker Logs: {target}" docker logs -f --tail 200 {target}'
        subprocess.Popen(cmd, shell=True)
        return {"status": "ok", "message": f"Logs opened for {target}"}

    return {"status": "error", "message": f"Unknown action '{action}'"}

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "data":
        print(json.dumps(get_docker_data()))
    elif sys.argv[1] == "stats":
        print(json.dumps(update_stats_cache()))
    elif sys.argv[1] == "action":
        action = sys.argv[2] if len(sys.argv) > 2 else ""
        target = sys.argv[3] if len(sys.argv) > 3 else ""
        print(json.dumps(perform_action(action, target)))
    else:
        print(json.dumps(get_docker_data()))

if __name__ == "__main__":
    main()
