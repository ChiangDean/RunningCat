class_name AdminCatalogCombatPowerRenderer
extends Control

signal changed

var _weight_controls: Array[Dictionary] = []
var _rows_box: VBoxContainer


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_weight_controls.clear()

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	root.add_child(action_row)

	var add_button: Button = Button.new()
	add_button.text = "新增權重"
	add_button.custom_minimum_size = Vector2(120.0, 38.0)
	UiPalette.apply_button_kind(add_button, "confirm")
	add_button.pressed.connect(_on_add_weight_pressed)
	action_row.add_child(add_button)

	var hint_label: Label = Label.new()
	hint_label.text = "每列代表一種會換算戰力的屬性。生命 +20% 會先放大生命值，再用生命權重計分。"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	hint_label.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	action_row.add_child(hint_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 2)
	scroll.add_child(_rows_box)

	_rows_box.add_child(_make_header())
	_rows_box.add_child(AdminCatalogFormHelpers.make_separator())

	var entries: Array = data.get("weights", []) if data.get("weights") is Array else []
	for index: int in range(entries.size()):
		var entry: Dictionary = entries[index] if entries[index] is Dictionary else {}
		_add_weight_row(entry, index)


func get_data() -> Dictionary:
	var result: Array = []
	for ctrl: Dictionary in _weight_controls:
		result.append({
			"id": ctrl["id"],
			"statType": AdminCatalogFormHelpers.get_enum_value(ctrl["stat"] as OptionButton),
			"flatWeight": (ctrl["flat"] as SpinBox).value,
			"percentWeight": (ctrl["percent"] as SpinBox).value,
			"baseOffset": (ctrl["offset"] as SpinBox).value,
			"sortOrder": int((ctrl["sort"] as SpinBox).value),
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
			"description": (ctrl["desc"] as LineEdit).text,
		})
	return {"weights": result}


func _make_header() -> PanelContainer:
	var panel: PanelContainer = AdminCatalogFormHelpers.make_header_row_panel()
	var margin: MarginContainer = _make_row_margin()
	panel.add_child(margin)
	var row: HBoxContainer = AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(row)
	row.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	row.add_child(AdminCatalogFormHelpers.make_col_header("屬性", 130.0, false))
	row.add_child(AdminCatalogFormHelpers.make_col_header("固定權重", 100.0, false))
	row.add_child(AdminCatalogFormHelpers.make_col_header("百分比權重", 110.0, false))
	row.add_child(AdminCatalogFormHelpers.make_col_header("基礎分", 90.0, false))
	row.add_child(AdminCatalogFormHelpers.make_col_header("排序", 75.0, false))
	row.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))
	row.add_child(AdminCatalogFormHelpers.make_col_header("說明"))
	return panel


func _add_weight_row(entry: Dictionary, index: int) -> void:
	var panel: PanelContainer = AdminCatalogFormHelpers.make_data_row_panel(index % 2 == 0)
	_rows_box.add_child(panel)

	var margin: MarginContainer = _make_row_margin()
	panel.add_child(margin)
	var row: HBoxContainer = AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(row)

	var stat_ob: OptionButton = AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.STAT_TYPE_OPTIONS,
		str(entry.get("statType", "None"))
	)
	stat_ob.custom_minimum_size.x = 130.0
	stat_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var flat_spin: SpinBox = AdminCatalogFormHelpers.make_float_cell(float(entry.get("flatWeight", 0.0)), 0.001, 100.0)
	var percent_spin: SpinBox = AdminCatalogFormHelpers.make_float_cell(float(entry.get("percentWeight", 0.0)), 0.001, 110.0)
	var offset_spin: SpinBox = AdminCatalogFormHelpers.make_float_cell(float(entry.get("baseOffset", 0.0)), 0.001, 90.0)
	var sort_spin: SpinBox = AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", (index + 1) * 10)), 0, 9999, 75.0)
	var enabled_cb: CheckBox = AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))
	var desc_edit: LineEdit = AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))

	row.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	row.add_child(stat_ob)
	row.add_child(flat_spin)
	row.add_child(percent_spin)
	row.add_child(offset_spin)
	row.add_child(sort_spin)
	row.add_child(enabled_cb)
	row.add_child(desc_edit)

	for node: Node in [stat_ob]:
		_connect_change(node, "item_selected", func(_v: Variant) -> void: changed.emit())
	for node: Node in [flat_spin, percent_spin, offset_spin, sort_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())
	_connect_change(desc_edit, "text_changed", func(_v: Variant) -> void: changed.emit())

	_weight_controls.append({
		"id": entry.get("id", 0),
		"stat": stat_ob,
		"flat": flat_spin,
		"percent": percent_spin,
		"offset": offset_spin,
		"sort": sort_spin,
		"enabled": enabled_cb,
		"desc": desc_edit,
	})


func _on_add_weight_pressed() -> void:
	var sort_order: int = (_weight_controls.size() + 1) * 10
	_add_weight_row({
		"id": 0,
		"statType": "None",
		"flatWeight": 0.0,
		"percentWeight": 0.0,
		"baseOffset": 0.0,
		"sortOrder": sort_order,
		"isEnabled": true,
		"description": "",
	}, _weight_controls.size())
	changed.emit()


static func _make_row_margin() -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	return margin


static func _connect_change(node: Node, signal_name: String, callable: Callable) -> void:
	node.connect(signal_name, callable)
