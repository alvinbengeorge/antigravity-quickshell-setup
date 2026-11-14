#!/usr/bin/env bash
# ==============================================================================
#  ✦ ANTIGRAVITY QUICKSHELL DESKTOP INSTALLER
#  Universal Setup, Dependency Resolver & Native Engine Compiler
# ==============================================================================

set -eo pipefail

# ── Color Palette & Formatting ────────────────────────────────────────────────
if [[ -t 1 ]]; then
    BOLD="\033[1m"
    DIM="\033[2m"
    ITALIC="\033[3m"
    RESET="\033[0m"

    # 24-bit TrueColor / 256-color fallback
    CYAN="\033[38;2;64;224;208m"
    PURPLE="\033[38;2;180;120;255m"
    GOLD="\033[38;2;255;191;0m"
    GREEN="\033[38;2;80;250;123m"
    RED="\033[38;2;255;85;85m"
    BLUE="\033[38;2;139;233;253m"
    GRAY="\033[38;2;120;120;140m"
else
    BOLD=""
    DIM=""
    ITALIC=""
    RESET=""
    CYAN=""
    PURPLE=""
    GOLD=""
    GREEN=""
    RED=""
    BLUE=""
    GRAY=""
fi

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
RUST_DIR="$ROOT_DIR/rust"
BIN_DIR="$ROOT_DIR/bin"
TARGET_LINK="$HOME/.config/quickshell/antigravity"
STATE_DIR="$HOME/.local/state/quickshell/user"

AUTO_YES=false
SKIP_RUST=false
SKIP_PKGS=false

# ── Helper Functions ──────────────────────────────────────────────────────────
print_banner() {
    clear 2>/dev/null || true
    echo -e "${PURPLE}"
    cat << "EOF"
    ┌──────────────────────────────────────────────────────────────┐
    │                                                              │
    │     ✦   A N T I G R A V I T Y   Q U I C K S H E L L   ✦     │
    │         Fluid Wayland Desktop Environment & AI Shell         │
    │                                                              │
    └──────────────────────────────────────────────────────────────┘
EOF
    echo -e "${RESET}"
    echo -e "  ${GRAY}Target Repository:${RESET} ${BOLD}${ROOT_DIR}${RESET}"
    echo -e "  ${GRAY}System Date:${RESET}       ${DIM}$(date -R)${RESET}"
    echo
}

step_header() {
    local num="$1"
    local title="$2"
    echo -e "\n${BOLD}${CYAN}━━━ [Step ${num}] ${title} ${RESET}"
}

status_ok() {
    local msg="$1"
    echo -e "  ${GREEN}✔${RESET} ${msg}"
}

status_skip() {
    local msg="$1"
    echo -e "  ${BLUE}↷${RESET} ${msg}"
}

status_warn() {
    local msg="$1"
    echo -e "  ${GOLD}⚠${RESET} ${msg}"
}

status_fail() {
    local msg="$1"
    echo -e "  ${RED}✖${RESET} ${msg}"
}

status_info() {
    local msg="$1"
    echo -e "  ${GRAY}ℹ${RESET} ${msg}"
}

confirm() {
    local prompt="$1"
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi
    echo -ne "  ${GOLD}?${RESET} ${BOLD}${prompt}${RESET} [Y/n]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]|"") return 0 ;;
        *) return 1 ;;
    esac
}

# ── Parse Arguments ───────────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        -y|--yes) AUTO_YES=true ;;
        --skip-rust) SKIP_RUST=true ;;
        --skip-pkgs) SKIP_PKGS=true ;;
        -h|--help)
            echo "Usage: ./install.sh [OPTIONS]"
            echo
            echo "Options:"
            echo "  -y, --yes        Automatically accept all confirmation prompts"
            echo "  --skip-rust      Skip native Rust engine compilation"
            echo "  --skip-pkgs      Skip system package manager checks"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
    esac
done

# ── Main Installer Logic ──────────────────────────────────────────────────────
print_banner

# Step 0: User Sanity Check
if [ "$(id -u)" -eq 0 ]; then
    status_fail "Please run this installer as a normal user, not as root (sudo privileges will be asked when needed)."
    exit 1
fi

# ── 1. OS & Distribution Detection ───────────────────────────────────────────
step_header "1" "Detecting Host Operating System & Tooling"

OS_NAME="unknown"
PKG_MGR="unknown"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$ID"
    OS_PRETTY="$PRETTY_NAME"
fi

status_info "Detected OS: ${BOLD}${OS_PRETTY:-$OS_NAME}${RESET}"

if command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
elif command -v pacman &>/dev/null; then
    PKG_MGR="pacman"
elif command -v apt-get &>/dev/null; then
    PKG_MGR="apt"
fi

status_info "Detected Package Manager: ${BOLD}${PKG_MGR}${RESET}"

# ── 2. System Package Dependencies ────────────────────────────────────────────
step_header "2" "Verifying System Dependencies"

if [ "$SKIP_PKGS" = true ]; then
    status_skip "Skipping package checks (--skip-pkgs passed)."
else
    MISSING_PKGS=()
    
    # Generic command-to-package mapping check
    check_cmd() {
        local cmd="$1"
        local pkg_name="$2"
        if ! command -v "$cmd" &>/dev/null; then
            MISSING_PKGS+=("$pkg_name")
        fi
    }

    check_cmd "hyprland" "hyprland"
    check_cmd "kitty" "kitty"
    check_cmd "playerctl" "playerctl"
    check_cmd "grim" "grim"
    check_cmd "slurp" "slurp"
    check_cmd "upower" "upower"
    check_cmd "cliphist" "cliphist"
    check_cmd "wl-copy" "wl-clipboard"
    check_cmd "parec" "pulseaudio-utils / pipewire-pulse"
    check_cmd "pactl" "pulseaudio-utils / pipewire-utils"
    check_cmd "qs" "quickshell"

    if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
        status_ok "All primary core dependencies are installed!"
    else
        status_warn "Missing tools: ${MISSING_PKGS[*]}"
        if [ "$PKG_MGR" = "dnf" ]; then
            if confirm "Would you like to install missing dependencies via dnf now?"; then
                # Enable COPR for quickshell on Fedora if not already installed
                if ! command -v qs &>/dev/null; then
                    status_info "Enabling lionheartp/Hyprland COPR repository for Quickshell..."
                    sudo dnf copr enable -y lionheartp/Hyprland || true
                fi
                sudo dnf install -y quickshell hyprland kitty playerctl grim slurp upower \
                                    pipewire-utils pulseaudio-utils libnotify \
                                    python3-dbus cliphist wl-clipboard \
                                    gsettings-desktop-schemas || true
            fi
        elif [ "$PKG_MGR" = "pacman" ]; then
            if confirm "Would you like to install missing dependencies via pacman now?"; then
                sudo pacman -S --needed --noconfirm hyprland kitty playerctl grim slurp upower \
                                                   pipewire-pulse \
                                                   python-dbus libnotify cliphist wl-clipboard || true
            fi
        else
            status_info "Please install missing packages manually: ${MISSING_PKGS[*]}"
        fi
    fi
fi

# ── 3. Symlink Quickshell Configuration ────────────────────────────────────────
step_header "3" "Configuring Quickshell Path (~/.config/quickshell/antigravity)"

mkdir -p "$HOME/.config/quickshell"

if [ -L "$TARGET_LINK" ]; then
    CURRENT_DEST="$(readlink -f "$TARGET_LINK" || true)"
    if [ "$CURRENT_DEST" = "$ROOT_DIR" ]; then
        status_ok "Symlink already points to this workspace: ${DIM}${TARGET_LINK}${RESET}"
    else
        status_warn "Existing symlink points elsewhere (${CURRENT_DEST})."
        if confirm "Update symlink to point to current directory (${ROOT_DIR})?"; then
            rm -f "$TARGET_LINK"
            ln -s "$ROOT_DIR" "$TARGET_LINK"
            status_ok "Symlink updated: ${BOLD}${TARGET_LINK} -> ${ROOT_DIR}${RESET}"
        fi
    fi
elif [ -e "$TARGET_LINK" ]; then
    status_warn "A regular file or directory exists at ${TARGET_LINK}."
    if confirm "Backup existing directory and link ${ROOT_DIR}?"; then
        mv "$TARGET_LINK" "${TARGET_LINK}.backup.$(date +%s)"
        ln -s "$ROOT_DIR" "$TARGET_LINK"
        status_ok "Symlink created: ${BOLD}${TARGET_LINK} -> ${ROOT_DIR}${RESET}"
    fi
else
    ln -s "$ROOT_DIR" "$TARGET_LINK"
    status_ok "Symlink created: ${BOLD}${TARGET_LINK} -> ${ROOT_DIR}${RESET}"
fi

# ── 4. State & Cache Directories ──────────────────────────────────────────────
step_header "4" "Ensuring State & Temporary Cache Directories"

mkdir -p "$STATE_DIR"
mkdir -p "/tmp/cliphist_cache"
chmod 700 "/tmp/cliphist_cache" 2>/dev/null || true
status_ok "User state directories initialized at ${DIM}${STATE_DIR}${RESET}"

# ── 5. Ensure Executable Permissions ──────────────────────────────────────────
step_header "5" "Configuring Dispatch Executables & Scripts"

chmod +x "$ROOT_DIR"/bin/* 2>/dev/null || true
chmod +x "$ROOT_DIR"/scripts/*.sh 2>/dev/null || true
chmod +x "$ROOT_DIR"/scripts/*.py 2>/dev/null || true
status_ok "Executable permissions granted to bin/ dispatchers and helper scripts."

# ── 6. Native Rust Acceleration Engine Build ──────────────────────────────────
step_header "6" "Compiling Native Rust Acceleration Engine (agy-tools)"

if [ "$SKIP_RUST" = true ]; then
    status_skip "Rust engine compilation skipped (--skip-rust passed)."
    status_info "Quickshell will seamlessly utilize the automatic Python fallbacks."
else
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env"
    fi

    if ! command -v cargo &>/dev/null; then
        status_warn "Rust toolchain (cargo) is not currently installed."
        if confirm "Install official minimal Rust toolchain via rustup now?"; then
            echo -e "  ${GRAY}Fetching rustup installer...${RESET}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal
            # shellcheck source=/dev/null
            source "$HOME/.cargo/env"
            status_ok "Rust toolchain installed successfully!"
        else
            status_skip "Skipping Rust installation. Desktop shell will run in automatic Python fallback mode."
        fi
    fi

    if command -v cargo &>/dev/null; then
        echo -e "  ${GRAY}Building agy-tools in release mode with Link-Time Optimization (LTO)...${RESET}"
        (cd "$RUST_DIR" && cargo build --release --bin agy-tools)
        
        if [ -x "$RUST_DIR/target/release/agy-tools" ]; then
            status_ok "Native multi-call engine compiled successfully! ($(du -h "$RUST_DIR/target/release/agy-tools" | awk '{print $1}'))"
            
            # Verify dispatch test
            TEST_OUT="$("$BIN_DIR/fast_system_stats" 2>/dev/null || true)"
            if [[ "$TEST_OUT" =~ "cpu" ]]; then
                status_ok "Engine self-test passed: ${DIM}${TEST_OUT}${RESET}"
            else
                status_warn "Engine self-test returned unexpected output; dispatchers will fallback if needed."
            fi
        else
            status_warn "Binary build did not produce target executable. Automatic Python fallback active."
        fi
    fi
fi

# ── 7. Hyprland Integration Check ─────────────────────────────────────────────
step_header "7" "Verifying Hyprland Compositor Integration"

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
HYPR_LUA="$HOME/.config/hypr/hyprland.lua"
FOUND_INTEGRATION=false

if [ -f "$HYPR_LUA" ]; then
    if grep -q "antigravity" "$HYPR_LUA"; then
        status_ok "Hyprland Lua configuration already contains Antigravity Quickshell bindings!"
        FOUND_INTEGRATION=true
    fi
fi

if [ -f "$HYPR_CONF" ]; then
    if grep -q "antigravity" "$HYPR_CONF"; then
        status_ok "Hyprland conf already contains Antigravity Quickshell autostart!"
        FOUND_INTEGRATION=true
    fi
fi

if [ "$FOUND_INTEGRATION" = false ]; then
    status_info "Tip: To autostart Quickshell on login, ensure your Hyprland config has:"
    echo -e "     ${BOLD}exec-once = qs -c antigravity${RESET}"
    echo -e "     ${DIM}(See README.md for full blur layer rules & recommended keybindings)${RESET}"
fi

# ── 8. Success Summary & Cheat Sheet ──────────────────────────────────────────
echo
echo -e "${GREEN}╭──────────────────────────────────────────────────────────────╮${RESET}"
echo -e "${GREEN}│${RESET}  ${BOLD}✦  A N T I G R A V I T Y   I S   R E A D Y !  ✦${RESET}            ${GREEN}│${RESET}"
echo -e "${GREEN}╰──────────────────────────────────────────────────────────────╯${RESET}"
echo
echo -e "  ${BOLD}Launch Quickshell manually:${RESET}"
echo -e "    ${CYAN}qs -c antigravity${RESET}"
echo
echo -e "  ${BOLD}Essential Desktop Shortcuts:${RESET}"
echo -e "    ${GOLD}Super + Space${RESET} / ${GOLD}Super + K${RESET}   Spotlight Omnibar & Universal Search"
echo -e "    ${GOLD}Super + A${RESET} / ${GOLD}Super + I${RESET}       Antigravity AI Agent HUD"
echo -e "    ${GOLD}Super + V${RESET}                   Visual Clipboard History"
echo -e "    ${GOLD}Super + Tab${RESET}                 macOS-style Window Switcher"
echo -e "    ${GOLD}Super + Shift + M${RESET}           System Resource Monitor (RAM/CPU/Swap)"
echo -e "    ${GOLD}Super + Shift + L${RESET}           Toggle Lite Mode (Zero-Overhead Gaming)"
echo
echo -e "  ${BOLD}CLI Subcommands (${CYAN}agy-tools${RESET}):"
echo -e "    ${DIM}fast_system_stats, system_monitor, cliphist_helper,${RESET}"
echo -e "    ${DIM}extract_media_color, audio_beat_tracker, docker_manager${RESET}"
echo

if confirm "Would you like to test-launch Quickshell now?"; then
    echo -e "  ${GRAY}Launching Quickshell in background...${RESET}"
    nohup qs -c antigravity >/dev/null 2>&1 &
    status_ok "Quickshell launched (PID: $!). Enjoy your new desktop shell!"
fi

echo -e "\n${BOLD}${PURPLE}✦ Setup completed successfully! ✦${RESET}\n"
