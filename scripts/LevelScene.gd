extends Control

## 關卡選擇畫面：世界 1（1-1 → 1-2 → 1-3 → 1-Boss）

const SW := 720.0

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 背景
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

	# 頂部列
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "關卡選擇"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	# 世界 1 標題
	var world_lbl := Label.new()
	world_lbl.text = "第一世界"
	world_lbl.add_theme_font_size_override("font_size", 26)
	world_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(world_lbl)

	root_vbox.add_child(_make_separator())

	# 關卡按鈕
	for level_id: String in GameState.WORLD_ORDER:
		var btn := _make_level_button(level_id)
		root_vbox.add_child(btn)

func _make_level_button(level_id: String) -> Button:
	var unlocked: bool = GameState.is_level_unlocked(level_id)
	var cleared: bool = level_id in GameState.cleared_levels
	var info: Dictionary = GameState.LEVELS[level_id]

	var label: String = level_id
	if info.get("is_boss", false):
		label = "⚔ %s（Boss）" % level_id
	if cleared:
		label += " ✓"

	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0.0, 80.0)
	btn.disabled = not unlocked
	if not unlocked:
		btn.modulate = Color(0.5, 0.5, 0.5, 1.0)

	btn.pressed.connect(func():
		GameState.current_level = level_id
		get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
	)
	return btn

func _make_separator() -> HSeparator:
	return HSeparator.new()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/StartScene.tscn")
