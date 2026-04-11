extends RefCounted

## 寶藏 Tab — 寶藏收藏列表


func build(scene: Control) -> void:
	var title := Label.new()
	title.text = "寶藏收藏"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(title)

	scene._treasure_summary_label = Label.new()
	scene._treasure_summary_label.add_theme_font_size_override("font_size", 18)
	scene._treasure_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(scene._treasure_summary_label)

	var hint := Label.new()
	hint.text = "商城禮包取得的寶藏會直接納入收藏，重複取得會重複生效。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(hint)

	scene._tab_content.add_child(scene._make_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(scroll)
	scene._treasure_scroller = InertialScroller.attach(scroll, "vertical")

	scene._treasure_list = VBoxContainer.new()
	scene._treasure_list.add_theme_constant_override("separation", 12)
	scene._treasure_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._treasure_list)

	if not scene.GameState.scooper_treasure_data.is_empty():
		_refresh_treasure_tab(scene)
	else:
		scene._show_loading_in(scene._treasure_list)


func _refresh_treasure_tab(scene: Control) -> void:
	var items: Array = scene.GameState.scooper_treasure_data
	if scene._treasure_summary_label != null:
		var total_types: int = items.size()
		var total_quantity := 0
		for item: Dictionary in items:
			total_quantity += int(item.get("quantity", 0))
		scene._treasure_summary_label.text = "已收藏：%d 種　總持有：%d 件" % [total_types, total_quantity]

	if scene._treasure_list == null:
		return

	for child in scene._treasure_list.get_children():
		child.queue_free()

	if items.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "目前還沒有收藏到任何寶藏"
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._treasure_list.add_child(empty_lbl)
		return

	for item: Dictionary in items:
		scene._treasure_list.add_child(_make_treasure_card(scene, item))


func _make_treasure_card(scene: Control, item: Dictionary) -> Control:
	var accent := _get_treasure_placeholder_color(item)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = accent
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
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

	var title_lbl := Label.new()
	title_lbl.text = item.get("displayName") if item.get("displayName") != null else ""
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var qty := Label.new()
	qty.text = "x%d" % int(item.get("quantity", 0))
	qty.add_theme_font_size_override("font_size", 18)
	qty.add_theme_color_override("font_color", accent)
	header.add_child(qty)

	var desc := Label.new()
	desc.text = item.get("description") if item.get("description") != null else ""
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	card.add_child(desc)

	var source := Label.new()
	source.text = item.get("sourceText") if item.get("sourceText") != null else ""
	source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source.add_theme_font_size_override("font_size", 15)
	source.add_theme_color_override("font_color", Color(0.74, 0.82, 0.92, 1.0))
	card.add_child(source)

	var time_lbl := Label.new()
	var obtained_at: String = item.get("latestObtainedAtUtc") if item.get("latestObtainedAtUtc") != null else ""
	time_lbl.text = "最近取得：%s" % (obtained_at if obtained_at != "" else "-")
	time_lbl.add_theme_font_size_override("font_size", 15)
	time_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	card.add_child(time_lbl)

	var bonus := Label.new()
	bonus.text = _treasure_bonus_desc(item)
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus.add_theme_font_size_override("font_size", 17)
	bonus.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0, 1.0))
	card.add_child(bonus)

	return panel


func _treasure_bonus_desc(item: Dictionary) -> String:
	var lines: Array[String] = []
	for effect: Dictionary in item.get("effects", []):
		lines.append(_format_treasure_effect(effect))
	return "\n".join(lines)


func _format_treasure_effect(effect: Dictionary) -> String:
	var target: String = effect.get("targetElementType") if effect.get("targetElementType") != null else "all"
	var target_str: String = "全隊" if target.to_lower() == "all" else "%s系" % target
	var stat: String = effect.get("statType") if effect.get("statType") != null else ""
	var value: float = float(effect.get("value", 0.0))
	match stat:
		"atk_percent", "AtkPercent":
			return "%s ATK +%.1f%%" % [target_str, value * 100.0]
		"def_percent", "DefPercent":
			return "%s DEF +%.1f%%" % [target_str, value * 100.0]
		"max_hp_percent", "MaxHpPercent":
			return "%s HP +%.1f%%" % [target_str, value * 100.0]
		"crit_rate", "CritRate":
			return "%s 暴擊率 +%.1f%%" % [target_str, value * 100.0]
		"crit_damage", "CritDamage":
			return "%s 暴擊傷害 +%.1f%%" % [target_str, value * 100.0]
		"damage_reduction", "DamageReduction":
			return "%s 減傷 +%.1f%%" % [target_str, value * 100.0]
		"cooldown_reduction", "CooldownReduction":
			return "%s 技能 CD -%.1f%%" % [target_str, value * 100.0]
		"idle_poop_percent", "IdlePoopPercent":
			return "掛機屎堆 +%.1f%%" % [value * 100.0]
		_:
			return "%s %s %.2f" % [target_str, stat, value]


func _get_treasure_placeholder_color(item: Dictionary) -> Color:
	var raw_color: String = item.get("placeholderColor") if item.get("placeholderColor") != null else "#6B7280"
	return Color.from_string(raw_color, Color(0.42, 0.45, 0.5, 1.0))
