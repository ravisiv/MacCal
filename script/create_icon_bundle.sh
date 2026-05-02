#!/usr/bin/env bash
set -euo pipefail

APP_NAME="MacCal"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
ICON_DIR="$DIST_DIR/icons"
ICONSET_DIR="$ICON_DIR/$APP_NAME.iconset"
SOURCE_PNG="$ICON_DIR/$APP_NAME-1024.png"
ICNS_PATH="$ICON_DIR/$APP_NAME.icns"
ZIP_PATH="$DIST_DIR/$APP_NAME-icons.zip"

cd "$ROOT_DIR"

rm -rf "$ICON_DIR" "$ZIP_PATH"
mkdir -p "$ICONSET_DIR"

/usr/bin/swift "$ROOT_DIR/script/render_icon.swift" "$SOURCE_PNG"

sips -z 16 16 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$SOURCE_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$SOURCE_PNG" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
ditto -c -k "$ICON_DIR" "$ZIP_PATH"

echo "Created icon source: $SOURCE_PNG"
echo "Created iconset: $ICONSET_DIR"
echo "Created icns: $ICNS_PATH"
echo "Created zip: $ZIP_PATH"
