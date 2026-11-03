@tool
extends EditorExportPlugin
## Adds the Tenjin native SDKs to Android and iOS exports.
##
## Android: the bridge AAR plus a Maven dependency on com.tenjin:android-sdk.
## Requires "Use Gradle Build" in the Android export preset.
##
## iOS: embeds TenjinSDK.xcframework and adds the ATT usage description and
## Tenjin's SKAdNetwork IDs to Info.plist. The bridge itself is a GDExtension
## (tenjin.gdextension), which Godot links on its own.

const TENJIN_ANDROID_DEPENDENCY := "com.tenjin:android-sdk:2.0.1"
# The Tenjin Android SDK doesn't bring these in, and without them it sends no
# advertising ID or App Set ID. See
# https://github.com/tenjin/tenjin-android-sdk#play-services-ads-identifier-google-play
const GOOGLE_ANDROID_DEPENDENCIES: PackedStringArray = [
	"com.google.android.gms:play-services-ads-identifier:18.2.0",
	"com.google.android.gms:play-services-appset:16.1.0",
]
const BIN_DIR := "res://addons/tenjin/bin/"
const IOS_BIN_DIR := BIN_DIR + "ios/"

const SETTING_TRACKING_DESCRIPTION := "tenjin/ios/tracking_usage_description"
const SETTING_ADD_SKADNETWORK_IDS := "tenjin/ios/add_skadnetwork_ids"

const DEFAULT_TRACKING_DESCRIPTION := "This identifier will be used to deliver personalized ads to you."

# Tenjin's SKAdNetwork identifiers. Keep in sync with
# https://github.com/tenjin/tenjin-ios-sdk#-skadnetwork
const SKADNETWORK_IDS: PackedStringArray = [
	"22mmun2rn5.skadnetwork",
	"4468km3ulz.skadnetwork",
	"v9wttpbfk9.skadnetwork",
	"n38lu8286q.skadnetwork",
]


static func register_project_settings() -> void:
	_add_setting(SETTING_TRACKING_DESCRIPTION, TYPE_STRING, DEFAULT_TRACKING_DESCRIPTION)
	_add_setting(SETTING_ADD_SKADNETWORK_IDS, TYPE_BOOL, true)


static func _add_setting(name: String, type: Variant.Type, default_value: Variant) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)
	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.add_property_info({"name": name, "type": type})


func _get_name() -> String:
	return "TenjinSDK"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid or platform is EditorExportPlatformIOS


func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	# Paths are relative to res://addons/.
	var variant := "debug" if debug else "release"
	return PackedStringArray(["tenjin/bin/android/tenjin-godot-%s.aar" % variant])


func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	var dependencies := PackedStringArray([TENJIN_ANDROID_DEPENDENCY])
	dependencies.append_array(GOOGLE_ANDROID_DEPENDENCIES)
	return dependencies


# The native binaries reach the build through the hooks above, never through
# the PCK. Without this, Godot imports the iOS framework's .abi.json files as
# resources and packs them (~930 KB) into every export, Android included.
func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path.begins_with(BIN_DIR):
		skip()


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	if not features.has("ios"):
		return

	add_ios_embedded_framework(IOS_BIN_DIR + "TenjinSDK.xcframework")

	var plist := ""
	var tracking_description: String = ProjectSettings.get_setting(SETTING_TRACKING_DESCRIPTION, DEFAULT_TRACKING_DESCRIPTION)
	if not tracking_description.is_empty():
		plist += "<key>NSUserTrackingUsageDescription</key>\n<string>%s</string>\n" % tracking_description.xml_escape()

	if ProjectSettings.get_setting(SETTING_ADD_SKADNETWORK_IDS, true):
		plist += "<key>SKAdNetworkItems</key>\n<array>\n"
		for id in SKADNETWORK_IDS:
			plist += "\t<dict><key>SKAdNetworkIdentifier</key><string>%s</string></dict>\n" % id
		plist += "</array>\n"

	if not plist.is_empty():
		add_ios_plist_content(plist)
