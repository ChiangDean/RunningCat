class_name BattleScene
extends Node2D

## 主遊戲畫面：戰鬥 + 底部導覽列

const MAX_CATS_ON_FIELD: int = 5

const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0
const NAV_H := 110.0       # 底部導覽高度
const NAV_Y := SH - NAV_H  # 導覽列起始 Y

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
var _boss_btn: Button
var _result_display: Label  # 勝利／敗北 短暫顯示用

var _last_result: String = ""

func _ready() -> void:
	_build_scene()
	_start_battle()

# ── 建立場景 ──────────────────────────────────

func _build_scene() -> void:
	_build_background()
	_build_battle_area()
	_build_ui()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var ground := ColorRect.new()
	ground.color = Color(0.22, 0.24, 0.27, 1.0)
	ground.position = Vector2(0.0, BATTLE_Y)
	ground.size = Vector2(SW, NAV_Y - BATTLE_Y)
	add_child(ground)

	var wall_l := ColorRect.new()
	wall_l.color = Color(0.34, 0.24, 0.6, 1.0)
	wall_l.position = Vector2(0.0, 200.0)
	wall_l.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(wall_l)

	var wall_r := ColorRect.new()
	wall_r.color = Color(0.34, 0.24, 0.6, 1.0)
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

	# 關卡標籤（戰鬥區下方）
	_level_label = _make_label("", Vector2(0.0, BATTLE_Y + 10.0), Vector2(SW, 40.0), 22)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_level_label)

	# 挑戰Boss 按鈕
	_boss_btn = _make_button("⚔ 挑戰 Boss", Vector2(SW / 2.0 - 150.0, BATTLE_Y + 60.0), Vector2(300.0, 64.0))
	_boss_btn.visible = false
	_ui_layer.add_child(_boss_btn)
	_boss_btn.pressed.connect(_on_challenge_boss_pressed)

	# 底部導覽列背景
	var nav_bg := ColorRect.new()
	nav_bg.color = Color(0.1, 0.1, 0.12, 1.0)
	nav_bg.position = Vector2(0.0, NAV_Y)
	nav_bg.size = Vector2(SW, NAV_H)
	_ui_layer.add_child(nav_bg)

	# 導覽按鈕
	var nav_items: Array = [["配置", _on_nav_config], ["強化", _on_nav_enhance],
							["商店", _on_nav_shop], ["競技場", _on_nav_stub]]
	var btn_w := SW / nav_items.size()
	for i in range(nav_items.size()):
		var nav_btn := _make_button(nav_items[i][0],
				Vector2(i * btn_w + 10.0, NAV_Y + 10.0),
				Vector2(btn_w - 20.0, NAV_H - 20.0))
		nav_btn.pressed.connect(nav_items[i][1])
		_ui_layer.add_child(nav_btn)

	# 勝利／敗北 短暫顯示文字（無按鈕，自動推進）
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

func _refresh_ui() -> void:
	_level_label.text = GameState.get_level_display()
	_boss_btn.visible = GameState.boss_available and not GameState.is_current_boss()

# ── 戰鬥邏輯 ─────────────────────────────────

func _start_battle() -> void:
	_result_display.visible = false
	_refresh_ui()

	for child in _player_team.get_children():
		child.queue_free()
	for child in _enemy_team.get_children():
		child.queue_free()

	var player_cats: Array = []
	var enemy_cats: Array = []

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
			push_error("BattleScene: 無法載入玩家貓咪 " + cat_id)

	var diff_mult: float = GameState.get_difficulty_multiplier()
	for cat_id: String in GameState.get_enemy_ids():
		var path := "res://data/default/cats/" + cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			# 依關卡難度倍率縮放敵方數值（speed 不縮放，保持操作手感一致）
			data.max_hp = roundi(data.max_hp * diff_mult)
			data.atk = roundi(data.atk * diff_mult)
			data.defense = roundi(data.defense * diff_mult)
			data.weight = roundi(data.weight * diff_mult)
			enemy_cats.append(data)
		else:
			push_error("BattleScene: 無法載入敵方貓咪 " + cat_id)

	if player_cats.is_empty() or enemy_cats.is_empty():
		push_error("BattleScene: 貓咪資料不足，無法開始戰鬥")
		return

	var simulator := BattleSimulator.new()
	var events := simulator.simulate(player_cats, enemy_cats)
	_battle_manager.setup(events, player_cats, enemy_cats,
			_player_team, _enemy_team, _timer_label)

func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()

func _on_battle_finished(result: String) -> void:
	_last_result = result
	var is_boss := GameState.is_current_boss()

	if result == "WIN":
		# 勝利：中間上方顯示，推進後重啟
		_show_result_text("勝利", Color(0.3, 1.0, 0.4, 1.0), 310.0)
		GameState.advance_after_win()
		await get_tree().create_timer(1.0).timeout
		_start_battle()
	else:
		# 失敗：頂部顯示，處理狀態後重啟
		_show_result_text("敗北", Color(1.0, 0.3, 0.3, 1.0), 310.0)
		if is_boss:
			GameState.on_boss_fail()
		await get_tree().create_timer(1.0).timeout
		_start_battle()

func _show_result_text(text: String, color: Color, y: float) -> void:
	_result_display.text = text
	_result_display.modulate = color
	_result_display.position = Vector2(0.0, y)
	_result_display.visible = true

func _on_challenge_boss_pressed() -> void:
	GameState.challenge_boss()
	_start_battle()

# ── 導覽 ─────────────────────────────────────

func _on_nav_config() -> void:
	get_tree().change_scene_to_file("res://scenes/ConfigScene.tscn")

func _on_nav_enhance() -> void:
	get_tree().change_scene_to_file("res://scenes/EnhanceScene.tscn")

func _on_nav_shop() -> void:
	get_tree().change_scene_to_file("res://scenes/ShopScene.tscn")

func _on_nav_stub() -> void:
	pass  # 未來實作
