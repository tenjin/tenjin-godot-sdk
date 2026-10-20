#!/usr/bin/env bash
# Copies TenjinSDK.xcframework into the addon. Pass the path of an extracted
# xcframework (e.g. from a tenjin-ios-sdk release), or omit it to use a
# sibling checkout of tenjin-ios-sdk.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/../tenjin-ios-sdk/TenjinSDK.xcframework}"
DEST="$ROOT/addons/tenjin/bin/ios/TenjinSDK.xcframework"

if [[ ! -d "$SRC" ]]; then
  echo "TenjinSDK.xcframework not found at $SRC" >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
cp -R "$SRC" "$DEST"
echo "Copied $SRC -> $DEST"
