extends Control

const GachaResultPanel = preload("res://scripts/gacha/GachaResultPanel.gd")
const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")

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


func _build_ui() -> void:
	var background := AssetResolver.make_fullscreen_background("gacha")
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
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(100.0, 50.0)
	back_button.pressed.connect(func() -> void:
		SceneNavigator.open_overlay_scene("res://scenes/ShopScene.tscn")
	)
	top_row.add_child(back_button)

	var title := Label.new()
	title.text = "誘捕"
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
	pull_intro.text = "選擇本次要進行的誘捕次數。"
	pull_intro.add_theme_font_size_override("font_size", 20)
	root.add_child(pull_intro)

	var options_row := HBoxContainer.new()
	options_row.add_theme_constant_override("separation", 12)
	root.add_child(options_row)

	for option in [
		{"count": 1, "label": "單抽"},
		{"count": 11, "label": "十一抽"},
		{"count": 35, "label": "三十五抽"},
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
	hint.text = "若誘捕籠不足，後端會依規則改以鑽石補足。"
	hint.add_theme_font_size_override("font_size", 18)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)


func refresh_from_bootstrap(show_error_dialog: bool = true) -> void:
	_api_client.get_authenticated_bootstrap(func(success: bool, data: Variant, error: Dictionary) -> void:
		if success and data is Dictionary:
			GameState.apply_player_bootstrap(data)
			_render_overview()
			return
		if show_error_dialog:
			DialogManager.show_info("讀取失敗", str(error.get("message", "無法取得誘捕資料。")))
	)


func _render_overview() -> void:
	var overview := GameState.gacha_data
	var technique_level := int(overview.get("techniqueLevel", 0))
	var total_pulls := int(overview.get("totalPulls", 0))
	var next_required := int(overview.get("nextTechniqueLevelRequiredPulls", 0))
	var next_text := "已達目前最高等級"
	if next_required > total_pulls:
		next_text = "距離下一級還差 %d 抽" % (next_required - total_pulls)
	_overview_label.text = "技巧等級 Lv.%d\n累計誘捕 %d 抽\n%s" % [
		technique_level,
		total_pulls,
		next_text,
	]
	_currency_label.text = "鑽石 %d  |  誘捕籠 %d" % [
		GameState.player_data.diamonds,
		GameState.player_data.trap_cages,
	]

	var options_variant: Variant = overview.get("pullOptions", [])
	var options: Array = options_variant if options_variant is Array else []
	for index in range(_pull_buttons.size()):
		var button := _pull_buttons[index]
		if index >= options.size():
			button.text = "方案 %d" % (index + 1)
			button.disabled = true
			continue
		var option: Dictionary = options[index]
		var count := int(option.get("pullCount", 0))
		var required_cages := int(option.get("requiredTrapCages", 0))
		var diamond_cost := int(option.get("diamondCost", 0))
		button.text = "%d 抽\n誘捕籠 %d / 鑽石 %d" % [count, required_cages, diamond_cost]
		button.disabled = false

	var has_used_free_pull_today := bool(overview.get("hasUsedFreePullToday", false))
	var free_pull_count := int(overview.get("freePullCount", 0))
	if has_used_free_pull_today:
		_free_button.text = "今日免費誘捕已使用"
		_free_button.disabled = true
	else:
		_free_button.text = "免費誘捕 x%d" % maxi(free_pull_count, 1)
		_free_button.disabled = false


func _request_pull(pull_count: int, use_free_pull: bool) -> void:
	var title := "進行誘捕"
	var message := "是否進行 %d 抽？" % pull_count
	if use_free_pull:
		title = "免費誘捕"
		message = "是否使用今日免費誘捕？"
	DialogManager.show_confirm(title, message, func() -> void:
		_api_client.perform_gacha_pull(pull_count, use_free_pull, true, _on_pull_completed)
	)


func _on_pull_button_pressed(pull_count: int) -> void:
	_request_pull(pull_count, false)


func _on_pull_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		DialogManager.show_info("誘捕失敗", str(error.get("message", "無法完成本次誘捕。")))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var results_variant: Variant = payload.get("results", [])
	var results: Array = results_variant if results_variant is Array else []
	GameState.apply_gacha_pull_response(payload)
	_render_overview()
	_show_results(results)


func _show_results(results: Array) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520.0, 520.0)

	var panel := GachaResultPanel.new()
	panel.setup(results)
	scroll.add_child(panel)

	DialogManager.show_info_node("誘捕結果", scroll)
