class_name BattleScene
extends Node2D

## 主遊戲畫面：戰鬥 + 底部導覽列

const BATTLE_BG_TEXTURE := preload("res://assets/sprites/ui/battle_background_homey_v1.png")

const MAX_CATS_ON_FIELD: int = 5
const CHAT_SCENE := preload("res://scenes/chat/ChatScene.tscn")

const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0
const NAV_H := 110.0
const NAV_Y := SH - NAV_H

# 技能列高度（BATTLE_Y 正下方）
const SKILL_BAR_Y := BATTLE_Y + 10.0
const SKILL_BAR_H := 100.0
const SKILL_SLOT_W := 100.0
const SKILL_SLOT_H := 90.0

# 關卡 / Boss 按鈕放在勝敗文字同高
const STAGE_BTN_Y := 310.0

# ── 戰鬥節點 ─────────────────────────────────
var _player_team: Node2D
var _enemy_team: Node2D
var _battle_manager: BattleManager

# ── UI 節點 ───────────────────────────────────
var _ui_layer: Control
var _timer_label: Label
var _speed_1x: Button
var _speed_2x: Button
var _speed_3x: Button
var _skip_btn: Button
var _level_label: Label
var _boss_btn: Button
var _result_display: Label
var _skill_bar: Control      # 技能列容器
var _sandbox_btn: Button     # ???????
var _mail_btn: Button
var _mail_badge: Label

var _chat_btn: Button
var _chat_badge: Label
var _last_result: String = ""


func _ready() -> void:
	_build_scene()
	_start_battle()
	# 每秒更新貓砂盆按鈕顯示
	var sandbox_timer := Timer.new()
	sandbox_timer.wait_time = 1.0
	sandbox_timer.autostart = true
	sandbox_timer.timeout.connect(_refresh_sandbox_btn)
	add_child(sandbox_timer)


# ── 建立場景 ──────────────────────────────────

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
	bg_tint.color = Color(0.08, 0.06, 0.10, 0.24)
	bg_tint.size = Vector2(SW, SH)
	add_child(bg_tint)

	var ground := ColorRect.new()
	ground.color = Color(0.16, 0.13, 0.12, 0.48)
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
	_ui_layer = Control.new()
	_ui_layer.name = "BattleUiLayer"
	_ui_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
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

	# 跳過按鈕
	_skip_btn = _make_button("跳過", Vector2(SW - 100.0, 20.0), Vector2(80.0, 44.0))
	_ui_layer.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip_pressed)
	_skip_btn.visible = GameState.can_skip_battle()
	_chat_btn = _make_button("Chat", Vector2(SW - 300.0, 20.0), Vector2(90.0, 44.0))
	_chat_btn.pressed.connect(_open_chat)
	_ui_layer.add_child(_chat_btn)
	_chat_badge = _make_label("", Vector2(SW - 222.0, 18.0), Vector2(22.0, 20.0), 12)
	_chat_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_chat_badge)
	GameState.chat_unread_changed.connect(func(_channel_key: String, _count: int) -> void:
		_refresh_chat_badge()
	)
	_refresh_chat_badge()

	_mail_btn = _make_button("郵件", Vector2(SW - 200.0, 20.0), Vector2(88.0, 44.0))
	_ui_layer.add_child(_mail_btn)
	_mail_btn.pressed.connect(_on_nav_mail)

	_mail_badge = Label.new()
	_mail_badge.position = Vector2(SW - 128.0, 12.0)
	_mail_badge.size = Vector2(28.0, 28.0)
	_mail_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mail_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mail_badge.add_theme_font_size_override("font_size", 14)
	_mail_badge.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_ui_layer.add_child(_mail_badge)

	# 關卡標籤（與勝敗文字同高）
	_level_label = _make_label("", Vector2(0.0, STAGE_BTN_Y - 40.0), Vector2(SW, 36.0), 20)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_level_label)

	# 挑戰Boss 按鈕（與勝敗文字同高）
	_boss_btn = _make_button("⚔ 挑戰 Boss",
			Vector2(SW / 2.0 - 150.0, STAGE_BTN_Y + 10.0), Vector2(300.0, 56.0))
	_boss_btn.visible = false
	_ui_layer.add_child(_boss_btn)
	_boss_btn.pressed.connect(_on_challenge_boss_pressed)

	# 技能列
	_skill_bar = _build_skill_bar()
	_ui_layer.add_child(_skill_bar)

	# 底部導覽列背景
	var nav_bg := ColorRect.new()
	nav_bg.color = Color(0.1, 0.1, 0.12, 1.0)
	nav_bg.position = Vector2(0.0, NAV_Y)
	nav_bg.size = Vector2(SW, NAV_H)
	_ui_layer.add_child(nav_bg)

	# 導覽按鈕
	var nav_items: Array = [["鏟屎官", _on_nav_scooper], ["配置", _on_nav_config],
							["強化", _on_nav_enhance], ["活動", _on_nav_activity],
							["商店", _on_nav_shop]]
	var btn_w := SW / nav_items.size()
	for i in range(nav_items.size()):
		var nav_btn := _make_button(nav_items[i][0],
				Vector2(i * btn_w + 10.0, NAV_Y + 10.0),
				Vector2(btn_w - 20.0, NAV_H - 20.0))
		nav_btn.pressed.connect(nav_items[i][1])
		_ui_layer.add_child(nav_btn)

	# 檢查貓砂盆按鈕（頂部置中，計時器下方）
	_sandbox_btn = _make_button("🪣 清理貓砂盆",
			Vector2(SW / 2.0 - 90.0, 72.0), Vector2(180.0, 38.0))
	_sandbox_btn.pressed.connect(_show_sandbox_dialog)
	_ui_layer.add_child(_sandbox_btn)

	# 勝利／敗北 短暫顯示文字
	_result_display = Label.new()
	_result_display.size = Vector2(SW, 80.0)
	_result_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_display.add_theme_font_size_override("font_size", 64)
	_result_display.visible = false
	_ui_layer.add_child(_result_display)


## 建立技能列容器（5 個槽，置中）
func _build_skill_bar() -> Control:
	var bar := Control.new()
	bar.name = "SkillBar"
	var total_w := SKILL_SLOT_W * MAX_CATS_ON_FIELD + 8.0 * (MAX_CATS_ON_FIELD - 1)
	var bar_x := (SW - total_w) / 2.0
	bar.position = Vector2(bar_x, SKILL_BAR_Y)
	bar.size = Vector2(total_w, SKILL_BAR_H)

	for i in range(MAX_CATS_ON_FIELD):
		var slot := _make_skill_slot(i)
		slot.position = Vector2(i * (SKILL_SLOT_W + 8.0), 0.0)
		bar.add_child(slot)

	return bar


func _make_skill_slot(idx: int) -> Control:
	var slot := Control.new()
	slot.name = "Slot%d" % idx
	slot.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	slot.custom_minimum_size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)

	# 背景
	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	bg.color = Color(0.15, 0.15, 0.18, 1.0)
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

	# 技能名稱（預留，啟動時填入）
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.size = Vector2(SKILL_SLOT_W, 22.0)
	name_lbl.position = Vector2(0.0, SKILL_SLOT_H - 24.0)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_contents = true
	slot.add_child(name_lbl)

	# 冷卻遮罩（從上往下覆蓋，按比例縮短）
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H - 24.0)
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.visible = false
	slot.add_child(overlay)

	# 冷卻數字
	var cd_lbl := Label.new()
	cd_lbl.name = "CdLabel"
	cd_lbl.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H - 24.0)
	cd_lbl.add_theme_font_size_override("font_size", 22)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_lbl.visible = false
	slot.add_child(cd_lbl)

	# Buff 持續外框（黃色邊框）
	var buff_frame := ColorRect.new()
	buff_frame.name = "BuffFrame"
	buff_frame.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	buff_frame.color = Color(1.0, 0.85, 0.0, 0.0)   # 透明填充
	buff_frame.visible = false
	slot.add_child(buff_frame)

	# 黃色邊框（4 條 ColorRect 組成）
	var border_color := Color(1.0, 0.85, 0.0, 1.0)
	var border_thick := 3.0
	for side in [
		[Vector2(0, 0), Vector2(SKILL_SLOT_W, border_thick)],
		[Vector2(0, SKILL_SLOT_H - border_thick), Vector2(SKILL_SLOT_W, border_thick)],
		[Vector2(0, 0), Vector2(border_thick, SKILL_SLOT_H)],
		[Vector2(SKILL_SLOT_W - border_thick, 0), Vector2(border_thick, SKILL_SLOT_H)],
	]:
		var border := ColorRect.new()
		border.position = side[0]
		border.size = side[1]
		border.color = border_color
		buff_frame.add_child(border)

	return slot


## 戰鬥開始後依玩家隊伍更新技能槽名稱
func _refresh_skill_bar_names(player_cats: Array) -> void:
	if _skill_bar == null:
		return
	for i in range(player_cats.size()):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node == null:
			continue
		var name_lbl: Label = slot_node.get_node_or_null("NameLabel")
		if name_lbl == null:
			continue
		var cat: CatData = player_cats[i]
		if cat.active_skills_data.size() > 0:
			name_lbl.text = cat.active_skills_data[0].get("display_name", "")
		else:
			name_lbl.text = ""

	# 空槽隱藏
	for i in range(player_cats.size(), MAX_CATS_ON_FIELD):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node:
			slot_node.visible = false


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


func _refresh_ui() -> void:
	_level_label.text = GameState.get_level_display()
	_boss_btn.visible = GameState.boss_available and not GameState.is_current_boss()
	_refresh_sandbox_btn()
	_refresh_mail_badge()


func _refresh_sandbox_btn() -> void:
	var elapsed := GameState.get_idle_elapsed_seconds()
	var claimable_minutes := elapsed / 60
	if claimable_minutes < 1:
		_sandbox_btn.disabled = true
		_sandbox_btn.text = "🪣 乾淨貓砂盆"
	else:
		_sandbox_btn.disabled = false
		var h := elapsed / 3600
		var m := (elapsed % 3600) / 60
		var s := elapsed % 60
		_sandbox_btn.text = "🪣 清理貓砂盆 %02d:%02d:%02d" % [h, m, s]


func _refresh_mail_badge() -> void:
	if _mail_badge == null:
		return
	if not GameState.has_mail_red_dot():
		_mail_badge.visible = false
		return
	_mail_badge.visible = true
	_mail_badge.text = GameState.get_mail_badge_text()
	_mail_badge.modulate = Color(1.0, 0.28, 0.28, 1.0)


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
		var player_cat_id: int = GameState.player_team[i]
		var cat_id: String = GameState.get_cat_file_id(player_cat_id)
		if cat_id.is_empty():
			push_error("BattleScene: 無法解析 playerCatId %d 的本地貓咪檔名" % player_cat_id)
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
			# 重新載入技能（強化後 rank 已設定，需更新 initial_delay）
			data._load_skill_data()
			if data.active_skills_data.size() > 0:
				data.active_skills_data[0]["initial_delay"] = GameState.get_delay(i)
			player_cats.append(data)
		else:
			push_error("BattleScene: 無法載入玩家貓咪 " + cat_id)

	var diff_mult: float = GameState.get_difficulty_multiplier()
	for cat_id: String in GameState.get_enemy_ids():
		var path := cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			data.max_hp  = roundi(data.max_hp  * diff_mult)
			data.atk     = roundi(data.atk     * diff_mult)
			data.defense = roundi(data.defense * diff_mult)
			data.weight  = roundi(data.weight  * diff_mult)
			enemy_cats.append(data)
		else:
			push_error("BattleScene: 無法載入敵方貓咪 " + cat_id)

	if player_cats.is_empty() or enemy_cats.is_empty():
		push_error("BattleScene: 貓咪資料不足，無法開始戰鬥")
		return

	_refresh_skill_bar_names(player_cats)

	var simulator := BattleSimulator.new()
	var events := simulator.simulate(player_cats, enemy_cats)
	_battle_manager.setup(events, player_cats, enemy_cats,
			_player_team, _enemy_team, _timer_label, _skill_bar)


func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()


func _on_battle_finished(result: String) -> void:
	_last_result = result
	var is_boss := GameState.is_current_boss()

	if result == "WIN":
		_show_result_text("勝利", Color(0.3, 1.0, 0.4, 1.0), 310.0)
		GameState.advance_after_win()
		await get_tree().create_timer(1.0).timeout
		_start_battle()
	else:
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

## 將鏟屎官戰鬥加成套用至 CatData（裝備 + 回憶 + 寶藏）
func _apply_equipment_bonuses(data: CatData) -> void:
	GameState.apply_player_combat_bonuses(data)


func _on_nav_scooper() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ScooperScene.tscn")


## 顯示貓砂盆互動視窗：掛機獎勵領取（完整分鐘）+ 屎堆鏟除
func _show_sandbox_dialog() -> void:
	var elapsed_seconds := GameState.get_idle_elapsed_seconds()
	var complete_minutes := elapsed_seconds / 60
	var has_rewards := complete_minutes >= 1
	var rewards := GameState.get_pending_idle_rewards() if has_rewards else {}

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(400.0, 0.0)

	# ── 掛機獎勵區 ────────────────────────────────────────
	var rewards_section := VBoxContainer.new()
	rewards_section.add_theme_constant_override("separation", 6)
	rewards_section.visible = has_rewards

	if has_rewards:
		var h := complete_minutes / 60
		var m := complete_minutes % 60
		var time_lbl := Label.new()
		time_lbl.text = "累積時間：%d 小時 %d 分鐘" % [h, m]
		time_lbl.add_theme_font_size_override("font_size", 18)
		time_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rewards_section.add_child(time_lbl)

		for entry: Array in [
			["💰 金幣",   "gold"],
			["💩 屎堆",   "poop"],
			["🍖 貓糧",   "cat_food"],
			["💎 鑽石",   "diamonds"],
			["🐱 鬍鬚",   "whiskers"],
		]:
			var val: int = rewards.get(entry[1], 0)
			if val > 0:
				var lbl := Label.new()
				lbl.text = "  %s  +%d" % [entry[0], val]
				lbl.add_theme_font_size_override("font_size", 18)
				rewards_section.add_child(lbl)

	vbox.add_child(rewards_section)

	# ── 鏟屎互動區 ────────────────────────────────────────
	var scoop_section := VBoxContainer.new()
	scoop_section.add_theme_constant_override("separation", 8)
	scoop_section.visible = not has_rewards and GameState.player_data.poop_count > 0

	var poop_count_lbl := Label.new()
	poop_count_lbl.text = "待鏟屎堆：%d 個" % GameState.player_data.poop_count
	poop_count_lbl.add_theme_font_size_override("font_size", 20)
	scoop_section.add_child(poop_count_lbl)

	var result_lbl := Label.new()
	result_lbl.text = ""
	result_lbl.add_theme_font_size_override("font_size", 18)
	result_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.7, 1.0))
	scoop_section.add_child(result_lbl)

	var scoop_btn := Button.new()
	scoop_btn.text = "🪣 鏟屎！"
	scoop_btn.custom_minimum_size = Vector2(160.0, 52.0)
	scoop_btn.disabled = GameState.player_data.poop_count <= 0
	scoop_btn.pressed.connect(func() -> void:
		var r := GameState.scoop_poop()
		var remaining := GameState.player_data.poop_count
		poop_count_lbl.text = "💩 待鏟屎堆：%d 個" % remaining
		var parts := []
		if r.get("exp", 0) > 0:
			parts.append("EXP +%d" % r["exp"])
		if r.get("memory_shards", 0) > 0:
			parts.append("回憶碎片 +%d" % r["memory_shards"])
		if r.get("whiskers", 0) > 0:
			parts.append("鬍鬚 +%d" % r["whiskers"])
		result_lbl.text = "（空手而歸）" if parts.is_empty() else "獲得：" + "、".join(parts)
		scoop_btn.disabled = remaining <= 0
		_refresh_sandbox_btn()
	)
	scoop_section.add_child(scoop_btn)
	vbox.add_child(scoop_section)

	# ── 領取按鈕 ───────────────────────────────────────────
	var close_ref := [Callable()]

	if has_rewards:
		var claim_btn := Button.new()
		claim_btn.text = "領取獎勵"
		claim_btn.custom_minimum_size = Vector2(200.0, 52.0)
		claim_btn.pressed.connect(func() -> void:
			var claimed := rewards.duplicate()
			GameState.claim_idle_rewards()
			close_ref[0].call()
			_refresh_sandbox_btn()
			var lines := []
			for entry: Array in [
				["💰 金幣",   "gold"],
				["💩 屎堆",   "poop"],
				["🍖 貓糧",   "cat_food"],
				["💎 鑽石",   "diamonds"],
				["🐱 鬍鬚",   "whiskers"],
			]:
				var val: int = claimed.get(entry[1], 0)
				if val > 0:
					lines.append("  %s  +%d" % [entry[0], val])
			DialogManager.show_info("領取成功！", "\n".join(lines))
		)
		vbox.add_child(claim_btn)

	close_ref[0] = DialogManager.show_info_node("清理貓砂盆", vbox)


func _on_nav_config() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ConfigScene.tscn")


func _on_nav_enhance() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/EnhanceScene.tscn")


func _on_nav_activity() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ActivityScene.tscn")


func _on_nav_shop() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ShopScene.tscn")


func _on_nav_mail() -> void:
	var mail_view: Control = load("res://scenes/MailScene.tscn").instantiate()
	if mail_view.has_method("set_close_action"):
		var close_dialog := [Callable()]
		mail_view.set_close_action(func() -> void:
			if close_dialog[0].is_valid():
				close_dialog[0].call()
		)
		close_dialog[0] = DialogManager.show_info_node("郵件", mail_view, Callable(), "large")
	else:
		DialogManager.show_info_node("郵件", mail_view, Callable(), "large")

func _open_chat() -> void:
	var chat_view: Control = CHAT_SCENE.instantiate()
	DialogManager.show_info_node("Chat", chat_view, Callable(), "large")


func _refresh_chat_badge() -> void:
	if _chat_badge == null:
		return
	var unread := GameState.get_chat_total_unread()
	_chat_badge.visible = unread > 0
	_chat_badge.text = str(mini(unread, 99))
