extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const RedDotService = preload("res://scripts/ui/red_dot_service.gd")
const ACTION_COOLDOWN: float = 0.5


func build(scene: Control) -> void:
	var summary_row: HBoxContainer = HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 10)
	scene._tab_content.add_child(summary_row)

	var section_label: Label = Label.new()
	section_label.text = UiText.SCOOPER_TAB_EQUIPMENT
	section_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(section_label)

	var summary: Label = Label.new()
	summary.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(summary)
	scene._level_label = summary

	scene._tab_content.add_child(scene._make_separator())

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(scroll)
	scene._equip_scroller = InertialScroller.attach(scroll, "vertical")

	scene._equip_list = VBoxContainer.new()
	scene._equip_list.add_theme_constant_override("separation", 10)
	scene._equip_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._equip_list)

	_refresh_equipment_tab(scene)


func process(scene: Control, _delta: float) -> void:
	for node_variant: Variant in scene._equipment_cooldown_nodes:
		var node_info: Dictionary = node_variant
		var overlay: ColorRect = node_info.get("overlay", null)
		var label: Label = node_info.get("label", null)
		var button: Button = node_info.get("button", null)
		if overlay == null or label == null or button == null:
			continue

		var is_active: bool = (
			scene._equipment_action_cooldown_remaining > 0.0
			and int(node_info.get("equipment_id", 0)) == scene._equipment_cooldown_equipment_id
			and str(node_info.get("action", "")) == scene._equipment_cooldown_action
		)
		if not is_active:
			overlay.visible = false
			label.visible = false
			continue

		var ratio: float = clampf(
			scene._equipment_action_cooldown_remaining / scene._equipment_action_cooldown_duration,
			0.0,
			1.0
		)
		var button_size: Vector2 = button.size
		overlay.visible = true
		overlay.position = Vector2(button_size.x * (1.0 - ratio), 0.0)
		overlay.size = Vector2(button_size.x * ratio, button_size.y)
		label.visible = false
		label.position = Vector2.ZERO
		label.size = button_size


func _refresh_equipment_tab(scene: Control) -> void:
	var items: Array = scene.GameState.scooper_equipment_data
	if scene._level_label != null:
		var owned_count: int = 0
		for item: Dictionary in items:
			if bool(item.get("isOwned", false)):
				owned_count += 1
		scene._level_label.text = UiText.SCOOPER_EQUIPMENT_SUMMARY_FORMAT % [owned_count, items.size()]

	if scene._equip_list == null:
		return

	scene._equipment_cooldown_nodes.clear()
	for child: Node in scene._equip_list.get_children():
		child.queue_free()

	if items.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = UiText.SCOOPER_EQUIPMENT_EMPTY
		empty_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._equip_list.add_child(empty_lbl)
		return

	var sorted_items: Array = items.duplicate()
	sorted_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_owned: bool = bool(a.get("isOwned", false))
		var b_owned: bool = bool(b.get("isOwned", false))
		if a_owned != b_owned:
			return a_owned and not b_owned
		return int(a.get("equipmentId", 0)) < int(b.get("equipmentId", 0))
	)

	var first_item: bool = true
	for item: Dictionary in sorted_items:
		if not first_item:
			scene._equip_list.add_child(scene._make_separator())
		scene._equip_list.add_child(_make_equip_card(scene, item))
		first_item = false


func _make_equip_card(scene: Control, item: Dictionary) -> Control:
	var equip_id: int = int(item.get("equipmentId", 0))
	var api_locked: bool = _is_api_locked(scene)
	var name_str: String = str(item.get("displayName", ""))
	var unlock_lv: int = int(item.get("unlockLevel", 1))
	var owned: bool = bool(item.get("isOwned", false))
	var level: int = int(item.get("level", 0))
	var exp_val: int = int(item.get("currentExp", 0))
	var broken: bool = bool(item.get("isBroken", false))
	var purchase_cost: int = int(item.get("purchaseCost", 0))
	var upgrade_cost: int = int(item.get("upgradeCost", 0))
	var sick_cat_name_variant: Variant = item.get("sickCatName", "")
	var sick_cat_name: String = "" if sick_cat_name_variant == null else str(sick_cat_name_variant)
	var scooper_lv: int = int(item.get("scooperLevel", scene.GameState.player_data.scooper_level))
	var exp_per_lv: int = int(item.get("expPerLevel", 10))
	var is_level_capped: bool = level >= scooper_lv
	var locked: bool = (not owned) and scooper_lv < unlock_lv
	var treat_mode: bool = sick_cat_name != ""

	var accent: Color = Color(0.48, 0.42, 0.32, 0.92)
	if broken:
		accent = Color(0.84, 0.40, 0.34, 0.94)
	elif treat_mode:
		accent = Color(0.88, 0.73, 0.34, 0.94)
	elif owned:
		accent = Color(0.52, 0.76, 0.95, 0.94)

	var panel: PanelContainer = scene._make_card_panel(accent)
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	panel.add_child(margin)

	var card: HBoxContainer = HBoxContainer.new()
	card.add_theme_constant_override("separation", 10)
	margin.add_child(card)

	var equipment_icon: Texture2D = AssetResolver.resolve_equipment_icon(item)
	var icon_frame: PanelContainer = PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(132.0, 132.0)
	icon_frame.add_theme_stylebox_override("panel", _make_icon_frame_style())
	card.add_child(icon_frame)

	var icon_margin: MarginContainer = MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_left", 8)
	icon_margin.add_theme_constant_override("margin_top", 8)
	icon_margin.add_theme_constant_override("margin_right", 8)
	icon_margin.add_theme_constant_override("margin_bottom", 8)
	icon_frame.add_child(icon_margin)

	var icon_center: CenterContainer = CenterContainer.new()
	icon_margin.add_child(icon_center)

	if equipment_icon != null:
		icon_center.add_child(AssetResolver.create_icon_rect(equipment_icon, Vector2(104.0, 104.0)))
	else:
		var icon_placeholder: ColorRect = ColorRect.new()
		icon_placeholder.color = Color(0.24, 0.24, 0.28, 0.95)
		icon_placeholder.custom_minimum_size = Vector2(104.0, 104.0)
		icon_center.add_child(icon_placeholder)

	var content_block: VBoxContainer = VBoxContainer.new()
	content_block.add_theme_constant_override("separation", 8)
	content_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(content_block)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	content_block.add_child(title_row)

	var title_lbl: Label = Label.new()
	title_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title_lbl)

	var detail_row: HBoxContainer = HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 10)
	content_block.add_child(detail_row)

	var desc_lbl: Label = Label.new()
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc_lbl.add_theme_color_override("font_color", Color(0.84, 0.84, 0.82, 1.0))
	detail_row.add_child(desc_lbl)

	var exp_inline_lbl: Label = Label.new()
	exp_inline_lbl.custom_minimum_size = Vector2(220.0, 0.0)
	exp_inline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	exp_inline_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_inline_lbl.add_theme_font_size_override("font_size", 13)
	exp_inline_lbl.add_theme_color_override("font_color", Color(0.78, 0.88, 0.98, 1.0))
	detail_row.add_child(exp_inline_lbl)

	var title_right: HBoxContainer = HBoxContainer.new()
	title_right.add_theme_constant_override("separation", 8)
	title_row.add_child(title_right)

	var status_badge: Control = _make_info_chip("", Color(0.26, 0.32, 0.38, 0.96), Color(0.72, 0.82, 0.95, 0.95))
	title_right.add_child(status_badge)

	var exp_row: HBoxContainer = HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 10)
	exp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content_block.add_child(exp_row)

	var exp_bar: ProgressBar = ProgressBar.new()
	exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_bar.custom_minimum_size = Vector2(0.0, 22.0)
	exp_bar.show_percentage = false
	exp_bar.min_value = 0.0
	exp_bar.max_value = maxf(1.0, float(exp_per_lv))
	exp_bar.value = exp_bar.max_value if is_level_capped else clampf(float(exp_val), 0.0, exp_bar.max_value)
	exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiPalette.style_exp_progress_bar(exp_bar, "max" if is_level_capped else "normal")
	exp_row.add_child(exp_bar)

	var exp_overlay: CenterContainer = CenterContainer.new()
	exp_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exp_bar.add_child(exp_overlay)

	var exp_label: Label = Label.new()
	exp_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	exp_label.add_theme_color_override("font_color", UiPalette.EXP_BAR_MAX_TEXT if is_level_capped else UiPalette.EXP_BAR_TEXT)
	exp_label.text = UiText.SCOOPER_EQUIPMENT_EXP_MAX if is_level_capped else UiText.SCOOPER_EQUIPMENT_EXP_FORMAT % [exp_val, exp_per_lv]
	exp_overlay.add_child(exp_label)

	var action_row: HBoxContainer = HBoxContainer.new()
	content_block.add_child(action_row)

	var action_btn: Button = Button.new()
	action_btn.custom_minimum_size = Vector2(0.0, 44.0)
	action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiPalette.apply_button_kind(action_btn, "confirm")
	action_row.add_child(action_btn)

	if locked:
		title_lbl.text = "%s %s" % [UiText.SCOOPER_EQUIPMENT_LOCKED_PREFIX, name_str]
		title_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
		desc_lbl.text = _bonus_desc(item, 0)
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_UNLOCK_AT % unlock_lv
		_set_chip_text(status_badge, UiText.SCOOPER_EQUIPMENT_BADGE_LOCKED)
		_set_chip_colors(status_badge, Color(0.30, 0.30, 0.34, 0.96), Color(0.82, 0.82, 0.86, 1.0))
		exp_bar.max_value = 1.0
		exp_bar.value = 0.0
		UiPalette.style_exp_progress_bar(exp_bar, "normal")
		exp_label.add_theme_color_override("font_color", UiPalette.EXP_BAR_TEXT)
		exp_label.text = "0/0"
		action_btn.text = UiText.SCOOPER_EQUIPMENT_ACTION_LOCKED_BUTTON
		action_btn.disabled = true
		_add_locked_overlay(panel, unlock_lv)
		return panel

	if not owned:
		var can_afford_purchase: bool = scene.GameState.player_data.gold >= purchase_cost
		title_lbl.text = name_str
		desc_lbl.text = _bonus_desc(item, 1)
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_UNOWNED % purchase_cost if can_afford_purchase else UiText.SCOOPER_EQUIPMENT_COST_INSUFFICIENT % purchase_cost
		_set_chip_text(status_badge, UiText.SCOOPER_EQUIPMENT_BADGE_UNOWNED)
		_set_chip_colors(status_badge, Color(0.31, 0.26, 0.16, 0.96), Color(0.96, 0.87, 0.58, 1.0))
		exp_bar.max_value = 1.0
		exp_bar.value = 0.0
		UiPalette.style_exp_progress_bar(exp_bar, "normal")
		exp_label.add_theme_color_override("font_color", UiPalette.EXP_BAR_TEXT)
		exp_label.text = "0/0"
		action_btn.text = UiText.SCOOPER_EQUIPMENT_ACTION_UNOWNED_BUTTON if can_afford_purchase else UiText.SCOOPER_EQUIPMENT_ACTION_INSUFFICIENT_GOLD_BUTTON
		action_btn.disabled = api_locked or not can_afford_purchase
		RedDotService.refresh_dot(action_btn, can_afford_purchase and not api_locked)
		if not can_afford_purchase:
			action_btn.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42, 1.0))
		action_btn.pressed.connect(func() -> void:
			if not _is_scene_alive(scene):
				return
			scene.DialogManager.show_confirm(
				UiText.SCOOPER_EQUIPMENT_UNLOCK_CONFIRM_TITLE,
				UiText.SCOOPER_EQUIPMENT_UNLOCK_CONFIRM_BODY % [purchase_cost, name_str],
				func() -> void:
					if not _is_scene_alive(scene):
						return
					_do_equipment_action(scene, "purchase", equip_id)
			)
		)
		return panel

	title_lbl.text = "%s Lv.%d" % [name_str, level]
	desc_lbl.text = _bonus_desc(item, maxi(level, 1))
	exp_inline_lbl.text = ""

	if broken:
		var repair_cost: int = int(item.get("repairCost", 0))
		var can_afford_repair: bool = scene.GameState.player_data.gold >= repair_cost
		_set_chip_text(status_badge, UiText.SCOOPER_EQUIPMENT_BADGE_BROKEN)
		_set_chip_colors(status_badge, Color(0.37, 0.16, 0.16, 0.96), Color(1.0, 0.80, 0.76, 1.0))
		title_lbl.text = "%s %s" % [UiText.SCOOPER_EQUIPMENT_BROKEN_PREFIX, title_lbl.text]
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.76, 0.72, 1.0))
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_REPAIR % repair_cost if can_afford_repair else UiText.SCOOPER_EQUIPMENT_COST_INSUFFICIENT % repair_cost
		action_btn.text = UiText.SCOOPER_EQUIPMENT_ACTION_REPAIR_BUTTON if can_afford_repair else UiText.SCOOPER_EQUIPMENT_ACTION_INSUFFICIENT_GOLD_BUTTON
		_register_cooldown_button(scene, action_btn, equip_id, "repair")
		action_btn.disabled = api_locked or _is_action_cooling(scene, equip_id, "repair") or not can_afford_repair
		if not can_afford_repair:
			action_btn.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42, 1.0))
		action_btn.pressed.connect(func() -> void:
			_do_equipment_action(scene, "repair", equip_id)
		)
		return panel

	if treat_mode:
		var treat_cost: int = int(item.get("treatCost", 0))
		var can_afford_treat: bool = scene.GameState.player_data.gold >= treat_cost
		_set_chip_text(status_badge, UiText.SCOOPER_EQUIPMENT_BADGE_SICK)
		_set_chip_colors(status_badge, Color(0.36, 0.28, 0.12, 0.96), Color(1.0, 0.92, 0.72, 1.0))
		title_lbl.text = "%s %s" % [UiText.SCOOPER_EQUIPMENT_SICK_PREFIX, title_lbl.text]
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_TREAT % treat_cost if can_afford_treat else UiText.SCOOPER_EQUIPMENT_COST_INSUFFICIENT % treat_cost
		action_btn.text = UiText.SCOOPER_EQUIPMENT_ACTION_TREAT_BUTTON if can_afford_treat else UiText.SCOOPER_EQUIPMENT_ACTION_INSUFFICIENT_GOLD_BUTTON
		_register_cooldown_button(scene, action_btn, equip_id, "treat")
		action_btn.disabled = api_locked or _is_action_cooling(scene, equip_id, "treat") or not can_afford_treat
		if not can_afford_treat:
			action_btn.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42, 1.0))
		action_btn.pressed.connect(func() -> void:
			_do_equipment_action(scene, "treat", equip_id)
		)
		return panel

	_set_chip_text(status_badge, UiText.SCOOPER_EQUIPMENT_BADGE_MAX if is_level_capped else UiText.SCOOPER_EQUIPMENT_BADGE_READY)
	if is_level_capped:
		_set_chip_colors(status_badge, Color(0.32, 0.20, 0.38, 0.96), Color(0.92, 0.82, 1.0, 1.0))
		UiPalette.style_exp_progress_bar(exp_bar, "max")
		exp_label.add_theme_color_override("font_color", UiPalette.EXP_BAR_MAX_TEXT)
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_MAX
	else:
		_set_chip_colors(status_badge, Color(0.14, 0.33, 0.24, 0.96), Color(0.80, 1.0, 0.87, 1.0))
		UiPalette.style_exp_progress_bar(exp_bar, "ready")
		exp_label.add_theme_color_override("font_color", UiPalette.EXP_BAR_READY_TEXT)
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_UPGRADE % upgrade_cost
	action_btn.text = UiText.SCOOPER_EQUIPMENT_ACTION_UPGRADE_BUTTON
	var can_afford_upgrade: bool = scene.GameState.player_data.gold >= upgrade_cost
	var cooldown_ready: bool = not _is_action_cooling(scene, equip_id, "upgrade")
	var can_upgrade: bool = not is_level_capped and cooldown_ready
	action_btn.disabled = api_locked or not can_upgrade
	_register_cooldown_button(scene, action_btn, equip_id, "upgrade")
	if not can_afford_upgrade:
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_INSUFFICIENT % upgrade_cost
		action_btn.text = UiText.SCOOPER_EQUIPMENT_ACTION_INSUFFICIENT_GOLD_BUTTON
		action_btn.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42, 1.0))
		action_btn.disabled = true
	elif is_level_capped and not api_locked:
		action_btn.disabled = false
		action_btn.text = UiText.SCOOPER_EQUIPMENT_LEVEL_MAX
		action_btn.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42, 1.0))
		action_btn.disabled = true

	action_btn.pressed.connect(func() -> void:
		if is_level_capped:
			scene.DialogManager.show_info(
				UiText.SCOOPER_EQUIPMENT_LEVEL_MAX,
				UiText.SCOOPER_EQUIPMENT_LEVEL_UP_HINT
			)
			return
		if not can_afford_upgrade:
			return
		_do_equipment_action(scene, "upgrade", equip_id)
	)
	return panel


func _do_equipment_action(scene: Control, action: String, equip_id: int) -> void:
	if scene._api_in_flight:
		return
	if _is_action_cooling(scene, equip_id, action):
		return
	scene._api_in_flight = true
	_refresh_equipment_tab(scene)

	var on_error: Callable = func(err: Dictionary) -> void:
		if not _is_scene_alive(scene):
			return
		scene._api_in_flight = false
		_refresh_equipment_tab(scene)
		if action == "upgrade":
			_refresh_equipment_after_action(scene)
			return
		scene.DialogManager.show_info(
			UiText.SCOOPER_EQUIPMENT_ACTION_FAILED % _action_label(action),
			str(err.get("message", UiText.SCOOPER_EQUIPMENT_ACTION_FAILED_DEFAULT))
		)

	match action:
		"purchase":
			scene.ApiClient.purchase_equipment(equip_id, func(ok: bool, _data: Variant, err: Dictionary) -> void:
				if not _is_scene_alive(scene):
					return
				if not ok:
					on_error.call(err)
					return
				_refresh_equipment_after_action(scene)
			)
		"upgrade":
			scene.ApiClient.upgrade_equipment_silent(equip_id, func(ok: bool, data: Variant, err: Dictionary) -> void:
				if not _is_scene_alive(scene):
					return
				if not ok:
					on_error.call(err)
					return
				var result: Dictionary = data if data is Dictionary else {}
				var reward_entries: Array[Dictionary] = []
				var gained: int = int(result.get("expGained", 0))
				if gained > 0:
					reward_entries.append(scene.make_reward_float_entry(UiText.REWARD_EXP, gained, "exp"))
				if not reward_entries.is_empty():
					scene.queue_home_reward_floats(reward_entries)
				_start_action_cooldown(scene, equip_id, action)
				_refresh_equipment_after_action(scene)
			)
		"repair":
			scene.ApiClient.repair_equipment_silent(equip_id, func(ok: bool, _data: Variant, err: Dictionary) -> void:
				if not _is_scene_alive(scene):
					return
				if not ok:
					on_error.call(err)
					return
				_start_action_cooldown(scene, equip_id, action)
				_refresh_equipment_after_action(scene)
			)
		"treat":
			scene.ApiClient.treat_equipment_silent(equip_id, func(ok: bool, _data: Variant, err: Dictionary) -> void:
				if not _is_scene_alive(scene):
					return
				if not ok:
					on_error.call(err)
					return
				_start_action_cooldown(scene, equip_id, action)
				_refresh_equipment_after_action(scene)
			)


func _refresh_equipment_after_action(scene: Control) -> void:
	scene.ApiClient.get_scooper_profile_silent(func(profile_ok: bool, profile_data: Variant, _profile_err: Dictionary) -> void:
		if not _is_scene_alive(scene):
			return
		if profile_ok and profile_data is Dictionary:
			scene.GameState.update_scooper_profile(profile_data)
			scene._refresh_resource_label()

		scene.ApiClient.get_equipment_list_silent(func(ok: bool, data: Variant, err: Dictionary) -> void:
			if not _is_scene_alive(scene):
				return
			scene._api_in_flight = false
			if ok and data is Array:
				scene.GameState.update_scooper_equipment(data)
				_refresh_equipment_tab(scene)
				return
			_refresh_equipment_tab(scene)
			scene.DialogManager.show_info(
				UiText.SCOOPER_EQUIPMENT_REFRESH_FAILED,
				str(err.get("message", UiText.SCOOPER_EQUIPMENT_REFRESH_FAILED_DEFAULT))
			)
		)
	)


func _action_label(action: String) -> String:
	match action:
		"purchase":
			return UiText.SCOOPER_EQUIPMENT_ACTION_PURCHASE
		"repair":
			return UiText.SCOOPER_EQUIPMENT_ACTION_REPAIR
		"treat":
			return UiText.SCOOPER_EQUIPMENT_ACTION_TREAT
		"upgrade":
			return UiText.SCOOPER_EQUIPMENT_ACTION_UPGRADE
		_:
			return action


func _bonus_desc(item: Dictionary, level: int) -> String:
	var stat: String = str(item.get("bonusStat", ""))
	var target: String = str(item.get("bonusTarget", "All"))
	var per_lv: float = float(item.get("bonusPerLevel", 0.0))
	var target_str: String = UiText.SCOOPER_EQUIPMENT_BONUS_ALL if target.to_lower() == "all" else target
	var stat_str: String = stat
	match stat:
		"atk_percent", "AtkPercent":
			stat_str = "ATK"
		"def_percent", "DefPercent":
			stat_str = "DEF"
		"max_hp_percent", "MaxHpPercent":
			stat_str = "HP"

	if level <= 0:
		return UiText.SCOOPER_EQUIPMENT_BONUS_PER_LEVEL % [target_str, stat_str, per_lv * 100.0]
	return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, stat_str, per_lv * float(level) * 100.0]


func _add_unlock_overlay(scene: Control, panel: PanelContainer, unlock_cost: int, equip_id: int, item_name: String) -> void:
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 5
	panel.add_child(overlay)

	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.10)
	overlay.add_child(shade)

	var unlock_btn: Button = Button.new()
	unlock_btn.text = UiText.SCOOPER_EQUIPMENT_ACTION_UNOWNED_BUTTON
	unlock_btn.custom_minimum_size = Vector2(200.0, 50.0)
	unlock_btn.anchor_left = 0.5
	unlock_btn.anchor_top = 0.5
	unlock_btn.anchor_right = 0.5
	unlock_btn.anchor_bottom = 0.5
	unlock_btn.offset_left = -100.0
	unlock_btn.offset_top = -25.0
	unlock_btn.offset_right = 100.0
	unlock_btn.offset_bottom = 25.0
	unlock_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	unlock_btn.disabled = true
	if unlock_btn.disabled:
		unlock_btn.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42, 1.0))
	overlay.add_child(unlock_btn)


func _add_locked_overlay(panel: PanelContainer, unlock_lv: int) -> void:
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 5
	panel.add_child(overlay)

	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.56)
	overlay.add_child(shade)

	var locked_lbl: Label = Label.new()
	locked_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	locked_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	locked_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	locked_lbl.text = UiText.SCOOPER_EQUIPMENT_LOCKED_LEVEL_FORMAT % unlock_lv
	overlay.add_child(locked_lbl)


func _register_cooldown_button(scene: Control, button: Button, equip_id: int, action: String) -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.42)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	button.add_child(overlay)

	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	label.visible = false
	button.add_child(label)

	scene._equipment_cooldown_nodes.append({
		"button": button,
		"overlay": overlay,
		"label": label,
		"equipment_id": equip_id,
		"action": action,
	})


func _start_action_cooldown(scene: Control, equip_id: int, action: String) -> void:
	scene._equipment_action_cooldown_duration = ACTION_COOLDOWN
	scene._equipment_action_cooldown_remaining = ACTION_COOLDOWN
	scene._equipment_cooldown_equipment_id = equip_id
	scene._equipment_cooldown_action = action
	scene._equipment_upgrade_cooldown_remaining = ACTION_COOLDOWN


func _is_action_cooling(scene: Control, equip_id: int, action: String) -> bool:
	return (
		scene._equipment_action_cooldown_remaining > 0.0
		and scene._equipment_cooldown_equipment_id == equip_id
		and scene._equipment_cooldown_action == action
	)


func _is_scene_alive(scene: Control) -> bool:
	return scene != null and is_instance_valid(scene)


func _is_api_locked(scene: Control) -> bool:
	return bool(scene._api_in_flight)


func _make_info_chip(text: String, bg_color: Color, font_color: Color) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", font_color)
	panel.add_child(label)
	return panel


func _set_chip_text(chip: Control, text: String) -> void:
	if chip == null or chip.get_child_count() == 0:
		return
	var label: Label = chip.get_child(0) as Label
	if label != null:
		label.text = text


func _set_chip_colors(chip: Control, bg_color: Color, font_color: Color) -> void:
	if chip == null:
		return
	var style: StyleBoxFlat = chip.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		var style_copy: StyleBoxFlat = style.duplicate()
		style_copy.bg_color = bg_color
		chip.add_theme_stylebox_override("panel", style_copy)
	if chip.get_child_count() == 0:
		return
	var label: Label = chip.get_child(0) as Label
	if label != null:
		label.add_theme_color_override("font_color", font_color)


func _make_icon_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22, 0.96)
	style.border_color = Color(0.52, 0.76, 0.95, 0.40)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	return style
