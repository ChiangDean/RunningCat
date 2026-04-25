extends Control

const BATTLE_BG_TEXTURE: Texture2D = preload("res://assets/sprites/ui/battle_background_homey_v1.png")
const SOFA_ICON_PATH: String = "res://assets/sprites/ui/combat_trial/sofa_icon.svg"
const BATH_BG_PATH: String = "res://assets/sprites/ui/combat_trial/bath_trial_bg.svg"
const SW: float = 720.0
const SH: float = 1280.0
const BATTLE_Y: float = 790.0
const SOFA_TRIAL_DURATION_SECONDS: float = 30.0
const BATH_TRIAL_DURATION_SECONDS: float = 30.0
const SOFA_HIT_INTERVAL_SECONDS: float = 0.42
const BATH_HIT_INTERVAL_SECONDS: float = 0.36

var _payload: Dictionary = {}
var _trial_type: String = ""
var _score: int = 0
var _trial_version: int = 1
var _result_text: String = ""
var _elapsed: float = 0.0
var _hit_elapsed: float = 0.0
var _displayed_score: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _submitted: bool = false
var _finished: bool = false
var _player_nodes: Array[CatNode] = []
var _player_home_positions: Array[Vector2] = []
var _battle_layer: Node2D
var _target_node: Node2D
var _progress_bar: ProgressBar
var _timer_label: Label
var _status_label: Label
var _score_label: Label
var _result_label: Label
var _skip_button: Button
var _return_button: Button
var _water_overlay: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_payload = GameState.get_combat_trial_battle_payload()
	if _payload.is_empty():
		SceneNavigator.open_overlay_scene("res://scenes/CombatTrialScene.tscn")
		return

	_trial_type = str(_payload.get("trialType", "sofa"))
	_score = int(_payload.get("score", 0))
	_trial_version = int(_payload.get("trialVersion", 1))
	_result_text = str(_payload.get("resultText", ""))
	_rng.randomize()
	_build_scene()
	_spawn_trial_units()


func _process(delta: float) -> void:
	if _finished:
		return

	_elapsed += delta
	_hit_elapsed += delta
	_update_progress()
	if _hit_elapsed >= _get_hit_interval_seconds():
		_hit_elapsed = 0.0
		_play_trial_tick()
	if _elapsed >= _get_trial_duration_seconds():
		_finish_trial_animation()


func _build_scene() -> void:
	_build_background()
	_battle_layer = Node2D.new()
	add_child(_battle_layer)
	_build_target()
	_water_overlay.move_to_front()
	_build_ui()


func _build_background() -> void:
	var bg: TextureRect = TextureRect.new()
	bg.texture = BATTLE_BG_TEXTURE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var tint: ColorRect = ColorRect.new()
	tint.color = Color(0.06, 0.05, 0.07, 0.22)
	tint.size = Vector2(SW, SH)
	add_child(tint)

	_water_overlay = ColorRect.new()
	_water_overlay.color = Color(0.28, 0.56, 1.0, 0.0)
	_water_overlay.position = Vector2.ZERO
	_water_overlay.size = Vector2(SW, SH)
	add_child(_water_overlay)


func _build_target() -> void:
	_target_node = Node2D.new()
	_target_node.position = Vector2(555.0, BATTLE_Y - 32.0)
	_battle_layer.add_child(_target_node)

	if _trial_type == "bath":
		_build_bath_target()
		return
	_build_sofa_target()


func _build_sofa_target() -> void:
	var sofa_texture: Texture2D = AssetResolver.resolve_preview_texture(SOFA_ICON_PATH, "combat_trial")
	if sofa_texture != null:
		var sofa: Sprite2D = Sprite2D.new()
		sofa.texture = sofa_texture
		sofa.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sofa.scale = Vector2(1.25, 1.25)
		_target_node.add_child(sofa)
		return

	var fallback: ColorRect = ColorRect.new()
	fallback.color = Color(0.55, 0.34, 0.18, 1.0)
	fallback.position = Vector2(-72.0, -72.0)
	fallback.size = Vector2(144.0, 96.0)
	_target_node.add_child(fallback)


func _build_bath_target() -> void:
	var bath_texture: Texture2D = AssetResolver.resolve_preview_texture(BATH_BG_PATH, "combat_trial")
	if bath_texture != null:
		var bath: Sprite2D = Sprite2D.new()
		bath.texture = bath_texture
		bath.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		bath.scale = Vector2(0.28, 0.28)
		bath.modulate = Color(1.0, 1.0, 1.0, 0.86)
		_target_node.add_child(bath)

	for index: int in range(6):
		var stream: Line2D = Line2D.new()
		stream.width = 5.0
		stream.default_color = Color(0.44, 0.76, 1.0, 0.78)
		var x: float = -110.0 + float(index) * 42.0
		stream.add_point(Vector2(x, -230.0))
		stream.add_point(Vector2(x - 18.0, -40.0))
		_target_node.add_child(stream)


func _build_ui() -> void:
	var title: Label = _make_label(_get_title_text(), Vector2(0.0, 36.0), Vector2(SW, 42.0), UiPalette.FONT_SIZE_DISPLAY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1.0))
	add_child(title)

	_status_label = _make_label(_get_status_text(), Vector2(40.0, 88.0), Vector2(SW - 80.0, 34.0), UiPalette.FONT_SIZE_BODY)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.68, 1.0))
	add_child(_status_label)

	_timer_label = _make_label("", Vector2(260.0, 132.0), Vector2(200.0, 38.0), UiPalette.FONT_SIZE_SUBHEADING)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_timer_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.position = Vector2(88.0, 184.0)
	_progress_bar.size = Vector2(544.0, 26.0)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.show_percentage = false
	UiPalette.style_exp_progress_bar(_progress_bar, "normal")
	add_child(_progress_bar)

	_score_label = _make_label("", Vector2(44.0, 226.0), Vector2(SW - 88.0, 42.0), UiPalette.FONT_SIZE_TITLE)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.62, 1.0))
	add_child(_score_label)

	_result_label = _make_label("", Vector2(44.0, 940.0), Vector2(SW - 88.0, 84.0), UiPalette.FONT_SIZE_TITLE)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.76, 1.0))
	add_child(_result_label)

	_skip_button = _make_button(UiText.COMBAT_TRIAL_BATTLE_SKIP, Vector2(112.0, 1058.0), Vector2(496.0, 54.0))
	_skip_button.pressed.connect(_finish_trial_animation)
	add_child(_skip_button)

	_return_button = _make_button(UiText.COMBAT_TRIAL_BATTLE_RETURN, Vector2(112.0, 1122.0), Vector2(496.0, 58.0))
	_return_button.visible = false
	_return_button.pressed.connect(_return_to_combat_trial)
	add_child(_return_button)
	_update_progress()


func _spawn_trial_units() -> void:
	if GameState.player_team.is_empty():
		GameState.apply_active_team_from_config("Boss")

	var team_size: int = mini(GameState.player_team.size(), 5)
	for index: int in range(team_size):
		var player_cat_id: int = int(GameState.player_team[index])
		var cat_id: String = GameState.get_cat_file_id(player_cat_id)
		if cat_id.is_empty():
			continue

		var cat_data: CatData = CatData.from_json_file(cat_id + ".json")
		if cat_data == null:
			continue
		var player_cat: PlayerCatData = GameState.get_player_cat(cat_id)
		cat_data.apply_enhancement(player_cat)
		cat_data.apply_rank_bonus(player_cat)
		GameState.apply_player_combat_bonuses(cat_data)

		var cat_node: CatNode = CatNode.new()
		var display_name: String = CatRegistry.get_cat_display_name_with_lv(cat_id, player_cat.cat_food_level)
		cat_node.setup(index, "player", display_name, cat_data.max_hp, cat_id)
		cat_node.position = Vector2(122.0 + float(index) * 92.0, BATTLE_Y)
		cat_node.scale = Vector2(0.92, 0.92)
		_battle_layer.add_child(cat_node)
		_player_nodes.append(cat_node)
		_player_home_positions.append(cat_node.position)


func _play_trial_tick() -> void:
	if _player_nodes.is_empty():
		return

	if _trial_type == "bath":
		_play_bath_tick()
		return
	_play_sofa_tick()


func _play_sofa_tick() -> void:
	var hit_index: int = floori(_elapsed / _get_hit_interval_seconds())
	var cat_node: CatNode = _player_nodes[hit_index % _player_nodes.size()]
	cat_node.play_skill()
	var start_x: float = cat_node.position.x
	var lunge_tween: Tween = create_tween()
	lunge_tween.tween_property(cat_node, "position:x", start_x + 26.0, 0.08)
	lunge_tween.tween_property(cat_node, "position:x", start_x, 0.14)

	var damage: int = _advance_displayed_score(_get_linear_progress())
	if damage > 0:
		_show_damage_label(damage, _target_node.global_position + Vector2(-34.0, -140.0))
	_pulse_target(Color(1.0, 0.72, 0.42, 1.0))


func _play_bath_tick() -> void:
	var pressure: float = _get_linear_progress()
	_water_overlay.color = Color(0.28, 0.56, 1.0, 0.08 + pressure * 0.18)
	var score_gain: int = _advance_displayed_score(pow(pressure, 1.35))
	var per_cat_damage: int = roundi(float(score_gain) / maxf(1.0, float(_player_nodes.size())))
	for index: int in range(_player_nodes.size()):
		var cat_node: CatNode = _player_nodes[index]
		cat_node.play_stagger()
		if per_cat_damage > 0:
			cat_node.show_damage_number(per_cat_damage)
		_scatter_bath_cat(cat_node, index, pressure)
	_pulse_target(Color(0.62, 0.86, 1.0, 1.0))


func _scatter_bath_cat(cat_node: CatNode, index: int, pressure: float) -> void:
	if index < 0 or index >= _player_home_positions.size():
		return
	var home_position: Vector2 = _player_home_positions[index]
	var scatter_x: float = _rng.randf_range(-42.0, 42.0) * (0.6 + pressure)
	var scatter_y: float = _rng.randf_range(-28.0, 16.0) * (0.6 + pressure)
	var target_position: Vector2 = home_position + Vector2(scatter_x, scatter_y)
	var tween: Tween = create_tween()
	tween.tween_property(cat_node, "position", target_position, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(cat_node, "position", home_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_damage_label(value: int, start_position: Vector2) -> void:
	var damage_label: Label = _make_label(GameState.format_number(value), start_position, Vector2(160.0, 42.0), UiPalette.FONT_SIZE_TITLE)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.28, 1.0))
	damage_label.add_theme_color_override("font_outline_color", Color(0.16, 0.06, 0.0, 1.0))
	damage_label.add_theme_constant_override("outline_size", 4)
	add_child(damage_label)

	var tween: Tween = create_tween()
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 80.0, 0.54).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.20).set_delay(0.34)
	tween.chain().tween_callback(Callable(damage_label, "queue_free"))


func _pulse_target(color: Color) -> void:
	if _target_node == null:
		return
	_target_node.modulate = color
	var tween: Tween = create_tween()
	tween.tween_property(_target_node, "scale", Vector2(1.08, 1.08), 0.08)
	tween.parallel().tween_property(_target_node, "modulate", Color.WHITE, 0.18)
	tween.tween_property(_target_node, "scale", Vector2.ONE, 0.12)


func _finish_trial_animation() -> void:
	if _submitted:
		return
	_submitted = true
	_finished = true
	_elapsed = _get_trial_duration_seconds()
	var final_gain: int = _advance_displayed_score(1.0)
	if final_gain > 0:
		if _trial_type == "bath":
			_show_final_bath_damage(final_gain)
		else:
			_show_damage_label(final_gain, _target_node.global_position + Vector2(-34.0, -140.0))
	_update_progress()
	_skip_button.disabled = true
	_result_label.text = _result_text
	_status_label.text = UiText.COMBAT_TRIAL_SAVING
	ApiClient.submit_combat_trial_score(_trial_type, _score, _trial_version, Callable(self, "_on_score_submitted"))


func _on_score_submitted(success: bool, data: Variant, _error: Dictionary) -> void:
	_skip_button.visible = false
	_return_button.visible = true
	if success and data is Dictionary:
		GameState.apply_combat_trial_scores(data as Dictionary)
		GameState.clear_combat_trial_battle_payload()
		_status_label.text = UiText.COMBAT_TRIAL_BATTLE_SAVED
		return
	_status_label.text = UiText.COMBAT_TRIAL_SAVE_FAILED


func _show_final_bath_damage(final_gain: int) -> void:
	if _player_nodes.is_empty():
		return
	var per_cat_damage: int = maxi(1, roundi(float(final_gain) / float(_player_nodes.size())))
	for cat_node: CatNode in _player_nodes:
		cat_node.play_stagger()
		cat_node.show_damage_number(per_cat_damage)


func _return_to_combat_trial() -> void:
	GameState.clear_combat_trial_battle_payload()
	SceneNavigator.open_overlay_scene("res://scenes/CombatTrialScene.tscn")


func _update_progress() -> void:
	var ratio: float = _get_linear_progress()
	if _progress_bar != null:
		_progress_bar.value = ratio * 100.0
	if _timer_label != null:
		_timer_label.text = "%.1f" % maxf(0.0, _get_trial_duration_seconds() - _elapsed)
	if _score_label != null:
		_score_label.text = _get_score_label_text()


func _advance_displayed_score(progress: float) -> int:
	var target_score: int = roundi(float(_score) * clampf(progress, 0.0, 1.0))
	target_score = mini(maxi(target_score, _displayed_score), _score)
	var gained_score: int = target_score - _displayed_score
	_displayed_score = target_score
	if _score_label != null:
		_score_label.text = _get_score_label_text()
	return gained_score


func _get_score_label_text() -> String:
	if _trial_type == "bath":
		return UiText.COMBAT_TRIAL_BATTLE_BATH_SCORE_FORMAT % GameState.format_number(_displayed_score)
	return UiText.COMBAT_TRIAL_BATTLE_SOFA_TOTAL_DAMAGE_FORMAT % GameState.format_number(_displayed_score)


func _get_linear_progress() -> float:
	return clampf(_elapsed / _get_trial_duration_seconds(), 0.0, 1.0)


func _get_trial_duration_seconds() -> float:
	if _trial_type == "bath":
		return BATH_TRIAL_DURATION_SECONDS
	return SOFA_TRIAL_DURATION_SECONDS


func _get_hit_interval_seconds() -> float:
	if _trial_type == "bath":
		return BATH_HIT_INTERVAL_SECONDS
	return SOFA_HIT_INTERVAL_SECONDS


func _get_title_text() -> String:
	if _trial_type == "bath":
		return UiText.COMBAT_TRIAL_BATTLE_BATH_TITLE
	return UiText.COMBAT_TRIAL_BATTLE_SOFA_TITLE


func _get_status_text() -> String:
	if _trial_type == "bath":
		return UiText.COMBAT_TRIAL_BATTLE_BATH_STATUS
	return UiText.COMBAT_TRIAL_BATTLE_SOFA_STATUS


func _make_label(text: String, position_value: Vector2, size_value: Vector2, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_button(text: String, position_value: Vector2, size_value: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = position_value
	button.size = size_value
	UiPalette.apply_button_kind(button, "confirm")
	return button
