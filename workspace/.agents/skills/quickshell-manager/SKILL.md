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
qs -c antigravity -d                                    # Start shell
quickshell log -c antigravity -t 30                     # Live log tail
quickshell list --all                                   # List running instances
quickshell kill -c antigravity                          # Stop shell

# Core IPC Triggers
qs -c antigravity ipc call antigravity toggle           # Toggle HUD (Super + A)
qs -c antigravity ipc call search toggle                # Toggle App Launcher (Super + Space)
qs -c antigravity ipc call session toggle               # Toggle Power Menu (Super + X)
qs -c antigravity ipc call pullRequests toggle          # Toggle Pull Requests Widget
qs -c antigravity ipc call systemMonitor toggle         # Toggle System Resource Monitor (Super + Shift + M)

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




