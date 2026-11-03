// Copyright (c) Tenjin. All Rights Reserved.
//
// Godot Android plugin (v2) wrapping com.tenjin.android.TenjinSDK. Godot
// exposes it as Engine.get_singleton("TenjinSDK"); addons/tenjin/tenjin.gd is
// the public API and the only intended caller.
//
// Method names are shared with the iOS GDExtension (ios/src/tenjin_ios.mm) so
// the GDScript wrapper can stay platform-agnostic. `connect` is avoided as a
// name because it would shadow Object.connect() on the Godot side.

package com.tenjin.godot

import android.util.Log
import com.tenjin.android.TenjinSDK
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONException
import org.json.JSONObject

class TenjinGodotPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "TenjinGodot"

        const val SIGNAL_ATTRIBUTION_INFO_RECEIVED = "attribution_info_received"
        const val SIGNAL_ATTRIBUTION_INFO_FAILED = "attribution_info_failed"
        const val SIGNAL_DEEP_LINK_RECEIVED = "deep_link_received"
    }

    private var instance: TenjinSDK? = null

    override fun getPluginName(): String = "TenjinSDK"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo(SIGNAL_ATTRIBUTION_INFO_RECEIVED, String::class.java),
        SignalInfo(SIGNAL_ATTRIBUTION_INFO_FAILED, String::class.java),
        SignalInfo(SIGNAL_DEEP_LINK_RECEIVED, String::class.java),
    )

    // ---- Lifecycle ---------------------------------------------------------

    @UsedByGodot
    fun initialize(sdkKey: String) {
        val context = activity ?: run {
            Log.e(TAG, "initialize called before the Godot activity is available")
            return
        }
        TenjinSDK.setPluginVersion("godot", BuildConfig.PLUGIN_VERSION)
        instance = TenjinSDK.getInstance(context, sdkKey)
    }

    @UsedByGodot
    fun connectSdk() {
        instance?.connect()
    }

    @UsedByGodot
    fun connectSdkWithDeferredDeeplink(deferredDeeplink: String) {
        instance?.connect(deferredDeeplink)
    }

    @UsedByGodot
    fun setAppStore(type: String) {
        val storeType = when (type) {
            "googleplay" -> TenjinSDK.AppStoreType.googleplay
            "amazon" -> TenjinSDK.AppStoreType.amazon
            "other" -> TenjinSDK.AppStoreType.other
            else -> TenjinSDK.AppStoreType.unspecified
        }
        instance?.setAppStore(storeType)
    }

    // ---- Privacy -----------------------------------------------------------

    @UsedByGodot
    fun optIn() {
        instance?.optIn()
    }

    @UsedByGodot
    fun optOut() {
        instance?.optOut()
    }

    @UsedByGodot
    fun optInParams(params: Array<String>) {
        instance?.optInParams(params)
    }

    @UsedByGodot
    fun optOutParams(params: Array<String>) {
        instance?.optOutParams(params)
    }

    @UsedByGodot
    fun optInOutUsingCMP() {
        instance?.optInOutUsingCMP()
    }

    @UsedByGodot
    fun optInGoogleDMA() {
        instance?.optInGoogleDMA()
    }

    @UsedByGodot
    fun optOutGoogleDMA() {
        instance?.optOutGoogleDMA()
    }

    @UsedByGodot
    fun setGoogleDMAParameters(adPersonalization: Boolean, adUserData: Boolean) {
        instance?.setGoogleDMAParameters(adPersonalization, adUserData)
    }

    // ---- Settings ----------------------------------------------------------

    @UsedByGodot
    fun setCacheEventSetting(setting: Boolean) {
        instance?.setCacheEventSetting(setting)
    }

    @UsedByGodot
    fun setEncryptRequestsSetting(setting: Boolean) {
        instance?.setEncryptRequestsSetting(setting)
    }

    @UsedByGodot
    fun appendAppSubversion(subversion: Int) {
        instance?.appendAppSubversion(subversion)
    }

    // ---- Events & revenue --------------------------------------------------

    @UsedByGodot
    fun eventWithName(name: String) {
        instance?.eventWithName(name)
    }

    @UsedByGodot
    fun eventWithNameAndValue(name: String, value: Int) {
        instance?.eventWithNameAndValue(name, value)
    }

    @UsedByGodot
    fun transaction(productName: String, currencyCode: String, quantity: Int, unitPrice: Double) {
        instance?.transaction(productName, currencyCode, quantity, unitPrice)
    }

    @UsedByGodot
    fun transactionWithDataSignature(
        productName: String,
        currencyCode: String,
        quantity: Int,
        unitPrice: Double,
        purchaseData: String,
        dataSignature: String,
    ) {
        instance?.transaction(productName, currencyCode, quantity, unitPrice, purchaseData, dataSignature)
    }

    @UsedByGodot
    fun subscription(
        productId: String,
        currencyCode: String,
        unitPrice: Double,
        purchaseToken: String,
        purchaseData: String,
        dataSignature: String,
    ) {
        val purchaseTime = try {
            JSONObject(purchaseData).optLong("purchaseTime", 0L)
        } catch (e: JSONException) {
            0L
        }
        instance?.subscription(
            productId, purchaseToken, unitPrice, currencyCode,
            purchaseTime, purchaseData, dataSignature,
        )
    }

    // ---- ILRD --------------------------------------------------------------

    @UsedByGodot
    fun eventAdImpression(network: String, json: String) {
        val sdk = instance ?: return
        try {
            val payload = JSONObject(json)
            when (network) {
                "admob" -> sdk.eventAdImpressionAdMob(payload)
                "applovin" -> sdk.eventAdImpressionAppLovin(payload)
                "ironsource" -> sdk.eventAdImpressionIronSource(payload)
                "hyperbid" -> sdk.eventAdImpressionHyperBid(payload)
                "topon" -> sdk.eventAdImpressionTopOn(payload)
                "tradplus" -> sdk.eventAdImpressionTradPlus(payload)
                "cas" -> sdk.eventAdImpressionCAS(payload)
                "cloudx" -> sdk.eventAdImpressionCloudX(payload)
                else -> Log.w(TAG, "Unknown ad impression network: $network")
            }
        } catch (e: JSONException) {
            Log.w(TAG, "Invalid $network impression JSON: ${e.message}")
        }
    }

    // ---- User --------------------------------------------------------------

    @UsedByGodot
    fun setCustomerUserId(userId: String) {
        instance?.setCustomerUserId(userId)
    }

    @UsedByGodot
    fun getCustomerUserId(): String = instance?.customerUserId ?: ""

    @UsedByGodot
    fun getAnalyticsInstallationId(): String = instance?.analyticsInstallationId ?: ""

    @UsedByGodot
    fun getUserProfileDictionary(): String {
        return try {
            instance?.userProfileDictionary?.let { JSONObject(it).toString() } ?: "{}"
        } catch (t: Throwable) {
            "{}"
        }
    }

    @UsedByGodot
    fun resetUserProfile() {
        instance?.resetUserProfile()
    }

    // ---- Async -------------------------------------------------------------
    //
    // Results arrive on SDK threads. The GDScript wrapper connects to these
    // signals with CONNECT_DEFERRED so handlers always run on the main thread.

    @UsedByGodot
    fun requestAttributionInfo() {
        val sdk = instance ?: run {
            emitSignal(SIGNAL_ATTRIBUTION_INFO_FAILED, "Tenjin is not initialized")
            return
        }
        sdk.getAttributionInfo { data ->
            emitSignal(SIGNAL_ATTRIBUTION_INFO_RECEIVED, JSONObject(data ?: emptyMap<String, String>()).toString())
        }
    }

    /**
     * The Android SDK's deep link API is one-shot (unlike iOS's persistent
     * registerDeepLinkHandler:), so this fetches once per call. The two
     * callback booleans are folded into the JSON payload.
     */
    @UsedByGodot
    fun registerDeepLinkHandler() {
        instance?.getDeeplink { clickedTenjinLink, isFirstSession, params ->
            try {
                val payload = JSONObject(params ?: emptyMap<String, String>())
                payload.put("clicked_tenjin_link", clickedTenjinLink)
                payload.put("is_first_session", isFirstSession)
                emitSignal(SIGNAL_DEEP_LINK_RECEIVED, payload.toString())
            } catch (e: JSONException) {
                Log.w(TAG, "getDeeplink: ${e.message}")
            }
        }
    }
}
