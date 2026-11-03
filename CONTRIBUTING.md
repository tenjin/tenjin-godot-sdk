# Contributing

This covers the plugin's internals: building it, adding SDK methods, bumping
the native SDKs and releasing. Integration docs for game developers are in
[README.md](README.md).

## Repository layout

```
addons/tenjin/                 # the addon users install
├── plugin.cfg                 # addon manifest (version bumped by release-please)
├── tenjin_editor_plugin.gd    # registers the `Tenjin` autoload + export plugin + project settings
├── tenjin_export_plugin.gd    # Android: AAR + Maven dep. iOS: embeds TenjinSDK.xcframework, Info.plist
├── tenjin.gd                  # public GDScript API (the `Tenjin` autoload)
├── tenjin.gdextension         # iOS bridge + desktop stubs
└── bin/                       # built binaries (gitignored, see "Building")
android/                       # Gradle project → Android plugin AARs (Kotlin)
ios/                           # SConstruct + godot-cpp GDExtension (Objective-C++); also builds the desktop stubs
sample/                        # Godot project that calls every method; addons/tenjin is a symlink
scripts/                       # build-android.sh, build-ios.sh, build-stub.sh, update-ios-sdk.sh
.github/workflows/             # ci.yml (build + smoke test + package), release-please.yml
```

## How a call reaches the native SDK

```
Tenjin.event_with_name("x")          tenjin.gd (autoload)
  └─ _native.callv("eventWithName")  Engine singleton "TenjinSDK"
       ├─ Android: TenjinGodotPlugin.eventWithName   (@UsedByGodot, Kotlin)
       └─ iOS:     TenjinIOS::eventWithName           (bind_method, Objective-C++)
```

- Both native sides register a singleton named `TenjinSDK` with **the same
  camelCase method names**, so `tenjin.gd` has one code path.
- When there's no singleton (editor, desktop, the stubs), `_call` returns the
  default and does nothing.
- Platform-only methods are guarded in `tenjin.gd` with `_is_android` /
  `_is_ios`.
- Async results come back as native signals carrying JSON strings
  (`attribution_info_received`, `attribution_info_failed`, `deep_link_received`).
  `tenjin.gd` connects with `CONNECT_DEFERRED`, so they reach game code on the
  main thread, and parses the JSON into a Dictionary. On iOS the bridge also
  emits through `call_deferred`.
- `connect` is taken by `Object.connect`, so the method is `connectSdk` /
  `connect_sdk`.

## Building

```bash
./scripts/build-android.sh        # → bin/android/tenjin-godot-{debug,release}.aar
./scripts/build-ios.sh            # → bin/ios/*.xcframework (+ downloads TenjinSDK.xcframework) and bin/macos stub
./scripts/build-stub.sh linux     # → bin/linux stub (also: windows, macos)
```

- Android needs JDK 17 and the Android SDK (`ANDROID_HOME` or
  `android/local.properties`).
- iOS needs Xcode and scons (`pipx install scons`).
- The scripts clone godot-cpp into `ios/godot-cpp` (branch `GODOT_CPP_BRANCH`,
  default `4.3`). Building against the 4.3 API keeps one binary compatible
  with Godot 4.3 and every later 4.x release, so don't raise it without raising
  `compatibility_minimum` in `tenjin.gdextension`.

Open `sample/` in Godot to try the result. On a desktop editor every call is a
no-op. To exercise the native SDKs, export the sample to a device:

- **Android**: the preset has Gradle build on. Install the Android build
  template when Godot asks.
- **iOS**: export the Xcode project and run it from Xcode.

Set a real key in `sample/main.gd` (`SDK_KEY`) first, and don't commit it.

The **Easter egg**: tap the title five times quickly.

## Adding a new SDK method

Every method touches three files, and the native names must match exactly:

1. **Android** — `android/plugin/src/main/java/com/tenjin/godot/TenjinGodotPlugin.kt`:
   add a `@UsedByGodot fun myMethod(...)` that calls `instance?.myMethod(...)`.
   Only Godot-compatible parameter types work (`String`, `Int`/`Long`,
   `Double`, `Boolean`, arrays, `Dictionary`). Pass anything structured as a
   JSON string.
2. **iOS**:
   - `ios/src/tenjin_ios.h`: declare it.
   - `ios/src/tenjin_ios.mm`: implement it, and add a
     `ClassDB::bind_method(D_METHOD("myMethod", ...), &TenjinIOS::myMethod)`
     in `_bind_methods`. If you skip the binding, the call silently does
     nothing.
3. **GDScript** — `addons/tenjin/tenjin.gd`: add a snake_case wrapper that
   calls `_call("myMethod", [...])`. Add a platform guard if only one SDK has
   the method, and a `##` doc comment.

Then:

- Add a button to `sample/main.gd`.
- Add a line to the README if users need to know about it.
- Rebuild both platforms.

For a callback, add a signal on both native sides with the same name and a
JSON string payload. Then connect it in `tenjin.gd` `_init` with
`CONNECT_DEFERRED`, and re-emit it as a typed signal.

## Bumping the native SDKs

- **Android**: change `tenjinAndroidSdkVersion` in
  `android/plugin/build.gradle.kts` and `TENJIN_ANDROID_DEPENDENCY` in
  `addons/tenjin/tenjin_export_plugin.gd`. The game's Gradle build resolves
  it from Maven Central at export.
- **iOS**: change `TENJIN_IOS_SDK_VERSION` and `TENJIN_IOS_SDK_SHA256` in
  `scripts/update-ios-sdk.sh`, then run `./scripts/build-ios.sh`. The
  SHA-256 is shown on the asset in the tenjin-ios-sdk GitHub release, or
  you can run `shasum -a 256 TenjinSDK.xcframework.zip`. If the new SDK
  adds headers the bridge uses (e.g. an ILRD category), import them in
  `tenjin_ios.mm`.
- Update the versions at the top of the README.

## CI

`.github/workflows/ci.yml` runs on every PR:

1. Builds the Android AARs (Ubuntu), the iOS xcframeworks + macOS stub (macOS),
   and the Linux and Windows stubs.
2. Assembles them into the addon (`tenjin-godot-sdk` artifact, downloadable from
   the run).
3. Imports and runs the sample headless on Godot 4.3 and the latest 4.x. It
   fails on any script error, or if the extension can't load.

## Releasing

Releases are cut by release-please from Conventional Commit PR titles on
`main`:

- `fix:` → patch
- `feat:` → minor
- `feat!:` → major
- `chore:`, `docs:`, `ci:` → no release

Merging the release PR:

- Tags the release.
- Updates `CHANGELOG.md` and the version in `plugin.cfg`, `tenjin.gd`,
  `android/plugin/build.gradle.kts` and `ios/SConstruct`.
- Runs `ci.yml` and attaches `tenjin-godot-sdk-<version>.zip` to the GitHub
  release.

That zip is what users install and what the Godot Asset Library serves.

After a release, update the Asset Library listing; see
[.github/assetlib/README.md](.github/assetlib/README.md).
