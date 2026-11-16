#!/usr/bin/env bash
# ==============================================================================
# Antigravity Universal Dropdown Scratchpad
# Toggles floating Kitty scratchpad on special:scratchpad (minimal 960x540)
# ==============================================================================

CLIENT=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "kitty-scratchpad") | .address' | head -1)

if [ -z "$CLIENT" ]; then
    nohup kitty --class kitty-scratchpad --title "Antigravity Scratchpad" -o initial_window_width=960 -o initial_window_height=540 -o remember_window_size=no >/dev/null 2>&1 &
    disown
    for i in {1..30}; do
        sleep 0.05
        CLIENT=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "kitty-scratchpad") | .address' | head -1)
        [ -n "$CLIENT" ] && break
    done
fi

hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")' >/dev/null 2>&1
