use regex::Regex;
use serde::Serialize;
use std::fs::{self, File};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::OnceLock;

const CACHE_DIR: &str = "/tmp/cliphist_cache";

#[derive(Serialize, Debug, Clone)]
struct ClipItem {
    id: String,
    text: String,
    #[serde(rename = "type")]
    item_type: String,
    thumb: String,
    meta: String,
}

static BINARY_RE: OnceLock<Regex> = OnceLock::new();

fn get_binary_re() -> &'static Regex {
    BINARY_RE.get_or_init(|| Regex::new(r"\[\[ binary data ([\d\.]+ \w+) (\w+) (\d+x\d+) \]\]").unwrap())
}

fn cache_path_for(cid: &str) -> PathBuf {
    Path::new(CACHE_DIR).join(format!("{}.png", cid))
}

fn decode_image_file(cid: &str) -> Option<String> {
    let _ = fs::create_dir_all(CACHE_DIR);
    let cache_file = cache_path_for(cid);
    if !cache_file.exists() {
        if let Ok(file) = File::create(&cache_file) {
            let status = Command::new("cliphist")
                .args(["decode", cid])
                .stdout(Stdio::from(file))
                .status();
            if let Ok(s) = status {
                if !s.success() {
                    let _ = fs::remove_file(&cache_file);
                    return None;
                }
            } else {
                let _ = fs::remove_file(&cache_file);
                return None;
            }
        }
    }
    if cache_file.exists() {
        Some(cache_file.to_string_lossy().to_string())
    } else {
        None
    }
}

fn get_list(limit: usize) -> Vec<ClipItem> {
    let _ = fs::create_dir_all(CACHE_DIR);

    let output = match Command::new("cliphist").arg("list").output() {
        Ok(out) if out.status.success() => String::from_utf8_lossy(&out.stdout).to_string(),
        _ => return Vec::new(),
    };

    let re = get_binary_re();
    let mut items = Vec::new();

    let code_keywords = [
        "def ", "function", "class ", "import ", "{", "}", "const ", "var ",
        "export ", "public ", "private ", "<!DOCTYPE", "<html",
    ];

    for line in output.lines().take(limit) {
        let (cid, text) = match line.split_once('\t') {
            Some((c, t)) => (c.trim(), t),
            None => continue,
        };

        let is_bin = text.starts_with("[[ binary data");

        if is_bin {
            let meta = if let Some(caps) = re.captures(text) {
                format!(
                    "{} • {} {}",
                    &caps[3],
                    &caps[1],
                    caps[2].to_uppercase()
                )
            } else {
                "Image".to_string()
            };

            let thumb = decode_image_file(cid).unwrap_or_default();

            items.push(ClipItem {
                id: cid.to_string(),
                text: text.to_string(),
                item_type: "image".to_string(),
                thumb,
                meta,
            });
        } else if text.starts_with("http://") || text.starts_with("https://") {
            items.push(ClipItem {
                id: cid.to_string(),
                text: text.to_string(),
                item_type: "url".to_string(),
                thumb: String::new(),
                meta: "URL Link".to_string(),
            });
        } else if code_keywords.iter().any(|&k| text.contains(k)) {
            items.push(ClipItem {
                id: cid.to_string(),
                text: text.to_string(),
                item_type: "code".to_string(),
                thumb: String::new(),
                meta: "Code Snippet".to_string(),
            });
        } else {
            let chars_count = text.chars().count();
            items.push(ClipItem {
                id: cid.to_string(),
                text: text.to_string(),
                item_type: "text".to_string(),
                thumb: String::new(),
                meta: format!("{} chars", chars_count),
            });
        }
    }

    items
}

fn decode_image_cmd(cid: &str) {
    if let Some(path) = decode_image_file(cid) {
        println!("{}", path);
    } else {
        println!();
    }
}

fn decode_text_cmd(cid: &str) {
    let output = Command::new("cliphist").args(["decode", cid]).output();
    if let Ok(out) = output {
        let _ = io::stdout().write_all(&out.stdout);
    }
}

fn copy_item_cmd(cid: &str) {
    // Pipe into wl-copy
    if let Ok(mut dec1) = Command::new("cliphist")
        .args(["decode", cid])
        .stdout(Stdio::piped())
        .spawn()
    {
        if let Some(stdout1) = dec1.stdout.take() {
            let _ = Command::new("wl-copy").stdin(stdout1).status();
        }
    }

    // Pipe into wl-copy --primary
    if let Ok(mut dec2) = Command::new("cliphist")
        .args(["decode", cid])
        .stdout(Stdio::piped())
        .spawn()
    {
        if let Some(stdout2) = dec2.stdout.take() {
            let _ = Command::new("wl-copy").arg("--primary").stdin(stdout2).status();
        }
    }
}

fn delete_item_cmd(cid: &str, raw_text: &str) {
    let child = Command::new("cliphist")
        .arg("delete")
        .stdin(Stdio::piped())
        .spawn();

    if let Ok(mut c) = child {
        if let Some(mut stdin) = c.stdin.take() {
            let payload = format!("{}\t{}\n", cid, raw_text);
            let _ = stdin.write_all(payload.as_bytes());
        }
        let _ = c.wait();
    }

    let cache_file = cache_path_for(cid);
    if cache_file.exists() {
        let _ = fs::remove_file(cache_file);
    }
}

fn wipe_all_cmd() {
    let _ = Command::new("cliphist").arg("wipe").status();
    if let Ok(entries) = fs::read_dir(CACHE_DIR) {
        for entry in entries.flatten() {
            let _ = fs::remove_file(entry.path());
        }
    }
}

pub fn run(args: &[String]) {
    if args.is_empty() {
        let items = get_list(80);
        if let Ok(json) = serde_json::to_string(&items) {
            println!("{}", json);
        }
        return;
    }

    match args[0].as_str() {
        "list" => {
            let limit = args.get(1).and_then(|s| s.parse::<usize>().ok()).unwrap_or(80);
            let items = get_list(limit);
            if let Ok(json) = serde_json::to_string(&items) {
                println!("{}", json);
            }
        }
        "decode-image" => {
            if let Some(cid) = args.get(1) {
                decode_image_cmd(cid);
            }
        }
        "decode-text" => {
            if let Some(cid) = args.get(1) {
                decode_text_cmd(cid);
            }
        }
        "copy" => {
            if let Some(cid) = args.get(1) {
                copy_item_cmd(cid);
            }
        }
        "delete" => {
            if let Some(cid) = args.get(1) {
                let raw_text = args.get(2).map(|s| s.as_str()).unwrap_or("");
                delete_item_cmd(cid, raw_text);
            }
        }
        "wipe" => {
            wipe_all_cmd();
        }
        _ => {
            eprintln!("Unknown command");
        }
    }
}
