class_name ArenaSceneHelpers
extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")


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
		var player_cat_id: int = int(member.get("playerCatId", 0))
		if player_cat_id > 0:
			player_cat_ids.append(player_cat_id)
	return player_cat_ids


static func get_effective_team_type(team_type: String, fallback_team_type: String = "") -> String:
	var team: Dictionary = GameState.get_team(team_type)
	var members: Array = team.get("members", [])
	if not members.is_empty():
		return team_type
	if fallback_team_type == "":
		return ""
	var fallback_team: Dictionary = GameState.get_team(fallback_team_type)
	var fallback_members: Array = fallback_team.get("members", [])
	return fallback_team_type if not fallback_members.is_empty() else ""


static func format_team_names_from_team(team_type: String, fallback_team_type: String = "", empty_text: String = UiText.ARENA_UNSET_TEAM) -> String:
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
		return UiText.ARENA_UNSET_DEFENSE_TEAM
	return _format_member_names(members)


static func format_rewards(rewards: Array) -> String:
	var parts: Array[String] = []
	for reward_variant: Variant in rewards:
		if not (reward_variant is Dictionary):
			continue
		var reward: Dictionary = reward_variant
		var quantity: int = int(reward.get("quantity", 0))
		if quantity <= 0:
			continue
		var label: String = _get_reward_type_label(str(reward.get("rewardType", "")))
		parts.append("%s ×%d" % [label, quantity])
	return "、".join(parts) if not parts.is_empty() else UiText.COMMON_NO_REWARD


static func build_error_message(error: Dictionary) -> String:
	var message: String = str(error.get("message", "")).strip_edges()
	return message if message != "" else UiText.COMMON_TRY_AGAIN_LATER


static func get_current_rank(overview: Dictionary) -> String:
	return str(overview.get("rankName", UiText.ARENA_DEFAULT_RANK))


static func get_current_score(overview: Dictionary) -> int:
	return int(overview.get("score", 0))


static func get_current_tickets(overview: Dictionary) -> int:
	return int(overview.get("tickets", 0))


static func resolve_rank_texture(image_path: Variant, rank_key: Variant) -> Texture2D:
	var resolved_image_path: String = AssetResolver.resolve_catalog_path(image_path)
	var badge_texture: Texture2D = AssetResolver.load_texture(resolved_image_path)
	if badge_texture != null:
		return badge_texture

	var normalized_rank_key: String = str(rank_key if rank_key != null else "").strip_edges().to_lower()
	if normalized_rank_key == "":
		return null
	return AssetResolver.load_texture("res://assets/sprites/ui/arena_ranks/%s.png" % normalized_rank_key)


static func resolve_cat_icon_by_catalog_id(cat_catalog_id: int) -> Texture2D:
	var cat_id: String = GameState.get_cat_file_id_by_catalog_id(cat_catalog_id)
	if cat_id == "":
		return null
	return AssetResolver.resolve_cat_icon(cat_id)


static func get_name_fallback(display_name: String) -> String:
	var trimmed: String = display_name.strip_edges()
	if trimmed == "":
		return "?"
	return trimmed.left(1)


static func _format_member_names(members: Array) -> String:
	var names: Array[String] = []
	for member_variant: Variant in members:
		if not (member_variant is Dictionary):
			continue
		var member: Dictionary = member_variant
		var level: int = int(member.get("catFoodLevel", 1))
		var cat_catalog_id: int = int(member.get("catCatalogId", 0))
		var cat_id: String = GameState.get_cat_file_id_by_catalog_id(cat_catalog_id)
		if cat_id == "":
			continue
		names.append(CatRegistry.get_cat_display_name_with_lv(cat_id, level))
	return "、".join(names) if not names.is_empty() else UiText.ARENA_UNSET_TEAM


static func _get_reward_type_label(reward_type: String) -> String:
	match reward_type:
		"Diamond":
			return UiText.REWARD_DIAMONDS
		"TrapCage":
			return UiText.REWARD_TRAP_CAGE
		"CatFood":
			return UiText.REWARD_CAT_FOOD
		"SpecialCatFood":
			return UiText.REWARD_SPECIAL_CAT_FOOD
		_:
			return reward_type if reward_type != "" else UiText.COMMON_NO_REWARD
