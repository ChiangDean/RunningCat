class_name EnhanceSceneRefresh
extends RefCounted



static func refresh_all_labels(scene) -> void:
	refresh_resource_label(scene)
	if scene._is_catalog_detail_mode():
		return
	if scene._selected_cat_id == "":
		return

	var player_cat: PlayerCatData = scene.GameState.get_player_cat(scene._selected_cat_id)
	var cat_data := CatData.from_json_file(scene._selected_cat_id + ".json")
	if cat_data == null:
		return
	if scene._detail_panel == null:
		return

	refresh_stat_labels(scene, cat_data, player_cat)
	refresh_food_labels(scene, player_cat)
	refresh_special_cost_label(scene, player_cat)
	refresh_special_point_labels(scene, player_cat)
	refresh_special_buttons(scene, player_cat)
	refresh_rank_labels(scene, player_cat)

	if scene._food_upgrade_btn:
		scene._food_upgrade_btn.disabled = scene._food_upgrade_btn.disabled or scene._action_inflight
	if scene._food_max_btn:
		scene._food_max_btn.disabled = scene._food_max_btn.disabled or scene._action_inflight
	if scene._rank_upgrade_btn:
		scene._rank_upgrade_btn.disabled = scene._rank_upgrade_btn.disabled or scene._action_inflight
	if scene._cat_name_label != null:
		scene._cat_name_label.text = get_display_name(scene._selected_cat_id)
	if scene._detail_resource_label != null:
		scene._detail_resource_label.text = _build_resource_line(scene)
	if scene._food_level_label != null:
		scene._food_level_label.text = UiText.ENHANCE_CAT_LEVEL_FORMAT % [player_cat.cat_food_level]


static func refresh_resource_label(scene) -> void:
	var resource_line: String = _build_resource_line(scene)
	if scene._resource_label == null:
		if scene._submenu_btns != null and scene._submenu_btns is Dictionary:
			SceneSubmenuBar.refresh(scene._submenu_btns, scene._active_submenu, {
				"active_color": SceneMenuTheme.ACTIVE_COLOR,
				"inactive_color": SceneMenuTheme.INACTIVE_COLOR,
			})
		return
	scene._resource_label.text = resource_line
	if scene._detail_resource_label != null:
		scene._detail_resource_label.text = resource_line
	if scene._submenu_btns != null and scene._submenu_btns is Dictionary:
		SceneSubmenuBar.refresh(scene._submenu_btns, scene._active_submenu, {
			"active_color": SceneMenuTheme.ACTIVE_COLOR,
			"inactive_color": SceneMenuTheme.INACTIVE_COLOR,
		})


static func refresh_stat_labels(scene, cat_data: CatData, player_cat: PlayerCatData) -> void:
	var food_lv := player_cat.cat_food_level - 1
	var sfp: Dictionary = scene._get_effective_special_points(player_cat)
	var growth := cat_data.enhancement_growth
	var rank := player_cat.rank
	var rank_growth := cat_data.rank_growth
	var rank_hp_multiplier: float = 1.0 + rank * rank_growth.get("hp_percent", 1.0) / 100.0
	var rank_atk_multiplier: float = 1.0 + rank * rank_growth.get("atk_percent", 1.0) / 100.0
	var rank_def_multiplier: float = 1.0 + rank * rank_growth.get("def_percent", 1.0) / 100.0

	var hp_special_bonus_raw: float = float(sfp.get("hp", 0)) * growth.get("hp", 0.0) * rank_hp_multiplier
	var hp_special_bonus: int = int(sfp.get("hp", 0) * growth.get("hp", 0.0))
	var hp_pre := cat_data.max_hp + int(food_lv * growth.get("hp", 0.0)) + hp_special_bonus
	var hp_final := int(hp_pre * rank_hp_multiplier)
	scene._stat_labels["hp"].text = _format_stat_value(UiText.ENHANCE_STAT_HP, hp_final, int(sfp.get("hp", 0)), hp_special_bonus_raw)

	var atk_special_bonus_raw: float = float(sfp.get("atk", 0)) * growth.get("atk", 0.0) * rank_atk_multiplier
	var atk_special_bonus: int = int(sfp.get("atk", 0) * growth.get("atk", 0.0))
	var atk_pre := cat_data.atk + int(food_lv * growth.get("atk", 0.0)) + atk_special_bonus
	var atk_final := int(atk_pre * rank_atk_multiplier)
	scene._stat_labels["atk"].text = _format_stat_value(UiText.ENHANCE_STAT_ATK, atk_final, int(sfp.get("atk", 0)), atk_special_bonus_raw)

	var def_special_bonus_raw: float = float(sfp.get("def", 0)) * growth.get("def", 0.0) * rank_def_multiplier
	var def_special_bonus: int = int(sfp.get("def", 0) * growth.get("def", 0.0))
	var def_pre := cat_data.defense + int(food_lv * growth.get("def", 0.0)) + def_special_bonus
	var def_final := int(def_pre * rank_def_multiplier)
	scene._stat_labels["def"].text = _format_stat_value(UiText.ENHANCE_STAT_DEF, def_final, int(sfp.get("def", 0)), def_special_bonus_raw)


static func refresh_food_labels(scene, player_cat: PlayerCatData) -> void:
	var lv := player_cat.cat_food_level
	var held: int = scene.GameState.player_data.cat_food
	var is_max_level := lv >= PlayerCatData.MAX_CAT_FOOD_LEVEL
	var is_upgrade_ready := false

	if scene._food_progress_bar != null:
		scene._food_progress_bar.min_value = 0

	if is_max_level:
		if scene._food_cost_label != null:
			scene._food_cost_label.text = UiText.ENHANCE_FOOD_UPGRADE_MAX
		if scene._food_progress_bar != null:
			scene._food_progress_bar.max_value = 1.0
			scene._food_progress_bar.value = 1.0
			UiPalette.style_exp_progress_bar(scene._food_progress_bar, "max")
		if scene._food_progress_label != null:
			scene._food_progress_label.add_theme_color_override("font_color", UiPalette.EXP_BAR_MAX_TEXT)
			scene._food_progress_label.text = UiText.ENHANCE_FOOD_PROGRESS_MAX
		if scene._food_upgrade_btn:
			scene._food_upgrade_btn.text = UiText.ENHANCE_FOOD_UPGRADE_BUTTON
			scene._food_upgrade_btn.disabled = true
		if scene._food_max_btn:
			scene._food_max_btn.text = UiText.ENHANCE_FOOD_MAX_UPGRADE_MAX
			scene._food_max_btn.disabled = true
		return

	var cost := PlayerCatData.cat_food_cost_for_level(lv)
	is_upgrade_ready = held >= cost
	if scene._food_cost_label != null:
		scene._food_cost_label.text = ""
	if scene._food_progress_bar != null:
		scene._food_progress_bar.max_value = maxf(float(cost), 1.0)
		scene._food_progress_bar.value = minf(float(held), float(cost))
		UiPalette.style_exp_progress_bar(scene._food_progress_bar, "ready" if is_upgrade_ready else "normal")
	if scene._food_progress_label != null:
		scene._food_progress_label.add_theme_color_override(
			"font_color",
			UiPalette.EXP_BAR_READY_TEXT if is_upgrade_ready else UiPalette.EXP_BAR_TEXT
		)
		scene._food_progress_label.text = UiText.ENHANCE_FOOD_PROGRESS_FORMAT % [held, cost]
	if scene._food_upgrade_btn:
		scene._food_upgrade_btn.text = UiText.ENHANCE_FOOD_UPGRADE_BUTTON
		scene._food_upgrade_btn.disabled = scene._action_inflight or held < cost
	if scene._food_max_btn:
		var target_lv := lv
		var total_cost := 0
		while target_lv < PlayerCatData.MAX_CAT_FOOD_LEVEL:
			var next_cost := PlayerCatData.cat_food_cost_for_level(target_lv)
			if total_cost + next_cost > held:
				break
			total_cost += next_cost
			target_lv += 1
		if target_lv > lv:
			scene._food_max_btn.text = UiText.ENHANCE_FOOD_MAX_UPGRADE_BUTTON
			scene._food_max_btn.disabled = scene._action_inflight
		else:
			scene._food_max_btn.text = UiText.ENHANCE_FOOD_MAX_UPGRADE_BUTTON
			scene._food_max_btn.disabled = true


static func refresh_special_cost_label(scene, player_cat: PlayerCatData) -> void:
	var total_pts: int = scene._get_effective_special_total_points(player_cat)
	var held: int = scene._get_effective_special_food_held(player_cat)
	var next_cost := PlayerCatData.special_food_next_cost(total_pts)
	scene._special_cost_label.text = UiText.ENHANCE_SPECIAL_COST_FORMAT % [
		next_cost,
		next_cost,
		held,
	]


static func refresh_special_point_labels(scene, player_cat: PlayerCatData) -> void:
	var effective_points: Dictionary = scene._get_effective_special_points(player_cat)
	for stat_key: String in ["hp", "atk", "def"]:
		if not scene._special_point_labels.has(stat_key):
			continue
		scene._special_point_labels[stat_key].text = GameState.format_number(int(effective_points.get(stat_key, 0)))


static func refresh_special_buttons(scene, player_cat: PlayerCatData) -> void:
	var held: int = scene._get_effective_special_food_held(player_cat)
	var total_pts: int = scene._get_effective_special_total_points(player_cat)
	var next_cost := PlayerCatData.special_food_next_cost(total_pts)
	var effective_points: Dictionary = scene._get_effective_special_points(player_cat)
	var allocated_points: int = int(player_cat.special_food_points.get("hp", 0)) + int(player_cat.special_food_points.get("atk", 0)) + int(player_cat.special_food_points.get("def", 0))

	for stat_key: String in ["hp", "atk", "def"]:
		if scene._special_plus_btns.has(stat_key):
			var plus_btn: Button = scene._special_plus_btns[stat_key]
			plus_btn.text = UiText.ENHANCE_ADD_POINT_BUTTON
			plus_btn.disabled = scene._action_inflight or held < next_cost
		if scene._special_minus_btns.has(stat_key):
			var minus_btn: Button = scene._special_minus_btns[stat_key]
			minus_btn.text = UiText.ENHANCE_REMOVE_POINT_BUTTON
			minus_btn.disabled = scene._action_inflight or int(effective_points.get(stat_key, 0)) <= 0

	if scene._special_apply_btn != null:
		scene._special_apply_btn.disabled = scene._action_inflight or not scene._has_special_point_draft()
		if scene._special_apply_btn.disabled:
			UiPalette.apply_button_palette(scene._special_apply_btn, Color(0.24, 0.21, 0.18, 0.86), Color(0.72, 0.69, 0.64, 1.0))
		else:
			UiPalette.apply_button_kind(scene._special_apply_btn, "primary")
	if scene._special_reset_btn != null:
		scene._special_reset_btn.disabled = scene._action_inflight or (allocated_points <= 0 and not scene._has_special_point_draft())


static func refresh_rank_labels(scene, player_cat: PlayerCatData) -> void:
	if scene._rank_stars_label == null or scene._rank_upgrade_btn == null:
		return

	var rank := player_cat.rank
	var cost := PlayerCatData.rank_upgrade_cost(rank + 1)
	scene._rank_stars_label.text = UiText.ENHANCE_CAT_RANK_FORMAT % [rank]
	var held: int = player_cat.cat_shards
	if scene._rank_progress_label != null:
		scene._rank_progress_label.text = "%s/%s" % [GameState.format_number(held), GameState.format_number(cost)]
	if scene._rank_progress_bar != null:
		scene._rank_progress_bar.min_value = 0
		scene._rank_progress_bar.max_value = maxf(float(cost), 1.0)
		scene._rank_progress_bar.value = minf(float(held), float(cost))
	scene._rank_upgrade_btn.text = UiText.ENHANCE_RANK_UPGRADE_BUTTON
	scene._rank_upgrade_btn.disabled = scene._action_inflight or held < cost
	RedDotService.refresh_dot(scene._rank_upgrade_btn, not scene._rank_upgrade_btn.disabled)
	var rank_tab_btn: Control = scene._detail_tab_btns.get("rank", null)
	RedDotService.refresh_dot(rank_tab_btn, not scene._rank_upgrade_btn.disabled)


static func _format_stat_value(label: String, value: int, point_delta: int, bonus: float) -> String:
	return "%s：%s +%s (%s)" % [label, GameState.format_number(value), GameState.format_number(point_delta), _format_bonus_value(bonus)]


static func _format_bonus_value(value: float) -> String:
	var rounded: float = snappedf(value, 0.1)
	if is_equal_approx(rounded, roundf(rounded)):
		return str(int(roundf(rounded)))
	return "%.1f" % rounded


static func build_skill_section(scene, cat_data: CatData, player_cat: PlayerCatData) -> void:
	var rank: int = player_cat.rank

	for sid: String in cat_data.passive_skill_ids:
		var skill_d := CatData._read_skill_json(sid)
		if skill_d.is_empty():
			continue
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		scene._detail_panel.add_child(row)

		var lbl := Label.new()
		lbl.text = UiText.ENHANCE_PASSIVE_SKILL_FORMAT % [skill_d.get("display_name", sid)]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		row.add_child(lbl)

		if rank >= 5:
			var rank_lbl := Label.new()
			rank_lbl.text = UiText.ENHANCE_SKILL_RANK_BONUS_FORMAT % [floori(float(rank) / 5.0)]
			rank_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rank_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
			rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			row.add_child(rank_lbl)

		var info_btn := Button.new()
		info_btn.text = UiText.ENHANCE_INFO_BUTTON
		info_btn.custom_minimum_size = Vector2(36.0, 36.0)
		info_btn.pressed.connect(Callable(scene, "_show_skill_bonus_info").bind(skill_d, rank, false))
		row.add_child(info_btn)

	for skill_d: Dictionary in cat_data.active_skills_data:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		scene._detail_panel.add_child(row)

		var lbl := Label.new()
		lbl.text = UiText.ENHANCE_ACTIVE_SKILL_FORMAT % [skill_d.get("display_name", ""), skill_d.get("cooldown", 0.0)]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		row.add_child(lbl)

		if rank >= 5:
			var rank_lbl := Label.new()
			rank_lbl.text = UiText.ENHANCE_SKILL_RANK_BONUS_FORMAT % [floori(float(rank) / 5.0)]
			rank_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rank_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
			rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			row.add_child(rank_lbl)

		var info_btn := Button.new()
		info_btn.text = UiText.ENHANCE_INFO_BUTTON
		info_btn.custom_minimum_size = Vector2(36.0, 36.0)
		info_btn.pressed.connect(Callable(scene, "_show_skill_bonus_info").bind(skill_d, rank, true))
		row.add_child(info_btn)


static func show_rank_bonus_info(cat_data: CatData, rank: int) -> void:
	var rg := cat_data.rank_growth
	var lines: Array[String] = []

	if rank <= 0:
		lines.append(UiText.ENHANCE_RANK_INFO_NONE)
		lines.append("")
		lines.append(UiText.ENHANCE_RANK_INFO_NEXT)
		lines.append(UiText.ENHANCE_RANK_INFO_NEXT_DETAIL)
	else:
		lines.append(UiText.ENHANCE_RANK_INFO_CURRENT_FORMAT % [rank])
		lines.append(UiText.ENHANCE_RANK_INFO_HP_FORMAT % [rank * rg.get("hp_percent", 1.0)])
		lines.append(UiText.ENHANCE_RANK_INFO_ATK_FORMAT % [rank * rg.get("atk_percent", 1.0)])
		lines.append(UiText.ENHANCE_RANK_INFO_DEF_FORMAT % [rank * rg.get("def_percent", 1.0)])

	DialogManager.show_info(UiText.ENHANCE_RANK_INFO_TITLE, "\n".join(lines))


static func show_skill_bonus_info(skill_d: Dictionary, rank: int, _is_active: bool) -> void:
	var name: String = skill_d.get("display_name", "")
	var desc: String = skill_d.get("description", "")
	var scaling: Array = skill_d.get("rank_scaling", [])
	var effects: Array = skill_d.get("effects", [])
	var lines: Array[String] = [name, desc, ""]

	if rank <= 0 or scaling.is_empty():
		lines.append(UiText.ENHANCE_SKILL_BONUS_NONE)
	else:
		lines.append(UiText.ENHANCE_SKILL_BONUS_CURRENT_FORMAT % [rank])
		for rs: Dictionary in scaling:
			var eff_idx: int = rs.get("effect_index", 0)
			var per_5: float = rs.get("per_5_ranks", 0.0)
			var bonus: float = floorf(rank / 5.0) * per_5
			if bonus <= 0.0:
				continue
			var stat_name := UiText.ENHANCE_EFFECT_LABEL
			if eff_idx < effects.size():
				var eff: Dictionary = effects[eff_idx]
				stat_name = stat_display_label(eff.get("stat", ""), eff.get("type", ""))
			lines.append(UiText.ENHANCE_SKILL_BONUS_EFFECT_FORMAT % [stat_name, bonus * 100.0])

	DialogManager.show_info(UiText.ENHANCE_SKILL_BONUS_INFO_TITLE, "\n".join(lines))


static func stat_display_label(stat: String, eff_type: String) -> String:
	match stat:
		"defense":
			return UiText.ENHANCE_STAT_DEFENSE_NAME
		"atk":
			return UiText.ENHANCE_STAT_ATTACK_NAME
		"speed":
			return UiText.ENHANCE_STAT_SPEED_NAME
		"max_hp":
			return UiText.ENHANCE_STAT_MAX_HP_NAME
		_:
			if eff_type == "damage":
				return UiText.ENHANCE_STAT_DAMAGE_NAME
			if eff_type == "reflect":
				return UiText.ENHANCE_STAT_REFLECT_DAMAGE_NAME
			return UiText.ENHANCE_EFFECT_LABEL


static func get_display_name(cat_id: String) -> String:
	var data := CatData.from_json_file(cat_id + ".json")
	if data != null:
		return data.display_name
	return cat_id


static func _build_resource_line(scene) -> String:
	return UiText.ENHANCE_RESOURCE_FORMAT % [
		scene.GameState.player_data.cat_food,
		scene.GameState.player_data.special_cat_food,
		scene.GameState.player_data.whisker_shards,
	]


static func stat_display_name(stat_key: String) -> String:
	match stat_key:
		"hp":
			return UiText.ENHANCE_STAT_HP
		"atk":
			return UiText.ENHANCE_STAT_ATK
		"def":
			return UiText.ENHANCE_STAT_DEF
	return stat_key


static func build_base_stat_rows(cat_data: CatData) -> Array[Dictionary]:
	return _build_stat_rows(cat_data)


static func build_effective_stat_rows(scene, cat_data: CatData, player_cat: PlayerCatData) -> Array[Dictionary]:
	var effective_cat: CatData = _build_effective_cat(scene, cat_data.id, player_cat)
	if effective_cat == null:
		return []
	return _build_stat_rows(effective_cat)


static func _build_effective_cat(scene, cat_id: String, player_cat: PlayerCatData) -> CatData:
	var effective_cat: CatData = CatData.from_json_file(cat_id + ".json")
	if effective_cat == null:
		return null
	var preview_cat: PlayerCatData = PlayerCatData.new()
	preview_cat.cat_id = player_cat.cat_id
	preview_cat.cat_food_level = player_cat.cat_food_level
	preview_cat.rank = player_cat.rank
	preview_cat.cat_shards = player_cat.cat_shards
	preview_cat.active_skill_settings = player_cat.active_skill_settings.duplicate(true)
	preview_cat.special_food_points = scene._get_effective_special_points(player_cat)
	effective_cat.apply_enhancement(preview_cat)
	effective_cat.apply_rank_bonus(preview_cat)
	scene.GameState.apply_player_combat_bonuses(effective_cat)
	_apply_overview_passive_bonuses(scene, effective_cat, player_cat)
	return effective_cat


static func _build_stat_rows(cat_data: CatData) -> Array[Dictionary]:
	return [
		_build_stat_row("max_hp", "生命", float(cat_data.max_hp), _format_flat_number(float(cat_data.max_hp)), cat_data),
		_build_stat_row("atk", "攻擊", float(cat_data.atk), _format_flat_number(float(cat_data.atk)), cat_data),
		_build_stat_row("defense", "防禦", float(cat_data.defense), _format_flat_number(float(cat_data.defense)), cat_data),
		_build_stat_row("speed", "速度", float(cat_data.speed), _format_decimal_number(float(cat_data.speed)), cat_data),
		_build_stat_row("weight", "重量", float(cat_data.weight), _format_decimal_number(float(cat_data.weight)), cat_data),
		_build_stat_row("crit_rate", "暴擊率", float(cat_data.crit_rate), _format_percent_value(float(cat_data.crit_rate)), cat_data),
		_build_stat_row("crit_damage", "暴擊傷害", float(cat_data.crit_damage_bonus), _format_percent_value(float(cat_data.crit_damage_bonus)), cat_data),
		_build_stat_row("evasion", "閃避率", float(cat_data.evasion), _format_percent_value(float(cat_data.evasion)), cat_data),
		_build_stat_row("accuracy", "命中率", float(cat_data.accuracy), _format_percent_value(float(cat_data.accuracy)), cat_data),
		_build_stat_row("armor_pen", "護甲穿透", float(cat_data.armor_pen), _format_percent_value(float(cat_data.armor_pen)), cat_data),
		_build_stat_row("damage_reduction", "傷害減免", float(cat_data.damage_reduction), _format_percent_value(float(cat_data.damage_reduction)), cat_data),
		_build_stat_row("cooldown_reduction", "冷卻縮減", float(cat_data.cooldown_reduction), _format_percent_value(float(cat_data.cooldown_reduction)), cat_data),
		_build_stat_row("multi_hit_rate", "連擊率", float(cat_data.multi_hit_rate), _format_percent_value(float(cat_data.multi_hit_rate)), cat_data),
		_build_stat_row("multi_hit_damage", "連擊傷害", float(cat_data.multi_hit_damage), _format_percent_value(float(cat_data.multi_hit_damage)), cat_data),
		_build_stat_row("counter_damage_chance", "反傷機率", float(cat_data.counter_damage_chance), _format_percent_value(float(cat_data.counter_damage_chance)), cat_data),
		_build_stat_row("dungeon_damage_boost", "副本增傷", float(cat_data.get_meta("dungeon_damage_boost", 0.0)), _format_percent_value(float(cat_data.get_meta("dungeon_damage_boost", 0.0))), cat_data),
		_build_stat_row("dungeon_damage_reduction", "副本減傷", float(cat_data.get_meta("dungeon_damage_reduction", 0.0)), _format_percent_value(float(cat_data.get_meta("dungeon_damage_reduction", 0.0))), cat_data),
		_build_stat_row("life_steal", "吸血比率", float(cat_data.get_meta("life_steal", 0.0)), _format_percent_value(float(cat_data.get_meta("life_steal", 0.0))), cat_data),
		_build_stat_row("physical_damage_boost", "物理增傷", float(cat_data.get_meta("physical_damage_boost", 0.0)), _format_percent_value(float(cat_data.get_meta("physical_damage_boost", 0.0))), cat_data),
		_build_stat_row("physical_damage_reduction", "物理減傷", float(cat_data.get_meta("physical_damage_reduction", 0.0)), _format_percent_value(float(cat_data.get_meta("physical_damage_reduction", 0.0))), cat_data),
	]


static func _build_stat_row(stat_key: String, label: String, raw_value: float, display_value: String, cat_data: CatData) -> Dictionary:
	return {
		"key": stat_key,
		"label": label,
		"value": display_value,
		"raw_value": raw_value,
		"description": _build_stat_description(stat_key, raw_value, cat_data),
	}


static func _build_stat_description(stat_key: String, value: float, cat_data: CatData) -> String:
	var lines: Array[String] = []
	match stat_key:
		"max_hp":
			lines.append("生命越高，能承受的總傷害越多。歸零時會退場。")
			_append_rank_note(lines, cat_data, "生命")
		"atk":
			lines.append("攻擊會作為基礎傷害，實際造成傷害仍會被目標防禦與減傷影響。")
			_append_rank_note(lines, cat_data, "攻擊")
		"defense":
			var reduction: float = CatStats.calc_def_reduction(value)
			lines.append("防禦採遞減式物理減傷：防禦 / (防禦 + 100)。")
			lines.append("目前防禦 %s 約等於 %.1f%% 物理減傷。" % [_format_decimal_number(value), reduction * 100.0])
			_append_rank_note(lines, cat_data, "防禦")
		"speed":
			lines.append("速度影響戰鬥中的左右移動、接敵節奏，以及擊退後回到戰線的速度。")
		"weight":
			lines.append("重量影響碰撞與被擊退距離。越重越不容易被推遠，也更容易推開較輕的目標。")
		"crit_rate":
			var normal_rate: float = minf(value, 1.0)
			var overflow: float = maxf(0.0, value - 1.0)
			lines.append("暴擊率決定攻擊變成暴擊的機率。100%% 以內代表暴擊機率，目前為 %.1f%%。" % (normal_rate * 100.0))
			if overflow > 0.0:
				lines.append("超過 100%% 的 %.1f%% 會列為暴擊傷害溢出參考。" % (overflow * 100.0))
			lines.append("基礎暴擊傷害倍率為 1.5 倍，再加上暴擊傷害屬性。")
		"crit_damage":
			lines.append("暴擊傷害會加在基礎 1.5 倍暴擊倍率上。")
			lines.append("目前暴擊時約造成 %.2f 倍傷害。" % (1.5 + value))
		"evasion":
			lines.append("閃避率越高，越有機會避開敵方命中判定。")
		"accuracy":
			lines.append("命中率用來對抗敵方閃避，命中越高越不容易打空。")
		"armor_pen":
			lines.append("護甲穿透會削弱目標可用於減傷公式的防禦。")
		"damage_reduction":
			lines.append("傷害減免會在防禦之外再降低受到的傷害，目前為 %.1f%%。" % (value * 100.0))
		"cooldown_reduction":
			lines.append("冷卻縮減會縮短技能循環時間，目前為 %.1f%%。" % (value * 100.0))
		"multi_hit_rate":
			lines.append("連擊率越高，攻擊時越容易追加連擊段數。")
		"multi_hit_damage":
			lines.append("連擊傷害會提升追加連擊造成的傷害。")
		"counter_damage_chance":
			lines.append("反傷機率越高，受到攻擊時越有機會觸發反擊或反傷效果。")
		"dungeon_damage_boost":
			lines.append("副本增傷只影響副本相關戰鬥，會提高造成的副本傷害。")
		"dungeon_damage_reduction":
			lines.append("副本減傷只影響副本相關戰鬥，會降低受到的副本傷害。")
		"life_steal":
			lines.append("吸血比率會把造成傷害的一部分轉回自身生命。")
		"physical_damage_boost":
			lines.append("物理增傷會提高物理攻擊造成的傷害。")
		"physical_damage_reduction":
			lines.append("物理減傷會在防禦之外降低受到的物理傷害。")
		_:
			lines.append("此能力會影響角色在戰鬥中的表現。")
	return "\n".join(lines)


static func _append_rank_note(lines: Array[String], cat_data: CatData, stat_label: String) -> void:
	if cat_data.rank <= 0:
		return
	var key: String = ""
	match stat_label:
		"生命":
			key = "hp_percent"
		"攻擊":
			key = "atk_percent"
		"防禦":
			key = "def_percent"
	if key == "":
		return
	var rank_bonus: float = float(cat_data.rank) * float(cat_data.rank_growth.get(key, 1.0))
	lines.append("加成後能力已包含目前品階 +%d 的 %s +%.1f%%。" % [cat_data.rank, stat_label, rank_bonus])


static func _apply_overview_passive_bonuses(scene, target_cat: CatData, target_player_cat: PlayerCatData) -> void:
	var caster_ids: Array[String] = _collect_overview_passive_caster_ids(scene, target_cat.id)
	var target_in_team: bool = _is_cat_in_player_team(scene, target_cat.id)
	for caster_id: String in caster_ids:
		var caster_cat: CatData = target_cat if caster_id == target_cat.id else CatData.from_json_file(caster_id + ".json")
		if caster_cat == null:
			continue
		var caster_player: PlayerCatData = target_player_cat if caster_id == target_cat.id else scene.GameState.get_player_cat(caster_id)
		_apply_passive_bonuses_from_caster(target_cat, caster_cat, caster_id, int(caster_player.rank), target_in_team)


static func _collect_overview_passive_caster_ids(scene, selected_cat_id: String) -> Array[String]:
	var result: Array[String] = []
	if selected_cat_id != "":
		result.append(selected_cat_id)
	for player_cat_id_variant: Variant in scene.GameState.player_team:
		var player_cat_id: int = int(player_cat_id_variant)
		if player_cat_id <= 0:
			continue
		var cat_file_id: String = scene.GameState.get_cat_file_id(player_cat_id)
		if cat_file_id == "" or result.has(cat_file_id):
			continue
		result.append(cat_file_id)
	return result


static func _is_cat_in_player_team(scene, cat_id: String) -> bool:
	for player_cat_id_variant: Variant in scene.GameState.player_team:
		var player_cat_id: int = int(player_cat_id_variant)
		if player_cat_id <= 0:
			continue
		if scene.GameState.get_cat_file_id(player_cat_id) == cat_id:
			return true
	return false


static func _apply_passive_bonuses_from_caster(target_cat: CatData, caster_cat: CatData, caster_id: String, caster_rank: int, target_in_team: bool) -> void:
	for passive_variant: Variant in caster_cat.passive_skills_data:
		if not (passive_variant is Dictionary):
			continue
		var passive: Dictionary = passive_variant
		var effects: Array = passive.get("effects", [])
		var scaling: Array = passive.get("rank_scaling", [])
		for index: int in range(effects.size()):
			var effect_variant: Variant = effects[index]
			if not (effect_variant is Dictionary):
				continue
			var effect: Dictionary = effect_variant
			var target: String = _normalize_key(str(effect.get("target", "team")))
			if not _passive_effect_targets_cat(target, caster_id, target_cat, target_in_team):
				continue
			var value: float = float(effect.get("value", 0.0)) + _passive_scaling_value(scaling, index, caster_rank)
			var effect_type: String = _normalize_key(str(effect.get("type", "")))
			match effect_type:
				"stat_boost":
					_apply_stat_bonus_to_cat(target_cat, _canonicalize_stat_key(str(effect.get("stat", ""))), value, _normalize_key(str(effect.get("value_type", "percent"))))
				"damage_reduction", "cooldown_reduction":
					_apply_stat_bonus_to_cat(target_cat, effect_type, value, "flat")


static func _passive_effect_targets_cat(target: String, caster_id: String, target_cat: CatData, target_in_team: bool) -> bool:
	match target:
		"", "self":
			return caster_id == target_cat.id
		"all", "team", "ally_all":
			return target_in_team or caster_id == target_cat.id
		"tank", "crusader", "assassin", "striker", "support", "defensive", "speed":
			return target_cat.cat_type == target
		_:
			return false


static func _apply_stat_bonus_to_cat(cat_data: CatData, stat: String, value: float, value_type: String) -> void:
	var is_percent: bool = value_type == "percent"
	if stat in ["max_hp_percent", "atk_percent", "def_percent"]:
		is_percent = true
	match stat:
		"max_hp", "max_hp_percent":
			cat_data.max_hp = int(float(cat_data.max_hp) * (1.0 + value)) if is_percent else cat_data.max_hp + int(value)
		"atk", "atk_percent":
			cat_data.atk = int(float(cat_data.atk) * (1.0 + value)) if is_percent else cat_data.atk + int(value)
		"defense", "def_percent":
			cat_data.defense = int(float(cat_data.defense) * (1.0 + value)) if is_percent else cat_data.defense + int(value)
		"speed":
			cat_data.speed = cat_data.speed * (1.0 + value) if is_percent else cat_data.speed + value
		"crit_rate":
			cat_data.crit_rate = maxf(0.0, cat_data.crit_rate + value)
		"crit_damage":
			cat_data.crit_damage_bonus = maxf(0.0, cat_data.crit_damage_bonus + value)
		"damage_reduction":
			cat_data.damage_reduction = minf(0.9, cat_data.damage_reduction + value)
		"cooldown_reduction":
			cat_data.cooldown_reduction = minf(0.5, cat_data.cooldown_reduction + value)
		"armor_pen":
			cat_data.armor_pen = maxf(0.0, cat_data.armor_pen + value)
		"evasion":
			cat_data.evasion = maxf(0.0, cat_data.evasion + value)
		"accuracy":
			cat_data.accuracy = maxf(0.0, cat_data.accuracy + value)
		"multi_hit_rate":
			cat_data.multi_hit_rate = maxf(0.0, cat_data.multi_hit_rate + value)
		"multi_hit_damage":
			cat_data.multi_hit_damage = maxf(0.0, cat_data.multi_hit_damage + value)
		"counter_damage_chance":
			cat_data.counter_damage_chance = maxf(0.0, cat_data.counter_damage_chance + value)
		"dungeon_damage_boost", "dungeon_damage_reduction", "life_steal", "physical_damage_boost", "physical_damage_reduction":
			cat_data.set_meta(stat, maxf(0.0, float(cat_data.get_meta(stat, 0.0)) + value))


static func _passive_scaling_value(scaling: Array, effect_index: int, rank: int) -> float:
	var total: float = 0.0
	for row_variant: Variant in scaling:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		if int(row.get("effect_index", -1)) != effect_index:
			continue
		total += floorf(float(rank) / 5.0) * float(row.get("per_5_ranks", 0.0))
	return total


static func _canonicalize_stat_key(raw_stat: String) -> String:
	match _normalize_key(raw_stat):
		"hp", "max_hp":
			return "max_hp"
		"hp_percent", "max_hp_percent":
			return "max_hp_percent"
		"atk", "attack":
			return "atk"
		"atk_percent", "attack_percent":
			return "atk_percent"
		"def", "defense":
			return "defense"
		"def_percent", "defense_percent":
			return "def_percent"
		"crit_dmg", "crit_damage", "crit_damage_bonus":
			return "crit_damage"
		"armor_pen", "armor_penetration", "ignore_armor", "ignore_def", "ignore_defense", "def_ignore", "defense_ignore":
			return "armor_pen"
		"dmg_reduction", "damage_reduction":
			return "damage_reduction"
		"cdr", "cooldown_reduction":
			return "cooldown_reduction"
		"multi_hit_dmg", "multi_hit_damage":
			return "multi_hit_damage"
		"counter_damage", "counter_damage_rate", "counter_damage_chance":
			return "counter_damage_chance"
		"physical_dmg_boost", "physical_damage_boost":
			return "physical_damage_boost"
		"physical_dmg_red", "physical_dmg_reduction", "physical_damage_reduction":
			return "physical_damage_reduction"
		"dungeon_dmg_boost", "dungeon_damage_boost":
			return "dungeon_damage_boost"
		"dungeon_dmg_red", "dungeon_dmg_reduction", "dungeon_damage_reduction":
			return "dungeon_damage_reduction"
		"life_steal", "lifesteal":
			return "life_steal"
		_:
			return _normalize_key(raw_stat)


static func _normalize_key(raw_value: String) -> String:
	var raw: String = raw_value.strip_edges()
	var result: String = ""
	for index: int in range(raw.length()):
		var ch: String = raw.substr(index, 1)
		if ch >= "A" and ch <= "Z":
			if index > 0 and not result.ends_with("_"):
				result += "_"
			result += ch.to_lower()
		else:
			result += ch.to_lower()
	result = result.replace(" ", "_").replace("-", "_")
	while result.find("__") >= 0:
		result = result.replace("__", "_")
	return result


static func _format_percent_value(value: float) -> String:
	return "%.1f%%" % (value * 100.0)


static func _format_flat_number(value: float) -> String:
	return GameState.format_number(int(roundf(value)))


static func _format_decimal_number(value: float) -> String:
	var rounded: float = snappedf(value, 0.1)
	if is_equal_approx(rounded, roundf(rounded)):
		return GameState.format_number(int(roundf(rounded)))
	return "%.1f" % rounded


static func make_separator() -> HSeparator:
	return HSeparator.new()
