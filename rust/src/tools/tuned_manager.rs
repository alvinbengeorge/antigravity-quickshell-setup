//! TuneD Performance Profile Manager Native Backend for Quickshell
//! Directly interfaces with TuneD D-Bus service (com.redhat.tuned) via busctl.

use serde::Serialize;
use std::process::Command;

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ProfileMeta {
    pub id: String,
    pub name: String,
    pub icon: String,
    pub color: String,
    pub summary: String,
    pub description: String,
    pub is_primary: bool,
    pub order: u32,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TunedStatus {
    pub available: bool,
    pub active_profile: String,
    pub active_meta: ProfileMeta,
    pub profiles: Vec<ProfileMeta>,
}

fn get_active_profile() -> String {
    if let Ok(out) = Command::new("busctl")
        .args(["call", "com.redhat.tuned", "/Tuned", "com.redhat.tuned.control", "active_profile"])
        .output()
    {
        let text = String::from_utf8_lossy(&out.stdout);
        if let Some(start) = text.find('"') {
            if let Some(end) = text[start + 1..].find('"') {
                return text[start + 1..start + 1 + end].to_string();
            }
        }
    }

    // Fallback to tuned-adm active
    if let Ok(out) = Command::new("tuned-adm").arg("active").output() {
        let text = String::from_utf8_lossy(&out.stdout);
        for line in text.lines() {
            if let Some(pos) = line.find(':') {
                return line[pos + 1..].trim().to_string();
            }
        }
    }

    "unknown".to_string()
}

fn get_known_meta(id: &str, desc: &str) -> ProfileMeta {
    match id {
        "powersave" => ProfileMeta {
            id: id.to_string(),
            name: "Power Saver".to_string(),
            icon: "leaf".to_string(),
            color: "#10B981".to_string(),
            summary: "Low power consumption & cool temps".to_string(),
            description: desc.to_string(),
            is_primary: true,
            order: 1,
        },
        "balanced" => ProfileMeta {
            id: id.to_string(),
            name: "Balanced".to_string(),
            icon: "gauge".to_string(),
            color: "#06B6D4".to_string(),
            summary: "Dynamic responsive desktop balance".to_string(),
            description: desc.to_string(),
            is_primary: true,
            order: 2,
        },
        "balanced-battery" => ProfileMeta {
            id: id.to_string(),
            name: "Balanced (Battery)".to_string(),
            icon: "gauge".to_string(),
            color: "#06B6D4".to_string(),
            summary: "Balanced with power-saving bias".to_string(),
            description: desc.to_string(),
            is_primary: false,
            order: 3,
        },
        "desktop" => ProfileMeta {
            id: id.to_string(),
            name: "Desktop".to_string(),
            icon: "monitor".to_string(),
            color: "#3B82F6".to_string(),
            summary: "Workstation responsiveness tuning".to_string(),
            description: desc.to_string(),
            is_primary: false,
            order: 4,
        },
        "throughput-performance" => ProfileMeta {
            id: id.to_string(),
            name: "Performance".to_string(),
            icon: "zap".to_string(),
            color: "#F59E0B".to_string(),
            summary: "Maximum multi-core CPU throughput".to_string(),
            description: desc.to_string(),
            is_primary: true,
            order: 5,
        },
        "latency-performance" => ProfileMeta {
            id: id.to_string(),
            name: "Low Latency".to_string(),
            icon: "flame".to_string(),
            color: "#EF4444".to_string(),
            summary: "Deterministic minimal latency & audio/gaming".to_string(),
            description: desc.to_string(),
            is_primary: true,
            order: 6,
        },
        "accelerator-performance" => ProfileMeta {
            id: id.to_string(),
            name: "Accelerator".to_string(),
            icon: "sparkles".to_string(),
            color: "#8B5CF6".to_string(),
            summary: "High throughput without deep STOP states".to_string(),
            description: desc.to_string(),
            is_primary: false,
            order: 7,
        },
        _ => {
            let pretty_name = id
                .split('-')
                .map(|part| {
                    let mut c = part.chars();
                    match c.next() {
                        None => String::new(),
                        Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
                    }
                })
                .collect::<Vec<_>>()
                .join(" ");

            ProfileMeta {
                id: id.to_string(),
                name: pretty_name,
                icon: "sliders".to_string(),
                color: "#94A3B8".to_string(),
                summary: if desc.is_empty() { id.to_string() } else { desc.to_string() },
                description: desc.to_string(),
                is_primary: false,
                order: 100,
            }
        }
    }
}

fn get_profiles() -> Vec<ProfileMeta> {
    let mut profiles = Vec::new();

    if let Ok(out) = Command::new("busctl")
        .args(["call", "com.redhat.tuned", "/Tuned", "com.redhat.tuned.control", "profiles2"])
        .output()
    {
        let text = String::from_utf8_lossy(&out.stdout);
        // Extracts strings inside quotes
        let mut matches = Vec::new();
        let mut in_quote = false;
        let mut current = String::new();
        for c in text.chars() {
            if c == '"' {
                if in_quote {
                    matches.push(current.clone());
                    current.clear();
                    in_quote = false;
                } else {
                    in_quote = true;
                }
            } else if in_quote {
                current.push(c);
            }
        }

        let mut i = 0;
        while i < matches.len() {
            let pid = &matches[i];
            let desc = if i + 1 < matches.len() { &matches[i + 1] } else { "" };
            profiles.push(get_known_meta(pid, desc));
            i += 2;
        }
    }

    if profiles.is_empty() {
        // Fallback default list
        for pid in &[
            "powersave",
            "balanced",
            "throughput-performance",
            "latency-performance",
        ] {
            profiles.push(get_known_meta(pid, ""));
        }
    }

    profiles.sort_by(|a, b| a.order.cmp(&b.order).then_with(|| a.id.cmp(&b.id)));
    profiles
}

fn switch_profile(target: &str) {
    if target.is_empty() {
        println!("{{\"success\":false,\"error\":\"Empty profile name\"}}");
        return;
    }

    let res = Command::new("busctl")
        .args([
            "call",
            "com.redhat.tuned",
            "/Tuned",
            "com.redhat.tuned.control",
            "switch_profile",
            "s",
            target,
        ])
        .output();

    match res {
        Ok(out) => {
            let text = String::from_utf8_lossy(&out.stdout);
            let success = out.status.success() && text.contains("true");
            println!(
                "{{\"success\":{},\"profile\":\"{}\",\"output\":\"{}\"}}",
                success,
                target,
                text.trim().replace('"', "\\\"")
            );
        }
        Err(e) => {
            println!("{{\"success\":false,\"error\":\"{}\"}}", e);
        }
    }
}

pub fn run(args: &[String]) {
    if args.first().map(|s| s.as_str()) == Some("switch") {
        let target = args.get(1).map(|s| s.as_str()).unwrap_or("");
        switch_profile(target);
        return;
    }

    let active = get_active_profile();
    let available = active != "unknown";
    let profiles = get_profiles();
    let active_obj = profiles
        .iter()
        .find(|p| p.id == active)
        .cloned()
        .unwrap_or_else(|| get_known_meta(&active, "Active TuneD Profile"));

    let status = TunedStatus {
        available,
        active_profile: active,
        active_meta: active_obj,
        profiles,
    };

    if let Ok(json) = serde_json::to_string(&status) {
        println!("{}", json);
    }
}
