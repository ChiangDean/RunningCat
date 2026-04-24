extends RefCounted

const CARD_TEMPLATE: PackedScene = preload("res://scenes/ui/scooper/achievement/ScooperAchievementCardTemplate.tscn")


func build(scene: Control) -> void:
	scene._achievement_summary_label = scene._tab_header_summary
	if scene._achievement_summary_label == null:
		var summary_row: HBoxContainer = HBoxContainer.new()
		summary_row.add_theme_constant_override("separation", 10)
		scene._tab_content.add_child(summary_row)

		var section_label: Label = Label.new()
		section_label.text = UiText.SCOOPER_TAB_ACHIEVEMENT
		section_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		summary_row.add_child(section_label)

		var section_line: HSeparator = HSeparator.new()
		section_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_row.add_child(section_line)

		scene._achievement_summary_label = Label.new()
		scene._achievement_summary_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		scene._achievement_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		summary_row.add_child(scene._achievement_summary_label)

	scene._achievement_feedback_label = Label.new()
	scene._achievement_feedback_label.text = ""
	scene._achievement_feedback_label.visible = false
	scene._achievement_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scene._achievement_feedback_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	scene._achievement_feedback_label.add_theme_color_override("font_color", Color(0.88, 0.98, 0.80, 1.0))
	scene._tab_content.add_child(scene._achievement_feedback_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(scroll)
	scene._achievement_scroller = InertialScroller.attach(scroll, "vertical")

	scene._achievement_list = VBoxContainer.new()
	scene._achievement_list.add_theme_constant_override("separation", 12)
	scene._achievement_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._achievement_list)

	_refresh_achievement_tab(scene)
	scene._refresh_tab_button_labels()


func _refresh_achievement_tab(scene: Control) -> void:
	scene._achievement_claimed_expanded = true
	var items: Array = scene.GameState.scooper_achievement_data
	var claimed: Array = []
	var active: Array = []
	var claimable_count: int = 0

	for item: Dictionary in items:
		var is_completed: bool = bool(item.get("isCompleted", false))
		var is_claimed: bool = bool(item.get("isClaimed", false))
		if is_claimed:
			claimed.append(item)
		else:
			active.append(item)
			if is_completed:
				claimable_count += 1

	if scene._achievement_summary_label != null:
		scene._achievement_summary_label.text = UiText.SCOOPER_ACHIEVEMENT_SUMMARY_FORMAT % [claimable_count]

	if scene._achievement_list == null:
		return

	for child: Node in scene._achievement_list.get_children():
		child.queue_free()

	_add_achievement_section(
		scene,
		UiText.SCOOPER_ACHIEVEMENT_SECTION_ACTIVE,
		active,
		UiText.SCOOPER_ACHIEVEMENT_EMPTY_ACTIVE,
		claimable_count
	)
	scene._achievement_list.add_child(scene._make_separator())
	_add_claimed_achievement_section(scene, claimed)


func _add_achievement_section(scene: Control, title_text: String, entries: Array, empty_text: String, claimable_count: int) -> void:
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	scene._achievement_list.add_child(header)

	var title: Label = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", Color(0.84, 0.90, 1.0, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	if claimable_count > 0:
		var claim_all_btn: Button = Button.new()
		claim_all_btn.text = UiText.SCOOPER_ACHIEVEMENT_CLAIM_ALL
		claim_all_btn.custom_minimum_size = Vector2(120.0, 40.0)
		claim_all_btn.disabled = bool(scene._api_in_flight)
		UiPalette.apply_button_kind(claim_all_btn, "confirm")
		RedDotService.refresh_dot(claim_all_btn, not claim_all_btn.disabled)
		claim_all_btn.pressed.connect(Callable(self, "_claim_all_achievements").bind(scene))
		header.add_child(claim_all_btn)

	if entries.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = empty_text
		empty_lbl.add_theme_font_size_override("font_size", 17)
		empty_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.68, 1.0))
		scene._achievement_list.add_child(empty_lbl)
		return

	var first_item: bool = true
	for entry: Dictionary in entries:
		if not first_item:
			scene._achievement_list.add_child(scene._make_separator())
		scene._achievement_list.add_child(_make_achievement_card(scene, entry))
		first_item = false


func _add_claimed_achievement_section(scene: Control, entries: Array) -> void:
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	scene._achievement_list.add_child(header)

	var title: Label = Label.new()
	title.text = UiText.SCOOPER_ACHIEVEMENT_SECTION_CLAIMED
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	if entries.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = UiText.SCOOPER_ACHIEVEMENT_EMPTY_CLAIMED
		empty_lbl.add_theme_font_size_override("font_size", 17)
		empty_lbl.add_theme_color_override("font_color", Color(0.68, 0.68, 0.68, 1.0))
		scene._achievement_list.add_child(empty_lbl)
		return

	var first_item: bool = true
	for entry: Dictionary in entries:
		if not first_item:
			scene._achievement_list.add_child(scene._make_separator())
		scene._achievement_list.add_child(_make_achievement_card(scene, entry))
		first_item = false


func _make_achievement_card(scene: Control, entry: Dictionary) -> Control:
	var panel: Panel = CARD_TEMPLATE.instantiate() as Panel
	var name_lbl: Label = panel.get_node("Margin/ContentCanvas/NameLabel") as Label
	var condition_lbl: Label = panel.get_node("Margin/ContentCanvas/ConditionLabel") as Label
	var claimed_time_lbl: Label = panel.get_node("Margin/ContentCanvas/ClaimedAtLabel") as Label
	var reward_lbl: Label = panel.get_node("Margin/ContentCanvas/RewardLabel") as Label
	var action_btn: Button = panel.get_node("Margin/ContentCanvas/ActionButton") as Button
	var reward_icon: TextureRect = panel.get_node("Margin/ContentCanvas/SlotFrame/Icon") as TextureRect
	var reward_count_lbl: Label = panel.get_node("Margin/ContentCanvas/SlotFrame/CountLabel") as Label
	name_lbl.text = str(entry.get("displayName", ""))
	condition_lbl.text = _format_achievement_text(entry.get("conditionText", ""))

	var is_completed: bool = bool(entry.get("isCompleted", false))
	var is_claimed: bool = bool(entry.get("isClaimed", false))
	var claimed_time_text: String = _achievement_claimed_at_text(entry)
	claimed_time_lbl.visible = is_claimed and claimed_time_text != ""
	if claimed_time_lbl.visible:
		claimed_time_lbl.text = UiText.SCOOPER_ACHIEVEMENT_CLAIMED_AT % claimed_time_text
	var reward_info: Dictionary = _parse_reward_display(entry.get("rewardText", ""))
	reward_lbl.text = str(reward_info.get("label", ""))
	reward_icon.texture = _resolve_reward_texture(str(reward_info.get("icon_path", "")))
	reward_icon.visible = reward_icon.texture != null
	var reward_amount: int = int(reward_info.get("amount", 0))
	reward_count_lbl.visible = reward_amount > 0
	reward_count_lbl.text = "x%s" % GameState.format_number(reward_amount)

	var achievement_id: int = int(entry.get("achievementId", 0))
	if is_completed and not is_claimed:
		action_btn.text = UiText.SCOOPER_ACHIEVEMENT_ACTION_CLAIM
		action_btn.disabled = bool(scene._api_in_flight)
		UiPalette.apply_button_kind(action_btn, "confirm")
		RedDotService.refresh_dot(action_btn, not action_btn.disabled)
		action_btn.pressed.connect(Callable(self, "_claim_achievement").bind(scene, achievement_id))
	elif is_claimed:
		action_btn.text = UiText.SCOOPER_ACHIEVEMENT_ACTION_CLAIMED
		action_btn.disabled = true
		UiPalette.apply_button_kind(action_btn, "neutral")
	else:
		action_btn.text = UiText.SCOOPER_ACHIEVEMENT_ACTION_PENDING
		action_btn.disabled = true
		UiPalette.apply_button_kind(action_btn, "neutral")

	return panel


func _claim_achievement(scene: Control, achievement_id: int) -> void:
	if scene._api_in_flight:
		return
	scene._api_in_flight = true
	_refresh_achievement_tab(scene)
	scene._refresh_tab_button_labels()

	scene.ApiClient.claim_achievement_silent(achievement_id, Callable(self, "_on_claim_achievement_completed").bind(scene))


func _claim_all_achievements(scene: Control) -> void:
	if scene._api_in_flight:
		return
	var claim_ids: Array[int] = []
	for entry: Dictionary in scene.GameState.scooper_achievement_data:
		if bool(entry.get("isCompleted", false)) and not bool(entry.get("isClaimed", false)):
			claim_ids.append(int(entry.get("achievementId", 0)))
	if claim_ids.is_empty():
		return

	scene._api_in_flight = true
	_refresh_achievement_tab(scene)
	scene._refresh_tab_button_labels()
	_claim_next_achievement(scene, claim_ids, [])


func _claim_next_achievement(scene: Control, pending_ids: Array[int], reward_entries: Array[Dictionary]) -> void:
	if pending_ids.is_empty():
		if not reward_entries.is_empty():
			scene.queue_home_reward_floats(reward_entries)
		_set_feedback(scene, UiText.SCOOPER_ACHIEVEMENT_CLAIM_SUCCESS)
		_refresh_achievements_after_claim(scene)
		return

	var next_ids: Array[int] = pending_ids.duplicate()
	var achievement_id: int = next_ids.pop_front()
	scene.ApiClient.claim_achievement_silent(achievement_id, Callable(self, "_on_claim_next_achievement_completed").bind(scene, next_ids, reward_entries))


func _refresh_achievements_after_claim(scene: Control) -> void:
	scene.ApiClient.get_scooper_profile_silent(Callable(self, "_on_refresh_achievements_profile_completed").bind(scene))


func _on_claim_achievement_completed(ok: bool, data: Variant, err: Dictionary, scene: Control) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	if not ok:
		scene._api_in_flight = false
		_refresh_achievement_tab(scene)
		scene._refresh_tab_button_labels()
		_set_feedback(scene, str(err.get("message", UiText.SCOOPER_ACHIEVEMENT_CLAIM_FAILED_DEFAULT)))
		return

	var result: Dictionary = data if data is Dictionary else {}
	var reward_entries: Array[Dictionary] = _extract_reward_float_entries(scene, result)
	if not reward_entries.is_empty():
		scene.queue_home_reward_floats(reward_entries)
	_apply_claim_result(scene, result)
	_refresh_achievements_after_claim(scene)


func _on_claim_next_achievement_completed(
	ok: bool,
	data: Variant,
	err: Dictionary,
	scene: Control,
	next_ids: Array[int],
	reward_entries: Array[Dictionary]
) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	if not ok:
		scene._api_in_flight = false
		_refresh_achievement_tab(scene)
		scene._refresh_tab_button_labels()
		_set_feedback(scene, str(err.get("message", UiText.SCOOPER_ACHIEVEMENT_CLAIM_FAILED_DEFAULT)))
		return

	var result: Dictionary = data if data is Dictionary else {}
	var next_entries: Array[Dictionary] = reward_entries.duplicate()
	next_entries.append_array(_extract_reward_float_entries(scene, result))
	_apply_claim_profile(scene)
	_claim_next_achievement(scene, next_ids, next_entries)


func _on_refresh_achievements_profile_completed(
	profile_ok: bool,
	profile_data: Variant,
	_profile_err: Dictionary,
	scene: Control
) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	if profile_ok and profile_data is Dictionary:
		scene.GameState.update_scooper_profile(profile_data)
		scene._refresh_resource_label()

	scene.ApiClient.get_achievements_silent(Callable(self, "_on_refresh_achievements_completed").bind(scene))


func _on_refresh_achievements_completed(
	refresh_ok: bool,
	refresh_data: Variant,
	refresh_err: Dictionary,
	scene: Control
) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	scene._api_in_flight = false
	if refresh_ok and refresh_data is Array:
		scene.GameState.update_scooper_achievement(refresh_data)
		_refresh_achievement_tab(scene)
		scene._refresh_tab_button_labels()
		return
	_refresh_achievement_tab(scene)
	scene._refresh_tab_button_labels()
	_set_feedback(scene, str(refresh_err.get("message", UiText.SCOOPER_ACHIEVEMENT_REFRESH_FAILED_DEFAULT)))


func _apply_claim_result(scene: Control, result: Dictionary) -> void:
	_apply_claim_profile(scene)
	var texts: Array[String] = _extract_granted_reward_texts(result)
	if texts.is_empty():
		_set_feedback(scene, UiText.SCOOPER_ACHIEVEMENT_CLAIM_SUCCESS)
		return
	_set_feedback(scene, UiText.SCOOPER_ACHIEVEMENT_CLAIM_SUCCESS + "\n" + "\n".join(texts))


func _apply_claim_profile(scene: Control) -> void:
	scene._refresh_resource_label()


func _extract_granted_reward_texts(result: Dictionary) -> Array[String]:
	var granted: Array = result.get("grantedRewards", [])
	var lines: Array[String] = []
	for reward_variant: Variant in granted:
		lines.append(_format_reward_string(str(reward_variant)))
	return lines


func _extract_reward_float_entries(scene: Control, result: Dictionary) -> Array[Dictionary]:
	var granted: Array = result.get("grantedRewards", [])
	var entries: Array[Dictionary] = []
	for reward_variant: Variant in granted:
		var entry: Dictionary = _parse_reward_float_entry(scene, str(reward_variant))
		if not entry.is_empty():
			entries.append(entry)
	return entries


func _parse_reward_float_entry(scene: Control, reward_text: String) -> Dictionary:
	var normalized: String = reward_text.strip_edges().replace("＋", "+")
	var amount_match: RegEx = RegEx.new()
	amount_match.compile("(\\d+)$")
	var amount_result: RegExMatch = amount_match.search(normalized)
	if amount_result == null:
		return {}

	var amount: int = int(amount_result.get_string(1))
	var name_text: String = normalized.substr(0, amount_result.get_start()).strip_edges()
	name_text = name_text.trim_suffix("x").trim_suffix("X").strip_edges()

	var reward_key: String = ""
	var label: String = name_text
	match name_text.to_lower():
		"gold":
			reward_key = "gold"
			label = UiText.REWARD_GOLD
		"diamonds":
			reward_key = "diamonds"
			label = UiText.REWARD_DIAMONDS
		"memory shards":
			reward_key = "memory_shards"
			label = UiText.REWARD_MEMORY_SHARDS
		"whisker shards":
			reward_key = "whiskers"
			label = UiText.REWARD_WHISKERS
		_:
			reward_key = "gold"

	return scene.make_reward_float_entry(label, amount, reward_key)


func _format_reward_string(reward_text: String) -> String:
	var entry_match: RegEx = RegEx.new()
	entry_match.compile("^\\s*(.+?)\\s*[xX]\\s*(\\d+)\\s*$")
	var result: RegExMatch = entry_match.search(reward_text)
	if result == null:
		return reward_text

	var name_text: String = result.get_string(1).strip_edges()
	var amount: String = result.get_string(2)
	match name_text.to_lower():
		"gold":
			return "%s +%s" % [UiText.REWARD_GOLD, amount]
		"diamonds":
			return "%s +%s" % [UiText.REWARD_DIAMONDS, amount]
		"memory shards":
			return "%s +%s" % [UiText.REWARD_MEMORY_SHARDS, amount]
		"whisker shards":
			return "%s +%s" % [UiText.REWARD_WHISKERS, amount]
		_:
			return "%s +%s" % [name_text, amount]


func _achievement_claimed_at_text(entry: Dictionary) -> String:
	for key: String in ["claimedAtUtc", "claimedAt", "claimTime", "claimedTime"]:
		var value: String = str(entry.get(key, "")).strip_edges()
		if value != "":
			return value
	return ""


func _parse_reward_display(value: Variant) -> Dictionary:
	var raw_text: String = _format_achievement_text(value).strip_edges()
	if raw_text == "":
		return {"label": "", "amount": 0, "icon_path": ""}

	var entry_match: RegEx = RegEx.new()
	entry_match.compile("^\\s*(.+?)\\s*[xX×]\\s*(\\d+)\\s*$")
	var result: RegExMatch = entry_match.search(raw_text)
	var name_text: String = raw_text
	var amount: int = 0
	if result != null:
		name_text = result.get_string(1).strip_edges()
		amount = int(result.get_string(2))

	var normalized: String = name_text.to_lower().replace(" ", "").replace("_", "")
	match normalized:
		"gold", UiText.REWARD_KEY_ZH_GOLD:
			return {"label": UiText.REWARD_GOLD, "amount": amount, "icon_path": "catalog/currency/gold"}
		"diamonds", "diamond", UiText.REWARD_KEY_ZH_DIAMONDS:
			return {"label": UiText.REWARD_DIAMONDS, "amount": amount, "icon_path": "catalog/currency/diamonds"}
		"catfood", UiText.REWARD_KEY_ZH_CAT_FOOD:
			return {"label": UiText.REWARD_CAT_FOOD, "amount": amount, "icon_path": "catalog/consumable/cat_food"}
		"specialcatfood", UiText.REWARD_KEY_ZH_SPECIAL_CAT_FOOD:
			return {"label": UiText.REWARD_SPECIAL_CAT_FOOD, "amount": amount, "icon_path": "catalog/consumable/special_cat_food"}
		"memoryshards", UiText.REWARD_KEY_ZH_MEMORY_SHARDS:
			return {"label": UiText.REWARD_MEMORY_SHARDS, "amount": amount, "icon_path": "catalog/consumable/memory_shards"}
		"whiskers", "whiskershards", UiText.REWARD_KEY_ZH_WHISKERS, UiText.REWARD_KEY_ZH_WHISKER_SHARDS:
			return {"label": UiText.REWARD_WHISKERS, "amount": amount, "icon_path": "catalog/consumable/whisker_shards"}
		"trapcage", "trapcages", UiText.REWARD_KEY_ZH_TRAP_CAGE:
			return {"label": UiText.REWARD_TRAP_CAGE, "amount": amount, "icon_path": "catalog/consumable/trap_cages"}
		"poop", "poopcount", UiText.REWARD_KEY_ZH_POOP:
			return {"label": UiText.REWARD_POOP, "amount": amount, "icon_path": "catalog/consumable/poop_count"}
		_:
			return {"label": name_text, "amount": amount, "icon_path": ""}


func _resolve_reward_texture(icon_path: String) -> Texture2D:
	if icon_path == "":
		return null
	return AssetResolver.load_texture(AssetResolver.resolve_catalog_path(icon_path))


func _format_achievement_text(value: Variant) -> String:
	if value is Dictionary:
		var dict_value: Dictionary = value
		if dict_value.has("value"):
			return str(dict_value.get("value", ""))
		return JSON.stringify(dict_value)

	var text: String = str(value)
	if text.find("{\"value\":") >= 0:
		var regex: RegEx = RegEx.new()
		regex.compile("\\{\\s*\"value\"\\s*:\\s*(\\d+)\\s*\\}")
		var match_result: RegExMatch = regex.search(text)
		if match_result != null:
			text = regex.sub(text, match_result.get_string(1), true)
	return text


func _set_feedback(scene: Control, text: String) -> void:
	if scene._achievement_feedback_label != null:
		scene._achievement_feedback_label.text = text
		scene._achievement_feedback_label.visible = text.strip_edges() != ""
