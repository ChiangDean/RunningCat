extends Node

## 全局遊戲狀態，跨場景共享

# ── 玩家資源 & 強化存檔 ──────────────────────
var player_data: PlayerData
## 已載入的貓咪強化存檔快取，key = cat_id
var _player_cat_cache: Dictionary = {}

## 目前擁有的貓咪 ID 列表（從 player_data 讀取）
func get_owned_cats() -> Array:
	if player_data == null:
		return ["milk_cat"]
	return player_data.owned_cat_ids


## 新增擁有的貓咪並建立快取（扭蛋後呼叫）
func add_owned_cat(cat_id: String) -> void:
	if not player_data.owned_cat_ids.has(cat_id):
		player_data.owned_cat_ids.append(cat_id)
	if not _player_cat_cache.has(cat_id):
		_player_cat_cache[cat_id] = PlayerCatData.load_or_default(cat_id)

# ── 玩家配置 ──────────────────────────────────
var player_team: Array = ["milk_cat", "milk_cat", "milk_cat"]
var skill_delays: Dictionary = {}

# ── 關卡進度（單一數字記錄）──────────────────────
## 全局關卡編號（1 起算），單一數字即可還原所有進度資訊
## 每個 Boss 關 = 4 個遭遇戰 + 1 個 Boss，共 5 格
## 範例：1=1-1, 2=1-2, 3=1-3, 4=1-4, 5=1-BOSS, 6=2-1, 50=10-BOSS
var current_global_stage: int = 1
## Boss 失敗後為 true，顯示「挑戰 Boss」按鈕
var boss_available: bool = false

# ── 地下城戰鬥狀態 ────────────────────────────
var dungeon_battle_id: String = ""
var dungeon_battle_level: int = 1
var dungeon_data: PlayerDungeonData
## 地下城全域設定（啟動時載入一次，供所有場景共用）
var dungeon_config: Dictionary = {}

# ── 競技場狀態 ────────────────────────────────
var arena_data: PlayerArenaData
## 競技場當前對戰資訊（進入戰鬥前設定，戰鬥結束後讀取）
var arena_opponent: Dictionary = {}   # { player_id, player_name, score, rank_name, defense_team }
var arena_config: Dictionary = {}     # 由 config 讀取的競技場設定（賽季日期、購買費用等）

# ── 常數 ──────────────────────────────────────
func _ready() -> void:
	player_data = PlayerData.load_or_default()
	current_global_stage = player_data.current_stage
	dungeon_config = _load_json("res://data/default/dungeon_config.json")
	dungeon_data = PlayerDungeonData.load_or_default()
	dungeon_data.check_daily_reset(int(dungeon_config.get("daily_free_tickets", 2)))
	for cat_id: String in player_data.owned_cat_ids:
		_player_cat_cache[cat_id] = PlayerCatData.load_or_default(cat_id)
	arena_config = _load_json("res://data/default/arena_config.json")
	arena_data = PlayerArenaData.load_or_create()
	arena_data.season_end_date = arena_config.get("season_end_date", arena_data.season_end_date)
	arena_data.check_daily_reset()
	arena_data.check_season_reset()
	# 以 boss_team 作為預設出戰隊伍
	if not player_data.boss_team.is_empty():
		player_team = player_data.boss_team.duplicate()


static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameState: 無法開啟 " + path)
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("GameState: JSON 解析失敗 " + path)
		return {}
	file.close()
	return json.get_data()


## 取得貓咪強化存檔（找不到時自動建立預設值）
func get_player_cat(cat_id: String) -> PlayerCatData:
	if not _player_cat_cache.has(cat_id):
		_player_cat_cache[cat_id] = PlayerCatData.load_or_default(cat_id)
	return _player_cat_cache[cat_id]


## 儲存所有玩家資料（資源 + 所有貓咪強化 + 地下城進度 + 競技場）
func save_all() -> void:
	player_data.current_stage = current_global_stage
	player_data.save()
	dungeon_data.save()
	arena_data.save()
	arena_data.flush_to_leaderboard()
	for cat_id: String in _player_cat_cache:
		_player_cat_cache[cat_id].save()

## 每個 Boss 關含幾個普通遭遇戰（不含 Boss）
const ENCOUNTERS_PER_BOSS_STAGE: int = 4
## 每個區域含幾個 Boss 關
const BOSS_STAGES_PER_ZONE: int = 10
## 每個領地含幾個區域
const ZONES_PER_TERRITORY: int = 5

## 難度成長係數（Stage 與 Boss 分開計算）
## 每進一普通遭遇戰，敵方數值累積 ×1.003
const STAGE_GROWTH: float = 1.003
## 每過一個 Boss 關，Boss 數值累積 ×1.02
const BOSS_GROWTH: float = 1.02

const TERRITORY_NAMES: Array = [
	"", "新手", "普通", "高級", "進階", "菁英",
]
const ZONE_SUFFIXES: Array = [
	"", "I", "II", "III", "IV", "V",
]

# ── 進度輔助計算 ───────────────────────────────

## 當前 Boss 關序號（全局，1 起算）
## 1-1 ~ 1-BOSS 均屬第 1 個 Boss 關，2-1 ~ 2-BOSS 屬第 2 個，以此類推
func get_boss_stage_number() -> int:
	return ceili(float(current_global_stage) / float(ENCOUNTERS_PER_BOSS_STAGE + 1))

## 當前遭遇戰索引（1~4 = 普通遭遇戰，5 = Boss）
func get_encounter_index() -> int:
	return ((current_global_stage - 1) % (ENCOUNTERS_PER_BOSS_STAGE + 1)) + 1

## 是否目前是 Boss 戰
func is_current_boss() -> bool:
	return get_encounter_index() == ENCOUNTERS_PER_BOSS_STAGE + 1

## Boss 關在當前區域內的序號（1~BOSS_STAGES_PER_ZONE）
func get_zone_boss_stage() -> int:
	return ((get_boss_stage_number() - 1) % BOSS_STAGES_PER_ZONE) + 1

## 當前所在領地的區域序號（1~ZONES_PER_TERRITORY）
func get_zone_in_territory() -> int:
	var stages_per_territory: int = BOSS_STAGES_PER_ZONE * ZONES_PER_TERRITORY
	return (((get_boss_stage_number() - 1) % stages_per_territory) / BOSS_STAGES_PER_ZONE) + 1

## 當前領地序號（1 起算）
func get_territory_number() -> int:
	var stages_per_territory: int = BOSS_STAGES_PER_ZONE * ZONES_PER_TERRITORY
	return ((get_boss_stage_number() - 1) / stages_per_territory) + 1

# ── 關卡顯示 ──────────────────────────────────

## 顯示格式範例：「新手 I  1-4」、「新手 II  3-BOSS」
func get_level_display() -> String:
	var stage_str: String
	if is_current_boss():
		stage_str = "%d-BOSS" % get_zone_boss_stage()
	else:
		stage_str = "%d-%d" % [get_zone_boss_stage(), get_encounter_index()]

	return "%s %s  %s" % [_get_territory_name(), _get_zone_suffix(), stage_str]

func _get_territory_name() -> String:
	var t: int = get_territory_number()
	if t < TERRITORY_NAMES.size():
		return TERRITORY_NAMES[t]
	return "領地%d" % t

func _get_zone_suffix() -> String:
	var z: int = get_zone_in_territory()
	if z < ZONE_SUFFIXES.size():
		return ZONE_SUFFIXES[z]
	return "%d" % z

# ── 難度計算 ───────────────────────────────────

## 回傳當前關卡的敵方數值倍率
## 普通遭遇戰：每關 +0.3% 複利成長（Stage 軌道）
## Boss 關：每個 Boss +2% 複利成長（Boss 軌道，與 Stage 分開計算）
func get_difficulty_multiplier() -> float:
	if is_current_boss():
		# Boss 軌道：依全局 Boss 關序號計算
		# 1-BOSS = ×1.020, 10-BOSS = ×1.219, 50-BOSS = ×2.692
		return pow(BOSS_GROWTH, get_boss_stage_number())
	else:
		# Stage 軌道：依全局關卡編號計算（1-1 = ×1.000）
		# 1-4 = ×1.009, 10-4 = ×1.136, 50-4 = ×2.064
		return pow(STAGE_GROWTH, current_global_stage - 1)

# ── 敵方生成 ───────────────────────────────────

func get_enemy_ids() -> Array:
	var boss_stage := get_boss_stage_number()
	var count: int
	if is_current_boss():
		# Boss 戰：隨世界推進增加到最多 5 隻
		count = mini(1 + boss_stage, 5)
	else:
		# 普通遭遇戰：較少，每 3 個 Boss 關增加一隻
		count = mini(1 + (boss_stage - 1) / 3, 5)
	count = maxi(count, 1)
	var ids: Array = []
	for i in range(count):
		ids.append("test_enemy")
	return ids

# ── 進度邏輯 ──────────────────────────────────

## 勝利後推進到下一關（一律 +1，結構由 current_global_stage 自動計算）
func advance_after_win() -> void:
	boss_available = false
	current_global_stage += 1
	player_data.current_stage = current_global_stage
	player_data.save()  # 即時寫入，確保強制退出時不遺失進度

## Boss 失敗後退回該 Boss 關的第 4 遭遇戰，顯示「挑戰 Boss」按鈕
func on_boss_fail() -> void:
	var bs: int = get_boss_stage_number()
	current_global_stage = (bs - 1) * (ENCOUNTERS_PER_BOSS_STAGE + 1) + ENCOUNTERS_PER_BOSS_STAGE
	boss_available = true

## 玩家手動挑戰 Boss（從第 4 遭遇戰跳到 Boss）
func challenge_boss() -> void:
	var bs: int = get_boss_stage_number()
	current_global_stage = bs * (ENCOUNTERS_PER_BOSS_STAGE + 1)

# ── 技能延遲 ──────────────────────────────────

func get_delay(slot_index: int) -> int:
	return skill_delays.get(slot_index, 0)

func set_delay(slot_index: int, delay: int) -> void:
	skill_delays[slot_index] = clampi(delay, 0, 9)
