extends Control

## 主畫面

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "RunningCat"
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 40.0)
	vbox.add_child(spacer)

	var config_btn := _make_button("配置")
	config_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ConfigScene.tscn")
	)
	vbox.add_child(config_btn)

	var level_btn := _make_button("出發")
	level_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/LevelScene.tscn")
	)
	vbox.add_child(level_btn)

func _make_button(txt: String) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(280.0, 70.0)
	return btn
