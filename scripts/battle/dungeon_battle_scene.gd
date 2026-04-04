class_name DungeonBattleScene
extends Node2D

## 地下城戰鬥場景
## - 勝利：消耗卷、給予獎勵、更新最高關卡，返回地下城頁面
## - 失敗：不消耗卷，返回地下城頁面

const MAX_CATS_ON_FIELD: int = 5

const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0
const NAV_H := 110.0
const NAV_Y := SH - NAV_H

# ── 戰鬥節點 ─────────────────────────────────
var _player_team: Node2D
var _enemy_team: Node2D
var _battle_manager: BattleManager

# ── UI 節點 ───────────────────────────────────
var _ui_layer: CanvasLayer
var _timer_label: Label
var _speed_1x: Button
var _speed_2x: Button
var _speed_3x: Button
var _skip_btn: Button
var _level_label: Label
var _result_display: Label

# ── 地下城資料 ────────────────────────────────
var _dungeon_id: String = ""
var _dungeon_level: int = 1
var _dungeon_cfg: Dictionary = {}


func _ready() -> void:
	_dungeon_id = GameState.dungeon_battle_id
	_dungeon_level = GameState.dungeon_battle_level
	for cfg: Dictionary in GameState.dungeon_config.get("dungeons", []):
		if cfg.get("id", "") == _dungeon_id:
			_dungeon_cfg = cfg
			break
	_build_scene()
	_start_battle()


# ── 建立場景 ──────────────────────────────────

func _build_scene() -> void:
	_build_background()
	_build_battle_area()
	_build_ui()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.15, 1.0)   # 地下城偏暗紫色調
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
	_highlight_speed_btn(_speed_1x)

	# 計時器
	_timer_label = _make_label("60.0", Vector2(260.0, 20.0), Vector2(200.0, 50.0), 28)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_timer_label)

	# 跳過按鈕
	_skip_btn = _make_button("跳過", Vector2(SW - 100.0, 20.0), Vector2(80.0, 44.0))
	_ui_layer.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip_pressed)

	# 地下城關卡標籤
	var dungeon_name: String = _dungeon_cfg.get("name", "地下城")
	_level_label = _make_label(
		"%s  Lv.%d" % [dungeon_name, _dungeon_level],
		Vector2(0.0, BATTLE_Y + 10.0),
		Vector2(SW, 40.0),
		22
	)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_level_label)

	# 底部導覽背景
	var nav_bg := ColorRect.new()
	nav_bg.color = Color(0.1, 0.1, 0.12, 1.0)
	nav_bg.position = Vector2(0.0, NAV_Y)
	nav_bg.size = Vector2(SW, NAV_H)
	_ui_layer.add_child(nav_bg)

	# 撤退按鈕
	var retreat_btn := _make_button("撤退", Vector2(10.0, NAV_Y + 10.0), Vector2(SW - 20.0, NAV_H - 20.0))
	retreat_btn.pressed.connect(_on_retreat_pressed)
	_ui_layer.add_child(retreat_btn)

	# 勝利／敗北 顯示
	_result_display = Label.new()
	_result_display.size = Vector2(SW, 80.0)
	_result_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_display.add_theme_font_size_override("font_size", 64)
	_result_display.visible = false
	_ui_layer.add_child(_result_display)


# ── 工廠輔助 ─────────────────────────────────

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
	_battle_manager.set_speed(mult)
	_highlight_speed_btn(active_btn)


func _highlight_speed_btn(active: Button) -> void:
	for btn: Button in [_speed_1x, _speed_2x, _speed_3x]:
		btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
	active.modulate = Color(1.0, 1.0, 1.0, 1.0)


# ── 戰鬥初始化 ────────────────────────────────

func _start_battle() -> void:
	_result_display.visible = false

	for child in _player_team.get_children():
		child.queue_free()
	for child in _enemy_team.get_children():
		child.queue_free()

	# 建立玩家隊伍
	var player_cats: Array = []
	for i in range(GameState.player_team.size()):
		var cat_id: String = GameState.player_team[i]
		var path := "res://data/default/cats/" + cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			if data.active_skill_configs.size() > 0:
				data.active_skill_configs[0]["initial_delay"] = GameState.get_delay(i)
			var player_cat := GameState.get_player_cat(cat_id)
			data.apply_enhancement(player_cat)
			data.apply_rank_bonus(player_cat)
			player_cats.append(data)
		else:
			push_error("DungeonBattleScene: 無法載入玩家貓咪 " + cat_id)

	# 建立地下城敵人（依地下城設定計算數值）
	var enemy_cats: Array = []
	var mult: float = pow(_dungeon_cfg.get("difficulty_multiplier", 1.03), _dungeon_level - 1)
	var base_hp: float  = _dungeon_cfg.get("base_hp",  100.0)
	var base_atk: float = _dungeon_cfg.get("base_atk", 15.0)
	var base_def: float = _dungeon_cfg.get("base_def", 5.0)

	var data := CatData.from_json_file("res://data/default/cats/test_enemy.json")
	if data:
		data.max_hp   = roundi(base_hp  * mult)
		data.atk      = roundi(base_atk * mult)
		data.defense  = roundi(base_def * mult)
		enemy_cats.append(data)
	else:
		push_error("DungeonBattleScene: 無法載入 test_enemy")

	if player_cats.is_empty() or enemy_cats.is_empty():
		push_error("DungeonBattleScene: 貓咪資料不足")
		return

	var simulator := BattleSimulator.new()
	var events := simulator.simulate(player_cats, enemy_cats)
	_battle_manager.setup(events, player_cats, enemy_cats,
			_player_team, _enemy_team, _timer_label)


func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()


# ── 戰鬥結果 ──────────────────────────────────

func _on_battle_finished(result: String) -> void:
	if result == "WIN":
		_show_result_text("勝利", Color(0.3, 1.0, 0.4, 1.0), 310.0)
		await get_tree().create_timer(1.0).timeout
		_handle_win()
	else:
		_show_result_text("敗北", Color(1.0, 0.3, 0.3, 1.0), 310.0)
		await get_tree().create_timer(1.0).timeout
		# 失敗不消耗卷，直接返回
		get_tree().change_scene_to_file("res://scenes/DungeonScene.tscn")


func _handle_win() -> void:
	var daily_free: int  = int(GameState.dungeon_config.get("daily_free_tickets", 2))
	var event_bonus: int = int(GameState.dungeon_config.get("event_bonus_tickets", 0))
	GameState.dungeon_data.consume_ticket(_dungeon_id, daily_free + event_bonus)
	GameState.dungeon_data.update_max_level(_dungeon_id, _dungeon_level)
	var rewards: Dictionary = PlayerDungeonData.calculate_rewards(_dungeon_cfg, _dungeon_level)
	PlayerDungeonData.apply_rewards(GameState.player_data, rewards)
	GameState.save_all()
	_show_reward_popup(_dungeon_level, rewards)


func _show_reward_popup(level: int, rewards: Dictionary) -> void:
	var lines: Array = ["Lv.%d 通關獎勵：" % level]
	if rewards.get("cat_food", 0) > 0:
		lines.append("  普通乾糧 ×%d" % rewards["cat_food"])
	if rewards.get("special_cat_food", 0) > 0:
		lines.append("  特殊乾糧 ×%d" % rewards["special_cat_food"])
	if rewards.get("diamonds", 0) > 0:
		lines.append("  💎 鑽石 ×%d" % rewards["diamonds"])
	if rewards.get("trap_cages", 0) > 0:
		lines.append("  誘捕籠 ×%d" % rewards["trap_cages"])
	if rewards.get("whisker_shards", 0) > 0:
		lines.append("  鬍鬚碎片 ×%d" % rewards["whisker_shards"])

	var dialog := AcceptDialog.new()
	dialog.title = "挑戰成功！"
	dialog.dialog_text = "\n".join(lines)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		dialog.queue_free()
		get_tree().change_scene_to_file("res://scenes/DungeonScene.tscn")
	)


func _show_result_text(text: String, color: Color, y: float) -> void:
	_result_display.text = text
	_result_display.modulate = color
	_result_display.position = Vector2(0.0, y)
	_result_display.visible = true


func _on_retreat_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/DungeonScene.tscn")
