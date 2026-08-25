#!/bin/bash
set -e

APP_NAME="WebBar"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building $APP_NAME for macOS (Release)..."
swift build -c release

echo "📦 Creating macOS App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"
chmod +x "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS_DIR/"

# Ad-hoc code signing for local macOS execution
echo "🔏 Code-signing application bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Build complete: $APP_BUNDLE created successfully!"

if [ "$1" == "--run" ] || [ "$1" == "-r" ]; then
    echo "🚀 Launching $APP_NAME..."
    open "$APP_BUNDLE"
fi
