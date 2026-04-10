extends RefCounted

## 成就 Tab — 成就列表、領取獎勵


func build(scene: Control) -> void:
	var title := Label.new()
	title.text = "成就"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(title)

	scene._achievement_summary_label = Label.new()
	scene._achievement_summary_label.add_theme_font_size_override("font_size", 18)
	scene._achievement_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(scene._achievement_summary_label)

	var hint := Label.new()
	hint.text = "成就達成後需手動領取。已領取成就會收納到最下方的收合區。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(hint)

	scene._tab_content.add_child(scene._make_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(scroll)
	scene._achievement_scroller = InertialScroller.attach(scroll, "vertical")

	scene._achievement_list = VBoxContainer.new()
	scene._achievement_list.add_theme_constant_override("separation", 12)
	scene._achievement_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._achievement_list)

	if not scene.GameState.scooper_achievement_data.is_empty():
		_refresh_achievement_tab(scene)
		scene._refresh_tab_button_labels()
	else:
		scene._show_loading_in(scene._achievement_list)
	scene.ApiClient.get_achievements(func(ok: bool, data: Variant, _err: Dictionary) -> void:
		if ok and data is Array:
			scene.GameState.update_scooper_achievement(data)
		if scene._current_tab == "achievement":
			_refresh_achievement_tab(scene)
			scene._refresh_tab_button_labels()
	)


func _refresh_achievement_tab(scene: Control) -> void:
	var items: Array = scene.GameState.scooper_achievement_data

	# 分組
	var claimed: Array = []
	var active: Array = []
	var claimable_count := 0
	var completed_count := 0

	for item: Dictionary in items:
		var is_completed: bool = bool(item.get("isCompleted", false))
		var is_claimed: bool = bool(item.get("isClaimed", false))
		if is_claimed:
			claimed.append(item)
			completed_count += 1
		elif is_completed:
			active.append(item)
			claimable_count += 1
			completed_count += 1
		else:
			active.append(item)

	if scene._achievement_summary_label != null:
		scene._achievement_summary_label.text = "可領取：%d　已完成：%d / %d" % [
			claimable_count,
			completed_count,
			items.size(),
		]

	if scene._achievement_list == null:
		return

	for child in scene._achievement_list.get_children():
		child.queue_free()

	_add_claimed_achievement_section(scene, claimed)
	scene._achievement_list.add_child(scene._make_separator())
	_add_achievement_section(
		scene,
		"成就列表",
		active,
		"目前沒有可顯示的未領取成就"
	)


func _add_achievement_section(scene: Control, title_text: String, entries: Array, empty_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 1.0))
	scene._achievement_list.add_child(title)

	if entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = empty_text
		empty_lbl.add_theme_font_size_override("font_size", 17)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
		scene._achievement_list.add_child(empty_lbl)
		return

	for entry: Dictionary in entries:
		scene._achievement_list.add_child(_make_achievement_card(scene, entry))


func _add_claimed_achievement_section(scene: Control, entries: Array) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	scene._achievement_list.add_child(header)

	var title := Label.new()
	title.text = "已領取"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var count_lbl := Label.new()
	count_lbl.text = "%d 項" % entries.size()
	count_lbl.add_theme_font_size_override("font_size", 18)
	count_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	header.add_child(count_lbl)

	var toggle_btn := Button.new()
	toggle_btn.text = "收合" if scene._achievement_claimed_expanded else "展開"
	toggle_btn.custom_minimum_size = Vector2(100.0, 38.0)
	toggle_btn.pressed.connect(func() -> void:
		scene._achievement_claimed_expanded = not scene._achievement_claimed_expanded
		_refresh_achievement_tab(scene)
	)
	header.add_child(toggle_btn)

	if not scene._achievement_claimed_expanded:
		var collapsed_lbl := Label.new()
		collapsed_lbl.text = "已領取成就預設收合，避免干擾目前可操作項目。"
		collapsed_lbl.add_theme_font_size_override("font_size", 16)
		collapsed_lbl.add_theme_color_override("font_color", Color(0.58, 0.58, 0.58, 1.0))
		collapsed_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scene._achievement_list.add_child(collapsed_lbl)
		return

	if entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "目前還沒有已領取的成就"
		empty_lbl.add_theme_font_size_override("font_size", 17)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
		scene._achievement_list.add_child(empty_lbl)
		return

	for entry: Dictionary in entries:
		scene._achievement_list.add_child(_make_achievement_card(scene, entry))


func _make_achievement_card(scene: Control, entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_color = _achievement_border_color(entry)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	margin.add_child(card)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	card.add_child(header)

	var name_lbl := Label.new()
	name_lbl.text = entry.get("displayName") if entry.get("displayName") != null else ""
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)

	var state_lbl := Label.new()
	state_lbl.text = _achievement_state_text(entry)
	state_lbl.add_theme_font_size_override("font_size", 16)
	state_lbl.add_theme_color_override("font_color", _achievement_border_color(entry))
	header.add_child(state_lbl)

	var condition_lbl := Label.new()
	condition_lbl.text = entry.get("conditionText") if entry.get("conditionText") != null else ""
	condition_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	condition_lbl.add_theme_font_size_override("font_size", 16)
	condition_lbl.add_theme_color_override("font_color", Color(0.84, 0.84, 0.84, 1.0))
	card.add_child(condition_lbl)

	var progress_lbl := Label.new()
	progress_lbl.text = entry.get("progressText") if entry.get("progressText") != null else ""
	progress_lbl.add_theme_font_size_override("font_size", 16)
	progress_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95, 1.0))
	card.add_child(progress_lbl)

	var reward_lbl := Label.new()
	reward_lbl.text = "獎勵：%s" % entry.get("rewardText", "")
	reward_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_lbl.add_theme_font_size_override("font_size", 17)
	reward_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.66, 1.0))
	card.add_child(reward_lbl)

	var is_completed: bool = bool(entry.get("isCompleted", false))
	var is_claimed: bool = bool(entry.get("isClaimed", false))

	if is_completed:
		var time_lbl := Label.new()
		var completed_at: String = entry.get("completedAtUtc") if entry.get("completedAtUtc") != null else "-"
		time_lbl.text = "完成時間：%s" % completed_at
		if is_claimed:
			time_lbl.text += "　領取時間：%s" % String(entry.get("claimedAtUtc", "-"))
		time_lbl.add_theme_font_size_override("font_size", 15)
		time_lbl.add_theme_color_override("font_color", Color(0.66, 0.66, 0.66, 1.0))
		card.add_child(time_lbl)

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(0.0, 42.0)
	action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(action_btn)

	var achievement_id: int = int(entry.get("achievementId", 0))
	if is_completed and not is_claimed:
		action_btn.text = "領取獎勵"
		action_btn.pressed.connect(func() -> void:
			_claim_achievement(scene, achievement_id)
		)
	elif is_claimed:
		action_btn.text = "已領取"
		action_btn.disabled = true
	else:
		action_btn.text = "尚未達成"
		action_btn.disabled = true

	return panel


func _claim_achievement(scene: Control, achievement_id: int) -> void:
	if scene._api_in_flight:
		return
	scene._api_in_flight = true

	scene.ApiClient.claim_achievement(achievement_id, func(ok: bool, data: Variant, err: Dictionary) -> void:
		scene._api_in_flight = false
		if not ok:
			scene.DialogManager.show_info("領取失敗", String(err.get("message", "操作失敗")))
			return

		var result: Dictionary = data if data is Dictionary else {}
		var granted: Array = result.get("grantedRewards", [])
		var lines: Array[String] = []
		for reward_text: Variant in granted:
			lines.append("• %s" % str(reward_text))
		if lines.is_empty():
			lines.append("• 已成功發放獎勵")
		scene.DialogManager.show_info(
			"領取成功",
			"%s\n\n%s" % [
				String(result.get("message", "")),
				"\n".join(lines),
			]
		)

		# 重拉成就、profile
		scene.ApiClient.get_achievements(func(a_ok: bool, a_data: Variant, _a_err: Dictionary) -> void:
			if a_ok and a_data is Array:
				scene.GameState.update_scooper_achievement(a_data)
			if scene._current_tab == "achievement":
				_refresh_achievement_tab(scene)
				scene._refresh_tab_button_labels()
		)
		scene.ApiClient.get_scooper_profile(func(p_ok: bool, p_data: Variant, _p_err: Dictionary) -> void:
			if p_ok and p_data is Dictionary:
				scene.GameState.update_scooper_profile(p_data)
				scene._apply_profile_to_player_data(p_data)
		)
	)


func _achievement_border_color(entry: Dictionary) -> Color:
	if bool(entry.get("isClaimed", false)):
		return Color(0.48, 0.48, 0.48, 1.0)
	if bool(entry.get("isCompleted", false)):
		return Color(0.94, 0.78, 0.36, 1.0)
	return Color(0.28, 0.3, 0.34, 1.0)


func _achievement_state_text(entry: Dictionary) -> String:
	if bool(entry.get("isClaimed", false)):
		return "已領取"
	if bool(entry.get("isCompleted", false)):
		return "可領取"
	return "未達成"
