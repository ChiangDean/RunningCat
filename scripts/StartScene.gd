extends Control

const BATTLE_SCENE_PATH := "res://scenes/BattleScene.tscn"
const HERO_IMAGE := preload("res://assets/sprites/ui/start_scene_homey_v1.png")
const TITLE_TEXT := "\u55b5\u55b5\u885d\u649e\u6d3e\u5c0d"
const SUBTITLE_TEXT := "\u93df\u5c4e\u5b98\u4e5f\u60f3\u7576\u8c93"
const TAP_TO_START_TEXT := "\u9ede\u64ca\u4efb\u610f\u4f4d\u7f6e\u958b\u59cb"

var _start_button: Button
var _title_card: Control
var _loading_block: Control
var _loading_fill: Control
var _loading_label: Label
var _loading_percent_label: Label
var _paw_row: HBoxContainer
var _tap_hint: Label
var _input_ready := false
var _loading_track_fill_width := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_play_idle_animation()
	_start_fake_loading()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = HERO_IMAGE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	var top_overlay := ColorRect.new()
	top_overlay.anchor_right = 1.0
	top_overlay.anchor_bottom = 0.42
	top_overlay.color = Color(0.18, 0.15, 0.11, 0.16)
	add_child(top_overlay)

	var bottom_overlay := ColorRect.new()
	bottom_overlay.anchor_top = 0.58
	bottom_overlay.anchor_right = 1.0
	bottom_overlay.anchor_bottom = 1.0
	bottom_overlay.color = Color(0.18, 0.14, 0.10, 0.16)
	add_child(bottom_overlay)

	var layout := Control.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	_title_card = _build_title_block()
	layout.add_child(_title_card)

	_loading_block = _build_loading_block()
	layout.add_child(_loading_block)

	_tap_hint = _build_tap_hint()
	layout.add_child(_tap_hint)


func _build_title_block() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.24
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.24
	panel.position = Vector2(-250, 0)
	panel.custom_minimum_size = Vector2(500, 156)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var ribbon := Label.new()
	ribbon.text = "HOME OF MEOW"
	ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_theme_font_size_override("font_size", 18)
	ribbon.add_theme_color_override("font_color", Color("f8f3ea"))
	ribbon.add_theme_stylebox_override("normal", _make_ribbon_stylebox())
	content.add_child(ribbon)

	var title := Label.new()
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	title.add_theme_color_override("font_shadow_color", Color("fffdf9"))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = SUBTITLE_TEXT
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color("6a5547"))
	content.add_child(subtitle)

	return panel


func _build_loading_block() -> Control:
	var block := Control.new()
	block.anchor_left = 0.5
	block.anchor_top = 0.80
	block.anchor_right = 0.5
	block.anchor_bottom = 0.80
	block.position = Vector2(-190, 0)
	block.custom_minimum_size = Vector2(380, 82)

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", _make_card_stylebox())
	block.add_child(frame)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	frame.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	_loading_label = Label.new()
	_loading_label.text = "\u8c93\u54aa\u5011\u6b63\u5728\u96c6\u5408..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_font_size_override("font_size", 22)
	_loading_label.add_theme_color_override("font_color", Color("5f4c3f"))
	content.add_child(_loading_label)

	_paw_row = _build_paw_row()
	content.add_child(_paw_row)

	var track := PanelContainer.new()
	track.custom_minimum_size = Vector2(320, 24)
	track.add_theme_stylebox_override("panel", _make_progress_track_stylebox())
	content.add_child(track)

	var fill_holder := Control.new()
	fill_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	track.add_child(fill_holder)

	_loading_fill = ColorRect.new()
	_loading_fill.color = Color("9aae8b")
	_loading_fill.position = Vector2(0, 0)
	_loading_fill.size = Vector2(0, 16)
	fill_holder.add_child(_loading_fill)
	_loading_track_fill_width = 312.0

	_loading_percent_label = Label.new()
	_loading_percent_label.text = "0%"
	_loading_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_percent_label.add_theme_font_size_override("font_size", 18)
	_loading_percent_label.add_theme_color_override("font_color", Color("715b4a"))
	content.add_child(_loading_percent_label)

	return block


func _build_paw_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for _i in range(4):
		var paw := Label.new()
		paw.text = "\u25cf"
		paw.add_theme_font_size_override("font_size", 14)
		paw.add_theme_color_override("font_color", Color("9aae8b"))
		row.add_child(paw)
	return row


func _build_tap_hint() -> Label:
	var hint := Label.new()
	hint.text = TAP_TO_START_TEXT
	hint.anchor_left = 0.5
	hint.anchor_top = 0.84
	hint.anchor_right = 0.5
	hint.anchor_bottom = 0.84
	hint.position = Vector2(-190, 0)
	hint.size = Vector2(380, 36)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color("f7f1e7"))
	hint.add_theme_color_override("font_shadow_color", Color("5e4a3d"))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	hint.visible = false
	return hint


func _play_idle_animation() -> void:
	if _title_card != null:
		var base_y := _title_card.position.y
		var title_tween := create_tween().set_loops()
		title_tween.tween_property(_title_card, "position:y", base_y + 6.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		title_tween.tween_property(_title_card, "position:y", base_y, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _start_button != null:
		var button_tween := create_tween().set_loops()
		button_tween.tween_property(_start_button, "scale", Vector2.ONE * 1.03, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		button_tween.tween_property(_start_button, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _tap_hint != null:
		var hint_tween := create_tween().set_loops()
		hint_tween.tween_property(_tap_hint, "modulate:a", 0.45, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hint_tween.tween_property(_tap_hint, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _paw_row != null:
		for i in range(_paw_row.get_child_count()):
			var paw: Label = _paw_row.get_child(i)
			var paw_tween := create_tween().set_loops()
			paw_tween.tween_interval(float(i) * 0.12)
			paw_tween.tween_property(paw, "scale", Vector2.ONE * 1.2, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			paw_tween.parallel().tween_property(paw, "modulate:a", 1.0, 0.24)
			paw_tween.tween_property(paw, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			paw_tween.parallel().tween_property(paw, "modulate:a", 0.45, 0.32)

func _start_fake_loading() -> void:
	if _loading_fill == null:
		return
	var tween := create_tween()
	tween.tween_property(_loading_fill, "size:x", _loading_track_fill_width, 2.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_finish_fake_loading)
	var percent_tween := create_tween()
	percent_tween.tween_method(_update_loading_progress, 0.0, 100.0, 2.0)


func _finish_fake_loading() -> void:
	_input_ready = true
	if _loading_label != null:
		_loading_label.text = "\u8c93\u54aa\u968a\u4f0d\u96c6\u5408\u5b8c\u7562"
	if _loading_percent_label != null:
		_loading_percent_label.text = "100%"
	if _loading_block != null:
		var fade_tween := create_tween()
		fade_tween.tween_property(_loading_block, "modulate:a", 0.0, 0.3)
		fade_tween.finished.connect(func():
			if _loading_block != null:
				_loading_block.visible = false
		)
	if _tap_hint != null:
		_tap_hint.visible = true


func _update_loading_progress(value: float) -> void:
	if _loading_percent_label != null:
		_loading_percent_label.text = "%d%%" % int(round(value))


func _input(event: InputEvent) -> void:
	if not _input_ready:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_game()
		get_viewport()
	elif event is InputEventScreenTouch and event.pressed:
		_start_game()
		get_viewport()


func _start_game() -> void:
	GameState.arena_data.update_defense_snapshot(
		GameState.player_data.arena_defense_team,
		GameState._player_cat_cache
	)
	GameState.arena_data.save()
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _make_card_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.88, 0.86)
	style.border_color = Color("6d5948")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.24, 0.18, 0.14, 0.22)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 6)
	style.anti_aliasing = false
	style.border_blend = false
	return style


func _make_ribbon_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("98a48c")
	style.border_color = Color("5e6958")
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 14
	style.content_margin_top = 6
	style.content_margin_right = 14
	style.content_margin_bottom = 6
	style.anti_aliasing = false
	style.border_blend = false
	return style


func _make_button_stylebox(fill_color: Color, bottom_depth: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color("6f5847")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = bottom_depth
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 12
	style.content_margin_top = 16
	style.content_margin_right = 12
	style.content_margin_bottom = 16
	style.shadow_color = Color(0.28, 0.21, 0.16, 0.22)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 6)
	style.anti_aliasing = false
	style.border_blend = false
	return style


func _make_progress_track_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d7c5b0")
	style.border_color = Color("7b6554")
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.anti_aliasing = false
	style.border_blend = false
	return style
