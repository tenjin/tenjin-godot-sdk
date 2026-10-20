# Tenjin Godot SDK

Godot 4 addon for [Tenjin](https://www.tenjin.com) mobile attribution and
analytics. It wraps the native Tenjin Android and iOS SDKs and exposes them to
GDScript as the `Tenjin` autoload.

- Godot **4.3+**
- Tenjin Android SDK **1.24.0** (resolved from Maven Central at export time)
- Tenjin iOS SDK **1.19.1** (`TenjinSDK.xcframework`, bundled in the release zip)

## Installation

1. Download `tenjin-godot-sdk-<version>.zip` from
   [Releases](https://github.com/tenjin/tenjin-godot-sdk/releases) and copy its
   `addons/tenjin` into your project's `addons/` folder. (The repo itself has
   no prebuilt binaries; see [Building](#building).)
2. **Project → Project Settings → Plugins**: enable **Tenjin SDK**. This
   registers the `Tenjin` autoload.
3. **Android**: in the Android export preset, enable
   **Gradle Build → Use Gradle Build** (install the Android build template
   when prompted). The Tenjin SDK is added as a Maven dependency, which needs a
   Gradle build.
4. **iOS**: nothing extra. The export embeds `TenjinSDK.xcframework` and adds
   `NSUserTrackingUsageDescription` and Tenjin's `SKAdNetworkItems` to
   `Info.plist`. Both can be changed under **Project Settings → Tenjin → iOS**
   (turn on *Advanced Settings*). Turn off `add_skadnetwork_ids` if another
   plugin (an ad network SDK, for example) already writes `SKAdNetworkItems`.

## Usage

```gdscript
func _ready() -> void:
	Tenjin.initialize("<SDK_KEY>")
	Tenjin.connect_sdk()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		Tenjin.connect_sdk()
```

In the editor and on desktop the native SDK isn't there, so every call does
nothing. Game code doesn't need platform checks. `Tenjin.is_available()`
tells you whether the native SDK is loaded.

The method is `connect_sdk()`, not `connect()`, because `connect()` already
exists on every Godot `Object` (for signals).

### Events and purchases

```gdscript
Tenjin.event_with_name("tutorial_complete")
Tenjin.event_with_name_and_value("level", 5)
Tenjin.transaction("com.game.coins", "USD", 1, 0.99)

# Validated purchases
Tenjin.transaction_with_receipt(product, "USD", 1, 0.99, transaction_id, base64_receipt)   # iOS
Tenjin.transaction_with_data_signature(product, "USD", 1, 0.99, purchase_data, signature)  # Android

# Subscriptions: fill the fields for the platform you're on
Tenjin.subscription(product_id, "USD", 4.99,
	ios_transaction_id, ios_original_transaction_id, ios_receipt, ios_sk_transaction,
	android_purchase_token, android_purchase_data, android_data_signature)

var error := Tenjin.subscription_with_storekit(product_id, "USD", 4.99)  # iOS 16+, "" on success
```

See [SUBSCRIPTIONS_TRACKING.md](SUBSCRIPTIONS_TRACKING.md) for where each
field comes from, with a Google Play Billing example.

### Privacy

```gdscript
Tenjin.opt_in()
Tenjin.opt_out()
Tenjin.opt_in_params(PackedStringArray(["ip_address", "advertising_id"]))
Tenjin.opt_in_out_using_cmp()
Tenjin.set_google_dma_parameters(true, true)
```

### Attribution and deep links

Async results come back as signals, on the main thread:

```gdscript
Tenjin.attribution_info_received.connect(func(info: Dictionary): print(info))
Tenjin.attribution_info_failed.connect(func(error: String): push_warning(error))
Tenjin.get_attribution_info()

Tenjin.deep_link_received.connect(func(params: Dictionary): print(params))
Tenjin.register_deep_link_handler()  # before connect_sdk()
```

### SKAdNetwork (iOS)

```gdscript
Tenjin.update_postback_conversion_value(10)
Tenjin.update_postback_conversion_value(10, "high", false)  # coarse value, lock window
```

### Impression-level ad revenue

Pass the mediation SDK's impression payload, either as a Dictionary or as a
JSON string:

```gdscript
Tenjin.event_ad_impression_admob(impression)
Tenjin.event_ad_impression_applovin(impression)
# also: ironsource, hyperbid, topon, tradplus, cas, cloudx
```

### User

```gdscript
Tenjin.set_customer_user_id("user-123")
Tenjin.get_customer_user_id()
Tenjin.get_analytics_installation_id()
Tenjin.get_user_profile_dictionary()
Tenjin.reset_user_profile()
```

See `addons/tenjin/tenjin.gd` for the full API.

## Architecture

```
addons/tenjin/
├── plugin.cfg / tenjin_editor_plugin.gd   # registers the autoload + export plugin
├── tenjin_export_plugin.gd                # Android AAR + Maven dep, iOS framework + plist
├── tenjin.gd                              # public API (the `Tenjin` autoload)
├── tenjin.gdextension                     # iOS bridge (+ desktop stubs)
└── bin/                                   # built, not committed
    ├── android/tenjin-godot-{debug,release}.aar
    ├── ios/TenjinSDK.xcframework
    ├── ios/libtenjin_godot.template_{debug,release}.xcframework
    ├── macos/libtenjin_godot.macos.framework
    ├── linux/libtenjin_godot.linux.x86_64.so
    └── windows/libtenjin_godot.windows.x86_64.dll
android/   # Gradle project → Godot Android plugin (v2), Kotlin
ios/       # godot-cpp GDExtension, Objective-C++
sample/    # Godot project that calls every method (addons/tenjin is a symlink)
scripts/   # build-android.sh, build-ios.sh, build-stub.sh, update-ios-sdk.sh
```

Both platforms register a native singleton called `TenjinSDK`, and the method
names are the same on each, so `tenjin.gd` has one code path:

- **Android**: `TenjinGodotPlugin.kt` is a Godot v2 Android plugin
  (`GodotPlugin` with `@UsedByGodot` methods). It's declared in the AAR
  manifest. `tenjin_export_plugin.gd` adds the AAR and
  `com.tenjin:android-sdk` to the Gradle build.
- **iOS**: `tenjin_ios.mm` is a GDExtension class, built as a static
  xcframework against godot-cpp. Godot links it into the Xcode project and
  calls its init function at startup. `TenjinSDK.xcframework` is a dynamic
  framework, so the export plugin embeds it.

Callbacks from native code come back on SDK threads. `tenjin.gd` connects to
the native signals with `CONNECT_DEFERRED`, so handlers in your game run on the
main thread.

## Building

The native binaries under `addons/tenjin/bin` aren't committed. Build them
before opening the sample from a checkout:

```bash
./scripts/build-android.sh   # → addons/tenjin/bin/android/*.aar
./scripts/build-ios.sh       # → addons/tenjin/bin/ios/*.xcframework + bin/macos stub
./scripts/build-stub.sh linux   # or windows: no-op stub for that desktop editor
```

`build-ios.sh` needs Xcode and `scons` (`pipx install scons`). It clones
godot-cpp (branch `GODOT_CPP_BRANCH`, default `4.3`) into `ios/godot-cpp`. The
4.3 bindings are used so a single build works on Godot 4.3 and every later
4.x release. It also downloads `TenjinSDK.xcframework` from the
[tenjin-ios-sdk release](https://github.com/tenjin/tenjin-ios-sdk/releases)
pinned in `scripts/update-ios-sdk.sh`, checking its SHA-256.

To bump the iOS SDK, change the version and SHA-256 in
`scripts/update-ios-sdk.sh` and run it (or pass it the path of a local
`TenjinSDK.xcframework`). To bump the Android SDK, change the version in
`android/plugin/build.gradle.kts` and `TENJIN_ANDROID_DEPENDENCY` in
`tenjin_export_plugin.gd`.

## Releasing

Releases are cut by [release-please](https://github.com/googleapis/release-please)
from [Conventional Commits](https://www.conventionalcommits.org/) on `main`
(`feat:` → minor, `fix:` → patch, `feat!:` → major), so use those prefixes in
PR titles. Merging the release PR it opens tags the release, updates
`CHANGELOG.md` and the plugin version (`plugin.cfg`, `tenjin.gd`, the Android
`BuildConfig` and the iOS `TENJIN_GODOT_PLUGIN_VERSION`), and attaches
`tenjin-godot-sdk-<version>.zip` (the `addons/tenjin` folder) to the GitHub
release. CI (`.github/workflows/ci.yml`) builds every binary in that zip from
source.

See [CONTRIBUTING.md](CONTRIBUTING.md) for internals and adding methods.

## Known limitations

- Desktop stubs are shipped for macOS (universal), Linux x86_64 and Windows
  x86_64. On other editor or export platforms (ARM Linux/Windows, Web), Godot
  logs "No GDExtension library found" when loading the project and when
  exporting. The SDK does nothing on those platforms anyway.
- **Android runtime** logs one "Error loading extension" line at startup,
  because `tenjin.gdextension` is left out of Android exports but is still
  listed in the project's extension list. Nothing breaks.
- The Android SDK's deep link API fires once. Each `register_deep_link_handler()`
  call fetches once, and the payload includes `clicked_tenjin_link` and
  `is_first_session`.
