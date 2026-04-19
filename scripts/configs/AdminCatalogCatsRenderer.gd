class_name AdminCatalogCatsRenderer
extends Control

signal changed

# ── State ────────────────────────────────────────────────────────

var _cat_controls: Array = []


# ── Public API ───────────────────────────────────────────────────

func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_cat_controls.clear()

	var cats: Array = data.get("cats", []) if data.get("cats") is Array else []

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	for i: int in range(cats.size()):
		var entry: Dictionary = cats[i] if cats[i] is Dictionary else {}
		var ctrls := _build_cat_block(entry, vbox, i % 2 == 0)
		_cat_controls.append(ctrls)


func get_data() -> Dictionary:
	return {"cats": _collect_cats()}


# ── Cat Block ────────────────────────────────────────────────────

func _build_cat_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block_panel := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block_panel)

	var block_margin := _make_row_margin()
	block_panel.add_child(block_margin)

	var block_vbox := VBoxContainer.new()
	block_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block_vbox.add_theme_constant_override("separation", 4)
	block_margin.add_child(block_vbox)

	# ── Row 1: Identity ───────────────────────────────────────────
	var row1 := AdminCatalogFormHelpers.make_row_hbox()
	block_vbox.add_child(row1)

	var cat_key_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("catKey", "")))
	var cat_type_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("catType", "")))
	var display_name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var rarity_ob := AdminCatalogFormHelpers.make_enum_cell(AdminCatalogFormHelpers.GACHA_RARITY_OPTIONS, str(entry.get("rarityType", "Common")))
	var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)), 60.0)
	var image_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("imagePath", "")), 140.0)

	row1.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))
	row1.add_child(_add_labeled("Key", cat_key_edit))
	row1.add_child(_add_labeled("類型", cat_type_edit))
	row1.add_child(_add_labeled("顯示名稱", display_name_edit))
	row1.add_child(_add_labeled("稀有度", rarity_ob))
	row1.add_child(_add_labeled("啟用", en_cb))
	row1.add_child(_add_labeled("圖片路徑", image_edit))

	_connect_change(rarity_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	for edit: Node in [cat_key_edit, cat_type_edit, display_name_edit, image_edit]:
		_connect_change(edit, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# ── Row 2: Base Stats ─────────────────────────────────────────
	var row2 := AdminCatalogFormHelpers.make_row_hbox()
	block_vbox.add_child(row2)

	var hp_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("baseHp", 100.0)), 0.1, 90.0)
	var atk_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("baseAtk", 10.0)), 0.1, 90.0)
	var def_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("baseDef", 5.0)), 0.1, 90.0)
	var spd_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("baseSpeed", 3.0)), 0.1, 90.0)
	var gacha_cb := CheckBox.new()
	gacha_cb.button_pressed = bool(entry.get("gachaAvailable", true))
	gacha_cb.custom_minimum_size.x = 24.0
	var gacha_w_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("gachaWeight", 1.0)), 0.001, 90.0)

	row2.add_child(_add_labeled("基礎HP", hp_spin))
	row2.add_child(_add_labeled("基礎ATK", atk_spin))
	row2.add_child(_add_labeled("基礎DEF", def_spin))
	row2.add_child(_add_labeled("基礎速度", spd_spin))
	row2.add_child(_add_labeled("可抽卡", gacha_cb))
	row2.add_child(_add_labeled("抽卡權重", gacha_w_spin))

	for node: Node in [hp_spin, atk_spin, def_spin, spd_spin, gacha_w_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(gacha_cb, "toggled", func(_v: Variant) -> void: changed.emit())

	# ── Row 3: Growth + Description ───────────────────────────────
	var row3 := AdminCatalogFormHelpers.make_row_hbox()
	block_vbox.add_child(row3)

	var hp_g_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("hpGrowth", 1.0)), 0.001, 90.0)
	var atk_g_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("atkGrowth", 1.0)), 0.001, 90.0)
	var def_g_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("defGrowth", 1.0)), 0.001, 90.0)
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))

	row3.add_child(_add_labeled("HP成長", hp_g_spin))
	row3.add_child(_add_labeled("ATK成長", atk_g_spin))
	row3.add_child(_add_labeled("DEF成長", def_g_spin))
	row3.add_child(_add_labeled("描述", desc_edit))

	for node: Node in [hp_g_spin, atk_g_spin, def_g_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(desc_edit, "text_changed", func(_v: Variant) -> void: changed.emit())

	# ── PassiveSkills Sub-table ───────────────────────────────────
	var passive_skills: Array = entry.get("passiveSkills", []) if entry.get("passiveSkills") is Array else []
	var passive_controls := _build_passive_skills_subtable(passive_skills, block_vbox)

	# ── ActiveSkills Sub-table ────────────────────────────────────
	var active_skills: Array = entry.get("activeSkills", []) if entry.get("activeSkills") is Array else []
	var active_controls := _build_active_skills_subtable(active_skills, block_vbox)

	return {
		"id": entry.get("id", 0),
		"cat_key_edit": cat_key_edit,
		"cat_type_edit": cat_type_edit,
		"display_name_edit": display_name_edit,
		"rarity_ob": rarity_ob,
		"enabled_cb": en_cb,
		"image_edit": image_edit,
		"hp_spin": hp_spin, "atk_spin": atk_spin,
		"def_spin": def_spin, "spd_spin": spd_spin,
		"gacha_cb": gacha_cb, "gacha_w_spin": gacha_w_spin,
		"hp_g_spin": hp_g_spin, "atk_g_spin": atk_g_spin, "def_g_spin": def_g_spin,
		"desc_edit": desc_edit,
		"passive_controls": passive_controls,
		"active_controls": active_controls,
	}


func _build_passive_skills_subtable(skills: Array, parent: VBoxContainer) -> Array:
	var sub_margin := MarginContainer.new()
	sub_margin.add_theme_constant_override("margin_left", 20)
	parent.add_child(sub_margin)

	var sub_vbox := VBoxContainer.new()
	sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_vbox.add_theme_constant_override("separation", 2)
	sub_margin.add_child(sub_vbox)

	var label := AdminCatalogFormHelpers.make_section_label("被動技能")
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	sub_vbox.add_child(label)

	var header := AdminCatalogFormHelpers.make_header_row_panel()
	sub_vbox.add_child(header)
	var hm := _make_small_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("技能順序 (readonly)", 160.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("技能 Id"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var result: Array = []
	for i: int in range(skills.size()):
		var sk: Dictionary = skills[i] if skills[i] is Dictionary else {}
		var row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		sub_vbox.add_child(row)
		var rm := _make_small_margin()
		row.add_child(rm)
		var rb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(rb)

		var order_lbl := AdminCatalogFormHelpers.make_id_cell(sk.get("skillOrder", i + 1))
		order_lbl.custom_minimum_size.x = 160.0
		var skill_id_spin := AdminCatalogFormHelpers.make_int_cell(int(sk.get("skillId", 1)), 1, 999999)
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(sk.get("isEnabled", true)), 60.0)

		rb.add_child(order_lbl)
		rb.add_child(skill_id_spin)
		rb.add_child(en_cb)

		_connect_change(skill_id_spin, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		result.append({
			"id": sk.get("id", 0),
			"skill_order": int(sk.get("skillOrder", i + 1)),
			"skill_id_spin": skill_id_spin,
			"enabled_cb": en_cb,
		})
	return result


func _build_active_skills_subtable(skills: Array, parent: VBoxContainer) -> Array:
	var sub_margin := MarginContainer.new()
	sub_margin.add_theme_constant_override("margin_left", 20)
	parent.add_child(sub_margin)

	var sub_vbox := VBoxContainer.new()
	sub_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_vbox.add_theme_constant_override("separation", 2)
	sub_margin.add_child(sub_vbox)

	var label := AdminCatalogFormHelpers.make_section_label("主動技能")
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	sub_vbox.add_child(label)

	var header := AdminCatalogFormHelpers.make_header_row_panel()
	sub_vbox.add_child(header)
	var hm := _make_small_margin()
	header.add_child(hm)
	var hb := AdminCatalogFormHelpers.make_row_hbox()
	hm.add_child(hb)
	hb.add_child(AdminCatalogFormHelpers.make_col_header("技能順序 (readonly)", 160.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("技能 Id"))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("初始延遲(秒)", 110.0, false))
	hb.add_child(AdminCatalogFormHelpers.make_col_header("啟用", 60.0, false))

	var result: Array = []
	for i: int in range(skills.size()):
		var sk: Dictionary = skills[i] if skills[i] is Dictionary else {}
		var row := AdminCatalogFormHelpers.make_data_row_panel(i % 2 == 0)
		sub_vbox.add_child(row)
		var rm := _make_small_margin()
		row.add_child(rm)
		var rb := AdminCatalogFormHelpers.make_row_hbox()
		rm.add_child(rb)

		var order_lbl := AdminCatalogFormHelpers.make_id_cell(sk.get("skillOrder", i + 1))
		order_lbl.custom_minimum_size.x = 160.0
		var skill_id_spin := AdminCatalogFormHelpers.make_int_cell(int(sk.get("skillId", 1)), 1, 999999)
		var delay_spin := AdminCatalogFormHelpers.make_int_cell(int(sk.get("initialDelaySeconds", 0)), 0, 9999, 110.0)
		var en_cb := AdminCatalogFormHelpers.make_bool_cell(bool(sk.get("isEnabled", true)), 60.0)

		rb.add_child(order_lbl)
		rb.add_child(skill_id_spin)
		rb.add_child(delay_spin)
		rb.add_child(en_cb)

		for node: Node in [skill_id_spin, delay_spin]:
			_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())
		_connect_change(en_cb, "toggled", func(_v: Variant) -> void: changed.emit())

		result.append({
			"id": sk.get("id", 0),
			"skill_order": int(sk.get("skillOrder", i + 1)),
			"skill_id_spin": skill_id_spin,
			"delay_spin": delay_spin,
			"enabled_cb": en_cb,
		})
	return result


# ── Collect ──────────────────────────────────────────────────────

func _collect_cats() -> Array:
	var result: Array = []
	for ctrl: Dictionary in _cat_controls:
		var passive_arr: Array = []
		for pc: Dictionary in (ctrl["passive_controls"] as Array):
			passive_arr.append({
				"id": pc["id"],
				"skillId": int((pc["skill_id_spin"] as SpinBox).value),
				"skillOrder": pc["skill_order"],
				"isEnabled": (pc["enabled_cb"] as CheckBox).button_pressed,
			})
		var active_arr: Array = []
		for ac: Dictionary in (ctrl["active_controls"] as Array):
			active_arr.append({
				"id": ac["id"],
				"skillId": int((ac["skill_id_spin"] as SpinBox).value),
				"skillOrder": ac["skill_order"],
				"initialDelaySeconds": int((ac["delay_spin"] as SpinBox).value),
				"isEnabled": (ac["enabled_cb"] as CheckBox).button_pressed,
			})
		result.append({
			"id": ctrl["id"],
			"catKey": (ctrl["cat_key_edit"] as LineEdit).text,
			"catType": (ctrl["cat_type_edit"] as LineEdit).text,
			"displayName": (ctrl["display_name_edit"] as LineEdit).text,
			"rarityType": AdminCatalogFormHelpers.get_enum_value(ctrl["rarity_ob"] as OptionButton),
			"baseHp": (ctrl["hp_spin"] as SpinBox).value,
			"baseAtk": (ctrl["atk_spin"] as SpinBox).value,
			"baseDef": (ctrl["def_spin"] as SpinBox).value,
			"baseSpeed": (ctrl["spd_spin"] as SpinBox).value,
			"gachaAvailable": (ctrl["gacha_cb"] as CheckBox).button_pressed,
			"gachaWeight": (ctrl["gacha_w_spin"] as SpinBox).value,
			"hpGrowth": (ctrl["hp_g_spin"] as SpinBox).value,
			"atkGrowth": (ctrl["atk_g_spin"] as SpinBox).value,
			"defGrowth": (ctrl["def_g_spin"] as SpinBox).value,
			"isEnabled": (ctrl["enabled_cb"] as CheckBox).button_pressed,
			"imagePath": (ctrl["image_edit"] as LineEdit).text,
			"description": (ctrl["desc_edit"] as LineEdit).text,
			"passiveSkills": passive_arr,
			"activeSkills": active_arr,
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
