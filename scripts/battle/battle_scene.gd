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
var _result_overlay: Control
var _result_label: Label
var _retry_btn: Button
var _continue_btn: Button

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
	var nav_items: Array = [["配置", _on_nav_config], ["強化", _on_nav_stub],
							["商店", _on_nav_stub], ["競技場", _on_nav_stub]]
	var btn_w := SW / nav_items.size()
	for i in range(nav_items.size()):
		var nav_btn := _make_button(nav_items[i][0],
				Vector2(i * btn_w + 10.0, NAV_Y + 10.0),
				Vector2(btn_w - 20.0, NAV_H - 20.0))
		nav_btn.pressed.connect(nav_items[i][1])
		_ui_layer.add_child(nav_btn)

	# 結果覆蓋層
	_result_overlay = Control.new()
	_result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.visible = false
	_ui_layer.add_child(_result_overlay)

	var overlay_bg := ColorRect.new()
	overlay_bg.color = Color(0.0, 0.0, 0.0, 0.7)
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.add_child(overlay_bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-200.0, -220.0)
	panel.size = Vector2(400.0, 440.0)
	_result_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_result_label)

	var level_result_lbl := Label.new()
	level_result_lbl.name = "LevelResultLabel"
	level_result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_result_lbl.add_theme_font_size_override("font_size", 22)
	level_result_lbl.modulate = Color(0.8, 0.8, 0.8, 1.0)
	vbox.add_child(level_result_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 20.0)
	vbox.add_child(spacer)

	_retry_btn = Button.new()
	_retry_btn.text = "重試"
	_retry_btn.custom_minimum_size = Vector2(200.0, 60.0)
	vbox.add_child(_retry_btn)
	_retry_btn.pressed.connect(_on_retry_pressed)

	_continue_btn = Button.new()
	_continue_btn.text = "繼續"
	_continue_btn.custom_minimum_size = Vector2(200.0, 60.0)
	vbox.add_child(_continue_btn)
	_continue_btn.pressed.connect(_on_continue_pressed)

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
	_boss_btn.visible = GameState.boss_available and GameState.current_stage != 0

# ── 戰鬥邏輯 ─────────────────────────────────

func _start_battle() -> void:
	_result_overlay.visible = false
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
			player_cats.append(data)
		else:
			push_error("BattleScene: 無法載入玩家貓咪 " + cat_id)

	for cat_id: String in GameState.get_enemy_ids():
		var path := "res://data/default/cats/" + cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
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
	var is_boss := GameState.current_stage == 0

	if result == "WIN":
		# 勝利：直接推進，不顯示 overlay
		GameState.advance_after_win()
		_start_battle()
		return

	# 失敗或時間到：顯示 overlay
	var level_result_lbl := _result_overlay.find_child("LevelResultLabel") as Label
	if level_result_lbl:
		level_result_lbl.text = GameState.get_level_display()

	_result_label.text = "失敗！" if result == "LOSE" else "時間到！"
	_result_label.modulate = Color(1.0, 0.3, 0.3, 1.0) if result == "LOSE" else Color(1.0, 0.8, 0.2, 1.0)

	if is_boss:
		# Boss 失敗：退回 stage 3，按確認後顯示 Boss 按鈕
		_retry_btn.visible = false
		_continue_btn.visible = true
		_continue_btn.text = "確認"
	else:
		_retry_btn.visible = true
		_continue_btn.visible = false

	_result_overlay.visible = true

func _on_retry_pressed() -> void:
	_start_battle()

func _on_continue_pressed() -> void:
	# 只會在 Boss 失敗時觸發
	GameState.on_boss_fail()
	_start_battle()

func _on_challenge_boss_pressed() -> void:
	GameState.challenge_boss()
	_start_battle()

# ── 導覽 ─────────────────────────────────────

func _on_nav_config() -> void:
	get_tree().change_scene_to_file("res://scenes/ConfigScene.tscn")

func _on_nav_stub() -> void:
	pass  # 未來實作
