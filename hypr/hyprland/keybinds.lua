--##! Applications
hl.bind("SUPER + Q", "kitty", {description = "Open Terminal (Kitty)"})
hl.bind("SUPER + RETURN", "kitty", {description = "Open Terminal"})
hl.bind("SUPER + E", "nautilus", {description = "Open File Manager"})
hl.bind("SUPER + B", "browser", {description = "Open Web Browser"})
hl.bind("CTRL + SHIFT + Escape", "gnome-system-monitor", {description = "Task Manager / System Monitor"})

--##! Window Management
hl.bind("SUPER + C", "killactive", {description = "Close active window"})
hl.bind("SUPER + M", "exit", {description = "Exit Hyprland to login screen"})
hl.bind("SUPER + F", "fullscreen", {description = "Toggle fullscreen"})
hl.bind("SUPER + T", "togglefloating", {description = "Toggle floating window"})
hl.bind("SUPER + P", "pseudo", {description = "Toggle pseudotile"})
hl.bind("SUPER + J", "togglesplit", {description = "Toggle horizontal/vertical split"})
hl.bind("SUPER + SHIFT + R", "restart", {description = "Reload/restart Quickshell"})

--##! Shell & UI Overlays
hl.bind("SUPER", "quickshell:searchToggle", {description = "App Launcher & Search"})
hl.bind("SUPER + Space", "quickshell:searchToggle", {description = "App Launcher & Search"})
hl.bind("SUPER + D", "quickshell:searchToggle", {description = "App Launcher & Search"})
hl.bind("SUPER + Escape", "quickshell:settingsToggle", {description = "Settings Panel"})
hl.bind("SUPER + Tab", "quickshell:overviewWorkspacesToggle", {description = "Workspaces Overview"})
hl.bind("SUPER + /", "quickshell:overviewKeybindsToggle", {description = "Shortcuts Cheatsheet"})
hl.bind("SUPER + K", "quickshell:overviewKeybindsToggle", {description = "Shortcuts Cheatsheet"})
hl.bind("SUPER + N", "quickshell:sidebarRightToggle", {description = "Control Center (Right Sidebar)"})
hl.bind("SUPER + A", "quickshell:sidebarLeftToggle", {description = "AI & Tools (Left Sidebar)"})
hl.bind("SUPER + X", "quickshell:sessionToggle", {description = "Power & Session Menu"})
hl.bind("SUPER + V", "quickshell:overviewClipboardToggle", {description = "Clipboard History"})
hl.bind("SUPER + .", "quickshell:overviewEmojiToggle", {description = "Emoji Picker"})
hl.bind("SUPER + W", "quickshell:wallpaperSelectorToggle", {description = "Wallpaper Selector"})
hl.bind("SUPER + I", "quickshell:islandToggle", {description = "Toggle Top Dynamic Island"})
hl.bind("SUPER + SHIFT + D", "quickshell:dockerToggle", {description = "Docker Management Dashboard"})
hl.bind("SUPER + ALT + D", "quickshell:dockPinToggle", {description = "Toggle Pin Dash / Dock"})

--##! Navigation & Workspaces
hl.bind("SUPER + 1..9", "workspace", {description = "Switch to Workspace 1 - 9"})
hl.bind("SUPER + SHIFT + 1..9", "movetoworkspace", {description = "Move active window to Workspace 1 - 9"})
hl.bind("SUPER + Left/Right/Up/Down", "movefocus", {description = "Move focus between windows"})
