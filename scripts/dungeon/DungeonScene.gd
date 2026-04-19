extends Control

const SW := 720.0
const SH := 1280.0

const UI = preload("res://scripts/dungeon/DungeonSceneUI.gd")
const Actions = preload("res://scripts/dungeon/DungeonSceneActions.gd")

var _dungeon_panels: Dictionary = {}
var _action_inflight: bool = false
var _active_dungeon_key: String = ""
var _submenu_buttons: Dictionary = {}
var _ui_layer: CanvasLayer
var _root_vbox: VBoxContainer
var _dungeon_list: VBoxContainer
var _scroll: ScrollContainer

@onready var GameState = get_node("/root/GameState")
@onready var ApiClient = get_node("/root/ApiClient")


func _ready() -> void:
	_build_ui()
	GameState.red_dot_state_changed.connect(_apply_red_dots)
	if GameState.dungeon_overview_data.is_empty():
		_request_dungeon_overview()
	else:
		_rebuild_dungeon_panels()
	_apply_red_dots()


func _build_ui() -> void:
	UI.build_ui(self)


func _rebuild_dungeon_panels() -> void:
	UI.rebuild_dungeon_panels(self)


func _refresh_panel(dungeon_id: int) -> void:
	UI.refresh_panel(self, dungeon_id)


func _apply_red_dots() -> void:
	UI.refresh_red_dots(self)


func _switch_dungeon_tab(dungeon_key: String) -> void:
	if _active_dungeon_key == dungeon_key:
		return
	_active_dungeon_key = dungeon_key
	_rebuild_dungeon_panels()


func _request_dungeon_overview() -> void:
	Actions.request_dungeon_overview(self)


func _on_dungeon_overview_completed(success: bool, data: Variant, error: Dictionary) -> void:
	Actions.on_dungeon_overview_completed(self, success, data, error)


func _on_dungeon_action_completed(success: bool, data: Variant, error: Dictionary) -> void:
	Actions.on_dungeon_action_completed(self, success, data, error)


func _on_ad_pressed(dungeon_id: int) -> void:
	Actions.on_ad_pressed(self, dungeon_id)


func _on_sweep_pressed(dungeon_id: int) -> void:
	Actions.on_sweep_pressed(self, dungeon_id)


func _on_challenge_pressed(dungeon_id: int) -> void:
	Actions.on_challenge_pressed(self, dungeon_id)


func _show_reward_popup(header: String, level: int, rewards: Dictionary) -> void:
	Actions.show_reward_popup(header, level, rewards)


func _get_local_dungeon_cfg(dungeon_key: String) -> Dictionary:
	for cfg: Dictionary in GameState.dungeon_config.get("dungeons", []):
		var cfg_id: String = str(cfg.get("id", ""))
		if cfg_id == dungeon_key:
			return cfg
		if cfg_id.get_basename() == dungeon_key:
			return cfg
	return {}


func _on_back_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ActivityScene.tscn")
