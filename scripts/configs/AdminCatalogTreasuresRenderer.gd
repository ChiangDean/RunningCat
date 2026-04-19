class_name AdminCatalogTreasuresRenderer
extends Control

signal changed

var _treasure_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_treasure_controls.clear()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	var entries: Array = data.get("treasures", []) if data.get("treasures") is Array else []

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var ctrls := _build_treasure_block(entry, vbox, i % 2 == 0)
		_treasure_controls.append(ctrls)


func get_data() -> Dictionary:
	var result: Array = []
	for ctrl: Dictionary in _treasure_controls:
		var effects_arr: Array = []
		for ec: Dictionary in (ctrl["effect_controls"] as Array):
			effects_arr.append({
				"id": ec["id"],
				"effectOrder": ec["order"],
				"targetScopeType": AdminCatalogFormHelpers.get_enum_value(ec["scope_ob"] as OptionButton),
				"statType": AdminCatalogFormHelpers.get_enum_value(ec["stat_ob"] as OptionButton),
				"valueType": AdminCatalogFormHelpers.get_enum_value(ec["value_ob"] as OptionButton),
				"baseValue": (ec["base_spin"] as SpinBox).value,
				"isEnabled": (ec["enabled"] as CheckBox).button_pressed,
			})
		result.append({
			"id": ctrl["id"],
			"displayName": (ctrl["name"] as LineEdit).text,
			"description": (ctrl["desc"] as LineEdit).text,
			"sourceText": (ctrl["source"] as LineEdit).text,
			"imagePath": (ctrl["path"] as LineEdit).text,
			"placeholderColor": (ctrl["color"] as LineEdit).text,
			"sortOrder": int((ctrl["sort"] as SpinBox).value),
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
			"effects": effects_arr,
		})
	return {"treasures": result}


func _build_treasure_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block)

	var margin := _make_row_margin()
	block.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Main info row
	var top_hb := AdminCatalogFormHelpers.make_row_hbox()
	vbox.add_child(top_hb)

	top_hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))

	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))
	var source_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("sourceText", "")))
	var path_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("imagePath", "")))
	var color_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("placeholderColor", "#ffffff")), 90.0)
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 999, 75.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	_add_labeled(top_hb, "名稱:", name_edit)
	_add_labeled(top_hb, "說明:", desc_edit)
	_add_labeled(top_hb, "來源:", source_edit)
	_add_labeled(top_hb, "圖片:", path_edit)
	_add_labeled(top_hb, "色:", color_edit)
	_add_labeled(top_hb, "排序:", sort_spin)
	_add_labeled(top_hb, "啟用:", enabled_cb)

	for node: Node in [name_edit, desc_edit, source_edit, path_edit, color_edit]:
		_connect_change(node, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# Effects sub-table
	var effects: Array = entry.get("effects", []) if entry.get("effects") is Array else []
	var effect_controls := _build_effects_subtable(effects, vbox)

	return {
		"id": entry.get("id", 0),
		"name": name_edit, "desc": desc_edit, "source": source_edit,
		"path": path_edit, "color": color_edit,
		"sort": sort_spin, "enabled": enabled_cb,
		"effect_controls": effect_controls,
	}


func _build_effects_subtable(effects: Array, parent: VBoxContainer) -> Array:
	if effects.is_empty():
		return []

	var sub_margin := MarginContainer.new()
	sub_margin.add_theme_constant_override("margin_left", 20)
	parent.add_child(sub_margin)

	var sub_vbox := VBoxContainer.new()
	sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_vbox.add_theme_constant_override("separation", 2)
	sub_margin.add_child(sub_vbox)

	var header := AdminCatalogFormHelpers.make_header_row_panel()
	sub_vbox.add_child(header)
	var hm := _make_small_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("順序", 55.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("目標範圍", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("屬性", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("數值類型", 100.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("基礎值", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var controls: Array = []
	for i: int in range(effects.size()):
		var ef: Dictionary = effects[i] if effects[i] is Dictionary else {}
		var row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		sub_vbox.add_child(row)
		var rm := _make_small_margin()
		row.add_child(rm)
		var r_hb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(r_hb)

		var order_lbl := Label.new()
		order_lbl.text = "#%d" % int(ef.get("effectOrder", i + 1))
		order_lbl.custom_minimum_size.x = 55.0
		order_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		order_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
		order_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		r_hb.add_child(order_lbl)

		var scope_ob := AdminCatalogFormHelpers.make_enum_cell(
			AdminCatalogFormHelpers.TARGET_SCOPE_OPTIONS,
			str(ef.get("targetScopeType", "None"))
		)
		scope_ob.custom_minimum_size.x = 110.0
		scope_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		var stat_ob := AdminCatalogFormHelpers.make_enum_cell(
			AdminCatalogFormHelpers.STAT_TYPE_OPTIONS,
			str(ef.get("statType", "None"))
		)
		stat_ob.custom_minimum_size.x = 110.0
		stat_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		var value_ob := AdminCatalogFormHelpers.make_enum_cell(
			AdminCatalogFormHelpers.VALUE_MODE_OPTIONS,
			str(ef.get("valueType", "None"))
		)
		value_ob.custom_minimum_size.x = 100.0
		value_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		var base_spin := AdminCatalogFormHelpers.make_float_cell(float(ef.get("baseValue", 0.0)), 0.001, 90.0)
		var ef_enabled := AdminCatalogFormHelpers.make_bool_cell(bool(ef.get("isEnabled", true)))

		r_hb.add_child(scope_ob)
		r_hb.add_child(stat_ob)
		r_hb.add_child(value_ob)
		r_hb.add_child(base_spin)
		r_hb.add_child(ef_enabled)

		for node: Node in [scope_ob, stat_ob, value_ob]:
			_connect_change(node, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(base_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(ef_enabled, "toggled", func(_v: Variant) -> void: changed.emit())

		controls.append({
			"id": ef.get("id", 0),
			"order": int(ef.get("effectOrder", i + 1)),
			"scope_ob": scope_ob,
			"stat_ob": stat_ob,
			"value_ob": value_ob,
			"base_spin": base_spin,
			"enabled": ef_enabled,
		})

	return controls


# ── Layout Helpers ────────────────────────────────────────────

static func _add_labeled(hb: HBoxContainer, label_text: String, control: Control) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(lbl)
	hb.add_child(control)


static func _make_row_margin() -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 6)
	m.add_theme_constant_override("margin_right", 6)
	m.add_theme_constant_override("margin_top", 3)
	m.add_theme_constant_override("margin_bottom", 3)
	return m


static func _make_small_margin() -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 4)
	m.add_theme_constant_override("margin_right", 4)
	m.add_theme_constant_override("margin_top", 2)
	m.add_theme_constant_override("margin_bottom", 2)
	return m


static func _connect_change(node: Node, signal_name: String, callable: Callable) -> void:
	node.connect(signal_name, callable)
