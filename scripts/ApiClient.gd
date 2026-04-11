extends Node

## 統一 HTTP API 客戶端 autoload，供各場景呼叫後端 Scooper API。
## 使用 HTTPRequest 節點池支援並行請求，內建 401 自動 refresh token 重試。

const POOL_SIZE := 3
const REQUEST_TIMEOUT := 15.0

var _pool: Array[HTTPRequest] = []
var _busy: Array[bool] = []
var _pending_queue: Array[Dictionary] = []
var _refreshing := false
var _refresh_queue: Array[Dictionary] = []


func _ready() -> void:
	for i in range(POOL_SIZE):
		var http := HTTPRequest.new()
		http.timeout = REQUEST_TIMEOUT
		http.request_completed.connect(_on_request_completed.bind(i))
		add_child(http)
		_pool.append(http)
		_busy.append(false)


# ── Public convenience methods ───────────────────────────────

func get_scooper_profile(callback: Callable) -> void:
	_api_get("scooper/profile", callback)


func scoop_poop(count: int, callback: Callable) -> void:
	_api_post("scooper/profile/scoop", {"count": count}, callback)


func get_equipment_list(callback: Callable) -> void:
	_api_get("scooper/equipment", callback)


func purchase_equipment(equipment_id: int, callback: Callable) -> void:
	_api_post("scooper/equipment/purchase", {"equipmentId": equipment_id}, callback)


func upgrade_equipment(equipment_id: int, callback: Callable) -> void:
	_api_post("scooper/equipment/upgrade", {"equipmentId": equipment_id}, callback)


func repair_equipment(equipment_id: int, callback: Callable) -> void:
	_api_post("scooper/equipment/repair", {"equipmentId": equipment_id}, callback)


func treat_equipment(equipment_id: int, callback: Callable) -> void:
	_api_post("scooper/equipment/treat", {"equipmentId": equipment_id}, callback)


func get_abilities(callback: Callable) -> void:
	_api_get("scooper/ability", callback)


func get_memories(callback: Callable) -> void:
	_api_get("scooper/memory", callback)


func unlock_memory(memory_id: int, callback: Callable) -> void:
	_api_post("scooper/memory/unlock", {"memoryId": memory_id}, callback)


func get_treasures(callback: Callable) -> void:
	_api_get("scooper/treasure", callback)


func get_achievements(callback: Callable) -> void:
	_api_get("scooper/achievement", callback)


func claim_achievement(achievement_id: int, callback: Callable) -> void:
	_api_post("scooper/achievement/claim", {"achievementId": achievement_id}, callback)


# ── Config / Team API ────────────────────────────────────────

func get_teams(callback: Callable) -> void:
	_api_get("config/teams", callback)


func replace_team(team_type_key: String, members: Array, callback: Callable) -> void:
	_api_put("config/teams/%s" % team_type_key, {"members": members}, callback)


func get_enhance_overview(callback: Callable) -> void:
	_api_get("enhance", callback)


func get_dungeon_overview(callback: Callable) -> void:
	_api_get("dungeon", callback)


func get_gacha_overview(callback: Callable) -> void:
	_api_get("gacha", callback)


func perform_gacha_pull(pull_count: int, use_free_pull: bool, spend_trap_cages_first: bool, callback: Callable) -> void:
	_api_post("gacha/pull", {
		"pullCount": pull_count,
		"useFreePull": use_free_pull,
		"spendTrapCagesFirst": spend_trap_cages_first,
	}, callback)


func get_shop_overview(callback: Callable) -> void:
	_api_get("shop", callback)


func purchase_trap_cages(trap_cage_count: int, callback: Callable) -> void:
	_api_post("shop/trap-cages/purchase", {
		"trapCageCount": trap_cage_count,
	}, callback)


func purchase_shop_bundle(bundle_id: int, callback: Callable) -> void:
	_api_post("shop/bundles/%d/purchase" % bundle_id, {}, callback)


func get_arena_overview(excluded_opponent_ids: Array, callback: Callable) -> void:
	var path := "arena"
	var filtered_ids: Array[String] = []
	for opponent_id_variant: Variant in excluded_opponent_ids:
		var opponent_id := str(opponent_id_variant).strip_edges()
		if opponent_id != "":
			filtered_ids.append(opponent_id.uri_encode())
	if not filtered_ids.is_empty():
		path += "?excludeOpponentIds=%s" % "&excludeOpponentIds=".join(filtered_ids)
	_api_get(path, callback)


func purchase_arena_tickets(callback: Callable) -> void:
	_api_post("arena/tickets/purchase", {}, callback)


func claim_arena_rank_reward(rank_id: int, callback: Callable) -> void:
	_api_post("arena/rewards/%d/claim" % rank_id, {}, callback)


func complete_arena_battle(opponent_id: String, is_win: bool, callback: Callable) -> void:
	_api_post("arena/opponents/%s/complete" % opponent_id.uri_encode(), {"isWin": is_win}, callback)


func grant_dungeon_ad_ticket(dungeon_id: int, callback: Callable) -> void:
	_api_post("dungeon/%d/ad-ticket" % dungeon_id, {}, callback)


func sweep_dungeon(dungeon_id: int, callback: Callable) -> void:
	_api_post("dungeon/%d/sweep" % dungeon_id, {}, callback)


func complete_dungeon_challenge(dungeon_id: int, target_floor: int, callback: Callable) -> void:
	_api_post("dungeon/%d/challenge" % dungeon_id, {"targetFloor": target_floor}, callback)


func upgrade_cat_food(player_cat_id: int, callback: Callable) -> void:
	_api_post("enhance/%d/food" % player_cat_id, {}, callback)


func upgrade_cat_food_to_max(player_cat_id: int, callback: Callable) -> void:
	_api_post("enhance/%d/food/max" % player_cat_id, {}, callback)


func add_cat_special_point(player_cat_id: int, stat_key: String, callback: Callable) -> void:
	_api_post("enhance/%d/special/add" % player_cat_id, {"statType": stat_key}, callback)


func remove_cat_special_point(player_cat_id: int, stat_key: String, callback: Callable) -> void:
	_api_post("enhance/%d/special/remove" % player_cat_id, {"statType": stat_key}, callback)


func upgrade_cat_rank(player_cat_id: int, callback: Callable) -> void:
	_api_post("enhance/%d/rank" % player_cat_id, {}, callback)


func reset_cat_enhance(player_cat_id: int, callback: Callable) -> void:
	_api_post("enhance/%d/reset" % player_cat_id, {}, callback)


# ── Core request methods ─────────────────────────────────────

func _api_get(path: String, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_GET, {}, callback)


func _api_post(path: String, body: Dictionary, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_POST, body, callback)


func _api_put(path: String, body: Dictionary, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_PUT, body, callback)


func _api_delete(path: String, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_DELETE, {}, callback)


func _api_patch(path: String, body: Dictionary, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_PATCH, body, callback)


func _enqueue_request(path: String, method: int, body: Dictionary, callback: Callable) -> void:
	var entry := {
		"path": path,
		"method": method,
		"body": body,
		"callback": callback,
	}

	var slot := _find_free_slot()
	if slot >= 0:
		_dispatch(slot, entry)
	else:
		_pending_queue.append(entry)


func _find_free_slot() -> int:
	for i in range(POOL_SIZE):
		if not _busy[i]:
			return i
	return -1


func _dispatch(slot: int, entry: Dictionary) -> void:
	_busy[slot] = true
	_pool[slot].set_meta("entry", entry)

	var base_url: String = GameState.api_base_url
	var url := "%s/%s" % [base_url, entry["path"]]
	var method: int = entry["method"]

	var headers := PackedStringArray([
		"Accept: application/json",
		"Authorization: Bearer %s" % GameState.get_access_token(),
	])

	var has_body := method == HTTPClient.METHOD_POST \
			or method == HTTPClient.METHOD_PUT \
			or method == HTTPClient.METHOD_PATCH
	if has_body:
		headers.append("Content-Type: application/json")
		var body_text := JSON.stringify(entry["body"])
		var error := _pool[slot].request(url, headers, method, body_text)
		if error != OK:
			_busy[slot] = false
			_invoke_callback(entry["callback"], false, {}, {"code": "HTTP.REQUEST_ERROR", "message": "無法送出請求，錯誤碼: %s" % error})
			_flush_pending()
	else:
		var error := _pool[slot].request(url, headers, method)
		if error != OK:
			_busy[slot] = false
			_invoke_callback(entry["callback"], false, {}, {"code": "HTTP.REQUEST_ERROR", "message": "無法送出請求，錯誤碼: %s" % error})
			_flush_pending()


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, slot: int) -> void:
	var entry: Dictionary = _pool[slot].get_meta("entry") if _pool[slot].has_meta("entry") else {}
	_pool[slot].remove_meta("entry")
	_busy[slot] = false

	var callback: Callable = entry.get("callback", Callable())

	var response_text := body.get_string_from_utf8()
	var json := JSON.new()
	if response_text == "" or json.parse(response_text) != OK:
		_invoke_callback(callback, false, {}, {"code": "HTTP.PARSE_ERROR", "message": "伺服器回傳格式無法解析。"})
		_flush_pending()
		return

	var payload: Variant = json.get_data()
	if not (payload is Dictionary):
		_invoke_callback(callback, false, {}, {"code": "HTTP.PARSE_ERROR", "message": "伺服器回傳格式無法解析。"})
		_flush_pending()
		return

	var envelope: Dictionary = payload
	var success := bool(envelope.get("success", false))
	var data_variant: Variant = envelope.get("data", {})
	var error_variant: Variant = envelope.get("error", {})

	if response_code >= 200 and response_code < 300 and success:
		_invoke_callback(callback, true, data_variant, {})
		_flush_pending()
		return

	# 401 → auto refresh token and retry
	if response_code == 401 and GameState.get_refresh_token() != "":
		_begin_refresh_and_retry(entry)
		_flush_pending()
		return

	var error_dict: Dictionary = error_variant if error_variant is Dictionary else {}
	_invoke_callback(callback, false, {}, error_dict)
	_flush_pending()


# ── Token refresh ────────────────────────────────────────────

func _begin_refresh_and_retry(original_entry: Dictionary) -> void:
	_refresh_queue.append(original_entry)

	if _refreshing:
		return

	_refreshing = true

	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	add_child(http)
	http.request_completed.connect(_on_refresh_completed.bind(http))

	var base_url: String = GameState.api_base_url
	var url := "%s/auth/refresh" % base_url
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
	])
	var body_text := JSON.stringify({"refreshToken": GameState.get_refresh_token()})
	var error := http.request(url, headers, HTTPClient.METHOD_POST, body_text)
	if error != OK:
		_on_refresh_failed()
		http.queue_free()


func _on_refresh_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	_refreshing = false

	var response_text := body.get_string_from_utf8()
	var json := JSON.new()
	if response_text == "" or json.parse(response_text) != OK:
		_on_refresh_failed()
		return

	var payload: Variant = json.get_data()
	if not (payload is Dictionary):
		_on_refresh_failed()
		return

	var envelope: Dictionary = payload
	var success := bool(envelope.get("success", false))

	if response_code >= 200 and response_code < 300 and success:
		var data_variant: Variant = envelope.get("data", {})
		var data: Dictionary = data_variant if data_variant is Dictionary else {}
		GameState.set_auth_session(GameState.api_base_url, data)

		# Retry all queued requests
		var queued := _refresh_queue.duplicate()
		_refresh_queue.clear()
		for entry: Dictionary in queued:
			_enqueue_request(entry["path"], entry["method"], entry["body"], entry["callback"])
		return

	_on_refresh_failed()


func _on_refresh_failed() -> void:
	_refreshing = false
	var queued := _refresh_queue.duplicate()
	_refresh_queue.clear()

	for entry: Dictionary in queued:
		_invoke_callback(entry.get("callback", Callable()), false, {}, {"code": "AUTH.SESSION_EXPIRED", "message": "登入已過期，請重新登入。"})

	GameState.clear_auth_and_player_state()
	get_tree().change_scene_to_file("res://scenes/StartScene.tscn")


# ── Helpers ──────────────────────────────────────────────────

func _invoke_callback(callback: Callable, success: bool, data: Variant, error: Dictionary) -> void:
	if callback.is_valid():
		callback.call(success, data, error)


func _flush_pending() -> void:
	while not _pending_queue.is_empty():
		var slot := _find_free_slot()
		if slot < 0:
			break
		var entry: Dictionary = _pending_queue.pop_front()
		_dispatch(slot, entry)
