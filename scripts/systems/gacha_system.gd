class_name GachaSystem
extends RefCounted

static func _get_overview() -> Dictionary:
	return GameState.gacha_data


static func get_technique_level() -> int:
	return int(_get_overview().get("techniqueLevel", 1))


static func get_next_level_threshold() -> int:
	return int(_get_overview().get("nextTechniqueLevelRequiredPulls", -1))


static func get_rarity_info(rarity_id: String) -> Dictionary:
	return {"id": rarity_id, "name": rarity_id, "color": "#FFFFFF"}


static func perform_pulls(_count: int) -> Array:
	push_warning("GachaSystem.perform_pulls() is deprecated; use ApiClient.perform_gacha_pull()")
	return []


static func cost_for_count(count: int) -> int:
	var options: Array = _get_overview().get("pullOptions", [])
	for option: Dictionary in options:
		if int(option.get("pullCount", 0)) == count:
			return int(option.get("diamondCost", 0))
	return 0


static func free_pull_cap() -> int:
	return int(_get_overview().get("freePullCount", 1))
