#!/bin/bash

APP_NAME="Breathe"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
VOL_NAME="${APP_NAME}"

echo "Building the app first..."
./build_app.sh
if [ $? -ne 0 ]; then
    echo "Error: App build failed!"
    exit 1
fi

# Ensure the app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found."
    exit 1
fi

echo "Creating a temporary staging directory..."
STAGING_DIR=$(mktemp -d "/tmp/dmg_staging_XXXXXX")

echo "Copying $APP_BUNDLE to staging directory..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/"

echo "Creating Applications symlink..."
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating the DMG..."
rm -f "$DMG_NAME"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

echo "Cleaning up..."
rm -rf "$STAGING_DIR"

echo "Done! Generated $DMG_NAME"
echo "----------------------------------------"
echo "SHA256 Checksum for Homebrew Cask:"
shasum -a 256 "$DMG_NAME"
echo "----------------------------------------"
