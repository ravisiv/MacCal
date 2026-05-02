#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MacCal"
BUNDLE_ID="com.ravis.MacCal"
MIN_MACOS="14.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUNDLE_PATH="$DIST_DIR/$APP_NAME.app"
PID_FILE="$DIST_DIR/$APP_NAME.pid"
BIN_DIR=""
EXECUTABLE_PATH=""

cd "$ROOT_DIR"

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  pkill -x "$APP_NAME" || true
fi

if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE")"
  if [[ -n "$OLD_PID" ]]; then
    kill "$OLD_PID" >/dev/null 2>&1 || true
  fi
  rm -f "$PID_FILE"
fi

swift build --disable-sandbox --cache-path ./.swiftpm-cache
BIN_DIR="$(swift build --disable-sandbox --cache-path ./.swiftpm-cache --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$APP_NAME"

rm -rf "$BUNDLE_PATH"
mkdir -p "$BUNDLE_PATH/Contents/MacOS" "$BUNDLE_PATH/Contents/Resources"
cp "$EXECUTABLE_PATH" "$BUNDLE_PATH/Contents/MacOS/$APP_NAME"
chmod +x "$BUNDLE_PATH/Contents/MacOS/$APP_NAME"
printf "APPL????" > "$BUNDLE_PATH/Contents/PkgInfo"

cat > "$BUNDLE_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 MacCal.</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_MACOS</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>MacCal shows your calendar events in the menu bar calendar.</string>
  <key>NSCalendarsUsageDescription</key>
  <string>MacCal shows your calendar events in the menu bar calendar.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - --entitlements "$ROOT_DIR/MacCal.entitlements" "$BUNDLE_PATH" >/dev/null

if /usr/bin/open -n "$BUNDLE_PATH"; then
  echo "Launched $BUNDLE_PATH"
else
  echo "Launch Services could not open the staged app in this sandbox; launching executable directly."
  nohup "$BUNDLE_PATH/Contents/MacOS/$APP_NAME" >/tmp/MacCal.log 2>&1 &
  echo "$!" > "$PID_FILE"
  echo "Launched $APP_NAME with pid $(cat "$PID_FILE")"
fi

if [[ "${1:-}" == "--verify" ]]; then
  sleep 1
  pgrep -x "$APP_NAME" >/dev/null
  echo "$APP_NAME is running."
fi
