class_name StatsPanel
extends Control

## Floating stats overview panel shown from the battle scene.
## Tabs: 全部 / 技能 / 裝備 / 回憶 / 寶藏 / 等級
## 角色被動 is rendered inside 全部 for each currently deployed cat.

const PANEL_OFFSET_TOP    := 96.0
const PANEL_OFFSET_BOTTOM := 120.0
const PANEL_OFFSET_SIDE   := 16.0

const TABS: Array = ["all", "ability", "equipment", "memory", "treasure", "level"]

var _current_tab: String = "all"
var _tab_btns: Dictionary = {}
var _content_box: VBoxContainer
var _game_state: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_game_state = get_node("/root/GameState")
	_build_panel()


func _build_panel() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.0, 0.0, 0.0, 0.60)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_backdrop_input)
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left   = PANEL_OFFSET_SIDE
	panel.offset_top    = PANEL_OFFSET_TOP
	panel.offset_right  = -PANEL_OFFSET_SIDE
	panel.offset_bottom = -PANEL_OFFSET_BOTTOM

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.10, 0.08, 0.97)
	style.border_color = Color(0.56, 0.44, 0.28, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# ── Title row ──────────────────────────────────────
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)

	var title_lbl := Label.new()
	title_lbl.text = UiText.STATS_PANEL_TITLE
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))
	title_row.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = UiText.STATS_PANEL_CLOSE
	close_btn.custom_minimum_size = Vector2(38.0, 38.0)
	UiPalette.apply_button_kind(close_btn, "info")
	close_btn.pressed.connect(func() -> void: visible = false)
	title_row.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# ── Tab buttons ────────────────────────────────────
	var tab_labels: Dictionary = {
		"all":       UiText.STATS_TAB_ALL,
		"ability":   UiText.STATS_TAB_ABILITY,
		"equipment": UiText.STATS_TAB_EQUIPMENT,
		"memory":    UiText.STATS_TAB_MEMORY,
		"treasure":  UiText.STATS_TAB_TREASURE,
		"level":     UiText.STATS_TAB_LEVEL,
	}

	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 5)
	vbox.add_child(tabs_row)

	for tab_key: String in TABS:
		var btn := Button.new()
		btn.text = tab_labels.get(tab_key, tab_key)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		var capture: String = tab_key
		btn.pressed.connect(func() -> void: _switch_tab(capture))
		tabs_row.add_child(btn)
		_tab_btns[tab_key] = btn

	_refresh_tab_styles()
	vbox.add_child(HSeparator.new())

	# ── Scrollable content ────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_content_box)

	_rebuild_content()


func refresh() -> void:
	_rebuild_content()


# ── Tab switching ──────────────────────────────────────

func _switch_tab(tab_key: String) -> void:
	_current_tab = tab_key
	_refresh_tab_styles()
	_rebuild_content()


func _refresh_tab_styles() -> void:
	for tab_key: String in _tab_btns.keys():
		var btn: Button = _tab_btns[tab_key]
		UiPalette.apply_button_kind(btn, "primary" if tab_key == _current_tab else "secondary")


# ── Content building ───────────────────────────────────

func _rebuild_content() -> void:
	if _content_box == null:
		return
	for child: Node in _content_box.get_children():
		child.queue_free()

	match _current_tab:
		"all":       _build_all_tab()
		"ability":   _build_ability_section(_content_box)
		"equipment": _build_bonus_section(_content_box, UiText.STATS_SECTION_EQUIPMENT,
				_game_state.get_equipment_bonuses(), Color(0.72, 0.88, 0.72, 0.9))
		"memory":    _build_bonus_section(_content_box, UiText.STATS_SECTION_MEMORY,
				_game_state.get_memory_bonuses(), Color(0.87, 0.72, 1.0, 0.9))
		"treasure":  _build_treasure_tab()
		"level":     _build_level_section(_content_box)


func _build_all_tab() -> void:
	# Global combat bonuses (equipment + memory + treasure combat stats)
	var combat: Array = []
	combat.append_array(_game_state.get_equipment_bonuses())
	combat.append_array(_game_state.get_memory_bonuses())
	combat.append_array(_game_state.get_treasure_combat_bonuses())
	_build_bonus_section(_content_box, UiText.STATS_SECTION_ALL_COMBAT,
			combat, Color(1.0, 0.88, 0.55, 0.9))

	# Non-combat / special-ability effects
	_build_ability_section(_content_box)

	# Idle poop bonus from treasures
	var poop_bonus: float = _game_state.get_treasure_idle_poop_bonus()
	if poop_bonus > 0.0001:
		_add_section(_content_box, UiText.STATS_SECTION_POOP,
				[_format_bonus_line("idle_poop_percent", "all", poop_bonus)],
				Color(0.92, 0.78, 0.50, 0.9))

	# Scooper level
	_build_level_section(_content_box)

	# Deployed-character passives
	_build_team_passive_sections(_content_box)


func _build_ability_section(container: VBoxContainer) -> void:
	var summary: Dictionary = _game_state.get_special_ability_summary()
	var lines: Array[String] = []

	var mult: float = float(summary.get("idle_reward_multiplier", 1.0))
	if mult > 1.0:
		lines.append("放置收益倍率  ×%.1f" % mult)

	var hours: int = int(summary.get("idle_max_hours_bonus", 0))
	if hours > 0:
		lines.append("掛機上限  +%d 小時" % hours)

	var speed_cap: float = float(summary.get("battle_speed_cap", 1.0))
	if speed_cap > 1.0:
		lines.append("戰鬥加速上限  ×%.0f" % speed_cap)

	if bool(summary.get("battle_skip_unlocked", false)):
		lines.append("可跳過戰鬥")

	_add_section(container, UiText.STATS_SECTION_ABILITY, lines, Color(0.54, 0.76, 0.92, 0.9))


func _build_bonus_section(container: VBoxContainer, title: String,
		bonuses: Array, accent: Color) -> void:
	var agg := _aggregate(bonuses)
	var lines: Array[String] = []
	for stat: String in agg.keys():
		for target: String in (agg[stat] as Dictionary).keys():
			var value: float = float((agg[stat] as Dictionary).get(target, 0.0))
			if absf(value) < 0.0001:
				continue
			lines.append(_format_bonus_line(stat, target, value))
	_add_section(container, title, lines, accent)


func _build_treasure_tab() -> void:
	var all_effects: Array = _game_state.get_treasure_effects()
	var combat_effs: Array = []
	var poop_effs: Array = []
	for eff: Dictionary in all_effects:
		if str(eff.get("stat", "")) == "idle_poop_percent":
			poop_effs.append(eff)
		else:
			combat_effs.append(eff)

	_build_bonus_section(_content_box, UiText.STATS_SECTION_TREASURE,
			combat_effs, Color(0.92, 0.78, 0.50, 0.9))

	if not poop_effs.is_empty():
		var poop_agg := _aggregate(poop_effs)
		var poop_lines: Array[String] = []
		for stat: String in poop_agg.keys():
			for target: String in (poop_agg[stat] as Dictionary).keys():
				var v: float = float((poop_agg[stat] as Dictionary).get(target, 0.0))
				if absf(v) > 0.0001:
					poop_lines.append(_format_bonus_line(stat, target, v))
		_add_section(_content_box, UiText.STATS_SECTION_POOP,
				poop_lines, Color(0.92, 0.78, 0.50, 0.9))


func _build_level_section(container: VBoxContainer) -> void:
	var lv: int = _game_state.player_data.scooper_level
	_add_section(container, UiText.STATS_SECTION_LEVEL, [
		"鏟屎官等級  Lv.%d" % lv,
		"裝備升級上限  Lv.%d" % lv,
	], Color(0.80, 0.68, 0.90, 0.9))


func _build_team_passive_sections(container: VBoxContainer) -> void:
	var team: Array = _game_state.player_team
	if team.is_empty():
		return

	for player_cat_id: Variant in team:
		var cat_file_id: String = _game_state.get_cat_file_id(int(player_cat_id))
		if cat_file_id == "":
			continue
		var cat_data: CatData = CatData.from_json_file(cat_file_id + ".json")
		if cat_data == null or cat_data.passive_skills_data.is_empty():
			continue

		var rank: int = _game_state.get_player_cat(cat_file_id).rank
		var lines: Array[String] = []

		for passive: Dictionary in cat_data.passive_skills_data:
			var skill_name: String = str(passive.get("display_name", ""))
			var effects: Array = passive.get("effects", [])
			var rank_scaling: Array = passive.get("rank_scaling", [])
			var skill_lines: Array[String] = []

			for eff: Dictionary in effects:
				var raw_val: float = float(eff.get("value", 0.0))
				var eff_idx: int = effects.find(eff)
				for rs: Dictionary in rank_scaling:
					if int(rs.get("effect_index", -1)) == eff_idx:
						raw_val += floorf(rank / 5.0) * float(rs.get("per_5_ranks", 0.0))

				var line: String = _format_passive_effect(
						str(eff.get("type", "")),
						str(eff.get("stat", "")),
						raw_val,
						str(eff.get("value_type", "percent")),
						str(eff.get("target", "team")))
				if line != "":
					skill_lines.append(line)

			if not skill_lines.is_empty():
				if skill_name != "":
					lines.append("[%s]  %s" % [skill_name, "、".join(skill_lines)])
				else:
					lines.append_array(skill_lines)

		if not lines.is_empty():
			var title: String = UiText.STATS_SECTION_PASSIVE_FORMAT % cat_data.display_name
			_add_section(container, title, lines, Color(0.90, 0.72, 0.72, 0.9))


# ── Helpers ────────────────────────────────────────────

func _aggregate(bonuses: Array) -> Dictionary:
	var result: Dictionary = {}
	for b: Variant in bonuses:
		if not (b is Dictionary):
			continue
		var stat: String = str((b as Dictionary).get("stat", ""))
		var target: String = str((b as Dictionary).get("target", "all")).to_lower()
		var value: float = float((b as Dictionary).get("value", 0.0))
		if stat == "":
			continue
		if not result.has(stat):
			result[stat] = {}
		if not (result[stat] as Dictionary).has(target):
			(result[stat] as Dictionary)[target] = 0.0
		(result[stat] as Dictionary)[target] = \
				float((result[stat] as Dictionary).get(target, 0.0)) + value
	return result


func _format_bonus_line(stat: String, target: String, value: float) -> String:
	var name: String = _stat_label(stat)
	var val_str: String = _format_value(stat, value)
	if target == "all":
		return "%s  %s" % [name, val_str]
	return "%s  %s（%s）" % [name, val_str, _target_label(target)]


func _format_passive_effect(eff_type: String, stat: String, value: float,
		value_type: String, target: String) -> String:
	var suffix: String = ""
	if target == "self":
		suffix = "（自身）"
	elif target != "team":
		suffix = "（%s）" % _target_label(target)

	match eff_type:
		"stat_boost":
			if value_type == "percent":
				return "%s %+.0f%%%s" % [_passive_stat_label(stat), value * 100.0, suffix]
			return "%s %+d%s" % [_passive_stat_label(stat), int(value), suffix]
		"damage_reduction":
			return "減傷 %+.0f%%%s" % [value * 100.0, suffix]
		"cooldown_reduction":
			return "冷卻縮減 %+.0f%%%s" % [value * 100.0, suffix]
	return ""


func _stat_label(stat: String) -> String:
	match stat:
		"atk_percent":       return "攻擊加成"
		"def_percent":       return "防禦加成"
		"max_hp_percent":    return "生命加成"
		"crit_rate":         return "暴擊率"
		"crit_damage":       return "暴擊傷害"
		"damage_reduction":  return "減傷"
		"cooldown_reduction": return "冷卻縮減"
		"idle_poop_percent": return "便便收益"
		_:                   return stat


func _passive_stat_label(stat: String) -> String:
	match stat:
		"atk":      return "攻擊力"
		"defense":  return "防禦力"
		"max_hp":   return "最大生命"
		"speed":    return "速度"
		_:          return stat


func _target_label(target: String) -> String:
	match target:
		"all":       return "全隊"
		"tank":      return "坦克"
		"speed":     return "速度型"
		"assassin":  return "刺客"
		"defensive": return "防禦系"
		"team":      return "我方"
		"self":      return "自身"
		_:           return target


func _format_value(stat: String, value: float) -> String:
	var pct_stats: Array = ["atk_percent", "def_percent", "max_hp_percent",
		"crit_rate", "crit_damage", "damage_reduction", "cooldown_reduction",
		"idle_poop_percent"]
	if stat in pct_stats:
		return "%+.0f%%" % (value * 100.0)
	return "%+d" % int(value)


func _add_section(container: VBoxContainer, title: String,
		lines: Array[String], accent: Color) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.10, 0.92)
	style.border_color = accent
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	container.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.64, 1.0))
	vbox.add_child(title_lbl)

	vbox.add_child(HSeparator.new())

	if lines.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = UiText.STATS_SECTION_EMPTY
		empty_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		empty_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60, 1.0))
		vbox.add_child(empty_lbl)
		return

	for line: String in lines:
		var lbl := Label.new()
		lbl.text = line
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		vbox.add_child(lbl)


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			visible = false
