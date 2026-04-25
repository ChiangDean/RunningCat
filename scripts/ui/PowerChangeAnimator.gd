extends CanvasLayer

const DISPLAY_DURATION: float = 1.25
const HOLD_DURATION: float = 0.55
const PANEL_SIZE := Vector2(520.0, 64.0)
const ICON_UP: String = "▲"
const ICON_DOWN: String = "▼"

var _panel: PanelContainer
var _value_label: Label
var _delta_label: Label
var _icon_label: Label
var _tween: Tween
var _from_score: int = 0
var _to_score: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _display_score: int = 0:
	set(value):
		_display_score = value
		if _value_label != null:
			_value_label.text = UiText.POWER_CHANGE_LABEL + " " + _format_number(_resolve_display_score(_display_score))


func _ready() -> void:
	layer = 140
	_rng.randomize()
	_build_ui()
	_panel.visible = false
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and not game_state.combat_power_changed.is_connected(_on_game_state_combat_power_changed):
		game_state.combat_power_changed.connect(_on_game_state_combat_power_changed)
	call_deferred("_show_pending_power_change")


func _on_game_state_combat_power_changed(previous_score: int, current_score: int) -> void:
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	var game_state: Node = get_node_or_null("/root/GameState")
	if battle_scene != null and game_state != null and game_state.has_method("clear_pending_combat_power_change"):
		game_state.clear_pending_combat_power_change()
	show_power_change(previous_score, current_score)


func _show_pending_power_change() -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null or not game_state.has_method("consume_pending_combat_power_change"):
		return
	var pending_variant: Variant = game_state.consume_pending_combat_power_change()
	if not (pending_variant is Dictionary):
		return
	var pending: Dictionary = pending_variant as Dictionary
	if pending.is_empty():
		return
	show_power_change(int(pending.get("previousScore", 0)), int(pending.get("currentScore", 0)))


func show_power_change(previous_score: int, current_score: int) -> void:
	if previous_score == current_score:
		return
	if _panel == null:
		_build_ui()

	_from_score = previous_score
	_to_score = current_score
	_display_score = previous_score
	var delta: int = current_score - previous_score
	var is_up: bool = delta > 0
	var accent: Color = Color(0.46, 1.0, 0.58, 1.0) if is_up else Color(1.0, 0.45, 0.42, 1.0)

	_value_label.text = UiText.POWER_CHANGE_LABEL + " " + _format_number(previous_score)
	_delta_label.text = "%s%s" % ["+" if is_up else "", _format_number(delta)]
	_icon_label.text = ICON_UP if is_up else ICON_DOWN
	var labels: Array[Label] = [_value_label, _delta_label, _icon_label]
	for label: Label in labels:
		var font_color: Color = accent if label != _value_label else Color(1.0, 0.96, 0.80, 1.0)
		label.add_theme_color_override("font_color", font_color)

	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_panel.scale = Vector2(0.92, 0.92)
	_panel.visible = true

	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.16)
	_tween.tween_property(_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_display_score", current_score, DISPLAY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(false)
	_tween.tween_interval(HOLD_DURATION)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.25)
	_tween.tween_callback(_hide_panel)


func _build_ui() -> void:
	if _panel != null:
		return
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_top = -224.0
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_bottom = -224.0 + PANEL_SIZE.y
	_panel.pivot_offset = PANEL_SIZE * 0.5
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.075, 0.045, 0.82)
	style.border_color = Color(0.95, 0.72, 0.34, 0.96)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	_value_label = Label.new()
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	row.add_child(_value_label)

	_delta_label = Label.new()
	_delta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_delta_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	row.add_child(_delta_label)

	_icon_label = Label.new()
	_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_label.custom_minimum_size = Vector2(32.0, 40.0)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 24)
	row.add_child(_icon_label)


func _hide_panel() -> void:
	_panel.visible = false


func _format_number(value: int) -> String:
	var text: String = str(abs(value))
	var output: String = ""
	var count: int = 0
	for index: int in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			output = "," + output
		output = text.substr(index, 1) + output
		count += 1
	return ("-" if value < 0 else "") + output


func _resolve_display_score(value: int) -> int:
	if value == _to_score:
		return value
	var direction: int = 1 if _to_score >= _from_score else -1
	var remaining: int = abs(_to_score - value)
	var jitter_cap: int = maxi(1, remaining / 18)
	var jitter: int = _rng.randi_range(0, jitter_cap) * direction
	var candidate: int = value + jitter
	if direction > 0:
		return clampi(candidate, mini(_from_score, _to_score), maxi(_from_score, _to_score))
	return clampi(candidate, mini(_from_score, _to_score), maxi(_from_score, _to_score))
