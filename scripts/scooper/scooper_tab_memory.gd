extends RefCounted

const CARD_TEMPLATE: PackedScene = preload("res://scenes/ui/scooper/memory/ScooperMemoryCardTemplate.tscn")


func build(scene: Control) -> void:
	scene._memory_summary_label = scene._tab_header_summary
	if scene._memory_summary_label == null:
		var summary_row: HBoxContainer = HBoxContainer.new()
		summary_row.add_theme_constant_override("separation", 10)
		scene._tab_content.add_child(summary_row)

		var section_label: Label = Label.new()
		section_label.text = UiText.SCOOPER_TAB_MEMORY
		section_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_row.add_child(section_label)

		scene._memory_summary_label = Label.new()
		scene._memory_summary_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
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
		empty_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
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
	var unlock_level: int = int(item.get("unlockLevel", 1))
	var level_locked: bool = scene.GameState.player_data.scooper_level < unlock_level
	var cost: int = int(item.get("unlockCost", 0))
	var can_unlock: bool = (not unlocked) and (not level_locked) and scene.GameState.player_data.memory_shards >= cost
	var accent: Color = _get_memory_placeholder_color(item)
	var current_shards: int = mini(scene.GameState.player_data.memory_shards, cost)

	var panel: Panel = CARD_TEMPLATE.instantiate() as Panel
	var display_name: String = str(item.get("displayName", ""))
	var title_lbl: Label = panel.get_node("Margin/ContentCanvas/TitleLabel") as Label
	title_lbl.text = display_name
	var preview_bg: ColorRect = panel.get_node("Margin/ContentCanvas/PreviewRoot/PreviewBackground") as ColorRect
	var preview_image: TextureRect = panel.get_node("Margin/ContentCanvas/PreviewRoot/PreviewImage") as TextureRect
	var overlay: ColorRect = panel.get_node("Margin/ContentCanvas/PreviewRoot/LockOverlay") as ColorRect
	var preview_text: Label = panel.get_node("Margin/ContentCanvas/PreviewRoot/PreviewTextLabel") as Label
	var desc: Label = panel.get_node("Margin/ContentCanvas/DescriptionLabel") as Label
	var bonus: Label = panel.get_node("Margin/ContentCanvas/BonusLabel") as Label
	var action_btn: Button = panel.get_node("Margin/ContentCanvas/ActionButton") as Button
	preview_bg.color = accent

	var photo_path: String = AssetResolver.resolve_catalog_path(item.get("imagePath", ""))
	var texture: Texture2D = AssetResolver.resolve_preview_texture(photo_path, "scooper")
	preview_image.visible = texture != null
	AssetResolver.apply_preview_texture(preview_image, photo_path, "scooper")

	overlay.visible = not unlocked
	preview_text.text = display_name if unlocked else UiText.SCOOPER_MEMORY_LOCKED

	desc.text = str(item.get("description", ""))
	bonus.text = _memory_bonus_desc(item)

	if unlocked:
		action_btn.text = UiText.SCOOPER_MEMORY_UNLOCKED_BUTTON
		action_btn.disabled = true
		UiPalette.apply_button_kind(action_btn, "neutral")
	elif level_locked:
		action_btn.text = UiText.SCOOPER_MEMORY_LEVEL_LOCKED % unlock_level
		action_btn.disabled = true
		UiPalette.apply_button_kind(action_btn, "neutral")
	elif can_unlock and not api_locked:
		action_btn.text = UiText.SCOOPER_MEMORY_UNLOCK_BUTTON % [current_shards, cost]
		UiPalette.apply_button_kind(action_btn, "confirm")
		RedDotService.refresh_dot(action_btn, true)
		action_btn.pressed.connect(Callable(self, "_confirm_unlock_memory").bind(scene, memory_id, item))
	else:
		action_btn.text = UiText.SCOOPER_MEMORY_UNLOCK_NEED % [current_shards, cost]
		action_btn.disabled = true
		UiPalette.apply_button_kind(action_btn, "neutral")

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
		Callable(self, "_unlock_memory_confirmed").bind(scene, memory_id, memory_item, display_name)
	)


func _unlock_memory_confirmed(scene: Control, memory_id: int, memory_item: Dictionary, display_name: String) -> void:
	if scene._api_in_flight:
		return
	scene._api_in_flight = true
	_refresh_memory_tab(scene)
	scene.ApiClient.unlock_memory(memory_id, Callable(self, "_on_unlock_memory_completed").bind(scene, memory_item, display_name))


func _on_unlock_memory_completed(
	ok: bool,
	data: Variant,
	err: Dictionary,
	scene: Control,
	memory_item: Dictionary,
	display_name: String
) -> void:
	if scene == null or not is_instance_valid(scene):
		return
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
	scene.refresh_from_bootstrap(Callable(self, "_on_unlock_memory_bootstrap_refreshed").bind(scene))


func _on_unlock_memory_bootstrap_refreshed(refresh_ok: bool, _refresh_data: Variant, refresh_err: Dictionary, scene: Control) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	if not refresh_ok:
		scene.DialogManager.show_info(
			UiText.SCOOPER_MEMORY_REFRESH_FAILED,
			str(refresh_err.get("message", UiText.SCOOPER_MEMORY_REFRESH_FAILED_DEFAULT))
		)


func _memory_bonus_desc(item: Dictionary) -> String:
	var stat: String = _normalize_stat_key(str(item.get("bonusStatType", "")))
	var target: String = str(item.get("bonusTarget", "All"))
	var value: float = float(item.get("bonusValue", 0.0))
	var target_str: String = UiText.SCOOPER_EQUIPMENT_BONUS_ALL if target.to_lower() == "all" else target
	var stat_str: String = _memory_stat_label(stat)
	if _is_percent_memory_stat(stat):
		return UiText.SCOOPER_EQUIPMENT_BONUS_TOTAL % [target_str, stat_str, value * 100.0]
	return "%s %s +%s" % [target_str, stat_str, _format_flat_memory_value(value)]


func _normalize_stat_key(raw_stat: String) -> String:
	match raw_stat:
		"Atk":
			return "atk"
		"Def":
			return "defense"
		"Hp", "MaxHp":
			return "max_hp"
		"Speed":
			return "speed"
		"AtkPercent":
			return "atk_percent"
		"DefPercent":
			return "def_percent"
		"HpPercent", "MaxHpPercent":
			return "max_hp_percent"
		"CritRate":
			return "crit_rate"
		"CritDamage":
			return "crit_damage"
		"DamageReduction":
			return "damage_reduction"
		"CooldownReduction":
			return "cooldown_reduction"
		"ArmorPen":
			return "armor_pen"
		"Evasion":
			return "evasion"
		"Accuracy":
			return "accuracy"
		"MultiHitRate":
			return "multi_hit_rate"
		"MultiHitDamage":
			return "multi_hit_damage"
		"DungeonDamageBoost":
			return "dungeon_damage_boost"
		"DungeonDamageReduction":
			return "dungeon_damage_reduction"
		"LifeSteal":
			return "life_steal"
		"CounterDamageChance":
			return "counter_damage_chance"
		"PhysicalDamageBoost":
			return "physical_damage_boost"
		"PhysicalDamageReduction":
			return "physical_damage_reduction"
	var result: String = ""
	for index: int in range(raw_stat.length()):
		var ch: String = raw_stat.substr(index, 1)
		if ch >= "A" and ch <= "Z":
			if index > 0 and not result.ends_with("_"):
				result += "_"
			result += ch.to_lower()
		else:
			result += ch.to_lower()
	return result


func _memory_stat_label(stat: String) -> String:
	match stat:
		"atk":
			return "固定攻擊"
		"atk_percent":
			return "攻擊加成"
		"defense", "def":
			return "固定防禦"
		"def_percent":
			return "防禦加成"
		"max_hp", "hp":
			return "固定生命"
		"max_hp_percent", "hp_percent":
			return "生命加成"
		"speed":
			return "固定速度"
		"crit_rate":
			return "暴擊率"
		"crit_damage":
			return "暴擊傷害"
		"damage_reduction":
			return "傷害減免"
		"cooldown_reduction":
			return "冷卻縮減"
		"armor_pen":
			return "護甲穿透"
		"evasion":
			return "閃避率"
		"accuracy":
			return "命中率"
		"multi_hit_rate":
			return "連擊率"
		"multi_hit_damage":
			return "連擊傷害"
		"dungeon_damage_boost":
			return "副本增傷"
		"dungeon_damage_reduction":
			return "副本減傷"
		"life_steal":
			return "吸血"
		"counter_damage_chance":
			return "反傷機率"
		"physical_damage_boost":
			return "物理增傷"
		"physical_damage_reduction":
			return "物理減傷"
	return stat.to_upper()


func _is_percent_memory_stat(stat: String) -> bool:
	return stat in [
		"atk_percent",
		"def_percent",
		"max_hp_percent",
		"hp_percent",
		"crit_rate",
		"crit_damage",
		"damage_reduction",
		"cooldown_reduction",
		"armor_pen",
		"evasion",
		"accuracy",
		"multi_hit_rate",
		"multi_hit_damage",
		"dungeon_damage_boost",
		"dungeon_damage_reduction",
		"life_steal",
		"counter_damage_chance",
		"physical_damage_boost",
		"physical_damage_reduction",
	]


func _format_flat_memory_value(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.1f" % value


func _get_memory_placeholder_color(item: Dictionary) -> Color:
	var raw_color: String = str(item.get("placeholderColor", "#6B7280"))
	return Color.from_string(raw_color, Color(0.42, 0.45, 0.50, 1.0))


func _is_api_locked(scene: Control) -> bool:
	return bool(scene._api_in_flight)


func _set_panel_style(panel: Panel, accent: Color) -> void:
	if panel == null:
		return
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	var style_copy: StyleBoxFlat = style.duplicate()
	style_copy.border_color = accent
	panel.add_theme_stylebox_override("panel", style_copy)
