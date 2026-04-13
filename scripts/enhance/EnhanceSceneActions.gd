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
	scene._set_loading_overlay(true)
	scene._refresh_all_labels()
	scene.ApiClient.get_enhance_overview(Callable(scene, "_on_enhance_action_completed"))


static func run_enhance_action(scene, action: Callable, action_type: String = "", refresh_achievements: bool = false) -> void:
	if scene._action_inflight:
		return
	scene._prepare_action_feedback(action_type)
	scene._action_inflight = true
	scene._set_loading_overlay(true)
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
	scene._set_loading_overlay(false)
	if success and data is Dictionary:
		scene.GameState.apply_enhance_overview(data)
		scene._reset_special_point_draft()
		scene._populate_cat_buttons()
		scene._refresh_all_labels()
		scene._play_action_feedback()
		if refresh_achievements:
			scene.GameState.refresh_achievements()
		return

	var message := str(error.get("message", UiText.ENHANCE_ACTION_FAILED_DEFAULT))
	DialogManager.show_info(UiText.ENHANCE_ACTION_FAILED_TITLE, message)
	scene._refresh_all_labels()


static func on_upgrade_one_pressed(scene) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	run_enhance_action(
		scene,
		func(callback: Callable): scene.ApiClient.upgrade_cat_food(player_cat_id, callback),
		"upgrade",
		true)


static func on_upgrade_max_pressed(scene) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	var on_confirm := func():
		run_enhance_action(
			scene,
			func(callback: Callable): scene.ApiClient.upgrade_cat_food_to_max(player_cat_id, callback),
			"upgrade_max",
			true)
	scene._show_confirm(UiText.ENHANCE_FOOD_MAX_CONFIRM_BODY, on_confirm)


static func on_special_add_pressed(scene, stat_key: String) -> void:
	if scene._selected_cat_id == "":
		return
	var player_cat: PlayerCatData = scene.GameState.get_player_cat(scene._selected_cat_id)
	if player_cat == null:
		return
	var held: int = scene._get_effective_special_food_held(player_cat)
	var next_cost := PlayerCatData.special_food_next_cost(scene._get_effective_special_total_points(player_cat))
	if held < next_cost:
		return
	scene._special_point_draft[stat_key] = int(scene._special_point_draft.get(stat_key, 0)) + 1
	scene._refresh_all_labels()


static func on_special_remove_pressed(scene, stat_key: String) -> void:
	if scene._selected_cat_id == "":
		return
	var player_cat: PlayerCatData = scene.GameState.get_player_cat(scene._selected_cat_id)
	if player_cat == null:
		return
	var effective_points: Dictionary = scene._get_effective_special_points(player_cat)
	if int(effective_points.get(stat_key, 0)) <= 0:
		return
	scene._special_point_draft[stat_key] = int(scene._special_point_draft.get(stat_key, 0)) - 1
	scene._refresh_all_labels()


static func on_apply_special_points_pressed(scene) -> void:
	if scene._action_inflight or not scene._has_special_point_draft():
		return
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return

	var operations: Array[Dictionary] = []
	for stat_key: String in ["hp", "atk", "def"]:
		var delta: int = int(scene._special_point_draft.get(stat_key, 0))
		if delta < 0:
			for _i in range(-delta):
				operations.append({"kind": "remove", "stat_key": stat_key})
	for stat_key: String in ["hp", "atk", "def"]:
		var delta: int = int(scene._special_point_draft.get(stat_key, 0))
		if delta > 0:
			for _i in range(delta):
				operations.append({"kind": "add", "stat_key": stat_key})

	if operations.is_empty():
		scene._reset_special_point_draft()
		scene._refresh_all_labels()
		return

	scene._action_inflight = true
	scene._set_loading_overlay(true)
	scene._refresh_all_labels()
	_run_special_point_operations(scene, player_cat_id, operations, 0, {})


static func _run_special_point_operations(scene, player_cat_id: int, operations: Array[Dictionary], index: int, last_data: Dictionary) -> void:
	if index >= operations.size():
		scene._action_inflight = false
		scene._set_loading_overlay(false)
		if not last_data.is_empty():
			scene.GameState.apply_enhance_overview(last_data)
		scene._reset_special_point_draft()
		scene._populate_cat_buttons()
		scene._refresh_all_labels()
		return

	var operation: Dictionary = operations[index]
	var stat_key: String = str(operation.get("stat_key", ""))
	var callback := func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			scene._action_inflight = false
			scene._set_loading_overlay(false)
			var message := str(error.get("message", UiText.ENHANCE_ACTION_FAILED_DEFAULT))
			DialogManager.show_info(UiText.ENHANCE_ACTION_FAILED_TITLE, message)
			scene._refresh_all_labels()
			return
		var next_last_data: Dictionary = data if data is Dictionary else last_data
		_run_special_point_operations(scene, player_cat_id, operations, index + 1, next_last_data)

	if str(operation.get("kind", "")) == "remove":
		scene.ApiClient.remove_cat_special_point(player_cat_id, stat_key, callback)
	else:
		scene.ApiClient.add_cat_special_point(player_cat_id, stat_key, callback)


static func on_rank_upgrade_pressed(scene) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	run_enhance_action(
		scene,
		func(callback: Callable): scene.ApiClient.upgrade_cat_rank(player_cat_id, callback),
		"rank",
		true)


static func on_reset_pressed(scene) -> void:
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return

	var on_confirm := func():
		run_enhance_action(
			scene,
			func(callback: Callable): scene.ApiClient.reset_cat_enhance(player_cat_id, callback))

	scene._show_confirm(UiText.ENHANCE_RESET_CONFIRM_BODY, on_confirm)


static func on_reset_special_points_pressed(scene) -> void:
	if scene._action_inflight:
		return
	var player_cat_id := get_selected_player_cat_id(scene)
	if player_cat_id <= 0:
		return
	var player_cat: PlayerCatData = scene.GameState.get_player_cat(scene._selected_cat_id)
	if player_cat == null:
		return

	var operations: Array[Dictionary] = []
	for stat_key: String in ["hp", "atk", "def"]:
		var saved_points: int = int(player_cat.special_food_points.get(stat_key, 0))
		for _i in range(saved_points):
			operations.append({"kind": "remove", "stat_key": stat_key})

	if operations.is_empty():
		if scene._has_special_point_draft():
			scene._reset_special_point_draft()
			scene._refresh_all_labels()
		return

	var on_confirm := func():
		scene._action_inflight = true
		scene._set_loading_overlay(true)
		scene._reset_special_point_draft()
		scene._refresh_all_labels()
		_run_special_point_operations(scene, player_cat_id, operations, 0, {})
	scene._show_confirm(UiText.ENHANCE_RESET_SPECIAL_CONFIRM_BODY, on_confirm)
