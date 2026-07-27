#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="$PROJECT_DIR/dist/NoSleep.app"
DMG_PATH="$PROJECT_DIR/dist/NoSleep-1.0.0.dmg"
STAGING_DIR="$PROJECT_DIR/.build/dmg/NoSleep"

if [[ "${NOSLEEP_SKIP_APP_BUILD:-0}" != "1" ]]; then
    "$PROJECT_DIR/Scripts/build-app.sh"
fi

[[ -d "$APP_PATH" ]] || {
    echo "NoSleep.app was not found. Run Scripts/build-app.sh first." >&2
    exit 1
}

codesign --verify --deep --strict "$APP_PATH"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

ditto "$APP_PATH" "$STAGING_DIR/NoSleep.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "NoSleep" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"

echo "DMG: $DMG_PATH"
