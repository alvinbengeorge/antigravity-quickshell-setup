//! Network and Bluetooth Telemetry & Control Engine for Quickshell
//! Fast native queries for WiFi, default IP routing, and BlueZ Bluetooth devices.

use serde::Serialize;
use std::collections::HashMap;
use std::process::Command;

#[derive(Serialize, Clone, Default)]
pub struct ActiveWifi {
    pub ssid: String,
    pub signal: u32,
    pub freq: String,
    pub security: String,
    pub rate: String,
    pub ip: String,
    pub bars: String,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct WifiNetwork {
    pub ssid: String,
    pub signal: u32,
    pub freq: String,
    pub security: String,
    pub rate: String,
    pub bars: String,
    pub in_use: bool,
}

#[derive(Serialize, Clone)]
pub struct BtDevice {
    pub mac: String,
    pub name: String,
    pub connected: bool,
    pub paired: bool,
    pub battery: i32,
    pub icon: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct NetworkReport {
    pub status: String,
    pub wifi_enabled: bool,
    pub active_ssid: String,
    pub active_wifi: ActiveWifi,
    pub networks: Vec<WifiNetwork>,
    pub bt_powered: bool,
    pub bt_devices: Vec<BtDevice>,
    pub connected_bt_count: usize,
    pub primary_connected_bt: Option<BtDevice>,
}

fn get_wifi_details() -> (bool, ActiveWifi, Vec<WifiNetwork>) {
    let mut wifi_enabled = false;
    if let Ok(out) = Command::new("nmcli").args(["radio", "wifi"]).output() {
        let text = String::from_utf8_lossy(&out.stdout).trim().to_lowercase();
        wifi_enabled = text == "enabled";
    }

    let mut active = ActiveWifi::default();
    let mut networks_map: HashMap<String, WifiNetwork> = HashMap::new();

    if wifi_enabled {
        // Query default IPv4 route to find WiFi interface & IP address
        if let Ok(out) = Command::new("ip").args(["-4", "route", "show", "default"]).output() {
            let text = String::from_utf8_lossy(&out.stdout);
            if let Some(pos) = text.find("dev ") {
                let rest = &text[pos + 4..];
                let dev = rest.split_whitespace().next().unwrap_or("");
                if !dev.is_empty() {
                    if let Ok(addr_out) = Command::new("ip").args(["-4", "addr", "show", dev]).output() {
                        let addr_text = String::from_utf8_lossy(&addr_out.stdout);
                        for line in addr_text.lines() {
                            let line = line.trim();
                            if line.starts_with("inet ") {
                                if let Some(ip_cidr) = line.split_whitespace().nth(1) {
                                    active.ip = ip_cidr.split('/').next().unwrap_or("").to_string();
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Query visible WiFi networks via nmcli tabular mode
        if let Ok(out) = Command::new("nmcli")
            .args(["-t", "-f", "ACTIVE,SSID,SIGNAL,FREQ,SECURITY,RATE,BARS", "dev", "wifi"])
            .output()
        {
            let text = String::from_utf8_lossy(&out.stdout);
            for line in text.lines() {
                if line.is_empty() {
                    continue;
                }
                let parts: Vec<&str> = line.split(':').collect();
                if parts.len() >= 6 {
                    let is_active = parts[0].eq_ignore_ascii_case("yes");
                    let ssid = parts[1].trim();
                    if ssid.is_empty() {
                        continue;
                    }
                    let signal = parts[2].trim().parse::<u32>().unwrap_or(0);
                    let freq_raw = parts[3].trim();
                    let freq = if freq_raw.starts_with('5') {
                        "5 GHz".to_string()
                    } else {
                        "2.4 GHz".to_string()
                    };
                    let sec = if parts[4].trim().is_empty() {
                        "Open".to_string()
                    } else {
                        parts[4].trim().to_string()
                    };
                    let rate = parts[5].trim().to_string();
                    let bars = if parts.len() >= 7 { parts[6].trim().to_string() } else { String::new() };

                    if is_active {
                        active.ssid = ssid.to_string();
                        active.signal = signal;
                        active.freq = freq.clone();
                        active.security = sec.clone();
                        active.rate = rate.clone();
                        active.bars = bars.clone();
                    }

                    let should_insert = match networks_map.get(ssid) {
                        Some(existing) => signal > existing.signal,
                        None => true,
                    };

                    if should_insert {
                        networks_map.insert(
                            ssid.to_string(),
                            WifiNetwork {
                                ssid: ssid.to_string(),
                                signal,
                                freq,
                                security: sec,
                                rate,
                                bars,
                                in_use: is_active,
                            },
                        );
                    }
                }
            }
        }
    }

    let mut networks: Vec<WifiNetwork> = networks_map.into_values().collect();
    for n in &mut networks {
        if !active.ssid.is_empty() && n.ssid == active.ssid {
            n.in_use = true;
        }
    }
    networks.sort_by(|a, b| {
        b.in_use
            .cmp(&a.in_use)
            .then_with(|| b.signal.cmp(&a.signal))
    });

    (wifi_enabled, active, networks)
}

fn get_bluetooth_details() -> (bool, Vec<BtDevice>) {
    let mut bt_powered = false;
    let mut devices = Vec::new();

    if let Ok(out) = Command::new("bluetoothctl").arg("show").output() {
        let text = String::from_utf8_lossy(&out.stdout);
        bt_powered = text.contains("Powered: yes");
    }

    if let Ok(out) = Command::new("bluetoothctl").arg("devices").output() {
        let text = String::from_utf8_lossy(&out.stdout);
        for line in text.lines() {
            let line = line.trim();
            if !line.starts_with("Device ") {
                continue;
            }
            let mut parts = line.splitn(3, ' ');
            let _ = parts.next(); // "Device"
            let mac = parts.next().unwrap_or("").trim();
            let name = parts.next().unwrap_or("").trim();
            if mac.is_empty() || name.is_empty() {
                continue;
            }

            let mut connected = false;
            let mut paired = true;
            let mut battery = -1;
            let mut icon = "bluetooth".to_string();

            let n_low = name.to_lowercase();
            if ["buds", "airpods", "headset", "earbuds", "wh-", "wf-"]
                .iter()
                .any(|k| n_low.contains(k))
            {
                icon = "headphones".to_string();
            } else if ["soundbar", "speaker", "audio"]
                .iter()
                .any(|k| n_low.contains(k))
            {
                icon = "speaker".to_string();
            } else if ["pixel", "iphone", "phone", "galaxy", "oneplus"]
                .iter()
                .any(|k| n_low.contains(k))
            {
                icon = "smartphone".to_string();
            } else if n_low.contains("mouse") {
                icon = "mouse".to_string();
            } else if n_low.contains("keyboard") {
                icon = "keyboard".to_string();
            }

            if let Ok(info_out) = Command::new("bluetoothctl").args(["info", mac]).output() {
                let info_text = String::from_utf8_lossy(&info_out.stdout);
                connected = info_text.contains("Connected: yes");
                paired = info_text.contains("Paired: yes");

                for line in info_text.lines() {
                    let l = line.trim();
                    if l.starts_with("Icon:") {
                        let raw_icon = l.trim_start_matches("Icon:").trim().to_lowercase();
                        if raw_icon.contains("headset") || raw_icon.contains("audio") {
                            icon = "headphones".to_string();
                        } else if raw_icon.contains("phone") {
                            icon = "smartphone".to_string();
                        }
                    } else if l.starts_with("Battery Percentage:") {
                        // Extract number in parentheses or last token
                        if let Some(start) = l.rfind('(') {
                            if let Some(end) = l.rfind(')') {
                                if let Ok(val) = l[start + 1..end].trim().parse::<i32>() {
                                    battery = val;
                                }
                            }
                        }
                    }
                }
            }

            devices.push(BtDevice {
                mac: mac.to_string(),
                name: name.to_string(),
                connected,
                paired,
                battery,
                icon,
            });
        }
    }

    devices.sort_by(|a, b| {
        b.connected
            .cmp(&a.connected)
            .then_with(|| a.name.to_lowercase().cmp(&b.name.to_lowercase()))
    });

    (bt_powered, devices)
}

fn handle_actions(args: &[String]) -> bool {
    if args.is_empty() {
        return false;
    }

    match args[0].as_str() {
        "--toggle-wifi" => {
            let (w_en, _, _) = get_wifi_details();
            let target = if w_en { "off" } else { "on" };
            let _ = Command::new("nmcli").args(["radio", "wifi", target]).output();
            true
        }
        "--toggle-bt" => {
            if args.len() > 1 {
                let mac = &args[1];
                let is_connected = Command::new("bluetoothctl")
                    .args(["info", mac])
                    .output()
                    .map(|out| String::from_utf8_lossy(&out.stdout).contains("Connected: yes"))
                    .unwrap_or(false);
                let action = if is_connected { "disconnect" } else { "connect" };
                let _ = Command::new("bluetoothctl").args([action, mac]).output();
            } else {
                let (bt_powered, _) = get_bluetooth_details();
                let target = if bt_powered { "off" } else { "on" };
                let _ = Command::new("bluetoothctl").args(["power", target]).output();
            }
            true
        }
        "--connect-wifi" => {
            if args.len() > 1 {
                let ssid = &args[1];
                let mut cmd = Command::new("nmcli");
                cmd.args(["device", "wifi", "connect", ssid]);
                if args.len() > 2 && !args[2].is_empty() {
                    cmd.args(["password", &args[2]]);
                }
                let _ = cmd.output();
            }
            true
        }
        "--disconnect-wifi" => {
            let dev = Command::new("ip")
                .args(["-4", "route", "show", "default"])
                .output()
                .ok()
                .and_then(|out| {
                    let text = String::from_utf8_lossy(&out.stdout);
                    text.find("dev ").map(|pos| {
                        text[pos + 4..]
                            .split_whitespace()
                            .next()
                            .unwrap_or("wlo1")
                            .to_string()
                    })
                })
                .unwrap_or_else(|| "wlo1".to_string());
            let _ = Command::new("nmcli").args(["device", "disconnect", &dev]).output();
            true
        }
        "--rescan-wifi" => {
            let _ = Command::new("nmcli").args(["device", "wifi", "rescan"]).output();
            true
        }
        _ => false,
    }
}

pub fn run(args: &[String]) {
    let _ = handle_actions(args);

    let (wifi_enabled, active_wifi, networks) = get_wifi_details();
    let (bt_powered, bt_devices) = get_bluetooth_details();

    let connected_bt: Vec<BtDevice> = bt_devices.iter().filter(|d| d.connected).cloned().collect();
    let primary = connected_bt.first().cloned();

    let report = NetworkReport {
        status: "ok".to_string(),
        wifi_enabled,
        active_ssid: active_wifi.ssid.clone(),
        active_wifi,
        networks,
        bt_powered,
        bt_devices,
        connected_bt_count: connected_bt.len(),
        primary_connected_bt: primary,
    };

    if let Ok(json) = serde_json::to_string(&report) {
        println!("{}", json);
    }
}
