class_name AdminCatalogCoreRenderer
extends Control

signal changed

var _currency_controls: Array = []
var _consumable_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_currency_controls.clear()
	_consumable_controls.clear()

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	tabs.add_child(_build_currency_tab(data.get("currencies", []) as Array))
	tabs.add_child(_build_consumable_tab(data.get("consumables", []) as Array))
	tabs.set_tab_title(0, "貨幣 (%d)" % (data.get("currencies", []) as Array).size())
	tabs.set_tab_title(1, "消耗品 (%d)" % (data.get("consumables", []) as Array).size())


func get_data() -> Dictionary:
	return {
		"currencies": _collect_currency_data(),
		"consumables": _collect_consumable_data(),
	}


# ── Currency Tab ──────────────────────────────────────────────

func _build_currency_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Currencies"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	vbox.add_child(_make_currency_header())
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		var row_controls := _build_currency_row(entry, row_panel)
		_currency_controls.append(row_controls)
		vbox.add_child(row_panel)

	return scroll


func _make_currency_header() -> PanelContainer:
	var panel := AdminCatalogFormHelpers.make_header_row_panel()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("顯示名稱"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("圖片路徑"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("說明"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("排序", 80.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))
	return panel


func _build_currency_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)

	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var path_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("imagePath", "")))
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)))
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	hb.add_child(name_edit)
	hb.add_child(path_edit)
	hb.add_child(desc_edit)
	hb.add_child(sort_spin)
	hb.add_child(enabled_cb)

	_connect_change(name_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(path_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(desc_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return {
		"id": entry.get("id", 0),
		"name_edit": name_edit,
		"path_edit": path_edit,
		"desc_edit": desc_edit,
		"sort_spin": sort_spin,
		"enabled_cb": enabled_cb,
	}


func _collect_currency_data() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _currency_controls:
		result.append({
			"id": ctrl["id"],
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"imagePath": (ctrl["path_edit"] as LineEdit).text,
			"description": (ctrl["desc_edit"] as LineEdit).text,
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})
	return result


# ── Consumable Tab ────────────────────────────────────────────

func _build_consumable_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Consumables"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	vbox.add_child(_make_consumable_header())
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		var row_controls := _build_consumable_row(entry, row_panel)
		_consumable_controls.append(row_controls)
		vbox.add_child(row_panel)

	return scroll


func _make_consumable_header() -> PanelContainer:
	var panel := AdminCatalogFormHelpers.make_header_row_panel()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("顯示名稱"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("分類"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("最大堆疊", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("圖片路徑"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("說明"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("排序", 80.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))
	return panel


func _build_consumable_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)

	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var cat_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.ITEM_CATEGORY_OPTIONS,
		str(entry.get("itemCategoryType", "None"))
	)
	var stack_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("maxStack", 1)), 1, 99999, 90.0)
	var path_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("imagePath", "")))
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)))
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	hb.add_child(name_edit)
	hb.add_child(cat_ob)
	hb.add_child(stack_spin)
	hb.add_child(path_edit)
	hb.add_child(desc_edit)
	hb.add_child(sort_spin)
	hb.add_child(enabled_cb)

	_connect_change(name_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(cat_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(stack_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(path_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(desc_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return {
		"id": entry.get("id", 0),
		"name_edit": name_edit,
		"cat_ob": cat_ob,
		"stack_spin": stack_spin,
		"path_edit": path_edit,
		"desc_edit": desc_edit,
		"sort_spin": sort_spin,
		"enabled_cb": enabled_cb,
	}


func _collect_consumable_data() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _consumable_controls:
		result.append({
			"id": ctrl["id"],
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"itemCategoryType": AdminCatalogFormHelpers.get_enum_value(ctrl["cat_ob"] as OptionButton),
			"maxStack": int((ctrl["stack_spin"] as SpinBox).value),
			"imagePath": (ctrl["path_edit"] as LineEdit).text,
			"description": (ctrl["desc_edit"] as LineEdit).text,
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})
	return result


# ── Helpers ───────────────────────────────────────────────────

static func _connect_change(node: Node, signal_name: String, callable: Callable) -> void:
	node.connect(signal_name, callable)
