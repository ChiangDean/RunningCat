class_name DungeonBattleScene
extends Node2D

const BATTLE_BG_TEXTURE := preload("res://assets/sprites/ui/battle_background_homey_v1.png")

var MAX_CATS_ON_FIELD: int = 5

const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0
const NAV_H := 110.0
const NAV_Y := SH - NAV_H

const SKILL_BAR_Y := BATTLE_Y + 10.0
const SKILL_SLOT_W := 100.0
const SKILL_SLOT_H := 90.0

var _player_team: Node2D
var _enemy_team: Node2D
var _battle_manager: BattleManager

var _ui_layer: CanvasLayer
var _timer_label: Label
var _speed_1x: Button
var _speed_2x: Button
var _speed_3x: Button
var _skip_btn: Button
var _level_label: Label
var _result_display: Label
var _skill_bar: Control

var _dungeon_id: String = ""
var _dungeon_key: String = ""
var _dungeon_level: int = 1
var _dungeon_cfg: Dictionary = {}
var _result_submit_inflight := false

@onready var ApiClient = get_node("/root/ApiClient")


func _ready() -> void:
	_dungeon_id = GameState.dungeon_battle_id
	_dungeon_key = GameState.dungeon_battle_key
	_dungeon_level = GameState.dungeon_battle_level

	for cfg: Dictionary in GameState.dungeon_config.get("dungeons", []):
		if cfg.get("id", "") == _dungeon_key:
			_dungeon_cfg = cfg
			break

	MAX_CATS_ON_FIELD = int(GameState.dungeon_config.get("max_team_size", 5))
	_build_scene()
	_start_battle()


func _build_scene() -> void:
	_build_background()
	_build_battle_area()
	_build_ui()


func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = BATTLE_BG_TEXTURE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var bg_tint := ColorRect.new()
	bg_tint.color = Color(0.09, 0.05, 0.12, 0.28)
	bg_tint.size = Vector2(SW, SH)
	add_child(bg_tint)

	var ground := ColorRect.new()
	ground.color = Color(0.15, 0.11, 0.16, 0.52)
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

	_timer_label = _make_label("60.0", Vector2(260.0, 20.0), Vector2(200.0, 50.0), 28)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_timer_label)

	_skip_btn = _make_button("跳過", Vector2(SW - 100.0, 20.0), Vector2(80.0, 44.0))
	_ui_layer.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip_pressed)
	_skip_btn.visible = GameState.can_skip_battle()

	var dungeon_name: String = _dungeon_cfg.get("name", "地城")
	_level_label = _make_label(
		"%s  Lv.%d" % [dungeon_name, _dungeon_level],
		Vector2(0.0, BATTLE_Y + 10.0 + SKILL_SLOT_H + 10.0),
		Vector2(SW, 40.0),
		22
	)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_level_label)

	_skill_bar = _build_skill_bar()
	_ui_layer.add_child(_skill_bar)

	var nav_bg := ColorRect.new()
	nav_bg.color = Color(0.1, 0.1, 0.12, 1.0)
	nav_bg.position = Vector2(0.0, NAV_Y)
	nav_bg.size = Vector2(SW, NAV_H)
	_ui_layer.add_child(nav_bg)

	var retreat_btn := _make_button("撤退", Vector2(10.0, NAV_Y + 10.0), Vector2(SW - 20.0, NAV_H - 20.0))
	retreat_btn.pressed.connect(_on_retreat_pressed)
	_ui_layer.add_child(retreat_btn)

	_result_display = Label.new()
	_result_display.size = Vector2(SW, 80.0)
	_result_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_display.add_theme_font_size_override("font_size", 64)
	_result_display.visible = false
	_ui_layer.add_child(_result_display)


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

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(10.0, 8.0)
	icon.size = Vector2(SKILL_SLOT_W - 20.0, SKILL_SLOT_H - 36.0)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	slot.add_child(icon)

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
			name_lbl.text = cat.active_skills_data[0].get("display_name", "") if cat.active_skills_data.size() > 0 else ""

	for i in range(player_cats.size(), MAX_CATS_ON_FIELD):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node:
			slot_node.visible = false


func _apply_equipment_bonuses(data: CatData) -> void:
	GameState.apply_player_combat_bonuses(data)


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


func _start_battle() -> void:
	_result_display.visible = false

	for child in _player_team.get_children():
		child.queue_free()
	for child in _enemy_team.get_children():
		child.queue_free()

	var player_cats: Array = []
	for i in range(GameState.player_team.size()):
		var player_cat_id: int = GameState.player_team[i]
		var cat_id: String = GameState.get_cat_file_id(player_cat_id)
		if cat_id.is_empty():
			push_error("DungeonBattleScene: 找不到 playerCatId %d 對應的貓咪資料。" % player_cat_id)
			continue

		var path := cat_id + ".json"
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
			push_error("DungeonBattleScene: 無法載入玩家貓咪 %s。" % cat_id)

	var enemy_cats: Array = []
	var mult: float = pow(_dungeon_cfg.get("difficulty_multiplier", 1.03), _dungeon_level - 1)
	var base_hp: float = _dungeon_cfg.get("base_hp", 100.0)
	var base_atk: float = _dungeon_cfg.get("base_atk", 15.0)
	var base_def: float = _dungeon_cfg.get("base_def", 5.0)

	var enemy := CatData.from_json_file("test_enemy.json")
	if enemy:
		enemy.max_hp = roundi(base_hp * mult)
		enemy.atk = roundi(base_atk * mult)
		enemy.defense = roundi(base_def * mult)
		enemy_cats.append(enemy)
	else:
		push_error("DungeonBattleScene: 無法載入 test_enemy。")

	if player_cats.is_empty() or enemy_cats.is_empty():
		push_error("DungeonBattleScene: 戰鬥資料不足。")
		return

	_refresh_skill_bar_names(player_cats)

	var simulator := BattleSimulator.new()
	var events := simulator.simulate(player_cats, enemy_cats)
	_battle_manager.setup(events, player_cats, enemy_cats, _player_team, _enemy_team, _timer_label, _skill_bar)


func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()


func _on_battle_finished(result: String) -> void:
	if result == "WIN":
		_show_result_text("勝利", Color(0.3, 1.0, 0.4, 1.0), 310.0)
		await get_tree().create_timer(1.0).timeout
		_handle_win()
	else:
		_show_result_text("敗北", Color(1.0, 0.3, 0.3, 1.0), 310.0)
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://scenes/DungeonScene.tscn")


func _handle_win() -> void:
	if _result_submit_inflight:
		return

	_result_submit_inflight = true
	ApiClient.complete_dungeon_challenge(int(_dungeon_id), _dungeon_level, _on_complete_challenge)


func _on_complete_challenge(success: bool, data: Variant, error: Dictionary) -> void:
	_result_submit_inflight = false

	if success and data is Dictionary:
		var payload: Dictionary = data
		var overview: Variant = payload.get("overview", {})
		if overview is Dictionary:
			GameState.apply_dungeon_overview(overview)
		var rewards: Variant = payload.get("reward", {})
		_show_reward_popup(_dungeon_level, rewards if rewards is Dictionary else {})
		return

	var message := str(error.get("message", "挑戰結算失敗。"))
	DialogManager.show_info("挑戰結算失敗", message, func():
		get_tree().change_scene_to_file("res://scenes/DungeonScene.tscn")
	)


func _show_reward_popup(level: int, rewards: Dictionary) -> void:
	var lines: Array = ["Lv.%d 獲得獎勵：" % level]
	if int(rewards.get("catFood", 0)) > 0:
		lines.append("  普通乾糧 ×%d" % int(rewards.get("catFood", 0)))
	if int(rewards.get("specialCatFood", 0)) > 0:
		lines.append("  特殊乾糧 ×%d" % int(rewards.get("specialCatFood", 0)))
	if int(rewards.get("diamonds", 0)) > 0:
		lines.append("  鑽石 ×%d" % int(rewards.get("diamonds", 0)))
	if int(rewards.get("trapCages", 0)) > 0:
		lines.append("  誘捕籠 ×%d" % int(rewards.get("trapCages", 0)))
	if int(rewards.get("whiskerShards", 0)) > 0:
		lines.append("  鬍鬚碎片 ×%d" % int(rewards.get("whiskerShards", 0)))

	DialogManager.show_info("挑戰完成", "\n".join(lines), func():
		get_tree().change_scene_to_file("res://scenes/DungeonScene.tscn")
	)


func _show_result_text(text: String, color: Color, y: float) -> void:
	_result_display.text = text
	_result_display.modulate = color
	_result_display.position = Vector2(0.0, y)
	_result_display.visible = true


func _on_retreat_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/DungeonScene.tscn")
