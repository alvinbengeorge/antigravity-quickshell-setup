//! Jira Assigned Tasks Provider Native Backend
//! Queries Jira Cloud REST API v3 via Basic Auth with fast pagination & disk caching.

use base64::prelude::*;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const CACHE_FILE: &str = "/tmp/jira_tasks_cache.json";
const AVATAR_CACHE: &str = "/tmp/jira_avatar.png";
const CACHE_TTL_SECS: u64 = 90;

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

fn parse_iso_to_epoch(s: &str) -> Option<u64> {
    if s.len() < 19 {
        return None;
    }
    let year: i64 = s[0..4].parse().ok()?;
    let month: i64 = s[5..7].parse().ok()?;
    let day: i64 = s[8..10].parse().ok()?;
    let hour: i64 = s[11..13].parse().ok()?;
    let min: i64 = s[14..16].parse().ok()?;
    let sec: i64 = s[17..19].parse().ok()?;

    let mut total_days = 0;
    for y in 1970..year {
        total_days += if (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0) {
            366
        } else {
            365
        };
    }
    let is_leap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    let days_in_months = [
        31,
        if is_leap { 29 } else { 28 },
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
    ];
    for m in 1..month {
        total_days += days_in_months[(m - 1) as usize];
    }
    total_days += day - 1;

    let mut epoch = total_days * 86400 + hour * 3600 + min * 60 + sec;

    let rest = &s[19..];
    if let Some(pos) = rest.find('+') {
        let tz_str = &rest[pos + 1..];
        let tz_digits: String = tz_str.chars().filter(|c| c.is_ascii_digit()).collect();
        if tz_digits.len() >= 4 {
            let th: i64 = tz_digits[0..2].parse().unwrap_or(0);
            let tm: i64 = tz_digits[2..4].parse().unwrap_or(0);
            epoch -= th * 3600 + tm * 60;
        }
    } else if let Some(pos) = rest.find('-') {
        let tz_str = &rest[pos + 1..];
        let tz_digits: String = tz_str.chars().filter(|c| c.is_ascii_digit()).collect();
        if tz_digits.len() >= 4 {
            let th: i64 = tz_digits[0..2].parse().unwrap_or(0);
            let tm: i64 = tz_digits[2..4].parse().unwrap_or(0);
            epoch += th * 3600 + tm * 60;
        }
    }

    if epoch >= 0 {
        Some(epoch as u64)
    } else {
        None
    }
}

fn format_relative_time(iso_str: &str) -> String {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);

    if let Some(epoch) = parse_iso_to_epoch(iso_str) {
        let diff = now.saturating_sub(epoch);
        if diff < 60 {
            "just now".to_string()
        } else if diff < 3600 {
            format!("{}m ago", diff / 60)
        } else if diff < 86400 {
            format!("{}h ago", diff / 3600)
        } else if diff < 86400 * 2 {
            "yesterday".to_string()
        } else if diff < 86400 * 30 {
            format!("{}d ago", diff / 86400)
        } else if diff < 86400 * 365 {
            format!("{}mo ago", diff / (86400 * 30))
        } else {
            format!("{}y ago", diff / (86400 * 365))
        }
    } else {
        iso_str.chars().take(10).collect()
    }
}

fn find_credentials() -> (String, String, String) {
    if let (Ok(u), Ok(un), Ok(t)) = (
        std::env::var("JIRA_URL"),
        std::env::var("JIRA_USERNAME"),
        std::env::var("ATLASSIAN_TOKEN"),
    ) {
        if !u.is_empty() && !un.is_empty() && !t.is_empty() {
            return (u.trim_end_matches('/').to_string(), un, t);
        }
    }

    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    let env_paths = [
        PathBuf::from(&home).join("Desktop/projects/jira-mcp/.env"),
        PathBuf::from(&home).join(".config/jira/.env"),
        PathBuf::from(&home).join(".jira.env"),
        PathBuf::from("/home/alvin/Desktop/projects/jira-mcp/.env"),
    ];

    for path in &env_paths {
        if path.exists() {
            if let Ok(content) = fs::read_to_string(path) {
                let mut map = HashMap::new();
                for line in content.lines() {
                    let trimmed = line.trim();
                    if !trimmed.is_empty() && !trimmed.starts_with('#') && trimmed.contains('=') {
                        if let Some((k, v)) = trimmed.split_once('=') {
                            let clean_val = v.trim().trim_matches('"').trim_matches('\'');
                            map.insert(k.trim().to_string(), clean_val.to_string());
                        }
                    }
                }
                if let (Some(u), Some(un), Some(t)) = (
                    map.get("JIRA_URL"),
                    map.get("JIRA_USERNAME"),
                    map.get("ATLASSIAN_TOKEN"),
                ) {
                    if !u.is_empty() && !un.is_empty() && !t.is_empty() {
                        return (u.trim_end_matches('/').to_string(), un.clone(), t.clone());
                    }
                }
            }
        }
    }

    (
        "https://askmeidentity.atlassian.net".to_string(),
        "alvin.george@askmeidentity.com".to_string(),
        String::new(),
    )
}

fn query_jql(
    jira_url: &str,
    auth_header: &str,
    jql: &str,
    max_results: usize,
    max_pages: usize,
) -> Vec<Value> {
    let mut issues = Vec::new();
    let mut next_page_token: Option<String> = None;
    let agent = ureq::AgentBuilder::new()
        .timeout(Duration::from_secs(15))
        .build();

    for _ in 0..max_pages {
        let mut body = json!({
            "jql": jql,
            "maxResults": max_results,
            "fields": ["summary", "status", "priority", "issuetype", "updated", "created", "project"]
        });

        if let Some(ref token) = next_page_token {
            if let Value::Object(ref mut map) = body {
                map.insert("nextPageToken".to_string(), Value::String(token.clone()));
            }
        }

        let resp = agent
            .post(&format!("{}/rest/api/3/search/jql", jira_url))
            .set("Authorization", auth_header)
            .set("Accept", "application/json")
            .set("Content-Type", "application/json")
            .send_json(body);

        match resp {
            Ok(r) => {
                if let Ok(res) = r.into_json::<Value>() {
                    if let Some(batch) = res.get("issues").and_then(|i| i.as_array()) {
                        issues.extend(batch.clone());
                        next_page_token = res
                            .get("nextPageToken")
                            .and_then(|t| t.as_str())
                            .map(|s| s.to_string());
                        if next_page_token.is_none() || batch.is_empty() {
                            break;
                        }
                    } else {
                        break;
                    }
                } else {
                    break;
                }
            }
            Err(_) => break,
        }
    }

    issues
}

fn fetch_jira_data(jira_url: &str, username: &str, token: &str) -> Result<Value, String> {
    let auth_str = format!("{}:{}", username, token);
    let auth_header = format!("Basic {}", BASE64_STANDARD.encode(auth_str.as_bytes()));

    let agent = ureq::AgentBuilder::new()
        .timeout(Duration::from_secs(12))
        .build();

    // 1. Fetch user profile
    let raw_user: Value = agent
        .get(&format!("{}/rest/api/3/myself", jira_url))
        .set("Authorization", &auth_header)
        .set("Accept", "application/json")
        .call()
        .map_err(|e| format!("Failed to fetch user profile: {}", e))?
        .into_json()
        .map_err(|e| e.to_string())?;

    let avatar_remote = raw_user
        .get("avatarUrls")
        .and_then(|a| a.get("48x48"))
        .and_then(|u| u.as_str())
        .unwrap_or("")
        .to_string();

    let mut avatar_local = String::new();
    if !avatar_remote.is_empty() {
        if let Ok(resp) = agent.get(&avatar_remote).call() {
            let mut bytes = Vec::new();
            if resp.into_reader().read_to_end(&mut bytes).is_ok() {
                if let Ok(mut f) = File::create(AVATAR_CACHE) {
                    let _ = f.write_all(&bytes);
                    avatar_local = AVATAR_CACHE.to_string();
                }
            }
        }
    }

    let default_display_name = username.split('@').next().unwrap_or(username);
    let display_name = raw_user
        .get("displayName")
        .and_then(|d| d.as_str())
        .unwrap_or(default_display_name);

    let user_obj = json!({
        "displayName": display_name,
        "emailAddress": raw_user.get("emailAddress").and_then(|e| e.as_str()).unwrap_or(username),
        "avatarLocal": avatar_local,
        "avatarUrl": avatar_remote,
        "jiraUrl": jira_url,
        "jiraHost": jira_url.replace("https://", "").replace("http://", ""),
        "timeZone": raw_user.get("timeZone").and_then(|t| t.as_str()).unwrap_or("")
    });

    // 2. Fetch tasks assigned to currentUser()
    let mut raw_issues = query_jql(
        jira_url,
        &auth_header,
        "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
        100,
        3,
    );

    let done_issues = query_jql(
        jira_url,
        &auth_header,
        "assignee = currentUser() AND statusCategory = Done ORDER BY updated DESC",
        50,
        1,
    );

    raw_issues.extend(done_issues);

    if raw_issues.is_empty() {
        raw_issues = query_jql(
            jira_url,
            &auth_header,
            "assignee = currentUser() ORDER BY updated DESC",
            150,
            2,
        );
    }

    let mut tasks = Vec::new();
    let mut to_do_count = 0;
    let mut in_progress_count = 0;
    let mut done_count = 0;

    for item in raw_issues {
        let fields = item.get("fields").unwrap_or(&Value::Null);
        let status_obj = fields.get("status").unwrap_or(&Value::Null);
        let status_cat = status_obj
            .get("statusCategory")
            .and_then(|sc| sc.get("name"))
            .and_then(|n| n.as_str())
            .unwrap_or("To Do");
        let status_name = status_obj
            .get("name")
            .and_then(|n| n.as_str())
            .unwrap_or("Unknown");

        let cat_key = match status_cat {
            "In Progress" => {
                in_progress_count += 1;
                "in_progress"
            }
            "Done" => {
                done_count += 1;
                "done"
            }
            _ => {
                to_do_count += 1;
                "to_do"
            }
        };

        let priority_name = fields
            .get("priority")
            .and_then(|p| p.get("name"))
            .and_then(|n| n.as_str())
            .unwrap_or("Medium");
        let p_low = priority_name.to_lowercase();
        let priority_level = if p_low.contains("high") {
            "high"
        } else if p_low.contains("low") {
            "low"
        } else {
            "medium"
        };

        let issuetype_name = fields
            .get("issuetype")
            .and_then(|it| it.get("name"))
            .and_then(|n| n.as_str())
            .unwrap_or("Task");
        let proj_obj = fields.get("project").unwrap_or(&Value::Null);
        let proj_name = proj_obj
            .get("name")
            .and_then(|n| n.as_str())
            .unwrap_or("");
        let proj_key = proj_obj
            .get("key")
            .and_then(|k| k.as_str())
            .unwrap_or("");
        let key = item.get("key").and_then(|k| k.as_str()).unwrap_or("");
        let updated = fields.get("updated").and_then(|u| u.as_str()).unwrap_or("");

        tasks.push(json!({
            "key": key,
            "summary": fields.get("summary").and_then(|s| s.as_str()).unwrap_or(""),
            "status": status_name,
            "category": cat_key,
            "category_name": status_cat,
            "priority": priority_name,
            "priority_level": priority_level,
            "issuetype": issuetype_name,
            "project": proj_name,
            "project_key": proj_key,
            "updated": updated,
            "updated_ago": format_relative_time(updated),
            "url": format!("{}/browse/{}", jira_url, key)
        }));
    }

    let now_epoch = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs_f64())
        .unwrap_or(0.0);

    Ok(json!({
        "status": "ok",
        "user": user_obj,
        "counts": {
            "total": tasks.len(),
            "in_progress": in_progress_count,
            "to_do": to_do_count,
            "done": done_count
        },
        "tasks": tasks,
        "last_updated": get_local_time_str(),
        "updated_at_epoch": now_epoch
    }))
}

fn is_system_online() -> bool {
    if let Ok(out) = std::process::Command::new("nmcli").args(["networking", "connectivity"]).output() {
        let text = String::from_utf8_lossy(&out.stdout).trim().to_lowercase();
        return text == "full";
    }
    if let Ok(out) = std::process::Command::new("ip").args(["-4", "route", "show", "default"]).output() {
        let text = String::from_utf8_lossy(&out.stdout);
        return text.contains("default via");
    }
    false
}

pub fn run(args: &[String]) {
    let force = args.iter().any(|a| a == "--force");
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);

    let cache_path = Path::new(CACHE_FILE);
    let mut cached: Option<Value> = None;

    if cache_path.exists() {
        if let Ok(content) = fs::read_to_string(cache_path) {
            if let Ok(v) = serde_json::from_str::<Value>(&content) {
                cached = Some(v);
            }
        }
    }

    if !force {
        if let Some(ref c) = cached {
            if c.get("status").and_then(|s| s.as_str()) == Some("ok") {
                let cached_epoch = c
                    .get("updated_at_epoch")
                    .and_then(|e| e.as_f64())
                    .unwrap_or(0.0) as u64;
                if now.saturating_sub(cached_epoch) < CACHE_TTL_SECS {
                    println!("{}", c);
                    return;
                }
            }
        }
    }

    let (jira_url, username, token) = find_credentials();
    if token.is_empty() {
        if let Some(ref c) = cached {
            println!("{}", c);
            return;
        }
        println!("{}", json!({
            "status": "error",
            "error": "No ATLASSIAN_TOKEN configured",
            "user": {"displayName": "Anonymous", "emailAddress": "", "avatarLocal": "", "jiraUrl": jira_url},
            "counts": {"total": 0, "in_progress": 0, "to_do": 0, "done": 0},
            "tasks": []
        }));
        return;
    }

    if !is_system_online() {
        if let Some(mut c) = cached {
            if let Value::Object(ref mut map) = c {
                map.insert("offline".to_string(), Value::Bool(true));
            }
            println!("{}", c);
            return;
        }
        let default_display_name = username.split('@').next().unwrap_or(&username);
        println!("{}", json!({
            "status": "offline",
            "error": "Offline (no internet connection)",
            "user": {"displayName": default_display_name, "emailAddress": username, "avatarLocal": "", "jiraUrl": jira_url},
            "counts": {"total": 0, "in_progress": 0, "to_do": 0, "done": 0},
            "tasks": [],
            "last_updated": "Offline"
        }));
        return;
    }

    match fetch_jira_data(&jira_url, &username, &token) {
        Ok(data) => {
            if let Ok(content) = serde_json::to_string(&data) {
                let _ = fs::write(CACHE_FILE, content);
            }
            println!("{}", data);
        }
        Err(e) => {
            if let Some(ref c) = cached {
                println!("{}", c);
            } else {
                let default_display_name = username.split('@').next().unwrap_or(&username);
                println!("{}", json!({
                    "status": "error",
                    "error": e,
                    "user": {"displayName": default_display_name, "emailAddress": username, "avatarLocal": "", "jiraUrl": jira_url},
                    "counts": {"total": 0, "in_progress": 0, "to_do": 0, "done": 0},
                    "tasks": []
                }));
            }
        }
    }
}
