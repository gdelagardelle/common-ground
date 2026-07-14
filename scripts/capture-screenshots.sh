#!/bin/bash
# Capture App Store screenshots from the iOS Simulator.
# Usage: ./scripts/capture-screenshots.sh [simulator_udid]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$ROOT/docs/app-store/screenshots"
SIMULATOR="${1:-02F3B1B5-1A64-4BC9-BA3F-0B72A5CA3735}"
BUNDLE_ID="com.germaind.CommonGround"
DERIVED="$ROOT/build/derived"

mkdir -p "$OUTPUT"

echo "Building Common Ground..."
xcodebuild -scheme CommonGround \
  -destination "platform=iOS Simulator,id=$SIMULATOR" \
  -derivedDataPath "$DERIVED" \
  build > /dev/null

APP="$DERIVED/Build/Products/Debug-iphonesimulator/CommonGround.app"

echo "Booting simulator..."
xcrun simctl boot "$SIMULATOR" 2>/dev/null || true
xcrun simctl bootstatus "$SIMULATOR" -b

echo "Installing app..."
xcrun simctl install "$SIMULATOR" "$APP"

capture() {
  local name="$1"
  local delay="${2:-2}"
  sleep "$delay"
  xcrun simctl io "$SIMULATOR" screenshot "$OUTPUT/$name.png"
  echo "  ✓ $name.png"
}

echo "Launching app..."
xcrun simctl launch "$SIMULATOR" "$BUNDLE_ID" > /dev/null

capture "01-home" 3
capture "02-calendar" 1
capture "03-children" 1
capture "04-messages" 1
capture "05-more" 1

echo ""
echo "Screenshots saved to $OUTPUT"
echo "Open the app manually to capture feature-specific screens (AI, Medical, Expenses)."
