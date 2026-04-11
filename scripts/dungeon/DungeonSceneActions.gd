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

	var message := str(error.get("message", "取得地城資料失敗。"))
	DialogManager.show_info("地城資料失敗", message)
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
			var run_type := str(response.get("runType", ""))
			var target_floor := int(response.get("targetFloor", 0))
			var header := "掃蕩完成" if run_type == "Sweep" else "挑戰完成"
			scene._show_reward_popup(header, target_floor, reward)
		return

	var message := str(error.get("message", "地城操作失敗。"))
	DialogManager.show_info("地城操作失敗", message)
	scene._rebuild_dungeon_panels()


static func on_ad_pressed(scene, dungeon_id: int) -> void:
	if scene._action_inflight:
		return

	DialogManager.show_confirm(
		"看廣告補票",
		"是否觀看廣告來補充 1 張地城門票？",
		func():
			scene._action_inflight = true
			scene._rebuild_dungeon_panels()
			scene.ApiClient.grant_dungeon_ad_ticket(dungeon_id, Callable(scene, "_on_dungeon_overview_completed")),
		Callable(),
		"取消",
		"確定")


static func on_sweep_pressed(scene, dungeon_id: int) -> void:
	if scene._action_inflight:
		return

	scene._action_inflight = true
	scene._rebuild_dungeon_panels()
	scene.ApiClient.sweep_dungeon(dungeon_id, Callable(scene, "_on_dungeon_action_completed"))


static func on_challenge_pressed(scene, dungeon_id: int) -> void:
	var dungeon: Dictionary = scene.GameState.get_dungeon_entry_by_id(dungeon_id)
	if dungeon.is_empty():
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


static func show_reward_popup(header: String, level: int, rewards: Dictionary) -> void:
	var lines: Array[String] = ["Lv.%d 獲得獎勵：" % level]
	if int(rewards.get("catFood", 0)) > 0:
		lines.append("  普通乾糧 ×%d" % int(rewards.get("catFood", 0)))
	if int(rewards.get("specialCatFood", 0)) > 0:
		lines.append("  特殊乾糧 ×%d" % int(rewards.get("specialCatFood", 0)))
	if int(rewards.get("diamonds", 0)) > 0:
		lines.append("  鑽石 ×%d" % int(rewards.get("diamonds", 0)))
	if int(rewards.get("trapCages", 0)) > 0:
		lines.append("  誘捕籠 ×%d" % int(rewards.get("trapCages", 0)))
	if int(rewards.get("whiskerShards", 0)) > 0:
		lines.append("  鬍鬚碎片 ×%d" % int(rewards.get("whiskerShards", 0)))

	DialogManager.show_info(header, "\n".join(lines))
