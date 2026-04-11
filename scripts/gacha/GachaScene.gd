extends Control

const GachaResultPanel = preload("res://scripts/gacha/GachaResultPanel.gd")

const SW := 720.0
const SH := 1280.0

var _overview_label: Label
var _currency_label: Label
var _free_button: Button
var _pull_buttons: Array[Button] = []

@onready var _api_client = get_node("/root/ApiClient")


func _ready() -> void:
	_build_ui()
	_render_overview()
	call_deferred("_refresh_overview", false)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.133, 0.157, 0.192, 1.0)
	background.size = Vector2(SW, SH)
	add_child(background)

	var layer := CanvasLayer.new()
	add_child(layer)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_top = 40
	root.offset_right = -20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 16)
	layer.add_child(root)

	var top_row := HBoxContainer.new()
	root.add_child(top_row)

	var back_button := Button.new()
	back_button.text = "\u8fd4\u56de"
	back_button.custom_minimum_size = Vector2(100.0, 50.0)
	back_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ShopScene.tscn")
	)
	top_row.add_child(back_button)

	var title := Label.new()
	title.text = "\u8a98\u6355"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	_overview_label = Label.new()
	_overview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overview_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_overview_label)

	_currency_label = Label.new()
	_currency_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_currency_label)

	root.add_child(HSeparator.new())

	var pull_intro := Label.new()
	pull_intro.text = "\u9078\u64c7\u672c\u6b21\u8981\u9032\u884c\u7684\u8a98\u6355\u6b21\u6578\u3002"
	pull_intro.add_theme_font_size_override("font_size", 20)
	root.add_child(pull_intro)

	var options_row := HBoxContainer.new()
	options_row.add_theme_constant_override("separation", 12)
	root.add_child(options_row)

	for option in [
		{"count": 1, "label": "\u55ae\u62bd"},
		{"count": 11, "label": "\u5341\u4e00\u62bd"},
		{"count": 35, "label": "\u4e09\u5341\u4e94\u62bd"},
	]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 82.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 22)
		var count := int(option["count"])
		button.pressed.connect(_on_pull_button_pressed.bind(count))
		options_row.add_child(button)
		_pull_buttons.append(button)

	_free_button = Button.new()
	_free_button.custom_minimum_size = Vector2(0.0, 72.0)
	_free_button.add_theme_font_size_override("font_size", 24)
	_free_button.pressed.connect(func() -> void:
		_request_pull(1, true)
	)
	root.add_child(_free_button)

	var hint := Label.new()
	hint.text = "\u82e5\u8a98\u6355\u7c60\u4e0d\u8db3\uff0c\u5f8c\u7aef\u6703\u4f9d\u898f\u5247\u6539\u4ee5\u947d\u77f3\u88dc\u8db3\u3002"
	hint.add_theme_font_size_override("font_size", 18)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)


func _refresh_overview(show_error_dialog: bool) -> void:
	_api_client.get_gacha_overview(func(success: bool, data: Variant, error: Dictionary) -> void:
		if success:
			if data is Dictionary:
				GameState.update_gacha(data)
			_render_overview()
			return
		if show_error_dialog:
			DialogManager.show_info("\u8b80\u53d6\u5931\u6557", str(error.get("message", "\u7121\u6cd5\u53d6\u5f97\u8a98\u6355\u8cc7\u6599\u3002")))
	)


func _render_overview() -> void:
	var overview := GameState.gacha_data
	var technique_level := int(overview.get("techniqueLevel", 0))
	var total_pulls := int(overview.get("totalPulls", 0))
	var next_required := int(overview.get("nextTechniqueLevelRequiredPulls", 0))
	var next_text := "\u5df2\u9054\u76ee\u524d\u6700\u9ad8\u7b49\u7d1a"
	if next_required > total_pulls:
		next_text = "\u8ddd\u96e2\u4e0b\u4e00\u7d1a\u9084\u5dee %d \u62bd" % (next_required - total_pulls)
	_overview_label.text = "\u6280\u5de7\u7b49\u7d1a Lv.%d\n\u7d2f\u8a08\u8a98\u6355 %d \u62bd\n%s" % [
		technique_level,
		total_pulls,
		next_text,
	]
	_currency_label.text = "\u947d\u77f3 %d  |  \u8a98\u6355\u7c60 %d" % [
		GameState.player_data.diamonds,
		GameState.player_data.trap_cages,
	]

	var options_variant: Variant = overview.get("pullOptions", [])
	var options: Array = options_variant if options_variant is Array else []
	for index in range(_pull_buttons.size()):
		var button := _pull_buttons[index]
		if index >= options.size():
			button.text = "\u65b9\u6848 %d" % (index + 1)
			button.disabled = true
			continue
		var option: Dictionary = options[index]
		var count := int(option.get("pullCount", 0))
		var required_cages := int(option.get("requiredTrapCages", 0))
		var diamond_cost := int(option.get("diamondCost", 0))
		button.text = "%d \u62bd\n\u8a98\u6355\u7c60 %d / \u947d\u77f3 %d" % [count, required_cages, diamond_cost]
		button.disabled = false

	var has_used_free_pull_today := bool(overview.get("hasUsedFreePullToday", false))
	var free_pull_count := int(overview.get("freePullCount", 0))
	if has_used_free_pull_today:
		_free_button.text = "\u4eca\u65e5\u514d\u8cbb\u8a98\u6355\u5df2\u4f7f\u7528"
		_free_button.disabled = true
	else:
		_free_button.text = "\u514d\u8cbb\u8a98\u6355 x%d" % maxi(free_pull_count, 1)
		_free_button.disabled = false


func _request_pull(pull_count: int, use_free_pull: bool) -> void:
	var title := "\u9032\u884c\u8a98\u6355"
	var message := "\u662f\u5426\u9032\u884c %d \u62bd\uff1f" % pull_count
	if use_free_pull:
		title = "\u514d\u8cbb\u8a98\u6355"
		message = "\u662f\u5426\u4f7f\u7528\u4eca\u65e5\u514d\u8cbb\u8a98\u6355\uff1f"
	DialogManager.show_confirm(title, message, func() -> void:
		_api_client.perform_gacha_pull(pull_count, use_free_pull, true, _on_pull_completed)
	)


func _on_pull_button_pressed(pull_count: int) -> void:
	_request_pull(pull_count, false)


func _on_pull_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		DialogManager.show_info("\u8a98\u6355\u5931\u6557", str(error.get("message", "\u7121\u6cd5\u5b8c\u6210\u672c\u6b21\u8a98\u6355\u3002")))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var overview: Variant = payload.get("overview", {})
	if overview is Dictionary:
		GameState.update_gacha(overview)
	var player_cats: Variant = payload.get("playerCats", [])
	if player_cats is Array:
		GameState.update_player_cats(player_cats)
	var enhance_cats: Variant = payload.get("enhanceCats", [])
	if enhance_cats is Array:
		GameState.update_enhance(enhance_cats)
	_render_overview()
	var results_variant: Variant = payload.get("results", [])
	var results: Array = results_variant if results_variant is Array else []
	_show_results(results)


func _show_results(results: Array) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520.0, 520.0)

	var panel := GachaResultPanel.new()
	panel.setup(results)
	scroll.add_child(panel)

	DialogManager.show_info_node("\u8a98\u6355\u7d50\u679c", scroll)
