class_name AdminCatalogDungeonsRenderer
extends Control

signal changed

var _dungeon_controls: Array = []


func setup(data: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()
	_dungeon_controls.clear()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	var entries: Array = data.get("dungeons", []) if data.get("dungeons") is Array else []

	for i: int in range(entries.size()):
		var entry: Dictionary = entries[i] if entries[i] is Dictionary else {}
		var ctrls := _build_dungeon_block(entry, vbox, i % 2 == 0)
		_dungeon_controls.append(ctrls)


func get_data() -> Dictionary:
	var result: Array = []
	for ctrl: Dictionary in _dungeon_controls:
		result.append({
			"id": ctrl["id"],
			"dungeonKey": (ctrl["key"] as LineEdit).text,
			"displayName": (ctrl["name"] as LineEdit).text,
			"rewardType": AdminCatalogFormHelpers.get_enum_value(ctrl["reward_ob"] as OptionButton),
			"dailyTicketLimit": int((ctrl["ticket"] as SpinBox).value),
			"dailyAdTicketLimit": int((ctrl["ad_ticket"] as SpinBox).value),
			"baseHp": (ctrl["base_hp"] as SpinBox).value,
			"baseAtk": (ctrl["base_atk"] as SpinBox).value,
			"baseDef": (ctrl["base_def"] as SpinBox).value,
			"difficultyMultiplier": (ctrl["diff_mult"] as SpinBox).value,
			"catFoodPerLevel": int((ctrl["cat_food"] as SpinBox).value),
			"specialCatFoodPerLevel": int((ctrl["special_food"] as SpinBox).value),
			"diamondsPerLevel": int((ctrl["diamonds"] as SpinBox).value),
			"trapCageDivisor": int((ctrl["trap_cage"] as SpinBox).value),
			"whiskerShardDivisor": int((ctrl["whisker"] as SpinBox).value),
			"isEnabled": (ctrl["enabled"] as CheckBox).button_pressed,
			"imagePath": (ctrl["path"] as LineEdit).text,
			"sortOrder": int((ctrl["sort"] as SpinBox).value),
			"description": (ctrl["desc"] as LineEdit).text,
		})
	return {"dungeons": result}


func _build_dungeon_block(entry: Dictionary, parent: VBoxContainer, is_odd: bool) -> Dictionary:
	var block := AdminCatalogFormHelpers.make_data_row_panel(is_odd)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(block)

	var margin := _make_row_margin()
	block.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# ── Row 1: Identification ─────────────────────────────────
	var row1 := AdminCatalogFormHelpers.make_row_hbox()
	vbox.add_child(row1)

	row1.add_child(AdminCatalogFormHelpers.make_id_cell(entry.get("id", 0)))

	var key_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("dungeonKey", "")))
	var name_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("displayName", "")))
	var reward_ob := AdminCatalogFormHelpers.make_enum_cell(
		AdminCatalogFormHelpers.REWARD_TYPE_OPTIONS,
		str(entry.get("rewardType", "None"))
	)
	reward_ob.custom_minimum_size.x = 110.0
	reward_ob.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var enabled_cb := AdminCatalogFormHelpers.make_bool_cell(bool(entry.get("isEnabled", true)))
	var sort_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("sortOrder", 0)), 0, 999, 75.0)

	_add_labeled(row1, "Key:", key_edit)
	_add_labeled(row1, "名稱:", name_edit)
	_add_labeled(row1, "獎勵:", reward_ob)
	_add_labeled(row1, "啟用:", enabled_cb)
	_add_labeled(row1, "排序:", sort_spin)

	for node: Node in [key_edit, name_edit]:
		_connect_change(node, "text_changed", func(_v: Variant) -> void: changed.emit())
	_connect_change(reward_ob, "item_selected", func(_v: Variant) -> void: changed.emit())
	_connect_change(enabled_cb, "toggled", func(_v: Variant) -> void: changed.emit())
	_connect_change(sort_spin, "value_changed", func(_v: Variant) -> void: changed.emit())

	# ── Row 2: Numeric Stats ──────────────────────────────────
	var row2 := AdminCatalogFormHelpers.make_row_hbox()
	vbox.add_child(row2)

	var ticket_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("dailyTicketLimit", 3)), 0, 99, 70.0)
	var ad_ticket_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("dailyAdTicketLimit", 2)), 0, 99, 70.0)
	var base_hp_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("baseHp", 100.0)), 0.1, 90.0)
	var base_atk_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("baseAtk", 10.0)), 0.1, 90.0)
	var base_def_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("baseDef", 5.0)), 0.1, 90.0)
	var diff_mult_spin := AdminCatalogFormHelpers.make_float_cell(float(entry.get("difficultyMultiplier", 1.0)), 0.01, 90.0)
	var cat_food_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("catFoodPerLevel", 0)), 0, 99999, 75.0)
	var special_food_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("specialCatFoodPerLevel", 0)), 0, 99999, 75.0)
	var diamonds_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("diamondsPerLevel", 0)), 0, 99999, 75.0)
	var trap_cage_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("trapCageDivisor", 0)), 0, 99999, 75.0)
	var whisker_spin := AdminCatalogFormHelpers.make_int_cell(int(entry.get("whiskerShardDivisor", 0)), 0, 99999, 75.0)

	_add_labeled(row2, "每日票:", ticket_spin)
	_add_labeled(row2, "每日廣告票:", ad_ticket_spin)
	_add_labeled(row2, "基礎HP:", base_hp_spin)
	_add_labeled(row2, "基礎ATK:", base_atk_spin)
	_add_labeled(row2, "基礎DEF:", base_def_spin)
	_add_labeled(row2, "難度倍率:", diff_mult_spin)
	_add_labeled(row2, "貓糧/層:", cat_food_spin)
	_add_labeled(row2, "特製貓糧/層:", special_food_spin)
	_add_labeled(row2, "鑽石/層:", diamonds_spin)
	_add_labeled(row2, "誘捕籠除數:", trap_cage_spin)
	_add_labeled(row2, "鬍鬚碎片除數:", whisker_spin)

	for node: Node in [ticket_spin, ad_ticket_spin, base_hp_spin, base_atk_spin, base_def_spin,
			diff_mult_spin, cat_food_spin, special_food_spin, diamonds_spin, trap_cage_spin, whisker_spin]:
		_connect_change(node, "value_changed", func(_v: Variant) -> void: changed.emit())

	# ── Row 3: Text Fields ────────────────────────────────────
	var row3 := AdminCatalogFormHelpers.make_row_hbox()
	vbox.add_child(row3)

	var path_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("imagePath", "")))
	var desc_edit := AdminCatalogFormHelpers.make_text_cell(str(entry.get("description", "")))

	_add_labeled(row3, "圖片路徑:", path_edit)
	_add_labeled(row3, "說明:", desc_edit)

	for node: Node in [path_edit, desc_edit]:
		_connect_change(node, "text_changed", func(_v: Variant) -> void: changed.emit())

	return {
		"id": entry.get("id", 0),
		"key": key_edit,
		"name": name_edit,
		"reward_ob": reward_ob,
		"enabled": enabled_cb,
		"sort": sort_spin,
		"ticket": ticket_spin,
		"ad_ticket": ad_ticket_spin,
		"base_hp": base_hp_spin,
		"base_atk": base_atk_spin,
		"base_def": base_def_spin,
		"diff_mult": diff_mult_spin,
		"cat_food": cat_food_spin,
		"special_food": special_food_spin,
		"diamonds": diamonds_spin,
		"trap_cage": trap_cage_spin,
		"whisker": whisker_spin,
		"path": path_edit,
		"desc": desc_edit,
	}


# ── Layout Helpers ────────────────────────────────────────────

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
