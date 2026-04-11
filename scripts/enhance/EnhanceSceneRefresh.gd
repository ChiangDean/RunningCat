class_name EnhanceSceneRefresh
extends RefCounted


static func refresh_all_labels(scene) -> void:
	refresh_resource_label(scene)
	if scene._selected_cat_id == "":
		return

	var player_cat: PlayerCatData = scene.GameState.get_player_cat(scene._selected_cat_id)
	var cat_data := CatData.from_json_file(scene._selected_cat_id + ".json")
	if cat_data == null:
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
		scene._cat_name_label.text = CatRegistry.get_cat_display_name_with_lv(scene._selected_cat_id, player_cat.cat_food_level)


static func refresh_resource_label(scene) -> void:
	if scene._resource_label == null:
		return
	scene._resource_label.text = "普通乾糧：%d　特殊乾糧：%d　金幣：%d" % [
		scene.GameState.player_data.cat_food,
		scene.GameState.player_data.special_cat_food,
		scene.GameState.player_data.gold,
	]


static func refresh_stat_labels(scene, cat_data: CatData, player_cat: PlayerCatData) -> void:
	var food_lv := player_cat.cat_food_level - 1
	var sfp := player_cat.special_food_points
	var growth := cat_data.enhancement_growth
	var rank := player_cat.rank
	var rank_growth := cat_data.rank_growth

	var hp_pre := cat_data.max_hp + int(food_lv * growth.get("hp", 0.0)) + int(sfp.get("hp", 0) * growth.get("hp", 0.0))
	var hp_final := int(hp_pre * (1.0 + rank * rank_growth.get("hp_percent", 1.0) / 100.0))
	scene._stat_labels["hp"].text = "HP: %d" % hp_final

	var atk_pre := cat_data.atk + int(food_lv * growth.get("atk", 0.0)) + int(sfp.get("atk", 0) * growth.get("atk", 0.0))
	var atk_final := int(atk_pre * (1.0 + rank * rank_growth.get("atk_percent", 1.0) / 100.0))
	scene._stat_labels["atk"].text = "ATK: %d" % atk_final

	var def_pre := cat_data.defense + int(food_lv * growth.get("def", 0.0)) + int(sfp.get("def", 0) * growth.get("def", 0.0))
	var def_final := int(def_pre * (1.0 + rank * rank_growth.get("def_percent", 1.0) / 100.0))
	scene._stat_labels["def"].text = "DEF: %d" % def_final


static func refresh_food_labels(scene, player_cat: PlayerCatData) -> void:
	var lv := player_cat.cat_food_level
	var held: int = scene.GameState.player_data.cat_food

	if lv >= PlayerCatData.MAX_CAT_FOOD_LEVEL:
		if scene._food_cost_label != null:
			scene._food_cost_label.text = ""
		if scene._food_upgrade_btn:
			scene._food_upgrade_btn.text = "升級(Max)"
			scene._food_upgrade_btn.disabled = true
		if scene._food_max_btn:
			scene._food_max_btn.text = "快速升級(Max)"
			scene._food_max_btn.disabled = true
		return

	var cost := PlayerCatData.cat_food_cost_for_level(lv)
	if scene._food_cost_label != null:
		scene._food_cost_label.text = ""
	if scene._food_upgrade_btn:
		scene._food_upgrade_btn.text = "升級(%d/%d)" % [held, cost]
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
			scene._food_max_btn.text = "快速升級(Lv%d)" % target_lv
			scene._food_max_btn.disabled = scene._action_inflight
		else:
			scene._food_max_btn.text = "快速升級(不足)"
			scene._food_max_btn.disabled = true


static func refresh_special_cost_label(scene, player_cat: PlayerCatData) -> void:
	var total_pts := player_cat.get_total_special_points()
	var next_cost := PlayerCatData.special_food_next_cost(total_pts)
	scene._special_cost_label.text = "  特殊乾糧下一點費用：%d（持有 %d）" % [
		next_cost,
		scene.GameState.player_data.special_cat_food,
	]


static func refresh_special_point_labels(scene, player_cat: PlayerCatData) -> void:
	for stat_key: String in ["hp", "atk", "def"]:
		if not scene._special_point_labels.has(stat_key):
			continue
		scene._special_point_labels[stat_key].text = "%d" % int(player_cat.special_food_points.get(stat_key, 0))


static func refresh_special_buttons(scene, player_cat: PlayerCatData) -> void:
	var held: int = scene.GameState.player_data.special_cat_food
	var total_pts := player_cat.get_total_special_points()
	var next_cost := PlayerCatData.special_food_next_cost(total_pts)

	for stat_key: String in ["hp", "atk", "def"]:
		if scene._special_plus_btns.has(stat_key):
			var plus_btn: Button = scene._special_plus_btns[stat_key]
			plus_btn.text = "+"
			plus_btn.disabled = scene._action_inflight or held < next_cost
		if scene._special_minus_btns.has(stat_key):
			var minus_btn: Button = scene._special_minus_btns[stat_key]
			minus_btn.text = "−"
			minus_btn.disabled = scene._action_inflight or int(player_cat.special_food_points.get(stat_key, 0)) <= 0


static func refresh_rank_labels(scene, player_cat: PlayerCatData) -> void:
	if scene._rank_stars_label == null or scene._rank_upgrade_btn == null:
		return

	var rank := player_cat.rank
	scene._rank_stars_label.text = "★×%d" % rank if rank > 0 else ""
	var cost := PlayerCatData.rank_upgrade_cost(rank + 1)
	var held: int = player_cat.cat_shards
	scene._rank_upgrade_btn.text = "升階(%d/%d)" % [held, cost]
	scene._rank_upgrade_btn.disabled = scene._action_inflight or held < cost


static func build_skill_section(scene, cat_data: CatData, player_cat: PlayerCatData) -> void:
	var skill_title := Label.new()
	skill_title.text = "技能"
	skill_title.add_theme_font_size_override("font_size", 22)
	scene._detail_panel.add_child(skill_title)

	var rank: int = player_cat.rank

	for sid: String in cat_data.passive_skill_ids:
		var skill_d := CatData._read_skill_json(sid)
		if skill_d.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		scene._detail_panel.add_child(row)

		var lbl := Label.new()
		lbl.text = "【被動】%s" % skill_d.get("display_name", sid)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(lbl)

		if rank >= 5:
			var rank_lbl := Label.new()
			rank_lbl.text = "+%d" % int(rank / 5)
			rank_lbl.add_theme_font_size_override("font_size", 16)
			rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			row.add_child(rank_lbl)

		var info_btn := Button.new()
		info_btn.text = "?"
		info_btn.custom_minimum_size = Vector2(36.0, 36.0)
		info_btn.pressed.connect(Callable(scene, "_show_skill_bonus_info").bind(skill_d, rank, false))
		row.add_child(info_btn)

	for skill_d: Dictionary in cat_data.active_skills_data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		scene._detail_panel.add_child(row)

		var lbl := Label.new()
		lbl.text = "【主動】%s  CD: %.1fs" % [skill_d.get("display_name", ""), skill_d.get("cooldown", 0.0)]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(lbl)

		if rank >= 5:
			var rank_lbl := Label.new()
			rank_lbl.text = "+%d" % int(rank / 5)
			rank_lbl.add_theme_font_size_override("font_size", 16)
			rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
			row.add_child(rank_lbl)

		var info_btn := Button.new()
		info_btn.text = "?"
		info_btn.custom_minimum_size = Vector2(36.0, 36.0)
		info_btn.pressed.connect(Callable(scene, "_show_skill_bonus_info").bind(skill_d, rank, true))
		row.add_child(info_btn)


static func show_rank_bonus_info(cat_data: CatData, rank: int) -> void:
	var rg := cat_data.rank_growth
	var lines: Array[String] = []

	if rank <= 0:
		lines.append("尚未升階")
		lines.append("")
		lines.append("每升一階：")
		lines.append("  血量、攻擊、防禦各額外提升 +1%")
	else:
		lines.append("目前品階 +%d 的加成：" % rank)
		lines.append("  血量額外提升 +%.0f%%" % (rank * rg.get("hp_percent", 1.0)))
		lines.append("  攻擊額外提升 +%.0f%%" % (rank * rg.get("atk_percent", 1.0)))
		lines.append("  防禦額外提升 +%.0f%%" % (rank * rg.get("def_percent", 1.0)))

	DialogManager.show_info("品階加成說明", "\n".join(lines))


static func show_skill_bonus_info(skill_d: Dictionary, rank: int, _is_active: bool) -> void:
	var name: String = skill_d.get("display_name", "")
	var desc: String = skill_d.get("description", "")
	var scaling: Array = skill_d.get("rank_scaling", [])
	var effects: Array = skill_d.get("effects", [])
	var lines: Array[String] = [name, desc, ""]

	if rank <= 0 or scaling.is_empty():
		lines.append("尚未升階，無額外加成。")
	else:
		lines.append("目前品階 +%d 的技能加成：" % rank)
		for rs: Dictionary in scaling:
			var eff_idx: int = rs.get("effect_index", 0)
			var per_5: float = rs.get("per_5_ranks", 0.0)
			var bonus: float = floorf(rank / 5.0) * per_5
			if bonus <= 0.0:
				continue
			var stat_name := "效果"
			if eff_idx < effects.size():
				var eff: Dictionary = effects[eff_idx]
				stat_name = stat_display_label(eff.get("stat", ""), eff.get("type", ""))
			lines.append("  %s 額外增強 +%.0f%%" % [stat_name, bonus * 100.0])

	DialogManager.show_info("技能加成說明", "\n".join(lines))


static func stat_display_label(stat: String, eff_type: String) -> String:
	match stat:
		"defense":
			return "防禦力"
		"atk":
			return "攻擊力"
		"speed":
			return "速度"
		"max_hp":
			return "最大 HP"
		_:
			if eff_type == "damage":
				return "傷害"
			if eff_type == "reflect":
				return "反彈傷害"
			return "效果"


static func get_display_name(cat_id: String) -> String:
	var data := CatData.from_json_file(cat_id + ".json")
	if data != null:
		return data.display_name
	return cat_id


static func stat_display_name(stat_key: String) -> String:
	match stat_key:
		"hp":
			return "HP"
		"atk":
			return "ATK"
		"def":
			return "DEF"
	return stat_key.to_upper()


static func make_separator() -> HSeparator:
	return HSeparator.new()
