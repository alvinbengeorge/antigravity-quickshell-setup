---
name: quickshell-manager
description: Linux Device Assistant and desktop shell manager for Fedora, Hyprland, and Quickshell. Handles system peripherals, audio, hardware telemetry, custom widgets, and safe execution of privileged commands.
---

# Linux Device Assistant & Quickshell Manager

This skill guides Antigravity to act as an autonomous **Linux Device Assistant** for Fedora running **Hyprland** (Wayland) and the **Antigravity Quickshell** desktop environment.

---

## 1. Core Rule: Handling `sudo`, `systemctl`, and Privileged Commands

> [!CRITICAL]
> **NEVER execute `sudo`, `pkexec`, or polkit-gated commands directly inside Antigravity's non-interactive runner.**
> Commands like `systemctl start docker`, `dnf install <pkg>`, or `sudo <cmd>` require interactive TTY authentication. If run in the background, they will block indefinitely waiting on a password prompt!

### Privileged Execution Protocol
Whenever a task requires root elevation or polkit authentication:
1. **Spawn an interactive Kitty terminal** on the user's desktop:
   ```bash
   /home/alvin/Desktop/personal/custom_quickshell/scripts/run_privileged.sh "<command>"
   ```
   Or directly:
   ```bash
   kitty --title "Privileged Task" bash -c "<command>; echo ''; echo 'Completed. Press Enter to close.'; read"
   ```
2. **Inform the user clearly**: State that an interactive terminal window has been opened for them to authenticate with their password.
3. **Do not block the turn**: Allow the user to authenticate in the GUI terminal.

---

## 2. Linux Hardware & Device Management

### Audio & Volume (PipeWire & WirePlumber)
* Read volume: `wpctl get-volume @DEFAULT_AUDIO_SINK@`
* Adjust volume: `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+` or `5%-`
* Toggle mute: `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`
* Real-time audio stream: `pactl subscribe` emits instant events for sink changes.

### Battery & Power (Kernel sysfs & UPower)
* Capacity: `cat /sys/class/power_supply/BAT0/capacity`
* Charging status: `cat /sys/class/power_supply/BAT0/status` (Full, Charging, Discharging)
* UPower: `upower -i /org/freedesktop/UPower/devices/battery_BAT0`

### Display & Compositor (Hyprland Wayland)
* Workspace switch: `hyprctl dispatch workspace <id>`
* Focus window: `hyprctl dispatch focuswindow <class/title>`
* List windows & monitors: `hyprctl clients -j`, `hyprctl monitors -j`, `hyprctl workspaces -j`
* Reload config: `hyprctl reload`

### Network & Bluetooth
* WiFi status: `nmcli device wifi list`
* Connect WiFi: `nmcli device wifi connect "<SSID>" password "<PASS>"`
* Bluetooth: `bluetoothctl devices`, `bluetoothctl connect <MAC>`

---

## 3. Quickshell Architecture & Custom Widget Recipes

### Project Structure
* **Project Root**: `~/Desktop/personal/custom_quickshell/`
* **Configuration Symlink**: `~/.config/quickshell/antigravity`
* **Agent Workspace**: `~/Desktop/personal/custom_quickshell/workspace/`

### Adding a Custom Widget (Step-by-Step)

#### Step 1: Create `bar/MyWidget.qml`
```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"

Rectangle {
    id: root
    height: 34
    radius: height / 2
    color: Theme.bgPill
    border.color: Theme.borderDim
    border.width: 1

    implicitWidth: contentRow.implicitWidth + 20

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: "⚡"
            font.pixelSize: 12
        }

        Text {
            text: "Status"
            font.family: Theme.fontMono
            font.pixelSize: 11
            font.bold: true
            color: Theme.textPrimary
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Interactive action or IPC call
        }
    }
}
```

#### Step 2: Create a Service (if dynamic data is needed) in `services/MyService.qml`
Use `pragma Singleton` with `Process` + `StdioCollector` and a `Timer` or event stream.

#### Step 3: Register in `bar/TopBar.qml`
Add the widget to `leftRow` or `rightRow`:
```qml
SystemPill {}
BatteryPill {}
MyWidget {}       // <-- Newly added widget
ClockPill {}
```

---

## 4. QML Best Practices & Rules

1. **Hex Alpha Rule**: QML hex colors are `#AARRGGBB` (Alpha first). `#F20B0F17` is 95% obsidian; `#0D1322` is solid black.
2. **Expanding Layouts**: Use QtQuick `Row` (NOT `RowLayout`) for items with dynamic or animated widths (e.g. workspace dots). Standard `Row` continuously shifts adjacent items without overlap.
3. **Island Boundary Rule**: Left and right rows in `TopBar.qml` must be anchored relative to `centerIsland` (`anchors.right: centerIsland.left`) so active window titles truncate with `elide: Text.ElideRight` instead of overlapping the center.
4. **Standard Unicode Icons**: Use universal unicode symbols (`🔊`, `🔇`, `⚡`, `🔋`, `✦`, `❖`) rather than unconfirmed Nerd Font codepoints to prevent `▯` missing glyph boxes.

---

## 5. IPC & CLI Commands

```bash
# Manage shell daemon
qs -c antigravity -d                            # Start shell
quickshell log -c antigravity -t 30             # Live log tail
quickshell list --all                           # List running instances
quickshell kill -c antigravity                  # Stop shell

# IPC Keybind Triggers
qs -c antigravity ipc call antigravity toggle   # Toggle HUD (Super + A)
qs -c antigravity ipc call search toggle        # Toggle App Launcher (Super + Space)
qs -c antigravity ipc call session toggle       # Toggle Power Menu (Super + X)
```

---

## 6. System Telemetry & Antigravity Token Tracking

* **System Telemetry**:
  - CPU, RAM, and SWAP are queried reactively in `services/SystemStats.qml` via:
    `python3 -c "import psutil; print(f'{int(psutil.cpu_percent(interval=0.1))} {int(psutil.virtual_memory().percent)} {int(psutil.swap_memory().percent)}')"`
  - Displayed in `bar/SystemPill.qml` alongside Volume and Antigravity metrics.

* **Antigravity 5-Hour & Weekly Quotas**:
  - Quotas are queried programmatically via Antigravity's internal command:
    `agy --print "/quota" --output-format json`
  - Cached in `/tmp/agy_quota_cache.json` by `scripts/update_quota_cache.py` to prevent blocking the shell UI.
  - Exposes:
    - **Gemini 5-Hour Limit Remaining** (`gemini-5h` window: 5h rolling demand).
    - **Gemini Weekly Limit Remaining** (`gemini-weekly` window: weekly tier allocation).
    - **Claude & GPT 5-Hour Limit Remaining** & **Weekly Limit Remaining**.
    - Reset timestamps and human-readable refresh descriptions.
  - **Top Bar Indicator**: `bar/SystemPill.qml` allows cycling between:
    - `✦ 5h <percent>%` (5-hour limit remaining)
    - `✦ Wk <percent>%` (Weekly limit remaining)
    - `✦ Ctx <tokens>` (Current turn context tokens)
  - **HUD Panel**: Full visual quota progress bars in `panels/AntigravityPanel.qml` (Super + A).


