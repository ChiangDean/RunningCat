extends Control

const SW := 720.0
const SH := 1280.0

const UI = preload("res://scripts/enhance/EnhanceSceneUI.gd")
const Refresh = preload("res://scripts/enhance/EnhanceSceneRefresh.gd")
const Actions = preload("res://scripts/enhance/EnhanceSceneActions.gd")
const ACTION_FLOAT_COLOR := Color(0.93, 0.98, 0.92, 1.0)
const ACTION_FLOAT_RANK_COLOR := Color(0.98, 0.95, 0.84, 1.0)

var _selected_cat_id: String = ""
var _detail_panel: VBoxContainer
var _resource_label: Label
var _detail_resource_label: Label
var _stat_labels: Dictionary = {}
var _food_level_label: Label
var _cat_name_label: Label
var _food_cost_label: Label
var _food_progress_bar: ProgressBar
var _food_progress_label: Label
var _special_cost_label: Label
var _special_point_labels: Dictionary = {}
var _rank_stars_label: Label
var _rank_progress_bar: ProgressBar
var _rank_progress_label: Label
var _rank_upgrade_btn: Button
var _special_plus_btns: Dictionary = {}
var _special_minus_btns: Dictionary = {}
var _special_apply_btn: Button
var _special_reset_btn: Button
var _food_upgrade_btn: Button
var _food_max_btn: Button
var _cat_hscroll: ScrollContainer
var _cats_container: GridContainer
var _cat_scroller: InertialScroller
var _catalog_hscroll: ScrollContainer
var _catalog_container: GridContainer
var _catalog_scroller: InertialScroller
var _detail_dialog_close: Callable = Callable()
var _detail_dialog_scroll: ScrollContainer
var _detail_dialog_scroller: InertialScroller
var _detail_tab: String = "upgrade"
var _detail_tab_btns: Dictionary = {}
var _detail_upgrade_tab: Control
var _detail_skill_tab: Control
var _detail_rank_tab: Control
var _stat_overview_tab: String = "base"
var _stat_overview_tab_btns: Dictionary = {}
var _stat_overview_body: VBoxContainer
var _action_inflight: bool = false
var _special_point_draft: Dictionary = {"hp": 0, "atk": 0, "def": 0}
var _loading_canvas: CanvasLayer
var _loading_overlay: ColorRect
var _loading_label: Label
var _float_canvas: CanvasLayer
var _pending_action_type: String = ""
var _pending_level_before: int = 0
var _pending_rank_before: int = 0
var _submenu_btns: Dictionary = {}
var _active_submenu: String = "main"
var _main_section: Control
var _catalog_section: Control
var _detail_context_submenu: String = ""

@onready var GameState = get_node("/root/GameState")
@onready var ApiClient = get_node("/root/ApiClient")


func _ready() -> void:
	_register_helper_shared_state()
	_build_feedback_layers()
	_build_ui()
	GameState.red_dot_state_changed.connect(_refresh_red_dots)
	if GameState.enhance_data.is_empty():
		_request_enhance_overview()
	_refresh_red_dots()


func _build_feedback_layers() -> void:
	_loading_canvas = CanvasLayer.new()
	_loading_canvas.layer = 120
	add_child(_loading_canvas)

	_loading_overlay = ColorRect.new()
	_loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.color = Color(0.0, 0.0, 0.0, 0.44)
	_loading_overlay.visible = false
	_loading_canvas.add_child(_loading_overlay)

	var loading_center := CenterContainer.new()
	loading_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.add_child(loading_center)

	_loading_label = Label.new()
	_loading_label.text = UiText.ADMIN_STATUS_LOADING
	_loading_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	loading_center.add_child(_loading_label)

	_float_canvas = CanvasLayer.new()
	_float_canvas.layer = 121
	add_child(_float_canvas)


func _register_helper_shared_state() -> void:
	# These scene fields are intentionally read and mutated by helper modules.
	var shared_state_snapshot: Array[Variant] = [
		_resource_label,
		_detail_resource_label,
		_stat_labels,
		_food_level_label,
		_cat_name_label,
		_food_cost_label,
		_food_progress_bar,
		_food_progress_label,
		_special_cost_label,
		_special_point_labels,
		_rank_stars_label,
		_rank_progress_bar,
		_rank_progress_label,
		_rank_upgrade_btn,
		_special_plus_btns,
		_special_minus_btns,
		_special_apply_btn,
		_special_reset_btn,
		_food_upgrade_btn,
		_food_max_btn,
		_cat_hscroll,
		_cats_container,
		_catalog_hscroll,
		_catalog_container,
		_detail_dialog_close,
		_detail_dialog_scroll,
		_detail_dialog_scroller,
		_detail_tab_btns,
		_detail_upgrade_tab,
		_detail_skill_tab,
		_detail_rank_tab,
		_stat_overview_tab_btns,
		_stat_overview_body,
		_action_inflight,
		_submenu_btns,
		_main_section,
		_catalog_section,
	]
	if shared_state_snapshot.is_empty():
		return


func _build_ui() -> void:
	UI.build_ui(self)


func _populate_cat_buttons() -> void:
	UI.populate_cat_buttons(self)


func _populate_catalog_buttons() -> void:
	UI.populate_catalog_buttons(self)


func _refresh_cat_card_sizes() -> void:
	UI.refresh_cat_card_sizes(self)


func _refresh_catalog_card_sizes() -> void:
	UI.refresh_catalog_card_sizes(self)


func _select_cat(cat_id: String) -> void:
	_selected_cat_id = cat_id
	_reset_special_point_draft()
	if _active_submenu == "catalog":
		_populate_catalog_buttons()
	else:
		_populate_cat_buttons()


func _on_cat_button_pressed(cat_id: String) -> void:
	var active_scroller: InertialScroller = _catalog_scroller if _active_submenu == "catalog" else _cat_scroller
	if active_scroller != null and active_scroller.consume_moved():
		return
	_select_cat(cat_id)
	_open_selected_cat_dialog()


func _switch_submenu(submenu_key: String) -> void:
	if _active_submenu == submenu_key:
		return
	_active_submenu = submenu_key
	UI.refresh_submenu_state(self)
	if submenu_key == "catalog":
		_populate_catalog_buttons()
	else:
		_populate_cat_buttons()


func _rebuild_detail_panel() -> void:
	UI.rebuild_detail_panel(self)


func _open_selected_cat_dialog() -> void:
	UI.open_selected_cat_dialog(self)


func _close_selected_cat_dialog() -> void:
	UI.close_selected_cat_dialog(self)


func _on_detail_dialog_closed() -> void:
	UI.on_detail_dialog_closed(self)


func _on_upgrade_one_pressed() -> void:
	Actions.on_upgrade_one_pressed(self)


func _on_upgrade_max_pressed() -> void:
	Actions.on_upgrade_max_pressed(self)


func _on_special_add_pressed(stat_key: String) -> void:
	Actions.on_special_add_pressed(self, stat_key)


func _on_special_remove_pressed(stat_key: String) -> void:
	Actions.on_special_remove_pressed(self, stat_key)


func _on_apply_special_points_pressed() -> void:
	Actions.on_apply_special_points_pressed(self)


func _on_reset_special_points_pressed() -> void:
	Actions.on_reset_special_points_pressed(self)


func _on_rank_upgrade_pressed() -> void:
	Actions.on_rank_upgrade_pressed(self)


func _on_reset_pressed() -> void:
	Actions.on_reset_pressed(self)


func _switch_detail_tab(tab_key: String) -> void:
	_detail_tab = tab_key
	UI.refresh_detail_tab_state(self)


func _switch_stat_overview_tab(tab_key: String) -> void:
	_stat_overview_tab = tab_key
	UI.refresh_stat_overview_tab_state(self)


func _set_loading_overlay(should_show: bool) -> void:
	if _loading_overlay != null:
		_loading_overlay.visible = should_show


func _prepare_action_feedback(action_type: String) -> void:
	_pending_action_type = action_type
	_pending_level_before = 0
	_pending_rank_before = 0
	if _selected_cat_id == "":
		return
	var player_cat: PlayerCatData = GameState.get_player_cat(_selected_cat_id)
	if player_cat == null:
		return
	_pending_level_before = player_cat.cat_food_level
	_pending_rank_before = player_cat.rank


func _play_action_feedback() -> void:
	if _pending_action_type == "" or _selected_cat_id == "":
		return
	var player_cat: PlayerCatData = GameState.get_player_cat(_selected_cat_id)
	if player_cat == null:
		_pending_action_type = ""
		return

	match _pending_action_type:
		"upgrade":
			var level_gain: int = maxi(0, player_cat.cat_food_level - _pending_level_before)
			_show_action_float(UiText.ENHANCE_LEVEL_UP, maxi(1, level_gain), ACTION_FLOAT_COLOR)
		"upgrade_max":
			var max_level_gain: int = maxi(0, player_cat.cat_food_level - _pending_level_before)
			_show_action_float(UiText.ENHANCE_LEVEL_UP, maxi(1, max_level_gain), ACTION_FLOAT_COLOR)
		"rank":
			var rank_gain: int = maxi(0, player_cat.rank - _pending_rank_before)
			_show_action_float(UiText.ENHANCE_RANK_UP, maxi(1, rank_gain), ACTION_FLOAT_RANK_COLOR)

	_pending_action_type = ""
	_pending_level_before = 0
	_pending_rank_before = 0


func _show_action_float(text: String, count: int, color: Color) -> void:
	if _float_canvas == null:
		return
	for idx: int in range(count):
		var label := Label.new()
		label.text = text
		label.modulate = color
		label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
		label.position = Vector2(250.0, 460.0 + idx * 10.0)
		_float_canvas.add_child(label)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - 92.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(label.queue_free)


func _reset_special_point_draft() -> void:
	_special_point_draft = {"hp": 0, "atk": 0, "def": 0}


func _has_special_point_draft() -> bool:
	for stat_key: String in ["hp", "atk", "def"]:
		if int(_special_point_draft.get(stat_key, 0)) != 0:
			return true
	return false


func _get_effective_special_points(player_cat: PlayerCatData) -> Dictionary:
	var result := {
		"hp": int(player_cat.special_food_points.get("hp", 0)) + int(_special_point_draft.get("hp", 0)),
		"atk": int(player_cat.special_food_points.get("atk", 0)) + int(_special_point_draft.get("atk", 0)),
		"def": int(player_cat.special_food_points.get("def", 0)) + int(_special_point_draft.get("def", 0)),
	}
	for stat_key: String in ["hp", "atk", "def"]:
		result[stat_key] = maxi(0, int(result.get(stat_key, 0)))
	return result


func _get_effective_special_total_points(player_cat: PlayerCatData) -> int:
	var effective_points: Dictionary = _get_effective_special_points(player_cat)
	return int(effective_points.get("hp", 0)) + int(effective_points.get("atk", 0)) + int(effective_points.get("def", 0))


func _get_effective_special_food_held(player_cat: PlayerCatData) -> int:
	var base_total := player_cat.get_total_special_points()
	var effective_total: int = _get_effective_special_total_points(player_cat)
	return GameState.player_data.special_cat_food \
		+ PlayerCatData.special_food_total_spent(base_total) \
		- PlayerCatData.special_food_total_spent(effective_total)


func _refresh_all_labels() -> void:
	Refresh.refresh_all_labels(self)
	UI.refresh_stat_overview_tab_state(self)


func _refresh_resource_label() -> void:
	Refresh.refresh_resource_label(self)


func _refresh_stat_labels(cat_data: CatData, player_cat: PlayerCatData) -> void:
	Refresh.refresh_stat_labels(self, cat_data, player_cat)


func _refresh_food_labels(player_cat: PlayerCatData) -> void:
	Refresh.refresh_food_labels(self, player_cat)


func _refresh_special_cost_label(player_cat: PlayerCatData) -> void:
	Refresh.refresh_special_cost_label(self, player_cat)


func _refresh_special_point_labels(player_cat: PlayerCatData) -> void:
	Refresh.refresh_special_point_labels(self, player_cat)


func _refresh_special_buttons(player_cat: PlayerCatData) -> void:
	Refresh.refresh_special_buttons(self, player_cat)


func _refresh_rank_labels(player_cat: PlayerCatData) -> void:
	Refresh.refresh_rank_labels(self, player_cat)


func _refresh_red_dots() -> void:
	_populate_cat_buttons()
	_populate_catalog_buttons()
	if _detail_panel != null and is_instance_valid(_detail_panel) and not _is_catalog_detail_mode():
		_refresh_all_labels()


func _build_skill_section(cat_data: CatData, player_cat: PlayerCatData) -> void:
	Refresh.build_skill_section(self, cat_data, player_cat)


func _show_rank_bonus_info(cat_data: CatData, rank: int) -> void:
	Refresh.show_rank_bonus_info(cat_data, rank)


func _show_skill_bonus_info(skill_d: Dictionary, rank: int, is_active: bool) -> void:
	Refresh.show_skill_bonus_info(skill_d, rank, is_active)


func _stat_display_label(stat: String, eff_type: String) -> String:
	return Refresh.stat_display_label(stat, eff_type)


func _show_confirm(message: String, on_confirm: Callable) -> void:
	DialogManager.show_confirm(UiText.ENHANCE_CONFIRM_TITLE, message, on_confirm)


func _get_display_name(cat_id: String) -> String:
	return Refresh.get_display_name(cat_id)


func _stat_display_name(stat_key: String) -> String:
	return Refresh.stat_display_name(stat_key)


func _make_separator() -> HSeparator:
	return Refresh.make_separator()


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()


func _get_selected_player_cat_id() -> int:
	return Actions.get_selected_player_cat_id(self)


func _request_enhance_overview() -> void:
	Actions.request_enhance_overview(self)


func _is_catalog_detail_mode() -> bool:
	return _detail_context_submenu == "catalog"


func _build_catalog_preview_cat(cat_id: String) -> PlayerCatData:
	var preview := PlayerCatData.new()
	preview.cat_id = cat_id
	preview.cat_food_level = 1
	preview.rank = 0
	preview.special_food_points = {"hp": 0, "atk": 0, "def": 0}
	preview.cat_shards = 0
	return preview


func _run_enhance_action(action: Callable, action_type: String = "", refresh_achievements: bool = false) -> void:
	Actions.run_enhance_action(self, action, action_type, refresh_achievements)


func _on_enhance_action_completed(success: bool, data: Variant, error: Dictionary, refresh_achievements: bool = false) -> void:
	Actions.on_enhance_action_completed(self, success, data, error, refresh_achievements)
