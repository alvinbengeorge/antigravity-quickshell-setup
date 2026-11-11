#!/usr/bin/env bash

# Kill any existing quickshell instances forcefully
killall -9 qs quickshell 2>/dev/null || true

# Pause to ensure socket/display cleanup
sleep 0.3

# Start exactly one Quickshell instance with antigravity
exec qs -c antigravity -d
