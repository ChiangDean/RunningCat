extends Control


const TAB_ALL := "all"
const TAB_ABILITY := "ability"
const TAB_EQUIPMENT := "equipment"
const TAB_MEMORY := "memory"
const TAB_TREASURE := "treasure"
const TAB_LEVEL := "level"
const TAB_FRIEND := "friend"







var _close_action: Callable = Callable()
var _active_tab: String = TAB_ALL
var _submenu_buttons: Dictionary = {}
var _content_list: VBoxContainer
@onready var _game_state: Node = get_node("/root/GameState")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(680.0, 920.0)
	_build_ui()
	_refresh_view()


func set_close_action(action: Callable) -> void:
	_close_action = action


func _build_ui() -> void:
	var root: MarginContainer = MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_right", 24)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 0)
	root.add_child(layout)

	var body_host: Control = Control.new()
	body_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body_host)

	var submenu: Dictionary = SceneSecondarySubmenu.build(body_host, {
		"items": _build_tab_items(),
		"active_key": _active_tab,
		"button_pressed": Callable(self, "_on_tab_pressed"),
		"secondary_width": 170.0,
		"row_separation": 14,
		"secondary_border": OverlaySceneChrome.PANEL_BORDER,
		"content_border": OverlaySceneChrome.CARD_BORDER,
	})
	_submenu_buttons = submenu.get("secondary_buttons", {})
	_content_list = submenu.get("content_list")


func _on_back_pressed() -> void:
	if _can_invoke_callable(_close_action):
		_close_action.call()
		return
	var scene_navigator: Node = get_node_or_null("/root/SceneNavigator")
	if scene_navigator != null and scene_navigator.has_method("return_to_battle"):
		scene_navigator.call("return_to_battle")


func _can_invoke_callable(callback: Callable) -> bool:
	if callback.is_null() or not callback.is_valid():
		return false
	var object_id: int = callback.get_object_id()
	if object_id == 0:
		return true
	var target: Object = instance_from_id(object_id)
	return target != null and is_instance_valid(target)


func _build_tab_items() -> Array:
	return [
		{"key": TAB_ALL, "label": UiText.STATS_TAB_ALL},
		{"key": TAB_ABILITY, "label": UiText.STATS_TAB_ABILITY},
		{"key": TAB_EQUIPMENT, "label": UiText.STATS_TAB_EQUIPMENT},
		{"key": TAB_MEMORY, "label": UiText.STATS_TAB_MEMORY},
		{"key": TAB_TREASURE, "label": UiText.STATS_TAB_TREASURE},
		{"key": TAB_LEVEL, "label": UiText.STATS_TAB_LEVEL},
		{"key": TAB_FRIEND, "label": UiText.STATS_TAB_FRIEND},
	]


func _on_tab_pressed(tab_key: String) -> void:
	if _active_tab == tab_key:
		return
	_active_tab = tab_key
	_refresh_view()


func _refresh_view() -> void:
	if _content_list == null:
		return
	SceneSecondarySubmenu.refresh(_submenu_buttons, _active_tab)
	_clear_children(_content_list)

	match _active_tab:
		TAB_ALL:
			_content_list.add_child(_build_all_tab())
		TAB_ABILITY:
			_content_list.add_child(_build_ability_tab())
		TAB_EQUIPMENT:
			_content_list.add_child(_build_equipment_tab())
		TAB_MEMORY:
			_content_list.add_child(_build_memory_tab())
		TAB_TREASURE:
			_content_list.add_child(_build_treasure_tab())
		TAB_LEVEL:
			_content_list.add_child(_build_level_tab())
		TAB_FRIEND:
			_content_list.add_child(_build_friend_tab())
func _build_all_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	var lines: Array[String] = []
	lines.append_array(_build_level_summary_lines())
	lines.append_array(_format_aggregate_lines(_collect_all_bonuses()))
	lines.append_array(_build_ability_summary_lines())

	if lines.is_empty():
		root.add_child(_make_empty_card(UiText.STATS_ALL_NO_ACTIVE_BONUSES, UiText.STATS_ALL_NO_ACTIVE_BONUSES_DESC))
		return root

	root.add_child(_make_lines_card(UiText.STATS_PANEL_TITLE, lines, Color(0.92, 0.78, 0.50, 0.95)))
	return root


func _build_ability_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var lines: Array[String] = _build_ability_effect_lines()
	if lines.is_empty():
		root.add_child(_make_empty_card(UiText.STATS_SECTION_EMPTY, UiText.STATS_ABILITY_EMPTY_DESC))
		return root

	root.add_child(_make_lines_card(UiText.STATS_SECTION_ABILITY, lines, Color(0.54, 0.76, 0.92, 0.95)))
	return root


func _build_equipment_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var lines: Array[String] = _format_aggregate_lines(_collect_equipment_bonuses())
	if lines.is_empty():
		root.add_child(_make_empty_card(UiText.STATS_SECTION_EMPTY, UiText.STATS_EQUIPMENT_EMPTY_DESC))
		return root
	root.add_child(_make_lines_card(UiText.STATS_SECTION_EQUIPMENT, lines, Color(0.70, 0.88, 0.72, 0.95)))
	return root


func _build_memory_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var lines: Array[String] = _format_aggregate_lines(_collect_memory_bonuses())
	if lines.is_empty():
		root.add_child(_make_empty_card(UiText.STATS_SECTION_EMPTY, UiText.STATS_MEMORY_EMPTY_DESC))
		return root
	root.add_child(_make_lines_card(UiText.STATS_SECTION_MEMORY, lines, Color(0.87, 0.72, 1.0, 0.95)))
	return root


func _build_treasure_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var treasure_lines: Array[String] = _format_aggregate_lines(_collect_treasure_combat_bonuses())
	var poop_lines: Array[String] = _format_aggregate_lines(_collect_treasure_poop_bonuses())

	if treasure_lines.is_empty() and poop_lines.is_empty():
		root.add_child(_make_empty_card(UiText.STATS_SECTION_EMPTY, UiText.STATS_TREASURE_EMPTY_DESC))
		return root
	if not treasure_lines.is_empty():
		root.add_child(_make_lines_card(UiText.STATS_SECTION_TREASURE, treasure_lines, Color(0.94, 0.78, 0.48, 0.95)))
	if not poop_lines.is_empty():
		root.add_child(_make_lines_card(UiText.STATS_SECTION_POOP, poop_lines, Color(0.95, 0.78, 0.45, 0.95)))
	return root


func _build_level_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.add_child(_make_lines_card(UiText.STATS_SECTION_LEVEL, _build_level_summary_lines(), Color(0.74, 0.66, 0.92, 0.95)))

	var passive_lines: Array[String] = _build_team_passive_summary_lines()
	if passive_lines.is_empty():
		root.add_child(_make_empty_card(UiText.STATS_PASSIVE_EMPTY, UiText.STATS_PASSIVE_EMPTY_DESC))
	else:
		root.add_child(_make_lines_card(UiText.STATS_PASSIVE_TITLE, passive_lines, Color(0.92, 0.72, 0.72, 0.95)))
	return root


func _build_friend_tab() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)

	var friend_bonuses: Array = _collect_friend_bonuses()
	var lines: Array[String] = _format_aggregate_lines(friend_bonuses)
	if lines.is_empty():
		root.add_child(_make_empty_card(UiText.STATS_SECTION_EMPTY, UiText.STATS_FRIEND_EMPTY_DESC))
		return root

	var friends: Array = _game_state.friend_list_data.get("friends", [])
	lines.insert(0, UiText.STATS_FRIEND_BONUS_FORMAT % friends.size())
	root.add_child(_make_lines_card(UiText.STATS_SECTION_FRIEND, lines, Color(0.50, 0.80, 0.90, 0.95)))
	return root


func _build_level_summary_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append(UiText.STATS_SCOOPER_LEVEL_FORMAT % int(_game_state.player_data.scooper_level))
	lines.append(UiText.STATS_SCOOPER_EXP_FORMAT % int(_game_state.player_data.scooper_exp))
	lines.append(UiText.STATS_EQUIP_LEVEL_NOTE)
	return lines


func _collect_combat_bonuses() -> Array:
	var bonuses: Array = []
	bonuses.append_array(_collect_equipment_bonuses())
	bonuses.append_array(_collect_memory_bonuses())
	bonuses.append_array(_collect_treasure_combat_bonuses())
	bonuses.append_array(_collect_friend_bonuses())
	return bonuses


func _collect_all_bonuses() -> Array:
	var bonuses: Array = []
	bonuses.append_array(_collect_combat_bonuses())
	bonuses.append_array(_collect_treasure_poop_bonuses())
	bonuses.append_array(_collect_team_passive_bonuses())
	return bonuses


func _build_ability_summary_lines() -> Array[String]:
	return _build_ability_effect_lines()

func _build_ability_effect_lines() -> Array[String]:
	var live_entries: Array = _get_live_scooper_entries("scooper_ability_data")
	if not live_entries.is_empty():
		var summary: Dictionary = {
			"idle_reward_multiplier": 1.0,
			"idle_max_hours_bonus": 0,
			"battle_speed_cap": 1.0,
			"battle_skip_unlocked": false,
			"scaled_scoop_by_level": false,
			"diamond_scoop_slot_unlocked": false,
			"battle_speed_charge_unlocked": false,
			"battle_speed_rate_upgrade_unlocked": false,
			"ad_free": false,
			"friend_capacity_unlocked": false,
			"lifetime_privilege": false,
			"monthly_privilege": false,
			"max_team_slots": 1,
		}
		for entry_variant: Variant in live_entries:
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = entry_variant
			var effect_type: String = _normalize_key(str(entry.get("effectType", "")))
			var quantity: int = maxi(1, int(entry.get("quantity", 1)))
			var effect_value: float = float(entry.get("effectValue", 0.0))
			match effect_type:
				"idle_reward_multiplier":
					summary["idle_reward_multiplier"] = float(summary.get("idle_reward_multiplier", 1.0)) + (effect_value * quantity)
				"idle_max_hours_bonus":
					summary["idle_max_hours_bonus"] = int(summary.get("idle_max_hours_bonus", 0)) + int(effect_value) * quantity
				"unlock_battle_speed":
					summary["battle_speed_cap"] = maxf(float(summary.get("battle_speed_cap", 1.0)), effect_value)
				"unlock_battle_skip":
					summary["battle_skip_unlocked"] = bool(summary.get("battle_skip_unlocked", false)) or quantity > 0 or bool(effect_value > 0.0)
				"scaled_scoop_by_level":
					summary["scaled_scoop_by_level"] = true
				"unlock_diamond_scoop_slot":
					summary["diamond_scoop_slot_unlocked"] = true
				"unlock_battle_speed_charge":
					summary["battle_speed_charge_unlocked"] = true
				"unlock_battle_speed_rate_upgrade":
					summary["battle_speed_rate_upgrade_unlocked"] = true
				"unlock_ad_free":
					summary["ad_free"] = true
				"unlock_friend_capacity_upgrade":
					summary["friend_capacity_unlocked"] = true
				"lifetime_privilege":
					summary["lifetime_privilege"] = true
				"monthly_privilege":
					summary["monthly_privilege"] = true
				"unlock_team_slot":
					summary["max_team_slots"] = maxi(int(summary.get("max_team_slots", 1)), int(effect_value))
		return _build_ability_lines_from_summary(summary)

	return _build_ability_lines_from_summary(_game_state.get_special_ability_summary())


func _build_ability_lines_from_summary(summary: Dictionary) -> Array[String]:
	var lines: Array[String] = []

	var reward_multiplier: float = float(summary.get("idle_reward_multiplier", 1.0)) - 1.0
	if reward_multiplier > 0.0001:
		lines.append(UiText.STATS_IDLE_REWARD_FORMAT % (reward_multiplier * 100.0))

	var idle_hours: int = int(summary.get("idle_max_hours_bonus", 0))
	if idle_hours > 0:
		lines.append(UiText.STATS_IDLE_CAP_FORMAT % idle_hours)

	var speed_cap: float = float(summary.get("battle_speed_cap", 1.0))
	if speed_cap > 1.0001:
		lines.append(UiText.STATS_SPEED_UNLOCK_FORMAT % speed_cap)

	if bool(summary.get("battle_skip_unlocked", false)):
		lines.append(UiText.STATS_BATTLE_SKIP_UNLOCKED)

	if bool(summary.get("scaled_scoop_by_level", false)):
		lines.append(UiText.STATS_SCALED_SCOOP)

	if bool(summary.get("diamond_scoop_slot_unlocked", false)):
		lines.append(UiText.STATS_DIAMOND_SCOOP_SLOT)

	if bool(summary.get("battle_speed_charge_unlocked", false)):
		lines.append(UiText.STATS_BATTLE_SPEED_CHARGE)

	if bool(summary.get("battle_speed_rate_upgrade_unlocked", false)):
		lines.append(UiText.STATS_BATTLE_SPEED_RATE_UPGRADE)

	if bool(summary.get("ad_free", false)):
		lines.append(UiText.STATS_AD_FREE)

	if bool(summary.get("friend_capacity_unlocked", false)):
		lines.append(UiText.STATS_FRIEND_CAPACITY)

	if bool(summary.get("lifetime_privilege", false)):
		lines.append(UiText.STATS_LIFETIME_PRIVILEGE)

	if bool(summary.get("monthly_privilege", false)):
		lines.append(UiText.STATS_MONTHLY_PRIVILEGE)

	var team_slots: int = int(summary.get("max_team_slots", 1))
	if team_slots > 1:
		lines.append(UiText.STATS_TEAM_SLOTS_FORMAT % team_slots)

	return lines


func _collect_equipment_bonuses() -> Array:
	var live_entries: Array = _get_live_scooper_entries("scooper_equipment_data")
	if not live_entries.is_empty():
		var result: Array = []
		for entry_variant: Variant in live_entries:
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = entry_variant
			if not bool(entry.get("isOwned", false)):
				continue
			if bool(entry.get("isBroken", false)):
				continue
			var level: int = int(entry.get("level", 0))
			if level <= 0:
				continue
			var stat: String = _canonicalize_stat_key(str(entry.get("bonusStat", "")))
			if stat == "":
				continue
			result.append({
				"target": _normalize_target_key(str(entry.get("bonusTarget", "All"))),
				"stat": stat,
				"value": float(entry.get("bonusPerLevel", 0.0)) * level,
			})
		return result
	return _normalize_bonus_array(_game_state.get_equipment_bonuses())


func _collect_memory_bonuses() -> Array:
	var live_entries: Array = _get_live_scooper_entries("scooper_memory_data")
	if not live_entries.is_empty():
		var result: Array = []
		for entry_variant: Variant in live_entries:
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = entry_variant
			if not bool(entry.get("isUnlocked", false)):
				continue
			var stat: String = _canonicalize_stat_key(str(entry.get("bonusStatType", "")))
			if stat == "":
				continue
			result.append({
				"target": _normalize_target_key(str(entry.get("bonusTarget", "All"))),
				"stat": stat,
				"value": float(entry.get("bonusValue", 0.0)),
			})
		return result
	return _normalize_bonus_array(_game_state.get_memory_bonuses())


func _collect_treasure_combat_bonuses() -> Array:
	var results: Array = []
	for bonus_variant: Variant in _collect_treasure_bonuses():
		if not (bonus_variant is Dictionary):
			continue
		var bonus: Dictionary = bonus_variant
		if not _is_combat_bonus_stat(str(bonus.get("stat", ""))):
			continue
		results.append(bonus)
	return results


func _collect_treasure_poop_bonuses() -> Array:
	var results: Array = []
	for bonus_variant: Variant in _collect_treasure_bonuses():
		if not (bonus_variant is Dictionary):
			continue
		var bonus: Dictionary = bonus_variant
		if str(bonus.get("stat", "")) != "idle_poop_percent":
			continue
		results.append(bonus)
	return results


func _collect_friend_bonuses() -> Array:
	return _game_state.get_friend_bonuses()


func _collect_treasure_bonuses() -> Array:
	var live_entries: Array = _get_live_scooper_entries("scooper_treasure_data")
	if not live_entries.is_empty():
		var result: Array = []
		for entry_variant: Variant in live_entries:
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = entry_variant
			var quantity: int = int(entry.get("quantity", 0))
			if quantity <= 0:
				continue
			var effects_variant: Variant = entry.get("effects", [])
			if not (effects_variant is Array):
				continue
			for effect_variant: Variant in effects_variant:
				if not (effect_variant is Dictionary):
					continue
				var effect: Dictionary = effect_variant
				var stat: String = _canonicalize_stat_key(str(effect.get("statType", effect.get("stat", ""))))
				if stat == "":
					continue
				result.append({
					"target": _normalize_target_key(str(effect.get("targetElementType", effect.get("target", "All")))),
					"stat": stat,
					"value": float(effect.get("value", 0.0)) * quantity,
				})
		return result
	return _normalize_bonus_array(_game_state.get_treasure_effects())


func _build_team_passive_summary_lines() -> Array[String]:
	var team: Array = _game_state.player_team
	if team.is_empty():
		return []

	var aggregate: Dictionary = {}

	for player_cat_id_variant: Variant in team:
		var player_cat_id: int = int(player_cat_id_variant)
		if player_cat_id <= 0:
			continue
		var cat_file_id: String = _game_state.get_cat_file_id(player_cat_id)
		if cat_file_id == "":
			continue
		var cat_data: CatData = CatData.from_json_file(cat_file_id + ".json")
		if cat_data == null or cat_data.passive_skills_data.is_empty():
			continue

		var player_cat: PlayerCatData = _game_state.get_player_cat(cat_file_id)
		var rank: int = int(player_cat.rank)
		for passive_variant: Variant in cat_data.passive_skills_data:
			if not (passive_variant is Dictionary):
				continue
			var passive: Dictionary = passive_variant
			_aggregate_passive_effects(aggregate, passive, rank)

	return _format_passive_aggregate_lines(aggregate)


func _collect_team_passive_bonuses() -> Array:
	var bonuses: Array = []
	var team: Array = _game_state.player_team
	if team.is_empty():
		return bonuses

	for player_cat_id_variant: Variant in team:
		var player_cat_id: int = int(player_cat_id_variant)
		if player_cat_id <= 0:
			continue
		var cat_file_id: String = _game_state.get_cat_file_id(player_cat_id)
		if cat_file_id == "":
			continue
		var cat_data: CatData = CatData.from_json_file(cat_file_id + ".json")
		if cat_data == null or cat_data.passive_skills_data.is_empty():
			continue

		var player_cat: PlayerCatData = _game_state.get_player_cat(cat_file_id)
		var rank: int = int(player_cat.rank)
		for passive_variant: Variant in cat_data.passive_skills_data:
			if not (passive_variant is Dictionary):
				continue
			var passive: Dictionary = passive_variant
			bonuses.append_array(_extract_passive_bonus_entries(passive, rank))

	return bonuses


func _extract_passive_bonus_entries(passive: Dictionary, rank: int) -> Array:
	var bonuses: Array = []
	var effects: Array = passive.get("effects", [])
	var rank_scaling: Array = passive.get("rank_scaling", [])

	for index: int in range(effects.size()):
		var effect_variant: Variant = effects[index]
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = effect_variant
		var value: float = float(effect.get("value", 0.0))
		for scaling_variant: Variant in rank_scaling:
			if not (scaling_variant is Dictionary):
				continue
			var scaling: Dictionary = scaling_variant
			if int(scaling.get("effect_index", -1)) == index:
				value += floorf(float(rank) / 5.0) * float(scaling.get("per_5_ranks", 0.0))

		var effect_type: String = _normalize_key(str(effect.get("type", "")))
		var value_type: String = _normalize_key(str(effect.get("value_type", "percent")))
		var target: String = _normalize_target_key(str(effect.get("target", "team")))
		if target == "team":
			target = "all"
		match effect_type:
			"stat_boost":
				var stat_key: String = _canonicalize_stat_key(str(effect.get("stat", "")))
				if value_type == "percent":
					stat_key = _to_percent_stat_key(stat_key)
				if stat_key == "":
					continue
				bonuses.append({
					"target": target,
					"stat": stat_key,
					"value": value,
				})
			"damage_reduction", "cooldown_reduction":
				bonuses.append({
					"target": target,
					"stat": effect_type,
					"value": value,
				})

	return bonuses


func _aggregate_passive_effects(aggregate: Dictionary, passive: Dictionary, rank: int) -> void:
	var effects: Array = passive.get("effects", [])
	var rank_scaling: Array = passive.get("rank_scaling", [])

	for index: int in range(effects.size()):
		var effect_variant: Variant = effects[index]
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = effect_variant
		var value: float = float(effect.get("value", 0.0))
		for scaling_variant: Variant in rank_scaling:
			if not (scaling_variant is Dictionary):
				continue
			var scaling: Dictionary = scaling_variant
			if int(scaling.get("effect_index", -1)) == index:
				value += floorf(float(rank) / 5.0) * float(scaling.get("per_5_ranks", 0.0))

		var key: String = "%s|%s|%s|%s" % [
			_normalize_key(str(effect.get("type", ""))),
			_normalize_key(str(effect.get("stat", ""))),
			_normalize_key(str(effect.get("value_type", "percent"))),
			_normalize_key(str(effect.get("target", "team"))),
		]
		aggregate[key] = float(aggregate.get(key, 0.0)) + value


func _format_passive_aggregate_lines(aggregate: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var keys: Array = aggregate.keys()
	keys.sort()

	for key_variant: Variant in keys:
		var key: String = str(key_variant)
		var parts: PackedStringArray = key.split("|")
		if parts.size() != 4:
			continue
		var line: String = _format_passive_effect(
			parts[0],
			parts[1],
			float(aggregate.get(key, 0.0)),
			parts[2],
			parts[3]
		)
		if line != "":
			lines.append(line)
	return lines


func _is_combat_bonus_stat(stat: String) -> bool:
	return _canonicalize_stat_key(stat) in [
		"atk",
		"atk_percent",
		"defense",
		"def_percent",
		"speed",
		"max_hp",
		"max_hp_percent",
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


func _format_aggregate_lines(bonuses: Array) -> Array[String]:
	var aggregate: Dictionary = _aggregate_bonuses(bonuses)
	var lines: Array[String] = []
	var stat_keys: Array = aggregate.keys()
	stat_keys.sort()

	for stat_variant: Variant in stat_keys:
		var stat: String = str(stat_variant)
		var target_map: Dictionary = aggregate.get(stat, {})
		var target_keys: Array = target_map.keys()
		target_keys.sort()
		for target_variant: Variant in target_keys:
			var target: String = str(target_variant)
			var value: float = float(target_map.get(target, 0.0))
			if absf(value) < 0.0001:
				continue
			lines.append(_format_bonus_line(stat, target, value))
	return lines


func _aggregate_bonuses(bonuses: Array) -> Dictionary:
	var result: Dictionary = {}
	for bonus_variant: Variant in bonuses:
		if not (bonus_variant is Dictionary):
			continue
		var bonus: Dictionary = bonus_variant
		var stat: String = _canonicalize_stat_key(str(bonus.get("stat", bonus.get("statType", ""))))
		var target: String = _normalize_target_key(str(bonus.get("target", bonus.get("targetElementType", "all"))))
		var value: float = float(bonus.get("value", 0.0))
		if stat == "":
			continue
		if target == "":
			target = "all"
		if not result.has(stat):
			result[stat] = {}
		var target_map: Dictionary = result[stat]
		target_map[target] = float(target_map.get(target, 0.0)) + value
		result[stat] = target_map
	return result


func _format_bonus_line(stat: String, target: String, value: float) -> String:
	var normalized_stat: String = _canonicalize_stat_key(stat)
	var normalized_target: String = _normalize_target_key(target)
	var label: String = _stat_label(normalized_stat)
	var value_text: String = _format_stat_value(normalized_stat, value)
	if normalized_target == "all" or normalized_target == "":
		return "%s %s" % [label, value_text]
	return "%s %s（%s）" % [label, value_text, _target_label(normalized_target)]


func _format_passive_effect(effect_type: String, stat: String, value: float, value_type: String, target: String) -> String:
	var suffix: String = ""
	var normalized_target: String = _normalize_key(target)
	if normalized_target == "self":
		suffix = UiText.STATS_SUFFIX_SELF
	elif normalized_target != "" and normalized_target != "team":
		suffix = "（%s）" % _target_label(normalized_target)

	match _normalize_key(effect_type):
		"stat_boost":
			if _normalize_key(value_type) == "percent":
				return "%s %+.0f%%%s" % [_passive_stat_label(_canonicalize_stat_key(stat)), value * 100.0, suffix]
			return "%s %+d%s" % [_passive_stat_label(_canonicalize_stat_key(stat)), int(value), suffix]
		"damage_reduction":
			return UiText.STATS_DAMAGE_REDUCTION_FORMAT % [value * 100.0, suffix]
		"cooldown_reduction":
			return UiText.STATS_COOLDOWN_REDUCTION_FORMAT % [value * 100.0, suffix]
		_:
			return ""


func _normalize_key(raw_value: String) -> String:
	var raw: String = raw_value.strip_edges()
	if raw == "":
		return ""
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


func _canonicalize_stat_key(raw_stat: String) -> String:
	match _normalize_key(raw_stat):
		"hp_percent", "max_hp_percent":
			return "max_hp_percent"
		"hp", "max_hp":
			return "max_hp"
		"def", "defense":
			return "defense"
		"def_percent", "defense_percent":
			return "def_percent"
		"atk_percent", "attack_percent":
			return "atk_percent"
		"atk", "attack":
			return "atk"
		_:
			return _normalize_key(raw_stat)


func _normalize_target_key(raw_target: String) -> String:
	match _normalize_key(raw_target):
		"", "all":
			return "all"
		_:
			return _normalize_key(raw_target)


func _normalize_bonus_array(bonuses: Array) -> Array:
	var normalized: Array = []
	for bonus_variant: Variant in bonuses:
		if not (bonus_variant is Dictionary):
			continue
		var bonus: Dictionary = bonus_variant
		var stat: String = _canonicalize_stat_key(str(bonus.get("stat", bonus.get("statType", ""))))
		if stat == "":
			continue
		normalized.append({
			"target": _normalize_target_key(str(bonus.get("target", bonus.get("targetElementType", "all")))),
			"stat": stat,
			"value": float(bonus.get("value", 0.0)),
		})
	return normalized


func _get_live_scooper_entries(property_name: String) -> Array:
	var entries_variant: Variant = _game_state.get(property_name)
	return entries_variant if entries_variant is Array else []


func _to_percent_stat_key(stat: String) -> String:
	match _canonicalize_stat_key(stat):
		"atk":
			return "atk_percent"
		"defense":
			return "def_percent"
		"max_hp":
			return "max_hp_percent"
		_:
			return _canonicalize_stat_key(stat)


func _stat_label(stat: String) -> String:
	match stat:
		"atk":
			return "固定攻擊"
		"atk_percent":
			return "攻擊加成"
		"defense":
			return "固定防禦"
		"def_percent":
			return "防禦加成"
		"max_hp":
			return "固定生命"
		"max_hp_percent":
			return "生命加成"
		"speed":
			return "固定速度"
		"crit_rate":
			return UiText.STATS_STAT_CRIT_RATE
		"crit_damage":
			return UiText.STATS_STAT_CRIT_DMG
		"damage_reduction":
			return UiText.STATS_STAT_DMG_REDUCTION
		"cooldown_reduction":
			return UiText.STATS_STAT_COOLDOWN
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
		"idle_poop_percent":
			return UiText.STATS_STAT_POOP
		"dungeon_damage_boost":
			return "副本增傷"
		"dungeon_damage_reduction":
			return "副本減傷"
		"life_steal":
			return "吸血比率"
		"counter_damage_chance":
			return "反傷機率"
		"physical_damage_boost":
			return "物理增傷"
		"physical_damage_reduction":
			return "物理減傷"
		_:
			return stat


func _passive_stat_label(stat: String) -> String:
	match stat:
		"atk":
			return "固定攻擊"
		"defense":
			return "固定防禦"
		"max_hp":
			return "固定生命"
		"speed":
			return "固定速度"
		_:
			return _stat_label(stat)


func _target_label(target: String) -> String:
	match target:
		"all":
			return UiText.STATS_TARGET_ALL
		"team":
			return UiText.STATS_TARGET_TEAM
		"self":
			return UiText.STATS_TARGET_SELF
		"tank":
			return UiText.STATS_TARGET_TANK
		"speed":
			return UiText.STATS_STAT_SPEED
		"assassin":
			return UiText.STATS_TARGET_ASSASSIN
		"defensive":
			return UiText.STATS_TARGET_DEFENSIVE
		_:
			return target


func _format_stat_value(stat: String, value: float) -> String:
	if stat in [
		"atk_percent",
		"def_percent",
		"max_hp_percent",
		"crit_rate",
		"crit_damage",
		"damage_reduction",
		"cooldown_reduction",
		"armor_pen",
		"evasion",
		"accuracy",
		"multi_hit_rate",
		"multi_hit_damage",
		"idle_poop_percent",
		"dungeon_damage_boost",
		"dungeon_damage_reduction",
		"life_steal",
		"counter_damage_chance",
		"physical_damage_boost",
		"physical_damage_reduction",
	]:
		return "%+.0f%%" % (value * 100.0)
	return "%+d" % int(value)


func _make_lines_card(title: String, lines: Array[String], accent: Color) -> Control:
	var detail_lines: Array[String] = lines.duplicate()
	if detail_lines.is_empty():
		detail_lines.append(UiText.STATS_SECTION_EMPTY)
	return _make_item_card(title, "", "", detail_lines, accent, null)


func _make_empty_card(title: String, detail: String) -> Control:
	return _make_item_card(title, "", "", [detail], Color(0.42, 0.42, 0.46, 0.92), null)


func _make_item_card(title: String, status: String, description: String, detail_lines: Array[String], accent: Color, icon: Texture2D) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(accent)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	if icon != null:
		row.add_child(AssetResolver.create_icon_rect(icon, Vector2(72.0, 72.0)))

	var body: VBoxContainer = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	row.add_child(body)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	body.add_child(title_row)

	var title_label: Label = Label.new()
	title_label.text = title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	title_row.add_child(title_label)

	if status != "":
		var status_label: Label = Label.new()
		status_label.text = status
		status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		status_label.add_theme_color_override("font_color", accent.lightened(0.25))
		title_row.add_child(status_label)

	if description != "":
		var desc_label: Label = Label.new()
		desc_label.text = description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		desc_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		body.add_child(desc_label)

	for line: String in detail_lines:
		var detail_label: Label = Label.new()
		detail_label.text = line
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		body.add_child(detail_label)

	return panel


func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()
