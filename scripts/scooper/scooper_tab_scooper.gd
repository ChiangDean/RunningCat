extends RefCounted

const CARD_TEMPLATE: PackedScene = preload("res://scenes/ui/scooper/equipment/ScooperEquipmentCardTemplate.tscn")
const ACTION_COOLDOWN: float = 0.5
const EFFECT_COLUMN_X: Array[float] = [173.0, 318.0, 463.0]
const EFFECT_ROW_Y: Array[float] = [65.0, 86.0, 107.0]
const EFFECT_COLUMN_W: float = 136.0
const EFFECT_ROW_H: float = 21.0
const FILTER_AVAILABLE: String = "available"
const FILTER_LOCKED: String = "locked"
const FILTER_MAXED: String = "maxed"
const EQUIPMENT_MAX_LEVEL: int = 10


func build(scene: Control) -> void:
	scene._level_label = scene._tab_header_summary
	if scene._level_label == null:
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
		summary.add_theme_color_override("font_color", Color(0.97, 0.88, 0.68, 1.0))
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_row.add_child(summary)
		scene._level_label = summary

	_add_equipment_filter_row(scene)

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

	var current_filter: String = _get_current_filter(scene)
	var scooper_lv: int = int(scene.GameState.player_data.scooper_level)
	var sorted_items: Array = []
	for item_variant: Variant in items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if _get_equipment_filter_bucket(item, scooper_lv) == current_filter:
			sorted_items.append(item)
	sorted_items.sort_custom(_sort_scooper_items)

	if sorted_items.is_empty():
		var filter_empty_lbl: Label = Label.new()
		filter_empty_lbl.text = _get_filter_empty_text(current_filter)
		filter_empty_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		filter_empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._equip_list.add_child(filter_empty_lbl)
		return

	for item: Dictionary in sorted_items:
		scene._equip_list.add_child(_make_equip_card(scene, item))


func _add_equipment_filter_row(scene: Control) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(row)

	var group: ButtonGroup = ButtonGroup.new()
	var options: Array[Dictionary] = [
		{"key": FILTER_AVAILABLE, "text": UiText.SCOOPER_EQUIPMENT_FILTER_AVAILABLE},
		{"key": FILTER_LOCKED, "text": UiText.SCOOPER_EQUIPMENT_FILTER_LOCKED},
		{"key": FILTER_MAXED, "text": UiText.SCOOPER_EQUIPMENT_FILTER_MAXED},
	]
	for option: Dictionary in options:
		var button: Button = Button.new()
		button.text = str(option.get("text", ""))
		button.toggle_mode = true
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 36.0)
		button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
		UiPalette.apply_button_kind(button, "confirm" if str(option.get("key", "")) == _get_current_filter(scene) else "neutral")
		button.button_pressed = str(option.get("key", "")) == _get_current_filter(scene)
		button.pressed.connect(Callable(self, "_set_equipment_filter").bind(scene, str(option.get("key", ""))))
		row.add_child(button)


func _set_equipment_filter(scene: Control, filter_key: String) -> void:
	if not _is_scene_alive(scene):
		return
	scene._equipment_filter = filter_key
	scene.call("_rebuild_tab_content")


func _get_current_filter(scene: Control) -> String:
	var current_filter: String = str(scene._equipment_filter)
	if current_filter in [FILTER_AVAILABLE, FILTER_LOCKED, FILTER_MAXED]:
		return current_filter
	return FILTER_AVAILABLE


func _get_equipment_filter_bucket(item: Dictionary, scooper_lv: int) -> String:
	var owned: bool = bool(item.get("isOwned", false))
	var level: int = int(item.get("level", 0))
	var unlock_lv: int = int(item.get("unlockLevel", 1))
	var locked: bool = (not owned) and scooper_lv < unlock_lv
	if locked:
		return FILTER_LOCKED
	if owned and level >= EQUIPMENT_MAX_LEVEL:
		return FILTER_MAXED
	return FILTER_AVAILABLE


func _get_filter_empty_text(filter_key: String) -> String:
	match filter_key:
		FILTER_LOCKED:
			return UiText.SCOOPER_EQUIPMENT_FILTER_EMPTY_LOCKED
		FILTER_MAXED:
			return UiText.SCOOPER_EQUIPMENT_FILTER_EMPTY_MAXED
		_:
			return UiText.SCOOPER_EQUIPMENT_FILTER_EMPTY_AVAILABLE


func _format_equipment_title(name_str: String, level: int) -> String:
	return "%s (%d/%d)" % [name_str, clampi(level, 0, EQUIPMENT_MAX_LEVEL), EQUIPMENT_MAX_LEVEL]


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
	var current_level_cap: int = mini(scooper_lv, EQUIPMENT_MAX_LEVEL)
	var is_level_capped: bool = owned and level >= current_level_cap
	var locked: bool = (not owned) and scooper_lv < unlock_lv
	var treat_mode: bool = sick_cat_name != ""

	var accent: Color = Color(0.48, 0.42, 0.32, 0.92)
	if broken:
		accent = Color(0.84, 0.40, 0.34, 0.94)
	elif treat_mode:
		accent = Color(0.88, 0.73, 0.34, 0.94)
	elif owned:
		accent = Color(0.52, 0.76, 0.95, 0.94)

	var panel: Control = CARD_TEMPLATE.instantiate() as Control
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var panel_background: TextureRect = panel.get_node("Frame") as TextureRect
	if panel_background != null:
		panel_background.modulate = accent.lightened(0.18)
	var icon_rect: TextureRect = panel.get_node("Icon") as TextureRect
	var level_lbl: Label = panel.get_node("LevelLabel") as Label
	var title_lbl: Label = panel.get_node("NameLabel") as Label
	var desc_lbl: Label = panel.get_node("MetaLabel") as Label
	var exp_inline_lbl: Label = panel.get_node("CostLabel") as Label
	var progress_frame: Panel = panel.get_node("ProgressFrame") as Panel
	var progress_fill: ColorRect = panel.get_node("ProgressFrame/ProgressFill") as ColorRect
	var exp_label: Label = panel.get_node("ProgressFrame/ProgressLabel") as Label
	var action_visual: Panel = panel.get_node("ActionButtonVisual") as Panel
	var action_label: Label = panel.get_node("ActionButtonVisual/ActionLabel") as Label
	var action_btn: Button = panel.get_node("ActionButton") as Button
	_prepare_flat_button(action_btn)
	_set_panel_fill(progress_frame, Color(0.19, 0.17, 0.15, 0.92))

	if icon_rect != null:
		AssetResolver.apply_equipment_icon_texture(icon_rect, item)
		icon_rect.visible = icon_rect.texture != null
	level_lbl.visible = owned
	level_lbl.text = str(level)
	title_lbl.text = _format_equipment_title(name_str, level if owned else 0)
	desc_lbl.visible = false
	_apply_effect_summary_layout(panel, item, maxi(level, 1) if owned else 1)
	exp_inline_lbl.text = ""

	if locked:
		level_lbl.visible = false
		title_lbl.text = _format_equipment_title(name_str, 0)
		title_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
		_apply_effect_summary_layout(panel, item, 0)
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_UNLOCK_AT % unlock_lv
		_set_progress_fill(progress_fill, 0.0, 440.0)
		_set_panel_fill(progress_frame, Color(0.19, 0.17, 0.15, 0.92))
		exp_label.add_theme_color_override("font_color", Color(0.97, 0.98, 0.94, 1.0))
		exp_label.text = "0/0"
		_set_action_visual(action_visual, action_label, Color(0.19, 0.17, 0.15, 0.92), Color(0.82, 0.72, 0.54, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_LOCKED_BUTTON)
		action_btn.disabled = true
		_add_locked_overlay(panel, unlock_lv)
		return panel

	if not owned:
		var can_afford_purchase: bool = scene.GameState.player_data.gold >= purchase_cost
		title_lbl.text = _format_equipment_title(name_str, 0)
		_apply_effect_summary_layout(panel, item, 1)
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_UNOWNED % purchase_cost if can_afford_purchase else UiText.SCOOPER_EQUIPMENT_COST_INSUFFICIENT % purchase_cost
		_set_progress_fill(progress_fill, 0.0, 440.0)
		_set_panel_fill(progress_frame, Color(0.19, 0.17, 0.15, 0.92))
		exp_label.add_theme_color_override("font_color", Color(0.97, 0.98, 0.94, 1.0))
		exp_label.text = "0/0"
		if can_afford_purchase:
			_set_action_visual(action_visual, action_label, Color(0.80, 0.70, 0.42, 1.0), Color(0.36, 0.21, 0.08, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_UNOWNED_BUTTON)
		else:
			_set_action_visual(action_visual, action_label, Color(0.19, 0.17, 0.15, 0.92), Color(1.0, 0.42, 0.42, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_INSUFFICIENT_GOLD_BUTTON)
		action_btn.disabled = api_locked or not can_afford_purchase
		RedDotService.refresh_dot(action_btn, can_afford_purchase and not api_locked)
		action_btn.pressed.connect(Callable(self, "_show_purchase_confirm").bind(scene, purchase_cost, name_str, equip_id))
		return panel

	title_lbl.text = _format_equipment_title(name_str, level)
	_apply_effect_summary_layout(panel, item, maxi(level, 1))
	exp_inline_lbl.text = ""
	_set_progress_fill(progress_fill, exp_bar_ratio(exp_val, exp_per_lv, is_level_capped), 440.0)
	exp_label.add_theme_color_override("font_color", Color(0.97, 0.98, 0.94, 1.0))
	exp_label.text = UiText.SCOOPER_EQUIPMENT_EXP_MAX if is_level_capped else UiText.SCOOPER_EQUIPMENT_EXP_FORMAT % [exp_val, exp_per_lv]

	if broken:
		var repair_cost: int = int(item.get("repairCost", 0))
		var can_afford_repair: bool = scene.GameState.player_data.gold >= repair_cost
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.76, 0.72, 1.0))
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_REPAIR % repair_cost if can_afford_repair else UiText.SCOOPER_EQUIPMENT_COST_INSUFFICIENT % repair_cost
		if can_afford_repair:
			_set_action_visual(action_visual, action_label, Color(0.80, 0.70, 0.42, 1.0), Color(0.36, 0.21, 0.08, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_REPAIR_BUTTON)
		else:
			_set_action_visual(action_visual, action_label, Color(0.19, 0.17, 0.15, 0.92), Color(1.0, 0.42, 0.42, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_INSUFFICIENT_GOLD_BUTTON)
		_register_cooldown_button(scene, action_btn, equip_id, "repair")
		action_btn.disabled = api_locked or _is_action_cooling(scene, equip_id, "repair") or not can_afford_repair
		action_btn.pressed.connect(Callable(self, "_do_equipment_action").bind(scene, "repair", equip_id))
		return panel

	if treat_mode:
		var treat_cost: int = int(item.get("treatCost", 0))
		var can_afford_treat: bool = scene.GameState.player_data.gold >= treat_cost
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_TREAT % treat_cost if can_afford_treat else UiText.SCOOPER_EQUIPMENT_COST_INSUFFICIENT % treat_cost
		if can_afford_treat:
			_set_action_visual(action_visual, action_label, Color(0.80, 0.70, 0.42, 1.0), Color(0.36, 0.21, 0.08, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_TREAT_BUTTON)
		else:
			_set_action_visual(action_visual, action_label, Color(0.19, 0.17, 0.15, 0.92), Color(1.0, 0.42, 0.42, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_INSUFFICIENT_GOLD_BUTTON)
		_register_cooldown_button(scene, action_btn, equip_id, "treat")
		action_btn.disabled = api_locked or _is_action_cooling(scene, equip_id, "treat") or not can_afford_treat
		action_btn.pressed.connect(Callable(self, "_do_equipment_action").bind(scene, "treat", equip_id))
		return panel

	if is_level_capped:
		_set_progress_fill(progress_fill, 1.0, 440.0)
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_MAX
		_set_action_visual(action_visual, action_label, Color(0.19, 0.17, 0.15, 0.92), Color(1.0, 0.42, 0.42, 1.0), UiText.SCOOPER_EQUIPMENT_LEVEL_MAX)
	else:
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_UPGRADE % upgrade_cost
		_set_action_visual(action_visual, action_label, Color(0.80, 0.70, 0.42, 1.0), Color(0.36, 0.21, 0.08, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_UPGRADE_BUTTON)
	var can_afford_upgrade: bool = scene.GameState.player_data.gold >= upgrade_cost
	var cooldown_ready: bool = not _is_action_cooling(scene, equip_id, "upgrade")
	var can_upgrade: bool = not is_level_capped and cooldown_ready
	action_btn.disabled = api_locked or not can_upgrade
	_register_cooldown_button(scene, action_btn, equip_id, "upgrade")
	if not can_afford_upgrade:
		exp_inline_lbl.text = UiText.SCOOPER_EQUIPMENT_COST_INSUFFICIENT % upgrade_cost
		_set_action_visual(action_visual, action_label, Color(0.19, 0.17, 0.15, 0.92), Color(1.0, 0.42, 0.42, 1.0), UiText.SCOOPER_EQUIPMENT_ACTION_INSUFFICIENT_GOLD_BUTTON)
		action_btn.disabled = true
	elif is_level_capped and not api_locked:
		action_btn.disabled = true

	action_btn.pressed.connect(Callable(self, "_on_upgrade_button_pressed").bind(scene, is_level_capped, can_afford_upgrade, equip_id))
	return panel


func _show_purchase_confirm(scene: Control, purchase_cost: int, item_name: String, equip_id: int) -> void:
	if not _is_scene_alive(scene):
		return
	scene.DialogManager.show_confirm(
		UiText.SCOOPER_EQUIPMENT_UNLOCK_CONFIRM_TITLE,
		UiText.SCOOPER_EQUIPMENT_UNLOCK_CONFIRM_BODY % [purchase_cost, item_name],
		Callable(self, "_confirm_purchase_equipment").bind(scene, equip_id)
	)


func _confirm_purchase_equipment(scene: Control, equip_id: int) -> void:
	if not _is_scene_alive(scene):
		return
	_do_equipment_action(scene, "purchase", equip_id)


func _on_upgrade_button_pressed(scene: Control, is_level_capped: bool, can_afford_upgrade: bool, equip_id: int) -> void:
	if not _is_scene_alive(scene):
		return
	if is_level_capped:
		scene.DialogManager.show_info(
			UiText.SCOOPER_EQUIPMENT_LEVEL_MAX,
			UiText.SCOOPER_EQUIPMENT_LEVEL_UP_HINT
		)
		return
	if not can_afford_upgrade:
		return
	_do_equipment_action(scene, "upgrade", equip_id)


func _do_equipment_action(scene: Control, action: String, equip_id: int) -> void:
	if scene._api_in_flight:
		return
	if _is_action_cooling(scene, equip_id, action):
		return
	scene._api_in_flight = true
	_refresh_equipment_tab(scene)

	match action:
		"purchase":
			scene.ApiClient.purchase_equipment_silent(equip_id, Callable(self, "_on_equipment_action_completed").bind(scene, action, equip_id))
		"upgrade":
			scene.ApiClient.upgrade_equipment_silent(equip_id, Callable(self, "_on_equipment_action_completed").bind(scene, action, equip_id))
		"repair":
			scene.ApiClient.repair_equipment_silent(equip_id, Callable(self, "_on_equipment_action_completed").bind(scene, action, equip_id))
		"treat":
			scene.ApiClient.treat_equipment_silent(equip_id, Callable(self, "_on_equipment_action_completed").bind(scene, action, equip_id))


func _on_equipment_action_completed(
	ok: bool,
	data: Variant,
	err: Dictionary,
	scene: Control,
	action: String,
	equip_id: int = 0
) -> void:
	if not _is_scene_alive(scene):
		return
	if not ok:
		scene._api_in_flight = false
		_refresh_equipment_tab(scene)
		if action == "upgrade":
			_refresh_equipment_after_action(scene)
			return
		scene.DialogManager.show_info(
			UiText.SCOOPER_EQUIPMENT_ACTION_FAILED % _action_label(action),
			str(err.get("message", UiText.SCOOPER_EQUIPMENT_ACTION_FAILED_DEFAULT))
		)
		return

	if action == "upgrade":
		var result: Dictionary = data if data is Dictionary else {}
		var reward_entries: Array[Dictionary] = []
		var gained: int = int(result.get("expGained", 0))
		if gained > 0:
			var critical_multiplier: int = int(result.get("expCriticalMultiplier", 1))
			var exp_label: String = UiText.SCOOPER_EQUIPMENT_EXP_CRITICAL % critical_multiplier if critical_multiplier > 1 else UiText.REWARD_EXP
			reward_entries.append(scene.make_reward_float_entry(exp_label, gained, "exp"))
		if not reward_entries.is_empty():
			scene.queue_home_reward_floats(reward_entries)
		_start_action_cooldown(scene, equip_id, action)
	elif action == "repair" or action == "treat":
		_start_action_cooldown(scene, equip_id, action)

	_refresh_equipment_after_action(scene)


func _refresh_equipment_after_action(scene: Control) -> void:
	scene.ApiClient.get_scooper_profile_silent(Callable(self, "_on_refresh_equipment_profile_completed").bind(scene))


func _on_refresh_equipment_profile_completed(refresh_ok: bool, refresh_data: Variant, refresh_err: Dictionary, scene: Control) -> void:
	if not _is_scene_alive(scene):
		return
	if not refresh_ok:
		_finish_equipment_refresh_failed(scene, refresh_err)
		return
	if refresh_data is Dictionary:
		scene.GameState.update_scooper_profile(refresh_data)
		scene._refresh_resource_label()
	scene.ApiClient.get_equipment_list_silent(Callable(self, "_on_refresh_equipment_list_completed").bind(scene))


func _on_refresh_equipment_list_completed(refresh_ok: bool, refresh_data: Variant, refresh_err: Dictionary, scene: Control) -> void:
	if not _is_scene_alive(scene):
		return
	if not refresh_ok:
		_finish_equipment_refresh_failed(scene, refresh_err)
		return
	if refresh_data is Array:
		scene.GameState.update_scooper_equipment(refresh_data)
	scene._api_in_flight = false
	_refresh_equipment_tab(scene)


func _finish_equipment_refresh_failed(scene: Control, refresh_err: Dictionary) -> void:
	if not _is_scene_alive(scene):
		return
	scene._api_in_flight = false
	_refresh_equipment_tab(scene)
	scene.DialogManager.show_info(
		UiText.SCOOPER_EQUIPMENT_REFRESH_FAILED,
		str(refresh_err.get("message", UiText.SCOOPER_EQUIPMENT_REFRESH_FAILED_DEFAULT))
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


func _apply_effect_summary_layout(panel: Control, item: Dictionary, level: int) -> void:
	var existing_host: Node = panel.get_node_or_null("EffectSummaryHost")
	if existing_host != null:
		existing_host.queue_free()

	var host: Control = Control.new()
	host.name = "EffectSummaryHost"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.position = Vector2.ZERO
	host.size = panel.size
	panel.add_child(host)

	var rows: Array[Dictionary] = _get_equipment_effect_rows(item, level)
	for index: int in range(rows.size()):
		var col: int = index % EFFECT_COLUMN_X.size()
		var row: int = int(floori(float(index) / float(EFFECT_COLUMN_X.size())))
		if row >= EFFECT_ROW_Y.size():
			break
		var effect_label: Label = Label.new()
		effect_label.name = "Effect%d" % index
		effect_label.position = Vector2(EFFECT_COLUMN_X[col], EFFECT_ROW_Y[row])
		effect_label.size = Vector2(EFFECT_COLUMN_W, EFFECT_ROW_H)
		effect_label.text = _format_effect_summary(rows[index])
		effect_label.clip_text = true
		effect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		effect_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
		effect_label.add_theme_color_override("font_color", Color(0.9, 0.84, 0.76, 1.0))
		effect_label.add_theme_color_override("font_outline_color", Color(0.14, 0.06, 0.02, 1.0))
		effect_label.add_theme_constant_override("outline_size", 2)
		host.add_child(effect_label)


func _bonus_summary(item: Dictionary, level: int) -> String:
	var rows: Array[Dictionary] = _get_equipment_effect_rows(item, level)
	var lines: Array[String] = []
	var pair_buffer: Array[String] = []
	for row: Dictionary in rows:
		pair_buffer.append(_format_effect_summary(row))
		if pair_buffer.size() >= 2:
			lines.append("  ".join(pair_buffer))
			pair_buffer.clear()
	if not pair_buffer.is_empty():
		lines.append("  ".join(pair_buffer))
	return "\n".join(lines)


func _bonus_desc(item: Dictionary, level: int) -> String:
	var rows: Array[Dictionary] = _get_equipment_effect_rows(item, level)
	var lines: Array[String] = []
	for row: Dictionary in rows:
		lines.append(_format_effect_summary(row))
	return "\n".join(lines)


func _get_equipment_effect_rows(item: Dictionary, level: int) -> Array[Dictionary]:
	var effects: Array = item.get("effects", [])
	if effects.is_empty():
		# fallback to legacy single-effect fields
		var stat: String = str(item.get("bonusStat", ""))
		var per_lv: float = float(item.get("bonusPerLevel", 0.0))
		effects = [{"stat_type": stat, "base_value": per_lv}]

	var rows: Array[Dictionary] = []
	var current_level: int = maxi(level, 0)
	var next_level: int = current_level + 1 if current_level > 0 else 1
	for e: Variant in effects:
		if not (e is Dictionary):
			continue
		var stat: String = str(e.get("stat_type", e.get("statType", "")))
		var base_val: float = float(e.get("base_value", e.get("baseValue", 0.0)))
		var is_percent: bool = stat in [
			"atk_percent", "AtkPercent", "def_percent", "DefPercent",
			"max_hp_percent", "MaxHpPercent", "hp_percent", "HpPercent",
			"crit_rate", "CritRate", "crit_damage", "CritDamage",
			"damage_reduction", "DamageReduction", "cooldown_reduction", "CooldownReduction",
			"idle_poop_percent", "IdlePoopPercent", "dungeon_damage_boost", "DungeonDamageBoost",
			"dungeon_damage_reduction", "DungeonDamageReduction", "life_steal", "LifeSteal",
			"counter_damage_chance", "CounterDamageChance", "physical_damage_boost", "PhysicalDamageBoost",
			"physical_damage_reduction", "PhysicalDamageReduction",
		]
		var stat_str: String
		match stat:
			"atk", "Atk":
				stat_str = "固定攻擊"
			"def", "Def":
				stat_str = "固定防禦"
			"hp", "Hp":
				stat_str = "固定生命"
			"atk_percent", "AtkPercent":
				stat_str = "攻擊加成"
			"def_percent", "DefPercent":
				stat_str = "防禦加成"
			"max_hp_percent", "MaxHpPercent", "hp_percent", "HpPercent":
				stat_str = "生命加成"
			"crit_rate", "CritRate":
				stat_str = "暴擊率"
			"crit_damage", "CritDamage":
				stat_str = "暴擊傷害"
			"damage_reduction", "DamageReduction":
				stat_str = "傷害減免"
			"cooldown_reduction", "CooldownReduction":
				stat_str = "冷卻縮減"
			"dungeon_damage_boost", "DungeonDamageBoost":
				stat_str = "\u526f\u672c\u589e\u50b7"
			"dungeon_damage_reduction", "DungeonDamageReduction":
				stat_str = "\u526f\u672c\u6e1b\u50b7"
			"life_steal", "LifeSteal":
				stat_str = "\u5438\u8840"
			"counter_damage_chance", "CounterDamageChance":
				stat_str = "\u53cd\u50b7\u6a5f\u7387"
			"physical_damage_boost", "PhysicalDamageBoost":
				stat_str = "\u7269\u7406\u589e\u50b7"
			"physical_damage_reduction", "PhysicalDamageReduction":
				stat_str = "\u7269\u7406\u6e1b\u50b7"
			"speed", "Speed":
				stat_str = "固定速度"
			_:
				stat_str = stat.to_upper()
		var display_base_value: float = base_val * 100.0 if is_percent else base_val
		rows.append({
			"stat": stat_str,
			"is_percent": is_percent,
			"current": display_base_value * float(current_level),
			"next": display_base_value * float(next_level),
			"delta": display_base_value,
		})
	return rows


func _format_effect_summary(row: Dictionary) -> String:
	return "%s %s (+%s)" % [
		str(row.get("stat", "")),
		_format_effect_value(float(row.get("current", 0.0)), bool(row.get("is_percent", false))),
		_format_effect_value(float(row.get("delta", 0.0)), bool(row.get("is_percent", false))),
	]


func _format_effect_value(value: float, is_percent: bool) -> String:
	if is_percent:
		return "%.1f%%" % value
	return "%.0f" % value


func _add_unlock_overlay(_scene: Control, panel: Control, _unlock_cost: int, _equip_id: int, _item_name: String) -> void:
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


func _add_locked_overlay(panel: Control, unlock_lv: int) -> void:
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


func _set_panel_fill(panel: Panel, bg_color: Color) -> void:
	if panel == null:
		return
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	var style_copy: StyleBoxFlat = style.duplicate()
	style_copy.bg_color = bg_color
	panel.add_theme_stylebox_override("panel", style_copy)


func _set_action_visual(panel: Panel, label: Label, bg_color: Color, font_color: Color, text: String) -> void:
	_set_panel_fill(panel, bg_color)
	if label == null:
		return
	label.text = text
	label.add_theme_color_override("font_color", font_color)


func _set_progress_fill(fill: ColorRect, ratio: float, width: float) -> void:
	if fill == null:
		return
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	fill.offset_right = 4.0 + width * clamped_ratio


func exp_bar_ratio(current_exp: int, max_exp: int, is_maxed: bool) -> float:
	if is_maxed:
		return 1.0
	if max_exp <= 0:
		return 0.0
	return float(current_exp) / float(max_exp)


func _prepare_flat_button(button: Button) -> void:
	if button == null:
		return
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)


func _sort_scooper_items(a: Dictionary, b: Dictionary) -> bool:
	var a_owned: bool = bool(a.get("isOwned", false))
	var b_owned: bool = bool(b.get("isOwned", false))
	if a_owned != b_owned:
		return a_owned and not b_owned
	return int(a.get("equipmentId", 0)) < int(b.get("equipmentId", 0))
