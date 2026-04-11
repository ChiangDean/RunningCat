extends Node

const HOME_SHELL_SCENE_PATH := "res://scenes/HomeShellScene.tscn"

var _home_shell: Node = null
var _pending_overlay_scene_path: String = ""


func register_home_shell(shell: Node) -> void:
	_home_shell = shell
	if _pending_overlay_scene_path != "":
		var pending_path := _pending_overlay_scene_path
		_pending_overlay_scene_path = ""
		_home_shell.call_deferred("show_overlay_scene", pending_path)


func unregister_home_shell(shell: Node) -> void:
	if _home_shell == shell:
		_home_shell = null


func enter_home_shell() -> void:
	_pending_overlay_scene_path = ""
	get_tree().change_scene_to_file(HOME_SHELL_SCENE_PATH)


func open_overlay_scene(scene_path: String) -> void:
	if _home_shell != null and is_instance_valid(_home_shell):
		_home_shell.call_deferred("show_overlay_scene", scene_path)
		return
	_pending_overlay_scene_path = scene_path
	get_tree().change_scene_to_file(HOME_SHELL_SCENE_PATH)


func return_to_battle() -> void:
	if _home_shell != null and is_instance_valid(_home_shell):
		_home_shell.call_deferred("clear_overlay_scene")
		return
	_pending_overlay_scene_path = ""
	get_tree().change_scene_to_file(HOME_SHELL_SCENE_PATH)
