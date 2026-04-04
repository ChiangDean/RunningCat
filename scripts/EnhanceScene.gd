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
var _food_cost_label: Label
var _special_cost_label: Label
var _special_point_labels: Dictionary = {}  # "hp"/"atk"/"def" -> Label


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

	if _selected_cat_id == "":
		return

	var player_cat := GameState.get_player_cat(_selected_cat_id)
	var cat_data   := CatData.from_json_file(
		"res://data/default/cats/" + _selected_cat_id + ".json")
	if cat_data == null:
		return

	# ── 標題 ──────────────────────────────────
	var name_lbl := Label.new()
	name_lbl.text = cat_data.display_name
	name_lbl.add_theme_font_size_override("font_size", 28)
	_detail_panel.add_child(name_lbl)

	# ── 屬性顯示 ──────────────────────────────
	var stats_title := Label.new()
	stats_title.text = "屬性"
	stats_title.add_theme_font_size_override("font_size", 22)
	_detail_panel.add_child(stats_title)

	for stat_key: String in ["hp", "atk", "def"]:
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 20)
		_stat_labels[stat_key] = lbl
		_detail_panel.add_child(lbl)
	_refresh_stat_labels(cat_data, player_cat)

	_detail_panel.add_child(_make_separator())

	# ── 普通乾糧升級 ──────────────────────────
	var food_title := Label.new()
	food_title.text = "普通乾糧升級"
	food_title.add_theme_font_size_override("font_size", 22)
	_detail_panel.add_child(food_title)

	_food_level_label = Label.new()
	_food_level_label.add_theme_font_size_override("font_size", 20)
	_detail_panel.add_child(_food_level_label)

	_food_cost_label = Label.new()
	_food_cost_label.add_theme_font_size_override("font_size", 20)
	_detail_panel.add_child(_food_cost_label)
	_refresh_food_labels(player_cat)

	var food_btn_row := HBoxContainer.new()
	food_btn_row.add_theme_constant_override("separation", 16)
	_detail_panel.add_child(food_btn_row)

	var upgrade_btn := Button.new()
	upgrade_btn.text = "升級"
	upgrade_btn.custom_minimum_size = Vector2(120.0, 52.0)
	upgrade_btn.pressed.connect(_on_upgrade_one_pressed)
	food_btn_row.add_child(upgrade_btn)

	var max_btn := Button.new()
	max_btn.text = "一鍵升至 Lv.%d" % PlayerCatData.MAX_CAT_FOOD_LEVEL
	max_btn.custom_minimum_size = Vector2(240.0, 52.0)
	max_btn.pressed.connect(_on_upgrade_max_pressed)
	food_btn_row.add_child(max_btn)

	_detail_panel.add_child(_make_separator())

	# ── 特殊乾糧分配 ──────────────────────────
	var special_title := Label.new()
	special_title.text = "特殊乾糧分配"
	special_title.add_theme_font_size_override("font_size", 22)
	_detail_panel.add_child(special_title)

	_special_cost_label = Label.new()
	_special_cost_label.add_theme_font_size_override("font_size", 20)
	_detail_panel.add_child(_special_cost_label)
	_refresh_special_cost_label(player_cat)

	for stat_key: String in ["hp", "atk", "def"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_detail_panel.add_child(row)

		var stat_name_lbl := Label.new()
		stat_name_lbl.text = _stat_display_name(stat_key)
		stat_name_lbl.custom_minimum_size = Vector2(60.0, 44.0)
		stat_name_lbl.add_theme_font_size_override("font_size", 20)
		row.add_child(stat_name_lbl)

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(52.0, 52.0)
		add_btn.pressed.connect(func(): _on_special_add_pressed(stat_key))
		row.add_child(add_btn)

		var pt_lbl := Label.new()
		pt_lbl.add_theme_font_size_override("font_size", 20)
		_special_point_labels[stat_key] = pt_lbl
		row.add_child(pt_lbl)
	_refresh_special_point_labels(player_cat)

	_detail_panel.add_child(_make_separator())

	# ── 重置按鈕 ──────────────────────────────
	var reset_btn := Button.new()
	reset_btn.text = "重置（退回全部素材）"
	reset_btn.custom_minimum_size = Vector2(0.0, 56.0)
	reset_btn.pressed.connect(_on_reset_pressed)
	_detail_panel.add_child(reset_btn)


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

	# HP
	var hp_food_bonus    := int(food_lv * g.get("hp", 0.0))
	var hp_special_bonus := int(sfp.get("hp", 0) * g.get("hp", 0.0))
	var hp_base_with_food := cat_data.max_hp + hp_food_bonus
	_stat_labels["hp"].text = _format_stat("HP", hp_base_with_food, hp_special_bonus)

	# ATK
	var atk_food_bonus    := int(food_lv * g.get("atk", 0.0))
	var atk_special_bonus := int(sfp.get("atk", 0) * g.get("atk", 0.0))
	var atk_base_with_food := cat_data.atk + atk_food_bonus
	_stat_labels["atk"].text = _format_stat("ATK", atk_base_with_food, atk_special_bonus)

	# DEF
	var def_food_bonus    := int(food_lv * g.get("def", 0.0))
	var def_special_bonus := int(sfp.get("def", 0) * g.get("def", 0.0))
	var def_base_with_food := cat_data.defense + def_food_bonus
	_stat_labels["def"].text = _format_stat("DEF", def_base_with_food, def_special_bonus)


func _format_stat(label_name: String, base_with_food: int, special_bonus: int) -> String:
	if special_bonus > 0:
		return "  %s: %d +%d" % [label_name, base_with_food, special_bonus]
	return "  %s: %d" % [label_name, base_with_food]


func _refresh_food_labels(player_cat: PlayerCatData) -> void:
	var lv := player_cat.cat_food_level
	if lv >= PlayerCatData.MAX_CAT_FOOD_LEVEL:
		_food_level_label.text = "  等級：Lv.%d（上限）" % lv
		_food_cost_label.text  = "  已達等級上限"
	else:
		var cost := PlayerCatData.cat_food_cost_for_level(lv)
		_food_level_label.text = "  等級：Lv.%d → Lv.%d" % [lv, lv + 1]
		_food_cost_label.text  = "  費用：%d 普通乾糧（持有 %d）" % [
			cost, GameState.player_data.cat_food]


func _refresh_special_cost_label(player_cat: PlayerCatData) -> void:
	var total_pts := player_cat.get_total_special_points()
	var next_cost := PlayerCatData.special_food_next_cost(total_pts)
	_special_cost_label.text = "  下一點費用：%d 特殊乾糧（持有 %d）" % [
		next_cost, GameState.player_data.special_cat_food]


func _refresh_special_point_labels(player_cat: PlayerCatData) -> void:
	for stat_key: String in ["hp", "atk", "def"]:
		if not _special_point_labels.has(stat_key):
			continue
		var pts: int = player_cat.special_food_points.get(stat_key, 0)
		_special_point_labels[stat_key].text = "已分配 %d 點" % pts


# ── 確認視窗 ──────────────────────────────────

func _show_confirm(message: String, on_confirm: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = message
	dialog.min_size = Vector2(500.0, 200.0)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		on_confirm.call()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())


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


# ── 導航 ──────────────────────────────────────

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
