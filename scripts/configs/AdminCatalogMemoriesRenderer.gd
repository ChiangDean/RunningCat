class_name AdminCatalogMemoriesRenderer
extends Control

signal changed

var _memory_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_memory_controls.clear()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	var entries: Array = data.get("memories", []) if data.get("memories") is Array else []

	vbox.add_child(_make_header())
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		_memory_controls.append(_build_row(entry, row_panel))
		vbox.add_child(row_panel)


func get_data() -> Dictionary:
	var result: Array = []
	for ctrl: Dictionary in _memory_controls:
		result.append({
			"id": ctrl["id"],
			"displayName": (ctrl["name"] as LineEdit).text,
			"description": (ctrl["desc"] as LineEdit).text,
			"imagePath": (ctrl["path"] as LineEdit).text,
			"placeholderColor": (ctrl["color"] as LineEdit).text,
			"sortOrder": int((ctrl["sort"] as SpinBox).value),
			"unlockCost": int((ctrl["cost"] as SpinBox).value),
			"bonusStatType": AdminCatalogFormHelpers.get_enum_value(ctrl["stat_ob"] as OptionButton),
			"bonusValue": (ctrl["bonus"] as SpinBox).value,
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
		})
	return {"memories": result}


func _make_header() -> PanelContainer:
	var panel := AdminCatalogFormHelpers.make_header_row_panel()
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("顯示名稱"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("說明"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("圖片路徑"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("佔位色", 100.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("排序", 75.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("解鎖費用", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("加成屬性", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("加成值", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))
	return panel


func _build_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))
	var path_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("imagePath", "")))
	var color_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("placeholderColor", "#ffffff")), 100.0)
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 999, 75.0)
	var cost_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("unlockCost", 0)), 0, 999999, 90.0)
	var stat_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.STAT_TYPE_OPTIONS,
		str(entry.get("bonusStatType", "None"))
	)
	stat_ob.custom_minimum_size.x = 110.0
	stat_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var bonus_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("bonusValue", 0.0)), 0.001, 90.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	hb.add_child(name_edit)
	hb.add_child(desc_edit)
	hb.add_child(path_edit)
	hb.add_child(color_edit)
	hb.add_child(sort_spin)
	hb.add_child(cost_spin)
	hb.add_child(stat_ob)
	hb.add_child(bonus_spin)
	hb.add_child(enabled_cb)

	for node: Node in [name_edit, desc_edit, path_edit, color_edit]:
		_connect_change(node, "text_changed", func(_v: Variant) -> void: changed.emit())
	for node: Node in [sort_spin, cost_spin, bonus_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(stat_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return {
		"id": entry.get("id", 0),
		"name": name_edit, "desc": desc_edit,
		"path": path_edit, "color": color_edit,
		"sort": sort_spin, "cost": cost_spin,
		"stat_ob": stat_ob, "bonus": bonus_spin,
		"enabled": enabled_cb,
	}


static func _make_row_margin() -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 6)
	m.add_theme_constant_override("margin_right", 6)
	m.add_theme_constant_override("margin_top", 3)
	m.add_theme_constant_override("margin_bottom", 3)
	return m


static func _connect_change(node: Node, signal_name: String, callable: Callable) -> void:
	node.connect(signal_name, callable)
