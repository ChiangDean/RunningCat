class_name AdminCatalogFormHelpers
extends RefCounted

const COL_TEXT_COLOR := Color(0.95, 0.93, 0.87, 1.0)
const MUTED_COLOR := Color(0.72, 0.69, 0.63, 0.85)

const ITEM_CATEGORY_OPTIONS := [
	["None", "未知"],
	["CurrencyLike", "貨幣型"],
	["Material", "素材"],
	["Ticket", "票券"],
	["Feed", "飼料"],
	["Shard", "碎片"],
	["Special", "特殊"],
]

const STAT_TYPE_OPTIONS := [
	["None", "未知"],
	["Hp", "生命"],
	["Atk", "攻擊"],
	["Def", "防禦"],
	["Speed", "速度"],
	["HpPercent", "生命%"],
	["AtkPercent", "攻擊%"],
	["DefPercent", "防禦%"],
	["CritRate", "暴擊率"],
	["CritDamage", "暴擊傷害"],
	["DamageReduction", "減傷"],
	["CooldownReduction", "冷卻縮減"],
	["IdlePoopPercent", "放置便便%"],
]

const VALUE_MODE_OPTIONS := [
	["None", "未知"],
	["Flat", "固定值"],
	["Percent", "百分比"],
]

const TARGET_SCOPE_OPTIONS := [
	["None", "未知"],
	["Self", "自身"],
	["AllySingle", "單體友方"],
	["AllyAll", "全體友方"],
	["EnemySingle", "單體敵方"],
	["EnemyFront", "前排敵方"],
	["EnemyLowestHp", "最低血量敵方"],
	["EnemyAll", "全體敵方"],
	["Team", "隊伍"],
	["All", "全體"],
	["Tank", "坦克"],
	["Speed", "速度型"],
	["Assassin", "刺客"],
	["Defensive", "防禦型"],
]

const GACHA_RARITY_OPTIONS := [
	["None", "未知"],
	["Common", "普通"],
	["Uncommon", "不常見"],
	["Fine", "精良"],
	["Special", "特殊"],
	["Precious", "珍貴"],
	["Excellent", "卓越"],
	["Rare", "稀有"],
	["Epic", "史詩"],
	["Legendary", "傳說"],
]


static func make_col_header(text: String, min_w: float = 0.0, expand: bool = true) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.62, 0.95))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if min_w > 0.0:
		lbl.custom_minimum_size.x = min_w
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


static func make_id_cell(id_val: Variant) -> Label:
	var lbl := Label.new()
	lbl.text = str(id_val)
	lbl.custom_minimum_size.x = 48.0
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	lbl.add_theme_color_override("font_color", MUTED_COLOR)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


static func make_text_cell(value: String, min_w: float = 0.0) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	if min_w > 0.0:
		edit.custom_minimum_size.x = min_w
	_apply_line_edit_style(edit)
	return edit


static func make_int_cell(value: int, min_val: int = 0, max_val: int = 999999, min_w: float = 80.0) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = 1
	spin.value = value
	spin.custom_minimum_size.x = min_w
	spin.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	return spin


static func make_float_cell(value: float, step: float = 0.001, min_w: float = 90.0) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = 0.0
	spin.max_value = 9999999.0
	spin.step = step
	spin.value = value
	spin.custom_minimum_size.x = min_w
	spin.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	return spin


static func make_bool_cell(value: bool, min_w: float = 60.0) -> CheckBox:
	var cb := CheckBox.new()
	cb.button_pressed = value
	cb.custom_minimum_size.x = min_w
	return cb


static func make_enum_cell(options: Array, current_str: String) -> OptionButton:
	var ob := OptionButton.new()
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ob.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	var selected_idx := 0
	for i: int in range(options.size()):
		var pair: Array = options[i]
		ob.add_item(str(pair[1]), i)
		ob.set_item_metadata(i, str(pair[0]))
		if str(pair[0]) == current_str:
			selected_idx = i
	ob.selected = selected_idx
	return ob


static func get_enum_value(ob: OptionButton) -> String:
	var idx := ob.selected
	if idx < 0:
		return ""
	return str(ob.get_item_metadata(idx))


static func make_header_row_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.11, 0.98)
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func make_data_row_panel(is_odd: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.17, 0.20, 0.85) if is_odd else Color(0.13, 0.12, 0.15, 0.85)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func make_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	lbl.add_theme_color_override("font_color", Color(0.99, 0.93, 0.74, 1.0))
	return lbl


static func make_form_row(label_text: String, control: Control, label_min_w: float = 220.0) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = label_min_w
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	lbl.add_theme_color_override("font_color", MUTED_COLOR)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	row.add_child(control)
	return row


static func make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.30, 0.26, 0.20, 0.60))
	return sep


static func make_row_hbox() -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return hb


static func _apply_line_edit_style(edit: LineEdit) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.12, 0.98)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.38, 0.32, 0.22, 0.75)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	edit.add_theme_stylebox_override("normal", style)
	edit.add_theme_stylebox_override("focus", style)
	edit.add_theme_color_override("font_color", COL_TEXT_COLOR)
