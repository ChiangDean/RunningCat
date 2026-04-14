extends Control

const GachaResultPanel = preload("res://scripts/gacha/GachaResultPanel.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")

var _active_tab: String = "pull"
var _tab_buttons: Dictionary = {}
var _resource_label: Label
var _pull_summary_label: Label
var _pull_option_list: VBoxContainer
var _free_button: Button
var _technique_title: Label
var _technique_desc: Label
var _technique_list: VBoxContainer

@onready var _api_client = get_node("/root/ApiClient")


func _ready() -> void:
	_build_ui()
	_refresh_view()


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "gacha", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": [
			{"key": "pull", "label": UiText.GACHA_TAB_PULL},
			{"key": "technique", "label": UiText.GACHA_TAB_TECHNIQUE},
		],
		"active_key": _active_tab,
		"button_pressed": Callable(self, "_switch_tab"),
		"button_height": 52.0,
		"font_size": 20,
	})
	_tab_buttons = chrome.get("dock_buttons", {})

	var content_box: VBoxContainer = chrome.get("content_box")

	_resource_label = Label.new()
	_resource_label.add_theme_font_size_override("font_size", 20)
	_resource_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	content_box.add_child(_resource_label)

	_pull_summary_label = Label.new()
	_pull_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pull_summary_label.add_theme_font_size_override("font_size", 20)
	_pull_summary_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	content_box.add_child(_pull_summary_label)

	var pull_panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	pull_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_child(pull_panel)

	var pull_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	pull_panel.add_child(pull_margin)

	var pull_box: VBoxContainer = VBoxContainer.new()
	pull_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pull_box.add_theme_constant_override("separation", 12)
	pull_margin.add_child(pull_box)

	var pull_intro: Label = Label.new()
	pull_intro.text = UiText.GACHA_PULL_DESC
	pull_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pull_intro.add_theme_font_size_override("font_size", 18)
	pull_intro.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	pull_box.add_child(pull_intro)

	_pull_option_list = VBoxContainer.new()
	_pull_option_list.add_theme_constant_override("separation", 10)
	pull_box.add_child(_pull_option_list)

	_free_button = Button.new()
	_free_button.custom_minimum_size = Vector2(0.0, 52.0)
	_free_button.pressed.connect(func() -> void:
		_request_pull(1, true)
	)
	UiPalette.apply_button_kind(_free_button, "rank")
	pull_box.add_child(_free_button)

	var hint: Label = Label.new()
	hint.text = UiText.GACHA_PULL_HINT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	pull_box.add_child(hint)

	var technique_panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.CARD_BORDER)
	technique_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_child(technique_panel)

	var technique_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	technique_panel.add_child(technique_margin)

	var technique_box: VBoxContainer = VBoxContainer.new()
	technique_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	technique_box.add_theme_constant_override("separation", 12)
	technique_margin.add_child(technique_box)

	_technique_title = Label.new()
	_technique_title.add_theme_font_size_override("font_size", 30)
	_technique_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	technique_box.add_child(_technique_title)

	_technique_desc = Label.new()
	_technique_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_technique_desc.add_theme_font_size_override("font_size", 18)
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

	pull_panel.name = "PullPanel"
	technique_panel.name = "TechniquePanel"


func refresh_from_bootstrap(show_error_dialog: bool = true) -> void:
	_api_client.get_authenticated_bootstrap(func(success: bool, data: Variant, error: Dictionary) -> void:
		if success and data is Dictionary:
			GameState.apply_player_bootstrap(data)
			_refresh_view()
			return
		if show_error_dialog:
			DialogManager.show_info(UiText.GACHA_LOAD_FAILED_TITLE, str(error.get("message", UiText.GACHA_LOAD_FAILED_BODY)))
	)


func _switch_tab(tab_key: String) -> void:
	if _active_tab == tab_key:
		return
	_active_tab = tab_key
	_refresh_view()


func _refresh_view() -> void:
	_refresh_summary()
	_refresh_pull_options()
	_refresh_technique_panel()
	_refresh_panel_state()
	SceneSubmenuBar.refresh(_tab_buttons, _active_tab, {
		"active_color": Color(1.0, 0.95, 0.82, 1.0),
		"inactive_color": Color(0.65, 0.65, 0.68, 1.0),
	})


func _refresh_summary() -> void:
	var overview: Dictionary = GameState.gacha_data
	var technique_level: int = int(overview.get("techniqueLevel", 0))
	var total_pulls: int = int(overview.get("totalPulls", 0))
	var next_required: int = int(overview.get("nextTechniqueLevelRequiredPulls", 0))
	var remaining_text: String = UiText.GACHA_TECHNIQUE_MAX
	if next_required > total_pulls:
		remaining_text = UiText.GACHA_TECHNIQUE_NEXT_FORMAT % (next_required - total_pulls)

	_resource_label.text = UiText.GACHA_RESOURCE_FORMAT % [
		GameState.player_data.diamonds,
		GameState.player_data.trap_cages,
	]
	_pull_summary_label.text = UiText.GACHA_SUMMARY_FORMAT % [
		technique_level,
		total_pulls,
		remaining_text,
	]


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


func _refresh_technique_panel() -> void:
	for child in _technique_list.get_children():
		child.queue_free()

	var overview: Dictionary = GameState.gacha_data
	var technique_level: int = int(overview.get("techniqueLevel", 0))
	var total_pulls: int = int(overview.get("totalPulls", 0))
	var next_required: int = int(overview.get("nextTechniqueLevelRequiredPulls", 0))

	_technique_title.text = UiText.GACHA_TECHNIQUE_TITLE_FORMAT % technique_level
	if next_required > total_pulls:
		_technique_desc.text = UiText.GACHA_TECHNIQUE_PROGRESS_FORMAT % [total_pulls, next_required]
	else:
		_technique_desc.text = UiText.GACHA_TECHNIQUE_MAX_DESC

	var levels_variant: Variant = GameState.gacha_config.get("technique_levels", [])
	var levels: Array = levels_variant if levels_variant is Array else []
	if levels.is_empty():
		_technique_list.add_child(_build_empty_card(UiText.GACHA_TECHNIQUE_EMPTY))
		return

	for level_variant: Variant in levels:
		if level_variant is Dictionary:
			_technique_list.add_child(_build_technique_level_card(level_variant, technique_level, total_pulls))


func _refresh_panel_state() -> void:
	var content_box: VBoxContainer = _resource_label.get_parent()
	if content_box == null:
		return
	var pull_panel: Control = content_box.get_node_or_null("PullPanel")
	var technique_panel: Control = content_box.get_node_or_null("TechniquePanel")
	if pull_panel != null:
		pull_panel.visible = _active_tab == "pull"
	if technique_panel != null:
		technique_panel.visible = _active_tab == "technique"


func _build_pull_option_card(option: Dictionary) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.CARD_BORDER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)

	var count: int = int(option.get("pullCount", 0))
	var required_cages: int = int(option.get("requiredTrapCages", 0))
	var diamond_cost: int = int(option.get("diamondCost", 0))

	var title: Label = Label.new()
	title.text = UiText.GACHA_PULL_COUNT_FORMAT % count
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.GACHA_PULL_COST_FORMAT % [required_cages, diamond_cost]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info.add_child(desc)

	var button: Button = Button.new()
	button.text = UiText.GACHA_PULL_ACTION
	button.custom_minimum_size = Vector2(160.0, 52.0)
	button.pressed.connect(_on_pull_button_pressed.bind(count))
	UiPalette.apply_button_kind(button, "primary")
	row.add_child(button)

	return panel


func _build_technique_level_card(level_data: Dictionary, current_level: int, total_pulls: int) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(
		OverlaySceneChrome.PANEL_BORDER if int(level_data.get("level", 0)) == current_level else OverlaySceneChrome.CARD_BORDER
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)

	var level: int = int(level_data.get("level", 0))
	var required_pulls: int = int(level_data.get("required_pulls", 0))

	var title: Label = Label.new()
	title.text = UiText.GACHA_TECHNIQUE_LEVEL_FORMAT % level
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	header.add_child(title)

	var state: Label = Label.new()
	state.text = UiText.GACHA_TECHNIQUE_CONDITION_FORMAT % [level, required_pulls]
	state.add_theme_font_size_override("font_size", 16)
	state.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	header.add_child(state)

	var progress: Label = Label.new()
	if level < current_level or required_pulls <= total_pulls:
		progress.text = UiText.GACHA_TECHNIQUE_UNLOCKED
	else:
		progress.text = UiText.GACHA_TECHNIQUE_REQUIRED_FORMAT % required_pulls
	progress.add_theme_font_size_override("font_size", 16)
	progress.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	root.add_child(progress)

	var rates_variant: Variant = level_data.get("rates", {})
	var rates: Dictionary = rates_variant if rates_variant is Dictionary else {}
	if rates.is_empty():
		var empty: Label = Label.new()
		empty.text = UiText.GACHA_TECHNIQUE_RATE_EMPTY
		empty.add_theme_font_size_override("font_size", 17)
		empty.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		root.add_child(empty)
	else:
		for rarity_key: String in _get_rate_order():
			if not rates.has(rarity_key):
				continue
			var rate_label: Label = Label.new()
			rate_label.text = UiText.GACHA_TECHNIQUE_RATE_LINE_FORMAT % [_format_rarity_name(rarity_key), float(rates.get(rarity_key, 0.0))]
			rate_label.add_theme_font_size_override("font_size", 17)
			rate_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
			root.add_child(rate_label)

	return panel


func _build_empty_card(message: String) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.CARD_BORDER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	panel.add_child(margin)

	var label: Label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	margin.add_child(label)

	return panel


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
		DialogManager.show_info(UiText.GACHA_PULL_FAILED_TITLE, str(error.get("message", UiText.GACHA_PULL_FAILED_BODY)))
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
	return [
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


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
