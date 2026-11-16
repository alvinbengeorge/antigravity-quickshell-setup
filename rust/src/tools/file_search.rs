use serde::Serialize;
use std::collections::HashSet;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{Instant, SystemTime, UNIX_EPOCH};

#[derive(Serialize, Clone)]
pub struct FileResult {
    pub name: String,
    pub path: String,
    pub parent: String,
    pub is_dir: bool,
    pub kind: String,
    pub icon: String,
    pub size_bytes: u64,
    pub size_str: String,
    pub mtime: u64,
    pub mtime_str: String,
    #[serde(skip_serializing)]
    pub score: i32,
}

#[derive(Serialize)]
pub struct SearchResponse {
    pub query: String,
    pub count: usize,
    pub latency_ms: u128,
    pub results: Vec<FileResult>,
}

fn format_size(bytes: u64, is_dir: bool) -> String {
    if is_dir {
        return "Folder".to_string();
    }
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;

    if bytes >= GB {
        format!("{:.1} GB", bytes as f64 / GB as f64)
    } else if bytes >= MB {
        format!("{:.1} MB", bytes as f64 / MB as f64)
    } else if bytes >= KB {
        format!("{:.1} KB", bytes as f64 / KB as f64)
    } else {
        format!("{} B", bytes)
    }
}

fn format_relative_time(mtime_epoch: u64) -> String {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);

    if now < mtime_epoch || mtime_epoch == 0 {
        return "Just now".to_string();
    }

    let diff = now - mtime_epoch;
    if diff < 60 {
        "Just now".to_string()
    } else if diff < 3600 {
        let mins = diff / 60;
        format!("{}m ago", mins)
    } else if diff < 86400 {
        let hours = diff / 3600;
        format!("{}h ago", hours)
    } else if diff < 172800 {
        "Yesterday".to_string()
    } else if diff < 604800 {
        let days = diff / 86400;
        format!("{}d ago", days)
    } else {
        let days = diff / 86400;
        if days < 30 {
            format!("{}d ago", days)
        } else {
            let months = days / 30;
            format!("{}mo ago", months)
        }
    }
}

fn classify_file(path: &Path, is_dir: bool) -> (String, String) {
    if is_dir {
        return ("Folder".to_string(), "📁".to_string());
    }

    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .map(|s| s.to_lowercase())
        .unwrap_or_default();

    match ext.as_str() {
        "py" | "pyw" | "ipynb" => ("Python Source".to_string(), "🐍".to_string()),
        "rs" => ("Rust Source".to_string(), "🦀".to_string()),
        "js" | "mjs" | "cjs" => ("JavaScript Source".to_string(), "⚡".to_string()),
        "ts" | "tsx" => ("TypeScript Source".to_string(), "📘".to_string()),
        "qml" => ("QML Component".to_string(), "❖".to_string()),
        "sh" | "bash" | "zsh" | "fish" => ("Shell Script".to_string(), "🐚".to_string()),
        "json" | "toml" | "yaml" | "yml" | "xml" | "ini" | "conf" => {
            ("Config File".to_string(), "⚙️".to_string())
        }
        "md" | "markdown" => ("Markdown Document".to_string(), "📝".to_string()),
        "txt" | "log" | "csv" | "tsv" => ("Text Document".to_string(), "📄".to_string()),
        "pdf" => ("PDF Document".to_string(), "📑".to_string()),
        "png" | "jpg" | "jpeg" | "webp" | "svg" | "gif" | "ico" | "bmp" => {
            ("Image".to_string(), "🖼️".to_string())
        }
        "mp4" | "mkv" | "webm" | "mov" | "avi" => ("Video".to_string(), "🎥".to_string()),
        "mp3" | "wav" | "flac" | "ogg" | "m4a" | "aac" | "opus" => {
            ("Audio Track".to_string(), "🎵".to_string())
        }
        "zip" | "tar" | "gz" | "tgz" | "7z" | "bz2" | "xz" => {
            ("Archive".to_string(), "📦".to_string())
        }
        "html" | "htm" => ("HTML Document".to_string(), "🌐".to_string()),
        "css" | "scss" | "sass" | "less" => ("Stylesheet".to_string(), "🎨".to_string()),
        _ => ("File".to_string(), "📄".to_string()),
    }
}

fn format_parent_path(path: &Path, home_dir: &str) -> String {
    let parent = path.parent().unwrap_or(path);
    let parent_str = parent.to_string_lossy();
    if parent_str.starts_with(home_dir) {
        format!("~{}", &parent_str[home_dir.len()..])
    } else {
        parent_str.to_string()
    }
}

fn score_result(path_str: &str, file_name: &str, query: &str) -> i32 {
    let mut score = 0;
    let query_lower = query.to_lowercase();
    let name_lower = file_name.to_lowercase();
    let path_lower = path_str.to_lowercase();

    if name_lower == query_lower {
        score += 150;
    } else if name_lower.starts_with(&query_lower) {
        score += 90;
    } else if name_lower.contains(&query_lower) {
        score += 60;
    } else if path_lower.contains(&query_lower) {
        score += 30;
    }

    // Boost files in active user directories
    if path_str.contains("/Desktop/personal/") {
        score += 45;
    } else if path_str.contains("/Desktop/") {
        score += 35;
    } else if path_str.contains("/Downloads/") {
        score += 25;
    } else if path_str.contains("/Documents/") {
        score += 20;
    } else if path_str.contains("/Pictures/") {
        score += 15;
    }

    // Slight penalty for hidden dot-directories
    if path_str.contains("/.") {
        score -= 20;
    }

    score
}

fn is_ignored_path(path: &str) -> bool {
    let normalized = if path.ends_with('/') {
        path.to_string()
    } else {
        format!("{}/", path)
    };
    let ignored = [
        "/.cache/",
        "/.git/",
        "/node_modules/",
        "/__pycache__/",
        "/.venv/",
        "/target/",
        "/.rustup/",
        "/.cargo/",
        "/.local/share/Trash/",
        "/.pytest_cache/",
        "/catboost_info/",
        "/browser_user_data/",
        "/proc/",
        "/sys/",
        "/dev/",
        "/var/tmp/",
        "/tmp/",
    ];
    ignored.iter().any(|ig| normalized.contains(ig))
}

fn inspect_file(path_buf: PathBuf, home_dir: &str, query: &str) -> Option<FileResult> {
    let path_str = path_buf.to_string_lossy().to_string();
    if is_ignored_path(&path_str) {
        return None;
    }

    let meta = fs::metadata(&path_buf).ok()?;
    let is_dir = meta.is_dir();
    let name = path_buf
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_string();

    if name.is_empty() {
        return None;
    }

    let size_bytes = if is_dir { 0 } else { meta.len() };
    let size_str = format_size(size_bytes, is_dir);

    let mtime = meta
        .modified()
        .ok()
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_secs())
        .unwrap_or(0);

    let mtime_str = format_relative_time(mtime);
    let (kind, icon) = classify_file(&path_buf, is_dir);
    let parent = format_parent_path(&path_buf, home_dir);
    let score = score_result(&path_str, &name, query);

    Some(FileResult {
        name,
        path: path_str,
        parent,
        is_dir,
        kind,
        icon,
        size_bytes,
        size_str,
        mtime,
        mtime_str,
        score,
    })
}

pub fn search(raw_query: &str, limit: usize) -> SearchResponse {
    let start_time = Instant::now();
    let home_dir = env::var("HOME").unwrap_or_else(|_| "/home/alvin".to_string());

    // Clean query: strip triggers '@file ', '@file:', '@file', 'file:'
    let mut query = raw_query.trim();
    if query.to_lowercase().starts_with("@file ") {
        query = query[6..].trim();
    } else if query.to_lowercase().starts_with("@file:") {
        query = query[6..].trim();
    } else if query.to_lowercase() == "@file" {
        query = "";
    } else if query.to_lowercase().starts_with("file:") {
        query = query[5..].trim();
    }

    let mut seen_paths = HashSet::new();
    let mut raw_paths = Vec::new();

    // 1. If query is empty or just "@file", list recent user files from Desktop & Downloads
    if query.is_empty() {
        let default_roots = [
            format!("{}/Desktop/personal", home_dir),
            format!("{}/Desktop", home_dir),
            format!("{}/Downloads", home_dir),
        ];

        for root in &default_roots {
            if let Ok(entries) = fs::read_dir(root) {
                for entry in entries.flatten() {
                    let p = entry.path();
                    let s = p.to_string_lossy().to_string();
                    if !is_ignored_path(&s) && seen_paths.insert(s.clone()) {
                        raw_paths.push(p);
                    }
                }
            }
        }
    } else {
        // 2. Primary fast scan with `fd` on user workspaces
        let search_dirs = [
            format!("{}/Desktop", home_dir),
            format!("{}/Downloads", home_dir),
            format!("{}/Documents", home_dir),
            format!("{}/Pictures", home_dir),
        ];

        let mut fd_cmd = Command::new("fd");
        fd_cmd
            .arg("-i")
            .arg("-t")
            .arg("f")
            .arg("-t")
            .arg("d")
            .arg("-E")
            .arg(".git")
            .arg("-E")
            .arg("node_modules")
            .arg("-E")
            .arg(".venv")
            .arg("-E")
            .arg("__pycache__")
            .arg("-E")
            .arg("target")
            .arg("--max-results")
            .arg(format!("{}", limit))
            .arg(query);

        for dir in &search_dirs {
            if Path::new(dir).exists() {
                fd_cmd.arg(dir);
            }
        }

        if let Ok(output) = fd_cmd.output() {
            if output.status.success() {
                let stdout = String::from_utf8_lossy(&output.stdout);
                for line in stdout.lines() {
                    let trimmed = line.trim();
                    if !trimmed.is_empty() && seen_paths.insert(trimmed.to_string()) {
                        raw_paths.push(PathBuf::from(trimmed));
                    }
                }
            }
        }

        // 3. Complementary global scan with `plocate` (fast indexed database)
        if raw_paths.len() < limit {
            let plocate_res = Command::new("plocate")
                .arg("-i")
                .arg("-l")
                .arg("50")
                .arg(query)
                .output();

            if let Ok(output) = plocate_res {
                if output.status.success() {
                    let stdout = String::from_utf8_lossy(&output.stdout);
                    for line in stdout.lines() {
                        let trimmed = line.trim();
                        if trimmed.starts_with(&home_dir)
                            && !is_ignored_path(trimmed)
                            && seen_paths.insert(trimmed.to_string())
                        {
                            raw_paths.push(PathBuf::from(trimmed));
                            if raw_paths.len() >= limit * 2 {
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    // Inspect files and gather metadata
    let mut results: Vec<FileResult> = raw_paths
        .into_iter()
        .filter_map(|p| inspect_file(p, &home_dir, query))
        .collect();

    // Sort by score descending, then by mtime descending
    results.sort_by(|a, b| {
        b.score
            .cmp(&a.score)
            .then_with(|| b.mtime.cmp(&a.mtime))
    });

    results.truncate(limit);

    let latency_ms = start_time.elapsed().as_millis();
    SearchResponse {
        query: query.to_string(),
        count: results.len(),
        latency_ms,
        results,
    }
}

pub fn run(args: &[String]) {
    let mut query = String::new();
    let mut limit = 30;

    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "-l" | "--limit" => {
                if i + 1 < args.len() {
                    limit = args[i + 1].parse().unwrap_or(30);
                    i += 1;
                }
            }
            arg if !arg.starts_with('-') && query.is_empty() => {
                query = arg.to_string();
            }
            arg if !arg.starts_with('-') => {
                query.push(' ');
                query.push_str(arg);
            }
            _ => {}
        }
        i += 1;
    }

    let response = search(&query, limit);
    if let Ok(json) = serde_json::to_string(&response) {
        println!("{}", json);
    } else {
        println!(r#"{{"query":"","count":0,"latency_ms":0,"results":[]}}"#);
    }
}
