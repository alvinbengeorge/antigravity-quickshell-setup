#!/usr/bin/env python3
import os
import sys
import subprocess

GTK_THEME_MAP = {
    "deepspace": "Obsidian-flow-blue-dark",
    "catppuccin": "Obsidian-flow-purple-dark",
    "tokyonight": "Obsidian-flow-blue-dark",
    "nord": "Obsidian-flow-gray-dark",
    "cyberpunk": "Obsidian-flow-red-dark",
    "gruvbox": "Obsidian-flow-yellow-dark"
}

def update_ini_file(filepath, key, value):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    lines = []
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            lines = f.readlines()

    has_settings = False
    key_found = False
    new_lines = []

    for line in lines:
        stripped = line.strip()
        if stripped == "[Settings]":
            has_settings = True
            new_lines.append(line)
        elif stripped.startswith(f"{key}=") or stripped.startswith(f"{key} ="):
            new_lines.append(f"{key} = {value}\n")
            key_found = True
        else:
            new_lines.append(line)

    if not has_settings:
        new_lines.insert(0, "[Settings]\n")
    if not key_found:
        new_lines.append(f"{key} = {value}\n")

    with open(filepath, "w") as f:
        f.writelines(new_lines)

def update_gtk2_file(filepath, theme_name):
    lines = []
    if os.path.exists(filepath):
        with open(filepath, "r") as f:
            lines = f.readlines()

    found = False
    new_lines = []
    for line in lines:
        if line.strip().startswith("gtk-theme-name="):
            new_lines.append(f'gtk-theme-name="{theme_name}"\n')
            found = True
        else:
            new_lines.append(line)

    if not found:
        new_lines.append(f'gtk-theme-name="{theme_name}"\n')

    with open(filepath, "w") as f:
        f.writelines(new_lines)

def apply_theme(theme_key):
    gtk_theme = GTK_THEME_MAP.get(theme_key, "Adwaita-dark")

    # 1. Modern GTK4 / Libadwaita & Web Browsers (Chromium, Firefox, VS Code)
    # This triggers the portal 'color-scheme' signal and GSettings
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark"], capture_output=True)

    # 2. Legacy Application Theme (GNOME gtk-theme)
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", gtk_theme], capture_output=True)

    # 3. Direct GTK3 / GTK4 Configuration Files
    home = os.path.expanduser("~")
    gtk3_path = os.path.join(home, ".config/gtk-3.0/settings.ini")
    gtk4_path = os.path.join(home, ".config/gtk-4.0/settings.ini")
    gtk2_path = os.path.join(home, ".gtkrc-2.0")

    update_ini_file(gtk3_path, "gtk-theme-name", gtk_theme)
    update_ini_file(gtk3_path, "gtk-application-prefer-dark-theme", "1")

    update_ini_file(gtk4_path, "gtk-theme-name", gtk_theme)
    update_ini_file(gtk4_path, "gtk-application-prefer-dark-theme", "1")

    update_gtk2_file(gtk2_path, gtk_theme)

    # 4. Flatpak override for sandboxed GTK applications
    try:
        subprocess.run(["flatpak", "override", "--user", f"--env=GTK_THEME={gtk_theme}"], capture_output=True)
    except Exception:
        pass

    # 5. Broadcast dconf update
    try:
        subprocess.run(["dconf", "write", "/org/gnome/desktop/interface/gtk-theme", f"'{gtk_theme}'"], capture_output=True)
        subprocess.run(["dconf", "write", "/org/gnome/desktop/interface/color-scheme", "'prefer-dark'"], capture_output=True)
    except Exception:
        pass

def main():
    theme_key = sys.argv[1] if len(sys.argv) > 1 else "deepspace"
    apply_theme(theme_key)

if __name__ == "__main__":
    main()
