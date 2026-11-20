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

### Display & Compositor (Hyprland Wayland 0.57+)
* Workspace switch: `hyprctl eval "return hl.dispatch(hl.dsp.focus({ workspace = <id> }))"`
* Focus window: `hyprctl eval "return hl.dispatch(hl.dsp.focus({ window = hl.get_window('address:<addr>') }))"`
* Close window: `hyprctl eval "return hl.dispatch(hl.dsp.window.close({ window = hl.get_window('address:<addr>') }))"`
* Move window to workspace: `hyprctl eval "return hl.dispatch(hl.dsp.window.move({ workspace = <id> }))"`
* Wake displays: `hyprctl eval "return hl.dispatch(hl.dsp.dpms('on'))"`
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
5. **No Flat Accent Lines Across Rounded Containers**: Avoid placing square 1px accent rectangles (`Rectangle { height: 1; anchors.top: parent.top }`) inside rounded cards without matching corner radiuses or clipping, as their square edges extend past parent borders and produce visible line artifacts across desktop widgets.

---

## 5. IPC & CLI Commands

```bash
# Manage shell daemon
qs -c antigravity -d                                    # Start shell daemon
quickshell log -c antigravity -t 30                     # Live log tail
quickshell list --all                                   # List running instances
quickshell kill -c antigravity                          # Stop shell daemon

# Core IPC Triggers
qs -c antigravity ipc call antigravity toggle           # Toggle HUD (Super + A / Super + I)
qs -c antigravity ipc call search toggle                # Toggle App Launcher (Super + Space / Super + Slash)
qs -c antigravity ipc call session toggle               # Toggle Power Menu (Super + X / Super + Escape)
qs -c antigravity ipc call omnibar toggle               # Toggle Omnibar Command Palette (Super + K)
qs -c antigravity ipc call pie toggle                   # Toggle 8-Slice Radial Pie Menu (Super + G)
qs -c antigravity ipc call clipboard toggle             # Toggle Clipboard History Manager (Super + V)
qs -c antigravity ipc call docker toggle                # Toggle Docker Container Manager (Super + D)
qs -c antigravity ipc call runner toggle                # Toggle Task Runner Modal (Super + R)
qs -c antigravity ipc call windowSwitcher toggle        # Toggle Mission Control Window Switcher (Super + Tab)
qs -c antigravity ipc call systemMonitor toggle         # Toggle System Resource Monitor (Super + Shift + M)
qs -c antigravity ipc call controlCenter toggle         # Toggle Control Center Panel
qs -c antigravity ipc call media toggle                 # Toggle Media Player Dropdown
qs -c antigravity ipc call pullRequests toggle          # Toggle GitHub Pull Requests Desktop Widget
qs -c antigravity ipc call jira toggle                  # Toggle Jira Issues Desktop Widget
qs -c antigravity ipc call whatsapp toggle              # Toggle WhatsApp Messenger Panel
qs -c antigravity ipc call liteMode toggle              # Toggle Lite / Battery Saver Mode (Super + Shift + L)

# Wallpaper, Gradient & Theme Controls
qs -c antigravity ipc call wallpaperTheme toggle       # Toggle Wallpaper & Theme Dialog (Super + W)
qs -c antigravity ipc call wallpaper toggleGradient    # Toggle Procedural Ambient Gradient Mode
qs -c antigravity ipc call theme fromWallpaperToggle   # Toggle Live "From Wallpaper" Adaptive Theme
qs -c antigravity ipc call wallpaper next              # Switch to next wallpaper in ~/Pictures/Wallpapers
qs -c antigravity ipc call wallpaper prev              # Switch to previous wallpaper
qs -c antigravity ipc call theme set <themeKey>        # Set theme (e.g. deepspace, catppuccin, tokyonight)
```

---

## 6. Wallpaper, Gradient & Theme Engine

### 1. Wallpapers & Themes Modal Dialog (`panels/WallpaperThemeDialog.qml`)
- **Keybinding**: <kbd>SUPER</kbd> + <kbd>W</kbd> mapped via Hyprland (`bind = $mainMod, W, exec, qs -c antigravity ipc call wallpaperTheme toggle`).
- **Wallpapers Tab**: Aspect-crop gallery of wallpapers from `~/Pictures/Wallpapers/` with active badge indicators and one-click application.
- **Themes Tab**: Visual palette cards showing accent preview dots, active selection status, and quick deletion for custom themes.

### 2. "From WP" Live Dynamic Theme Toggle (Temporary Preview)
- **Non-Persisting Preview**: Toggling "From WP" dynamically extracts dominant colors from the current desktop wallpaper using `scripts/extract_wallpaper_theme.py --temp`.
- **No Unwanted Saves**: The temporary palette is held in `Theme.tempWallpaperPalette` and cached in `~/.local/state/quickshell/user/temp-wallpaper-theme.json` during the live session; it is **NEVER** written to `antigravity-custom-themes.json`.
- **Auto-Revert**: Turning the "From WP" toggle OFF or selecting any saved palette immediately discards the temporary palette and cleanly reverts to the user's permanent theme.
- **Optional Permanent Save**: If the user wants to keep a live wallpaper theme permanently, clicking **"Save as Permanent Theme"** in the dialog banner freezes it into `antigravity-custom-themes.json`.

### 3. Procedural Ambient Gradient Mode
- **Header Toggle**: Accessible via the `Gradient: ON / OFF` button in the <kbd>SUPER</kbd> + <kbd>W</kbd> dialog or via IPC (`qs -c antigravity ipc call wallpaper toggleGradient`).
- **Ambient Canvas**: Replaces image wallpapers with CSS-style ambient color gradients synchronized with the current active theme accents.
- **State Preservation**: `WallpaperService.previousMode` remembers whether the user was previously on `manual` or `theme` wallpaper mode so exiting gradient mode returns cleanly to their previous background.

### 4. Custom Theme Generation
- **Script**: `scripts/create_custom_theme.py --name "<Name>" --primary "<Hex>" --secondary "<Hex>" --base "<Hex>"`.
- Generates 25 semantic UI tokens (surfaces, cards, glows, borders, text, accents) and saves to `antigravity-custom-themes.json`.

---

## 7. System Telemetry & Antigravity Token Tracking

* **System Telemetry**:
  - High-performance procfs CPU, RAM, Network and SWAP are queried in `services/SystemStats.qml` via native Rust (`bin/fast_system_stats`).
  - Displayed in `bar/SystemPill.qml` alongside Volume and Antigravity metrics.

* **Antigravity 5-Hour & Weekly Quotas**:
  - Quotas are queried programmatically via Antigravity's internal command:
    `agy --print "/quota" --output-format json`
  - Managed by native Rust engine `bin/antigravity_status` and cached in `/tmp/agy_quota_cache.json` to prevent blocking the shell UI.
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

---

## 8. Antigravity Mobile Remote & Hyprland Integration

The **Antigravity Mobile Remote** is a high-performance Progressive Web App (PWA) and WebSocket control daemon connecting smartphones to the Linux workstation for remote touchpad, keyboard, MPRIS media playback, 10 Hyprland workspaces, and desktop theme synchronization.

### 8.1 Architecture & Services
* **Codebase Directory**: `/home/alvin/Desktop/personal/antigravity-remote`
* **Daemon Service**: `systemctl --user {status|restart|stop} antigravity-remote.service`
* **Network & Port**: `https://<LAN_IP>.nip.io:3457` (e.g. `https://192.168.1.174.nip.io:3457`)
* **Strict 1-MAC Hardware Guard**: `lib/mac-guard.js` enforces single-device pairing using ARP table MAC inspection (`allowed_macs: ["16:cc:5f:cd:57:35"]`). Local loopback `127.0.0.1` (`host-loopback`) is permitted for testing and Playwright verification.
* **Input Driver (`ydotoold`)**: Virtual input via `~/.config/systemd/user/ydotool.service` with `ExecStartPre=/usr/bin/rm -f %t/.ydotool_socket` and a self-healing socket watchdog in `lib/input-engine.js`.

### 8.2 Hyprland Socket IPC & Workspace Rules
1. **Hyprland Command Socket Protocol (`.socket.sock`)**:
   > [!CRITICAL]
   > **NEVER send commands with a trailing newline (`\n`) to Hyprland's UNIX domain socket.**
   > Hyprland's command parser does not strip trailing newlines on arguments. Sending `dispatch workspace 2\n` causes Hyprland to parse the workspace number as `"2\n"`, which immediately fails with `Bad workspace`!
   > Always write commands cleanly with `client.end(cleanCmd.trim())` and provide a fallback to `exec("hyprctl " + cleanCmd)`.
2. **Multi-Monitor Workspaces (1–10)**:
   * Workspaces `1` through `5` are bound to the primary external monitor `HDMI-A-1`.
   * Workspaces `6` through `10` are bound to the laptop internal display `eDP-1`.
   * **Horizontally Scrollable Rail**: The UI organizes workspaces 1–10 into a smooth horizontal touch rail (`overflow-x-auto no-scrollbar scroll-smooth style={{ touchAction: 'pan-x' }}`).
   * **Auto-Centering**: Whenever `activeWorkspace` changes (via phone tap or desktop keybinding), an active button ref triggers `activeWsButtonRef.current.scrollIntoView({ behavior: 'smooth', inline: 'center' })`.
   * **Active Indicator**: Active workspace pill illuminates with `var(--accent-primary)` and ambient glow `0 0 14px var(--border-glow)`.

### 8.3 Mobile PWA & Flexbox Layout Rules
1. **The Flex Squeeze Prevention Rule (`shrink-0`)**:
   > [!IMPORTANT]
   > In vertical scrolling layouts (`overflow-y-auto`), every top-level card container **MUST** have `shrink-0` (or `flex-shrink: 0`).
   > In standard flexbox containers (`flex flex-col`), children default to `flex-shrink: 1`. When content exceeds the viewport, flexbox will aggressively compress elements (e.g. crushing a 140px media player card down to 26px). Adding `shrink-0` guarantees natural component height and enables smooth native scrolling.
2. **Viewport Height**: Always use `h-dvh` instead of `vh` across layout containers to avoid abrupt jumps when mobile browser address bars show or hide.
3. **No Clunky Scrollbars**: Apply `.no-scrollbar` (`scrollbar-width: none; &::-webkit-scrollbar { display: none; }`) to all mobile screens for a native app feel.
4. **Glow & Border Clearance**: Always add `pt-1.5 px-0.5 pb-6` to scroll containers so glowing box shadows (`0 0 16px var(--border-glow)`) and rounded borders are not sliced off by parent `overflow-hidden`.
5. **Touch Action**: Set `style={{ touchAction: 'none' }}` on touchpads and `touchAction: 'pan-x'` on horizontal scroll rails to eliminate 300ms mobile tap delays and accidental page panning.

### 8.4 Desktop Theme & Audio Synchronization
* **Live Theme Sync**: `lib/theme-syncer.js` watches `~/.local/state/quickshell/user/` and broadcasts active desktop theme changes to phone clients within 80ms.
* **Theme Studio Modal**: Allows the user to select from 15 themes or trigger 5-minute auto-cycling directly from their phone.
* **MPRIS Playerctl Audio**: Polls and streams metadata (`title`, `artist`, `status`) to the mobile remote with animated playback states and controls (`play-pause`, `prev`, `next`).
* **Integrated Master Volume**: Directly binds PipeWire volume (`wpctl get-volume @DEFAULT_AUDIO_SINK@`) into the audio card with live percentage readout, quick ±5% steppers, and mute toggle.

### 8.5 Magic Clipboard & Instant File Drop
* **Engine Module**: `/home/alvin/Desktop/personal/antigravity-remote/lib/clipboard-engine.js`
* **Wayland Non-Blocking Protocol**:
  - `wl-paste -n` reads the Wayland system clipboard with zero latency.
  - When copying from Node.js, `spawn('wl-copy', [text], { detached: true, stdio: 'ignore' }).unref()` must be used. Standard synchronous spawn or piped stdin hangs because Wayland's clipboard manager keeps pipes open until the next paste event.
* **Bi-Directional Phone ⇄ Workstation Sync**:
  - **PC ➔ Phone**: Displays real-time preview of the PC clipboard; 1-tap "Copy to Phone" triggers native mobile clipboard write (`navigator.clipboard.writeText`) with haptic pulse.
  - **Phone ➔ PC**: User types or pastes text from phone; 1-tap "Copy to PC" sends via WebSocket or `POST /api/clipboard`, executes `wl-copy`, and pops a desktop notification via `notify-send`.
  - **Direct Screen Typing**: "Type onto Screen" types the phone text directly into the active window using `ydotool type`.
* **Magic File & Photo Drop**:
  - Direct camera snap (`<input capture="environment" />`) or file picker streams binary chunks directly into `/home/alvin/Downloads/MagicDrop/` via `POST /api/upload`.
  - Automatically copies the dropped file path to the Wayland clipboard (`wl-copy`) and dispatches a desktop toast (`notify-send "Magic File Drop"`).
  - Quick action to open the folder on Linux via `POST /api/open-drop-folder` (`xdg-open` / `nautilus`).

### 8.6 Biometric Workstation Unlock (Local mkcert CA & WebAuthn)
* **Component & Engine**:
  - Frontend Modal: `/home/alvin/Desktop/personal/antigravity-remote/src/components/BiometricUnlockModal.tsx`
  - Engine Execution: `lib/input-engine.js` (`unlockSession(password)`)
  - WebSocket Handler: `server.js` (`biometric_unlock` / `unlock`)
* **Strict 100% Local LAN Certificate Authority (`mkcert`)**:
  - No external tunnels, no cloud services, no remote proxies. Everything stays strictly inside the local Wi-Fi.
  - Workstation CA: Generated via `/usr/bin/mkcert` in `~/.local/share/mkcert/rootCA.pem`.
  - Local Certificate: Generated in `/home/alvin/Desktop/personal/antigravity-remote/certs/` covering `192.168.1.174`, `192.168.1.174.nip.io`, `127.0.0.1`, `localhost`, `fedora`, and `fedora.local`.
  - Dedicated HTTPS Listener:
    - Runs exclusively on port `3457` over local HTTPS with the local CA-signed certificate. Plain HTTP port 3456 has been retired.
  - CA Distribution: Served directly at `https://192.168.1.174.nip.io:3457/rootCA.crt` for 1-tap phone installation.
* **Native Phone Biometrics Execution**:
  - When accessed over `https://192.168.1.174.nip.io:3457` with trusted CA, `window.isSecureContext === true`.
  - The domain name `192.168.1.174.nip.io` has a valid Public Suffix (`.io`), satisfying the W3C WebAuthn `rp.id` domain specification.
  - Calls `navigator.credentials.create` / `get` with `authenticatorAttachment: 'platform'` and `userVerification: 'required'`.
  - Directly prompts the native Android OS fingerprint dialog or iOS FaceID/TouchID sheet.
  - Hardware biometric verification is mandatory.
* **Workstation Unlock Protocol**:
  - **Display Wakeup**: Dispatches `hyprctl dispatch dpms on` to instantly power on screens.
  - **Hyprlock Dismissal**: Dispatches `pkill -SIGUSR1 hyprlock 2>/dev/null || pkill -x hyprlock 2>/dev/null || loginctl unlock-session 2>/dev/null`.
  - **PAM Fallback Vault**: Optional phone-stored local password safely dispatched via `ydotool type` followed by Enter (`key 28:1 28:0`) for strict password-only login managers.
  - **Desktop Notification**: Sends desktop verification toast `notify-send "Workstation Unlocked" "🔓 Authenticated via Phone Biometrics"`.
  - **Auto-Close**: Server broadcasts `session_unlocked`, causing the mobile UI to flash green checkmark confirmation and smoothly auto-close the modal.

### 8.7 Workstation App Launcher & Workspaces Page
* **Component & Engine**:
  - Engine Module: `/home/alvin/Desktop/personal/antigravity-remote/lib/app-engine.js`
  - Frontend Component: `/home/alvin/Desktop/personal/antigravity-remote/src/components/AppLauncher.tsx`
  - WebSocket Protocol:
    - `get_apps`: Returns array of parsed `.desktop` entries.
    - `launch_app`: Spawns application on Hyprland via `gtk-launch <desktopId>` or `hyprctl dispatch exec "<exec>"`.
* **Discovery Protocol**:
  - Scans `/usr/share/applications`, `/var/lib/flatpak/exports/share/applications`, `~/.local/share/applications`, and `~/.local/share/flatpak/exports/share/applications`.
  - Automatically filters `NoDisplay=true`, hidden entries, and duplicate desktop names.
* **Unified Workspaces + Overlays + App Launcher Integration**:
  - The 10 Hyprland Workspaces horizontal scroll rail has been centralized into this dedicated `Apps` tab.
  - **Workstation Overlays & Controls**: Placed right below the Workspaces rail:
    - Window actions: `Fullscreen`, `Float`, `Kill Win` (`act('hypr', ...)`).
    - Quickshell HUD: `✦ HUD`, `WA` (WhatsApp), `Controls` (`act('quickshell', ...)`).
    - Display brightness: `Bright -`, `Bright +` (`act('brightness', ...)`).
  - Allows selecting the target workspace (1–10) or controlling window geometry, then 1-tapping any installed app to launch it onto that workspace.
  - Features instant real-time search filtering across 103+ applications with category pills (`Development`, `Internet`, `Media`, `System`, `Utility`).
  - **Clean Media Tab**: With Workspaces and Overlays moved to the Apps page, the `Media` tab is now exclusively dedicated to Workstation Audio (MPRIS playback, PipeWire volume steppers & mute) and the Desktop Theme Studio.

---

## 9. Universal Dropdown Scratchpad Terminal

The Quake-style dropdown terminal is mapped via Hyprland keybinding to provide an instant, minimal floating terminal session.

* **Trigger**: <kbd>SUPER</kbd> + <kbd>`</kbd> (`grave`).
* **Launcher Script**: `~/.config/hypr/scripts/scratchpad.sh` (mirrored in `custom_quickshell/hypr/scripts/scratchpad.sh`).
* **Window Dimensions**: Minimal compact **960 × 540** (50% screen width & height), centered on the active display.
* **Window Rule (`hyprland.lua`)**:
  ```lua
  hl.window_rule({
      name = "kitty-scratchpad",
      match = { class = "kitty-scratchpad" },
      float = true,
      size = "960 540",
      center = true,
      workspace = "special:scratchpad",
      suppress_event = "maximize",
      rounding = 16,
  })
  ```
* **Kitty Launch Flags**:
  `kitty --class kitty-scratchpad --title "Antigravity Scratchpad" -o initial_window_width=960 -o initial_window_height=540 -o remember_window_size=no`
* **Behavior**:
  - The special workspace `special:scratchpad` is used for instant zero-latency hide/show without killing the underlying bash/zsh shell session.
  - Floating state, 16px corner rounding, and `suppress_event = "maximize"` prevent the window from expanding to the entire monitor.

---

## 10. Native Rust Multi-Call Engine (`agy-tools`)

All recurring system telemetry, status parsers, and external API collectors are implemented in a single unified, release-optimized Rust multi-call binary located at `rust/target/release/agy-tools` and symlinked into `bin/`.

### 10.1 Build & Deployment
```bash
cd ~/Desktop/personal/custom_quickshell
./scripts/build_rust.sh
```
Compiles with Release LTO (`opt-level = 3`, `lto = "fat"`, `codegen-units = 1`, `strip = true`) yielding sub-millisecond execution times and updating symlinks in `bin/`.

### 10.2 Inventory of Ported Native Tools

| Binary / Command | Source File | Function & Output Schema |
|---|---|---|
| `bin/fast_system_stats` | `rust/src/tools/fast_system_stats.rs` | High-frequency CPU %, RAM (used/total), Swap, Network in/out, Battery %, Load avg in <1ms via procfs. |
| `bin/system_monitor` | `rust/src/tools/system_monitor.rs` | Process tree, top 25 CPU/RAM consumers, PID kill handler (`--kill <pid> [--force]`), drop caches. |
| `bin/cliphist_helper` | `rust/src/tools/cliphist_helper.rs` | Wayland clipboard history parser, search filter, item deletion, and clear history. |
| `bin/extract_media_color` | `rust/src/tools/extract_media_color.rs` | Dominant palette extraction from Spotify/MPRIS album art for dynamic accent tinting. |
| `bin/audio_beat_tracker` | `rust/src/tools/audio_beat_tracker.rs` | 22 FFT chunk/s PipeWire audio beat tracker for reactive visualizers. Gated to `MediaService.isPlaying`. |
| `bin/docker_manager` | `rust/src/tools/docker_manager.rs` | Direct `/var/run/docker.sock` daemon communication; container start/stop/restart/pause/prune, image list/prune. |
| `bin/battery_helper` | `rust/src/tools/battery_helper.rs` | Linux sysfs battery capacity, status, wattage calculation, cycle mode indicator. |
| `bin/network_status` | `rust/src/tools/network_status.rs` | NetworkManager Wi-Fi SSID, signal strength %, IP addresses, gateway, and ethernet status. |
| `bin/wallpaper_helper` | `rust/src/tools/wallpaper_helper.rs` | Scans `~/Pictures/Wallpapers`, creates blurred backdrop cache, thumbnail generation. |
| `bin/window_switcher` | `rust/src/tools/window_switcher.rs` | Fast `hyprctl clients -j` parser formatting window addresses, titles, icons, and workspace coordinates in 0.7ms. |
| `bin/tuned_manager` | `rust/src/tools/tuned_manager.rs` | Tuned performance profile query and 1-click switching (Powersave ↔ Balanced ↔ Latency-Performance). |
| `bin/task_runner` | `rust/src/tools/task_runner.rs` | Executes custom developer scripts and shell commands in background tasks with real-time log tracking. |
| `bin/antigravity_status` | `rust/src/tools/antigravity_status.rs` | Scans 280+ brain conversation folders and active `transcript.jsonl` in 1.2ms; formats steps, status, quotas. |
| `bin/openwa_status` | `rust/src/tools/openwa_status.rs` | OpenWA WhatsApp container REST API client (`127.0.0.1:2785/api`); chats, unread counter, QR base64 decode. |
| `bin/github_prs` | `rust/src/tools/github_prs.rs` | GitHub GraphQL API query; relative timestamps, review state, CI rollup status, 90s cache. |
| `bin/jira_tasks` | `rust/src/tools/jira_tasks.rs` | Jira Cloud v3 REST API client; active vs completed tasks, avatar sync, JQL search pagination. |
| `bin/file_search` | `rust/src/tools/file_search.rs` | Ultra-fast multi-threaded file search engine combining user workspace scanning with indexed `plocate` global lookup in 3–15ms. |
| `bin/calendar_events` | `rust/src/tools/calendar_events.rs` | Multi-feed iCalendar (.ics) engine; parses VEVENTs, Google Meet / Zoom extraction, offline cache in 2ms. |

### 10.1 Omnibar Instant File Search (`@file`)
Integrated directly into **Omnibar** (<kbd>Super</kbd> + <kbd>K</kbd>):
* **Trigger Syntax**:
  - `@file <query>`: Instant global search matching file and folder names across `~/Desktop`, `~/Downloads`, `~/Documents`, `~/Pictures`, and full drive.
  - `@file`: Displays most recently modified files and active directories from user workspaces in **1ms**.
  - Also matches `@file:` or `file:`. (Lone `@` is reserved for standard application and system search).
* **Keyboard Navigation**:
  - <kbd>↑</kbd> / <kbd>↓</kbd>: Navigate through matched file items.
  - <kbd>PageUp</kbd> / <kbd>PageDown</kbd>: Scroll by 5 items.
  - <kbd>Enter</kbd>: Open selected file or directory with default system handler (`xdg-open`).
  - <kbd>Ctrl</kbd> + <kbd>Enter</kbd>: Reveal file in its parent directory / file manager.
  - <kbd>Ctrl</kbd> + <kbd>C</kbd>: Copy selected file's absolute path to clipboard (`wl-copy`) and send notification.
* **Folder Default Handler**:
  - `inode/directory` MIME type is explicitly configured to `org.gnome.Nautilus.desktop` in `~/.config/mimeapps.list`.

### 10.2 Omnibar Smart Web Jumps & Math Engine
Omnibar (<kbd>Super</kbd> + <kbd>K</kbd>) serves as a unified command bar:
* **Smart Prefixes**:
  - `@gh <query>` or `gh <query>`: Instant GitHub search (`https://github.com/search?q=<query>`). Press <kbd>Enter</kbd> to launch in default browser.
  - `@jira <key>` or `jira <key>`: Direct jump to AskMeIdentity Jira issue (`https://askmeidentity.atlassian.net/browse/<KEY>`) or `/jira/your-work`.
  - `@web <query>` or `@g <query>` or `? <query>`: Instant Google search without opening browser first.
* **Math & Programmer Base Conversion**:
  - Arbitrary arithmetic: `240 * 1.18`, `(1024 * 16) / 3`, `sqrt(144) + 5^2`, `15% of 850`.
  - Number base conversions: `0x7f to dec` (127), `255 to hex` (`0xFF`), `128 to bin` (`0b10000000`), `0b1010 to dec` (10).
  - Currency & Unit conversions: `150 usd to inr`, `32 c to f`, `100 km/h to mph`, `16 gb to mb`.
  - Time in city: `time in tokyo`, `time in london`, `time in nyc`.
  - Pressing <kbd>Enter</kbd> copies calculation results directly to clipboard (`wl-copy`).

### 10.3 Native Calendar & Agenda System (`DesktopClock.qml`)
Integrated directly into the desktop clock and calendar card with zero clutter:
* **Configuration**: `~/.config/quickshell/calendars.json`:
  ```json
  [
    {
      "name": "Calendar",
      "url": "https://calendar.google.com/calendar/ical/.../basic.ics",
      "color": "#f6c177"
    }
  ]
  ```
* **Features**:
  - **Expandable Integrated Schedule**: Nested directly beneath the monthly calendar grid in `DesktopClock.qml`.
  - **Collapsed Active Ticker**: Displays a sleek one-liner pill (`● 12:00 PM: Dentist`) under the date when the calendar grid is collapsed; clicking it expands the schedule.
  - **Notification Pip**: Small amber counter badge on the clock's calendar icon showing the number of events scheduled for today.
  - **Today's Timeline**: Chronologically sorted list showing start/end times, event title, venue, and emerald "NOW" indicator for current events.
  - **Upcoming Preview**: Next 2 events across the upcoming week.
  - **Side-by-Side Positioning**: `PullRequestsWidget.qml` sits cleanly beside `DesktopClock.qml` (`top: 76`), preventing any overlap whether the calendar is expanded or collapsed.
  - **IPC Control**: `qs -c antigravity ipc call agenda toggle` or `refresh`.
  - **Zero-Idle Cache**: 5-minute disk cache (`/tmp/quickshell_calendar_cache.json`) with automatic offline detection.

### 10.4 Antigravity HUD v2 (`AntigravityPanel.qml`)
Triggered via <kbd>Super</kbd> + <kbd>A</kbd> or `qs -c antigravity ipc call antigravity toggle`:
* **Quick Slash Workflow Launcher**: 1-click execution into Kitty terminal for:
  - `🚀 /plan`: Interactive multi-step planning
  - `⚡ /boost`: Deep reasoning & verification
  - `👥 /teamwork`: Multi-agent swarm orchestration
  - `🌐 /browser`: Headless/visual browser automation
  - `▶ Resume`: Resume active session with `agy -c --dangerously-skip-permissions`
* **Brain & Artifacts Quick Links**:
  - Direct 1-click button to open `~/.gemini/antigravity-cli/brain/`
  - 1-click button to browse current session's generated artifacts and reports
* **Live Telemetry**: Real-time token usage, 5h & weekly quota limits for Gemini and Claude/GPT fallback models.

---

## 11. Zero-Idle Scene Graph & Energy Efficiency

To ensure the desktop environment uses near **0.0% – 2.0% idle CPU** on battery and AC:

1. **No Infinite Looping Animations**:
   - Continuous animations (`SequentialAnimation on opacity { loops: Animation.Infinite }`) dirty the Wayland scene graph at 60Hz/120Hz continuously.
   - Status dots in `DockerPill.qml`, `WhatsAppPill.qml`, and `AntigravityWidget.qml` use clean static state indicators (`Theme.accentEmerald`, `Theme.accentAmber`, `Theme.accentRose`).
2. **Audio Service Real-Time Event Streaming**:
   - `services/AudioService.qml` streams live sink volume and mute updates via `pactl subscribe`.
   - Fallback polling timers have been removed; zero unnecessary process forks occur when audio volume is static.
3. **Audio Visualizer Process Gating**:
   - `services/AudioVisualizerService.qml` binds `audio_beat_tracker` execution strictly to `MediaService.isPlaying`. When Spotify or YouTube is paused, the FFT process sleeps immediately.
4. **WhatsApp Poller Backoff**:
   - `services/WhatsAppService.qml` applies exponential backoff (relaxed from 12s to 60s) when the OpenWA container or session is offline.
5. **Offline Network Poller Suspension (Jira, GitHub PRs, Gemini AGY)**:
   - When the system disconnects from the internet (`NetworkService.isOnline` becomes `false` via `nmcli networking connectivity`), polling timers in `JiraService.qml`, `GithubService.qml`, and `AntigravityService.qml` are immediately paused (`running: NetworkService.isOnline`).
   - Manual or scheduled `refresh()` calls instantly short-circuit without spawning background network processes, blocking on HTTP socket timeouts, or generating error spam.
   - In `AntigravityService.qml`, background detached `agy --print /quota` calls are strictly blocked while offline, preventing failed quota network calls.
   - Native Rust tools (`bin/jira_tasks`, `bin/github_prs`, `bin/antigravity_status`) perform native connectivity checks and return cached models with `"offline": true` in <1ms without network I/O.
   - When network connectivity is restored (`NetworkService.isOnline` transitions to `true`), services automatically resume polling and trigger an immediate fresh query without user intervention.
   - Desktop widgets (`JiraWidget.qml`, `PullRequestsWidget.qml`) gracefully display amber "Offline" indicators and cached item counters.

---

## 12. Display Topology & Hyprland Rules

* **Monitor Configuration**:
  - `HDMI-A-1`: 1920 × 1080 @ 100% scale (Workspaces 1–5, primary developer display).
  - `eDP-1`: 1920 × 1080 @ 100% scale (Workspaces 6–10, internal laptop screen).
  - **Strict Scale Rule**: Dual monitors must strictly maintain `scale = 1.000000` (100%).
* **Hyprland Lua Engine**:
  - Configured at `~/.config/hypr/hyprland.lua` (mirrored in `custom_quickshell/hypr/hyprland.lua`).
  - **Variable Frame Rate (VFR)**: VFR is permanently enabled in modern Hyprland core; do not add deprecated `misc.vfr` keys.





