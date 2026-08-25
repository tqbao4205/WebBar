#!/bin/bash
set -e

APP_NAME="WebBar"
VOLUME_NAME="WebBar Installer"
DMG_FINAL="$APP_NAME-Installer.dmg"
DMG_TEMP="dmg_temp.dmg"

echo "🧹 Cleaning previous builds..."
rm -rf "$DMG_TEMP" "$DMG_FINAL"
hdiutil detach "/Volumes/$VOLUME_NAME" 2>/dev/null || true

echo "🔨 Building Release App..."
./build.sh

echo "📦 Creating master DMG image..."
hdiutil create -size 80m -volname "$VOLUME_NAME" -fs HFS+ -ov "$DMG_TEMP"

echo "💿 Mounting DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 1

MOUNT_DIR="/Volumes/$VOLUME_NAME"

echo "📁 Copying application and resources..."
cp -R "$APP_NAME.app" "$MOUNT_DIR/"
ln -s /Applications "$MOUNT_DIR/Applications"
mkdir -p "$MOUNT_DIR/.background"
cp "Resources/dmg_background.png" "$MOUNT_DIR/.background/background.png"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$MOUNT_DIR/.VolumeIcon.icns"
    # Set volume icon attribute if SetFile is available
    if command -v SetFile &>/dev/null; then
        SetFile -a C "$MOUNT_DIR"
    fi
fi

echo "🎨 Styling Finder window with AppleScript..."
osascript << APPLESCRIPT || true
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 150, 1000, 550}
        
        set opts to the icon view options of container window
        set arrangement of opts to not arranged
        set icon size of opts to 108
        set background picture of opts to file ".background:background.png"
        
        delay 1
        set position of item "$APP_NAME.app" of container window to {160, 205}
        set position of item "Applications" of container window to {440, 205}
        
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Hide background folder
SetFile -a V "$MOUNT_DIR/.background" 2>/dev/null || true

echo "💾 Syncing and detaching DMG..."
sync
sleep 2
hdiutil detach "$DEVICE" -force || true
sleep 1

echo "🗜️ Compressing final DMG..."
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG_FINAL"
rm -f "$DMG_TEMP"

echo "🎉 Professional DMG created: $DMG_FINAL"
