class_name BadgeOverlay
extends RefCounted

const _META_KEY := "_badge_node"

const DOT_SIZE := 14.0
const BADGE_H := 18.0
const BADGE_MIN_W := 18.0
const BADGE_OFFSET := Vector2(-12.0, 10.0)
const DOT_COLOR := Color(0.92, 0.22, 0.22, 1.0)
const DOT_BORDER := Color(1.0, 0.55, 0.55, 0.90)
const BADGE_COLOR := Color(0.88, 0.20, 0.20, 1.0)
const BADGE_BORDER := Color(1.0, 0.52, 0.52, 0.90)
const TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)


static func add_dot(target: Control) -> void:
	_remove_existing(target)
	var dot := _make_dot()
	_attach(target, dot)


static func add_count(target: Control, count: int, max_display: int = 99) -> void:
	if count <= 0:
		remove(target)
		return
	_remove_existing(target)
	var text := "%d+" % max_display if count > max_display else str(count)
	var badge := _make_badge(text)
	_attach(target, badge)


static func remove(target: Control) -> void:
	_remove_existing(target)


static func _remove_existing(target: Control) -> void:
	if target.has_meta(_META_KEY):
		var existing: Node = target.get_meta(_META_KEY)
		if is_instance_valid(existing):
			existing.queue_free()
		target.remove_meta(_META_KEY)


static func _attach(target: Control, badge: Control) -> void:
	target.set_meta(_META_KEY, badge)
	target.add_child(badge)
	_pin_to_top_right(badge)

static func _pin_to_top_right(badge: Control) -> void:
	badge.reset_size()
	var badge_size: Vector2 = _get_badge_size(badge)
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_left = BADGE_OFFSET.x - badge_size.x * 0.5
	badge.offset_right = BADGE_OFFSET.x + badge_size.x * 0.5
	badge.offset_top = BADGE_OFFSET.y - badge_size.y * 0.5
	badge.offset_bottom = BADGE_OFFSET.y + badge_size.y * 0.5


static func _get_badge_size(badge: Control) -> Vector2:
	var min_size: Vector2 = badge.get_combined_minimum_size()
	var current_size: Vector2 = badge.size
	return Vector2(
		maxf(current_size.x, min_size.x),
		maxf(current_size.y, min_size.y)
	)


static func _make_dot() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 10

	var style := StyleBoxFlat.new()
	style.bg_color = DOT_COLOR
	style.border_color = DOT_BORDER
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = int(DOT_SIZE / 2.0)
	style.corner_radius_top_right = int(DOT_SIZE / 2.0)
	style.corner_radius_bottom_left = int(DOT_SIZE / 2.0)
	style.corner_radius_bottom_right = int(DOT_SIZE / 2.0)
	panel.add_theme_stylebox_override("panel", style)

	return panel


static func _make_badge(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(BADGE_MIN_W, BADGE_H)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 10

	var style := StyleBoxFlat.new()
	style.bg_color = BADGE_COLOR
	style.border_color = BADGE_BORDER
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	var r := int(BADGE_H / 2.0)
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

	return panel
