class_name ArenaMatchmaking
extends RefCounted

## 競技場對手選取邏輯
## 從 arena_data.json（排行榜）篩選鄰近積分的對手，
## 再從 fake_players/ 或 player_data 取得詳細資訊

const FAKE_PLAYERS_DIR: String = "res://data/arena/fake_players/"
const MATCH_COUNT: int = 3          # 每次顯示幾個對手
const SCORE_RANGE_STEP: int = 100   # 每次擴大搜尋範圍的步距（約一個段位）

## 單筆對手資料結構
## { "player_id", "player_name", "score", "rank_name", "defense_team": Array[String] }


# ── 公開 API ──────────────────────────────────────────

## 取得 MATCH_COUNT 個對手
## excluded_ids: 本輪已出現過的 player_id（重骰時傳入，避免重複）
static func get_opponents(player_score: int, player_id: String, excluded_ids: Array = []) -> Array:
	var leaderboard := PlayerArenaData.load_leaderboard()
	# 排除自己
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


# ── 內部：候選篩選 ────────────────────────────────────

static func _find_candidates(leaderboard: Dictionary, player_score: int, excluded_ids: Array) -> Array:
	var range_size := SCORE_RANGE_STEP
	var candidates: Array = []

	# 逐步擴大分數範圍，直到找到足夠候選人（最多擴到全部）
	while candidates.size() < MATCH_COUNT and range_size <= 3000:
		candidates = []
		for pid: String in leaderboard:
			if excluded_ids.has(pid):
				continue
			var s: int = leaderboard[pid].get("score", 0)
			if abs(s - player_score) <= range_size:
				candidates.append({ "player_id": pid, "score": s })
		range_size += SCORE_RANGE_STEP

	# 如果仍不足（全服玩家少），就直接用全部
	if candidates.size() < MATCH_COUNT:
		candidates = []
		for pid: String in leaderboard:
			if excluded_ids.has(pid):
				continue
			candidates.append({ "player_id": pid, "score": leaderboard[pid].get("score", 0) })

	return candidates


# ── 內部：載入玩家詳細資訊 ───────────────────────────

static func _load_player_detail(player_id: String, score: int) -> Dictionary:
	# 假玩家
	if player_id.begins_with("fake_"):
		return _load_fake_player(player_id, score)
	# 未來：真實玩家從伺服器取得，目前佔位
	return {}


static func _load_fake_player(player_id: String, score: int) -> Dictionary:
	var path := FAKE_PLAYERS_DIR + player_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	var data: Dictionary = json.get_data()

	var defense: Array = data.get("defense_team", [])
	return {
		"player_id":        player_id,
		"player_name":      data.get("player_name", player_id),
		"score":            score,
		"rank_name":        ArenaRankSystem.score_to_rank_name(score),
		"defense_team":     defense,
		"defense_snapshot": data.get("defense_snapshot", {}),
	}
