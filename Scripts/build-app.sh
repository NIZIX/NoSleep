#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_DIR="$PROJECT_DIR/dist/NoSleep.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$PROJECT_DIR/.build/NoSleep.iconset"
ICON_PATH="$PROJECT_DIR/.build/AppIcon.icns"

typeset -a ARCHITECTURES
typeset -a BUILT_BINARIES

if [[ -n "${NOSLEEP_ARCHITECTURE:-}" ]]; then
    case "$NOSLEEP_ARCHITECTURE" in
        arm64|x86_64)
            ARCHITECTURES=("$NOSLEEP_ARCHITECTURE")
            ;;
        *)
            echo "Unsupported architecture: $NOSLEEP_ARCHITECTURE" >&2
            exit 1
            ;;
    esac
else
    ARCHITECTURES=(arm64 x86_64)
fi

for ARCHITECTURE in "${ARCHITECTURES[@]}"; do
    TRIPLE="${ARCHITECTURE}-apple-macosx13.0"
    SCRATCH_PATH="$PROJECT_DIR/.build/$ARCHITECTURE"

    swift build \
        --package-path "$PROJECT_DIR" \
        --configuration "$CONFIGURATION" \
        --product NoSleep \
        --triple "$TRIPLE" \
        --scratch-path "$SCRATCH_PATH"

    BIN_DIR="$(swift build \
        --package-path "$PROJECT_DIR" \
        --configuration "$CONFIGURATION" \
        --product NoSleep \
        --triple "$TRIPLE" \
        --scratch-path "$SCRATCH_PATH" \
        --show-bin-path)"

    BUILT_BINARIES+=("$BIN_DIR/NoSleep")
done

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

if (( ${#BUILT_BINARIES[@]} == 1 )); then
    install -m 755 "${BUILT_BINARIES[1]}" "$MACOS_DIR/NoSleep"
else
    lipo -create "${BUILT_BINARIES[@]}" -output "$MACOS_DIR/NoSleep"
    chmod 755 "$MACOS_DIR/NoSleep"
fi

install -m 644 "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

render_icon() {
    local pixels="$1"
    local filename="$2"

    sips \
        --setProperty format png \
        --resampleHeightWidth "$pixels" "$pixels" \
        "$PROJECT_DIR/Resources/AppIcon.svg" \
        --out "$ICONSET_DIR/$filename" >/dev/null
}

render_icon 16 "icon_16x16.png"
render_icon 32 "icon_16x16@2x.png"
render_icon 32 "icon_32x32.png"
render_icon 64 "icon_32x32@2x.png"
render_icon 128 "icon_128x128.png"
render_icon 256 "icon_128x128@2x.png"
render_icon 256 "icon_256x256.png"
render_icon 512 "icon_256x256@2x.png"
render_icon 512 "icon_512x512.png"
render_icon 1024 "icon_512x512@2x.png"

iconutil --convert icns "$ICONSET_DIR" --output "$ICON_PATH"
install -m 644 "$ICON_PATH" "$RESOURCES_DIR/AppIcon.icns"

for LOCALIZATION_DIR in "$PROJECT_DIR"/Resources/*.lproj; do
    plutil -lint "$LOCALIZATION_DIR/Localizable.strings" >/dev/null
    ditto "$LOCALIZATION_DIR" "$RESOURCES_DIR/$(basename "$LOCALIZATION_DIR")"
done

codesign --force --sign - "$APP_DIR"

echo "App: $APP_DIR"
