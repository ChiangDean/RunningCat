extends Control

## 競技場主頁

const SW := 720.0
const SH := 1280.0

var _opponents: Array = []           # 當前顯示的3個對手
var _shown_ids: Array = []           # 本次刷新輪次已出現過的 player_id
var _reroll_cooldown: float = 0.0    # 重骰冷卻計時（秒）
const REROLL_COOLDOWN: float = 5.0

# UI 節點引用
var _rank_label: Label
var _score_label: Label
var _ticket_label: Label
var _reroll_btn: Button
var _opponent_container: VBoxContainer


func _ready() -> void:
	_build_ui()
	_refresh_opponents(false)


func _process(delta: float) -> void:
	if _reroll_cooldown > 0.0:
		_reroll_cooldown -= delta
		if _reroll_cooldown <= 0.0:
			_reroll_cooldown = 0.0
			_reroll_btn.disabled = false
			_reroll_btn.text = "重骰對手"
		else:
			_reroll_btn.text = "重骰 (%d)" % ceili(_reroll_cooldown)


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

	# ── 頂部列 ──
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "競技場"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	root_vbox.add_child(HSeparator.new())

	# ── 玩家狀態列 ──
	var status_panel := PanelContainer.new()
	status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(status_panel)

	var status_vbox := VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 6)
	status_panel.add_child(status_vbox)

	var name_lbl := Label.new()
	name_lbl.text = GameState.arena_data.player_name
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(name_lbl)

	_rank_label = Label.new()
	_rank_label.add_theme_font_size_override("font_size", 28)
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(_rank_label)

	_score_label = Label.new()
	_score_label.add_theme_font_size_override("font_size", 20)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(_score_label)

	_ticket_label = Label.new()
	_ticket_label.add_theme_font_size_override("font_size", 20)
	_ticket_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(_ticket_label)

	# ── 攻防陣容顯示列 ──
	var team_panel := PanelContainer.new()
	team_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(team_panel)

	var team_hbox := HBoxContainer.new()
	team_hbox.add_theme_constant_override("separation", 8)
	team_panel.add_child(team_hbox)

	var team_vbox := VBoxContainer.new()
	team_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_vbox.add_theme_constant_override("separation", 4)
	team_hbox.add_child(team_vbox)

	var attack_team := GameState.player_data.arena_attack_team
	if attack_team.is_empty():
		attack_team = GameState.player_data.boss_team

	var atk_lbl := Label.new()
	atk_lbl.text = "攻擊：" + (_cat_ids_to_names(attack_team) if not attack_team.is_empty() else "（未設定，使用BOSS陣容）")
	atk_lbl.add_theme_font_size_override("font_size", 17)
	atk_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	team_vbox.add_child(atk_lbl)

	var defense_team := GameState.player_data.arena_defense_team
	var def_lbl := Label.new()
	def_lbl.text = "防守：" + (_cat_ids_to_names(defense_team) if not defense_team.is_empty() else "（未設定，自動代入攻擊陣容）")
	def_lbl.add_theme_font_size_override("font_size", 17)
	def_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	team_vbox.add_child(def_lbl)

	var config_hint := Label.new()
	config_hint.text = "可於\n配置頁面\n修改陣容"
	config_hint.add_theme_font_size_override("font_size", 15)
	config_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	config_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	config_hint.custom_minimum_size = Vector2(80.0, 0.0)
	team_hbox.add_child(config_hint)

	# ── 操作按鈕列 ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(btn_row)

	var reward_btn := Button.new()
	reward_btn.text = "段位獎勵"
	reward_btn.custom_minimum_size = Vector2(0.0, 54.0)
	reward_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_btn.add_theme_font_size_override("font_size", 20)
	reward_btn.pressed.connect(_on_reward_pressed)
	btn_row.add_child(reward_btn)

	var buy_btn := Button.new()
	buy_btn.text = "購買競技券"
	buy_btn.custom_minimum_size = Vector2(0.0, 54.0)
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.add_theme_font_size_override("font_size", 20)
	buy_btn.pressed.connect(_on_buy_ticket_pressed)
	btn_row.add_child(buy_btn)

	root_vbox.add_child(HSeparator.new())

	# ── 對手區域標題列 ──
	var opp_title_row := HBoxContainer.new()
	root_vbox.add_child(opp_title_row)

	var opp_title := Label.new()
	opp_title.text = "選擇對手"
	opp_title.add_theme_font_size_override("font_size", 24)
	opp_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opp_title_row.add_child(opp_title)

	_reroll_btn = Button.new()
	_reroll_btn.text = "重骰對手"
	_reroll_btn.custom_minimum_size = Vector2(130.0, 44.0)
	_reroll_btn.add_theme_font_size_override("font_size", 20)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	opp_title_row.add_child(_reroll_btn)

	# ── 對手卡片容器 ──
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	_opponent_container = VBoxContainer.new()
	_opponent_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opponent_container.add_theme_constant_override("separation", 12)
	scroll.add_child(_opponent_container)

	_refresh_status()


func _refresh_status() -> void:
	var d := GameState.arena_data
	_rank_label.text  = ArenaRankSystem.score_to_rank_name(d.score)
	_score_label.text = "積分：%d" % d.score
	_ticket_label.text = "競技券：%d 張" % d.tickets


func _refresh_opponents(is_reroll: bool) -> void:
	# 清除舊卡片
	for child in _opponent_container.get_children():
		child.queue_free()

	_opponents = ArenaMatchmaking.get_opponents(
		GameState.arena_data.score,
		GameState.arena_data.player_id,
		_shown_ids if is_reroll else []
	)

	if not is_reroll:
		_shown_ids = []

	for opp: Dictionary in _opponents:
		_shown_ids.append(opp["player_id"])
		_opponent_container.add_child(_build_opponent_card(opp))

	if _opponents.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "目前沒有可挑戰的對手"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_opponent_container.add_child(empty_lbl)


func _build_opponent_card(opp: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# 對手名稱 & 段位
	var name_row := HBoxContainer.new()
	vbox.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = opp.get("player_name", "???")
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)

	var rank_lbl := Label.new()
	rank_lbl.text = "%s  %d分" % [opp.get("rank_name", ""), opp.get("score", 0)]
	rank_lbl.add_theme_font_size_override("font_size", 18)
	rank_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4, 1.0))
	name_row.add_child(rank_lbl)

	# 防守隊伍預覽
	var defense: Array = opp.get("defense_team", [])
	var team_lbl := Label.new()
	team_lbl.text = "防守：" + (_cat_ids_to_names(defense) if not defense.is_empty() else "（未設定）")
	team_lbl.add_theme_font_size_override("font_size", 18)
	team_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	vbox.add_child(team_lbl)

	# 挑戰按鈕
	var challenge_btn := Button.new()
	challenge_btn.text = "挑戰"
	challenge_btn.custom_minimum_size = Vector2(0.0, 50.0)
	challenge_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_btn.add_theme_font_size_override("font_size", 22)
	challenge_btn.disabled = (GameState.arena_data.tickets <= 0)
	challenge_btn.pressed.connect(func(): _on_challenge_pressed(opp))
	vbox.add_child(challenge_btn)

	return panel


# ── 事件處理 ──────────────────────────────────────────

func _on_reroll_pressed() -> void:
	if _reroll_cooldown > 0.0:
		return
	_reroll_cooldown = REROLL_COOLDOWN
	_reroll_btn.disabled = true
	_refresh_opponents(true)


func _on_challenge_pressed(opp: Dictionary) -> void:
	if not GameState.arena_data.consume_ticket():
		_show_dialog("競技券不足", "請購買更多競技券或明日再來。")
		return
	GameState.arena_data.save()
	GameState.arena_opponent = opp
	# 使用競技場攻擊陣容，未設定則 fallback 到 boss_team
	var attack: Array = GameState.player_data.arena_attack_team
	if attack.is_empty():
		attack = GameState.player_data.boss_team
	if not attack.is_empty():
		GameState.player_team = attack.duplicate()
	get_tree().change_scene_to_file("res://scenes/ArenaBattleScene.tscn")


func _on_reward_pressed() -> void:
	_show_rank_rewards()


func _on_buy_ticket_pressed() -> void:
	var d := GameState.arena_data
	if not d.can_purchase_more():
		_show_dialog("今日已達購買上限", "每日最多購買 %d 次競技券。" % PlayerArenaData.MAX_DAILY_PURCHASES)
		return
	var costs: Array = GameState.arena_config.get("ticket_purchase_costs", [60, 120, 240, 480, 960])
	var cost: int = d.get_next_purchase_cost(costs)
	if cost < 0:
		_show_dialog("今日已達購買上限", "無法繼續購買。")
		return
	var msg := "花費 %d 鑽購買 %d 張競技券\n今日已購買 %d / %d 次" % [
		cost, PlayerArenaData.TICKETS_PER_PURCHASE,
		d.daily_purchase_count, PlayerArenaData.MAX_DAILY_PURCHASES
	]
	DialogManager.show_confirm("購買競技券", msg, func():
		if d.purchase_tickets(cost, GameState.player_data):
			GameState.save_all()
			_refresh_status()
			_refresh_opponents(false)
		else:
			_show_dialog("購買失敗", "鑽石不足。")
	, Callable(), "購買", "取消")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ActivityScene.tscn")


# ── 段位獎勵（Popup） ────────────────────────────────

func _show_rank_rewards() -> void:
	var d := GameState.arena_data
	var claimable := ArenaRankSystem.get_claimable_rewards(d.score, d.claimed_rank_rewards)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500.0, 600.0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# close_fn 在 show_info_node 回傳後填入
	var close_fn: Callable

	for rank_key: String in ArenaRankSystem.RANK_ORDER:
		var min_score: int = ArenaRankSystem.rank_key_to_min_score(rank_key)
		var rank_name: String = ArenaRankSystem.RANK_NAMES.get(rank_key, rank_key)
		var reward: Dictionary = ArenaRankSystem.get_reward(rank_key)
		var is_claimed: bool = d.has_claimed_reward(rank_key)
		var can_claim: bool = claimable.has(rank_key)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)

		var rank_lbl := Label.new()
		rank_lbl.text = rank_name
		rank_lbl.custom_minimum_size = Vector2(120.0, 0.0)
		rank_lbl.add_theme_font_size_override("font_size", 18)
		rank_lbl.add_theme_color_override("font_color",
			Color(0.5, 0.5, 0.5) if is_claimed else Color(1.0, 1.0, 1.0)
		)
		row.add_child(rank_lbl)

		var reward_lbl := Label.new()
		reward_lbl.text = _format_reward(reward)
		reward_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward_lbl.add_theme_font_size_override("font_size", 16)
		reward_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
		row.add_child(reward_lbl)

		if is_claimed:
			var claimed_lbl := Label.new()
			claimed_lbl.text = "已領取"
			claimed_lbl.add_theme_font_size_override("font_size", 16)
			claimed_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			row.add_child(claimed_lbl)
		elif can_claim:
			var claim_btn := Button.new()
			claim_btn.text = "領取"
			claim_btn.custom_minimum_size = Vector2(80.0, 36.0)
			claim_btn.add_theme_font_size_override("font_size", 18)
			claim_btn.pressed.connect(func():
				ArenaRankSystem.apply_reward(rank_key, GameState.player_data)
				d.claim_reward(rank_key)
				GameState.save_all()
				if close_fn.is_valid():
					close_fn.call()
				_show_rank_rewards()
			)
			row.add_child(claim_btn)
		else:
			var locked_lbl := Label.new()
			locked_lbl.text = "需 %d 分" % min_score
			locked_lbl.add_theme_font_size_override("font_size", 16)
			locked_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			row.add_child(locked_lbl)

	close_fn = DialogManager.show_info_node("段位獎勵", scroll)


# ── 工具 ──────────────────────────────────────────────

func _cat_ids_to_names(ids: Array) -> String:
	var names: Array = []
	for cat_id: String in ids:
		var lv := 1
		var player_cat = GameState.get_player_cat(cat_id)
		if player_cat != null:
			lv = player_cat.cat_food_level
		names.append(CatRegistry.get_cat_display_name_with_lv(cat_id, lv))
	return ", ".join(names)


func _format_reward(reward: Dictionary) -> String:
	var parts: Array = []
	if reward.get("diamonds", 0) > 0:
		parts.append("鑽石 ×%d" % reward["diamonds"])
	if reward.get("trap_cages", 0) > 0:
		parts.append("誘捕籠 ×%d" % reward["trap_cages"])
	if reward.get("cat_food", 0) > 0:
		parts.append("乾糧 ×%d" % reward["cat_food"])
	if reward.get("special_cat_food", 0) > 0:
		parts.append("特殊乾糧 ×%d" % reward["special_cat_food"])
	return "  ".join(parts)


func _show_dialog(title_text: String, body_text: String) -> void:
	DialogManager.show_info(title_text, body_text)
