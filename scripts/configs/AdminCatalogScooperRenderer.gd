class_name AdminCatalogScooperRenderer
extends Control

signal changed

# ── State ────────────────────────────────────────────────────────

var _idle_ctrls: Dictionary = {}
var _base_rate_controls: Array = []
var _stage_bonus_controls: Array = []
var _scooper_bonus_controls: Array = []
var _equipment_controls: Array = []
var _ability_controls: Array = []


# ── Public API ───────────────────────────────────────────────────

func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_idle_ctrls.clear()
	_base_rate_controls.clear()
	_stage_bonus_controls.clear()
	_scooper_bonus_controls.clear()
	_equipment_controls.clear()
	_ability_controls.clear()

	var idle_setting: Dictionary = data.get("idleSetting", {}) if data.get("idleSetting") is Dictionary else {}
	var equipments: Array = data.get("equipments", []) if data.get("equipments") is Array else []
	var abilities: Array = data.get("abilities", []) if data.get("abilities") is Array else []

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	tabs.add_child(_build_idle_tab(idle_setting))
	tabs.add_child(_build_equipment_tab(equipments))
	tabs.add_child(_build_ability_tab(abilities))

	tabs.set_tab_title(0, "閒置設定")
	tabs.set_tab_title(1, "裝備 (%d)" % equipments.size())
	tabs.set_tab_title(2, "特殊能力 (%d)" % abilities.size())


func get_data() -> Dictionary:
	return {
		"idleSetting": _collect_idle_setting(),
		"equipments": _collect_equipments(),
		"abilities": _collect_abilities(),
	}


# ── Tab: 閒置設定 ─────────────────────────────────────────────────

func _build_idle_tab(s: Dictionary) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "IdleSetting"

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	vbox.add_child(AdminCatalogFormHelpers.make_section_label("閒置設定"))
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	var max_hours_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("maxIdleHours", 8)), 0, 999, 120.0)
	var exp_chance_spin := AdminCatalogFormHelpers.make_float_cell(float(s.get("scoopExpChance", 0.0)), 0.001, 120.0)
	var exp_amount_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("scoopExpAmount", 0)), 0, 99999, 120.0)
	var mem_base_spin := AdminCatalogFormHelpers.make_float_cell(float(s.get("scoopMemoryShardBaseChance", 0.0)), 0.001, 120.0)
	var wsk_base_spin := AdminCatalogFormHelpers.make_float_cell(float(s.get("scoopWhiskerBaseChance", 0.0)), 0.001, 120.0)
	var wsk_per_spin := AdminCatalogFormHelpers.make_float_cell(float(s.get("scoopWhiskerChancePerScooperLevel", 0.0)), 0.001, 120.0)
	var mem_per_spin := AdminCatalogFormHelpers.make_float_cell(float(s.get("scoopMemoryShardChancePerTwoScooperLevels", 0.0)), 0.001, 120.0)
	var exp_per_lv_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("scooperExpPerLevel", 100)), 1, 999999, 120.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(s.get("isEnabled", true)), 0.0)

	vbox.add_child(AdminCatalogFormHelpers.make_form_row("最大閒置時數", max_hours_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("鏟屎經驗機率", exp_chance_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("鏟屎經驗數量", exp_amount_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("記憶碎片基礎機率", mem_base_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("鬍鬚基礎機率", wsk_base_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("鬍鬚每級機率", wsk_per_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("記憶碎片每兩級機率", mem_per_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("每級所需經驗", exp_per_lv_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("啟用", enabled_cb))

	_idle_ctrls = {
		"id": s.get("id", 0),
		"max_hours": max_hours_spin,
		"exp_chance": exp_chance_spin,
		"exp_amount": exp_amount_spin,
		"mem_base": mem_base_spin,
		"wsk_base": wsk_base_spin,
		"wsk_per": wsk_per_spin,
		"mem_per": mem_per_spin,
		"exp_per_lv": exp_per_lv_spin,
		"enabled": enabled_cb,
	}

	for node: Node in [max_hours_spin, exp_chance_spin, exp_amount_spin, mem_base_spin,
			wsk_base_spin, wsk_per_spin, mem_per_spin, exp_per_lv_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# Sub-tables
	vbox.add_child(AdminCatalogFormHelpers.make_separator())
	vbox.add_child(AdminCatalogFormHelpers.make_section_label("基礎掉落率"))
	var base_rates: Array = s.get("baseRates", []) if s.get("baseRates") is Array else []
	_build_base_rates_table(base_rates, vbox)

	vbox.add_child(AdminCatalogFormHelpers.make_separator())
	vbox.add_child(AdminCatalogFormHelpers.make_section_label("關卡加成"))
	var stage_bonuses: Array = s.get("stageBonuses", []) if s.get("stageBonuses") is Array else []
	_build_stage_bonuses_table(stage_bonuses, vbox)

	vbox.add_child(AdminCatalogFormHelpers.make_separator())
	vbox.add_child(AdminCatalogFormHelpers.make_section_label("Scooper 加成"))
	var scooper_bonuses: Array = s.get("scooperBonuses", []) if s.get("scooperBonuses") is Array else []
	_build_scooper_bonuses_table(scooper_bonuses, vbox)

	return scroll


func _build_base_rates_table(entries: Array, parent: VBoxContainer) -> void:
	# Header
	var header := AdminCatalogFormHelpers.make_header_row_panel()
	parent.add_child(header)
	var hm := _make_row_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 48.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("獎勵類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("每小時掉落率", 130.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("排序", 70.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		parent.add_child(row_panel)
		var rm := _make_row_margin()
		row_panel.add_child(rm)
		var rb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(rb)

		var reward_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.REWARD_TYPE_OPTIONS, str(entry.get("rewardType", "None")))
		var rate_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("ratePerHour", 0.0)), 0.001, 130.0)
		var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 1)), 0, 9999, 70.0)
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)), 60.0)

		rb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
		rb.add_child(reward_ob)
		rb.add_child(rate_spin)
		rb.add_child(sort_spin)
		rb.add_child(en_cb)

		_connect_change(reward_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(rate_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		_base_rate_controls.append({
			"id": entry.get("id", 0),
			"reward_ob": reward_ob, "rate_spin": rate_spin,
			"sort_spin": sort_spin, "enabled_cb": en_cb,
		})


func _build_stage_bonuses_table(entries: Array, parent: VBoxContainer) -> void:
	var header := AdminCatalogFormHelpers.make_header_row_panel()
	parent.add_child(header)
	var hm := _make_row_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 48.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("獎勵類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("關卡間隔", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("每間隔加成值", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("數值模式", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		parent.add_child(row_panel)
		var rm := _make_row_margin()
		row_panel.add_child(rm)
		var rb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(rb)

		var reward_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.REWARD_TYPE_OPTIONS, str(entry.get("rewardType", "None")))
		var interval_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("stageInterval", 10)), 1, 99999, 90.0)
		var bonus_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("bonusValuePerInterval", 0.0)), 0.001, 110.0)
		var vtype_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.VALUE_MODE_OPTIONS, str(entry.get("valueType", "Flat")))
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)), 60.0)

		rb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
		rb.add_child(reward_ob)
		rb.add_child(interval_spin)
		rb.add_child(bonus_spin)
		rb.add_child(vtype_ob)
		rb.add_child(en_cb)

		_connect_change(reward_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(interval_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(bonus_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(vtype_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		_stage_bonus_controls.append({
			"id": entry.get("id", 0),
			"reward_ob": reward_ob, "interval_spin": interval_spin,
			"bonus_spin": bonus_spin, "vtype_ob": vtype_ob, "enabled_cb": en_cb,
		})


func _build_scooper_bonuses_table(entries: Array, parent: VBoxContainer) -> void:
	var header := AdminCatalogFormHelpers.make_header_row_panel()
	parent.add_child(header)
	var hm := _make_row_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 48.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("獎勵類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("每級加成值", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("數值模式", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		parent.add_child(row_panel)
		var rm := _make_row_margin()
		row_panel.add_child(rm)
		var rb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(rb)

		var reward_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.REWARD_TYPE_OPTIONS, str(entry.get("rewardType", "None")))
		var per_lv_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("perLevelBonusValue", 0.0)), 0.001, 110.0)
		var vtype_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.VALUE_MODE_OPTIONS, str(entry.get("valueType", "Flat")))
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)), 60.0)

		rb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
		rb.add_child(reward_ob)
		rb.add_child(per_lv_spin)
		rb.add_child(vtype_ob)
		rb.add_child(en_cb)

		_connect_change(reward_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(per_lv_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(vtype_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		_scooper_bonus_controls.append({
			"id": entry.get("id", 0),
			"reward_ob": reward_ob, "per_lv_spin": per_lv_spin,
			"vtype_ob": vtype_ob, "enabled_cb": en_cb,
		})


func _collect_idle_setting() -> Dictionary:
	return {
		"id": _idle_ctrls.get("id", 0),
		"maxIdleHours": int((_idle_ctrls["max_hours"] as SpinBox).value),
		"scoopExpChance": (_idle_ctrls["exp_chance"] as SpinBox).value,
		"scoopExpAmount": int((_idle_ctrls["exp_amount"] as SpinBox).value),
		"scoopMemoryShardBaseChance": (_idle_ctrls["mem_base"] as SpinBox).value,
		"scoopWhiskerBaseChance": (_idle_ctrls["wsk_base"] as SpinBox).value,
		"scoopWhiskerChancePerScooperLevel": (_idle_ctrls["wsk_per"] as SpinBox).value,
		"scoopMemoryShardChancePerTwoScooperLevels": (_idle_ctrls["mem_per"] as SpinBox).value,
		"scooperExpPerLevel": int((_idle_ctrls["exp_per_lv"] as SpinBox).value),
		"isEnabled": (_idle_ctrls["enabled"] as CheckBox).button_pressed,
		"baseRates": _collect_base_rates(),
		"stageBonuses": _collect_stage_bonuses(),
		"scooperBonuses": _collect_scooper_bonuses(),
	}


func _collect_base_rates() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _base_rate_controls:
		result.append({
			"id": ctrl["id"],
			"rewardType": AdminCatalogFormHelpers.get_enum_value(ctrl["reward_ob"] as OptionButton),
			"ratePerHour": (ctrl["rate_spin"] as SpinBox).value,
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})
	return result


func _collect_stage_bonuses() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _stage_bonus_controls:
		result.append({
			"id": ctrl["id"],
			"rewardType": AdminCatalogFormHelpers.get_enum_value(ctrl["reward_ob"] as OptionButton),
			"stageInterval": int((ctrl["interval_spin"] as SpinBox).value),
			"bonusValuePerInterval": (ctrl["bonus_spin"] as SpinBox).value,
			"valueType": AdminCatalogFormHelpers.get_enum_value(ctrl["vtype_ob"] as OptionButton),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})
	return result


func _collect_scooper_bonuses() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _scooper_bonus_controls:
		result.append({
			"id": ctrl["id"],
			"rewardType": AdminCatalogFormHelpers.get_enum_value(ctrl["reward_ob"] as OptionButton),
			"perLevelBonusValue": (ctrl["per_lv_spin"] as SpinBox).value,
			"valueType": AdminCatalogFormHelpers.get_enum_value(ctrl["vtype_ob"] as OptionButton),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})
	return result


# ── Tab: 裝備 ─────────────────────────────────────────────────────

func _build_equipment_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Equipments"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var ctrls := _build_equipment_block(entry, vbox, i % 2 == 0)
		_equipment_controls.append(ctrls)

	return scroll


func _build_equipment_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block_panel := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block_panel)

	var block_margin := _make_row_margin()
	block_panel.add_child(block_margin)

	var block_vbox := VBoxContainer.new()
	block_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block_vbox.add_theme_constant_override("separation", 4)
	block_margin.add_child(block_vbox)

	# Main row
	var main_hb := AdminCatalogFormHelpers.make_row_hbox()
	block_vbox.add_child(main_hb)

	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var unlock_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("unlockLevel", 1)), 1, 9999, 80.0)
	var purchase_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("basePurchaseCost", 0)), 0, 9999999, 90.0)
	var break_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("breakChance", 0.0)), 0.001, 90.0)
	var sick_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("sickChance", 0.0)), 0.001, 90.0)
	var repair_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("baseRepairCost", 0)), 0, 9999999, 90.0)
	var treat_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("baseTreatCost", 0)), 0, 9999999, 90.0)
	var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)), 60.0)

	main_hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	main_hb.add_child(name_edit)
	main_hb.add_child(_add_labeled("解鎖等級", unlock_spin))
	main_hb.add_child(_add_labeled("購買費用", purchase_spin))
	main_hb.add_child(_add_labeled("損壞機率", break_spin))
	main_hb.add_child(_add_labeled("生病機率", sick_spin))
	main_hb.add_child(_add_labeled("修復費用", repair_spin))
	main_hb.add_child(_add_labeled("治療費用", treat_spin))
	main_hb.add_child(en_cb)

	for node: Node in [unlock_spin, purchase_spin, break_spin, sick_spin, repair_spin, treat_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(name_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# Effects sub-table
	var effects: Array = entry.get("effects", []) if entry.get("effects") is Array else []
	var effect_controls := _build_equipment_effects_subtable(effects, block_vbox)

	# ExpRolls sub-table
	var exp_rolls: Array = entry.get("expRolls", []) if entry.get("expRolls") is Array else []
	var exp_roll_controls := _build_exp_rolls_subtable(exp_rolls, block_vbox)

	return {
		"id": entry.get("id", 0),
		"name_edit": name_edit,
		"unlock_spin": unlock_spin,
		"purchase_spin": purchase_spin,
		"break_spin": break_spin,
		"sick_spin": sick_spin,
		"repair_spin": repair_spin,
		"treat_spin": treat_spin,
		"enabled_cb": en_cb,
		"effect_controls": effect_controls,
		"exp_roll_controls": exp_roll_controls,
	}


func _build_equipment_effects_subtable(effects: Array, parent: VBoxContainer) -> Array:
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
	hb.add_child(AdminCatalogFormHelpers.make_col_header("順序", 60.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("目標範圍"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("效果類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("能力類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("數值模式"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("基礎值", 90.0, false))
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
		var etype_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.SKILL_EFFECT_TYPE_OPTIONS, str(eff.get("effectType", "StatBoost")))
		var stat_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.STAT_TYPE_OPTIONS, str(eff.get("statType", "None")))
		var vtype_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.VALUE_MODE_OPTIONS, str(eff.get("valueType", "Flat")))
		var base_spin := AdminCatalogFormHelpers.make_float_cell(float(eff.get("baseValue", 0.0)), 0.001, 90.0)
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(eff.get("isEnabled", true)), 60.0)

		rb.add_child(order_spin)
		rb.add_child(scope_ob)
		rb.add_child(etype_ob)
		rb.add_child(stat_ob)
		rb.add_child(vtype_ob)
		rb.add_child(base_spin)
		rb.add_child(en_cb)

		for node: Node in [order_spin, base_spin]:
			_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
		for ob: Node in [scope_ob, etype_ob, stat_ob, vtype_ob]:
			_connect_change(ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		result.append({
			"id": eff.get("id", 0),
			"order_spin": order_spin, "scope_ob": scope_ob,
			"etype_ob": etype_ob, "stat_ob": stat_ob,
			"vtype_ob": vtype_ob, "base_spin": base_spin, "enabled_cb": en_cb,
		})
	return result


func _build_exp_rolls_subtable(rolls: Array, parent: VBoxContainer) -> Array:
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
	hb.add_child(AdminCatalogFormHelpers.make_col_header("順序", 60.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("最小經驗", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("最大經驗", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("權重", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var result: Array = []
	for i: int in range(rolls.size()):
		var roll: Dictionary = rolls[i] if rolls[i] is Dictionary else {}
		var row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		sub_vbox.add_child(row)
		var rm := _make_small_margin()
		row.add_child(rm)
		var rb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(rb)

		var order_spin := AdminCatalogFormHelpers.make_int_cell(int(roll.get("rollOrder", 1)), 1, 99, 60.0)
		var min_spin := AdminCatalogFormHelpers.make_int_cell(int(roll.get("expMin", 0)), 0, 999999, 90.0)
		var max_spin := AdminCatalogFormHelpers.make_int_cell(int(roll.get("expMax", 0)), 0, 999999, 90.0)
		var weight_spin := AdminCatalogFormHelpers.make_float_cell(float(roll.get("weight", 1.0)), 0.001, 90.0)
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(roll.get("isEnabled", true)), 60.0)

		rb.add_child(order_spin)
		rb.add_child(min_spin)
		rb.add_child(max_spin)
		rb.add_child(weight_spin)
		rb.add_child(en_cb)

		for node: Node in [order_spin, min_spin, max_spin, weight_spin]:
			_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		result.append({
			"id": roll.get("id", 0),
			"order_spin": order_spin, "min_spin": min_spin,
			"max_spin": max_spin, "weight_spin": weight_spin, "enabled_cb": en_cb,
		})
	return result


func _collect_equipments() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _equipment_controls:
		var effects_arr: Array = []
		for ec: Dictionary in (ctrl["effect_controls"] as Array):
			effects_arr.append({
				"id": ec["id"],
				"effectOrder": int((ec["order_spin"] as SpinBox).value),
				"targetScopeType": AdminCatalogFormHelpers.get_enum_value(ec["scope_ob"] as OptionButton),
				"effectType": AdminCatalogFormHelpers.get_enum_value(ec["etype_ob"] as OptionButton),
				"statType": AdminCatalogFormHelpers.get_enum_value(ec["stat_ob"] as OptionButton),
				"valueType": AdminCatalogFormHelpers.get_enum_value(ec["vtype_ob"] as OptionButton),
				"baseValue": (ec["base_spin"] as SpinBox).value,
				"isEnabled": (ec["enabled_cb"] as CheckBox).button_pressed,
			})
		var rolls_arr: Array = []
		for rc: Dictionary in (ctrl["exp_roll_controls"] as Array):
			rolls_arr.append({
				"id": rc["id"],
				"rollOrder": int((rc["order_spin"] as SpinBox).value),
				"expMin": int((rc["min_spin"] as SpinBox).value),
				"expMax": int((rc["max_spin"] as SpinBox).value),
				"weight": (rc["weight_spin"] as SpinBox).value,
				"isEnabled": (rc["enabled_cb"] as CheckBox).button_pressed,
			})
		result.append({
			"id": ctrl["id"],
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"unlockLevel": int((ctrl["unlock_spin"] as SpinBox).value),
			"basePurchaseCost": int((ctrl["purchase_spin"] as SpinBox).value),
			"breakChance": (ctrl["break_spin"] as SpinBox).value,
			"sickChance": (ctrl["sick_spin"] as SpinBox).value,
			"baseRepairCost": int((ctrl["repair_spin"] as SpinBox).value),
			"baseTreatCost": int((ctrl["treat_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
			"effects": effects_arr,
			"expRolls": rolls_arr,
		})
	return result


# ── Tab: 特殊能力 ─────────────────────────────────────────────────

func _build_ability_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Abilities"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	# Header
	var header := AdminCatalogFormHelpers.make_header_row_panel()
	vbox.add_child(header)
	var hm := _make_row_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 48.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("顯示名稱", 120.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("描述"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("效果類型", 140.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("效果值", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("分類", 70.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("排序", 70.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("補償鑽石", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("來源說明", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		vbox.add_child(row_panel)
		_ability_controls.append(_build_ability_row(entry, row_panel))

	return scroll


func _build_ability_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var rm := _make_row_margin()
	panel.add_child(rm)
	var rb := AdminCatalogFormHelpers.make_row_hbox()
	rm.add_child(rb)

	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")), 120.0)
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))
	var etype_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.SPECIAL_ABILITY_EFFECT_OPTIONS, str(entry.get("effectType", "None")))
	etype_ob.custom_minimum_size.x = 140.0
	etype_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var effect_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("effectValue", 0.0)), 0.001, 90.0)
	var category_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("categoryType", 1)), 0, 99, 70.0)
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 1)), 0, 9999, 70.0)
	var comp_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("duplicateCompensationDiamonds", 0)), 0, 99999, 90.0)
	var source_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("sourceText", "")), 110.0)
	var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)), 60.0)

	rb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	rb.add_child(name_edit)
	rb.add_child(desc_edit)
	rb.add_child(etype_ob)
	rb.add_child(effect_spin)
	rb.add_child(category_spin)
	rb.add_child(sort_spin)
	rb.add_child(comp_spin)
	rb.add_child(source_edit)
	rb.add_child(en_cb)

	for node: Node in [effect_spin, category_spin, sort_spin, comp_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(etype_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	for edit: Node in [name_edit, desc_edit, source_edit]:
		_connect_change(edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return {
		"id": entry.get("id", 0),
		"name_edit": name_edit, "desc_edit": desc_edit,
		"etype_ob": etype_ob, "effect_spin": effect_spin,
		"category_spin": category_spin, "sort_spin": sort_spin,
		"comp_spin": comp_spin, "source_edit": source_edit, "enabled_cb": en_cb,
	}


func _collect_abilities() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _ability_controls:
		result.append({
			"id": ctrl["id"],
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"description": (ctrl["desc_edit"] as LineEdit).text,
			"effectType": AdminCatalogFormHelpers.get_enum_value(ctrl["etype_ob"] as OptionButton),
			"effectValue": (ctrl["effect_spin"] as SpinBox).value,
			"categoryType": int((ctrl["category_spin"] as SpinBox).value),
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"duplicateCompensationDiamonds": int((ctrl["comp_spin"] as SpinBox).value),
			"sourceText": (ctrl["source_edit"] as LineEdit).text,
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
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
