#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RUST_DIR="$ROOT_DIR/rust"
BIN_DIR="$ROOT_DIR/bin"

if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Auto-install Rust toolchain if cargo is missing
if ! command -v cargo &>/dev/null; then
    echo "Rust/cargo not found. Installing Rust toolchain via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal
    source "$HOME/.cargo/env"
fi

echo "Building Antigravity Multi-Call Engine (agy-tools) in release mode..."
cd "$RUST_DIR"
cargo build --release --bin agy-tools

# Ensure all binary dispatch wrappers are executable
chmod +x "$BIN_DIR"/*

echo "Build successful! Native Rust engine ready at $RUST_DIR/target/release/agy-tools"
echo "All desktop shell services will now run at maximum native performance."
