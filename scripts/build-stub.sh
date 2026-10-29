#!/usr/bin/env bash
# Builds the no-op GDExtension stub for a desktop platform (macos, linux or
# windows) into addons/tenjin/bin/<platform>. The stub registers nothing; it
# only lets that platform's editor and desktop exports load tenjin.gdextension
# without a "No GDExtension library found" error.
#
# Requires: scons and a C++ toolchain (Xcode, GCC/Clang or MSVC).
set -euo pipefail

PLATFORM="${1:?usage: build-stub.sh macos|linux|windows}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IOS="$ROOT/ios"
GODOT_CPP_BRANCH="${GODOT_CPP_BRANCH:-4.3}"

if [[ ! -d "$IOS/godot-cpp" ]]; then
  git clone --depth 1 --branch "$GODOT_CPP_BRANCH" https://github.com/godotengine/godot-cpp.git "$IOS/godot-cpp"
fi

case "$PLATFORM" in
  macos) ARCH=universal ;;
  linux | windows) ARCH=x86_64 ;;
  *) echo "Unsupported platform: $PLATFORM" >&2; exit 1 ;;
esac

# One debug build serves the editor and both export templates.
cd "$IOS"
scons -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)" platform="$PLATFORM" arch="$ARCH" target=template_debug
# MSVC leaves the import library and exports file next to the DLL; nothing
# loads them, so they stay out of the addon.
rm -f "$ROOT/addons/tenjin/bin/$PLATFORM/"*.lib "$ROOT/addons/tenjin/bin/$PLATFORM/"*.exp
echo "Built $PLATFORM stub into $ROOT/addons/tenjin/bin/$PLATFORM"
