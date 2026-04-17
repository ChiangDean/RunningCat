class_name BattleScene
extends Node2D

## Main home scene: battle view plus bottom navigation.

const BATTLE_BG_TEXTURE := preload("res://assets/sprites/ui/battle_background_homey_v1.png")
const HOME_TOP_HUD_SCENE := preload("res://scenes/ui/HomeTopHudEditor.tscn")
const HOME_TOP_BAR_TEXTURE := preload("res://assets/sprites/ui/home/v2/home_hud_main_v2.png")
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
const CHAT_SCENE := preload("res://scenes/chat/ChatScene.tscn")
const SOCIAL_SCENE := preload("res://scenes/social/SocialScene.tscn")

const SW := 720.0
const SH := 1280.0
const BATTLE_Y := 750.0
const NAV_H := 110.0
const NAV_Y := SH - NAV_H

# Skill bar baseline positioned just below BATTLE_Y.
const SKILL_BAR_Y := BATTLE_Y + 10.0
const SKILL_BAR_H := 126.0
const SKILL_SLOT_W := 132.0
const SKILL_SLOT_H := 126.0

# Stage and boss actions stay aligned with the result banner.
const STAGE_BTN_Y := 310.0
const TOP_BAR_FRAME_X := 26.0
const TOP_BAR_FRAME_Y := 28.0
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
const HOME_SCOOP_PANEL_H := 112.0
const HOME_SCOOP_COOLDOWN := 0.5
const PARTY_COUPON_DISPLAY_CAP := 5
const RESULT_BANNER_W := 296.0
const RESULT_BANNER_H := 84.0
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
var _skill_filter_btn: Button
var _speed_1x: Button
var _speed_2x: Button
var _speed_3x: Button
var _skip_btn: Button
var _level_label: Label
var _boss_btn: Button
var _result_display: Label
var _result_backdrop: Control
var _result_glow: Label
var _result_shadow_label: Label
var _result_streak_left: ColorRect
var _result_streak_right: ColorRect
var _skill_panel: Control
var _skill_shadow: ColorRect
var _skill_body: ColorRect
var _skill_inner: ColorRect
var _skill_top_glow: ColorRect
var _skill_header_rule: ColorRect
var _skill_bar: Control      # Skill bar container
var _sandbox_btn: Button     # Idle rewards action button
var _mail_btn: Button
var _mail_badge: Label

var _friend_btn: Button
var _party_btn: Button
var _chat_btn: Button
var _chat_badge: Label
var _resource_value_labels: Dictionary = {}
var _stage_task_label: Label
var _battle_countdown_fill: ColorRect
var _profile_name_label: Label
var _profile_level_label: Label
var _top_area_label: Label
var _top_exp_bar: ProgressBar
var _top_progress_value_label: Label
var _top_poop_value_label: Label
var _top_heart_labels: Array[Label] = []
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
var _home_scoop_button: Button
var _home_scoop_result_label: Label
var _home_scoop_overlay: ColorRect
var _home_scoop_cd_label: Label
var _home_scoop_cooldown_remaining: float = 0.0
var _nav_buttons: Dictionary = {}
var _nav_canvas: CanvasLayer
var _last_overlay_scene_path: String = ""
var _skill_filter_mode: String = "player"
var _current_speed_mult: float = 1.0
var _free_speed_boost_end_unix: int = 0
var _free_speed_boost_mult: float = 1.0
var _free_speed_boost_used: bool = false


func _ready() -> void:
	add_to_group("battle_scene")
	_build_scene()
	_start_battle()
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

	_refresh_speed_boost_state()

	var overlay_scene_path: String = SceneNavigator.get_current_overlay_scene_path()
	if overlay_scene_path != _last_overlay_scene_path:
		_last_overlay_scene_path = overlay_scene_path
		_refresh_main_nav_state()
		_refresh_overlay_fx_state()


# Scene construction

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
	_top_avatar_rect.texture = PROFILE_AVATAR_TEXTURE
	var avatar_circle_material := ShaderMaterial.new()
	avatar_circle_material.shader = Shader.new()
	avatar_circle_material.shader.code = "shader_type canvas_item;\nvoid fragment(){\n\tvec2 uv = UV - vec2(0.5);\n\tif (length(uv) > 0.5) {\n\t\tdiscard;\n\t}\n\tCOLOR = texture(TEXTURE, UV) * COLOR;\n}\n"
	_top_avatar_rect.material = avatar_circle_material
	_profile_name_label = top_bar_root.get_node("NameLabel") as Label
	_profile_level_label = top_bar_root.get_node("LevelLabel") as Label
	_top_exp_bar = top_bar_root.get_node("TopExpBar") as ProgressBar
	_top_progress_value_label = top_bar_root.get_node("ExpValueLabel") as Label
	_resource_value_labels["diamonds"] = top_bar_root.get_node("DiamondsPanel/Value") as Label
	_resource_value_labels["gold"] = top_bar_root.get_node("GoldPanel/Value") as Label
	_resource_value_labels["power"] = top_bar_root.get_node("PowerPanel/Value") as Label
	var stage_panel := _make_panel(
		Vector2(188.0, 244.0),
		Vector2(344.0, 104.0),
		Color(0.12, 0.08, 0.06, 0.72),
		Color(0.66, 0.53, 0.31, 0.92)
	)
	_ui_layer.add_child(stage_panel)

	_stage_task_label = _make_label(UiText.HOME_DAILY_TASK, Vector2(18.0, 10.0), Vector2(308.0, 18.0), 11)
	_stage_task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_task_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.63, 0.86))
	stage_panel.add_child(_stage_task_label)

	_level_label = _make_label("", Vector2(18.0, 28.0), Vector2(308.0, 28.0), 25)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(_level_label)

	_timer_label = _make_label("60.0", Vector2(18.0, 54.0), Vector2(308.0, 20.0), 18)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_panel.add_child(_timer_label)

	var countdown_bar_bg := ColorRect.new()
	countdown_bar_bg.position = Vector2(28.0, 80.0)
	countdown_bar_bg.size = Vector2(288.0, 8.0)
	countdown_bar_bg.color = Color(0.20, 0.14, 0.10, 0.92)
	stage_panel.add_child(countdown_bar_bg)

	_battle_countdown_fill = ColorRect.new()
	_battle_countdown_fill.position = Vector2(1.0, 1.0)
	_battle_countdown_fill.size = Vector2(286.0, 6.0)
	_battle_countdown_fill.color = Color(0.97, 0.78, 0.28, 0.96)
	countdown_bar_bg.add_child(_battle_countdown_fill)

	_mail_btn = _make_button(UiText.HOME_MAIL, Vector2(ACTION_STACK_X, ACTION_STACK_Y), Vector2(ACTION_STACK_W, ACTION_STACK_H))
	_ui_layer.add_child(_mail_btn)
	_mail_btn.pressed.connect(_on_nav_mail)

	_mail_badge = Label.new()
	_mail_badge.position = _mail_btn.position + Vector2(ACTION_STACK_W - 20.0, -6.0)
	_mail_badge.size = Vector2(28.0, 28.0)
	_mail_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mail_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mail_badge.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_mail_badge.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_ui_layer.add_child(_mail_badge)

	_friend_btn = _make_button(UiText.HOME_FRIEND, Vector2(ACTION_STACK_X, ACTION_STACK_Y + ACTION_STACK_H + 10.0), Vector2(ACTION_STACK_W, ACTION_STACK_H))
	_friend_btn.pressed.connect(_open_friend)
	_ui_layer.add_child(_friend_btn)

	_party_btn = _make_button(UiText.HOME_PARTY, Vector2(ACTION_STACK_X, ACTION_STACK_Y + (ACTION_STACK_H + 10.0) * 2.0), Vector2(ACTION_STACK_W, ACTION_STACK_H))
	_party_btn.pressed.connect(_open_party)
	_ui_layer.add_child(_party_btn)

	_chat_btn = _make_button(UiText.HOME_CHAT, Vector2(ACTION_STACK_X, ACTION_STACK_Y + (ACTION_STACK_H + 10.0) * 3.0), Vector2(ACTION_STACK_W, ACTION_STACK_H))
	_chat_btn.pressed.connect(_open_chat)
	_ui_layer.add_child(_chat_btn)

	_chat_badge = _make_label("", _chat_btn.position + Vector2(ACTION_STACK_W - 22.0, -4.0), Vector2(22.0, 18.0), 12)
	_chat_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ui_layer.add_child(_chat_badge)
	GameState.chat_unread_changed.connect(func(_channel_key: String, _count: int) -> void:
		_refresh_chat_badge()
	)
	GameState.party_cheer_coupon_count_changed.connect(func(_count: int) -> void:
		_refresh_home_scoop_panel()
	)
	_refresh_chat_badge()

	_boss_btn = _make_button(UiText.HOME_BOSS, Vector2(252.0, 350.0), Vector2(216.0, 42.0))
	_boss_btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	_boss_btn.visible = false
	_ui_layer.add_child(_boss_btn)
	_boss_btn.pressed.connect(_on_challenge_boss_pressed)

	_skill_panel = Control.new()
	_skill_panel.position = Vector2(SKILL_PANEL_X, SKILL_PANEL_Y)
	_skill_panel.size = Vector2(SKILL_PANEL_W, SKILL_PANEL_H)
	_ui_layer.add_child(_skill_panel)

	_skill_shadow = ColorRect.new()
	_skill_shadow.position = Vector2(0.0, 6.0)
	_skill_shadow.size = _skill_panel.size
	_skill_shadow.color = Color(0.03, 0.02, 0.02, 0.28)
	_skill_panel.add_child(_skill_shadow)

	_skill_body = ColorRect.new()
	_skill_body.position = Vector2.ZERO
	_skill_body.size = _skill_panel.size
	_skill_body.color = Color(0.13, 0.09, 0.07, 0.88)
	_skill_panel.add_child(_skill_body)

	_skill_inner = ColorRect.new()
	_skill_inner.position = Vector2(2.0, 2.0)
	_skill_inner.size = _skill_panel.size - Vector2(4.0, 4.0)
	_skill_inner.color = Color(0.20, 0.14, 0.10, 0.82)
	_skill_panel.add_child(_skill_inner)

	_skill_top_glow = ColorRect.new()
	_skill_top_glow.position = Vector2(SKILL_PANEL_CONTENT_PAD, 6.0)
	_skill_top_glow.size = Vector2(_skill_panel.size.x - SKILL_PANEL_CONTENT_PAD * 2.0, 12.0)
	_skill_top_glow.color = Color(1.0, 0.92, 0.78, 0.0)
	_skill_panel.add_child(_skill_top_glow)

	_skill_header_rule = ColorRect.new()
	_skill_header_rule.position = Vector2(SKILL_PANEL_CONTENT_PAD, 34.0)
	_skill_header_rule.size = Vector2(_skill_panel.size.x - SKILL_PANEL_CONTENT_PAD * 2.0, 2.0)
	_skill_header_rule.color = Color(0.84, 0.66, 0.34, 0.26)
	_skill_panel.add_child(_skill_header_rule)

	_skill_filter_btn = _make_button("切換(我方)", Vector2(SKILL_PANEL_CONTENT_PAD, -16.0), Vector2(104.0, 26.0))
	_skill_panel.add_child(_skill_filter_btn)
	_apply_skill_filter_button_style(_skill_filter_btn, true)
	_skill_filter_btn.pressed.connect(_cycle_skill_filter_mode)

	_skill_bar = _build_skill_bar()
	_skill_panel.add_child(_skill_bar)
	_apply_skill_bar_layout()

	_speed_1x = _make_button("加速", Vector2(_skill_panel.size.x - SKILL_PANEL_CONTENT_PAD - 128.0, -16.0), Vector2(128.0, 26.0))
	_skill_panel.add_child(_speed_1x)
	_apply_skill_speed_button_style(_speed_1x, false)
	_speed_2x = null
	_speed_3x = null
	_speed_1x.pressed.connect(_cycle_speed)
	_apply_speed_unlocks()
	_highlight_speed_btn(_speed_1x)
	_highlight_skill_filter_btn()

	_sandbox_btn = _make_button("Idle 00:00:00", Vector2(0.0, -16.0), Vector2(224.0, 26.0))
	_sandbox_btn.add_theme_font_size_override("font_size", 14)
	_sandbox_btn.pressed.connect(_show_sandbox_dialog)
	_skill_panel.add_child(_sandbox_btn)
	_layout_sandbox_btn()

	_home_scoop_panel = Control.new()
	_home_scoop_panel.position = Vector2(HOME_SCOOP_PANEL_X, HOME_SCOOP_PANEL_Y)
	_home_scoop_panel.size = Vector2(HOME_SCOOP_PANEL_W, HOME_SCOOP_PANEL_H)
	_ui_layer.add_child(_home_scoop_panel)

	_home_exp_label = null
	_home_exp_bar = null

	_home_scoop_result_label = _make_label("", Vector2(18.0, 32.0), Vector2(176.0, 24.0), 11)
	_home_scoop_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_home_scoop_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_home_scoop_result_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_scoop_result_label.add_theme_color_override("font_color", Color(0.84, 0.98, 0.80, 1.0))
	_home_scoop_panel.add_child(_home_scoop_result_label)

	_home_coupon_button = null

	_home_scoop_button = Button.new()
	_home_scoop_button.text = UiText.HOME_SCOOPER_BUTTON
	_home_scoop_button.position = Vector2(242.0, 36.0)
	_home_scoop_button.size = Vector2(154.0, 26.0)
	_home_scoop_button.add_theme_font_size_override("font_size", 15)
	_home_scoop_button.modulate = Color(0.97, 0.93, 0.88, 1.0)
	_home_scoop_button.pressed.connect(UiAudio.play_ui_click)
	_home_scoop_button.pressed.connect(_on_home_scoop_pressed)
	_home_scoop_panel.add_child(_home_scoop_button)

	_home_scoop_overlay = ColorRect.new()
	_home_scoop_overlay.color = Color(0.0, 0.0, 0.0, 0.42)
	_home_scoop_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_scoop_overlay.visible = false
	_home_scoop_button.add_child(_home_scoop_overlay)

	_home_scoop_cd_label = Label.new()
	_home_scoop_cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_scoop_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_home_scoop_cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_home_scoop_cd_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	_home_scoop_cd_label.visible = false
	_home_scoop_button.add_child(_home_scoop_cd_label)

	_skip_btn = _make_button("Skip", Vector2(SW - 104.0, 76.0), Vector2(90.0, 34.0))
	_ui_layer.add_child(_skip_btn)
	_skip_btn.pressed.connect(_on_skip_pressed)
	_skip_btn.visible = GameState.is_admin_session()

	_result_backdrop = Control.new()
	_result_backdrop.position = Vector2((SW - RESULT_BANNER_W) / 2.0, 356.0)
	_result_backdrop.size = Vector2(RESULT_BANNER_W, RESULT_BANNER_H)
	_result_backdrop.visible = false
	_ui_layer.add_child(_result_backdrop)

	_result_streak_left = ColorRect.new()
	_result_streak_left.position = Vector2(20.0, 38.0)
	_result_streak_left.size = Vector2(116.0, 9.0)
	_result_streak_left.color = Color(1.0, 1.0, 1.0, 0.0)
	_result_streak_left.rotation_degrees = -18.0
	_result_backdrop.add_child(_result_streak_left)

	_result_streak_right = ColorRect.new()
	_result_streak_right.position = Vector2(RESULT_BANNER_W - 136.0, 38.0)
	_result_streak_right.size = Vector2(116.0, 9.0)
	_result_streak_right.color = Color(1.0, 1.0, 1.0, 0.0)
	_result_streak_right.rotation_degrees = 18.0
	_result_backdrop.add_child(_result_streak_right)

	_result_glow = Label.new()
	_result_glow.size = Vector2(RESULT_BANNER_W, RESULT_BANNER_H)
	_result_glow.position = Vector2.ZERO
	_result_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_glow.add_theme_font_size_override("font_size", 78)
	_result_glow.add_theme_constant_override("outline_size", 18)
	_result_glow.visible = false
	_result_backdrop.add_child(_result_glow)

	_result_shadow_label = Label.new()
	_result_shadow_label.size = Vector2(RESULT_BANNER_W, RESULT_BANNER_H)
	_result_shadow_label.position = Vector2(6.0, 8.0)
	_result_shadow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_shadow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_shadow_label.add_theme_font_size_override("font_size", 62)
	_result_shadow_label.add_theme_constant_override("outline_size", 10)
	_result_shadow_label.visible = false
	_result_backdrop.add_child(_result_shadow_label)

	_result_display = Label.new()
	_result_display.size = Vector2(RESULT_BANNER_W, RESULT_BANNER_H)
	_result_display.position = Vector2.ZERO
	_result_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_display.add_theme_font_size_override("font_size", 66)
	_result_display.add_theme_constant_override("outline_size", 10)
	_result_display.add_theme_color_override("font_outline_color", Color(0.20, 0.09, 0.04, 0.98))
	_result_display.visible = false
	_result_backdrop.add_child(_result_display)

	_nav_canvas = CanvasLayer.new()
	_nav_canvas.layer = 20
	add_child(_nav_canvas)

	var nav_bg: Control = _make_panel(
		Vector2(0.0, NAV_Y),
		Vector2(SW, NAV_H),
		Color(0.11, 0.08, 0.06, 0.94),
		Color(0.52, 0.40, 0.24, 1.0)
	)
	_nav_canvas.add_child(nav_bg)

	var nav_items: Array = [
		[UiText.NAV_SCOOPER, "res://scenes/ScooperScene.tscn", _on_nav_scooper],
		[UiText.NAV_CONFIG, "res://scenes/ConfigScene.tscn", _on_nav_config],
		[UiText.NAV_ENHANCE, "res://scenes/EnhanceScene.tscn", _on_nav_enhance],
		[UiText.NAV_ACTIVITY, "res://scenes/ActivityScene.tscn", _on_nav_activity],
		[UiText.NAV_SHOP, "res://scenes/ShopScene.tscn", _on_nav_shop],
		[UiText.NAV_BACKPACK, "res://scenes/BackpackScene.tscn", _on_nav_backpack],
	]
	var btn_w := SW / nav_items.size()
	for i in range(nav_items.size()):
		var nav_btn: Button = _make_button(
			nav_items[i][0],
			Vector2(i * btn_w + 8.0, NAV_Y + 12.0),
			Vector2(btn_w - 16.0, NAV_H - 24.0)
		)
		nav_btn.pressed.connect(nav_items[i][2])
		nav_btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
		_nav_canvas.add_child(nav_btn)
		_nav_buttons[String(nav_items[i][1])] = nav_btn

	_refresh_main_nav_state()
	_layout_home_scoop_panel()

	_reward_fx_canvas = CanvasLayer.new()
	_reward_fx_canvas.layer = 99
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
	bar.position = Vector2(SKILL_PANEL_CONTENT_PAD, 48.0)
	bar.size = Vector2(SKILL_PANEL_W - SKILL_PANEL_CONTENT_PAD * 2.0, SKILL_BAR_H)

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
	var is_all_mode: bool = _skill_filter_mode == "all"
	_skill_panel.size.y = SKILL_PANEL_ALL_H if is_all_mode else SKILL_PANEL_H
	if _skill_shadow != null:
		_skill_shadow.size = _skill_panel.size
	if _skill_body != null:
		_skill_body.size = _skill_panel.size
	if _skill_inner != null:
		_skill_inner.size = _skill_panel.size - Vector2(4.0, 4.0)
	if _skill_top_glow != null:
		_skill_top_glow.position.x = SKILL_PANEL_CONTENT_PAD
		_skill_top_glow.size.x = _skill_panel.size.x - SKILL_PANEL_CONTENT_PAD * 2.0
	if _skill_header_rule != null:
		_skill_header_rule.position.x = SKILL_PANEL_CONTENT_PAD
		_skill_header_rule.size.x = _skill_panel.size.x - SKILL_PANEL_CONTENT_PAD * 2.0
	if _speed_1x != null:
		_speed_1x.position.x = _skill_panel.size.x - SKILL_PANEL_CONTENT_PAD - _speed_1x.size.x
	_layout_sandbox_btn()
	if _sandbox_btn != null:
		_sandbox_btn.visible = true
	if _home_scoop_panel != null:
		_home_scoop_panel.visible = not is_all_mode
	if _skip_btn != null:
		_skip_btn.visible = GameState.is_admin_session()
	_skill_bar.position.x = SKILL_PANEL_CONTENT_PAD
	_skill_bar.size.x = _skill_panel.size.x - SKILL_PANEL_CONTENT_PAD * 2.0
	var row_gap: float = 24.0
	var content_w: float = _skill_bar.size.x - SKILL_BAR_EDGE_PAD * 2.0
	var horizontal_gap: float = (content_w - SKILL_SLOT_W * MAX_CATS_ON_FIELD) / float(MAX_CATS_ON_FIELD - 1)
	var slot_count: int = MAX_CATS_ON_FIELD * 2
	if is_all_mode:
		_skill_bar.position = Vector2(SKILL_PANEL_CONTENT_PAD, 48.0)
		_skill_bar.size = Vector2(_skill_bar.size.x, SKILL_SLOT_H * 2.0 + row_gap)
		for i in range(slot_count):
			var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
			if slot_node == null:
				continue
			var col: int = i % MAX_CATS_ON_FIELD
			var row: int = i / MAX_CATS_ON_FIELD
			slot_node.scale = Vector2.ONE
			slot_node.position = Vector2(SKILL_BAR_EDGE_PAD + col * (SKILL_SLOT_W + horizontal_gap), row * (SKILL_SLOT_H + row_gap))
			slot_node.visible = true
	else:
		_skill_bar.position = Vector2(SKILL_PANEL_CONTENT_PAD, 48.0)
		_skill_bar.size = Vector2(_skill_bar.size.x, SKILL_BAR_H)
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
	var bg_color: Color = ENHANCE_DETAIL_TAB_ACTIVE_FILL if is_active else ENHANCE_APPLY_DISABLED_BG
	var fg_color: Color = ENHANCE_DETAIL_TAB_ACTIVE_FG if is_active else ENHANCE_APPLY_DISABLED_FG
	UiPalette.apply_button_palette(button, bg_color, fg_color)
	button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _layout_sandbox_btn() -> void:
	if _sandbox_btn == null or _speed_1x == null:
		return
	_sandbox_btn.position = Vector2(
		_speed_1x.position.x - _sandbox_btn.size.x - 8.0,
		_speed_1x.position.y
	)


func _highlight_skill_filter_btn() -> void:
	if _skill_filter_btn == null:
		return
	_skill_filter_btn.text = _get_skill_filter_button_label()
	_apply_skill_filter_button_style(_skill_filter_btn, true)


func _set_skill_filter_mode(mode: String) -> void:
	_skill_filter_mode = mode
	_apply_skill_bar_layout()
	_highlight_skill_filter_btn()
	if _battle_manager != null:
		_battle_manager.set_skill_bar_filter(mode)


func _cycle_skill_filter_mode() -> void:
	var next_mode: String = "player"
	if _skill_filter_mode == "player":
		next_mode = "enemy"
	elif _skill_filter_mode == "enemy":
		next_mode = "all"
	_set_skill_filter_mode(next_mode)


func _get_skill_filter_button_label() -> String:
	match _skill_filter_mode:
		"enemy":
			return "切換(敵方)"
		"all":
			return "切換(全部)"
		_:
			return "切換(我方)"


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


func _apply_skill_speed_button_style(button: Button, is_active: bool) -> void:
	if button == null:
		return
	var show_enabled_style: bool = is_active or not button.disabled
	var bg_color: Color = UiPalette.BUTTON_PRIMARY_BG if show_enabled_style else ENHANCE_APPLY_DISABLED_BG
	var fg_color: Color = UiPalette.BUTTON_PRIMARY_FG if show_enabled_style else ENHANCE_APPLY_DISABLED_FG
	UiPalette.apply_button_palette(button, bg_color, fg_color)
	button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
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
	var negative := value < 0
	var digits := str(abs(value))
	var parts: Array[String] = []
	while digits.length() > 3:
		parts.push_front(digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	parts.push_front(digits)
	var joined := ",".join(parts)
	return "-" + joined if negative else joined


func _refresh_resource_strip() -> void:
	if _resource_value_labels.is_empty():
		return
	if _resource_value_labels.has("diamonds"):
		_resource_value_labels["diamonds"].text = _format_resource_count(GameState.player_data.diamonds)
	if _resource_value_labels.has("gold"):
		_resource_value_labels["gold"].text = _format_resource_count(GameState.player_data.gold)
	if _resource_value_labels.has("power"):
		_resource_value_labels["power"].text = _format_resource_count(_cached_team_power)


func _get_home_reward_defs() -> Array[Array]:
	return [
		[UiText.REWARD_GOLD, "gold"],
		[UiText.REWARD_POOP, "poop"],
		[UiText.REWARD_CAT_FOOD, "cat_food"],
		[UiText.REWARD_DIAMONDS, "diamonds"],
		[UiText.REWARD_WHISKERS, "whiskers"],
	]


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
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


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
		_speed_1x.text = "%s加速中 %s" % [_format_speed_label(_free_speed_boost_mult), _format_countdown_time(remaining_seconds)]
		_speed_1x.disabled = true
	elif _free_speed_boost_used:
		_speed_1x.text = "已加速"
		_speed_1x.disabled = true
	else:
		_speed_1x.text = "加速"
		_speed_1x.disabled = false
	_highlight_speed_btn(_speed_1x if _is_free_speed_boost_active() else null)
	_apply_skill_speed_button_style(_speed_1x, _is_free_speed_boost_active() or not _speed_1x.disabled)


func _format_countdown_time(total_seconds: int) -> String:
	var clamped_seconds: int = maxi(total_seconds, 0)
	var minutes: int = clamped_seconds / 60
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
	if _stage_task_label != null:
		_stage_task_label.text = UiText.HOME_DAILY_TASK
	if _profile_name_label != null:
		var profile_name := GameState.player_data.display_name.strip_edges()
		if profile_name.is_empty():
			profile_name = GameState.player_data.player_name.strip_edges()
		if profile_name.is_empty():
			profile_name = "Scooper"
		_profile_name_label.text = profile_name
	if _profile_level_label != null:
		_profile_level_label.text = str(GameState.player_data.scooper_level)
	if _top_exp_bar != null and _top_progress_value_label != null:
		var top_profile: Dictionary = GameState.scooper_profile_data
		var top_level: int
		var top_exp: int
		var top_threshold: int
		if not top_profile.is_empty():
			top_level = int(top_profile.get("scooperLevel", GameState.player_data.scooper_level))
			top_exp = int(top_profile.get("scooperExp", GameState.player_data.scooper_exp))
			top_threshold = int(top_profile.get("expThreshold", max((top_level + 1) * 10, 1)))
		else:
			top_level = GameState.player_data.scooper_level
			top_exp = GameState.player_data.scooper_exp
			top_threshold = max((top_level + 1) * int(GameState.idle_config.get("scooper_exp_per_level", 10)), 1)
		_top_exp_bar.max_value = top_threshold
		_top_exp_bar.value = top_exp
		_top_progress_value_label.text = "EXP %d/%d" % [top_exp, top_threshold]
	_boss_btn.visible = GameState.boss_available and not GameState.is_current_boss()
	_refresh_resource_strip()
	_refresh_sandbox_btn()
	_refresh_home_scoop_panel()
	_refresh_mail_badge()


func _refresh_sandbox_btn() -> void:
	if _sandbox_btn == null:
		return
	var elapsed := GameState.get_idle_elapsed_seconds()
	var claimable_minutes := elapsed / 60
	if claimable_minutes < 1:
		_sandbox_btn.disabled = true
		_sandbox_btn.text = UiText.HOME_IDLE_NOT_READY
		UiPalette.apply_button_palette(_sandbox_btn, ENHANCE_APPLY_DISABLED_BG, ENHANCE_APPLY_DISABLED_FG)
	else:
		_sandbox_btn.disabled = false
		var h := elapsed / 3600
		var m := (elapsed % 3600) / 60
		var s := elapsed % 60
		_sandbox_btn.text = "%s %02d:%02d:%02d" % [UiText.HOME_IDLE_READY, h, m, s]
		UiPalette.apply_button_kind(_sandbox_btn, "primary")


func _refresh_home_scoop_panel() -> void:
	if _home_scoop_button == null:
		return
	_layout_home_scoop_panel()

	var profile: Dictionary = GameState.scooper_profile_data
	var level: int
	var exp: int
	var threshold: int
	if not profile.is_empty():
		level = int(profile.get("scooperLevel", GameState.player_data.scooper_level))
		exp = int(profile.get("scooperExp", GameState.player_data.scooper_exp))
		threshold = int(profile.get("expThreshold", max((level + 1) * 10, 1)))
	else:
		level = GameState.player_data.scooper_level
		exp = GameState.player_data.scooper_exp
		threshold = max((level + 1) * int(GameState.idle_config.get("scooper_exp_per_level", 10)), 1)

	if _home_exp_bar != null:
		_home_exp_bar.max_value = threshold
		_home_exp_bar.value = exp
	if _home_exp_label != null:
		_home_exp_label.text = "Lv.%d  EXP %d / %d" % [level, exp, threshold]

	var poop_count := GameState.player_data.poop_count
	var cooling_down := _home_scoop_cooldown_remaining > 0.0
	_home_scoop_button.disabled = cooling_down or poop_count <= 0
	_home_scoop_button.text = "%s (%d)" % [UiText.HOME_SCOOPER_BUTTON, poop_count]
	if poop_count <= 0 and _home_scoop_result_label != null and _home_scoop_result_label.text.is_empty():
		_home_scoop_result_label.text = UiText.HOME_SCOOPER_EMPTY

	if _home_scoop_overlay != null and _home_scoop_cd_label != null:
		if cooling_down:
			var button_size := _home_scoop_button.size
			var ratio := clampf(_home_scoop_cooldown_remaining / HOME_SCOOP_COOLDOWN, 0.0, 1.0)
			_home_scoop_overlay.visible = true
			_home_scoop_overlay.position = Vector2(button_size.x * (1.0 - ratio), 0.0)
			_home_scoop_overlay.size = Vector2(button_size.x * ratio, button_size.y)
			_home_scoop_cd_label.visible = false
			_home_scoop_cd_label.position = Vector2.ZERO
			_home_scoop_cd_label.size = button_size
			_home_scoop_cd_label.text = "%.1f" % _home_scoop_cooldown_remaining
		else:
			_home_scoop_overlay.visible = false
			_home_scoop_cd_label.visible = false


func _layout_home_scoop_panel() -> void:
	if _home_scoop_panel == null or _home_scoop_button == null:
		return
	var enhance_btn_variant: Variant = _nav_buttons.get("res://scenes/EnhanceScene.tscn")
	var enhance_btn: Button = enhance_btn_variant as Button
	if enhance_btn == null:
		return
	var target_center_x: float = enhance_btn.position.x + enhance_btn.size.x * 0.5
	var target_button_x: float = target_center_x - (_home_scoop_button.position.x + _home_scoop_button.size.x * 0.5)
	var target_button_y: float = enhance_btn.position.y - 50.0 - _home_scoop_button.size.y
	_home_scoop_panel.position = Vector2(
		target_button_x,
		target_button_y - _home_scoop_button.position.y
	)


func _refresh_main_nav_state() -> void:
	var active_scene_path: String = SceneNavigator.get_current_overlay_scene_path()
	for scene_path: String in _nav_buttons.keys():
		var btn: Button = _nav_buttons[scene_path]
		if btn == null:
			continue
		var is_active: bool = scene_path == active_scene_path
		btn.modulate = Color(1.0, 0.93, 0.76, 1.0) if is_active else Color(0.97, 0.93, 0.88, 1.0)
		btn.add_theme_font_size_override("font_size", 30 if is_active else 28)


func get_damage_fx_host() -> Node2D:
	return _damage_fx_layer if _damage_fx_layer != null else self


func _refresh_overlay_fx_state() -> void:
	var overlay_open: bool = not SceneNavigator.get_current_overlay_scene_path().is_empty()
	if _damage_fx_layer != null:
		if overlay_open:
			for child: Node in _damage_fx_layer.get_children():
				child.queue_free()
		_damage_fx_layer.visible = not overlay_open


func _refresh_mail_badge() -> void:
	if _mail_badge == null:
		return
	if not GameState.has_mail_red_dot():
		_mail_badge.visible = false
		return
	_mail_badge.visible = true
	_mail_badge.text = GameState.get_mail_badge_text()
	_mail_badge.modulate = Color(1.0, 0.28, 0.28, 1.0)


# Battle flow

func _start_battle() -> void:
	_result_display.visible = false
	if _result_glow != null:
		_result_glow.visible = false
	if _result_shadow_label != null:
		_result_shadow_label.visible = false
	if _result_streak_left != null:
		_result_streak_left.color = Color(_result_streak_left.color.r, _result_streak_left.color.g, _result_streak_left.color.b, 0.0)
	if _result_streak_right != null:
		_result_streak_right.color = Color(_result_streak_right.color.r, _result_streak_right.color.g, _result_streak_right.color.b, 0.0)
	if _result_backdrop != null:
		_result_backdrop.visible = false
	_refresh_ui()

	for child in _player_team.get_children():
		child.queue_free()
	for child in _enemy_team.get_children():
		child.queue_free()

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

	var simulator := BattleSimulator.new()
	var events := simulator.simulate(player_cats, enemy_cats)
	_battle_manager.setup(events, player_cats, enemy_cats,
			_player_team, _enemy_team, _timer_label, _skill_bar)
	_set_skill_filter_mode(_skill_filter_mode)


func restart_with_latest_team() -> void:
	GameState.apply_active_team_from_config("Boss")
	_start_battle()


func _on_skip_pressed() -> void:
	_battle_manager.skip_to_end()


func _on_battle_finished(result: String) -> void:
	_last_result = result
	var is_boss := GameState.is_current_boss()

	if result == "WIN":
		_show_result_text(UiText.BATTLE_RESULT_WIN, Color(0.46, 0.98, 0.48, 1.0), 356.0)
		GameState.advance_after_win()
		await get_tree().create_timer(1.0).timeout
		_start_battle()
	else:
		_show_result_text(UiText.BATTLE_RESULT_LOSE, Color(1.0, 0.42, 0.38, 1.0), 356.0)
		if is_boss:
			GameState.on_boss_fail()
		await get_tree().create_timer(1.0).timeout
		_start_battle()


func _show_result_text(text: String, color: Color, y: float) -> void:
	if _result_backdrop != null:
		_result_backdrop.position = Vector2((SW - RESULT_BANNER_W) / 2.0, y + 26.0)
		_result_backdrop.visible = true
	_result_backdrop.scale = Vector2(0.54, 0.54)
	_result_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_result_backdrop.rotation_degrees = -9.0 if text == UiText.BATTLE_RESULT_WIN else 9.0

	var accent_color: Color = color
	var glow_color: Color = color.lerp(Color(1.0, 0.98, 0.90, 1.0), 0.62)
	var streak_color: Color = color.lerp(Color(1.0, 0.95, 0.80, 1.0), 0.50)
	var shadow_color: Color = Color(0.12, 0.05, 0.03, 0.92)

	if _result_glow != null:
		_result_glow.text = text
		_result_glow.position = Vector2(0.0, -3.0)
		_result_glow.scale = Vector2(1.42, 1.42)
		_result_glow.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_result_glow.add_theme_color_override("font_color", glow_color)
		_result_glow.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.92))
		_result_glow.visible = true

	if _result_shadow_label != null:
		_result_shadow_label.text = text
		_result_shadow_label.position = Vector2(10.0, 20.0)
		_result_shadow_label.scale = Vector2(1.10, 1.10)
		_result_shadow_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_result_shadow_label.add_theme_color_override("font_color", shadow_color)
		_result_shadow_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.01, 0.95))
		_result_shadow_label.visible = true

	_result_display.text = text
	_result_display.position = Vector2(0.0, -4.0)
	_result_display.scale = Vector2(0.60, 0.60)
	_result_display.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_result_display.add_theme_color_override("font_color", accent_color)
	_result_display.add_theme_color_override("font_outline_color", Color(0.20, 0.09, 0.04, 0.98))
	_result_display.visible = true

	if _result_streak_left != null:
		_result_streak_left.color = Color(streak_color.r, streak_color.g, streak_color.b, 0.0)
		_result_streak_left.scale = Vector2(0.12, 1.0)
		_result_streak_left.position = Vector2(42.0, 40.0)
	if _result_streak_right != null:
		_result_streak_right.color = Color(streak_color.r, streak_color.g, streak_color.b, 0.0)
		_result_streak_right.scale = Vector2(0.12, 1.0)
		_result_streak_right.position = Vector2(RESULT_BANNER_W - 158.0, 40.0)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_result_backdrop, "modulate:a", 1.0, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_backdrop, "position:y", y, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_backdrop, "scale", Vector2(1.18, 1.18), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_backdrop, "rotation_degrees", 0.0, 0.20).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_display, "modulate:a", 1.0, 0.05).set_delay(0.02).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_display, "scale", Vector2(1.28, 1.28), 0.12).set_delay(0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_shadow_label, "modulate:a", 0.82, 0.07).set_delay(0.01).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_shadow_label, "position:y", 10.0, 0.16).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_glow, "modulate:a", 1.0, 0.06).set_delay(0.00).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_property(_result_glow, "scale", Vector2(1.06, 1.06), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _result_streak_left != null:
		tween.tween_property(_result_streak_left, "color:a", 0.98, 0.04).set_delay(0.03).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		tween.tween_property(_result_streak_left, "scale:x", 1.0, 0.12).set_delay(0.03).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if _result_streak_right != null:
		tween.tween_property(_result_streak_right, "color:a", 0.98, 0.04).set_delay(0.03).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		tween.tween_property(_result_streak_right, "scale:x", 1.0, 0.12).set_delay(0.03).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_result_backdrop, "scale", Vector2(0.98, 0.98), 0.10).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_result_display, "scale", Vector2(0.96, 0.96), 0.09).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_result_glow, "modulate:a", 0.56, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_result_backdrop, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_result_display, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if _result_streak_left != null:
		tween.parallel().tween_property(_result_streak_left, "color:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if _result_streak_right != null:
		tween.parallel().tween_property(_result_streak_right, "color:a", 0.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_challenge_boss_pressed() -> void:
	GameState.challenge_boss()
	_start_battle()


# Navigation

## Apply scooper-related combat bonuses to the cat data.
func _apply_equipment_bonuses(data: CatData) -> void:
	GameState.apply_player_combat_bonuses(data)


func _on_nav_scooper() -> void:
	_toggle_overlay_scene("res://scenes/ScooperScene.tscn")


func _toggle_overlay_scene(scene_path: String) -> void:
	SceneNavigator.toggle_overlay_scene(scene_path)


func _on_home_scoop_pressed() -> void:
	if _home_scoop_cooldown_remaining > 0.0 or GameState.player_data.poop_count <= 0:
		return

	_home_scoop_button.disabled = true
	_home_scoop_result_label.text = ""
	ApiClient.scoop_poop(1, func(ok: bool, data: Variant, err: Dictionary) -> void:
		if not ok:
			_home_scoop_result_label.text = str(err.get("message", UiText.HOME_SCOOPER_ERROR))
			_refresh_home_scoop_panel()
			return

		var result: Dictionary = data if data is Dictionary else {}
		var updated_profile: Variant = result.get("updatedProfile", {})
		if updated_profile is Dictionary:
			GameState.update_scooper_profile(updated_profile)

		var reward_entries := _build_scoop_reward_entries(result)
		_home_scoop_result_label.text = ""
		_home_scoop_cooldown_remaining = HOME_SCOOP_COOLDOWN
		if not reward_entries.is_empty():
			_queue_reward_floats(reward_entries)
		_refresh_ui()
	)


func _on_home_coupon_pressed() -> void:
	if _home_coupon_button == null or _home_coupon_button.disabled:
		return

	_home_coupon_button.disabled = true
	ApiClient.use_party_cheer_coupon(func(ok: bool, data: Variant, err: Dictionary) -> void:
		if not ok:
			_home_scoop_result_label.text = str(err.get("message", UiText.HOME_PARTY_COUPON_ERROR))
			_refresh_home_scoop_panel()
			return

		GameState.adjust_party_cheer_coupon_count(-1)
		var result: Dictionary = data if data is Dictionary else {}
		_home_scoop_result_label.text = UiText.HOME_PARTY_COUPON_SUCCESS % int(result.get("goldGranted", 0))
		_refresh_ui()
	)


func _build_scoop_reward_entries(result: Dictionary) -> Array[Dictionary]:
	var reward_entries: Array[Dictionary] = []
	var exp_gained := int(result.get("expGained", 0))
	if exp_gained > 0:
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_EXP, exp_gained, "exp"))

	var memory_shards_gained := int(result.get("memoryShardsGained", 0))
	if memory_shards_gained > 0:
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_MEMORY_SHARDS, memory_shards_gained, "memory_shards"))

	var whiskers_gained := int(result.get("WhiskersGained", result.get("whiskersGained", 0)))
	if whiskers_gained > 0:
		reward_entries.append(_make_reward_float_entry(UiText.REWARD_WHISKERS, whiskers_gained, "whiskers"))

	return reward_entries


func _format_scoop_result_text(result: Dictionary) -> String:
	var parts: Array[String] = []
	var exp_gained := int(result.get("expGained", 0))
	if exp_gained > 0:
		parts.append("%s +%d" % [UiText.REWARD_EXP, exp_gained])

	var memory_shards_gained := int(result.get("memoryShardsGained", 0))
	if memory_shards_gained > 0:
		parts.append("%s +%d" % [UiText.REWARD_MEMORY_SHARDS, memory_shards_gained])

	var whiskers_gained := int(result.get("WhiskersGained", result.get("whiskersGained", 0)))
	if whiskers_gained > 0:
		parts.append("%s +%d" % [UiText.REWARD_WHISKERS, whiskers_gained])

	if parts.is_empty():
		return UiText.HOME_SANDBOX_NONE_EXTRA
	return UiText.HOME_SCOOPER_RESULT_PREFIX + " / ".join(parts)


## Show the idle rewards and cleanup dialog.
func _show_sandbox_dialog() -> void:
	var elapsed_seconds := GameState.get_idle_elapsed_seconds()
	var complete_minutes := elapsed_seconds / 60
	var has_rewards := complete_minutes >= 1
	var rewards := GameState.get_pending_idle_rewards() if has_rewards else {}

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(400.0, 0.0)

	# Idle rewards section
	var rewards_section := VBoxContainer.new()
	rewards_section.add_theme_constant_override("separation", 6)

	if has_rewards:
		var h := complete_minutes / 60
		var m := complete_minutes % 60
		var time_lbl := Label.new()
		time_lbl.text = UiText.HOME_SANDBOX_TIME_FORMAT % [h, m]
		time_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		time_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rewards_section.add_child(time_lbl)

		for entry: Array in _get_home_reward_defs():
			var val: int = int(rewards.get(entry[1], 0))
			if val > 0:
				var lbl := Label.new()
				lbl.text = "%s +%d" % [entry[0], val]
				lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
				rewards_section.add_child(lbl)

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
	scoop_btn.pressed.connect(func() -> void:
		if scoop_btn.disabled:
			return
		scoop_btn.disabled = true
		result_lbl.text = ""
		ApiClient.scoop_poop(1, func(ok: bool, data: Variant, err: Dictionary) -> void:
			if not ok:
				result_lbl.text = str(err.get("message", UiText.HOME_SANDBOX_CLEAN_FAILED))
				scoop_btn.disabled = GameState.player_data.poop_count <= 0
				return

			var result: Dictionary = data if data is Dictionary else {}
			var updated_profile: Variant = result.get("updatedProfile", {})
			if updated_profile is Dictionary:
				GameState.update_scooper_profile(updated_profile)

			var remaining := GameState.player_data.poop_count
			poop_count_lbl.text = UiText.HOME_SANDBOX_PENDING_POOP % remaining
			var parts: Array[String] = []
			var reward_entries: Array[Dictionary] = []

			var exp_gained := int(result.get("expGained", 0))
			if exp_gained > 0:
				parts.append("EXP +%d" % exp_gained)
				reward_entries.append(_make_reward_float_entry(UiText.REWARD_EXP, exp_gained, "exp"))

			var memory_shards_gained := int(result.get("memoryShardsGained", 0))
			if memory_shards_gained > 0:
				parts.append("%s +%d" % [UiText.REWARD_MEMORY_SHARDS, memory_shards_gained])
				reward_entries.append(_make_reward_float_entry(UiText.REWARD_MEMORY_SHARDS, memory_shards_gained, "memory_shards"))

			var whiskers_gained := int(result.get("WhiskersGained", result.get("whiskersGained", 0)))
			if whiskers_gained > 0:
				parts.append("%s +%d" % [UiText.REWARD_WHISKERS, whiskers_gained])
				reward_entries.append(_make_reward_float_entry(UiText.REWARD_WHISKERS, whiskers_gained, "whiskers"))

			result_lbl.text = UiText.HOME_SANDBOX_NONE_EXTRA if parts.is_empty() else UiText.HOME_SANDBOX_GAINED_PREFIX + " / ".join(parts)
			if not reward_entries.is_empty():
				_queue_reward_floats(reward_entries)

			scoop_btn.disabled = remaining <= 0
			_refresh_ui()
		)
	)
	scoop_section.add_child(scoop_btn)
	if false:
		vbox.add_child(scoop_section)

	# Claim rewards action
	var close_ref := [Callable()]
	var coupon_btn: Button = Button.new()
	coupon_btn.text = UiText.HOME_PARTY_COUPON_BUTTON_FORMAT % [
		mini(GameState.get_party_cheer_coupon_count(), PARTY_COUPON_DISPLAY_CAP),
		PARTY_COUPON_DISPLAY_CAP
	]
	coupon_btn.custom_minimum_size = Vector2(200.0, 46.0)
	coupon_btn.disabled = GameState.get_party_cheer_coupon_count() <= 0
	coupon_btn.pressed.connect(func() -> void:
		if coupon_btn.disabled:
			return
		coupon_btn.disabled = true
		ApiClient.use_party_cheer_coupon(func(ok: bool, data: Variant, err: Dictionary) -> void:
			if not ok:
				coupon_btn.disabled = GameState.get_party_cheer_coupon_count() <= 0
				ToastManager.error(UiText.SOCIAL_PARTY_USE_COUPON, str(err.get("message", UiText.HOME_PARTY_COUPON_ERROR)))
				return

			GameState.adjust_party_cheer_coupon_count(-1)
			var result: Dictionary = data if data is Dictionary else {}
			var coupon_count: int = GameState.get_party_cheer_coupon_count()
			coupon_btn.text = UiText.HOME_PARTY_COUPON_BUTTON_FORMAT % [
				mini(coupon_count, PARTY_COUPON_DISPLAY_CAP),
				PARTY_COUPON_DISPLAY_CAP
			]
			coupon_btn.disabled = coupon_count <= 0
			ToastManager.success(UiText.SOCIAL_PARTY_USE_COUPON, UiText.HOME_PARTY_COUPON_SUCCESS % int(result.get("goldGranted", 0)))
			_refresh_ui()
		)
	)
	vbox.add_child(coupon_btn)

	if has_rewards:
		var claim_btn := Button.new()
		claim_btn.text = UiText.HOME_CLAIM_REWARDS
		claim_btn.custom_minimum_size = Vector2(200.0, 52.0)
		claim_btn.pressed.connect(func() -> void:
			claim_btn.disabled = true
			ApiClient.claim_idle_rewards(func(ok: bool, data: Variant, err: Dictionary) -> void:
				claim_btn.disabled = false
				if not ok:
					ToastManager.error(UiText.HOME_CLAIM_FAILED_TITLE, str(err.get("message", UiText.HOME_CLAIM_FAILED_MESSAGE)))
					return

				var response: Dictionary = data if data is Dictionary else {}
				GameState.apply_idle_claim_response(response)
				close_ref[0].call()
				_refresh_ui()

				var claimed: Dictionary = response.get("rewards", {})
				var reward_entries: Array[Dictionary] = []
				for entry: Array in _get_home_reward_defs():
					var val: int = int(claimed.get(entry[1], 0))
					if val > 0:
						reward_entries.append(_make_reward_float_entry(entry[0], val, entry[1]))

				if not reward_entries.is_empty():
					_queue_reward_floats(reward_entries)
			)
		)
		vbox.add_child(claim_btn)

	close_ref[0] = DialogManager.show_info_node(UiText.HOME_IDLE_DIALOG_TITLE, vbox)


func _on_nav_config() -> void:
	_toggle_overlay_scene("res://scenes/ConfigScene.tscn")


func _on_nav_enhance() -> void:
	_toggle_overlay_scene("res://scenes/EnhanceScene.tscn")


func _on_nav_activity() -> void:
	_toggle_overlay_scene("res://scenes/ActivityScene.tscn")


func _on_nav_shop() -> void:
	_toggle_overlay_scene("res://scenes/ShopScene.tscn")


func _on_nav_backpack() -> void:
	_toggle_overlay_scene("res://scenes/BackpackScene.tscn")


func _on_nav_mail() -> void:
	var mail_view: Control = load("res://scenes/MailScene.tscn").instantiate()
	if mail_view.has_method("set_close_action"):
		var close_dialog := [Callable()]
		mail_view.set_close_action(func() -> void:
			if close_dialog[0].is_valid():
				close_dialog[0].call()
		)
		close_dialog[0] = DialogManager.show_info_node(UiText.HOME_MAIL_DIALOG_TITLE, mail_view, Callable(), "large")
	else:
		DialogManager.show_info_node(UiText.HOME_MAIL_DIALOG_TITLE, mail_view, Callable(), "large")

func _open_chat() -> void:
	var chat_view: Control = CHAT_SCENE.instantiate()
	DialogManager.show_info_node(UiText.HOME_CHAT_DIALOG_TITLE, chat_view, Callable(), "large")


func _open_friend() -> void:
	var social_view = SOCIAL_SCENE.instantiate()
	social_view.set_mode("friend")
	DialogManager.show_info_node(UiText.HOME_FRIEND_DIALOG_TITLE, social_view, Callable(), "large")


func _open_party() -> void:
	var social_view = SOCIAL_SCENE.instantiate()
	social_view.set_mode("party")
	DialogManager.show_info_node(UiText.HOME_PARTY_DIALOG_TITLE, social_view, Callable(), "large")


func _refresh_chat_badge() -> void:
	if _chat_badge == null:
		return
	var unread := GameState.get_chat_total_unread()
	_chat_badge.visible = unread > 0
	_chat_badge.text = str(min(unread, 99))
