extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")


func build(scene: Control) -> void:
	var summary_row: HBoxContainer = HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 10)
	scene._tab_content.add_child(summary_row)

	var section_label: Label = Label.new()
	section_label.text = UiText.SCOOPER_TAB_MEMORY
	section_label.add_theme_font_size_override("font_size", 18)
	section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(section_label)

	scene._memory_summary_label = Label.new()
	scene._memory_summary_label.add_theme_font_size_override("font_size", 18)
	scene._memory_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scene._memory_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(scene._memory_summary_label)

	scene._tab_content.add_child(scene._make_separator())

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(scroll)
	scene._memory_scroller = InertialScroller.attach(scroll, "vertical")

	scene._memory_list = VBoxContainer.new()
	scene._memory_list.add_theme_constant_override("separation", 12)
	scene._memory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._memory_list)

	_refresh_memory_tab(scene)


func _refresh_memory_tab(scene: Control) -> void:
	var items: Array = scene.GameState.scooper_memory_data
	if scene._memory_summary_label != null:
		var unlocked: int = 0
		for item: Dictionary in items:
			if bool(item.get("isUnlocked", false)):
				unlocked += 1
		scene._memory_summary_label.text = UiText.SCOOPER_MEMORY_UNLOCKED_SUMMARY % [unlocked, items.size()]

	if scene._memory_list == null:
		return

	for child: Node in scene._memory_list.get_children():
		child.queue_free()

	if items.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = UiText.SCOOPER_MEMORY_EMPTY
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._memory_list.add_child(empty_lbl)
		return

	var first_item: bool = true
	for item: Dictionary in items:
		if not first_item:
			scene._memory_list.add_child(scene._make_separator())
		scene._memory_list.add_child(_make_memory_card(scene, item))
		first_item = false


func _make_memory_card(scene: Control, item: Dictionary) -> Control:
	var memory_id: int = int(item.get("memoryId", 0))
	var api_locked: bool = _is_api_locked(scene)
	var unlocked: bool = bool(item.get("isUnlocked", false))
	var cost: int = int(item.get("unlockCost", 0))
	var can_unlock: bool = (not unlocked) and scene.GameState.player_data.memory_shards >= cost
	var accent: Color = _get_memory_placeholder_color(item)
	var current_shards: int = mini(scene.GameState.player_data.memory_shards, cost)

	var panel: PanelContainer = scene._make_card_panel(accent if unlocked else Color(0.42, 0.42, 0.46, 0.94))
	var margin: MarginContainer = scene._make_card_margin()
	panel.add_child(margin)

	var card: VBoxContainer = VBoxContainer.new()
	card.add_theme_constant_override("separation", 10)
	margin.add_child(card)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	card.add_child(header)

	var display_name: String = str(item.get("displayName", ""))
	var title_lbl: Label = Label.new()
	title_lbl.text = display_name
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var preview: Control = Control.new()
	preview.custom_minimum_size = Vector2(0.0, 176.0)
	card.add_child(preview)

	var preview_bg: ColorRect = ColorRect.new()
	preview_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_bg.color = accent
	preview.add_child(preview_bg)

	var photo_path: String = AssetResolver.resolve_catalog_path(item.get("imagePath", ""))
	var texture: Texture2D = AssetResolver.load_texture(photo_path)
	if texture != null:
		var photo: TextureRect = TextureRect.new()
		photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		photo.texture = texture
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview.add_child(photo)

	if not unlocked:
		var overlay: ColorRect = ColorRect.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.color = Color(0.0, 0.0, 0.0, 0.66)
		preview.add_child(overlay)

	var preview_text: Label = Label.new()
	preview_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_text.add_theme_font_size_override("font_size", 28)
	preview_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	preview_text.text = display_name if unlocked else UiText.SCOOPER_MEMORY_LOCKED
	preview.add_child(preview_text)

	var desc: Label = Label.new()
	desc.text = str(item.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80, 1.0))
	card.add_child(desc)

	var bonus: Label = Label.new()
	bonus.text = UiText.SCOOPER_MEMORY_BONUS_PREFIX % _memory_bonus_desc(item)
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus.add_theme_font_size_override("font_size", 17)
	bonus.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0, 1.0))
	card.add_child(bonus)

	var action_btn: Button = Button.new()
	action_btn.custom_minimum_size = Vector2(190.0, 42.0)
	action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(action_btn)

	if unlocked:
		action_btn.text = UiText.SCOOPER_MEMORY_UNLOCKED_BUTTON
		action_btn.disabled = true
	elif can_unlock and not api_locked:
		action_btn.text = UiText.SCOOPER_MEMORY_UNLOCK_BUTTON % [current_shards, cost]
		action_btn.pressed.connect(func() -> void:
			_confirm_unlock_memory(scene, memory_id, item)
		)
	else:
		action_btn.text = UiText.SCOOPER_MEMORY_UNLOCK_NEED % [current_shards, cost]
		action_btn.disabled = true

	return panel


func _confirm_unlock_memory(scene: Control, memory_id: int, memory_item: Dictionary) -> void:
	var cost: int = int(memory_item.get("unlockCost", 0))
	var display_name: String = str(memory_item.get("displayName", ""))
	scene.DialogManager.show_confirm(
		UiText.SCOOPER_MEMORY_CONFIRM_TITLE,
		UiText.SCOOPER_MEMORY_CONFIRM_BODY % [
			cost,
			display_name,
			_memory_bonus_desc(memory_item),
		],
		func() -> void:
			if scene._api_in_flight:
				return
			scene._api_in_flight = true
			_refresh_memory_tab(scene)
			scene.ApiClient.unlock_memory(memory_id, func(ok: bool, data: Variant, err: Dictionary) -> void:
				scene._api_in_flight = false
				_refresh_memory_tab(scene)
				if not ok:
					scene.DialogManager.show_info(
						UiText.SCOOPER_MEMORY_CONFIRM_FAILED,
						str(err.get("message", UiText.SCOOPER_MEMORY_CONFIRM_FAILED_DEFAULT))
					)
					return

				var result: Dictionary = data if data is Dictionary else {}
				scene.GameState.player_data.memory_shards = int(result.get("remainingMemoryShards", scene.GameState.player_data.memory_shards))
				scene._refresh_resource_label()
				scene.DialogManager.show_info(
					UiText.SCOOPER_MEMORY_CONFIRM_SUCCESS,
					"%s\n%s" % [display_name, _memory_bonus_desc(memory_item)]
				)
				scene.refresh_from_bootstrap(func(refresh_ok: bool, _refresh_data: Variant, refresh_err: Dictionary) -> void:
					if not refresh_ok:
						scene.DialogManager.show_info(
							UiText.SCOOPER_MEMORY_REFRESH_FAILED,
							str(refresh_err.get("message", UiText.SCOOPER_MEMORY_REFRESH_FAILED_DEFAULT))
						)
				)
			)
	)


func _memory_bonus_desc(item: Dictionary) -> String:
	var stat: String = str(item.get("bonusStatType", ""))
	var target: String = str(item.get("bonusTarget", "All"))
	var value: float = float(item.get("bonusValue", 0.0))
	var target_str: String = UiText.SCOOPER_EQUIPMENT_BONUS_ALL if target.to_lower() == "all" else target
	var stat_str: String = stat
	match stat:
		"atk_percent", "AtkPercent":
			stat_str = "ATK"
		"def_percent", "DefPercent":
			stat_str = "DEF"
		"max_hp_percent", "MaxHpPercent":
			stat_str = "HP"
		"crit_rate", "CritRate":
			stat_str = "CRIT"
		"crit_damage", "CritDamage":
			stat_str = "CRIT DMG"
	return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, stat_str, value * 100.0]


func _get_memory_placeholder_color(item: Dictionary) -> Color:
	var raw_color: String = str(item.get("placeholderColor", "#6B7280"))
	return Color.from_string(raw_color, Color(0.42, 0.45, 0.50, 1.0))


func _is_api_locked(scene: Control) -> bool:
	return bool(scene._api_in_flight)
