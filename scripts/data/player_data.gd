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
var trap_cages: int = 0          # 誘捕籠道具（消耗品，可存放後手動使用）
var whisker_shards: int = 0      # 通用鬍鬚（地下城獎勵等來源）

# ── 誘捕籠 ────────────────────────────────────────────
var total_pulls: int = 0          # 累計誘捕次數，決定誘捕技術等級
var free_pull_count: int = 1      # 每日免費抽數（累積遞增，上限由 Config 設定）
var last_free_pull_date: String = ""  # 上次免費誘捕日期（YYYY-MM-DD），空字串 = 未使用過

# ── 關卡進度 ────────────────────────────────────────────
var current_stage: int = 1        # 全局關卡進度，對應 GameState.current_global_stage

# ── 擁有貓咪 ──────────────────────────────────────────
## 玩家目前擁有的貓咪 ID 列表（初始含牛奶貓）
var owned_cat_ids: Array = ["milk_cat"]

# ── 隊伍設定 ──────────────────────────────────────────
## BOSS 推關隊伍（最多 5 隻）
var boss_team: Array = []
## 地下城隊伍（最多 5 隻）
var dungeon_team: Array = []
## 競技場攻擊隊伍（最多 5 隻）
var arena_attack_team: Array = []
## 競技場防守隊伍（最多 5 隻；空陣列 = 自動代入攻擊隊伍）
var arena_defense_team: Array = []


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
	p.trap_cages        = data.get("trap_cages",        0)
	p.whisker_shards    = data.get("whisker_shards",    0)
	p.total_pulls       = data.get("total_pulls",       0)
	p.free_pull_count   = data.get("free_pull_count",   1)
	p.last_free_pull_date = data.get("last_free_pull_date", "")
	p.current_stage     = data.get("current_stage",     1)
	var ids: Array = data.get("owned_cat_ids", ["milk_cat"])
	p.owned_cat_ids = ids if not ids.is_empty() else ["milk_cat"]
	p.boss_team          = data.get("boss_team",           [])
	p.dungeon_team       = data.get("dungeon_team",        [])
	p.arena_attack_team  = data.get("arena_attack_team",   [])
	p.arena_defense_team = data.get("arena_defense_team",  [])
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
		"trap_cages":         trap_cages,
		"whisker_shards":     whisker_shards,
		"total_pulls":        total_pulls,
		"free_pull_count":    free_pull_count,
		"last_free_pull_date": last_free_pull_date,
		"current_stage":       current_stage,
		"owned_cat_ids":       owned_cat_ids,
		"boss_team":           boss_team,
		"dungeon_team":        dungeon_team,
		"arena_attack_team":   arena_attack_team,
		"arena_defense_team":  arena_defense_team,
	}
