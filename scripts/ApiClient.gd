extends Node

const POOL_SIZE := 3
const REQUEST_TIMEOUT := 15.0
const LOADING_LAYER := 140
const DEFAULT_LOADING_MESSAGE := "loading."
const NGROK_SKIP_WARNING_HEADER := "ngrok-skip-browser-warning: true"

var _pool: Array[HTTPRequest] = []
var _busy: Array[bool] = []
var _refreshing := false
var _refresh_queue: Array[Dictionary] = []

var _loading_canvas: CanvasLayer
var _loading_message_label: Label
var _loading_spinner: Control
var _spinner_dots: Array[Control] = []
var _loading_request_count := 0
var _spinner_time := 0.0
var _loading_text_phase := 0
var _loading_text_elapsed := 0.0

## Accumulated daily-task event counts keyed by event_key.
## Flushed in batch when the player opens the daily-tasks dialog.
var _pending_daily_task_events: Dictionary = {}


func _ready() -> void:
	if GameState.api_base_url.strip_edges().is_empty():
		var resolved_api_base_url: String = RuntimeConfig.get_api_base_url("")
		if not resolved_api_base_url.is_empty():
			GameState.api_base_url = resolved_api_base_url

	for i in range(POOL_SIZE):
		var http := HTTPRequest.new()
		http.timeout = REQUEST_TIMEOUT
		http.request_completed.connect(_on_request_completed.bind(i))
		add_child(http)
		_pool.append(http)
		_busy.append(false)

	_build_loading_overlay()
	set_process(false)


func _process(delta: float) -> void:
	if _loading_request_count <= 0 or _loading_spinner == null:
		return

	_spinner_time += delta * 2.8
	_loading_text_elapsed += delta
	_loading_spinner.rotation = _spinner_time

	for i in range(_spinner_dots.size()):
		var dot := _spinner_dots[i]
		if dot == null:
			continue
		var pulse: float = maxf(0.0, sin(_spinner_time * 2.0 - float(i) * 0.65))
		var alpha: float = 0.35 + 0.65 * pulse
		dot.modulate.a = alpha

	if _loading_text_elapsed >= 0.28:
		_loading_text_elapsed = 0.0
		_loading_text_phase = (_loading_text_phase + 1) % 3
		_update_loading_label()


func get_scooper_profile(callback: Callable) -> void:
	_api_get("scooper/profile", callback)


func get_scooper_profile_silent(callback: Callable) -> void:
	_api_get_tracked("scooper/profile", callback, false)


func scoop_poop(count: int, callback: Callable) -> void:
	_api_post("scooper/profile/scoop", {"count": count}, _with_daily_task_event(callback, "scoop_poop"))


func scoop_poop_silent(count: int, callback: Callable) -> void:
	_api_post_tracked("scooper/profile/scoop", {"count": count}, _with_daily_task_event(callback, "scoop_poop"), false)


func claim_idle_rewards(callback: Callable) -> void:
	_api_post("scooper/profile/claim-idle", {}, _with_daily_task_event(callback, "claim_idle_rewards"))


func stage_clear_silent(cleared_stage: int, is_boss: bool, callback: Callable) -> void:
	_api_post_tracked("scooper/profile/stage-clear", {"clearedStage": cleared_stage, "isBoss": is_boss}, callback, false)


func get_equipment_list(callback: Callable) -> void:
	_api_get("scooper/equipment", callback)


func get_equipment_list_silent(callback: Callable) -> void:
	_api_get_tracked("scooper/equipment", callback, false)


func purchase_equipment(equipment_id: int, callback: Callable) -> void:
	_api_post("scooper/equipment/purchase", {"equipmentId": equipment_id}, _with_daily_task_event(callback, "equipment_action"))


func purchase_equipment_silent(equipment_id: int, callback: Callable) -> void:
	_api_post_tracked("scooper/equipment/purchase", {"equipmentId": equipment_id}, _with_daily_task_event(callback, "equipment_action"), false)


func upgrade_equipment(equipment_id: int, callback: Callable) -> void:
	_api_post("scooper/equipment/upgrade", {"equipmentId": equipment_id}, _with_daily_task_event(callback, "equipment_action"))


func upgrade_equipment_silent(equipment_id: int, callback: Callable) -> void:
	_api_post_tracked("scooper/equipment/upgrade", {"equipmentId": equipment_id}, _with_daily_task_event(callback, "equipment_action"), false)


func repair_equipment(equipment_id: int, callback: Callable) -> void:
	_api_post("scooper/equipment/repair", {"equipmentId": equipment_id}, _with_daily_task_event(callback, "equipment_action"))


func repair_equipment_silent(equipment_id: int, callback: Callable) -> void:
	_api_post_tracked("scooper/equipment/repair", {"equipmentId": equipment_id}, _with_daily_task_event(callback, "equipment_action"), false)


func treat_equipment(equipment_id: int, callback: Callable) -> void:
	_api_post("scooper/equipment/treat", {"equipmentId": equipment_id}, _with_daily_task_event(callback, "equipment_action"))


func treat_equipment_silent(equipment_id: int, callback: Callable) -> void:
	_api_post_tracked("scooper/equipment/treat", {"equipmentId": equipment_id}, _with_daily_task_event(callback, "equipment_action"), false)


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


func get_achievements_silent(callback: Callable) -> void:
	_api_get_tracked("scooper/achievement", callback, false)


func claim_achievement(achievement_id: int, callback: Callable) -> void:
	_api_post("scooper/achievement/claim", {"achievementId": achievement_id}, callback)


func claim_achievement_silent(achievement_id: int, callback: Callable) -> void:
	_api_post_tracked("scooper/achievement/claim", {"achievementId": achievement_id}, callback, false)


func get_authenticated_bootstrap(callback: Callable) -> void:
	_api_get("auth/bootstrap", callback)


func get_authenticated_bootstrap_silent(callback: Callable) -> void:
	_api_get_tracked("auth/bootstrap", callback, false)


func get_combat_trial_scores(callback: Callable) -> void:
	_api_get("combat-trial", callback)


func submit_combat_trial_score(trial_type: String, score: int, trial_version: int, callback: Callable) -> void:
	_api_post("combat-trial/score", {
		"trialType": trial_type,
		"score": score,
		"trialVersion": trial_version,
	}, callback)


func get_announcements(callback: Callable) -> void:
	_api_get("announcements", callback)


func get_daily_tasks(callback: Callable) -> void:
	_api_get("daily-tasks", callback)


func claim_daily_task(task_key: String, callback: Callable) -> void:
	_api_post("daily-tasks/%s/claim" % task_key.uri_encode(), {}, callback)


func record_daily_task_event(event_key: String, _callback: Callable = Callable()) -> void:
	var key := event_key.strip_edges()
	if key.is_empty():
		return
	_pending_daily_task_events[key] = int(_pending_daily_task_events.get(key, 0)) + 1
	GameState.set_daily_task_events_pending(true)


func has_pending_daily_task_events() -> bool:
	return not _pending_daily_task_events.is_empty()


func flush_daily_task_events(callback: Callable) -> void:
	if _pending_daily_task_events.is_empty():
		callback.call(false, {}, {})
		return
	var events_to_flush: Dictionary = _pending_daily_task_events.duplicate()
	_pending_daily_task_events.clear()
	GameState.set_daily_task_events_pending(false)
	_flush_daily_task_events_sequential(events_to_flush.keys(), events_to_flush, 0, callback)


func _flush_daily_task_events_sequential(keys: Array, counts: Dictionary, index: int, final_callback: Callable) -> void:
	if index >= keys.size():
		if _can_invoke_callable(final_callback):
			final_callback.call(true, {}, {})
		return
	var event_key: String = keys[index]
	var count: int = int(counts[event_key])
	_api_post_tracked("daily-tasks/events", {"eventKey": event_key, "count": count},
		Callable(self, "_on_flush_daily_task_event_done").bind(keys, counts, index, final_callback), false)


func _on_flush_daily_task_event_done(_ok: bool, _data: Variant, _err: Dictionary, keys: Array, counts: Dictionary, index: int, final_callback: Callable) -> void:
	_flush_daily_task_events_sequential(keys, counts, index + 1, final_callback)


func get_profile_me(callback: Callable) -> void:
	_api_get("profile/me", callback)


func update_profile_me(payload: Dictionary, callback: Callable) -> void:
	_api_put("profile/me", payload, callback)


func delete_profile_me(callback: Callable) -> void:
	_api_delete("profile/me", callback)


func begin_oauth_link(provider_key: String, payload: Dictionary, callback: Callable) -> void:
	_api_post("profile/oauth/%s/begin-link" % provider_key.uri_encode(), payload, callback)


func exchange_oauth_link(transaction_id: String, callback: Callable) -> void:
	_api_post_tracked("profile/oauth/link/exchange", {"transactionId": transaction_id}, callback, false)


func unlink_oauth_provider(provider_key: String, current_refresh_token: String, callback: Callable) -> void:
	_enqueue_request(
		"profile/oauth/%s" % provider_key.uri_encode(),
		HTTPClient.METHOD_DELETE,
		{"currentRefreshToken": current_refresh_token},
		callback
	)


func revoke_refresh_token(refresh_token: String, reason: String, callback: Callable) -> void:
	_api_post("auth/revoke", {
		"refreshToken": refresh_token,
		"reason": reason,
	}, callback)


func redeem_code(code: String, callback: Callable) -> void:
	_api_post("redeem-codes/redeem", {"code": code}, callback)


func get_mail_summary(callback: Callable) -> void:
	_api_get("mail/summary", callback)


func get_mail_list(callback: Callable, page: int = 1, page_size: int = 20) -> void:
	_api_get("mail?page=%d&pageSize=%d" % [page, page_size], callback)


func get_mail_list_silent(callback: Callable, page: int = 1, page_size: int = 20) -> void:
	_api_get_tracked("mail?page=%d&pageSize=%d" % [page, page_size], callback, false)


func get_mail_detail(mail_id: int, callback: Callable) -> void:
	_api_get("mail/%d" % mail_id, callback)


func get_mail_detail_silent(mail_id: int, callback: Callable) -> void:
	_api_get_tracked("mail/%d" % mail_id, callback, false)


func mark_mail_read(mail_id: int, callback: Callable) -> void:
	_api_post("mail/%d/read" % mail_id, {}, callback)


func mark_mail_read_silent(mail_id: int, callback: Callable) -> void:
	_api_post_tracked("mail/%d/read" % mail_id, {}, callback, false)


func claim_mail(mail_id: int, callback: Callable) -> void:
	_api_post("mail/%d/claim" % mail_id, {}, callback)


func claim_all_mails(callback: Callable) -> void:
	_api_post("mail/claim-all", {}, callback)


func delete_read_mails(callback: Callable) -> void:
	_api_delete("mail/read", callback)

func get_chat_summary(callback: Callable) -> void:
	_api_get("chat/summary", callback)


func get_chat_history(channel_key: String, before_seq: int, page_size: int, callback: Callable) -> void:
	var query := "chat/history?channelKey=%s&pageSize=%d" % [channel_key.uri_encode(), page_size]
	if before_seq > 0:
		query += "&beforeSequence=%d" % before_seq
	_api_get(query, callback)


func post_chat_message(channel_key: String, content: String, callback: Callable) -> void:
	_api_post("chat/messages", {"channelKey": channel_key, "content": content}, _with_daily_task_event(callback, "chat_message"))


func post_chat_read(channel_key: String, last_read_sequence: int, callback: Callable) -> void:
	_api_post("chat/read", {"channelKey": channel_key, "lastReadSequence": last_read_sequence}, callback)


func post_chat_read_silent(channel_key: String, last_read_sequence: int, callback: Callable) -> void:
	_api_post_tracked("chat/read", {"channelKey": channel_key, "lastReadSequence": last_read_sequence}, callback, false)


func get_friends(callback: Callable) -> void:
	_api_get("friend", callback)


func get_friend_inbox(callback: Callable) -> void:
	_api_get("friend/request/inbox", callback)


func get_friend_outbox(callback: Callable) -> void:
	_api_get("friend/request/outbox", callback)


func search_friend_candidates(query: String, callback: Callable) -> void:
	_api_get("friend/search-candidates?query=%s" % query.uri_encode(), callback)


func send_friend_request(receiver_player_uid: String, callback: Callable) -> void:
	_api_post("friend/request", {"receiverPlayerUid": receiver_player_uid}, callback)


func accept_friend_request(request_id: int, callback: Callable) -> void:
	_api_post("friend/request/%d/accept" % request_id, {}, callback)


func reject_friend_request(request_id: int, callback: Callable) -> void:
	_api_post("friend/request/%d/reject" % request_id, {}, callback)


func cancel_friend_request(request_id: int, callback: Callable) -> void:
	_api_delete("friend/request/%d" % request_id, callback)


func remove_friend(friend_user_id: int, callback: Callable) -> void:
	_api_delete("friend/%d" % friend_user_id, callback)


func send_friend_gifts(callback: Callable) -> void:
	_api_post("friend/gift/send-all", {}, _with_daily_task_event(callback, "friend_gift"))


func set_friend_showcase_cat(player_cat_id: int, callback: Callable) -> void:
	_api_put("friend/showcase-cat", {"playerCatId": player_cat_id}, callback)


func clear_friend_showcase_cat(callback: Callable) -> void:
	_api_put("friend/showcase-cat", {"playerCatId": null}, callback)


func get_my_party(callback: Callable) -> void:
	_api_get("party/my", callback)


func get_my_party_silent(callback: Callable) -> void:
	_api_get_tracked("party/my", callback, false)


func get_party(party_id: int, callback: Callable) -> void:
	_api_get("party/%d" % party_id, callback)


func create_party(party_name: String, callback: Callable) -> void:
	_api_post("party", {"name": party_name}, callback)


func update_party_name(party_id: int, party_name: String, callback: Callable) -> void:
	_api_put("party/%d/name" % party_id, {"name": party_name}, callback)


func disband_party(party_id: int, callback: Callable) -> void:
	_api_delete("party/%d" % party_id, callback)


func transfer_party_leadership(party_id: int, target_user_id: int, callback: Callable) -> void:
	_api_post("party/%d/transfer-leadership" % party_id, {"targetUserId": target_user_id}, callback)


func kick_party_member(party_id: int, target_user_id: int, callback: Callable) -> void:
	_api_post("party/%d/kick/%d" % [party_id, target_user_id], {}, callback)


func leave_party(party_id: int, callback: Callable) -> void:
	_api_delete("party/%d/leave" % party_id, callback)


func apply_to_party_by_id(party_id: int, callback: Callable) -> void:
	_api_post("party/apply", {"partyId": party_id}, callback)


func apply_to_party_by_name(party_name: String, callback: Callable) -> void:
	_api_post("party/apply", {"partyName": party_name}, callback)


func search_party_invite_candidates(party_id: int, query: String, callback: Callable) -> void:
	_api_get("party/%d/invite-candidates?query=%s" % [party_id, query.uri_encode()], callback)


func invite_player_to_party(party_id: int, target_player_uid: String, callback: Callable) -> void:
	_api_post("party/%d/invite" % party_id, {"targetPlayerUid": target_player_uid}, callback)


func get_party_applications(party_id: int, callback: Callable) -> void:
	_api_get("party/%d/applications" % party_id, callback)


func get_party_applications_silent(party_id: int, callback: Callable) -> void:
	_api_get_tracked("party/%d/applications" % party_id, callback, false)


func get_my_party_applications(callback: Callable) -> void:
	_api_get("party/applications/my", callback)


func get_my_party_applications_silent(callback: Callable) -> void:
	_api_get_tracked("party/applications/my", callback, false)


func accept_party_invite(application_id: int, callback: Callable) -> void:
	_api_post("party/invite/%d/accept" % application_id, {}, callback)


func reject_party_invite(application_id: int, callback: Callable) -> void:
	_api_post("party/invite/%d/reject" % application_id, {}, callback)


func accept_party_application(application_id: int, callback: Callable) -> void:
	_api_post("party/application/%d/accept" % application_id, {}, callback)


func reject_party_application(application_id: int, callback: Callable) -> void:
	_api_post("party/application/%d/reject" % application_id, {}, callback)


func cancel_party_application(application_id: int, callback: Callable) -> void:
	_api_delete("party/application/%d" % application_id, callback)


func usurp_party_leadership(party_id: int, callback: Callable) -> void:
	_api_post("party/%d/usurp" % party_id, {}, callback)


func get_party_cheer_status(party_id: int, callback: Callable) -> void:
	_api_get("party/%d/cheer" % party_id, callback)


func get_party_cheer_status_silent(party_id: int, callback: Callable) -> void:
	_api_get_tracked("party/%d/cheer" % party_id, callback, false)


func cheer_party(party_id: int, is_ad_boost: bool, callback: Callable) -> void:
	var event_keys: Array[String] = ["party_cheer"]
	if is_ad_boost:
		event_keys.append("watch_ad")
	_api_post("party/%d/cheer" % party_id, {"isAdBoost": is_ad_boost}, _with_daily_task_events(callback, event_keys))


func use_party_cheer_coupon(callback: Callable) -> void:
	_api_post("party/cheer-coupon/use", {}, callback)


func get_teams(callback: Callable) -> void:
	_api_get("config/teams", callback)


func replace_team(team_type_key: String, members: Array, callback: Callable) -> void:
	_api_put("config/teams/%s" % team_type_key, {"members": members}, callback)


func get_enhance_overview(callback: Callable) -> void:
	_api_get("enhance", callback)


func get_dungeon_overview(callback: Callable) -> void:
	_api_get("dungeon", callback)


func get_expedition(callback: Callable) -> void:
	_api_get("expedition", callback)


func start_expedition(zone_id: int, cat_id: String, callback: Callable) -> void:
	_api_post("expedition/%d/start" % zone_id, {"catId": cat_id}, _with_daily_task_event(callback, "expedition_dispatch"))


func claim_expedition(zone_id: int, callback: Callable) -> void:
	_api_post("expedition/%d/claim" % zone_id, {}, callback)


func get_gacha_overview(callback: Callable) -> void:
	_api_get("gacha", callback)


func perform_gacha_pull(pull_count: int, use_free_pull: bool, spend_trap_cages_first: bool, callback: Callable) -> void:
	var request_callback: Callable = _with_daily_task_event(callback, "free_gacha_pull") if use_free_pull else callback
	_api_post("gacha/pull", {
		"pullCount": pull_count,
		"useFreePull": use_free_pull,
		"spendTrapCagesFirst": spend_trap_cages_first,
	}, request_callback)


func get_shop_overview(callback: Callable) -> void:
	_api_get("shop", callback)


func purchase_trap_cages(trap_cage_count: int, callback: Callable) -> void:
	_api_post("shop/trap-cages/purchase", {
		"trapCageCount": trap_cage_count,
	}, callback)


func purchase_shop_bundle(bundle_id: int, callback: Callable, record_daily_free_pack: bool = false) -> void:
	var request_callback: Callable = _with_daily_task_event(callback, "claim_daily_shop_pack") if record_daily_free_pack else callback
	_api_post("shop/bundles/%d/purchase" % bundle_id, {}, request_callback)


func upgrade_scooper_ability(ability_id: int, expected_cost: int, callback: Callable) -> void:
	_api_post("scooper/ability/%d/upgrade" % ability_id, {"expectedCost": expected_cost}, callback)


func purchase_trap_points(trap_point_amount: int, callback: Callable) -> void:
	_api_post("shop/trap-points/purchase", {
		"trapPointAmount": trap_point_amount,
	}, callback)


func purchase_collision_coin(collision_coin_amount: int, callback: Callable) -> void:
	_api_post("shop/collision-coin/purchase", {
		"collisionCoinAmount": collision_coin_amount,
	}, callback)


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


func purchase_arena_tickets(quantity: int, callback: Callable) -> void:
	_api_post("arena/tickets/purchase", {"quantity": quantity}, callback)


func claim_arena_rank_reward(rank_id: int, callback: Callable) -> void:
	_api_post("arena/rewards/%d/claim" % rank_id, {}, callback)


func complete_arena_battle(opponent_id: String, is_win: bool, callback: Callable) -> void:
	_api_post("arena/opponents/%s/complete" % opponent_id.uri_encode(), {"isWin": is_win}, _with_daily_task_event(callback, "arena_battle"))


func grant_dungeon_ad_ticket(dungeon_id: int, callback: Callable) -> void:
	_api_post("dungeon/%d/ad-ticket" % dungeon_id, {}, callback)


func sweep_dungeon(dungeon_id: int, callback: Callable) -> void:
	_api_post("dungeon/%d/sweep" % dungeon_id, {}, callback)


func complete_dungeon_challenge(dungeon_id: int, target_floor: int, callback: Callable) -> void:
	_api_post("dungeon/%d/challenge" % dungeon_id, {"targetFloor": target_floor}, _with_daily_task_event(callback, _get_daily_dungeon_event_key(dungeon_id)))


func claim_temporary_event(event_id: String, callback: Callable) -> void:
	_api_post_tracked("events/%s/claim" % event_id, {}, callback, false)


func upgrade_cat_food(player_cat_id: int, callback: Callable) -> void:
	_api_post("enhance/%d/food" % player_cat_id, {}, _with_daily_task_event(callback, "upgrade_cat"))


func upgrade_cat_food_to_max(player_cat_id: int, callback: Callable) -> void:
	_api_post("enhance/%d/food/max" % player_cat_id, {}, _with_daily_task_event(callback, "upgrade_cat"))


func add_cat_special_point(player_cat_id: int, stat_key: String, callback: Callable) -> void:
	_api_post("enhance/%d/special/add" % player_cat_id, {"statType": stat_key}, callback)


func remove_cat_special_point(player_cat_id: int, stat_key: String, callback: Callable) -> void:
	_api_post("enhance/%d/special/remove" % player_cat_id, {"statType": stat_key}, callback)


func upgrade_cat_rank(player_cat_id: int, callback: Callable) -> void:
	_api_post("enhance/%d/rank" % player_cat_id, {}, _with_daily_task_event(callback, "upgrade_cat"))


func reset_cat_enhance(player_cat_id: int, callback: Callable) -> void:
	_api_post("enhance/%d/reset" % player_cat_id, {}, callback)


func _with_daily_task_event(callback: Callable, event_key: String) -> Callable:
	return _with_daily_task_events(callback, [event_key])


func _with_daily_task_events(callback: Callable, event_keys: Array[String]) -> Callable:
	return Callable(self, "_on_daily_task_wrapped_callback").bind(callback, event_keys)


func _on_daily_task_wrapped_callback(ok: bool, data: Variant, err: Dictionary, callback: Callable, event_keys: Array[String]) -> void:
	if _can_invoke_callable(callback):
		callback.call(ok, data, err)
	if not ok:
		return
	for event_key: String in event_keys:
		if not event_key.strip_edges().is_empty():
			record_daily_task_event(event_key)


func _get_daily_dungeon_event_key(dungeon_id: int) -> String:
	match dungeon_id:
		2:
			return "dungeon_diamond"
		3:
			return "dungeon_whisker"
		4:
			return "dungeon_poop"
		5:
			return "dungeon_gold"
		_:
			return ""


func retain_loading_overlay(_message: String = DEFAULT_LOADING_MESSAGE) -> void:
	_retain_loading_overlay()


func release_loading_overlay() -> void:
	_release_loading_overlay()


func _api_get(path: String, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_GET, {}, callback)


func _api_get_tracked(path: String, callback: Callable, track_loading: bool) -> void:
	_enqueue_request(path, HTTPClient.METHOD_GET, {}, callback, track_loading)


func _api_post(path: String, body: Dictionary, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_POST, body, callback)


func _api_post_tracked(path: String, body: Dictionary, callback: Callable, track_loading: bool) -> void:
	_enqueue_request(path, HTTPClient.METHOD_POST, body, callback, track_loading)


func _api_put(path: String, body: Dictionary, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_PUT, body, callback)


func _api_delete(path: String, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_DELETE, {}, callback)


func _api_patch(path: String, body: Dictionary, callback: Callable) -> void:
	_enqueue_request(path, HTTPClient.METHOD_PATCH, body, callback)


func _enqueue_request(path: String, method: int, body: Dictionary, callback: Callable, track_loading: bool = true) -> void:
	if track_loading:
		_retain_loading_overlay()

	var entry := {
		"path": path,
		"method": method,
		"body": body,
		"callback": callback,
		"track_loading": track_loading,
	}

	var slot := _find_free_slot()
	if slot >= 0:
		_dispatch(slot, entry)
		return

	_invoke_callback(callback, false, {}, {
		"code": "HTTP.CLIENT_BUSY",
		"message": "Client request pool is busy. Please try again.",
	})
	_release_loading_overlay_if_tracked(entry)


func _find_free_slot() -> int:
	for i in range(POOL_SIZE):
		if not _busy[i]:
			return i
	return -1


func _dispatch(slot: int, entry: Dictionary) -> void:
	_busy[slot] = true
	_pool[slot].set_meta("entry", entry)

	var url := "%s/%s" % [GameState.api_base_url, entry["path"]]
	var method: int = entry["method"]
	var request_body: Dictionary = entry["body"] if entry.get("body") is Dictionary else {}
	var headers := _build_request_headers(GameState.get_access_token())

	var has_body := method == HTTPClient.METHOD_POST \
			or method == HTTPClient.METHOD_PUT \
			or method == HTTPClient.METHOD_PATCH \
			or not request_body.is_empty()

	var error := OK
	if has_body:
		headers.append("Content-Type: application/json")
		error = _pool[slot].request(url, headers, method, JSON.stringify(request_body))
	else:
		error = _pool[slot].request(url, headers, method)

	if error != OK:
		_busy[slot] = false
		_pool[slot].remove_meta("entry")
		_invoke_callback(entry["callback"], false, {}, {
			"code": "HTTP.REQUEST_ERROR",
			"message": UiText.API_ERROR_REQUEST_FAILED_FORMAT % error,
		})
		_release_loading_overlay_if_tracked(entry)


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, slot: int) -> void:
	var entry: Dictionary = _pool[slot].get_meta("entry") if _pool[slot].has_meta("entry") else {}
	_pool[slot].remove_meta("entry")
	_busy[slot] = false

	var callback: Callable = entry.get("callback", Callable())
	var response_text := body.get_string_from_utf8()
	var json := JSON.new()

	if response_text == "" or json.parse(response_text) != OK:
		_invoke_callback(callback, false, {}, {
			"code": "HTTP.PARSE_ERROR",
			"message": UiText.API_ERROR_PARSE_ERROR,
		})
		_release_loading_overlay_if_tracked(entry)
		return

	var payload: Variant = json.get_data()
	if not (payload is Dictionary):
		_invoke_callback(callback, false, {}, {
			"code": "HTTP.PARSE_ERROR",
			"message": UiText.API_ERROR_PARSE_ERROR,
		})
		_release_loading_overlay_if_tracked(entry)
		return

	var envelope: Dictionary = payload
	var success := bool(envelope.get("success", false))
	var data_variant: Variant = envelope.get("data", {})
	var error_variant: Variant = envelope.get("error", {})

	if response_code >= 200 and response_code < 300 and success:
		_invoke_callback(callback, true, data_variant, {})
		_release_loading_overlay_if_tracked(entry)
		return

	if response_code == 401 and GameState.get_refresh_token() != "":
		_begin_refresh_and_retry(entry)
		return

	var error_dict: Dictionary = error_variant if error_variant is Dictionary else {}
	_invoke_callback(callback, false, {}, error_dict)
	_release_loading_overlay_if_tracked(entry)


func _begin_refresh_and_retry(original_entry: Dictionary) -> void:
	_refresh_queue.append(original_entry)
	if _refreshing:
		return

	_refreshing = true

	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	add_child(http)
	http.request_completed.connect(_on_refresh_completed.bind(http))

	var url := "%s/auth/refresh" % GameState.api_base_url
	var headers := _build_request_headers("", true)
	var body_text := JSON.stringify({"refreshToken": GameState.get_refresh_token()})
	var error := http.request(url, headers, HTTPClient.METHOD_POST, body_text)
	if error != OK:
		_on_refresh_failed()
		http.queue_free()


func _build_request_headers(access_token: String = "", include_json_content_type: bool = false) -> PackedStringArray:
	var headers := PackedStringArray([
		"Accept: application/json",
		NGROK_SKIP_WARNING_HEADER,
	])
	if include_json_content_type:
		headers.append("Content-Type: application/json")
	if access_token != "":
		headers.append("Authorization: Bearer %s" % access_token)
	return headers


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

		var queued := _refresh_queue.duplicate()
		_refresh_queue.clear()
		for entry: Dictionary in queued:
			_enqueue_request(entry["path"], entry["method"], entry["body"], entry["callback"], false)
		return

	_on_refresh_failed()


func _on_refresh_failed() -> void:
	_refreshing = false
	var queued := _refresh_queue.duplicate()
	_refresh_queue.clear()

	for entry: Dictionary in queued:
		_invoke_callback(entry.get("callback", Callable()), false, {}, {
			"code": "AUTH.SESSION_EXPIRED",
			"message": UiText.API_ERROR_SESSION_EXPIRED,
		})
		_release_loading_overlay_if_tracked(entry)

	GameState.clear_auth_and_player_state()
	get_tree().change_scene_to_file("res://scenes/StartScene.tscn")


func _invoke_callback(callback: Callable, success: bool, data: Variant, error: Dictionary) -> void:
	if not _can_invoke_callable(callback):
		return
	callback.call(success, data, error)


func _can_invoke_callable(callback: Callable) -> bool:
	if callback.is_null() or not callback.is_valid():
		return false
	var object_id: int = callback.get_object_id()
	if object_id == 0:
		return true
	var target: Object = instance_from_id(object_id)
	return target != null and is_instance_valid(target)


func _release_loading_overlay_if_tracked(entry: Dictionary) -> void:
	if bool(entry.get("track_loading", true)):
		_release_loading_overlay()


func _retain_loading_overlay() -> void:
	_loading_request_count += 1
	_ensure_loading_overlay()
	_loading_text_phase = 0
	_loading_text_elapsed = 0.0
	_update_loading_label()
	if _loading_canvas != null:
		_loading_canvas.visible = true
	set_process(true)


func _release_loading_overlay() -> void:
	_loading_request_count = max(_loading_request_count - 1, 0)
	if _loading_request_count > 0:
		return
	if _loading_canvas != null:
		_loading_canvas.visible = false
	set_process(false)


func _ensure_loading_overlay() -> void:
	if _loading_canvas == null:
		_build_loading_overlay()


func _build_loading_overlay() -> void:
	if _loading_canvas != null:
		return

	_loading_canvas = CanvasLayer.new()
	_loading_canvas.layer = LOADING_LAYER
	_loading_canvas.visible = false
	add_child(_loading_canvas)

	var overlay := ColorRect.new()
	overlay.color = Color(0.18, 0.14, 0.10, 0.28)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_canvas.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_canvas.add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(320.0, 164.0)
	frame.add_theme_stylebox_override("panel", _make_start_loading_card_stylebox())
	center.add_child(frame)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	frame.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	var spinner_center: CenterContainer = CenterContainer.new()
	spinner_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spinner_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(spinner_center)

	_loading_spinner = Control.new()
	_loading_spinner.custom_minimum_size = Vector2(84.0, 84.0)
	_loading_spinner.pivot_offset = _loading_spinner.custom_minimum_size * 0.5
	_loading_spinner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spinner_center.add_child(_loading_spinner)
	_build_spinner_dots()

	_loading_message_label = Label.new()
	_loading_message_label.text = DEFAULT_LOADING_MESSAGE
	_loading_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_loading_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_message_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	_loading_message_label.add_theme_color_override("font_color", Color("5f4c3f"))
	content.add_child(_loading_message_label)


func _build_spinner_dots() -> void:
	_spinner_dots.clear()
	if _loading_spinner == null:
		return

	var ring_center := _loading_spinner.custom_minimum_size * 0.5
	var radius := 24.0
	var dot_size := Vector2(12.0, 12.0)
	for i in range(8):
		var dot := ColorRect.new()
		var angle := TAU * float(i) / 8.0
		dot.color = Color("9aae8b")
		dot.size = dot_size
		dot.position = ring_center + Vector2(cos(angle), sin(angle)) * radius - dot_size * 0.5
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_loading_spinner.add_child(dot)
		_spinner_dots.append(dot)


func _update_loading_label() -> void:
	if _loading_message_label == null:
		return
	_loading_message_label.text = "loading%s" % ".".repeat(_loading_text_phase + 1)


func _make_start_loading_card_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.88, 0.86)
	style.border_color = Color("6d5948")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.24, 0.18, 0.14, 0.22)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 6)
	style.anti_aliasing = false
	style.border_blend = false
	return style
