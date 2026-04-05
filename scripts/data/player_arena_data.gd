class_name PlayerArenaData
extends Resource

## 玩家競技場存檔
## 對應 data/saves/player_arena.json

const SAVE_PATH: String = "res://data/saves/player_arena.json"
const ARENA_DATA_PATH: String = "res://data/arena/arena_data.json"

const DAILY_FREE_TICKETS: int = 10
const MAX_DAILY_PURCHASES: int = 5
const TICKETS_PER_PURCHASE: int = 3

# ── 玩家基本資料 ──────────────────────────────────────
var player_id: String = ""
var player_name: String = ""

# ── 積分 ──────────────────────────────────────────────
var score: int = 0

# ── 競技券 ────────────────────────────────────────────
var tickets: int = DAILY_FREE_TICKETS
var daily_purchase_count: int = 0   # 今日已購買次數（每日重置）
var last_reset_date: String = ""    # 上次每日重置（UTC+8，YYYY-MM-DD）

# ── 連勝 / 連敗 ───────────────────────────────────────
var win_streak: int = 0
var loss_streak: int = 0

# ── 段位獎勵 ──────────────────────────────────────────
## 已領取的段位 key 列表，例如 ["bronze_3", "bronze_2"]
var claimed_rank_rewards: Array = []

# ── 賽季 ──────────────────────────────────────────────
var season_end_date: String = ""    # 由 Config 設定，格式 YYYY-MM-DD

# ── 防守快照 ───────────────────────────────────────────
## 記錄設定防守隊伍當下的貓咪強化狀態，供對手戰鬥使用
## 格式：{ cat_id: { "cat_food_level", "special_food_points", "rank" } }
var defense_snapshot: Dictionary = {}


# ── 初始化 ────────────────────────────────────────────

## 建立新玩家資料，生成唯一 player_id 與預設名稱
static func create_new() -> PlayerArenaData:
	var d := PlayerArenaData.new()
	d.player_id = "player_" + str(randi() % 900000 + 100000)
	d.player_name = "測試玩家" + str(randi() % 9000 + 1000)
	d.score = 0
	d.tickets = DAILY_FREE_TICKETS
	d.last_reset_date = _today_utc8()
	return d


# ── 每日重置 ──────────────────────────────────────────

func check_daily_reset() -> void:
	var today := _today_utc8()
	if last_reset_date == today:
		return
	last_reset_date = today
	tickets = DAILY_FREE_TICKETS
	daily_purchase_count = 0
	save()


static func _today_utc8() -> String:
	var unix_time: float = Time.get_unix_time_from_system()
	var adjusted: int = int(unix_time) + 8 * 3600
	var dict: Dictionary = Time.get_datetime_dict_from_unix_time(adjusted)
	return "%04d-%02d-%02d" % [dict["year"], dict["month"], dict["day"]]


# ── 競技券操作 ────────────────────────────────────────

func consume_ticket() -> bool:
	if tickets <= 0:
		return false
	tickets -= 1
	return true

## 購買競技券，費用由外部（Config）傳入
## 回傳 false 若今日已達購買上限或鑽石不足
func purchase_tickets(cost: int, player_data: PlayerData) -> bool:
	if daily_purchase_count >= MAX_DAILY_PURCHASES:
		return false
	if player_data.diamonds < cost:
		return false
	player_data.diamonds -= cost
	tickets += TICKETS_PER_PURCHASE
	daily_purchase_count += 1
	return true

func get_next_purchase_cost(cost_table: Array) -> int:
	if daily_purchase_count >= cost_table.size():
		return -1  # 已達上限
	return cost_table[daily_purchase_count]

func can_purchase_more() -> bool:
	return daily_purchase_count < MAX_DAILY_PURCHASES


# ── 積分操作 ──────────────────────────────────────────

func add_score(delta: int) -> void:
	score = maxi(0, score + delta)

func record_win() -> void:
	win_streak += 1
	loss_streak = 0

func record_loss() -> void:
	loss_streak += 1
	win_streak = 0


# ── 防守快照 ──────────────────────────────────────────

## 更新防守隊伍快照（存檔配置時呼叫）
## defense_team: Array[String]（cat_id 列表）
## cat_cache: Dictionary（cat_id → PlayerCatData）
func update_defense_snapshot(defense_team: Array, cat_cache: Dictionary) -> void:
	defense_snapshot = {}
	for cat_id: String in defense_team:
		var pcat: PlayerCatData = cat_cache.get(cat_id)
		if pcat == null:
			defense_snapshot[cat_id] = { "cat_food_level": 1, "special_food_points": {"hp":0,"atk":0,"def":0}, "rank": 0 }
		else:
			defense_snapshot[cat_id] = {
				"cat_food_level":      pcat.cat_food_level,
				"special_food_points": pcat.special_food_points.duplicate(),
				"rank":                pcat.rank,
			}


# ── 段位獎勵 ──────────────────────────────────────────

func has_claimed_reward(rank_key: String) -> bool:
	return claimed_rank_rewards.has(rank_key)

func claim_reward(rank_key: String) -> void:
	if not has_claimed_reward(rank_key):
		claimed_rank_rewards.append(rank_key)


# ── 賽季重置 ──────────────────────────────────────────

## 檢查賽季是否已結束，若是則執行重置
## 應在遊戲啟動時呼叫
func check_season_reset() -> bool:
	if season_end_date.is_empty():
		return false
	var today := _today_utc8()
	if today <= season_end_date:
		return false
	_apply_season_reset()
	return true

func _apply_season_reset() -> void:
	var old_score := score
	# 依段位決定重置積分
	if old_score >= 1200:         # 鑽石以上（含大師/菁英）
		score = 1200              # 退回鑽石III
	elif old_score >= 600:        # 金牌以上（含白金/鑽石）
		score = 600               # 退回金牌III
	elif old_score >= 300:        # 銀牌以上（含白金）
		score = 300               # 退回銀牌III
	else:                         # 銅牌
		score = 0
	# 重置段位獎勵（降段後可重新領取降段以下的獎勵）
	claimed_rank_rewards = claimed_rank_rewards.filter(
		func(key: String) -> bool:
			return ArenaRankSystem.rank_key_to_min_score(key) >= score
	)


# ── 排行榜（arena_data.json）操作 ─────────────────────

## 將本玩家積分寫入排行榜
func flush_to_leaderboard() -> void:
	var leaderboard := _load_leaderboard()
	leaderboard[player_id] = { "score": score }
	_save_leaderboard(leaderboard)

static func _load_leaderboard() -> Dictionary:
	if not FileAccess.file_exists(ARENA_DATA_PATH):
		return {}
	var file := FileAccess.open(ARENA_DATA_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	return json.get_data()

static func _save_leaderboard(data: Dictionary) -> void:
	var file := FileAccess.open(ARENA_DATA_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerArenaData: 無法寫入排行榜：" + ARENA_DATA_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## 取得排行榜（供 matchmaking 使用）
static func load_leaderboard() -> Dictionary:
	return _load_leaderboard()


# ── 載入 ──────────────────────────────────────────────

static func load_or_create() -> PlayerArenaData:
	if not FileAccess.file_exists(SAVE_PATH):
		var fresh := create_new()
		fresh.save()
		fresh.flush_to_leaderboard()
		return fresh
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("PlayerArenaData: 存檔解析失敗，重新建立")
		var fresh := create_new()
		fresh.save()
		fresh.flush_to_leaderboard()
		return fresh
	file.close()
	return _from_dict(json.get_data())


static func _from_dict(data: Dictionary) -> PlayerArenaData:
	var d := PlayerArenaData.new()
	d.player_id           = data.get("player_id",           "")
	d.player_name         = data.get("player_name",         "")
	d.score               = data.get("score",               0)
	d.tickets             = data.get("tickets",             DAILY_FREE_TICKETS)
	d.daily_purchase_count = data.get("daily_purchase_count", 0)
	d.last_reset_date     = data.get("last_reset_date",     "")
	d.win_streak          = data.get("win_streak",          0)
	d.loss_streak         = data.get("loss_streak",         0)
	d.claimed_rank_rewards = data.get("claimed_rank_rewards", [])
	d.season_end_date     = data.get("season_end_date",     "")
	d.defense_snapshot    = data.get("defense_snapshot",    {})
	# 若 player_id 為空（舊存檔），重新初始化
	if d.player_id.is_empty():
		d.player_id = "player_" + str(randi() % 900000 + 100000)
	if d.player_name.is_empty():
		d.player_name = "測試玩家" + str(randi() % 9000 + 1000)
	return d


# ── 儲存 ──────────────────────────────────────────────

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerArenaData: 無法寫入存檔：" + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_to_dict(), "\t"))
	file.close()


func _to_dict() -> Dictionary:
	return {
		"schema_version":       1,
		"player_id":            player_id,
		"player_name":          player_name,
		"score":                score,
		"tickets":              tickets,
		"daily_purchase_count": daily_purchase_count,
		"last_reset_date":      last_reset_date,
		"win_streak":           win_streak,
		"loss_streak":          loss_streak,
		"claimed_rank_rewards": claimed_rank_rewards,
		"season_end_date":      season_end_date,
		"defense_snapshot":     defense_snapshot,
	}
