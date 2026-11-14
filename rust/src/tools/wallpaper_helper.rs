//! Wallpaper Directory Scanner for Quickshell
//! Fast directory reader that lists and sorts wallpaper images.

use std::fs;

pub fn run(_args: &[String]) {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    let dir_path = format!("{}/Pictures/Wallpapers", home);
    let mut files = Vec::new();

    if let Ok(entries) = fs::read_dir(&dir_path) {
        for entry in entries.flatten() {
            if let Ok(file_type) = entry.file_type() {
                if file_type.is_file() {
                    let file_name = entry.file_name().to_string_lossy().to_string();
                    let lower = file_name.to_lowercase();
                    if lower.ends_with(".jpg")
                        || lower.ends_with(".jpeg")
                        || lower.ends_with(".png")
                        || lower.ends_with(".webp")
                    {
                        files.push(file_name);
                    }
                }
            }
        }
    }

    files.sort();
    if let Ok(json) = serde_json::to_string(&files) {
        println!("{}", json);
    } else {
        println!("[]");
    }
}
