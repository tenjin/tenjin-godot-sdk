#!/usr/bin/env bash
# Builds the Android plugin AARs into addons/tenjin/bin/android.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/android"
./gradlew :plugin:buildAddon
