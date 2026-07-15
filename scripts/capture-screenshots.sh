#!/bin/bash
# Capture App Store screenshots from the iOS Simulator (6.7" / iPhone 16 Pro Max).
# Usage: ./scripts/capture-screenshots.sh [simulator_udid]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$ROOT/docs/app-store/screenshots"
# iPhone 16 Pro Max — 6.7" display (required App Store size)
SIMULATOR="${1:-0B6B6BDD-0B90-4401-9D2C-5F3751A89FC7}"
BUNDLE_ID="com.germaind.CommonGround"
DERIVED="$ROOT/build/derived"

mkdir -p "$OUTPUT"

echo "Building Common Ground (Debug)..."
xcodebuild -scheme CommonGround \
  -destination "platform=iOS Simulator,id=$SIMULATOR" \
  -derivedDataPath "$DERIVED" \
  build > /dev/null

APP="$DERIVED/Build/Products/Debug-iphonesimulator/CommonGround.app"

echo "Booting simulator..."
xcrun simctl boot "$SIMULATOR" 2>/dev/null || true
xcrun simctl bootstatus "$SIMULATOR" -b

echo "Preparing simulator..."
xcrun simctl uninstall "$SIMULATOR" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl privacy "$SIMULATOR" reset all "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$SIMULATOR" "$APP"
xcrun simctl spawn "$SIMULATOR" defaults write "$BUNDLE_ID" debug.screenshotMode -bool true

capture_tab() {
  local name="$1"
  local tab="$2"
  local delay="${3:-3}"

  xcrun simctl terminate "$SIMULATOR" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$SIMULATOR" "$BUNDLE_ID" "-ScreenshotTab=$tab" > /dev/null
  sleep "$delay"
  xcrun simctl io "$SIMULATOR" screenshot "$OUTPUT/$name.png"
  echo "  ✓ $name.png"
}

echo "Capturing screenshots..."
capture_tab "01-home" "home" 4
capture_tab "02-calendar" "calendar" 2
capture_tab "03-children" "children" 2
capture_tab "04-messages" "messages" 2
capture_tab "05-more" "more" 2

echo ""
echo "Screenshots saved to $OUTPUT"
echo "Upload the 6.7\" set in App Store Connect → App Store → Screenshots."
echo "See docs/app-store/SUBMISSION.md for the full checklist."
