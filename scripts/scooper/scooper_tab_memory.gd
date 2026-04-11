extends RefCounted

## 回憶 Tab — 回憶收藏列表、解鎖功能


func build(scene: Control) -> void:
	var title := Label.new()
	title.text = "回憶收藏"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(title)

	scene._memory_summary_label = Label.new()
	scene._memory_summary_label.add_theme_font_size_override("font_size", 18)
	scene._memory_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(scene._memory_summary_label)

	var hint := Label.new()
	hint.text = "回憶碎片足夠時，可自由選擇要解鎖哪一張回憶。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(hint)

	scene._tab_content.add_child(scene._make_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(scroll)
	scene._memory_scroller = InertialScroller.attach(scroll, "vertical")

	scene._memory_list = VBoxContainer.new()
	scene._memory_list.add_theme_constant_override("separation", 12)
	scene._memory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._memory_list)

	if not scene.GameState.scooper_memory_data.is_empty():
		_refresh_memory_tab(scene)
	else:
		scene._show_loading_in(scene._memory_list)
	_fetch_memory_data(scene)


func _fetch_memory_data(scene: Control) -> void:
	scene.ApiClient.get_memories(func(ok: bool, data: Variant, _err: Dictionary) -> void:
		if ok and data is Array:
			scene.GameState.update_scooper_memory(data)
		if scene._current_tab == "memory":
			_refresh_memory_tab(scene)
	)


func _refresh_memory_tab(scene: Control) -> void:
	var items: Array = scene.GameState.scooper_memory_data
	if scene._memory_summary_label != null:
		var total: int = items.size()
		var unlocked := 0
		for item: Dictionary in items:
			if bool(item.get("isUnlocked", false)):
				unlocked += 1
		scene._memory_summary_label.text = "回憶碎片：%d　已解鎖：%d / %d" % [
			scene.GameState.player_data.memory_shards,
			unlocked,
			total,
		]

	if scene._memory_list == null:
		return

	for child in scene._memory_list.get_children():
		child.queue_free()

	if items.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "目前沒有可展示的回憶"
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._memory_list.add_child(empty_lbl)
		return

	for item: Dictionary in items:
		scene._memory_list.add_child(_make_memory_card(scene, item))


func _make_memory_card(scene: Control, item: Dictionary) -> Control:
	var memory_id: int = int(item.get("memoryId", 0))
	var unlocked: bool = bool(item.get("isUnlocked", false))
	var cost: int = int(item.get("unlockCost", 0))
	var can_unlock: bool = not unlocked and scene.GameState.player_data.memory_shards >= cost
	var accent := _get_memory_placeholder_color(item)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = accent if unlocked else Color(0.25, 0.27, 0.31, 1.0)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 10)
	margin.add_child(card)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	card.add_child(header)

	var display_name: String = item.get("displayName") if item.get("displayName") != null else ""
	var title_lbl := Label.new()
	title_lbl.text = display_name
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not unlocked:
		title_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	header.add_child(title_lbl)

	var state := Label.new()
	state.text = "已解鎖" if unlocked else "未解鎖"
	state.add_theme_font_size_override("font_size", 16)
	state.add_theme_color_override("font_color", accent if unlocked else Color(0.75, 0.75, 0.75, 1.0))
	header.add_child(state)

	var preview := Control.new()
	preview.custom_minimum_size = Vector2(0.0, 170.0)
	card.add_child(preview)

	var preview_bg := ColorRect.new()
	preview_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_bg.color = accent
	preview.add_child(preview_bg)

	var photo_path: String = item.get("imagePath") if item.get("imagePath") != null else ""
	if photo_path != "" and ResourceLoader.exists(photo_path):
		var texture := load(photo_path)
		if texture is Texture2D:
			var photo := TextureRect.new()
			photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			photo.texture = texture
			photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			preview.add_child(photo)

	var preview_text := Label.new()
	preview_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_text.add_theme_font_size_override("font_size", 28)
	preview_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	preview_text.text = display_name if unlocked else "LOCKED"
	preview.add_child(preview_text)

	if not unlocked:
		var overlay := ColorRect.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.color = Color(0.0, 0.0, 0.0, 0.62)
		preview.add_child(overlay)

		var lock_lbl := Label.new()
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 26)
		lock_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		lock_lbl.text = "🔒"
		preview.add_child(lock_lbl)

	var desc := Label.new()
	desc.text = item.get("description") if item.get("description") != null else ""
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	card.add_child(desc)

	var bonus := Label.new()
	bonus.text = _memory_bonus_desc(item)
	bonus.add_theme_font_size_override("font_size", 17)
	bonus.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0, 1.0))
	card.add_child(bonus)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	card.add_child(action_row)

	var detail_btn := Button.new()
	detail_btn.text = "查看詳情"
	detail_btn.custom_minimum_size = Vector2(130.0, 42.0)
	detail_btn.pressed.connect(func() -> void:
		_show_memory_dialog(scene, item, unlocked)
	)
	action_row.add_child(detail_btn)

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(190.0, 42.0)
	action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(action_btn)

	if unlocked:
		action_btn.text = "已收藏"
		action_btn.disabled = true
	elif can_unlock:
		action_btn.text = "消耗 %d 碎片解鎖" % cost
		action_btn.pressed.connect(func() -> void:
			_confirm_unlock_memory(scene, memory_id, item)
		)
	else:
		action_btn.text = "需要 %d 碎片" % cost
		action_btn.disabled = true

	return panel


func _show_memory_dialog(scene: Control, item: Dictionary, unlocked: bool) -> void:
	var lines: Array[String] = [
		str(item.get("description", "")),
		"",
		"效果：%s" % _memory_bonus_desc(item),
		"解鎖需求：回憶碎片 %d" % int(item.get("unlockCost", 0)),
		"目前狀態：%s" % ("已解鎖" if unlocked else "未解鎖"),
	]
	scene.DialogManager.show_info(str(item.get("displayName", "")), "\n".join(lines))


func _confirm_unlock_memory(scene: Control, memory_id: int, memory_item: Dictionary) -> void:
	var cost: int = int(memory_item.get("unlockCost", 0))
	var display_name: String = memory_item.get("displayName") if memory_item.get("displayName") != null else ""
	scene.DialogManager.show_confirm(
		"解鎖回憶",
		"要消耗 %d 個回憶碎片解鎖「%s」嗎？\n\n%s" % [
			cost,
			display_name,
			_memory_bonus_desc(memory_item),
		],
		func() -> void:
			if scene._api_in_flight:
				return
			scene._api_in_flight = true
			scene.ApiClient.unlock_memory(memory_id, func(ok: bool, data: Variant, err: Dictionary) -> void:
				scene._api_in_flight = false
				if not ok:
					scene.DialogManager.show_info("解鎖失敗", str(err.get("message", "操作失敗")))
					return
				var result: Dictionary = data if data is Dictionary else {}
				scene.GameState.player_data.memory_shards = int(result.get("remainingMemoryShards", scene.GameState.player_data.memory_shards))
				scene._refresh_resource_label()
				scene.DialogManager.show_info(
					"解鎖成功",
					"已解鎖「%s」\n%s" % [
						display_name,
						_memory_bonus_desc(memory_item),
					]
				)
				_fetch_memory_data(scene)
			)
	)


func _memory_bonus_desc(item: Dictionary) -> String:
	var stat: String   = item.get("bonusStatType") if item.get("bonusStatType") != null else ""
	var target: String = item.get("bonusTarget") if item.get("bonusTarget") != null else "All"
	var value: float   = float(item.get("bonusValue", 0.0))
	var target_str: String = "全隊" if target.to_lower() == "all" else "%s系" % target
	var stat_str: String
	match stat:
		"atk_percent", "AtkPercent":     stat_str = "ATK"
		"def_percent", "DefPercent":     stat_str = "DEF"
		"max_hp_percent", "MaxHpPercent": stat_str = "HP"
		"crit_rate", "CritRate":         stat_str = "暴擊率"
		"crit_damage", "CritDamage":     stat_str = "暴擊傷害"
		_:                               stat_str = stat
	return "%s %s +%.1f%%" % [target_str, stat_str, value * 100.0]


func _get_memory_placeholder_color(item: Dictionary) -> Color:
	var raw_color: String = item.get("placeholderColor") if item.get("placeholderColor") != null else "#6B7280"
	return Color.from_string(raw_color, Color(0.42, 0.45, 0.5, 1.0))
