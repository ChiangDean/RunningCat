extends Control

const BATTLE_SCENE := preload("res://scenes/BattleScene.tscn")

var _battle_scene: Node
var _overlay_root: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_shell()
	SceneNavigator.register_home_shell(self)


func _exit_tree() -> void:
	SceneNavigator.unregister_home_shell(self)


func show_overlay_scene(scene_path: String) -> void:
	clear_overlay_scene()
	if scene_path == "":
		_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("HomeShellScene: failed to load overlay scene %s" % scene_path)
		_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	var overlay := packed_scene.instantiate()
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_root.add_child(overlay)
	if overlay is Control:
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.set_deferred("size", get_viewport_rect().size)


func clear_overlay_scene() -> void:
	for child in _overlay_root.get_children():
		child.queue_free()
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_shell() -> void:
	_battle_scene = BATTLE_SCENE.instantiate()
	add_child(_battle_scene)

	_overlay_root = Control.new()
	_overlay_root.name = "OverlayRoot"
	_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_root)
