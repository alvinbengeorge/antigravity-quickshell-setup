//! Antigravity CLI Agent & Brain Status Native Backend
//! Scans ~/.gemini/antigravity-cli/brain/ in <1ms and tracks quota cache.

use serde::Serialize;
use serde_json::Value;
use std::fs::{self, File};
use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

const CACHE_FILE: &str = "/tmp/agy_quota_cache.json";
const LOCK_FILE: &str = "/tmp/agy_quota_cache.lock";

fn get_persistent_cache_path() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    PathBuf::from(home)
        .join(".cache")
        .join("antigravity")
        .join("agy_quota_cache.json")
}

fn get_brain_dir() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    PathBuf::from(home)
        .join(".gemini")
        .join("antigravity-cli")
        .join("brain")
}

fn get_mtime(path: &Path) -> u64 {
    fs::metadata(path)
        .and_then(|m| m.modified())
        .ok()
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn get_now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn format_tokens(n: i64) -> String {
    if n >= 1_000_000 {
        format!("{:.1}M", n as f64 / 1_000_000.0)
    } else if n >= 1_000 {
        format!("{:.1}k", n as f64 / 1_000.0)
    } else {
        format!("{}", n)
    }
}

fn clean_quota_desc(d: &str) -> String {
    if d.is_empty() {
        return String::new();
    }
    if let Some(pos) = d.find(". If on a supported") {
        return format!("{}.", d[..pos].trim());
    }
    if let Some(pos) = d.find("If on a supported") {
        return d[..pos].trim().to_string();
    }
    d.to_string()
}

#[derive(Serialize)]
pub struct AntigravityStatus {
    pub conversation_count: usize,
    pub latest_id: String,
    pub active: bool,
    pub step_count: i64,
    pub status: String,
    pub last_text: String,
    pub context_tokens: i64,
    pub context_limit: i64,
    pub context_percent: f64,
    pub context_tokens_str: String,
    pub total_session_tokens: i64,
    pub total_session_tokens_str: String,

    pub gemini_5h_remaining: i64,
    pub gemini_5h_reset: String,
    pub gemini_5h_desc: String,
    pub gemini_weekly_remaining: i64,
    pub gemini_weekly_reset: String,
    pub gemini_weekly_desc: String,
    pub claude_5h_remaining: i64,
    pub claude_5h_reset: String,
    pub claude_5h_desc: String,
    pub claude_weekly_remaining: i64,
    pub claude_weekly_reset: String,
    pub claude_weekly_desc: String,
}

fn is_system_online() -> bool {
    if let Ok(out) = Command::new("nmcli").args(["networking", "connectivity"]).output() {
        let text = String::from_utf8_lossy(&out.stdout).trim().to_lowercase();
        return text == "full";
    }
    if let Ok(out) = Command::new("ip").args(["-4", "route", "show", "default"]).output() {
        let text = String::from_utf8_lossy(&out.stdout);
        return text.contains("default via");
    }
    false
}

fn do_update_quota() {
    if !is_system_online() {
        return;
    }

    let lock_path = Path::new(LOCK_FILE);
    if lock_path.exists() {
        let mtime = get_mtime(lock_path);
        let now = get_now_secs();
        if now.saturating_sub(mtime) < 15 {
            return; // Already updating
        }
    }

    let _ = fs::write(LOCK_FILE, format!("{}", std::process::id()));

    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    let agy_bin = PathBuf::from(&home).join(".local").join("bin").join("agy");
    let agy_cmd = if agy_bin.exists() {
        agy_bin.to_string_lossy().to_string()
    } else {
        "agy".to_string()
    };

    let path_env = format!(
        "{}:{}:{}",
        PathBuf::from(&home).join(".local").join("bin").to_string_lossy(),
        "/usr/local/bin",
        std::env::var("PATH").unwrap_or_default()
    );

    let res = Command::new(agy_cmd)
        .args(["--print", "/quota", "--output-format", "json"])
        .env("PATH", path_env)
        .output();

    if let Ok(out) = res {
        if out.status.success() {
            if let Ok(data) = serde_json::from_slice::<Value>(&out.stdout) {
                let mut parsed_quotas = serde_json::Map::new();

                if let Some(groups) = data
                    .get("command")
                    .and_then(|c| c.get("data"))
                    .and_then(|d| d.get("groups"))
                    .and_then(|g| g.as_array())
                {
                    for g in groups {
                        let gname = g.get("name").and_then(|n| n.as_str()).unwrap_or("");
                        if let Some(buckets) = g.get("buckets").and_then(|b| b.as_array()) {
                            for b in buckets {
                                let w = b.get("window").and_then(|w| w.as_str()).unwrap_or("");
                                let rem_frac = b
                                    .get("remaining_fraction")
                                    .and_then(|rf| rf.as_f64())
                                    .unwrap_or(0.0);
                                let rem = (rem_frac * 100.0).round() as i64;
                                let key = format!("{}_{}", gname, w);
                                let raw_desc = b
                                    .get("description")
                                    .and_then(|d| d.as_str())
                                    .unwrap_or("");
                                let clean_desc = clean_quota_desc(raw_desc);

                                parsed_quotas.insert(
                                    key,
                                    serde_json::json!({
                                        "group": gname,
                                        "window": w,
                                        "name": b.get("name").and_then(|n| n.as_str()).unwrap_or(""),
                                        "remaining": rem,
                                        "reset_time": b.get("reset_time").and_then(|r| r.as_str()).unwrap_or(""),
                                        "description": clean_desc
                                    }),
                                );
                            }
                        }
                    }
                }

                let payload = serde_json::json!({
                    "updated_at": get_now_secs() as f64,
                    "quotas": parsed_quotas
                });

                if let Ok(s) = serde_json::to_string(&payload) {
                    let _ = fs::write(CACHE_FILE, &s);
                    let pcache = get_persistent_cache_path();
                    if let Some(parent) = pcache.parent() {
                        let _ = fs::create_dir_all(parent);
                    }
                    let _ = fs::write(pcache, &s);
                }
            }
        }
    }

    let _ = fs::remove_file(LOCK_FILE);
}

fn trigger_quota_update_detached() {
    let current_exe = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("agy-tools"));
    let _ = Command::new(current_exe)
        .args(["antigravity_status", "--do-update-quota"])
        .stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn();
}

struct QuotaData {
    gemini_5h_remaining: i64,
    gemini_5h_reset: String,
    gemini_5h_desc: String,
    gemini_weekly_remaining: i64,
    gemini_weekly_reset: String,
    gemini_weekly_desc: String,
    claude_5h_remaining: i64,
    claude_5h_reset: String,
    claude_5h_desc: String,
    claude_weekly_remaining: i64,
    claude_weekly_reset: String,
    claude_weekly_desc: String,
}

fn read_quota_cache(force_refresh: bool) -> QuotaData {
    let now = get_now_secs();
    let mut cache_val: Option<Value> = None;

    for target in &[PathBuf::from(CACHE_FILE), get_persistent_cache_path()] {
        if target.exists() {
            if let Ok(content) = fs::read_to_string(target) {
                if let Ok(v) = serde_json::from_str::<Value>(&content) {
                    if v.get("quotas").is_some() {
                        cache_val = Some(v);
                        break;
                    }
                }
            }
        }
    }

    let need_refresh = match &cache_val {
        None => true,
        Some(v) => {
            let updated_at = v.get("updated_at").and_then(|u| u.as_f64()).unwrap_or(0.0) as u64;
            force_refresh || (now.saturating_sub(updated_at) > 1800)
        }
    };

    if need_refresh && is_system_online() {
        trigger_quota_update_detached();
    }

    let quotas = cache_val.as_ref().and_then(|c| c.get("quotas"));

    let extract_bucket = |key: &str| -> (i64, String, String) {
        if let Some(b) = quotas.and_then(|q| q.get(key)) {
            let rem = b.get("remaining").and_then(|r| r.as_i64()).unwrap_or(100);
            let reset = b
                .get("reset_time")
                .and_then(|r| r.as_str())
                .unwrap_or("")
                .to_string();
            let desc = b
                .get("description")
                .and_then(|d| d.as_str())
                .unwrap_or("")
                .to_string();
            (rem, reset, clean_quota_desc(&desc))
        } else {
            (100, String::new(), String::new())
        }
    };

    let (g5h_rem, g5h_reset, g5h_desc) = extract_bucket("Gemini Models_5h");
    let (gwk_rem, gwk_reset, gwk_desc) = extract_bucket("Gemini Models_weekly");
    let (c5h_rem, c5h_reset, c5h_desc) = extract_bucket("Claude and GPT models_5h");
    let (cwk_rem, cwk_reset, cwk_desc) = extract_bucket("Claude and GPT models_weekly");

    QuotaData {
        gemini_5h_remaining: g5h_rem,
        gemini_5h_reset: g5h_reset,
        gemini_5h_desc: g5h_desc,
        gemini_weekly_remaining: gwk_rem,
        gemini_weekly_reset: gwk_reset,
        gemini_weekly_desc: gwk_desc,
        claude_5h_remaining: c5h_rem,
        claude_5h_reset: c5h_reset,
        claude_5h_desc: c5h_desc,
        claude_weekly_remaining: cwk_rem,
        claude_weekly_reset: cwk_reset,
        claude_weekly_desc: cwk_desc,
    }
}

pub fn run(args: &[String]) {
    if args.iter().any(|a| a == "--do-update-quota") {
        do_update_quota();
        return;
    }

    let force_refresh = args
        .iter()
        .any(|a| a == "--refresh-quota" || a == "refresh-quota");

    let quota = read_quota_cache(force_refresh);
    let brain_dir = get_brain_dir();

    if !brain_dir.exists() {
        let status = AntigravityStatus {
            conversation_count: 0,
            latest_id: "None".to_string(),
            active: false,
            step_count: 0,
            status: "IDLE".to_string(),
            last_text: "No active session".to_string(),
            context_tokens: 0,
            context_limit: 1000000,
            context_percent: 0.0,
            context_tokens_str: "0k".to_string(),
            total_session_tokens: 0,
            total_session_tokens_str: "0".to_string(),
            gemini_5h_remaining: quota.gemini_5h_remaining,
            gemini_5h_reset: quota.gemini_5h_reset,
            gemini_5h_desc: quota.gemini_5h_desc,
            gemini_weekly_remaining: quota.gemini_weekly_remaining,
            gemini_weekly_reset: quota.gemini_weekly_reset,
            gemini_weekly_desc: quota.gemini_weekly_desc,
            claude_5h_remaining: quota.claude_5h_remaining,
            claude_5h_reset: quota.claude_5h_reset,
            claude_5h_desc: quota.claude_5h_desc,
            claude_weekly_remaining: quota.claude_weekly_remaining,
            claude_weekly_reset: quota.claude_weekly_reset,
            claude_weekly_desc: quota.claude_weekly_desc,
        };
        if let Ok(json) = serde_json::to_string(&status) {
            println!("{}", json);
        }
        return;
    }

    let entries = fs::read_dir(&brain_dir)
        .ok()
        .map(|rd| {
            rd.filter_map(|e| e.ok())
                .filter(|e| {
                    let name = e.file_name();
                    let s = name.to_string_lossy();
                    !s.starts_with('.') && e.path().is_dir()
                })
                .collect::<Vec<_>>()
        })
        .unwrap_or_default();

    let conv_count = entries.len();

    // Find latest conversation by transcript.jsonl mtime (or dir mtime)
    let mut latest_path: Option<PathBuf> = None;
    let mut latest_mtime: u64 = 0;

    for e in &entries {
        let p = e.path();
        let tf = p.join(".system_generated").join("logs").join("transcript.jsonl");
        let mtime = if tf.exists() {
            get_mtime(&tf)
        } else {
            get_mtime(&p)
        };

        if mtime >= latest_mtime {
            latest_mtime = mtime;
            latest_path = Some(p);
        }
    }

    let latest_path = match latest_path {
        Some(p) => p,
        None => {
            let status = AntigravityStatus {
                conversation_count: 0,
                latest_id: "None".to_string(),
                active: false,
                step_count: 0,
                status: "IDLE".to_string(),
                last_text: "Antigravity Ready".to_string(),
                context_tokens: 0,
                context_limit: 1000000,
                context_percent: 0.0,
                context_tokens_str: "0k".to_string(),
                total_session_tokens: 0,
                total_session_tokens_str: "0".to_string(),
                gemini_5h_remaining: quota.gemini_5h_remaining,
                gemini_5h_reset: quota.gemini_5h_reset,
                gemini_5h_desc: quota.gemini_5h_desc,
                gemini_weekly_remaining: quota.gemini_weekly_remaining,
                gemini_weekly_reset: quota.gemini_weekly_reset,
                gemini_weekly_desc: quota.gemini_weekly_desc,
                claude_5h_remaining: quota.claude_5h_remaining,
                claude_5h_reset: quota.claude_5h_reset,
                claude_5h_desc: quota.claude_5h_desc,
                claude_weekly_remaining: quota.claude_weekly_remaining,
                claude_weekly_reset: quota.claude_weekly_reset,
                claude_weekly_desc: quota.claude_weekly_desc,
            };
            if let Ok(json) = serde_json::to_string(&status) {
                println!("{}", json);
            }
            return;
        }
    };

    let latest_id = latest_path
        .file_name()
        .map(|s| s.to_string_lossy().to_string())
        .unwrap_or_else(|| "None".to_string());

    let now = get_now_secs();
    let is_active = now.saturating_sub(latest_mtime) < 180; // active within 3 minutes

    let mut step_count: i64 = 0;
    let mut status_str = if is_active { "ACTIVE" } else { "IDLE" }.to_string();
    let mut last_text = String::new();
    let mut last_inp: i64 = 0;
    let mut last_cache: i64 = 0;

    let transcript_file = latest_path
        .join(".system_generated")
        .join("logs")
        .join("transcript.jsonl");

    if transcript_file.exists() {
        if let Ok(mut file) = File::open(&transcript_file) {
            if let Ok(meta) = file.metadata() {
                let file_size = meta.len();
                let seek_pos = if file_size > 65536 {
                    file_size - 65536
                } else {
                    0
                };
                if file.seek(SeekFrom::Start(seek_pos)).is_ok() {
                    let mut buffer = Vec::new();
                    if file.read_to_end(&mut buffer).is_ok() {
                        let text = String::from_utf8_lossy(&buffer);
                        let lines: Vec<&str> = text.lines().collect();

                        let mut last_obj: Option<Value> = None;
                        for line in lines.iter().rev() {
                            let trimmed = line.trim();
                            if trimmed.is_empty() {
                                continue;
                            }
                            if let Ok(obj) = serde_json::from_str::<Value>(trimmed) {
                                if last_obj.is_none() {
                                    step_count = obj
                                        .get("step_index")
                                        .and_then(|v| v.as_i64())
                                        .unwrap_or(0);
                                    last_obj = Some(obj.clone());
                                }
                                if obj.get("type").and_then(|v| v.as_str())
                                    == Some("PLANNER_RESPONSE")
                                    && last_inp == 0
                                {
                                    last_inp = obj
                                        .get("input_tokens")
                                        .and_then(|v| v.as_i64())
                                        .unwrap_or(0);
                                    last_cache = obj
                                        .get("cache_read_tokens")
                                        .and_then(|v| v.as_i64())
                                        .unwrap_or(0);
                                    break;
                                }
                            }
                        }

                        if let Some(obj) = last_obj {
                            let obj_status = obj
                                .get("status")
                                .and_then(|v| v.as_str())
                                .unwrap_or("DONE");
                            if obj_status == "RUNNING" || is_active {
                                status_str = if is_active {
                                    "PROCESSING".to_string()
                                } else {
                                    "IDLE".to_string()
                                };
                            }

                            if let Some(content) = obj.get("content").and_then(|v| v.as_str()) {
                                let clean = content.trim().replace('\n', " ");
                                if !clean.is_empty() {
                                    let truncated = if clean.chars().count() > 80 {
                                        let s: String = clean.chars().take(80).collect();
                                        format!("{}...", s)
                                    } else {
                                        clean
                                    };
                                    last_text = truncated;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    let current_context = last_inp + last_cache;
    let context_limit: i64 = 1000000;
    let context_percent =
        ((current_context as f64 / context_limit as f64) * 1000.0).round() / 10.0;

    let final_status = AntigravityStatus {
        conversation_count: conv_count,
        latest_id,
        active: is_active,
        step_count,
        status: status_str,
        last_text: if last_text.is_empty() {
            "Antigravity Ready".to_string()
        } else {
            last_text
        },
        context_tokens: current_context,
        context_limit,
        context_percent,
        context_tokens_str: format_tokens(current_context),
        total_session_tokens: 0,
        total_session_tokens_str: "0".to_string(),
        gemini_5h_remaining: quota.gemini_5h_remaining,
        gemini_5h_reset: quota.gemini_5h_reset,
        gemini_5h_desc: quota.gemini_5h_desc,
        gemini_weekly_remaining: quota.gemini_weekly_remaining,
        gemini_weekly_reset: quota.gemini_weekly_reset,
        gemini_weekly_desc: quota.gemini_weekly_desc,
        claude_5h_remaining: quota.claude_5h_remaining,
        claude_5h_reset: quota.claude_5h_reset,
        claude_5h_desc: quota.claude_5h_desc,
        claude_weekly_remaining: quota.claude_weekly_remaining,
        claude_weekly_reset: quota.claude_weekly_reset,
        claude_weekly_desc: quota.claude_weekly_desc,
    };

    if let Ok(json) = serde_json::to_string(&final_status) {
        println!("{}", json);
    }
}
