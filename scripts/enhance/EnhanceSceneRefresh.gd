class_name EnhanceSceneRefresh
extends RefCounted

const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const RedDotService = preload("res://scripts/ui/red_dot_service.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const SceneMenuTheme = preload("res://scripts/ui/scene_menu_theme.gd")


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
		scene._special_point_labels[stat_key].text = "%d" % int(effective_points.get(stat_key, 0))


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
		scene._rank_progress_label.text = "%d/%d" % [held, cost]
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
	return "%s：%d +%d (%s)" % [label, value, point_delta, _format_bonus_value(bonus)]


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
		row.add_theme_constant_override("separation", 8)
		scene._detail_panel.add_child(row)

		var lbl := Label.new()
		lbl.text = UiText.ENHANCE_PASSIVE_SKILL_FORMAT % [skill_d.get("display_name", sid)]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		row.add_child(lbl)

		if rank >= 5:
			var rank_lbl := Label.new()
			rank_lbl.text = UiText.ENHANCE_SKILL_RANK_BONUS_FORMAT % [int(rank / 5)]
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
		row.add_theme_constant_override("separation", 8)
		scene._detail_panel.add_child(row)

		var lbl := Label.new()
		lbl.text = UiText.ENHANCE_ACTIVE_SKILL_FORMAT % [skill_d.get("display_name", ""), skill_d.get("cooldown", 0.0)]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		row.add_child(lbl)

		if rank >= 5:
			var rank_lbl := Label.new()
			rank_lbl.text = UiText.ENHANCE_SKILL_RANK_BONUS_FORMAT % [int(rank / 5)]
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


static func make_separator() -> HSeparator:
	return HSeparator.new()
