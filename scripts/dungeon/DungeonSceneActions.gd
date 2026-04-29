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

	DialogManager.show_confirm(
		UiText.DUNGEON_AD_CONFIRM_TITLE,
		UiText.DUNGEON_AD_CONFIRM_BODY,
		Callable(DungeonSceneActions, "_confirm_ad_ticket").bind(scene, dungeon_id),
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
		ToastManager.error(UiText.DUNGEON_ACTION_FAILED_TITLE, UiText.DUNGEON_AD_TICKET_EXHAUSTED)
		return

	DialogManager.show_confirm(
		UiText.DUNGEON_NO_TICKET_TITLE,
		UiText.DUNGEON_NO_TICKET_AD_BODY,
		Callable(DungeonSceneActions, "_confirm_prompt_ad_ticket").bind(scene, int(dungeon.get("dungeonId", 0)))
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
	if int(rewards.get("poopCount", 0)) > 0:
		lines.append(UiText.DUNGEON_REWARD_POOP_FORMAT % int(rewards.get("poopCount", 0)))
	if int(rewards.get("gold", 0)) > 0:
		lines.append(UiText.DUNGEON_REWARD_GOLD_FORMAT % int(rewards.get("gold", 0)))

	DialogManager.show_info(header, "\n".join(lines))


static func _confirm_ad_ticket(scene, dungeon_id: int) -> void:
	scene._action_inflight = true
	scene._rebuild_dungeon_panels()
	scene.ApiClient.grant_dungeon_ad_ticket(dungeon_id, Callable(scene, "_on_dungeon_overview_completed"))


static func _confirm_prompt_ad_ticket(scene, dungeon_id: int) -> void:
	scene._action_inflight = true
	scene._rebuild_dungeon_panels()
	scene.ApiClient.grant_dungeon_ad_ticket(
		dungeon_id,
		Callable(DungeonSceneActions, "_on_prompt_ad_ticket_completed").bind(scene)
	)


static func _on_prompt_ad_ticket_completed(success: bool, data: Variant, error: Dictionary, scene) -> void:
	scene._action_inflight = false
	if success and data is Dictionary:
		scene.GameState.apply_dungeon_overview(data)
		scene._rebuild_dungeon_panels()
		return
	var message: String = str(error.get("message", UiText.DUNGEON_ACTION_FAILED_DEFAULT))
	ToastManager.error(UiText.DUNGEON_ACTION_FAILED_TITLE, message)
	scene._rebuild_dungeon_panels()
