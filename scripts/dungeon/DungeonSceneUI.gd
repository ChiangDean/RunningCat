class_name DungeonSceneUI
extends RefCounted


static func build_ui(scene) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(scene.SW, scene.SH)
	scene.add_child(bg)

	scene._ui_layer = CanvasLayer.new()
	scene.add_child(scene._ui_layer)

	scene._root_vbox = VBoxContainer.new()
	scene._root_vbox.name = "RootVBox"
	scene._root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene._root_vbox.add_theme_constant_override("separation", 16)
	scene._root_vbox.offset_left = 20
	scene._root_vbox.offset_top = 40
	scene._root_vbox.offset_right = -20
	scene._root_vbox.offset_bottom = -20
	scene._ui_layer.add_child(scene._root_vbox)

	var top_row := HBoxContainer.new()
	scene._root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(scene._on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "地城"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	scene._root_vbox.add_child(HSeparator.new())

	scene._dungeon_list = VBoxContainer.new()
	scene._dungeon_list.name = "DungeonList"
	scene._dungeon_list.add_theme_constant_override("separation", 14)
	scene._dungeon_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._root_vbox.add_child(scene._dungeon_list)

	rebuild_dungeon_panels(scene)


static func rebuild_dungeon_panels(scene) -> void:
	scene._dungeon_panels.clear()

	var list: VBoxContainer = scene._dungeon_list
	if not is_instance_valid(list):
		return

	for child in list.get_children():
		child.queue_free()

	if scene.GameState.dungeon_overview_data.is_empty():
		var label := Label.new()
		label.text = "尚未取得地城資料。"
		label.add_theme_font_size_override("font_size", 22)
		list.add_child(label)
		return

	for item: Variant in scene.GameState.dungeon_overview_data:
		if item is Dictionary:
			var panel := _build_dungeon_panel(scene, item)
			list.add_child(panel)


static func refresh_panel(scene, dungeon_id: int) -> void:
	var entry: Dictionary = scene._dungeon_panels.get(dungeon_id, {})
	if entry.is_empty():
		return

	var dungeon: Dictionary = scene.GameState.get_dungeon_entry_by_id(dungeon_id)
	if dungeon.is_empty():
		return

	var max_floor := int(dungeon.get("maxClearedFloor", 0))
	var ticket_count := int(dungeon.get("remainingTicketCount", 0))
	var ad_count := int(dungeon.get("remainingAdTicketCount", 0))
	var display_name := str(dungeon.get("displayName", "地城"))

	var floor_label: Label = entry["floor_label"]
	floor_label.text = "最高通關：%s" % ("Lv.%d" % max_floor if max_floor > 0 else "尚未通關")

	var ticket_label: Label = entry["ticket_label"]
	ticket_label.text = "%s 門票：%d" % [display_name, ticket_count]

	var ad_label: Label = entry["ad_label"]
	ad_label.text = "今日可補票次數：%d" % ad_count

	var ad_button: Button = entry["ad_button"]
	var action_inflight: bool = bool(scene._action_inflight)
	var can_get_ad_ticket: bool = ad_count > 0 and not action_inflight
	ad_button.disabled = not can_get_ad_ticket
	ad_button.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_get_ad_ticket else Color(0.5, 0.5, 0.5, 1.0)

	var sweep_button: Button = entry["sweep_button"]
	var can_sweep: bool = max_floor > 0 and ticket_count > 0 and not action_inflight
	sweep_button.text = "掃蕩 Lv.%d" % max_floor if max_floor > 0 else "掃蕩"
	sweep_button.disabled = not can_sweep
	sweep_button.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_sweep else Color(0.5, 0.5, 0.5, 1.0)

	var challenge_button: Button = entry["challenge_button"]
	var next_floor := max_floor + 1
	var can_challenge: bool = ticket_count > 0 and not action_inflight
	challenge_button.text = "挑戰 Lv.%d" % next_floor
	challenge_button.disabled = not can_challenge
	challenge_button.modulate = Color(1.0, 1.0, 1.0, 1.0) if can_challenge else Color(0.5, 0.5, 0.5, 1.0)


static func _build_dungeon_panel(scene, dungeon: Dictionary) -> PanelContainer:
	var dungeon_id := int(dungeon.get("dungeonId", 0))
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.text = str(dungeon.get("displayName", "地城"))
	name_label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(dungeon.get("description", ""))
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	var floor_label := Label.new()
	floor_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(floor_label)

	var ticket_label := Label.new()
	ticket_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(ticket_label)

	var ad_row := HBoxContainer.new()
	ad_row.add_theme_constant_override("separation", 12)
	vbox.add_child(ad_row)

	var ad_label := Label.new()
	ad_label.add_theme_font_size_override("font_size", 20)
	ad_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad_row.add_child(ad_label)

	var ad_button := Button.new()
	ad_button.text = "看廣告補票"
	ad_button.custom_minimum_size = Vector2(160.0, 44.0)
	ad_button.add_theme_font_size_override("font_size", 18)
	ad_row.add_child(ad_button)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	vbox.add_child(button_row)

	var sweep_button := Button.new()
	sweep_button.custom_minimum_size = Vector2(0.0, 60.0)
	sweep_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sweep_button.add_theme_font_size_override("font_size", 22)
	button_row.add_child(sweep_button)

	var challenge_button := Button.new()
	challenge_button.custom_minimum_size = Vector2(0.0, 60.0)
	challenge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_button.add_theme_font_size_override("font_size", 22)
	button_row.add_child(challenge_button)

	scene._dungeon_panels[dungeon_id] = {
		"floor_label": floor_label,
		"ticket_label": ticket_label,
		"ad_label": ad_label,
		"ad_button": ad_button,
		"sweep_button": sweep_button,
		"challenge_button": challenge_button,
	}

	ad_button.pressed.connect(func(): scene._on_ad_pressed(dungeon_id))
	sweep_button.pressed.connect(func(): scene._on_sweep_pressed(dungeon_id))
	challenge_button.pressed.connect(func(): scene._on_challenge_pressed(dungeon_id))

	refresh_panel(scene, dungeon_id)
	return panel
