#!/usr/bin/env bash
# ==============================================================================
# Antigravity Universal Dropdown Scratchpad
# Toggles floating Kitty scratchpad on special:scratchpad
# ==============================================================================

CLIENT=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "kitty-scratchpad") | .address' | head -1)

if [ -z "$CLIENT" ]; then
    nohup kitty --class kitty-scratchpad --title "Antigravity Scratchpad" >/dev/null 2>&1 &
    disown
    for i in {1..15}; do
        sleep 0.05
        CLIENT=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "kitty-scratchpad") | .address' | head -1)
        [ -n "$CLIENT" ] && break
    done
fi

hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")' >/dev/null 2>&1
