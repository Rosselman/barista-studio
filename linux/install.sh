#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${HOME}/.local/share/barista_studio"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/512x512/apps"

echo "Installing Barista Studio..."
mkdir -p "${APP_DIR}"
mkdir -p "${DESKTOP_DIR}"
mkdir -p "${ICON_DIR}"

cp -r "${SCRIPT_DIR}/"* "${APP_DIR}/"

# Install icon
if [ -f "${APP_DIR}/data/barista_studio.png" ]; then
    cp "${APP_DIR}/data/barista_studio.png" "${ICON_DIR}/barista_studio.png"
elif [ -f "${APP_DIR}/barista_studio.png" ]; then
    cp "${APP_DIR}/barista_studio.png" "${ICON_DIR}/barista_studio.png"
fi

# Generate desktop launcher pointing to user application directory
cat <<EOF > "${DESKTOP_DIR}/barista_studio.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Barista Studio
GenericName=Recipe Maker & Studio
Comment=Flashing and managing custom recipes on the Nespresso Barista Recipe Maker W545
Exec=${APP_DIR}/barista_studio %u
Icon=${ICON_DIR}/barista_studio.png
Terminal=false
Categories=Utility;HardwareSettings;
StartupWMClass=barista_studio
Keywords=nespresso;barista;coffee;recipe;ble;bluetooth;w545;
EOF

chmod +x "${DESKTOP_DIR}/barista_studio.desktop"
chmod +x "${APP_DIR}/barista_studio"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "Barista Studio installed successfully! You can launch it from your desktop applications menu."
