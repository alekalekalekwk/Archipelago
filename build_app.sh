#!/bin/bash
set -e

APP_NAME="DynamicIsland"
APP_DIR="${APP_NAME}.app"

swift build -c release

rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp ".build/release/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_DIR}/Contents/Info.plist"

codesign --force --sign - "${APP_DIR}"

echo "Build bundle completed: ${APP_DIR}"
