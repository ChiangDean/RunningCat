class_name RedDotService
extends RefCounted

const PlayerCatDataRef = preload("res://scripts/data/cats/player_cat_data.gd")


static func refresh_dot(target: Control, is_visible: bool, z_index: int = 10) -> void:
	if target == null:
		return
	if is_visible:
		BadgeOverlay.add_dot(target, z_index)
		return
	BadgeOverlay.remove(target)


static func build_friend_summary(friend_list: Dictionary, friend_inbox: Array) -> Dictionary:
	var unsent_gift_count: int = 0
	var friend_rows_variant: Variant = friend_list.get("friends", [])
	if friend_rows_variant is Array:
		for item_variant: Variant in friend_rows_variant:
			if not (item_variant is Dictionary):
				continue
			var item: Dictionary = item_variant
			if bool(item.get("giftSentToday", false)):
				continue
			unsent_gift_count += 1

	return {
		"hasSentGiftToday": bool(friend_list.get("hasSentGiftToday", false)),
		"unsentGiftCount": unsent_gift_count,
		"incomingRequestCount": friend_inbox.size(),
	}


static func build_party_summary(party_detail: Dictionary, party_cheer_status: Dictionary, party_applications: Array) -> Dictionary:
	var in_party: bool = not party_detail.is_empty()
	var free_cheer_available: bool = in_party and not bool(party_cheer_status.get("hasCheeredFree", false))
	var is_leader: bool = _is_current_party_leader(party_detail)
	var pending_review_count: int = 0

	if is_leader:
		for item_variant: Variant in party_applications:
			if not (item_variant is Dictionary):
				continue
			var item: Dictionary = item_variant
			if int(item.get("status", -1)) != 0:
				continue
			if int(item.get("applicationType", -1)) != 1:
				continue
			pending_review_count += 1

	return {
		"inParty": in_party,
		"isLeader": is_leader,
		"freeCheerAvailable": free_cheer_available,
		"pendingReviewCount": pending_review_count,
	}


static func has_friend_send_all_gift_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	var summary: Dictionary = game_state.friend_red_dot_summary
	var has_sent_gift_today: bool = bool(summary.get("hasSentGiftToday", false))
	var unsent_gift_count: int = int(summary.get("unsentGiftCount", 0))
	return not has_sent_gift_today and unsent_gift_count > 0


static func has_friend_request_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	var summary: Dictionary = game_state.friend_red_dot_summary
	return int(summary.get("incomingRequestCount", 0)) > 0


static func has_friend_red_dot() -> bool:
	return has_friend_send_all_gift_red_dot() or has_friend_request_red_dot()


static func has_party_free_cheer_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	var summary: Dictionary = game_state.party_red_dot_summary
	return bool(summary.get("freeCheerAvailable", false))


static func has_party_review_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	var summary: Dictionary = game_state.party_red_dot_summary
	return int(summary.get("pendingReviewCount", 0)) > 0


static func has_party_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	if not game_state.is_feature_unlocked("party"):
		return false
	return has_party_free_cheer_red_dot() or has_party_review_red_dot() or has_party_chat_red_dot()


static func has_mail_unread_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	return int(game_state.mail_summary_data.get("unreadCount", 0)) > 0


static func has_mail_claimable_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	return int(game_state.mail_summary_data.get("claimableCount", 0)) > 0


static func has_mail_red_dot() -> bool:
	return has_mail_unread_red_dot() or has_mail_claimable_red_dot()


static func has_scooper_achievement_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	for item_variant: Variant in game_state.scooper_achievement_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if can_claim_scooper_achievement(item):
			return true
	return false


static func has_scooper_memory_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null or game_state.player_data == null:
		return false
	var memory_shards: int = int(game_state.player_data.memory_shards)
	for item_variant: Variant in game_state.scooper_memory_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if can_unlock_scooper_memory(item, memory_shards):
			return true
	return false


static func has_scooper_equipment_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null or game_state.player_data == null:
		return false
	var scooper_level: int = int(game_state.player_data.scooper_level)
	var gold: int = int(game_state.player_data.gold)
	for item_variant: Variant in game_state.scooper_equipment_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if can_purchase_scooper_equipment(item, scooper_level, gold):
			return true
	return false


static func has_scooper_red_dot() -> bool:
	return has_scooper_achievement_red_dot() or has_scooper_memory_red_dot() or has_scooper_equipment_red_dot()


static func has_dungeon_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	for item_variant: Variant in game_state.dungeon_overview_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if has_dungeon_entry_red_dot(item):
			return true
	return false


static func has_arena_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	if not game_state.is_feature_unlocked("arena"):
		return false
	var ranks_variant: Variant = game_state.arena_overview_data.get("ranks", [])
	if not (ranks_variant is Array):
		return false
	for item_variant: Variant in ranks_variant:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if bool(item.get("isClaimable", false)):
			return true
	return false


static func has_expedition_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	var now_unix: int = int(Time.get_unix_time_from_system())
	for item_variant: Variant in game_state.expedition_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if bool(item.get("isClaimable", false)):
			return true
		if int(item.get("completesAtUnixSeconds", 0)) > 0 and now_unix >= int(item.get("completesAtUnixSeconds", 0)):
			return true
	return false


static func has_activity_red_dot() -> bool:
	return has_dungeon_red_dot() or has_arena_red_dot() or has_expedition_red_dot()


static func has_gacha_red_dot() -> bool:
	return has_gacha_free_pull_red_dot()


static func has_shop_free_bundle_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	var bundles_variant: Variant = game_state.shop_data.get("bundles", [])
	if not (bundles_variant is Array):
		return false
	for item_variant: Variant in bundles_variant:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if has_shop_bundle_red_dot(item):
			return true
	return false


static func has_shop_red_dot() -> bool:
	return has_shop_free_bundle_red_dot() or has_gacha_red_dot()


static func has_enhance_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	var owned_cats: Array = game_state.get_owned_cats()
	for cat_id_variant: Variant in owned_cats:
		var cat_id: String = str(cat_id_variant).strip_edges()
		if cat_id == "":
			continue
		var player_cat: PlayerCatData = game_state.get_player_cat(cat_id)
		if can_rank_up_cat(player_cat):
			return true
	return false


static func has_daily_task_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	if not game_state.is_feature_unlocked("daily_tasks"):
		return false
	return bool(game_state.daily_task_events_pending)


static func has_more_menu_red_dot() -> bool:
	return has_mail_red_dot() or has_friend_red_dot() or has_party_red_dot() or has_daily_task_red_dot()


static func has_party_chat_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	return int(game_state.chat_unread_counts.get("party", 0)) > 0


static func can_claim_scooper_achievement(item: Dictionary) -> bool:
	return bool(item.get("isCompleted", false)) and not bool(item.get("isClaimed", false))


static func can_unlock_scooper_memory(item: Dictionary, memory_shards_override: int = -1) -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null or game_state.player_data == null:
		return false
	if bool(item.get("isUnlocked", false)):
		return false
	if int(game_state.player_data.scooper_level) < int(item.get("unlockLevel", 1)):
		return false
	var memory_shards: int = memory_shards_override
	if memory_shards < 0:
		memory_shards = int(game_state.player_data.memory_shards)
	return memory_shards >= int(item.get("unlockCost", 0))


static func can_purchase_scooper_equipment(item: Dictionary, scooper_level_override: int = -1, gold_override: int = -1) -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null or game_state.player_data == null:
		return false
	if bool(item.get("isOwned", false)):
		return false
	var scooper_level: int = scooper_level_override
	if scooper_level < 0:
		scooper_level = int(game_state.player_data.scooper_level)
	if scooper_level < int(item.get("unlockLevel", 0)):
		return false
	var gold: int = gold_override
	if gold < 0:
		gold = int(game_state.player_data.gold)
	return gold >= int(item.get("purchaseCost", 0))


static func can_rank_up_cat(player_cat: PlayerCatDataRef) -> bool:
	if player_cat == null:
		return false
	var target_rank: int = int(player_cat.rank) + 1
	var required_shards: int = PlayerCatDataRef.rank_upgrade_cost(target_rank)
	return int(player_cat.cat_shards) >= required_shards


static func has_gacha_free_pull_red_dot() -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	return not bool(game_state.gacha_data.get("hasUsedFreePullToday", false))


static func has_dungeon_entry_red_dot(dungeon: Dictionary) -> bool:
	return int(dungeon.get("remainingTicketCount", 0)) > 0 or int(dungeon.get("remainingAdTicketCount", 0)) > 0


static func has_dungeon_action_red_dot(dungeon: Dictionary, action_key: String) -> bool:
	if not has_dungeon_entry_red_dot(dungeon):
		return false
	match action_key:
		"sweep":
			return int(dungeon.get("maxClearedFloor", 0)) > 0
		"challenge":
			return true
		_:
			return false


static func has_shop_bundle_red_dot(bundle: Dictionary) -> bool:
	if bool(bundle.get("isSoldOut", false)):
		return false
	return int(bundle.get("priceAmount", 0)) <= 0


static func has_shop_group_red_dot(tab_key: String, group_id: String) -> bool:
	var game_state: Node = _get_game_state()
	if game_state == null:
		return false
	for bundle_variant: Variant in game_state.shop_data.get("bundles", []):
		if not (bundle_variant is Dictionary):
			continue
		var bundle: Dictionary = bundle_variant
		if str(bundle.get("groupId", "")) != group_id:
			continue
		if tab_key != "" and str(bundle.get("categoryType", "")).to_lower() != tab_key.to_lower():
			continue
		if has_shop_bundle_red_dot(bundle):
			return true
	return false


static func _get_game_state() -> Node:
	var main_loop: MainLoop = Engine.get_main_loop()
	var scene_tree: SceneTree = main_loop as SceneTree
	if scene_tree == null:
		return null
	return scene_tree.root.get_node_or_null("GameState")


static func _is_current_party_leader(party_detail: Dictionary) -> bool:
	if party_detail.is_empty():
		return false
	var game_state: Node = _get_game_state()
	if game_state == null or game_state.player_data == null:
		return false
	var self_names: Array[String] = [
		str(game_state.player_data.display_name).strip_edges(),
		str(game_state.player_data.player_name).strip_edges(),
	]
	var leader_name: String = str(party_detail.get("leaderDisplayName", "")).strip_edges()
	return leader_name != "" and leader_name in self_names
