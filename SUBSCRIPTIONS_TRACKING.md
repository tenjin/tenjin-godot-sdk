# Tenjin – Godot Subscription Tracking

Track subscription purchases with Tenjin for server-side verification and
attribution. Supported on **iOS** and **Android**; on other platforms the calls
do nothing.

## Method

```gdscript
Tenjin.subscription(
	"com.example.monthly",  # product_id (required)
	"USD",                  # currency_code (required)
	9.99,                   # unit_price (required)
	# iOS
	ios_transaction_id,
	ios_original_transaction_id,
	ios_receipt,
	ios_sk_transaction,
	# Android
	android_purchase_token,
	android_purchase_data,
	android_data_signature)
```

Fill the fields for the platform you're on and leave the others as `""`. The
call only forwards the current platform's fields.

### Parameters

| Parameter | Platform | Description |
|-----------|----------|-------------|
| `product_id` | Both | Product identifier |
| `currency_code` | Both | ISO 4217 currency code, e.g. `"USD"` |
| `unit_price` | Both | Price, e.g. `9.99` |
| `ios_transaction_id` | iOS | StoreKit 2 transaction ID |
| `ios_original_transaction_id` | iOS | Original transaction ID (for renewals) |
| `ios_receipt` | iOS | JWS signed transaction |
| `ios_sk_transaction` | iOS | StoreKit 2 transaction `jsonRepresentation` |
| `android_purchase_token` | Android | Purchase token from Google Play Billing |
| `android_purchase_data` | Android | The purchase's original JSON |
| `android_data_signature` | Android | The purchase's signature |

## iOS: `subscription_with_storekit` (recommended)

Most Godot iOS purchase plugins don't expose StoreKit 2 transaction data.
`subscription_with_storekit` fetches the latest StoreKit 2 transaction for the
product natively and sends it to Tenjin, so you only pass the product and price.
It needs iOS 16+.

```gdscript
var error := Tenjin.subscription_with_storekit("com.example.monthly", "USD", 9.99)
if not error.is_empty():
	push_warning("Tenjin subscription failed: %s" % error)
```

Call it after the purchase has completed in your purchase plugin. It returns an
empty string on success and an error message otherwise. On Android it returns an
error without doing anything.

## Android: Godot Google Play Billing

With the official
[Godot Google Play Billing](https://github.com/godot-sdk-integrations/godot-google-play-billing)
plugin, the purchase dictionary already has the token, original JSON and
signature. The price comes from the product details you queried before the
purchase (the subscription offer's pricing phases):

```gdscript
var billing := BillingClient.new()
var prices := {}  # product_id -> {price, currency}

func _ready() -> void:
	add_child(billing)
	billing.connected.connect(func(): billing.query_product_details(
			PackedStringArray(["com.example.monthly"]), BillingClient.ProductType.SUBS))
	billing.query_product_details_response.connect(_on_product_details)
	billing.on_purchase_updated.connect(_on_purchase_updated)
	billing.start_connection()

func _on_product_details(response: Dictionary) -> void:
	for product in response.get("product_details", []):
		var phase: Dictionary = product["subscription_offer_details"][0]["pricing_phases"][-1]
		prices[product["product_id"]] = {
			"price": phase["price_amount_micros"] / 1_000_000.0,
			"currency": phase["price_currency_code"],
		}

func _on_purchase_updated(response: Dictionary) -> void:
	if response["response_code"] != BillingClient.BillingResponseCode.OK:
		return
	for purchase in response["purchases"]:
		var product_id: String = purchase["product_ids"][0]
		var price: Dictionary = prices.get(product_id, {"price": 0.0, "currency": "USD"})
		Tenjin.subscription(product_id, price["currency"], price["price"],
				"", "", "", "",
				purchase["purchase_token"], purchase["original_json"], purchase["signature"])
		billing.acknowledge_purchase(purchase["purchase_token"])
```

The last pricing phase is the recurring price; earlier phases are free trials or
introductory prices. Check the field names against the plugin version you use.

## One-time purchases

Use `transaction_with_receipt` (iOS) or `transaction_with_data_signature`
(Android) for validated one-time purchases. See the [README](README.md#events-and-purchases).
