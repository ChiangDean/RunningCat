extends Control

## 商店主畫面：各功能入口按鈕

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
	root_vbox.add_theme_constant_override("separation", 20)
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
	title.text = "商店"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	root_vbox.add_child(_make_separator())

	# 商店按鈕列表
	var items: Array = [
		["誘捕籠",   true,  _on_gacha_pressed],
		["商城禮包", false, Callable()],
		["購買鑽石", false, Callable()],
		["每日特賣", false, Callable()],
		["道具兌換", false, Callable()],
	]

	for item: Array in items:
		var btn_label:   String   = item[0]
		var available:   bool     = item[1]
		var callback:    Callable = item[2]

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0.0, 80.0)
		btn.add_theme_font_size_override("font_size", 26)

		if available:
			btn.text = btn_label
			btn.pressed.connect(callback)
		else:
			btn.text = btn_label + "  🔒 待開放"
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6, 1.0)

		root_vbox.add_child(btn)


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")


func _on_gacha_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GachaScene.tscn")
