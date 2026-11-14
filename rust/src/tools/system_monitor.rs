use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Write};
use std::path::Path;
use std::process::Command;

#[derive(Serialize, Deserialize, Debug, Clone)]
struct CpuMetrics {
    percent: f64,
    cores: usize,
    load_1: f64,
    load_5: f64,
    load_15: f64,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct RamMetrics {
    total_mb: u64,
    used_mb: u64,
    free_mb: u64,
    avail_mb: u64,
    cached_mb: u64,
    shmem_mb: u64,
    used_percent: u32,
    avail_percent: u32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct SwapMetrics {
    total_mb: u64,
    used_mb: u64,
    free_mb: u64,
    used_percent: u32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct AppGroup {
    name: String,
    icon: String,
    count: usize,
    cpu: f64,
    rss_mb: f64,
    swap_mb: f64,
    percent_ram: f64,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
struct ProcessItem {
    pid: u32,
    user: String,
    name: String,
    category: String,
    cpu: f64,
    rss_mb: f64,
    swap_mb: f64,
    command: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct SystemTelemetry {
    cpu: CpuMetrics,
    ram: RamMetrics,
    swap: SwapMetrics,
    groups: Vec<AppGroup>,
    top_by_mem: Vec<ProcessItem>,
    top_by_cpu: Vec<ProcessItem>,
    top_by_swap: Vec<ProcessItem>,
}

fn round1(val: f64) -> f64 {
    (val * 10.0).round() / 10.0
}

fn round2(val: f64) -> f64 {
    (val * 100.0).round() / 100.0
}

fn split_whitespace_max5(line: &str) -> Vec<&str> {
    let mut parts = Vec::with_capacity(6);
    let mut remainder = line.trim_start();

    for _ in 0..5 {
        if let Some(space_idx) = remainder.find(|c: char| c.is_whitespace()) {
            parts.push(&remainder[..space_idx]);
            remainder = remainder[space_idx..].trim_start();
        } else {
            break;
        }
    }
    if !remainder.is_empty() {
        parts.push(remainder);
    }
    parts
}

fn classify_process(comm: &str, args: &str) -> (&'static str, &'static str) {
    if comm.contains("chrome") || args.contains("chrome") {
        if args.contains("openwa") || args.contains("puppeteer") {
            ("OpenWA (WhatsApp Bot)", "message-square")
        } else {
            ("Google Chrome", "globe")
        }
    } else if comm.contains("zapzap")
        || args.contains("zapzap")
        || (comm.contains("QtWebEngineProcess") && args.contains("zapzap"))
    {
        ("ZapZap (WhatsApp)", "message-square")
    } else if comm.contains("agy") || comm.contains("antigravity") {
        ("Antigravity CLI", "sparkles")
    } else if comm.contains("qs") || comm.contains("quickshell") {
        ("Quickshell Shell", "layers")
    } else if args.contains("mcp") || args.contains("graphify") || args.contains("playwright") {
        ("MCP Tool Servers", "cpu")
    } else if comm.contains("docker") || comm.contains("containerd") {
        ("Docker Engine", "hard-drive")
    } else if comm.contains("node") && args.contains("antigravity-remote") {
        ("Antigravity Remote", "smartphone")
    } else if comm.contains("hypr") || comm.contains("waybar") {
        ("Hyprland Desktop", "monitor")
    } else if comm.contains("pipewire") || comm.contains("wireplumber") {
        ("PipeWire Audio", "volume-2")
    } else if comm.contains("easyeffects") {
        ("EasyEffects", "sliders")
    } else if comm.contains("kitty") || comm.contains("kitten") {
        ("Kitty Terminal", "terminal")
    } else if comm.contains("code") || comm.contains("cursor") {
        ("Code Editor", "code")
    } else if matches!(
        comm,
        "systemd" | "dbus-broker" | "systemd-journal" | "systemd-logind"
    ) {
        ("System Daemons", "settings")
    } else {
        ("", "activity")
    }
}

fn get_swap_kb(pid: u32) -> u64 {
    let path = format!("/proc/{}/status", pid);
    if let Ok(file) = File::open(path) {
        let reader = BufReader::new(file);
        for line in reader.lines().flatten() {
            if line.starts_with("VmSwap:") {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 2 {
                    return parts[1].parse().unwrap_or(0);
                }
            }
        }
    }
    0
}

fn get_system_telemetry() -> SystemTelemetry {
    let my_pid = std::process::id();

    // 1. Read /proc/meminfo
    let mut mem_tot = 1u64;
    let mut mem_free = 0u64;
    let mut mem_avail = 0u64;
    let mut cached = 0u64;
    let mut shmem = 0u64;
    let mut swap_tot = 0u64;
    let mut swap_free = 0u64;

    if let Ok(file) = File::open("/proc/meminfo") {
        let reader = BufReader::new(file);
        for line in reader.lines().flatten() {
            if let Some((k, v)) = line.split_once(':') {
                let key = k.trim();
                let val: u64 = v
                    .trim()
                    .split_whitespace()
                    .next()
                    .and_then(|s| s.parse().ok())
                    .unwrap_or(0);
                match key {
                    "MemTotal" => mem_tot = val.max(1),
                    "MemFree" => mem_free = val,
                    "MemAvailable" => mem_avail = val,
                    "Cached" => cached = val,
                    "Shmem" => shmem = val,
                    "SwapTotal" => swap_tot = val,
                    "SwapFree" => swap_free = val,
                    _ => {}
                }
            }
        }
    }

    let used_ram_kb = mem_tot.saturating_sub(mem_avail);
    let used_swap_kb = swap_tot.saturating_sub(swap_free);

    // Load average
    let mut load_1 = 0.0;
    let mut load_5 = 0.0;
    let mut load_15 = 0.0;
    if let Ok(load_str) = fs::read_to_string("/proc/loadavg") {
        let parts: Vec<&str> = load_str.split_whitespace().collect();
        if parts.len() >= 3 {
            load_1 = parts[0].parse().unwrap_or(0.0);
            load_5 = parts[1].parse().unwrap_or(0.0);
            load_15 = parts[2].parse().unwrap_or(0.0);
        }
    }

    // Cores
    let cores = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(1);

    // Query processes via ps
    let ps_output = Command::new("ps")
        .args(["-eo", "pid,user,%cpu,rss,comm,args", "--sort=-rss"])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
        .unwrap_or_default();

    struct GroupAcc {
        name: String,
        icon: String,
        count: usize,
        rss_kb: u64,
        swap_kb: u64,
        cpu: f64,
    }

    let mut groups_map: HashMap<String, GroupAcc> = HashMap::new();
    let mut all_procs: Vec<ProcessItem> = Vec::new();

    for (idx, line) in ps_output.lines().skip(1).enumerate() {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        let parts = split_whitespace_max5(trimmed);
        if parts.len() < 5 {
            continue;
        }

        let pid: u32 = match parts[0].parse() {
            Ok(p) => p,
            Err(_) => continue,
        };

        let user = parts[1].to_string();
        let cpu: f64 = parts[2].parse().unwrap_or(0.0);
        let rss: u64 = parts[3].parse().unwrap_or(0);
        let comm = parts[4];
        let args = if parts.len() > 5 { parts[5] } else { comm };

        // Self-filtering
        if pid == my_pid
            || comm == "ps"
            || comm == "system_monitor"
            || args.contains("system_monitor")
        {
            continue;
        }

        let swap_kb = if idx < 30 { get_swap_kb(pid) } else { 0 };

        let (mut cat, icon) = classify_process(comm, args);
        let dynamic_cat: String;
        if cat.is_empty() {
            let mut c = comm.chars();
            dynamic_cat = match c.next() {
                None => String::new(),
                Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
            };
            cat = &dynamic_cat;
        }

        let entry = groups_map
            .entry(cat.to_string())
            .or_insert_with(|| GroupAcc {
                name: cat.to_string(),
                icon: icon.to_string(),
                count: 0,
                rss_kb: 0,
                swap_kb: 0,
                cpu: 0.0,
            });
        entry.count += 1;
        entry.rss_kb += rss;
        entry.swap_kb += swap_kb;
        entry.cpu += cpu;

        let mut cmd_short = comm.to_string();
        if matches!(comm, "python" | "python3" | "node" | "ruby" | "perl") {
            let tokens: Vec<&str> = args.split_whitespace().collect();
            for t in tokens.iter().skip(1) {
                if !t.starts_with('-') {
                    cmd_short = Path::new(t)
                        .file_name()
                        .map(|f| f.to_string_lossy().to_string())
                        .unwrap_or_else(|| t.to_string());
                    break;
                }
            }
        }

        let truncated_args = if args.len() > 85 {
            args[..85].to_string()
        } else {
            args.to_string()
        };

        all_procs.push(ProcessItem {
            pid,
            user,
            name: cmd_short,
            category: cat.to_string(),
            cpu: round1(cpu),
            rss_mb: round1(rss as f64 / 1024.0),
            swap_mb: round1(swap_kb as f64 / 1024.0),
            command: truncated_args,
        });
    }

    // Top 15 Groups by RAM usage
    let mut group_list: Vec<AppGroup> = groups_map
        .into_values()
        .map(|g| AppGroup {
            name: g.name,
            icon: g.icon,
            count: g.count,
            cpu: round1(g.cpu),
            rss_mb: round1(g.rss_kb as f64 / 1024.0),
            swap_mb: round1(g.swap_kb as f64 / 1024.0),
            percent_ram: round1((g.rss_kb as f64 / mem_tot as f64) * 100.0),
        })
        .collect();
    group_list.sort_by(|a, b| {
        b.rss_mb
            .partial_cmp(&a.rss_mb)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    group_list.truncate(15);

    // Top 30 by Mem
    let mut top_by_mem = all_procs.clone();
    top_by_mem.sort_by(|a, b| {
        b.rss_mb
            .partial_cmp(&a.rss_mb)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    top_by_mem.truncate(30);

    // Top 30 by CPU
    let mut top_by_cpu = all_procs.clone();
    top_by_cpu.sort_by(|a, b| {
        b.cpu
            .partial_cmp(&a.cpu)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    top_by_cpu.truncate(30);

    // Top 30 by Swap
    let mut top_by_swap: Vec<ProcessItem> =
        all_procs.into_iter().filter(|p| p.swap_mb > 0.0).collect();
    top_by_swap.sort_by(|a, b| {
        b.swap_mb
            .partial_cmp(&a.swap_mb)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    top_by_swap.truncate(30);

    let total_cpu: f64 = top_by_cpu.iter().map(|p| p.cpu).sum();
    let norm_cpu = round1(total_cpu / (cores as f64).max(1.0)).min(100.0);

    SystemTelemetry {
        cpu: CpuMetrics {
            percent: norm_cpu,
            cores,
            load_1: round2(load_1),
            load_5: round2(load_5),
            load_15: round2(load_15),
        },
        ram: RamMetrics {
            total_mb: (mem_tot as f64 / 1024.0).round() as u64,
            used_mb: (used_ram_kb as f64 / 1024.0).round() as u64,
            free_mb: (mem_free as f64 / 1024.0).round() as u64,
            avail_mb: (mem_avail as f64 / 1024.0).round() as u64,
            cached_mb: (cached as f64 / 1024.0).round() as u64,
            shmem_mb: (shmem as f64 / 1024.0).round() as u64,
            used_percent: ((used_ram_kb as f64 / mem_tot as f64) * 100.0).round() as u32,
            avail_percent: ((mem_avail as f64 / mem_tot as f64) * 100.0).round() as u32,
        },
        swap: SwapMetrics {
            total_mb: (swap_tot as f64 / 1024.0).round() as u64,
            used_mb: (used_swap_kb as f64 / 1024.0).round() as u64,
            free_mb: (swap_free as f64 / 1024.0).round() as u64,
            used_percent: if swap_tot > 0 {
                ((used_swap_kb as f64 / swap_tot as f64) * 100.0).round() as u32
            } else {
                0
            },
        },
        groups: group_list,
        top_by_mem,
        top_by_cpu,
        top_by_swap,
    }
}

fn kill_process(pid_str: &str, force: bool) {
    if let Ok(pid) = pid_str.parse::<u32>() {
        let sig = if force { "-9" } else { "-15" };
        let status = Command::new("kill").args([sig, &pid.to_string()]).status();
        match status {
            Ok(s) if s.success() => {
                println!(
                    r#"{{"success":true,"pid":{},"signal":{}}}"#,
                    pid,
                    if force { 9 } else { 15 }
                );
            }
            Ok(_) | Err(_) => {
                println!(
                    r#"{{"success":false,"pid":{},"error":"failed to kill"}}"#,
                    pid
                );
            }
        }
    } else {
        println!(r#"{{"success":false,"error":"Invalid PID"}}"#);
    }
}

fn drop_caches() {
    let _ = Command::new("sync").status();
    if let Ok(mut f) = File::create("/proc/sys/vm/drop_caches") {
        if f.write_all(b"3\n").is_ok() {
            println!(r#"{{"success":true}}"#);
            return;
        }
    }
    println!(r#"{{"success":false,"error":"Permission denied"}}"#);
}

pub fn run(args: &[String]) {
    let action = args.first().map(|s| s.as_str()).unwrap_or("data");

    match action {
        "data" => {
            let telemetry = get_system_telemetry();
            if let Ok(json) = serde_json::to_string(&telemetry) {
                println!("{}", json);
            }
        }
        "kill" => {
            if let Some(pid_str) = args.get(1) {
                let force = args
                    .get(2)
                    .map(|s| matches!(s.as_str(), "1" | "true" | "force" | "-9"))
                    .unwrap_or(false);
                kill_process(pid_str, force);
            } else {
                println!(r#"{{"success":false,"error":"Missing PID"}}"#);
            }
        }
        "drop_caches" => {
            drop_caches();
        }
        _ => {
            println!(r#"{{"error":"Unknown action"}}"#);
        }
    }
}
