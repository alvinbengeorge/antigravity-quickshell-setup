use serde::{Deserialize, Serialize};
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Write};
use std::thread::sleep;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const CPU_PREV_FILE: &str = "/tmp/qs_cpu_prev.json";
const NET_PREV_FILE: &str = "/tmp/qs_net_prev.json";

#[derive(Serialize, Deserialize, Debug)]
struct CpuPrev {
    idle: f64,
    total: f64,
}

#[derive(Serialize, Deserialize, Debug)]
struct NetPrev {
    rx: u64,
    tx: u64,
    time: f64,
}

#[derive(Serialize, Debug)]
struct SystemStats {
    cpu: u32,
    mem: u32,
    swap: u32,
    down: String,
    up: String,
}

fn current_time_secs() -> f64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs_f64())
        .unwrap_or(0.0)
}

fn format_speed(b_s: f64) -> String {
    if b_s < 1024.0 {
        format!("{}B", b_s.round() as u64)
    } else if b_s < 1024.0 * 1024.0 {
        let kb = b_s / 1024.0;
        if kb >= 100.0 {
            format!("{}K", kb.round() as u64)
        } else {
            format!("{:.1}K", kb)
        }
    } else {
        let mb = b_s / (1024.0 * 1024.0);
        format!("{:.1}M", mb)
    }
}

// 1. CPU differential
fn compute_cpu(prev: Option<&CpuPrev>) -> (u32, CpuPrev) {
    let mut idle = 0.0;
    let mut total = 0.0;

    if let Ok(file) = File::open("/proc/stat") {
        let mut reader = BufReader::new(file);
        let mut first_line = String::new();
        if reader.read_line(&mut first_line).is_ok() {
            let mut parts = first_line.split_whitespace();
            if parts.next() == Some("cpu") {
                let fields: Vec<f64> = parts.filter_map(|s| s.parse::<f64>().ok()).collect();
                if fields.len() >= 4 {
                    idle = fields[3] + if fields.len() > 4 { fields[4] } else { 0.0 };
                    total = fields.iter().sum();
                }
            }
        }
    }

    let mut cpu_pct = 0u32;
    if let Some(p) = prev {
        let d_idle = idle - p.idle;
        let d_total = total - p.total;
        if d_total > 0.0 {
            let ratio = 1.0 - (d_idle / d_total);
            cpu_pct = (ratio.clamp(0.0, 1.0) * 100.0).round() as u32;
        }
    }

    (cpu_pct, CpuPrev { idle, total })
}

// 2. RAM and Swap
fn compute_mem_swap() -> (u32, u32) {
    let mut mem_tot = 0u64;
    let mut mem_avail = 0u64;
    let mut swap_tot = 0u64;
    let mut swap_free = 0u64;

    if let Ok(file) = File::open("/proc/meminfo") {
        let reader = BufReader::new(file);
        for line in reader.lines().flatten() {
            if let Some((k, v)) = line.split_once(':') {
                let key = k.trim();
                let val_str = v.trim().split_whitespace().next().unwrap_or("0");
                match key {
                    "MemTotal" => mem_tot = val_str.parse().unwrap_or(0),
                    "MemAvailable" => mem_avail = val_str.parse().unwrap_or(0),
                    "SwapTotal" => swap_tot = val_str.parse().unwrap_or(0),
                    "SwapFree" => swap_free = val_str.parse().unwrap_or(0),
                    _ => {}
                }
            }
        }
    }

    let mem_pct = if mem_tot > 0 {
        let used = mem_tot.saturating_sub(mem_avail);
        ((used as f64 / mem_tot as f64) * 100.0).round() as u32
    } else {
        0
    };

    let swap_pct = if swap_tot > 0 {
        let used = swap_tot.saturating_sub(swap_free);
        ((used as f64 / swap_tot as f64) * 100.0).round() as u32
    } else {
        0
    };

    (mem_pct.min(100), swap_pct.min(100))
}

// 3. Network speed differential
fn compute_net(prev: Option<&NetPrev>, now: f64) -> (String, String, NetPrev) {
    let mut rx_total = 0u64;
    let mut tx_total = 0u64;

    if let Ok(file) = File::open("/proc/net/dev") {
        let reader = BufReader::new(file);
        for (idx, line) in reader.lines().flatten().enumerate() {
            if idx < 2 {
                continue;
            }
            if let Some((iface, stats)) = line.split_once(':') {
                let iface_clean = iface.trim();
                if iface_clean == "lo"
                    || iface_clean.starts_with("docker")
                    || iface_clean.starts_with("br-")
                    || iface_clean.starts_with("veth")
                {
                    continue;
                }
                let cols: Vec<&str> = stats.split_whitespace().collect();
                if cols.len() >= 9 {
                    if let Ok(rx) = cols[0].parse::<u64>() {
                        rx_total += rx;
                    }
                    if let Ok(tx) = cols[8].parse::<u64>() {
                        tx_total += tx;
                    }
                }
            }
        }
    }

    let mut rx_speed = 0.0;
    let mut tx_speed = 0.0;

    if let Some(p) = prev {
        let dt = now - p.time;
        if dt > 0.2 {
            let d_rx = rx_total.saturating_sub(p.rx) as f64;
            let d_tx = tx_total.saturating_sub(p.tx) as f64;
            rx_speed = (d_rx / dt).max(0.0);
            tx_speed = (d_tx / dt).max(0.0);
        }
    }

    (
        format_speed(rx_speed),
        format_speed(tx_speed),
        NetPrev {
            rx: rx_total,
            tx: tx_total,
            time: now,
        },
    )
}

fn run_oneshot() {
    let prev_cpu = fs::read_to_string(CPU_PREV_FILE)
        .ok()
        .and_then(|s| serde_json::from_str::<CpuPrev>(&s).ok());

    let (cpu_pct, new_cpu) = compute_cpu(prev_cpu.as_ref());
    if let Ok(json) = serde_json::to_string(&new_cpu) {
        let _ = fs::write(CPU_PREV_FILE, json);
    }

    let (mem_pct, swap_pct) = compute_mem_swap();

    let prev_net = fs::read_to_string(NET_PREV_FILE)
        .ok()
        .and_then(|s| serde_json::from_str::<NetPrev>(&s).ok());

    let now = current_time_secs();
    let (down, up, new_net) = compute_net(prev_net.as_ref(), now);
    if let Ok(json) = serde_json::to_string(&new_net) {
        let _ = fs::write(NET_PREV_FILE, json);
    }

    let stats = SystemStats {
        cpu: cpu_pct,
        mem: mem_pct,
        swap: swap_pct,
        down,
        up,
    };

    if let Ok(json) = serde_json::to_string(&stats) {
        println!("{}", json);
    }
}

fn run_stream(interval_ms: u64) {
    // Warm up reading
    let (_, c) = compute_cpu(None);
    let mut prev_cpu = Some(c);

    let now = current_time_secs();
    let (_, _, n) = compute_net(None, now);
    let mut prev_net = Some(n);

    let dur = Duration::from_millis(interval_ms);
    let mut stdout = std::io::stdout().lock();

    loop {
        sleep(dur);

        let (cpu_pct, new_cpu) = compute_cpu(prev_cpu.as_ref());
        prev_cpu = Some(new_cpu);

        let (mem_pct, swap_pct) = compute_mem_swap();

        let t = current_time_secs();
        let (down, up, new_net) = compute_net(prev_net.as_ref(), t);
        prev_net = Some(new_net);

        let stats = SystemStats {
            cpu: cpu_pct,
            mem: mem_pct,
            swap: swap_pct,
            down,
            up,
        };

        if let Ok(json) = serde_json::to_string(&stats) {
            let _ = writeln!(stdout, "{}", json);
            let _ = stdout.flush();
        }
    }
}

pub fn run(args: &[String]) {
    if !args.is_empty() && (args[0] == "--stream" || args[0] == "-s" || args[0] == "--watch") {
        let ms = args
            .get(1)
            .and_then(|s| s.parse::<u64>().ok())
            .unwrap_or(2500);
        run_stream(ms);
    } else {
        run_oneshot();
    }
}
