class_name BattleScene
extends Node2D

## 主戰鬥場景：建立 UI、載入貓咪資料、執行模擬與播放

# 測試用貓咪（未來改為從存檔讀取）
const PLAYER_CAT_IDS: Array = ["milk_cat"]
const ENEMY_CAT_IDS: Array = ["test_enemy"]

# 場景尺寸
const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0  # 戰鬥地面 y 位置

# 子節點
var _bg: ColorRect
var _ground: ColorRect
var _wall_l: ColorRect
var _wall_r: ColorRect
var _player_team: Node2D
var _enemy_team: Node2D
var _ui_layer: CanvasLayer
var _timer_label: Label
var _speed_1x: Button
var _speed_2x: Button
var _speed_3x: Button
var _skip_btn: Button
var _result_overlay: Control
var _result_label: Label
var _replay_btn: Button
var _continue_btn: Button
var _battle_manager: BattleManager

var _last_result: String = ""

func _ready() -> void:
	_build_scene()
	_start_battle()

# ── 建立場景節點 ──────────────────────────────

func _build_scene() -> void:
	_build_background()
	_build_battle_area()
	_build_ui()

func _build_background() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.133, 0.157, 0.192, 1.0)
	_bg.size = Vector2(SW, SH)
	add_child(_bg)

	_ground = ColorRect.new()
	_ground.color = Color(0.22, 0.24, 0.27, 1.0)
	_ground.position = Vector2(0.0, BATTLE_Y)
	_ground.size = Vector2(SW, SH - BATTLE_Y)
	add_child(_ground)

	_wall_l = ColorRect.new()
	_wall_l.color = Color(0.34, 0.24, 0.6, 1.0)
	_wall_l.position = Vector2(0.0, 200.0)
	_wall_l.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(_wall_l)

	_wall_r = ColorRect.new()
	_wall_r.color = Color(0.34, 0.24, 0.6, 1.0)
	_wall_r.position = Vector2(SW - 20.0, 200.0)
	_wall_r.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(_wall_r)

func _build_battle_area() -> void:
	_player_team = Node2D.new()
	_player_team.position = Vector2(0.0, BATTLE_Y)
	add_child(_player_team)

	_enemy_team = Node2D.new()
	_enemy_team.position = Vector2(0.0, BATTLE_Y)
	add_child(_enemy_team)

	# BattleManager
	_battle_manager = BattleManager.new()
	add_child(_battle_manager)
	_battle_manager.battle_finished.connect(_on_battle_finished)

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	# 計時器
	_timer_label = _make_label("60.0", Vector2(260.0, 20.0), Vector2(200.0, 50.0), 28)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_timer_label)

	# 速度按鈕
	var speed_x := 20.0
	var speed_y := 20.0
	_speed_1x = _make_button("1x", Vector2(speed_x, speed_y), Vector2(70.0, 44.0))
	_speed_2x = _make_button("2x", Vector2(speed_x + 75.0, speed_y), Vector2(70.0, 44.0))
	_speed_3x = _make_button("3x", Vector2(speed_x + 150.0, speed_y), Vector2(70.0, 44.0))
	_ui_layer.add_child(_speed_1x)
	_ui_layer.add_child(_speed_2x)
	_ui_layer.add_child(_speed_3x)
	_speed_1x.pressed.connect(func(): _set_speed(1.0, _speed_1x))
	_speed_2x.pressed.connect(func(): _set_speed(2.0, _speed_2x))
	_speed_3x.pressed.connect(func(): _set_speed(3.0, _speed_3x))
	_highlight_speed_btn(_speed_1x)

	# 跳過按鈕
	_skip_btn = _make_button("跳過", Vector2(SW - 100.0, 20.0), Vector2(80.0, 44.0))
	_ui_layer.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip_pressed)

	# 結果覆蓋層（初始隱藏）
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
	panel.position = Vector2(-200.0, -200.0)
	panel.size = Vector2(400.0, 400.0)
	_result_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	_result_label = Label.new()
	_result_label.text = "結果"
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(_result_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 20.0)
	vbox.add_child(spacer)

	_replay_btn = Button.new()
	_replay_btn.text = "重播"
	_replay_btn.custom_minimum_size = Vector2(200.0, 60.0)
	vbox.add_child(_replay_btn)
	_replay_btn.pressed.connect(_on_replay_pressed)

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
	for btn in [_speed_1x, _speed_2x, _speed_3x]:
		btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
	active.modulate = Color(1.0, 1.0, 1.0, 1.0)

# ── 戰鬥邏輯 ─────────────────────────────────

func _start_battle() -> void:
	# 清除舊的貓咪節點
	for child in _player_team.get_children():
		child.queue_free()
	for child in _enemy_team.get_children():
		child.queue_free()

	# 載入貓咪資料
	var player_cats: Array = []
	var enemy_cats: Array = []

	for cat_id: String in PLAYER_CAT_IDS:
		var path := "res://data/default/cats/" + cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			player_cats.append(data)
		else:
			push_error("BattleScene: 無法載入玩家貓咪 " + cat_id)

	for cat_id: String in ENEMY_CAT_IDS:
		var path := "res://data/default/cats/" + cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			enemy_cats.append(data)
		else:
			push_error("BattleScene: 無法載入敵方貓咪 " + cat_id)

	if player_cats.is_empty() or enemy_cats.is_empty():
		push_error("BattleScene: 貓咪資料不足，無法開始戰鬥")
		return

	# 預先模擬
	var simulator := BattleSimulator.new()
	var events := simulator.simulate(player_cats, enemy_cats)

	# 交給 BattleManager 播放
	_battle_manager.setup(events, player_cats, enemy_cats,
			_player_team, _enemy_team, _timer_label)

func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()

func _on_battle_finished(result: String) -> void:
	_last_result = result
	match result:
		"WIN":
			_result_label.text = "勝利！"
			_result_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
		"LOSE":
			_result_label.text = "失敗！"
			_result_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		"TIMEOUT":
			_result_label.text = "時間到！"
			_result_label.modulate = Color(1.0, 0.8, 0.2, 1.0)
	_result_overlay.visible = true

func _on_replay_pressed() -> void:
	_result_overlay.visible = false
	_start_battle()

func _on_continue_pressed() -> void:
	# 暫時：回到 StartScene
	get_tree().change_scene_to_file("res://scenes/StartScene.tscn")
