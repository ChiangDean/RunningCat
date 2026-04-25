class_name BattleScene
extends Node2D

## Main home scene: battle view plus bottom navigation.

const BATTLE_BG_TEXTURE := preload("res://assets/sprites/ui/battle_background_homey_v1.png")
const AdaptiveViewportScript = preload("res://scripts/ui/adaptive_viewport.gd")
const OverlaySceneChromeRef = preload("res://scripts/ui/overlay_scene_chrome.gd")
const HOME_TOP_HUD_SCENE := preload("res://scenes/ui/home/HomeTopHudEditor.tscn")
const HOME_BOTTOM_HUD_SCENE := preload("res://scenes/ui/home/HomeBottomHudEditor.tscn")
const BOSS_WARNING_OVERLAY_SCENE := preload("res://scenes/ui/battle/BossWarningOverlayEditor.tscn")
const HOME_SCOOP_TEMPLATE_SCENE := preload("res://scenes/ui/home/HomeScoopButtonTemplate.tscn")
const ITEM_SLOT_TEMPLATE := preload("res://scenes/ui/ItemSlotTemplate.tscn")
const HOME_TOP_BAR_TEXTURE := preload("res://assets/sprites/ui/home/v2/home_hud_main_v3.png")
const HOME_LOWER_MENU_BG_TEXTURE := preload("res://assets/sprites/ui/home/v2/slices/background/home_lower_menu_background.png")
const HOME_LOWER_MENU_BG_SKILL_TEXTURE := preload("res://assets/sprites/ui/home/v2/slices/background/home_lower_menu_background_skill.png")
const HOME_LOWER_MAINMENU_BG_TEXTURE := preload("res://assets/sprites/ui/home/v2/slices/background/home_lower_mainmenu_background.png")
const HOME_SCOOP_SHEET_TEXTURE := preload("res://assets/sprites/ui/home/scooper/clean_litter_button_sheet.png")
const HOME_AUTO_SCOOP_TOGGLE_OFF_TEXTURE := preload("res://assets/sprites/ui/home/scooper/auto_scoop_toggle_off.svg")
const HOME_AUTO_SCOOP_TOGGLE_ON_TEXTURE := preload("res://assets/sprites/ui/home/scooper/auto_scoop_toggle_on.svg")
const HOME_MAIN_BUTTON_PANEL_TEXTURE := preload("res://assets/sprites/ui/home/v2/slices/main_buttons/main_button_panel_long_default.png")
const HOME_NAV_BUTTON_DEFAULT_TEXTURE := preload("res://assets/sprites/ui/home/v2/slices/main_buttons/main_button_default.png")
const HOME_NAV_BUTTON_ACTIVE_TEXTURE := preload("res://assets/sprites/ui/home/v2/slices/main_buttons/main_button_active.png")
const HOME_MORE_BUTTON_DEFAULT_TEXTURE := preload("res://assets/sprites/ui/home/v2/slices/main_buttons/main_button_default.png")
const HOME_MORE_BUTTON_ACTIVE_TEXTURE := preload("res://assets/sprites/ui/home/v2/slices/main_buttons/main_button_active.png")
const RESULT_VICTORY_TEXTURE := preload("res://assets/sprites/ui/results/victory_overlay_v1.png")
const RESULT_DEFEAT_TEXTURE := preload("res://assets/sprites/ui/results/defeat_overlay_v1.png")
const BOSS_WARNING_TEXTURE := preload("res://assets/sprites/ui/warning/boss_warning_compact_overlay_v1.png")
const RESOURCE_GOLD_TEXTURE := preload("res://assets/sprites/ui/rewards/gold.png.png")
const RESOURCE_DIAMOND_TEXTURE := preload("res://assets/sprites/ui/rewards/diamonds.png")
const RESOURCE_POOP_TEXTURE := preload("res://assets/sprites/ui/rewards/poop_count.png")
const PROFILE_AVATAR_TEXTURE := preload("res://assets/sprites/ui/character_refs/black_cat/black_cat_icon_v1.png")
const REWARD_DEFAULT_SFX := preload("res://assets/audio/sfx/rewards/ui_reward_float_default.mp3")
const REWARD_SFX_BY_KEY := {
	"gold": preload("res://assets/audio/sfx/rewards/reward_gold.mp3"),
	"diamonds": preload("res://assets/audio/sfx/rewards/reward_diamonds.mp3"),
	"poop": preload("res://assets/audio/sfx/rewards/reward_poop.mp3"),
	"cat_food": preload("res://assets/audio/sfx/rewards/reward_cat_food.mp3"),
	"whiskers": preload("res://assets/audio/sfx/rewards/reward_whiskers.mp3"),
	"exp": preload("res://assets/audio/sfx/rewards/reward_exp.mp3"),
	"memory_shards": preload("res://assets/audio/sfx/rewards/reward_memory_shards.mp3"),
}

const MAX_CATS_ON_FIELD: int = 5
const CHAT_SCENE_PATH := "res://scenes/ChatScene.tscn"
const MAIL_SCENE_PATH := "res://scenes/MailOverlayScene.tscn"
const FRIEND_SCENE_PATH := "res://scenes/FriendScene.tscn"
const PARTY_SCENE_PATH := "res://scenes/PartyScene.tscn"

const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0
const NAV_H := 110.0
const NAV_Y := SH - NAV_H
const HOME_LOWER_MENU_SUBMENU_RESERVE_H := OverlaySceneChromeRef.BOTTOM_DOCK_H
const HOME_NAV_BUTTON_SIZE := Vector2(126.0, 102.0)
const HOME_NAV_BUTTON_ROW_Y := 1162.0
const HOME_NAV_BUTTON_LABEL_Y := 56.0
const HOME_NAV_BUTTON_LABEL_H := 30.0
const HOME_NAV_BUTTON_FONT_SIZE := 15
const HOME_QUICK_BUTTON_SIZE := Vector2(92.0, 100.0)
const HOME_QUICK_BUTTON_LABEL_Y := 59.0
const HOME_QUICK_BUTTON_LABEL_H := 26.0
const HOME_QUICK_BUTTON_FONT_SIZE := 13
const HOME_MAIN_NAV_GAP_X := 10.0
const HOME_MORE_BUTTON_GAP_X := 10.0
const HOME_MORE_BUTTON_ROW_GAP_Y := 12.0
const HOME_MAIN_NAV_OFFSET_Y := -10.0
const HOME_MORE_MENU_OFFSET_Y := -30.0
const HOME_NAV_BG := Color(0.14, 0.10, 0.07, 0.96)
const HOME_NAV_BG_BORDER := Color(0.38, 0.27, 0.14, 0.96)
const HOME_NAV_LABEL_IDLE := Color(0.33, 0.20, 0.09, 1.0)
const HOME_NAV_LABEL_ACTIVE := Color(0.24, 0.14, 0.05, 1.0)
const HOME_NAV_LABEL_PRESSED := Color(0.56, 0.31, 0.10, 1.0)
const HOME_NAV_LABEL_OUTLINE := Color(0.98, 0.93, 0.84, 0.98)
const HOME_NAV_LABEL_MAIN_FONT_BOOST := 3
const HOME_NAV_LABEL_MORE_FONT_BOOST := 2
const HOME_NAV_LABEL_MAIN_OUTLINE_SIZE := 6
const HOME_NAV_LABEL_MORE_OUTLINE_SIZE := 5
const HOME_NAV_LABEL_MAIN_PAD_X := 6.0
const HOME_NAV_LABEL_MORE_PAD_X := 4.0
const HOME_NAV_LABEL_MAIN_PAD_Y := -2.0
const HOME_NAV_LABEL_MORE_PAD_Y := -2.0
const HOME_NAV_LABEL_MAIN_EXTRA_H := 6.0
const HOME_NAV_LABEL_MORE_EXTRA_H := 4.0
const HOME_NAV_LABEL_PRESSED_OFFSET_Y := 2.0
const SKILL_MODE_LABEL_IDLE := Color(0.37, 0.24, 0.12, 1.0)
const SKILL_MODE_LABEL_ACTIVE := Color(0.23, 0.14, 0.06, 1.0)
const SKILL_MODE_LABEL_PRESSED := Color(0.61, 0.34, 0.11, 1.0)
const SKILL_MODE_LABEL_OUTLINE := Color(0.98, 0.93, 0.84, 0.98)
const SKILL_MODE_LABEL_OUTLINE_SIZE := 5
const SKILL_MODE_LABEL_ACTIVE_OUTLINE_SIZE := 6
const SKILL_MODE_LABEL_FONT_BOOST := 2

# Skill bar baseline positioned just below BATTLE_Y.
const SKILL_BAR_Y := BATTLE_Y + 10.0
const SKILL_BAR_H := 126.0
const SKILL_SLOT_W := 132.0
const SKILL_SLOT_H := 126.0

# Stage and boss actions stay aligned with the result banner.
const STAGE_BTN_Y := 310.0
const TOP_BAR_FRAME_X := 26.0
const TOP_BAR_FRAME_Y := 18.0
const ACTION_STACK_X := 586.0
const ACTION_STACK_Y := 250.0
const ACTION_STACK_W := 96.0
const ACTION_STACK_H := 42.0
const SKILL_PANEL_CONTENT_PAD := 8.0
const SKILL_BAR_EDGE_PAD := 8.0
const SKILL_PANEL_X := 0.0
const SKILL_PANEL_W := SW
const SKILL_PANEL_Y := 790.0
const SKILL_PANEL_H := NAV_Y - SKILL_PANEL_Y
const SKILL_PANEL_ALL_H := NAV_Y - SKILL_PANEL_Y
const DEFAULT_FREE_SPEED_BOOST_MULT: float = 1.2
const FREE_SPEED_BOOST_DURATION_SECONDS: int = 30 * 60
const ENHANCE_APPLY_DISABLED_BG := Color(0.24, 0.21, 0.18, 0.86)
const ENHANCE_APPLY_DISABLED_FG := Color(0.72, 0.69, 0.64, 1.0)
const ENHANCE_DETAIL_TAB_ACTIVE_FILL := Color(0.43, 0.31, 0.14, 0.98)
const ENHANCE_DETAIL_TAB_ACTIVE_FG := Color(1.0, 0.95, 0.82, 1.0)
const IDLE_BAR_Y := 1054.0
const IDLE_BAR_W := 412.0
const IDLE_BAR_H := 18.0
const IDLE_PROGRESS_CAP_SECONDS := 8 * 3600.0
const HOME_SCOOP_PANEL_X := 154.0
const HOME_SCOOP_PANEL_Y := 1032.0
const HOME_SCOOP_PANEL_W := 412.0
const HOME_SCOOP_PANEL_H := 228.0
const HOME_SCOOP_COOLDOWN := 2.0
const HOME_SCOOP_FRAME_SIZE := Vector2i(256, 256)
const HOME_SCOOP_FRAME_COUNT := 14
const HOME_SCOOP_ANIMATION_START_FRAME := 1
const HOME_SCOOP_TEMPLATE_BUTTON_SIZE := Vector2(192.0, 192.0)
const HOME_SCOOP_TEMPLATE_BUTTON_OFFSET := Vector2(136.0, 0.0)
const HOME_SCOOP_TEMPLATE_ENHANCE_CENTER_OFFSET_X := 34.0
const HOME_SCOOP_TEMPLATE_COUNT_LABEL_OFFSET := Vector2(110, 145.0)
const HOME_SCOOP_TEMPLATE_COUNT_LABEL_SIZE := Vector2(88.0, 36.0)
const HOME_SCOOP_TEMPLATE_COUNT_LABEL_FONT_SIZE := 24
const HOME_SCOOP_TEMPLATE_COUNT_LABEL_OUTLINE_SIZE := 4
const HOME_SCOOP_TEMPLATE_RESULT_LABEL_OFFSET := Vector2(12.0, 196.0)
const HOME_SCOOP_TEMPLATE_RESULT_LABEL_SIZE := Vector2(212.0, 24.0)
const PARTY_CHEER_COUPON_REUSE_COOLDOWN_SECONDS := 2.0
const IDLE_CLAIM_RED_DOT_THRESHOLD_SECONDS := 4 * 3600
const IDLE_REWARD_GRID_COLUMNS := 5
const IDLE_REWARD_SLOT_SCALE := 0.24
const IDLE_REWARD_SLOT_CELL_SIZE := Vector2(122.0, 122.0)
const RESULT_OVERLAY_OFFSET_Y := -200.0
const RESULT_OVERLAY_START_SCALE := 0.56
const RESULT_OVERLAY_OVERSHOOT_SCALE := 1.10
const RESULT_OVERLAY_DISPLAY_SCALE := 0.8
const BOSS_WARNING_DURATION_SECONDS := 3.0
const BOSS_WARNING_DISPLAY_W := 700.0
const BOSS_WARNING_DISPLAY_H := 468.0
const BOSS_WARNING_DISPLAY_Y := 150.0
const BOSS_WARNING_FLASH_ALPHA := 0.52
const BOSS_WARNING_FLASH_DURATION := 0.18
const BOSS_WARNING_PULSE_SCALE := 1.07
const BOSS_WARNING_PULSE_DURATION := 0.22
const BOSS_WARNING_TEXT := UiText.BATTLE_BOSS_WARNING
const REWARD_FLOAT_START_Y := 620.0
const REWARD_FLOAT_RISE := 168.0
const REWARD_FLOAT_STEP_DELAY := 0.18
const REWARD_FLOAT_DURATION := 0.76
const REWARD_FLOAT_LABEL_SIZE := Vector2(360.0, 56.0)
const REWARD_FLOAT_DEFAULT_COLOR := Color(0.98, 0.92, 0.76, 1.0)
const REWARD_FLOAT_DEMO_ENABLED := false
const REWARD_FLOAT_DEMO_INTERVAL := 0.3

# Battle nodes
var _player_team: Node2D
var _enemy_team: Node2D
var _damage_fx_layer: Node2D
var _battle_manager: BattleManager

# UI nodes
var _ui_layer: Control
var _timer_label: Label
var _scoop_mode_btn: Button
var _skill_filter_btn: Button
var _speed_1x: Button
var _speed_2x: Button
var _speed_3x: Button
var _skip_btn: Button
var _level_label: Label
var _boss_btn: Button
var _result_display: TextureRect
var _result_backdrop: Control
var _boss_warning_overlay: Control
var _boss_warning_icon: TextureRect
var _boss_warning_text_label: Label
var _skill_panel: Control
var _skill_shadow: ColorRect
var _skill_body: ColorRect
var _skill_inner: ColorRect
var _skill_top_glow: ColorRect
var _skill_header_rule: ColorRect
var _skill_bar: Control      # Skill bar container
var _sandbox_btn: Button     # Idle rewards action button
var _mail_btn: TextureButton
var _mail_badge: Label

var _friend_btn: TextureButton
var _party_btn: TextureButton
var _chat_btn: TextureButton
var _backpack_btn: TextureButton
var _lineup_btn: TextureButton
var _chat_badge: Label
var _home_lower_mainmenu_bg: TextureRect
var _home_lower_menu_bg: TextureRect
var _home_main_button_panel: TextureRect
var _resource_value_labels: Dictionary = {}
var _battle_countdown_fill: ColorRect
var _profile_name_label: Label
var _profile_level_label: Label
var _top_exp_bar: ProgressBar
var _top_progress_value_label: Label
var _top_avatar_rect: TextureRect
var _cached_team_power: int = 0
var _reward_fx_layer: Control
var _reward_fx_canvas: CanvasLayer
var _reward_fx_queue: Array[Dictionary] = []
var _reward_fx_active: bool = false
var _reward_float_demo_index: int = 0
var _last_result: String = ""
var _home_scoop_panel: Control
var _home_exp_bar: ProgressBar
var _home_exp_label: Label
var _home_coupon_button: Button
var _home_scoop_button: TextureButton
var _home_scoop_result_label: Label
var _home_scoop_overlay: ColorRect
var _home_scoop_cd_label: Label
var _home_scoop_count_debug_frame: PanelContainer
var _home_scoop_count_label: Label
var _home_auto_scoop_toggle_button: TextureButton
var _home_auto_scoop_enabled: bool = false
var _home_scoop_frames: Array[Texture2D] = []
var _home_scoop_animation_active: bool = false
var _home_scoop_animation_elapsed: float = 0.0
var _home_scoop_frame_index: int = 0
var _home_scoop_cooldown_remaining: float = 0.0
var _home_scoop_request_in_flight: bool = false
var _home_scoop_response_ready: bool = false
var _home_scoop_profile_fetch_in_flight: bool = false
var _home_scoop_pending_profile: Dictionary = {}
var _home_scoop_pending_result: Dictionary = {}
var _home_scoop_pending_reward_entries: Array[Dictionary] = []
var _home_scoop_previous_profile: Dictionary = {}
var _home_scoop_previous_player_exp: int = 0
var _home_scoop_previous_player_memory_shards: int = 0
var _home_scoop_previous_player_whiskers: int = 0
var _party_cheer_coupon_cooldown_buttons: Array[Button] = []
var _nav_buttons: Dictionary = {}
var _nav_canvas: CanvasLayer
var _nav_more_button: TextureButton
var _home_more_buttons_layer: Control
var _home_more_dismiss_button: Button
var _home_more_buttons: Dictionary = {}
var _home_more_button_order: Array[String] = []
var _home_more_menu_expanded: bool = false
var _last_overlay_scene_path: String = ""
var _announcement_btn: TextureButton
var _stats_btn: TextureButton
var _bottom_hud_layout: Control
var _skill_filter_mode: String = "scoop"
var _startup_idle_rewards_dialog_checked: bool = false
var _current_speed_mult: float = 1.0
var _free_speed_boost_end_unix: int = 0
var _free_speed_boost_mult: float = 1.0
var _free_speed_boost_used: bool = false
var _boss_warning_flash_tween: Tween
var _boss_warning_pulse_tween: Tween
var _current_enemy_cats: Array = []
var _adaptive_content_origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("battle_scene")
	_build_home_scoop_frames()
	GameState.player_profile_changed.connect(_on_player_profile_changed)
	GameState.player_wallet_changed.connect(_on_player_wallet_changed)
	GameState.combat_trial_score_changed.connect(_on_combat_trial_score_changed)
	GameState.red_dot_state_changed.connect(_on_red_dot_state_changed)
	_build_scene()
	call_deferred("_show_pending_combat_power_change")
	_refresh_home_red_dots()
	UiAudio.stop_bgm()
	_start_battle()
	call_deferred("_show_startup_idle_rewards_dialog_if_needed")
	# Update the idle button text every second.
	var sandbox_timer := Timer.new()
	sandbox_timer.wait_time = 1.0
	sandbox_timer.autostart = true
	sandbox_timer.timeout.connect(_refresh_sandbox_btn)
	add_child(sandbox_timer)

	if REWARD_FLOAT_DEMO_ENABLED:
		var reward_demo_timer := Timer.new()
		reward_demo_timer.wait_time = REWARD_FLOAT_DEMO_INTERVAL
		reward_demo_timer.autostart = true
		reward_demo_timer.timeout.connect(_play_reward_float_demo_tick)
		add_child(reward_demo_timer)


func set_adaptive_content_origin(origin: Vector2) -> void:
	_adaptive_content_origin = origin
	_apply_adaptive_content_origin()


func _apply_adaptive_content_origin() -> void:
	if _nav_canvas != null:
		_nav_canvas.offset = _adaptive_content_origin
	if _reward_fx_canvas != null:
		_reward_fx_canvas.offset = _adaptive_content_origin


func _process(_delta: float) -> void:
	if _battle_countdown_fill == null or _timer_label == null:
		pass
	else:
		var remaining := _timer_label.text.to_float()
		var fill_ratio := clampf(remaining / 60.0, 0.0, 1.0)
		_battle_countdown_fill.size.x = 286.0 * fill_ratio

	if _home_scoop_cooldown_remaining > 0.0:
		_home_scoop_cooldown_remaining = maxf(0.0, _home_scoop_cooldown_remaining - _delta)
		_refresh_home_scoop_panel()
	_update_party_cheer_coupon_cooldowns(_delta)
	if _home_scoop_animation_active:
		_update_home_scoop_animation(_delta)
	_update_home_auto_scoop()

	_refresh_speed_boost_state()

	var overlay_scene_path: String = SceneNavigator.get_current_overlay_scene_path()
	if overlay_scene_path != _last_overlay_scene_path:
		_last_overlay_scene_path = overlay_scene_path
		_refresh_main_nav_state()
		_refresh_overlay_fx_state()
		_refresh_home_red_dots()
		_refresh_sandbox_btn()


# Scene construction

func _build_scene() -> void:
	_init_bottom_hud_layout()
	_build_background()
	_build_home_lower_mainmenu_underlay()
	_build_home_lower_menu_underlay()
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
	bg_tint.color = Color(0.08, 0.06, 0.10, 0.24)
	bg_tint.size = Vector2(SW, SH)
	add_child(bg_tint)

	var ground := ColorRect.new()
	ground.color = Color(0.16, 0.13, 0.12, 0.0)
	ground.position = Vector2(0.0, BATTLE_Y)
	ground.size = Vector2(SW, NAV_Y - BATTLE_Y)
	add_child(ground)

	var wall_l := ColorRect.new()
	wall_l.color = Color(0.34, 0.24, 0.6, 0.0)
	wall_l.position = Vector2(-20.0, 200.0)
	wall_l.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(wall_l)

	var wall_r := ColorRect.new()
	wall_r.color = Color(0.34, 0.24, 0.6, 0.0)
	wall_r.position = Vector2(SW, 200.0)
	wall_r.size = Vector2(20.0, BATTLE_Y - 200.0)
	add_child(wall_r)


func _init_bottom_hud_layout() -> void:
	_bottom_hud_layout = HOME_BOTTOM_HUD_SCENE.instantiate() as Control


func _get_bottom_hud_control(path: String) -> Control:
	if _bottom_hud_layout == null:
		return null
	return _bottom_hud_layout.get_node_or_null(path) as Control


func _get_bottom_hud_position(path: String, fallback: Vector2) -> Vector2:
	var control: Control = _get_bottom_hud_control(path)
	return control.position if control != null else fallback


func _get_bottom_hud_size(path: String, fallback: Vector2) -> Vector2:
	var control: Control = _get_bottom_hud_control(path)
	return control.size if control != null else fallback


func _get_bottom_hud_font_size(path: String, fallback: int) -> int:
	var control: Control = _get_bottom_hud_control(path)
	if control == null:
		return fallback
	if control.has_theme_font_size_override("font_size"):
		return control.get_theme_font_size("font_size")
	return fallback


func _apply_bottom_hud_font_size(control: Control, path: String, fallback: int) -> void:
	if control == null:
		return
	control.add_theme_font_size_override("font_size", _get_bottom_hud_font_size(path, fallback))


func _get_control_font_size(control: Control, fallback: int) -> int:
	if control == null:
		return fallback
	return control.get_theme_font_size("font_size") if control.has_theme_font_size_override("font_size") else fallback


func _apply_fredoka_font(control: Control, fallback: int, weight: String = "medium") -> void:
	if control == null:
		return
	var font_size: int = _get_control_font_size(control, fallback)
	match weight:
		"bold":
			UiFonts.apply_fredoka_bold(control, font_size)
		"semibold":
			UiFonts.apply_fredoka_semibold(control, font_size)
		"regular":
			UiFonts.apply_fredoka_regular(control, font_size)
		_:
			UiFonts.apply_fredoka_medium(control, font_size)


func _apply_home_hud_fonts() -> void:
	_apply_fredoka_font(_profile_level_label, 28, "bold")
	_apply_fredoka_font(_top_progress_value_label, 16, "medium")
	_apply_fredoka_font(_timer_label, 18, "medium")
	_apply_fredoka_font(_home_scoop_cd_label, _get_bottom_hud_font_size("HomeScoopPanel/ScoopButton/CooldownLabel", 20), "bold")
	_apply_fredoka_font(_home_scoop_count_label, _get_bottom_hud_font_size("HomeScoopPanel/ScoopButton/CountLabel", 24), "bold")
	for resource_label_variant: Variant in _resource_value_labels.values():
		var resource_label: Label = resource_label_variant as Label
		_apply_fredoka_font(resource_label, 18, "medium")


func _get_bottom_hud_average_rect(paths: Array[String], fallback: Rect2) -> Rect2:
	var match_count: int = 0
	var total_pos: Vector2 = Vector2.ZERO
	var total_size: Vector2 = Vector2.ZERO
	for path: String in paths:
		var control: Control = _get_bottom_hud_control(path)
		if control == null:
			continue
		match_count += 1
		total_pos += control.position
		total_size += control.size
	if match_count <= 0:
		return fallback
	return Rect2(total_pos / float(match_count), total_size / float(match_count))


func _get_bottom_hud_average_gap_x(paths: Array[String], fallback: float = 0.0) -> float:
	var previous_rect: Rect2 = Rect2()
	var has_previous: bool = false
	var gap_sum: float = 0.0
	var gap_count: int = 0
	for path: String in paths:
		var control: Control = _get_bottom_hud_control(path)
		if control == null:
			continue
		var current_rect: Rect2 = Rect2(control.position, control.size)
		if has_previous:
			gap_sum += current_rect.position.x - (previous_rect.position.x + previous_rect.size.x)
			gap_count += 1
		previous_rect = current_rect
		has_previous = true
	if gap_count <= 0:
		return fallback
	return gap_sum / float(gap_count)


func _get_bottom_hud_bounds_rect(paths: Array[String], fallback: Rect2) -> Rect2:
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	var match_count: int = 0
	for path: String in paths:
		var control: Control = _get_bottom_hud_control(path)
		if control == null:
			continue
		match_count += 1
		min_x = minf(min_x, control.position.x)
		min_y = minf(min_y, control.position.y)
		max_x = maxf(max_x, control.position.x + control.size.x)
		max_y = maxf(max_y, control.position.y + control.size.y)
	if match_count <= 0:
		return fallback
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _build_uniform_horizontal_layout(paths: Array[String], fallback_bounds: Rect2, fallback_button_size: Vector2, gap_override: float = -1.0) -> Dictionary:
	var layout: Dictionary = {}
	if paths.is_empty():
		return layout
	var bounds: Rect2 = fallback_bounds
	var average_rect: Rect2 = _get_bottom_hud_average_rect(paths, Rect2(Vector2.ZERO, fallback_button_size))
	var button_size: Vector2 = average_rect.size
	if bounds.size.y > 0.0:
		button_size.y = minf(button_size.y, bounds.size.y)
	var gap: float = gap_override if gap_override >= 0.0 else 0.0
	if paths.size() > 1:
		if gap_override < 0.0:
			gap = (bounds.size.x - button_size.x * paths.size()) / float(paths.size() - 1)
		if gap < 0.0:
			button_size.x = bounds.size.x / float(paths.size())
			gap = 0.0
	var row_width: float = button_size.x * paths.size() + gap * float(maxi(paths.size() - 1, 0))
	if row_width > bounds.size.x:
		button_size.x = maxf(0.0, (bounds.size.x - gap * float(maxi(paths.size() - 1, 0))) / float(paths.size()))
		row_width = button_size.x * paths.size() + gap * float(maxi(paths.size() - 1, 0))
	var start_x: float = bounds.position.x + (bounds.size.x - row_width) * 0.5
	var y: float = bounds.position.y + (bounds.size.y - button_size.y) * 0.5
	for i in range(paths.size()):
		var x: float = start_x + i * (button_size.x + gap)
		layout[paths[i]] = Rect2(Vector2(x, y), button_size)
	return layout


func _build_wrapped_button_layout(item_count: int, bounds: Rect2, button_size: Vector2, max_columns: int, gap_x: float = 0.0, gap_y: float = 0.0, align_right: bool = false) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if item_count <= 0:
		return rects
	var clamped_columns: int = maxi(max_columns, 1)
	var row_counts: Array[int] = []
	var row_total: int = int(ceili(float(item_count) / float(clamped_columns)))
	for row_index in range(row_total):
		var items_before_row: int = row_index * clamped_columns
		var row_count: int = mini(clamped_columns, item_count - items_before_row)
		row_counts.append(row_count)
	for row_index in range(row_counts.size()):
		var row_count: int = row_counts[row_index]
		var effective_gap_x: float = gap_x
		var effective_button_width: float = button_size.x
		var row_width: float = effective_button_width * row_count + effective_gap_x * float(maxi(row_count - 1, 0))
		if row_width > bounds.size.x:
			effective_button_width = maxf(0.0, (bounds.size.x - effective_gap_x * float(maxi(row_count - 1, 0))) / float(row_count))
			row_width = effective_button_width * row_count + effective_gap_x * float(maxi(row_count - 1, 0))
		var start_x: float = bounds.position.x + (bounds.size.x - row_width) * 0.5
		if align_right:
			start_x = bounds.position.x + bounds.size.x - row_width
		var y: float = bounds.position.y + row_index * (button_size.y + gap_y)
		for column_index in range(row_count):
			var x: float = start_x + column_index * (effective_button_width + effective_gap_x)
			rects.append(Rect2(Vector2(x, y), Vector2(effective_button_width, button_size.y)))
	return rects


func _apply_texture_button_label_rect(button: TextureButton, label_rect: Rect2) -> void:
	if button == null:
		return
	var label: Label = button.get_meta("label_node", null) as Label
	if label == null:
		return
	var is_main_nav: bool = bool(button.get_meta("is_main_nav", false))
	var label_pad_x: float = HOME_NAV_LABEL_MAIN_PAD_X if is_main_nav else HOME_NAV_LABEL_MORE_PAD_X
	var label_pad_y: float = HOME_NAV_LABEL_MAIN_PAD_Y if is_main_nav else HOME_NAV_LABEL_MORE_PAD_Y
	var label_extra_h: float = HOME_NAV_LABEL_MAIN_EXTRA_H if is_main_nav else HOME_NAV_LABEL_MORE_EXTRA_H
	var adjusted_rect: Rect2 = Rect2(
		Vector2(label_rect.position.x + label_pad_x, label_rect.position.y + label_pad_y),
		Vector2(maxf(0.0, label_rect.size.x - label_pad_x * 2.0), label_rect.size.y + label_extra_h)
	)
	button.set_meta("label_base_rect", adjusted_rect)
	label.position = adjusted_rect.position
	label.size = adjusted_rect.size
	_refresh_home_quick_button_visual(button)


func _build_home_lower_mainmenu_underlay() -> void:
	_home_lower_mainmenu_bg = TextureRect.new()
	_home_lower_mainmenu_bg.name = "HomeLowerMainmenuBackground"
	_home_lower_mainmenu_bg.texture = HOME_LOWER_MAINMENU_BG_TEXTURE
	_home_lower_mainmenu_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_home_lower_mainmenu_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_home_lower_mainmenu_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_home_lower_mainmenu_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_home_lower_mainmenu_underlay()
	add_child(_home_lower_mainmenu_bg)


func _layout_home_lower_mainmenu_underlay() -> void:
	if _home_lower_mainmenu_bg == null:
		return
	var editor_size: Vector2 = _get_bottom_hud_size("LowerMainmenuBackground", Vector2.ZERO)
	if editor_size != Vector2.ZERO:
		_home_lower_mainmenu_bg.size = editor_size
		_home_lower_mainmenu_bg.position = _get_bottom_hud_position("LowerMainmenuBackground", Vector2.ZERO)
		return
	var scaled_size: Vector2 = _get_width_fitted_texture_size(HOME_LOWER_MAINMENU_BG_TEXTURE)
	if scaled_size.y <= 0.0:
		_home_lower_mainmenu_bg.position = Vector2.ZERO
		_home_lower_mainmenu_bg.size = Vector2(SW, 0.0)
		return
	_home_lower_mainmenu_bg.size = scaled_size
	_home_lower_mainmenu_bg.position = Vector2(
		(SW - scaled_size.x) * 0.5,
		SH - scaled_size.y
	)


func _build_home_lower_menu_underlay() -> void:
	_home_lower_menu_bg = TextureRect.new()
	_home_lower_menu_bg.name = "HomeLowerMenuBackground"
	_home_lower_menu_bg.texture = _get_home_lower_menu_background_texture()
	_home_lower_menu_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_home_lower_menu_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_home_lower_menu_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_home_lower_menu_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_home_lower_menu_underlay()
	add_child(_home_lower_menu_bg)


func _layout_home_lower_menu_underlay() -> void:
	if _home_lower_menu_bg == null:
		return
	_home_lower_menu_bg.texture = _get_home_lower_menu_background_texture()
	var editor_size: Vector2 = _get_bottom_hud_size("LowerMenuBackground", Vector2.ZERO)
	if editor_size != Vector2.ZERO:
		_home_lower_menu_bg.size = editor_size
		_home_lower_menu_bg.position = _get_bottom_hud_position("LowerMenuBackground", Vector2.ZERO)
		return
	var scaled_size: Vector2 = _get_width_fitted_texture_size(_get_home_lower_menu_background_texture())
	if scaled_size.y <= 0.0:
		_home_lower_menu_bg.position = Vector2.ZERO
		_home_lower_menu_bg.size = Vector2(SW, 0.0)
		return
	_home_lower_menu_bg.size = scaled_size
	_home_lower_menu_bg.position = Vector2(
		(SW - scaled_size.x) * 0.5,
		SH - HOME_LOWER_MENU_SUBMENU_RESERVE_H - scaled_size.y
	)


func _build_battle_area() -> void:
	_player_team = Node2D.new()
	_player_team.position = Vector2(0.0, BATTLE_Y)
	add_child(_player_team)

	_enemy_team = Node2D.new()
	_enemy_team.position = Vector2(0.0, BATTLE_Y)
	add_child(_enemy_team)

	_damage_fx_layer = Node2D.new()
	_damage_fx_layer.name = "DamageFxLayer"
	add_child(_damage_fx_layer)

	_battle_manager = BattleManager.new()
	add_child(_battle_manager)
	_battle_manager.battle_finished.connect(_on_battle_finished)


func _build_ui() -> void:
	_ui_layer = Control.new()
	_ui_layer.name = "BattleUiLayer"
	_ui_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui_layer)

	var top_bar_root: Control = HOME_TOP_HUD_SCENE.instantiate()
	top_bar_root.position = Vector2(TOP_BAR_FRAME_X, TOP_BAR_FRAME_Y)
	_ui_layer.add_child(top_bar_root)

	_top_avatar_rect = top_bar_root.get_node("Avatar") as TextureRect
	_top_avatar_rect.texture = AssetResolver.resolve_profile_avatar(GameState.get_profile_avatar_id())
	if _top_avatar_rect.texture == null:
		_top_avatar_rect.texture = PROFILE_AVATAR_TEXTURE
	var avatar_circle_material := ShaderMaterial.new()
	avatar_circle_material.shader = Shader.new()
	avatar_circle_material.shader.code = "shader_type canvas_item;\nvoid fragment(){\n\tvec2 uv = UV - vec2(0.5);\n\tif (length(uv) > 0.5) {\n\t\tdiscard;\n\t}\n\tCOLOR = texture(TEXTURE, UV) * COLOR;\n}\n"
	_top_avatar_rect.material = avatar_circle_material
	var profile_entry_button := Button.new()
	profile_entry_button.flat = true
	profile_entry_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	profile_entry_button.focus_mode = Control.FOCUS_NONE
	profile_entry_button.position = Vector2(0.0, 14.0)
	profile_entry_button.size = Vector2(180.0, 170.0)
	profile_entry_button.modulate = Color(1.0, 1.0, 1.0, 0.01)
	profile_entry_button.pressed.connect(UiAudio.play_ui_click)
	profile_entry_button.pressed.connect(_open_settings_scene)
	top_bar_root.add_child(profile_entry_button)
	_profile_name_label = top_bar_root.get_node("NameLabel") as Label
	_profile_level_label = top_bar_root.get_node("LevelLabel") as Label
	_top_exp_bar = top_bar_root.get_node("TopExpBar") as ProgressBar
	_top_progress_value_label = top_bar_root.get_node("ExpValueLabel") as Label
	_resource_value_labels["diamonds"] = top_bar_root.get_node("DiamondsPanel/Value") as Label
	_resource_value_labels["trap_points"] = top_bar_root.get_node("GoldPanel/Value") as Label
	_resource_value_labels["power"] = top_bar_root.get_node("PowerPanel/Value") as Label
	var power_button: Button = Button.new()
	power_button.flat = true
	power_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	power_button.focus_mode = Control.FOCUS_NONE
	power_button.position = Vector2(452.0, 128.0)
	power_button.size = Vector2(210.0, 58.0)
	power_button.modulate = Color(1.0, 1.0, 1.0, 0.01)
	power_button.pressed.connect(UiAudio.play_ui_click)
	power_button.pressed.connect(_on_stats_btn_pressed)
	top_bar_root.add_child(power_button)
	_apply_home_hud_fonts()
	var stage_panel := _make_panel(
		Vector2(188.0, 244.0),
		Vector2(344.0, 104.0),
		Color(0.12, 0.08, 0.06, 0.72),
		Color(0.66, 0.53, 0.31, 0.92)
	)
	_ui_layer.add_child(stage_panel)

	_level_label = _make_label("", Vector2(18.0, 16.0), Vector2(308.0, 28.0), 25)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(_level_label)

	_timer_label = _make_label("60.0", Vector2(18.0, 50.0), Vector2(308.0, 20.0), 18)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(_timer_label)
	_apply_fredoka_font(_timer_label, 18, "medium")

	var countdown_bar_bg := ColorRect.new()
	countdown_bar_bg.position = Vector2(28.0, 76.0)
	countdown_bar_bg.size = Vector2(288.0, 8.0)
	countdown_bar_bg.color = Color(0.20, 0.14, 0.10, 0.92)
	stage_panel.add_child(countdown_bar_bg)

	_battle_countdown_fill = ColorRect.new()
	_battle_countdown_fill.position = Vector2(1.0, 1.0)
	_battle_countdown_fill.size = Vector2(286.0, 6.0)
	_battle_countdown_fill.color = Color(0.97, 0.78, 0.28, 0.96)
	countdown_bar_bg.add_child(_battle_countdown_fill)

	_mail_badge = Label.new()
	_mail_badge.size = Vector2(28.0, 28.0)
	_mail_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mail_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mail_badge.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_mail_badge.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_chat_badge = _make_label("", Vector2.ZERO, Vector2(22.0, 18.0), 12)
	_chat_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameState.chat_unread_changed.connect(_on_chat_unread_changed)
	GameState.party_cheer_coupon_count_changed.connect(_on_party_cheer_coupon_count_changed)
	_refresh_chat_badge()

	_boss_btn = _make_button(UiText.HOME_BOSS, Vector2(252.0, 350.0), Vector2(216.0, 42.0))
	_boss_btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	_boss_btn.visible = false
	_ui_layer.add_child(_boss_btn)
	_boss_btn.pressed.connect(_on_challenge_boss_pressed)

	_skill_panel = Control.new()
	_skill_panel.position = _get_bottom_hud_position("SkillPanel", Vector2(SKILL_PANEL_X, SKILL_PANEL_Y))
	_skill_panel.size = _get_bottom_hud_size("SkillPanel", Vector2(SKILL_PANEL_W, SKILL_PANEL_H))
	_ui_layer.add_child(_skill_panel)

	_skill_shadow = ColorRect.new()
	_skill_shadow.position = _get_bottom_hud_position("SkillPanel/SkillShadow", Vector2(0.0, 6.0))
	_skill_shadow.size = _get_bottom_hud_size("SkillPanel/SkillShadow", _skill_panel.size)
	_skill_shadow.color = Color(0.03, 0.02, 0.02, 0.0)
	_skill_panel.add_child(_skill_shadow)

	_skill_body = ColorRect.new()
	_skill_body.position = _get_bottom_hud_position("SkillPanel/SkillBody", Vector2.ZERO)
	_skill_body.size = _get_bottom_hud_size("SkillPanel/SkillBody", _skill_panel.size)
	_skill_body.color = Color(0.13, 0.09, 0.07, 0.0)
	_skill_panel.add_child(_skill_body)

	_skill_inner = ColorRect.new()
	_skill_inner.position = _get_bottom_hud_position("SkillPanel/SkillInner", Vector2(2.0, 2.0))
	_skill_inner.size = _get_bottom_hud_size("SkillPanel/SkillInner", _skill_panel.size - Vector2(4.0, 4.0))
	_skill_inner.color = Color(0.20, 0.14, 0.10, 0.0)
	_skill_panel.add_child(_skill_inner)

	_skill_top_glow = ColorRect.new()
	_skill_top_glow.position = _get_bottom_hud_position("SkillPanel/SkillTopGlow", Vector2(SKILL_PANEL_CONTENT_PAD, 6.0))
	_skill_top_glow.size = _get_bottom_hud_size("SkillPanel/SkillTopGlow", Vector2(_skill_panel.size.x - SKILL_PANEL_CONTENT_PAD * 2.0, 12.0))
	_skill_top_glow.color = Color(1.0, 0.92, 0.78, 0.0)
	_skill_panel.add_child(_skill_top_glow)

	_skill_header_rule = ColorRect.new()
	_skill_header_rule.position = _get_bottom_hud_position("SkillPanel/SkillHeaderRule", Vector2(SKILL_PANEL_CONTENT_PAD, 34.0))
	_skill_header_rule.size = _get_bottom_hud_size("SkillPanel/SkillHeaderRule", Vector2(_skill_panel.size.x - SKILL_PANEL_CONTENT_PAD * 2.0, 2.0))
	_skill_header_rule.color = Color(0.84, 0.66, 0.34, 0.26)
	_skill_panel.add_child(_skill_header_rule)

	_scoop_mode_btn = _make_button(
		UiText.HOME_SKILL_MODE_SCOOP,
		_get_bottom_hud_position("SkillPanel/ScoopButton", Vector2(194.0, 48.0)),
		_get_bottom_hud_size("SkillPanel/ScoopButton", Vector2(104.0, 43.0))
	)
	_apply_bottom_hud_font_size(_scoop_mode_btn, "SkillPanel/ScoopButton", UiPalette.FONT_SIZE_SUBHEADING)
	_skill_panel.add_child(_scoop_mode_btn)
	_setup_skill_mode_button_visual(_scoop_mode_btn, "SkillPanel/ScoopButton")
	_scoop_mode_btn.pressed.connect(_show_scoop_mode)

	_skill_filter_btn = _make_button(
		UiText.HOME_SKILL_MODE_DASH,
		_get_bottom_hud_position("SkillPanel/SkillFilterButton", Vector2(306.0, 48.0)),
		_get_bottom_hud_size("SkillPanel/SkillFilterButton", Vector2(104.0, 43.0))
	)
	_apply_bottom_hud_font_size(_skill_filter_btn, "SkillPanel/SkillFilterButton", UiPalette.FONT_SIZE_SUBHEADING)
	_skill_panel.add_child(_skill_filter_btn)
	_setup_skill_mode_button_visual(_skill_filter_btn, "SkillPanel/SkillFilterButton")
	_apply_skill_filter_button_style(_skill_filter_btn, true)
	_skill_filter_btn.pressed.connect(_show_dash_mode)

	_skill_bar = _build_skill_bar()
	_skill_panel.add_child(_skill_bar)
	_apply_skill_bar_layout()

	_speed_1x = _make_button(
		UiText.HOME_SPEED_BOOST,
		_get_bottom_hud_position("SkillPanel/SpeedButton", Vector2(_skill_panel.size.x - SKILL_PANEL_CONTENT_PAD - 128.0, -16.0)),
		_get_bottom_hud_size("SkillPanel/SpeedButton", Vector2(128.0, 26.0))
	)
	_apply_bottom_hud_font_size(_speed_1x, "SkillPanel/SpeedButton", UiPalette.FONT_SIZE_SUBHEADING)
	_skill_panel.add_child(_speed_1x)
	_apply_skill_speed_button_style(_speed_1x, false)
	_speed_2x = null
	_speed_3x = null
	_speed_1x.pressed.connect(_cycle_speed)
	_apply_speed_unlocks()
	_highlight_speed_btn(_speed_1x)
	_refresh_skill_mode_buttons()

	_sandbox_btn = _make_button(
		UiText.HOME_IDLE_TIMER_PLACEHOLDER,
		_get_bottom_hud_position("SkillPanel/SandboxButton", Vector2(0.0, -16.0)),
		_get_bottom_hud_size("SkillPanel/SandboxButton", Vector2(224.0, 26.0))
	)
	_apply_bottom_hud_font_size(_sandbox_btn, "SkillPanel/SandboxButton", 14)
	_sandbox_btn.pressed.connect(_show_sandbox_dialog)
	_skill_panel.add_child(_sandbox_btn)
	_layout_sandbox_btn()

	_home_scoop_panel = HOME_SCOOP_TEMPLATE_SCENE.instantiate() as Control
	_home_scoop_panel.position = Vector2(HOME_SCOOP_PANEL_X, HOME_SCOOP_PANEL_Y)
	_ui_layer.add_child(_home_scoop_panel)

	_home_exp_label = null
	_home_exp_bar = null
	_home_coupon_button = null

	_home_scoop_result_label = _home_scoop_panel.get_node("ResultLabel") as Label
	_home_scoop_button = _home_scoop_panel.get_node("ScoopButton") as TextureButton
	_home_scoop_overlay = _home_scoop_panel.get_node("ScoopButton/CooldownOverlay") as ColorRect
	_home_scoop_cd_label = _home_scoop_panel.get_node("ScoopButton/CooldownLabel") as Label
	_home_scoop_count_debug_frame = _home_scoop_panel.get_node_or_null("ScoopButton/CountDebugFrame") as PanelContainer
	_home_scoop_count_label = _home_scoop_panel.get_node_or_null("ScoopButton/CountDebugFrame/CountLabel") as Label
	if _home_scoop_count_label == null:
		_home_scoop_count_label = _home_scoop_panel.get_node_or_null("ScoopButton/CountLabel") as Label
	_apply_bottom_hud_font_size(_home_scoop_result_label, "HomeScoopPanel/ResultLabel", 11)
	_apply_bottom_hud_font_size(_home_scoop_cd_label, "HomeScoopPanel/ScoopButton/CooldownLabel", 20)
	_apply_bottom_hud_font_size(_home_scoop_count_label, "HomeScoopPanel/ScoopButton/CountLabel", 24)
	_apply_fredoka_font(_home_scoop_cd_label, _get_bottom_hud_font_size("HomeScoopPanel/ScoopButton/CooldownLabel", 20), "bold")
	_apply_fredoka_font(_home_scoop_count_label, _get_bottom_hud_font_size("HomeScoopPanel/ScoopButton/CountLabel", 24), "bold")
	_home_auto_scoop_toggle_button = _home_scoop_panel.get_node_or_null("AutoScoopToggleButton") as TextureButton
	_home_scoop_button.modulate = Color(0.97, 0.93, 0.88, 1.0)
	_home_scoop_button.pressed.connect(_on_home_scoop_pressed)
	if _home_auto_scoop_toggle_button != null:
		_home_auto_scoop_toggle_button.pressed.connect(_on_home_auto_scoop_toggle_pressed)
		_refresh_home_auto_scoop_toggle_button()
	_set_home_scoop_frame(0)

	_skip_btn = _make_button(UiText.HOME_SKIP, Vector2(SW - 104.0, 76.0), Vector2(90.0, 34.0))
	_ui_layer.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip_pressed)
	_skip_btn.visible = GameState.is_admin_session()

	_result_backdrop = Control.new()
	_result_backdrop.position = Vector2.ZERO
	_result_backdrop.size = Vector2(SW, SH)
	_result_backdrop.visible = false
	_result_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_backdrop.pivot_offset = Vector2(SW * 0.5, SH * 0.5)
	_ui_layer.add_child(_result_backdrop)

	_result_display = TextureRect.new()
	_result_display.size = Vector2(SW, SH)
	_result_display.position = Vector2(0.0, RESULT_OVERLAY_OFFSET_Y)
	_result_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_result_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_result_display.visible = false
	_result_backdrop.add_child(_result_display)

	_boss_warning_overlay = BOSS_WARNING_OVERLAY_SCENE.instantiate() as Control
	_boss_warning_overlay.position = Vector2(
		(SW - BOSS_WARNING_DISPLAY_W) * 0.5,
		BOSS_WARNING_DISPLAY_Y
	)
	_boss_warning_overlay.visible = false
	_result_backdrop.add_child(_boss_warning_overlay)
	_boss_warning_icon = _boss_warning_overlay.get_node("Icon") as TextureRect
	_boss_warning_text_label = _boss_warning_overlay.get_node("TextLabel") as Label

	_nav_canvas = CanvasLayer.new()
	_nav_canvas.layer = 20
	_nav_canvas.offset = _adaptive_content_origin
	add_child(_nav_canvas)

	_home_more_buttons_layer = Control.new()
	_home_more_buttons_layer.name = "HomeMoreButtonsLayer"
	_home_more_buttons_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_home_more_buttons_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_more_buttons_layer.visible = false
	_nav_canvas.add_child(_home_more_buttons_layer)

	_home_more_dismiss_button = Button.new()
	_home_more_dismiss_button.name = "HomeMoreDismissHitArea"
	_home_more_dismiss_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_home_more_dismiss_button.focus_mode = Control.FOCUS_NONE
	_home_more_dismiss_button.flat = true
	_home_more_dismiss_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_home_more_dismiss_button.text = ""
	var dismiss_style: StyleBoxEmpty = StyleBoxEmpty.new()
	_home_more_dismiss_button.add_theme_stylebox_override("normal", dismiss_style)
	_home_more_dismiss_button.add_theme_stylebox_override("hover", dismiss_style)
	_home_more_dismiss_button.add_theme_stylebox_override("pressed", dismiss_style)
	_home_more_dismiss_button.add_theme_stylebox_override("focus", dismiss_style)
	_home_more_dismiss_button.add_theme_stylebox_override("disabled", dismiss_style)
	_home_more_dismiss_button.pressed.connect(_close_home_more_menu)
	_home_more_buttons_layer.add_child(_home_more_dismiss_button)
	_build_home_main_button_panel()

	var nav_paths: Array[String] = _get_main_nav_button_paths()
	var nav_bounds_raw: Rect2 = _get_bottom_hud_bounds_rect(nav_paths, Rect2(36.0, 1197.0, 657.0, 78.0))
	var nav_bounds: Rect2 = Rect2(0.0, nav_bounds_raw.position.y + HOME_MAIN_NAV_OFFSET_Y, SW, nav_bounds_raw.size.y)
	var nav_button_rect: Rect2 = _get_bottom_hud_average_rect(nav_paths, Rect2(Vector2.ZERO, HOME_NAV_BUTTON_SIZE))
	var nav_gap: float = maxf(0.0, _get_bottom_hud_average_gap_x(nav_paths, 0.0) + HOME_MAIN_NAV_GAP_X)
	var nav_row_width: float = nav_button_rect.size.x * float(nav_paths.size()) + nav_gap * float(maxi(nav_paths.size() - 1, 0))
	var nav_start_x: float = nav_bounds_raw.position.x + (nav_bounds_raw.size.x - nav_row_width) * 0.5
	var nav_y: float = nav_bounds.position.y + (nav_bounds.size.y - nav_button_rect.size.y) * 0.5
	var nav_label_rect: Rect2 = _get_bottom_hud_average_rect(
		_get_main_nav_label_paths(),
		Rect2(Vector2(8.0, 8.0), Vector2(112.0, 60.0))
	)
	var nav_layouts: Dictionary = {}
	for i in range(nav_paths.size()):
		var nav_x: float = nav_start_x + float(i) * (nav_button_rect.size.x + nav_gap)
		nav_layouts[nav_paths[i]] = Rect2(Vector2(nav_x, nav_y), nav_button_rect.size)
	var nav_items: Array = [
		[UiText.NAV_SCOOPER, "res://scenes/ScooperScene.tscn", _on_nav_scooper, "MainNav/ScooperButton"],
		[UiText.NAV_ENHANCE, "res://scenes/EnhanceScene.tscn", _on_nav_enhance, "MainNav/EnhanceButton"],
		[UiText.NAV_ACTIVITY, "res://scenes/ActivityScene.tscn", _on_nav_activity, "MainNav/ActivityButton"],
		[UiText.NAV_SHOP, "res://scenes/ShopScene.tscn", _on_nav_shop, "MainNav/ShopButton"],
	]
	for i in range(nav_items.size()):
		var nav_rect: Rect2 = nav_layouts.get(
			str(nav_items[i][3]),
			Rect2(Vector2(18.0 + i * 138.0, HOME_NAV_BUTTON_ROW_Y), HOME_NAV_BUTTON_SIZE)
		)
		var nav_btn: TextureButton = _build_home_nav_button(
			nav_items[i][0],
			nav_rect.position,
			nav_rect.size,
			"%s/Label" % str(nav_items[i][3])
		)
		_apply_texture_button_label_rect(nav_btn, nav_label_rect)
		nav_btn.pressed.connect(nav_items[i][2])
		_apply_home_nav_button_style(nav_btn, false)
		_nav_canvas.add_child(nav_btn)
		_nav_buttons[String(nav_items[i][1])] = nav_btn

	var more_rect: Rect2 = nav_layouts.get("MainNav/MoreButton", Rect2(Vector2(574.0, HOME_NAV_BUTTON_ROW_Y), HOME_NAV_BUTTON_SIZE))
	_nav_more_button = _build_home_nav_button(
		UiText.NAV_MORE,
		more_rect.position,
		more_rect.size,
		"MainNav/MoreButton/Label"
	)
	_apply_texture_button_label_rect(_nav_more_button, nav_label_rect)
	_nav_more_button.pressed.connect(_toggle_home_more_menu)
	_apply_home_more_button_style(false)
	_nav_canvas.add_child(_nav_more_button)

	_build_home_more_buttons()
	_home_more_buttons_layer.add_child(_mail_badge)
	_home_more_buttons_layer.add_child(_chat_badge)
	_refresh_home_more_badge_positions()

	_refresh_main_nav_state()
	_refresh_home_more_menu_visibility()
	_layout_home_scoop_panel()

	_reward_fx_canvas = CanvasLayer.new()
	_reward_fx_canvas.layer = 101
	_reward_fx_canvas.offset = _adaptive_content_origin
	add_child(_reward_fx_canvas)

	_reward_fx_layer = Control.new()
	_reward_fx_layer.name = "RewardFxLayer"
	_reward_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reward_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward_fx_canvas.add_child(_reward_fx_layer)


## Build the skill bar container. Layout is adjusted by filter mode.
func _build_skill_bar() -> Control:
	var bar := Control.new()
	bar.name = "SkillBar"
	bar.position = _get_bottom_hud_position("SkillPanel/SkillBarAnchor", Vector2(SKILL_PANEL_CONTENT_PAD, 48.0))
	bar.size = _get_bottom_hud_size("SkillPanel/SkillBarAnchor", Vector2(SKILL_PANEL_W - SKILL_PANEL_CONTENT_PAD * 2.0, SKILL_BAR_H))

	for i in range(MAX_CATS_ON_FIELD * 2):
		var slot := _make_skill_slot(i)
		bar.add_child(slot)

	return bar


func _make_skill_slot(idx: int) -> Control:
	var slot := Control.new()
	slot.name = "Slot%d" % idx
	slot.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	slot.custom_minimum_size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)

	var shadow := ColorRect.new()
	shadow.position = Vector2(0.0, 4.0)
	shadow.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H - 1.0)
	shadow.color = Color(0.02, 0.02, 0.02, 0.28)
	slot.add_child(shadow)

	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	bg.color = Color(0.39, 0.28, 0.14, 0.96)
	slot.add_child(bg)

	var inner := ColorRect.new()
	inner.position = Vector2(2.0, 2.0)
	inner.size = Vector2(SKILL_SLOT_W - 4.0, SKILL_SLOT_H - 4.0)
	inner.color = Color(0.14, 0.10, 0.08, 0.96)
	slot.add_child(inner)

	var top_glow := ColorRect.new()
	top_glow.position = Vector2(4.0, 4.0)
	top_glow.size = Vector2(SKILL_SLOT_W - 8.0, 10.0)
	top_glow.color = Color(1.0, 0.92, 0.80, 0.08)
	slot.add_child(top_glow)

	var icon_shell := ColorRect.new()
	icon_shell.name = "IconShell"
	icon_shell.position = Vector2(8.0, 8.0)
	icon_shell.size = Vector2(SKILL_SLOT_W - 16.0, 62.0)
	icon_shell.color = Color(0.26, 0.18, 0.12, 0.96)
	slot.add_child(icon_shell)

	var icon_shell_inner := ColorRect.new()
	icon_shell_inner.position = Vector2(2.0, 2.0)
	icon_shell_inner.size = icon_shell.size - Vector2(4.0, 4.0)
	icon_shell_inner.color = Color(0.10, 0.08, 0.08, 0.98)
	icon_shell.add_child(icon_shell_inner)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(1.2, 4.2)
	icon.size = Vector2((SKILL_SLOT_W - 24.0) * 1.2, 58.0 * 1.2)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	slot.add_child(icon)

	var death_overlay := ColorRect.new()
	death_overlay.name = "DeathOverlay"
	death_overlay.position = Vector2(8.0, 8.0)
	death_overlay.size = Vector2(SKILL_SLOT_W - 16.0, 62.0)
	death_overlay.color = Color(0.82, 0.10, 0.10, 0.42)
	death_overlay.visible = false
	slot.add_child(death_overlay)

	var hp_bar_bg := ColorRect.new()
	hp_bar_bg.name = "HpBarBg"
	hp_bar_bg.position = Vector2(10.0, 80.0)
	hp_bar_bg.size = Vector2(SKILL_SLOT_W - 20.0, 14.0)
	hp_bar_bg.color = Color(0.08, 0.09, 0.07, 0.96)
	slot.add_child(hp_bar_bg)

	var hp_bar_fill := ColorRect.new()
	hp_bar_fill.name = "HpBarFill"
	hp_bar_fill.position = Vector2(1.0, 1.0)
	hp_bar_fill.size = Vector2(hp_bar_bg.size.x - 2.0, hp_bar_bg.size.y - 2.0)
	hp_bar_fill.color = Color(0.30, 0.92, 0.40, 1.0)
	hp_bar_bg.add_child(hp_bar_fill)

	var hp_value_lbl := Label.new()
	hp_value_lbl.name = "HpValueLabel"
	hp_value_lbl.position = Vector2(10.0, 72.0)
	hp_value_lbl.size = Vector2(SKILL_SLOT_W - 20.0, 12.0)
	hp_value_lbl.add_theme_font_size_override("font_size", 13)
	hp_value_lbl.add_theme_constant_override("outline_size", 2)
	hp_value_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	hp_value_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.96))
	hp_value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_value_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(hp_value_lbl)

	var cooldown_bar_bg := ColorRect.new()
	cooldown_bar_bg.name = "CooldownBarBg"
	cooldown_bar_bg.position = Vector2(10.0, 102.0)
	cooldown_bar_bg.size = Vector2(SKILL_SLOT_W - 20.0, 12.0)
	cooldown_bar_bg.color = Color(0.06, 0.12, 0.22, 0.96)
	slot.add_child(cooldown_bar_bg)

	var cooldown_bar_fill := ColorRect.new()
	cooldown_bar_fill.name = "CooldownBarFill"
	cooldown_bar_fill.position = Vector2(1.0, 1.0)
	cooldown_bar_fill.size = Vector2(0.0, cooldown_bar_bg.size.y - 2.0)
	cooldown_bar_fill.color = Color(0.28, 0.74, 1.0, 1.0)
	cooldown_bar_bg.add_child(cooldown_bar_fill)

	# Cooldown overlay shrinks downward over time
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.position = Vector2(8.0, 8.0)
	overlay.size = Vector2(SKILL_SLOT_W - 16.0, 62.0)
	overlay.color = Color(0.05, 0.03, 0.02, 0.76)
	overlay.visible = false
	overlay.set_meta("base_y", overlay.position.y)
	overlay.set_meta("base_height", overlay.size.y)
	slot.add_child(overlay)

	# Cooldown number
	var cd_lbl := Label.new()
	cd_lbl.name = "CdLabel"
	cd_lbl.position = Vector2(10.0, 93.0)
	cd_lbl.size = Vector2(SKILL_SLOT_W - 20.0, 14.0)
	cd_lbl.add_theme_font_size_override("font_size", 13)
	cd_lbl.add_theme_constant_override("outline_size", 2)
	cd_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
	cd_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.20, 0.42, 0.96))
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_lbl.visible = false
	slot.add_child(cd_lbl)

	# Active buff outline
	var buff_frame := ColorRect.new()
	buff_frame.name = "BuffFrame"
	buff_frame.size = Vector2(SKILL_SLOT_W, SKILL_SLOT_H)
	buff_frame.color = Color(0.98, 0.82, 0.28, 0.12)
	buff_frame.visible = false
	slot.add_child(buff_frame)

	# Build the border from four ColorRect edges
	var border_color := Color(0.98, 0.82, 0.28, 1.0)
	var border_thick := 2.0
	for side in [
		[Vector2(0, 0), Vector2(SKILL_SLOT_W, border_thick)],
		[Vector2(0, SKILL_SLOT_H - border_thick), Vector2(SKILL_SLOT_W, border_thick)],
		[Vector2(0, 0), Vector2(border_thick, SKILL_SLOT_H)],
		[Vector2(SKILL_SLOT_W - border_thick, 0), Vector2(border_thick, SKILL_SLOT_H)],
	]:
		var border := ColorRect.new()
		border.position = side[0]
		border.size = side[1]
		border.color = border_color
		buff_frame.add_child(border)

	return slot


func _apply_skill_bar_layout() -> void:
	if _skill_bar == null or _skill_panel == null:
		return
	var skill_panel_base_size: Vector2 = _get_bottom_hud_size("SkillPanel", Vector2(SKILL_PANEL_W, SKILL_PANEL_H))
	var is_all_mode: bool = _skill_filter_mode == "all"
	var is_scoop_mode: bool = _skill_filter_mode == "scoop"
	_skill_panel.size = Vector2(
		skill_panel_base_size.x,
		0.0 if is_scoop_mode else (SKILL_PANEL_ALL_H if is_all_mode else skill_panel_base_size.y)
	)
	if _skill_shadow != null:
		_skill_shadow.size = _skill_panel.size
	if _skill_body != null:
		_skill_body.size = _skill_panel.size
	if _skill_inner != null:
		_skill_inner.size = _skill_panel.size - Vector2(4.0, 4.0)
	if _skill_top_glow != null:
		var skill_top_glow_pos: Vector2 = _get_bottom_hud_position("SkillPanel/SkillTopGlow", _skill_top_glow.position)
		var skill_top_glow_size: Vector2 = _get_bottom_hud_size("SkillPanel/SkillTopGlow", _skill_top_glow.size)
		_skill_top_glow.position = Vector2(skill_top_glow_pos.x, _skill_top_glow.position.y)
		_skill_top_glow.size = Vector2(skill_top_glow_size.x, _skill_top_glow.size.y)
	if _skill_header_rule != null:
		var skill_header_rule_pos: Vector2 = _get_bottom_hud_position("SkillPanel/SkillHeaderRule", _skill_header_rule.position)
		var skill_header_rule_size: Vector2 = _get_bottom_hud_size("SkillPanel/SkillHeaderRule", _skill_header_rule.size)
		_skill_header_rule.position = Vector2(skill_header_rule_pos.x, _skill_header_rule.position.y)
		_skill_header_rule.size = Vector2(skill_header_rule_size.x, _skill_header_rule.size.y)
	if _speed_1x != null:
		_speed_1x.position = _get_bottom_hud_position("SkillPanel/SpeedButton", _speed_1x.position)
	_layout_sandbox_btn()
	if _sandbox_btn != null:
		_sandbox_btn.visible = true
	if _home_scoop_panel != null:
		_home_scoop_panel.visible = is_scoop_mode
	if _skip_btn != null:
		_skip_btn.visible = GameState.is_admin_session()
	var skill_bar_anchor_pos: Vector2 = _get_bottom_hud_position("SkillPanel/SkillBarAnchor", Vector2(SKILL_PANEL_CONTENT_PAD, 48.0))
	var skill_bar_anchor_size: Vector2 = _get_bottom_hud_size("SkillPanel/SkillBarAnchor", Vector2(_skill_panel.size.x - SKILL_PANEL_CONTENT_PAD * 2.0, SKILL_BAR_H))
	_skill_bar.position.x = skill_bar_anchor_pos.x
	_skill_bar.size.x = skill_bar_anchor_size.x
	if is_scoop_mode:
		_skill_bar.position = skill_bar_anchor_pos
		_skill_bar.size = Vector2(_skill_bar.size.x, 0.0)
		for i in range(MAX_CATS_ON_FIELD * 2):
			var scoop_slot: Control = _skill_bar.get_node_or_null("Slot%d" % i)
			if scoop_slot == null:
				continue
			scoop_slot.visible = false
		return
	var row_gap: float = 24.0
	var content_w: float = _skill_bar.size.x - SKILL_BAR_EDGE_PAD * 2.0
	var horizontal_gap: float = (content_w - SKILL_SLOT_W * MAX_CATS_ON_FIELD) / float(MAX_CATS_ON_FIELD - 1)
	var slot_count: int = MAX_CATS_ON_FIELD * 2
	if is_all_mode:
		_skill_bar.position = skill_bar_anchor_pos
		_skill_bar.size = Vector2(_skill_bar.size.x, SKILL_SLOT_H * 2.0 + row_gap)
		for i in range(slot_count):
			var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
			if slot_node == null:
				continue
			var col: int = i % MAX_CATS_ON_FIELD
			var row: int = floori(float(i) / float(MAX_CATS_ON_FIELD))
			slot_node.scale = Vector2.ONE
			slot_node.position = Vector2(SKILL_BAR_EDGE_PAD + col * (SKILL_SLOT_W + horizontal_gap), row * (SKILL_SLOT_H + row_gap))
			slot_node.visible = true
	else:
		_skill_bar.position = skill_bar_anchor_pos
		_skill_bar.size = Vector2(_skill_bar.size.x, skill_bar_anchor_size.y)
		for i in range(slot_count):
			var slot_node_single: Control = _skill_bar.get_node_or_null("Slot%d" % i)
			if slot_node_single == null:
				continue
			slot_node_single.scale = Vector2.ONE
			slot_node_single.position = Vector2(SKILL_BAR_EDGE_PAD + i * (SKILL_SLOT_W + horizontal_gap), 0.0)
			slot_node_single.visible = i < MAX_CATS_ON_FIELD


func _apply_skill_filter_button_style(button: Button, is_active: bool) -> void:
	if button == null:
		return
	button.flat = true
	button.set_meta("skill_mode_active", is_active)
	_refresh_skill_mode_button_visual(button)


func _setup_skill_mode_button_visual(button: Button, path: String) -> void:
	if button == null:
		return
	button.set_meta("skill_mode_base_font_size", _get_bottom_hud_font_size(path, UiPalette.FONT_SIZE_SUBHEADING))
	button.set_meta("skill_mode_pressed", false)
	button.set_meta("skill_mode_active", false)
	button.button_down.connect(Callable(self, "_set_skill_mode_button_pressed").bind(button, true))
	button.button_up.connect(Callable(self, "_set_skill_mode_button_pressed").bind(button, false))
	button.mouse_exited.connect(Callable(self, "_set_skill_mode_button_pressed").bind(button, false))
	_refresh_skill_mode_button_visual(button)


func _set_skill_mode_button_pressed(button: Button, is_pressed: bool) -> void:
	if button == null:
		return
	button.set_meta("skill_mode_pressed", is_pressed)
	_refresh_skill_mode_button_visual(button)


func _refresh_skill_mode_button_visual(button: Button) -> void:
	if button == null:
		return
	var base_font_size: int = int(button.get_meta("skill_mode_base_font_size", UiPalette.FONT_SIZE_SUBHEADING))
	var is_active: bool = bool(button.get_meta("skill_mode_active", false))
	var is_pressed: bool = bool(button.get_meta("skill_mode_pressed", false))
	var label_color: Color = SKILL_MODE_LABEL_ACTIVE if is_active else SKILL_MODE_LABEL_IDLE
	var outline_size: int = SKILL_MODE_LABEL_ACTIVE_OUTLINE_SIZE if is_active else SKILL_MODE_LABEL_OUTLINE_SIZE
	var font_size: int = base_font_size + SKILL_MODE_LABEL_FONT_BOOST + (1 if is_active else 0)
	if is_pressed:
		label_color = SKILL_MODE_LABEL_PRESSED
		outline_size += 1
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", label_color)
	button.add_theme_color_override("font_hover_color", label_color)
	button.add_theme_color_override("font_pressed_color", SKILL_MODE_LABEL_PRESSED)
	button.add_theme_color_override("font_hover_pressed_color", SKILL_MODE_LABEL_PRESSED)
	button.add_theme_color_override("font_focus_color", label_color)
	button.add_theme_color_override("font_outline_color", SKILL_MODE_LABEL_OUTLINE)
	button.add_theme_constant_override("outline_size", outline_size)
	button.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	button.add_theme_constant_override("shadow_offset_x", 0)
	button.add_theme_constant_override("shadow_offset_y", 0)
	button.modulate = Color(0.98, 0.96, 0.93, 1.0) if is_pressed else Color(1.0, 1.0, 1.0, 1.0)


func _layout_sandbox_btn() -> void:
	if _sandbox_btn == null or _speed_1x == null:
		return
	var sandbox_control: Control = _get_bottom_hud_control("SkillPanel/SandboxButton")
	if sandbox_control != null:
		_sandbox_btn.position = sandbox_control.position
		return
	_sandbox_btn.position = Vector2(
		_speed_1x.position.x - _sandbox_btn.size.x - 8.0,
		_speed_1x.position.y
	)


func _refresh_skill_mode_buttons() -> void:
	if _scoop_mode_btn != null:
		_scoop_mode_btn.text = UiText.HOME_SKILL_MODE_SCOOP
		_apply_skill_filter_button_style(_scoop_mode_btn, _skill_filter_mode == "scoop")
	if _skill_filter_btn != null:
		_skill_filter_btn.text = UiText.HOME_SKILL_MODE_DASH
		_apply_skill_filter_button_style(_skill_filter_btn, _skill_filter_mode == "all")


func _set_skill_filter_mode(mode: String) -> void:
	_skill_filter_mode = "all" if mode == "all" else "scoop"
	_refresh_home_lower_menu_background()
	_apply_skill_bar_layout()
	_refresh_skill_mode_buttons()
	if _battle_manager != null:
		_battle_manager.set_skill_bar_filter(_skill_filter_mode)


func _show_scoop_mode() -> void:
	_set_skill_filter_mode("scoop")


func _show_dash_mode() -> void:
	_set_skill_filter_mode("all")


func _get_home_lower_menu_background_texture() -> Texture2D:
	return HOME_LOWER_MENU_BG_SKILL_TEXTURE if _skill_filter_mode == "all" else HOME_LOWER_MENU_BG_TEXTURE


func _refresh_home_lower_menu_background() -> void:
	if _home_lower_menu_bg == null:
		return
	_layout_home_lower_menu_underlay()


## Refresh skill slot names from the active player team.
func _refresh_skill_bar_names(player_cats: Array) -> void:
	if _skill_bar == null:
		return
	for i in range(player_cats.size()):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node == null:
			continue
		var name_lbl: Label = slot_node.get_node_or_null("NameLabel")
		if name_lbl == null:
			continue
		var cat: CatData = player_cats[i]
		if cat.active_skills_data.size() > 0:
			name_lbl.text = cat.active_skills_data[0].get("display_name", "")
		else:
			name_lbl.text = ""

	# Hide unused slots
	for i in range(player_cats.size(), MAX_CATS_ON_FIELD):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node:
			slot_node.visible = false


# Factory helpers

func _make_label(txt: String, pos: Vector2, sz: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.97, 0.92, 0.84, 1.0))
	return lbl


func _make_button(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.position = pos
	btn.size = sz
	btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	btn.modulate = Color(0.97, 0.93, 0.88, 1.0)
	btn.pressed.connect(UiAudio.play_ui_click)
	return btn


func _build_home_nav_background() -> Control:
	var background: ColorRect = ColorRect.new()
	background.position = Vector2(0.0, NAV_Y)
	background.size = Vector2(SW, NAV_H)
	background.color = HOME_NAV_BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border: ColorRect = ColorRect.new()
	border.position = Vector2(0.0, 0.0)
	border.size = Vector2(SW, 2.0)
	border.color = HOME_NAV_BG_BORDER
	background.add_child(border)
	return background


func _build_home_main_button_panel() -> void:
	_home_main_button_panel = TextureRect.new()
	_home_main_button_panel.name = "HomeMainButtonPanel"
	_home_main_button_panel.texture = HOME_MAIN_BUTTON_PANEL_TEXTURE
	_home_main_button_panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_home_main_button_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_home_main_button_panel.stretch_mode = TextureRect.STRETCH_SCALE
	_home_main_button_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_home_main_button_panel()
	_nav_canvas.add_child(_home_main_button_panel)


func _layout_home_main_button_panel() -> void:
	if _home_main_button_panel == null:
		return
	var editor_size: Vector2 = _get_bottom_hud_size("MainButtonPanel", Vector2.ZERO)
	if editor_size != Vector2.ZERO:
		_home_main_button_panel.size = editor_size
		_home_main_button_panel.position = _get_bottom_hud_position("MainButtonPanel", Vector2.ZERO)
		return
	var source_size: Vector2 = Vector2(HOME_MAIN_BUTTON_PANEL_TEXTURE.get_size())
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		_home_main_button_panel.position = Vector2.ZERO
		_home_main_button_panel.size = Vector2(SW, 0.0)
		return
	_home_main_button_panel.size = source_size
	_home_main_button_panel.position = Vector2(
		(SW - source_size.x) * 0.5,
		SH - source_size.y
	)


func _get_width_fitted_texture_size(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2(SW, 0.0)
	var source_size: Vector2 = Vector2(texture.get_size())
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return Vector2(SW, 0.0)
	var target_width: float = SW
	var width_scale: float = target_width / source_size.x
	return Vector2(target_width, source_size.y * width_scale)


func _build_home_nav_button(txt: String, pos: Vector2, sz: Vector2, label_path: String = "") -> TextureButton:
	return _build_home_quick_button(txt, pos, sz, true, label_path)


func _build_home_quick_action_button(txt: String, pos: Vector2, callback: Callable, size: Vector2 = HOME_QUICK_BUTTON_SIZE, label_path: String = "") -> TextureButton:
	var btn: TextureButton = _build_home_quick_button(txt, pos, size, false, label_path)
	btn.pressed.connect(callback)
	btn.visible = false
	return btn


func _build_home_quick_button(txt: String, pos: Vector2, sz: Vector2, is_main_nav: bool, label_path: String = "") -> TextureButton:
	var btn: TextureButton = TextureButton.new()
	btn.position = pos
	btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	btn.pressed.connect(UiAudio.play_ui_click)

	var label: Label = Label.new()
	label.name = "Label"
	label.position = Vector2(
		12.0,
		HOME_NAV_BUTTON_LABEL_Y if is_main_nav else HOME_QUICK_BUTTON_LABEL_Y
	)
	label.size = Vector2(
		sz.x - 24.0,
		HOME_NAV_BUTTON_LABEL_H if is_main_nav else HOME_QUICK_BUTTON_LABEL_H
	)
	label.text = txt
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var base_font_size: int = _get_bottom_hud_font_size(
		label_path,
		HOME_NAV_BUTTON_FONT_SIZE if is_main_nav else HOME_QUICK_BUTTON_FONT_SIZE
	)
	label.add_theme_font_size_override("font_size", base_font_size)
	label.add_theme_constant_override("outline_size", HOME_NAV_LABEL_MAIN_OUTLINE_SIZE if is_main_nav else HOME_NAV_LABEL_MORE_OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", HOME_NAV_LABEL_OUTLINE)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(label)

	btn.set_meta("label_node", label)
	btn.set_meta("is_main_nav", is_main_nav)
	btn.set_meta("label_base_font_size", base_font_size)
	btn.set_meta("label_base_rect", Rect2(label.position, label.size))
	btn.set_meta("home_button_active", false)
	btn.set_meta("home_button_pressed", false)
	btn.button_down.connect(Callable(self, "_set_home_quick_button_pressed").bind(btn, true))
	btn.button_up.connect(Callable(self, "_set_home_quick_button_pressed").bind(btn, false))
	btn.mouse_exited.connect(Callable(self, "_set_home_quick_button_pressed").bind(btn, false))
	if is_main_nav:
		btn.texture_normal = HOME_NAV_BUTTON_DEFAULT_TEXTURE
		btn.texture_hover = HOME_NAV_BUTTON_ACTIVE_TEXTURE
		btn.texture_pressed = HOME_NAV_BUTTON_DEFAULT_TEXTURE
	else:
		btn.texture_normal = HOME_MORE_BUTTON_DEFAULT_TEXTURE
		btn.texture_hover = HOME_MORE_BUTTON_ACTIVE_TEXTURE
		btn.texture_pressed = HOME_MORE_BUTTON_DEFAULT_TEXTURE
	btn.texture_disabled = btn.texture_normal
	_refresh_home_quick_button_visual(btn)
	return btn


func _get_main_nav_button_paths() -> Array[String]:
	return [
		"MainNav/ScooperButton",
		"MainNav/EnhanceButton",
		"MainNav/ActivityButton",
		"MainNav/ShopButton",
		"MainNav/MoreButton",
	]


func _get_main_nav_label_paths() -> Array[String]:
	return [
		"MainNav/ScooperButton/Label",
		"MainNav/EnhanceButton/Label",
		"MainNav/ActivityButton/Label",
		"MainNav/ShopButton/Label",
		"MainNav/MoreButton/Label",
	]


func _get_home_more_button_defs() -> Array[Dictionary]:
	return [
		{
			"key": "announcements",
			"text": UiText.HOME_ANNOUNCEMENTS,
			"callback": Callable(self, "_on_nav_announcements"),
			"button_path": "QuickButtons/AnnouncementsButton",
			"label_path": "QuickButtons/AnnouncementsButton/Label",
		},
		{
			"key": "daily_tasks",
			"text": UiText.HOME_DAILY_TASKS,
			"callback": Callable(self, "_on_nav_daily_tasks"),
			"button_path": "QuickButtons/DailyTasksButton",
			"label_path": "QuickButtons/DailyTasksButton/Label",
		},
		{
			"key": "backpack",
			"text": UiText.NAV_BACKPACK,
			"callback": Callable(self, "_on_nav_backpack"),
			"button_path": "QuickButtons/BackpackButton",
			"label_path": "QuickButtons/BackpackButton/Label",
		},
		{
			"key": "lineup",
			"text": UiText.NAV_CONFIG,
			"callback": Callable(self, "_on_nav_config"),
			"button_path": "QuickButtons/LineupButton",
			"label_path": "QuickButtons/LineupButton/Label",
		},
		{
			"key": "party",
			"text": UiText.HOME_PARTY,
			"callback": Callable(self, "_open_party"),
			"button_path": "QuickButtons/PartyButton",
			"label_path": "QuickButtons/PartyButton/Label",
		},
		{
			"key": "stats",
			"text": UiText.STATS_BTN_LABEL,
			"callback": Callable(self, "_on_stats_btn_pressed"),
			"button_path": "QuickButtons/StatsButton",
			"label_path": "QuickButtons/StatsButton/Label",
		},
		{
			"key": "chat",
			"text": UiText.HOME_CHAT,
			"callback": Callable(self, "_open_chat"),
			"button_path": "QuickButtons/ChatButton",
			"label_path": "QuickButtons/ChatButton/Label",
		},
		{
			"key": "friend",
			"text": UiText.HOME_FRIEND,
			"callback": Callable(self, "_open_friend"),
			"button_path": "QuickButtons/FriendButton",
			"label_path": "QuickButtons/FriendButton/Label",
		},
		{
			"key": "mail",
			"text": UiText.HOME_MAIL,
			"callback": Callable(self, "_on_nav_mail"),
			"button_path": "QuickButtons/MailButton",
			"label_path": "QuickButtons/MailButton/Label",
		},
	]


func _assign_home_more_button_reference(key: String, button: TextureButton) -> void:
	match key:
		"mail":
			_mail_btn = button
		"friend":
			_friend_btn = button
		"party":
			_party_btn = button
		"chat":
			_chat_btn = button
		"stats":
			_stats_btn = button
		"announcements":
			_announcement_btn = button
		"backpack":
			_backpack_btn = button
		"lineup":
			_lineup_btn = button


func _build_home_more_buttons() -> void:
	if _home_more_buttons_layer == null:
		return
	for child: Node in _home_more_buttons_layer.get_children():
		if child is TextureButton:
			child.queue_free()
	_home_more_buttons.clear()
	_home_more_button_order.clear()
	var button_paths: Array[String] = []
	var label_paths: Array[String] = []
	var defs: Array[Dictionary] = _get_home_more_button_defs()
	for def: Dictionary in defs:
		button_paths.append(str(def.get("button_path", "")))
		label_paths.append(str(def.get("label_path", "")))
	var bounds_raw: Rect2 = _get_bottom_hud_bounds_rect(button_paths, Rect2(169.0, 1035.0, 530.0, 165.0))
	var more_button_right_x: float = bounds_raw.position.x + bounds_raw.size.x
	if _nav_more_button != null:
		more_button_right_x = _nav_more_button.position.x + _nav_more_button.size.x
	var bounds: Rect2 = Rect2(0.0, bounds_raw.position.y + HOME_MORE_MENU_OFFSET_Y, more_button_right_x, bounds_raw.size.y)
	var average_button_rect: Rect2 = _get_bottom_hud_average_rect(button_paths, Rect2(bounds.position, HOME_QUICK_BUTTON_SIZE))
	var average_label_rect: Rect2 = _get_bottom_hud_average_rect(label_paths, Rect2(Vector2(8.0, 8.0), Vector2(116.0, 60.0)))
	var button_gap_x: float = maxf(0.0, _get_bottom_hud_average_gap_x(_get_main_nav_button_paths(), 0.0) + HOME_MORE_BUTTON_GAP_X)
	var button_rects: Array[Rect2] = _build_wrapped_button_layout(
		defs.size(),
		bounds,
		average_button_rect.size,
		4,
		button_gap_x,
		HOME_MORE_BUTTON_ROW_GAP_Y,
		true
	)
	for i in range(defs.size()):
		var def: Dictionary = defs[i]
		var callback: Callable = def.get("callback", Callable())
		var button: TextureButton = _build_home_quick_action_button(
			str(def.get("text", "")),
			button_rects[i].position,
			callback,
			button_rects[i].size,
			str(def.get("label_path", ""))
		)
		_apply_texture_button_label_rect(button, average_label_rect)
		button.visible = true
		_home_more_buttons_layer.add_child(button)
		var key: String = str(def.get("key", ""))
		_home_more_buttons[key] = button
		_home_more_button_order.append(key)
		_assign_home_more_button_reference(key, button)
	_refresh_home_more_badge_positions()


func _refresh_home_more_badge_positions() -> void:
	if _mail_badge != null and _mail_btn != null:
		_mail_badge.position = _mail_btn.position + Vector2(_mail_btn.size.x - 18.0, 4.0)
	if _chat_badge != null and _chat_btn != null:
		_chat_badge.position = _chat_btn.position + Vector2(_chat_btn.size.x - 18.0, 6.0)


func _set_home_quick_button_active(button: TextureButton, is_active: bool) -> void:
	if button == null:
		return
	button.set_meta("home_button_active", is_active)
	_refresh_home_quick_button_visual(button)


func _set_home_quick_button_pressed(button: TextureButton, is_pressed: bool) -> void:
	if button == null:
		return
	button.set_meta("home_button_pressed", is_pressed)
	_refresh_home_quick_button_visual(button)


func _refresh_home_quick_button_visual(button: TextureButton) -> void:
	if button == null:
		return
	var label: Label = button.get_meta("label_node", null) as Label
	if label == null:
		return
	var is_main_nav: bool = bool(button.get_meta("is_main_nav", false))
	var is_active: bool = bool(button.get_meta("home_button_active", false))
	var is_pressed: bool = bool(button.get_meta("home_button_pressed", false))
	var base_font_size: int = int(button.get_meta("label_base_font_size", HOME_NAV_BUTTON_FONT_SIZE if is_main_nav else HOME_QUICK_BUTTON_FONT_SIZE))
	var font_boost: int = HOME_NAV_LABEL_MAIN_FONT_BOOST if is_main_nav else HOME_NAV_LABEL_MORE_FONT_BOOST
	var outline_size: int = HOME_NAV_LABEL_MAIN_OUTLINE_SIZE if is_main_nav else HOME_NAV_LABEL_MORE_OUTLINE_SIZE
	var label_color: Color = HOME_NAV_LABEL_IDLE
	if is_active:
		label_color = HOME_NAV_LABEL_ACTIVE
		outline_size += 1
	if is_pressed:
		label_color = HOME_NAV_LABEL_PRESSED
		outline_size += 1
	label.add_theme_font_size_override("font_size", base_font_size + font_boost + (1 if is_active else 0))
	label.add_theme_color_override("font_color", label_color)
	label.add_theme_color_override("font_outline_color", HOME_NAV_LABEL_OUTLINE)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	var label_base_rect_variant: Variant = button.get_meta("label_base_rect", Rect2(label.position, label.size))
	var label_base_rect: Rect2 = label_base_rect_variant if label_base_rect_variant is Rect2 else Rect2(label.position, label.size)
	label.position = label_base_rect.position + Vector2(0.0, HOME_NAV_LABEL_PRESSED_OFFSET_Y if is_pressed else 0.0)
	label.size = label_base_rect.size
	label.rotation = 0.0
	button.modulate = Color(0.98, 0.96, 0.93, 1.0) if is_pressed else Color(1.0, 1.0, 1.0, 1.0)


func _apply_home_nav_button_style(button: BaseButton, is_active: bool) -> void:
	if button == null:
		return
	var texture_button: TextureButton = button as TextureButton
	if texture_button == null:
		return
	if is_active:
		texture_button.texture_normal = HOME_NAV_BUTTON_ACTIVE_TEXTURE
		texture_button.texture_hover = HOME_NAV_BUTTON_ACTIVE_TEXTURE
		texture_button.texture_pressed = HOME_NAV_BUTTON_ACTIVE_TEXTURE
	else:
		texture_button.texture_normal = HOME_NAV_BUTTON_DEFAULT_TEXTURE
		texture_button.texture_hover = HOME_NAV_BUTTON_ACTIVE_TEXTURE
		texture_button.texture_pressed = HOME_NAV_BUTTON_DEFAULT_TEXTURE
	texture_button.texture_disabled = texture_button.texture_normal
	_set_home_quick_button_active(texture_button, is_active)


func _apply_home_more_button_style(is_active: bool) -> void:
	if _nav_more_button == null:
		return
	if is_active:
		_nav_more_button.texture_normal = HOME_NAV_BUTTON_ACTIVE_TEXTURE
		_nav_more_button.texture_hover = HOME_NAV_BUTTON_ACTIVE_TEXTURE
		_nav_more_button.texture_pressed = HOME_NAV_BUTTON_ACTIVE_TEXTURE
	else:
		_nav_more_button.texture_normal = HOME_NAV_BUTTON_DEFAULT_TEXTURE
		_nav_more_button.texture_hover = HOME_NAV_BUTTON_ACTIVE_TEXTURE
		_nav_more_button.texture_pressed = HOME_NAV_BUTTON_DEFAULT_TEXTURE
	_nav_more_button.texture_disabled = _nav_more_button.texture_normal
	_set_home_quick_button_active(_nav_more_button, is_active)


func _register_home_more_button(button: TextureButton) -> void:
	if button == null or _home_more_buttons_layer == null:
		return
	if button.get_parent() != null:
		button.get_parent().remove_child(button)
	button.visible = true
	_home_more_buttons_layer.add_child(button)


func _refresh_home_more_menu_visibility() -> void:
	if _home_more_buttons_layer != null:
		_home_more_buttons_layer.visible = _home_more_menu_expanded
	_refresh_home_more_badge_positions()
	if _chat_badge != null:
		_chat_badge.visible = _home_more_menu_expanded and GameState.get_chat_total_unread() > 0
	_apply_home_more_button_style(_home_more_menu_expanded)


func _refresh_home_red_dots() -> void:
	RedDotService.refresh_dot(_nav_buttons.get("res://scenes/ScooperScene.tscn") as Control, RedDotService.has_scooper_red_dot())
	RedDotService.refresh_dot(_nav_buttons.get("res://scenes/EnhanceScene.tscn") as Control, RedDotService.has_enhance_red_dot())
	RedDotService.refresh_dot(_nav_buttons.get("res://scenes/ActivityScene.tscn") as Control, RedDotService.has_activity_red_dot())
	RedDotService.refresh_dot(_nav_buttons.get("res://scenes/ShopScene.tscn") as Control, RedDotService.has_shop_red_dot())
	RedDotService.refresh_dot(_nav_more_button, RedDotService.has_more_menu_red_dot())
	RedDotService.refresh_dot(_home_more_buttons.get("mail") as Control, RedDotService.has_mail_red_dot())
	RedDotService.refresh_dot(_home_more_buttons.get("friend") as Control, RedDotService.has_friend_red_dot())
	RedDotService.refresh_dot(_home_more_buttons.get("party") as Control, RedDotService.has_party_red_dot())
	_refresh_mail_badge()


func _toggle_home_more_menu() -> void:
	_home_more_menu_expanded = not _home_more_menu_expanded
	_refresh_home_more_menu_visibility()


func _close_home_more_menu() -> void:
	if not _home_more_menu_expanded:
		return
	_home_more_menu_expanded = false
	_refresh_home_more_menu_visibility()


func _apply_skill_speed_button_style(button: Button, is_active: bool) -> void:
	if button == null:
		return
	var show_enabled_style: bool = is_active or not button.disabled
	var bg_color: Color = UiPalette.BUTTON_PRIMARY_BG if show_enabled_style else ENHANCE_APPLY_DISABLED_BG
	var fg_color: Color = UiPalette.BUTTON_PRIMARY_FG if show_enabled_style else ENHANCE_APPLY_DISABLED_FG
	UiPalette.apply_button_palette(button, bg_color, fg_color)
	button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _make_panel(pos: Vector2, size: Vector2, fill: Color, border: Color) -> Control:
	var panel := Control.new()
	panel.position = pos
	panel.size = size

	var body := ColorRect.new()
	body.size = size
	body.color = fill
	panel.add_child(body)

	var border_thick := 2.0
	for edge in [
		[Vector2(0.0, 0.0), Vector2(size.x, border_thick)],
		[Vector2(0.0, size.y - border_thick), Vector2(size.x, border_thick)],
		[Vector2(0.0, 0.0), Vector2(border_thick, size.y)],
		[Vector2(size.x - border_thick, 0.0), Vector2(border_thick, size.y)],
	]:
		var line := ColorRect.new()
		line.position = edge[0]
		line.size = edge[1]
		line.color = border
		panel.add_child(line)

	return panel


func _format_resource_count(value: int) -> String:
	return GameState.format_number(value)


func _refresh_resource_strip() -> void:
	if _resource_value_labels.is_empty():
		return
	if _resource_value_labels.has("diamonds"):
		_resource_value_labels["diamonds"].text = _format_resource_count(GameState.player_data.diamonds)
	if _resource_value_labels.has("trap_points"):
		_resource_value_labels["trap_points"].text = _format_resource_count(GameState.player_data.trap_points)
	if _resource_value_labels.has("power"):
		_resource_value_labels["power"].text = _format_resource_count(GameState.player_data.combat_score)


func _get_home_reward_defs() -> Array[Array]:
	return [
		[UiText.REWARD_GOLD, "gold"],
		[UiText.REWARD_POOP, "poop"],
		[UiText.REWARD_CAT_FOOD, "cat_food"],
		[UiText.REWARD_DIAMONDS, "diamonds"],
		[UiText.REWARD_WHISKERS, "whiskers"],
	]


func _build_idle_reward_float_entries(rewards: Dictionary) -> Array[Dictionary]:
	var reward_entries: Array[Dictionary] = []
	for entry: Array in _get_home_reward_defs():
		var reward_key: String = str(entry[1])
		var amount: int = int(rewards.get(reward_key, 0))
		if amount > 0:
			reward_entries.append(_make_reward_float_entry(str(entry[0]), amount, reward_key))
	return reward_entries


func _build_idle_reward_slot_grid(rewards: Dictionary) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = IDLE_REWARD_GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	for entry: Array in _get_home_reward_defs():
		var reward_name: String = str(entry[0])
		var reward_key: String = str(entry[1])
		var amount: int = int(rewards.get(reward_key, 0))
		if amount <= 0:
			continue
		grid.add_child(_build_idle_reward_slot(reward_name, reward_key, amount))

	return grid


func _build_idle_reward_slot(reward_name: String, reward_key: String, amount: int) -> Control:
	var cell: Control = Control.new()
	cell.custom_minimum_size = IDLE_REWARD_SLOT_CELL_SIZE
	cell.size = IDLE_REWARD_SLOT_CELL_SIZE
	cell.tooltip_text = "%s x%s" % [reward_name, GameState.format_number(amount)]

	var slot: Control = ITEM_SLOT_TEMPLATE.instantiate() as Control
	slot.custom_minimum_size = Vector2(512.0, 512.0)
	slot.size = Vector2(512.0, 512.0)
	slot.scale = Vector2(IDLE_REWARD_SLOT_SCALE, IDLE_REWARD_SLOT_SCALE)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(slot)

	var icon: TextureRect = slot.get_node("ItemIcon") as TextureRect
	var name_label: Label = slot.get_node("ItemNameLabel") as Label
	var count_label: Label = slot.get_node("CountLabel") as Label
	var texture: Texture2D = AssetResolver.load_texture(_get_idle_reward_icon_path(reward_key))
	if texture != null:
		icon.texture = texture
		icon.visible = true
	else:
		icon.visible = false

	name_label.text = reward_name
	name_label.tooltip_text = reward_name
	name_label.add_theme_font_size_override("font_size", 52)
	count_label.text = GameState.format_number(amount)
	count_label.tooltip_text = count_label.text
	count_label.add_theme_font_size_override("font_size", 66)
	return cell


func _get_idle_reward_icon_path(reward_key: String) -> String:
	match reward_key:
		"gold":
			return AssetResolver.resolve_catalog_path("catalog/currency/gold")
		"poop":
			return AssetResolver.resolve_catalog_path("catalog/consumable/poop_count")
		"cat_food":
			return AssetResolver.resolve_catalog_path("catalog/consumable/cat_food")
		"diamonds":
			return AssetResolver.resolve_catalog_path("catalog/currency/diamonds")
		"whiskers":
			return AssetResolver.resolve_catalog_path("catalog/consumable/whisker_shards")
		_:
			return ""


func _get_reward_float_color(reward_key: String, override_color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> Color:
	if override_color.a > 0.0:
		return override_color
	match reward_key:
		"gold":
			return Color(1.0, 0.84, 0.25, 1.0)
		"diamonds":
			return Color(0.35, 0.86, 1.0, 1.0)
		"poop":
			return Color(0.80, 0.58, 0.35, 1.0)
		"exp":
			return Color(0.63, 0.96, 0.54, 1.0)
		"memory_shards":
			return Color(0.87, 0.72, 1.0, 1.0)
		"whiskers":
			return Color(1.0, 0.66, 0.82, 1.0)
		"cat_food":
			return Color(1.0, 0.73, 0.43, 1.0)
		_:
			return REWARD_FLOAT_DEFAULT_COLOR


func _make_reward_float_entry(label: String, amount: int, reward_key: String, color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> Dictionary:
	return {
		"label": label,
		"amount": amount,
		"key": reward_key,
		"color": _get_reward_float_color(reward_key, color),
	}


func make_reward_float_entry(label: String, amount: int, reward_key: String, color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> Dictionary:
	return _make_reward_float_entry(label, amount, reward_key, color)


func build_idle_reward_float_entries(rewards: Dictionary) -> Array[Dictionary]:
	return _build_idle_reward_float_entries(rewards)


func _queue_reward_floats(entries: Array[Dictionary]) -> void:
	for entry in entries:
		if int(entry.get("amount", 0)) <= 0:
			continue
		_reward_fx_queue.append(entry)
	if _reward_fx_active or _reward_fx_queue.is_empty():
		return
	_play_next_reward_float()


func queue_home_reward_floats(entries: Array[Dictionary]) -> void:
	_queue_reward_floats(entries)


func _play_next_reward_float() -> void:
	if _reward_fx_queue.is_empty():
		_reward_fx_active = false
		return
	_reward_fx_active = true
	_spawn_reward_float(_reward_fx_queue.pop_front())
	var delay_timer := get_tree().create_timer(REWARD_FLOAT_STEP_DELAY)
	delay_timer.timeout.connect(_play_next_reward_float)


func _spawn_reward_float(entry: Dictionary) -> void:
	if _reward_fx_layer == null:
		return
	var amount := int(entry.get("amount", 0))
	if amount <= 0:
		return

	var label := Label.new()
	label.text = "%s +%s" % [str(entry.get("label", "")), _format_resource_count(amount)]
	label.size = REWARD_FLOAT_LABEL_SIZE
	label.position = Vector2((SW - REWARD_FLOAT_LABEL_SIZE.x) / 2.0, REWARD_FLOAT_START_Y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_color", entry.get("color", REWARD_FLOAT_DEFAULT_COLOR))
	label.add_theme_color_override("font_outline_color", Color(0.16, 0.09, 0.04, 0.92))
	label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	label.scale = Vector2(0.92, 0.92)
	_reward_fx_layer.add_child(label)
	_play_reward_float_sfx(str(entry.get("key", "")))

	var motion_tween := create_tween()
	motion_tween.set_parallel(true)
	motion_tween.tween_property(label, "position:y", REWARD_FLOAT_START_Y - REWARD_FLOAT_RISE, REWARD_FLOAT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion_tween.finished.connect(label.queue_free)

	var fade_tween := create_tween()
	fade_tween.tween_property(label, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_tween.tween_interval(REWARD_FLOAT_DURATION - 0.36)
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _play_reward_float_demo_tick() -> void:
	var demo_entries: Array[Dictionary] = [
		_make_reward_float_entry(UiText.REWARD_GOLD, 1234, "gold"),
		_make_reward_float_entry(UiText.REWARD_DIAMONDS, 18, "diamonds"),
		_make_reward_float_entry(UiText.REWARD_POOP, 2, "poop"),
		_make_reward_float_entry(UiText.REWARD_CAT_FOOD, 25, "cat_food"),
		_make_reward_float_entry(UiText.REWARD_WHISKERS, 8, "whiskers"),
	]
	if demo_entries.is_empty():
		return
	_queue_reward_floats([demo_entries[_reward_float_demo_index % demo_entries.size()]])
	_reward_float_demo_index += 1


func _play_reward_float_sfx(reward_key: String) -> void:
	var stream: AudioStream = REWARD_SFX_BY_KEY.get(reward_key, REWARD_DEFAULT_SFX)
	if stream == null:
		return
	UiAudio.play_sfx(stream)


func _set_speed(mult: float, active_btn: Button) -> void:
	_current_speed_mult = mult
	_battle_manager.set_speed(mult)
	_refresh_speed_boost_button()
	_highlight_speed_btn(active_btn)


func _cycle_speed() -> void:
	if _is_free_speed_boost_active() or _free_speed_boost_used:
		return
	_free_speed_boost_mult = _get_free_speed_boost_mult()
	_free_speed_boost_end_unix = int(Time.get_unix_time_from_system()) + FREE_SPEED_BOOST_DURATION_SECONDS
	_free_speed_boost_used = true
	_set_speed(_free_speed_boost_mult, _speed_1x)


func _get_available_speed_options() -> Array[float]:
	var options: Array[float] = [1.0]
	if GameState.get_special_ability_speed_cap() > 1.0:
		options.append(1.2)
		options.append(1.5)
	return options


func _format_speed_label(mult: float) -> String:
	if is_equal_approx(mult, 1.0):
		return "1x"
	if is_equal_approx(mult, 1.2):
		return "1.2x"
	if is_equal_approx(mult, 1.5):
		return "1.5x"
	return "%.1fx" % mult


func _apply_speed_unlocks() -> void:
	_refresh_speed_boost_button()


func _highlight_speed_btn(active: Button) -> void:
	for btn: Button in [_speed_1x, _speed_2x, _speed_3x]:
		if btn == null or not btn.visible:
			continue
		_apply_skill_speed_button_style(btn, btn == active)


func _refresh_speed_boost_state() -> void:
	var boost_active: bool = _is_free_speed_boost_active()
	if boost_active and not is_equal_approx(_current_speed_mult, _free_speed_boost_mult):
		_set_speed(_free_speed_boost_mult, _speed_1x)
	elif not boost_active and _free_speed_boost_end_unix != 0:
		_free_speed_boost_end_unix = 0
		_free_speed_boost_mult = 1.0
		_set_speed(1.0, _speed_1x)
	else:
		_refresh_speed_boost_button()


func _is_free_speed_boost_active() -> bool:
	return _free_speed_boost_end_unix > int(Time.get_unix_time_from_system())


func _refresh_speed_boost_button() -> void:
	if _speed_1x == null:
		return
	if _is_free_speed_boost_active():
		var remaining_seconds: int = _free_speed_boost_end_unix - int(Time.get_unix_time_from_system())
		_speed_1x.text = UiText.BATTLE_SPEED_BOOSTING_FORMAT % [_format_speed_label(_free_speed_boost_mult), _format_countdown_time(remaining_seconds)]
		_speed_1x.disabled = true
	elif _free_speed_boost_used:
		_speed_1x.text = UiText.BATTLE_SPEED_BOOSTED
		_speed_1x.disabled = true
	else:
		_speed_1x.text = UiText.HOME_SPEED_BOOST
		_speed_1x.disabled = false
	_highlight_speed_btn(_speed_1x if _is_free_speed_boost_active() else null)
	_apply_skill_speed_button_style(_speed_1x, _is_free_speed_boost_active() or not _speed_1x.disabled)


func _format_countdown_time(total_seconds: int) -> String:
	var clamped_seconds: int = maxi(total_seconds, 0)
	var minutes: int = floori(float(clamped_seconds) / 60.0)
	var seconds: int = clamped_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _get_free_speed_boost_mult() -> float:
	var speed_cap: float = GameState.get_special_ability_speed_cap()
	if speed_cap >= 3.0:
		return 3.0
	if speed_cap >= 2.0:
		return 2.0
	if speed_cap >= 1.5:
		return 1.5
	return DEFAULT_FREE_SPEED_BOOST_MULT


func _refresh_ui() -> void:
	_level_label.text = GameState.get_level_display()
	if _profile_name_label != null:
		_profile_name_label.text = GameState.get_profile_display_name()
	if _profile_level_label != null:
		_profile_level_label.text = str(GameState.player_data.scooper_level)
	if _top_avatar_rect != null:
		var avatar_texture: Texture2D = AssetResolver.resolve_profile_avatar(GameState.get_profile_avatar_id())
		_top_avatar_rect.texture = avatar_texture if avatar_texture != null else PROFILE_AVATAR_TEXTURE
	if _top_exp_bar != null and _top_progress_value_label != null:
		var top_profile: Dictionary = GameState.scooper_profile_data
		var top_scooper_level: int
		var top_exp: int
		var top_threshold: int
		if not top_profile.is_empty():
			top_scooper_level = int(top_profile.get("scooperLevel", GameState.player_data.scooper_level))
			top_exp = int(top_profile.get("scooperExp", GameState.player_data.scooper_exp))
			top_threshold = int(top_profile.get("expThreshold", max((top_scooper_level + 1) * 10, 1)))
		else:
			top_scooper_level = GameState.player_data.scooper_level
			top_exp = GameState.player_data.scooper_exp
			top_threshold = max((top_scooper_level + 1) * int(GameState.idle_config.get("scooper_exp_per_level", 10)), 1)
		_top_exp_bar.max_value = top_threshold
		_top_exp_bar.value = top_exp
		_top_progress_value_label.text = "EXP %s/%s" % [GameState.format_number(top_exp), GameState.format_number(top_threshold)]
	_boss_btn.visible = GameState.boss_available and not GameState.is_current_boss()
	_refresh_resource_strip()
	_refresh_sandbox_btn()
	_refresh_home_scoop_panel()
	_apply_home_hud_fonts()
	_refresh_chat_badge()
	_refresh_home_more_menu_visibility()
	_refresh_home_red_dots()


func _refresh_sandbox_btn() -> void:
	if _sandbox_btn == null:
		return
	var overlay_open: bool = not SceneNavigator.get_current_overlay_scene_path().is_empty()
	var elapsed := GameState.get_idle_elapsed_seconds()
	var claimable_minutes: int = floori(float(elapsed) / 60.0)
	_sandbox_btn.disabled = false
	if claimable_minutes < 1:
		_sandbox_btn.text = UiText.HOME_IDLE_NOT_READY
		UiPalette.apply_button_kind(_sandbox_btn, "neutral")
	else:
		var h: int = floori(float(elapsed) / 3600.0)
		var m: int = floori(float(elapsed % 3600) / 60.0)
		var s := elapsed % 60
		_sandbox_btn.text = "%s %02d:%02d:%02d" % [UiText.HOME_IDLE_READY, h, m, s]
		UiPalette.apply_button_kind(_sandbox_btn, "primary")
	var has_coupon_red_dot: bool = GameState.get_party_cheer_coupon_count() > 0
	RedDotService.refresh_dot(_sandbox_btn, not overlay_open and (has_coupon_red_dot or _has_idle_claim_red_dot()), 1)


func _refresh_home_scoop_panel() -> void:
	if _home_scoop_button == null:
		return
	_layout_home_scoop_panel()

	var profile: Dictionary = GameState.scooper_profile_data
	var level: int
	var current_exp: int
	var threshold: int
	if not profile.is_empty():
		level = int(profile.get("scooperLevel", GameState.player_data.scooper_level))
		current_exp = int(profile.get("scooperExp", GameState.player_data.scooper_exp))
		threshold = int(profile.get("expThreshold", max((level + 1) * 10, 1)))
	else:
		level = GameState.player_data.scooper_level
		current_exp = GameState.player_data.scooper_exp
		threshold = max((level + 1) * int(GameState.idle_config.get("scooper_exp_per_level", 10)), 1)

	if _home_exp_bar != null:
		_home_exp_bar.max_value = threshold
		_home_exp_bar.value = current_exp
	if _home_exp_label != null:
		_home_exp_label.text = "Lv.%d  EXP %s / %s" % [level, GameState.format_number(current_exp), GameState.format_number(threshold)]

	var poop_count := GameState.player_data.poop_count
	_home_scoop_button.disabled = poop_count <= 0 or _home_scoop_request_in_flight or _home_scoop_animation_active
	_home_scoop_button.modulate = Color(0.97, 0.93, 0.88, 1.0) if poop_count > 0 else Color(0.62, 0.60, 0.58, 1.0)
	if poop_count <= 0 and _home_auto_scoop_enabled:
		_set_home_auto_scoop_enabled(false)
	if _home_scoop_count_label != null:
		_home_scoop_count_label.text = _format_resource_count(poop_count)
	if _home_scoop_result_label != null and _home_scoop_result_label.text.is_empty():
		_home_scoop_result_label.visible = false

	if _home_scoop_overlay != null and _home_scoop_cd_label != null:
		_home_scoop_overlay.visible = false
		_home_scoop_cd_label.visible = false
	_refresh_home_auto_scoop_toggle_button()


func _layout_home_scoop_panel() -> void:
	if _home_scoop_panel == null or _home_scoop_button == null:
		return
	var editor_panel: Control = _get_bottom_hud_control("HomeScoopPanel")
	if editor_panel != null:
		_home_scoop_panel.position = editor_panel.position
		return
	var enhance_btn_variant: Variant = _nav_buttons.get("res://scenes/EnhanceScene.tscn")
	var enhance_btn: TextureButton = enhance_btn_variant as TextureButton
	if enhance_btn == null:
		return
	var target_center_x: float = enhance_btn.position.x + enhance_btn.size.x * 0.5
	var target_button_x: float = target_center_x - (_home_scoop_button.size.x * 0.5) + HOME_SCOOP_TEMPLATE_ENHANCE_CENTER_OFFSET_X
	var target_button_y: float = NAV_Y - _home_scoop_button.size.y
	_home_scoop_panel.position = Vector2(
		target_button_x - _home_scoop_button.position.x,
		target_button_y - _home_scoop_button.position.y
	)


func _refresh_main_nav_state() -> void:
	var active_scene_path: String = SceneNavigator.get_current_overlay_scene_path()
	for scene_path: String in _nav_buttons.keys():
		var btn: TextureButton = _nav_buttons[scene_path] as TextureButton
		if btn == null:
			continue
		var is_active: bool = scene_path == active_scene_path
		_apply_home_nav_button_style(btn, is_active)
	_apply_home_more_button_style(_home_more_menu_expanded)


func get_damage_fx_host() -> Node2D:
	return _damage_fx_layer if _damage_fx_layer != null else self


func _refresh_overlay_fx_state() -> void:
	var overlay_open: bool = not SceneNavigator.get_current_overlay_scene_path().is_empty()
	if _damage_fx_layer != null:
		if overlay_open:
			for child: Node in _damage_fx_layer.get_children():
				child.queue_free()
		_damage_fx_layer.visible = not overlay_open


func _clear_battle_transient_fx() -> void:
	if _damage_fx_layer != null:
		for child: Node in _damage_fx_layer.get_children():
			child.queue_free()
	if _reward_fx_layer != null:
		for child: Node in _reward_fx_layer.get_children():
			child.queue_free()
	_reward_fx_queue.clear()
	_reward_fx_active = false


func _refresh_mail_badge() -> void:
	if _mail_badge == null:
		return
	_refresh_home_more_badge_positions()
	_mail_badge.visible = false


# Battle flow

func _start_battle() -> void:
	_start_battle_internal()


func _start_battle_internal() -> void:
	if _result_display != null:
		_result_display.texture = null
		_result_display.visible = false
	if _result_backdrop != null:
		_result_backdrop.visible = false
		_result_backdrop.scale = Vector2.ONE
		_result_backdrop.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_refresh_ui()

	var player_cats: Array = []
	var enemy_cats: Array = []
	var team_power_total: int = 0

	for i in range(GameState.player_team.size()):
		var player_cat_id: int = GameState.player_team[i]
		var cat_id: String = GameState.get_cat_file_id(player_cat_id)
		if cat_id.is_empty():
			push_error("BattleScene: failed to resolve local cat file id for playerCatId %d" % player_cat_id)
			continue
		var path := cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			if data.active_skill_configs.size() > 0:
				data.active_skill_configs[0]["initial_delay"] = GameState.get_delay(i)
			var player_cat := GameState.get_player_cat(cat_id)
			data.apply_enhancement(player_cat)
			data.apply_rank_bonus(player_cat)
			_apply_equipment_bonuses(data)
			team_power_total += int(data.max_hp) + int(data.atk) * 6 + int(data.defense) * 4
			# Reload skills after enhancement so the initial delay stays in sync.
			data._load_skill_data()
			if data.active_skills_data.size() > 0:
				data.active_skills_data[0]["initial_delay"] = GameState.get_delay(i)
			player_cats.append(data)
		else:
			push_error("BattleScene: failed to load player cat " + cat_id)

	var diff_mult: float = GameState.get_difficulty_multiplier()
	for cat_id: String in GameState.get_enemy_ids():
		var path := cat_id + ".json"
		var data := CatData.from_json_file(path)
		if data:
			data.max_hp  = roundi(data.max_hp  * diff_mult)
			data.atk     = roundi(data.atk     * diff_mult)
			data.defense = roundi(data.defense * diff_mult)
			data.weight  = roundi(data.weight  * diff_mult)
			enemy_cats.append(data)
		else:
			push_error("BattleScene: failed to load enemy cat " + cat_id)

	if player_cats.is_empty() or enemy_cats.is_empty():
		push_error("BattleScene: insufficient cat data; cannot start battle")
		return

	_cached_team_power = max(team_power_total, 0)
	_refresh_resource_strip()
	_refresh_skill_bar_names(player_cats)

	_current_enemy_cats = enemy_cats.duplicate()
	_clear_battle_transient_fx()
	_clear_team_nodes(_player_team)
	_clear_team_nodes(_enemy_team)
	_battle_manager.setup([], player_cats, enemy_cats,
			_player_team, _enemy_team, _timer_label, _skill_bar)
	_set_skill_filter_mode(_skill_filter_mode)
	if GameState.is_current_boss():
		_start_boss_warning_phase()


func _clear_team_nodes(team_node: Node2D) -> void:
	if team_node == null:
		return
	for child: Node in team_node.get_children():
		team_node.remove_child(child)
		child.queue_free()


func restart_with_latest_team() -> void:
	GameState.apply_active_team_from_config("Boss")
	_start_battle()


func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()


func _on_battle_finished(result: String) -> void:
	_last_result = result
	var is_boss := GameState.is_current_boss()

	if result == "WIN":
		if is_boss:
			_show_result_overlay(true)
		GameState.advance_after_win()
		if is_boss:
			await get_tree().create_timer(1.0).timeout
		_start_battle()
	else:
		_show_result_overlay(false)
		if is_boss:
			GameState.on_boss_fail()
		await get_tree().create_timer(1.0).timeout
		_start_battle()


func _show_result_overlay(is_win: bool) -> void:
	if _result_backdrop == null or _result_display == null:
		return

	var overlay_texture: Texture2D = RESULT_VICTORY_TEXTURE if is_win else RESULT_DEFEAT_TEXTURE
	_show_center_overlay(overlay_texture, true)


func _show_center_overlay(texture: Texture2D, fill_screen: bool = false) -> void:
	if _result_backdrop == null or _result_display == null or texture == null:
		return

	_stop_boss_warning_overlay_fx()
	_set_boss_warning_overlay_content_visible(not fill_screen)
	if fill_screen:
		var result_overlay_size: Vector2 = Vector2(SW, SH) * RESULT_OVERLAY_DISPLAY_SCALE
		_result_display.texture = texture
		_result_display.size = result_overlay_size
		_result_display.position = Vector2(
			(SW - result_overlay_size.x) * 0.5,
			RESULT_OVERLAY_OFFSET_Y + ((SH - result_overlay_size.y) * 0.5)
		)
		_result_display.visible = true
		if _boss_warning_overlay != null:
			_boss_warning_overlay.visible = false
	else:
		_result_display.texture = null
		_result_display.visible = false
		if _boss_warning_overlay != null:
			_boss_warning_overlay.position = Vector2(
				(SW - BOSS_WARNING_DISPLAY_W) * 0.5,
				BOSS_WARNING_DISPLAY_Y
			)
			_boss_warning_overlay.size = Vector2(BOSS_WARNING_DISPLAY_W, BOSS_WARNING_DISPLAY_H)
			_boss_warning_overlay.scale = Vector2.ONE
			_boss_warning_overlay.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_boss_warning_overlay.pivot_offset = _boss_warning_overlay.size * 0.5
			_boss_warning_overlay.visible = true
	_result_backdrop.visible = true
	_result_backdrop.scale = Vector2(RESULT_OVERLAY_START_SCALE, RESULT_OVERLAY_START_SCALE)
	_result_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_result_backdrop.pivot_offset = _result_backdrop.size * 0.5

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_result_backdrop, "modulate:a", 1.0, 0.10).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_backdrop, "scale", Vector2(RESULT_OVERLAY_OVERSHOOT_SCALE, RESULT_OVERLAY_OVERSHOOT_SCALE), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_result_backdrop, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _play_boss_warning_overlay() -> void:
	_show_center_overlay(BOSS_WARNING_TEXTURE, false)
	_refresh_boss_warning_overlay_content()
	_start_boss_warning_overlay_fx()


func _refresh_boss_warning_overlay_content() -> void:
	if _boss_warning_icon == null or _boss_warning_text_label == null:
		return

	_boss_warning_text_label.text = BOSS_WARNING_TEXT
	var icon_texture: Texture2D = null
	if not _current_enemy_cats.is_empty():
		var boss_cat: CatData = _current_enemy_cats[0] as CatData
		if boss_cat != null:
			icon_texture = AssetResolver.resolve_cat_icon(boss_cat.id)
	_boss_warning_icon.texture = icon_texture
	_set_boss_warning_overlay_content_visible(_result_backdrop != null and _result_backdrop.visible)


func _set_boss_warning_overlay_content_visible(should_show: bool) -> void:
	if _boss_warning_icon != null:
		_boss_warning_icon.visible = should_show and _boss_warning_icon.texture != null
	if _boss_warning_text_label != null:
		_boss_warning_text_label.visible = should_show


func _start_boss_warning_overlay_fx() -> void:
	if _boss_warning_overlay == null or not _boss_warning_overlay.visible:
		return

	_stop_boss_warning_overlay_fx()
	_boss_warning_overlay.scale = Vector2.ONE
	_boss_warning_overlay.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_boss_warning_flash_tween = create_tween()
	_boss_warning_flash_tween.set_loops()
	_boss_warning_flash_tween.tween_property(_boss_warning_overlay, "modulate:a", BOSS_WARNING_FLASH_ALPHA, BOSS_WARNING_FLASH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_boss_warning_flash_tween.tween_property(_boss_warning_overlay, "modulate:a", 1.0, BOSS_WARNING_FLASH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_boss_warning_pulse_tween = create_tween()
	_boss_warning_pulse_tween.set_loops()
	_boss_warning_pulse_tween.tween_property(_boss_warning_overlay, "scale", Vector2(BOSS_WARNING_PULSE_SCALE, BOSS_WARNING_PULSE_SCALE), BOSS_WARNING_PULSE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_boss_warning_pulse_tween.tween_property(_boss_warning_overlay, "scale", Vector2.ONE, BOSS_WARNING_PULSE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _stop_boss_warning_overlay_fx() -> void:
	if _boss_warning_flash_tween != null:
		_boss_warning_flash_tween.kill()
		_boss_warning_flash_tween = null
	if _boss_warning_pulse_tween != null:
		_boss_warning_pulse_tween.kill()
		_boss_warning_pulse_tween = null


func _hide_center_overlay() -> void:
	_stop_boss_warning_overlay_fx()
	if _result_backdrop != null:
		_result_backdrop.visible = false
		_result_backdrop.scale = Vector2.ONE
		_result_backdrop.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if _result_display != null:
		_result_display.scale = Vector2.ONE
		_result_display.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_result_display.texture = null
		_result_display.visible = false
	if _boss_warning_overlay != null:
		_boss_warning_overlay.scale = Vector2.ONE
		_boss_warning_overlay.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_boss_warning_overlay.visible = false
	_set_boss_warning_overlay_content_visible(false)


func _start_boss_warning_phase() -> void:
	_battle_manager.prime_initial_spawn_state()
	_battle_manager.pause_battle()
	_play_boss_warning_overlay()
	var warning_timer: SceneTreeTimer = get_tree().create_timer(BOSS_WARNING_DURATION_SECONDS)
	warning_timer.timeout.connect(_on_boss_warning_finished, CONNECT_ONE_SHOT)


func _on_boss_warning_finished() -> void:
	_hide_center_overlay()
	_battle_manager.resume_battle()


func _on_challenge_boss_pressed() -> void:
	_clear_battle_transient_fx()
	GameState.challenge_boss()
	_start_battle()


# Navigation

## Apply scooper-related combat bonuses to the cat data.
func _apply_equipment_bonuses(data: CatData) -> void:
	GameState.apply_player_combat_bonuses(data)


func _on_nav_scooper() -> void:
	_toggle_overlay_scene("res://scenes/ScooperScene.tscn")


func _toggle_overlay_scene(scene_path: String) -> void:
	if scene_path != "":
		_home_more_menu_expanded = false
		_refresh_home_more_menu_visibility()
	SceneNavigator.toggle_overlay_scene(scene_path)
	_last_overlay_scene_path = SceneNavigator.get_current_overlay_scene_path()
	_refresh_main_nav_state()
	_refresh_overlay_fx_state()
	_refresh_home_red_dots()
	_refresh_sandbox_btn()


func _on_home_scoop_pressed() -> void:
	_trigger_home_scoop(true)


func _on_home_auto_scoop_toggle_pressed() -> void:
	UiAudio.play_ui_click()
	_set_home_auto_scoop_enabled(not _home_auto_scoop_enabled)


func _set_home_auto_scoop_enabled(enabled: bool) -> void:
	_home_auto_scoop_enabled = enabled
	_refresh_home_auto_scoop_toggle_button()


func _refresh_home_auto_scoop_toggle_button() -> void:
	if _home_auto_scoop_toggle_button == null:
		return
	var toggle_texture: Texture2D = HOME_AUTO_SCOOP_TOGGLE_ON_TEXTURE if _home_auto_scoop_enabled else HOME_AUTO_SCOOP_TOGGLE_OFF_TEXTURE
	_home_auto_scoop_toggle_button.texture_normal = toggle_texture
	_home_auto_scoop_toggle_button.texture_pressed = toggle_texture
	_home_auto_scoop_toggle_button.texture_hover = toggle_texture
	_home_auto_scoop_toggle_button.texture_disabled = toggle_texture
	_home_auto_scoop_toggle_button.texture_focused = toggle_texture
	_home_auto_scoop_toggle_button.modulate = Color(1.0, 1.0, 1.0, 0.72) if GameState.player_data.poop_count <= 0 and not _home_auto_scoop_enabled else Color(1.0, 1.0, 1.0, 1.0)


func _update_home_auto_scoop() -> void:
	if not _home_auto_scoop_enabled:
		return
	if GameState.player_data.poop_count <= 0:
		_set_home_auto_scoop_enabled(false)
		return
	if _home_scoop_request_in_flight or _home_scoop_animation_active or _home_scoop_cooldown_remaining > 0.0:
		return
	_trigger_home_scoop(false)


func _get_home_auto_scoop_batch_size() -> int:
	var profile: Dictionary = GameState.scooper_profile_data
	if int(profile.get("autoScoopBatchSize", 0)) > 0:
		return int(profile.get("autoScoopBatchSize", 1))
	if int(GameState.idle_config.get("auto_scoop_batch_size", 0)) > 0:
		return int(GameState.idle_config.get("auto_scoop_batch_size", 1))
	var ability_summary: Dictionary = GameState.get_special_ability_summary()
	if int(ability_summary.get("auto_scoop_batch_size", 0)) > 0:
		return int(ability_summary.get("auto_scoop_batch_size", 1))
	return 1


func _trigger_home_scoop(play_click_sound: bool) -> void:
	if _home_scoop_request_in_flight or _home_scoop_cooldown_remaining > 0.0 or _home_scoop_animation_active or GameState.player_data.poop_count <= 0:
		return

	if play_click_sound:
		UiAudio.play_ui_click()
	if _home_scoop_result_label != null:
		_home_scoop_result_label.text = ""
		_home_scoop_result_label.visible = false
	_home_scoop_profile_fetch_in_flight = false
	_home_scoop_pending_result.clear()
	_home_scoop_pending_profile.clear()
	_home_scoop_pending_reward_entries.clear()
	_home_scoop_previous_profile = GameState.scooper_profile_data.duplicate(true)
	_home_scoop_previous_player_exp = GameState.player_data.scooper_exp
	_home_scoop_previous_player_memory_shards = GameState.player_data.memory_shards
	_home_scoop_previous_player_whiskers = GameState.player_data.whisker_shards
	_home_scoop_request_in_flight = true
	_home_scoop_response_ready = false
	_home_scoop_cooldown_remaining = HOME_SCOOP_COOLDOWN
	_start_home_scoop_animation()
	_refresh_home_scoop_panel()
	var scoop_count: int = mini(_get_home_auto_scoop_batch_size(), max(GameState.player_data.poop_count, 1))
	ApiClient.scoop_poop_silent(scoop_count, Callable(self, "_on_home_scoop_silent_completed"))


func _build_home_scoop_frames() -> void:
	_home_scoop_frames.clear()
	if HOME_SCOOP_SHEET_TEXTURE == null:
		return
	for frame_index: int in range(HOME_SCOOP_FRAME_COUNT):
		var atlas_texture: AtlasTexture = AtlasTexture.new()
		atlas_texture.atlas = HOME_SCOOP_SHEET_TEXTURE
		atlas_texture.region = Rect2(
			float(frame_index * HOME_SCOOP_FRAME_SIZE.x),
			0.0,
			float(HOME_SCOOP_FRAME_SIZE.x),
			float(HOME_SCOOP_FRAME_SIZE.y)
		)
		_home_scoop_frames.append(atlas_texture)


func _set_home_scoop_frame(frame_index: int) -> void:
	if _home_scoop_button == null or _home_scoop_frames.is_empty():
		return
	var safe_index: int = clampi(frame_index, 0, _home_scoop_frames.size() - 1)
	_home_scoop_frame_index = safe_index
	var frame_texture: Texture2D = _home_scoop_frames[safe_index]
	_home_scoop_button.texture_normal = frame_texture
	_home_scoop_button.texture_pressed = frame_texture
	_home_scoop_button.texture_hover = frame_texture
	_home_scoop_button.texture_disabled = frame_texture
	_home_scoop_button.texture_focused = frame_texture


func _start_home_scoop_animation() -> void:
	if _home_scoop_frames.size() <= 1:
		return
	_home_scoop_animation_active = true
	_home_scoop_animation_elapsed = 0.0
	_set_home_scoop_frame(HOME_SCOOP_ANIMATION_START_FRAME)


func _update_home_scoop_animation(delta: float) -> void:
	if _home_scoop_frames.size() <= 1:
		_home_scoop_animation_active = false
		return
	_home_scoop_animation_elapsed += delta
	var animated_frame_count: int = _home_scoop_frames.size() - HOME_SCOOP_ANIMATION_START_FRAME
	if animated_frame_count <= 0:
		_home_scoop_animation_active = false
		_set_home_scoop_frame(0)
		return
	var progress: float = clampf(_home_scoop_animation_elapsed / HOME_SCOOP_COOLDOWN, 0.0, 1.0)
	var frame_offset: int = int(floor(progress * float(animated_frame_count)))
	var frame_index: int = HOME_SCOOP_ANIMATION_START_FRAME + frame_offset
	if frame_index >= _home_scoop_frames.size():
		_home_scoop_animation_active = false
		_home_scoop_animation_elapsed = 0.0
		_set_home_scoop_frame(0)
		_try_finalize_home_scoop_resolution()
		return
	if frame_index != _home_scoop_frame_index:
		_set_home_scoop_frame(frame_index)


func _on_home_coupon_pressed() -> void:
	if _home_coupon_button == null or _home_coupon_button.disabled:
		return

	_home_coupon_button.disabled = true
	ApiClient.use_party_cheer_coupon(Callable(self, "_on_home_coupon_completed"))


func _refresh_party_cheer_coupon_button(button: Button) -> void:
	if button == null:
		return
	var coupon_count: int = GameState.get_party_cheer_coupon_count()
	button.text = UiText.HOME_PARTY_COUPON_BUTTON_FORMAT % coupon_count
	button.disabled = coupon_count <= 0 or _get_party_cheer_coupon_cooldown_remaining(button) > 0.0
	if _get_party_cheer_coupon_cooldown_remaining(button) <= 0.0:
		_set_party_cheer_coupon_cooldown_visual(button, 0.0)
	RedDotService.refresh_dot(button, coupon_count > 0)


func _start_party_cheer_coupon_cooldown(button: Button) -> void:
	if button == null:
		return
	_refresh_party_cheer_coupon_button(button)
	button.set_meta("party_cheer_coupon_cooldown_remaining", PARTY_CHEER_COUPON_REUSE_COOLDOWN_SECONDS)
	button.disabled = true
	_set_party_cheer_coupon_cooldown_visual(button, PARTY_CHEER_COUPON_REUSE_COOLDOWN_SECONDS)
	if not _party_cheer_coupon_cooldown_buttons.has(button):
		_party_cheer_coupon_cooldown_buttons.append(button)


func _update_party_cheer_coupon_cooldowns(delta: float) -> void:
	if _party_cheer_coupon_cooldown_buttons.is_empty():
		return
	for index: int in range(_party_cheer_coupon_cooldown_buttons.size() - 1, -1, -1):
		var button: Button = _party_cheer_coupon_cooldown_buttons[index]
		if not is_instance_valid(button):
			_party_cheer_coupon_cooldown_buttons.remove_at(index)
			continue
		var remaining: float = maxf(0.0, _get_party_cheer_coupon_cooldown_remaining(button) - delta)
		button.set_meta("party_cheer_coupon_cooldown_remaining", remaining)
		_set_party_cheer_coupon_cooldown_visual(button, remaining)
		if remaining > 0.0:
			continue
		button.remove_meta("party_cheer_coupon_cooldown_remaining")
		_party_cheer_coupon_cooldown_buttons.remove_at(index)
		_refresh_party_cheer_coupon_button(button)


func _get_party_cheer_coupon_cooldown_remaining(button: Button) -> float:
	if button == null or not button.has_meta("party_cheer_coupon_cooldown_remaining"):
		return 0.0
	return float(button.get_meta("party_cheer_coupon_cooldown_remaining"))


func _set_party_cheer_coupon_cooldown_visual(button: Button, remaining_seconds: float) -> void:
	if button == null:
		return
	var overlay: ColorRect = _ensure_party_cheer_coupon_cooldown_overlay(button)
	var label: Label = _ensure_party_cheer_coupon_cooldown_label(button)
	var button_size: Vector2 = button.size
	if button_size.x <= 0.0 or button_size.y <= 0.0:
		button_size = button.get_combined_minimum_size()
	if remaining_seconds <= 0.0:
		overlay.visible = false
		label.visible = false
		return
	var progress: float = clampf(remaining_seconds / PARTY_CHEER_COUPON_REUSE_COOLDOWN_SECONDS, 0.0, 1.0)
	overlay.visible = true
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(button_size.x * progress, button_size.y)
	label.visible = true
	label.position = Vector2.ZERO
	label.size = button_size
	label.text = "%.1fs" % remaining_seconds


func _ensure_party_cheer_coupon_cooldown_overlay(button: Button) -> ColorRect:
	if button.has_meta("party_cheer_coupon_cooldown_overlay"):
		var existing_overlay: ColorRect = button.get_meta("party_cheer_coupon_cooldown_overlay") as ColorRect
		if is_instance_valid(existing_overlay):
			return existing_overlay
	var overlay: ColorRect = ColorRect.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0.07, 0.11, 0.20, 0.36)
	overlay.visible = false
	overlay.z_index = 1
	button.add_child(overlay)
	button.set_meta("party_cheer_coupon_cooldown_overlay", overlay)
	return overlay


func _ensure_party_cheer_coupon_cooldown_label(button: Button) -> Label:
	if button.has_meta("party_cheer_coupon_cooldown_label"):
		var existing_label: Label = button.get_meta("party_cheer_coupon_cooldown_label") as Label
		if is_instance_valid(existing_label):
			return existing_label
	var label: Label = Label.new()
	label.visible = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 2
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.90, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.92))
	label.add_theme_constant_override("outline_size", 4)
	button.add_child(label)
	button.set_meta("party_cheer_coupon_cooldown_label", label)
	return label


func _has_idle_claim_red_dot() -> bool:
	return GameState.get_idle_elapsed_seconds() >= IDLE_CLAIM_RED_DOT_THRESHOLD_SECONDS


func _show_startup_idle_rewards_dialog_if_needed() -> void:
	if _startup_idle_rewards_dialog_checked:
		return
	_startup_idle_rewards_dialog_checked = true
	if not is_inside_tree():
		return
	if not SceneNavigator.get_current_overlay_scene_path().is_empty():
		return
	if not GameState.has_pending_idle_rewards():
		return
	_show_sandbox_dialog()


func _build_scoop_reward_entries(
	result: Dictionary,
	previous_profile: Dictionary = {},
	previous_player_exp: int = 0,
	previous_player_memory_shards: int = 0,
	previous_player_whiskers: int = 0,
	final_profile: Dictionary = {}
) -> Array[Dictionary]:
	var reward_entries: Array[Dictionary] = []
	var exp_gained := int(result.get("expGained", 0))
	if exp_gained <= 0:
		var updated_profile_dict: Dictionary = final_profile
		if updated_profile_dict.is_empty():
			var updated_profile: Variant = result.get("updatedProfile", {})
			if updated_profile is Dictionary:
				updated_profile_dict = updated_profile as Dictionary
		if not updated_profile_dict.is_empty():
			var old_level: int = int(previous_profile.get("scooperLevel", GameState.player_data.scooper_level))
			var new_level: int = int(updated_profile_dict.get("scooperLevel", old_level))
			var old_exp: int = int(previous_profile.get("scooperExp", previous_player_exp))
			var new_exp: int = int(updated_profile_dict.get("scooperExp", previous_player_exp))
			if new_level == old_level:
				exp_gained = maxi(0, new_exp - old_exp)
			else:
				var old_threshold: int = int(previous_profile.get("expThreshold", max((old_level + 1) * 10, 1)))
				exp_gained = maxi(0, (old_threshold - old_exp) + new_exp)
	if exp_gained <= 0:
		exp_gained = maxi(0, int(result.get("exp", 0)))
	if exp_gained > 0:
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_EXP, exp_gained, "exp"))

	var memory_shards_gained := int(result.get("memoryShardsGained", 0))
	if memory_shards_gained <= 0:
		var new_memory_shards: int = int(final_profile.get("memoryShards", result.get("memoryShards", GameState.player_data.memory_shards)))
		memory_shards_gained = maxi(0, new_memory_shards - previous_player_memory_shards)
	if memory_shards_gained > 0:
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_MEMORY_SHARDS, memory_shards_gained, "memory_shards"))

	var whiskers_gained := int(result.get("WhiskersGained", result.get("whiskersGained", 0)))
	if whiskers_gained <= 0:
		var new_whiskers: int = int(final_profile.get("whiskers", result.get("whiskerShards", GameState.player_data.whisker_shards)))
		whiskers_gained = maxi(0, new_whiskers - previous_player_whiskers)
	if whiskers_gained > 0:
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_WHISKERS, whiskers_gained, "whiskers"))

	return reward_entries


func _try_finalize_home_scoop_resolution() -> void:
	if _home_scoop_animation_active:
		return
	if _home_scoop_request_in_flight and not _home_scoop_response_ready:
		return

	if _home_scoop_pending_profile.is_empty() and _home_scoop_response_ready:
		if _home_scoop_profile_fetch_in_flight:
			return
		_home_scoop_profile_fetch_in_flight = true
		ApiClient.get_scooper_profile_silent(Callable(self, "_on_pending_scooper_profile_fetched"))
		return

	if _home_scoop_pending_reward_entries.is_empty() and not _home_scoop_pending_profile.is_empty():
		_home_scoop_pending_reward_entries = _build_scoop_reward_entries(
			_home_scoop_pending_result,
			_home_scoop_previous_profile,
			_home_scoop_previous_player_exp,
			_home_scoop_previous_player_memory_shards,
			_home_scoop_previous_player_whiskers,
			_home_scoop_pending_profile
		)

	if _home_scoop_pending_profile.is_empty() and _home_scoop_pending_reward_entries.is_empty():
		_home_scoop_request_in_flight = false
		_home_scoop_response_ready = false
		_home_scoop_profile_fetch_in_flight = false
		_refresh_home_scoop_panel()
		return

	if not _home_scoop_pending_profile.is_empty():
		GameState.update_scooper_profile(_home_scoop_pending_profile)
	if not _home_scoop_pending_reward_entries.is_empty():
		_queue_reward_floats(_home_scoop_pending_reward_entries)

	_home_scoop_request_in_flight = false
	_home_scoop_response_ready = false
	_home_scoop_profile_fetch_in_flight = false
	_home_scoop_pending_profile.clear()
	_home_scoop_pending_result.clear()
	_home_scoop_pending_reward_entries.clear()
	_home_scoop_previous_profile.clear()
	_home_scoop_previous_player_exp = 0
	_home_scoop_previous_player_memory_shards = 0
	_home_scoop_previous_player_whiskers = 0
	_refresh_ui()


## Show the idle rewards and cleanup dialog.
func _show_sandbox_dialog() -> void:
	var elapsed_seconds := GameState.get_idle_elapsed_seconds()
	var complete_minutes: int = floori(float(elapsed_seconds) / 60.0)
	var has_rewards := complete_minutes >= 1
	var rewards := GameState.get_pending_idle_rewards() if has_rewards else {}

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(640.0, 0.0)

	# Idle rewards section
	var rewards_section := VBoxContainer.new()
	rewards_section.add_theme_constant_override("separation", 6)

	if has_rewards:
		var h: int = floori(float(complete_minutes) / 60.0)
		var m := complete_minutes % 60
		var time_lbl := Label.new()
		time_lbl.text = UiText.HOME_SANDBOX_TIME_FORMAT % [h, m]
		time_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		time_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rewards_section.add_child(time_lbl)

		var reward_grid: GridContainer = _build_idle_reward_slot_grid(rewards)
		if reward_grid.get_child_count() > 0:
			rewards_section.add_child(reward_grid)

	if has_rewards:
		vbox.add_child(rewards_section)

	# Cleanup interaction section
	var scoop_section := VBoxContainer.new()
	scoop_section.add_theme_constant_override("separation", 8)

	var poop_count_lbl := Label.new()
	poop_count_lbl.text = UiText.HOME_SANDBOX_PENDING_POOP % GameState.player_data.poop_count
	poop_count_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	scoop_section.add_child(poop_count_lbl)

	var result_lbl := Label.new()
	result_lbl.text = ""
	result_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	result_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.7, 1.0))
	scoop_section.add_child(result_lbl)

	var scoop_btn := Button.new()
	scoop_btn.text = UiText.HOME_SANDBOX_CLEAN_NOW
	scoop_btn.custom_minimum_size = Vector2(160.0, 52.0)
	scoop_btn.disabled = GameState.player_data.poop_count <= 0
	var scoop_btn_ref: WeakRef = weakref(scoop_btn)
	var result_lbl_ref: WeakRef = weakref(result_lbl)
	var poop_count_lbl_ref: WeakRef = weakref(poop_count_lbl)
	scoop_btn.pressed.connect(Callable(self, "_on_idle_scoop_pressed").bind(scoop_btn_ref, result_lbl_ref, poop_count_lbl_ref))
	scoop_section.add_child(scoop_btn)
	if false:
		vbox.add_child(scoop_section)

	# Claim rewards action
	var close_ref := [Callable()]
	var coupon_btn: Button = Button.new()
	coupon_btn.custom_minimum_size = Vector2(200.0, 46.0)
	_refresh_party_cheer_coupon_button(coupon_btn)
	coupon_btn.pressed.connect(Callable(self, "_on_idle_dialog_coupon_pressed").bind(coupon_btn))
	vbox.add_child(coupon_btn)

	if has_rewards:
		var claim_btn := Button.new()
		claim_btn.text = UiText.HOME_CLAIM_REWARDS
		claim_btn.custom_minimum_size = Vector2(200.0, 52.0)
		RedDotService.refresh_dot(claim_btn, _has_idle_claim_red_dot())
		claim_btn.pressed.connect(Callable(self, "_on_idle_claim_pressed").bind(claim_btn, close_ref))
		vbox.add_child(claim_btn)

	close_ref[0] = DialogManager.show_info_node(UiText.HOME_IDLE_DIALOG_TITLE, vbox)


func _on_nav_config() -> void:
	_close_home_more_menu()
	_toggle_overlay_scene("res://scenes/LineupScene.tscn")


func _open_settings_scene() -> void:
	_close_home_more_menu()
	call_deferred("_toggle_overlay_scene", "res://scenes/ConfigScene.tscn")


func _on_nav_enhance() -> void:
	_close_home_more_menu()
	_toggle_overlay_scene("res://scenes/EnhanceScene.tscn")


func _on_nav_activity() -> void:
	_close_home_more_menu()
	_toggle_overlay_scene("res://scenes/ActivityScene.tscn")


func _on_nav_shop() -> void:
	_close_home_more_menu()
	_toggle_overlay_scene("res://scenes/ShopScene.tscn")


func _on_nav_backpack() -> void:
	_close_home_more_menu()
	_toggle_overlay_scene("res://scenes/BackpackScene.tscn")


func _on_nav_mail() -> void:
	_close_home_more_menu()
	_toggle_overlay_scene(MAIL_SCENE_PATH)


func _on_nav_announcements() -> void:
	_close_home_more_menu()
	ApiClient.get_announcements(Callable(self, "_on_announcements_loaded"))


func _on_nav_daily_tasks() -> void:
	_close_home_more_menu()
	ApiClient.get_daily_tasks(Callable(self, "_on_daily_tasks_loaded"))


func _on_announcements_loaded(ok: bool, data: Variant, err: Dictionary) -> void:
	if ok and data is Array:
		GameState.update_announcements(data as Array)
		_show_announcements_dialog()
		return

	if not GameState.announcement_catalog.is_empty():
		ToastManager.error(UiText.HOME_ANNOUNCEMENTS_TITLE, str(err.get("message", UiText.HOME_ANNOUNCEMENTS_LOAD_FAILED)))
		_show_announcements_dialog()
		return

	ToastManager.error(UiText.HOME_ANNOUNCEMENTS_TITLE, str(err.get("message", UiText.HOME_ANNOUNCEMENTS_LOAD_FAILED)))


func _on_daily_tasks_loaded(ok: bool, data: Variant, err: Dictionary) -> void:
	if ok and data is Dictionary:
		_show_daily_tasks_dialog(data as Dictionary)
		return
	ToastManager.error(UiText.HOME_DAILY_TASKS_TITLE, str(err.get("message", UiText.HOME_DAILY_TASKS_LOAD_FAILED)))


func _show_daily_tasks_dialog(data: Dictionary) -> void:
	var tasks: Array = data.get("tasks", []) if data.get("tasks", []) is Array else []
	if tasks.is_empty():
		DialogManager.show_info(UiText.HOME_DAILY_TASKS_TITLE, UiText.HOME_DAILY_TASKS_EMPTY, Callable(), "medium")
		return

	var root: VBoxContainer = VBoxContainer.new()
	root.custom_minimum_size = Vector2(650.0, 760.0)
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var header: HBoxContainer = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(header)

	var title: Label = Label.new()
	title.text = UiText.HOME_DAILY_TASKS_TITLE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1.0))
	header.add_child(title)

	var reset_label: Label = Label.new()
	reset_label.text = "%s\n%s" % [
		UiText.HOME_DAILY_TASKS_RESET_FORMAT % int(data.get("resetHour", 0)),
		UiText.HOME_DAILY_TASKS_COUNTDOWN_FORMAT % _format_daily_task_reset_countdown(int(data.get("remainingSecondsUntilReset", 0)))
	]
	reset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reset_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	reset_label.add_theme_color_override("font_color", Color(0.82, 0.74, 0.62, 1.0))
	header.add_child(reset_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var close_ref: Array = [Callable()]
	for task_variant: Variant in tasks:
		if task_variant is Dictionary:
			list.add_child(_build_daily_task_card(task_variant as Dictionary, close_ref))

	close_ref[0] = DialogManager.show_info_node(UiText.HOME_DAILY_TASKS_TITLE, root, Callable(), "xlarge")


func _build_daily_task_card(task: Dictionary, close_ref: Array) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.12, 0.09, 0.96)
	style.border_color = Color(0.76, 0.58, 0.30, 0.78)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.add_theme_constant_override("separation", 4)
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)

	var task_title: Label = Label.new()
	task_title.text = str(task.get("title", "")).strip_edges()
	task_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	task_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1.0))
	text_box.add_child(task_title)

	var progress: Label = Label.new()
	progress.text = "%s  %s" % [
		UiText.HOME_DAILY_TASKS_IN_PROGRESS_FORMAT % [int(task.get("progressCount", 0)), int(task.get("requiredCount", 1))],
		_format_daily_task_rewards(task.get("rewards", []))
	]
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	progress.add_theme_color_override("font_color", Color(0.92, 0.86, 0.76, 1.0))
	text_box.add_child(progress)

	var claim_button: Button = Button.new()
	claim_button.custom_minimum_size = Vector2(108.0, 44.0)
	var is_completed: bool = bool(task.get("isCompleted", false))
	var is_claimed: bool = bool(task.get("isClaimed", false))
	claim_button.text = UiText.HOME_DAILY_TASKS_CLAIMED if is_claimed else UiText.HOME_DAILY_TASKS_CLAIM
	claim_button.disabled = not is_completed or is_claimed
	UiPalette.apply_button_kind(claim_button, "confirm" if is_completed and not is_claimed else "neutral")
	claim_button.pressed.connect(Callable(self, "_on_daily_task_claim_pressed").bind(str(task.get("taskKey", "")), claim_button, close_ref))
	row.add_child(claim_button)
	return panel


func _format_daily_task_rewards(rewards_variant: Variant) -> String:
	if not (rewards_variant is Array):
		return ""
	var parts: Array[String] = []
	for reward_variant: Variant in rewards_variant:
		if not (reward_variant is Dictionary):
			continue
		var reward: Dictionary = reward_variant
		var display_name: String = str(reward.get("displayName", "")).strip_edges()
		var quantity: int = int(reward.get("quantity", 0))
		if display_name.is_empty() or quantity <= 0:
			continue
		parts.append("%s x%s" % [display_name, GameState.format_number(quantity)])
	return " / ".join(parts)


func _format_daily_task_reset_countdown(remaining_seconds: int) -> String:
	var remaining: int = max(0, remaining_seconds)
	var hours: int = floori(float(remaining) / 3600.0)
	var minutes: int = floori(float(remaining % 3600) / 60.0)
	var seconds: int = remaining % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


func _on_daily_task_claim_pressed(task_key: String, claim_button: Button, close_ref: Array) -> void:
	if task_key.strip_edges().is_empty():
		return
	claim_button.disabled = true
	ApiClient.claim_daily_task(task_key, Callable(self, "_on_daily_task_claim_completed").bind(close_ref))


func _on_daily_task_claim_completed(ok: bool, data: Variant, err: Dictionary, close_ref: Array) -> void:
	if not ok or not (data is Dictionary):
		ToastManager.error(UiText.HOME_DAILY_TASKS_TITLE, str(err.get("message", UiText.HOME_DAILY_TASKS_CLAIM_FAILED)))
		return
	var response: Dictionary = data
	var wallet_snapshot: Variant = response.get("walletSnapshot", {})
	if wallet_snapshot is Dictionary:
		GameState.apply_wallet_snapshot(wallet_snapshot as Dictionary)
	var close_callable: Callable = close_ref[0] if close_ref.size() > 0 and close_ref[0] is Callable else Callable()
	if close_callable.is_valid():
		close_callable.call()
	var overview: Variant = response.get("overview", {})
	if overview is Dictionary:
		_show_daily_tasks_dialog(overview as Dictionary)


func _show_announcements_dialog() -> void:
	var announcements: Array = GameState.announcement_catalog
	if announcements.is_empty():
		DialogManager.show_info(UiText.HOME_ANNOUNCEMENTS_TITLE, UiText.HOME_ANNOUNCEMENTS_EMPTY, Callable(), "medium")
		return

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640.0, 720.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for item_variant: Variant in announcements:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		list.add_child(_build_announcement_card(item))

	if list.get_child_count() == 0:
		var empty_label: Label = _make_label(UiText.HOME_ANNOUNCEMENTS_EMPTY, Vector2.ZERO, Vector2(620.0, 40.0), UiPalette.FONT_SIZE_BODY)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(empty_label)

	DialogManager.show_info_node(UiText.HOME_ANNOUNCEMENTS_TITLE, scroll, Callable(), "xlarge")


func _build_announcement_card(item: Dictionary) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.12, 0.09, 0.96)
	style.border_color = Color(0.76, 0.58, 0.30, 0.78)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)

	var title: Label = Label.new()
	title.text = str(item.get("title", "")).strip_edges()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1.0))
	stack.add_child(title)

	var meta_parts: Array[String] = []
	var category: String = str(item.get("category", "")).strip_edges()
	if category.is_empty():
		category = UiText.HOME_ANNOUNCEMENTS_CATEGORY_UPDATE
	meta_parts.append(category)
	var starts_at: String = _format_announcement_date(str(item.get("startsAtUtc", "")).strip_edges())
	if not starts_at.is_empty():
		meta_parts.append(starts_at)
	var meta: Label = Label.new()
	meta.text = " / ".join(meta_parts)
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	meta.add_theme_color_override("font_color", Color(0.80, 0.72, 0.62, 1.0))
	stack.add_child(meta)

	var summary: String = str(item.get("summary", "")).strip_edges()
	if not summary.is_empty():
		var summary_label: Label = Label.new()
		summary_label.text = summary
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		summary_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.78, 1.0))
		stack.add_child(summary_label)

	var content: Label = Label.new()
	content.text = str(item.get("content", "")).strip_edges()
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	content.add_theme_color_override("font_color", Color(0.94, 0.90, 0.84, 1.0))
	stack.add_child(content)

	return panel


func _format_announcement_date(value: String) -> String:
	if value.is_empty():
		return ""
	var normalized: String = value.replace("Z", "")
	var parts: PackedStringArray = normalized.split("T")
	if parts.size() == 0:
		return value
	return parts[0]


func _open_chat() -> void:
	_close_home_more_menu()
	_toggle_overlay_scene(CHAT_SCENE_PATH)


func _on_stats_btn_pressed() -> void:
	_close_home_more_menu()
	var stats_view: Control = load("res://scenes/StatsScene.tscn").instantiate()
	if stats_view.has_method("set_close_action"):
		var close_dialog := [Callable()]
		stats_view.set_close_action(Callable(self, "_close_overlay_dialog_ref").bind(close_dialog))
		close_dialog[0] = DialogManager.show_info_node(UiText.STATS_PANEL_TITLE, stats_view, Callable(), "xlarge")
	else:
		DialogManager.show_info_node(UiText.STATS_PANEL_TITLE, stats_view, Callable(), "xlarge")


func _on_home_coupon_completed(ok: bool, data: Variant, err: Dictionary) -> void:
	if not ok:
		if _home_scoop_result_label != null:
			_home_scoop_result_label.text = str(err.get("message", UiText.HOME_PARTY_COUPON_ERROR))
			_home_scoop_result_label.visible = true
		_refresh_home_scoop_panel()
		return

	var result: Dictionary = data if data is Dictionary else {}
	var wallet_snapshot: Variant = result.get("walletSnapshot", {})
	if wallet_snapshot is Dictionary:
		GameState.apply_wallet_snapshot(wallet_snapshot)
	var remaining_coupon_count: int = GameState.get_party_cheer_coupon_count()
	if remaining_coupon_count > 0:
		_start_party_cheer_coupon_cooldown(_home_coupon_button)
	else:
		_refresh_party_cheer_coupon_button(_home_coupon_button)
	if _home_scoop_result_label != null:
		_home_scoop_result_label.text = ""
		_home_scoop_result_label.visible = false
	var reward_entries: Array[Dictionary] = _build_idle_reward_float_entries(result.get("rewards", {}))
	if not reward_entries.is_empty():
		_queue_reward_floats(reward_entries)
	_refresh_home_scoop_panel()
	_refresh_ui()


func _on_pending_scooper_profile_fetched(profile_ok: bool, profile_data: Variant, _profile_err: Dictionary) -> void:
	_home_scoop_profile_fetch_in_flight = false
	if profile_ok and profile_data is Dictionary:
		_home_scoop_pending_profile = (profile_data as Dictionary).duplicate(true)
	_try_finalize_home_scoop_resolution()


func _on_home_scoop_silent_completed(ok: bool, data: Variant, err: Dictionary) -> void:
	if not ok:
		_home_scoop_request_in_flight = false
		_home_scoop_response_ready = false
		_home_scoop_profile_fetch_in_flight = false
		_home_scoop_pending_profile.clear()
		_home_scoop_pending_result.clear()
		_home_scoop_pending_reward_entries.clear()
		_home_scoop_cooldown_remaining = 0.0
		_home_scoop_animation_active = false
		_home_scoop_animation_elapsed = 0.0
		_set_home_scoop_frame(0)
		if _home_auto_scoop_enabled:
			_set_home_auto_scoop_enabled(false)
		if _home_scoop_result_label != null:
			_home_scoop_result_label.text = str(err.get("message", UiText.HOME_SCOOPER_ERROR))
			_home_scoop_result_label.visible = true
		_refresh_home_scoop_panel()
		return

	var result: Dictionary = data if data is Dictionary else {}
	_home_scoop_pending_result = result.duplicate(true)
	var updated_profile: Variant = result.get("updatedProfile", {})
	if updated_profile is Dictionary and not (updated_profile as Dictionary).is_empty():
		_home_scoop_pending_profile = (updated_profile as Dictionary).duplicate(true)
		_home_scoop_response_ready = true
		_try_finalize_home_scoop_resolution()
		return

	_home_scoop_response_ready = true
	_try_finalize_home_scoop_resolution()


func _on_idle_dialog_coupon_pressed(coupon_btn: Button) -> void:
	if coupon_btn == null or not is_instance_valid(coupon_btn) or coupon_btn.disabled:
		return
	coupon_btn.disabled = true
	ApiClient.use_party_cheer_coupon(Callable(self, "_on_idle_dialog_coupon_completed").bind(coupon_btn))


func _on_idle_dialog_coupon_completed(ok: bool, data: Variant, err: Dictionary, coupon_btn: Button) -> void:
	if coupon_btn == null or not is_instance_valid(coupon_btn):
		return
	if not ok:
		_refresh_party_cheer_coupon_button(coupon_btn)
		ToastManager.error(UiText.SOCIAL_PARTY_USE_COUPON, str(err.get("message", UiText.HOME_PARTY_COUPON_ERROR)))
		return

	var result: Dictionary = data if data is Dictionary else {}
	var wallet_snapshot: Variant = result.get("walletSnapshot", {})
	if wallet_snapshot is Dictionary:
		GameState.apply_wallet_snapshot(wallet_snapshot)
	var remaining_coupon_count: int = GameState.get_party_cheer_coupon_count()
	if remaining_coupon_count > 0:
		_start_party_cheer_coupon_cooldown(coupon_btn)
	else:
		_refresh_party_cheer_coupon_button(coupon_btn)
	var reward_entries: Array[Dictionary] = _build_idle_reward_float_entries(result.get("rewards", {}))
	if not reward_entries.is_empty():
		_queue_reward_floats(reward_entries)
	_refresh_ui()


func _on_idle_claim_pressed(claim_btn: Button, close_ref: Array) -> void:
	if claim_btn == null or not is_instance_valid(claim_btn):
		return
	claim_btn.disabled = true
	ApiClient.claim_idle_rewards(Callable(self, "_on_idle_claim_completed").bind(claim_btn, close_ref))


func _on_idle_claim_completed(ok: bool, data: Variant, err: Dictionary, claim_btn: Button, close_ref: Array) -> void:
	if claim_btn != null and is_instance_valid(claim_btn):
		claim_btn.disabled = false
	if not ok:
		ToastManager.error(UiText.HOME_CLAIM_FAILED_TITLE, str(err.get("message", UiText.HOME_CLAIM_FAILED_MESSAGE)))
		return

	var response: Dictionary = data if data is Dictionary else {}
	GameState.apply_idle_claim_response(response)
	_close_overlay_dialog_ref(close_ref)
	_refresh_ui()

	var claimed: Dictionary = response.get("rewards", {})
	var reward_entries: Array[Dictionary] = []
	for entry: Array in _get_home_reward_defs():
		var val: int = int(claimed.get(entry[1], 0))
		if val > 0:
			reward_entries.append(_make_reward_float_entry(entry[0], val, entry[1]))

	if not reward_entries.is_empty():
		_queue_reward_floats(reward_entries)


func _on_idle_scoop_pressed(scoop_btn_ref: WeakRef, result_lbl_ref: WeakRef, poop_count_lbl_ref: WeakRef) -> void:
	var scoop_btn_obj: Object = scoop_btn_ref.get_ref() if scoop_btn_ref != null else null
	var result_lbl_obj: Object = result_lbl_ref.get_ref() if result_lbl_ref != null else null
	if not (scoop_btn_obj is Button):
		return
	var scoop_btn: Button = scoop_btn_obj as Button
	if scoop_btn.disabled:
		return
	scoop_btn.disabled = true
	if result_lbl_obj is Label:
		(result_lbl_obj as Label).text = ""
	ApiClient.scoop_poop(1, Callable(self, "_on_idle_scoop_completed").bind(scoop_btn_ref, result_lbl_ref, poop_count_lbl_ref))


func _on_idle_scoop_completed(
	ok: bool,
	data: Variant,
	err: Dictionary,
	scoop_btn_ref: WeakRef,
	result_lbl_ref: WeakRef,
	poop_count_lbl_ref: WeakRef
) -> void:
	var scoop_btn_obj: Object = scoop_btn_ref.get_ref() if scoop_btn_ref != null else null
	var result_lbl_obj: Object = result_lbl_ref.get_ref() if result_lbl_ref != null else null
	var poop_count_lbl_obj: Object = poop_count_lbl_ref.get_ref() if poop_count_lbl_ref != null else null
	var scoop_btn: Button = scoop_btn_obj as Button if scoop_btn_obj is Button else null
	var result_lbl: Label = result_lbl_obj as Label if result_lbl_obj is Label else null
	var poop_count_lbl: Label = poop_count_lbl_obj as Label if poop_count_lbl_obj is Label else null
	if not ok:
		if result_lbl != null:
			result_lbl.text = str(err.get("message", UiText.HOME_SANDBOX_CLEAN_FAILED))
		if scoop_btn != null:
			scoop_btn.disabled = GameState.player_data.poop_count <= 0
		return

	var result: Dictionary = data if data is Dictionary else {}
	var updated_profile: Variant = result.get("updatedProfile", {})
	if updated_profile is Dictionary:
		GameState.update_scooper_profile(updated_profile)

	var remaining: int = GameState.player_data.poop_count
	if poop_count_lbl != null:
		poop_count_lbl.text = UiText.HOME_SANDBOX_PENDING_POOP % remaining
	var parts: Array[String] = []
	var reward_entries: Array[Dictionary] = []

	var exp_gained: int = int(result.get("expGained", 0))
	if exp_gained > 0:
		parts.append("EXP +%d" % exp_gained)
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_EXP, exp_gained, "exp"))

	var memory_shards_gained: int = int(result.get("memoryShardsGained", 0))
	if memory_shards_gained > 0:
		parts.append("%s +%d" % [UiText.REWARD_MEMORY_SHARDS, memory_shards_gained])
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_MEMORY_SHARDS, memory_shards_gained, "memory_shards"))

	var whiskers_gained: int = int(result.get("WhiskersGained", result.get("whiskersGained", 0)))
	if whiskers_gained > 0:
		parts.append("%s +%d" % [UiText.REWARD_WHISKERS, whiskers_gained])
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_WHISKERS, whiskers_gained, "whiskers"))

	if result_lbl != null:
		result_lbl.text = UiText.HOME_SANDBOX_NONE_EXTRA if parts.is_empty() else UiText.HOME_SANDBOX_GAINED_PREFIX + " / ".join(parts)
	if not reward_entries.is_empty():
		_queue_reward_floats(reward_entries)

	if scoop_btn != null:
		scoop_btn.disabled = remaining <= 0
	_refresh_ui()


func _close_overlay_dialog_ref(close_ref: Array) -> void:
	if close_ref.is_empty():
		return
	var close_callable: Callable = close_ref[0]
	if close_callable.is_valid():
		close_callable.call()


func _on_player_profile_changed() -> void:
	_refresh_ui()


func _on_player_wallet_changed() -> void:
	_refresh_ui()


func _on_combat_trial_score_changed() -> void:
	_refresh_ui()


func _show_pending_combat_power_change() -> void:
	var pending: Dictionary = GameState.consume_pending_combat_power_change()
	if pending.is_empty():
		return
	PowerChangeAnimator.show_power_change(
		int(pending.get("previousScore", 0)),
		int(pending.get("currentScore", 0))
	)


func _on_red_dot_state_changed() -> void:
	_refresh_home_red_dots()


func _on_chat_unread_changed(_channel_key: String, _count: int) -> void:
	_refresh_chat_badge()
	_refresh_home_red_dots()


func _on_party_cheer_coupon_count_changed(_count: int) -> void:
	_refresh_home_scoop_panel()
	_refresh_sandbox_btn()


func _open_friend() -> void:
	_toggle_overlay_scene(FRIEND_SCENE_PATH)


func _open_party() -> void:
	_toggle_overlay_scene(PARTY_SCENE_PATH)


func _refresh_chat_badge() -> void:
	if _chat_badge == null:
		return
	_refresh_home_more_badge_positions()
	var unread := GameState.get_chat_total_unread()
	_chat_badge.visible = _home_more_menu_expanded and unread > 0
	_chat_badge.text = str(min(unread, 99))
