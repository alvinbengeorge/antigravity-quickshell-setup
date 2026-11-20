//! Antigravity Multi-Call Desktop Engine (`agy-tools`)
//! Dispatches to the appropriate native tool based on symlink name (argv[0]) or subcommand (argv[1]).

use antigravity_tools::tools;
use std::env;
use std::path::Path;

fn print_help() {
    println!(r#"Antigravity Desktop Shell Tools (agy-tools) v0.1.0

USAGE:
    agy-tools <SUBCOMMAND> [ARGS...]
    (Or execute directly via symlinks: fast_system_stats, system_monitor, etc.)

AVAILABLE SUBCOMMANDS:
    system-stats, stats        High-performance procfs CPU/RAM/Net telemetry
    system-monitor, monitor    Process telemetry, memory grouping, and termination
    cliphist, clipboard        Wayland clipboard history and disk caching
    media-color, color         Vibrant album art color extractor (Catmull-Rom)
    audio-tracker, audio       SIMD real-to-complex FFT audio visualizer
    docker, docker_manager     Docker container/image manager and JSON telemetry
    battery, battery_helper    Microsecond sysfs battery telemetry & power control
    network, network_status    Native WiFi and Bluetooth BlueZ engine
    wallpapers, wallpaper      Fast wallpaper directory listing & scanner
    windows, window_switcher   Hyprland client list, focus, and close
    tuned, tuned_manager       TuneD active profile and switcher
    tasks, task_runner         Developer persistent task manager and executor
    agy, antigravity_status    Antigravity agent & brain status and quota cache
    whatsapp, openwa           WhatsApp OpenWA connection, chats, and actions
    github, github-prs         GitHub open pull requests and CI status
    jira, jira-tasks           Jira assigned issues, status categories, and counts
    file_search, files         Ultra-fast native multi-threaded file search engine

OPTIONS:
    -h, --help                 Print help information
    -V, --version              Print version information
"#);
}

fn main() {
    let raw_args: Vec<String> = env::args().collect();
    let argv0 = raw_args.first().cloned().unwrap_or_default();
    let bin_name = Path::new(&argv0)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("");

    // Symlink / Direct Invocation dispatch (argv[0])
    match bin_name {
        "fast_system_stats" => {
            tools::fast_system_stats::run(&raw_args[1..]);
            return;
        }
        "system_monitor" => {
            tools::system_monitor::run(&raw_args[1..]);
            return;
        }
        "cliphist_helper" => {
            tools::cliphist_helper::run(&raw_args[1..]);
            return;
        }
        "extract_media_color" => {
            tools::extract_media_color::run(&raw_args[1..]);
            return;
        }
        "audio_beat_tracker" => {
            tools::audio_beat_tracker::run(&raw_args[1..]);
            return;
        }
        "docker_manager" => {
            tools::docker_manager::run(&raw_args[1..]);
            return;
        }
        "battery_helper" => {
            tools::battery_helper::run(&raw_args[1..]);
            return;
        }
        "network_status" => {
            tools::network_status::run(&raw_args[1..]);
            return;
        }
        "wallpaper_helper" => {
            tools::wallpaper_helper::run(&raw_args[1..]);
            return;
        }
        "window_switcher" => {
            tools::window_switcher::run(&raw_args[1..]);
            return;
        }
        "tuned_manager" => {
            tools::tuned_manager::run(&raw_args[1..]);
            return;
        }
        "task_runner" => {
            tools::task_runner::run(&raw_args[1..]);
            return;
        }
        "antigravity_status" | "get_antigravity_status" => {
            tools::antigravity_status::run(&raw_args[1..]);
            return;
        }
        "openwa_status" | "get_openwa_status" => {
            tools::openwa_status::run(&raw_args[1..]);
            return;
        }
        "github_prs" | "get_github_prs" => {
            tools::github_prs::run(&raw_args[1..]);
            return;
        }
        "jira_tasks" | "get_jira_tasks" => {
            tools::jira_tasks::run(&raw_args[1..]);
            return;
        }
        "file_search" | "find_files" => {
            tools::file_search::run(&raw_args[1..]);
            return;
        }
        "calendar_events" | "get_calendar_events" | "calendar" | "agenda" => {
            tools::calendar_events::run(&raw_args[1..]);
            return;
        }
        _ => {}
    }

    // Subcommand dispatch (argv[1])
    let subcmd = raw_args.get(1).map(|s| s.as_str()).unwrap_or("");
    let rest = if raw_args.len() > 2 { &raw_args[2..] } else { &[] };

    match subcmd {
        "system-stats" | "fast_system_stats" | "stats" => {
            tools::fast_system_stats::run(rest);
        }
        "system-monitor" | "system_monitor" | "monitor" => {
            tools::system_monitor::run(rest);
        }
        "cliphist" | "cliphist_helper" | "clipboard" => {
            tools::cliphist_helper::run(rest);
        }
        "media-color" | "extract_media_color" | "color" => {
            tools::extract_media_color::run(rest);
        }
        "audio-tracker" | "audio_beat_tracker" | "audio" => {
            tools::audio_beat_tracker::run(rest);
        }
        "docker" | "docker_manager" => {
            tools::docker_manager::run(rest);
        }
        "battery" | "battery_helper" => {
            tools::battery_helper::run(rest);
        }
        "network" | "network_status" => {
            tools::network_status::run(rest);
        }
        "wallpapers" | "wallpaper_helper" | "wallpaper" => {
            tools::wallpaper_helper::run(rest);
        }
        "windows" | "window_switcher" | "window-switcher" => {
            tools::window_switcher::run(rest);
        }
        "tuned" | "tuned_manager" | "tuned-manager" => {
            tools::tuned_manager::run(rest);
        }
        "tasks" | "task_runner" | "task-runner" => {
            tools::task_runner::run(rest);
        }
        "agy" | "antigravity_status" | "antigravity-status" | "status" => {
            tools::antigravity_status::run(rest);
        }
        "whatsapp" | "openwa" | "openwa_status" | "get_openwa_status" => {
            tools::openwa_status::run(rest);
        }
        "github" | "github-prs" | "github_prs" | "prs" => {
            tools::github_prs::run(rest);
        }
        "jira" | "jira-tasks" | "jira_tasks" => {
            tools::jira_tasks::run(rest);
        }
        "file_search" | "find" | "files" | "file-search" | "file" => {
            tools::file_search::run(rest);
        }
        "calendar_events" | "calendar" | "agenda" | "events" => {
            tools::calendar_events::run(rest);
        }
        "-V" | "--version" => {
            println!("agy-tools 0.1.0");
        }
        "-h" | "--help" | "help" | "" => {
            print_help();
        }
        unknown => {
            eprintln!("Unknown subcommand: '{}'. Run 'agy-tools --help' for available subcommands.", unknown);
            std::process::exit(1);
        }
    }
}
