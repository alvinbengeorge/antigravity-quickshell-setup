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
    sleep 0.1
fi

# Ensure window is on special:scratchpad, floating, sized minimally (960x540) and centered
hyprctl eval "
local w = hl.get_window('class:kitty-scratchpad')
if w then
    if not w.floating then
        hl.dispatch(hl.dsp.window.float({ window = w }))
    end
    hl.dispatch(hl.dsp.window.move({ window = w, workspace = 'special:scratchpad' }))
    hl.dispatch(hl.dsp.window.fullscreen_state({ window = w, internal = 0, client = 0 }))
    hl.dispatch(hl.dsp.focus({ window = w }))
    hl.dispatch(hl.dsp.window.resize({ x = 960, y = 540 }))
    hl.dispatch(hl.dsp.window.center({}))
end
" >/dev/null 2>&1

hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")' >/dev/null 2>&1
