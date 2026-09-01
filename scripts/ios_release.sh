#!/usr/bin/env bash
# Build a release IPA for TestFlight / App Store with the production API.
#
# Prerequisites:
#   - Xcode + CocoaPods (`cd ios && pod install`)
#   - Apple Distribution signing configured for com.sahajayoga.twentyOneDays
#   - Flutter stable on PATH
#
# Usage:
#   ./scripts/ios_release.sh
#   API_BASE_URL=https://custom.example.com ./scripts/ios_release.sh
#
# Output: build/ios/ipa/*.ipa — upload via Xcode Organizer or Transporter.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Production API (Cloud Run — direct; avoids custom-domain routing).
API_BASE_URL="${API_BASE_URL:-https://na21days-media-api-2g62ryauoq-uc.a.run.app}"

echo "==> 21Days iOS release build"
echo "    API_BASE_URL=$API_BASE_URL"
echo "    Version: $(grep '^version:' pubspec.yaml | awk '{print $2}')"
echo ""

flutter pub get

# Clean optional — uncomment if you hit stale iOS build issues.
# flutter clean && flutter pub get

flutter build ipa --release \
  --dart-define="API_BASE_URL=${API_BASE_URL}"

echo ""
echo "==> Done. IPA path:"
ls -1 build/ios/ipa/*.ipa 2>/dev/null || echo "    (check build/ios/archive for Xcode export)"
echo ""
echo "Next steps:"
echo "  1. Open build/ios/archive/Runner.xcarchive in Xcode Organizer, or upload the .ipa with Transporter."
echo "  2. In App Store Connect: Privacy Policy URL → https://www.explore21days.org/privacy"
echo "  3. Paste review notes from docs/APPLE_REVIEW.md"
echo "  4. See docs/APPLE_REVIEW.md for screenshots and checklist."
