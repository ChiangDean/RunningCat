extends Control

const BATTLE_SCENE := preload("res://scenes/BattleScene.tscn")
const BATTLE_BG_TEXTURE := preload("res://assets/sprites/ui/battle_background_homey_v1.png")
const AdaptiveViewportScript = preload("res://scripts/ui/adaptive_viewport.gd")
const OVERLAY_BOTTOM_RESERVE := 0.0
const TABLET_SIDE_DIM_COLOR := Color(0.12, 0.08, 0.04, 0.58)
const TABLET_EDGE_SHADOW_COLOR := Color(0.05, 0.03, 0.02, 0.34)
const TABLET_EDGE_SHADOW_WIDTHS: Array[float] = [8.0, 14.0, 22.0, 34.0]
const TABLET_EDGE_SHADOW_ALPHAS: Array[float] = [0.28, 0.20, 0.13, 0.07]

var _battle_scene: Node
var _tablet_decor: TextureRect
var _tablet_decor_tint: ColorRect
var _tablet_side_dim_left: ColorRect
var _tablet_side_dim_right: ColorRect
var _tablet_edge_shadows_left: Array[ColorRect] = []
var _tablet_edge_shadows_right: Array[ColorRect] = []
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

	_tablet_side_dim_left = _make_tablet_dim_panel("TabletSideDimLeft")
	add_child(_tablet_side_dim_left)

	_tablet_side_dim_right = _make_tablet_dim_panel("TabletSideDimRight")
	add_child(_tablet_side_dim_right)

	_build_tablet_edge_shadows()

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
	var viewport_size: Vector2 = AdaptiveViewportScript.get_visible_size(self)
	var content_origin: Vector2 = AdaptiveViewportScript.get_content_origin(self)
	AdaptiveViewportScript.apply_full_viewport(_tablet_decor, self)
	AdaptiveViewportScript.apply_full_viewport(_tablet_decor_tint, self)
	_sync_tablet_side_dim(viewport_size, content_origin)
	_sync_tablet_edge_shadows(viewport_size, content_origin)
	if _battle_scene is Node2D:
		var battle_node: Node2D = _battle_scene as Node2D
		var origin: Vector2 = AdaptiveViewportScript.apply_centered_node2d(battle_node)
		if _battle_scene.has_method("set_adaptive_content_origin"):
			_battle_scene.call("set_adaptive_content_origin", origin)
	AdaptiveViewportScript.apply_safe_control_frame(_overlay_root, self)


func _make_tablet_dim_panel(panel_name: String) -> ColorRect:
	var panel: ColorRect = ColorRect.new()
	panel.name = panel_name
	panel.color = TABLET_SIDE_DIM_COLOR
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _build_tablet_edge_shadows() -> void:
	for index: int in range(TABLET_EDGE_SHADOW_WIDTHS.size()):
		var left_shadow: ColorRect = _make_tablet_edge_shadow("TabletEdgeShadowLeft%d" % index, index)
		_tablet_edge_shadows_left.append(left_shadow)
		add_child(left_shadow)

		var right_shadow: ColorRect = _make_tablet_edge_shadow("TabletEdgeShadowRight%d" % index, index)
		_tablet_edge_shadows_right.append(right_shadow)
		add_child(right_shadow)


func _make_tablet_edge_shadow(shadow_name: String, index: int) -> ColorRect:
	var shadow: ColorRect = ColorRect.new()
	shadow.name = shadow_name
	var alpha: float = TABLET_EDGE_SHADOW_ALPHAS[index]
	shadow.color = Color(
		TABLET_EDGE_SHADOW_COLOR.r,
		TABLET_EDGE_SHADOW_COLOR.g,
		TABLET_EDGE_SHADOW_COLOR.b,
		alpha
	)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shadow


func _sync_tablet_side_dim(viewport_size: Vector2, content_origin: Vector2) -> void:
	var side_width: float = maxf(content_origin.x, 0.0)
	_tablet_side_dim_left.position = Vector2.ZERO
	_tablet_side_dim_left.size = Vector2(side_width, viewport_size.y)
	_tablet_side_dim_left.visible = side_width > 0.0

	_tablet_side_dim_right.position = Vector2(content_origin.x + AdaptiveViewportScript.BASE_SIZE.x, 0.0)
	_tablet_side_dim_right.size = Vector2(maxf(viewport_size.x - _tablet_side_dim_right.position.x, 0.0), viewport_size.y)
	_tablet_side_dim_right.visible = _tablet_side_dim_right.size.x > 0.0


func _sync_tablet_edge_shadows(viewport_size: Vector2, content_origin: Vector2) -> void:
	var has_side_space: bool = content_origin.x > 0.0
	for index: int in range(TABLET_EDGE_SHADOW_WIDTHS.size()):
		var width: float = TABLET_EDGE_SHADOW_WIDTHS[index]
		var left_shadow: ColorRect = _tablet_edge_shadows_left[index]
		left_shadow.position = Vector2(maxf(content_origin.x - width, 0.0), 0.0)
		left_shadow.size = Vector2(minf(width, content_origin.x), viewport_size.y)
		left_shadow.visible = has_side_space

		var right_shadow: ColorRect = _tablet_edge_shadows_right[index]
		right_shadow.position = Vector2(content_origin.x + AdaptiveViewportScript.BASE_SIZE.x, 0.0)
		right_shadow.size = Vector2(minf(width, maxf(viewport_size.x - right_shadow.position.x, 0.0)), viewport_size.y)
		right_shadow.visible = has_side_space


func _attach_ui_click_sfx(root: Node) -> void:
	if root is BaseButton:
		var button := root as BaseButton
		if UiAudio.should_play_for_button(button) and not button.pressed.is_connected(UiAudio.play_ui_click):
			button.pressed.connect(UiAudio.play_ui_click)
	for child in root.get_children():
		_attach_ui_click_sfx(child)
