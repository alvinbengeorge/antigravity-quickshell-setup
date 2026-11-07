#!/usr/bin/env bash
# ==============================================================================
# Virtual Display & Wireless Cast Manager for Hyprland & GNOME Network Displays
# ==============================================================================

set -e

ACTION="${1:-status}"
DEFAULT_WIDTH=1920
DEFAULT_HEIGHT=1080
DEFAULT_HZ=30
DEFAULT_SIDE="left"

get_target_coordinates() {
    local SIDE="${1:-$DEFAULT_SIDE}"
    local WIDTH="${2:-$DEFAULT_WIDTH}"
    python3 -c "
import json, subprocess
side = '$SIDE'
width = int('$WIDTH')
try:
    monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j']))
    hdmi = next((m for m in monitors if 'HDMI' in m['name']), None)
    phys = [m for m in monitors if not m['name'].startswith('HEADLESS')]
    if side == 'left':
        if hdmi:
            target_x = hdmi['x'] - width
            target_y = hdmi['y']
        elif phys:
            target_x = min(m['x'] for m in phys) - width
            target_y = 0
        else:
            target_x = -width
            target_y = 0
    else:
        if phys:
            target_x = max(m['x'] + m['width'] for m in phys)
            target_y = 0
        else:
            target_x = 3840
            target_y = 0
    print(f'{target_x}x{target_y}')
except Exception:
    print('-1920x0')
"
}

get_active_headless() {
    python3 -c "
import json, subprocess
try:
    monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j']))
    headless = [m['name'] for m in monitors if m['name'].startswith('HEADLESS')]
    print(' '.join(headless))
except:
    pass
"
}

create_virtual() {
    local WIDTH="${1:-$DEFAULT_WIDTH}"
    local HEIGHT="${2:-$DEFAULT_HEIGHT}"
    local HZ="${3:-$DEFAULT_HZ}"
    local SIDE="${4:-$DEFAULT_SIDE}"
    local COORDS=$(get_target_coordinates "$SIDE" "$WIDTH")
    
    echo "[✦] Creating virtual headless display (${WIDTH}x${HEIGHT}@${HZ} at ${COORDS}, $SIDE of HDMI)..." >&2
    hyprctl output create headless >/dev/null
    
    # Give compositor a split second to register
    sleep 0.3
    
    local NEW_NAME=$(python3 -c "
import json, subprocess
monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j']))
headless = [m['name'] for m in monitors if m['name'].startswith('HEADLESS')]
print(headless[-1] if headless else '')
")

    if [ -z "$NEW_NAME" ]; then
        echo "[-] Failed to detect created headless display." >&2
        exit 1
    fi

    echo "[✦] Configuring $NEW_NAME via Hyprland Lua manager at $COORDS..." >&2
    hyprctl eval "hl.monitor({ output = '$NEW_NAME', mode = '${WIDTH}x${HEIGHT}@${HZ}', position = '${COORDS}', scale = 1 })" >/dev/null || true
    
    # Bind workspace 10 to virtual display
    hyprctl eval "return hl.dispatch(hl.dsp.workspace.move({ workspace = 10, monitor = '$NEW_NAME' }))" >/dev/null 2>&1 || true

    echo "[✦] Virtual display active: $NEW_NAME (${WIDTH}x${HEIGHT} at position ${COORDS})" >&2
    echo "$NEW_NAME"
}

remove_virtual() {
    local TARGET="$1"
    if [ -z "$TARGET" ]; then
        local ACTIVE_LIST=$(get_active_headless)
        if [ -z "$ACTIVE_LIST" ]; then
            echo "[i] No active virtual headless displays found."
            return 0
        fi
        for h in $ACTIVE_LIST; do
            echo "[✦] Removing virtual display: $h..."
            hyprctl output remove "$h" >/dev/null
        done
    else
        echo "[✦] Removing virtual display: $TARGET..."
        hyprctl output remove "$TARGET" >/dev/null
    fi
    echo "[✦] Virtual displays removed."
}

show_status() {
    echo "=============================================================================="
    echo " Hyprland Display Topology"
    echo "=============================================================================="
    python3 -c "
import json, subprocess
try:
    monitors = json.loads(subprocess.check_output(['hyprctl', 'monitors', '-j']))
    print(f'{\"Monitor\":<14} | {\"Resolution\":<16} | {\"Position\":<12} | {\"Workspace\":<10} | {\"Type\"}')
    print('-' * 70)
    for m in monitors:
        mtype = 'Virtual (Headless)' if m['name'].startswith('HEADLESS') else 'Physical Display'
        res = f\"{m['width']}x{m['height']}@{int(m.get('refreshRate', 60))}Hz\"
        x = m['x']
        y = m['y']
        pos = f\"{x:+d},{y:+d}\" if x != 0 or y != 0 else \"0,0\"
        ws = str(m.get('activeWorkspace', {}).get('name', 'N/A'))
        print(f\"{m['name']:<14} | {res:<16} | {pos:<12} | {ws:<10} | {mtype}\")
except Exception as e:
    print('Error reading monitors:', e)
"
    echo ""
    local ACTIVE_HEADLESS=$(get_active_headless)
    if [ -n "$ACTIVE_HEADLESS" ]; then
        echo "Active Virtual Output(s): $ACTIVE_HEADLESS"
    else
        echo "No virtual display active. Run: $0 create"
    fi
}

start_cast() {
    # Ensure any previous instances are closed so portal re-queries all monitors
    killall -q gnome-network-displays || true
    sleep 0.8

    local ACTIVE=$(get_active_headless | awk '{print $NF}')
    if [ -z "$ACTIVE" ]; then
        ACTIVE=$(create_virtual "$@")
        sleep 0.8
    else
        echo "[i] Reusing existing virtual display: $ACTIVE"
        local COORDS=$(get_target_coordinates "left" "$DEFAULT_WIDTH")
        hyprctl eval "hl.monitor({ output = '$ACTIVE', mode = '${DEFAULT_WIDTH}x${DEFAULT_HEIGHT}@${DEFAULT_HZ}', position = '${COORDS}', scale = 1 })" >/dev/null || true
    fi

    # Select best encoder for Windows Wireless Display compatibility
    if gst-inspect-1.0 x264enc >/dev/null 2>&1; then
        export NETWORK_DISPLAYS_H264_ENC=x264enc
        echo "[✦] Using high-compatibility x264 encoder (Windows Wireless Display compatible)"
    elif gst-inspect-1.0 vaapih264enc >/dev/null 2>&1; then
        export NETWORK_DISPLAYS_H264_ENC=vaapih264enc
        echo "[✦] Using hardware VA-API encoder"
    fi

    echo "[✦] Launching GNOME Network Displays (auto-selecting $ACTIVE on the left)..."
    echo "[i] Under 'Available Video Sinks', select your Windows laptop."

    # Background helper to automatically select the headless monitor in the portal share-picker
    python3 -c "
import json, subprocess, time
for _ in range(40):
    try:
        clients = json.loads(subprocess.check_output(['hyprctl', 'clients', '-j']))
        picker = next((c for c in clients if 'share-picker' in c.get('class', '')), None)
        if picker:
            time.sleep(0.4)
            bx = picker['at'][0] + (picker['size'][0] // 2)
            by = picker['at'][1] + 171
            subprocess.run(['hyprctl', 'eval', f'return hl.dispatch(hl.dsp.cursor.move({{ x = {bx}, y = {by} }}))'], capture_output=True)
            time.sleep(0.15)
            subprocess.run(['env', 'YDOTOOL_SOCKET=/run/user/1000/.ydotool_socket', 'ydotool', 'click', '0xC0'], capture_output=True)
            break
    except Exception:
        pass
    time.sleep(0.2)
" >/dev/null 2>&1 &

    setsid env NETWORK_DISPLAYS_H264_ENC=x264enc G_MESSAGES_DEBUG=all gnome-network-displays </dev/null >/tmp/network-displays.log 2>&1 &
}

start_vnc() {
    local WIDTH="${1:-$DEFAULT_WIDTH}"
    local HEIGHT="${2:-$DEFAULT_HEIGHT}"
    local HZ="${3:-60}"
    local SIDE="${4:-$DEFAULT_SIDE}"

    # Kill any existing VNC instances
    killall -q wayvnc novnc_server websockify 2>/dev/null || true
    sleep 0.5

    local ACTIVE=$(get_active_headless | awk '{print $NF}')
    if [ -z "$ACTIVE" ]; then
        ACTIVE=$(create_virtual "$WIDTH" "$HEIGHT" "$HZ" "$SIDE")
        sleep 0.5
    else
        echo "[i] Reusing existing virtual display: $ACTIVE"
        local COORDS=$(get_target_coordinates "$SIDE" "$WIDTH")
        hyprctl eval "hl.monitor({ output = '$ACTIVE', mode = '${WIDTH}x${HEIGHT}@${HZ}', position = '${COORDS}', scale = 1 })" >/dev/null || true
    fi

    echo "[✦] Starting WayVNC server on output $ACTIVE (60 FPS, GPU accelerated)..."
    setsid wayvnc -o "$ACTIVE" --gpu -f "$HZ" 0.0.0.0 5900 </dev/null >/tmp/wayvnc.log 2>&1 &
    sleep 0.8

    echo "[✦] Starting noVNC web server on port 6080..."
    setsid novnc_server --web /usr/share/novnc --listen 6080 --vnc localhost:5900 </dev/null >/tmp/novnc.log 2>&1 &
    sleep 0.8

    local IP=$(ip -4 addr show wlo1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    if [ -z "$IP" ]; then
        IP=$(hostname -I | awk '{print $1}')
    fi

    echo "=============================================================================="
    echo " 🚀 High-Performance Virtual Second Display Ready!"
    echo "=============================================================================="
    echo " Target Monitor : $ACTIVE (${WIDTH}x${HEIGHT}@${HZ}Hz on Workspace 10)"
    echo " Position       : $SIDE of HDMI"
    echo ""
    echo " 👉 Option 1 (Zero Install - In Browser on Windows Laptop):"
    echo "    Open Google Chrome or Edge and go to:"
    echo "    http://${IP}:6080/vnc.html?autoconnect=true&resize=remote"
    echo "    (Press F11 for seamless Full Screen)"
    echo ""
    echo " 👉 Option 2 (Native VNC Client - TigerVNC / RealVNC on Windows):"
    echo "    VNC Address: ${IP}:5900"
    echo "=============================================================================="
}

stop_cast() {
    echo "[✦] Stopping Virtual Display services..."
    killall gnome-network-displays wayvnc novnc_server websockify 2>/dev/null || true
    remove_virtual
}

case "$ACTION" in
    create)
        shift
        create_virtual "$@"
        ;;
    remove|destroy|delete)
        shift
        remove_virtual "$@"
        ;;
    status|list)
        show_status
        ;;
    vnc)
        shift
        start_vnc "$@"
        ;;
    cast)
        shift
        start_cast "$@"
        ;;
    start)
        shift
        start_vnc "$@"
        ;;
    stop)
        stop_cast
        ;;
    *)
        echo "Usage: $0 {start|vnc [W] [H] [Hz] [left|right] | cast | remove [name] | status | stop}"
        exit 1
        ;;
esac
