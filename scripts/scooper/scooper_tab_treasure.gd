extends RefCounted

const CARD_TEMPLATE: PackedScene = preload("res://scenes/ui/scooper/treasure/ScooperTreasureCardTemplate.tscn")


func build(scene: Control) -> void:
	scene._treasure_summary_label = scene._tab_header_summary
	if scene._treasure_summary_label == null:
		var summary_row: HBoxContainer = HBoxContainer.new()
		summary_row.add_theme_constant_override("separation", 10)
		scene._tab_content.add_child(summary_row)

		var section_label: Label = Label.new()
		section_label.text = UiText.SCOOPER_TAB_TREASURE
		section_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		summary_row.add_child(section_label)

		var section_line: HSeparator = HSeparator.new()
		section_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_row.add_child(section_line)

		scene._treasure_summary_label = Label.new()
		scene._treasure_summary_label.text = ""
		scene._treasure_summary_label.visible = false
		summary_row.add_child(scene._treasure_summary_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(scroll)
	scene._treasure_scroller = InertialScroller.attach(scroll, "vertical")

	scene._treasure_list = VBoxContainer.new()
	scene._treasure_list.add_theme_constant_override("separation", 12)
	scene._treasure_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._treasure_list)

	_refresh_treasure_tab(scene)


func _refresh_treasure_tab(scene: Control) -> void:
	var items: Array = scene.GameState.scooper_treasure_data
	if scene._treasure_summary_label != null:
		var total_quantity: int = 0
		for item_variant: Variant in items:
			if not (item_variant is Dictionary):
				continue
			var item: Dictionary = item_variant
			total_quantity += int(item.get("quantity", 0))
		scene._treasure_summary_label.visible = true
		scene._treasure_summary_label.text = UiText.SCOOPER_TREASURE_SUMMARY_FORMAT % [items.size(), total_quantity]
	if scene._treasure_list == null:
		return

	for child: Node in scene._treasure_list.get_children():
		child.queue_free()

	if items.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = UiText.SCOOPER_TREASURE_EMPTY
		empty_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._treasure_list.add_child(empty_lbl)
		return

	var first_item: bool = true
	for item: Dictionary in items:
		if not first_item:
			scene._treasure_list.add_child(scene._make_separator())
		scene._treasure_list.add_child(_make_treasure_card(scene, item))
		first_item = false


func _make_treasure_card(_scene: Control, item: Dictionary) -> Control:
	var accent: Color = _get_treasure_placeholder_color(item)
	var panel: Panel = CARD_TEMPLATE.instantiate() as Panel
	var icon_rect: TextureRect = panel.get_node("Margin/ContentCanvas/Icon") as TextureRect
	var title_lbl: Label = panel.get_node("Margin/ContentCanvas/TitleLabel") as Label
	var qty: Label = panel.get_node("Margin/ContentCanvas/QuantityLabel") as Label
	var desc: Label = panel.get_node("Margin/ContentCanvas/DescriptionLabel") as Label
	var bonus: Label = panel.get_node("Margin/ContentCanvas/BonusLabel") as Label
	var treasure_texture: Texture2D = AssetResolver.load_texture(AssetResolver.resolve_catalog_path(item.get("imagePath", "")))
	icon_rect.texture = treasure_texture
	icon_rect.visible = treasure_texture != null
	title_lbl.text = str(item.get("displayName", ""))
	qty.text = "x%s" % GameState.format_number(int(item.get("quantity", 0)))
	qty.add_theme_color_override("font_color", accent)
	desc.text = str(item.get("description", ""))
	bonus.text = _treasure_bonus_desc(item)
	bonus.visible = bonus.text.strip_edges() != ""

	return panel


func _treasure_bonus_desc(item: Dictionary) -> String:
	var lines: Array[String] = []
	for effect: Dictionary in item.get("effects", []):
		lines.append(_format_treasure_effect(effect))
	return "\n".join(lines)


func _format_treasure_effect(effect: Dictionary) -> String:
	var target: String = str(effect.get("targetElementType", "all"))
	var target_str: String = UiText.SCOOPER_EQUIPMENT_BONUS_ALL if target.to_lower() == "all" else target
	var stat: String = str(effect.get("statType", ""))
	var value: float = float(effect.get("value", 0.0))
	match stat:
		"atk_percent", "AtkPercent":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "ATK", value * 100.0]
		"def_percent", "DefPercent":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "DEF", value * 100.0]
		"max_hp_percent", "MaxHpPercent":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "HP", value * 100.0]
		"crit_rate", "CritRate":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "CRIT", value * 100.0]
		"crit_damage", "CritDamage":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "CRIT DMG", value * 100.0]
		"damage_reduction", "DamageReduction":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "DMG RED", value * 100.0]
		"cooldown_reduction", "CooldownReduction":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "CD RED", value * 100.0]
		"idle_poop_percent", "IdlePoopPercent":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [UiText.SCOOPER_EQUIPMENT_BONUS_ALL, UiText.REWARD_POOP, value * 100.0]
		_:
			return "%s %s %.2f" % [target_str, stat, value]


func _get_treasure_placeholder_color(item: Dictionary) -> Color:
	var raw_color: String = str(item.get("placeholderColor", "#6B7280"))
	return Color.from_string(raw_color, Color(0.42, 0.45, 0.50, 1.0))


func _show_total_bonus_dialog(scene: Control) -> void:
	var totals: Dictionary = {}
	for item: Dictionary in scene.GameState.scooper_treasure_data:
		var quantity: int = int(item.get("quantity", 0))
		if quantity <= 0:
			continue
		for effect: Dictionary in item.get("effects", []):
			var key: String = "%s|%s" % [str(effect.get("targetElementType", "all")).to_lower(), str(effect.get("statType", ""))]
			totals[key] = float(totals.get(key, 0.0)) + float(effect.get("value", 0.0)) * quantity

	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(420.0, 0.0)
	content.add_theme_constant_override("separation", 8)

	if totals.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = UiText.SCOOPER_TREASURE_EMPTY
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		content.add_child(empty_label)
	else:
		var keys: Array = totals.keys()
		keys.sort()
		for key_variant: Variant in keys:
			var key: String = str(key_variant)
			var parts: PackedStringArray = key.split("|")
			var effect: Dictionary = {
				"targetElementType": parts[0],
				"statType": parts[1],
				"value": float(totals[key]),
			}
			var line: Label = Label.new()
			line.text = _format_treasure_effect(effect)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_theme_font_size_override("font_size", 17)
			content.add_child(line)

	scene.DialogManager.show_info_node(UiText.SCOOPER_TREASURE_TOTAL_BONUS_TITLE, content, Callable(), "medium")
