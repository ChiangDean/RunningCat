class_name PlayerData
extends Resource

## 玩家全域資源存檔
## 新增欄位只需加上預設值，舊存檔讀取時不會壞掉

const SAVE_PATH: String = "res://data/saves/player_data.json"

# ── 資源 ──────────────────────────────────────────────
var cat_food: int = 0
var special_cat_food: int = 0
var gold: int = 0
var diamonds: int = 0
var trap_points: int = 0         # 誘捕點數，用於商店兌換

# ── 誘捕籠 ────────────────────────────────────────────
var total_pulls: int = 0          # 累計誘捕次數，決定誘捕技術等級
var free_pull_count: int = 1      # 每日免費抽數（累積遞增，上限由 Config 設定）
var last_free_pull_date: String = ""  # 上次免費誘捕日期（YYYY-MM-DD），空字串 = 未使用過

# ── 擁有貓咪 ──────────────────────────────────────────
## 玩家目前擁有的貓咪 ID 列表（初始含牛奶貓）
var owned_cat_ids: Array = ["milk_cat"]


# ── 查詢輔助 ──────────────────────────────────────────

## 今日是否已使用免費誘捕
func has_used_free_pull_today() -> bool:
	return last_free_pull_date == _today_string()

## 標記今日免費誘捕已使用，並讓下次免費抽數 +1（上限由外部傳入）
func consume_free_pull(cap: int) -> void:
	last_free_pull_date = _today_string()
	free_pull_count = mini(free_pull_count + 1, cap)

static func _today_string() -> String:
	return Time.get_date_string_from_system()


# ── 載入 ───────────────────────────────────────────────

static func load_or_default() -> PlayerData:
	if not FileAccess.file_exists(SAVE_PATH):
		return PlayerData.new()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("PlayerData: 存檔解析失敗，使用預設值")
		return PlayerData.new()
	file.close()
	return _from_dict(json.get_data())


static func _from_dict(data: Dictionary) -> PlayerData:
	var p := PlayerData.new()
	p.cat_food          = data.get("cat_food",          0)
	p.special_cat_food  = data.get("special_cat_food",  0)
	p.gold              = data.get("gold",              0)
	p.diamonds          = data.get("diamonds",          0)
	p.trap_points       = data.get("trap_points",       0)
	p.total_pulls       = data.get("total_pulls",       0)
	p.free_pull_count   = data.get("free_pull_count",   1)
	p.last_free_pull_date = data.get("last_free_pull_date", "")
	var ids: Array = data.get("owned_cat_ids", ["milk_cat"])
	p.owned_cat_ids = ids if not ids.is_empty() else ["milk_cat"]
	return p


# ── 儲存 ───────────────────────────────────────────────

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerData: 無法寫入存檔：" + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_to_dict(), "\t"))
	file.close()


func _to_dict() -> Dictionary:
	return {
		"schema_version":     1,
		"cat_food":           cat_food,
		"special_cat_food":   special_cat_food,
		"gold":               gold,
		"diamonds":           diamonds,
		"trap_points":        trap_points,
		"total_pulls":        total_pulls,
		"free_pull_count":    free_pull_count,
		"last_free_pull_date": last_free_pull_date,
		"owned_cat_ids":      owned_cat_ids,
	}
