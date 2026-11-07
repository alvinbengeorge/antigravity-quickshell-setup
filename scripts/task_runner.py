#!/usr/bin/env python3
"""
Custom Developer Task Runner Backend
Manages persistent tasks and execution for Antigravity Quickshell.
"""
import sys
import json
import subprocess
import os

TASKS_DIR = os.path.expanduser("~/.local/state/quickshell/user")
TASKS_FILE = os.path.join(TASKS_DIR, "custom-tasks.json")

DEFAULT_TASKS = []

def load_tasks():
    os.makedirs(TASKS_DIR, exist_ok=True)
    if not os.path.exists(TASKS_FILE):
        save_tasks(DEFAULT_TASKS)
        return DEFAULT_TASKS
    try:
        with open(TASKS_FILE, "r") as f:
            data = json.load(f)
            return data if isinstance(data, list) else DEFAULT_TASKS
    except Exception:
        return DEFAULT_TASKS

def save_tasks(tasks):
    os.makedirs(TASKS_DIR, exist_ok=True)
    with open(TASKS_FILE, "w") as f:
        json.dump(tasks, f, indent=2)

def add_or_update_task(task_obj):
    tasks = load_tasks()
    tid = task_obj.get("id") or str(int(os.times().system * 1000) or os.urandom(4).hex())
    task_obj["id"] = tid
    # Check if existing
    updated = False
    for i, t in enumerate(tasks):
        if t.get("id") == tid:
            tasks[i] = task_obj
            updated = True
            break
    if not updated:
        tasks.insert(0, task_obj)
    save_tasks(tasks)
    return {"status": "ok", "id": tid, "tasks": tasks}

def delete_task(task_id):
    tasks = load_tasks()
    tasks = [t for t in tasks if t.get("id") != task_id]
    save_tasks(tasks)
    return {"status": "ok", "tasks": tasks}

def run_task(task_id):
    tasks = load_tasks()
    matched = next((t for t in tasks if t.get("id") == task_id), None)
    if not matched:
        return {"status": "error", "message": f"Task '{task_id}' not found."}

    name = matched.get("name", "Task")
    cmd = matched.get("command", "")
    interactive = matched.get("interactive", False)

    if interactive:
        # Spawn an interactive Kitty terminal running the command
        full_kitty_cmd = f'kitty --title "Task: {name}" bash -c "{cmd}; echo \'\'; echo \'Task finished. Press Enter to close.\'; read -p \'\'"'
        subprocess.Popen(full_kitty_cmd, shell=True)
        # Notify
        subprocess.Popen(["notify-send", "-a", "Task Runner", f"Started: {name}", "Running in interactive terminal..."])
        return {"status": "ok", "type": "interactive"}
    else:
        # Run in background and notify when finished
        try:
            res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
            if res.returncode == 0:
                subprocess.Popen(["notify-send", "-a", "Task Runner", f"✓ {name}", "Completed successfully."])
                return {"status": "ok", "output": res.stdout[:500]}
            else:
                err_msg = (res.stderr or res.stdout or f"Exited with code {res.returncode}")[:200]
                subprocess.Popen(["notify-send", "-a", "Task Runner", "-u", "critical", f"✗ {name} Failed", err_msg])
                return {"status": "error", "output": err_msg}
        except subprocess.TimeoutExpired:
            subprocess.Popen(["notify-send", "-a", "Task Runner", "-u", "critical", f"✗ {name} Timeout", "Command exceeded 120s limit."])
            return {"status": "error", "message": "Timed out after 120s"}
        except Exception as e:
            subprocess.Popen(["notify-send", "-a", "Task Runner", "-u", "critical", f"✗ {name} Error", str(e)])
            return {"status": "error", "message": str(e)}

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "list":
        print(json.dumps(load_tasks()))
    elif sys.argv[1] == "create" or sys.argv[1] == "save":
        if len(sys.argv) > 2:
            try:
                task_data = json.loads(sys.argv[2])
                print(json.dumps(add_or_update_task(task_data)))
            except Exception as e:
                print(json.dumps({"status": "error", "message": str(e)}))
        else:
            print(json.dumps({"status": "error", "message": "Missing task payload"}))
    elif sys.argv[1] == "delete":
        if len(sys.argv) > 2:
            print(json.dumps(delete_task(sys.argv[2])))
        else:
            print(json.dumps({"status": "error", "message": "Missing task id"}))
    elif sys.argv[1] == "run":
        if len(sys.argv) > 2:
            print(json.dumps(run_task(sys.argv[2])))
        else:
            print(json.dumps({"status": "error", "message": "Missing task id"}))
    else:
        print(json.dumps(load_tasks()))

if __name__ == "__main__":
    main()
