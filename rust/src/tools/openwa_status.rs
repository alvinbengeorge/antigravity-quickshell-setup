//! OpenWA WhatsApp Status & Chat Provider Native Backend
//! Fast, zero-overhead WhatsApp session manager and chat provider for Quickshell.

use base64::prelude::*;
use serde_json::{json, Value};
use std::fs::{self, File};
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;

const COMPOSE_FILE: &str = "/home/alvin/Downloads/OpenWA/docker-compose.yml";
const QR_IMG_PATH: &str = "/tmp/openwa_qr.png";
const DEFAULT_SESSION_ID: &str = "5e24dc37-3676-48a7-9c50-35559fefbed6";

fn get_api_base() -> String {
    std::env::var("OPENWA_BASE_URL").unwrap_or_else(|_| "http://localhost:2785/api".to_string())
}

fn get_api_key() -> String {
    std::env::var("OPENWA_API_KEY").unwrap_or_else(|_| "abcd".to_string())
}

fn get_cache_path() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    PathBuf::from(home)
        .join(".local")
        .join("state")
        .join("quickshell")
        .join("user")
        .join("openwa-cache.json")
}

fn get_local_time_str() -> String {
    unsafe {
        let t = libc::time(std::ptr::null_mut());
        let mut tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&t, &mut tm);
        let mut buf = [0u8; 32];
        let fmt = std::ffi::CString::new("%I:%M %p").unwrap();
        let len = libc::strftime(
            buf.as_mut_ptr() as *mut libc::c_char,
            buf.len(),
            fmt.as_ptr(),
            &tm,
        );
        if len > 0 {
            let s = String::from_utf8_lossy(&buf[..len]);
            if s.starts_with('0') {
                s[1..].to_string()
            } else {
                s.to_string()
            }
        } else {
            "12:00 PM".to_string()
        }
    }
}

fn format_timestamp(mut ts: f64) -> String {
    if ts <= 0.0 {
        return String::new();
    }
    if ts > 1e11 {
        ts /= 1000.0;
    }
    let sec = ts as i64;
    unsafe {
        let mut tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&sec, &mut tm);

        let now_sec = libc::time(std::ptr::null_mut());
        let mut now_tm: libc::tm = std::mem::zeroed();
        libc::localtime_r(&now_sec, &mut now_tm);

        let mut buf = [0u8; 32];
        if tm.tm_year == now_tm.tm_year && tm.tm_yday == now_tm.tm_yday {
            let fmt = std::ffi::CString::new("%I:%M %p").unwrap();
            let len = libc::strftime(
                buf.as_mut_ptr() as *mut libc::c_char,
                buf.len(),
                fmt.as_ptr(),
                &tm,
            );
            let s = String::from_utf8_lossy(&buf[..len]);
            if s.starts_with('0') {
                s[1..].to_string()
            } else {
                s.to_string()
            }
        } else if tm.tm_year == now_tm.tm_year && now_tm.tm_yday.saturating_sub(tm.tm_yday) == 1 {
            "Yesterday".to_string()
        } else if tm.tm_year == now_tm.tm_year && now_tm.tm_yday.saturating_sub(tm.tm_yday) < 7 {
            let fmt = std::ffi::CString::new("%a").unwrap();
            let len = libc::strftime(
                buf.as_mut_ptr() as *mut libc::c_char,
                buf.len(),
                fmt.as_ptr(),
                &tm,
            );
            String::from_utf8_lossy(&buf[..len]).to_string()
        } else {
            let fmt = std::ffi::CString::new("%b %d").unwrap();
            let len = libc::strftime(
                buf.as_mut_ptr() as *mut libc::c_char,
                buf.len(),
                fmt.as_ptr(),
                &tm,
            );
            String::from_utf8_lossy(&buf[..len]).to_string()
        }
    }
}

fn clean_body(val: &Value) -> String {
    if let Value::Object(map) = val {
        let body = map
            .get("body")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .trim();
        let mtype = map.get("type").and_then(|v| v.as_str()).unwrap_or("");
        if body.is_empty() {
            match mtype {
                "image" => "📷 Photo".to_string(),
                "video" => "🎥 Video".to_string(),
                "audio" | "ptt" => "🎵 Voice message".to_string(),
                "document" => "📄 Document".to_string(),
                "sticker" => "✨ Sticker".to_string(),
                "location" => "📍 Location".to_string(),
                _ => String::new(),
            }
        } else {
            body.replace('\n', " ")
        }
    } else if let Some(s) = val.as_str() {
        s.replace('\n', " ").trim().to_string()
    } else {
        String::new()
    }
}

fn api_request(
    endpoint: &str,
    method: &str,
    data: Option<&Value>,
    timeout_secs: u64,
) -> Result<Value, String> {
    let url = format!("{}{}", get_api_base(), endpoint);
    let agent = ureq::AgentBuilder::new()
        .timeout(Duration::from_secs(timeout_secs))
        .build();

    let req = agent
        .request(method, &url)
        .set("x-api-key", &get_api_key())
        .set("Content-Type", "application/json");

    let resp = if let Some(payload) = data {
        let json_str = serde_json::to_string(payload).map_err(|e| e.to_string())?;
        req.send_string(&json_str)
    } else {
        req.call()
    };

    match resp {
        Ok(r) => {
            let val = r.into_json::<Value>().map_err(|e| e.to_string())?;
            Ok(val)
        }
        Err(e) => Err(e.to_string()),
    }
}

fn reconnect_session(session_id: &str) -> Value {
    match api_request(&format!("/sessions/{}/start", session_id), "POST", None, 6) {
        Ok(res) => json!({ "status": "reconnecting", "result": res }),
        Err(e) => json!({ "status": "error", "error": e }),
    }
}

fn disconnect_session(session_id: &str) -> Value {
    match api_request(&format!("/sessions/{}/stop", session_id), "POST", None, 6) {
        Ok(res) => json!({ "status": "disconnected", "result": res }),
        Err(e) => json!({ "status": "error", "error": e }),
    }
}

fn start_gateway() -> Value {
    let res = Command::new("docker")
        .args(["compose", "-f", COMPOSE_FILE, "up", "-d", "openwa-api"])
        .output();

    match res {
        Ok(out) if out.status.success() => json!({ "status": "gateway_starting" }),
        Ok(out) => json!({ "status": "error", "error": String::from_utf8_lossy(&out.stderr) }),
        Err(e) => json!({ "status": "error", "error": e.to_string() }),
    }
}

fn send_message(session_id: &str, chat_id: &str, text: &str) -> Value {
    let body = json!({ "chatId": chat_id, "text": text });
    match api_request(
        &format!("/sessions/{}/messages", session_id),
        "POST",
        Some(&body),
        8,
    ) {
        Ok(res) => json!({ "status": "sent", "result": res }),
        Err(e) => json!({ "status": "error", "error": e }),
    }
}

pub fn fetch_status() -> Value {
    let last_updated = get_local_time_str();

    let sessions = match api_request("/sessions", "GET", None, 3) {
        Ok(Value::Array(arr)) if !arr.is_empty() => arr,
        Ok(_) => {
            return json!({
                "status": "no_session",
                "error": "No WhatsApp sessions configured",
                "chats": [],
                "unread_total": 0,
                "session": Value::Null,
                "qr_path": Value::Null,
                "last_updated": last_updated
            });
        }
        Err(e) => {
            return json!({
                "status": "offline",
                "error": format!("Gateway offline ({}): {}", get_api_base(), e),
                "chats": [],
                "unread_total": 0,
                "session": Value::Null,
                "qr_path": Value::Null,
                "last_updated": last_updated
            });
        }
    };

    let s = &sessions[0];
    let session_id = s
        .get("id")
        .and_then(|v| v.as_str())
        .unwrap_or(DEFAULT_SESSION_ID);
    let s_status = s
        .get("status")
        .and_then(|v| v.as_str())
        .unwrap_or("disconnected");

    let mut chats_out = Vec::new();
    let mut unread_total = 0;
    let mut qr_path: Option<String> = None;

    if s_status == "ready" {
        if let Ok(Value::Array(raw_chats)) =
            api_request(&format!("/sessions/{}/chats?limit=25", session_id), "GET", None, 4)
        {
            for c in raw_chats.iter().take(20) {
                let unread = c.get("unreadCount").and_then(|u| u.as_i64()).unwrap_or(0);
                unread_total += unread;

                let lm = c.get("lastMessage").unwrap_or(&Value::Null);
                let body = clean_body(lm);
                let ts = c
                    .get("timestamp")
                    .and_then(|t| t.as_f64())
                    .or_else(|| lm.get("timestamp").and_then(|t| t.as_f64()))
                    .unwrap_or(0.0);

                let id = c.get("id").and_then(|v| v.as_str()).unwrap_or("");
                let name = c
                    .get("name")
                    .or_else(|| c.get("pushName"))
                    .and_then(|v| v.as_str())
                    .unwrap_or("Unknown");
                let is_group = c
                    .get("isGroup")
                    .and_then(|v| v.as_bool())
                    .unwrap_or(false);

                let truncated_body = if body.chars().count() > 90 {
                    format!("{}...", body.chars().take(90).collect::<String>())
                } else {
                    body
                };

                chats_out.push(json!({
                    "id": id,
                    "name": name,
                    "isGroup": is_group,
                    "unreadCount": unread,
                    "timestamp": ts,
                    "timeStr": format_timestamp(ts),
                    "lastMessage": truncated_body
                }));
            }
        }
    } else if s_status == "qr_ready" {
        if let Ok(qr_data) =
            api_request(&format!("/sessions/{}/qr", session_id), "GET", None, 3)
        {
            if let Some(b64_raw) = qr_data.get("qrCode").and_then(|v| v.as_str()) {
                let b64 = if let Some(pos) = b64_raw.find("base64,") {
                    &b64_raw[pos + 7..]
                } else {
                    b64_raw
                };
                if let Ok(bytes) = BASE64_STANDARD.decode(b64) {
                    if let Ok(mut f) = File::create(QR_IMG_PATH) {
                        let _ = f.write_all(&bytes);
                        qr_path = Some(QR_IMG_PATH.to_string());
                    }
                }
            }
        }
    }

    let result = json!({
        "status": s_status,
        "session": {
            "id": session_id,
            "name": s.get("name").and_then(|v| v.as_str()).unwrap_or("default"),
            "phone": s.get("phone").and_then(|v| v.as_str()).unwrap_or(""),
            "pushName": s.get("pushName").and_then(|v| v.as_str()).unwrap_or("Alvin"),
            "status": s_status,
            "connectedAt": s.get("connectedAt").unwrap_or(&Value::Null)
        },
        "unread_total": unread_total,
        "chats": chats_out,
        "qr_path": qr_path,
        "last_updated": last_updated
    });

    let cache_p = get_cache_path();
    if let Some(parent) = cache_p.parent() {
        let _ = fs::create_dir_all(parent);
    }
    if let Ok(content) = serde_json::to_string_pretty(&result) {
        let _ = fs::write(cache_p, content);
    }

    result
}

pub fn run(args: &[String]) {
    if args.iter().any(|a| a == "--reconnect") {
        let sid = args
            .get(1)
            .map(|s| s.as_str())
            .unwrap_or(DEFAULT_SESSION_ID);
        println!("{}", reconnect_session(sid));
    } else if args.iter().any(|a| a == "--disconnect") {
        let sid = args
            .get(1)
            .map(|s| s.as_str())
            .unwrap_or(DEFAULT_SESSION_ID);
        println!("{}", disconnect_session(sid));
    } else if args.iter().any(|a| a == "--start-gateway") {
        println!("{}", start_gateway());
    } else if args.iter().any(|a| a == "--send") {
        if args.len() >= 3 {
            let target = &args[1];
            let msg = &args[2];
            println!("{}", send_message(DEFAULT_SESSION_ID, target, msg));
        } else {
            println!("{{\"error\":\"Usage: --send <chat_id> <message>\"}}");
        }
    } else {
        println!("{}", fetch_status());
    }
}
