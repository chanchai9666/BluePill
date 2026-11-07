#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="BluePill"
APP_DIR="$PROJECT_ROOT/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Building $APP_NAME for release (arm64)..."
cd "$PROJECT_ROOT"
swift build -c release --arch arm64

RELEASE_BIN="$PROJECT_ROOT/.build/arm64-apple-macosx/release/$APP_NAME"
if [ ! -f "$RELEASE_BIN" ]; then
    # Fallback to general release path if arch path differs
    RELEASE_BIN="$PROJECT_ROOT/.build/release/$APP_NAME"
fi

if [ ! -f "$RELEASE_BIN" ]; then
    echo "Error: Binary not found at $RELEASE_BIN"
    exit 1
fi

echo "==> Packaging into $APP_NAME.app..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$RELEASE_BIN" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp "$PROJECT_ROOT/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "==> Signing $APP_NAME.app..."
codesign --force --deep --sign - "$APP_DIR"

echo "==> Successfully created $APP_NAME.app at $APP_DIR"
ls -la "$APP_DIR/Contents"
