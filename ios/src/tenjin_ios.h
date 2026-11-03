// Copyright (c) Tenjin. All Rights Reserved.
//
// iOS GDExtension class wrapping the TenjinSDK framework. Registered as the
// "TenjinSDK" engine singleton; addons/tenjin/tenjin.gd is the public API and
// the only intended caller. Method names match the Android plugin
// (android/plugin/.../TenjinGodotPlugin.kt).

#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class TenjinIOS : public Object {
	GDCLASS(TenjinIOS, Object);

protected:
	static void _bind_methods();

public:
	// Lifecycle
	void initialize(const String &sdk_key);
	void connectSdk();
	void connectSdkWithDeferredDeeplink(const String &deferred_deeplink);

	// Privacy
	void optIn();
	void optOut();
	void optInParams(const PackedStringArray &params);
	void optOutParams(const PackedStringArray &params);
	void optInOutUsingCMP();
	void optInGoogleDMA();
	void optOutGoogleDMA();
	void setGoogleDMAParameters(bool ad_personalization, bool ad_user_data);

	// Settings
	void setCacheEventSetting(bool setting);
	void setEncryptRequestsSetting(bool setting);
	void appendAppSubversion(int subversion);

	// Events & revenue
	void eventWithName(const String &name);
	void eventWithNameAndValue(const String &name, int value);
	void transaction(const String &product_name, const String &currency_code, int quantity, double unit_price);
	void transactionWithReceipt(const String &product_name, const String &currency_code, int quantity,
			double unit_price, const String &transaction_id, const String &base64_receipt);
	void subscription(const String &product_id, const String &currency_code, double unit_price,
			const String &transaction_id, const String &original_transaction_id,
			const String &receipt, const String &sk_transaction);
	String subscriptionWithStoreKit(const String &product_id, const String &currency_code, double unit_price);

	// SKAdNetwork
	void updatePostbackConversionValue(int conversion_value);
	void updatePostbackConversionValueWithCoarseValue(int conversion_value, const String &coarse_value, bool lock_window);

	// ILRD
	void eventAdImpression(const String &network, const String &json);

	// User
	void setCustomerUserId(const String &user_id);
	String getCustomerUserId();
	String getAnalyticsInstallationId();
	String getUserProfileDictionary();
	void resetUserProfile();

	// Async (results are emitted as signals on the main thread)
	void requestAttributionInfo();
	void registerDeepLinkHandler();
	void requestTrackingAuthorization();
};

} // namespace godot
