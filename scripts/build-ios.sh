#!/usr/bin/env bash
# Builds the iOS GDExtension (debug + release, device + simulator) and
# packages each target as an xcframework under addons/tenjin/bin/ios, plus
# the no-op macOS stub (scripts/build-stub.sh).
#
# Requires: Xcode, scons (pipx install scons), and godot-cpp checked out at
# ios/godot-cpp on the branch matching the minimum supported Godot version.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS="$ROOT/ios"
OUT="$ROOT/addons/tenjin/bin/ios"
GODOT_CPP_BRANCH="${GODOT_CPP_BRANCH:-4.3}"
JOBS="$(sysctl -n hw.ncpu)"

if [[ ! -d "$IOS/godot-cpp" ]]; then
  git clone --depth 1 --branch "$GODOT_CPP_BRANCH" https://github.com/godotengine/godot-cpp.git "$IOS/godot-cpp"
fi

if [[ ! -d "$OUT/TenjinSDK.xcframework" ]]; then
  "$ROOT/scripts/update-ios-sdk.sh"
fi

cd "$IOS"
for target in template_debug template_release; do
  scons -j"$JOBS" platform=ios arch=arm64 ios_simulator=no target="$target"
  scons -j"$JOBS" platform=ios arch=arm64 ios_simulator=yes target="$target"
  scons -j"$JOBS" platform=ios arch=x86_64 ios_simulator=yes target="$target"

  lipo -create \
    "build/libtenjin_godot.$target.simulator.arm64.a" \
    "build/libtenjin_godot.$target.simulator.x86_64.a" \
    -output "build/libtenjin_godot.$target.simulator.a"

  rm -rf "$OUT/libtenjin_godot.$target.xcframework"
  xcodebuild -create-xcframework \
    -library "build/libtenjin_godot.$target.device.arm64.a" \
    -library "build/libtenjin_godot.$target.simulator.a" \
    -output "$OUT/libtenjin_godot.$target.xcframework"
done

echo "Built iOS GDExtension libraries into $OUT"

"$ROOT/scripts/build-stub.sh" macos
