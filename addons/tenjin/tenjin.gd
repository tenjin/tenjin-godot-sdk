extends Node
## Tenjin SDK for Godot. Registered as the [code]Tenjin[/code] autoload by the
## addon; call it from anywhere, e.g. [code]Tenjin.initialize("SDK_KEY")[/code].
##
## Forwards to the native "TenjinSDK" singleton: the Android plugin AAR or the
## iOS GDExtension. In the editor and on desktop there is no native singleton
## and every call is a no-op, so game code needs no platform checks.
## Platform-specific methods are no-ops on the other platform.

## Attribution data requested with [method get_attribution_info].
signal attribution_info_received(info: Dictionary)
## [method get_attribution_info] failed, or Tenjin was not initialized.
signal attribution_info_failed(error: String)
## Deep link parameters, after [method register_deep_link_handler]. On Android
## the payload also has [code]clicked_tenjin_link[/code] and
## [code]is_first_session[/code].
signal deep_link_received(params: Dictionary)

const VERSION := "1.0.0"
const NATIVE_SINGLETON := "TenjinSDK"

enum AppStore { UNSPECIFIED, GOOGLE_PLAY, AMAZON, OTHER }

const _APP_STORE_NAMES := {
	AppStore.UNSPECIFIED: "unspecified",
	AppStore.GOOGLE_PLAY: "googleplay",
	AppStore.AMAZON: "amazon",
	AppStore.OTHER: "other",
}

var _native: Object
var _is_android := OS.get_name() == "Android"
var _is_ios := OS.get_name() == "iOS"


func _init() -> void:
	if not Engine.has_singleton(NATIVE_SINGLETON):
		print_verbose("Tenjin: native SDK not available on %s; calls are no-ops." % OS.get_name())
		return
	_native = Engine.get_singleton(NATIVE_SINGLETON)
	# Native callbacks arrive on SDK threads; deferring puts them on the main thread.
	_native.connect("attribution_info_received", _on_native_attribution_info_received, CONNECT_DEFERRED)
	_native.connect("attribution_info_failed", _on_native_attribution_info_failed, CONNECT_DEFERRED)
	_native.connect("deep_link_received", _on_native_deep_link_received, CONNECT_DEFERRED)


## Returns true when running on a platform with the native SDK.
func is_available() -> bool:
	return _native != null


# ---- Lifecycle ---------------------------------------------------------------

## Creates the native SDK instance. Call once, before anything else.
func initialize(sdk_key: String) -> void:
	_call("initialize", [sdk_key])


## Sends the app open/install event. Call on every app start and on resume.
func connect_sdk() -> void:
	_call("connectSdk")


func connect_sdk_with_deferred_deeplink(deferred_deeplink: String) -> void:
	_call("connectSdkWithDeferredDeeplink", [deferred_deeplink])


## Android only.
func set_app_store(store: AppStore) -> void:
	if _is_android:
		_call("setAppStore", [_APP_STORE_NAMES[store]])


# ---- Privacy -----------------------------------------------------------------

func opt_in() -> void:
	_call("optIn")


func opt_out() -> void:
	_call("optOut")


func opt_in_params(params: PackedStringArray) -> void:
	_call("optInParams", [params])


func opt_out_params(params: PackedStringArray) -> void:
	_call("optOutParams", [params])


func opt_in_out_using_cmp() -> void:
	_call("optInOutUsingCMP")


func opt_in_google_dma() -> void:
	_call("optInGoogleDMA")


func opt_out_google_dma() -> void:
	_call("optOutGoogleDMA")


func set_google_dma_parameters(ad_personalization: bool, ad_user_data: bool) -> void:
	_call("setGoogleDMAParameters", [ad_personalization, ad_user_data])


# ---- Settings ----------------------------------------------------------------

func set_cache_event_setting(enabled: bool) -> void:
	_call("setCacheEventSetting", [enabled])


func set_encrypt_requests_setting(enabled: bool) -> void:
	_call("setEncryptRequestsSetting", [enabled])


func append_app_subversion(subversion: int) -> void:
	_call("appendAppSubversion", [subversion])


# ---- Events & revenue --------------------------------------------------------

func event_with_name(event_name: String) -> void:
	_call("eventWithName", [event_name])


func event_with_name_and_value(event_name: String, value: int) -> void:
	_call("eventWithNameAndValue", [event_name, value])


func transaction(product_name: String, currency_code: String, quantity: int, unit_price: float) -> void:
	_call("transaction", [product_name, currency_code, quantity, unit_price])


## iOS only. Validated purchase with the App Store receipt.
func transaction_with_receipt(product_name: String, currency_code: String, quantity: int,
		unit_price: float, transaction_id: String, base64_receipt: String) -> void:
	if _is_ios:
		_call("transactionWithReceipt", [product_name, currency_code, quantity, unit_price, transaction_id, base64_receipt])


## Android only. Validated purchase with Google Play purchase data and signature.
func transaction_with_data_signature(product_name: String, currency_code: String, quantity: int,
		unit_price: float, purchase_data: String, data_signature: String) -> void:
	if _is_android:
		_call("transactionWithDataSignature", [product_name, currency_code, quantity, unit_price, purchase_data, data_signature])


## Tracks a subscription purchase. Pass the fields for the current platform;
## the others are ignored.
func subscription(product_id: String, currency_code: String, unit_price: float,
		ios_transaction_id := "", ios_original_transaction_id := "", ios_receipt := "", ios_sk_transaction := "",
		android_purchase_token := "", android_purchase_data := "", android_data_signature := "") -> void:
	if _is_ios:
		_call("subscription", [product_id, currency_code, unit_price,
				ios_transaction_id, ios_original_transaction_id, ios_receipt, ios_sk_transaction])
	elif _is_android:
		_call("subscription", [product_id, currency_code, unit_price,
				android_purchase_token, android_purchase_data, android_data_signature])


## iOS 16+ only. Fetches the latest StoreKit 2 transaction natively. Returns an
## empty string on success, or an error message.
func subscription_with_storekit(product_id: String, currency_code: String, unit_price: float) -> String:
	if not _is_ios:
		return "subscription_with_storekit is only available on iOS"
	if _native == null:
		return "Tenjin native SDK is not available"
	return _native.call("subscriptionWithStoreKit", product_id, currency_code, unit_price)


# ---- SKAdNetwork (iOS only) --------------------------------------------------

## [param coarse_value] is "low", "medium" or "high" (iOS 16.1+); leave empty
## to send only the fine value.
func update_postback_conversion_value(conversion_value: int, coarse_value := "", lock_window := false) -> void:
	if not _is_ios:
		return
	if coarse_value.is_empty():
		_call("updatePostbackConversionValue", [conversion_value])
	else:
		_call("updatePostbackConversionValueWithCoarseValue", [conversion_value, coarse_value, lock_window])


# ---- Impression-level ad revenue ---------------------------------------------
#
# [param impression] is the mediation SDK's impression payload, as a Dictionary
# or a JSON string.

func event_ad_impression_admob(impression: Variant) -> void:
	_ad_impression("admob", impression)


func event_ad_impression_applovin(impression: Variant) -> void:
	_ad_impression("applovin", impression)


func event_ad_impression_ironsource(impression: Variant) -> void:
	_ad_impression("ironsource", impression)


func event_ad_impression_hyperbid(impression: Variant) -> void:
	_ad_impression("hyperbid", impression)


func event_ad_impression_topon(impression: Variant) -> void:
	_ad_impression("topon", impression)


func event_ad_impression_tradplus(impression: Variant) -> void:
	_ad_impression("tradplus", impression)


func event_ad_impression_cas(impression: Variant) -> void:
	_ad_impression("cas", impression)


func event_ad_impression_cloudx(impression: Variant) -> void:
	_ad_impression("cloudx", impression)


# ---- User --------------------------------------------------------------------

func set_customer_user_id(user_id: String) -> void:
	_call("setCustomerUserId", [user_id])


func get_customer_user_id() -> String:
	return _call("getCustomerUserId", [], "")


func get_analytics_installation_id() -> String:
	return _call("getAnalyticsInstallationId", [], "")


func get_user_profile_dictionary() -> Dictionary:
	return _parse_json_dictionary(_call("getUserProfileDictionary", [], "{}"))


func reset_user_profile() -> void:
	_call("resetUserProfile")


# ---- Async -------------------------------------------------------------------

## Requests attribution data. The result arrives through
## [signal attribution_info_received] or [signal attribution_info_failed]:
## [codeblock]
## Tenjin.attribution_info_received.connect(func(info): print(info))
## Tenjin.get_attribution_info()
## [/codeblock]
func get_attribution_info() -> void:
	if _native == null:
		attribution_info_failed.emit.call_deferred("Tenjin native SDK is not available")
		return
	_native.call("requestAttributionInfo")


## Starts listening for deep links; results arrive through
## [signal deep_link_received]. Call after [method initialize] and before
## [method connect_sdk].
func register_deep_link_handler() -> void:
	_call("registerDeepLinkHandler")


# ---- Internals ---------------------------------------------------------------

func _call(method: String, args: Array = [], default: Variant = null) -> Variant:
	if _native == null:
		return default
	return _native.callv(method, args)


func _ad_impression(network: String, impression: Variant) -> void:
	var json: String = impression if impression is String else JSON.stringify(impression)
	_call("eventAdImpression", [network, json])


func _parse_json_dictionary(json: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(json)
	return parsed if parsed is Dictionary else {}


func _on_native_attribution_info_received(json: String) -> void:
	attribution_info_received.emit(_parse_json_dictionary(json))


func _on_native_attribution_info_failed(error: String) -> void:
	attribution_info_failed.emit(error)


func _on_native_deep_link_received(json: String) -> void:
	deep_link_received.emit(_parse_json_dictionary(json))
