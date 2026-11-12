-- ==============================================================================
-- Hyprland Lua Configuration for Fedora with Quickshell (Antigravity)
-- Migrated to modern Lua config manager (compatible with Hyprland 0.56+)
-- ==============================================================================

------------------
---- MONITORS ----
------------------
-- Left (Main External Monitor - Samsung 27" @ 100Hz):
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@100",
    position = "0x0",
    scale    = 1,
})

-- Middle / Right (Integrated Laptop Display @ 60Hz):
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60.06",
    position = "1920x0",
    scale    = 1,
})

-- Fallback for any newly connected display:
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-------------------------
---- WORKSPACE RULES ----
-------------------------
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1" })

hl.workspace_rule({ workspace = "6", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "7", monitor = "eDP-1", layout = "scrolling" })
hl.workspace_rule({ workspace = "8", monitor = "eDP-1", layout = "scrolling" })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1" })

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", "/home/alvin/.local/state/quickshell/venv")
hl.env("qsConfig", "antigravity")
hl.env("GTK_THEME", "Adwaita-dark")

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprlock")
    hl.exec_cmd("~/.config/hypr/scripts/launch-shell.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY")
    hl.exec_cmd("~/.config/hypr/scripts/start-portals.sh")
    hl.exec_cmd("easyeffects --gapplication-service")
    hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"')
    hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')
    hl.exec_cmd("kitty --class kitty-scratchpad --title 'Antigravity Scratchpad'")
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(ffaa00ee)", "rgba(ffc533ee)"}, angle = 45 },
            inactive_border = "rgba(171f2eaa)",
        },
        layout = "dwindle",
        allow_tearing = false,
    },

    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 0.92,
        dim_inactive = true,
        dim_strength = 0.28,

        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            new_optimizations = true,
            xray = false,
        },

        shadow = {
            enabled = true,
            range = 28,
            render_power = 4,
            color = "rgba(ffaa0044)",
            color_inactive = "rgba(00000044)",
        },
    },

    dwindle = {
        preserve_split = true,
    },

    scrolling = {
        column_width = 0.5,
        direction = "right",
        focus_fit_method = 1,
        follow_focus = 1,
        wrap_focus = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = false,
        disable_hyprland_guiutils_check = true,
        session_lock_xray = true,
    },

    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },

    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_direction_lock = true,
    },
})

---------------------------------
---- TRACKPAD GESTURES ----------
---------------------------------
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

---------------------------------
---- ANIMATIONS & BEZIERS -------
---------------------------------
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",     enabled = true, speed = 6,   bezier = "default" })
hl.animation({ leaf = "border",     enabled = true, speed = 5,   bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",    enabled = true, speed = 4.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,   bezier = "easeOutQuint", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "popin 80%" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 3.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 3.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 4,   bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4,   bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4,   bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })

----------------------
---- WINDOW RULES ----
----------------------
-- Universal Dropdown Scratchpad
hl.window_rule({
    name = "kitty-scratchpad",
    match = { class = "kitty-scratchpad" },
    float = true,
    size = "75% 60%",
    move = "12.5% 52",
    workspace = "special:scratchpad",
    rounding = 16,
})

-- Quickshell Compositor Blur Rules (Panels, Dialogs & Modals only; TopBar remains pure transparent)
hl.layer_rule({
    blur = true,
    match = { namespace = "quickshell:(launcher|session|antigravity:hud|clipboard|wallpapertheme|docker|runner|windowswitcher|whatsapp|systemmonitor|controlcenter|osd|omnibar|notifications)" }
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Core Applications
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd("~/.config/hypr/scripts/scratchpad.sh"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("google-chrome || brave-browser || chromium"))
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("btop"))

-- Quickshell & Launcher Overlays
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("qs -c antigravity ipc call search toggle"), { release = true })
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("qs -c antigravity ipc call search toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs -c antigravity ipc call docker toggle"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("qs -c antigravity ipc call runner toggle"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("qs -c antigravity ipc call session toggle"))
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("qs -c antigravity ipc call windowSwitcher toggle"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs -c antigravity ipc call search toggle"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("qs -c antigravity ipc call omnibar toggle"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("qs -c antigravity ipc call pie toggle"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs -c antigravity ipc call antigravity toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c antigravity ipc call antigravity toggle"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("qs -c antigravity ipc call session toggle"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs -c antigravity ipc call clipboard toggle"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs -c antigravity ipc call wallpaperTheme toggle"))
hl.bind(mainMod .. " + Period", hl.dsp.exec_cmd("qs -c antigravity ipc call search toggle"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("qs -c antigravity ipc call antigravity toggle"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("qs -c antigravity ipc call liteMode toggle"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("qs -c antigravity ipc call systemMonitor toggle"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/launch-shell.sh"))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +'%Y-%m-%d-%H%M%S').png"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("grim ~/Pictures/screenshot-$(date +'%Y-%m-%d-%H%M%S').png"))

-- Window Actions
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Scrolling Layout Controls (PaperWM Ribbon - Workspaces 7 & 8)
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + bracketleft",  hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -conf"))
hl.bind(mainMod .. " + O", hl.dsp.layout("promote"))

-- Focus Movement
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspace Switching & Moving (1-9)
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
end

-- Multimedia & Hardware Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"),                       { locked = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"),                             { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"),                         { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl set 5%+"),                      { repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl set 5%-"),                      { repeating = true })

-- Mouse Binds
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
