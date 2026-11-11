# ✦ Antigravity Quickshell Desktop Setup

A high-performance, modern desktop shell built with **[Quickshell](https://quickshell.org/)** (QtQuick/QML) and tailored specifically for **Hyprland** on Wayland. Designed for pairing with **Google Antigravity** workflows, featuring dynamic reactive theming, real-time audio visualization, hardware telemetry, and fluid macOS-inspired micro-interactions.

> [!NOTE]
> **Platform Support**: This configuration is designed and tested natively on **Fedora Linux** (Rawhide / Fedora 40+), but is **fully configurable for Arch Linux** and other modern Wayland distributions with minimal package adjustments.

---

## ✦ Key Features

- **✦ Antigravity Dynamic Island**:
  - Live AI agent trajectory tracking and active status indicator.
  - **4-Band Real-Time Audio Visualizer**: Symmetrical live FFT equalizer (Sub-bass, Bass, Mid, Treble) with audio-reactive bass pulse aura.
  - **Dynamic Album Art Theming**: Extracts dominant vibrant accents from track artwork on the fly and adapts island borders, glows, and dropdown mini-player.
  - One-click access to the Antigravity HUD, media player, and omnibar.
- **⚡ Lite Mode (`Super + Shift + L`)**:
  - Instantly toggles between full visual effects and a lightweight zero-overhead mode for gaming and heavy workloads.
  - Shuts down background audio-stream monitoring daemons (`audio_beat_tracker.py`), freezes complex QML canvas animations, and suppresses album art extraction.
- **🎨 Synchronized Compositor & App Theming**:
  - **Hyprland Active Window Borders & Glow**: Automatically computes 45° border gradients and soft drop-shadow colors directly in Hyprland's Lua compositor engine in real time.
  - **Terminal (`kitty`)**: Generates ANSI palettes and Starship prompt colors on the fly, reloading active terminals with `SIGUSR1`.
  - **GTK & Browser Theming**: Updates GNOME `color-scheme` to `prefer-dark` and syncs GTK 3/4 `settings.ini`, `~/.gtkrc-2.0`, and Flatpak overrides.
  - **Lock Screen (`hyprlock`)**: Synchronizes lock screen colors and wallpaper automatically.
- **🔋 Tri-State Battery Pill**:
  - Click the battery pill in the TopBar to cycle between:
    1. **Percentage** (e.g. `85%`)
    2. **Time Remaining** (e.g. `4h 12min`)
    3. **Live Power Draw** (e.g. `14.2W` discharging or `+28.5W` fast charging)
  - Right-click opens GNOME Power Statistics.
- **📺 Hardware Shaders (`hyprshade`)**:
  - Curated GLSL 300 ES shaders ready to toggle:
    - **CRT Mode**: Curved barrel distortion, phosphor bloom, 600-line scanlines, and subtle chromatic aberration.
    - **Night Light**: Warm eye-care color temperature (~3200K).
    - **Vibrance**: Saturation and dynamic range boost.
    - **Grayscale**: High-contrast monochromatic black & white.
- **🎛 Control Center & Overlays**:
  - System monitor (CPU, RAM, swap, top processes), visual clipboard manager, application launcher, task runner, and mobile remote control companion.

---

## 📦 Installation & Dependencies

### 1. Fedora Linux (Native)

Install compositor, shell, media, and telemetry packages via `dnf`:

```bash
# Core Compositor & Shell
sudo dnf install quickshell hyprland kitty

# Audio, Media & Utilities
sudo dnf install playerctl grim slurp upower \
                 pipewire-utils pulseaudio-utils libnotify \
                 gsettings-desktop-schemas

# Python Libraries for Image & Audio Processing
sudo dnf install python3-pillow python3-numpy python3-dbus

# Install hyprshade for GLSL Screen Shaders
pip3 install --user hyprshade
```

### 2. Arch Linux (Adaptation)

All packages are readily available in Arch's official repositories and the AUR:

```bash
# Core Compositor & Utilities
sudo pacman -S hyprland kitty playerctl grim slurp upower \
               pipewire-pulse python-pillow python-numpy \
               python-dbus libnotify

# AUR Packages (Quickshell & Hyprshade)
yay -S quickshell-git hyprshade
```

> [!TIP]
> **Arch Configuration Notes**:
> - Ensure your PipeWire user services are active (`systemctl --user enable --now pipewire pipewire-pulse wireplumber`).
> - The audio visualizer automatically detects the default PipeWire audio monitor (`@DEFAULT_MONITOR@`) or EasyEffects sink.
> - If your laptop battery sysfs node is named `BAT1` instead of `BAT0`, the battery service automatically falls back cleanly to UPower's `DisplayDevice` over D-Bus.

---

## 🚀 Setup & Deployment

### Step 1: Clone & Symlink Quickshell Configuration

Clone this repository and symlink it to your user's Quickshell configuration path under the target name `antigravity`:

```bash
# Clone repository
git clone https://github.com/alvinbengeorge/antigravity-quickshell-setup.git ~/custom_quickshell

# Create config directory and symlink
mkdir -p ~/.config/quickshell
ln -s ~/custom_quickshell ~/.config/quickshell/antigravity
```

### Step 2: Configure Hyprland

This repository includes the complete, production-tested Hyprland setup under [`hypr/`](hypr/) (including Lua config, standard `.conf`, lock screen configs, shaders, and helper scripts).

You can either copy the bundled setup directly:
```bash
# Optional: Copy the bundled complete Hyprland setup
cp -r ~/custom_quickshell/hypr/* ~/.config/hypr/
```

Or add the autostart entry, layer rules, and keybinds to your existing config:

#### If using `hyprland.lua`:
```lua
-- Autostart Quickshell Antigravity configuration
hl.exec_cmd("qs -c antigravity")

-- Smooth blur for Quickshell panels and overlays
hl.layerrule({
    rule = "blur",
    match = { namespace = "quickshell:(launcher|session|antigravity:hud|clipboard|wallpapertheme|docker|runner|windowswitcher|whatsapp|systemmonitor|controlcenter|osd|omnibar|notifications)" }
})
hl.layerrule({
    rule = "ignorealpha 0.2",
    match = { namespace = "quickshell:(launcher|session|antigravity:hud|clipboard|wallpapertheme|docker|runner|windowswitcher|whatsapp|systemmonitor|controlcenter|osd|omnibar|notifications)" }
})

-- Recommended Keybindings
local mod = "SUPER"
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("qs -c antigravity ipc call search toggle"))
hl.bind(mod .. " + A",     hl.dsp.exec_cmd("qs -c antigravity ipc call antigravity toggle"))
hl.bind(mod .. " + V",     hl.dsp.exec_cmd("qs -c antigravity ipc call clipboard toggle"))
hl.bind(mod .. " + Tab",   hl.dsp.exec_cmd("qs -c antigravity ipc call windowSwitcher toggle"))
hl.bind(mod .. " + Escape",hl.dsp.exec_cmd("qs -c antigravity ipc call session toggle"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd("qs -c antigravity ipc call liteMode toggle"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("qs -c antigravity ipc call systemMonitor toggle"))
```

#### If using `hyprland.conf`:
```ini
# Autostart
exec-once = qs -c antigravity

# Layer Shell Blur Rules
layerrule = blur, quickshell:(launcher|session|antigravity:hud|clipboard|wallpapertheme|docker|runner|windowswitcher|whatsapp|systemmonitor|controlcenter|osd|omnibar|notifications)
layerrule = ignorealpha 0.2, quickshell:(launcher|session|antigravity:hud|clipboard|wallpapertheme|docker|runner|windowswitcher|whatsapp|systemmonitor|controlcenter|osd|omnibar|notifications)

# Keybindings
$mainMod = SUPER
bind = $mainMod, Space, exec, qs -c antigravity ipc call search toggle
bind = $mainMod, A,     exec, qs -c antigravity ipc call antigravity toggle
bind = $mainMod, V,     exec, qs -c antigravity ipc call clipboard toggle
bind = $mainMod, Tab,   exec, qs -c antigravity ipc call windowSwitcher toggle
bind = $mainMod, Escape,exec, qs -c antigravity ipc call session toggle
bind = $mainMod SHIFT, L, exec, qs -c antigravity ipc call liteMode toggle
bind = $mainMod SHIFT, M, exec, qs -c antigravity ipc call systemMonitor toggle
```

### Step 3: Test and Launch

Run Quickshell in test mode or launch it directly in the background:

```bash
# Launch active shell configuration
qs -c antigravity

# Or check live shell logs in real time
quickshell log -c antigravity -t 30
```

---

## ⌨️ Hyprland Keybindings Reference

| Shortcut | Action | Description |
|---|---|---|
| `Super + Space` | **App Launcher & Search** | Spotlight-style fuzzy application & file search |
| `Super + A` / `Super + I` | **Antigravity AI HUD** | Access agent instructions, active trajectories & brain logs |
| `Super + V` | **Clipboard History** | Visual clipboard manager with search and image preview |
| `Super + Tab` | **Window Switcher** | Alt-Tab style visual switcher across workspaces |
| `Super + Escape` / `Super + X` | **Session Menu** | Lock, Logout, Suspend, Reboot, or Shutdown dialog |
| `Super + Shift + L` | **Toggle Lite Mode** | Toggle between maximum visual eye candy and raw gaming FPS |
| `Super + Shift + M` | **System Monitor** | Live CPU, Memory, Swap, and top process monitor |
| `Super + K` | **Omnibar** | Global launcher and command runner |
| `Super + W` | **Wallpaper Theme Picker** | Extract themes from wallpapers or select palettes |

---

## 🕹️ CLI & IPC Command Cheat Sheet

Quickshell includes an IPC interface via `qs` to automate and control any component from the terminal or external scripts:

```bash
# UI Panels
qs -c antigravity ipc call search toggle            # App Launcher
qs -c antigravity ipc call antigravity toggle       # Antigravity AI HUD
qs -c antigravity ipc call clipboard toggle         # Clipboard History
qs -c antigravity ipc call session toggle           # Power / Session Menu
qs -c antigravity ipc call systemMonitor toggle     # System Monitor

# Performance Modes
qs -c antigravity ipc call liteMode toggle          # Toggle Lite Mode on/off
qs -c antigravity ipc call liteMode status          # Print "enabled" or "disabled"

# Theming & Wallpaper
qs -c antigravity ipc call theme next               # Cycle to next theme
qs -c antigravity ipc call theme prev               # Cycle to previous theme
qs -c antigravity ipc call theme set "askmeidentity"# Set theme: askmeidentity, cyberpunk, arythmatic, catppuccin, tokyonight, nord
qs -c antigravity ipc call wallpaper next           # Cycle wallpaper
qs -c antigravity ipc call wallpaper themeMode      # Lock wallpaper to active theme

# Shaders (via hyprshade)
hyprshade on crt                                    # Enable vintage CRT scanlines & curvature
hyprshade on night-light                            # Enable warm blue-light filter (~3200K)
hyprshade on vibrance                               # Boost saturation & dynamic range
hyprshade on grayscale                              # Monochromatic B&W reading mode
hyprshade off                                       # Revert to standard display
```

---

## 📂 Project Architecture

```
custom_quickshell/
├── shell.qml                         # Root ShellRoot entrypoint & window registrations
├── theme/
│   └── Theme.qml                     # Palette definitions, semantic tokens & theme switcher
├── bar/
│   ├── TopBar.qml                    # Top Layer-Shell panel hosting floating pills
│   ├── AntigravityIsland.qml         # Dynamic center island with live FFT visualizer & aura
│   ├── WorkspacePill.qml             # Hyprland workspace switcher dots & focus ring
│   ├── ActiveWindowPill.qml          # Active application title indicator
│   ├── SystemPill.qml                # Telemetry pill: CPU, RAM, and Tri-State Battery
│   └── BatteryPill.qml               # Percentage / Time / Watts toggle component
├── panels/
│   ├── ControlCenter.qml             # Full quick-settings panel (WiFi, BT, Audio, Shaders)
│   ├── MediaDropdown.qml             # Floating frosted mini-player beneath dynamic island
│   ├── WorkspacePreview.qml          # Live workspace preview popup
│   ├── AntigravityPanel.qml          # Full agent HUD & brain inspector
│   ├── Launcher.qml                  # Quick application launcher modal
│   ├── Clipboard.qml                 # Visual clipboard history manager
│   └── SessionDialog.qml             # Power, lock, and session modal
├── services/
│   ├── AudioVisualizerService.qml    # PipeWire FFT streaming client (with Lite Mode controls)
│   ├── MediaService.qml              # MPRIS media player controller & album art color extractor
│   ├── BatteryService.qml            # D-Bus & sysfs tri-state power manager
│   ├── ShellState.qml                # Global UI state, IPC handlers, and persistent settings
│   └── AntigravityService.qml        # Real-time Antigravity trajectory telemetry
├── hypr/                             # Complete Hyprland compositor setup
│   ├── hyprland.lua                  # Primary modern Lua compositor config
│   ├── hyprland.conf                 # Alternative standard .conf provider
│   ├── hyprlock.conf                 # Lock screen configuration
│   ├── hyprlock-colors.conf          # Dynamic lock screen theme colors
│   ├── shaders/                      # Hardware GLSL 300 ES shaders (CRT, Night Light, Vibrance)
│   └── scripts/                      # Window rules, scratchpad, and shell launch helpers
└── scripts/
    ├── apply_hyprland_theme.py       # Live compositor border & shadow syncer (Lua eval)
    ├── apply_system_theme.py         # Master theme pipeline (GTK, Hyprland, Hyprlock)
    ├── audio_beat_tracker.py         # Sub-20ms PipeWire audio FFT analyzer
    ├── extract_media_color.py        # Dominant color extractor from album artwork
    └── get_jira_tasks.py             # Secure Jira task loader for desktop widget
```

---

## 📜 License

Released under the **MIT License**. Created and maintained by [Alvin Ben George](https://github.com/alvinbengeorge).
