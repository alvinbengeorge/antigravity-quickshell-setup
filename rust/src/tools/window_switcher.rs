//! Window Switcher & Mission Control Native Backend for Hyprland
//! Fast query of open clients and active window, with instant category and color tagging.

use serde::Serialize;
use serde_json::Value;
use std::process::Command;

#[derive(Serialize)]
pub struct WindowMeta {
    pub address: String,
    pub title: String,
    pub class: String,
    pub workspace_id: i32,
    pub workspace_name: String,
    pub monitor: i64,
    pub floating: bool,
    pub size: [i64; 2],
    pub at: [i64; 2],
    pub pid: i64,
    pub is_active: bool,
    pub icon: String,
    pub glyph: String,
    pub accent_color: String,
    pub category_label: String,
}

fn get_icon_and_color(cls: &str) -> (&'static str, &'static str, &'static str, &'static str) {
    let c = cls.to_lowercase();
    if c.contains("kitty") || c.contains("terminal") || c.contains("alacritty") {
        ("code", "💻", "#38BDF8", "TERMINAL")
    } else if c.contains("firefox") {
        ("globe", "🦊", "#FB923C", "BROWSER")
    } else if c.contains("chrome") || c.contains("chromium") || c.contains("brave") {
        ("globe", "🌐", "#38BDF8", "BROWSER")
    } else if c.contains("teams") {
        ("activity", "💬", "#A78BFA", "TEAMS")
    } else if c.contains("code") || c.contains("vsc") {
        ("code", "⚡", "#60A5FA", "IDE")
    } else if c.contains("software") {
        ("layers", "📦", "#34D399", "STORE")
    } else if c.contains("nautilus") || c.contains("files") {
        ("folder", "📁", "#FBBF24", "FILES")
    } else if c.contains("spotify") || c.contains("music") {
        ("headphones", "🎵", "#34D399", "AUDIO")
    } else {
        ("monitor", "🪟", "#94A3B8", "APP")
    }
}

fn get_windows() -> Vec<WindowMeta> {
    let clients: Vec<Value> = Command::new("hyprctl")
        .args(["clients", "-j"])
        .output()
        .ok()
        .and_then(|out| serde_json::from_slice(&out.stdout).ok())
        .unwrap_or_default();

    let active_addr: String = Command::new("hyprctl")
        .args(["activewindow", "-j"])
        .output()
        .ok()
        .and_then(|out| serde_json::from_slice::<Value>(&out.stdout).ok())
        .and_then(|val| val.get("address").and_then(|a| a.as_str()).map(|s| s.to_string()))
        .unwrap_or_default();

    let mut windows = Vec::new();

    for c in clients {
        let mapped = c.get("mapped").and_then(|v| v.as_bool()).unwrap_or(true);
        let title_str = c.get("title").and_then(|v| v.as_str()).unwrap_or("");
        if !mapped && title_str.is_empty() {
            continue;
        }

        let address = c.get("address").and_then(|v| v.as_str()).unwrap_or("").to_string();
        let class_str = c.get("class")
            .or_else(|| c.get("initialClass"))
            .and_then(|v| v.as_str())
            .unwrap_or("Application");
        let class_name = class_str.to_string();

        let title = if !title_str.is_empty() {
            title_str.to_string()
        } else {
            c.get("initialTitle")
                .and_then(|v| v.as_str())
                .unwrap_or(&class_name)
                .to_string()
        };

        let ws = c.get("workspace");
        let ws_name = ws
            .and_then(|w| w.get("name"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();

        let ws_id = if ws.and_then(|w| w.get("type")).and_then(|v| v.as_str()) == Some("special")
            || ws_name.starts_with("special:")
        {
            -1
        } else {
            ws.and_then(|w| w.get("id")).and_then(|v| v.as_i64()).unwrap_or(1) as i32
        };

        let monitor = c.get("monitor").and_then(|v| v.as_i64()).unwrap_or(0);
        let floating = c.get("floating").and_then(|v| v.as_bool()).unwrap_or(false);

        let size = [
            c.get("size").and_then(|v| v.get(0)).and_then(|v| v.as_i64()).unwrap_or(0),
            c.get("size").and_then(|v| v.get(1)).and_then(|v| v.as_i64()).unwrap_or(0),
        ];

        let at = [
            c.get("at").and_then(|v| v.get(0)).and_then(|v| v.as_i64()).unwrap_or(0),
            c.get("at").and_then(|v| v.get(1)).and_then(|v| v.as_i64()).unwrap_or(0),
        ];

        let pid = c.get("pid").and_then(|v| v.as_i64()).unwrap_or(0);
        let is_active = !address.is_empty() && address == active_addr;

        let (icon, glyph, color, label) = get_icon_and_color(&class_name);

        windows.push(WindowMeta {
            address,
            title,
            class: class_name,
            workspace_id: ws_id,
            workspace_name: ws_name,
            monitor,
            floating,
            size,
            at,
            pid,
            is_active,
            icon: icon.to_string(),
            glyph: glyph.to_string(),
            accent_color: color.to_string(),
            category_label: label.to_string(),
        });
    }

    // Sort active window first, then by workspace_id
    windows.sort_by(|a, b| {
        let active_a = if a.is_active { 0 } else { 1 };
        let active_b = if b.is_active { 0 } else { 1 };
        active_a.cmp(&active_b).then_with(|| a.workspace_id.cmp(&b.workspace_id))
    });

    windows
}

fn focus_window(address: &str) {
    if address.is_empty() {
        println!("{{\"status\":\"error\"}}");
        return;
    }
    let code = format!("return hl.dispatch(hl.dsp.focus({{ window = hl.get_window(\"address:{}\") }}))", address);
    let res = Command::new("hyprctl").args(["eval", &code]).output();
    let is_ok = res.map(|o| String::from_utf8_lossy(&o.stdout).contains("ok")).unwrap_or(false);
    println!("{{\"status\":\"{}\"}}", if is_ok { "ok" } else { "error" });
}

fn close_window(address: &str) {
    if address.is_empty() {
        println!("{{\"status\":\"error\"}}");
        return;
    }
    let code = format!("return hl.dispatch(hl.dsp.window.close({{ window = hl.get_window(\"address:{}\") }}))", address);
    let res = Command::new("hyprctl").args(["eval", &code]).output();
    let is_ok = res.map(|o| String::from_utf8_lossy(&o.stdout).contains("ok")).unwrap_or(false);
    println!("{{\"status\":\"{}\"}}", if is_ok { "ok" } else { "error" });
}

pub fn run(args: &[String]) {
    let action = args.first().map(|s| s.as_str()).unwrap_or("list");
    match action {
        "focus" => {
            let addr = args.get(1).map(|s| s.as_str()).unwrap_or("");
            focus_window(addr);
        }
        "close" => {
            let addr = args.get(1).map(|s| s.as_str()).unwrap_or("");
            close_window(addr);
        }
        "list" | _ => {
            let windows = get_windows();
            if let Ok(json) = serde_json::to_string(&windows) {
                println!("{}", json);
            } else {
                println!("[]");
            }
        }
    }
}
