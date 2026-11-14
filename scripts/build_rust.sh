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

echo "Building Antigravity Rust Tools in release mode..."
cd "$RUST_DIR"
cargo build --release

mkdir -p "$BIN_DIR"
ln -sf "$RUST_DIR/target/release/fast_system_stats" "$BIN_DIR/fast_system_stats"

echo "Build successful! Binaries linked in $BIN_DIR"
