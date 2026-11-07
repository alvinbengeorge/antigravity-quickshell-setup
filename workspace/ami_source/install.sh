#!/bin/bash
set -e

# ==============================================================================
# AskMeIdentity Plymouth Theme Installer
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: Please run this script with sudo:"
    echo "    sudo $0"
    exit 1
fi

THEME_NAME="askmeidentity"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
SRC_DIR="/tmp/askmeidentity-plymouth"

echo "[✦] Installing AskMeIdentity Plymouth Theme..."

if [ ! -d "$SRC_DIR" ]; then
    echo "[-] Source directory $SRC_DIR not found!"
    exit 1
fi

# 1. Install files
echo "[✦] Copying assets to ${THEME_DIR}..."
mkdir -p "$THEME_DIR"
cp -rf "${SRC_DIR}"/* "${THEME_DIR}/"

# 2. Set permissions
chmod 755 "$THEME_DIR"
chmod 644 "$THEME_DIR"/*

# 3. Verify files
echo "[✦] Verifying installed theme files..."
if [ ! -f "${THEME_DIR}/${THEME_NAME}.plymouth" ] || [ ! -f "${THEME_DIR}/${THEME_NAME}.script" ]; then
    echo "[-] Installation verification failed: missing theme definition."
    exit 1
fi

# 4. Set as default theme
echo "[✦] Setting ${THEME_NAME} as the default Plymouth theme..."
plymouth-set-default-theme "${THEME_NAME}"

ACTIVE=$(plymouth-set-default-theme)
if [ "$ACTIVE" != "$THEME_NAME" ]; then
    echo "[-] Failed to set default theme. Current: $ACTIVE"
    exit 1
fi
echo "[✦] Active Plymouth theme confirmed: $ACTIVE"

# 5. Rebuild initramfs
echo "[✦] Rebuilding initramfs with dracut (baking new theme into early boot)..."
dracut -f

echo ""
echo "=============================================================================="
echo " [✦] AskMeIdentity Plymouth Theme successfully installed!"
echo "=============================================================================="
echo " - Active Theme: ${THEME_NAME}"
echo " - Location:     ${THEME_DIR}"
echo " - Initramfs:    Updated with new theme assets"
echo ""
echo " Quick Switch Commands:"
echo "   Switch back to Antigravity Quantum Core: sudo plymouth-set-default-theme antigravity -R"
echo "   Switch back to AskMeIdentity:            sudo plymouth-set-default-theme askmeidentity -R"
echo "   Switch to stock Fedora theme:            sudo plymouth-set-default-theme bgrt -R"
echo "=============================================================================="
