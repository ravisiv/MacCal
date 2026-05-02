#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${1:-$ROOT_DIR/dist/MacCal.app}"
ZIP_PATH="$ROOT_DIR/dist/MacCal-0.1.0.zip"
PLIST="$APP_PATH/Contents/Info.plist"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Missing app bundle: $APP_PATH" >&2
  exit 1
fi

if [[ ! -x "$APP_PATH/Contents/MacOS/MacCal" ]]; then
  echo "Missing executable: $APP_PATH/Contents/MacOS/MacCal" >&2
  exit 1
fi

/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PLIST" >/dev/null
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST" >/dev/null
/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$PLIST" >/dev/null
/usr/libexec/PlistBuddy -c "Print :NSCalendarsFullAccessUsageDescription" "$PLIST" >/dev/null

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -d --entitlements :- "$APP_PATH" >/dev/null

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Missing zip archive: $ZIP_PATH" >&2
  exit 1
fi

echo "Package validation passed for $APP_PATH"
