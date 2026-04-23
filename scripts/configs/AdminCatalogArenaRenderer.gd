class_name AdminCatalogArenaRenderer
extends Control

signal changed

var _setting_ctrls: Dictionary = {}
var _purchase_cost_controls: Array = []
var _rank_controls: Array = []
var _bot_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_setting_ctrls.clear()
	_purchase_cost_controls.clear()
	_rank_controls.clear()
	_bot_controls.clear()

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	var setting: Dictionary = data.get("setting", {}) if data.get("setting") is Dictionary else {}
	var ranks: Array = data.get("ranks", []) if data.get("ranks") is Array else []
	var bots: Array = data.get("bots", []) if data.get("bots") is Array else []

	tabs.add_child(_build_setting_tab(setting))
	tabs.add_child(_build_ranks_tab(ranks))
	tabs.add_child(_build_bots_tab(bots))

	tabs.set_tab_title(0, "全域設定")
	tabs.set_tab_title(1, "段位 (%d)" % ranks.size())
	tabs.set_tab_title(2, "Bot (%d)" % bots.size())


func get_data() -> Dictionary:
	return {
		"setting": _collect_setting(),
		"ranks": _collect_ranks(),
		"bots": _collect_bots(),
	}


#  Setting Tab

func _build_setting_tab(s: Dictionary) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Setting"

	var margin := _make_form_margin()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	vbox.add_child(AdminCatalogFormHelpers.make_section_label("競技場全域設定"))
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	var free_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("dailyFreeTickets", 0)), 0, 999, 120.0)
	var max_purch_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("maxDailyPurchases", 0)), 0, 999, 120.0)
	var per_purch_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("ticketsPerPurchase", 0)), 0, 99, 120.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(s.get("isEnabled", true)), 0.0)

	vbox.add_child(AdminCatalogFormHelpers.make_form_row("每日免費票券", free_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("每日最大購買次數", max_purch_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("每次購買票券數", per_purch_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("啟用", enabled_cb))

	vbox.add_child(AdminCatalogFormHelpers.make_separator())
	vbox.add_child(AdminCatalogFormHelpers.make_section_label("購票費用（依購買次序）"))

	var costs: Array = s.get("purchaseCosts", []) if s.get("purchaseCosts") is Array else []
	for i: int in range(costs.size()):
		var cost: Dictionary = costs[i] if costs[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		var ctrls := _build_cost_row(cost, row_panel, i)
		_purchase_cost_controls.append(ctrls)
		vbox.add_child(row_panel)

	_setting_ctrls = {
		"id": s.get("id", 0),
		"free": free_spin, "max_purch": max_purch_spin,
		"per_purch": per_purch_spin, "enabled": enabled_cb,
	}

	for node: Node in [free_spin, max_purch_spin, per_purch_spin]:
		_connect_change(node, "value_changed", Callable(self, "_on_changed_value"))
	_connect_change(enabled_cb, "toggled", Callable(self, "_on_changed_value"))

	return scroll


func _build_cost_row(cost: Dictionary, panel: PanelContainer, idx: int) -> Dictionary:
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var order_lbl := Label.new()
	order_lbl.text = "第 %d 次" % (idx + 1)
	order_lbl.custom_minimum_size.x = 70.0
	order_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	order_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	order_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(order_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "鑽石費用："
	cost_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	cost_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(cost_lbl)

	var diamond_spin := AdminCatalogFormHelpers.make_int_cell(int(cost.get("diamondCost", 0)), 0, 999999, 100.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(cost.get("isEnabled", true)))

	hb.add_child(diamond_spin)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(spacer)

	var en_lbl := Label.new()
	en_lbl.text = "啟用"
	en_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	en_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	en_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(en_lbl)
	hb.add_child(enabled_cb)

	_connect_change(diamond_spin, "value_changed", Callable(self, "_on_changed_value"))
	_connect_change(enabled_cb, "toggled", Callable(self, "_on_changed_value"))

	return {
		"id": cost.get("id", 0),
		"order": int(cost.get("purchaseOrder", idx + 1)),
		"diamond": diamond_spin,
		"enabled": enabled_cb,
	}


func _collect_setting() -> Dictionary:
	var costs_arr: Array = []
	for ctrl: Dictionary in _purchase_cost_controls:
		costs_arr.append({
			"id": ctrl["id"],
			"purchaseOrder": ctrl["order"],
			"diamondCost": int((ctrl["diamond"] as SpinBox).value),
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
		})
	return {
		"id": _setting_ctrls.get("id", 0),
		"dailyFreeTickets": int((_setting_ctrls["free"] as SpinBox).value),
		"maxDailyPurchases": int((_setting_ctrls["max_purch"] as SpinBox).value),
		"ticketsPerPurchase": int((_setting_ctrls["per_purch"] as SpinBox).value),
		"isEnabled": (_setting_ctrls["enabled"] as CheckBox).button_pressed,
		"purchaseCosts": costs_arr,
	}


#  Ranks Tab 

func _build_ranks_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Ranks"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	vbox.add_child(_make_rank_header())
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		_rank_controls.append(_build_rank_row(entry, row_panel))
		vbox.add_child(row_panel)

	return scroll


func _make_rank_header() -> PanelContainer:
	var panel := AdminCatalogFormHelpers.make_header_row_panel()
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Key"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("顯示名稱"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("最低分", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("最高分", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("圖片路徑"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("排序", 80.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))
	return panel


func _build_rank_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var key_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("rankKey", "")))
	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var min_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("scoreMin", 0)), 0, 999999, 90.0)
	var max_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("scoreMax", 0)), 0, 999999, 90.0)
	var path_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("imagePath", "")))
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 99, 80.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	hb.add_child(key_edit)
	hb.add_child(name_edit)
	hb.add_child(min_spin)
	hb.add_child(max_spin)
	hb.add_child(path_edit)
	hb.add_child(sort_spin)
	hb.add_child(enabled_cb)

	for node: Node in [key_edit, name_edit, path_edit]:
		_connect_change(node, "text_changed", Callable(self, "_on_changed_value"))
	for node: Node in [min_spin, max_spin, sort_spin]:
		_connect_change(node, "value_changed", Callable(self, "_on_changed_value"))
	_connect_change(enabled_cb, "toggled", Callable(self, "_on_changed_value"))

	return {
		"id": entry.get("id", 0),
		"key": key_edit, "name": name_edit,
		"min": min_spin, "max": max_spin,
		"path": path_edit, "sort": sort_spin, "enabled": enabled_cb,
	}


func _collect_ranks() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _rank_controls:
		result.append({
			"id": ctrl["id"],
			"rankKey": (ctrl["key"] as LineEdit).text,
			"displayName": (ctrl["name"] as LineEdit).text,
			"scoreMin": int((ctrl["min"] as SpinBox).value),
			"scoreMax": int((ctrl["max"] as SpinBox).value),
			"imagePath": (ctrl["path"] as LineEdit).text,
			"sortOrder": int((ctrl["sort"] as SpinBox).value),
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
		})
	return result


#  Bots Tab 

func _build_bots_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Bots"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var ctrls := _build_bot_block(entry, vbox, i % 2 == 0)
		_bot_controls.append(ctrls)

	return scroll


func _build_bot_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block)

	var margin := _make_row_margin()
	block.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Bot main row
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	vbox.add_child(hb)

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))

	var key_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("botKey", "")))
	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var offset_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("scoreOffset", 0)), -9999, 99999, 90.0)
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 99, 80.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	var key_lbl := Label.new()
	key_lbl.text = "Key:"
	key_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	key_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	key_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(key_lbl)
	hb.add_child(key_edit)

	var name_lbl := Label.new()
	name_lbl.text = "名稱:"
	name_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	name_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(name_lbl)
	hb.add_child(name_edit)

	var offset_lbl := Label.new()
	offset_lbl.text = "分數偏移:"
	offset_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	offset_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	offset_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(offset_lbl)
	hb.add_child(offset_spin)

	var sort_lbl := Label.new()
	sort_lbl.text = "排序:"
	sort_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	sort_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	sort_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(sort_lbl)
	hb.add_child(sort_spin)

	var en_lbl := Label.new()
	en_lbl.text = "啟用:"
	en_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	en_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	en_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(en_lbl)
	hb.add_child(enabled_cb)

	for node: Node in [key_edit, name_edit]:
		_connect_change(node, "text_changed", Callable(self, "_on_changed_value"))
	for node: Node in [offset_spin, sort_spin]:
		_connect_change(node, "value_changed", Callable(self, "_on_changed_value"))
	_connect_change(enabled_cb, "toggled", Callable(self, "_on_changed_value"))

	# Members sub-section
	var members: Array = entry.get("members", []) if entry.get("members") is Array else []
	var member_controls := _build_members_subtable(members, vbox)

	return {
		"id": entry.get("id", 0),
		"key": key_edit, "name": name_edit,
		"offset": offset_spin, "sort": sort_spin, "enabled": enabled_cb,
		"member_controls": member_controls,
	}


func _build_members_subtable(members: Array, parent: VBoxContainer) -> Array:
	if members.is_empty():
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
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Slot", 60.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Cat Id", 100.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var controls: Array = []
	for i: int in range(members.size()):
		var m: Dictionary = members[i] if members[i] is Dictionary else {}
		var row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		sub_vbox.add_child(row)
		var rm := _make_small_margin()
		row.add_child(rm)
		var r_hb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(r_hb)

		var slot_lbl := Label.new()
		slot_lbl.text = "Slot %d" % int(m.get("slotNo", i + 1))
		slot_lbl.custom_minimum_size.x = 60.0
		slot_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		slot_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
		slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		r_hb.add_child(slot_lbl)

		var cat_spin := AdminCatalogFormHelpers.make_int_cell(int(m.get("catId", 0)), 0, 999999, 100.0)
		var m_enabled := AdminCatalogFormHelpers.make_bool_cell(bool(m.get("isEnabled", true)))
		r_hb.add_child(cat_spin)
		r_hb.add_child(m_enabled)

		_connect_change(cat_spin, "value_changed", Callable(self, "_on_changed_value"))
		_connect_change(m_enabled, "toggled", Callable(self, "_on_changed_value"))

		controls.append({
			"id": m.get("id", 0),
			"slot": int(m.get("slotNo", i + 1)),
			"cat_spin": cat_spin,
			"enabled": m_enabled,
		})

	return controls


func _collect_bots() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _bot_controls:
		var members_arr: Array = []
		for mc: Dictionary in (ctrl["member_controls"] as Array):
			members_arr.append({
				"id": mc["id"],
				"catId": int((mc["cat_spin"] as SpinBox).value),
				"slotNo": mc["slot"],
				"isEnabled": (mc["enabled"] as CheckBox).button_pressed,
			})
		result.append({
			"id": ctrl["id"],
			"botKey": (ctrl["key"] as LineEdit).text,
			"displayName": (ctrl["name"] as LineEdit).text,
			"scoreOffset": int((ctrl["offset"] as SpinBox).value),
			"sortOrder": int((ctrl["sort"] as SpinBox).value),
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
			"members": members_arr,
		})
	return result


#  Layout Helpers 

static func _make_form_margin() -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	return m


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

func _on_changed_value(_value: Variant) -> void:
	changed.emit()
