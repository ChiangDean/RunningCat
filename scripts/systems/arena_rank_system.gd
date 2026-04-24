class_name ArenaRankSystem
extends RefCounted

## Arena rank / score / season / rank-reward logic
## All methods are static; no instantiation required

# ── Rank definitions ──────────────────────────────────────────
## Minimum score threshold per rank key (Master/Elite also require PR; this only tracks the score cutoff)
const RANK_THRESHOLDS: Dictionary = {
	"bronze_3":   0,
	"bronze_2":   100,
	"bronze_1":   200,
	"silver_3":   300,
	"silver_2":   400,
	"silver_1":   500,
	"gold_3":     600,
	"gold_2":     700,
	"gold_1":     800,
	"platinum_3": 900,
	"platinum_2": 1000,
	"platinum_1": 1100,
	"diamond_3":  1200,
	"diamond_2":  1300,
	"diamond_1":  1400,
	"master_3":   1500,
	"master_2":   1700,
	"master_1":   1900,
	"elite":      2000,
}

## Rank display names
const RANK_NAMES: Dictionary = {
	"bronze_3":   UiText.ARENA_RANK_BRONZE + " III",
	"bronze_2":   UiText.ARENA_RANK_BRONZE + " II",
	"bronze_1":   UiText.ARENA_RANK_BRONZE + " I",
	"silver_3":   UiText.ARENA_RANK_SILVER + " III",
	"silver_2":   UiText.ARENA_RANK_SILVER + " II",
	"silver_1":   UiText.ARENA_RANK_SILVER + " I",
	"gold_3":     UiText.ARENA_RANK_GOLD + " III",
	"gold_2":     UiText.ARENA_RANK_GOLD + " II",
	"gold_1":     UiText.ARENA_RANK_GOLD + " I",
	"platinum_3": UiText.ARENA_RANK_PLATINUM + " III",
	"platinum_2": UiText.ARENA_RANK_PLATINUM + " II",
	"platinum_1": UiText.ARENA_RANK_PLATINUM + " I",
	"diamond_3":  UiText.ARENA_RANK_DIAMOND + " III",
	"diamond_2":  UiText.ARENA_RANK_DIAMOND + " II",
	"diamond_1":  UiText.ARENA_RANK_DIAMOND + " I",
	"master_3":   UiText.ARENA_RANK_MASTER + " III",
	"master_2":   UiText.ARENA_RANK_MASTER + " II",
	"master_1":   UiText.ARENA_RANK_MASTER + " I",
	"elite":      UiText.ARENA_RANK_ELITE,
}

## Rank order (lowest to highest)
const RANK_ORDER: Array = [
	"bronze_3", "bronze_2", "bronze_1",
	"silver_3", "silver_2", "silver_1",
	"gold_3",   "gold_2",   "gold_1",
	"platinum_3", "platinum_2", "platinum_1",
	"diamond_3", "diamond_2", "diamond_1",
	"master_3", "master_2", "master_1",
	"elite",
]

## Rank reward contents
## Each entry format: { "diamonds": int, "trap_cages": int, "cat_food": int, "special_cat_food": int }
const RANK_REWARDS: Dictionary = {
	"bronze_3":   { "diamonds": 20 },
	"bronze_2":   { "diamonds": 30, "trap_cages": 1 },
	"bronze_1":   { "diamonds": 40, "trap_cages": 1 },
	"silver_3":   { "diamonds": 50, "trap_cages": 2 },
	"silver_2":   { "diamonds": 60, "trap_cages": 2 },
	"silver_1":   { "diamonds": 70, "trap_cages": 2 },
	"gold_3":     { "diamonds": 80,  "trap_cages": 3, "cat_food": 10 },
	"gold_2":     { "diamonds": 90,  "trap_cages": 3, "cat_food": 15 },
	"gold_1":     { "diamonds": 100, "trap_cages": 4, "cat_food": 20 },
	"platinum_3": { "diamonds": 120, "trap_cages": 4, "special_cat_food": 5 },
	"platinum_2": { "diamonds": 140, "trap_cages": 5, "special_cat_food": 8 },
	"platinum_1": { "diamonds": 160, "trap_cages": 5, "special_cat_food": 10 },
	"diamond_3":  { "diamonds": 200, "trap_cages": 6, "special_cat_food": 12 },
	"diamond_2":  { "diamonds": 240, "trap_cages": 7, "special_cat_food": 15 },
	"diamond_1":  { "diamonds": 280, "trap_cages": 8, "special_cat_food": 20 },
	"master_3":   { "diamonds": 320, "trap_cages": 10, "special_cat_food": 25 },
	"master_2":   { "diamonds": 380, "trap_cages": 12, "special_cat_food": 30 },
	"master_1":   { "diamonds": 440, "trap_cages": 15, "special_cat_food": 35 },
	"elite":      { "diamonds": 500, "trap_cages": 20, "special_cat_food": 50 },
}


# ── Rank queries ──────────────────────────────────────────

## Get rank key from score
static func score_to_rank_key(score: int) -> String:
	var result := "bronze_3"
	for key: String in RANK_ORDER:
		if score >= RANK_THRESHOLDS[key]:
			result = key
	return result

## Get rank display name from score
static func score_to_rank_name(score: int) -> String:
	return RANK_NAMES.get(score_to_rank_key(score), UiText.ARENA_RANK_BRONZE + " III")

## Get minimum score for a rank key
static func rank_key_to_min_score(rank_key: String) -> int:
	return RANK_THRESHOLDS.get(rank_key, 0)

## Get rank index in RANK_ORDER (higher index = higher rank)
static func rank_key_to_index(rank_key: String) -> int:
	return RANK_ORDER.find(rank_key)


# ── Rank rewards ──────────────────────────────────────────

## Get rank reward keys claimable at the given score that have not yet been claimed
static func get_claimable_rewards(score: int, claimed: Array) -> Array:
	var result: Array = []
	for key: String in RANK_ORDER:
		if score >= RANK_THRESHOLDS[key] and not claimed.has(key):
			result.append(key)
	return result

## Get reward contents for a rank key
static func get_reward(rank_key: String) -> Dictionary:
	return RANK_REWARDS.get(rank_key, {})

## Apply rank rewards to PlayerData
static func apply_reward(rank_key: String, player_data: PlayerData) -> void:
	var reward := get_reward(rank_key)
	player_data.diamonds        += reward.get("diamonds",        0)
	player_data.trap_cages      += reward.get("trap_cages",      0)
	player_data.cat_food        += reward.get("cat_food",        0)
	player_data.special_cat_food += reward.get("special_cat_food", 0)
