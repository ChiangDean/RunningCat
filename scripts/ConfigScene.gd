extends Control

## 配置畫面：選擇各場景出戰貓咪 + 設定技能起始延遲
## 支援四種隊伍類型：BOSS推關 / 地下城 / 競技場攻擊 / 競技場防禦
## 長按出戰貓咪列中的「技能」按鈕 → 彩蛋資訊面板

const SW := 720.0
const SH := 1280.0

## 當前編輯的隊伍類型
var _current_team_type: String = "boss"

var _team_container: VBoxContainer
var _team_type_btns: Dictionary = {}   # key: team_type → Button
var cats_container: VBoxContainer      # 新增：class 層級 cats_container
var _team_title: Label

const TEAM_LABELS: Dictionary = {
	"boss":          "BOSS 推關",
	"dungeon":       "地下城",
	"arena_attack":  "競技場攻擊",
	"arena_defense": "競技場防禦",
}


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

	# 隊伍類型選擇列
	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 6)
	root_vbox.add_child(type_row)

	for type_key: String in ["boss", "dungeon", "arena_attack", "arena_defense"]:
		var btn := Button.new()
		btn.text = TEAM_LABELS[type_key]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 48.0)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(): _switch_team_type(type_key))
		type_row.add_child(btn)
		_team_type_btns[type_key] = btn

	root_vbox.add_child(_make_separator())

	# 出戰隊伍區塊

	_team_title = Label.new()
	_team_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(_team_title)

	_team_container = VBoxContainer.new()
	_team_container.add_theme_constant_override("separation", 8)
	root_vbox.add_child(_team_container)

	root_vbox.add_child(_make_separator())

	# 可用貓咪區塊
	var cats_title := Label.new()
	cats_title.text = "可用貓咪"
	cats_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(cats_title)

	cats_container = VBoxContainer.new()
	cats_container.add_theme_constant_override("separation", 8)
	root_vbox.add_child(cats_container)
	_refresh_cats_list()
	root_vbox.add_child(_make_separator())



	_switch_team_type("boss")
func _update_team_title() -> void:
	var mode_label = TEAM_LABELS.get(_current_team_type, _current_team_type)
	var team = _get_editing_team()
	var count = team.size()
	var max_count = _get_max_team_size()
	_team_title.text = "%s 出戰隊伍(%d/%d)" % [mode_label, count, max_count]


# ── 隊伍類型切換 ──────────────────────────────

func _switch_team_type(type_key: String) -> void:
	_current_team_type = type_key
	for key: String in _team_type_btns:
		var btn: Button = _team_type_btns[key]
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if key == type_key else Color(0.6, 0.6, 0.6, 1.0)
	_refresh_team()
	_update_team_title()


func _get_editing_team() -> Array:
	match _current_team_type:
		"boss":          return GameState.player_data.boss_team
		"dungeon":       return GameState.player_data.dungeon_team
		"arena_attack":  return GameState.player_data.arena_attack_team
		"arena_defense": return GameState.player_data.arena_defense_team
	return GameState.player_data.boss_team


# ── 隊伍更新 ─────────────────────────────────

func _refresh_team() -> void:
	for child in _team_container.get_children():
		child.queue_free()

	var team := _get_editing_team()
	var max_count = _get_max_team_size()
	for i in range(max_count):
		var cat_id = team[i] if i < team.size() else ""
		_team_container.add_child(_make_team_slot_row(i, cat_id))

	_refresh_cats_list() # 每次隊伍刷新時也刷新可用貓咪按鈕狀態

	_update_team_title()


func _make_team_slot_row(slot_index: int, cat_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var is_filled := cat_id != ""

	var name_lbl := Label.new()
	if is_filled:
		var player_cat := GameState.get_player_cat(cat_id)
		var lv := 1
		if player_cat != null:
			lv = player_cat.cat_food_level
		name_lbl.text = "%d. %s" % [slot_index + 1, CatRegistry.get_cat_display_name_with_lv(cat_id, lv)]
	else:
		name_lbl.text = "%d." % [slot_index + 1]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(name_lbl)

	# 技能按鈕（長按查看）
	var skill_btn := Button.new()
	skill_btn.text = "技能"
	skill_btn.custom_minimum_size = Vector2(64.0, 44.0)
	skill_btn.disabled = not is_filled
	if is_filled:
		var press_time: float = 0.0
		skill_btn.button_down.connect(func(): press_time = Time.get_ticks_msec() / 1000.0)
		skill_btn.button_up.connect(func():
			if Time.get_ticks_msec() / 1000.0 - press_time >= 0.4:
				_show_skill_popup(cat_id)
		)
	row.add_child(skill_btn)

	# 延遲（僅 boss / dungeon / arena_attack 有意義）
	if _current_team_type != "arena_defense":
		var delay_lbl := Label.new()
		delay_lbl.text = "延遲:"
		delay_lbl.add_theme_font_size_override("font_size", 20)
		row.add_child(delay_lbl)

		var minus_btn := Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(44.0, 44.0)
		minus_btn.disabled = not is_filled
		row.add_child(minus_btn)

		var delay_val := Label.new()
		delay_val.text = str(GameState.get_delay(slot_index)) if is_filled else "-"
		delay_val.custom_minimum_size = Vector2(30.0, 44.0)
		delay_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		delay_val.add_theme_font_size_override("font_size", 22)
		row.add_child(delay_val)

		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(44.0, 44.0)
		plus_btn.disabled = not is_filled
		row.add_child(plus_btn)

		if is_filled:
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
	remove_btn.disabled = not is_filled
	if is_filled:
		remove_btn.pressed.connect(func():
			var team := _get_editing_team()
			team.remove_at(slot_index)
			if _current_team_type == "boss":
				var new_delays: Dictionary = {}
				for j in range(team.size()):
					var old_j: int = j if j < slot_index else j + 1
					new_delays[j] = GameState.skill_delays.get(old_j, 0)
				GameState.skill_delays = new_delays
			GameState.player_data.save()
			_refresh_team()
		)
	row.add_child(remove_btn)

	return row


func _make_cat_row(cat_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_lbl := Label.new()
	var player_cat := GameState.get_player_cat(cat_id)
	var lv := 1
	if player_cat != null:
		lv = player_cat.cat_food_level
	name_lbl.text = CatRegistry.get_cat_display_name_with_lv(cat_id, lv)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(name_lbl)

	var add_btn := Button.new()
	add_btn.text = "加入"
	add_btn.custom_minimum_size = Vector2(100.0, 50.0)

	# 若已在隊伍中則 disabled
	var team := _get_editing_team()
	if cat_id in team:
		add_btn.disabled = true
	add_btn.pressed.connect(func():
		var editing_team := _get_editing_team()
		var max_count = _get_max_team_size()
		if editing_team.size() < max_count and not (cat_id in editing_team):
			editing_team.append(cat_id)
			GameState.player_data.save()
			_refresh_team() # 這裡會自動刷新所有按鈕狀態
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

	for sid: String in cat_data.passive_skill_ids:
		var skill_d := CatData._read_skill_json(
				"res://data/default/skills/passive/" + sid + ".json")
		if not skill_d.is_empty():
			lines.append("【被動】%s" % skill_d.get("display_name", sid))
			lines.append("  " + skill_d.get("description", ""))

	for skill_d: Dictionary in cat_data.active_skills_data:
		var rank_info := _format_rank_scaling(skill_d, player_cat.rank)
		lines.append("【主動】%s  CD: %.1fs" % [
				skill_d.get("display_name", ""), skill_d.get("cooldown", 0.0)])
		lines.append("  " + skill_d.get("description", ""))
		if not rank_info.is_empty():
			lines.append("  " + rank_info)

	DialogManager.show_info("技能資訊", "\n".join(lines))


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
	# 同步 boss_team → GameState.player_team
	GameState.player_team = GameState.player_data.boss_team.duplicate()
	_save_with_snapshot()
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")


func _save_with_snapshot() -> void:
	GameState.arena_data.update_defense_snapshot(
		GameState.player_data.arena_defense_team,
		GameState._player_cat_cache
	)
	GameState.arena_data.save()
	GameState.player_data.save()

func _refresh_cats_list() -> void:
	# 先移除所有子節點
	for child in cats_container.get_children():
		child.queue_free()
	for cat_id: String in GameState.get_owned_cats():
		cats_container.add_child(_make_cat_row(cat_id))

# 根據模式取得最大隊伍數
func _get_max_team_size() -> int:
	match _current_team_type:
		"boss":
			return int(GameState.boss_config.get("max_team_size", 5))
		"dungeon":
			return int(GameState.dungeon_config.get("max_team_size", 5))
		"arena_attack", "arena_defense":
			return int(GameState.arena_config.get("max_team_size", 5))
	return 5
