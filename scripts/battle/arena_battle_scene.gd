class_name ArenaBattleScene
extends Node2D

## 競技場戰鬥場景
## - 勝利：積分 +N，更新連勝，返回競技場
## - 失敗：積分 -N，更新連敗，返回競技場

const MAX_CATS_ON_FIELD: int = 5

const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0
const NAV_H := 110.0
const NAV_Y := SH - NAV_H

const SKILL_BAR_Y := BATTLE_Y + 10.0
const SKILL_SLOT_W := 100.0
const SKILL_SLOT_H := 90.0

# ── 戰鬥節點 ───────────────────────────���─────
var _player_team: Node2D
var _enemy_team: Node2D
var _battle_manager: BattleManager

# ── UI 節點 ──────────────────────────────────
var _ui_layer: CanvasLayer
var _timer_label: Label
var _speed_1x: Button
var _speed_2x: Button
var _speed_3x: Button
var _skip_btn: Button
var _skill_bar: Control

# ── 對手資料 ─────────────────────────────────��
var _opponent: Dictionary = {}


func _ready() -> void:
	_opponent = GameState.arena_opponent
	_build_scene()
	_start_battle()


# ── 建立場景 ──────────────────────────────────

func _build_scene() -> void:
	_build_background()
	_build_battle_area()
	_build_ui()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.15, 1.0)
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var ground := ColorRect.new()
	ground.color = Color(0.18, 0.15, 0.22, 1.0)
	ground.position = Vector2(0.0, BATTLE_Y)
	ground.size = Vector2(SW, NAV_Y - BATTLE_Y)
	add_child(ground)

	var wall_l := ColorRect.new()
	wall_l.color = Color(0.5, 0.2, 0.7, 1.0)
	wall_l.position = Vector2(0.0, 200.0)
	wall_l.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(wall_l)

	var wall_r := ColorRect.new()
	wall_r.color = Color(0.5, 0.2, 0.7, 1.0)
	wall_r.position = Vector2(SW - 20.0, 200.0)
	wall_r.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(wall_r)


func _build_battle_area() -> void:
	_player_team = Node2D.new()
	_player_team.position = Vector2(0.0, BATTLE_Y)
	add_child(_player_team)

	_enemy_team = Node2D.new()
	_enemy_team.position = Vector2(0.0, BATTLE_Y)
	add_child(_enemy_team)

	_battle_manager = BattleManager.new()
	add_child(_battle_manager)
	_battle_manager.battle_finished.connect(_on_battle_finished)


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	# 速度按鈕
	_speed_1x = _make_button("1x", Vector2(20.0, 20.0), Vector2(70.0, 44.0))
	_speed_2x = _make_button("2x", Vector2(95.0, 20.0), Vector2(70.0, 44.0))
	_speed_3x = _make_button("3x", Vector2(170.0, 20.0), Vector2(70.0, 44.0))
	_ui_layer.add_child(_speed_1x)
	_ui_layer.add_child(_speed_2x)
	_ui_layer.add_child(_speed_3x)
	_speed_1x.pressed.connect(func(): _set_speed(1.0, _speed_1x))
	_speed_2x.pressed.connect(func(): _set_speed(2.0, _speed_2x))
	_speed_3x.pressed.connect(func(): _set_speed(3.0, _speed_3x))
	_apply_speed_unlocks()
	_highlight_speed_btn(_speed_1x)

	# 計時器
	_timer_label = _make_label("60.0", Vector2(260.0, 20.0), Vector2(200.0, 50.0), 28)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_timer_label)

	# 跳過
	_skip_btn = _make_button("跳過", Vector2(SW - 100.0, 20.0), Vector2(80.0, 44.0))
	_ui_layer.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip_pressed)
	_skip_btn.visible = GameState.can_skip_battle()

	# ── 競技場對戰標題（放在速度按鈕下方，y ≈ 74）──
	var my_data := GameState.arena_data
	var opp_score: int = _opponent.get("score", 0)
	const HEADER_Y := 74.0
	const HALF := SW / 2.0

	# 我方
	var my_name_lbl := _make_label(
		my_data.player_name,
		Vector2(10.0, HEADER_Y),
		Vector2(HALF - 30.0, 26.0), 18
	)
	my_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ui_layer.add_child(my_name_lbl)

	var my_rank_lbl := _make_label(
		"%s  %d" % [ArenaRankSystem.score_to_rank_name(my_data.score), my_data.score],
		Vector2(10.0, HEADER_Y + 28.0),
		Vector2(HALF - 30.0, 22.0), 14
	)
	my_rank_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	my_rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ui_layer.add_child(my_rank_lbl)

	# VS
	var vs_lbl := _make_label("VS",
		Vector2(HALF - 20.0, HEADER_Y + 6.0),
		Vector2(40.0, 36.0), 22)
	vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	_ui_layer.add_child(vs_lbl)

	# 對手
	var opp_name_lbl := _make_label(
		_opponent.get("player_name", "???"),
		Vector2(HALF + 20.0, HEADER_Y),
		Vector2(HALF - 30.0, 26.0), 18
	)
	opp_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ui_layer.add_child(opp_name_lbl)

	var opp_rank_lbl := _make_label(
		"%s  %d" % [_opponent.get("rank_name", ""), opp_score],
		Vector2(HALF + 20.0, HEADER_Y + 28.0),
		Vector2(HALF - 30.0, 22.0), 14
	)
	opp_rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7))
	opp_rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ui_layer.add_child(opp_rank_lbl)

	# 技能列
	_skill_bar = _build_skill_bar()
	_ui_layer.add_child(_skill_bar)

	# 底部背景
	var nav_bg := ColorRect.new()
	nav_bg.color = Color(0.1, 0.1, 0.12, 1.0)
	nav_bg.position = Vector2(0.0, NAV_Y)
	nav_bg.size = Vector2(SW, NAV_H)
	_ui_layer.add_child(nav_bg)

	# 撤退按鈕
	var retreat_btn := _make_button("撤退", Vector2(10.0, NAV_Y + 10.0), Vector2(SW - 20.0, NAV_H - 20.0))
	retreat_btn.pressed.connect(_on_retreat_pressed)
	_ui_layer.add_child(retreat_btn)



func _build_skill_bar() -> Control:
	var bar := Control.new()
	bar.name = "SkillBar"
	var total_w := SKILL_SLOT_W * MAX_CATS_ON_FIELD + 8.0 * (MAX_CATS_ON_FIELD - 1)
	bar.position = Vector2((SW - total_w) / 2.0, SKILL_BAR_Y)
	bar.size = Vector2(total_w, SKILL_SLOT_H)

	for i in range(MAX_CATS_ON_FIELD):
		var slot := _make_skill_slot(i)
		slot.position = Vector2(i * (SKILL_SLOT_W + 8.0), 0.0)
		bar.add_child(slot)

	return bar


func _make_skill_slot(idx: int) -> Control:
	var slot := Control.new()
	slot.name = "Slot%d" % idx
	slot.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)

	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	bg.color = Color(0.15, 0.10, 0.20, 1.0)
	slot.add_child(bg)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.size = Vector2(SKILL_SLOT_W, 22.0)
	name_lbl.position = Vector2(0.0, SKILL_SLOT_H - 24.0)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_contents = true
	slot.add_child(name_lbl)

	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H - 24.0)
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.visible = false
	slot.add_child(overlay)

	var cd_lbl := Label.new()
	cd_lbl.name = "CdLabel"
	cd_lbl.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H - 24.0)
	cd_lbl.add_theme_font_size_override("font_size", 22)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_lbl.visible = false
	slot.add_child(cd_lbl)

	var buff_frame := ColorRect.new()
	buff_frame.name = "BuffFrame"
	buff_frame.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	buff_frame.color = Color(1.0, 0.85, 0.0, 0.0)
	buff_frame.visible = false
	slot.add_child(buff_frame)

	var border_color := Color(1.0, 0.85, 0.0, 1.0)
	var bt := 3.0
	for side in [
		[Vector2(0, 0), Vector2(SKILL_SLOT_W, bt)],
		[Vector2(0, SKILL_SLOT_H - bt), Vector2(SKILL_SLOT_W, bt)],
		[Vector2(0, 0), Vector2(bt, SKILL_SLOT_H)],
		[Vector2(SKILL_SLOT_W - bt, 0), Vector2(bt, SKILL_SLOT_H)],
	]:
		var border := ColorRect.new()
		border.position = side[0]
		border.size = side[1]
		border.color = border_color
		buff_frame.add_child(border)

	return slot


func _refresh_skill_bar_names(player_cats: Array) -> void:
	if _skill_bar == null:
		return
	for i in range(player_cats.size()):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node == null:
			continue
		var name_lbl: Label = slot_node.get_node_or_null("NameLabel")
		if name_lbl:
			var cat: CatData = player_cats[i]
			name_lbl.text = cat.active_skills_data[0].get("display_name", "") \
					if cat.active_skills_data.size() > 0 else ""
	for i in range(player_cats.size(), MAX_CATS_ON_FIELD):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node:
			slot_node.visible = false


## 將鏟屎官戰鬥加成套用至 CatData（裝備 + 回憶 + 寶藏）
func _apply_equipment_bonuses(data: CatData) -> void:
	GameState.apply_player_combat_bonuses(data)


# ── 工廠輔助 ───────────────────────��─────────

func _make_label(txt: String, pos: Vector2, sz: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	return lbl


func _make_button(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.position = pos
	btn.size = sz
	return btn


func _set_speed(mult: float, active_btn: Button) -> void:
	if mult > GameState.get_special_ability_speed_cap():
		return
	_battle_manager.set_speed(mult)
	_highlight_speed_btn(active_btn)


func _apply_speed_unlocks() -> void:
	var speed_cap: float = GameState.get_special_ability_speed_cap()
	_speed_2x.visible = speed_cap >= 2.0
	_speed_3x.visible = speed_cap >= 3.0


func _highlight_speed_btn(active: Button) -> void:
	for btn: Button in [_speed_1x, _speed_2x, _speed_3x]:
		if btn == null or not btn.visible:
			continue
		btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
	active.modulate = Color(1.0, 1.0, 1.0, 1.0)


# ── 戰鬥初始化 ────────────────────────────────

func _start_battle() -> void:
	for child in _player_team.get_children():
		child.queue_free()
	for child in _enemy_team.get_children():
		child.queue_free()

	# 玩家貓咪
	var player_cats: Array = []
	for i in range(GameState.player_team.size()):
		var player_cat_id: int = GameState.player_team[i]
		var cat_id: String = GameState.get_cat_file_id(player_cat_id)
		if cat_id.is_empty():
			push_error("ArenaBattleScene: 無法解析 playerCatId %d 的本地貓咪檔名" % player_cat_id)
			continue
		var path := "res://data/default/cats/" + cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			if data.active_skill_configs.size() > 0:
				data.active_skill_configs[0]["initial_delay"] = GameState.get_delay(i)
			var player_cat := GameState.get_player_cat(cat_id)
			data.apply_enhancement(player_cat)
			data.apply_rank_bonus(player_cat)
			_apply_equipment_bonuses(data)
			data._load_skill_data()
			if data.active_skills_data.size() > 0:
				data.active_skills_data[0]["initial_delay"] = GameState.get_delay(i)
			player_cats.append(data)
		else:
			push_error("ArenaBattleScene: 無法載入玩家貓咪 " + cat_id)

	# 敵方貓咪（對手防守隊伍，套用快照強化數值）
	var enemy_cats: Array = []
	var defense_team: Array = _opponent.get("defense_team", [])
	var defense_snapshot: Dictionary = _opponent.get("defense_snapshot", {})
	if defense_team.is_empty():
		defense_team = ["test_enemy"]

	for cat_id: String in defense_team:
		var path := "res://data/default/cats/" + cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			var snap: Dictionary = defense_snapshot.get(cat_id, {})
			if not snap.is_empty():
				var pcat := PlayerCatData.new()
				pcat.cat_id = cat_id
				pcat.cat_food_level = snap.get("cat_food_level", 1)
				var sfp: Dictionary = snap.get("special_food_points", {})
				pcat.special_food_points = {
					"hp":  sfp.get("hp",  0),
					"atk": sfp.get("atk", 0),
					"def": sfp.get("def", 0),
				}
				pcat.rank = snap.get("rank", 0)
				data.apply_enhancement(pcat)
				data.apply_rank_bonus(pcat)
				data._load_skill_data()
			enemy_cats.append(data)
		else:
			push_error("ArenaBattleScene: 無法載入對手貓咪 " + cat_id)

	if player_cats.is_empty() or enemy_cats.is_empty():
		push_error("ArenaBattleScene: 貓咪資料不足，返回競技場")
		get_tree().change_scene_to_file("res://scenes/ArenaScene.tscn")
		return

	_refresh_skill_bar_names(player_cats)

	var simulator := BattleSimulator.new()
	var events := simulator.simulate(player_cats, enemy_cats)
	_battle_manager.setup(events, player_cats, enemy_cats,
			_player_team, _enemy_team, _timer_label, _skill_bar)


func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()


# ── 戰鬥結果 ──────────────────────────────────

func _on_battle_finished(result: String) -> void:
	_handle_result(result == "WIN")


func _handle_result(is_win: bool) -> void:
	var d := GameState.arena_data
	var opp_score: int = _opponent.get("score", 0)
	var delta: int

	if is_win:
		delta = ArenaRankSystem.calc_win_delta(d.score, opp_score, d.win_streak + 1)
		d.record_win()
	else:
		delta = ArenaRankSystem.calc_loss_delta(d.score, opp_score, d.loss_streak + 1)
		d.record_loss()

	var old_score := d.score
	d.add_score(delta)
	GameState.save_all()

	_show_result_popup(is_win, delta, old_score, d.score)


func _show_result_popup(is_win: bool, delta: int, old_score: int, new_score: int) -> void:
	var d := GameState.arena_data
	var result_text := "勝利！" if is_win else "敗北"
	var delta_str := ("+%d" % delta) if delta >= 0 else "%d" % delta
	var rank_name := ArenaRankSystem.score_to_rank_name(new_score)

	const POPUP_W := 440.0
	const POPUP_H := 300.0
	var popup := PanelContainer.new()
	popup.position = Vector2((SW - POPUP_W) / 2.0, (SH - POPUP_H) / 2.0)
	popup.custom_minimum_size = Vector2(POPUP_W, POPUP_H)
	_ui_layer.add_child(popup)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	popup.add_child(vbox)

	var result_lbl := Label.new()
	result_lbl.text = result_text
	result_lbl.add_theme_font_size_override("font_size", 40)
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4) if is_win else Color(1.0, 0.3, 0.3)
	)
	vbox.add_child(result_lbl)

	var rank_lbl := Label.new()
	rank_lbl.text = rank_name
	rank_lbl.add_theme_font_size_override("font_size", 26)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rank_lbl)

	var delta_lbl := Label.new()
	delta_lbl.text = "積分變化：%s" % delta_str
	delta_lbl.add_theme_font_size_override("font_size", 22)
	delta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delta_lbl.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if delta >= 0 else Color(1.0, 0.4, 0.4)
	)
	vbox.add_child(delta_lbl)

	var score_lbl := Label.new()
	score_lbl.text = "目前積分：%d" % new_score
	score_lbl.add_theme_font_size_override("font_size", 22)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "（點擊任意處返回）"
	hint_lbl.add_theme_font_size_override("font_size", 16)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint_lbl)

	# 點擊任意處關閉
	var area := ColorRect.new()
	area.color = Color(0.0, 0.0, 0.0, 0.0)
	area.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_layer.add_child(area)
	area.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			area.queue_free()
			popup.queue_free()
			get_tree().change_scene_to_file("res://scenes/ArenaScene.tscn")
	)


func _on_retreat_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ArenaScene.tscn")
