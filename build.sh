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

# Copy Info.plist and Resources
cp "Resources/Info.plist" "$CONTENTS_DIR/"
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/"
fi

# Ad-hoc code signing for local macOS execution
echo "🔏 Code-signing application bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Build complete: $APP_BUNDLE created successfully!"

if [ "$1" == "--dmg" ]; then
    echo "💿 Creating macOS DMG Installer..."
    rm -rf "dmg_temp" "$APP_NAME-Installer.dmg"
    mkdir -p "dmg_temp"
    cp -R "$APP_BUNDLE" "dmg_temp/"
    ln -s /Applications "dmg_temp/Applications"
    hdiutil create -volname "$APP_NAME Installer" -srcfolder "dmg_temp" -ov -format UDZO "$APP_NAME-Installer.dmg"
    rm -rf "dmg_temp"
    echo "🎉 DMG Installer created: $APP_NAME-Installer.dmg"
fi

if [ "$1" == "--install" ]; then
    echo "📥 Installing $APP_NAME into /Applications..."
    killall WebBar 2>/dev/null || true
    rm -rf "/Applications/$APP_BUNDLE"
    cp -R "$APP_BUNDLE" "/Applications/"
    echo "🎉 Successfully installed $APP_NAME to /Applications/$APP_BUNDLE!"
    open "/Applications/$APP_BUNDLE"
fi

if [ "$1" == "--run" ] || [ "$1" == "-r" ]; then
    echo "🚀 Launching $APP_NAME..."
    open "$APP_BUNDLE"
fi
