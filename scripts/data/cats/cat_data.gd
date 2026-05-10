class_name CatData
extends Resource

var id: String = ""
var display_name: String = ""
var cat_type: String = "base"
var max_hp: int = 100
var atk: int = 10
var defense: int = 0
var speed: float = 100.0
var weight: float = 100.0
var crit_rate: float = 0.0
var crit_damage_bonus: float = 0.0
var evasion: float = 0.0
var accuracy: float = 0.0
var armor_pen: float = 0.0
var multi_hit_rate: float = 0.0
var multi_hit_damage: float = 0.0
var damage_reduction: float = 0.0
var cooldown_reduction: float = 0.0
var counter_damage_chance: float = 0.0
var rarity: String = "common"
var gacha_available: bool = false
var enhancement_growth: Dictionary = {"hp": 1.5, "atk": 1.0, "def": 0.5}
var rank_growth: Dictionary = {
	"hp_percent": 1.0,
	"atk_percent": 1.0,
	"def_percent": 1.0,
	"crit_rate": 0.0,
	"crit_damage": 0.0,
	"evasion": 0.0,
	"accuracy": 0.0,
	"multi_hit_rate": 0.0,
}
var rank: int = 0
var passive_skill_ids: Array = []
var active_skill_configs: Array = []
var passive_skills_data: Array = []
var active_skills_data: Array = []


static func from_json_file(path: String) -> CatData:
	var cat_id := path.get_file().get_basename()
	var raw := GameState.get_cat_catalog_item(cat_id)
	if raw.is_empty():
		raw = GameState.get_enemy_catalog_item(cat_id)
	if raw.is_empty():
		push_error("CatData: missing catalog entry for " + cat_id)
		return null
	return _from_catalog(raw)


static func _from_catalog(data: Dictionary) -> CatData:
	var cat := CatData.new()
	cat.id = str(data.get("id", ""))
	cat.display_name = str(data.get("display_name", ""))
	cat.cat_type = str(data.get("cat_type", "base"))
	cat.max_hp = int(data.get("base_hp", 100))
	cat.atk = int(data.get("base_atk", 10))
	cat.defense = int(data.get("base_def", 0))
	cat.speed = float(data.get("base_speed", 100.0))
	cat.weight = float(data.get("weight", 100.0))
	cat.crit_rate = _read_rate(data, "base_crit_rate")
	cat.crit_damage_bonus = _read_rate(data, "base_crit_damage")
	cat.evasion = _read_rate(data, "base_evasion")
	cat.accuracy = _read_rate(data, "base_accuracy")
	cat.multi_hit_rate = _read_rate(data, "base_multi_hit_rate")
	cat.multi_hit_damage = _read_rate(data, "base_multi_hit_damage")
	cat.rarity = str(data.get("rarity", "common"))
	cat.gacha_available = bool(data.get("gacha_available", false))

	var growth: Dictionary = data.get("enhancement_growth", {})
	cat.enhancement_growth = {
		"hp": float(growth.get("hp", 1.5)),
		"atk": float(growth.get("atk", 1.0)),
		"def": float(growth.get("def", 0.5)),
	}

	var rank_growth_data: Dictionary = data.get("rank_growth", {})
	cat.rank_growth = {
		"hp_percent": float(rank_growth_data.get("hp_percent", 1.0)),
		"atk_percent": float(rank_growth_data.get("atk_percent", 1.0)),
		"def_percent": float(rank_growth_data.get("def_percent", 1.0)),
		"crit_rate": _read_rate(data, "crit_rate_growth"),
		"crit_damage": _read_rate(data, "crit_damage_growth"),
		"evasion": _read_rate(data, "evasion_growth"),
		"accuracy": _read_rate(data, "accuracy_growth"),
		"multi_hit_rate": _read_rate(data, "multi_hit_rate_growth"),
	}

	cat.passive_skill_ids = data.get("passive_skills", [])
	cat.active_skill_configs = data.get("active_skills", [])
	cat._load_skill_data()
	return cat


func _load_skill_data() -> void:
	passive_skills_data.clear()
	active_skills_data.clear()

	for sid: String in passive_skill_ids:
		var skill := _read_skill_json(sid)
		if not skill.is_empty():
			passive_skills_data.append(skill)

	for cfg: Dictionary in active_skill_configs:
		var sid: String = str(cfg.get("skill_id", cfg.get("id", "")))
		var skill := _read_skill_json(sid)
		if skill.is_empty():
			continue
		var active := skill.duplicate(true)
		active["id"] = sid
		active["initial_delay"] = int(cfg.get("initial_delay", 0))
		if cfg.has("cooldown"):
			active["cooldown"] = cfg.get("cooldown", active.get("cooldown", 0))
		active_skills_data.append(active)


static func _read_skill_json(path_or_skill_id: String) -> Dictionary:
	var skill_id := path_or_skill_id
	if skill_id.contains("/"):
		skill_id = skill_id.get_file().get_basename()
	var result := GameState.get_skill_catalog_item(skill_id)
	if result.is_empty():
		push_warning("CatData: missing cached skill catalog for " + skill_id)
	return result


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
	max_hp = int(max_hp * (1.0 + rank * rank_growth.get("hp_percent", 1.0) / 100.0))
	atk = int(atk * (1.0 + rank * rank_growth.get("atk_percent", 1.0) / 100.0))
	defense = int(defense * (1.0 + rank * rank_growth.get("def_percent", 1.0) / 100.0))
	crit_rate += rank * float(rank_growth.get("crit_rate", 0.0))
	crit_damage_bonus += rank * float(rank_growth.get("crit_damage", 0.0))
	evasion += rank * float(rank_growth.get("evasion", 0.0))
	accuracy += rank * float(rank_growth.get("accuracy", 0.0))
	multi_hit_rate += rank * float(rank_growth.get("multi_hit_rate", 0.0))


static func get_scaled_effect_value(base_value: float, per_5_ranks: float, current_rank: int) -> float:
	return base_value + floorf(current_rank / 5.0) * per_5_ranks


static func _read_rate(data: Dictionary, key: String) -> float:
	var value: float = float(data.get(key, 0.0))
	return value / 100.0 if value >= 1.0 else value
