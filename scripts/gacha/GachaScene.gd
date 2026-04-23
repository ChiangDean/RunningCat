extends Control

const GachaResultPanel = preload("res://scripts/gacha/GachaResultPanel.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const RedDotService = preload("res://scripts/ui/red_dot_service.gd")
const BUTTON_BAR_TEXTURE = preload("res://assets/sprites/ui/common/button_bar_m_default.png")
const CONTENT_XL_TEXTURE = preload("res://assets/sprites/ui/common/content_xl_default_v1.png")

var _active_tab: String = "pull"
var _tab_buttons: Dictionary = {}
var _content_box: VBoxContainer
var _pull_panel: Control
var _pull_option_list: VBoxContainer
var _free_button: Button
var _technique_panel: Control
var _technique_title: Label
var _technique_desc: Label
var _technique_level_status: Label
var _technique_prev_button: Button
var _technique_next_button: Button
var _technique_list: VBoxContainer
var _selected_technique_level: int = 0

@onready var _api_client = get_node("/root/ApiClient")


func _ready() -> void:
	_build_ui()
	GameState.red_dot_state_changed.connect(_apply_red_dots)
	_refresh_view()


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "gacha", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": [
			{
				"key": "pull",
				"label": UiText.GACHA_TAB_PULL,
				"shell_description": UiText.GACHA_PULL_DESC,
				"shell_summary_left": Callable(self, "_build_shell_summary_left"),
				"shell_summary_right": Callable(self, "_build_shell_summary_right").bind("pull"),
			},
			{
				"key": "technique",
				"label": UiText.GACHA_TAB_TECHNIQUE,
				"shell_description": UiText.GACHA_TECHNIQUE_SHELL_DESC,
				"shell_summary_left": Callable(self, "_build_shell_summary_left"),
				"shell_summary_right": Callable(self, "_build_shell_summary_right").bind("technique"),
			},
		],
		"active_key": _active_tab,
		"button_pressed": Callable(self, "_switch_tab"),
		"button_height": 52.0,
		"font_size": 20,
	})
	_tab_buttons = chrome.get("dock_buttons", {})

	_content_box = chrome.get("content_box")

	var pull_box: VBoxContainer = VBoxContainer.new()
	pull_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pull_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pull_box.add_theme_constant_override("separation", 12)
	_pull_panel = pull_box
	_content_box.add_child(_pull_panel)

	_pull_option_list = VBoxContainer.new()
	_pull_option_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pull_option_list.add_theme_constant_override("separation", 10)
	pull_box.add_child(_pull_option_list)

	_free_button = Button.new()
	_free_button.custom_minimum_size = Vector2(0.0, 52.0)
	_free_button.pressed.connect(func() -> void:
		_request_pull(1, true)
	)
	UiPalette.apply_button_kind(_free_button, "confirm")
	pull_box.add_child(_free_button)

	_technique_panel = Control.new()
	_technique_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_technique_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_child(_technique_panel)

	var technique_background: TextureRect = TextureRect.new()
	technique_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	technique_background.texture = CONTENT_XL_TEXTURE
	technique_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	technique_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	technique_background.stretch_mode = TextureRect.STRETCH_SCALE
	_technique_panel.add_child(technique_background)

	var technique_margin: MarginContainer = OverlaySceneChrome.make_content_margin(24)
	technique_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_technique_panel.add_child(technique_margin)

	var technique_box: VBoxContainer = VBoxContainer.new()
	technique_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	technique_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	technique_box.add_theme_constant_override("separation", 12)
	technique_margin.add_child(technique_box)

	_technique_title = Label.new()
	_technique_title.add_theme_font_size_override("font_size", 30)
	_technique_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	technique_box.add_child(_technique_title)

	_technique_desc = Label.new()
	_technique_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_technique_desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	_technique_desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	technique_box.add_child(_technique_desc)

	var technique_scroll: ScrollContainer = ScrollContainer.new()
	technique_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	technique_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	technique_box.add_child(technique_scroll)
	InertialScroller.attach(technique_scroll, "vertical")

	_technique_list = VBoxContainer.new()
	_technique_list.add_theme_constant_override("separation", 10)
	_technique_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	technique_scroll.add_child(_technique_list)

	var technique_nav_row: HBoxContainer = HBoxContainer.new()
	technique_nav_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	technique_nav_row.add_theme_constant_override("separation", 12)
	technique_box.add_child(technique_nav_row)

	_technique_prev_button = Button.new()
	_technique_prev_button.text = UiText.GACHA_TECHNIQUE_PREV
	_technique_prev_button.custom_minimum_size = Vector2(132.0, 46.0)
	_technique_prev_button.pressed.connect(_on_technique_prev_pressed)
	UiPalette.apply_button_kind(_technique_prev_button, "secondary")
	technique_nav_row.add_child(_technique_prev_button)

	_technique_level_status = Label.new()
	_technique_level_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_technique_level_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_technique_level_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_technique_level_status.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	_technique_level_status.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	technique_nav_row.add_child(_technique_level_status)

	_technique_next_button = Button.new()
	_technique_next_button.text = UiText.GACHA_TECHNIQUE_NEXT
	_technique_next_button.custom_minimum_size = Vector2(132.0, 46.0)
	_technique_next_button.pressed.connect(_on_technique_next_pressed)
	UiPalette.apply_button_kind(_technique_next_button, "secondary")
	technique_nav_row.add_child(_technique_next_button)

func refresh_from_bootstrap(show_error_dialog: bool = true) -> void:
	_api_client.get_authenticated_bootstrap(func(success: bool, data: Variant, error: Dictionary) -> void:
		if success and data is Dictionary:
			GameState.apply_player_bootstrap(data)
			_refresh_view()
			return
		if show_error_dialog:
			ToastManager.error(UiText.GACHA_LOAD_FAILED_TITLE, str(error.get("message", UiText.GACHA_LOAD_FAILED_BODY)))
	)


func _switch_tab(tab_key: String) -> void:
	if _active_tab == tab_key:
		return
	_active_tab = tab_key
	if _active_tab == "technique":
		_selected_technique_level = int(GameState.gacha_data.get("techniqueLevel", 0))
	_refresh_view()


func _refresh_view() -> void:
	_refresh_pull_options()
	_refresh_technique_panel()
	_refresh_panel_state()
	_apply_red_dots()
	SceneSubmenuBar.refresh(_tab_buttons, _active_tab, {
		"active_color": Color(1.0, 0.95, 0.82, 1.0),
		"inactive_color": Color(0.65, 0.65, 0.68, 1.0),
	})

func _refresh_pull_options() -> void:
	for child in _pull_option_list.get_children():
		child.queue_free()

	var options_variant: Variant = GameState.gacha_data.get("pullOptions", [])
	var options: Array = options_variant if options_variant is Array else []
	if options.is_empty():
		_pull_option_list.add_child(_build_empty_card(UiText.GACHA_PULL_EMPTY))
	else:
		for option_variant: Variant in options:
			if option_variant is Dictionary:
				_pull_option_list.add_child(_build_pull_option_card(option_variant))

	var has_used_free_pull_today: bool = bool(GameState.gacha_data.get("hasUsedFreePullToday", false))
	var free_pull_count: int = int(GameState.gacha_data.get("freePullCount", 0))
	if has_used_free_pull_today:
		_free_button.text = UiText.GACHA_FREE_PULL_USED
		_free_button.disabled = true
	else:
		_free_button.text = UiText.GACHA_FREE_PULL_FORMAT % maxi(free_pull_count, 1)
		_free_button.disabled = false
	_apply_red_dots()


func _apply_red_dots() -> void:
	var has_free_pull_red_dot: bool = _free_button != null and not _free_button.disabled and RedDotService.has_gacha_free_pull_red_dot()
	RedDotService.refresh_dot(_free_button, has_free_pull_red_dot)
	RedDotService.refresh_dot(_tab_buttons.get("pull") as Control, has_free_pull_red_dot)


func _refresh_technique_panel() -> void:
	for child in _technique_list.get_children():
		child.queue_free()

	var overview: Dictionary = GameState.gacha_data
	var technique_level: int = int(overview.get("techniqueLevel", 0))
	var total_pulls: int = int(overview.get("totalPulls", 0))
	var next_required: int = int(overview.get("nextTechniqueLevelRequiredPulls", 0))

	var levels_variant: Variant = GameState.gacha_config.get("technique_levels", [])
	var levels: Array = levels_variant if levels_variant is Array else []
	if levels.is_empty():
		_technique_title.text = UiText.GACHA_TECHNIQUE_TITLE_FORMAT % technique_level
		_technique_desc.text = UiText.GACHA_TECHNIQUE_EMPTY
		_technique_level_status.text = ""
		_technique_prev_button.disabled = true
		_technique_next_button.disabled = true
		return

	var level_items: Array[Dictionary] = []
	for level_variant: Variant in levels:
		if level_variant is Dictionary:
			level_items.append(level_variant)
	level_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("level", 0)) < int(b.get("level", 0))
	)

	if _selected_technique_level <= 0:
		_selected_technique_level = technique_level
	if _selected_technique_level <= 0 and not level_items.is_empty():
		_selected_technique_level = int(level_items[0].get("level", 0))

	var selected_index: int = 0
	var found_selected: bool = false
	for index: int in range(level_items.size()):
		if int(level_items[index].get("level", 0)) == _selected_technique_level:
			selected_index = index
			found_selected = true
			break
	if not found_selected:
		selected_index = mini(maxi(technique_level - 1, 0), level_items.size() - 1)
		_selected_technique_level = int(level_items[selected_index].get("level", 0))

	var selected_level_data: Dictionary = level_items[selected_index]
	var selected_level: int = int(selected_level_data.get("level", 0))

	_technique_title.text = UiText.GACHA_TECHNIQUE_TITLE_FORMAT % selected_level
	if selected_level == technique_level:
		if next_required > total_pulls:
			_technique_desc.text = UiText.GACHA_TECHNIQUE_PROGRESS_FORMAT % [total_pulls, next_required]
		else:
			_technique_desc.text = UiText.GACHA_TECHNIQUE_MAX_DESC
	else:
		var selected_required: int = int(selected_level_data.get("required_pulls", 0))
		_technique_desc.text = UiText.GACHA_TECHNIQUE_CONDITION_FORMAT % [selected_level, selected_required]

	_technique_level_status.text = "%d / %d" % [selected_index + 1, level_items.size()]
	_technique_prev_button.disabled = selected_index <= 0
	_technique_next_button.disabled = selected_index >= level_items.size() - 1
	_technique_list.add_child(_build_technique_level_card(selected_level_data, technique_level, total_pulls))


func _refresh_panel_state() -> void:
	if _pull_panel != null:
		_pull_panel.visible = _active_tab == "pull"
	if _technique_panel != null:
		_technique_panel.visible = _active_tab == "technique"


func _build_pull_option_card(option: Dictionary) -> Control:
	var shell: Control = Control.new()
	shell.custom_minimum_size = Vector2(0.0, 104.0)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var background: TextureRect = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = BUTTON_BAR_TEXTURE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	shell.add_child(background)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	shell.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)

	var count: int = int(option.get("pullCount", 0))
	var required_cages: int = int(option.get("requiredTrapCages", 0))

	var title: Label = Label.new()
	title.text = UiText.GACHA_PULL_COUNT_FORMAT % count
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info.add_child(title)

	var button: Button = Button.new()
	button.text = UiText.GACHA_PULL_CAGE_COST_FORMAT % required_cages
	button.custom_minimum_size = Vector2(196.0, 50.0)
	button.pressed.connect(_on_pull_button_pressed.bind(count))
	UiPalette.apply_button_kind(button, "primary")
	row.add_child(button)

	return shell


func _build_technique_level_card(level_data: Dictionary, _current_level: int, _total_pulls: int) -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)

	var rates_variant: Variant = level_data.get("rates", {})
	var rates: Dictionary = rates_variant if rates_variant is Dictionary else {}

	var rate_title: Label = Label.new()
	rate_title.text = UiText.GACHA_RATE_LIST_TITLE
	rate_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	rate_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	root.add_child(rate_title)

	var rate_list: VBoxContainer = VBoxContainer.new()
	rate_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rate_list.add_theme_constant_override("separation", 14)
	root.add_child(rate_list)

	var rate_list_margin: MarginContainer = MarginContainer.new()
	rate_list_margin.add_theme_constant_override("margin_left", 18)
	rate_list_margin.add_theme_constant_override("margin_right", 18)
	rate_list.add_child(rate_list_margin)

	var rate_list_box: VBoxContainer = VBoxContainer.new()
	rate_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rate_list_box.add_theme_constant_override("separation", 12)
	rate_list_margin.add_child(rate_list_box)

	for rarity_key: String in _get_rate_order():
		var rate_row: HBoxContainer = HBoxContainer.new()
		rate_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rate_row.add_theme_constant_override("separation", 16)
		rate_list_box.add_child(rate_row)

		var rarity_label: Label = Label.new()
		rarity_label.text = _format_rarity_name(rarity_key)
		rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rarity_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		rarity_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
		rate_row.add_child(rarity_label)

		var rate_value: Label = Label.new()
		rate_value.text = "%.2f%%" % float(rates.get(rarity_key, 0.0))
		rate_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rate_value.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		rate_value.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		rate_row.add_child(rate_value)

	return root


func _build_empty_card(message: String) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.CARD_BORDER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	panel.add_child(margin)

	var label: Label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	margin.add_child(label)

	return panel


func _on_technique_prev_pressed() -> void:
	var levels_variant: Variant = GameState.gacha_config.get("technique_levels", [])
	var levels: Array = levels_variant if levels_variant is Array else []
	var previous_level: int = _find_adjacent_technique_level(levels, _selected_technique_level, -1)
	if previous_level == _selected_technique_level:
		return
	_selected_technique_level = previous_level
	_refresh_technique_panel()


func _on_technique_next_pressed() -> void:
	var levels_variant: Variant = GameState.gacha_config.get("technique_levels", [])
	var levels: Array = levels_variant if levels_variant is Array else []
	var next_level: int = _find_adjacent_technique_level(levels, _selected_technique_level, 1)
	if next_level == _selected_technique_level:
		return
	_selected_technique_level = next_level
	_refresh_technique_panel()


func _find_adjacent_technique_level(levels: Array, selected_level: int, direction: int) -> int:
	var sorted_levels: Array[int] = []
	for level_variant: Variant in levels:
		if level_variant is Dictionary:
			sorted_levels.append(int(level_variant.get("level", 0)))
	sorted_levels.sort()
	if sorted_levels.is_empty():
		return selected_level
	var current_index: int = sorted_levels.find(selected_level)
	if current_index < 0:
		current_index = 0
	var next_index: int = clampi(current_index + direction, 0, sorted_levels.size() - 1)
	return sorted_levels[next_index]


func _request_pull(pull_count: int, use_free_pull: bool) -> void:
	var title: String = UiText.GACHA_PULL_CONFIRM_TITLE
	var message: String = UiText.GACHA_PULL_CONFIRM_BODY % pull_count
	if use_free_pull:
		title = UiText.GACHA_FREE_PULL_TITLE
		message = UiText.GACHA_FREE_PULL_CONFIRM_BODY
	DialogManager.show_confirm(title, message, func() -> void:
		_api_client.perform_gacha_pull(pull_count, use_free_pull, true, _on_pull_completed)
	)


func _on_pull_button_pressed(pull_count: int) -> void:
	_request_pull(pull_count, false)


func _on_pull_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.GACHA_PULL_FAILED_TITLE, str(error.get("message", UiText.GACHA_PULL_FAILED_BODY)))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var results_variant: Variant = payload.get("results", [])
	var results: Array = results_variant if results_variant is Array else []
	GameState.apply_gacha_pull_response(payload)
	_refresh_view()
	_show_results(results)


func _show_results(results: Array) -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520.0, 520.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	InertialScroller.attach(scroll, "vertical")

	var panel: GachaResultPanel = GachaResultPanel.new()
	panel.setup(results)
	scroll.add_child(panel)

	DialogManager.show_info_node(UiText.GACHA_RESULT_TITLE, scroll)


func _format_rarity_name(rarity_key: String) -> String:
	var rarities_variant: Variant = GameState.gacha_config.get("rarities", [])
	if rarities_variant is Array:
		for rarity_variant: Variant in rarities_variant:
			if not (rarity_variant is Dictionary):
				continue
			var rarity: Dictionary = rarity_variant
			if str(rarity.get("id", "")) == rarity_key:
				return str(rarity.get("name", rarity_key))
	return rarity_key.capitalize()


func _get_rate_order() -> Array[String]:
	var rate_order: Array[String] = [
		"legendary",
		"epic",
		"rare",
		"excellent",
		"precious",
		"special",
		"fine",
		"uncommon",
		"common",
	]
	return rate_order


func _build_shell_summary_left() -> String:
	return UiText.GACHA_RESOURCE_FORMAT % [
		GameState.player_data.diamonds,
		GameState.player_data.trap_cages,
	]


func _build_shell_summary_right(tab_key: String) -> String:
	var overview: Dictionary = GameState.gacha_data
	var total_pulls: int = int(overview.get("totalPulls", 0))
	if tab_key == "technique":
		var technique_level: int = int(overview.get("techniqueLevel", 0))
		return UiText.GACHA_SHELL_TECHNIQUE_SUMMARY_FORMAT % [technique_level, total_pulls]

	var free_pull_count: int = int(overview.get("freePullCount", 0))
	var has_used_free_pull_today: bool = bool(overview.get("hasUsedFreePullToday", false))
	var free_text: String = UiText.GACHA_SHELL_FREE_STATUS_USED if has_used_free_pull_today else str(maxi(free_pull_count, 1))
	return UiText.GACHA_SHELL_FREE_SUMMARY_FORMAT % [free_text, total_pulls]


func _on_back_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ActivityScene.tscn")
