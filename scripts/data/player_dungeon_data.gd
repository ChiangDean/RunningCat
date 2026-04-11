class_name PlayerDungeonData
extends Resource

# Legacy path kept only so GameState can clean up older files.
const SAVE_PATH: String = "res://data/saves/player_dungeons.json"

var dungeons: Dictionary = {}
var last_reset_date: String = ""


func check_daily_reset(daily_free: int) -> void:
	var today := _today_utc8()
	if last_reset_date == today:
		return
	last_reset_date = today
	for key: String in dungeons:
		dungeons[key]["tickets"] = daily_free
		dungeons[key]["ad_views_used"] = 0


static func _today_utc8() -> String:
	var unix_time: float = Time.get_unix_time_from_system()
	var adjusted: int = int(unix_time) + 8 * 3600
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(adjusted)
	return "%04d-%02d-%02d" % [dict["year"], dict["month"], dict["day"]]


func get_dungeon(dungeon_id: String, daily_free: int = 2) -> Dictionary:
	if not dungeons.has(dungeon_id):
		dungeons[dungeon_id] = {
			"max_level": 0,
			"tickets": daily_free,
			"ad_views_used": 0,
		}
	return dungeons[dungeon_id]


func get_tickets(dungeon_id: String, daily_free: int) -> int:
	return get_dungeon(dungeon_id, daily_free).get("tickets", daily_free)


func get_ad_views_remaining(dungeon_id: String, ad_per_type: int) -> int:
	var d: Dictionary = get_dungeon(dungeon_id)
	return maxi(0, ad_per_type - d.get("ad_views_used", 0))


func consume_ticket(dungeon_id: String, daily_free: int) -> bool:
	var d: Dictionary = get_dungeon(dungeon_id, daily_free)
	if d.get("tickets", 0) <= 0:
		return false
	d["tickets"] = d["tickets"] - 1
	return true


func grant_ad_ticket(dungeon_id: String, ad_per_type: int, daily_free: int) -> bool:
	if get_ad_views_remaining(dungeon_id, ad_per_type) <= 0:
		return false
	var d: Dictionary = get_dungeon(dungeon_id, daily_free)
	d["ad_views_used"] = d.get("ad_views_used", 0) + 1
	d["tickets"] = d.get("tickets", 0) + 1
	return true


static func calculate_rewards(dungeon_cfg: Dictionary, level: int) -> Dictionary:
	var r: Dictionary = dungeon_cfg.get("rewards", {})
	var rewards: Dictionary = {}

	var cat_food: int = int(r.get("cat_food_per_level", 0)) * level
	if cat_food > 0:
		rewards["cat_food"] = cat_food

	var special_food: int = int(r.get("special_cat_food_per_level", 0)) * level
	if special_food > 0:
		rewards["special_cat_food"] = special_food

	var diamonds: int = int(r.get("diamonds_per_level", 0)) * level
	if diamonds > 0:
		rewards["diamonds"] = diamonds

	var cage_div: int = int(r.get("trap_cage_divisor", 0))
	if cage_div > 0:
		rewards["trap_cages"] = roundi(float(level) / float(cage_div) + 0.5)

	var shard_div: int = int(r.get("whisker_shard_divisor", 0))
	if shard_div > 0:
		rewards["whisker_shards"] = roundi(float(level) / float(shard_div) + 0.5)

	return rewards


static func apply_rewards(pd: PlayerData, rewards: Dictionary) -> void:
	pd.cat_food += rewards.get("cat_food", 0)
	pd.special_cat_food += rewards.get("special_cat_food", 0)
	pd.diamonds += rewards.get("diamonds", 0)
	pd.trap_cages += rewards.get("trap_cages", 0)
	pd.whisker_shards += rewards.get("whisker_shards", 0)


func update_max_level(dungeon_id: String, level: int) -> void:
	var d: Dictionary = get_dungeon(dungeon_id)
	if level > d.get("max_level", 0):
		d["max_level"] = level


static func load_or_default() -> PlayerDungeonData:
	return PlayerDungeonData.new()


static func _from_dict(data: Dictionary) -> PlayerDungeonData:
	var pd := PlayerDungeonData.new()
	pd.last_reset_date = data.get("last_reset_date", "")
	var saved: Dictionary = data.get("dungeons", {})
	for key: String in saved:
		var entry: Dictionary = saved[key]
		pd.dungeons[key] = {
			"max_level": entry.get("max_level", 0),
			"tickets": entry.get("tickets", 2),
			"ad_views_used": entry.get("ad_views_used", 0),
		}
	return pd


func save() -> void:
	return


func _to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"last_reset_date": last_reset_date,
		"dungeons": dungeons,
	}
