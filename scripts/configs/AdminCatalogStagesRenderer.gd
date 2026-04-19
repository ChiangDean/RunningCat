class_name AdminCatalogStagesRenderer
extends Control

signal changed

var _stage_ctrls: Dictionary = {}
var _reward_preview_controls: Array = []
var _world_ctrls: Dictionary = {}
var _territory_controls: Array = []
var _suffix_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_stage_ctrls.clear()
	_reward_preview_controls.clear()
	_world_ctrls.clear()
	_territory_controls.clear()
	_suffix_controls.clear()

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	var stage_setting: Dictionary = data.get("stageSetting", {}) if data.get("stageSetting") is Dictionary else {}
	var world_setting: Dictionary = data.get("worldSetting", {}) if data.get("worldSetting") is Dictionary else {}

	tabs.add_child(_build_stage_tab(stage_setting))
	tabs.add_child(_build_world_tab(world_setting))

	tabs.set_tab_title(0, "關卡設定")
	tabs.set_tab_title(1, "世界設定")


func get_data() -> Dictionary:
	return {
		"stageSetting": _collect_stage_setting(),
		"worldSetting": _collect_world_setting(),
	}


# ── Stage Setting Tab ─────────────────────────────────────────

func _build_stage_tab(s: Dictionary) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "StageSetting"

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

	vbox.add_child(AdminCatalogFormHelpers.make_section_label("關卡設定"))
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	var enc_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("encountersPerBossStage", 5)), 1, 999, 120.0)
	var boss_stages_spin := AdminCatalogFormHelpers.make_int_cell(int(s.get("bossStagesPerZone", 3)), 1, 999, 120.0)
	var enc_growth_spin := AdminCatalogFormHelpers.make_float_cell(float(s.get("encounterGrowthRate", 1.0)), 0.001, 120.0)
	var boss_growth_spin := AdminCatalogFormHelpers.make_float_cell(float(s.get("bossGrowthRate", 1.0)), 0.001, 120.0)
	var zone_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.ZONE_TYPE_OPTIONS,
		str(s.get("zoneType", "None"))
	)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(s.get("isEnabled", true)))

	vbox.add_child(AdminCatalogFormHelpers.make_form_row("遭遇數/首領關", enc_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("首領關/區域", boss_stages_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("遭遇成長率", enc_growth_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("首領成長率", boss_growth_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("區域類型", zone_ob))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("啟用", enabled_cb))

	_stage_ctrls = {
		"id": s.get("id", 0),
		"enc_spin": enc_spin,
		"boss_stages_spin": boss_stages_spin,
		"enc_growth_spin": enc_growth_spin,
		"boss_growth_spin": boss_growth_spin,
		"zone_ob": zone_ob,
		"enabled_cb": enabled_cb,
	}

	for node: Node in [enc_spin, boss_stages_spin, enc_growth_spin, boss_growth_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(zone_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# Reward previews section
	vbox.add_child(AdminCatalogFormHelpers.make_separator())
	vbox.add_child(AdminCatalogFormHelpers.make_section_label("獎勵預覽"))

	var reward_previews: Array = s.get("rewardPreviews", []) if s.get("rewardPreviews") is Array else []
	_build_reward_previews_table(reward_previews, vbox)

	return scroll


func _build_reward_previews_table(entries: Array, parent: VBoxContainer) -> void:
	# Header
	var header_panel := AdminCatalogFormHelpers.make_header_row_panel()
	parent.add_child(header_panel)
	var hm := _make_row_margin()
	header_panel.add_child(hm)
	var h_hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(h_hb)
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("Order", 60.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("RewardType"))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("Quantity", 110.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("SortOrder", 90.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("IsEnabled", 70.0, false))

	var rows_vbox := VBoxContainer.new()
	rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_vbox.add_theme_constant_override("separation", 2)
	parent.add_child(rows_vbox)

	for i: int in range(entries.size()):
		var rw: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		rows_vbox.add_child(row_panel)
		var rm := _make_row_margin()
		row_panel.add_child(rm)
		var r_hb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(r_hb)

		var order_lbl := Label.new()
		order_lbl.text = "#%d" % int(rw.get("rewardOrder", i + 1))
		order_lbl.custom_minimum_size.x = 60.0
		order_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		order_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
		order_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var type_ob := AdminCatalogFormHelpers.make_enum_cell(
			AdminCatalogFormHelpers.REWARD_TYPE_OPTIONS,
			str(rw.get("rewardType", "None"))
		)
		var qty_spin := AdminCatalogFormHelpers.make_float_cell(float(rw.get("rewardQuantity", 0.0)), 0.001, 110.0)
		var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(rw.get("sortOrder", 0)), 0, 9999, 90.0)
		var rw_enabled := AdminCatalogFormHelpers.make_bool_cell(bool(rw.get("isEnabled", true)))

		r_hb.add_child(order_lbl)
		r_hb.add_child(type_ob)
		r_hb.add_child(qty_spin)
		r_hb.add_child(sort_spin)
		r_hb.add_child(rw_enabled)

		_connect_change(type_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
		_connect_change(qty_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(rw_enabled, "toggled", func(_v: Variant) -> void: changed.emit())

		_reward_preview_controls.append({
			"id": rw.get("id", 0),
			"reward_order": int(rw.get("rewardOrder", i + 1)),
			"type_ob": type_ob,
			"qty_spin": qty_spin,
			"sort_spin": sort_spin,
			"enabled_cb": rw_enabled,
		})


func _collect_stage_setting() -> Dictionary:
	return {
		"id": _stage_ctrls.get("id", 0),
		"encountersPerBossStage": int((_stage_ctrls["enc_spin"] as SpinBox).value),
		"bossStagesPerZone": int((_stage_ctrls["boss_stages_spin"] as SpinBox).value),
		"encounterGrowthRate": (_stage_ctrls["enc_growth_spin"] as SpinBox).value,
		"bossGrowthRate": (_stage_ctrls["boss_growth_spin"] as SpinBox).value,
		"zoneType": AdminCatalogFormHelpers.get_enum_value(_stage_ctrls["zone_ob"] as OptionButton),
		"isEnabled": (_stage_ctrls["enabled_cb"] as CheckBox).button_pressed,
		"rewardPreviews": _collect_reward_previews(),
	}


func _collect_reward_previews() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _reward_preview_controls:
		result.append({
			"id": ctrl["id"],
			"rewardOrder": ctrl["reward_order"],
			"rewardType": AdminCatalogFormHelpers.get_enum_value(ctrl["type_ob"] as OptionButton),
			"rewardQuantity": (ctrl["qty_spin"] as SpinBox).value,
			"sortOrder": int((ctrl["sort_spin"] as SpinBox).value),
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})
	return result


# ── World Setting Tab ─────────────────────────────────────────

func _build_world_tab(w: Dictionary) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "WorldSetting"

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

	vbox.add_child(AdminCatalogFormHelpers.make_section_label("世界設定"))
	vbox.add_child(AdminCatalogFormHelpers.make_separator())

	var zones_spin := AdminCatalogFormHelpers.make_int_cell(int(w.get("zonesPerTerritory", 5)), 1, 999, 120.0)
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(w.get("isEnabled", true)))

	vbox.add_child(AdminCatalogFormHelpers.make_form_row("區域數/地域", zones_spin))
	vbox.add_child(AdminCatalogFormHelpers.make_form_row("啟用", enabled_cb))

	_world_ctrls = {
		"id": w.get("id", 0),
		"zones_spin": zones_spin,
		"enabled_cb": enabled_cb,
	}

	_connect_change(zones_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# Territories section
	vbox.add_child(AdminCatalogFormHelpers.make_separator())
	vbox.add_child(AdminCatalogFormHelpers.make_section_label("地域列表"))

	var territories: Array = w.get("territories", []) if w.get("territories") is Array else []
	_build_territories_table(territories, vbox)

	# Zone Suffixes section
	vbox.add_child(AdminCatalogFormHelpers.make_separator())
	vbox.add_child(AdminCatalogFormHelpers.make_section_label("Zone 後綴"))

	var zone_suffixes: Array = w.get("zoneSuffixes", []) if w.get("zoneSuffixes") is Array else []
	_build_suffixes_table(zone_suffixes, vbox)

	return scroll


func _build_territories_table(entries: Array, parent: VBoxContainer) -> void:
	var header_panel := AdminCatalogFormHelpers.make_header_row_panel()
	parent.add_child(header_panel)
	var hm := _make_row_margin()
	header_panel.add_child(hm)
	var h_hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(h_hb)
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("Order", 60.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("DisplayName"))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("IsEnabled", 70.0, false))

	var rows_vbox := VBoxContainer.new()
	rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_vbox.add_theme_constant_override("separation", 2)
	parent.add_child(rows_vbox)

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		rows_vbox.add_child(row_panel)
		var rm := _make_row_margin()
		row_panel.add_child(rm)
		var r_hb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(r_hb)

		var order_lbl := Label.new()
		order_lbl.text = "#%d" % int(entry.get("territoryOrder", i + 1))
		order_lbl.custom_minimum_size.x = 60.0
		order_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		order_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
		order_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
		var t_enabled := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

		r_hb.add_child(order_lbl)
		r_hb.add_child(name_edit)
		r_hb.add_child(t_enabled)

		_connect_change(name_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(t_enabled, "toggled", func(_v: Variant) -> void: changed.emit())

		_territory_controls.append({
			"id": entry.get("id", 0),
			"territory_order": int(entry.get("territoryOrder", i + 1)),
			"name_edit": name_edit,
			"enabled_cb": t_enabled,
		})


func _build_suffixes_table(entries: Array, parent: VBoxContainer) -> void:
	var header_panel := AdminCatalogFormHelpers.make_header_row_panel()
	parent.add_child(header_panel)
	var hm := _make_row_margin()
	header_panel.add_child(hm)
	var h_hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(h_hb)
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("Order", 60.0, false))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("DisplayName"))
	h_hb.add_child(AdminCatalogFormHelpers.make_col_header("IsEnabled", 70.0, false))

	var rows_vbox := VBoxContainer.new()
	rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_vbox.add_theme_constant_override("separation", 2)
	parent.add_child(rows_vbox)

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var row_panel := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		rows_vbox.add_child(row_panel)
		var rm := _make_row_margin()
		row_panel.add_child(rm)
		var r_hb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(r_hb)

		var order_lbl := Label.new()
		order_lbl.text = "#%d" % int(entry.get("suffixOrder", i + 1))
		order_lbl.custom_minimum_size.x = 60.0
		order_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		order_lbl.add_theme_color_override("font_color", AdminCatalogFormHelpers.MUTED_COLOR)
		order_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
		var s_enabled := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))

		r_hb.add_child(order_lbl)
		r_hb.add_child(name_edit)
		r_hb.add_child(s_enabled)

		_connect_change(name_edit, "text_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(s_enabled, "toggled", func(_v: Variant) -> void: changed.emit())

		_suffix_controls.append({
			"id": entry.get("id", 0),
			"suffix_order": int(entry.get("suffixOrder", i + 1)),
			"name_edit": name_edit,
			"enabled_cb": s_enabled,
		})


func _collect_world_setting() -> Dictionary:
	var territories_arr: Array = []
	for ctrl: Dictionary in _territory_controls:
		territories_arr.append({
			"id": ctrl["id"],
			"territoryOrder": ctrl["territory_order"],
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})

	var suffixes_arr: Array = []
	for ctrl: Dictionary in _suffix_controls:
		suffixes_arr.append({
			"id": ctrl["id"],
			"suffixOrder": ctrl["suffix_order"],
			"displayName": (ctrl["name_edit"] as LineEdit).text,
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
		})

	return {
		"id": _world_ctrls.get("id", 0),
		"zonesPerTerritory": int((_world_ctrls["zones_spin"] as SpinBox).value),
		"isEnabled": (_world_ctrls["enabled_cb"] as CheckBox).button_pressed,
		"territories": territories_arr,
		"zoneSuffixes": suffixes_arr,
	}


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
