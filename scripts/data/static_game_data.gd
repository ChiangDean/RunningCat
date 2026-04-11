class_name StaticGameData

const CATS := {
	"black_cat": {
		"schema_version": 1,
		"id": "black_cat",
		"display_name": "\u9ed1\u8c93",
		"cat_type": "assassin",
		"rarity": "common",
		"gacha_available": true,
		"base_stats": {"max_hp": 500, "atk": 200, "defense": 15, "speed": 140.0, "weight": 90.0},
		"enhancement_growth": {"hp": 0.5, "atk": 2.0, "def": 0.5},
		"rank_growth": {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0},
		"passive_skills": ["black_night"],
		"active_skills": [{"id": "black_ambush", "initial_delay": 0, "cooldown": 5.0}],
	},
	"calico_cat": {
		"schema_version": 1,
		"id": "calico_cat",
		"display_name": "\u4e09\u82b1\u8c93",
		"cat_type": "speed",
		"rarity": "common",
		"gacha_available": true,
		"base_stats": {"max_hp": 600, "atk": 100, "defense": 20, "speed": 150.0, "weight": 100.0},
		"enhancement_growth": {"hp": 1.0, "atk": 1.5, "def": 0.5},
		"rank_growth": {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0},
		"passive_skills": ["calico_luck"],
		"active_skills": [{"id": "calico_dash", "initial_delay": 0, "cooldown": 4.0}],
	},
	"milk_cat": {
		"schema_version": 1,
		"id": "milk_cat",
		"display_name": "\u725b\u5976\u8c93",
		"cat_type": "tank",
		"base_stats": {"max_hp": 1000, "atk": 150, "defense": 50, "speed": 80.0, "weight": 200.0},
		"rarity": "fine",
		"gacha_available": false,
		"enhancement_growth": {"hp": 2.0, "atk": 0.5, "def": 1.5},
		"rank_growth": {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0},
		"passive_skills": ["milk_thick_body"],
		"active_skills": [{"id": "milk_shield", "initial_delay": 0, "cooldown": 5.0}],
	},
	"ninja_cat": {
		"schema_version": 1,
		"id": "ninja_cat",
		"display_name": "\u5fcd\u8005\u8c93",
		"cat_type": "assassin",
		"rarity": "fine",
		"gacha_available": true,
		"base_stats": {"max_hp": 700, "atk": 250, "defense": 25, "speed": 160.0, "weight": 110.0},
		"enhancement_growth": {"hp": 1.0, "atk": 2.5, "def": 0.5},
		"rank_growth": {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0},
		"passive_skills": ["ninja_instinct"],
		"active_skills": [{"id": "ninja_shadow", "initial_delay": 0, "cooldown": 4.5}],
	},
	"orange_cat": {
		"schema_version": 1,
		"id": "orange_cat",
		"display_name": "\u5927\u6a58\u8c93",
		"cat_type": "tank",
		"rarity": "uncommon",
		"gacha_available": true,
		"base_stats": {"max_hp": 1200, "atk": 130, "defense": 60, "speed": 70.0, "weight": 220.0},
		"enhancement_growth": {"hp": 2.5, "atk": 0.5, "def": 1.5},
		"rank_growth": {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0},
		"passive_skills": ["orange_aura"],
		"active_skills": [{"id": "orange_charge", "initial_delay": 0, "cooldown": 5.5}],
	},
	"test_enemy": {
		"schema_version": 1,
		"id": "test_enemy",
		"display_name": "\u7070\u8c93",
		"cat_type": "base",
		"base_stats": {"max_hp": 800, "atk": 120, "defense": 30, "speed": 90.0, "weight": 150.0},
		"rarity": "common",
		"gacha_available": false,
		"enhancement_growth": {"hp": 1.5, "atk": 1.0, "def": 0.5},
		"rank_growth": {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0},
		"passive_skills": [],
		"active_skills": [{"id": "scratch", "initial_delay": 5, "cooldown": 6.0}],
	},
	"tuxedo_cat": {
		"schema_version": 1,
		"id": "tuxedo_cat",
		"display_name": "\u8cd3\u58eb\u8c93",
		"cat_type": "defensive",
		"rarity": "uncommon",
		"gacha_available": true,
		"base_stats": {"max_hp": 800, "atk": 80, "defense": 120, "speed": 85.0, "weight": 180.0},
		"enhancement_growth": {"hp": 1.5, "atk": 0.5, "def": 2.0},
		"rank_growth": {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0},
		"passive_skills": ["tuxedo_elite"],
		"active_skills": [{"id": "tuxedo_counter", "initial_delay": 0, "cooldown": 8.0}],
	},
}

const PASSIVE_SKILLS := {
	"black_night": {
		"id": "black_night",
		"display_name": "\u591c\u884c\u8005",
		"description": "\u81ea\u8eab\u901f\u5ea6 +10%",
		"skill_type": "passive",
		"effects": [{"type": "stat_boost", "stat": "speed", "value": 0.1, "value_type": "percent", "target": "self"}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.01}],
	},
	"calico_luck": {
		"id": "calico_luck",
		"display_name": "\u5e78\u904b\u82b1\u7d0b",
		"description": "\u6211\u65b9\u5168\u9ad4\u51b7\u537b\u6642\u9593 -8%",
		"skill_type": "passive",
		"effects": [{"type": "cooldown_reduction", "value": 0.08, "target": "team"}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.01}],
	},
	"milk_thick_body": {
		"id": "milk_thick_body",
		"display_name": "\u539a\u5be6\u9ad4\u614b",
		"description": "\u81ea\u8eab\u53d7\u5230\u7684\u50b7\u5bb3 -8%",
		"skill_type": "passive",
		"effects": [{"type": "damage_reduction", "value": 0.08, "target": "self"}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.01}],
	},
	"ninja_instinct": {
		"id": "ninja_instinct",
		"display_name": "\u6697\u6bba\u672c\u80fd",
		"description": "\u81ea\u8eab\u653b\u64ca\u529b +12%",
		"skill_type": "passive",
		"effects": [{"type": "stat_boost", "stat": "atk", "value": 0.12, "value_type": "percent", "target": "self"}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.02}],
	},
	"orange_aura": {
		"id": "orange_aura",
		"display_name": "\u5927\u6a58\u5a01\u58d3",
		"description": "\u6211\u65b9\u5168\u9ad4\u6700\u5927 HP +6%",
		"skill_type": "passive",
		"effects": [{"type": "stat_boost", "stat": "max_hp", "value": 0.06, "value_type": "percent", "target": "team"}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.01}],
	},
	"tuxedo_elite": {
		"id": "tuxedo_elite",
		"display_name": "\u7cbe\u82f1\u6c23\u5834",
		"description": "\u6211\u65b9\u5168\u9ad4\u653b\u64ca\u529b +5%",
		"skill_type": "passive",
		"effects": [{"type": "stat_boost", "stat": "atk", "value": 0.05, "value_type": "percent", "target": "team"}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.01}],
	},
}

const ACTIVE_SKILLS := {
	"black_ambush": {
		"id": "black_ambush",
		"display_name": "\u9ed1\u6697\u7a81\u8972",
		"description": "\u4ee5 150% \u653b\u64ca\u529b\u653b\u64ca\u8840\u91cf\u6700\u4f4e\u7684\u6575\u4eba",
		"skill_type": "active",
		"cooldown": 5.0,
		"effects": [{"type": "damage", "value": 1.5, "target": "enemy_lowest_hp"}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.1}],
	},
	"calico_dash": {
		"id": "calico_dash",
		"display_name": "\u5e78\u904b\u885d\u523a",
		"description": "\u4ee5 100% \u653b\u64ca\u529b\u653b\u64ca\u6700\u524d\u65b9\u6575\u4eba\uff0c\u63d0\u5347\u81ea\u8eab\u901f\u5ea6 25%\uff0c\u6301\u7e8c 3 \u79d2",
		"skill_type": "active",
		"cooldown": 4.0,
		"effects": [
			{"type": "damage", "value": 1.0, "target": "enemy_front"},
			{"type": "buff_stat", "stat": "speed", "value": 0.25, "value_type": "percent", "target": "self", "duration": 3.0},
		],
		"rank_scaling": [
			{"effect_index": 0, "property": "value", "per_5_ranks": 0.05},
			{"effect_index": 1, "property": "value", "per_5_ranks": 0.03},
		],
	},
	"milk_shield": {
		"id": "milk_shield",
		"display_name": "\u725b\u5976\u8b77\u76fe",
		"description": "\u63d0\u5347\u81ea\u8eab\u9632\u79a6\u529b 30%\uff0c\u6301\u7e8c 4 \u79d2",
		"skill_type": "active",
		"cooldown": 5.0,
		"effects": [{"type": "buff_stat", "stat": "defense", "value": 0.3, "value_type": "percent", "target": "self", "duration": 4.0}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.05}],
	},
	"ninja_shadow": {
		"id": "ninja_shadow",
		"display_name": "\u5f71\u5206\u8eab\u65ac",
		"description": "\u4ee5 75% \u653b\u64ca\u529b\u653b\u64ca\u8840\u91cf\u6700\u4f4e\u7684\u6575\u4eba\uff0c\u9023\u64ca 2 \u6b21",
		"skill_type": "active",
		"cooldown": 4.5,
		"effects": [{"type": "damage", "value": 0.75, "target": "enemy_lowest_hp", "hits": 2}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.05}],
	},
	"orange_charge": {
		"id": "orange_charge",
		"display_name": "\u6a6b\u885d\u76f4\u649e",
		"description": "\u4ee5 130% \u653b\u64ca\u529b\u653b\u64ca\u6700\u524d\u65b9\u6575\u4eba\uff0c\u4e26\u5c07\u5176\u984d\u5916\u64ca\u9000",
		"skill_type": "active",
		"cooldown": 5.5,
		"effects": [{"type": "damage", "value": 1.3, "target": "enemy_front", "extra_knockback": 50.0}],
		"rank_scaling": [{"effect_index": 0, "property": "value", "per_5_ranks": 0.1}],
	},
	"tuxedo_counter": {
		"id": "tuxedo_counter",
		"display_name": "\u53cd\u64ca\u59ff\u614b",
		"description": "\u63d0\u5347\u81ea\u8eab\u9632\u79a6\u529b 20%\uff0c\u6301\u7e8c 6 \u79d2\uff1b\u671f\u9593\u53d7\u64ca\u53cd\u5f48 15% \u50b7\u5bb3",
		"skill_type": "active",
		"cooldown": 8.0,
		"effects": [
			{"type": "buff_stat", "stat": "defense", "value": 0.2, "value_type": "percent", "target": "self", "duration": 6.0},
			{"type": "reflect", "value": 0.15, "target": "self", "duration": 6.0},
		],
		"rank_scaling": [{"effect_index": 1, "property": "value", "per_5_ranks": 0.02}],
	},
}

const CONFIGS := {
	"boss": {
		"max_team_size": 5,
		"encounters_per_boss_stage": 4,
		"boss_stages_per_zone": 10,
		"zones_per_territory": 5,
		"stage_growth": 1.003,
		"boss_growth": 1.02,
		"territory_names": ["", "\u65b0\u624b", "\u666e\u901a", "\u9ad8\u7d1a", "\u9032\u968e", "\u83c1\u82f1"],
		"zone_suffixes": ["", "I", "II", "III", "IV", "V"],
	},
	"dungeon": {
		"daily_free_tickets": 2,
		"ad_tickets_per_type": 2,
		"event_bonus_tickets": 0,
		"reset_timezone_offset_hours": 8,
		"max_team_size": 5,
		"dungeons": [
			{"id": "cat_food", "name": "\u4e7e\u7ce7\u5730\u57ce", "enabled": true, "is_limited_event": false, "base_hp": 100, "base_atk": 15, "base_def": 5, "difficulty_multiplier": 1.03, "rewards": {"cat_food_per_level": 5, "special_cat_food_per_level": 1, "diamonds_per_level": 0, "trap_cage_divisor": 0, "whisker_shard_divisor": 0}},
			{"id": "diamond", "name": "\u947d\u77f3\u5730\u57ce", "enabled": true, "is_limited_event": false, "base_hp": 120, "base_atk": 18, "base_def": 6, "difficulty_multiplier": 1.03, "rewards": {"cat_food_per_level": 0, "special_cat_food_per_level": 0, "diamonds_per_level": 2, "trap_cage_divisor": 5, "whisker_shard_divisor": 0}},
			{"id": "whisker", "name": "\u9b0d\u9b1a\u5730\u57ce", "enabled": true, "is_limited_event": false, "base_hp": 110, "base_atk": 16, "base_def": 5, "difficulty_multiplier": 1.03, "rewards": {"cat_food_per_level": 0, "special_cat_food_per_level": 0, "diamonds_per_level": 2, "trap_cage_divisor": 0, "whisker_shard_divisor": 10}},
		],
	},
	"arena": {
		"max_team_size": 5,
		"season_end_date": "2026-04-30",
		"ticket_purchase_costs": [60, 120, 240, 480, 960],
		"daily_free_tickets": 10,
		"max_daily_purchases": 5,
		"tickets_per_purchase": 3,
	},
	"idle": {
		"schema_version": 1,
		"max_idle_hours": 8,
		"base_gold_per_hour": 1000,
		"base_poop_per_hour": 5,
		"base_cat_food_per_hour": 5,
		"base_diamonds_per_hour": 10,
		"base_whiskers_per_hour": 1,
		"stage_bonus_interval": 50,
		"stage_gold_bonus_per_interval": 100,
		"stage_poop_bonus_per_interval": 2,
		"stage_cat_food_bonus_per_interval": 2,
		"stage_diamonds_bonus_per_interval": 2,
		"whisker_stage_bonus_interval": 150,
		"whisker_stage_bonus_per_interval": 1,
		"scooper_gold_per_level_per_hour": 1000,
		"scooper_poop_per_level_per_hour": 5,
		"scooper_cat_food_per_level_per_hour": 5,
		"scooper_diamonds_per_level_per_hour": 10,
		"scoop_exp_chance": 1.0,
		"scoop_exp_amount": 1,
		"scoop_memory_shard_base_chance": 0.0001,
		"scoop_whisker_base_chance": 0.0002,
		"scoop_whisker_chance_per_scooper_level": 0.0001,
		"scoop_memory_shard_chance_per_two_scooper_levels": 0.0001,
		"scooper_exp_per_level": 10,
	},
}


static func get_cat(cat_id: String) -> Dictionary:
	return _deep_copy(CATS.get(cat_id, {}))


static func get_skill(skill_id: String) -> Dictionary:
	if PASSIVE_SKILLS.has(skill_id):
		return _deep_copy(PASSIVE_SKILLS[skill_id])
	if ACTIVE_SKILLS.has(skill_id):
		return _deep_copy(ACTIVE_SKILLS[skill_id])
	return {}


static func get_passive_skill(skill_id: String) -> Dictionary:
	return _deep_copy(PASSIVE_SKILLS.get(skill_id, {}))


static func get_active_skill(skill_id: String) -> Dictionary:
	return _deep_copy(ACTIVE_SKILLS.get(skill_id, {}))


static func get_all_passive_skills() -> Dictionary:
	return _deep_copy(PASSIVE_SKILLS)


static func get_all_active_skills() -> Dictionary:
	return _deep_copy(ACTIVE_SKILLS)


static func get_config(config_name: String) -> Dictionary:
	return _deep_copy(CONFIGS.get(config_name, {}))


static func resolve_cat_id_from_path(path: String) -> String:
	return path.get_file().get_basename()


static func resolve_skill_id_from_path(path: String) -> String:
	return path.get_file().get_basename()


static func _deep_copy(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
