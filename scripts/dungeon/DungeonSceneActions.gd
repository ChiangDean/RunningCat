class_name DungeonSceneActions
extends RefCounted


static func request_dungeon_overview(scene) -> void:
	scene._action_inflight = true
	scene._rebuild_dungeon_panels()
	scene.ApiClient.get_dungeon_overview(Callable(scene, "_on_dungeon_overview_completed"))


static func on_dungeon_overview_completed(scene, success: bool, data: Variant, error: Dictionary) -> void:
	scene._action_inflight = false
	if success and data is Dictionary:
		scene.GameState.apply_dungeon_overview(data)
		scene._rebuild_dungeon_panels()
		return

	var message: String = str(error.get("message", UiText.DUNGEON_FETCH_FAILED_DEFAULT))
	ToastManager.error(UiText.DUNGEON_FETCH_FAILED_TITLE, message)
	scene._rebuild_dungeon_panels()


static func on_dungeon_action_completed(scene, success: bool, data: Variant, error: Dictionary) -> void:
	scene._action_inflight = false
	if success and data is Dictionary:
		var response: Dictionary = data
		var overview: Variant = response.get("overview", {})
		if overview is Dictionary:
			scene.GameState.apply_dungeon_overview(overview)
		scene._rebuild_dungeon_panels()

		var reward: Variant = response.get("reward", {})
		if reward is Dictionary and not (reward as Dictionary).is_empty():
			var run_type: String = str(response.get("runType", ""))
			var target_floor: int = int(response.get("targetFloor", 0))
			var header: String = UiText.DUNGEON_SWEEP_COMPLETE if run_type == "Sweep" else UiText.DUNGEON_CHALLENGE_COMPLETE
			scene._show_reward_popup(header, target_floor, reward)
		return

	var message: String = str(error.get("message", UiText.DUNGEON_ACTION_FAILED_DEFAULT))
	ToastManager.error(UiText.DUNGEON_ACTION_FAILED_TITLE, message)
	scene._rebuild_dungeon_panels()


static func on_ad_pressed(scene, dungeon_id: int) -> void:
	if scene._action_inflight:
		return

	var on_confirm: Callable = func() -> void:
		scene._action_inflight = true
		scene._rebuild_dungeon_panels()
		scene.ApiClient.grant_dungeon_ad_ticket(dungeon_id, Callable(scene, "_on_dungeon_overview_completed"))

	DialogManager.show_confirm(
		UiText.DUNGEON_AD_CONFIRM_TITLE,
		UiText.DUNGEON_AD_CONFIRM_BODY,
		on_confirm,
		Callable(),
		UiText.COMMON_CANCEL,
		UiText.COMMON_CONFIRM
	)


static func on_sweep_pressed(scene, dungeon_id: int) -> void:
	if scene._action_inflight:
		return

	var dungeon: Dictionary = scene.GameState.get_dungeon_entry_by_id(dungeon_id)
	if dungeon.is_empty():
		return
	if int(dungeon.get("maxClearedFloor", 0)) <= 0:
		return
	if int(dungeon.get("remainingTicketCount", 0)) <= 0:
		_prompt_ad_ticket(scene, dungeon)
		return

	scene._action_inflight = true
	scene._rebuild_dungeon_panels()
	scene.ApiClient.sweep_dungeon(dungeon_id, Callable(scene, "_on_dungeon_action_completed"))


static func on_challenge_pressed(scene, dungeon_id: int) -> void:
	if scene._action_inflight:
		return

	var dungeon: Dictionary = scene.GameState.get_dungeon_entry_by_id(dungeon_id)
	if dungeon.is_empty():
		return
	if int(dungeon.get("remainingTicketCount", 0)) <= 0:
		_prompt_ad_ticket(scene, dungeon)
		return

	scene.GameState.dungeon_battle_id = str(dungeon_id)
	scene.GameState.dungeon_battle_key = str(dungeon.get("key", ""))
	scene.GameState.dungeon_battle_level = int(dungeon.get("maxClearedFloor", 0)) + 1

	var dungeon_team: Array = scene.GameState.player_data.dungeon_team
	if dungeon_team.is_empty():
		dungeon_team = scene.GameState.player_data.boss_team
	if not dungeon_team.is_empty():
		scene.GameState.player_team = dungeon_team.duplicate()

	scene.get_tree().change_scene_to_file("res://scenes/DungeonBattleScene.tscn")


static func _prompt_ad_ticket(scene, dungeon: Dictionary) -> void:
	var ad_count: int = int(dungeon.get("remainingAdTicketCount", 0))
	if ad_count <= 0:
		ToastManager.error(UiText.DUNGEON_ACTION_FAILED_TITLE, "\u4eca\u65e5\u88dc\u7968\u6b21\u6578\u5df2\u7528\u5b8c\u3002")
		return

	var on_confirm: Callable = func() -> void:
		scene._action_inflight = true
		scene._rebuild_dungeon_panels()
		scene.ApiClient.grant_dungeon_ad_ticket(int(dungeon.get("dungeonId", 0)), func(success: bool, data: Variant, error: Dictionary) -> void:
			scene._action_inflight = false
			if success and data is Dictionary:
				scene.GameState.apply_dungeon_overview(data)
				scene._rebuild_dungeon_panels()
				return
			var message: String = str(error.get("message", UiText.DUNGEON_ACTION_FAILED_DEFAULT))
			ToastManager.error(UiText.DUNGEON_ACTION_FAILED_TITLE, message)
			scene._rebuild_dungeon_panels()
		)

	DialogManager.show_confirm(
		"\u9580\u7968\u4e0d\u8db3",
		"\u76ee\u524d\u6c92\u6709\u9580\u7968\uff0c\u662f\u5426\u89c0\u770b\u5ee3\u544a\u88dc\u5145 1 \u5f35\u9580\u7968\u4e26\u7e7c\u7e8c\uff1f",
		on_confirm
	)


static func show_reward_popup(header: String, level: int, rewards: Dictionary) -> void:
	var lines: Array[String] = [UiText.DUNGEON_REWARD_LEVEL_FORMAT % level]
	if int(rewards.get("catFood", 0)) > 0:
		lines.append(UiText.DUNGEON_REWARD_CAT_FOOD_FORMAT % int(rewards.get("catFood", 0)))
	if int(rewards.get("specialCatFood", 0)) > 0:
		lines.append(UiText.DUNGEON_REWARD_SPECIAL_FOOD_FORMAT % int(rewards.get("specialCatFood", 0)))
	if int(rewards.get("diamonds", 0)) > 0:
		lines.append(UiText.DUNGEON_REWARD_DIAMONDS_FORMAT % int(rewards.get("diamonds", 0)))
	if int(rewards.get("trapCages", 0)) > 0:
		lines.append(UiText.DUNGEON_REWARD_TRAP_CAGE_FORMAT % int(rewards.get("trapCages", 0)))
	if int(rewards.get("whiskerShards", 0)) > 0:
		lines.append(UiText.DUNGEON_REWARD_WHISKER_FORMAT % int(rewards.get("whiskerShards", 0)))

	DialogManager.show_info(header, "\n".join(lines))
