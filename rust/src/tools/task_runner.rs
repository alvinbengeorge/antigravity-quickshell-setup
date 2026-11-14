//! Developer Task Runner Native Backend for Quickshell
//! Manages persistent custom tasks in ~/.local/state/quickshell/user/custom-tasks.json

use serde_json::Value;
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

fn get_tasks_path() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    PathBuf::from(home)
        .join(".local")
        .join("state")
        .join("quickshell")
        .join("user")
        .join("custom-tasks.json")
}

fn load_tasks() -> Vec<Value> {
    let p = get_tasks_path();
    if let Ok(content) = fs::read_to_string(&p) {
        if let Ok(Value::Array(arr)) = serde_json::from_str(&content) {
            return arr;
        }
    }
    Vec::new()
}

fn save_tasks(tasks: &[Value]) {
    let p = get_tasks_path();
    if let Some(parent) = p.parent() {
        let _ = fs::create_dir_all(parent);
    }
    if let Ok(content) = serde_json::to_string_pretty(tasks) {
        let _ = fs::write(p, content);
    }
}

fn add_or_update_task(mut task_obj: Value) -> Value {
    let mut tasks = load_tasks();
    let tid = task_obj
        .get("id")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| {
            let now = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|d| d.as_millis())
                .unwrap_or(0);
            format!("{}", now)
        });

    if let Value::Object(ref mut map) = task_obj {
        map.insert("id".to_string(), Value::String(tid.clone()));
    }

    let mut updated = false;
    for t in &mut tasks {
        if t.get("id").and_then(|v| v.as_str()) == Some(&tid) {
            *t = task_obj.clone();
            updated = true;
            break;
        }
    }

    if !updated {
        tasks.insert(0, task_obj);
    }

    save_tasks(&tasks);

    serde_json::json!({
        "status": "ok",
        "id": tid,
        "tasks": tasks
    })
}

fn delete_task(task_id: &str) -> Value {
    let mut tasks = load_tasks();
    tasks.retain(|t| t.get("id").and_then(|v| v.as_str()) != Some(task_id));
    save_tasks(&tasks);

    serde_json::json!({
        "status": "ok",
        "tasks": tasks
    })
}

fn run_task(task_id: &str) -> Value {
    let tasks = load_tasks();
    let matched = tasks
        .iter()
        .find(|t| t.get("id").and_then(|v| v.as_str()) == Some(task_id));

    let task = match matched {
        Some(t) => t,
        None => {
            return serde_json::json!({
                "status": "error",
                "message": format!("Task '{}' not found", task_id)
            });
        }
    };

    let name = task
        .get("name")
        .and_then(|v| v.as_str())
        .unwrap_or("Task");
    let cmd = task
        .get("command")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let interactive = task
        .get("interactive")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);

    if interactive {
        let shell_cmd = format!(
            "{}; echo ''; echo 'Task finished. Press Enter to close.'; read -p ''",
            cmd
        );
        let _ = Command::new("kitty")
            .args(["--title", &format!("Task: {}", name), "bash", "-c", &shell_cmd])
            .spawn();

        let _ = Command::new("notify-send")
            .args(["-a", "Task Runner", &format!("Started: {}", name), "Running in interactive terminal..."])
            .spawn();

        serde_json::json!({
            "status": "ok",
            "type": "interactive"
        })
    } else {
        match Command::new("bash").args(["-c", cmd]).output() {
            Ok(out) => {
                let stdout_text = String::from_utf8_lossy(&out.stdout);
                let stderr_text = String::from_utf8_lossy(&out.stderr);
                if out.status.success() {
                    let _ = Command::new("notify-send")
                        .args(["-a", "Task Runner", &format!("✓ {}", name), "Completed successfully."])
                        .spawn();

                    serde_json::json!({
                        "status": "ok",
                        "output": stdout_text.chars().take(500).collect::<String>()
                    })
                } else {
                    let err_msg = if !stderr_text.trim().is_empty() {
                        stderr_text.trim().to_string()
                    } else if !stdout_text.trim().is_empty() {
                        stdout_text.trim().to_string()
                    } else {
                        format!("Exited with code {:?}", out.status.code())
                    };

                    let preview = err_msg.chars().take(200).collect::<String>();
                    let _ = Command::new("notify-send")
                        .args(["-a", "Task Runner", "-u", "critical", &format!("✗ {} Failed", name), &preview])
                        .spawn();

                    serde_json::json!({
                        "status": "error",
                        "output": preview
                    })
                }
            }
            Err(e) => {
                let err_str = e.to_string();
                let _ = Command::new("notify-send")
                    .args(["-a", "Task Runner", "-u", "critical", &format!("✗ {} Error", name), &err_str])
                    .spawn();

                serde_json::json!({
                    "status": "error",
                    "message": err_str
                })
            }
        }
    }
}

pub fn run(args: &[String]) {
    let action = args.first().map(|s| s.as_str()).unwrap_or("list");
    match action {
        "create" | "save" => {
            if let Some(payload_str) = args.get(1) {
                if let Ok(obj) = serde_json::from_str::<Value>(payload_str) {
                    println!("{}", add_or_update_task(obj));
                } else {
                    println!("{{\"status\":\"error\",\"message\":\"Invalid JSON payload\"}}");
                }
            } else {
                println!("{{\"status\":\"error\",\"message\":\"Missing task payload\"}}");
            }
        }
        "delete" => {
            if let Some(tid) = args.get(1) {
                println!("{}", delete_task(tid));
            } else {
                println!("{{\"status\":\"error\",\"message\":\"Missing task id\"}}");
            }
        }
        "run" => {
            if let Some(tid) = args.get(1) {
                println!("{}", run_task(tid));
            } else {
                println!("{{\"status\":\"error\",\"message\":\"Missing task id\"}}");
            }
        }
        "list" | _ => {
            let tasks = load_tasks();
            println!("{}", Value::Array(tasks));
        }
    }
}
