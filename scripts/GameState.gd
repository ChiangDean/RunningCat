extends Node

const AUTH_SESSION_PATH := "user://auth_session.json"
const PLAYER_DATA_PATH := PlayerData.SAVE_PATH
const LEGACY_PLAYER_DATA_PATH := PlayerData.LEGACY_SAVE_PATH
const LEGACY_PLAYER_DUNGEON_DATA_PATH := PlayerDungeonData.SAVE_PATH
const LEGACY_PLAYER_ARENA_DATA_PATH := PlayerArenaData.SAVE_PATH
const LEGACY_PLAYER_CAT_DIR_PATH := PlayerCatData.SAVE_DIR

var api_base_url: String = ""
var auth_session: Dictionary = {}

## 全局遊戲狀態，跨場景共享
signal achievements_changed

# ── 玩家資源 & 強化存檔 ──────────────────────
var player_data: PlayerData
## 已載入的貓咪強化存檔快取，key = cat_id
var _player_cat_cache: Dictionary = {}


func set_auth_session(base_url: String, session: Dictionary) -> void:
	api_base_url = base_url
	auth_session = session.duplicate(true)
	_save_auth_session()


func clear_auth_session() -> void:
	api_base_url = ""
	auth_session = {}
	_delete_auth_session_file()


func clear_persisted_player_state() -> void:
	_delete_file_if_exists(PLAYER_DATA_PATH)
	_delete_file_if_exists(LEGACY_PLAYER_DATA_PATH)
	_delete_file_if_exists(LEGACY_PLAYER_DUNGEON_DATA_PATH)
	_delete_file_if_exists(LEGACY_PLAYER_ARENA_DATA_PATH)
	_delete_files_in_directory(LEGACY_PLAYER_CAT_DIR_PATH)

	player_data = PlayerData.new()
	_player_cat_cache = {}
	player_team = ["milk_cat", "milk_cat", "milk_cat"]
	skill_delays = {}
	current_global_stage = 1
	boss_available = false
	dungeon_battle_id = ""
	dungeon_battle_level = 1
	dungeon_data = PlayerDungeonData.new()
	arena_data = PlayerArenaData.new()
	arena_opponent = {}


func clear_auth_and_player_state() -> void:
	clear_auth_session()
	clear_persisted_player_state()


func load_persisted_auth_session() -> bool:
	if not FileAccess.file_exists(AUTH_SESSION_PATH):
		return false

	var file := FileAccess.open(AUTH_SESSION_PATH, FileAccess.READ)
	if file == null:
		return false

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		return false

	var data: Variant = json.get_data()
	if not (data is Dictionary):
		return false

	var payload: Dictionary = data
	var session_variant: Variant = payload.get("session", {})
	if not (session_variant is Dictionary):
		return false

	var persisted_base_url := String(payload.get("api_base_url", "")).strip_edges()
	if persisted_base_url == "":
		return false

	var session: Dictionary = session_variant if session_variant is Dictionary else {}
	api_base_url = persisted_base_url
	auth_session = session.duplicate(true)
	return not auth_session.is_empty()


func get_access_token() -> String:
	return String(auth_session.get("accessToken", "")).strip_edges()


func get_refresh_token() -> String:
	return String(auth_session.get("refreshToken", "")).strip_edges()


func apply_player_bootstrap(data: Dictionary) -> void:
	if player_data == null:
		player_data = PlayerData.load_or_default()

	player_data.account = String(data.get("account", player_data.account))
	player_data.display_name = String(data.get("displayName", player_data.display_name))
	player_data.player_public_id = String(data.get("playerPublicId", player_data.player_public_id))
	player_data.player_name = String(data.get("playerName", player_data.player_name))
	player_data.cat_food = int(data.get("catFood", player_data.cat_food))
	player_data.special_cat_food = int(data.get("specialCatFood", player_data.special_cat_food))
	player_data.gold = int(data.get("gold", player_data.gold))
	player_data.diamonds = int(data.get("diamonds", player_data.diamonds))
	player_data.trap_points = int(data.get("trapPoints", player_data.trap_points))
	player_data.trap_cages = int(data.get("trapCages", player_data.trap_cages))
	player_data.whisker_shards = int(data.get("whiskerShards", player_data.whisker_shards))
	player_data.last_quit_time = int(data.get("lastQuitTimeUnixSeconds", player_data.last_quit_time))
	player_data.poop_count = int(data.get("poopCount", player_data.poop_count))
	player_data.memory_shards = int(data.get("memoryShards", player_data.memory_shards))
	player_data.scooper_level = int(data.get("scooperLevel", player_data.scooper_level))
	player_data.scooper_exp = int(data.get("scooperExp", player_data.scooper_exp))
	player_data.total_pulls = int(data.get("totalPulls", player_data.total_pulls))
	player_data.free_pull_count = int(data.get("freePullCount", player_data.free_pull_count))
	player_data.last_free_pull_date = String(data.get("lastFreePullDate", player_data.last_free_pull_date))
	player_data.current_stage = int(data.get("currentStage", player_data.current_stage))
	current_global_stage = player_data.current_stage
	player_data.save()


func _save_auth_session() -> void:
	var file := FileAccess.open(AUTH_SESSION_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify({
		"api_base_url": api_base_url,
		"session": auth_session,
	}, "\t"))
	file.close()


func _delete_auth_session_file() -> void:
	_delete_file_if_exists(AUTH_SESSION_PATH)


func _delete_file_if_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		return

	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute_path)


func _delete_files_in_directory(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return

	var directory := DirAccess.open(path)
	if directory == null:
		return

	directory.list_dir_begin()
	while true:
		var entry_name := directory.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == ".." or directory.current_is_dir():
			continue
		directory.remove(entry_name)
	directory.list_dir_end()

## 目前擁有的貓咪 ID 列表（從 player_data 讀取）
func get_owned_cats() -> Array:
	if player_data == null:
		return ["milk_cat"]
	return player_data.owned_cat_ids


## 新增擁有的貓咪並建立快取（扭蛋後呼叫）
func add_owned_cat(cat_id: String) -> void:
	var added := false
	if not player_data.owned_cat_ids.has(cat_id):
		player_data.owned_cat_ids.append(cat_id)
		added = true
	if not _player_cat_cache.has(cat_id):
		_player_cat_cache[cat_id] = PlayerCatData.load_or_default(cat_id)
	if added:
		refresh_achievements()

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

# ── BOSS 關卡全域設定 ─────────────────────────
var boss_config: Dictionary = {}

# ── 競技場狀態 ────────────────────────────────
var arena_data: PlayerArenaData
## 競技場當前對戰資訊（進入戰鬥前設定，戰鬥結束後讀取）
var arena_opponent: Dictionary = {}   # { player_id, player_name, score, rank_name, defense_team }
var arena_config: Dictionary = {}     # 由 config 讀取的競技場設定（賽季日期、購買費用等）

# ── 掛機系統 ──────────────────────────────────
var idle_config: Dictionary = {}
var _idle_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ── 裝備系統 ──────────────────────────────────
var equipment_config: Dictionary = {}
var _equip_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var special_ability_config: Dictionary = {}
var _special_ability_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var memory_config: Dictionary = {}
var treasure_config: Dictionary = {}
var shop_bundle_config: Dictionary = {}
var achievement_config: Dictionary = {}
var _pending_achievement_popup_titles: Array[String] = []
var _achievement_popup_scheduled: bool = false

# ── 常數 ──────────────────────────────────────
func _ready() -> void:
	player_data = PlayerData.load_or_default()
	current_global_stage = player_data.current_stage
	dungeon_config = _load_json("res://data/default/dungeon_config.json")
	boss_config = _load_json("res://data/default/boss_config.json")
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
	# 掛機系統：載入設定與隨機種子
	idle_config = _load_json("res://data/default/idle_config.json")
	_idle_rng.randomize()
	# 裝備系統：載入設定與隨機種子
	equipment_config = _load_json("res://data/default/equipment_config.json")
	_equip_rng.randomize()
	special_ability_config = _load_json("res://data/default/ability_config.json")
	_special_ability_rng.randomize()
	memory_config = _load_json("res://data/default/memory_config.json")
	treasure_config = _load_json("res://data/default/treasure_config.json")
	shop_bundle_config = _load_json("res://data/default/shop_bundle_config.json")
	achievement_config = _load_json("res://data/default/achievement_config.json")
	# 首次啟動時初始化計時起點（往後只有領取時才會重設）
	if player_data.last_quit_time == 0:
		player_data.last_quit_time = Time.get_unix_time_from_system()
		player_data.save()
	refresh_achievements(false)


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


# ── 成就系統 ──────────────────────────────────

func get_all_achievements() -> Array:
	return achievement_config.get("items", [])


func get_achievement_item(achievement_id: String) -> Dictionary:
	for item: Dictionary in get_all_achievements():
		if item.get("id", "") == achievement_id:
			return item
	return {}


func get_achievement_state(achievement_id: String) -> Dictionary:
	var state: Dictionary = player_data.achievement_states.get(achievement_id, {})
	return {
		"completed": bool(state.get("completed", false)),
		"claimed": bool(state.get("claimed", false)),
		"completed_at": String(state.get("completed_at", "")),
		"claimed_at": String(state.get("claimed_at", "")),
	}


func get_achievement_display_groups() -> Dictionary:
	refresh_achievements(false)
	var active: Array = []
	var claimed: Array = []
	var claimable_count := 0
	var completed_count := 0
	var items: Array = get_all_achievements()
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var entry := _build_achievement_display_entry(item, i)
		if entry.is_empty():
			continue
		if entry.get("completed", false):
			completed_count += 1
		if entry.get("claimable", false):
			claimable_count += 1
		if entry.get("claimed", false):
			claimed.append(entry)
		else:
			active.append(entry)

	active.sort_custom(Callable(self, "_compare_active_achievement_entries"))
	claimed.sort_custom(Callable(self, "_compare_claimed_achievement_entries"))

	return {
		"active": active,
		"claimed": claimed,
		"claimable_count": claimable_count,
		"completed_count": completed_count,
		"total_count": items.size(),
	}


func has_unclaimed_achievements() -> bool:
	return get_unclaimed_achievement_count() > 0


func get_unclaimed_achievement_count() -> int:
	refresh_achievements(false)
	var count := 0
	for item: Dictionary in get_all_achievements():
		var state := get_achievement_state(item.get("id", ""))
		if state.get("completed", false) and not state.get("claimed", false):
			count += 1
	return count


func refresh_achievements(show_notifications: bool = true) -> Array[String]:
	var newly_completed: Array[String] = []
	var changed := false
	for item: Dictionary in get_all_achievements():
		var achievement_id: String = item.get("id", "")
		if achievement_id == "":
			continue
		var state := get_achievement_state(achievement_id)
		if state.get("completed", false):
			continue
		var progress := get_achievement_progress(item)
		if not progress.get("met", false):
			continue
		state["completed"] = true
		state["completed_at"] = _now_string()
		player_data.achievement_states[achievement_id] = state
		newly_completed.append(item.get("name", achievement_id))
		changed = true

	if changed:
		player_data.save()
		emit_signal("achievements_changed")

	if show_notifications and not newly_completed.is_empty():
		_queue_achievement_popup(newly_completed)

	return newly_completed


func claim_achievement(achievement_id: String) -> Dictionary:
	var item := get_achievement_item(achievement_id)
	if item.is_empty():
		return { "success": false, "error": "找不到成就" }

	refresh_achievements(false)
	var state := get_achievement_state(achievement_id)
	if not state.get("completed", false):
		return { "success": false, "error": "成就尚未達成" }
	if state.get("claimed", false):
		return { "success": false, "error": "成就獎勵已領取" }

	for reward: Dictionary in item.get("rewards", []):
		var validation := _validate_achievement_reward(reward)
		if not validation.get("success", false):
			return validation

	var grant_results: Array = []
	for reward: Dictionary in item.get("rewards", []):
		var grant_result := _grant_achievement_reward(reward)
		if not grant_result.get("success", false):
			return grant_result
		grant_results.append(grant_result)

	state["claimed"] = true
	state["claimed_at"] = _now_string()
	player_data.achievement_states[achievement_id] = state
	player_data.save()
	emit_signal("achievements_changed")
	return {
		"success": true,
		"achievement": item,
		"granted": grant_results,
	}


func get_achievement_progress(item: Dictionary) -> Dictionary:
	var condition_type: String = item.get("condition_type", "")
	var target: int = int(item.get("condition_value", 0))
	var current := 0
	var condition_text := ""

	match condition_type:
		"scooper_level_reached":
			current = player_data.scooper_level
			condition_text = "鏟屎官達到 Lv.%d" % target
		"any_cat_level_reached":
			current = _get_highest_cat_level()
			condition_text = "任意主子達到 Lv.%d" % target
		"any_cat_rank_reached":
			current = _get_highest_cat_rank()
			condition_text = "任意主子達到 +%d 品階" % target
		"equipment_owned_count_reached":
			current = player_data.equipments.size()
			condition_text = "持有 %d 件裝備" % target
		"stage_reached":
			current = current_global_stage
			condition_text = "推關進度到達 Stage %d" % target
		"memory_unlocked_count_reached":
			current = player_data.unlocked_memory_ids.size()
			condition_text = "解鎖 %d 張回憶" % target
		"owned_cat_count_reached":
			current = player_data.owned_cat_ids.size()
			condition_text = "持有 %d 隻主子" % target
		_:
			condition_text = "未知條件"

	return {
		"current": current,
		"target": target,
		"met": current >= target,
		"condition_text": condition_text,
		"progress_text": "進度：%d / %d" % [mini(current, target), target],
	}


func format_achievement_rewards(rewards: Array) -> String:
	var parts: Array[String] = []
	for reward: Dictionary in rewards:
		parts.append(_format_achievement_reward(reward))
	return "、".join(parts)


func _build_achievement_display_entry(item: Dictionary, config_order: int) -> Dictionary:
	var achievement_id: String = item.get("id", "")
	if achievement_id == "":
		return {}
	var state := get_achievement_state(achievement_id)
	var progress := get_achievement_progress(item)
	var entry: Dictionary = item.duplicate(true)
	entry["config_order"] = config_order
	entry["completed"] = state.get("completed", false)
	entry["claimed"] = state.get("claimed", false)
	entry["completed_at"] = state.get("completed_at", "")
	entry["claimed_at"] = state.get("claimed_at", "")
	entry["claimable"] = state.get("completed", false) and not state.get("claimed", false)
	entry["condition_text"] = progress.get("condition_text", "")
	entry["progress_current"] = progress.get("current", 0)
	entry["progress_target"] = progress.get("target", 0)
	entry["progress_text"] = progress.get("progress_text", "")
	entry["reward_text"] = format_achievement_rewards(item.get("rewards", []))
	return entry


func _compare_active_achievement_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_claimable: bool = bool(a.get("claimable", false))
	var b_claimable: bool = bool(b.get("claimable", false))
	if a_claimable != b_claimable:
		return a_claimable and not b_claimable
	return int(a.get("config_order", 0)) < int(b.get("config_order", 0))


func _compare_claimed_achievement_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_time: String = a.get("claimed_at", "")
	var b_time: String = b.get("claimed_at", "")
	if a_time == b_time:
		return int(a.get("config_order", 0)) < int(b.get("config_order", 0))
	return a_time > b_time


func _get_highest_cat_level() -> int:
	var highest := 0
	for cat_id: String in player_data.owned_cat_ids:
		highest = maxi(highest, get_player_cat(cat_id).cat_food_level)
	return highest


func _get_highest_cat_rank() -> int:
	var highest := 0
	for cat_id: String in player_data.owned_cat_ids:
		highest = maxi(highest, get_player_cat(cat_id).rank)
	return highest


func _validate_achievement_reward(reward: Dictionary) -> Dictionary:
	match reward.get("type", ""):
		"special_ability":
			if _get_special_ability_item(reward.get("id", "")).is_empty():
				return { "success": false, "error": "成就獎勵的特殊能力不存在" }
		"treasure":
			if _get_treasure_item(reward.get("id", "")).is_empty():
				return { "success": false, "error": "成就獎勵的寶藏不存在" }
		_:
			pass
	return { "success": true }


func _grant_achievement_reward(reward: Dictionary) -> Dictionary:
	var reward_type: String = reward.get("type", "")
	match reward_type:
		"gold":
			var gold_amount: int = int(reward.get("amount", 0))
			player_data.gold += gold_amount
			return { "success": true, "text": "金幣 ×%d" % gold_amount }
		"diamonds":
			var diamond_amount: int = int(reward.get("amount", 0))
			player_data.diamonds += diamond_amount
			return { "success": true, "text": "鑽石 ×%d" % diamond_amount }
		"cat_food":
			var cat_food_amount: int = int(reward.get("amount", 0))
			player_data.cat_food += cat_food_amount
			return { "success": true, "text": "貓糧 ×%d" % cat_food_amount }
		"special_cat_food":
			var special_food_amount: int = int(reward.get("amount", 0))
			player_data.special_cat_food += special_food_amount
			return { "success": true, "text": "特殊乾糧 ×%d" % special_food_amount }
		"whisker_shards":
			var whisker_amount: int = int(reward.get("amount", 0))
			player_data.whisker_shards += whisker_amount
			return { "success": true, "text": "鬍鬚 ×%d" % whisker_amount }
		"memory_shards":
			var memory_amount: int = int(reward.get("amount", 0))
			player_data.memory_shards += memory_amount
			return { "success": true, "text": "回憶碎片 ×%d" % memory_amount }
		"trap_cages":
			var cage_amount: int = int(reward.get("amount", 0))
			player_data.trap_cages += cage_amount
			return { "success": true, "text": "誘捕籠 ×%d" % cage_amount }
		"special_ability":
			var ability_id: String = reward.get("id", "")
			if player_data.special_ability_ids.has(ability_id):
				var compensation: Dictionary = reward.get("duplicate_compensation", {})
				if compensation.is_empty():
					return { "success": true, "text": "特殊能力 %s（已擁有）" % ability_id }
				var compensation_result := _grant_achievement_reward(compensation)
				if not compensation_result.get("success", false):
					return compensation_result
				var ability_name: String = _get_special_ability_item(ability_id).get("name", ability_id)
				return {
					"success": true,
					"text": "%s 已擁有，改發 %s" % [ability_name, compensation_result.get("text", "")],
				}
			var ability_result := grant_special_ability(ability_id)
			if not ability_result.get("success", false):
				return ability_result
			return {
				"success": true,
				"text": "特殊能力「%s」" % ability_result.get("ability", {}).get("name", ability_id),
			}
		"treasure":
			var treasure_id: String = reward.get("id", "")
			var quantity: int = int(reward.get("amount", 1))
			var treasure_result := grant_treasure(treasure_id, quantity)
			if not treasure_result.get("success", false):
				return treasure_result
			return {
				"success": true,
				"text": "寶藏「%s」×%d" % [
					treasure_result.get("treasure", {}).get("name", treasure_id),
					quantity,
				],
			}
		_:
			return { "success": false, "error": "不支援的成就獎勵類型：%s" % reward_type }


func _format_achievement_reward(reward: Dictionary) -> String:
	match reward.get("type", ""):
		"gold":
			return "金幣 ×%d" % int(reward.get("amount", 0))
		"diamonds":
			return "鑽石 ×%d" % int(reward.get("amount", 0))
		"cat_food":
			return "貓糧 ×%d" % int(reward.get("amount", 0))
		"special_cat_food":
			return "特殊乾糧 ×%d" % int(reward.get("amount", 0))
		"whisker_shards":
			return "鬍鬚 ×%d" % int(reward.get("amount", 0))
		"memory_shards":
			return "回憶碎片 ×%d" % int(reward.get("amount", 0))
		"trap_cages":
			return "誘捕籠 ×%d" % int(reward.get("amount", 0))
		"special_ability":
			var ability_id: String = reward.get("id", "")
			var ability_name: String = _get_special_ability_item(ability_id).get("name", ability_id)
			return "特殊能力「%s」" % ability_name
		"treasure":
			var treasure_id: String = reward.get("id", "")
			var treasure_name: String = _get_treasure_item(treasure_id).get("name", treasure_id)
			return "寶藏「%s」×%d" % [treasure_name, int(reward.get("amount", 1))]
		_:
			return str(reward)


func _queue_achievement_popup(titles: Array[String]) -> void:
	for title: String in titles:
		if not _pending_achievement_popup_titles.has(title):
			_pending_achievement_popup_titles.append(title)
	if _achievement_popup_scheduled:
		return
	_achievement_popup_scheduled = true
	call_deferred("_flush_achievement_popup")


func _flush_achievement_popup() -> void:
	_achievement_popup_scheduled = false
	if _pending_achievement_popup_titles.is_empty():
		return
	var titles := _pending_achievement_popup_titles.duplicate()
	_pending_achievement_popup_titles.clear()
	var lines: Array[String] = []
	if titles.size() == 1:
		lines.append("已達成成就：")
	else:
		lines.append("有 %d 項成就達成：" % titles.size())
	for title: String in titles:
		lines.append("• %s" % title)
	lines.append("")
	lines.append("可前往「鏟屎官 > 成就」領取獎勵。")
	DialogManager.show_info("成就達成", "\n".join(lines))

## 每個 Boss 關含幾個普通遭遇戰（不含 Boss）

# boss_config 存取輔助
func _get_boss_config_int(key: String, default_val: int) -> int:
	return int(boss_config.get(key, default_val))
func _get_boss_config_float(key: String, default_val: float) -> float:
	return float(boss_config.get(key, default_val))
func _get_boss_config_array(key: String, default_val: Array) -> Array:
	return boss_config.get(key, default_val)

# ── 進度輔助計算 ───────────────────────────────

## 當前 Boss 關序號（全局，1 起算）
## 1-1 ~ 1-BOSS 均屬第 1 個 Boss 關，2-1 ~ 2-BOSS 屬第 2 個，以此類推
func get_boss_stage_number() -> int:
	var enc = _get_boss_config_int("encounters_per_boss_stage", 4)
	return ceili(float(current_global_stage) / float(enc + 1))

## 當前遭遇戰索引（1~4 = 普通遭遇戰，5 = Boss）
func get_encounter_index() -> int:
	var enc = _get_boss_config_int("encounters_per_boss_stage", 4)
	return ((current_global_stage - 1) % (enc + 1)) + 1

## 是否目前是 Boss 戰
func is_current_boss() -> bool:
	var enc = _get_boss_config_int("encounters_per_boss_stage", 4)
	return get_encounter_index() == enc + 1

## Boss 關在當前區域內的序號（1~BOSS_STAGES_PER_ZONE）
func get_zone_boss_stage() -> int:
	var bsz = _get_boss_config_int("boss_stages_per_zone", 10)
	return ((get_boss_stage_number() - 1) % bsz) + 1

## 當前所在領地的區域序號（1~ZONES_PER_TERRITORY）
func get_zone_in_territory() -> int:
	var bsz = _get_boss_config_int("boss_stages_per_zone", 10)
	var zpt = _get_boss_config_int("zones_per_territory", 5)
	var stages_per_territory: int = bsz * zpt
	return (((get_boss_stage_number() - 1) % stages_per_territory) / bsz) + 1

## 當前領地序號（1 起算）
func get_territory_number() -> int:
	var bsz = _get_boss_config_int("boss_stages_per_zone", 10)
	var zpt = _get_boss_config_int("zones_per_territory", 5)
	var stages_per_territory: int = bsz * zpt
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
	var arr = _get_boss_config_array("territory_names", ["", "新手", "普通", "高級", "進階", "菁英"])
	if t < arr.size():
		return arr[t]
	return "領地%d" % t

func _get_zone_suffix() -> String:
	var z: int = get_zone_in_territory()
	var arr = _get_boss_config_array("zone_suffixes", ["", "I", "II", "III", "IV", "V"])
	if z < arr.size():
		return arr[z]
	return "%d" % z

# ── 難度計算 ───────────────────────────────────

## 回傳當前關卡的敵方數值倍率
## 普通遭遇戰：每關 +0.3% 複利成長（Stage 軌道）
## Boss 關：每個 Boss +2% 複利成長（Boss 軌道，與 Stage 分開計算）
func get_difficulty_multiplier() -> float:
	var stage_growth = _get_boss_config_float("stage_growth", 1.003)
	var boss_growth = _get_boss_config_float("boss_growth", 1.02)
	if is_current_boss():
		# Boss 軌道：依全局 Boss 關序號計算
		# 1-BOSS = ×1.020, 10-BOSS = ×1.219, 50-BOSS = ×2.692
		return pow(boss_growth, get_boss_stage_number())
	else:
		# Stage 軌道：依全局關卡編號計算（1-1 = ×1.000）
		# 1-4 = ×1.009, 10-4 = ×1.136, 50-4 = ×2.064
		return pow(stage_growth, current_global_stage - 1)

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
	refresh_achievements()
	player_data.save()  # 即時寫入，確保強制退出時不遺失進度

## Boss 失敗後退回該 Boss 關的第 4 遭遇戰，顯示「挑戰 Boss」按鈕
func on_boss_fail() -> void:
	var bs: int = get_boss_stage_number()
	var enc = _get_boss_config_int("encounters_per_boss_stage", 4)
	current_global_stage = (bs - 1) * (enc + 1) + enc
	boss_available = true

## 玩家手動挑戰 Boss（從第 4 遭遇戰跳到 Boss）
func challenge_boss() -> void:
	var bs: int = get_boss_stage_number()
	var enc = _get_boss_config_int("encounters_per_boss_stage", 4)
	current_global_stage = bs * (enc + 1)

# ── 技能延遲 ──────────────────────────────────

func get_delay(slot_index: int) -> int:
	return skill_delays.get(slot_index, 0)

func set_delay(slot_index: int, delay: int) -> void:
	skill_delays[slot_index] = clampi(delay, 0, 9)


# ── 掛機系統 ──────────────────────────────────

## 當前累積的離線秒數（已套最大上限），即時計算
func get_idle_elapsed_seconds() -> int:
	if player_data.last_quit_time == 0:
		return 0
	var now: int = Time.get_unix_time_from_system()
	var idle_summary := get_special_ability_summary()
	var max_hours: float = float(idle_config.get("max_idle_hours", 8)) \
			+ float(idle_summary.get("idle_max_hours_bonus", 0))
	var max_seconds: int = int(max_hours * 3600.0)
	return mini(now - player_data.last_quit_time, max_seconds)

## 可領取的完整分鐘數（即時計算）
func get_idle_complete_minutes() -> int:
	return get_idle_elapsed_seconds() / 60

## 是否已累積至少一分鐘可領取（即時計算）
func has_pending_idle_rewards() -> bool:
	return get_idle_complete_minutes() >= 1

## 計算並回傳當前可領取的獎勵明細（即時計算，不修改任何狀態）
func get_pending_idle_rewards() -> Dictionary:
	var minutes := get_idle_complete_minutes()
	if minutes < 1:
		return {}
	var rates := IdleSystem.calculate_rates(idle_config, current_global_stage, player_data.scooper_level)
	var rewards := IdleSystem.calculate_rewards(minutes, rates)
	var multiplier: float = float(get_special_ability_summary().get("idle_reward_multiplier", 1.0))
	if multiplier > 1.0:
		for key: String in rewards.keys():
			rewards[key] = int(float(rewards[key]) * multiplier)
	var poop_multiplier := 1.0 + get_treasure_idle_poop_bonus()
	if poop_multiplier > 1.0:
		rewards["poop"] = int(float(rewards.get("poop", 0)) * poop_multiplier)
	return rewards

## 領取掛機獎勵：加入玩家資源，並將 last_quit_time 往前撥回餘秒（保留不足一分鐘的累積）
func claim_idle_rewards() -> void:
	if not has_pending_idle_rewards():
		return
	var elapsed_seconds := get_idle_elapsed_seconds()
	var remainder_seconds := elapsed_seconds % 60
	var rewards := get_pending_idle_rewards()
	player_data.gold           += rewards.get("gold",     0)
	player_data.poop_count     += rewards.get("poop",     0)
	player_data.cat_food       += rewards.get("cat_food", 0)
	player_data.diamonds       += rewards.get("diamonds", 0)
	player_data.whisker_shards += rewards.get("whiskers", 0)
	# 將餘秒保留至下次計算
	player_data.last_quit_time = Time.get_unix_time_from_system() - remainder_seconds
	player_data.save()

## 鏟一次屎：扣除一個屎堆，隨機產出並存檔
## 回傳產出 dict（exp, memory_shards, whiskers），poop_count 為 0 時回傳空 dict
func scoop_poop() -> Dictionary:
	if player_data.poop_count <= 0:
		return {}
	player_data.poop_count -= 1
	var result := IdleSystem.scoop_once(idle_config, _idle_rng, player_data.scooper_level)
	player_data.scooper_exp    += result.get("exp",           0)
	player_data.memory_shards  += result.get("memory_shards", 0)
	player_data.whisker_shards += result.get("whiskers",      0)
	_check_scooper_level_up()
	refresh_achievements()
	player_data.save()
	return result


## 檢查並處理鏟屎官升等（可能連續升多級）
func _check_scooper_level_up() -> void:
	var base: int = int(idle_config.get("scooper_exp_per_level", 10))
	var threshold := (player_data.scooper_level + 1) * base
	while player_data.scooper_exp >= threshold:
		player_data.scooper_exp -= threshold
		player_data.scooper_level += 1
		threshold = (player_data.scooper_level + 1) * base

## 應用程式暫停或關閉時，即時存檔（不重置掛機計時）
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		player_data.save()


func _get_special_ability_item(ability_id: String) -> Dictionary:
	var items: Array = special_ability_config.get("items", [])
	for item: Dictionary in items:
		if item.get("id", "") == ability_id:
			return item
	return {}


func get_special_ability_summary() -> Dictionary:
	return SpecialAbilitySystem.summarize(player_data.special_ability_ids, special_ability_config)


func get_owned_special_abilities() -> Array:
	var result: Array = []
	for ability_id: String in player_data.special_ability_ids:
		var item := _get_special_ability_item(ability_id)
		if not item.is_empty():
			result.append(item)
	return result


func get_unowned_special_abilities() -> Array:
	var result: Array = []
	var owned := player_data.special_ability_ids
	for item: Dictionary in special_ability_config.get("items", []):
		if not owned.has(item.get("id", "")):
			result.append(item)
	return result


func get_special_ability_draw_cost() -> int:
	return 0


func get_special_ability_speed_cap() -> float:
	return float(get_special_ability_summary().get("battle_speed_cap", 1.0))


func can_skip_battle() -> bool:
	return bool(get_special_ability_summary().get("battle_skip_unlocked", false))


func draw_special_ability(_use_free_ticket: bool) -> Dictionary:
	return { "success": false, "error": "特殊能力無法抽取，請透過活動、成就或商城禮包取得" }


func grant_special_ability(ability_id: String) -> Dictionary:
	var item := _get_special_ability_item(ability_id)
	if item.is_empty():
		return { "success": false, "error": "特殊能力不存在" }
	if player_data.special_ability_ids.has(ability_id):
		return { "success": false, "error": "特殊能力已擁有" }
	player_data.special_ability_ids.append(ability_id)
	player_data.save()
	return {
		"success": true,
		"ability": item,
	}


# ── 回憶系統 ──────────────────────────────────

func _get_memory_item(memory_id: String) -> Dictionary:
	var items: Array = memory_config.get("items", [])
	for item: Dictionary in items:
		if item.get("id", "") == memory_id:
			return item
	return {}


func get_all_memories() -> Array:
	return memory_config.get("items", [])


func get_memory_item(memory_id: String) -> Dictionary:
	return _get_memory_item(memory_id)


func is_memory_unlocked(memory_id: String) -> bool:
	return player_data.unlocked_memory_ids.has(memory_id)


func unlock_memory(memory_id: String) -> Dictionary:
	var item := _get_memory_item(memory_id)
	if item.is_empty():
		return { "success": false, "error": "找不到回憶" }
	if is_memory_unlocked(memory_id):
		return { "success": false, "error": "回憶已解鎖" }
	var cost: int = int(item.get("unlock_cost", 0))
	if player_data.memory_shards < cost:
		return { "success": false, "error": "回憶碎片不足（需要 %d）" % cost }
	player_data.memory_shards -= cost
	player_data.unlocked_memory_ids.append(memory_id)
	refresh_achievements()
	player_data.save()
	return {
		"success": true,
		"memory": item,
	}


func get_memory_bonuses() -> Array:
	var result: Array = []
	for memory_id: String in player_data.unlocked_memory_ids:
		var item := _get_memory_item(memory_id)
		if item.is_empty():
			continue
		result.append({
			"target": item.get("bonus_target", "all"),
			"stat": item.get("bonus_stat", ""),
			"value": float(item.get("bonus_value", 0.0)),
		})
	return result


func get_combat_bonuses() -> Array:
	var result: Array = []
	result.append_array(get_equipment_bonuses())
	result.append_array(get_memory_bonuses())
	result.append_array(get_treasure_combat_bonuses())
	return result


func apply_player_combat_bonuses(data: CatData) -> void:
	for bonus: Dictionary in get_combat_bonuses():
		var target: String = bonus.get("target", "all")
		if target != "all" and target != data.cat_type:
			continue
		var value: float = float(bonus.get("value", 0.0))
		match bonus.get("stat", ""):
			"atk_percent":
				data.atk = int(data.atk * (1.0 + value))
			"def_percent":
				data.defense = int(data.defense * (1.0 + value))
			"max_hp_percent":
				data.max_hp = int(data.max_hp * (1.0 + value))
			"crit_rate":
				data.set_meta("crit_rate", minf(float(data.get_meta("crit_rate", 0.0)) + value, 1.0))
			"crit_damage":
				data.set_meta("crit_damage_bonus",
						maxf(0.0, float(data.get_meta("crit_damage_bonus", 0.0)) + value))
			"damage_reduction":
				data.set_meta("damage_reduction_bonus",
						minf(float(data.get_meta("damage_reduction_bonus", 0.0)) + value, 0.9))
			"cooldown_reduction":
				data.set_meta("cdr", minf(float(data.get_meta("cdr", 0.0)) + value, 0.5))


# ── 寶藏系統 ──────────────────────────────────

func _get_treasure_item(treasure_id: String) -> Dictionary:
	var items: Array = treasure_config.get("items", [])
	for item: Dictionary in items:
		if item.get("id", "") == treasure_id:
			return item
	return {}


func get_all_treasures() -> Array:
	return treasure_config.get("items", [])


func get_treasure_item(treasure_id: String) -> Dictionary:
	return _get_treasure_item(treasure_id)


func get_treasure_state(treasure_id: String) -> Dictionary:
	return player_data.treasures.get(treasure_id, {})


func get_treasure_quantity(treasure_id: String) -> int:
	return int(get_treasure_state(treasure_id).get("quantity", 0))


func has_treasure(treasure_id: String) -> bool:
	return get_treasure_quantity(treasure_id) > 0


func get_owned_treasures() -> Array:
	var result: Array = []
	for treasure_id: String in player_data.treasures.keys():
		var item := _get_treasure_item(treasure_id)
		if item.is_empty():
			continue
		var state: Dictionary = player_data.treasures.get(treasure_id, {})
		var quantity: int = int(state.get("quantity", 0))
		if quantity <= 0:
			continue
		var entry := item.duplicate(true)
		entry["quantity"] = quantity
		entry["latest_obtained_at"] = state.get("latest_obtained_at", "")
		result.append(entry)
	result.sort_custom(func(a, b):
		return String(a.get("latest_obtained_at", "")) > String(b.get("latest_obtained_at", ""))
	)
	return result


func get_treasure_idle_poop_bonus() -> float:
	var total := 0.0
	for effect: Dictionary in get_treasure_effects():
		if effect.get("stat", "") == "idle_poop_percent":
			total += float(effect.get("value", 0.0))
	return total


func get_treasure_combat_bonuses() -> Array:
	var result: Array = []
	for effect: Dictionary in get_treasure_effects():
		if _is_combat_bonus_stat(effect.get("stat", "")):
			result.append(effect)
	return result


func get_treasure_effects() -> Array:
	var result: Array = []
	for treasure_id: String in player_data.treasures.keys():
		var item := _get_treasure_item(treasure_id)
		if item.is_empty():
			continue
		var quantity: int = int(player_data.treasures.get(treasure_id, {}).get("quantity", 0))
		if quantity <= 0:
			continue
		var effects: Array = item.get("effects", [])
		for _i in range(quantity):
			for effect: Dictionary in effects:
				result.append({
					"target": effect.get("target", "all"),
					"stat": effect.get("stat", ""),
					"value": float(effect.get("value", 0.0)),
					"treasure_id": treasure_id,
				})
	return result


func grant_treasure(treasure_id: String, quantity: int = 1) -> Dictionary:
	var item := _get_treasure_item(treasure_id)
	if item.is_empty():
		return { "success": false, "error": "找不到寶藏" }
	if quantity <= 0:
		return { "success": false, "error": "數量必須大於 0" }
	var state: Dictionary = player_data.treasures.get(treasure_id, {})
	state["quantity"] = int(state.get("quantity", 0)) + quantity
	state["latest_obtained_at"] = _now_string()
	player_data.treasures[treasure_id] = state
	player_data.save()
	return {
		"success": true,
		"treasure": item,
		"quantity": quantity,
		"total_quantity": state["quantity"],
	}


# ── 商城禮包 ──────────────────────────────────

func _get_shop_bundle_item(bundle_id: String) -> Dictionary:
	var items: Array = shop_bundle_config.get("items", [])
	for item: Dictionary in items:
		if item.get("id", "") == bundle_id:
			return item
	return {}


func get_shop_bundle_categories() -> Array:
	return shop_bundle_config.get("categories", [])


func get_shop_bundles_by_category(category_id: String) -> Array:
	var result: Array = []
	for item: Dictionary in shop_bundle_config.get("items", []):
		if item.get("category", "") == category_id:
			result.append(item)
	return result


func get_bundle_purchase_count(bundle_id: String) -> int:
	return int(player_data.bundle_purchase_counts.get(bundle_id, 0))


func can_purchase_bundle(bundle_id: String) -> Dictionary:
	var item := _get_shop_bundle_item(bundle_id)
	if item.is_empty():
		return { "success": false, "error": "找不到禮包" }
	var purchase_limit: int = int(item.get("purchase_limit", 1))
	var purchased: int = get_bundle_purchase_count(bundle_id)
	if purchase_limit >= 0 and purchased >= purchase_limit:
		return { "success": false, "error": "已達購買上限" }
	var diamond_cost: int = int(item.get("diamond_cost", 0))
	if player_data.diamonds < diamond_cost:
		return { "success": false, "error": "鑽石不足（需要 %d）" % diamond_cost }
	return { "success": true, "bundle": item }


func purchase_shop_bundle(bundle_id: String) -> Dictionary:
	var check := can_purchase_bundle(bundle_id)
	if not check.get("success", false):
		return check
	var item: Dictionary = check.get("bundle", {})
	var rewards: Array = item.get("rewards", [])
	var granted: Array = []
	player_data.diamonds -= int(item.get("diamond_cost", 0))
	player_data.bundle_purchase_counts[bundle_id] = get_bundle_purchase_count(bundle_id) + 1
	for reward: Dictionary in rewards:
		if reward.get("type", "") != "treasure":
			continue
		var treasure_id: String = reward.get("id", "")
		var quantity: int = int(reward.get("quantity", 1))
		var result := grant_treasure(treasure_id, quantity)
		if result.get("success", false):
			granted.append({
				"id": treasure_id,
				"name": result.get("treasure", {}).get("name", treasure_id),
				"quantity": quantity,
				"total_quantity": result.get("total_quantity", quantity),
			})
	player_data.save()
	return {
		"success": true,
		"bundle": item,
		"granted": granted,
		"purchase_count": get_bundle_purchase_count(bundle_id),
	}


# ── 裝備系統 ──────────────────────────────────

## 根據 ID 取得裝備設定項目（找不到回傳空 dict）
func _get_equip_item(equip_id: String) -> Dictionary:
	var items: Array = equipment_config.get("items", [])
	for item: Dictionary in items:
		if item.get("id", "") == equip_id:
			return item
	return {}


## 是否已購買指定裝備
func is_equipment_owned(equip_id: String) -> bool:
	return player_data.equipments.has(equip_id)


## 購買裝備。回傳 "" 表示成功，否則回傳錯誤訊息
func buy_equipment(equip_id: String) -> String:
	var item := _get_equip_item(equip_id)
	if item.is_empty():
		return "找不到裝備"
	if is_equipment_owned(equip_id):
		return "已擁有此裝備"
	var unlock_level: int = item.get("unlock_level", 1)
	if player_data.scooper_level < unlock_level:
		return "鏟屎官等級不足（需要 Lv.%d）" % unlock_level
	var cost: int = item.get("buy_cost", 0)
	if player_data.gold < cost:
		return "金幣不足（需要 %d）" % cost
	player_data.gold -= cost
	player_data.equipments[equip_id] = {
		"level": 0, "exp": 0, "broken": false, "sick_cat_id": ""
	}
	refresh_achievements()
	player_data.save()
	return ""


## 升級裝備。回傳結果 dict：
## { success, exp, leveled_up, broken, sick_cat_id, error }
func upgrade_equipment(equip_id: String) -> Dictionary:
	var item := _get_equip_item(equip_id)
	if item.is_empty():
		return { "success": false, "error": "找不到裝備" }
	if not is_equipment_owned(equip_id):
		return { "success": false, "error": "尚未購買此裝備" }
	var state: Dictionary = player_data.equipments[equip_id]
	if state.get("broken", false):
		return { "success": false, "error": "裝備已損壞，請先修復" }
	if state.get("sick_cat_id", "") != "":
		return { "success": false, "error": "有貓咪生病，請先就醫" }
	var current_level: int = state.get("level", 0)
	var max_level: int = player_data.scooper_level
	if current_level >= max_level:
		return { "success": false, "error": "已達升級上限（Lv.%d）" % max_level }
	var cost: int = item.get("upgrade_cost", 300)
	if player_data.gold < cost:
		return { "success": false, "error": "金幣不足（需要 %d）" % cost }

	player_data.gold -= cost

	# 隨機取得 0~3 EXP（依設定加權）
	var exp_weights: Array = item.get("exp_weights", [20, 40, 30, 10])
	var exp_gained: int = _roll_weighted(exp_weights)

	# 損壞判定
	var now_broken: bool = _equip_rng.randf() < float(item.get("damage_chance", 0.1))

	# 生病判定（損壞時不觸發）
	var sick_cat_id := ""
	if not now_broken:
		var illness_chance: float = float(item.get("illness_chance", 0.05))
		if _equip_rng.randf() < illness_chance:
			var cat_ids: Array = player_data.owned_cat_ids
			if not cat_ids.is_empty():
				sick_cat_id = cat_ids[_equip_rng.randi() % cat_ids.size()]

	# 套用 EXP 並檢查升等
	var exp_per_level: int = int(equipment_config.get("exp_per_level", 10))
	state["exp"] = state.get("exp", 0) + exp_gained
	var leveled_up := false
	while state.get("level", 0) < max_level and state.get("exp", 0) >= exp_per_level:
		state["exp"] -= exp_per_level
		state["level"] = state.get("level", 0) + 1
		leveled_up = true

	state["broken"] = now_broken
	if sick_cat_id != "":
		state["sick_cat_id"] = sick_cat_id

	player_data.equipments[equip_id] = state
	player_data.save()

	return {
		"success":    true,
		"exp":        exp_gained,
		"leveled_up": leveled_up,
		"broken":     now_broken,
		"sick_cat_id": sick_cat_id,
		"error":      ""
	}


## 修復損壞裝備。回傳 "" 表示成功，否則回傳錯誤訊息
func repair_equipment(equip_id: String) -> String:
	var item := _get_equip_item(equip_id)
	if item.is_empty():
		return "找不到裝備"
	if not is_equipment_owned(equip_id):
		return "尚未購買此裝備"
	var state: Dictionary = player_data.equipments[equip_id]
	if not state.get("broken", false):
		return "裝備未損壞"
	var cost: int = item.get("repair_cost", 200)
	if player_data.gold < cost:
		return "金幣不足（需要 %d）" % cost
	player_data.gold -= cost
	state["broken"] = false
	player_data.equipments[equip_id] = state
	player_data.save()
	return ""


## 替生病的貓咪就醫。回傳 "" 表示成功，否則回傳錯誤訊息
func heal_sick_cat(equip_id: String) -> String:
	var item := _get_equip_item(equip_id)
	if item.is_empty():
		return "找不到裝備"
	if not is_equipment_owned(equip_id):
		return "尚未購買此裝備"
	var state: Dictionary = player_data.equipments[equip_id]
	if state.get("sick_cat_id", "") == "":
		return "沒有貓咪需要就醫"
	var cost: int = item.get("heal_cost", 500)
	if player_data.gold < cost:
		return "金幣不足（需要 %d）" % cost
	player_data.gold -= cost
	state["sick_cat_id"] = ""
	player_data.equipments[equip_id] = state
	player_data.save()
	return ""


## 取得所有有效裝備加成（非損壞、等級 > 0）
## 回傳 Array[Dictionary]，每項：{ target, stat, value }
func get_equipment_bonuses() -> Array:
	var result: Array = []
	var items: Array = equipment_config.get("items", [])
	for item: Dictionary in items:
		var equip_id: String = item.get("id", "")
		if not is_equipment_owned(equip_id):
			continue
		var state: Dictionary = player_data.equipments.get(equip_id, {})
		if state.get("broken", false):
			continue
		var level: int = state.get("level", 0)
		if level <= 0:
			continue
		var bonus_per_level: float = float(item.get("bonus_per_level", 0.0))
		result.append({
			"target": item.get("bonus_target", "all"),
			"stat":   item.get("bonus_stat",   ""),
			"value":  bonus_per_level * level,
		})
	return result


func _is_combat_bonus_stat(stat: String) -> bool:
	return stat in [
		"atk_percent",
		"def_percent",
		"max_hp_percent",
		"crit_rate",
		"crit_damage",
		"damage_reduction",
		"cooldown_reduction",
	]


func _now_string() -> String:
	var dict: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		dict.get("year", 0),
		dict.get("month", 0),
		dict.get("day", 0),
		dict.get("hour", 0),
		dict.get("minute", 0),
		dict.get("second", 0),
	]


## 加權隨機：weights 為整數陣列，回傳命中的索引（0-based）
func _roll_weighted(weights: Array) -> int:
	var total := 0
	for w in weights:
		total += int(w)
	if total <= 0:
		return 0
	var roll := _equip_rng.randi() % total
	var cumulative := 0
	for i in range(weights.size()):
		cumulative += int(weights[i])
		if roll < cumulative:
			return i
	return 0
