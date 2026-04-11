class_name ArenaMatchmaking
extends RefCounted

static func get_opponents(_player_score: int, _player_id: String, excluded_ids: Array = []) -> Array:
	var overview: Dictionary = GameState.arena_overview_data
	var opponents: Array = overview.get("opponents", [])
	var result: Array = []
	for opponent_variant: Variant in opponents:
		if not (opponent_variant is Dictionary):
			continue
		var opponent: Dictionary = opponent_variant
		if excluded_ids.has(String(opponent.get("opponentId", ""))):
			continue
		result.append(opponent.duplicate(true))
	return result
