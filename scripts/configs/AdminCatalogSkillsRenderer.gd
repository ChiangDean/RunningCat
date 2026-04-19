class_name AdminCatalogSkillsRenderer
extends Control

signal changed

# ── State ────────────────────────────────────────────────────────

var _skill_controls: Array = []


# ── Public API ───────────────────────────────────────────────────

func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_skill_controls.clear()

	var skills: Array = data.get("skills", []) if data.get("skills") is Array else []

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	for i: int in range(skills.size()):
		var entry: Dictionary = skills[i] if skills[i] is Dictionary else {}
		var ctrls := _build_skill_block(entry, vbox, i % 2 == 0)
		_skill_controls.append(ctrls)


func get_data() -> Dictionary:
	return {"skills": _collect_skills()}


# ── Skill Block ───────────────────────────────────────────────────

func _build_skill_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block_panel := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block_panel)

	var block_margin := _make_row_margin()
	block_panel.add_child(block_margin)

	var block_vbox := VBoxContainer.new()
	block_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block_vbox.add_theme_constant_override("separation", 4)
	block_margin.add_child(block_vbox)

	# ── Main Row ──────────────────────────────────────────────────
	var main_hb := AdminCatalogFormHelpers.make_row_hbox()
	block_vbox.add_child(main_hb)

	var skill_key_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("skillKey", "")))
	var display_name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var stype_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.SKILL_TYPE_OPTIONS, str(entry.get("skillType", "Active")))
	var cooldown_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("cooldownSeconds", 0)), 0, 99999, 90.0)
	var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)), 60.0)
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))

	main_hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	main_hb.add_child(_add_labeled("Key", skill_key_edit))
	main_hb.add_child(_add_labeled("顯示名稱", display_name_edit))
	main_hb.add_child(_add_labeled("技能類型", stype_ob))
	main_hb.add_child(_add_labeled("冷卻(秒)", cooldown_spin))
	main_hb.add_child(_add_labeled("啟用", en_cb))
	main_hb.add_child(_add_labeled("描述", desc_edit))

	_connect_change(stype_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(cooldown_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	for edit: Node in [skill_key_edit, display_name_edit, desc_edit]:
		_connect_change(edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# ── Effects Sub-table ─────────────────────────────────────────
	var effects: Array = entry.get("effects", []) if entry.get("effects") is Array else []
	var effect_controls := _build_effects_subtable(effects, block_vbox)

	# ── RankScaling Sub-table ─────────────────────────────────────
	var rank_scaling: Array = entry.get("rankScaling", []) if entry.get("rankScaling") is Array else []
	var rank_controls := _build_rank_scaling_subtable(rank_scaling, block_vbox)

	return {
		"id": entry.get("id", 0),
		"skill_key_edit": skill_key_edit,
		"display_name_edit": display_name_edit,
		"stype_ob": stype_ob,
		"cooldown_spin": cooldown_spin,
		"enabled_cb": en_cb,
		"desc_edit": desc_edit,
		"effect_controls": effect_controls,
		"rank_controls": rank_controls,
	}


func _build_effects_subtable(effects: Array, parent: VBoxContainer) -> Array:
	var sub_margin := MarginContainer.new()
	sub_margin.add_theme_constant_override("margin_left", 20)
	parent.add_child(sub_margin)

	var sub_vbox := VBoxContainer.new()
	sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_vbox.add_theme_constant_override("separation", 2)
	sub_margin.add_child(sub_vbox)

	var label := AdminCatalogFormHelpers.make_section_label("技能效果")
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	sub_vbox.add_child(label)

	var header := AdminCatalogFormHelpers.make_header_row_panel()
	sub_vbox.add_child(header)
	var hm := _make_small_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("順序", 60.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("目標範圍"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("效果類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("能力類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("數值模式"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("基礎值", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("持續時間", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("最大疊加", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var result: Array = []
	for i: int in range(effects.size()):
		var eff: Dictionary = effects[i] if effects[i] is Dictionary else {}
		var row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		sub_vbox.add_child(row)
		var rm := _make_small_margin()
		row.add_child(rm)
		var rb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(rb)

		var order_spin := AdminCatalogFormHelpers.make_int_cell(int(eff.get("effectOrder", 1)), 1, 99, 60.0)
		var scope_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.TARGET_SCOPE_OPTIONS, str(eff.get("targetScopeType", "Self")))
		var etype_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.SKILL_EFFECT_TYPE_OPTIONS, str(eff.get("effectType", "Damage")))
		# statType may be null — treat null as "None"
		var stat_str := str(eff.get("statType", "None")) if eff.get("statType") != null else "None"
		var stat_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.STAT_TYPE_OPTIONS, stat_str)
		var vtype_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.VALUE_MODE_OPTIONS, str(eff.get("valueType", "Flat")))
		var base_spin := AdminCatalogFormHelpers.make_float_cell(float(eff.get("baseValue", 0.0)), 0.001, 90.0)
		# durationSeconds: null → 0
		var dur_val: float = float(eff.get("durationSeconds", 0.0)) if eff.get("durationSeconds") != null else 0.0
		var dur_spin := AdminCatalogFormHelpers.make_float_cell(dur_val, 0.1, 90.0)
		# maxStack: null → 0
		var stack_val: int = int(eff.get("maxStack", 0)) if eff.get("maxStack") != null else 0
		var stack_spin := AdminCatalogFormHelpers.make_int_cell(stack_val, 0, 999, 90.0)
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(eff.get("isEnabled", true)), 60.0)

		rb.add_child(order_spin)
		rb.add_child(scope_ob)
		rb.add_child(etype_ob)
		rb.add_child(stat_ob)
		rb.add_child(vtype_ob)
		rb.add_child(base_spin)
		rb.add_child(dur_spin)
		rb.add_child(stack_spin)
		rb.add_child(en_cb)

		for node: Node in [order_spin, base_spin, dur_spin, stack_spin]:
			_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
		for ob: Node in [scope_ob, etype_ob, stat_ob, vtype_ob]:
			_connect_change(ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		result.append({
			"id": eff.get("id", 0),
			"order_spin": order_spin,
			"scope_ob": scope_ob,
			"etype_ob": etype_ob,
			"stat_ob": stat_ob,
			"vtype_ob": vtype_ob,
			"base_spin": base_spin,
			"dur_spin": dur_spin,
			"stack_spin": stack_spin,
			"enabled_cb": en_cb,
		})
	return result


func _build_rank_scaling_subtable(scalings: Array, parent: VBoxContainer) -> Array:
	var sub_margin := MarginContainer.new()
	sub_margin.add_theme_constant_override("margin_left", 20)
	parent.add_child(sub_margin)

	var sub_vbox := VBoxContainer.new()
	sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_vbox.add_theme_constant_override("separation", 2)
	sub_margin.add_child(sub_vbox)

	var label := AdminCatalogFormHelpers.make_section_label("階級縮放")
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	sub_vbox.add_child(label)

	var header := AdminCatalogFormHelpers.make_header_row_panel()
	sub_vbox.add_child(header)
	var hm := _make_small_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("階級", 70.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("效果順序", 80.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("縮放類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("縮放值", 100.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var result: Array = []
	for i: int in range(scalings.size()):
		var sc: Dictionary = scalings[i] if scalings[i] is Dictionary else {}
		var row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		sub_vbox.add_child(row)
		var rm := _make_small_margin()
		row.add_child(rm)
		var rb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(rb)

		var rank_spin := AdminCatalogFormHelpers.make_int_cell(int(sc.get("rank", 1)), 1, 99, 70.0)
		var effect_order_spin := AdminCatalogFormHelpers.make_int_cell(int(sc.get("effectOrder", 1)), 1, 99, 80.0)
		var scaling_type_edit := AdminCatalogFormHelpers.make_text_cell(str(sc.get("scalingType", "")))
		var scaling_val_spin := AdminCatalogFormHelpers.make_float_cell(float(sc.get("scalingValue", 1.0)), 0.001, 100.0)
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(sc.get("isEnabled", true)), 60.0)

		rb.add_child(rank_spin)
		rb.add_child(effect_order_spin)
		rb.add_child(scaling_type_edit)
		rb.add_child(scaling_val_spin)
		rb.add_child(en_cb)

		for node: Node in [rank_spin, effect_order_spin, scaling_val_spin]:
			_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(scaling_type_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		result.append({
			"id": sc.get("id", 0),
			"rank_spin": rank_spin,
			"effect_order_spin": effect_order_spin,
			"scaling_type_edit": scaling_type_edit,
			"scaling_val_spin": scaling_val_spin,
			"enabled_cb": en_cb,
		})
	return result


# ── Collect ──────────────────────────────────────────────────────

func _collect_skills() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _skill_controls:
		var effects_arr: Array = []
		for ec: Dictionary in (ctrl["effect_controls"] as Array):
			# statType: "None" key → null
			var stat_key := AdminCatalogFormHelpers.get_enum_value(ec["stat_ob"] as OptionButton)
			var stat_out: Variant = null if stat_key == "None" else stat_key
			# durationSeconds: 0 → null
			var dur_val: float = (ec["dur_spin"] as SpinBox).value
			var dur_out: Variant = null if dur_val == 0.0 else dur_val
			# maxStack: 0 → null
			var stack_val: int = int((ec["stack_spin"] as SpinBox).value)
			var stack_out: Variant = null if stack_val == 0 else stack_val
			effects_arr.append({
				"id": ec["id"],
				"effectOrder": int((ec["order_spin"] as SpinBox).value),
				"targetScopeType": AdminCatalogFormHelpers.get_enum_value(ec["scope_ob"] as OptionButton),
				"effectType": AdminCatalogFormHelpers.get_enum_value(ec["etype_ob"] as OptionButton),
				"statType": stat_out,
				"valueType": AdminCatalogFormHelpers.get_enum_value(ec["vtype_ob"] as OptionButton),
				"baseValue": (ec["base_spin"] as SpinBox).value,
				"durationSeconds": dur_out,
				"maxStack": stack_out,
				"isEnabled": (ec["enabled_cb"] as CheckBox).button_pressed,
			})
		var rank_arr: Array = []
		for rc: Dictionary in (ctrl["rank_controls"] as Array):
			rank_arr.append({
				"id": rc["id"],
				"rank": int((rc["rank_spin"] as SpinBox).value),
				"effectOrder": int((rc["effect_order_spin"] as SpinBox).value),
				"scalingType": (rc["scaling_type_edit"] as LineEdit).text,
				"scalingValue": (rc["scaling_val_spin"] as SpinBox).value,
				"isEnabled": (rc["enabled_cb"] as CheckBox).button_pressed,
			})
		result.append({
			"id": ctrl["id"],
			"skillKey": (ctrl["skill_key_edit"] as LineEdit).text,
			"displayName": (ctrl["display_name_edit"] as LineEdit).text,
			"skillType": AdminCatalogFormHelpers.get_enum_value(ctrl["stype_ob"] as OptionButton),
			"description": (ctrl["desc_edit"] as LineEdit).text,
			"cooldownSeconds": int((ctrl["cooldown_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
			"effects": effects_arr,
			"rankScaling": rank_arr,
		})
	return result


# ── Layout Helpers ────────────────────────────────────────────────

static func _add_labeled(label_text: String, control: Control) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(lbl)
	hb.add_child(control)
	return hb


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
