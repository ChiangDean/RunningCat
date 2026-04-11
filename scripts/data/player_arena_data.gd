class_name PlayerArenaData
extends Resource

const SAVE_PATH: String = "user://player_arena.json"
const DAILY_FREE_TICKETS: int = 10
const MAX_DAILY_PURCHASES: int = 5
const TICKETS_PER_PURCHASE: int = 3

var player_id: String = ""
var player_name: String = ""
var score: int = 0
var tickets: int = DAILY_FREE_TICKETS
var daily_purchase_count: int = 0
var last_reset_date: String = ""
var win_streak: int = 0
var loss_streak: int = 0
var claimed_rank_rewards: Array = []
var season_end_date: String = ""
var defense_snapshot: Dictionary = {}


static func create_new() -> PlayerArenaData:
	var arena_data := PlayerArenaData.new()
	arena_data.player_id = "player_" + str(randi() % 900000 + 100000)
	arena_data.player_name = "\u65b0\u624b\u73a9\u5bb6" + str(randi() % 9000 + 1000)
	arena_data.score = 0
	arena_data.tickets = DAILY_FREE_TICKETS
	arena_data.last_reset_date = _today_utc8()
	return arena_data


func check_daily_reset() -> void:
	var today := _today_utc8()
	if last_reset_date == today:
		return
	last_reset_date = today
	tickets = DAILY_FREE_TICKETS
	daily_purchase_count = 0
	save()


static func _today_utc8() -> String:
	var unix_time: float = Time.get_unix_time_from_system()
	var adjusted: int = int(unix_time) + 8 * 3600
	var time_dict: Dictionary = Time.get_datetime_dict_from_unix_time(adjusted)
	return "%04d-%02d-%02d" % [time_dict["year"], time_dict["month"], time_dict["day"]]


func consume_ticket() -> bool:
	if tickets <= 0:
		return false
	tickets -= 1
	return true


func purchase_tickets(cost: int, player_data: PlayerData) -> bool:
	if daily_purchase_count >= MAX_DAILY_PURCHASES:
		return false
	if player_data.diamonds < cost:
		return false
	player_data.diamonds -= cost
	tickets += TICKETS_PER_PURCHASE
	daily_purchase_count += 1
	return true


func get_next_purchase_cost(cost_table: Array) -> int:
	if daily_purchase_count >= cost_table.size():
		return -1
	return cost_table[daily_purchase_count]


func can_purchase_more() -> bool:
	return daily_purchase_count < MAX_DAILY_PURCHASES


func add_score(delta: int) -> void:
	score = maxi(0, score + delta)


func record_win() -> void:
	win_streak += 1
	loss_streak = 0


func record_loss() -> void:
	loss_streak += 1
	win_streak = 0


func update_defense_snapshot(defense_team: Array, cat_cache: Dictionary) -> void:
	defense_snapshot = {}
	for cat_id: String in defense_team:
		var player_cat: PlayerCatData = cat_cache.get(cat_id)
		if player_cat == null:
			defense_snapshot[cat_id] = {"cat_food_level": 1, "special_food_points": {"hp": 0, "atk": 0, "def": 0}, "rank": 0}
			continue
		defense_snapshot[cat_id] = {
			"cat_food_level": player_cat.cat_food_level,
			"special_food_points": player_cat.special_food_points.duplicate(),
			"rank": player_cat.rank,
		}


func has_claimed_reward(rank_key: String) -> bool:
	return claimed_rank_rewards.has(rank_key)


func claim_reward(rank_key: String) -> void:
	if not has_claimed_reward(rank_key):
		claimed_rank_rewards.append(rank_key)


func check_season_reset() -> bool:
	if season_end_date.is_empty():
		return false
	var today := _today_utc8()
	if today <= season_end_date:
		return false
	_apply_season_reset()
	return true


func _apply_season_reset() -> void:
	var old_score := score
	if old_score >= 1200:
		score = 1200
	elif old_score >= 600:
		score = 600
	elif old_score >= 300:
		score = 300
	else:
		score = 0

	claimed_rank_rewards = claimed_rank_rewards.filter(
		func(key: String) -> bool:
			return ArenaRankSystem.rank_key_to_min_score(key) >= score
	)


func flush_to_leaderboard() -> void:
	return


static func load_leaderboard() -> Dictionary:
	return {}


static func load_or_create() -> PlayerArenaData:
	if not FileAccess.file_exists(SAVE_PATH):
		var fresh := create_new()
		fresh.save()
		return fresh

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("PlayerArenaData: failed to parse arena save")
		var fresh := create_new()
		fresh.save()
		return fresh
	file.close()
	return _from_dict(json.get_data())


static func _from_dict(data: Dictionary) -> PlayerArenaData:
	var arena_data := PlayerArenaData.new()
	arena_data.player_id = data.get("player_id", "")
	arena_data.player_name = data.get("player_name", "")
	arena_data.score = data.get("score", 0)
	arena_data.tickets = data.get("tickets", DAILY_FREE_TICKETS)
	arena_data.daily_purchase_count = data.get("daily_purchase_count", 0)
	arena_data.last_reset_date = data.get("last_reset_date", "")
	arena_data.win_streak = data.get("win_streak", 0)
	arena_data.loss_streak = data.get("loss_streak", 0)
	arena_data.claimed_rank_rewards = data.get("claimed_rank_rewards", [])
	arena_data.season_end_date = data.get("season_end_date", "")
	arena_data.defense_snapshot = data.get("defense_snapshot", {})
	if arena_data.player_id.is_empty():
		arena_data.player_id = "player_" + str(randi() % 900000 + 100000)
	if arena_data.player_name.is_empty():
		arena_data.player_name = "\u65b0\u624b\u73a9\u5bb6" + str(randi() % 9000 + 1000)
	return arena_data


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerArenaData: failed to save arena state " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_to_dict(), "\t"))
	file.close()


func _to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"player_id": player_id,
		"player_name": player_name,
		"score": score,
		"tickets": tickets,
		"daily_purchase_count": daily_purchase_count,
		"last_reset_date": last_reset_date,
		"win_streak": win_streak,
		"loss_streak": loss_streak,
		"claimed_rank_rewards": claimed_rank_rewards,
		"season_end_date": season_end_date,
		"defense_snapshot": defense_snapshot,
	}
