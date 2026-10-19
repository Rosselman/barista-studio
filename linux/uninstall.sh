#!/usr/bin/env bash
set -e

APP_DIR="${HOME}/.local/share/barista_studio"
DESKTOP_FILE="${HOME}/.local/share/applications/barista_studio.desktop"
ICON_FILE="${HOME}/.local/share/icons/hicolor/512x512/apps/barista_studio.png"

echo "Uninstalling Barista Studio..."
rm -rf "${APP_DIR}"
rm -f "${DESKTOP_FILE}"
rm -f "${ICON_FILE}"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
fi

echo "Barista Studio uninstalled."
