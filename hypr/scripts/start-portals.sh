#!/usr/bin/env bash
# Start xdg-desktop-portal backends and main portal for Hyprland
# (Hyprland doesn't activate graphical-session.target so we start manually)

export XDG_CURRENT_DESKTOP=Hyprland
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY}"

# Kill any stale portal instances
pkill -f xdg-desktop-portal-hyprland 2>/dev/null
pkill -f xdg-desktop-portal 2>/dev/null
sleep 0.5

# Start Hyprland portal backend first
/usr/libexec/xdg-desktop-portal-hyprland &

sleep 1

# Start the main portal
/usr/libexec/xdg-desktop-portal &

echo "Portals started"
