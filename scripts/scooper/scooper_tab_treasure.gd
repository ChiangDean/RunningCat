extends RefCounted

const ITEM_SLOT_TEMPLATE: PackedScene = preload("res://scenes/ui/backpack/ItemSlotTemplate.tscn")

const GRID_COLS := 5
const SLOT_TEMPLATE_BASE_SIZE := Vector2(512.0, 512.0)
const SLOT_SCALE := 0.25
const SLOT_CELL_SIZE := Vector2(128.0, 128.0)
const GRID_H_SEPARATION := 2
const GRID_V_SEPARATION := 10


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

	var grid_width: float = (
		(SLOT_CELL_SIZE.x * float(GRID_COLS))
		+ (GRID_H_SEPARATION * float(maxi(GRID_COLS - 1, 0)))
	)
	var center: CenterContainer = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._treasure_list.add_child(center)

	var grid: GridContainer = GridContainer.new()
	grid.columns = GRID_COLS
	grid.custom_minimum_size = Vector2(grid_width, 0.0)
	grid.add_theme_constant_override("h_separation", GRID_H_SEPARATION)
	grid.add_theme_constant_override("v_separation", GRID_V_SEPARATION)
	center.add_child(grid)

	for item: Dictionary in items:
		grid.add_child(_make_treasure_slot(scene, item))


func _make_treasure_slot(scene: Control, item: Dictionary) -> Control:
	var qty: int = int(item.get("quantity", 0))
	var slot: Control = ITEM_SLOT_TEMPLATE.instantiate() as Control
	var icon: TextureRect = slot.get_node("ItemIcon") as TextureRect
	var name_label: Label = slot.get_node("ItemNameLabel") as Label
	var qty_label: Label = slot.get_node("CountLabel") as Label
	var frame: TextureRect = slot.get_node("Frame") as TextureRect
	var overlay_mask: TextureRect = slot.get_node("OverlayMask") as TextureRect

	AssetResolver.apply_catalog_texture(icon, item.get("imagePath", ""))
	icon.visible = item.get("imagePath", "") != ""

	name_label.text = str(item.get("displayName", ""))
	name_label.tooltip_text = name_label.text
	qty_label.text = GameState.format_number(qty)
	qty_label.tooltip_text = qty_label.text

	frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	overlay_mask.modulate = Color(1.0, 1.0, 1.0, 0.42)

	slot.scale = Vector2(SLOT_SCALE, SLOT_SCALE)

	var cell: Control = Control.new()
	cell.custom_minimum_size = SLOT_CELL_SIZE
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.add_child(slot)

	cell.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_show_treasure_detail(scene, item)
	)

	return cell


func _show_treasure_detail(scene: Control, item: Dictionary) -> void:
	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(420.0, 0.0)
	content.add_theme_constant_override("separation", 16)

	# --- Icon row: ItemSlotTemplate centered ---
	var icon_center: CenterContainer = CenterContainer.new()
	content.add_child(icon_center)
	var detail_slot: Control = ITEM_SLOT_TEMPLATE.instantiate() as Control
	var detail_icon: TextureRect = detail_slot.get_node("ItemIcon") as TextureRect
	var detail_name: Label = detail_slot.get_node("ItemNameLabel") as Label
	var detail_qty: Label = detail_slot.get_node("CountLabel") as Label
	var detail_frame: TextureRect = detail_slot.get_node("Frame") as TextureRect
	var detail_overlay: TextureRect = detail_slot.get_node("OverlayMask") as TextureRect

	AssetResolver.apply_catalog_texture(detail_icon, item.get("imagePath", ""))
	detail_name.visible = false
	detail_qty.text = GameState.format_number(int(item.get("quantity", 0)))
	detail_frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
	detail_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	detail_overlay.modulate = Color(1.0, 1.0, 1.0, 0.42)

	var detail_scale: float = 0.30
	detail_slot.scale = Vector2(detail_scale, detail_scale)
	var slot_cell: Control = Control.new()
	var cell_size: float = SLOT_TEMPLATE_BASE_SIZE.x * detail_scale
	slot_cell.custom_minimum_size = Vector2(cell_size, cell_size)
	slot_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_cell.add_child(detail_slot)
	icon_center.add_child(slot_cell)

	# --- 詳細說明 ---
	var desc_title: Label = Label.new()
	desc_title.text = "詳細說明"
	desc_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	desc_title.add_theme_color_override("font_color", Color(0.82, 0.70, 0.42, 1.0))
	content.add_child(desc_title)

	var desc_label: Label = Label.new()
	desc_label.text = str(item.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	content.add_child(desc_label)

	# --- 加成 ---
	var bonus_text: String = _treasure_bonus_desc(item)
	if bonus_text.strip_edges() != "":
		var sep: HSeparator = HSeparator.new()
		content.add_child(sep)

		var bonus_title: Label = Label.new()
		bonus_title.text = "加成"
		bonus_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		bonus_title.add_theme_color_override("font_color", Color(0.82, 0.70, 0.42, 1.0))
		content.add_child(bonus_title)

		var bonus_label: Label = Label.new()
		bonus_label.text = bonus_text
		bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bonus_label.add_theme_font_size_override("font_size", 17)
		content.add_child(bonus_label)

	var title: String = str(item.get("displayName", ""))
	scene.DialogManager.show_info_node(title, content, Callable(), "medium")


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
		"atk", "Atk":
			return "%s 固定攻擊 +%.0f" % [target_str, value]
		"def", "Def":
			return "%s 固定防禦 +%.0f" % [target_str, value]
		"hp", "Hp", "max_hp", "MaxHp":
			return "%s 固定生命 +%.0f" % [target_str, value]
		"speed", "Speed":
			return "%s 固定速度 +%.0f" % [target_str, value]
		"atk_percent", "AtkPercent":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "攻擊加成", value * 100.0]
		"def_percent", "DefPercent":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "防禦加成", value * 100.0]
		"max_hp_percent", "MaxHpPercent", "hp_percent", "HpPercent":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "生命加成", value * 100.0]
		"crit_rate", "CritRate":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "暴擊率", value * 100.0]
		"crit_damage", "CritDamage":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "暴擊傷害", value * 100.0]
		"damage_reduction", "DamageReduction":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "傷害減免", value * 100.0]
		"cooldown_reduction", "CooldownReduction":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "冷卻縮減", value * 100.0]
		"idle_poop_percent", "IdlePoopPercent":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [UiText.SCOOPER_EQUIPMENT_BONUS_ALL, UiText.REWARD_POOP, value * 100.0]
		"dungeon_damage_boost", "DungeonDamageBoost":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "副本增傷", value * 100.0]
		"dungeon_damage_reduction", "DungeonDamageReduction":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "副本減傷", value * 100.0]
		"life_steal", "LifeSteal":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "吸血比率", value * 100.0]
		"counter_damage_chance", "CounterDamageChance":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "反傷機率", value * 100.0]
		"physical_damage_boost", "PhysicalDamageBoost":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "物理增傷", value * 100.0]
		"physical_damage_reduction", "PhysicalDamageReduction":
			return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, "物理減傷", value * 100.0]
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
