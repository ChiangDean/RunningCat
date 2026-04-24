## Global toast notification system
## Usage:
##   ToastManager.success("Purchase succeeded")
##   ToastManager.error("Network error, please try again later")
##   ToastManager.hint("Copied to clipboard")
extends Node

enum ToastType { SUCCESS, ERROR, HINT }

const TOAST_DURATION := 3.0
const TOAST_ANIM_IN := 0.25
const TOAST_ANIM_OUT := 0.20
const TOAST_TOP_OFFSET := 60.0
const TOAST_SIDE_MARGIN := 40.0
const TOAST_MIN_HEIGHT := 72.0
const TOAST_FONT_SIZE := 20
const TOAST_FONT_SIZE_SMALL := 16

const _TYPE_COLORS := {
	ToastType.SUCCESS: Color(0.20, 0.55, 0.28, 0.96),
	ToastType.ERROR:   Color(0.55, 0.18, 0.18, 0.96),
	ToastType.HINT:    Color(0.52, 0.42, 0.10, 0.96),
}

const _TYPE_BORDER_COLORS := {
	ToastType.SUCCESS: Color(0.45, 0.85, 0.52, 0.90),
	ToastType.ERROR:   Color(0.90, 0.42, 0.40, 0.90),
	ToastType.HINT:    Color(0.90, 0.78, 0.30, 0.90),
}

const _TYPE_ICONS := {
	ToastType.SUCCESS: "✓",
	ToastType.ERROR:   "✕",
	ToastType.HINT:    "！",
}

var _canvas: CanvasLayer
var _queue: Array[Dictionary] = []
var _active: bool = false


func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 128
	add_child(_canvas)


## Show a success toast (green)
func success(message: String, sub_text: String = "") -> void:
	_enqueue(ToastType.SUCCESS, message, sub_text)


## Show an error toast (red)
func error(message: String, sub_text: String = "") -> void:
	_enqueue(ToastType.ERROR, message, sub_text)


## Show a hint toast (yellow)
func hint(message: String, sub_text: String = "") -> void:
	_enqueue(ToastType.HINT, message, sub_text)


func _enqueue(type: ToastType, message: String, sub_text: String) -> void:
	_queue.append({"type": type, "message": message, "sub_text": sub_text})
	if not _active:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_active = false
		return

	_active = true
	var data: Dictionary = _queue.pop_front()
	_spawn_toast(data.type, data.message, data.sub_text)


func _spawn_toast(type: ToastType, message: String, sub_text: String) -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	# --- Outer panel ---
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _TYPE_COLORS[type]
	style.border_color = _TYPE_BORDER_COLORS[type]
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)

	panel.custom_minimum_size = Vector2(viewport_size.x - TOAST_SIDE_MARGIN * 2.0, TOAST_MIN_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# --- Inner margin ---
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	# --- Icon ---
	var icon_label := Label.new()
	icon_label.text = _TYPE_ICONS[type]
	icon_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	icon_label.add_theme_color_override("font_color", _TYPE_BORDER_COLORS[type])
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon_label)

	# --- Text block ---
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)

	var msg_label := Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", TOAST_FONT_SIZE)
	msg_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(msg_label)

	if sub_text != "":
		var sub_label := Label.new()
		sub_label.text = sub_text
		sub_label.add_theme_font_size_override("font_size", TOAST_FONT_SIZE_SMALL)
		sub_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.75))
		sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_col.add_child(sub_label)

	# --- Position: slide in from the top ---
	var control_root := Control.new()
	control_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	control_root.offset_bottom = TOAST_MIN_HEIGHT + TOAST_TOP_OFFSET + 40.0
	_canvas.add_child(control_root)
	var control_root_ref: WeakRef = weakref(control_root)

	panel.position = Vector2(TOAST_SIDE_MARGIN, -TOAST_MIN_HEIGHT - 20.0)
	control_root.add_child(panel)

	# --- Animation: slide in ---
	var target_y := TOAST_TOP_OFFSET
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "position:y", target_y, TOAST_ANIM_IN)
	tween.tween_interval(TOAST_DURATION)

	# --- Animation: fade out ---
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(panel, "modulate:a", 0.0, TOAST_ANIM_OUT)
	tween.tween_callback(Callable(self, "_finish_toast").bind(control_root_ref))


func _finish_toast(control_root_ref: WeakRef) -> void:
	if control_root_ref != null:
		var control_root_obj: Object = control_root_ref.get_ref()
		if control_root_obj is Control:
			(control_root_obj as Control).queue_free()
	_show_next()
