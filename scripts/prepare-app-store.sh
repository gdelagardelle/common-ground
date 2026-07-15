#!/bin/bash
# One-shot App Store prep: screenshots + Release archive.
# Usage: ./scripts/prepare-app-store.sh [build_number]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_NUMBER="${1:-2}"

if [[ -f "$ROOT/.env.local" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/.env.local"
fi

TEAM="${DEVELOPMENT_TEAM:-3N4Q2GQ558}"

echo "==> Capturing 6.7\" screenshots"
"$ROOT/scripts/capture-screenshots.sh"

echo "==> Generating 6.5\" screenshot set (resized)"
RESIZED="$ROOT/docs/app-store/screenshots-6.5"
mkdir -p "$RESIZED"
for shot in "$ROOT"/docs/app-store/screenshots/*.png; do
  sips -z 2778 1284 "$shot" --out "$RESIZED/$(basename "$shot")" > /dev/null
  echo "  ✓ $(basename "$shot")"
done

echo "==> Regenerating Xcode project"
(cd "$ROOT" && xcodegen generate)

echo "==> Archiving build $BUILD_NUMBER"
xcodebuild \
  -scheme CommonGround \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath "$ROOT/build/CommonGround.xcarchive" \
  MARKETING_VERSION=1.0.0 \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  DEVELOPMENT_TEAM="$TEAM" \
  clean archive

echo ""
echo "Archive ready: $ROOT/build/CommonGround.xcarchive"
echo ""
echo "Next steps:"
echo "  1. Xcode → Window → Organizer → Distribute App → App Store Connect"
echo "  OR: ./scripts/upload-testflight.sh $BUILD_NUMBER  (requires .env.local API key)"
echo "  2. App Store Connect → paste docs from docs/app-store/"
echo "     - metadata.md (description)"
echo "     - review-notes.txt (App Review)"
echo "     - testflight-beta-notes.md (external beta)"
echo "     - app-privacy.md (privacy questionnaire)"
echo "  3. Upload screenshots from docs/app-store/screenshots/ (6.7\")"
echo "     Optional 6.5\": docs/app-store/screenshots-6.5/"
