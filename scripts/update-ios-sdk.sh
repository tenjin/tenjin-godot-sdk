#!/usr/bin/env bash
# Downloads TenjinSDK.xcframework from the tenjin-ios-sdk GitHub release into
# the addon, checking it against the pinned SHA-256. Pass the path of an
# extracted xcframework instead to use a local build.
#
# To bump the iOS SDK, change both values below.
set -euo pipefail

TENJIN_IOS_SDK_VERSION="1.20.1"
TENJIN_IOS_SDK_SHA256="4568c042705df3efb5eaf869a4e64f39fa1664e6b03552f25dde7c88ca2923a2"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/addons/tenjin/bin/ios/TenjinSDK.xcframework"

rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"

if [[ $# -gt 0 ]]; then
  if [[ ! -d "$1" ]]; then
    echo "TenjinSDK.xcframework not found at $1" >&2
    exit 1
  fi
  cp -R "$1" "$DEST"
  echo "Copied $1 -> $DEST"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
URL="https://github.com/tenjin/tenjin-ios-sdk/releases/download/$TENJIN_IOS_SDK_VERSION/TenjinSDK.xcframework.zip"
curl -fsSL -o "$TMP/sdk.zip" "$URL"
echo "$TENJIN_IOS_SDK_SHA256  $TMP/sdk.zip" | shasum -a 256 -c - >/dev/null
unzip -q "$TMP/sdk.zip" -d "$TMP/sdk"
mv "$TMP/sdk/TenjinSDK.xcframework" "$DEST"
echo "Downloaded TenjinSDK $TENJIN_IOS_SDK_VERSION -> $DEST"
