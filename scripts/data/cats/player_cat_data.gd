class_name PlayerCatData
extends Resource

## Save model for a player's individual cat (one record per player-cat pair)
## Stores only player-applied changes; default values come from CatData
## Merged with CatData at runtime to compute effective stats

const SAVE_DIR: String = "user://player_cats/"
const LEGACY_SAVE_DIR: String = "res://data/saves/player_cats/"
const MAX_CAT_FOOD_LEVEL: int = 30

# ── Identity ────────────────────────────────────────────
var cat_id: String = ""

# ── Cat-food level ─────────────────────────────────────
## Current level (default 1); each upgrade costs (lv+1)² cat food
## All stats scale by CatData.enhancement_growth per level
var cat_food_level: int = 1

# ── Special-food allocation ────────────────────────────
## Points freely assigned to stats; the Nth point (0-based) costs N+1 special food
## Format: { "hp": int, "atk": int, "def": int }
var special_food_points: Dictionary = {"hp": 0, "atk": 0, "def": 0}

# ── Rank ───────────────────────────────────────────────
## Current rank (0 = unranked); reaching rank N costs N×20 whisker shards
## Each rank: HP/ATK/DEF each +1% (per CatData.rank_growth)
## Every 5 ranks: skill effect +10%
var rank: int = 0

# ── Other upgrades (reserved, no effect yet) ───────────
var cat_can_fed: int = 0      # canned food invested → Weight (future)
var cat_shards: int = 0       # whisker shards held, used for rank upgrades

# ── Skill settings ─────────────────────────────────────
## Format: [{ "skill_id": "shield_bash", "initial_delay": 0 }]
var active_skill_settings: Array = []


# ── Cost helpers (pure functions) ──────────────────────

## Cat-food cost to level up once: cost(lv) = (lv + 1)²
static func cat_food_cost_for_level(current_level: int) -> int:
	return (current_level + 1) * (current_level + 1)

## Total cat-food cost to go from from_level to to_level
static func cat_food_total_cost(from_level: int, to_level: int) -> int:
	var total := 0
	for lv in range(from_level, to_level):
		total += cat_food_cost_for_level(lv)
	return total

## Special-food cost for the next point: total_points_allocated + 1
static func special_food_next_cost(total_points_allocated: int) -> int:
	return total_points_allocated + 1

## Total special food already spent given the current allocation
## Let n = total_points_allocated - 1 (0-based index)
## f(n) = 0+1+2+...+(n+1) = (n+1)(n+2)/2
## Substituting T = n+1: T*(T+1)/2
## Example: 3 points allocated → 1+2+3 = 6 → 3*4/2 = 6
static func special_food_total_spent(total_points_allocated: int) -> int:
	return (total_points_allocated * (total_points_allocated + 1)) >> 1


# ── Query helpers ──────────────────────────────────────

## Whisker shards needed to reach target_rank (single-step cost)
## cost = target_rank × 20
static func rank_upgrade_cost(target_rank: int) -> int:
	return target_rank * 20


func get_total_special_points() -> int:
	return (special_food_points.get("hp", 0)
		+ special_food_points.get("atk", 0)
		+ special_food_points.get("def", 0))


# ── Serialisation ──────────────────────────────────────

## Parse from a Dictionary, automatically handling legacy format migration
static func from_dict(data: Dictionary) -> PlayerCatData:
	var p := PlayerCatData.new()
	p.cat_id = data.get("cat_id", "")

	# Migration: old format used cat_food_fed; new format uses cat_food_level
	if data.has("cat_food_level"):
		p.cat_food_level = data.get("cat_food_level", 1)
	else:
		# Old saves cannot be back-converted; reset to level 1 (materials are lost)
		p.cat_food_level = 1

	var sfp: Dictionary = data.get("special_food_points", {})
	p.special_food_points = {
		"hp":  sfp.get("hp",  0),
		"atk": sfp.get("atk", 0),
		"def": sfp.get("def", 0),
	}
	p.rank        = data.get("rank",        0)
	p.cat_can_fed = data.get("cat_can_fed", 0)
	p.cat_shards  = data.get("cat_shards",  0)
	p.active_skill_settings = data.get("active_skill_settings", [])
	return p


func to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"cat_id": cat_id,
		"cat_food_level": cat_food_level,
		"special_food_points": special_food_points.duplicate(),
		"rank": rank,
		"cat_can_fed": cat_can_fed,
		"cat_shards": cat_shards,
		"active_skill_settings": active_skill_settings,
	}


# ── File IO ────────────────────────────────────────────

static func load_or_default(p_cat_id: String) -> PlayerCatData:
	var path := SAVE_DIR + p_cat_id + ".json"
	var legacy_path := LEGACY_SAVE_DIR + p_cat_id + ".json"
	var load_path := path
	if not FileAccess.file_exists(load_path):
		load_path = legacy_path
	if not FileAccess.file_exists(load_path):
		var p := PlayerCatData.new()
		p.cat_id = p_cat_id
		return p
	var file := FileAccess.open(load_path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		var p := PlayerCatData.new()
		p.cat_id = p_cat_id
		return p
	file.close()
	var player_cat := from_dict(json.get_data())
	if load_path == legacy_path:
		player_cat.save()
	return player_cat


func save() -> void:
	var path := SAVE_DIR + cat_id + ".json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PlayerCatData: " + UiText.PLAYER_CAT_SAVE_FAILED_FORMAT + path)
		return
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
