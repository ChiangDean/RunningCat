class_name CatData
extends Resource

const StaticGameData = preload("res://scripts/data/static_game_data.gd")

var id: String = ""
var display_name: String = ""
var cat_type: String = "base"
var max_hp: int = 100
var atk: int = 10
var defense: int = 0
var speed: float = 100.0
var weight: float = 100.0
var rarity: String = "common"
var gacha_available: bool = false
var enhancement_growth: Dictionary = {"hp": 1.5, "atk": 1.0, "def": 0.5}
var rank_growth: Dictionary = {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0}
var rank: int = 0
var passive_skill_ids: Array = []
var active_skill_configs: Array = []
var passive_skills_data: Array = []
var active_skills_data: Array = []


static func from_json_file(path: String) -> CatData:
	var cat_id := StaticGameData.resolve_cat_id_from_path(path)
	var raw := StaticGameData.get_cat(cat_id)
	if raw.is_empty():
		push_error("CatData: missing cat data " + cat_id)
		return null

	var migrated: Dictionary = CatDataMigrator.migrate(raw)
	return _from_dict(migrated)


static func _from_dict(data: Dictionary) -> CatData:
	var cat := CatData.new()
	cat.id = data.get("id", "")
	cat.display_name = data.get("display_name", "")
	cat.cat_type = data.get("cat_type", "base")

	var stats: Dictionary = data.get("base_stats", {})
	cat.max_hp = stats.get("max_hp", 100)
	cat.atk = stats.get("atk", 10)
	cat.defense = stats.get("defense", 0)
	cat.speed = stats.get("speed", 100.0)
	cat.weight = stats.get("weight", 100.0)

	cat.rarity = data.get("rarity", "common")
	cat.gacha_available = data.get("gacha_available", false)

	var default_growth: Dictionary = {"hp": 1.5, "atk": 1.0, "def": 0.5}
	var growth: Dictionary = data.get("enhancement_growth", {})
	cat.enhancement_growth = {
		"hp": growth.get("hp", default_growth["hp"]),
		"atk": growth.get("atk", default_growth["atk"]),
		"def": growth.get("def", default_growth["def"]),
	}

	var default_rank_growth: Dictionary = {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0}
	var rg: Dictionary = data.get("rank_growth", {})
	cat.rank_growth = {
		"hp_percent": rg.get("hp_percent", default_rank_growth["hp_percent"]),
		"atk_percent": rg.get("atk_percent", default_rank_growth["atk_percent"]),
		"def_percent": rg.get("def_percent", default_rank_growth["def_percent"]),
	}

	cat.passive_skill_ids = data.get("passive_skills", [])
	cat.active_skill_configs = data.get("active_skills", [])
	cat._load_skill_data()
	return cat


func _load_skill_data() -> void:
	passive_skills_data.clear()
	active_skills_data.clear()

	for sid: String in passive_skill_ids:
		var skill_data := _read_skill_json("res://skills/passive/" + sid + ".json")
		if not skill_data.is_empty():
			passive_skills_data.append(skill_data)

	for cfg: Dictionary in active_skill_configs:
		var sid: String = cfg.get("id", "")
		var skill_data := _read_skill_json("res://skills/active/" + sid + ".json")
		if skill_data.is_empty():
			continue

		skill_data = skill_data.duplicate(true)
		skill_data["initial_delay"] = cfg.get("initial_delay", 0)
		if cfg.has("cooldown"):
			skill_data["cooldown"] = cfg["cooldown"]
		active_skills_data.append(skill_data)


static func _read_skill_json(path: String) -> Dictionary:
	var skill_id := StaticGameData.resolve_skill_id_from_path(path)
	return StaticGameData.get_skill(skill_id)


func apply_enhancement(player_cat: PlayerCatData) -> void:
	var food_levels: int = player_cat.cat_food_level - 1
	var sfp: Dictionary = player_cat.special_food_points

	max_hp += int((food_levels + sfp.get("hp", 0)) * enhancement_growth.get("hp", 0.0))
	atk += int((food_levels + sfp.get("atk", 0)) * enhancement_growth.get("atk", 0.0))
	defense += int((food_levels + sfp.get("def", 0)) * enhancement_growth.get("def", 0.0))


func apply_rank_bonus(player_cat: PlayerCatData) -> void:
	rank = player_cat.rank
	if rank <= 0:
		return

	var rg: Dictionary = rank_growth
	max_hp = int(max_hp * (1.0 + rank * rg.get("hp_percent", 1.0) / 100.0))
	atk = int(atk * (1.0 + rank * rg.get("atk_percent", 1.0) / 100.0))
	defense = int(defense * (1.0 + rank * rg.get("def_percent", 1.0) / 100.0))


static func get_scaled_effect_value(base_value: float, per_5_ranks: float, current_rank: int) -> float:
	return base_value + floorf(current_rank / 5.0) * per_5_ranks
