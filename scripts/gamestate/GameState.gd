extends Node

## Global AutoLoad state.
## FileUtils manages user:// cleanup, CacheIO manages bootstrap caches, BossStage handles boss-stage rules.
const FileUtils = preload("res://scripts/gamestate/GameStateFileUtils.gd")
const CacheIO   = preload("res://scripts/gamestate/GameStateCacheIO.gd")
const BossStage = preload("res://scripts/gamestate/GameStateBossStage.gd")

const AUTH_SESSION_PATH := "user://auth_session.json"
const PLAYER_DATA_PATH := PlayerData.SAVE_PATH

var api_base_url: String = ""
var auth_session: Dictionary = {}

signal achievements_changed
signal chat_connection_state_changed(state: String)
signal chat_messages_changed(channel_key: String)
signal chat_unread_changed(channel_key: String, count: int)

# Primary player state and runtime caches.
var player_data: PlayerData
## Player cat enhancement cache. key = cat_id.
var _player_cat_cache: Dictionary = {}
var chat_connection_state: String = "disconnected"
var chat_world_messages: Array = []
var chat_system_messages: Array = []
var chat_guild_messages: Array = []
var chat_unread_counts: Dictionary = {"system": 0, "world": 0, "guild": 0}
var chat_last_received_seq_by_channel: Dictionary = {"system": 0, "world": 0, "guild": 0}
var chat_last_snapshot_at_unix: int = 0
var chat_guild_context: Dictionary = {}
var chat_endpoint: String = ""
var chat_token: String = ""
var chat_guild_available: bool = false


func set_auth_session(base_url: String, session: Dictionary) -> void:
	api_base_url = base_url
	auth_session = session.duplicate(true)
	_save_auth_session()


func clear_auth_session() -> void:
	api_base_url = ""
	auth_session = {}
	_delete_auth_session_file()


func clear_persisted_player_state() -> void:
	FileUtils.delete_file_if_exists(PLAYER_DATA_PATH)
	FileUtils.delete_files_in_directory(CacheIO.CONFIG_CACHE_DIR)

	player_data = PlayerData.new()
	_player_cat_cache = {}
	player_team = []
	skill_delays = {}
	player_cats_data = []
	teams_data = {}
	mail_summary_data = {}
	mail_list_data = []
	selected_mail_data = {}
	current_global_stage = 1
	boss_available = false
	dungeon_battle_id = ""
	dungeon_battle_key = ""
	dungeon_battle_level = 1
	dungeon_data = PlayerDungeonData.new()
	dungeon_overview_data = []
	arena_data = PlayerArenaData.new()
	arena_opponent = {}
	arena_overview_data = {}
	gacha_data = {}
	shop_data = {}
	clear_chat_state()


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

	var persisted_base_url = (payload.get("api_base_url") if payload.get("api_base_url") != null else "").strip_edges()
	if persisted_base_url == "":
		return false

	var session: Dictionary = session_variant if session_variant is Dictionary else {}
	api_base_url = persisted_base_url
	auth_session = session.duplicate(true)
	return not auth_session.is_empty()


func get_access_token() -> String:
	return str(auth_session.get("accessToken", "")).strip_edges()


func get_refresh_token() -> String:
	return str(auth_session.get("refreshToken", "")).strip_edges()


func apply_player_bootstrap(data: Dictionary) -> void:
	if player_data == null:
		player_data = PlayerData.load_or_default()

	player_data.account = data.get("account") if data.get("account") != null else player_data.account
	player_data.display_name = data.get("displayName") if data.get("displayName") != null else player_data.display_name
	player_data.player_public_id = data.get("playerPublicId") if data.get("playerPublicId") != null else player_data.player_public_id
	player_data.player_name = data.get("playerName") if data.get("playerName") != null else player_data.player_name
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
	player_data.last_free_pull_date = data.get("lastFreePullDate") if data.get("lastFreePullDate") != null else player_data.last_free_pull_date
	player_data.current_stage = int(data.get("currentStage", player_data.current_stage))
	current_global_stage = player_data.current_stage
	update_mail_summary(data.get("mailSummary", {}))
	var mail_inbox: Variant = data.get("mailInbox", [])
	if mail_inbox is Array:
		update_mail_list(mail_inbox)
		update_selected_mail({})
	player_data.save()

	var cat_cat: Variant = data.get("catCatalog", [])
	cat_catalog = cat_cat if cat_cat is Array else []
	CacheIO.save_catalog("cat_catalog", cat_catalog)

	var active_skill_cat: Variant = data.get("activeSkillCatalog", [])
	active_skill_catalog = active_skill_cat if active_skill_cat is Array else []
	CacheIO.save_catalog("active_skill_catalog", active_skill_catalog)

	var passive_skill_cat: Variant = data.get("passiveSkillCatalog", [])
	passive_skill_catalog = passive_skill_cat if passive_skill_cat is Array else []
	CacheIO.save_catalog("passive_skill_catalog", passive_skill_catalog)

	var gacha_cfg: Variant = data.get("gachaConfig", {})
	gacha_config = gacha_cfg if gacha_cfg is Dictionary else {}
	CacheIO.save_config("gacha_static", gacha_config)

	var dungeon_cfg: Variant = data.get("dungeonConfig", {})
	dungeon_config = dungeon_cfg if dungeon_cfg is Dictionary else {}
	CacheIO.save_config("dungeon_static", dungeon_config)

	var boss_cfg: Variant = data.get("bossConfig", {})
	boss_config = boss_cfg if boss_cfg is Dictionary else {}
	CacheIO.save_config("boss_static", boss_config)

	var idle_cfg: Variant = data.get("idleConfig", {})
	idle_config = idle_cfg if idle_cfg is Dictionary else {}
	CacheIO.save_config("idle_static", idle_config)

	var arena_cfg: Variant = data.get("arenaConfig", {})
	arena_config = arena_cfg if arena_cfg is Dictionary else {}
	CacheIO.save_config("arena_static", arena_config)

	_rebuild_cached_static_configs()

	# ── 解析並快取 catalog 資料 ──
	var eq_cat: Variant = data.get("equipmentCatalog", [])
	scooper_equipment_catalog = eq_cat if eq_cat is Array else []
	CacheIO.save_catalog("equipment_catalog", scooper_equipment_catalog)

	var mem_cat: Variant = data.get("memoryCatalog", [])
	scooper_memory_catalog = mem_cat if mem_cat is Array else []
	CacheIO.save_catalog("memory_catalog", scooper_memory_catalog)

	var tr_cat: Variant = data.get("treasureCatalog", [])
	scooper_treasure_catalog = tr_cat if tr_cat is Array else []
	CacheIO.save_catalog("treasure_catalog", scooper_treasure_catalog)

	var ach_cat: Variant = data.get("achievementCatalog", [])
	scooper_achievement_catalog = ach_cat if ach_cat is Array else []
	CacheIO.save_catalog("achievement_catalog", scooper_achievement_catalog)

	var ab_cat: Variant = data.get("abilityCatalog", [])
	scooper_ability_catalog = ab_cat if ab_cat is Array else []
	CacheIO.save_catalog("ability_catalog", scooper_ability_catalog)

	# ── 解析並快取 live scooper data ──
	var s_profile: Variant = data.get("scooperProfile", {})
	if s_profile is Dictionary and not (s_profile as Dictionary).is_empty():
		update_scooper_profile(s_profile)
	var s_equip: Variant = data.get("scooperEquipment", [])
	if s_equip is Array:
		update_scooper_equipment(s_equip)
	var s_ability: Variant = data.get("scooperAbilities", [])
	if s_ability is Array:
		update_scooper_ability(s_ability)
	var s_memory: Variant = data.get("scooperMemories", [])
	if s_memory is Array:
		update_scooper_memory(s_memory)
	var s_treasure: Variant = data.get("scooperTreasures", [])
	if s_treasure is Array:
		update_scooper_treasure(s_treasure)
	var s_achievement: Variant = data.get("scooperAchievements", [])
	if s_achievement is Array:
		update_scooper_achievement(s_achievement)

	# ── Config 資料（貓咪 + 隊伍）──
	var p_cats: Variant = data.get("playerCats", [])
	if p_cats is Array:
		update_player_cats(p_cats)
	var p_enhance: Variant = data.get("enhanceCats", [])
	if p_enhance is Array:
		update_enhance(p_enhance)
	var p_teams: Variant = data.get("playerTeams", [])
	if p_teams is Array:
		update_player_teams(p_teams)
		var boss_team: Dictionary = teams_data.get("Boss", {})
		var boss_members: Array = boss_team.get("members", [])
		player_team = boss_members.map(func(m: Dictionary) -> int: return int(m.get("playerCatId", 0)))
	apply_dungeon_overview(data)
	var gacha_overview: Variant = data.get("gachaOverview", {})
	if gacha_overview is Dictionary and not (gacha_overview as Dictionary).is_empty():
		update_gacha(gacha_overview)
	var shop_overview: Variant = data.get("shopOverview", {})
	if shop_overview is Dictionary and not (shop_overview as Dictionary).is_empty():
		update_shop(shop_overview)
	var chat_summary_variant: Variant = data.get("chatSummary", {})
	if chat_summary_variant is Dictionary:
		apply_chat_summary(chat_summary_variant)


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
	FileUtils.delete_file_if_exists(AUTH_SESSION_PATH)

## 目前擁有的貓咪 ID 列表（從 player_data 讀取）
func get_owned_cats() -> Array:
	if not enhance_data.is_empty():
		var result: Array = []
		for item: Variant in enhance_data:
			if item is Dictionary:
				var cat_file_id := get_cat_file_id_by_catalog_id(int(item.get("catCatalogId", 0)))
				if cat_file_id != "":
					result.append(cat_file_id)
		if not result.is_empty():
			return result
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
var player_team: Array = []
var skill_delays: Dictionary = {}  ## DEPRECATED: 延遲改由 teams_data 管理

# ── Config 快取（Bootstrap 時寫入 user://config/）──────────────────────
## 玩家擁有的貓咪清單（來自後端 PlayerCat，含 playerCatId、catalogId、displayName 等）
var player_cats_data: Array = []
var enhance_data: Array = []
## 所有隊伍設定（key = teamType 字串，value = teamResponse Dict）
var teams_data: Dictionary = {}

# ── 關卡進度（單一數字記錄）──────────────────────
## 全局關卡編號（1 起算），單一數字即可還原所有進度資訊
var current_global_stage: int = 1
## Boss 失敗後為 true，顯示「挑戰 Boss」按鈕
var boss_available: bool = false

# ── 地下城戰鬥狀態 ────────────────────────────
var dungeon_battle_id: String = ""
var dungeon_battle_key: String = ""
var dungeon_battle_level: int = 1
var dungeon_data: PlayerDungeonData
var dungeon_overview_data: Array = []
## 地下城全域設定（啟動時載入一次，供所有場景共用）
var dungeon_config: Dictionary = {}

# ── BOSS 關卡全域設定 ─────────────────────────
var boss_config: Dictionary = {}

# ── 競技場狀態 ────────────────────────────────
var arena_data: PlayerArenaData
var arena_opponent: Dictionary = {}
var arena_overview_data: Dictionary = {}
var arena_config: Dictionary = {}

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
var cat_catalog: Array = []
var active_skill_catalog: Array = []
var passive_skill_catalog: Array = []
var gacha_config: Dictionary = {}
var _cat_file_map: Dictionary = {}

# ── API 目錄快取（Bootstrap 時寫入 user://catalog/）──────
var scooper_equipment_catalog: Array = []
var scooper_memory_catalog: Array = []
var scooper_treasure_catalog: Array = []
var scooper_achievement_catalog: Array = []
var scooper_ability_catalog: Array = []

# ── 即時 API 資料（場景拉取後存入）──────────────────
var scooper_profile_data: Dictionary = {}
var scooper_equipment_data: Array = []
var scooper_ability_data: Array = []
var scooper_memory_data: Array = []
var scooper_treasure_data: Array = []
var scooper_achievement_data: Array = []
var gacha_data: Dictionary = {}
var shop_data: Dictionary = {}
var mail_summary_data: Dictionary = {}
var mail_list_data: Array = []
var selected_mail_data: Dictionary = {}


func _ready() -> void:
	player_data = PlayerData.load_or_default()
	current_global_stage = player_data.current_stage
	cat_catalog = CacheIO.load_catalog("cat_catalog")
	active_skill_catalog = CacheIO.load_catalog("active_skill_catalog")
	passive_skill_catalog = CacheIO.load_catalog("passive_skill_catalog")
	dungeon_config = CacheIO.load_config_dict("dungeon_static")
	boss_config = CacheIO.load_config_dict("boss_static")
	arena_config = CacheIO.load_config_dict("arena_static")
	idle_config = CacheIO.load_config_dict("idle_static")
	gacha_config = CacheIO.load_config_dict("gacha_static")
	dungeon_data = PlayerDungeonData.new()
	update_dungeon_overview(_load_dungeon_cache_array())
	for cat_id: String in player_data.owned_cat_ids:
		_player_cat_cache[cat_id] = PlayerCatData.load_or_default(cat_id)
	arena_data = PlayerArenaData.new()
	arena_data.season_end_date = arena_config.get("season_end_date", arena_data.season_end_date)
	arena_overview_data = CacheIO.load_config_dict("arena")
	if not player_data.boss_team.is_empty():
		player_team = player_data.boss_team.duplicate()
	_idle_rng.randomize()
	_equip_rng.randomize()
	_special_ability_rng.randomize()
	scooper_equipment_catalog = CacheIO.load_catalog("equipment_catalog")
	scooper_memory_catalog = CacheIO.load_catalog("memory_catalog")
	scooper_treasure_catalog = CacheIO.load_catalog("treasure_catalog")
	scooper_achievement_catalog = CacheIO.load_catalog("achievement_catalog")
	scooper_ability_catalog = CacheIO.load_catalog("ability_catalog")
	_rebuild_cached_static_configs()
	scooper_profile_data = CacheIO.load_scooper_dict("profile")
	scooper_equipment_data = CacheIO.load_scooper_array("equipment")
	scooper_ability_data = CacheIO.load_scooper_array("ability")
	scooper_memory_data = CacheIO.load_scooper_array("memory")
	scooper_treasure_data = CacheIO.load_scooper_array("treasure")
	scooper_achievement_data = CacheIO.load_scooper_array("achievement")
	gacha_data = CacheIO.load_config_dict("gacha")
	shop_data = CacheIO.load_config_dict("shop")
	shop_bundle_config = {"bundles": shop_data.get("bundles", [])}
	player_cats_data = CacheIO.load_config_array("player_cats")
	update_enhance(_load_enhance_cache_array())
	var cached_teams := CacheIO.load_config_array("teams")
	if not cached_teams.is_empty():
		update_player_teams(cached_teams)
		var boss_team: Dictionary = teams_data.get("Boss", {})
		var boss_members: Array = boss_team.get("members", [])
		if not boss_members.is_empty():
			player_team = boss_members.map(func(m: Dictionary) -> int: return int(m.get("playerCatId", 0)))
	if player_data.last_quit_time == 0:
		player_data.last_quit_time = Time.get_unix_time_from_system()
		player_data.save()
	refresh_achievements(false)


func _rebuild_cached_static_configs() -> void:
	_rebuild_cat_file_map()
	equipment_config = _build_equipment_config()
	special_ability_config = _build_special_ability_config()
	memory_config = _build_memory_config()
	treasure_config = _build_treasure_config()
	achievement_config = _build_achievement_config()
	shop_bundle_config = {"bundles": shop_data.get("bundles", [])}


func _build_equipment_config() -> Dictionary:
	var items: Array = []
	for item: Variant in scooper_equipment_catalog:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		items.append({
			"id": str(row.get("equipmentId", "")),
			"display_name": str(row.get("displayName", "")),
			"unlock_level": int(row.get("unlockLevel", 0)),
			"purchase_cost": int(row.get("purchaseCost", 0)),
			"repair_cost": int(row.get("repairCost", 0)),
			"treat_cost": int(row.get("treatCost", 0)),
			"bonus_stat": _to_snake_case(str(row.get("bonusStat", ""))),
			"bonus_target": _to_snake_case(str(row.get("bonusTarget", "All"))),
			"bonus_per_level": float(row.get("bonusPerLevel", 0.0)),
		})
	return {"items": items}


func _build_special_ability_config() -> Dictionary:
	var items: Array = []
	for item: Variant in scooper_ability_catalog:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		items.append({
			"id": str(row.get("abilityId", "")),
			"display_name": str(row.get("displayName", "")),
			"description": str(row.get("description", "")),
			"effect_type": _to_snake_case(str(row.get("effectType", ""))),
			"value": row.get("effectValue", 0),
			"source_text": str(row.get("sourceText", "")),
		})
	return {"items": items}


func _build_memory_config() -> Dictionary:
	var items: Array = []
	for item: Variant in scooper_memory_catalog:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		items.append({
			"id": str(row.get("memoryId", "")),
			"display_name": str(row.get("displayName", "")),
			"description": str(row.get("description", "")),
			"image_path": str(row.get("imagePath", "")),
			"unlock_cost": int(row.get("unlockCost", 0)),
			"bonus_stat": _to_snake_case(str(row.get("bonusStatType", ""))),
			"bonus_target": _to_snake_case(str(row.get("bonusTarget", "All"))),
			"bonus_value": float(row.get("bonusValue", 0.0)),
		})
	return {"items": items}


func _build_treasure_config() -> Dictionary:
	var items: Array = []
	for item: Variant in scooper_treasure_catalog:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var effects: Array = []
		for effect_variant: Variant in row.get("effects", []):
			if not (effect_variant is Dictionary):
				continue
			var effect: Dictionary = effect_variant
			effects.append({
				"target": _to_snake_case(str(effect.get("targetScope", "All"))),
				"stat": _to_snake_case(str(effect.get("statType", ""))),
				"value": float(effect.get("value", 0.0)),
			})
		items.append({
			"id": str(row.get("treasureId", "")),
			"display_name": str(row.get("displayName", "")),
			"description": str(row.get("description", "")),
			"source_text": str(row.get("sourceText", "")),
			"effects": effects,
		})
	return {"items": items}


func _build_achievement_config() -> Dictionary:
	var items: Array = []
	for item: Variant in scooper_achievement_catalog:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		items.append({
			"id": str(row.get("achievementId", "")),
			"display_name": str(row.get("displayName", "")),
			"category_type": _to_snake_case(str(row.get("categoryType", ""))),
			"condition_type": _to_snake_case(str(row.get("conditionType", ""))),
			"condition_value": int(row.get("conditionValue", 0)),
			"rewards": row.get("rewards", []),
		})
	return {"items": items}


func _to_snake_case(value: String) -> String:
	var result := ""
	for i in range(value.length()):
		var ch := value[i]
		if i > 0 and ch >= "A" and ch <= "Z":
			result += "_"
		result += ch.to_lower()
	return result


func get_cat_catalog_item(cat_id: String) -> Dictionary:
	for item: Variant in cat_catalog:
		if item is Dictionary and str(item.get("id", "")) == cat_id:
			return item
	return {}


func get_skill_catalog_item(skill_id: String) -> Dictionary:
	for item: Variant in passive_skill_catalog:
		if item is Dictionary and str(item.get("id", "")) == skill_id:
			return item
	for item: Variant in active_skill_catalog:
		if item is Dictionary and str(item.get("id", "")) == skill_id:
			return item
	return {}


# ── Scooper 快取更新 ────────────────────────────────

## 更新鏟屎官 profile 快取（記憶體 + 本地檔案）
func update_scooper_profile(data: Dictionary) -> void:
	scooper_profile_data = data
	CacheIO.save_scooper("profile", data)

## 更新裝備快取（記憶體 + 本地檔案）
func update_scooper_equipment(data: Array) -> void:
	scooper_equipment_data = data
	CacheIO.save_scooper("equipment", data)

## 更新特殊能力快取（記憶體 + 本地檔案）
func update_scooper_ability(data: Array) -> void:
	scooper_ability_data = data
	CacheIO.save_scooper("ability", data)

## 更新回憶快取（記憶體 + 本地檔案）
func update_scooper_memory(data: Array) -> void:
	scooper_memory_data = data
	CacheIO.save_scooper("memory", data)

## 更新寶藏快取（記憶體 + 本地檔案）
func update_scooper_treasure(data: Array) -> void:
	scooper_treasure_data = data
	CacheIO.save_scooper("treasure", data)

## 更新成就快取（記憶體 + 本地檔案）
func update_scooper_achievement(data: Array) -> void:
	scooper_achievement_data = data
	CacheIO.save_scooper("achievement", data)


func update_arena(data: Dictionary) -> void:
	arena_overview_data = data.duplicate(true)
	CacheIO.save_config("arena", arena_overview_data)
	if player_data == null:
		return
	if arena_overview_data.get("playerName") != null:
		player_data.player_name = str(arena_overview_data.get("playerName", player_data.player_name))
	if arena_overview_data.get("playerPublicId") != null:
		player_data.player_public_id = str(arena_overview_data.get("playerPublicId", player_data.player_public_id))
	player_data.diamonds = int(arena_overview_data.get("diamonds", player_data.diamonds))
	player_data.trap_cages = int(arena_overview_data.get("trapCages", player_data.trap_cages))
	player_data.cat_food = int(arena_overview_data.get("catFood", player_data.cat_food))
	player_data.special_cat_food = int(arena_overview_data.get("specialCatFood", player_data.special_cat_food))
	player_data.save()


func update_mail_summary(data: Dictionary) -> void:
	mail_summary_data = {
		"unreadCount": int(data.get("unreadCount", 0)),
		"claimableCount": int(data.get("claimableCount", 0)),
		"totalCount": int(data.get("totalCount", 0)),
	}


func update_mail_list(data: Array) -> void:
	mail_list_data = data.duplicate(true)


func update_selected_mail(data: Dictionary) -> void:
	selected_mail_data = data.duplicate(true)
	if not selected_mail_data.is_empty():
		_merge_mail_into_list(selected_mail_data)


func apply_wallet_snapshot(data: Dictionary) -> void:
	player_data.gold = int(data.get("gold", player_data.gold))
	player_data.diamonds = int(data.get("diamonds", player_data.diamonds))
	player_data.trap_points = int(data.get("trapPoints", player_data.trap_points))
	player_data.cat_food = int(data.get("catFood", player_data.cat_food))
	player_data.special_cat_food = int(data.get("specialCatFood", player_data.special_cat_food))
	player_data.trap_cages = int(data.get("trapCages", player_data.trap_cages))
	player_data.poop_count = int(data.get("poopCount", player_data.poop_count))
	player_data.memory_shards = int(data.get("memoryShards", player_data.memory_shards))
	player_data.whisker_shards = int(data.get("whiskerShards", player_data.whisker_shards))
	player_data.save()


func has_mail_red_dot() -> bool:
	return int(mail_summary_data.get("unreadCount", 0)) > 0 or int(mail_summary_data.get("claimableCount", 0)) > 0


func get_mail_badge_text() -> String:
	var total := int(mail_summary_data.get("unreadCount", 0)) + int(mail_summary_data.get("claimableCount", 0))
	if total <= 0:
		return ""
	return "99+" if total > 99 else str(total)


func mark_mail_read_local(mail_id: int) -> void:
	for item: Dictionary in mail_list_data:
		if int(item.get("mailId", 0)) != mail_id:
			continue
		if not bool(item.get("isRead", false)):
			item["isRead"] = true
			update_mail_summary({
				"unreadCount": maxi(0, int(mail_summary_data.get("unreadCount", 0)) - 1),
				"claimableCount": int(mail_summary_data.get("claimableCount", 0)),
				"totalCount": int(mail_summary_data.get("totalCount", 0)),
			})
		break
	if int(selected_mail_data.get("mailId", 0)) == mail_id:
		selected_mail_data["isRead"] = true


func mark_mail_claimed_local(mail_id: int) -> void:
	for item: Dictionary in mail_list_data:
		if int(item.get("mailId", 0)) != mail_id:
			continue
		item["isClaimed"] = true
		item["status"] = "Claimed"
		break
	if int(selected_mail_data.get("mailId", 0)) == mail_id:
		selected_mail_data["isClaimed"] = true
		selected_mail_data["status"] = "Claimed"
		for attachment: Dictionary in selected_mail_data.get("attachments", []):
			attachment["isClaimed"] = true


func mark_mail_claimed_many_local(mail_ids: Array) -> void:
	for mail_id: Variant in mail_ids:
		mark_mail_claimed_local(int(mail_id))


func _merge_mail_into_list(mail_data: Dictionary) -> void:
	var mail_id := int(mail_data.get("mailId", 0))
	if mail_id <= 0:
		return
	for i in range(mail_list_data.size()):
		var item: Dictionary = mail_list_data[i]
		if int(item.get("mailId", 0)) != mail_id:
			continue
		item["title"] = mail_data.get("title", item.get("title", ""))
		item["previewText"] = mail_data.get("previewText", item.get("previewText", ""))
		item["isRead"] = bool(mail_data.get("isRead", item.get("isRead", false)))
		item["isClaimed"] = bool(mail_data.get("isClaimed", item.get("isClaimed", false)))
		item["status"] = mail_data.get("status", item.get("status", ""))
		mail_list_data[i] = item
		return


# ?? Config ???????? ConfigScene ??????????

func _save_config_cache(cache_name: String, data: Variant) -> void:
	CacheIO.save_config(cache_name, data)

func _load_config_cache_array(cache_name: String) -> Array:
	return CacheIO.load_config_array(cache_name)


func _save_enhance_cache(data: Array) -> void:
	CacheIO.save_config("enhance", data)


func _load_enhance_cache_array() -> Array:
	return CacheIO.load_config_array("enhance")


func _save_dungeon_cache(data: Array) -> void:
	CacheIO.save_config("dungeon", data)


func _load_dungeon_cache_array() -> Array:
	return CacheIO.load_config_array("dungeon")


func _save_gacha_cache(data: Dictionary) -> void:
	CacheIO.save_config("gacha", data)


func _save_shop_cache(data: Dictionary) -> void:
	CacheIO.save_config("shop", data)


## ?????????????? + ?????
func update_player_cats(data: Array) -> void:
	player_cats_data = data
	CacheIO.save_config("player_cats", data)
	var owned_cat_ids: Array = []
	for item: Variant in data:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		if not bool(row.get("isOwned", false)):
			continue
		var cat_file_id := get_cat_file_id_by_catalog_id(int(row.get("catCatalogId", 0)))
		if cat_file_id != "" and not owned_cat_ids.has(cat_file_id):
			owned_cat_ids.append(cat_file_id)
	if owned_cat_ids.is_empty():
		owned_cat_ids = ["milk_cat"]
	player_data.owned_cat_ids = owned_cat_ids
	player_data.save()


func update_gacha(data: Dictionary) -> void:
	gacha_data = data.duplicate(true)
	_save_gacha_cache(gacha_data)
	if player_data == null:
		return
	player_data.diamonds = int(gacha_data.get("diamonds", player_data.diamonds))
	player_data.trap_cages = int(gacha_data.get("trapCages", player_data.trap_cages))
	player_data.total_pulls = int(gacha_data.get("totalPulls", player_data.total_pulls))
	player_data.free_pull_count = int(gacha_data.get("freePullCount", player_data.free_pull_count))
	if gacha_data.get("lastFreePullDate") != null:
		player_data.last_free_pull_date = str(gacha_data.get("lastFreePullDate", player_data.last_free_pull_date))
	player_data.save()


func update_shop(data: Dictionary) -> void:
	shop_data = data.duplicate(true)
	shop_bundle_config = {"bundles": shop_data.get("bundles", [])}
	_save_shop_cache(shop_data)
	if player_data == null:
		return
	player_data.diamonds = int(shop_data.get("diamonds", player_data.diamonds))
	player_data.trap_cages = int(shop_data.get("trapCages", player_data.trap_cages))
	var purchase_counts: Dictionary = {}
	var bundles_variant: Variant = shop_data.get("bundles", [])
	if bundles_variant is Array:
		for item: Variant in bundles_variant:
			if item is Dictionary:
				var bundle: Dictionary = item
				purchase_counts[str(bundle.get("bundleId", ""))] = int(bundle.get("purchaseCount", 0))
	player_data.bundle_purchase_counts = purchase_counts
	player_data.save()


func update_enhance(data: Array) -> void:
	enhance_data = data
	_save_enhance_cache(data)

	for item: Variant in data:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var cat_file_id := get_cat_file_id_by_catalog_id(int(row.get("catCatalogId", 0)))
		if cat_file_id == "":
			continue
		var player_cat: PlayerCatData = get_player_cat(cat_file_id)
		player_cat.cat_id = cat_file_id
		player_cat.cat_food_level = int(row.get("catFoodLevel", player_cat.cat_food_level))
		player_cat.rank = int(row.get("rank", player_cat.rank))
		player_cat.cat_shards = int(row.get("catShards", player_cat.cat_shards))
		player_cat.special_food_points = {
			"hp": int(row.get("hpPoints", 0)),
			"atk": int(row.get("atkPoints", 0)),
			"def": int(row.get("defPoints", 0)),
		}

		for cat_row: Variant in player_cats_data:
			if cat_row is Dictionary and int(cat_row.get("playerCatId", -1)) == int(row.get("playerCatId", -2)):
				cat_row["catFoodLevel"] = player_cat.cat_food_level
				cat_row["rank"] = player_cat.rank
				break
	if not player_cats_data.is_empty():
		CacheIO.save_config("player_cats", player_cats_data)


func apply_enhance_overview(data: Dictionary) -> void:
	player_data.cat_food = int(data.get("catFood", player_data.cat_food))
	player_data.special_cat_food = int(data.get("specialCatFood", player_data.special_cat_food))
	player_data.gold = int(data.get("gold", player_data.gold))
	player_data.diamonds = int(data.get("diamonds", player_data.diamonds))
	var cats: Variant = data.get("cats", [])
	if cats is Array:
		update_enhance(cats)
	player_data.save()


func update_dungeon_overview(data: Array) -> void:
	dungeon_overview_data = data.duplicate(true)
	_save_dungeon_cache(dungeon_overview_data)


func apply_dungeon_overview(data: Dictionary) -> void:
	player_data.cat_food = int(data.get("catFood", player_data.cat_food))
	player_data.special_cat_food = int(data.get("specialCatFood", player_data.special_cat_food))
	player_data.diamonds = int(data.get("diamonds", player_data.diamonds))
	player_data.trap_cages = int(data.get("trapCages", player_data.trap_cages))
	player_data.whisker_shards = int(data.get("whiskerShards", player_data.whisker_shards))
	var dungeons: Variant = data.get("dungeons", [])
	if dungeons is Array:
		update_dungeon_overview(dungeons)
	player_data.save()


func get_dungeon_entry_by_id(dungeon_id: int) -> Dictionary:
	for item: Variant in dungeon_overview_data:
		if item is Dictionary and int(item.get("dungeonId", 0)) == dungeon_id:
			return item
	return {}


func get_dungeon_entry_by_key(dungeon_key: String) -> Dictionary:
	for item: Variant in dungeon_overview_data:
		if item is Dictionary and str(item.get("key", "")) == dungeon_key:
			return item
	return {}


## 更新隊伍快取（記憶體 + 本地檔案）
func update_player_teams(data: Array) -> void:
	teams_data = {}
	for team: Variant in data:
		if team is Dictionary:
			var team_type: String = str(team.get("teamType", ""))
			if team_type != "":
				teams_data[team_type] = team
	CacheIO.save_config("teams", data)


## 取得指定隊伍資料（teamType 如 "Boss", "Dungeon", "ArenaAttack", "ArenaDefense"）
func get_team(team_type: String) -> Dictionary:
	return teams_data.get(team_type, {"teamType": team_type, "members": []})


## 取得可用貓咪列表（已擁有）
func get_config_owned_cats() -> Array:
	return player_cats_data.filter(func(c: Dictionary) -> bool: return bool(c.get("isOwned", false)))


## 取得 playerCatId → 貓咪名稱 的對應（供顯示用）
func get_player_cat_display_name(player_cat_id: int) -> String:
	for cat: Variant in player_cats_data:
		if cat is Dictionary and int(cat.get("playerCatId", -1)) == player_cat_id:
			return str(cat.get("displayName", ""))
	return ""


## playerCatId (int) ? ?? JSON ???? "black_cat"?
## ? player_cats_data ?? catCatalogId ???????
func _rebuild_cat_file_map() -> void:
	_cat_file_map = {}
	for item: Variant in cat_catalog:
		if not (item is Dictionary):
			continue
		var row: Dictionary = item
		var catalog_id := int(row.get("catalog_id", row.get("catalogId", 0)))
		var file_id := str(row.get("id", ""))
		if catalog_id > 0 and file_id != "":
			_cat_file_map[catalog_id] = file_id

func get_cat_file_id(player_cat_id: int) -> String:
	for cat: Variant in player_cats_data:
		if cat is Dictionary and int(cat.get("playerCatId", -1)) == player_cat_id:
			var catalog_id: int = int(cat.get("catCatalogId", 0))
			return str(_cat_file_map.get(catalog_id, ""))
	return ""


func get_cat_file_id_by_catalog_id(cat_catalog_id: int) -> String:
	return str(_cat_file_map.get(cat_catalog_id, ""))


## 取得貓咪強化存檔（找不到時自動建立預設值）
func get_player_cat(cat_id: String) -> PlayerCatData:
	if not _player_cat_cache.has(cat_id):
		_player_cat_cache[cat_id] = PlayerCatData.load_or_default(cat_id)
	return _player_cat_cache[cat_id]


## 儲存所有玩家資料（資源 + 所有貓咪強化 + 地下城進度 + 競技場）
func save_all() -> void:
	player_data.current_stage = current_global_stage
	player_data.save()
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
		"completed_at": str(state.get("completed_at", "")),
		"claimed_at": str(state.get("claimed_at", "")),
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


## DEPRECATED: 成就改由後端管理，但仍保留供 EnhanceScene 呼叫
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
		state["completed_at"] = FileUtils.now_string()
		player_data.achievement_states[achievement_id] = state
		newly_completed.append(item.get("name", achievement_id))
		changed = true

	if changed:
		player_data.save()
		emit_signal("achievements_changed")

	if show_notifications and not newly_completed.is_empty():
		_queue_achievement_popup(newly_completed)

	return newly_completed


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


# ── Boss 關卡進度（委派 BossStage）─────────────
func get_boss_stage_number() -> int:
	return BossStage.get_boss_stage_number(current_global_stage, boss_config)

func get_encounter_index() -> int:
	return BossStage.get_encounter_index(current_global_stage, boss_config)

func is_current_boss() -> bool:
	return BossStage.is_current_boss(current_global_stage, boss_config)

func get_zone_boss_stage() -> int:
	return BossStage.get_zone_boss_stage(current_global_stage, boss_config)

func get_zone_in_territory() -> int:
	return BossStage.get_zone_in_territory(current_global_stage, boss_config)

func get_territory_number() -> int:
	return BossStage.get_territory_number(current_global_stage, boss_config)

func get_level_display() -> String:
	return BossStage.get_level_display(current_global_stage, boss_config)

func get_difficulty_multiplier() -> float:
	return BossStage.get_difficulty_multiplier(current_global_stage, boss_config)

func get_enemy_ids() -> Array:
	return BossStage.get_enemy_ids(current_global_stage, boss_config)


# ── 進度邏輯 ──────────────────────────────────

## 勝利後推進到下一關
func advance_after_win() -> void:
	boss_available = false
	current_global_stage += 1
	player_data.current_stage = current_global_stage
	refresh_achievements()
	player_data.save()

## Boss 失敗後退回該 Boss 關的最後遭遇戰，顯示「挑戰 Boss」按鈕
func on_boss_fail() -> void:
	var bs: int = get_boss_stage_number()
	var enc := int(boss_config.get("encounters_per_boss_stage", 4))
	current_global_stage = (bs - 1) * (enc + 1) + enc
	boss_available = true

## 玩家手動挑戰 Boss（從最後遭遇戰跳到 Boss）
func challenge_boss() -> void:
	var bs: int = get_boss_stage_number()
	var enc := int(boss_config.get("encounters_per_boss_stage", 4))
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
	return floori(float(get_idle_elapsed_seconds()) / 60.0)

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
	player_data.last_quit_time = int(Time.get_unix_time_from_system()) - remainder_seconds
	player_data.save()

## 鏟一次屎：扣除一個屎堆，隨機產出並存檔
## DEPRECATED: 使用 ApiClient.scoop_poop() 取代（仍保留供 battle_scene 呼叫）
func scoop_poop() -> Dictionary:
	push_warning("DEPRECATED: scoop_poop() - use ApiClient.scoop_poop() instead")
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


func get_special_ability_speed_cap() -> float:
	return float(get_special_ability_summary().get("battle_speed_cap", 1.0))


func can_skip_battle() -> bool:
	return bool(get_special_ability_summary().get("battle_skip_unlocked", false))


func clear_chat_state() -> void:
	chat_connection_state = "disconnected"
	chat_world_messages = []
	chat_system_messages = []
	chat_guild_messages = []
	chat_unread_counts = {"system": 0, "world": 0, "guild": 0}
	chat_last_received_seq_by_channel = {"system": 0, "world": 0, "guild": 0}
	chat_last_snapshot_at_unix = 0
	chat_guild_context = {}
	chat_endpoint = ""
	chat_token = ""
	chat_guild_available = false
	emit_signal("chat_connection_state_changed", chat_connection_state)
	for channel_key: String in ["system", "world", "guild"]:
		emit_signal("chat_messages_changed", channel_key)
		emit_signal("chat_unread_changed", channel_key, 0)


func set_chat_connection_state(state: String) -> void:
	if chat_connection_state == state:
		return
	chat_connection_state = state
	emit_signal("chat_connection_state_changed", chat_connection_state)


func apply_chat_summary(summary: Dictionary) -> void:
	chat_endpoint = str(summary.get("chatEndpoint", chat_endpoint))
	chat_token = str(summary.get("chatToken", chat_token))
	chat_guild_available = bool(summary.get("guildChatAvailable", false))
	chat_last_snapshot_at_unix = Time.get_unix_time_from_system()
	if summary.has("unreadSystemCount"):
		chat_unread_counts["system"] = int(summary.get("unreadSystemCount", 0))
		emit_signal("chat_unread_changed", "system", int(chat_unread_counts["system"]))
	if summary.has("unreadWorldCount"):
		chat_unread_counts["world"] = int(summary.get("unreadWorldCount", 0))
		emit_signal("chat_unread_changed", "world", int(chat_unread_counts["world"]))
	if summary.has("unreadGuildCount"):
		chat_unread_counts["guild"] = int(summary.get("unreadGuildCount", 0))
		emit_signal("chat_unread_changed", "guild", int(chat_unread_counts["guild"]))
	if summary.has("worldHistoryCursor"):
		chat_last_received_seq_by_channel["world"] = int(summary.get("worldHistoryCursor", 0))
	if summary.has("guildHistoryCursor"):
		chat_last_received_seq_by_channel["guild"] = int(summary.get("guildHistoryCursor", 0))
	var channels_variant: Variant = summary.get("channels", [])
	if channels_variant is Array:
		for item: Variant in channels_variant:
			if not (item is Dictionary):
				continue
			var channel: Dictionary = item
			var channel_key := str(channel.get("channelKey", "")).to_lower()
			if channel_key == "":
				continue
			chat_unread_counts[channel_key] = int(channel.get("unreadCount", 0))
			chat_last_received_seq_by_channel[channel_key] = int(channel.get("latestSequence", 0))
			emit_signal("chat_unread_changed", channel_key, int(chat_unread_counts[channel_key]))


func get_chat_messages(channel_key: String) -> Array:
	match channel_key:
		"system":
			return chat_system_messages
		"guild":
			return chat_guild_messages
		_:
			return chat_world_messages


func get_chat_latest_sequence(channel_key: String) -> int:
	return int(chat_last_received_seq_by_channel.get(channel_key, 0))


func get_chat_total_unread() -> int:
	return int(chat_unread_counts.get("system", 0)) + int(chat_unread_counts.get("world", 0)) + int(chat_unread_counts.get("guild", 0))


func set_chat_unread_count(channel_key: String, count: int) -> void:
	chat_unread_counts[channel_key] = maxi(0, count)
	emit_signal("chat_unread_changed", channel_key, int(chat_unread_counts[channel_key]))


func append_chat_message_envelope(channel_key: String, sequence: int, message: Dictionary) -> void:
	var target := get_chat_messages(channel_key)
	var message_id := str(message.get("messageId", ""))
	for existing: Dictionary in target:
		if str(existing.get("messageId", "")) == message_id and message_id != "":
			return

	var entry := message.duplicate(true)
	entry["sequence"] = sequence
	target.append(entry)
	target.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sequence", 0)) < int(b.get("sequence", 0))
	)
	_trim_chat_channel(channel_key)
	chat_last_received_seq_by_channel[channel_key] = maxi(int(chat_last_received_seq_by_channel.get(channel_key, 0)), sequence)
	emit_signal("chat_messages_changed", channel_key)


func replace_chat_history(channel_key: String, messages: Array) -> void:
	var target: Array = []
	for item: Variant in messages:
		if not (item is Dictionary):
			continue
		var envelope: Dictionary = item
		var message: Dictionary = envelope.get("message", {})
		var entry := message.duplicate(true)
		entry["sequence"] = int(envelope.get("sequence", 0))
		target.append(entry)
	target.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sequence", 0)) < int(b.get("sequence", 0))
	)
	match channel_key:
		"system":
			chat_system_messages = target
		"guild":
			chat_guild_messages = target
		_:
			chat_world_messages = target
	_trim_chat_channel(channel_key)
	if not target.is_empty():
		chat_last_received_seq_by_channel[channel_key] = int(target[-1].get("sequence", 0))
	emit_signal("chat_messages_changed", channel_key)


func _trim_chat_channel(channel_key: String) -> void:
	var target := get_chat_messages(channel_key)
	var limit := 200 if channel_key == "world" else 100
	var cutoff := Time.get_unix_time_from_system() - (24 * 60 * 60)
	var filtered: Array = []
	for item: Dictionary in target:
		var sent_at := str(item.get("sentAtUtc", ""))
		var unix_time := Time.get_unix_time_from_datetime_string(sent_at) if sent_at != "" else 0
		if unix_time == 0 or unix_time >= cutoff:
			filtered.append(item)
	while filtered.size() > limit:
		filtered.pop_front()
	match channel_key:
		"system":
			chat_system_messages = filtered
		"guild":
			chat_guild_messages = filtered
		_:
			chat_world_messages = filtered


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


func get_memory_bonuses() -> Array:
	if not scooper_memory_data.is_empty():
		var live_result: Array = []
		for item: Dictionary in scooper_memory_data:
			if not bool(item.get("isUnlocked", false)):
				continue
			live_result.append({
				"target": str(item.get("bonusTarget", "All")).to_lower(),
				"stat": str(item.get("bonusStatType", "")),
				"value": float(item.get("bonusValue", 0.0)),
			})
		return live_result
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
		return str(a.get("latest_obtained_at", "")) > str(b.get("latest_obtained_at", ""))
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
	if not scooper_treasure_data.is_empty():
		var result: Array = []
		for item: Dictionary in scooper_treasure_data:
			var quantity: int = int(item.get("quantity", 0))
			if quantity <= 0:
				continue
			var effects: Array = item.get("effects", [])
			for _i in range(quantity):
				for effect: Dictionary in effects:
					result.append({
						"target": str(effect.get("targetElementType", "all")).to_lower(),
						"stat": str(effect.get("statType", "")),
						"value": float(effect.get("value", 0.0)),
					})
		return result
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


## DEPRECATED: 寶藏改由後端管理（仍保留供 purchase_shop_bundle 使用）
func grant_treasure(treasure_id: String, quantity: int = 1) -> Dictionary:
	push_warning("DEPRECATED: grant_treasure() - use backend API instead")
	var item := _get_treasure_item(treasure_id)
	if item.is_empty():
		return { "success": false, "error": "找不到寶藏" }
	if quantity <= 0:
		return { "success": false, "error": "數量必須大於 0" }
	var state: Dictionary = player_data.treasures.get(treasure_id, {})
	state["quantity"] = int(state.get("quantity", 0)) + quantity
	state["latest_obtained_at"] = FileUtils.now_string()
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
	var bundles_variant: Variant = shop_data.get("bundles", [])
	if bundles_variant is Array:
		for item: Variant in bundles_variant:
			if item is Dictionary and str(item.get("bundleId", "")) == bundle_id:
				return item
	return {}


func get_shop_bundle_categories() -> Array:
	var categories_variant: Variant = shop_data.get("categories", [])
	return categories_variant if categories_variant is Array else []


func get_shop_bundles_by_category(category_id: Variant) -> Array:
	var result: Array = []
	var bundles_variant: Variant = shop_data.get("bundles", [])
	if bundles_variant is Array:
		for item: Variant in bundles_variant:
			if item is Dictionary and str(item.get("categoryId", "")) == str(category_id):
				result.append(item)
	return result


func get_bundle_purchase_count(bundle_id: Variant) -> int:
	var bundle := _get_shop_bundle_item(str(bundle_id))
	if not bundle.is_empty():
		return int(bundle.get("purchaseCount", 0))
	return int(player_data.bundle_purchase_counts.get(str(bundle_id), 0))


func can_purchase_bundle(bundle_id: Variant) -> Dictionary:
	var item := _get_shop_bundle_item(str(bundle_id))
	if item.is_empty():
		return { "success": false, "error": "找不到禮包" }
	var purchase_limit: int = int(item.get("purchaseLimit", 1))
	var purchased: int = get_bundle_purchase_count(str(bundle_id))
	if purchase_limit >= 0 and purchased >= purchase_limit:
		return { "success": false, "error": "已達購買上限" }
	var diamond_cost: int = int(item.get("priceAmount", 0))
	if player_data.diamonds < diamond_cost:
		return { "success": false, "error": "鑽石不足（需要 %d）" % diamond_cost }
	return { "success": true, "bundle": item }


func purchase_shop_bundle(_bundle_id: Variant) -> Dictionary:
	push_warning("DEPRECATED: purchase_shop_bundle() 請改用 ApiClient.purchase_shop_bundle()")
	return { "success": false, "error": "請改用後端 API 購買禮包" }


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


## 取得所有有效裝備加成（非損壞、等級 > 0）
func get_equipment_bonuses() -> Array:
	if not scooper_equipment_data.is_empty():
		var live_result: Array = []
		for item: Dictionary in scooper_equipment_data:
			if not bool(item.get("isOwned", false)):
				continue
			if bool(item.get("isBroken", false)):
				continue
			var level: int = int(item.get("level", 0))
			if level <= 0:
				continue
			var bonus_per_level: float = float(item.get("bonusPerLevel", 0.0))
			live_result.append({
				"target": str(item.get("bonusTarget", "All")).to_lower(),
				"stat":   str(item.get("bonusStat", "")),
				"value":  bonus_per_level * level,
			})
		return live_result
	# Fallback: 本地設定
	var fallback_result: Array = []
	for equip_id: String in player_data.equipments.keys():
		var item := _get_equip_item(equip_id)
		if item.is_empty():
			continue
		var state: Dictionary = player_data.equipments.get(equip_id, {})
		if state.get("broken", false):
			continue
		var level: int = int(state.get("level", 0))
		if level <= 0:
			continue
		var bonus_per_level: float = float(item.get("bonus_per_level", 0.0))
		fallback_result.append({
			"target": item.get("bonus_target", "all"),
			"stat":   item.get("bonus_stat", ""),
			"value":  bonus_per_level * level,
		})
	return fallback_result


# ── 私有輔助 ──────────────────────────────────


func _is_combat_bonus_stat(stat: String) -> bool:
	return stat in ["atk_percent", "def_percent", "max_hp_percent",
			"crit_rate", "crit_damage", "damage_reduction", "cooldown_reduction"]
