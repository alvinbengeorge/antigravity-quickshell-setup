//! GitHub Open Pull Requests Provider Native Backend
//! Fast, cached GraphQL/Search query of authored PRs via GitHub CLI (`gh`).

use serde_json::{json, Value};
use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

const CACHE_FILE: &str = "/tmp/github_prs_cache.json";
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
        let parts: Vec<&str> = tz_str.split(':').collect();
        if let (Some(th), Some(tm)) = (
            parts.first().and_then(|x| x.parse::<i64>().ok()),
            parts.get(1).and_then(|x| x.parse::<i64>().ok()),
        ) {
            epoch -= th * 3600 + tm * 60;
        }
    } else if let Some(pos) = rest.find('-') {
        let tz_str = &rest[pos + 1..];
        let parts: Vec<&str> = tz_str.split(':').collect();
        if let (Some(th), Some(tm)) = (
            parts.first().and_then(|x| x.parse::<i64>().ok()),
            parts.get(1).and_then(|x| x.parse::<i64>().ok()),
        ) {
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

fn fetch_prs_graphql() -> Result<(i64, Vec<Value>), String> {
    let query = r#"
query {
  viewer {
    pullRequests(first: 100, states: OPEN, orderBy: {field: UPDATED_AT, direction: DESC}) {
      totalCount
      nodes {
        number
        title
        url
        updatedAt
        isDraft
        comments {
          totalCount
        }
        repository {
          name
          nameWithOwner
        }
        commits(last: 1) {
          nodes {
            commit {
              statusCheckRollup {
                state
              }
            }
          }
        }
      }
    }
  }
}
"#;

    let res = Command::new("gh")
        .args(["api", "graphql", "-f", &format!("query={}", query)])
        .output()
        .map_err(|e| e.to_string())?;

    if !res.status.success() {
        return Err(String::from_utf8_lossy(&res.stderr).trim().to_string());
    }

    let data: Value =
        serde_json::from_slice(&res.stdout).map_err(|e| format!("JSON parse error: {}", e))?;
    let pr_container = data
        .get("data")
        .and_then(|d| d.get("viewer"))
        .and_then(|v| v.get("pullRequests"))
        .ok_or("Missing pullRequests container")?;

    let total_count = pr_container
        .get("totalCount")
        .and_then(|t| t.as_i64())
        .unwrap_or(0);
    let nodes = pr_container
        .get("nodes")
        .and_then(|n| n.as_array())
        .cloned()
        .unwrap_or_default();

    let mut prs = Vec::new();
    for item in nodes {
        let repo_data = item.get("repository").unwrap_or(&Value::Null);
        let repo_name = repo_data
            .get("name")
            .and_then(|v| v.as_str())
            .unwrap_or("repo");
        let full_repo = repo_data
            .get("nameWithOwner")
            .and_then(|v| v.as_str())
            .unwrap_or(repo_name);

        let mut ci_status = "none";
        if let Some(commits_nodes) = item
            .get("commits")
            .and_then(|c| c.get("nodes"))
            .and_then(|n| n.as_array())
        {
            if let Some(first_commit_node) = commits_nodes.first() {
                if let Some(rollup) = first_commit_node
                    .get("commit")
                    .and_then(|c| c.get("statusCheckRollup"))
                {
                    if let Some(raw_state) = rollup.get("state").and_then(|s| s.as_str()) {
                        match raw_state {
                            "SUCCESS" => ci_status = "success",
                            "PENDING" | "EXPECTED" => ci_status = "pending",
                            "FAILURE" | "ERROR" => ci_status = "failure",
                            _ => {}
                        }
                    }
                }
            }
        }

        let comments_count = item
            .get("comments")
            .and_then(|c| c.get("totalCount"))
            .and_then(|t| t.as_i64())
            .unwrap_or(0);
        let updated_at = item
            .get("updatedAt")
            .and_then(|u| u.as_str())
            .unwrap_or("");

        prs.push(json!({
            "number": item.get("number").and_then(|n| n.as_i64()).unwrap_or(0),
            "title": item.get("title").and_then(|t| t.as_str()).unwrap_or(""),
            "repo": repo_name,
            "full_repo": full_repo,
            "url": item.get("url").and_then(|u| u.as_str()).unwrap_or(""),
            "is_draft": item.get("isDraft").and_then(|d| d.as_bool()).unwrap_or(false),
            "comments": comments_count,
            "ci_status": ci_status,
            "updated_at": updated_at,
            "updated_ago": format_relative_time(updated_at)
        }));
    }

    Ok((total_count, prs))
}

fn fetch_prs_search_fallback() -> Result<(i64, Vec<Value>), String> {
    let res = Command::new("gh")
        .args([
            "search",
            "prs",
            "--state=open",
            "--author=@me",
            "--limit=100",
            "--json",
            "number,title,repository,url,updatedAt,isDraft,commentsCount,labels",
        ])
        .output()
        .map_err(|e| e.to_string())?;

    if !res.status.success() {
        return Err(String::from_utf8_lossy(&res.stderr).trim().to_string());
    }

    let raw_items: Vec<Value> =
        serde_json::from_slice(&res.stdout).map_err(|e| format!("JSON parse error: {}", e))?;

    let mut prs = Vec::new();
    for item in &raw_items {
        let repo_data = item.get("repository").unwrap_or(&Value::Null);
        let repo_name = repo_data
            .get("name")
            .and_then(|v| v.as_str())
            .unwrap_or("repo");
        let full_repo = repo_data
            .get("nameWithOwner")
            .and_then(|v| v.as_str())
            .unwrap_or(repo_name);
        let updated_at = item
            .get("updatedAt")
            .and_then(|u| u.as_str())
            .unwrap_or("");

        prs.push(json!({
            "number": item.get("number").and_then(|n| n.as_i64()).unwrap_or(0),
            "title": item.get("title").and_then(|t| t.as_str()).unwrap_or(""),
            "repo": repo_name,
            "full_repo": full_repo,
            "url": item.get("url").and_then(|u| u.as_str()).unwrap_or(""),
            "is_draft": item.get("isDraft").and_then(|d| d.as_bool()).unwrap_or(false),
            "comments": item.get("commentsCount").and_then(|c| c.as_i64()).unwrap_or(0),
            "ci_status": "none",
            "updated_at": updated_at,
            "updated_ago": format_relative_time(updated_at)
        }));
    }

    Ok((prs.len() as i64, prs))
}

fn fetch_prs() -> Value {
    let (total_count, prs) = fetch_prs_graphql()
        .or_else(|_| fetch_prs_search_fallback())
        .unwrap_or((0, Vec::new()));

    let now_epoch = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs_f64())
        .unwrap_or(0.0);

    json!({
        "status": "ok",
        "count": total_count,
        "prs": prs,
        "updated_at_epoch": now_epoch,
        "last_updated": get_local_time_str()
    })
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

    let data = fetch_prs();
    if data.get("status").and_then(|s| s.as_str()) == Some("ok") {
        if let Ok(content) = serde_json::to_string(&data) {
            let _ = fs::write(CACHE_FILE, content);
        }
        println!("{}", data);
    } else if let Some(mut c) = cached {
        if let Value::Object(ref mut map) = c {
            map.insert("stale".to_string(), Value::Bool(true));
        }
        println!("{}", c);
    } else {
        println!("{}", json!({
            "status": "error",
            "count": 0,
            "prs": [],
            "error": "Failed to fetch pull requests",
            "last_updated": "Error"
        }));
    }
}
