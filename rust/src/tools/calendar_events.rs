//! Native Calendar Events Provider Backend (`bin/calendar_events`)
//! Fetches and parses iCalendar (.ics) feeds with multi-calendar support,
//! Google Meet / Zoom link extraction, offline cache, and zero CPU overhead.

use chrono::{DateTime, Local, NaiveDate, NaiveDateTime, NaiveTime, TimeZone, Utc};
use regex::Regex;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::{Duration, SystemTime};

const CACHE_FILE: &str = "/tmp/quickshell_calendar_cache.json";
const CACHE_TTL_SECS: u64 = 300; // 5 minutes cache

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct CalendarConfig {
    pub name: String,
    pub url: String,
    pub color: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EventItem {
    pub id: String,
    pub title: String,
    pub description: String,
    pub location: String,
    pub calendar_name: String,
    pub calendar_color: String,
    pub is_all_day: bool,
    pub is_now: bool,
    pub is_today: bool,
    pub starts_in_mins: i64,
    pub time_str: String,
    pub date_str: String,
    pub start_epoch: i64,
    pub end_epoch: i64,
    pub meet_url: Option<String>,
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

fn get_config_calendars() -> Vec<CalendarConfig> {
    let home = env::var("HOME").unwrap_or_else(|_| "/home/alvin".to_string());
    let config_path = format!("{}/.config/quickshell/calendars.json", home);

    if let Ok(data) = fs::read_to_string(&config_path) {
        if let Ok(cals) = serde_json::from_str::<Vec<CalendarConfig>>(&data) {
            if !cals.is_empty() {
                return cals;
            }
        }
    }

    // No hardcoded fallback URL - user must configure ~/.config/quickshell/calendars.json
    Vec::new()
}

fn unfold_ics_lines(raw: &str) -> Vec<String> {
    let mut lines = Vec::new();
    let mut current_line = String::new();

    for line in raw.lines() {
        if line.starts_with(' ') || line.starts_with('\t') {
            current_line.push_str(&line[1..]);
        } else {
            if !current_line.is_empty() {
                lines.push(current_line);
            }
            current_line = line.to_string();
        }
    }
    if !current_line.is_empty() {
        lines.push(current_line);
    }
    lines
}

fn extract_meeting_link(text: &str) -> Option<String> {
    // Google Meet
    let meet_re = Regex::new(r"https://meet\.google\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}").ok()?;
    if let Some(m) = meet_re.find(text) {
        return Some(m.as_str().to_string());
    }

    // Zoom
    let zoom_re = Regex::new(r"https://[a-zA-Z0-9.-]*zoom\.us/j/[0-9]+(\?[^\s]*)?").ok()?;
    if let Some(m) = zoom_re.find(text) {
        return Some(m.as_str().to_string());
    }

    // Microsoft Teams
    let teams_re = Regex::new(r"https://teams\.microsoft\.com/l/meetup-join/[^\s]+").ok()?;
    if let Some(m) = teams_re.find(text) {
        return Some(m.as_str().to_string());
    }

    None
}

fn parse_ics_date(s: &str, now_local: &DateTime<Local>) -> Option<(DateTime<Local>, bool)> {
    let clean = s.trim();

    // VALUE=DATE:YYYYMMDD (All day)
    if clean.len() == 8 && clean.chars().all(|c| c.is_ascii_digit()) {
        let year: i32 = clean[0..4].parse().ok()?;
        let month: u32 = clean[4..6].parse().ok()?;
        let day: u32 = clean[6..8].parse().ok()?;
        let d = NaiveDate::from_ymd_opt(year, month, day)?;
        let naive = NaiveDateTime::new(d, NaiveTime::from_hms_opt(0, 0, 0)?);
        let dt = Local.from_local_datetime(&naive).single()?;
        return Some((dt, true));
    }

    // YYYYMMDDTHHMMSSZ (UTC)
    if clean.ends_with('Z') && clean.len() >= 15 {
        let year: i32 = clean[0..4].parse().ok()?;
        let month: u32 = clean[4..6].parse().ok()?;
        let day: u32 = clean[6..8].parse().ok()?;
        let hour: u32 = clean[9..11].parse().ok()?;
        let min: u32 = clean[11..13].parse().ok()?;
        let sec: u32 = clean[13..15].parse().ok()?;

        let d = NaiveDate::from_ymd_opt(year, month, day)?;
        let t = NaiveTime::from_hms_opt(hour, min, sec)?;
        let utc_dt = DateTime::<Utc>::from_naive_utc_and_offset(NaiveDateTime::new(d, t), Utc);
        let local_dt = utc_dt.with_timezone(&Local);
        return Some((local_dt, false));
    }

    // Local naive YYYYMMDDTHHMMSS
    if clean.len() >= 15 && clean.contains('T') {
        let year: i32 = clean[0..4].parse().ok()?;
        let month: u32 = clean[4..6].parse().ok()?;
        let day: u32 = clean[6..8].parse().ok()?;
        let hour: u32 = clean[9..11].parse().ok()?;
        let min: u32 = clean[11..13].parse().ok()?;
        let sec: u32 = clean[13..15].parse().ok()?;

        let d = NaiveDate::from_ymd_opt(year, month, day)?;
        let t = NaiveTime::from_hms_opt(hour, min, sec)?;
        let naive = NaiveDateTime::new(d, t);
        let dt = Local.from_local_datetime(&naive).single().unwrap_or(*now_local);
        return Some((dt, false));
    }

    None
}

fn unescape_ics_text(s: &str) -> String {
    s.replace(r"\,", ",")
        .replace(r"\;", ";")
        .replace(r"\n", " ")
        .replace(r"\N", " ")
        .replace(r"\\", r"\")
        .trim()
        .to_string()
}

fn parse_calendar_feed(raw_ics: &str, cal: &CalendarConfig, now: &DateTime<Local>) -> Vec<EventItem> {
    let lines = unfold_ics_lines(raw_ics);
    let mut events = Vec::new();
    let mut in_event = false;

    let mut uid = String::new();
    let mut summary = String::new();
    let mut description = String::new();
    let mut location = String::new();
    let mut dtstart_str = String::new();
    let mut dtend_str = String::new();
    let mut rrule = String::new();

    let today_date = now.date_naive();

    for line in lines {
        if line == "BEGIN:VEVENT" {
            in_event = true;
            uid.clear();
            summary.clear();
            description.clear();
            location.clear();
            dtstart_str.clear();
            dtend_str.clear();
            rrule.clear();
            continue;
        }

        if line == "END:VEVENT" {
            in_event = false;

            if summary.is_empty() {
                summary = "Untitled Event".to_string();
            }

            // Extract pure date strings without parameters
            let clean_start = if let Some(idx) = dtstart_str.find(':') {
                &dtstart_str[idx + 1..]
            } else {
                &dtstart_str
            };

            let clean_end = if let Some(idx) = dtend_str.find(':') {
                &dtend_str[idx + 1..]
            } else {
                &dtend_str
            };

            if let Some((start_dt, is_all_day)) = parse_ics_date(clean_start, now) {
                let end_dt = if !clean_end.is_empty() {
                    parse_ics_date(clean_end, now)
                        .map(|(d, _)| d)
                        .unwrap_or_else(|| start_dt + chrono::Duration::hours(1))
                } else if is_all_day {
                    start_dt + chrono::Duration::days(1)
                } else {
                    start_dt + chrono::Duration::hours(1)
                };

                let event_start_date = start_dt.date_naive();
                let event_end_date = end_dt.date_naive();

                // Event occurs today if its start date is today, or multi-day spanning today
                let matches_today = (event_start_date == today_date)
                    || (event_start_date < today_date && event_end_date >= today_date);

                // Upcoming range (tomorrow to today + 7 days)
                let max_upcoming = today_date + chrono::Duration::days(7);
                let is_upcoming = event_start_date > today_date && event_start_date <= max_upcoming;

                if matches_today || is_upcoming {
                    let full_search_text = format!("{} {} {}", summary, description, location);
                    let meet_url = extract_meeting_link(&full_search_text);

                    let is_now = if is_all_day {
                        matches_today
                    } else {
                        *now >= start_dt && *now < end_dt
                    };

                    let diff_mins = (start_dt.timestamp() - now.timestamp()) / 60;

                    let time_str = if is_all_day {
                        "All day".to_string()
                    } else {
                        format!(
                            "{} - {}",
                            start_dt.format("%I:%M %p").to_string().trim_start_matches('0'),
                            end_dt.format("%I:%M %p").to_string().trim_start_matches('0')
                        )
                    };

                    let date_str = if event_start_date == today_date {
                        "Today".to_string()
                    } else if event_start_date == today_date + chrono::Duration::days(1) {
                        "Tomorrow".to_string()
                    } else {
                        start_dt.format("%A, %b %d").to_string()
                    };

                    events.push(EventItem {
                        id: if uid.is_empty() { format!("evt_{}", start_dt.timestamp()) } else { uid.clone() },
                        title: unescape_ics_text(&summary),
                        description: unescape_ics_text(&description),
                        location: unescape_ics_text(&location),
                        calendar_name: cal.name.clone(),
                        calendar_color: cal.color.clone().unwrap_or_else(|| "#f6c177".to_string()),
                        is_all_day,
                        is_now,
                        is_today: matches_today,
                        starts_in_mins: diff_mins,
                        time_str,
                        date_str,
                        start_epoch: start_dt.timestamp(),
                        end_epoch: end_dt.timestamp(),
                        meet_url,
                    });
                }
            }

            continue;
        }

        if in_event {
            if line.starts_with("UID:") {
                uid = line[4..].to_string();
            } else if line.starts_with("SUMMARY:") || line.starts_with("SUMMARY;") {
                if let Some(idx) = line.find(':') {
                    summary = line[idx + 1..].to_string();
                }
            } else if line.starts_with("DESCRIPTION:") || line.starts_with("DESCRIPTION;") {
                if let Some(idx) = line.find(':') {
                    description = line[idx + 1..].to_string();
                }
            } else if line.starts_with("LOCATION:") || line.starts_with("LOCATION;") {
                if let Some(idx) = line.find(':') {
                    location = line[idx + 1..].to_string();
                }
            } else if line.starts_with("DTSTART") {
                dtstart_str = line.clone();
            } else if line.starts_with("DTEND") {
                dtend_str = line.clone();
            } else if line.starts_with("RRULE:") {
                rrule = line[6..].to_string();
            }
        }
    }

    events
}

fn read_cached_data() -> Option<Value> {
    let p = Path::new(CACHE_FILE);
    if !p.exists() {
        return None;
    }
    let data = fs::read_to_string(p).ok()?;
    serde_json::from_str(&data).ok()
}

fn cache_is_fresh() -> bool {
    let p = Path::new(CACHE_FILE);
    if let Ok(meta) = p.metadata() {
        if let Ok(mtime) = meta.modified() {
            if let Ok(dur) = SystemTime::now().duration_since(mtime) {
                return dur.as_secs() < CACHE_TTL_SECS;
            }
        }
    }
    false
}

pub fn run(args: &[String]) {
    let force = args.iter().any(|a| a == "--force" || a == "-f");
    let now = Local::now();
    let online = is_system_online();

    // If offline or fresh cache (and not forcing), return cache
    if !online || (!force && cache_is_fresh()) {
        if let Some(mut cached) = read_cached_data() {
            if !online {
                if let Some(obj) = cached.as_object_mut() {
                    obj.insert("offline".to_string(), json!(true));
                }
            }
            println!("{}", cached);
            return;
        }
    }

    if !online {
        println!("{}", json!({
            "status": "offline",
            "offline": true,
            "count": 0,
            "next_event": null,
            "today_events": [],
            "upcoming_events": [],
            "last_updated": "Offline"
        }));
        return;
    }

    let calendars = get_config_calendars();
    let mut all_events: Vec<EventItem> = Vec::new();
    let mut cal_names = Vec::new();

    for cal in &calendars {
        cal_names.push(cal.name.clone());
        match ureq::get(&cal.url)
            .timeout(Duration::from_secs(8))
            .call()
        {
            Ok(resp) => {
                if let Ok(text) = resp.into_string() {
                    let mut events = parse_calendar_feed(&text, cal, &now);
                    all_events.append(&mut events);
                }
            }
            Err(e) => {
                eprintln!("Warning: Failed to fetch calendar '{}': {}", cal.name, e);
            }
        }
    }

    // Sort all events by start timestamp
    all_events.sort_by_key(|e| e.start_epoch);

    // Split into today and upcoming
    let today_events: Vec<EventItem> = all_events.iter().filter(|e| e.is_today).cloned().collect();
    let upcoming_events: Vec<EventItem> = all_events
        .iter()
        .filter(|e| !e.is_today && e.start_epoch >= now.timestamp())
        .take(10)
        .cloned()
        .collect();

    // Determine next event (prefer timed upcoming/now event over all-day)
    let next_event = today_events
        .iter()
        .find(|e| !e.is_all_day && (e.is_now || e.starts_in_mins >= 0))
        .or_else(|| today_events.iter().find(|e| e.is_now || e.starts_in_mins >= 0))
        .or_else(|| upcoming_events.first());

    let last_updated = now.format("%I:%M %p").to_string().trim_start_matches('0').to_string();

    let output = json!({
        "status": "ok",
        "offline": false,
        "calendars": cal_names,
        "count": today_events.len(),
        "next_event": next_event,
        "today_events": today_events,
        "upcoming_events": upcoming_events,
        "last_updated": last_updated
    });

    // Write to cache
    if let Ok(content) = serde_json::to_string(&output) {
        let _ = fs::write(CACHE_FILE, content);
    }

    println!("{}", output);
}
