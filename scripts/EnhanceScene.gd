extends Control

## 強化畫面
## 流程：選貓咪 → 查看屬性 → 普通乾糧升級 / 特殊乾糧分配 / 重置

const SW := 720.0
const SH := 1280.0

# ── 目前選中的貓咪 ────────────────────────────
var _selected_cat_id: String = ""
var _detail_panel: VBoxContainer  # 右側詳細面板，每次選貓重建

# ── 顯示標籤（需即時更新） ────────────────────
var _resource_label: Label
var _stat_labels: Dictionary = {}  # "hp"/"atk"/"def" -> Label
var _food_level_label: Label
var _cat_name_label: Label
var _food_cost_label: Label
var _special_cost_label: Label
var _special_point_labels: Dictionary = {}  # "hp"/"atk"/"def" -> Label
var _rank_stars_label: Label
var _rank_upgrade_btn: Button
var _special_plus_btns: Dictionary = {}   # stat_key -> Button
var _special_minus_btns: Dictionary = {}  # stat_key -> Button
var _food_upgrade_btn: Button
var _food_max_btn: Button


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
	root_vbox.add_theme_constant_override("separation", 14)
	root_vbox.offset_left   = 20
	root_vbox.offset_top    = 40
	root_vbox.offset_right  = -20
	root_vbox.offset_bottom = -20
	layer.add_child(root_vbox)

	# ── 頂部列 ────────────────────────────────
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "強化"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	# ── 資源列 ────────────────────────────────
	_resource_label = Label.new()
	_resource_label.add_theme_font_size_override("font_size", 22)
	root_vbox.add_child(_resource_label)
	_refresh_resource_label()

	root_vbox.add_child(_make_separator())

	# ── 貓咪選擇列 ───────────────────────────
	var cat_select_title := Label.new()
	cat_select_title.text = "選擇貓咪"
	cat_select_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(cat_select_title)

	var cat_row := HBoxContainer.new()
	cat_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(cat_row)

	for cat_id: String in GameState.get_owned_cats():
		var btn := Button.new()
		btn.text = _get_display_name(cat_id)
		btn.custom_minimum_size = Vector2(140.0, 56.0)
		btn.pressed.connect(func(): _select_cat(cat_id))
		cat_row.add_child(btn)

	root_vbox.add_child(_make_separator())

	# ── 詳細面板（初始為空，選貓後填充）─────────
	_detail_panel = VBoxContainer.new()
	_detail_panel.add_theme_constant_override("separation", 12)
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_detail_panel)

	# 若只有一隻貓，自動選中
	var _owned := GameState.get_owned_cats()
	if _owned.size() > 0:
		_select_cat(_owned[0])


# ── 貓咪選擇 ──────────────────────────────────

func _select_cat(cat_id: String) -> void:
	_selected_cat_id = cat_id
	_rebuild_detail_panel()


func _rebuild_detail_panel() -> void:
	for child in _detail_panel.get_children():
		child.queue_free()
	_stat_labels.clear()
	_special_point_labels.clear()
	_special_plus_btns.clear()
	_special_minus_btns.clear()
	_rank_stars_label = null
	_rank_upgrade_btn = null
	_food_upgrade_btn = null
	_food_max_btn = null
	_cat_name_label = null

	if _selected_cat_id == "":
		return

	var player_cat := GameState.get_player_cat(_selected_cat_id)
	var cat_data   := CatData.from_json_file(
		"res://data/default/cats/" + _selected_cat_id + ".json")
	if cat_data == null:
		return

	# ── 名字列（名字 + 星星 + ? + 升階）──────────────
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	_detail_panel.add_child(name_row)

	_cat_name_label = Label.new()
	_cat_name_label.text = CatRegistry.get_cat_display_name_with_lv(_selected_cat_id, player_cat.cat_food_level)
	_cat_name_label.add_theme_font_size_override("font_size", 28)
	name_row.add_child(_cat_name_label)

	_rank_stars_label = Label.new()
	_rank_stars_label.add_theme_font_size_override("font_size", 20)
	_rank_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	name_row.add_child(_rank_stars_label)

	var rank_info_btn := Button.new()
	rank_info_btn.text = "?"
	rank_info_btn.custom_minimum_size = Vector2(36.0, 36.0)
	rank_info_btn.pressed.connect(func(): _show_rank_bonus_info(cat_data, player_cat.rank))
	name_row.add_child(rank_info_btn)

	var name_spacer := Control.new()
	name_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_spacer)

	_rank_upgrade_btn = Button.new()
	_rank_upgrade_btn.custom_minimum_size = Vector2(160.0, 44.0)
	_rank_upgrade_btn.pressed.connect(_on_rank_upgrade_pressed)
	name_row.add_child(_rank_upgrade_btn)
	_refresh_rank_labels(player_cat)

	# ── 屬性 + 特殊乾糧 ───────────────────────────
	var stats_title := Label.new()
	stats_title.text = "屬性"
	stats_title.add_theme_font_size_override("font_size", 22)
	_detail_panel.add_child(stats_title)

	_special_cost_label = Label.new()
	_special_cost_label.add_theme_font_size_override("font_size", 18)
	_detail_panel.add_child(_special_cost_label)

	for stat_key: String in ["hp", "atk", "def"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_detail_panel.add_child(row)

		var stat_lbl := Label.new()
		stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_lbl.add_theme_font_size_override("font_size", 20)
		_stat_labels[stat_key] = stat_lbl
		row.add_child(stat_lbl)

		var minus_btn := Button.new()
		minus_btn.text = "−"
		minus_btn.custom_minimum_size = Vector2(44.0, 44.0)
		minus_btn.pressed.connect(func(): _on_special_remove_pressed(stat_key))
		_special_minus_btns[stat_key] = minus_btn
		row.add_child(minus_btn)

		var pt_lbl := Label.new()
		pt_lbl.add_theme_font_size_override("font_size", 20)
		pt_lbl.custom_minimum_size = Vector2(40.0, 0.0)
		pt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_special_point_labels[stat_key] = pt_lbl
		row.add_child(pt_lbl)

		var plus_btn := Button.new()
		plus_btn.custom_minimum_size = Vector2(44.0, 44.0)
		plus_btn.pressed.connect(func(): _on_special_add_pressed(stat_key))
		_special_plus_btns[stat_key] = plus_btn
		row.add_child(plus_btn)

	_refresh_stat_labels(cat_data, player_cat)
	_refresh_special_cost_label(player_cat)
	_refresh_special_point_labels(player_cat)
	_refresh_special_buttons(player_cat)

	_detail_panel.add_child(_make_separator())

	# ── 技能資訊 ──────────────────────────────
	_build_skill_section(cat_data, player_cat)

	_detail_panel.add_child(_make_separator())

	# ── 升級、快速升級、重置按鈕同一列 ─────────────
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 16)
	_detail_panel.add_child(action_row)

	_food_upgrade_btn = Button.new()
	_food_upgrade_btn.pressed.connect(_on_upgrade_one_pressed)
	_food_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_food_upgrade_btn)

	_food_max_btn = Button.new()
	_food_max_btn.pressed.connect(_on_upgrade_max_pressed)
	_food_max_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_food_max_btn)

	var reset_btn := Button.new()
	reset_btn.text = "重置"
	reset_btn.pressed.connect(_on_reset_pressed)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(reset_btn)

	# 設定按鈕比例 40% 40% 20%
	_food_upgrade_btn.custom_minimum_size = Vector2(0, 52.0)
	_food_max_btn.custom_minimum_size = Vector2(0, 52.0)
	reset_btn.custom_minimum_size = Vector2(0, 52.0)
	_food_upgrade_btn.size_flags_stretch_ratio = 4
	_food_max_btn.size_flags_stretch_ratio = 4
	reset_btn.size_flags_stretch_ratio = 2

	_food_cost_label = Label.new()
	_food_cost_label.add_theme_font_size_override("font_size", 20)
	_detail_panel.add_child(_food_cost_label)
	_refresh_food_labels(player_cat)


# ── 升級邏輯 ──────────────────────────────────

func _on_upgrade_one_pressed() -> void:
	var player_cat := GameState.get_player_cat(_selected_cat_id)
	if player_cat.cat_food_level >= PlayerCatData.MAX_CAT_FOOD_LEVEL:
		return
	var cost := PlayerCatData.cat_food_cost_for_level(player_cat.cat_food_level)
	if GameState.player_data.cat_food < cost:
		return
	GameState.player_data.cat_food -= cost
	player_cat.cat_food_level += 1
	GameState.save_all()
	_refresh_all_labels()


func _on_upgrade_max_pressed() -> void:
	var player_cat := GameState.get_player_cat(_selected_cat_id)
	var levels_to_go := PlayerCatData.MAX_CAT_FOOD_LEVEL - player_cat.cat_food_level
	if levels_to_go <= 0:
		return

	# 計算實際可以升幾級
	var available := GameState.player_data.cat_food
	var upgradable := 0
	var total_cost := 0
	for i in range(levels_to_go):
		var lv := player_cat.cat_food_level + i
		var c := PlayerCatData.cat_food_cost_for_level(lv)
		if total_cost + c > available:
			break
		total_cost += c
		upgradable += 1

	if upgradable == 0:
		return

	var target_level := player_cat.cat_food_level + upgradable
	var confirm_msg := "升至 Lv.%d，花費 %d 普通乾糧，確定嗎？" % [target_level, total_cost]
	_show_confirm(confirm_msg, func():
		GameState.player_data.cat_food -= total_cost
		player_cat.cat_food_level = target_level
		GameState.save_all()
		_refresh_all_labels()
	)


func _on_special_add_pressed(stat_key: String) -> void:
	var player_cat := GameState.get_player_cat(_selected_cat_id)
	var total_pts := player_cat.get_total_special_points()
	var cost := PlayerCatData.special_food_next_cost(total_pts)
	if GameState.player_data.special_cat_food < cost:
		return
	GameState.player_data.special_cat_food -= cost
	player_cat.special_food_points[stat_key] = player_cat.special_food_points.get(stat_key, 0) + 1
	GameState.save_all()
	_refresh_all_labels()


func _on_reset_pressed() -> void:
	var player_cat := GameState.get_player_cat(_selected_cat_id)
	var food_refund := PlayerCatData.cat_food_total_cost(1, player_cat.cat_food_level)
	var total_pts   := player_cat.get_total_special_points()
	var special_refund := PlayerCatData.special_food_total_spent(total_pts)

	# 目前重置費用為 0 鑽石（未來可接 diamonds 邏輯）
	var diamond_cost := 0
	var msg := "退回 %d 普通乾糧、%d 特殊乾糧\n費用：%d 鑽石\n確定重置嗎？" % [
		food_refund, special_refund, diamond_cost]
	_show_confirm(msg, func():
		GameState.player_data.cat_food         += food_refund
		GameState.player_data.special_cat_food += special_refund
		player_cat.cat_food_level   = 1
		player_cat.special_food_points = {"hp": 0, "atk": 0, "def": 0}
		GameState.save_all()
		_refresh_all_labels()
	)


func _on_special_remove_pressed(stat_key: String) -> void:
	var player_cat := GameState.get_player_cat(_selected_cat_id)
	if player_cat.special_food_points.get(stat_key, 0) <= 0:
		return
	var total_pts := player_cat.get_total_special_points()
	var refund := total_pts  # 退還最後一點的費用（第 total_pts 點費用 = total_pts）
	player_cat.special_food_points[stat_key] -= 1
	GameState.player_data.special_cat_food += refund
	GameState.save_all()
	_refresh_all_labels()


func _on_rank_upgrade_pressed() -> void:
	var player_cat := GameState.get_player_cat(_selected_cat_id)
	var target_rank := player_cat.rank + 1
	var cost := PlayerCatData.rank_upgrade_cost(target_rank)
	if player_cat.cat_shards < cost:
		return
	player_cat.cat_shards -= cost
	player_cat.rank += 1
	GameState.save_all()
	_refresh_all_labels()


func _refresh_rank_labels(player_cat: PlayerCatData) -> void:
	if _rank_stars_label == null or _rank_upgrade_btn == null:
		return
	var rank := player_cat.rank
	_rank_stars_label.text = "★×%d" % rank if rank > 0 else ""
	var cost := PlayerCatData.rank_upgrade_cost(rank + 1)
	var held := player_cat.cat_shards
	_rank_upgrade_btn.text = "升階(%d/%d)" % [held, cost]
	_rank_upgrade_btn.disabled = held < cost


func _refresh_special_buttons(player_cat: PlayerCatData) -> void:
	var held      := GameState.player_data.special_cat_food
	var total_pts := player_cat.get_total_special_points()
	var next_cost := PlayerCatData.special_food_next_cost(total_pts)
	for stat_key: String in ["hp", "atk", "def"]:
		if _special_plus_btns.has(stat_key):
			var btn: Button = _special_plus_btns[stat_key]
			btn.text     = "+"
			btn.disabled = held < next_cost
		if _special_minus_btns.has(stat_key):
			var btn: Button = _special_minus_btns[stat_key]
			btn.disabled = player_cat.special_food_points.get(stat_key, 0) <= 0


func _show_rank_bonus_info(cat_data: CatData, rank: int) -> void:
	var rg := cat_data.rank_growth
	var lines: Array
	if rank <= 0:
		lines = ["尚未升階", "", "每升一階：", "  血量、攻擊、防禦各額外提升 +1%"]
	else:
		lines = [
			"目前品階 +%d 的加成：" % rank,
			"  血量額外提升 +%.0f%%" % (rank * rg.get("hp_percent", 1.0)),
			"  攻擊額外提升 +%.0f%%" % (rank * rg.get("atk_percent", 1.0)),
			"  防禦額外提升 +%.0f%%" % (rank * rg.get("def_percent", 1.0)),
		]
	DialogManager.show_info("品階加成說明", "\n".join(lines))


# ── 標籤更新 ──────────────────────────────────

func _refresh_all_labels() -> void:
	_refresh_resource_label()
	if _selected_cat_id == "":
		return
	var player_cat := GameState.get_player_cat(_selected_cat_id)
	var cat_data   := CatData.from_json_file(
		"res://data/default/cats/" + _selected_cat_id + ".json")
	if cat_data == null:
		return
	_refresh_stat_labels(cat_data, player_cat)
	_refresh_food_labels(player_cat)
	_refresh_special_cost_label(player_cat)
	_refresh_special_point_labels(player_cat)
	_refresh_special_buttons(player_cat)
	_refresh_rank_labels(player_cat)
	# 更新名稱Lv顯示
	if _cat_name_label != null:
		_cat_name_label.text = CatRegistry.get_cat_display_name_with_lv(_selected_cat_id, player_cat.cat_food_level)


func _refresh_resource_label() -> void:
	_resource_label.text = "普通乾糧：%d　特殊乾糧：%d　金幣：%d" % [
		GameState.player_data.cat_food,
		GameState.player_data.special_cat_food,
		GameState.player_data.gold,
	]


func _refresh_stat_labels(cat_data: CatData, player_cat: PlayerCatData) -> void:
	var food_lv := player_cat.cat_food_level - 1
	var sfp     := player_cat.special_food_points
	var g       := cat_data.enhancement_growth
	var rk      := player_cat.rank
	var rg      := cat_data.rank_growth

	# HP
	var hp_pre  := cat_data.max_hp + int(food_lv * g.get("hp", 0.0)) + int(sfp.get("hp", 0) * g.get("hp", 0.0))
	var hp_final := int(hp_pre * (1.0 + rk * rg.get("hp_percent", 1.0) / 100.0))
	_stat_labels["hp"].text = "HP: %d" % hp_final

	# ATK
	var atk_pre  := cat_data.atk + int(food_lv * g.get("atk", 0.0)) + int(sfp.get("atk", 0) * g.get("atk", 0.0))
	var atk_final := int(atk_pre * (1.0 + rk * rg.get("atk_percent", 1.0) / 100.0))
	_stat_labels["atk"].text = "ATK: %d" % atk_final

	# DEF
	var def_pre  := cat_data.defense + int(food_lv * g.get("def", 0.0)) + int(sfp.get("def", 0) * g.get("def", 0.0))
	var def_final := int(def_pre * (1.0 + rk * rg.get("def_percent", 1.0) / 100.0))
	_stat_labels["def"].text = "DEF: %d" % def_final


func _refresh_food_labels(player_cat: PlayerCatData) -> void:
	var lv   := player_cat.cat_food_level
	var held := GameState.player_data.cat_food
	if lv >= PlayerCatData.MAX_CAT_FOOD_LEVEL:
		if _food_cost_label != null:
			_food_cost_label.text  = ""
		if _food_upgrade_btn:
			_food_upgrade_btn.text     = "升級(Max)"
			_food_upgrade_btn.disabled = true
		if _food_max_btn:
			_food_max_btn.text     = "快速升級(Max)"
			_food_max_btn.disabled = true
	else:
		var cost := PlayerCatData.cat_food_cost_for_level(lv)
		if _food_cost_label != null:
			_food_cost_label.text  = ""
		if _food_upgrade_btn:
			_food_upgrade_btn.text     = "升級(%d/%d)" % [held, cost]
			_food_upgrade_btn.disabled = held < cost
		if _food_max_btn:
			# 計算目前乾糧可升到的最高等級
			var target_lv  := lv
			var total_cost := 0
			while target_lv < PlayerCatData.MAX_CAT_FOOD_LEVEL:
				var c := PlayerCatData.cat_food_cost_for_level(target_lv)
				if total_cost + c > held:
					break
				total_cost += c
				target_lv  += 1
			if target_lv > lv:
				_food_max_btn.text     = "快速升級(Lv%d)" % [target_lv]
				_food_max_btn.disabled = false
			else:
				_food_max_btn.text     = "快速升級(不足)"
				_food_max_btn.disabled = true


func _refresh_special_cost_label(player_cat: PlayerCatData) -> void:
	var total_pts := player_cat.get_total_special_points()
	var next_cost := PlayerCatData.special_food_next_cost(total_pts)
	_special_cost_label.text = "  特殊乾糧下一點費用：%d（持有 %d）" % [
		next_cost, GameState.player_data.special_cat_food]


func _refresh_special_point_labels(player_cat: PlayerCatData) -> void:
	for stat_key: String in ["hp", "atk", "def"]:
		if not _special_point_labels.has(stat_key):
			continue
		var pts: int = player_cat.special_food_points.get(stat_key, 0)
		_special_point_labels[stat_key].text = "%d" % pts


# ── 確認視窗 ──────────────────────────────────

func _show_confirm(message: String, on_confirm: Callable) -> void:
	DialogManager.show_confirm("確認", message, on_confirm)


# ── 輔助 ──────────────────────────────────────

func _get_display_name(cat_id: String) -> String:
	var data := CatData.from_json_file("res://data/default/cats/" + cat_id + ".json")
	if data != null:
		return data.display_name
	return cat_id


func _stat_display_name(stat_key: String) -> String:
	match stat_key:
		"hp":  return "HP"
		"atk": return "ATK"
		"def": return "DEF"
	return stat_key.to_upper()


func _make_separator() -> HSeparator:
	return HSeparator.new()


# ── 技能區塊 ──────────────────────────────────

func _build_skill_section(cat_data: CatData, player_cat: PlayerCatData) -> void:
	var skill_title := Label.new()
	skill_title.text = "技能"
	skill_title.add_theme_font_size_override("font_size", 22)
	_detail_panel.add_child(skill_title)

	var rank: int = player_cat.rank

	# 被動技能
	for sid: String in cat_data.passive_skill_ids:
		var skill_d := CatData._read_skill_json(
				"res://data/default/skills/passive/" + sid + ".json")
		if skill_d.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_detail_panel.add_child(row)

		var lbl := Label.new()
		lbl.text = "【被動】%s" % skill_d.get("display_name", sid)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(lbl)

		# 品階標示（每 5 階 +1 技能等級，至少 5 階才顯示）
		if rank >= 5:
			var rank_lbl := Label.new()
			rank_lbl.text = "+%d" % (rank / 5)
			rank_lbl.add_theme_font_size_override("font_size", 16)
			rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			row.add_child(rank_lbl)

		# 提示按鈕
		var info_btn := Button.new()
		info_btn.text = "?"
		info_btn.custom_minimum_size = Vector2(36.0, 36.0)
		info_btn.pressed.connect(func():
			_show_skill_bonus_info(skill_d, rank, false)
		)
		row.add_child(info_btn)

	# 主動技能
	for skill_d: Dictionary in cat_data.active_skills_data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_detail_panel.add_child(row)

		var lbl := Label.new()
		lbl.text = "【主動】%s  CD:%.1fs" % [
				skill_d.get("display_name", ""), skill_d.get("cooldown", 0.0)]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(lbl)

		if rank >= 5:
			var rank_lbl := Label.new()
			rank_lbl.text = "+%d" % (rank / 5)
			rank_lbl.add_theme_font_size_override("font_size", 16)
			rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			row.add_child(rank_lbl)

		var info_btn := Button.new()
		info_btn.text = "?"
		info_btn.custom_minimum_size = Vector2(36.0, 36.0)
		info_btn.pressed.connect(func():
			_show_skill_bonus_info(skill_d, rank, true)
		)
		row.add_child(info_btn)


func _show_skill_bonus_info(skill_d: Dictionary, rank: int, is_active: bool) -> void:
	var name: String = skill_d.get("display_name", "")
	var desc: String = skill_d.get("description", "")
	var scaling: Array = skill_d.get("rank_scaling", [])
	var effects: Array = skill_d.get("effects", [])

	var lines: Array = [name, desc, ""]

	if rank <= 0 or scaling.is_empty():
		lines.append("尚未升階，無額外加成。")
	else:
		lines.append("目前品階 +%d 的技能加成：" % rank)
		for rs: Dictionary in scaling:
			var eff_idx: int = rs.get("effect_index", 0)
			var per_5: float = rs.get("per_5_ranks", 0.0)
			var bonus: float = floorf(rank / 5.0) * per_5
			if bonus <= 0.0:
				continue
			var stat_name: String = ""
			if eff_idx < effects.size():
				var eff: Dictionary = effects[eff_idx]
				stat_name = _stat_display_label(eff.get("stat", ""), eff.get("type", ""))
			lines.append("  %s 額外增強 +%.0f%%" % [stat_name, bonus * 100.0])

	DialogManager.show_info("技能加成說明", "\n".join(lines))


func _stat_display_label(stat: String, eff_type: String) -> String:
	match stat:
		"defense": return "防禦力"
		"atk":     return "攻擊力"
		"speed":   return "速度"
		"max_hp":  return "最大 HP"
		_:
			if eff_type == "damage": return "傷害"
			if eff_type == "reflect": return "反彈傷害"
			return "效果"


# ── 導航 ──────────────────────────────────────

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
