#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RUST_DIR="$ROOT_DIR/rust"
BIN_DIR="$ROOT_DIR/bin"

if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

if ! command -v cargo &>/dev/null; then
    echo "Error: cargo is not installed or not in PATH."
    exit 1
fi

echo "Building Antigravity Unified Multi-Call Engine (agy-tools) in release mode..."
cd "$RUST_DIR"
cargo build --release --bin agy-tools

mkdir -p "$BIN_DIR"
# Link primary multi-call binary
ln -sf "$RUST_DIR/target/release/agy-tools" "$BIN_DIR/agy-tools"

# Create symlinks for all tool subcommands (argv[0] dispatch)
cd "$BIN_DIR"
ln -sf "agy-tools" "fast_system_stats"
ln -sf "agy-tools" "system_monitor"
ln -sf "agy-tools" "cliphist_helper"
ln -sf "agy-tools" "extract_media_color"
ln -sf "agy-tools" "audio_beat_tracker"
ln -sf "agy-tools" "docker_manager"

echo "Build successful! Multi-call binary and tool symlinks linked in $BIN_DIR"
