class_name IdleSystem
extends RefCounted

## 掛機系統純邏輯（計算離線產出速率、每分鐘獎勵、鏟屎隨機掉落）
## 所有方法皆為 static，不持有狀態

## 依當前關卡與鏟屎官等級計算每小時產出速率
static func calculate_rates(config: Dictionary, current_stage: int, scooper_level: int) -> Dictionary:
	var stage_tiers: int  = current_stage / int(config.get("stage_bonus_interval",        50))
	var whisker_tiers: int = current_stage / int(config.get("whisker_stage_bonus_interval", 150))

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

## 依完整分鐘數與速率計算獎勵（整數地板除，floor(速率 × 分鐘 / 60)）
## complete_minutes = elapsed_seconds / 60（整數）
static func calculate_rewards(complete_minutes: int, rates: Dictionary) -> Dictionary:
	if complete_minutes <= 0:
		return {"gold": 0, "poop": 0, "cat_food": 0, "diamonds": 0, "whiskers": 0}
	return {
		"gold":     rates.get("gold",     0) * complete_minutes / 60,
		"poop":     rates.get("poop",     0) * complete_minutes / 60,
		"cat_food": rates.get("cat_food", 0) * complete_minutes / 60,
		"diamonds": rates.get("diamonds", 0) * complete_minutes / 60,
		"whiskers": rates.get("whiskers", 0) * complete_minutes / 60,
	}

## 鏟一次屎的隨機掉落，機率依鏟屎官等級動態計算
## 回傳欄位：exp, memory_shards, whiskers（均為 int，0 表示未獲得）
static func scoop_once(config: Dictionary, rng: RandomNumberGenerator, scooper_level: int) -> Dictionary:
	var result := {"exp": 0, "memory_shards": 0, "whiskers": 0}

	if rng.randf() < float(config.get("scoop_exp_chance", 1.0)):
		result["exp"] = int(config.get("scoop_exp_amount", 1))

	var mem_chance: float = (
		float(config.get("scoop_memory_shard_base_chance", 0.0001))
		+ float(config.get("scoop_memory_shard_chance_per_two_scooper_levels", 0.0001))
		  * float(scooper_level / 2)   # 整數除法，每兩級才加一次
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
