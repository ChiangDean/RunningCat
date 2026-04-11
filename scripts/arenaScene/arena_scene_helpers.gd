class_name ArenaSceneHelpers
extends RefCounted


static func get_team_member_player_cat_ids(team_type: String, fallback_team_type: String = "") -> Array:
	var team: Dictionary = GameState.get_team(team_type)
	var members: Array = team.get("members", [])
	if members.is_empty() and fallback_team_type != "":
		team = GameState.get_team(fallback_team_type)
		members = team.get("members", [])
	var player_cat_ids: Array = []
	for member_variant: Variant in members:
		if not (member_variant is Dictionary):
			continue
		var member: Dictionary = member_variant
		var player_cat_id := int(member.get("playerCatId", 0))
		if player_cat_id > 0:
			player_cat_ids.append(player_cat_id)
	return player_cat_ids


static func format_team_names_from_team(team_type: String, fallback_team_type: String = "", empty_text: String = "未設定") -> String:
	var team: Dictionary = GameState.get_team(team_type)
	var members: Array = team.get("members", [])
	if members.is_empty() and fallback_team_type != "":
		team = GameState.get_team(fallback_team_type)
		members = team.get("members", [])
	if members.is_empty():
		return empty_text
	return _format_member_names(members)


static func format_opponent_team(opponent: Dictionary) -> String:
	var members: Array = opponent.get("defenseMembers", [])
	if members.is_empty():
		return "未設定防守隊伍"
	return _format_member_names(members)


static func format_rewards(rewards: Array) -> String:
	var parts: Array[String] = []
	for reward_variant: Variant in rewards:
		if not (reward_variant is Dictionary):
			continue
		var reward: Dictionary = reward_variant
		var quantity := int(reward.get("quantity", 0))
		if quantity <= 0:
			continue
		var label := _get_reward_type_label(str(reward.get("rewardType", "")))
		parts.append("%s x%d" % [label, quantity])
	return "、".join(parts) if not parts.is_empty() else "無獎勵"


static func build_error_message(error: Dictionary) -> String:
	var message := str(error.get("message", "")).strip_edges()
	return message if message != "" else "請稍後再試。"


static func get_current_rank(overview: Dictionary) -> String:
	return str(overview.get("rankName", "青銅 III"))


static func get_current_score(overview: Dictionary) -> int:
	return int(overview.get("score", 0))


static func get_current_tickets(overview: Dictionary) -> int:
	return int(overview.get("tickets", 0))


static func _format_member_names(members: Array) -> String:
	var names: Array[String] = []
	for member_variant: Variant in members:
		if not (member_variant is Dictionary):
			continue
		var member: Dictionary = member_variant
		var level := int(member.get("catFoodLevel", 1))
		var cat_catalog_id := int(member.get("catCatalogId", 0))
		var cat_id := GameState.get_cat_file_id_by_catalog_id(cat_catalog_id)
		if cat_id == "":
			continue
		names.append(CatRegistry.get_cat_display_name_with_lv(cat_id, level))
	return "、".join(names) if not names.is_empty() else "未設定"


static func _get_reward_type_label(reward_type: String) -> String:
	match reward_type:
		"Diamond":
			return "鑽石"
		"TrapCage":
			return "陷阱籠"
		"CatFood":
			return "貓糧"
		"SpecialCatFood":
			return "特殊貓糧"
		_:
			return reward_type if reward_type != "" else "未知獎勵"
