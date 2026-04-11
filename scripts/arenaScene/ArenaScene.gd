extends Control

const Helpers = preload("res://scripts/arenaScene/arena_scene_helpers.gd")
const RewardPopup = preload("res://scripts/arenaScene/arena_scene_reward_popup.gd")

const SW := 720.0
const SH := 1280.0
const REROLL_COOLDOWN := 5.0

var _overview: Dictionary = {}
var _reroll_cooldown := 0.0

var _rank_label: Label
var _score_label: Label
var _ticket_label: Label
var _season_label: Label
var _attack_team_label: Label
var _defense_team_label: Label
var _reroll_button: Button
var _opponent_container: VBoxContainer


func _ready() -> void:
	_build_ui()
	if not GameState.arena_overview_data.is_empty():
		_apply_overview(GameState.arena_overview_data)
	_refresh_overview([])


func _process(delta: float) -> void:
	if _reroll_cooldown <= 0.0:
		return
	_reroll_cooldown = maxf(0.0, _reroll_cooldown - delta)
	if _reroll_cooldown == 0.0:
		_reroll_button.disabled = false
		_reroll_button.text = "重骰"
	else:
		_reroll_button.text = "重骰 (%d)" % ceili(_reroll_cooldown)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.133, 0.157, 0.192, 1.0)
	background.size = Vector2(SW, SH)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_top = 40
	root.offset_right = -20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var top_row := HBoxContainer.new()
	root.add_child(top_row)

	var back_button := Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(100.0, 50.0)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ActivityScene.tscn"))
	top_row.add_child(back_button)

	var title := Label.new()
	title.text = "競技場"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	root.add_child(HSeparator.new())

	var status_panel := PanelContainer.new()
	root.add_child(status_panel)

	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 6)
	status_panel.add_child(status_box)

	_rank_label = Label.new()
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.add_theme_font_size_override("font_size", 28)
	status_box.add_child(_rank_label)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 20)
	status_box.add_child(_score_label)

	_ticket_label = Label.new()
	_ticket_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticket_label.add_theme_font_size_override("font_size", 20)
	status_box.add_child(_ticket_label)

	_season_label = Label.new()
	_season_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_season_label.add_theme_font_size_override("font_size", 16)
	status_box.add_child(_season_label)

	var team_panel := PanelContainer.new()
	root.add_child(team_panel)

	var team_box := VBoxContainer.new()
	team_box.add_theme_constant_override("separation", 4)
	team_panel.add_child(team_box)

	_attack_team_label = Label.new()
	_attack_team_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_attack_team_label.add_theme_font_size_override("font_size", 17)
	team_box.add_child(_attack_team_label)

	_defense_team_label = Label.new()
	_defense_team_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_defense_team_label.add_theme_font_size_override("font_size", 17)
	team_box.add_child(_defense_team_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	root.add_child(button_row)

	var reward_button := Button.new()
	reward_button.text = "牌位獎勵"
	reward_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_button.custom_minimum_size = Vector2(0.0, 54.0)
	reward_button.pressed.connect(_on_reward_pressed)
	button_row.add_child(reward_button)

	var purchase_button := Button.new()
	purchase_button.text = "購買競技券"
	purchase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_button.custom_minimum_size = Vector2(0.0, 54.0)
	purchase_button.pressed.connect(_on_purchase_pressed)
	button_row.add_child(purchase_button)

	root.add_child(HSeparator.new())

	var opponent_title_row := HBoxContainer.new()
	root.add_child(opponent_title_row)

	var opponent_title := Label.new()
	opponent_title.text = "推薦對手"
	opponent_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_title.add_theme_font_size_override("font_size", 24)
	opponent_title_row.add_child(opponent_title)

	_reroll_button = Button.new()
	_reroll_button.text = "重骰"
	_reroll_button.custom_minimum_size = Vector2(140.0, 44.0)
	_reroll_button.pressed.connect(_on_reroll_pressed)
	opponent_title_row.add_child(_reroll_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_opponent_container = VBoxContainer.new()
	_opponent_container.add_theme_constant_override("separation", 12)
	scroll.add_child(_opponent_container)

	_apply_overview({})


func _refresh_overview(excluded_opponent_ids: Array) -> void:
	ApiClient.get_arena_overview(excluded_opponent_ids, func(success: bool, data: Variant, error: Dictionary) -> void:
		if success and data is Dictionary:
			GameState.update_arena(data)
			_apply_overview(data)
			return
		if _overview.is_empty():
			_show_dialog("競技場", Helpers.build_error_message(error))
	)


func _apply_overview(overview: Dictionary) -> void:
	_overview = overview.duplicate(true)
	_rank_label.text = Helpers.get_current_rank(_overview)
	_score_label.text = "積分：%d" % Helpers.get_current_score(_overview)
	_ticket_label.text = "競技券：%d" % Helpers.get_current_tickets(_overview)
	_season_label.text = "%s｜結束日 %s" % [
		str(_overview.get("seasonDisplayName", "目前賽季")),
		str(_overview.get("seasonEndDate", "-"))
	]
	_attack_team_label.text = "攻擊隊伍：%s" % Helpers.format_team_names_from_team("ArenaAttack", "Boss", "未設定，將改用 Boss 隊伍")
	_defense_team_label.text = "防守隊伍：%s" % Helpers.format_team_names_from_team("ArenaDefense", "", "未設定防守隊伍")
	_render_opponents()


func _render_opponents() -> void:
	for child: Node in _opponent_container.get_children():
		child.queue_free()

	var opponents: Array = _overview.get("opponents", [])
	if opponents.is_empty():
		var empty_label := Label.new()
		empty_label.text = "目前沒有可挑戰的對手。"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_opponent_container.add_child(empty_label)
		return

	for opponent_variant: Variant in opponents:
		if opponent_variant is Dictionary:
			_opponent_container.add_child(_build_opponent_card(opponent_variant))


func _build_opponent_card(opponent: Dictionary) -> Control:
	var panel := PanelContainer.new()

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title_row := HBoxContainer.new()
	box.add_child(title_row)

	var name_label := Label.new()
	name_label.text = str(opponent.get("playerName", "未知對手"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 22)
	title_row.add_child(name_label)

	var score_label := Label.new()
	score_label.text = "%s  %d" % [str(opponent.get("rankName", "青銅 III")), int(opponent.get("score", 0))]
	score_label.add_theme_font_size_override("font_size", 18)
	title_row.add_child(score_label)

	var team_label := Label.new()
	team_label.text = "防守隊伍：%s" % Helpers.format_opponent_team(opponent)
	team_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	team_label.add_theme_font_size_override("font_size", 16)
	box.add_child(team_label)

	var challenge_button := Button.new()
	challenge_button.text = "挑戰"
	challenge_button.custom_minimum_size = Vector2(0.0, 48.0)
	challenge_button.disabled = Helpers.get_current_tickets(_overview) <= 0
	challenge_button.pressed.connect(func() -> void: _on_challenge_pressed(opponent))
	box.add_child(challenge_button)

	return panel


func _on_reroll_pressed() -> void:
	if _reroll_cooldown > 0.0:
		return
	_reroll_cooldown = REROLL_COOLDOWN
	_reroll_button.disabled = true
	_refresh_overview(_get_current_opponent_ids())


func _on_challenge_pressed(opponent: Dictionary) -> void:
	var attack_team := Helpers.get_team_member_player_cat_ids("ArenaAttack", "Boss")
	if attack_team.is_empty():
		_show_dialog("競技場", "請先在配置頁設定競技場攻擊隊伍或 Boss 隊伍。")
		return
	if Helpers.get_current_tickets(_overview) <= 0:
		_show_dialog("競技場", "競技券不足。")
		return
	GameState.player_team = attack_team
	GameState.arena_opponent = opponent.duplicate(true)
	get_tree().change_scene_to_file("res://scenes/ArenaBattleScene.tscn")


func _on_reward_pressed() -> void:
	if _overview.is_empty():
		_show_dialog("牌位獎勵", "尚未取得競技場資料。")
		return
	RewardPopup.show(self, _overview, func(rank_id: int) -> void: _claim_rank_reward(rank_id))


func _claim_rank_reward(rank_id: int) -> void:
	ApiClient.claim_arena_rank_reward(rank_id, func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success or not (data is Dictionary):
			_show_dialog("牌位獎勵", Helpers.build_error_message(error))
			return
		var response: Dictionary = data
		var overview: Dictionary = response.get("overview", {})
		if not overview.is_empty():
			GameState.update_arena(overview)
			_apply_overview(overview)
		_show_dialog("牌位獎勵", "已領取 %s：%s" % [
			str(response.get("rankName", "牌位獎勵")),
			Helpers.format_rewards(response.get("rewards", []))
		])
	)


func _on_purchase_pressed() -> void:
	if _overview.is_empty():
		_show_dialog("購買競技券", "尚未取得競技場資料。")
		return
	var purchase_count := int(_overview.get("dailyPurchaseCount", 0))
	var max_purchase_count := int(_overview.get("maxDailyPurchaseCount", 5))
	if purchase_count >= max_purchase_count:
		_show_dialog("購買競技券", "今日已達購買上限。")
		return
	var costs: Array = _overview.get("ticketPurchaseCosts", [])
	var cost := int(costs[purchase_count]) if purchase_count < costs.size() else -1
	if cost < 0:
		_show_dialog("購買競技券", "目前沒有可用的購買方案。")
		return
	DialogManager.show_confirm(
		"購買競技券",
		"消耗 %d 鑽石，購買 %d 張競技券？" % [cost, int(_overview.get("ticketsPerPurchase", 3))],
		_purchase_tickets_confirmed
	)


func _show_dialog(title_text: String, body_text: String) -> void:
	DialogManager.show_info(title_text, body_text)


func _get_current_opponent_ids() -> Array:
	var ids: Array = []
	for opponent_variant: Variant in _overview.get("opponents", []):
		if not (opponent_variant is Dictionary):
			continue
		var opponent: Dictionary = opponent_variant
		var opponent_id := str(opponent.get("opponentId", "")).strip_edges()
		if opponent_id != "":
			ids.append(opponent_id)
	return ids


func _purchase_tickets_confirmed() -> void:
	ApiClient.purchase_arena_tickets(_on_purchase_tickets_completed)


func _on_purchase_tickets_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success or not (data is Dictionary):
		_show_dialog("購買競技券", Helpers.build_error_message(error))
		return
	var response: Dictionary = data
	var overview: Dictionary = response.get("overview", {})
	if not overview.is_empty():
		GameState.update_arena(overview)
		_apply_overview(overview)
	_show_dialog("購買競技券", "已購買 %d 張競技券。" % int(response.get("addedTickets", 0)))
