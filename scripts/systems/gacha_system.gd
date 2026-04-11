class_name GachaSystem
extends RefCounted

static var _config: Dictionary = {}


static func _get_config() -> Dictionary:
	if not GameState.gacha_config.is_empty():
		_config = GameState.gacha_config
		return _config
	return _config


static func get_technique_level() -> int:
	var config := _get_config()
	var total: int = GameState.player_data.total_pulls
	var levels: Array = config.get("technique_levels", [])
	var current := 1
	for entry: Dictionary in levels:
		if total >= int(entry.get("required_pulls", 0)):
			current = int(entry.get("level", 1))
	return current


static func get_next_level_threshold() -> int:
	var config := _get_config()
	var total: int = GameState.player_data.total_pulls
	var levels: Array = config.get("technique_levels", [])
	for entry: Dictionary in levels:
		var req: int = int(entry.get("required_pulls", 0))
		if total < req:
			return req
	return -1


static func get_rarity_info(rarity_id: String) -> Dictionary:
	var config := _get_config()
	for r: Dictionary in config.get("rarities", []):
		if r.get("id", "") == rarity_id:
			return r
	return {"id": rarity_id, "name": rarity_id, "color": "#FFFFFF"}


static func perform_pulls(count: int) -> Array:
	var config := _get_config()
	var results: Array = []

	var tech_lv := get_technique_level()
	var rates := _get_rates_for_level(tech_lv)
	var pool: Dictionary = config.get("cat_pool", {})

	for _i in range(count):
		var rarity_id := _roll_rarity(rates)
		var cat_ids: Array = pool.get(rarity_id, [])
		if cat_ids.is_empty():
			continue
		var cat_id: String = cat_ids[randi() % cat_ids.size()]
		results.append(_process_single(cat_id, rarity_id, config))

	GameState.player_data.total_pulls += count
	GameState.save_all()
	return results


static func cost_for_count(count: int) -> int:
	var config := _get_config()
	var costs: Dictionary = config.get("pull_costs", {})
	match count:
		1:
			return int(costs.get("single", 100))
		11:
			return int(costs.get("eleven", 1000))
		35:
			return int(costs.get("thirty_five", 3000))
	return count * int(costs.get("single", 100))


static func free_pull_cap() -> int:
	return int(_get_config().get("daily_free_pull_cap", 50))


static func _get_rates_for_level(level: int) -> Dictionary:
	var config := _get_config()
	for entry: Dictionary in config.get("technique_levels", []):
		if int(entry.get("level", 0)) == level:
			return entry.get("rates", {})
	return {"common": 100}


static func _roll_rarity(rates: Dictionary) -> String:
	var order: Array = [
		"legendary", "epic", "rare", "excellent",
		"precious", "special", "fine", "uncommon", "common"
	]
	var roll: float = randf() * 100.0
	var cumulative: float = 0.0
	for rarity_id: String in order:
		cumulative += float(rates.get(rarity_id, 0))
		if roll < cumulative:
			return rarity_id
	return "common"


static func _process_single(cat_id: String, rarity_id: String, config: Dictionary) -> Dictionary:
	var cat_data := CatData.from_json_file(cat_id + ".json")
	var display := cat_data.display_name if cat_data != null else cat_id
	var rarity_info := get_rarity_info(rarity_id)

	var is_new: bool = not GameState.player_data.owned_cat_ids.has(cat_id)
	var shards_given: int = 0
	var trap_given: int = 0

	if is_new:
		GameState.add_owned_cat(cat_id)
	else:
		var player_cat := GameState.get_player_cat(cat_id)
		shards_given = int(config.get("duplicate_shard_reward", 10))
		player_cat.cat_shards += shards_given

	return {
		"cat_id": cat_id,
		"display_name": display,
		"rarity_id": rarity_id,
		"rarity_name": rarity_info.get("name", rarity_id),
		"rarity_color": rarity_info.get("color", "#FFFFFF"),
		"is_new": is_new,
		"shards_given": shards_given,
		"trap_points_given": trap_given,
	}
