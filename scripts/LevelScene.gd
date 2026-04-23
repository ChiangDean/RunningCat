extends Control

## Stage info screen (shows current player progress; can be extended to a stage map in the future)

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 20)
	root_vbox.offset_left = 20.0
	root_vbox.offset_top = 40.0
	root_vbox.offset_right = -20.0
	root_vbox.offset_bottom = -20.0
	layer.add_child(root_vbox)

	# Top row
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = UiText.COMMON_BACK
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = UiText.LEVEL_PAGE_TITLE
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	root_vbox.add_child(_make_separator())

	# Current stage info
	var info_lbl := Label.new()
	info_lbl.text = UiText.LEVEL_CURRENT_FORMAT % GameState.get_level_display()
	info_lbl.add_theme_font_size_override("font_size", 26)
	info_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(info_lbl)

	var global_lbl := Label.new()
	global_lbl.text = UiText.LEVEL_GLOBAL_STAGE_FORMAT % GameState.current_global_stage
	global_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	global_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	global_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
	root_vbox.add_child(global_lbl)

func _make_separator() -> HSeparator:
	return HSeparator.new()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/StartScene.tscn")
