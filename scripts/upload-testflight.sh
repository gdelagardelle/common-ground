#!/bin/bash
# Archive Common Ground and upload to TestFlight via App Store Connect API.
#
# Prerequisites:
#   1. App record created in App Store Connect (com.germaind.CommonGround)
#   2. API key: App Store Connect → Users and Access → Integrations → App Store Connect API
#   3. Environment variables (or .env.local in repo root, gitignored):
#        ASC_KEY_ID=XXXXXXXXXX
#        ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#        ASC_KEY_PATH=/path/to/AuthKey_XXXXXXXXXX.p8
#        DEVELOPMENT_TEAM=XXXXXXXXXX
#
# Usage:
#   ./scripts/upload-testflight.sh [build_number]
#
# Example:
#   DEVELOPMENT_TEAM=ABC123 ./scripts/upload-testflight.sh 2

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/CommonGround.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_PLIST="$ROOT/ExportOptions.plist"
SCHEME="CommonGround"
BUILD_NUMBER="${1:-$(date +%Y%m%d%H%M)}"

# Load optional local secrets
if [[ -f "$ROOT/.env.local" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/.env.local"
fi

: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM (Xcode team ID)}"
: "${ASC_KEY_ID:?Set ASC_KEY_ID (App Store Connect API key ID)}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID (App Store Connect issuer ID)}"
: "${ASC_KEY_PATH:?Set ASC_KEY_PATH (path to .p8 API key)}"

if [[ ! -f "$ASC_KEY_PATH" ]]; then
  echo "error: API key not found at $ASC_KEY_PATH" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"

echo "==> Regenerating Xcode project"
(cd "$ROOT" && xcodegen generate)

echo "==> Archiving (build $BUILD_NUMBER)"
xcodebuild \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION=1.0.0 \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  clean archive

echo "==> Exporting IPA"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"

IPA=$(find "$EXPORT_PATH" -name '*.ipa' | head -1)
if [[ -z "$IPA" ]]; then
  echo "error: No IPA found in $EXPORT_PATH" >&2
  exit 1
fi

echo "==> Uploading to App Store Connect: $IPA"
xcrun altool \
  --upload-app \
  --type ios \
  --file "$IPA" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"

echo ""
echo "Upload complete. Processing usually takes 5–15 minutes."
echo "Open App Store Connect → TestFlight to add testers."
echo "Build number: $BUILD_NUMBER"
