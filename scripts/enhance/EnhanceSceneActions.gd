class_name EnhanceSceneActions
extends RefCounted


static func get_selected_player_cat_id(scene) -> int:
	for item: Variant in scene.GameState.enhance_data:
		if item is Dictionary:
			var row: Dictionary = item
			var cat_file_id = scene.GameState.get_cat_file_id_by_catalog_id(int(row.get("catCatalogId", 0)))
			if cat_file_id == scene._selected_cat_id:
				return int(row.get("playerCatId", 0))
	return 0


static func request_enhance_overview(scene) -> void:
	scene._action_inflight = true
	scene._refresh_all_labels()
	scene.ApiClient.get_enhance_overview(Callable(scene, "_on_enhance_action_completed"))


static func run_enhance_action(scene, action: Callable, refresh_achievements: bool = false) -> void:
	if scene._action_inflight:
		return
	scene._action_inflight = true
	scene._refresh_all_labels()
	action.call(Callable(scene, "_on_enhance_action_completed").bind(refresh_achievements))


static func on_enhance_action_completed(
	scene,
	success: bool,
	data: Variant,
	error: Dictionary,
	refresh_achievements: bool = false
) -> void:
	scene._action_inflight = false
	if success and data is Dictionary:
		scene.GameState.apply_enhance_overview(data)
		scene._populate_cat_buttons()
		scene._refresh_all_labels()
		if refresh_achievements:
			scene.GameState.refresh_achievements()
		return

	var message := str(error.get("message", "強化操作失敗"))
	DialogManager.show_info("強化失敗", message)
	scene._refresh_all_labels()


static func on_upgrade_one_pressed(scene) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	run_enhance_action(
		scene,
		func(callback: Callable): scene.ApiClient.upgrade_cat_food(player_cat_id, callback),
		true)


static func on_upgrade_max_pressed(scene) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	run_enhance_action(
		scene,
		func(callback: Callable): scene.ApiClient.upgrade_cat_food_to_max(player_cat_id, callback),
		true)


static func on_special_add_pressed(scene, stat_key: String) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	run_enhance_action(
		scene,
		func(callback: Callable): scene.ApiClient.add_cat_special_point(player_cat_id, stat_key, callback))


static func on_special_remove_pressed(scene, stat_key: String) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	run_enhance_action(
		scene,
		func(callback: Callable): scene.ApiClient.remove_cat_special_point(player_cat_id, stat_key, callback))


static func on_rank_upgrade_pressed(scene) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	run_enhance_action(
		scene,
		func(callback: Callable): scene.ApiClient.upgrade_cat_rank(player_cat_id, callback),
		true)


static func on_reset_pressed(scene) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return

	var on_confirm := func():
		run_enhance_action(
			scene,
			func(callback: Callable): scene.ApiClient.reset_cat_enhance(player_cat_id, callback))

	scene._show_confirm("確認要重置這隻貓咪的強化嗎？已投入的資源會依規則返還。", on_confirm)
