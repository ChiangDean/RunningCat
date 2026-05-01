class_name PlayerData
extends Resource

const SAVE_PATH: String = "user://player_data.json"

var cat_food: int = 0
var special_cat_food: int = 0
var gold: int = 0
var diamonds: int = 0
var trap_points: int = 0
var collision_coin: int = 0
var trap_cages: int = 0
var whisker_shards: int = 0
var account: String = ""
var display_name: String = ""
var player_public_id: String = ""
var player_name: String = ""
var avatar_id: String = "black_cat"
var bio: String = ""
var birthday: String = ""
var gender_type: String = "Unspecified"
var region: String = ""
var linked_providers: Array = []
var password_login_enabled: bool = true

var total_pulls: int = 0
var free_pull_count: int = 1
var last_free_pull_date: String = ""

var current_stage: int = 1

var last_quit_time: int = 0
var poop_count: int = 0
var party_cheer_coupon_count: int = 0
var sofa_score: int = 0
var bath_score: int = 0
var combat_score: int = 0
var combat_trial_version: int = 1

var memory_shards: int = 0
var unlocked_memory_ids: Array = []

var treasures: Dictionary = {}
var bundle_purchase_counts: Dictionary = {}
var achievement_states: Dictionary = {}

var scooper_level: int = 0
var scooper_exp: int = 0
var special_ability_ids: Array = []

var equipments: Dictionary = {}
var owned_cat_ids: Array = ["milk_cat"]

var boss_team: Array = []
var dungeon_team: Array = []
var arena_attack_team: Array = []
var arena_defense_team: Array = []


func has_used_free_pull_today() -> bool:
	return last_free_pull_date == _today_string()


func consume_free_pull(cap: int) -> void:
	last_free_pull_date = _today_string()
	free_pull_count = mini(free_pull_count + 1, cap)


static func _today_string() -> String:
	return Time.get_date_string_from_system()


static func load_or_default() -> PlayerData:
	if not FileAccess.file_exists(SAVE_PATH):
		return PlayerData.new()

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("PlayerData: failed to parse save file")
		return PlayerData.new()

	file.close()
	return _from_dict(json.get_data())


static func _from_dict(data: Dictionary) -> PlayerData:
	var p := PlayerData.new()
	p.account = data.get("account", "")
	p.display_name = data.get("display_name", "")
	p.player_public_id = data.get("player_public_id", "")
	p.player_name = data.get("player_name", "")
	p.avatar_id = data.get("avatar_id", "black_cat")
	p.bio = data.get("bio", "")
	p.birthday = data.get("birthday", "")
	p.gender_type = data.get("gender_type", "Unspecified")
	p.region = data.get("region", "")
	p.linked_providers = data.get("linked_providers", [])
	p.password_login_enabled = bool(data.get("password_login_enabled", true))
	p.cat_food = data.get("cat_food", 0)
	p.special_cat_food = data.get("special_cat_food", 0)
	p.gold = data.get("gold", 0)
	p.diamonds = data.get("diamonds", 0)
	p.trap_points = data.get("trap_points", 0)
	p.collision_coin = data.get("collision_coin", 0)
	p.trap_cages = data.get("trap_cages", 0)
	p.whisker_shards = data.get("whisker_shards", 0)
	p.last_quit_time = data.get("last_quit_time", 0)
	p.poop_count = data.get("poop_count", 0)
	p.party_cheer_coupon_count = data.get("party_cheer_coupon_count", 0)
	p.sofa_score = data.get("sofa_score", 0)
	p.bath_score = data.get("bath_score", 0)
	p.combat_score = data.get("combat_score", 0)
	p.combat_trial_version = data.get("combat_trial_version", 1)
	p.memory_shards = data.get("memory_shards", 0)
	p.unlocked_memory_ids = data.get("unlocked_memory_ids", [])
	p.treasures = data.get("treasures", {})
	p.bundle_purchase_counts = data.get("bundle_purchase_counts", {})
	p.achievement_states = data.get("achievement_states", {})
	p.scooper_level = data.get("scooper_level", 0)
	p.scooper_exp = data.get("scooper_exp", 0)
	p.special_ability_ids = data.get("special_ability_ids", [])
	p.equipments = data.get("equipments", {})
	p.total_pulls = data.get("total_pulls", 0)
	p.free_pull_count = data.get("free_pull_count", 1)
	p.last_free_pull_date = data.get("last_free_pull_date", "")
	p.current_stage = data.get("current_stage", 1)

	var ids: Array = data.get("owned_cat_ids", ["milk_cat"])
	p.owned_cat_ids = ids if not ids.is_empty() else ["milk_cat"]

	p.boss_team = data.get("boss_team", [])
	p.dungeon_team = data.get("dungeon_team", [])
	p.arena_attack_team = data.get("arena_attack_team", [])
	p.arena_defense_team = data.get("arena_defense_team", [])
	return p


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerData: failed to open save file: " + SAVE_PATH)
		return

	file.store_string(JSON.stringify(_to_dict(), "\t"))
	file.close()


func _to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"account": account,
		"display_name": display_name,
		"player_public_id": player_public_id,
		"player_name": player_name,
		"avatar_id": avatar_id,
		"bio": bio,
		"birthday": birthday,
		"gender_type": gender_type,
		"region": region,
		"linked_providers": linked_providers,
		"password_login_enabled": password_login_enabled,
		"cat_food": cat_food,
		"special_cat_food": special_cat_food,
		"gold": gold,
		"diamonds": diamonds,
		"trap_points": trap_points,
		"collision_coin": collision_coin,
		"trap_cages": trap_cages,
		"whisker_shards": whisker_shards,
		"last_quit_time": last_quit_time,
		"poop_count": poop_count,
		"party_cheer_coupon_count": party_cheer_coupon_count,
		"sofa_score": sofa_score,
		"bath_score": bath_score,
		"combat_score": combat_score,
		"combat_trial_version": combat_trial_version,
		"memory_shards": memory_shards,
		"unlocked_memory_ids": unlocked_memory_ids,
		"treasures": treasures,
		"bundle_purchase_counts": bundle_purchase_counts,
		"achievement_states": achievement_states,
		"scooper_level": scooper_level,
		"scooper_exp": scooper_exp,
		"special_ability_ids": special_ability_ids,
		"equipments": equipments,
		"total_pulls": total_pulls,
		"free_pull_count": free_pull_count,
		"last_free_pull_date": last_free_pull_date,
		"current_stage": current_stage,
		"owned_cat_ids": owned_cat_ids,
		"boss_team": boss_team,
		"dungeon_team": dungeon_team,
		"arena_attack_team": arena_attack_team,
		"arena_defense_team": arena_defense_team,
	}
