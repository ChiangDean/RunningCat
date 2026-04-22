class_name ArenaRankSystem
extends RefCounted

## 競技場段位 / 積分 / 賽季 / 段位獎勵邏輯
## 所有方法皆為 static，無需實例化

# ── 段位定義 ──────────────────────────────────────────
## 每個段位 key 對應的最低積分門檻（大師/菁英以積分+PR決定，此處只管積分門檻）
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

## 段位顯示名稱（中文）
const RANK_NAMES: Dictionary = {
	"bronze_3":   "銅牌 III",
	"bronze_2":   "銅牌 II",
	"bronze_1":   "銅牌 I",
	"silver_3":   "銀牌 III",
	"silver_2":   "銀牌 II",
	"silver_1":   "銀牌 I",
	"gold_3":     "金牌 III",
	"gold_2":     "金牌 II",
	"gold_1":     "金牌 I",
	"platinum_3": "白金 III",
	"platinum_2": "白金 II",
	"platinum_1": "白金 I",
	"diamond_3":  "鑽石 III",
	"diamond_2":  "鑽石 II",
	"diamond_1":  "鑽石 I",
	"master_3":   "大師 III",
	"master_2":   "大師 II",
	"master_1":   "大師 I",
	"elite":      "菁英",
}

## 段位排序（由低到高）
const RANK_ORDER: Array = [
	"bronze_3", "bronze_2", "bronze_1",
	"silver_3", "silver_2", "silver_1",
	"gold_3",   "gold_2",   "gold_1",
	"platinum_3", "platinum_2", "platinum_1",
	"diamond_3", "diamond_2", "diamond_1",
	"master_3", "master_2", "master_1",
	"elite",
]

## 段位獎勵內容
## 每項格式：{ "diamonds": int, "trap_cages": int, "cat_food": int, "special_cat_food": int }
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


# ── 段位查詢 ──────────────────────────────────────────

## 依積分取得段位 key
static func score_to_rank_key(score: int) -> String:
	var result := "bronze_3"
	for key: String in RANK_ORDER:
		if score >= RANK_THRESHOLDS[key]:
			result = key
	return result

## 取得段位顯示名稱
static func score_to_rank_name(score: int) -> String:
	return RANK_NAMES.get(score_to_rank_key(score), "銅牌 III")

## 取得段位 key 對應的最低積分
static func rank_key_to_min_score(rank_key: String) -> int:
	return RANK_THRESHOLDS.get(rank_key, 0)

## 取得段位在 RANK_ORDER 中的索引（數值越高段位越高）
static func rank_key_to_index(rank_key: String) -> int:
	return RANK_ORDER.find(rank_key)


# ── 段位獎勵 ──────────────────────────────────────────

## 取得某積分可領取但尚未領取的段位獎勵 key 列表
static func get_claimable_rewards(score: int, claimed: Array) -> Array:
	var result: Array = []
	for key: String in RANK_ORDER:
		if score >= RANK_THRESHOLDS[key] and not claimed.has(key):
			result.append(key)
	return result

## 取得段位獎勵內容
static func get_reward(rank_key: String) -> Dictionary:
	return RANK_REWARDS.get(rank_key, {})

## 將段位獎勵套用至 PlayerData
static func apply_reward(rank_key: String, player_data: PlayerData) -> void:
	var reward := get_reward(rank_key)
	player_data.diamonds        += reward.get("diamonds",        0)
	player_data.trap_cages      += reward.get("trap_cages",      0)
	player_data.cat_food        += reward.get("cat_food",        0)
	player_data.special_cat_food += reward.get("special_cat_food", 0)
