class_name ArenaBattleScene
extends Node2D

const BATTLE_BG_TEXTURE := preload("res://assets/sprites/ui/battle_background_homey_v1.png")
const AdaptiveViewportScript = preload("res://scripts/ui/adaptive_viewport.gd")
const RESULT_VICTORY_TEXTURE := preload("res://assets/sprites/ui/results/victory_overlay_v1.png")
const RESULT_DEFEAT_TEXTURE := preload("res://assets/sprites/ui/results/defeat_overlay_v1.png")

const MAX_CATS_ON_FIELD := 5

const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0
const NAV_H := 110.0
const NAV_Y := SH - NAV_H

const SKILL_BAR_Y := BATTLE_Y + 10.0
const SKILL_SLOT_W := 100.0
const SKILL_SLOT_H := 90.0
const RESULT_OVERLAY_OFFSET_Y := -200.0
const RESULT_OVERLAY_START_SCALE := 0.56
const RESULT_OVERLAY_OVERSHOOT_SCALE := 1.10
const BATTLE_START_DELAY_SECONDS := 1.0

var _player_team: Node2D
var _enemy_team: Node2D
var _battle_manager: BattleManager

var _ui_layer: CanvasLayer
var _timer_label: Label
var _speed_1x: Button
var _speed_2x: Button
var _speed_3x: Button
var _skip_btn: Button
var _skill_bar: Control

var _opponent: Dictionary = {}
var _settling := false
var _tablet_decor_canvas: CanvasLayer
var _tablet_decor: TextureRect


func _ready() -> void:
	_build_tablet_decor()
	_sync_adaptive_layout()
	get_viewport().size_changed.connect(_sync_adaptive_layout)
	_opponent = GameState.arena_opponent
	_build_scene()
	_start_battle()


func _build_scene() -> void:
	_build_background()
	_build_battle_area()
	_build_ui()


func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = BATTLE_BG_TEXTURE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var bg_tint := ColorRect.new()
	bg_tint.color = Color(0.09, 0.05, 0.12, 0.28)
	bg_tint.size = Vector2(SW, SH)
	add_child(bg_tint)

	var ground := ColorRect.new()
	ground.color = Color(0.15, 0.11, 0.16, 0.52)
	ground.position = Vector2(0.0, BATTLE_Y)
	ground.size = Vector2(SW, NAV_Y - BATTLE_Y)
	add_child(ground)

	var wall_l := ColorRect.new()
	wall_l.color = Color(0.5, 0.2, 0.7, 0.0)
	wall_l.position = Vector2(-20.0, 200.0)
	wall_l.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(wall_l)

	var wall_r := ColorRect.new()
	wall_r.color = Color(0.5, 0.2, 0.7, 0.0)
	wall_r.position = Vector2(SW, 200.0)
	wall_r.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(wall_r)


func _build_battle_area() -> void:
	_player_team = Node2D.new()
	_player_team.position = Vector2(0.0, BATTLE_Y)
	add_child(_player_team)

	_enemy_team = Node2D.new()
	_enemy_team.position = Vector2(0.0, BATTLE_Y)
	add_child(_enemy_team)

	_battle_manager = BattleManager.new()
	add_child(_battle_manager)
	_battle_manager.battle_finished.connect(_on_battle_finished)


func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	AdaptiveViewportScript.apply_canvas_layer_origin(_ui_layer, self)
	add_child(_ui_layer)

	_speed_1x = _make_button("1x", Vector2(20.0, 20.0), Vector2(70.0, 44.0))
	_speed_2x = _make_button("2x", Vector2(95.0, 20.0), Vector2(70.0, 44.0))
	_speed_3x = _make_button("3x", Vector2(170.0, 20.0), Vector2(70.0, 44.0))
	_ui_layer.add_child(_speed_1x)
	_ui_layer.add_child(_speed_2x)
	_ui_layer.add_child(_speed_3x)
	_speed_1x.pressed.connect(_on_speed_1x_pressed)
	_speed_2x.pressed.connect(_on_speed_2x_pressed)
	_speed_3x.pressed.connect(_on_speed_3x_pressed)
	_apply_speed_unlocks()
	_highlight_speed_btn(_speed_1x)

	_timer_label = _make_label("60.0", Vector2(260.0, 20.0), Vector2(200.0, 50.0), 28)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_timer_label)

	_skip_btn = _make_button(UiText.HOME_SKIP, Vector2(SW - 100.0, 20.0), Vector2(80.0, 44.0))
	_ui_layer.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip_pressed)
	_skip_btn.visible = GameState.can_skip_battle()

	var my_overview := GameState.arena_overview_data
	var opp_score := int(_opponent.get("score", 0))
	const HEADER_Y := 74.0
	const HALF := SW / 2.0

	var my_name_lbl := _make_label(
		str(my_overview.get("playerName", GameState.player_data.player_name)),
		Vector2(10.0, HEADER_Y),
		Vector2(HALF - 30.0, 26.0),
		18
	)
	my_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ui_layer.add_child(my_name_lbl)

	var my_rank_lbl := _make_label(
		"%s  %d" % [str(my_overview.get("rankName", UiText.ARENA_DEFAULT_RANK)), int(my_overview.get("score", 0))],
		Vector2(10.0, HEADER_Y + 28.0),
		Vector2(HALF - 30.0, 22.0),
		14
	)
	my_rank_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	my_rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ui_layer.add_child(my_rank_lbl)

	var vs_lbl := _make_label("VS", Vector2(HALF - 20.0, HEADER_Y + 6.0), Vector2(40.0, 36.0), 22)
	vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	_ui_layer.add_child(vs_lbl)

	var opp_name_lbl := _make_label(
		str(_opponent.get("playerName", UiText.ARENA_UNKNOWN_OPPONENT)),
		Vector2(HALF + 20.0, HEADER_Y),
		Vector2(HALF - 30.0, 26.0),
		18
	)
	opp_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ui_layer.add_child(opp_name_lbl)

	var opp_rank_lbl := _make_label(
		"%s  %d" % [str(_opponent.get("rankName", UiText.ARENA_DEFAULT_RANK)), opp_score],
		Vector2(HALF + 20.0, HEADER_Y + 28.0),
		Vector2(HALF - 30.0, 22.0),
		14
	)
	opp_rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7))
	opp_rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ui_layer.add_child(opp_rank_lbl)

	_skill_bar = _build_skill_bar()
	_ui_layer.add_child(_skill_bar)

	var nav_bg := ColorRect.new()
	nav_bg.color = Color(0.1, 0.1, 0.12, 1.0)
	nav_bg.position = Vector2(0.0, NAV_Y)
	nav_bg.size = Vector2(SW, NAV_H)
	_ui_layer.add_child(nav_bg)

	var retreat_btn := _make_button(UiText.ARENA_BATTLE_RETURN_BUTTON, Vector2(10.0, NAV_Y + 10.0), Vector2(SW - 20.0, NAV_H - 20.0))
	retreat_btn.pressed.connect(_on_retreat_pressed)
	_ui_layer.add_child(retreat_btn)


func _build_skill_bar() -> Control:
	var bar := Control.new()
	bar.name = "SkillBar"
	var total_w := SKILL_SLOT_W * MAX_CATS_ON_FIELD + 8.0 * (MAX_CATS_ON_FIELD - 1)
	bar.position = Vector2((SW - total_w) / 2.0, SKILL_BAR_Y)
	bar.size = Vector2(total_w, SKILL_SLOT_H)

	for i in range(MAX_CATS_ON_FIELD):
		var slot := _make_skill_slot(i)
		slot.position = Vector2(i * (SKILL_SLOT_W + 8.0), 0.0)
		bar.add_child(slot)

	return bar


func _make_skill_slot(idx: int) -> Control:
	var slot := Control.new()
	slot.name = "Slot%d" % idx
	slot.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)

	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	bg.color = Color(0.15, 0.10, 0.20, 1.0)
	slot.add_child(bg)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(10.0, 8.0)
	icon.size = Vector2(SKILL_SLOT_W - 20.0, SKILL_SLOT_H - 36.0)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	slot.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.size = Vector2(SKILL_SLOT_W, 22.0)
	name_lbl.position = Vector2(0.0, SKILL_SLOT_H - 24.0)
	name_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_contents = true
	slot.add_child(name_lbl)

	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H - 24.0)
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.visible = false
	slot.add_child(overlay)

	var cd_lbl := Label.new()
	cd_lbl.name = "CdLabel"
	cd_lbl.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H - 24.0)
	cd_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_lbl.visible = false
	slot.add_child(cd_lbl)

	var buff_frame := ColorRect.new()
	buff_frame.name = "BuffFrame"
	buff_frame.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	buff_frame.color = Color(1.0, 0.85, 0.0, 0.0)
	buff_frame.visible = false
	slot.add_child(buff_frame)

	var border_color := Color(1.0, 0.85, 0.0, 1.0)
	var bt := 3.0
	for side in [
		[Vector2(0, 0), Vector2(SKILL_SLOT_W, bt)],
		[Vector2(0, SKILL_SLOT_H - bt), Vector2(SKILL_SLOT_W, bt)],
		[Vector2(0, 0), Vector2(bt, SKILL_SLOT_H)],
		[Vector2(SKILL_SLOT_W - bt, 0), Vector2(bt, SKILL_SLOT_H)],
	]:
		var border := ColorRect.new()
		border.position = side[0]
		border.size = side[1]
		border.color = border_color
		buff_frame.add_child(border)

	return slot


func _refresh_skill_bar_names(player_cats: Array) -> void:
	if _skill_bar == null:
		return
	for i in range(player_cats.size()):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node == null:
			continue
		var name_lbl: Label = slot_node.get_node_or_null("NameLabel")
		if name_lbl:
			var cat: CatData = player_cats[i]
			name_lbl.text = cat.active_skills_data[0].get("display_name", "") if cat.active_skills_data.size() > 0 else ""
	for i in range(player_cats.size(), MAX_CATS_ON_FIELD):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node:
			slot_node.visible = false


func _apply_equipment_bonuses(data: CatData) -> void:
	GameState.apply_player_combat_bonuses(data)


func _make_label(txt: String, pos: Vector2, sz: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	return lbl


func _make_button(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.position = pos
	btn.size = sz
	return btn


func _set_speed(mult: float, active_btn: Button) -> void:
	if mult > GameState.get_special_ability_speed_cap():
		return
	_battle_manager.set_speed(mult)
	_highlight_speed_btn(active_btn)


func _on_speed_1x_pressed() -> void:
	_set_speed(1.0, _speed_1x)


func _on_speed_2x_pressed() -> void:
	_set_speed(2.0, _speed_2x)


func _on_speed_3x_pressed() -> void:
	_set_speed(3.0, _speed_3x)


func _apply_speed_unlocks() -> void:
	var speed_cap: float = GameState.get_special_ability_speed_cap()
	_speed_2x.visible = speed_cap >= 2.0
	_speed_3x.visible = speed_cap >= 3.0


func _highlight_speed_btn(active: Button) -> void:
	for btn: Button in [_speed_1x, _speed_2x, _speed_3x]:
		if btn == null or not btn.visible:
			continue
		btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
	active.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _start_battle() -> void:
	await get_tree().create_timer(BATTLE_START_DELAY_SECONDS).timeout
	for child in _player_team.get_children():
		child.queue_free()
	for child in _enemy_team.get_children():
		child.queue_free()

	var player_cats: Array = []
	for i in range(GameState.player_team.size()):
		var player_cat_id := int(GameState.player_team[i])
		var cat_id := GameState.get_cat_file_id(player_cat_id)
		if cat_id.is_empty():
			continue
		var path := cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data == null:
			continue
		if data.active_skill_configs.size() > 0:
			data.active_skill_configs[0]["initial_delay"] = GameState.get_delay(i)
		var player_cat := GameState.get_player_cat(cat_id)
		data.apply_enhancement(player_cat)
		data.apply_rank_bonus(player_cat)
		_apply_equipment_bonuses(data)
		data._load_skill_data()
		if data.active_skills_data.size() > 0:
			data.active_skills_data[0]["initial_delay"] = GameState.get_delay(i)
		player_cats.append(data)

	var enemy_cats: Array = []
	for member_variant: Variant in _opponent.get("defenseMembers", []):
		if not (member_variant is Dictionary):
			continue
		var member: Dictionary = member_variant
		var cat_id := GameState.get_cat_file_id_by_catalog_id(int(member.get("catCatalogId", 0)))
		if cat_id.is_empty():
			continue
		var path := cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data == null:
			continue
		var enemy_cat := PlayerCatData.new()
		enemy_cat.cat_id = cat_id
		enemy_cat.cat_food_level = int(member.get("catFoodLevel", 1))
		enemy_cat.rank = int(member.get("rank", 0))
		data.apply_enhancement(enemy_cat)
		data.apply_rank_bonus(enemy_cat)
		data._load_skill_data()
		enemy_cats.append(data)

	if player_cats.is_empty() or enemy_cats.is_empty():
		DialogManager.show_info(UiText.ARENA_DIALOG_TITLE, UiText.ARENA_BATTLE_TEAM_DATA_ERROR, Callable(self, "_return_to_arena_scene"))
		return

	_refresh_skill_bar_names(player_cats)

	_battle_manager.setup([], player_cats, enemy_cats, _player_team, _enemy_team, _timer_label, _skill_bar)


func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()


func _on_battle_finished(result: String) -> void:
	_handle_result(result == "WIN")


func _handle_result(is_win: bool) -> void:
	if _settling:
		return
	_settling = true

	ApiClient.complete_arena_battle(
		str(_opponent.get("opponentId", "")),
		is_win,
		Callable(self, "_on_complete_arena_battle").bind(is_win)
	)


func _on_complete_arena_battle(success: bool, data: Variant, error: Dictionary, _is_win: bool) -> void:
	_settling = false
	if not success or not (data is Dictionary):
		DialogManager.show_info(
			UiText.ARENA_SETTLE_TITLE,
			str(error.get("message", UiText.ARENA_SETTLE_FAILED_BODY)),
			Callable(self, "_return_to_arena_scene")
		)
		return
	var response: Dictionary = data
	var overview: Dictionary = response.get("overview", {})
	if not overview.is_empty():
		GameState.update_arena(overview)
	_show_result_popup(response)


func _show_result_popup(response: Dictionary) -> void:
	var is_win := bool(response.get("isWin", false))
	var delta := int(response.get("scoreDelta", 0))
	var new_score := int(response.get("newScore", 0))
	var rank_name := str(response.get("rankName", UiText.ARENA_DEFAULT_RANK))
	var delta_str := ("+%d" % delta) if delta >= 0 else "%d" % delta
	var result_overlay: Control = _show_result_overlay(is_win)

	const POPUP_W := 440.0
	const POPUP_H := 228.0
	var popup := PanelContainer.new()
	popup.position = Vector2((SW - POPUP_W) / 2.0, 782.0)
	popup.custom_minimum_size = Vector2(POPUP_W, POPUP_H)
	_ui_layer.add_child(popup)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup.add_child(vbox)

	var rank_lbl := Label.new()
	rank_lbl.text = rank_name
	rank_lbl.add_theme_font_size_override("font_size", 26)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rank_lbl)

	var delta_lbl := Label.new()
	delta_lbl.text = UiText.ARENA_SCORE_DELTA_FORMAT % delta_str
	delta_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	delta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delta_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5) if delta >= 0 else Color(1.0, 0.4, 0.4))
	vbox.add_child(delta_lbl)

	var score_lbl := Label.new()
	score_lbl.text = UiText.ARENA_CURRENT_SCORE_FORMAT % GameState.format_number(new_score)
	score_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = UiText.ARENA_BATTLE_CLICK_RETURN
	hint_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint_lbl)

	var area := ColorRect.new()
	area.color = Color(0.0, 0.0, 0.0, 0.0)
	area.set_anchors_preset(Control.PRESET_FULL_RECT)
	area.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_layer.add_child(area)
	area.gui_input.connect(Callable(self, "_on_result_area_gui_input").bind(area, result_overlay, popup))


func _on_result_area_gui_input(event: InputEvent, area: ColorRect, result_overlay: Control, popup: PanelContainer) -> void:
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	area.queue_free()
	result_overlay.queue_free()
	popup.queue_free()
	_return_to_arena_scene()


func _return_to_arena_scene() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ArenaScene.tscn")


func _show_result_overlay(is_win: bool) -> Control:
	var overlay := Control.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(SW, SH)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.pivot_offset = Vector2(SW * 0.5, SH * 0.5)
	overlay.scale = Vector2(RESULT_OVERLAY_START_SCALE, RESULT_OVERLAY_START_SCALE)
	overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_ui_layer.add_child(overlay)

	var display := TextureRect.new()
	display.position = Vector2(0.0, RESULT_OVERLAY_OFFSET_Y)
	display.size = Vector2(SW, SH)
	display.texture = RESULT_VICTORY_TEXTURE if is_win else RESULT_DEFEAT_TEXTURE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay.add_child(display)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.10).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "scale", Vector2(RESULT_OVERLAY_OVERSHOOT_SCALE, RESULT_OVERLAY_OVERSHOOT_SCALE), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(overlay, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return overlay


func _on_retreat_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ArenaScene.tscn")


func _build_tablet_decor() -> void:
	_tablet_decor_canvas = CanvasLayer.new()
	_tablet_decor_canvas.layer = -100
	add_child(_tablet_decor_canvas)

	_tablet_decor = TextureRect.new()
	_tablet_decor.name = "TabletDecorBackground"
	_tablet_decor.texture = BATTLE_BG_TEXTURE
	_tablet_decor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tablet_decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tablet_decor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_tablet_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tablet_decor_canvas.add_child(_tablet_decor)


func _sync_adaptive_layout() -> void:
	AdaptiveViewportScript.apply_centered_node2d(self)
	AdaptiveViewportScript.apply_full_viewport(_tablet_decor, self)
	AdaptiveViewportScript.apply_canvas_layer_origin(_ui_layer, self)
