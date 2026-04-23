class_name AdminCatalogAchievementsRenderer
extends Control

signal changed

var _achievement_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_achievement_controls.clear()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	var entries: Array = data.get("achievements", []) if data.get("achievements") is Array else []

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var ctrls := _build_achievement_block(entry, vbox, i % 2 == 0)
		_achievement_controls.append(ctrls)


func get_data() -> Dictionary:
	var result: Array = []
	for ctrl: Dictionary in _achievement_controls:
		var rewards_arr: Array = []
		for rc: Dictionary in (ctrl["reward_controls"] as Array):
			var dup_ob := rc["dup_type_ob"] as OptionButton
			var dup_type_str := AdminCatalogFormHelpers.get_enum_value(dup_ob)
			var dup_type_val: Variant = null if dup_type_str == "None" else dup_type_str
			var dup_qty_val: Variant = null if dup_type_str == "None" else int((rc["dup_qty"] as SpinBox).value)
			rewards_arr.append({
				"id": rc["id"],
				"rewardOrder": rc["order"],
				"rewardType": AdminCatalogFormHelpers.get_enum_value(rc["reward_ob"] as OptionButton),
				"quantity": int((rc["qty"] as SpinBox).value),
				"duplicateRewardType": dup_type_val,
				"duplicateRewardQuantity": dup_qty_val,
				"isEnabled": (rc["enabled"] as CheckBox).button_pressed,
			})
		result.append({
			"id": ctrl["id"],
			"displayName": (ctrl["name"] as LineEdit).text,
			"categoryType": AdminCatalogFormHelpers.get_enum_value(ctrl["category_ob"] as OptionButton),
			"sortOrder": int((ctrl["sort"] as SpinBox).value),
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
			"conditionType": AdminCatalogFormHelpers.get_enum_value(ctrl["condition_ob"] as OptionButton),
			"conditionValue": (ctrl["condition_val"] as LineEdit).text,
			"rewards": rewards_arr,
		})
	return {"achievements": result}


func _build_achievement_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block)

	var margin := _make_row_margin()
	block.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Main row 
	var main_hb := AdminCatalogFormHelpers.make_row_hbox()
	vbox.add_child(main_hb)

	main_hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))

	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var category_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.ACHIEVEMENT_CATEGORY_OPTIONS,
		str(entry.get("categoryType", "None"))
	)
	category_ob.custom_minimum_size.x = 100.0
	category_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var condition_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.ACHIEVEMENT_CONDITION_OPTIONS,
		str(entry.get("conditionType", "None"))
	)
	condition_ob.custom_minimum_size.x = 140.0
	condition_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var condition_val_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("conditionValue", "")), 80.0)
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 999, 75.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	_add_labeled(main_hb, "名稱:", name_edit)
	_add_labeled(main_hb, "類別:", category_ob)
	_add_labeled(main_hb, "條件:", condition_ob)
	_add_labeled(main_hb, "條件值:", condition_val_edit)
	_add_labeled(main_hb, "排序:", sort_spin)
	_add_labeled(main_hb, "啟用:", enabled_cb)

	for node: Node in [name_edit, condition_val_edit]:
		_connect_change(node, "text_changed", Callable(self, "_on_changed_value"))
	for node: Node in [category_ob, condition_ob]:
		_connect_change(node, "item_selected", Callable(self, "_on_changed_value"))
	_connect_change(sort_spin, "value_changed", Callable(self, "_on_changed_value"))
	_connect_change(enabled_cb, "toggled", Callable(self, "_on_changed_value"))

	# ── Rewards sub-table ─────────────────────────────────────
	var rewards: Array = entry.get("rewards", []) if entry.get("rewards") is Array else []
	var reward_controls := _build_rewards_subtable(rewards, vbox)

	return {
		"id": entry.get("id", 0),
		"name": name_edit,
		"category_ob": category_ob,
		"condition_ob": condition_ob,
		"condition_val": condition_val_edit,
		"sort": sort_spin,
		"enabled": enabled_cb,
		"reward_controls": reward_controls,
	}


func _build_rewards_subtable(rewards: Array, parent: VBoxContainer) -> Array:
	if rewards.is_empty():
		return []

	var sub_margin := MarginContainer.new()
	sub_margin.add_theme_constant_override("margin_left", 20)
	parent.add_child(sub_margin)

	var sub_vbox := VBoxContainer.new()
	sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_vbox.add_theme_constant_override("separation", 2)
	sub_margin.add_child(sub_vbox)

	# Header
	var header := AdminCatalogFormHelpers.make_header_row_panel()
	sub_vbox.add_child(header)
	var hm := _make_small_margin()
	header.add_child(hm)
	var h_hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(h_hb)
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("順序", 50.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("獎勵類型", 120.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("數量", 80.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("重複獎勵類型", 130.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("重複數量", 80.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var controls: Array = []
	for i: int in range(rewards.size()):
		var rw: Dictionary = rewards[i] if rewards[i] is Dictionary else {}

		var row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		sub_vbox.add_child(row)
		var rm := _make_small_margin()
		row.add_child(rm)
		var r_hb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(r_hb)

		# RewardOrder — readonly label
		var order_lbl := Label.new()
		order_lbl.text = "#%d" % int(rw.get("rewardOrder", i + 1))
		order_lbl.custom_minimum_size.x = 50.0
		order_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		order_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
		order_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		r_hb.add_child(order_lbl)

		# RewardType
		var reward_ob := AdminCatalogFormHelpers.make_enum_cell(
			AdminCatalogFormHelpers.REWARD_TYPE_OPTIONS,
			str(rw.get("rewardType", "None"))
		)
		reward_ob.custom_minimum_size.x = 120.0
		reward_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		# Quantity
		var qty_spin := AdminCatalogFormHelpers.make_int_cell(int(rw.get("quantity", 0)), 0, 999999, 80.0)

		# DuplicateRewardType — "None" when null
		var dup_type_raw: Variant = rw.get("duplicateRewardType", null)
		var dup_type_str := "None" if dup_type_raw == null else str(dup_type_raw)
		var dup_type_ob := AdminCatalogFormHelpers.make_enum_cell(
			AdminCatalogFormHelpers.REWARD_TYPE_OPTIONS,
			dup_type_str
		)
		dup_type_ob.custom_minimum_size.x = 130.0
		dup_type_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		# DuplicateRewardQuantity — 0 when null
		var dup_qty_raw: Variant = rw.get("duplicateRewardQuantity", null)
		var dup_qty_val := 0 if dup_qty_raw == null else int(dup_qty_raw)
		var dup_qty_spin := AdminCatalogFormHelpers.make_int_cell(dup_qty_val, 0, 999999, 80.0)

		var rw_enabled := AdminCatalogFormHelpers.make_bool_cell(bool(rw.get("isEnabled", true)))

		r_hb.add_child(reward_ob)
		r_hb.add_child(qty_spin)
		r_hb.add_child(dup_type_ob)
		r_hb.add_child(dup_qty_spin)
		r_hb.add_child(rw_enabled)

		for node: Node in [reward_ob, dup_type_ob]:
			_connect_change(node, "item_selected", Callable(self, "_on_changed_value"))
		for node: Node in [qty_spin, dup_qty_spin]:
			_connect_change(node, "value_changed", Callable(self, "_on_changed_value"))
		_connect_change(rw_enabled, "toggled", Callable(self, "_on_changed_value"))

		controls.append({
			"id": rw.get("id", 0),
			"order": int(rw.get("rewardOrder", i + 1)),
			"reward_ob": reward_ob,
			"qty": qty_spin,
			"dup_type_ob": dup_type_ob,
			"dup_qty": dup_qty_spin,
			"enabled": rw_enabled,
		})

	return controls


#  Layout Helpers 

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

func _on_changed_value(_value: Variant) -> void:
	changed.emit()
