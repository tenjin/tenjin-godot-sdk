extends Control
## Drives every public Tenjin method from an on-screen button list.

# Replace with your app's SDK key from the Tenjin dashboard.
const SDK_KEY := "YOUR_SDK_KEY"

const EasterEgg := preload("res://easter_egg.gd")
const EASTER_EGG_TAPS := 5
const EASTER_EGG_WINDOW_MS := 2000

var _log: RichTextLabel
var _title_taps: Array[int] = []


func _ready() -> void:
	_build_ui()

	Tenjin.attribution_info_received.connect(func(info: Dictionary) -> void: _print("attribution: %s" % info))
	Tenjin.attribution_info_failed.connect(func(error: String) -> void: _print("attribution failed: %s" % error))
	Tenjin.deep_link_received.connect(func(params: Dictionary) -> void: _print("deep link: %s" % params))

	Tenjin.initialize(SDK_KEY)
	Tenjin.register_deep_link_handler()
	Tenjin.connect_sdk()
	_print("initialized (native SDK available: %s)" % Tenjin.is_available())


func _notification(what: int) -> void:
	# Tenjin expects connect on every foreground.
	if what == NOTIFICATION_APPLICATION_RESUMED:
		Tenjin.connect_sdk()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var column := VBoxContainer.new()
	margin.add_child(column)

	var title := Label.new()
	title.text = "Tenjin Sample"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	title.gui_input.connect(_on_title_input)
	column.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)

	var buttons := VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(buttons)

	_log = RichTextLabel.new()
	_log.custom_minimum_size.y = 320
	_log.scroll_following = true
	column.add_child(_log)

	var actions := {
		"Connect": func() -> void: Tenjin.connect_sdk(),
		"Opt in": func() -> void: Tenjin.opt_in(),
		"Opt out": func() -> void: Tenjin.opt_out(),
		"Opt in/out using CMP": func() -> void: Tenjin.opt_in_out_using_cmp(),
		"Google DMA: allow both": func() -> void: Tenjin.set_google_dma_parameters(true, true),
		"Event: sample_event": func() -> void: Tenjin.event_with_name("sample_event"),
		"Event with value: level=5": func() -> void: Tenjin.event_with_name_and_value("level", 5),
		"Transaction: 0.99 USD": func() -> void: Tenjin.transaction("com.tenjin.sample.coins", "USD", 1, 0.99),
		"SKAN conversion value 10 / high": func() -> void: Tenjin.update_postback_conversion_value(10, "high", false),
		"Set customer user id": func() -> void: Tenjin.set_customer_user_id("sample-user-123"),
		"Get customer user id": func() -> void: _print("customer user id: %s" % Tenjin.get_customer_user_id()),
		"Get analytics installation id": func() -> void: _print("installation id: %s" % Tenjin.get_analytics_installation_id()),
		"Get attribution info": func() -> void: Tenjin.get_attribution_info(),
		"Get user profile": func() -> void: _print("profile: %s" % Tenjin.get_user_profile_dictionary()),
		"Reset user profile": func() -> void: Tenjin.reset_user_profile(),
		"AdMob impression (sample)": func() -> void: Tenjin.event_ad_impression_admob({
			"ad_unit_id": "ca-app-pub-3940256099942544/1033173712",
			"currency_code": "USD",
			"value_micros": 1500,
			"precision_type": "ESTIMATED",
		}),
	}
	for label in actions:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size.y = 64
		var action: Callable = actions[label]
		button.pressed.connect(func() -> void:
			action.call()
			_print("> " + label))
		buttons.add_child(button)


# Tap the title EASTER_EGG_TAPS times within EASTER_EGG_WINDOW_MS. Touches
# arrive as emulated mouse clicks, so only mouse events are counted.
func _on_title_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var now := Time.get_ticks_msec()
	_title_taps.append(now)
	_title_taps = _title_taps.filter(func(t: int) -> bool: return now - t <= EASTER_EGG_WINDOW_MS)
	if _title_taps.size() >= EASTER_EGG_TAPS:
		_title_taps.clear()
		add_child(EasterEgg.new())


func _print(message: String) -> void:
	print("[TenjinSample] ", message)
	if _log:
		_log.append_text(message + "\n")
