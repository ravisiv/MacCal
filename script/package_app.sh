#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MacCal"
BUNDLE_ID="com.ravis.MacCal"
VERSION="0.1.0"
BUILD_NUMBER="1"
MIN_MACOS="14.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUNDLE_PATH="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"
BIN_DIR=""
EXECUTABLE_PATH=""
ICONSET_DIR="$DIST_DIR/MacCal.iconset"
ICON_PNG="$DIST_DIR/MacCalIcon-1024.png"
ICON_PATH="$BUNDLE_PATH/Contents/Resources/AppIcon.icns"

cd "$ROOT_DIR"

swift build -c release --disable-sandbox --cache-path ./.swiftpm-cache
BIN_DIR="$(swift build -c release --disable-sandbox --cache-path ./.swiftpm-cache --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$APP_NAME"

find "$DIST_DIR" -maxdepth 1 -type d -name "$APP_NAME*.app" -exec rm -rf {} +
rm -rf "$ICONSET_DIR" "$ICON_PNG" "$ZIP_PATH"
mkdir -p "$BUNDLE_PATH/Contents/MacOS" "$BUNDLE_PATH/Contents/Resources"

cp "$EXECUTABLE_PATH" "$BUNDLE_PATH/Contents/MacOS/$APP_NAME"
chmod +x "$BUNDLE_PATH/Contents/MacOS/$APP_NAME"
printf "APPL????" > "$BUNDLE_PATH/Contents/PkgInfo"

/usr/bin/swift "$ROOT_DIR/script/render_icon.swift" "$ICON_PNG"
sips -z 1024 1024 "$ICON_PNG" --out "$DIST_DIR/MacCalIcon-1024-normalized.png" >/dev/null
cp "$DIST_DIR/MacCalIcon-1024-normalized.png" "$ICON_PNG"
mkdir -p "$ICONSET_DIR"
sips -z 16 16 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$ICON_PNG" "$ICONSET_DIR/icon_512x512@2x.png"
if iconutil -c icns "$ICONSET_DIR" -o "$ICON_PATH"; then
  ICON_CREATED="true"
else
  ICON_CREATED="false"
  echo "Warning: iconutil could not create AppIcon.icns; continuing without a bundle icon."
fi

/usr/libexec/PlistBuddy -c "Clear dict" "$BUNDLE_PATH/Contents/Info.plist" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP_NAME" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string en" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string $MIN_MACOS" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSPrincipalClass string NSApplication" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSSupportsAutomaticGraphicsSwitching bool true" "$BUNDLE_PATH/Contents/Info.plist"
if [[ "$ICON_CREATED" == "true" ]]; then
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$BUNDLE_PATH/Contents/Info.plist"
fi
/usr/libexec/PlistBuddy -c "Add :LSApplicationCategoryType string public.app-category.productivity" "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSHumanReadableCopyright string Copyright © 2026 MacCal." "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSCalendarsFullAccessUsageDescription string MacCal shows your calendar events in the menu bar calendar." "$BUNDLE_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSCalendarsUsageDescription string MacCal shows your calendar events in the menu bar calendar." "$BUNDLE_PATH/Contents/Info.plist"

codesign --force --deep --sign - --entitlements "$ROOT_DIR/MacCal.entitlements" "$BUNDLE_PATH" >/dev/null
codesign --verify --deep --strict --verbose=2 "$BUNDLE_PATH"

ditto -c -k --keepParent "$BUNDLE_PATH" "$ZIP_PATH"

echo "Packaged $BUNDLE_PATH"
echo "Created $ZIP_PATH"
