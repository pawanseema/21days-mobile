#!/usr/bin/env bash
# Write this app's store version into the API config for one platform.
#
# Called after a successful iOS or Android release build. The next
# 21days-media-resources deploy publishes that version to phones.
#
# Usage: ./scripts/record_store_version.sh ios|android

set -euo pipefail

PLATFORM="${1:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${ROOT}/../21days-media-resources/scripts/gcp/config.env"

case "$PLATFORM" in
  ios) KEY=LATEST_IOS_VERSION ;;
  android) KEY=LATEST_ANDROID_VERSION ;;
  *)
    echo "Usage: $0 ios|android" >&2
    exit 1
    ;;
esac

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Missing $CONFIG" >&2
  echo "Copy scripts/gcp/config.env.example to config.env in 21days-media-resources." >&2
  exit 1
fi

RAW="$(grep '^version:' "$ROOT/pubspec.yaml" | awk '{print $2}')"
VERSION="${RAW%%+*}"
if [[ -z "$VERSION" ]]; then
  echo "ERROR: Could not read version from $ROOT/pubspec.yaml" >&2
  exit 1
fi

tmp="$(mktemp)"
if grep -qE "^${KEY}=" "$CONFIG"; then
  awk -v key="$KEY" -v value="$VERSION" '
    $0 ~ "^" key "=" { print key "=" value; next }
    { print }
  ' "$CONFIG" > "$tmp"
else
  cat "$CONFIG" > "$tmp"
  # command substitution drops a trailing newline, so a non-empty result
  # means the file does not already end with one.
  if [[ -n "$(tail -c 1 "$CONFIG")" ]]; then
    printf '\n' >> "$tmp"
  fi
  printf '%s=%s\n' "$KEY" "$VERSION" >> "$tmp"
fi
mv "$tmp" "$CONFIG"
echo "==> Set ${KEY}=${VERSION} in config.env"
