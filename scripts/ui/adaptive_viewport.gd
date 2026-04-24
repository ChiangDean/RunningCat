class_name AdaptiveViewport
extends RefCounted

const BASE_SIZE: Vector2 = Vector2(720.0, 1280.0)


static func get_visible_size(node: Node) -> Vector2:
	var viewport: Viewport = node.get_viewport()
	if viewport == null:
		return BASE_SIZE
	return viewport.get_visible_rect().size


static func get_content_origin(node: Node) -> Vector2:
	var viewport_size: Vector2 = get_visible_size(node)
	return Vector2(
		maxf((viewport_size.x - BASE_SIZE.x) * 0.5, 0.0),
		maxf((viewport_size.y - BASE_SIZE.y) * 0.5, 0.0)
	)


static func apply_centered_node2d(node: Node2D) -> Vector2:
	var origin: Vector2 = get_content_origin(node)
	node.position = origin
	return origin


static func apply_canvas_layer_origin(layer: CanvasLayer, node: Node) -> void:
	if layer == null:
		return
	layer.offset = get_content_origin(node)


static func apply_safe_control_frame(control: Control, node: Node) -> void:
	if control == null:
		return
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.position = get_content_origin(node)
	control.size = BASE_SIZE


static func apply_full_viewport(control: Control, node: Node) -> void:
	if control == null:
		return
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.position = Vector2.ZERO
	control.size = get_visible_size(node)
