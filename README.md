# Antigravity Quickshell Configuration

A modern, high-performance desktop shell built with **Quickshell** (QtQuick/QML) and tailored specifically for **Google Antigravity** workflows, Hyprland, and Wayland.

---

## Features

- **✦ Antigravity AI Dynamic Island**:
  - Live agent status monitoring (Active / Ready) with pulsating cosmic glow.
  - Real-time step counter tracking current agent trajectories.
  - One-click access to the Antigravity HUD.
- **✦ Antigravity Assistant Center / HUD (`Super + A`)**:
  - **Quick Prompt Input**: Type instructions and execute them directly via `agy -i "<instruction>"`.
  - **Session Resume**: One-click continuation of current session (`agy -c`).
  - **New Agent Launcher**: Launch interactive agent session (`agy`).
  - **Brain Artifacts Browser**: Direct shortcut to browse `~/.gemini/antigravity-cli/brain`.
  - **Live Agent Telemetry**: Active conversation ID, total session count, trajectory step count, and latest activity logs.
- **❖ Hyprland Integration**:
  - Interactive workspace switcher pills with active workspace highlight and window animation.
  - Active window title pill with automatic truncation.
- **📊 System Telemetry**:
  - CPU usage percentage with threshold-based color coding.
  - RAM usage percentage.
  - PipeWire volume control (click to mute, scroll wheel to adjust volume).
- **⏱ Clock & Power**:
  - Formatted time (`HH:mm`) and date (`ddd, MMM d`).
  - Power / session modal with Lock, Logout, Sleep, Reboot, and Power Off.
- **🔍 Quick Spotlight Launcher (`Super + Space`)**:
  - Fast search and app launcher for terminal, editor, files, and commands.

---

## Directory Structure

```
custom_quickshell/
├── shell.qml                         # Root ShellRoot entrypoint
├── theme/
│   └── Theme.qml                     # Color palette, spacing, and font constants
├── services/
│   ├── AntigravityService.qml        # Real-time Antigravity brain / transcript monitor
│   ├── SystemStats.qml               # CPU and RAM telemetry service
│   └── ShellState.qml                # Global UI state and IPC message dispatcher
├── bar/
│   ├── TopBar.qml                    # Top Layer-Shell panel with floating islands
│   ├── WorkspacePill.qml             # Hyprland workspace switcher
│   ├── ActiveWindowPill.qml          # Focused window title widget
│   ├── AntigravityIsland.qml         # Dynamic center island with agent status
│   ├── SystemPill.qml                # CPU, Memory, and PipeWire volume
│   └── ClockPill.qml                 # Time, date, and power trigger
├── desktop/
│   └── DesktopClock.qml              # Desktop ambient clock & calendar widget (WlrLayer.Bottom)
├── panels/
│   ├── AntigravityPanel.qml          # Full agent HUD & workspace controller
│   ├── Launcher.qml                  # Quick application launcher modal
│   └── SessionDialog.qml             # System power and session modal
└── scripts/
    └── get_antigravity_status.py     # Fast parser for ~/.gemini/antigravity-cli/brain
```

---

## Keybindings (Hyprland)

| Shortcut | Action |
| :--- | :--- |
| `Super + A` / `Super + I` | Toggle Antigravity Assistant HUD |
| `Super + Space` / `Super + D` | Toggle App Launcher & Search |
| `Super + X` / `Super + Escape` | Toggle System Session & Power Dialog |
| `Super + Shift + R` | Reload / restart Quickshell (`launch-shell.sh`) |

---

## IPC Commands

You can control the shell from scripts or keybinds using `qs`:

```bash
# Toggle Antigravity HUD
qs -c antigravity ipc call antigravity toggle

# Toggle Launcher
qs -c antigravity ipc call search toggle

# Toggle Session / Power Dialog
qs -c antigravity ipc call session toggle

# Toggle Desktop Clock Widget
qs -c antigravity ipc call clock toggle

# Toggle Desktop Clock Format (12H / 24H)
qs -c antigravity ipc call clock toggleFormat
```
