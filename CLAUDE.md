# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Project

Godot 4.3+ addon that wraps the native Tenjin Android and iOS SDKs and exposes
them to GDScript as the `Tenjin` autoload. Read
[CONTRIBUTING.md](CONTRIBUTING.md) for the architecture, build steps, and the
checklist for adding a method.

## Things that are easy to get wrong

- **Three places per method.** A new SDK method needs:
  - Kotlin: `@UsedByGodot` in `TenjinGodotPlugin.kt`.
  - Objective-C++: declaration in `tenjin_ios.h`, plus implementation and
    `ClassDB::bind_method` in `tenjin_ios.mm`.
  - GDScript: wrapper in `addons/tenjin/tenjin.gd`.

  The native names must be identical camelCase strings on both platforms.
  A missing `bind_method`, or a typo in a name passed to `_call`, fails
  silently: the call is just a no-op.
- **Native signals carry JSON strings.** `tenjin.gd` parses them and connects
  with `CONNECT_DEFERRED`. Keep that pattern, because native callbacks
  arrive on SDK threads.
- **Don't name a method `connect`.** It collides with `Object.connect`; the
  SDK's connect is `connectSdk` / `connect_sdk`.
- **godot-cpp stays on the 4.3 branch.** It keeps one binary working on all
  of 4.3+. Raising it means raising `compatibility_minimum` in
  `tenjin.gdextension`.
- **`addons/tenjin/bin/` is gitignored.** It's built by `scripts/` locally
  and by `.github/workflows/ci.yml` for releases. Never commit binaries.
  `TenjinSDK.xcframework` is downloaded and checksum-verified by
  `scripts/update-ios-sdk.sh`.
- **The desktop libraries are no-op stubs** (`TENJIN_STUB`). They exist so
  editors and desktop exports can load the extension. They register no
  singleton.
- **Version strings are bumped by release-please** through the
  `x-release-please-version` markers. Don't edit those versions by hand, and
  keep the markers when touching those lines.
- **PR titles must be Conventional Commits** (`feat:`, `fix:`, `chore:`…),
  since release-please builds the changelog from them.
- **Sample**:
  - `sample/addons/tenjin` is a symlink to the real addon; edit the addon,
    not a copy.
  - The `SDK_KEY` placeholder in `sample/main.gd` must stay a placeholder.

## Verifying changes

- GDScript: `godot --headless --path sample --import`, then
  `godot --headless --path sample --quit-after 120`. Expect no `SCRIPT ERROR`.
- Android: `./scripts/build-android.sh`.
- iOS: `./scripts/build-ios.sh` (needs Xcode and scons).
- Native behavior can only be checked by exporting the sample to a device.
