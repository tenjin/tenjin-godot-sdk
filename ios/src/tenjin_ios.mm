// Copyright (c) Tenjin. All Rights Reserved.

#include "tenjin_ios.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#import <Foundation/Foundation.h>
#import <TenjinSDK/TenjinSDK.h>
// ILRD passthroughs live in per-network category headers.
#import <TenjinSDK/TenjinSDK+AdMobILRD.h>
#import <TenjinSDK/TenjinSDK+AppLovinILRD.h>
#import <TenjinSDK/TenjinSDK+CASILRD.h>
#import <TenjinSDK/TenjinSDK+CloudXILRD.h>
#import <TenjinSDK/TenjinSDK+HyperBidILRD.h>
#import <TenjinSDK/TenjinSDK+IronSourceILRD.h>
#import <TenjinSDK/TenjinSDK+TopOnILRD.h>
#import <TenjinSDK/TenjinSDK+TradPlusILRD.h>

#ifndef TENJIN_GODOT_PLUGIN_VERSION
#define TENJIN_GODOT_PLUGIN_VERSION "0.0.0"
#endif

using namespace godot;

namespace {

NSString *to_ns(const String &s) {
	return [NSString stringWithUTF8String:s.utf8().get_data()];
}

String from_ns(NSString *s) {
	return s ? String::utf8([s UTF8String]) : String();
}

NSArray<NSString *> *to_ns_array(const PackedStringArray &items) {
	NSMutableArray<NSString *> *arr = [NSMutableArray arrayWithCapacity:items.size()];
	for (int64_t i = 0; i < items.size(); i++) {
		[arr addObject:to_ns(items[i])];
	}
	return arr;
}

NSString *json_from_dictionary(NSDictionary *dict) {
	if (!dict || ![NSJSONSerialization isValidJSONObject:dict]) {
		return @"{}";
	}
	NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
	return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"{}";
}

NSDecimalNumber *to_decimal(double value) {
	return [[NSDecimalNumber alloc] initWithDouble:value];
}

} // namespace

void TenjinIOS::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize", "sdk_key"), &TenjinIOS::initialize);
	ClassDB::bind_method(D_METHOD("connectSdk"), &TenjinIOS::connectSdk);
	ClassDB::bind_method(D_METHOD("connectSdkWithDeferredDeeplink", "deferred_deeplink"), &TenjinIOS::connectSdkWithDeferredDeeplink);

	ClassDB::bind_method(D_METHOD("optIn"), &TenjinIOS::optIn);
	ClassDB::bind_method(D_METHOD("optOut"), &TenjinIOS::optOut);
	ClassDB::bind_method(D_METHOD("optInParams", "params"), &TenjinIOS::optInParams);
	ClassDB::bind_method(D_METHOD("optOutParams", "params"), &TenjinIOS::optOutParams);
	ClassDB::bind_method(D_METHOD("optInOutUsingCMP"), &TenjinIOS::optInOutUsingCMP);
	ClassDB::bind_method(D_METHOD("optInGoogleDMA"), &TenjinIOS::optInGoogleDMA);
	ClassDB::bind_method(D_METHOD("optOutGoogleDMA"), &TenjinIOS::optOutGoogleDMA);
	ClassDB::bind_method(D_METHOD("setGoogleDMAParameters", "ad_personalization", "ad_user_data"), &TenjinIOS::setGoogleDMAParameters);

	ClassDB::bind_method(D_METHOD("setCacheEventSetting", "setting"), &TenjinIOS::setCacheEventSetting);
	ClassDB::bind_method(D_METHOD("setEncryptRequestsSetting", "setting"), &TenjinIOS::setEncryptRequestsSetting);
	ClassDB::bind_method(D_METHOD("appendAppSubversion", "subversion"), &TenjinIOS::appendAppSubversion);

	ClassDB::bind_method(D_METHOD("eventWithName", "name"), &TenjinIOS::eventWithName);
	ClassDB::bind_method(D_METHOD("eventWithNameAndValue", "name", "value"), &TenjinIOS::eventWithNameAndValue);
	ClassDB::bind_method(D_METHOD("transaction", "product_name", "currency_code", "quantity", "unit_price"), &TenjinIOS::transaction);
	ClassDB::bind_method(D_METHOD("transactionWithReceipt", "product_name", "currency_code", "quantity", "unit_price", "transaction_id", "base64_receipt"), &TenjinIOS::transactionWithReceipt);
	ClassDB::bind_method(D_METHOD("subscription", "product_id", "currency_code", "unit_price", "transaction_id", "original_transaction_id", "receipt", "sk_transaction"), &TenjinIOS::subscription);
	ClassDB::bind_method(D_METHOD("subscriptionWithStoreKit", "product_id", "currency_code", "unit_price"), &TenjinIOS::subscriptionWithStoreKit);

	ClassDB::bind_method(D_METHOD("updatePostbackConversionValue", "conversion_value"), &TenjinIOS::updatePostbackConversionValue);
	ClassDB::bind_method(D_METHOD("updatePostbackConversionValueWithCoarseValue", "conversion_value", "coarse_value", "lock_window"), &TenjinIOS::updatePostbackConversionValueWithCoarseValue);

	ClassDB::bind_method(D_METHOD("eventAdImpression", "network", "json"), &TenjinIOS::eventAdImpression);

	ClassDB::bind_method(D_METHOD("setCustomerUserId", "user_id"), &TenjinIOS::setCustomerUserId);
	ClassDB::bind_method(D_METHOD("getCustomerUserId"), &TenjinIOS::getCustomerUserId);
	ClassDB::bind_method(D_METHOD("getAnalyticsInstallationId"), &TenjinIOS::getAnalyticsInstallationId);
	ClassDB::bind_method(D_METHOD("getUserProfileDictionary"), &TenjinIOS::getUserProfileDictionary);
	ClassDB::bind_method(D_METHOD("resetUserProfile"), &TenjinIOS::resetUserProfile);

	ClassDB::bind_method(D_METHOD("requestAttributionInfo"), &TenjinIOS::requestAttributionInfo);
	ClassDB::bind_method(D_METHOD("registerDeepLinkHandler"), &TenjinIOS::registerDeepLinkHandler);
	ClassDB::bind_method(D_METHOD("requestTrackingAuthorization"), &TenjinIOS::requestTrackingAuthorization);

	ADD_SIGNAL(MethodInfo("attribution_info_received", PropertyInfo(Variant::STRING, "json")));
	ADD_SIGNAL(MethodInfo("attribution_info_failed", PropertyInfo(Variant::STRING, "error")));
	ADD_SIGNAL(MethodInfo("deep_link_received", PropertyInfo(Variant::STRING, "json")));
	ADD_SIGNAL(MethodInfo("tracking_authorization_received", PropertyInfo(Variant::INT, "status")));
}

// ---- Lifecycle -------------------------------------------------------------

void TenjinIOS::initialize(const String &sdk_key) {
	[TenjinSDK setPluginVersion:@"godot" version:@TENJIN_GODOT_PLUGIN_VERSION];
	[TenjinSDK getInstance:to_ns(sdk_key)];
}

void TenjinIOS::connectSdk() {
	[TenjinSDK connect];
}

void TenjinIOS::connectSdkWithDeferredDeeplink(const String &deferred_deeplink) {
	[TenjinSDK connectWithDeferredDeeplink:[NSURL URLWithString:to_ns(deferred_deeplink)]];
}

// ---- Privacy ---------------------------------------------------------------

void TenjinIOS::optIn() { [TenjinSDK optIn]; }
void TenjinIOS::optOut() { [TenjinSDK optOut]; }
void TenjinIOS::optInParams(const PackedStringArray &params) { [TenjinSDK optInParams:to_ns_array(params)]; }
void TenjinIOS::optOutParams(const PackedStringArray &params) { [TenjinSDK optOutParams:to_ns_array(params)]; }
void TenjinIOS::optInOutUsingCMP() { [TenjinSDK optInOutUsingCMP]; }
void TenjinIOS::optInGoogleDMA() { [TenjinSDK optInGoogleDMA]; }
void TenjinIOS::optOutGoogleDMA() { [TenjinSDK optOutGoogleDMA]; }

void TenjinIOS::setGoogleDMAParameters(bool ad_personalization, bool ad_user_data) {
	[[TenjinSDK sharedInstance] setGoogleDMAParametersWithAdPersonalization:ad_personalization
	                                                             adUserData:ad_user_data];
}

// ---- Settings --------------------------------------------------------------

void TenjinIOS::setCacheEventSetting(bool setting) { [TenjinSDK setCacheEventSetting:setting]; }
void TenjinIOS::setEncryptRequestsSetting(bool setting) { [TenjinSDK setEncryptRequestsSetting:setting]; }

void TenjinIOS::appendAppSubversion(int subversion) {
	[TenjinSDK appendAppSubversion:@(subversion)];
}

// ---- Events & revenue ------------------------------------------------------

void TenjinIOS::eventWithName(const String &name) {
	[TenjinSDK sendEventWithName:to_ns(name)];
}

void TenjinIOS::eventWithNameAndValue(const String &name, int value) {
	[TenjinSDK sendEventWithName:to_ns(name) andValue:(NSInteger)value];
}

void TenjinIOS::transaction(const String &product_name, const String &currency_code, int quantity, double unit_price) {
	[TenjinSDK transactionWithProductName:to_ns(product_name)
	                      andCurrencyCode:to_ns(currency_code)
	                          andQuantity:(NSInteger)quantity
	                         andUnitPrice:to_decimal(unit_price)];
}

void TenjinIOS::transactionWithReceipt(const String &product_name, const String &currency_code, int quantity,
		double unit_price, const String &transaction_id, const String &base64_receipt) {
	[TenjinSDK transactionWithProductName:to_ns(product_name)
	                      andCurrencyCode:to_ns(currency_code)
	                          andQuantity:(NSInteger)quantity
	                         andUnitPrice:to_decimal(unit_price)
	                     andTransactionId:to_ns(transaction_id)
	                     andBase64Receipt:to_ns(base64_receipt)];
}

void TenjinIOS::subscription(const String &product_id, const String &currency_code, double unit_price,
		const String &transaction_id, const String &original_transaction_id,
		const String &receipt, const String &sk_transaction) {
	[TenjinSDK subscriptionWithProductName:to_ns(product_id)
	                       andCurrencyCode:to_ns(currency_code)
	                          andUnitPrice:to_decimal(unit_price)
	                      andTransactionId:to_ns(transaction_id)
	              andOriginalTransactionId:to_ns(original_transaction_id)
	                      andBase64Receipt:to_ns(receipt)
	                      andSKTransaction:to_ns(sk_transaction)];
}

// The native StoreKit 2 helper is fire-and-forget and iOS 16+. Returns an
// empty string once dispatched, or an error message.
String TenjinIOS::subscriptionWithStoreKit(const String &product_id, const String &currency_code, double unit_price) {
	if (@available(iOS 16.0, *)) {
		[TenjinSDK subscriptionWithStoreKitForProductId:to_ns(product_id)
		                               andCurrencyCode:to_ns(currency_code)
		                                  andUnitPrice:to_decimal(unit_price)];
		return String();
	}
	return "subscriptionWithStoreKit requires iOS 16.0 or later";
}

// ---- SKAdNetwork -----------------------------------------------------------

void TenjinIOS::updatePostbackConversionValue(int conversion_value) {
	[TenjinSDK updatePostbackConversionValue:conversion_value];
}

void TenjinIOS::updatePostbackConversionValueWithCoarseValue(int conversion_value, const String &coarse_value, bool lock_window) {
	[TenjinSDK updatePostbackConversionValue:conversion_value
	                             coarseValue:to_ns(coarse_value)
	                              lockWindow:lock_window];
}

// ---- ILRD ------------------------------------------------------------------

void TenjinIOS::eventAdImpression(const String &network, const String &json) {
	NSString *payload = to_ns(json);
	if (network == "admob") {
		[TenjinSDK adMobImpressionFromJSON:payload];
	} else if (network == "applovin") {
		[TenjinSDK appLovinImpressionFromJSON:payload];
	} else if (network == "ironsource") {
		[TenjinSDK ironSourceImpressionFromJSON:payload];
	} else if (network == "hyperbid") {
		[TenjinSDK hyperBidImpressionFromJSON:payload];
	} else if (network == "topon") {
		[TenjinSDK topOnImpressionFromJSON:payload];
	} else if (network == "tradplus") {
		[TenjinSDK tradPlusImpressionFromJSON:payload];
	} else if (network == "cas") {
		[TenjinSDK casImpressionFromJSON:payload];
	} else if (network == "cloudx") {
		[TenjinSDK cloudXImpressionFromJSON:payload];
	} else {
		UtilityFunctions::push_warning("Tenjin: unknown ad impression network: ", network);
	}
}

// ---- User ------------------------------------------------------------------

void TenjinIOS::setCustomerUserId(const String &user_id) {
	[TenjinSDK setCustomerUserId:to_ns(user_id)];
}

String TenjinIOS::getCustomerUserId() {
	return from_ns([TenjinSDK getCustomerUserId]);
}

String TenjinIOS::getAnalyticsInstallationId() {
	return from_ns([TenjinSDK getAnalyticsInstallationId]);
}

String TenjinIOS::getUserProfileDictionary() {
	return from_ns(json_from_dictionary([TenjinSDK getUserProfileAsDictionary]));
}

void TenjinIOS::resetUserProfile() {
	[TenjinSDK resetUserProfile];
}

// ---- Async -----------------------------------------------------------------
//
// SDK completion blocks may run off the main thread; call_deferred queues the
// emit onto Godot's main loop.

void TenjinIOS::requestAttributionInfo() {
	TenjinSDK *sdk = [TenjinSDK sharedInstance];
	if (!sdk) {
		call_deferred("emit_signal", "attribution_info_failed", "Tenjin is not initialized");
		return;
	}
	[sdk getAttributionInfo:^(NSDictionary *info, NSError *error) {
		if (error || !info) {
			String message = from_ns(error.localizedDescription ?: @"No attribution info");
			call_deferred("emit_signal", "attribution_info_failed", message);
			return;
		}
		call_deferred("emit_signal", "attribution_info_received", from_ns(json_from_dictionary(info)));
	}];
}

void TenjinIOS::registerDeepLinkHandler() {
	[[TenjinSDK sharedInstance] registerDeepLinkHandler:^(NSDictionary *params, NSError *error) {
		if (error || !params) {
			return;
		}
		call_deferred("emit_signal", "deep_link_received", from_ns(json_from_dictionary(params)));
	}];
}

// Shows the App Tracking Transparency prompt (once per install; later calls
// return the stored status). The status is ATTrackingManagerAuthorizationStatus.
void TenjinIOS::requestTrackingAuthorization() {
	[TenjinSDK requestTrackingAuthorizationWithCompletionHandler:^(NSUInteger status) {
		call_deferred("emit_signal", "tracking_authorization_received", (int64_t)status);
	}];
}
