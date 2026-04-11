class_name ArenaMatchmaking
extends RefCounted

const MATCH_COUNT: int = 3
const SCORE_RANGE_STEP: int = 100


static func get_opponents(player_score: int, player_id: String, excluded_ids: Array = []) -> Array:
	var leaderboard := PlayerArenaData.load_leaderboard()
	leaderboard.erase(player_id)

	var candidates := _find_candidates(leaderboard, player_score, excluded_ids)
	candidates.shuffle()
	candidates = candidates.slice(0, MATCH_COUNT)

	var result: Array = []
	for entry: Dictionary in candidates:
		var detail := _load_player_detail(entry["player_id"], entry["score"])
		if not detail.is_empty():
			result.append(detail)
	return result


static func _find_candidates(leaderboard: Dictionary, player_score: int, excluded_ids: Array) -> Array:
	var range_size := SCORE_RANGE_STEP
	var candidates: Array = []

	while candidates.size() < MATCH_COUNT and range_size <= 3000:
		candidates = []
		for pid: String in leaderboard:
			if excluded_ids.has(pid):
				continue
			var score: int = leaderboard[pid].get("score", 0)
			if abs(score - player_score) <= range_size:
				candidates.append({"player_id": pid, "score": score})
		range_size += SCORE_RANGE_STEP

	if candidates.size() < MATCH_COUNT:
		candidates = []
		for pid: String in leaderboard:
			if excluded_ids.has(pid):
				continue
			candidates.append({"player_id": pid, "score": leaderboard[pid].get("score", 0)})

	return candidates


static func _load_player_detail(player_id: String, score: int) -> Dictionary:
	if player_id.begins_with("fake_"):
		return _load_fake_player(player_id, score)
	return {}


static func _load_fake_player(player_id: String, score: int) -> Dictionary:
	var defense: Array = []
	for item: Variant in GameState.cat_catalog:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		if bool(row.get("gacha_available", false)):
			defense.append(str(row.get("id", "")))
		if defense.size() >= 5:
			break

	if defense.is_empty():
		defense = ["milk_cat"]

	return {
		"player_id": player_id,
		"player_name": player_id.capitalize(),
		"score": score,
		"rank_name": ArenaRankSystem.score_to_rank_name(score),
		"defense_team": defense,
		"defense_snapshot": {},
	}
