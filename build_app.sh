#!/bin/bash

APP_NAME="Breathe"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Cleaning up old build..."
rm -rf "${APP_BUNDLE}"

echo "Creating App Bundle structure..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Compiling Swift files..."
swiftc -parse-as-library Sources/*.swift -o "${MACOS_DIR}/${APP_NAME}"

if [ $? -eq 0 ]; then
    echo "Copying Info.plist..."
    cp Info.plist "${CONTENTS_DIR}/"
    echo "Copying App Icon..."
    cp assets/AppIcon.icns "${RESOURCES_DIR}/"
    echo "Build complete: ${APP_BUNDLE}"
else
    echo "Build failed!"
    exit 1
fi
