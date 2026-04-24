class_name IdleSystem
extends RefCounted

## Pure idle-system logic (offline yield rates, per-minute rewards, random poop drops)
## All methods are static; no state is held

## Calculate per-hour yield rates from the current stage and scooper level
static func calculate_rates(config: Dictionary, current_stage: int, scooper_level: int) -> Dictionary:
	var stage_interval := float(int(config.get("stage_bonus_interval", 50)))
	var whisker_interval := float(int(config.get("whisker_stage_bonus_interval", 150)))
	var stage_tiers: int = floori(float(current_stage) / stage_interval)
	var whisker_tiers: int = floori(float(current_stage) / whisker_interval)

	return {
		"gold": (int(config.get("base_gold_per_hour", 1000))
				+ stage_tiers   * int(config.get("stage_gold_bonus_per_interval",    100))
				+ scooper_level * int(config.get("scooper_gold_per_level_per_hour", 1000))),
		"poop": (int(config.get("base_poop_per_hour", 5))
				+ stage_tiers   * int(config.get("stage_poop_bonus_per_interval",   2))
				+ scooper_level * int(config.get("scooper_poop_per_level_per_hour", 5))),
		"cat_food": (int(config.get("base_cat_food_per_hour", 5))
				+ stage_tiers   * int(config.get("stage_cat_food_bonus_per_interval",   2))
				+ scooper_level * int(config.get("scooper_cat_food_per_level_per_hour", 5))),
		"diamonds": (int(config.get("base_diamonds_per_hour", 10))
				+ stage_tiers   * int(config.get("stage_diamonds_bonus_per_interval",   2))
				+ scooper_level * int(config.get("scooper_diamonds_per_level_per_hour", 10))),
		"whiskers": (int(config.get("base_whiskers_per_hour", 1))
				+ whisker_tiers * int(config.get("whisker_stage_bonus_per_interval", 1))),
	}

## Calculate rewards from complete elapsed minutes and rates (integer floor: floor(rate × minutes / 60))
## complete_minutes = elapsed_seconds / 60 (integer)
static func calculate_rewards(complete_minutes: int, rates: Dictionary) -> Dictionary:
	if complete_minutes <= 0:
		return {"gold": 0, "poop": 0, "cat_food": 0, "diamonds": 0, "whiskers": 0}
	return {
		"gold": floori(float(rates.get("gold", 0)) * float(complete_minutes) / 60.0),
		"poop": floori(float(rates.get("poop", 0)) * float(complete_minutes) / 60.0),
		"cat_food": floori(float(rates.get("cat_food", 0)) * float(complete_minutes) / 60.0),
		"diamonds": floori(float(rates.get("diamonds", 0)) * float(complete_minutes) / 60.0),
		"whiskers": floori(float(rates.get("whiskers", 0)) * float(complete_minutes) / 60.0),
	}

## Random drops from a single poop scoop; probability scales with scooper level
## Return fields: exp, memory_shards, whiskers (all int; 0 means not obtained)
static func scoop_once(config: Dictionary, rng: RandomNumberGenerator, scooper_level: int) -> Dictionary:
	var result := {"exp": 0, "memory_shards": 0, "whiskers": 0}

	if rng.randf() < float(config.get("scoop_exp_chance", 1.0)):
		result["exp"] = int(config.get("scoop_exp_amount", 1))

	var mem_chance: float = (
		float(config.get("scoop_memory_shard_base_chance", 0.0001))
		+ float(config.get("scoop_memory_shard_chance_per_two_scooper_levels", 0.0001))
		  * floorf(float(scooper_level) / 2.0)   # integer division: one bonus per two levels
	)
	if rng.randf() < mem_chance:
		result["memory_shards"] = 1

	var whisker_chance: float = (
		float(config.get("scoop_whisker_base_chance", 0.0002))
		+ float(config.get("scoop_whisker_chance_per_scooper_level", 0.0001))
		  * float(scooper_level)
	)
	if rng.randf() < whisker_chance:
		result["whiskers"] = 1

	return result
