extends Control

## 地下城選擇頁面

const SW := 720.0
const SH := 1280.0

var _dungeon_panels: Dictionary = {}  # key: dungeon_id → Dictionary of UI nodes


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
	root_vbox.offset_left   = 20
	root_vbox.offset_top    = 40
	root_vbox.offset_right  = -20
	root_vbox.offset_bottom = -20
	layer.add_child(root_vbox)

	# 頂部列
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "地下城"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	root_vbox.add_child(HSeparator.new())

	if GameState.dungeon_config.is_empty():
		var err_lbl := Label.new()
		err_lbl.text = "無法載入地下城設定"
		root_vbox.add_child(err_lbl)
		return

	var dungeons: Array = GameState.dungeon_config.get("dungeons", [])
	for dungeon_cfg: Dictionary in dungeons:
		if not dungeon_cfg.get("enabled", false):
			continue
		var panel := _build_dungeon_panel(dungeon_cfg)
		root_vbox.add_child(panel)


func _build_dungeon_panel(cfg: Dictionary) -> PanelContainer:
	var dungeon_id: String = cfg.get("id", "")
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# 地下城名稱
	var name_lbl := Label.new()
	name_lbl.text = cfg.get("name", dungeon_id)
	name_lbl.add_theme_font_size_override("font_size", 26)
	vbox.add_child(name_lbl)

	# 最高關卡 & 卷數資訊
	var level_lbl := Label.new()
	level_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(level_lbl)

	var ticket_lbl := Label.new()
	ticket_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(ticket_lbl)

	# 廣告列（廣告次數 + 看廣告按鈕）
	var ad_row := HBoxContainer.new()
	ad_row.add_theme_constant_override("separation", 12)
	vbox.add_child(ad_row)

	var ad_lbl := Label.new()
	ad_lbl.add_theme_font_size_override("font_size", 20)
	ad_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad_row.add_child(ad_lbl)

	var ad_btn := Button.new()
	ad_btn.text = "看廣告"
	ad_btn.custom_minimum_size = Vector2(120.0, 44.0)
	ad_btn.add_theme_font_size_override("font_size", 20)
	ad_row.add_child(ad_btn)

	# 操作按鈕列
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var sweep_btn := Button.new()
	sweep_btn.text = "掃蕩"
	sweep_btn.custom_minimum_size = Vector2(0.0, 60.0)
	sweep_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sweep_btn.add_theme_font_size_override("font_size", 22)
	btn_row.add_child(sweep_btn)

	var challenge_btn := Button.new()
	challenge_btn.custom_minimum_size = Vector2(0.0, 60.0)
	challenge_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_btn.add_theme_font_size_override("font_size", 22)
	btn_row.add_child(challenge_btn)

	_dungeon_panels[dungeon_id] = {
		"cfg":          cfg,
		"level_lbl":    level_lbl,
		"ticket_lbl":   ticket_lbl,
		"ad_lbl":       ad_lbl,
		"ad_btn":       ad_btn,
		"sweep_btn":    sweep_btn,
		"challenge_btn": challenge_btn,
	}

	ad_btn.pressed.connect(func(): _on_ad_pressed(dungeon_id))
	sweep_btn.pressed.connect(func(): _on_sweep_pressed(dungeon_id))
	challenge_btn.pressed.connect(func(): _on_challenge_pressed(dungeon_id))

	_refresh_panel(dungeon_id)
	return panel


func _refresh_panel(dungeon_id: String) -> void:
	var entry: Dictionary = _dungeon_panels.get(dungeon_id, {})
	if entry.is_empty():
		return

	var daily_free: int  = int(GameState.dungeon_config.get("daily_free_tickets",  2))
	var ad_per_type: int = int(GameState.dungeon_config.get("ad_tickets_per_type", 2))
	var event_bonus: int = int(GameState.dungeon_config.get("event_bonus_tickets",  0))
	var effective_free: int = daily_free + event_bonus

	var d: Dictionary = GameState.dungeon_data.get_dungeon(dungeon_id, effective_free)
	var max_level: int  = d.get("max_level", 0)
	var tickets: int    = d.get("tickets",   effective_free)
	var ad_rem: int     = GameState.dungeon_data.get_ad_views_remaining(dungeon_id, ad_per_type)

	# 最高關卡
	var level_lbl: Label = entry["level_lbl"]
	level_lbl.text = "最高關卡：%s" % ("Lv.%d" % max_level if max_level > 0 else "尚未挑戰")

	# 卷數
	var ticket_lbl: Label = entry["ticket_lbl"]
	ticket_lbl.text = "%s 卷：%d 張" % [_get_dungeon_name(dungeon_id), tickets]

	# 廣告次數
	var ad_lbl: Label = entry["ad_lbl"]
	ad_lbl.text = "尚可看廣告獲取：%d 次" % ad_rem

	var ad_btn: Button = entry["ad_btn"]
	ad_btn.disabled = (ad_rem <= 0)
	ad_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if ad_rem > 0 else Color(0.5, 0.5, 0.5, 1.0)

	# 掃蕩（須已通關 & 有卷）
	var sweep_btn: Button = entry["sweep_btn"]
	var can_sweep := (max_level > 0 and tickets > 0)
	sweep_btn.text = "掃蕩 Lv.%d" % max_level if max_level > 0 else "掃蕩"
	sweep_btn.disabled = not can_sweep
	sweep_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_sweep else Color(0.5, 0.5, 0.5, 1.0)

	# 挑戰（有卷即可）
	var challenge_btn: Button = entry["challenge_btn"]
	var next_level := max_level + 1
	challenge_btn.text = "挑戰 Lv.%d" % next_level
	challenge_btn.disabled = (tickets <= 0)
	challenge_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if tickets > 0 else Color(0.5, 0.5, 0.5, 1.0)


# ── 操作處理 ───────────────────────────────────

func _on_ad_pressed(dungeon_id: String) -> void:
	var ad_per_type: int = int(GameState.dungeon_config.get("ad_tickets_per_type", 2))
	var daily_free: int  = int(GameState.dungeon_config.get("daily_free_tickets",  2))
	var event_bonus: int = int(GameState.dungeon_config.get("event_bonus_tickets",  0))

	var dialog := ConfirmationDialog.new()
	dialog.title = "看廣告獲得卷"
	dialog.dialog_text = "可以透過看廣告獲得地下城卷"
	dialog.ok_button_text = "確認"
	dialog.cancel_button_text = "取消"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		# 廣告功能待實作，確認後直接給卷（模擬看完廣告）
		GameState.dungeon_data.grant_ad_ticket(dungeon_id, ad_per_type, daily_free + event_bonus)
		GameState.save_all()
		_refresh_panel(dungeon_id)
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())


func _on_sweep_pressed(dungeon_id: String) -> void:
	var daily_free: int  = int(GameState.dungeon_config.get("daily_free_tickets",  2))
	var event_bonus: int = int(GameState.dungeon_config.get("event_bonus_tickets",  0))
	var effective_free := daily_free + event_bonus

	var d: Dictionary = GameState.dungeon_data.get_dungeon(dungeon_id, effective_free)
	var max_level: int = d.get("max_level", 0)

	if not GameState.dungeon_data.consume_ticket(dungeon_id, effective_free):
		return

	var cfg := _get_dungeon_cfg(dungeon_id)
	var rewards: Dictionary = PlayerDungeonData.calculate_rewards(cfg, max_level)
	PlayerDungeonData.apply_rewards(GameState.player_data, rewards)
	GameState.save_all()
	_refresh_panel(dungeon_id)
	_show_reward_popup("掃蕩完成！", max_level, rewards)


func _on_challenge_pressed(dungeon_id: String) -> void:
	var daily_free: int  = int(GameState.dungeon_config.get("daily_free_tickets",  2))
	var event_bonus: int = int(GameState.dungeon_config.get("event_bonus_tickets",  0))
	var d: Dictionary = GameState.dungeon_data.get_dungeon(dungeon_id, daily_free + event_bonus)
	var next_level: int = d.get("max_level", 0) + 1

	GameState.dungeon_battle_id    = dungeon_id
	GameState.dungeon_battle_level = next_level
	# 使用地下城專屬陣容，未設定則 fallback 到 boss_team
	var dungeon_team: Array = GameState.player_data.dungeon_team
	if dungeon_team.is_empty():
		dungeon_team = GameState.player_data.boss_team
	if not dungeon_team.is_empty():
		GameState.player_team = dungeon_team.duplicate()
	get_tree().change_scene_to_file("res://scenes/DungeonBattleScene.tscn")


# ── 獎勵計算 ───────────────────────────────────

func _get_dungeon_cfg(dungeon_id: String) -> Dictionary:
	for cfg: Dictionary in GameState.dungeon_config.get("dungeons", []):
		if cfg.get("id", "") == dungeon_id:
			return cfg
	return {}


func _get_dungeon_name(dungeon_id: String) -> String:
	return _get_dungeon_cfg(dungeon_id).get("name", dungeon_id)


func _show_reward_popup(header: String, level: int, rewards: Dictionary) -> void:
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
	dialog.title = header
	dialog.dialog_text = "\n".join(lines)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ActivityScene.tscn")
