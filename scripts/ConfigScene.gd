extends Control

## 配置畫面：選擇出戰貓咪 + 設定技能起始延遲
## 長按出戰貓咪列中的「技能」按鈕 → 彈出技能資訊面板

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
	root_vbox.offset_left = 20
	root_vbox.offset_top = 40
	root_vbox.offset_right = -20
	root_vbox.offset_bottom = -20
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

	for cat_id: String in GameState.get_owned_cats():
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
	var display_name := _get_display_name(cat_id)
	name_lbl.text = "%d. %s" % [slot_index + 1, display_name]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(name_lbl)

	# 技能按鈕（長按查看技能）
	var skill_btn := Button.new()
	skill_btn.text = "技能"
	skill_btn.custom_minimum_size = Vector2(64.0, 44.0)
	# 用 button_down + timer 模擬長按
	var press_time: float = 0.0
	var is_pressed := false
	skill_btn.button_down.connect(func():
		is_pressed = true
		press_time = Time.get_ticks_msec() / 1000.0
	)
	skill_btn.button_up.connect(func():
		is_pressed = false
		var held := Time.get_ticks_msec() / 1000.0 - press_time
		if held >= 0.4:
			_show_skill_popup(cat_id)
	)
	row.add_child(skill_btn)

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
	name_lbl.text = _get_display_name(cat_id)
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

# ── 技能資訊 Popup ────────────────────────────

func _show_skill_popup(cat_id: String) -> void:
	var cat_data := CatData.from_json_file("res://data/default/cats/" + cat_id + ".json")
	if cat_data == null:
		return
	var player_cat := GameState.get_player_cat(cat_id)

	var lines: Array = [cat_data.display_name + " 技能"]

	# 被動技能
	for sid: String in cat_data.passive_skill_ids:
		var skill_d := CatData._read_skill_json(
				"res://data/default/skills/passive/" + sid + ".json")
		if not skill_d.is_empty():
			lines.append("【被動】%s" % skill_d.get("display_name", sid))
			lines.append("  " + skill_d.get("description", ""))

	# 主動技能
	for skill_d: Dictionary in cat_data.active_skills_data:
		var rank_info := _format_rank_scaling(skill_d, player_cat.rank)
		lines.append("【主動】%s  CD: %.1fs" % [
				skill_d.get("display_name", ""), skill_d.get("cooldown", 0.0)])
		lines.append("  " + skill_d.get("description", ""))
		if not rank_info.is_empty():
			lines.append("  " + rank_info)

	var dialog := AcceptDialog.new()
	dialog.title = "技能資訊"
	dialog.dialog_text = "\n".join(lines)
	dialog.min_size = Vector2(560.0, 300.0)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())


func _format_rank_scaling(skill_d: Dictionary, rank: int) -> String:
	if rank <= 0:
		return ""
	var scaling: Array = skill_d.get("rank_scaling", [])
	if scaling.is_empty():
		return ""
	var effects: Array = skill_d.get("effects", [])
	var parts: Array = []
	for rs: Dictionary in scaling:
		var eff_idx: int = rs.get("effect_index", 0)
		var per_5: float = rs.get("per_5_ranks", 0.0)
		var bonus: float = floorf(rank / 5.0) * per_5
		if bonus > 0.0 and eff_idx < effects.size():
			var stat: String = effects[eff_idx].get("stat", "效果")
			parts.append("%s +%.0f%%" % [stat, bonus * 100.0])
	if parts.is_empty():
		return ""
	return "品階加成（+%d）：%s" % [rank, ", ".join(parts)]

# ── 輔助 ─────────────────────────────────────

func _get_display_name(cat_id: String) -> String:
	var data := CatData.from_json_file("res://data/default/cats/" + cat_id + ".json")
	return data.display_name if data != null else cat_id

func _make_separator() -> HSeparator:
	return HSeparator.new()

# ── 導航 ─────────────────────────────────────

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")

func _on_confirm_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
