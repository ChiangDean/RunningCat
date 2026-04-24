extends Control

const TRIAL_VERSION: int = 1
const SOFA_TRIAL_SECONDS: float = 60.0
const BATH_TICK_COUNT: int = 600
const BATH_BASE_DAMAGE: float = 2.0
const BATH_GROWTH_PER_TICK: float = 0.065
const SOFA_CARD_ART: String = "res://assets/sprites/ui/combat_trial/sofa_trial_card.svg"
const BATH_CARD_ART: String = "res://assets/sprites/ui/combat_trial/bath_trial_bg.svg"

var _sofa_best_label: Label
var _bath_best_label: Label
var _combat_best_label: Label
var _result_label: Label
var _progress_bar: ProgressBar
var _sofa_button: Button
var _bath_button: Button
var _trial_inflight: bool = false
var _pending_trial_type: String = ""
var _pending_score: int = 0


func _ready() -> void:
	_build_ui()
	_refresh_score_labels()


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "combat_trial", Callable(self, "_on_back_pressed"), {
		"show_dock": false,
	})
	var content_box: VBoxContainer = chrome.get("content_box") as VBoxContainer
	if content_box == null:
		return

	var header: VBoxContainer = VBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	content_box.add_child(header)

	var title: Label = Label.new()
	title.text = UiText.COMBAT_TRIAL_PAGE_TITLE
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	header.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.COMBAT_TRIAL_PAGE_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	desc.add_theme_color_override("font_color", Color(0.86, 0.78, 0.64, 1.0))
	header.add_child(desc)

	var score_row: HBoxContainer = HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 10)
	score_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_child(score_row)

	_sofa_best_label = _make_score_chip(score_row, UiText.COMBAT_TRIAL_SOFA_TITLE)
	_bath_best_label = _make_score_chip(score_row, UiText.COMBAT_TRIAL_BATH_TITLE)
	_combat_best_label = _make_score_chip(score_row, UiText.COMBAT_TRIAL_COMBAT_TITLE)

	var cards: HBoxContainer = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_child(cards)

	_sofa_button = _make_trial_card(
		cards,
		UiText.COMBAT_TRIAL_SOFA_TITLE,
		UiText.COMBAT_TRIAL_SOFA_DESC,
		SOFA_CARD_ART,
		UiText.COMBAT_TRIAL_START_SOFA,
		Callable(self, "_start_sofa_trial")
	)
	_bath_button = _make_trial_card(
		cards,
		UiText.COMBAT_TRIAL_BATH_TITLE,
		UiText.COMBAT_TRIAL_BATH_DESC,
		BATH_CARD_ART,
		UiText.COMBAT_TRIAL_START_BATH,
		Callable(self, "_start_bath_trial")
	)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0.0, 28.0)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiPalette.style_exp_progress_bar(_progress_bar, "normal")
	content_box.add_child(_progress_bar)

	_result_label = Label.new()
	_result_label.text = ""
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.74, 1.0))
	content_box.add_child(_result_label)


func _make_score_chip(parent: HBoxContainer, title_text: String) -> Label:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title_label: Label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.82, 0.72, 0.56, 1.0))
	box.add_child(title_label)

	var value_label: Label = Label.new()
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.82, 1.0))
	box.add_child(value_label)
	return value_label


func _make_trial_card(parent: HBoxContainer, title_text: String, body_text: String, art_path: String, button_text: String, pressed: Callable) -> Button:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var preview: TextureRect = TextureRect.new()
	preview.custom_minimum_size = Vector2(0.0, 190.0)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.texture = AssetResolver.resolve_preview_texture(art_path, "combat_trial")
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	box.add_child(preview)

	var title_label: Label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title_label)

	var body_label: Label = Label.new()
	body_label.text = body_text
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	body_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.70, 1.0))
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(body_label)

	var action_button: Button = Button.new()
	action_button.text = button_text
	action_button.custom_minimum_size = Vector2(0.0, 48.0)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.pressed.connect(pressed)
	UiPalette.apply_button_kind(action_button, "confirm")
	box.add_child(action_button)
	return action_button


func _start_sofa_trial() -> void:
	if _trial_inflight:
		return
	var cats: Array[CatData] = _resolve_trial_cats()
	if cats.is_empty():
		_show_message(UiText.COMBAT_TRIAL_TEAM_EMPTY)
		return
	var score: int = _calculate_sofa_score(cats)
	_run_trial_animation("sofa", score, UiText.COMBAT_TRIAL_RESULT_SOFA_FORMAT % GameState.format_number(score))


func _start_bath_trial() -> void:
	if _trial_inflight:
		return
	var cats: Array[CatData] = _resolve_trial_cats()
	if cats.is_empty():
		_show_message(UiText.COMBAT_TRIAL_TEAM_EMPTY)
		return
	var score: int = _calculate_bath_score(cats)
	_run_trial_animation("bath", score, UiText.COMBAT_TRIAL_RESULT_BATH_FORMAT % GameState.format_number(score))


func _run_trial_animation(trial_type: String, score: int, result_text: String) -> void:
	_trial_inflight = true
	_pending_trial_type = trial_type
	_pending_score = score
	_set_buttons_disabled(true)
	_progress_bar.value = 0.0
	_result_label.text = result_text

	var tween: Tween = create_tween()
	tween.tween_property(_progress_bar, "value", 100.0, 1.2)
	tween.finished.connect(_submit_pending_score)


func _submit_pending_score() -> void:
	_show_message(UiText.COMBAT_TRIAL_SAVING)
	ApiClient.submit_combat_trial_score(_pending_trial_type, _pending_score, TRIAL_VERSION, Callable(self, "_on_score_submitted"))


func _on_score_submitted(success: bool, data: Variant, _error: Dictionary) -> void:
	_trial_inflight = false
	_set_buttons_disabled(false)
	if success and data is Dictionary:
		GameState.apply_combat_trial_scores(data as Dictionary)
		_refresh_score_labels()
		return
	_show_message(UiText.COMBAT_TRIAL_SAVE_FAILED)


func _resolve_trial_cats() -> Array[CatData]:
	if GameState.player_team.is_empty():
		GameState.apply_active_team_from_config("Boss")

	var result: Array[CatData] = []
	for i: int in range(GameState.player_team.size()):
		var player_cat_id: int = int(GameState.player_team[i])
		var cat_id: String = GameState.get_cat_file_id(player_cat_id)
		if cat_id.is_empty():
			continue
		var data: CatData = CatData.from_json_file(cat_id + ".json")
		if data == null:
			continue
		var player_cat: PlayerCatData = GameState.get_player_cat(cat_id)
		data.apply_enhancement(player_cat)
		data.apply_rank_bonus(player_cat)
		GameState.apply_player_combat_bonuses(data)
		result.append(data)
	return result


func _calculate_sofa_score(cats: Array[CatData]) -> int:
	var total: float = 0.0
	for cat: CatData in cats:
		var crit_rate: float = clampf(float(cat.get_meta("crit_rate", 0.0)), 0.0, 1.0)
		var crit_damage_bonus: float = maxf(0.0, float(cat.get_meta("crit_damage_bonus", 0.0)))
		var crit_multiplier: float = 1.0 + crit_rate * (1.5 + crit_damage_bonus - 1.0)
		var speed_multiplier: float = 0.75 + clampf(cat.speed / 220.0, 0.25, 1.4)
		var cdr: float = clampf(float(cat.get_meta("cdr", 0.0)), 0.0, 0.5)
		var skill_multiplier: float = 1.0 + float(cat.active_skills_data.size()) * (0.18 + cdr * 0.5)
		total += float(cat.atk) * speed_multiplier * crit_multiplier * skill_multiplier * SOFA_TRIAL_SECONDS
	return maxi(0, roundi(total))


func _calculate_bath_score(cats: Array[CatData]) -> int:
	var hp_values: Array[float] = []
	var def_values: Array[float] = []
	var reduction_values: Array[float] = []
	for cat: CatData in cats:
		hp_values.append(float(cat.max_hp))
		def_values.append(float(cat.defense))
		reduction_values.append(clampf(float(cat.get_meta("damage_reduction_bonus", 0.0)), 0.0, 0.9))

	var pressure_score: float = 0.0
	for tick: int in range(BATH_TICK_COUNT):
		var alive_count: int = 0
		for hp: float in hp_values:
			if hp > 0.0:
				alive_count += 1
		if alive_count <= 0:
			break

		var raw_damage: float = BATH_BASE_DAMAGE + BATH_GROWTH_PER_TICK * float(tick)
		pressure_score += raw_damage * float(alive_count)

		for index: int in range(hp_values.size()):
			if hp_values[index] <= 0.0:
				continue
			var defense_reduction: float = def_values[index] / (def_values[index] + 120.0)
			var effective_damage: float = raw_damage * (1.0 - defense_reduction) * (1.0 - reduction_values[index])
			hp_values[index] = maxf(0.0, hp_values[index] - maxf(1.0, effective_damage))

	var remaining_hp: float = 0.0
	for hp: float in hp_values:
		remaining_hp += maxf(0.0, hp)
	if remaining_hp > 0.0:
		pressure_score += remaining_hp * 0.35
	return maxi(0, roundi(pressure_score))


func _refresh_score_labels() -> void:
	if _sofa_best_label != null:
		_sofa_best_label.text = _format_best(GameState.player_data.sofa_score)
	if _bath_best_label != null:
		_bath_best_label.text = _format_best(GameState.player_data.bath_score)
	if _combat_best_label != null:
		_combat_best_label.text = _format_best(GameState.player_data.combat_score)


func _format_best(value: int) -> String:
	if value <= 0:
		return UiText.COMBAT_TRIAL_UNTESTED
	return UiText.COMBAT_TRIAL_BEST_FORMAT % GameState.format_number(value)


func _show_message(message: String) -> void:
	if _result_label != null:
		_result_label.text = message


func _set_buttons_disabled(disabled: bool) -> void:
	if _sofa_button != null:
		_sofa_button.disabled = disabled
	if _bath_button != null:
		_bath_button.disabled = disabled


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
