extends Control

const BATTLE_SCENE := preload("res://scenes/BattleScene.tscn")
const BATTLE_BG_TEXTURE := preload("res://assets/sprites/ui/battle_background_homey_v1.png")
const AdaptiveViewportScript = preload("res://scripts/ui/adaptive_viewport.gd")
const OVERLAY_BOTTOM_RESERVE := 0.0

var _battle_scene: Node
var _tablet_decor: TextureRect
var _tablet_decor_tint: ColorRect
var _overlay_root: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_shell()
	_sync_adaptive_layout()
	get_viewport().size_changed.connect(_sync_adaptive_layout)
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
	var overlay_wrapper := Control.new()
	overlay_wrapper.name = "OverlayWrapper"
	overlay_wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_wrapper.clip_contents = true
	overlay_wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_root.add_child(overlay_wrapper)
	overlay_wrapper.add_child(overlay)
	_attach_ui_click_sfx(overlay)
	if overlay is Control:
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.set_deferred("size", overlay_wrapper.size)


func clear_overlay_scene() -> void:
	for child in _overlay_root.get_children():
		child.queue_free()
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_shell() -> void:
	_tablet_decor = TextureRect.new()
	_tablet_decor.name = "TabletDecorBackground"
	_tablet_decor.texture = BATTLE_BG_TEXTURE
	_tablet_decor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tablet_decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tablet_decor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tablet_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tablet_decor)

	_tablet_decor_tint = ColorRect.new()
	_tablet_decor_tint.name = "TabletDecorTint"
	_tablet_decor_tint.color = Color(0.20, 0.14, 0.08, 0.18)
	_tablet_decor_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tablet_decor_tint)

	_battle_scene = BATTLE_SCENE.instantiate()
	add_child(_battle_scene)

	_overlay_root = Control.new()
	_overlay_root.name = "OverlayRoot"
	_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_root.offset_bottom = -OVERLAY_BOTTOM_RESERVE
	_overlay_root.clip_contents = true
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_root)
	_sync_adaptive_layout()


func _sync_adaptive_layout() -> void:
	AdaptiveViewportScript.apply_full_viewport(_tablet_decor, self)
	AdaptiveViewportScript.apply_full_viewport(_tablet_decor_tint, self)
	if _battle_scene is Node2D:
		var battle_node: Node2D = _battle_scene as Node2D
		var origin: Vector2 = AdaptiveViewportScript.apply_centered_node2d(battle_node)
		if _battle_scene.has_method("set_adaptive_content_origin"):
			_battle_scene.call("set_adaptive_content_origin", origin)
	AdaptiveViewportScript.apply_safe_control_frame(_overlay_root, self)


func _attach_ui_click_sfx(root: Node) -> void:
	if root is BaseButton:
		var button := root as BaseButton
		if UiAudio.should_play_for_button(button) and not button.pressed.is_connected(UiAudio.play_ui_click):
			button.pressed.connect(UiAudio.play_ui_click)
	for child in root.get_children():
		_attach_ui_click_sfx(child)
