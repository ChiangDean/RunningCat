class_name PlayerArenaData
extends Resource

const ARENA_DATA_PATH: String = "user://arena_data.json"

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
	var d := PlayerArenaData.new()
	d.player_id = "player_" + str(randi() % 900000 + 100000)
	d.player_name = "arena_player_" + str(randi() % 9000 + 1000)
	d.score = 0
	d.tickets = DAILY_FREE_TICKETS
	d.last_reset_date = _today_utc8()
	return d


func check_daily_reset() -> void:
	var today := _today_utc8()
	if last_reset_date == today:
		return
	last_reset_date = today
	tickets = DAILY_FREE_TICKETS
	daily_purchase_count = 0


static func _today_utc8() -> String:
	var unix_time: float = Time.get_unix_time_from_system()
	var adjusted: int = int(unix_time) + 8 * 3600
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(adjusted)
	return "%04d-%02d-%02d" % [dict["year"], dict["month"], dict["day"]]


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
		var pcat: PlayerCatData = cat_cache.get(cat_id)
		if pcat == null:
			defense_snapshot[cat_id] = {
				"cat_food_level": 1,
				"special_food_points": {"hp": 0, "atk": 0, "def": 0},
				"rank": 0,
			}
		else:
			defense_snapshot[cat_id] = {
				"cat_food_level": pcat.cat_food_level,
				"special_food_points": pcat.special_food_points.duplicate(),
				"rank": pcat.rank,
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


static func _load_leaderboard() -> Dictionary:
	return {}


static func _save_leaderboard(data: Dictionary) -> void:
	return


static func load_leaderboard() -> Dictionary:
	return _load_leaderboard()


static func load_or_create() -> PlayerArenaData:
	return PlayerArenaData.new()


static func _from_dict(data: Dictionary) -> PlayerArenaData:
	var d := PlayerArenaData.new()
	d.player_id = data.get("player_id", "")
	d.player_name = data.get("player_name", "")
	d.score = data.get("score", 0)
	d.tickets = data.get("tickets", DAILY_FREE_TICKETS)
	d.daily_purchase_count = data.get("daily_purchase_count", 0)
	d.last_reset_date = data.get("last_reset_date", "")
	d.win_streak = data.get("win_streak", 0)
	d.loss_streak = data.get("loss_streak", 0)
	d.claimed_rank_rewards = data.get("claimed_rank_rewards", [])
	d.season_end_date = data.get("season_end_date", "")
	d.defense_snapshot = data.get("defense_snapshot", {})
	if d.player_id.is_empty():
		d.player_id = "player_" + str(randi() % 900000 + 100000)
	if d.player_name.is_empty():
		d.player_name = "arena_player_" + str(randi() % 9000 + 1000)
	return d


func save() -> void:
	return


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
