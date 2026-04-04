class_name GachaSystem
extends RefCounted

## 誘捕籠核心邏輯：機率計算、結果產生、重複處理
## 所有函式皆為 static，不需實例化

const GACHA_CONFIG_PATH: String = "res://data/default/gacha_config.json"
const CAT_DATA_PATH: String     = "res://data/default/cats/"

# ── 設定快取 ───────────────────────────────────────────
static var _config: Dictionary = {}

static func _get_config() -> Dictionary:
	if not _config.is_empty():
		return _config
	if not FileAccess.file_exists(GACHA_CONFIG_PATH):
		push_error("GachaSystem: 找不到 gacha_config.json")
		return {}
	var file := FileAccess.open(GACHA_CONFIG_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("GachaSystem: gacha_config.json 解析失敗")
		return {}
	file.close()
	_config = json.get_data()
	return _config


# ── 技術等級查詢 ───────────────────────────────────────

## 依累計抽數回傳目前誘捕技術等級
static func get_technique_level() -> int:
	var config := _get_config()
	var total: int = GameState.player_data.total_pulls
	var levels: Array = config.get("technique_levels", [])
	var current := 1
	for entry: Dictionary in levels:
		if total >= int(entry.get("required_pulls", 0)):
			current = int(entry.get("level", 1))
	return current


## 回傳下一等級所需累計抽數（-1 表示已滿等）
static func get_next_level_threshold() -> int:
	var config := _get_config()
	var total: int = GameState.player_data.total_pulls
	var levels: Array = config.get("technique_levels", [])
	for entry: Dictionary in levels:
		var req: int = int(entry.get("required_pulls", 0))
		if total < req:
			return req
	return -1


# ── 稀有度查詢 ────────────────────────────────────────

## 依稀有度 ID 取得顯示資料（name, color）
static func get_rarity_info(rarity_id: String) -> Dictionary:
	var config := _get_config()
	for r: Dictionary in config.get("rarities", []):
		if r.get("id", "") == rarity_id:
			return r
	return {"id": rarity_id, "name": rarity_id, "color": "#FFFFFF"}


# ── 主要抽獎邏輯 ──────────────────────────────────────

## 執行 count 次抽獎，回傳結果陣列
## 每筆結果格式：
## { cat_id, display_name, rarity_id, rarity_name, rarity_color, is_new, shards_given, trap_points_given }
static func perform_pulls(count: int) -> Array:
	var config  := _get_config()
	var results: Array = []

	var tech_lv := get_technique_level()
	var rates   := _get_rates_for_level(tech_lv)
	var pool: Dictionary = config.get("cat_pool", {})

	for _i in range(count):
		var rarity_id := _roll_rarity(rates)
		var cat_ids: Array = pool.get(rarity_id, [])
		if cat_ids.is_empty():
			continue
		var cat_id: String = cat_ids[randi() % cat_ids.size()]
		results.append(_process_single(cat_id, rarity_id, config))

	# 累積總抽數並存檔
	GameState.player_data.total_pulls += count
	GameState.save_all()
	return results


# ── 費用計算 ──────────────────────────────────────────

## 依抽數回傳鑽石費用
static func cost_for_count(count: int) -> int:
	var config := _get_config()
	var costs: Dictionary = config.get("pull_costs", {})
	match count:
		1:  return int(costs.get("single",      100))
		11: return int(costs.get("eleven",      1000))
		35: return int(costs.get("thirty_five", 3000))
	return count * int(costs.get("single", 100))


## 每日免費誘捕的 Config 上限
static func free_pull_cap() -> int:
	return int(_get_config().get("daily_free_pull_cap", 50))


# ── 內部輔助 ──────────────────────────────────────────

static func _get_rates_for_level(level: int) -> Dictionary:
	var config := _get_config()
	for entry: Dictionary in config.get("technique_levels", []):
		if int(entry.get("level", 0)) == level:
			return entry.get("rates", {})
	return {"common": 100}


## 依機率表擲骰，回傳稀有度 ID
static func _roll_rarity(rates: Dictionary) -> String:
	# 從高稀有到低稀有依序累加，確保高稀有優先命中
	var order: Array = [
		"legendary", "epic", "rare", "excellent",
		"precious", "special", "fine", "uncommon", "common"
	]
	var roll: float = randf() * 100.0
	var cumulative: float = 0.0
	for rarity_id: String in order:
		cumulative += float(rates.get(rarity_id, 0))
		if roll < cumulative:
			return rarity_id
	return "common"


static func _process_single(cat_id: String, rarity_id: String, config: Dictionary) -> Dictionary:
	var cat_data := CatData.from_json_file(CAT_DATA_PATH + cat_id + ".json")
	var display  := cat_data.display_name if cat_data != null else cat_id
	var rarity_info := get_rarity_info(rarity_id)

	var is_new: bool = not GameState.player_data.owned_cat_ids.has(cat_id)
	var shards_given: int = 0
	var trap_given: int = 0

	if is_new:
		# 新貓咪：加入擁有列表並初始化存檔
		GameState.add_owned_cat(cat_id)
	else:
		# 重複貓咪：給鬍鬚碎片或誘捕點數
		var player_cat := GameState.get_player_cat(cat_id)
		shards_given = int(config.get("duplicate_shard_reward", 10))
		player_cat.cat_shards += shards_given

	return {
		"cat_id":        cat_id,
		"display_name":  display,
		"rarity_id":     rarity_id,
		"rarity_name":   rarity_info.get("name",  rarity_id),
		"rarity_color":  rarity_info.get("color", "#FFFFFF"),
		"is_new":        is_new,
		"shards_given":  shards_given,
		"trap_points_given": trap_given,
	}
