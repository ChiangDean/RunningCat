extends Control

## 配置畫面：選擇出戰貓咪 + 設定技能起始延遲

const SW := 720.0
const SH := 1280.0

var _team_container: VBoxContainer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	# 主容器
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 16)
	var margins := [20, 40, 20, 20]  # left, top, right, bottom
	root_vbox.offset_left = margins[0]
	root_vbox.offset_top = margins[1]
	root_vbox.offset_right = -margins[2]
	root_vbox.offset_bottom = -margins[3]
	layer.add_child(root_vbox)

	# 頂部列：返回 + 標題
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "配置"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	# 出戰隊伍區塊
	var team_title := Label.new()
	team_title.text = "出戰隊伍（最多 5 隻）"
	team_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(team_title)

	_team_container = VBoxContainer.new()
	_team_container.add_theme_constant_override("separation", 8)
	root_vbox.add_child(_team_container)

	root_vbox.add_child(_make_separator())

	# 可用貓咪區塊
	var cats_title := Label.new()
	cats_title.text = "可用貓咪"
	cats_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(cats_title)

	var cats_container := VBoxContainer.new()
	cats_container.add_theme_constant_override("separation", 8)
	root_vbox.add_child(cats_container)

	for cat_id: String in GameState.OWNED_CATS:
		var row := _make_cat_row(cat_id)
		cats_container.add_child(row)

	root_vbox.add_child(_make_separator())

	# 確認按鈕
	var confirm_btn := Button.new()
	confirm_btn.text = "確認"
	confirm_btn.custom_minimum_size = Vector2(0.0, 64.0)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	root_vbox.add_child(confirm_btn)

	_refresh_team()

# ── 隊伍更新 ─────────────────────────────────

func _refresh_team() -> void:
	for child in _team_container.get_children():
		child.queue_free()

	for i in range(GameState.player_team.size()):
		var cat_id: String = GameState.player_team[i]
		var row := _make_team_slot_row(i, cat_id)
		_team_container.add_child(row)

	if GameState.player_team.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "（尚未選擇貓咪）"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_team_container.add_child(empty_lbl)

func _make_team_slot_row(slot_index: int, cat_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# 槽號 + 貓名
	var name_lbl := Label.new()
	name_lbl.text = "%d. %s" % [slot_index + 1, cat_id]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(name_lbl)

	# 延遲選擇器
	var delay_lbl_prefix := Label.new()
	delay_lbl_prefix.text = "延遲:"
	delay_lbl_prefix.add_theme_font_size_override("font_size", 20)
	row.add_child(delay_lbl_prefix)

	var minus_btn := Button.new()
	minus_btn.text = "-"
	minus_btn.custom_minimum_size = Vector2(44.0, 44.0)
	row.add_child(minus_btn)

	var delay_val := Label.new()
	delay_val.text = str(GameState.get_delay(slot_index))
	delay_val.custom_minimum_size = Vector2(30.0, 44.0)
	delay_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delay_val.add_theme_font_size_override("font_size", 22)
	row.add_child(delay_val)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(44.0, 44.0)
	row.add_child(plus_btn)

	minus_btn.pressed.connect(func():
		GameState.set_delay(slot_index, GameState.get_delay(slot_index) - 1)
		delay_val.text = str(GameState.get_delay(slot_index))
	)
	plus_btn.pressed.connect(func():
		GameState.set_delay(slot_index, GameState.get_delay(slot_index) + 1)
		delay_val.text = str(GameState.get_delay(slot_index))
	)

	# 移除按鈕
	var remove_btn := Button.new()
	remove_btn.text = "移除"
	remove_btn.custom_minimum_size = Vector2(80.0, 44.0)
	remove_btn.pressed.connect(func():
		GameState.player_team.remove_at(slot_index)
		# 清除後面槽的 delay（重新編號）
		var new_delays: Dictionary = {}
		for j in range(GameState.player_team.size()):
			var old_j: int = j if j < slot_index else j + 1
			new_delays[j] = GameState.skill_delays.get(old_j, 0)
		GameState.skill_delays = new_delays
		_refresh_team()
	)
	row.add_child(remove_btn)

	return row

func _make_cat_row(cat_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_lbl := Label.new()
	name_lbl.text = cat_id
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(name_lbl)

	var add_btn := Button.new()
	add_btn.text = "加入"
	add_btn.custom_minimum_size = Vector2(100.0, 50.0)
	add_btn.pressed.connect(func():
		if GameState.player_team.size() < 5:
			GameState.player_team.append(cat_id)
			_refresh_team()
	)
	row.add_child(add_btn)

	return row

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	return sep

# ── 導航 ─────────────────────────────────────

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/StartScene.tscn")

func _on_confirm_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/StartScene.tscn")
