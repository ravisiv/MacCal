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
ICON_BUNDLE_ICNS="$DIST_DIR/icons/MacCal.icns"

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

if [[ ! -f "$ICON_BUNDLE_ICNS" ]]; then
  "$ROOT_DIR/script/create_icon_bundle.sh"
fi

if cp "$ICON_BUNDLE_ICNS" "$ICON_PATH"; then
  ICON_CREATED="true"
else
  ICON_CREATED="false"
  echo "Warning: could not copy AppIcon.icns; continuing without a bundle icon."
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
