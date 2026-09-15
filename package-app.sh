#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PRODUCT="CaptureToIssue"
cd "$ROOT"
swift build -c release --product "$PRODUCT"
BIN="$(swift build -c release --product "$PRODUCT" --show-bin-path)/$PRODUCT"
APP="$ROOT/dist/$PRODUCT.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$PRODUCT"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
if [ -f "$ROOT/Assets/AppIcon.icns" ]; then
  cp "$ROOT/Assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi
/usr/bin/codesign -s - --force --deep "$APP"
echo "$APP"
