//! High-Performance Docker Container Manager Backend in Rust
//! Provides sub-50ms JSON telemetry and action orchestration for Antigravity Quickshell.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::process::Command;
use std::thread;

const STATS_CACHE: &str = "/tmp/docker_stats_cache.json";

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
struct StatEntry {
    cpu: String,
    mem: String,
    mem_perc: String,
    net: String,
    pids: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct ContainerItem {
    id: String,
    name: String,
    image: String,
    state: String,
    status: String,
    ports: String,
    compose_project: String,
    compose_service: String,
    created: String,
    cpu_perc: String,
    mem_usage: String,
    mem_perc: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct ImageItem {
    id: String,
    repository: String,
    tag: String,
    size: String,
    created: String,
    containers: i64,
}

#[derive(Debug, Serialize, Deserialize)]
struct Summary {
    total: usize,
    running: usize,
    stopped: usize,
    paused: usize,
    images_count: usize,
}

#[derive(Debug, Serialize, Deserialize)]
struct DockerData {
    daemon_running: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
    containers: Vec<ContainerItem>,
    images: Vec<ImageItem>,
    summary: Summary,
}

#[derive(Debug, Serialize, Deserialize)]
struct ActionResult {
    status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    message: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    output: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    logs: Option<String>,
}

fn get_stats_cache() -> HashMap<String, StatEntry> {
    if let Ok(content) = fs::read_to_string(STATS_CACHE) {
        if let Ok(map) = serde_json::from_str(&content) {
            return map;
        }
    }
    HashMap::new()
}

fn update_stats_cache() -> HashMap<String, StatEntry> {
    let mut stats_map = HashMap::new();
    if let Ok(res) = Command::new("docker")
        .args(["stats", "--no-stream", "--format", "{{json .}}"])
        .output()
    {
        if res.status.success() {
            let stdout = String::from_utf8_lossy(&res.stdout);
            for line in stdout.lines() {
                let trimmed = line.trim();
                if trimmed.is_empty() {
                    continue;
                }
                if let Ok(val) = serde_json::from_str::<serde_json::Value>(trimmed) {
                    let cid = val.get("ID").and_then(|v| v.as_str()).unwrap_or("");
                    let name = val.get("Name").and_then(|v| v.as_str()).unwrap_or("");
                    let st = StatEntry {
                        cpu: val.get("CPUPerc").and_then(|v| v.as_str()).unwrap_or("0.00%").to_string(),
                        mem: val.get("MemUsage").and_then(|v| v.as_str()).unwrap_or("0B").to_string(),
                        mem_perc: val.get("MemPerc").and_then(|v| v.as_str()).unwrap_or("0.00%").to_string(),
                        net: val.get("NetIO").and_then(|v| v.as_str()).unwrap_or("0B / 0B").to_string(),
                        pids: val.get("PIDs").and_then(|v| v.as_str()).unwrap_or("0").to_string(),
                    };
                    if !cid.is_empty() {
                        stats_map.insert(cid.to_string(), st.clone());
                    }
                    if !name.is_empty() {
                        stats_map.insert(name.to_string(), st);
                    }
                }
            }
            if let Ok(json_str) = serde_json::to_string(&stats_map) {
                let _ = fs::write(STATS_CACHE, json_str);
            }
        }
    }
    stats_map
}

fn format_ports(ports_raw: &str) -> String {
    let mut clean_ports = Vec::new();
    for p in ports_raw.split(',') {
        let p = p.trim();
        if p.is_empty() {
            continue;
        }
        if let Some((host_part, cont_part)) = p.split_once("->") {
            let host_port = host_part.rsplit(':').next().unwrap_or(host_part);
            let cont_port = cont_part.split('/').next().unwrap_or(cont_part);
            let entry = format!("{}:{}", host_port, cont_port);
            if !clean_ports.contains(&entry) {
                clean_ports.push(entry);
            }
        } else if let Some((proto_left, _)) = p.split_once('/') {
            let entry = proto_left.to_string();
            if !clean_ports.contains(&entry) {
                clean_ports.push(entry);
            }
        }
    }
    clean_ports.join(", ")
}

fn get_docker_data() -> DockerData {
    // 1. Check daemon status
    let ping = Command::new("docker")
        .args(["info", "--format", "{{json .ServerErrors}}"])
        .output();

    let is_running = match ping {
        Ok(ref out) => out.status.success(),
        Err(_) => false,
    };

    if !is_running {
        return DockerData {
            daemon_running: false,
            error: Some("Docker daemon is not running or socket is inaccessible.".to_string()),
            containers: Vec::new(),
            images: Vec::new(),
            summary: Summary {
                total: 0,
                running: 0,
                stopped: 0,
                paused: 0,
                images_count: 0,
            },
        };
    }

    let stats_cache = get_stats_cache();

    // Parallel fetch: containers and images
    let handle_ps = thread::spawn(|| {
        Command::new("docker")
            .args(["ps", "-a", "--format", "{{json .}}"])
            .output()
    });

    let handle_img = thread::spawn(|| {
        Command::new("docker")
            .args(["images", "--format", "{{json .}}"])
            .output()
    });

    let ps_res = handle_ps.join().unwrap_or_else(|_| Ok(std::process::Output {
        status: std::os::unix::process::ExitStatusExt::from_raw(1),
        stdout: Vec::new(),
        stderr: Vec::new(),
    }));

    let img_res = handle_img.join().unwrap_or_else(|_| Ok(std::process::Output {
        status: std::os::unix::process::ExitStatusExt::from_raw(1),
        stdout: Vec::new(),
        stderr: Vec::new(),
    }));

    let mut containers = Vec::new();
    let mut running_count = 0;
    let mut stopped_count = 0;
    let mut paused_count = 0;

    if let Ok(out) = ps_res {
        if out.status.success() {
            let stdout = String::from_utf8_lossy(&out.stdout);
            for line in stdout.lines() {
                let trimmed = line.trim();
                if trimmed.is_empty() {
                    continue;
                }
                if let Ok(raw) = serde_json::from_str::<serde_json::Value>(trimmed) {
                    let cid = raw.get("ID").and_then(|v| v.as_str()).unwrap_or("");
                    let name = raw.get("Names").and_then(|v| v.as_str()).unwrap_or("").trim_start_matches('/');
                    let state = raw.get("State").and_then(|v| v.as_str()).unwrap_or("unknown").to_lowercase();
                    let status = raw.get("Status").and_then(|v| v.as_str()).unwrap_or("");
                    let image = raw.get("Image").and_then(|v| v.as_str()).unwrap_or("");
                    let ports_raw = raw.get("Ports").and_then(|v| v.as_str()).unwrap_or("");
                    let created = raw.get("RunningFor").and_then(|v| v.as_str()).unwrap_or("");
                    let labels_str = raw.get("Labels").and_then(|v| v.as_str()).unwrap_or("");

                    let mut compose_project = String::new();
                    let mut compose_service = String::new();
                    if !labels_str.is_empty() {
                        for part in labels_str.split(',') {
                            if let Some(val) = part.strip_prefix("com.docker.compose.project=") {
                                compose_project = val.to_string();
                            } else if let Some(val) = part.strip_prefix("com.docker.compose.service=") {
                                compose_service = val.to_string();
                            }
                        }
                    }

                    let ports_display = format_ports(ports_raw);

                    let cid_short = if cid.len() >= 12 { &cid[..12] } else { cid };
                    let st = stats_cache.get(cid_short).or_else(|| stats_cache.get(name));

                    let is_running_state = state == "running";
                    let cpu_perc = if is_running_state {
                        st.map(|s| s.cpu.clone()).unwrap_or_default()
                    } else {
                        String::new()
                    };
                    let mem_usage = if is_running_state {
                        st.map(|s| s.mem.clone()).unwrap_or_default()
                    } else {
                        String::new()
                    };
                    let mem_perc = if is_running_state {
                        st.map(|s| s.mem_perc.clone()).unwrap_or_default()
                    } else {
                        String::new()
                    };

                    if is_running_state {
                        running_count += 1;
                    } else if state == "paused" {
                        paused_count += 1;
                    } else {
                        stopped_count += 1;
                    }

                    containers.push(ContainerItem {
                        id: cid_short.to_string(),
                        name: name.to_string(),
                        image: image.to_string(),
                        state,
                        status: status.to_string(),
                        ports: ports_display,
                        compose_project,
                        compose_service,
                        created: created.to_string(),
                        cpu_perc,
                        mem_usage,
                        mem_perc,
                    });
                }
            }
        }
    }

    let mut images = Vec::new();
    if let Ok(out) = img_res {
        if out.status.success() {
            let stdout = String::from_utf8_lossy(&out.stdout);
            for line in stdout.lines() {
                let trimmed = line.trim();
                if trimmed.is_empty() {
                    continue;
                }
                if let Ok(raw) = serde_json::from_str::<serde_json::Value>(trimmed) {
                    let repo = raw.get("Repository").and_then(|v| v.as_str()).unwrap_or("");
                    let tag = raw.get("Tag").and_then(|v| v.as_str()).unwrap_or("");
                    if repo == "<none>" && tag == "<none>" {
                        continue;
                    }
                    let id_full = raw.get("ID").and_then(|v| v.as_str()).unwrap_or("");
                    let id_short = if id_full.len() >= 12 { &id_full[..12] } else { id_full };
                    let size = raw.get("Size").and_then(|v| v.as_str()).unwrap_or("");
                    let created = raw.get("CreatedSince").and_then(|v| v.as_str()).unwrap_or("");
                    let cont_str = raw.get("Containers").and_then(|v| v.as_str()).unwrap_or("0");
                    let containers_cnt = cont_str.parse::<i64>().unwrap_or(0);

                    images.push(ImageItem {
                        id: id_short.to_string(),
                        repository: repo.to_string(),
                        tag: tag.to_string(),
                        size: size.to_string(),
                        created: created.to_string(),
                        containers: containers_cnt,
                    });
                }
            }
        }
    }

    let total = containers.len();
    let images_count = images.len();

    DockerData {
        daemon_running: true,
        error: None,
        containers,
        images,
        summary: Summary {
            total,
            running: running_count,
            stopped: stopped_count,
            paused: paused_count,
            images_count,
        },
    }
}

fn perform_action(action: &str, target: &str, args: &[String]) -> ActionResult {
    let act = action.to_lowercase();
    match act.as_str() {
        "start" | "stop" | "restart" | "pause" | "unpause" => {
            if target.is_empty() {
                return ActionResult {
                    status: "error".to_string(),
                    message: Some("No target container specified.".to_string()),
                    output: None,
                    logs: None,
                };
            }
            let res = Command::new("docker").args([act.as_str(), target]).output();
            match res {
                Ok(out) => {
                    let text = if out.stdout.is_empty() {
                        String::from_utf8_lossy(&out.stderr).to_string()
                    } else {
                        String::from_utf8_lossy(&out.stdout).to_string()
                    };
                    ActionResult {
                        status: if out.status.success() { "ok".to_string() } else { "error".to_string() },
                        message: None,
                        output: Some(text),
                        logs: None,
                    }
                }
                Err(e) => ActionResult {
                    status: "error".to_string(),
                    message: Some(e.to_string()),
                    output: None,
                    logs: None,
                },
            }
        }
        "remove" => {
            if target.is_empty() {
                return ActionResult {
                    status: "error".to_string(),
                    message: Some("No target container specified.".to_string()),
                    output: None,
                    logs: None,
                };
            }
            let res = Command::new("docker").args(["rm", "-f", target]).output();
            match res {
                Ok(out) => {
                    let text = if out.stdout.is_empty() {
                        String::from_utf8_lossy(&out.stderr).to_string()
                    } else {
                        String::from_utf8_lossy(&out.stdout).to_string()
                    };
                    ActionResult {
                        status: if out.status.success() { "ok".to_string() } else { "error".to_string() },
                        message: None,
                        output: Some(text),
                        logs: None,
                    }
                }
                Err(e) => ActionResult {
                    status: "error".to_string(),
                    message: Some(e.to_string()),
                    output: None,
                    logs: None,
                },
            }
        }
        "remove_image" => {
            if target.is_empty() {
                return ActionResult {
                    status: "error".to_string(),
                    message: Some("No target image specified.".to_string()),
                    output: None,
                    logs: None,
                };
            }
            let res = Command::new("docker").args(["rmi", target]).output();
            match res {
                Ok(out) => {
                    let text = if out.stdout.is_empty() {
                        String::from_utf8_lossy(&out.stderr).to_string()
                    } else {
                        String::from_utf8_lossy(&out.stdout).to_string()
                    };
                    ActionResult {
                        status: if out.status.success() { "ok".to_string() } else { "error".to_string() },
                        message: None,
                        output: Some(text),
                        logs: None,
                    }
                }
                Err(e) => ActionResult {
                    status: "error".to_string(),
                    message: Some(e.to_string()),
                    output: None,
                    logs: None,
                },
            }
        }
        "prune_containers" => {
            let res = Command::new("docker").args(["container", "prune", "-f"]).output();
            match res {
                Ok(out) => ActionResult {
                    status: if out.status.success() { "ok".to_string() } else { "error".to_string() },
                    message: None,
                    output: Some(String::from_utf8_lossy(&out.stdout).to_string()),
                    logs: None,
                },
                Err(e) => ActionResult {
                    status: "error".to_string(),
                    message: Some(e.to_string()),
                    output: None,
                    logs: None,
                },
            }
        }
        "prune_images" => {
            let res = Command::new("docker").args(["image", "prune", "-f"]).output();
            match res {
                Ok(out) => ActionResult {
                    status: if out.status.success() { "ok".to_string() } else { "error".to_string() },
                    message: None,
                    output: Some(String::from_utf8_lossy(&out.stdout).to_string()),
                    logs: None,
                },
                Err(e) => ActionResult {
                    status: "error".to_string(),
                    message: Some(e.to_string()),
                    output: None,
                    logs: None,
                },
            }
        }
        "start_all" => {
            let cmd = "docker start $(docker ps -a -q -f status=exited)";
            let res = Command::new("sh").args(["-c", cmd]).output();
            match res {
                Ok(out) => ActionResult {
                    status: if out.status.success() { "ok".to_string() } else { "error".to_string() },
                    message: None,
                    output: Some(String::from_utf8_lossy(&out.stdout).to_string()),
                    logs: None,
                },
                Err(e) => ActionResult {
                    status: "error".to_string(),
                    message: Some(e.to_string()),
                    output: None,
                    logs: None,
                },
            }
        }
        "stop_all" => {
            let cmd = "docker stop $(docker ps -q)";
            let res = Command::new("sh").args(["-c", cmd]).output();
            match res {
                Ok(out) => ActionResult {
                    status: if out.status.success() { "ok".to_string() } else { "error".to_string() },
                    message: None,
                    output: Some(String::from_utf8_lossy(&out.stdout).to_string()),
                    logs: None,
                },
                Err(e) => ActionResult {
                    status: "error".to_string(),
                    message: Some(e.to_string()),
                    output: None,
                    logs: None,
                },
            }
        }
        "logs" => {
            let lines = if !args.is_empty() && args[0].chars().all(|c| c.is_ascii_digit()) {
                &args[0]
            } else {
                "100"
            };
            let res = Command::new("docker").args(["logs", "--tail", lines, target]).output();
            match res {
                Ok(out) => {
                    let mut text = String::from_utf8_lossy(&out.stdout).to_string();
                    if !out.stderr.is_empty() {
                        text.push('\n');
                        text.push_str(&String::from_utf8_lossy(&out.stderr));
                    }
                    ActionResult {
                        status: "ok".to_string(),
                        message: None,
                        output: None,
                        logs: Some(text),
                    }
                }
                Err(e) => ActionResult {
                    status: "error".to_string(),
                    message: Some(e.to_string()),
                    output: None,
                    logs: None,
                },
            }
        }
        "terminal" => {
            let cmd = format!(
                r#"kitty --title "Docker Exec: {target}" bash -c "docker exec -it {target} /bin/bash || docker exec -it {target} /bin/sh || (echo Container shell unavailable; read -p Press_Enter)""#
            );
            let _ = Command::new("sh").args(["-c", &cmd]).spawn();
            ActionResult {
                status: "ok".to_string(),
                message: Some(format!("Terminal opened for {target}")),
                output: None,
                logs: None,
            }
        }
        "live_logs" => {
            let cmd = format!(r#"kitty --title "Docker Logs: {target}" docker logs -f --tail 200 {target}"#);
            let _ = Command::new("sh").args(["-c", &cmd]).spawn();
            ActionResult {
                status: "ok".to_string(),
                message: Some(format!("Logs opened for {target}")),
                output: None,
                logs: None,
            }
        }
        _ => ActionResult {
            status: "error".to_string(),
            message: Some(format!("Unknown action '{action}'")),
            output: None,
            logs: None,
        },
    }
}

pub fn run(args: &[String]) {
    if args.is_empty() || args[0] == "data" {
        let data = get_docker_data();
        if let Ok(json_str) = serde_json::to_string(&data) {
            println!("{}", json_str);
        }
    } else if args[0] == "stats" {
        let stats = update_stats_cache();
        if let Ok(json_str) = serde_json::to_string(&stats) {
            println!("{}", json_str);
        }
    } else if args[0] == "action" {
        let action = if args.len() > 1 { &args[1] } else { "" };
        let target = if args.len() > 2 { &args[2] } else { "" };
        let rest = if args.len() > 3 { &args[3..] } else { &[] };
        let res = perform_action(action, target, rest);
        if let Ok(json_str) = serde_json::to_string(&res) {
            println!("{}", json_str);
        }
    } else {
        let data = get_docker_data();
        if let Ok(json_str) = serde_json::to_string(&data) {
            println!("{}", json_str);
        }
    }
}
