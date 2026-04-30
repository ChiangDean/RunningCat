extends Node

const HOME_SHELL_SCENE_PATH := "res://scenes/HomeShellScene.tscn"
const ONBOARDING_SCENE_PATH := "res://scenes/OnboardingScene.tscn"

var _home_shell: Node = null
var _pending_overlay_scene_path: String = ""
var _current_overlay_scene_path: String = ""


func register_home_shell(shell: Node) -> void:
	_home_shell = shell
	if _pending_overlay_scene_path != "":
		var pending_path := _pending_overlay_scene_path
		_pending_overlay_scene_path = ""
		_current_overlay_scene_path = pending_path
		_home_shell.call_deferred("show_overlay_scene", pending_path)


func unregister_home_shell(shell: Node) -> void:
	if _home_shell == shell:
		_home_shell = null


func enter_home_shell() -> void:
	_pending_overlay_scene_path = ""
	_current_overlay_scene_path = ""
	get_tree().change_scene_to_file(HOME_SHELL_SCENE_PATH)


func enter_onboarding() -> void:
	_pending_overlay_scene_path = ""
	_current_overlay_scene_path = ""
	get_tree().change_scene_to_file(ONBOARDING_SCENE_PATH)


func open_overlay_scene(scene_path: String) -> void:
	_current_overlay_scene_path = scene_path
	if _home_shell != null and is_instance_valid(_home_shell):
		_home_shell.call_deferred("show_overlay_scene", scene_path)
		return
	_pending_overlay_scene_path = scene_path
	call_deferred("_change_to_home_shell_for_pending_overlay")


func toggle_overlay_scene(scene_path: String) -> void:
	if _current_overlay_scene_path == scene_path:
		return_to_battle()
		return
	open_overlay_scene(scene_path)


func return_to_battle() -> void:
	_current_overlay_scene_path = ""
	if _home_shell != null and is_instance_valid(_home_shell):
		_home_shell.call_deferred("clear_overlay_scene")
		return
	_pending_overlay_scene_path = ""
	get_tree().change_scene_to_file(HOME_SHELL_SCENE_PATH)


func get_current_overlay_scene_path() -> String:
	return _current_overlay_scene_path


func _change_to_home_shell_for_pending_overlay() -> void:
	if _pending_overlay_scene_path == "":
		return
	get_tree().change_scene_to_file(HOME_SHELL_SCENE_PATH)
