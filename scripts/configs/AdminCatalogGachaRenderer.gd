class_name AdminCatalogGachaRenderer
extends Control

signal changed

var _setting_ctrls: Dictionary = {}
var _pull_controls: Array = []
var _technique_controls: Array = []
var _rarity_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_setting_ctrls.clear()
	_pull_controls.clear()
	_technique_controls.clear()
	_rarity_controls.clear()

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	var setting: Dictionary = data.get("setting", {}) if data.get("setting") is Dictionary else {}
	var pull_options: Array = data.get("pullOptions", []) if data.get("pullOptions") is Array else []
	var technique_levels: Array = data.get("techniqueLevels", []) if data.get("techniqueLevels") is Array else []
	var rarity_pres: Array = data.get("rarityPresentations", []) if data.get("rarityPresentations") is Array else []

	tabs.add_child(_build_setting_tab(setting))
	tabs.add_child(_build_pull_options_tab(pull_options))
	tabs.add_child(_build_technique_tab(technique_levels))
	tabs.add_child(_build_rarity_tab(rarity_pres))

	tabs.set_tab_title(0, "全域設定")
	tabs.set_tab_title(1, "抽卡選項 (%d)" % pull_options.size())
	tabs.set_tab_title(2, "技巧等級 (%d)" % technique_levels.size())
	tabs.set_tab_title(3, "稀有度展示 (%d)" % rarity_pres.size())


func get_data() -> Dictionary:
	return {
		"setting": _collect_setting(),
		"pullOptions": _collect_pull_options(),
		"techniqueLevels": _collect_technique_levels(),
		"rarityPresentations": _collect_rarity_presentations(),
	}


# ── Settings Tab ──────────────────────────────────────────────

func _build_setting_tab(s: Dictionary) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Setting"

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

	vbox.add_child(AdminCatalogFormHelpers.make_section_label("Gacha 全域設定"))
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	var free_pull_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("dailyFreePullCap", 0)), 0, 9999, 120.0)
	var dup_shard_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("duplicateCatShardReward", 0)), 0, 9999, 120.0)
	var trap_extra_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("trapPointsExtraPullCost", 0)), 0, 99999, 120.0)
	var trap_shard_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("trapPointsCatShardCost", 0)), 0, 99999, 120.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(s.get("isEnabled", true)), 0.0)

	vbox.add_child(AdminCatalogFormHelpers.make_form_row("每日免費抽卡上限", free_pull_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("重複貓咪碎片獎勵", dup_shard_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("陷阱點額外抽卡費用", trap_extra_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("陷阱點貓咪碎片費用", trap_shard_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("啟用", enabled_cb))

	_setting_ctrls = {
		"id": s.get("id", 0),
		"free_pull": free_pull_spin,
		"dup_shard": dup_shard_spin,
		"trap_extra": trap_extra_spin,
		"trap_shard": trap_shard_spin,
		"enabled": enabled_cb,
	}

	_connect_change(free_pull_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(dup_shard_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(trap_extra_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(trap_shard_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return scroll


func _collect_setting() -> Dictionary:
	return {
		"id": _setting_ctrls.get("id", 0),
		"dailyFreePullCap": int((_setting_ctrls["free_pull"] as SpinBox).value),
		"duplicateCatShardReward": int((_setting_ctrls["dup_shard"] as SpinBox).value),
		"trapPointsExtraPullCost": int((_setting_ctrls["trap_extra"] as SpinBox).value),
		"trapPointsCatShardCost": int((_setting_ctrls["trap_shard"] as SpinBox).value),
		"isEnabled": (_setting_ctrls["enabled"] as CheckBox).button_pressed,
	}


# ── Pull Options Tab ──────────────────────────────────────────

func _build_pull_options_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "PullOptions"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	vbox.add_child(_make_pull_header())
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		_pull_controls.append(_build_pull_row(entry, row_panel))
		vbox.add_child(row_panel)

	return scroll


func _make_pull_header() -> PanelContainer:
	var panel := AdminCatalogFormHelpers.make_header_row_panel()
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("抽卡次數", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("鑽石費用", 90.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("需要陷阱籠", 100.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("排序", 80.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))
	return panel


func _build_pull_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var count_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("pullCount", 1)), 1, 999, 90.0)
	var cost_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("diamondCost", 0)), 0, 999999, 90.0)
	var trap_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("requiredTrapCages", 0)), 0, 999, 100.0)
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 99, 80.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	hb.add_child(count_spin)
	hb.add_child(cost_spin)
	hb.add_child(trap_spin)
	hb.add_child(sort_spin)
	hb.add_child(enabled_cb)

	for node: Node in [count_spin, cost_spin, trap_spin, sort_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return {"id": entry.get("id", 0), "count": count_spin, "cost": cost_spin,
		"trap": trap_spin, "sort": sort_spin, "enabled": enabled_cb}


func _collect_pull_options() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _pull_controls:
		result.append({
			"id": ctrl["id"],
			"pullCount": int((ctrl["count"] as SpinBox).value),
			"diamondCost": int((ctrl["cost"] as SpinBox).value),
			"requiredTrapCages": int((ctrl["trap"] as SpinBox).value),
			"sortOrder": int((ctrl["sort"] as SpinBox).value),
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
		})
	return result


# ── Technique Levels Tab ──────────────────────────────────────

func _build_technique_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Techniques"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var ctrls := _build_technique_block(entry, vbox, i % 2 == 0)
		_technique_controls.append(ctrls)

	return scroll


func _build_technique_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block_panel := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block_panel)

	var block_margin := _make_row_margin()
	block_panel.add_child(block_margin)

	var block_vbox := VBoxContainer.new()
	block_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block_vbox.add_theme_constant_override("separation", 4)
	block_margin.add_child(block_vbox)

	# Header row: level info + controls
	var header_hb := AdminCatalogFormHelpers.make_row_hbox()
	block_vbox.add_child(header_hb)

	var level_lbl := Label.new()
	level_lbl.text = "Lv %d" % int(entry.get("techniqueLevel", 0))
	level_lbl.custom_minimum_size.x = 60.0
	level_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	level_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.62, 0.95))
	level_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_hb.add_child(level_lbl)

	var req_lbl := Label.new()
	req_lbl.text = "需要 pull 數："
	req_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	req_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	req_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_hb.add_child(req_lbl)

	var req_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("requiredPullCount", 0)), 0, 99999, 90.0)
	header_hb.add_child(req_spin)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hb.add_child(spacer)

	var enabled_lbl := Label.new()
	enabled_lbl.text = "啟用"
	enabled_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	enabled_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
	enabled_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_hb.add_child(enabled_lbl)

	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))
	header_hb.add_child(enabled_cb)

	_connect_change(req_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# Rates sub-table
	var rates: Array = entry.get("rates", []) if entry.get("rates") is Array else []
	var rate_controls := _build_rates_subtable(rates, block_vbox)

	return {
		"id": entry.get("id", 0),
		"level": int(entry.get("techniqueLevel", 0)),
		"req_spin": req_spin,
		"enabled_cb": enabled_cb,
		"rate_controls": rate_controls,
	}


func _build_rates_subtable(rates: Array, parent: VBoxContainer) -> Array:
	if rates.is_empty():
		return []

	var rate_margin := MarginContainer.new()
	rate_margin.add_theme_constant_override("margin_left", 20)
	parent.add_child(rate_margin)

	var rate_vbox := VBoxContainer.new()
	rate_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rate_vbox.add_theme_constant_override("separation", 2)
	rate_margin.add_child(rate_vbox)

	# Rates header
	var rate_header := AdminCatalogFormHelpers.make_header_row_panel()
	rate_vbox.add_child(rate_header)
	var rh_margin := _make_small_margin()
	rate_header.add_child(rh_margin)
	var rh_hb := AdminCatalogFormHelpers.make_row_hbox()
	rh_margin.add_child(rh_hb)
	rh_hb.add_child(AdminCatalogFormHelpers.make_col_header("稀有度"))
	rh_hb.add_child(AdminCatalogFormHelpers.make_col_header("機率 %", 100.0, false))
	rh_hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var rate_controls: Array = []
	for i: int in range(rates.size()):
		var rate_entry: Dictionary = rates[i] if rates[i] is Dictionary else {}
		var rate_row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		rate_vbox.add_child(rate_row)
		var rm := _make_small_margin()
		rate_row.add_child(rm)
		var r_hb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(r_hb)

		var rarity_ob := AdminCatalogFormHelpers.make_enum_cell(
			AdminCatalogFormHelpers.GACHA_RARITY_OPTIONS,
			str(rate_entry.get("rarityType", "None"))
		)
		var rate_spin := AdminCatalogFormHelpers.make_float_cell(float(rate_entry.get("ratePercent", 0.0)), 0.001, 100.0)
		var rate_enabled := AdminCatalogFormHelpers.make_bool_cell(bool(rate_entry.get("isEnabled", true)))

		r_hb.add_child(rarity_ob)
		r_hb.add_child(rate_spin)
		r_hb.add_child(rate_enabled)

		_connect_change(rarity_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(rate_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(rate_enabled, "toggled", func(_v: Variant) -> void: changed.emit())

		rate_controls.append({
			"id": rate_entry.get("id", 0),
			"rarity_ob": rarity_ob,
			"rate_spin": rate_spin,
			"enabled_cb": rate_enabled,
		})

	return rate_controls


func _collect_technique_levels() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _technique_controls:
		var rates_arr: Array = []
		for rc: Dictionary in (ctrl["rate_controls"] as Array):
			rates_arr.append({
				"id": rc["id"],
				"rarityType": AdminCatalogFormHelpers.get_enum_value(rc["rarity_ob"] as OptionButton),
				"ratePercent": (rc["rate_spin"] as SpinBox).value,
				"isEnabled": (rc["enabled_cb"] as CheckBox).button_pressed,
			})
		result.append({
			"id": ctrl["id"],
			"techniqueLevel": ctrl["level"],
			"requiredPullCount": int((ctrl["req_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
			"rates": rates_arr,
		})
	return result


# ── Rarity Presentations Tab ──────────────────────────────────

func _build_rarity_tab(entries: Array) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "Rarities"

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	scroll.add_child(vbox)

	vbox.add_child(_make_rarity_header())
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		_rarity_controls.append(_build_rarity_row(entry, row_panel))
		vbox.add_child(row_panel)

	return scroll


func _make_rarity_header() -> PanelContainer:
	var panel := AdminCatalogFormHelpers.make_header_row_panel()
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Id", 50.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("稀有度類型"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("Key"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("顯示名稱"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("顏色HEX", 120.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("排序", 80.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))
	return panel


func _build_rarity_row(entry: Dictionary, panel: PanelContainer) -> Dictionary:
	var margin := _make_row_margin()
	panel.add_child(margin)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	margin.add_child(hb)

	var rarity_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.GACHA_RARITY_OPTIONS,
		str(entry.get("rarityType", "None"))
	)
	var key_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("rarityKey", "")))
	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var color_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("colorHex", "#ffffff")), 120.0)
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 99, 80.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

	hb.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	hb.add_child(rarity_ob)
	hb.add_child(key_edit)
	hb.add_child(name_edit)
	hb.add_child(color_edit)
	hb.add_child(sort_spin)
	hb.add_child(enabled_cb)

	_connect_change(rarity_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(key_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(name_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(color_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	return {
		"id": entry.get("id", 0),
		"rarity_ob": rarity_ob,
		"key_edit": key_edit,
		"name_edit": name_edit,
		"color_edit": color_edit,
		"sort_spin": sort_spin,
		"enabled_cb": enabled_cb,
	}


func _collect_rarity_presentations() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _rarity_controls:
		result.append({
			"id": ctrl["id"],
			"rarityType": AdminCatalogFormHelpers.get_enum_value(ctrl["rarity_ob"] as OptionButton),
			"rarityKey": (ctrl["key_edit"] as LineEdit).text,
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"colorHex": (ctrl["color_edit"] as LineEdit).text,
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
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
