//! Battery Telemetry and Power Management for Quickshell
//! Reads Linux sysfs (/sys/class/power_supply/BAT*) directly with microsecond latency,
//! queries UPower properties via busctl when available, and provides helper actions.

use serde::Serialize;
use std::fs;
use std::path::Path;
use std::process::Command;

#[derive(Serialize)]
pub struct BatteryInfo {
    pub capacity: u32,
    pub status: String,
    pub time_empty: u64,
    pub time_full: u64,
    pub energy_rate: f64,
}

fn open_power_statistics() {
    // Check if gnome-power-statistics is already open in hyprland
    if let Ok(output) = Command::new("hyprctl").args(["clients", "-j"]).output() {
        if let Ok(clients) = serde_json::from_slice::<Vec<serde_json::Value>>(&output.stdout) {
            for c in clients {
                if let Some(cls) = c.get("class").and_then(|v| v.as_str()) {
                    if cls.contains("org.gnome.PowerStats") {
                        if let Some(addr) = c.get("address").and_then(|v| v.as_str()) {
                            let _ = Command::new("hyprctl")
                                .args(["dispatch", "focuswindow", &format!("address:{}", addr)])
                                .output();
                            return;
                        }
                    }
                }
            }
        }
    }

    // Otherwise launch detached via setsid
    let _ = Command::new("setsid")
        .arg("gnome-power-statistics")
        .spawn();
}

fn get_battery_info() -> BatteryInfo {
    let mut bat_dir = None;
    for name in &["BAT0", "BAT1", "BAT2"] {
        let p = format!("/sys/class/power_supply/{}", name);
        if Path::new(&p).exists() {
            bat_dir = Some(p);
            break;
        }
    }

    let mut capacity = 0;
    let mut status = "Unknown".to_string();
    let mut energy_rate = 0.0;
    let mut time_empty = 0;
    let mut time_full = 0;

    if let Some(ref dir) = bat_dir {
        if let Ok(content) = fs::read_to_string(format!("{}/capacity", dir)) {
            capacity = content.trim().parse().unwrap_or(0);
        }
        if let Ok(content) = fs::read_to_string(format!("{}/status", dir)) {
            status = content.trim().to_string();
        }
        if let Ok(content) = fs::read_to_string(format!("{}/power_now", dir)) {
            if let Ok(val) = content.trim().parse::<f64>() {
                energy_rate = (val / 1_000_000.0 * 10.0).round() / 10.0;
            }
        } else if let (Ok(curr), Ok(volt)) = (
            fs::read_to_string(format!("{}/current_now", dir)),
            fs::read_to_string(format!("{}/voltage_now", dir)),
        ) {
            if let (Ok(c), Ok(v)) = (curr.trim().parse::<f64>(), volt.trim().parse::<f64>()) {
                energy_rate = ((c * v) / 1e12 * 10.0).round() / 10.0;
            }
        }
    }

    // Try UPower via busctl for TimeToEmpty, TimeToFull, and fallback EnergyRate
    if let Ok(out) = Command::new("busctl")
        .args([
            "call",
            "org.freedesktop.UPower",
            "/org/freedesktop/UPower/devices/DisplayDevice",
            "org.freedesktop.DBus.Properties",
            "Get",
            "ss",
            "org.freedesktop.UPower.Device",
            "TimeToEmpty",
        ])
        .output()
    {
        let text = String::from_utf8_lossy(&out.stdout);
        let parts: Vec<&str> = text.split_whitespace().collect();
        if parts.len() >= 3 {
            time_empty = parts[2].parse().unwrap_or(0);
        }
    }

    if let Ok(out) = Command::new("busctl")
        .args([
            "call",
            "org.freedesktop.UPower",
            "/org/freedesktop/UPower/devices/DisplayDevice",
            "org.freedesktop.DBus.Properties",
            "Get",
            "ss",
            "org.freedesktop.UPower.Device",
            "TimeToFull",
        ])
        .output()
    {
        let text = String::from_utf8_lossy(&out.stdout);
        let parts: Vec<&str> = text.split_whitespace().collect();
        if parts.len() >= 3 {
            time_full = parts[2].parse().unwrap_or(0);
        }
    }

    if energy_rate == 0.0 {
        if let Ok(out) = Command::new("busctl")
            .args([
                "call",
                "org.freedesktop.UPower",
                "/org/freedesktop/UPower/devices/DisplayDevice",
                "org.freedesktop.DBus.Properties",
                "Get",
                "ss",
                "org.freedesktop.UPower.Device",
                "EnergyRate",
            ])
            .output()
        {
            let text = String::from_utf8_lossy(&out.stdout);
            let parts: Vec<&str> = text.split_whitespace().collect();
            if parts.len() >= 3 {
                if let Ok(rate) = parts[2].parse::<f64>() {
                    energy_rate = (rate * 10.0).round() / 10.0;
                }
            }
        }
    }

    BatteryInfo {
        capacity,
        status,
        time_empty,
        time_full,
        energy_rate,
    }
}

pub fn run(args: &[String]) {
    if args.first().map(|s| s.as_str()) == Some("open-stats") {
        open_power_statistics();
        return;
    }

    let info = get_battery_info();
    if let Ok(json) = serde_json::to_string(&info) {
        println!("{}", json);
    }
}
