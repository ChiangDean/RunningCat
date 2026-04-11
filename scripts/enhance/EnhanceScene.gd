extends Control

const SW := 720.0
const SH := 1280.0

const UI = preload("res://scripts/enhance/EnhanceSceneUI.gd")
const Refresh = preload("res://scripts/enhance/EnhanceSceneRefresh.gd")
const Actions = preload("res://scripts/enhance/EnhanceSceneActions.gd")

var _selected_cat_id: String = ""
var _detail_panel: VBoxContainer
var _resource_label: Label
var _stat_labels: Dictionary = {}
var _food_level_label: Label
var _cat_name_label: Label
var _food_cost_label: Label
var _special_cost_label: Label
var _special_point_labels: Dictionary = {}
var _rank_stars_label: Label
var _rank_upgrade_btn: Button
var _special_plus_btns: Dictionary = {}
var _special_minus_btns: Dictionary = {}
var _food_upgrade_btn: Button
var _food_max_btn: Button
var _cat_hscroll: ScrollContainer
var _cat_scroller: InertialScroller
var _cat_drag_threshold: float = 8.0
var _action_inflight: bool = false

@onready var GameState = get_node("/root/GameState")
@onready var ApiClient = get_node("/root/ApiClient")


func _ready() -> void:
	_build_ui()
	if GameState.enhance_data.is_empty():
		_request_enhance_overview()


func _build_ui() -> void:
	UI.build_ui(self)


func _populate_cat_buttons() -> void:
	UI.populate_cat_buttons(self)


func _select_cat(cat_id: String) -> void:
	_selected_cat_id = cat_id
	_rebuild_detail_panel()


func _on_cat_button_pressed(cat_id: String) -> void:
	if _cat_scroller != null and _cat_scroller.consume_moved():
		return
	_select_cat(cat_id)


func _rebuild_detail_panel() -> void:
	UI.rebuild_detail_panel(self)


func _on_upgrade_one_pressed() -> void:
	Actions.on_upgrade_one_pressed(self)


func _on_upgrade_max_pressed() -> void:
	Actions.on_upgrade_max_pressed(self)


func _on_special_add_pressed(stat_key: String) -> void:
	Actions.on_special_add_pressed(self, stat_key)


func _on_special_remove_pressed(stat_key: String) -> void:
	Actions.on_special_remove_pressed(self, stat_key)


func _on_rank_upgrade_pressed() -> void:
	Actions.on_rank_upgrade_pressed(self)


func _on_reset_pressed() -> void:
	Actions.on_reset_pressed(self)


func _refresh_all_labels() -> void:
	Refresh.refresh_all_labels(self)


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


func _build_skill_section(cat_data: CatData, player_cat: PlayerCatData) -> void:
	Refresh.build_skill_section(self, cat_data, player_cat)


func _show_rank_bonus_info(cat_data: CatData, rank: int) -> void:
	Refresh.show_rank_bonus_info(cat_data, rank)


func _show_skill_bonus_info(skill_d: Dictionary, rank: int, is_active: bool) -> void:
	Refresh.show_skill_bonus_info(skill_d, rank, is_active)


func _stat_display_label(stat: String, eff_type: String) -> String:
	return Refresh.stat_display_label(stat, eff_type)


func _show_confirm(message: String, on_confirm: Callable) -> void:
	DialogManager.show_confirm("確認", message, on_confirm)


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


func _run_enhance_action(action: Callable, refresh_achievements: bool = false) -> void:
	Actions.run_enhance_action(self, action, refresh_achievements)


func _on_enhance_action_completed(success: bool, data: Variant, error: Dictionary, refresh_achievements: bool = false) -> void:
	Actions.on_enhance_action_completed(self, success, data, error, refresh_achievements)
