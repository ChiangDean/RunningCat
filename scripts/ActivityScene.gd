extends Control

## 活動頁面：活動功能入口（地下城、競技場）

const SW := 720.0
const SH := 1280.0


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 24)
	root_vbox.offset_left   = 20
	root_vbox.offset_top    = 40
	root_vbox.offset_right  = -20
	root_vbox.offset_bottom = -20
	layer.add_child(root_vbox)

	# 頂部列
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "活動"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	root_vbox.add_child(HSeparator.new())

	# 地下城按鈕
	var dungeon_btn := _make_entry_button(
		"地下城",
		"挑戰各種地下城，獲取豐富獎勵",
		_on_dungeon_pressed
	)
	root_vbox.add_child(dungeon_btn)

	# 競技場按鈕
	var arena_btn := _make_entry_button(
		"競技場",
		"異步 PvP 對戰，爭奪段位獎勵",
		_on_arena_pressed
	)
	root_vbox.add_child(arena_btn)


func _make_entry_button(title_text: String, subtitle_text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0.0, 110.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	btn.add_child(vbox)

	var t := Label.new()
	t.text = title_text
	t.add_theme_font_size_override("font_size", 28)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(t)

	var s := Label.new()
	s.text = subtitle_text
	s.add_theme_font_size_override("font_size", 18)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(s)

	btn.pressed.connect(callback)
	return btn


func _on_dungeon_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/DungeonScene.tscn")


func _on_arena_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ArenaScene.tscn")


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
