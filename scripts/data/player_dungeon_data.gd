class_name PlayerDungeonData
extends Resource

## 玩家地下城進度存檔
## 新增地下城只需在 dungeon_config.json 中加入，舊存檔讀取時會自動補上預設值

const SAVE_PATH: String = "res://data/saves/player_dungeons.json"

## 每個地下城的進度記錄
## key: dungeon_id (String)
## value: {
##   "max_level": int,      最高通關關卡
##   "tickets": int,        當前卷數（每日重置為 daily_free_tickets）
##   "ad_views_used": int,  今日已看廣告次數（每日重置為 0）
## }
var dungeons: Dictionary = {}

## 上次每日重置的日期（UTC+8，YYYY-MM-DD）
var last_reset_date: String = ""


# ── 每日重置 ───────────────────────────────────

## 檢查並執行每日重置（UTC+8 午夜）
## 應在遊戲啟動時呼叫一次，需傳入 daily_free_tickets 作為重置後的卷數基準
func check_daily_reset(daily_free: int) -> void:
	var today := _today_utc8()
	if last_reset_date == today:
		return
	last_reset_date = today
	for key: String in dungeons:
		dungeons[key]["tickets"]       = daily_free
		dungeons[key]["ad_views_used"] = 0
	save()


static func _today_utc8() -> String:
	var unix_time: float = Time.get_unix_time_from_system()
	var adjusted: int = int(unix_time) + 8 * 3600
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(adjusted)
	return "%04d-%02d-%02d" % [dict["year"], dict["month"], dict["day"]]


# ── 進度查詢 ───────────────────────────────────

## 取得指定地下城的進度（找不到時自動建立預設值）
func get_dungeon(dungeon_id: String, daily_free: int = 2) -> Dictionary:
	if not dungeons.has(dungeon_id):
		dungeons[dungeon_id] = {
			"max_level":    0,
			"tickets":      daily_free,
			"ad_views_used": 0,
		}
	return dungeons[dungeon_id]


## 當前卷數
func get_tickets(dungeon_id: String, daily_free: int) -> int:
	return get_dungeon(dungeon_id, daily_free).get("tickets", daily_free)


## 今日剩餘可看廣告次數
func get_ad_views_remaining(dungeon_id: String, ad_per_type: int) -> int:
	var d: Dictionary = get_dungeon(dungeon_id)
	return maxi(0, ad_per_type - d.get("ad_views_used", 0))


## 消耗一張卷（回傳 false 若無卷）
func consume_ticket(dungeon_id: String, daily_free: int) -> bool:
	var d: Dictionary = get_dungeon(dungeon_id, daily_free)
	if d.get("tickets", 0) <= 0:
		return false
	d["tickets"] = d["tickets"] - 1
	return true


## 看廣告後獲得一張卷（回傳 false 若已達今日上限）
func grant_ad_ticket(dungeon_id: String, ad_per_type: int, daily_free: int) -> bool:
	if get_ad_views_remaining(dungeon_id, ad_per_type) <= 0:
		return false
	var d: Dictionary = get_dungeon(dungeon_id, daily_free)
	d["ad_views_used"] = d.get("ad_views_used", 0) + 1
	d["tickets"]       = d.get("tickets", 0) + 1
	return true


## 計算指定地下城在指定關卡的獎勵
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


## 將獎勵套用至 PlayerData
static func apply_rewards(pd: PlayerData, rewards: Dictionary) -> void:
	pd.cat_food         += rewards.get("cat_food",         0)
	pd.special_cat_food += rewards.get("special_cat_food", 0)
	pd.diamonds         += rewards.get("diamonds",         0)
	pd.trap_cages       += rewards.get("trap_cages",       0)
	pd.whisker_shards   += rewards.get("whisker_shards",   0)


## 更新最高通關關卡（僅在新紀錄時更新）
func update_max_level(dungeon_id: String, level: int) -> void:
	var d: Dictionary = get_dungeon(dungeon_id)
	if level > d.get("max_level", 0):
		d["max_level"] = level


# ── 載入 ───────────────────────────────────────

static func load_or_default() -> PlayerDungeonData:
	if not FileAccess.file_exists(SAVE_PATH):
		return PlayerDungeonData.new()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("PlayerDungeonData: 存檔解析失敗，使用預設值")
		return PlayerDungeonData.new()
	file.close()
	return _from_dict(json.get_data())


static func _from_dict(data: Dictionary) -> PlayerDungeonData:
	var pd := PlayerDungeonData.new()
	pd.last_reset_date = data.get("last_reset_date", "")
	var saved: Dictionary = data.get("dungeons", {})
	for key: String in saved:
		var entry: Dictionary = saved[key]
		pd.dungeons[key] = {
			"max_level":    entry.get("max_level",    0),
			"tickets":      entry.get("tickets",      2),
			"ad_views_used": entry.get("ad_views_used", 0),
		}
	return pd


# ── 儲存 ───────────────────────────────────────

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerDungeonData: 無法寫入存檔：" + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_to_dict(), "\t"))
	file.close()


func _to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"last_reset_date": last_reset_date,
		"dungeons":        dungeons,
	}
