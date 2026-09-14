#!/usr/bin/env bash
# Build a release Android App Bundle for Play Console with the production API.
#
# Prerequisites:
#   1. Upload keystore created (see android/key.properties.example)
#   2. android/key.properties filled in (gitignored)
#   3. Flutter stable on PATH
#
# Usage:
#   ./scripts/android_release.sh
#   API_BASE_URL=https://custom.example.com ./scripts/android_release.sh
#
# Output: build/app/outputs/bundle/release/app-release.aab

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

API_BASE_URL="${API_BASE_URL:-https://na21days-media-api-2g62ryauoq-uc.a.run.app}"
KEY_PROPS="$ROOT/android/key.properties"

echo "==> 21Days Android release build"
echo "    API_BASE_URL=$API_BASE_URL"
echo "    Version: $(grep '^version:' pubspec.yaml | awk '{print $2}')"
echo ""

if [[ ! -f "$KEY_PROPS" ]]; then
  echo "ERROR: Missing $KEY_PROPS"
  echo "Copy android/key.properties.example → android/key.properties and fill in"
  echo "storePassword, keyPassword, keyAlias, and storeFile."
  echo "See docs/PLAY_STORE.md step 3."
  exit 1
fi

flutter pub get

flutter build appbundle --release \
  --dart-define="API_BASE_URL=${API_BASE_URL}"

echo ""
echo "==> Done. AAB path:"
ls -1 build/app/outputs/bundle/release/*.aab 2>/dev/null || echo "    (check build/app/outputs/bundle/release/)"
echo ""
echo "Next steps: upload the .aab to Play Console → Internal testing, then Production."
echo "See docs/PLAY_STORE.md"
