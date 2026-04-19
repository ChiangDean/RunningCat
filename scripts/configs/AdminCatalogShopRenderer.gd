class_name AdminCatalogShopRenderer
extends Control

signal changed

var _category_controls: Array = []
var _group_controls: Array = []
var _bundle_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_category_controls.clear()
	_group_controls.clear()
	_bundle_controls.clear()

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	var categories: Array = data.get("categories", []) if data.get("categories") is Array else []
	var groups: Array = data.get("groups", []) if data.get("groups") is Array else []
	var bundles: Array = data.get("bundles", []) if data.get("bundles") is Array else []

	tabs.add_child(_build_categories_tab(categories))
	tabs.add_child(_build_groups_tab(groups))
	tabs.add_child(_build_bundles_tab(bundles))

	tabs.set_tab_title(0, "商品分類")
	tabs.set_tab_title(1, "商品群組")
	tabs.set_tab_title(2, "商品包 (%d)" % bundles.size())


func get_data() -> Dictionary:
	return {
		"categories": _collect_categories(),
		"groups": _collect_groups(),
		"bundles": _collect_bundles(),
	}


# ── Categories Tab ────────────────────────────────────────────

func _build_categories_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Categories"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	vbox.add_child(_make_category_header())
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		_category_controls.append(_build_category_row(entry, row_panel))
		vbox.add_child(row_panel)

	return scroll


func _make_category_header() -> PanelContainer:
	var panel := AdminCatalogFormHelpers.make_header_row_panel()
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("CategoryType"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("DisplayName"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("SortOrder", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("IsEnabled", 70.0, false))
	return panel


func _build_category_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var cat_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.SHOP_CATEGORY_OPTIONS,
		str(entry.get("categoryType", "None"))
	)
	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 9999, 90.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	hb.add_child(cat_ob)
	hb.add_child(name_edit)
	hb.add_child(sort_spin)
	hb.add_child(enabled_cb)

	_connect_change(cat_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(name_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return {
		"id": entry.get("id", 0),
		"cat_ob": cat_ob,
		"name_edit": name_edit,
		"sort_spin": sort_spin,
		"enabled_cb": enabled_cb,
	}


func _collect_categories() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _category_controls:
		result.append({
			"id": ctrl["id"],
			"categoryType": AdminCatalogFormHelpers.get_enum_value(ctrl["cat_ob"] as OptionButton),
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})
	return result


# ── Groups Tab ────────────────────────────────────────────────

func _build_groups_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Groups"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	vbox.add_child(_make_group_header())
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		_group_controls.append(_build_group_row(entry, row_panel))
		vbox.add_child(row_panel)

	return scroll


func _make_group_header() -> PanelContainer:
	var panel := AdminCatalogFormHelpers.make_header_row_panel()
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("CategoryType"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("GroupType"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("DisplayName"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("SortOrder", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("IsEnabled", 70.0, false))
	return panel


func _build_group_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var cat_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.SHOP_CATEGORY_OPTIONS,
		str(entry.get("categoryType", "None"))
	)
	var group_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.SHOP_GROUP_OPTIONS,
		str(entry.get("groupType", "None"))
	)
	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 9999, 90.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	hb.add_child(cat_ob)
	hb.add_child(group_ob)
	hb.add_child(name_edit)
	hb.add_child(sort_spin)
	hb.add_child(enabled_cb)

	_connect_change(cat_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(group_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(name_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return {
		"id": entry.get("id", 0),
		"cat_ob": cat_ob,
		"group_ob": group_ob,
		"name_edit": name_edit,
		"sort_spin": sort_spin,
		"enabled_cb": enabled_cb,
	}


func _collect_groups() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _group_controls:
		result.append({
			"id": ctrl["id"],
			"categoryType": AdminCatalogFormHelpers.get_enum_value(ctrl["cat_ob"] as OptionButton),
			"groupType": AdminCatalogFormHelpers.get_enum_value(ctrl["group_ob"] as OptionButton),
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})
	return result


# ── Bundles Tab ───────────────────────────────────────────────

func _build_bundles_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Bundles"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var ctrls := _build_bundle_block(entry, vbox, i % 2 == 0)
		_bundle_controls.append(ctrls)

	return scroll


func _build_bundle_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block)

	var margin := _make_row_margin()
	block.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Row 1: Id | DisplayName | Description | CategoryType | GroupType | IsEnabled
	var row1 := AdminCatalogFormHelpers.make_row_hbox()
	vbox.add_child(row1)

	row1.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))

	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))
	var cat_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.SHOP_CATEGORY_OPTIONS,
		str(entry.get("categoryType", "None"))
	)
	var group_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.SHOP_GROUP_OPTIONS,
		str(entry.get("groupType", "None"))
	)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	row1.add_child(name_edit)
	row1.add_child(desc_edit)
	row1.add_child(cat_ob)
	row1.add_child(group_ob)
	row1.add_child(enabled_cb)

	# Row 2: PriceCurrencyId | PriceAmount | DiscountPercent | PurchaseLimit | SortOrder
	var row2 := AdminCatalogFormHelpers.make_row_hbox()
	vbox.add_child(row2)

	var currency_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("priceCurrencyId", 1)), 1, 9999, 110.0)
	var amount_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("priceAmount", 0)), 0, 9999999, 110.0)
	var discount_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("discountPercent", 0)), 0, 100, 100.0)
	var limit_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("purchaseLimit", 0)), 0, 9999, 100.0)
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 9999, 90.0)

	var _add_labeled_row2 := func(label_text: String, ctrl: Control) -> void:
		var lbl := Label.new()
		lbl.text = label_text
		lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row2.add_child(lbl)
		row2.add_child(ctrl)

	_add_labeled_row2.call("幣種:", currency_spin)
	_add_labeled_row2.call("價格:", amount_spin)
	_add_labeled_row2.call("折扣%:", discount_spin)
	_add_labeled_row2.call("購買上限:", limit_spin)
	_add_labeled_row2.call("排序:", sort_spin)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(spacer)

	# Connect signals
	for node: Node in [name_edit, desc_edit]:
		_connect_change(node, "text_changed", func(_v: Variant) -> void: changed.emit())
	for node: Node in [cat_ob, group_ob]:
		_connect_change(node, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())
	for node: Node in [currency_spin, amount_spin, discount_spin, limit_spin, sort_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())

	# Rewards sub-table
	var rewards: Array = entry.get("rewards", []) if entry.get("rewards") is Array else []
	var reward_controls := _build_rewards_subtable(rewards, vbox)

	return {
		"id": entry.get("id", 0),
		"name_edit": name_edit,
		"desc_edit": desc_edit,
		"cat_ob": cat_ob,
		"group_ob": group_ob,
		"enabled_cb": enabled_cb,
		"currency_spin": currency_spin,
		"amount_spin": amount_spin,
		"discount_spin": discount_spin,
		"limit_spin": limit_spin,
		"sort_spin": sort_spin,
		"reward_controls": reward_controls,
	}


func _build_rewards_subtable(rewards: Array, parent: VBoxContainer) -> Array:
	if rewards.is_empty():
		return []

	var reward_margin := MarginContainer.new()
	reward_margin.add_theme_constant_override("margin_left", 20)
	reward_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(reward_margin)

	var reward_vbox := VBoxContainer.new()
	reward_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_vbox.add_theme_constant_override("separation", 2)
	reward_margin.add_child(reward_vbox)

	# Rewards header
	var rh_panel := AdminCatalogFormHelpers.make_header_row_panel()
	reward_vbox.add_child(rh_panel)
	var rh_margin := _make_small_margin()
	rh_panel.add_child(rh_margin)
	var rh_hb := AdminCatalogFormHelpers.make_row_hbox()
	rh_margin.add_child(rh_hb)
	rh_hb.add_child(AdminCatalogFormHelpers.make_col_header("Order", 60.0, false))
	rh_hb.add_child(AdminCatalogFormHelpers.make_col_header("RewardType"))
	rh_hb.add_child(AdminCatalogFormHelpers.make_col_header("RefId (0=null)", 110.0, false))
	rh_hb.add_child(AdminCatalogFormHelpers.make_col_header("Quantity", 90.0, false))
	rh_hb.add_child(AdminCatalogFormHelpers.make_col_header("IsEnabled", 70.0, false))

	var reward_controls: Array = []
	for i: int in range(rewards.size()):
		var rw: Dictionary = rewards[i] if rewards[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		reward_vbox.add_child(row_panel)
		var rm := _make_small_margin()
		row_panel.add_child(rm)
		var r_hb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(r_hb)

		var order_lbl := Label.new()
		order_lbl.text = "#%d" % int(rw.get("rewardOrder", i + 1))
		order_lbl.custom_minimum_size.x = 60.0
		order_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		order_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
		order_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var ref_id_raw: Variant = rw.get("rewardReferenceId", null)
		var ref_id_val: int = int(ref_id_raw) if ref_id_raw != null else 0

		var type_ob := AdminCatalogFormHelpers.make_enum_cell(
			AdminCatalogFormHelpers.REWARD_TYPE_OPTIONS,
			str(rw.get("rewardType", "None"))
		)
		var ref_spin := AdminCatalogFormHelpers.make_int_cell(ref_id_val, 0, 9999999, 110.0)
		var qty_spin := AdminCatalogFormHelpers.make_int_cell(int(rw.get("quantity", 0)), 0, 9999999, 90.0)
		var rw_enabled := AdminCatalogFormHelpers.make_bool_cell(bool(rw.get("isEnabled", true)))

		r_hb.add_child(order_lbl)
		r_hb.add_child(type_ob)
		r_hb.add_child(ref_spin)
		r_hb.add_child(qty_spin)
		r_hb.add_child(rw_enabled)

		_connect_change(type_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(ref_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(qty_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(rw_enabled, "toggled", func(_v: Variant) -> void: changed.emit())

		reward_controls.append({
			"id": rw.get("id", 0),
			"reward_order": int(rw.get("rewardOrder", i + 1)),
			"type_ob": type_ob,
			"ref_spin": ref_spin,
			"qty_spin": qty_spin,
			"enabled_cb": rw_enabled,
		})

	return reward_controls


func _collect_bundles() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _bundle_controls:
		var rewards_arr: Array = []
		for rc: Dictionary in (ctrl["reward_controls"] as Array):
			var ref_val: int = int((rc["ref_spin"] as SpinBox).value)
			rewards_arr.append({
				"id": rc["id"],
				"rewardOrder": rc["reward_order"],
				"rewardType": AdminCatalogFormHelpers.get_enum_value(rc["type_ob"] as OptionButton),
				"rewardReferenceId": null if ref_val == 0 else ref_val,
				"quantity": int((rc["qty_spin"] as SpinBox).value),
				"isEnabled": (rc["enabled_cb"] as CheckBox).button_pressed,
			})
		result.append({
			"id": ctrl["id"],
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"description": (ctrl["desc_edit"] as LineEdit).text,
			"categoryType": AdminCatalogFormHelpers.get_enum_value(ctrl["cat_ob"] as OptionButton),
			"groupType": AdminCatalogFormHelpers.get_enum_value(ctrl["group_ob"] as OptionButton),
			"priceCurrencyId": int((ctrl["currency_spin"] as SpinBox).value),
			"priceAmount": int((ctrl["amount_spin"] as SpinBox).value),
			"discountPercent": int((ctrl["discount_spin"] as SpinBox).value),
			"purchaseLimit": int((ctrl["limit_spin"] as SpinBox).value),
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
			"rewards": rewards_arr,
		})
	return result


# ── Layout Helpers ────────────────────────────────────────────

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
