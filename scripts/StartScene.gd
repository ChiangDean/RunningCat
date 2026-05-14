extends Control

const HERO_IMAGE_PATH := "res://assets/sprites/ui/start_scene_homey_v1.png"
const TITLE_TEXT := UiText.START_TITLE
const SUBTITLE_TEXT := UiText.START_SUBTITLE
const TAP_TO_START_TEXT := UiText.START_TAP_TO_START
const DEVICE_ID_PATH := "user://device_id.txt"
const DEFAULT_API_BASE_URL := "http://localhost:5000/api"
const REQUEST_TIMEOUT_SECONDS := 15.0
const BOOTSTRAP_MAX_RETRY_COUNT := 2
const BOOTSTRAP_RETRY_DELAY_SECONDS := 5.0
const BOOTSTRAP_PROGRESS_MAX_PERCENT := 96.0
const BOOTSTRAP_PROGRESS_DURATION_SECONDS := 36.0
const NGROK_SKIP_WARNING_HEADER := "ngrok-skip-browser-warning: true"
const REQUEST_KIND_AUTH := "auth"
const REQUEST_KIND_BOOTSTRAP := "bootstrap"
const REQUEST_KIND_REFRESH := "refresh"
const REQUEST_KIND_LOGOUT_REVOKE := "logout_revoke"
const REQUEST_KIND_LOGOUT_REFRESH := "logout_refresh"
const REQUEST_KIND_OAUTH_BEGIN := "oauth_begin"
const REQUEST_KIND_OAUTH_EXCHANGE := "oauth_exchange"
const REQUEST_KIND_OAUTH_COMPLETE_PROFILE := "oauth_complete_profile"
const REQUEST_KIND_GUEST_LOGIN := "guest_login"
const REQUEST_KIND_GUEST_REGISTER := "guest_register"
const OAUTH_POLL_INTERVAL_SECONDS := 1.5
const OAUTH_POLL_TIMEOUT_SECONDS := 90.0
const OAUTH_PROVIDER_GOOGLE := "google"
const OAUTH_PROVIDER_APPLE := "apple"
const OAUTH_PROVIDER_LINE := "line"
const DISABLED_OAUTH_PROVIDER_KEYS: Array[String] = [OAUTH_PROVIDER_APPLE]
const OAUTH_PROVIDER_NAME_GOOGLE := "Google"
const OAUTH_PROVIDER_NAME_APPLE := "Apple"
const OAUTH_PROVIDER_NAME_LINE := "LINE"
const OAUTH_GOOGLE_BUTTON_TEXTURE := preload("res://assets/sprites/ui/oauth/google/google_signin_neutral_square_220.png")
const OAUTH_APPLE_BUTTON_TEXTURE := preload("res://assets/sprites/ui/oauth/apple/apple_signin_left_black_220x50.png")
const OAUTH_LINE_BUTTON_TEXTURE := preload("res://assets/sprites/ui/oauth/line/line_login_base_220.png")
const OAUTH_LINE_BUTTON_HOVER_TEXTURE := preload("res://assets/sprites/ui/oauth/line/line_login_hover_220.png")
const OAUTH_LINE_BUTTON_PRESS_TEXTURE := preload("res://assets/sprites/ui/oauth/line/line_login_press_220.png")
const OAUTH_DIVIDER_TEXT := "or continue with"
const OAUTH_PROFILE_TITLE := "Set Your Player Name"
const OAUTH_PROFILE_HINT := "Choose the name other players will see."
const OAUTH_PROFILE_PRIMARY := "Start Adventure"
const OAUTH_PROFILE_SECONDARY := "Back"
const OAUTH_GOOGLE_BUTTON := "Google"
const OAUTH_APPLE_BUTTON := "Apple"
const OAUTH_LINE_BUTTON := "LINE"
const GUEST_ACCOUNT_PREFIX := "guest_"
const GUEST_PASSWORD_PREFIX := "guest:"
const GUEST_PASSWORD_SUFFIX := ":meow-party-dash"
const GUEST_DISPLAY_NAME_PREFIX := "遊客"
const OAUTH_OPENED_STATUS := "Browser opened. Finish authorization, then come back here."
const OAUTH_PENDING_STATUS := "Waiting for authorization to finish..."
const OAUTH_TIMEOUT_STATUS := "Authorization was not completed in time. Please try again."
const OAUTH_CANCELLED_STATUS := "Authorization was cancelled."
const OAUTH_CONFLICT_STATUS := "This provider already matches another account. Sign in to that account first, then link it from settings."
const OAUTH_PLAYER_NAME_REQUIRED := "Please enter a player name."
const OAUTH_BEGIN_FAILED_STATUS := "Unable to start external sign-in."
const OAUTH_COMPLETE_PROFILE_STATUS := "Creating your player profile..."
const AUTH_BLOCK_WIDTH := 440.0
const AUTH_BLOCK_HEIGHT_WITH_OAUTH := 584.0
const AUTH_BLOCK_HEIGHT_LOGIN_COMPACT := 388.0
const AUTH_BLOCK_HEIGHT_REGISTER_COMPACT := 456.0
const AUTH_BLOCK_HEIGHT_OAUTH_PROFILE := 286.0
const TITLE_CARD_DEFAULT_TOP := 307.2
const AUTH_BLOCK_DEFAULT_TOP := 806.4
const LOADING_BLOCK_DEFAULT_TOP := 1024.0
const TAP_HINT_DEFAULT_TOP := 1075.2
const AUTH_BLOCK_FOCUS_MIN_TOP := 120.0
const AUTH_BLOCK_FOCUS_BOTTOM_MARGIN := 24.0
const KEYBOARD_COMPACT_HEIGHT_THRESHOLD := 1120.0
enum AuthMode
{
	LOGIN,
	REGISTER,
	OAUTH_PROFILE
}

var _api_base_url := DEFAULT_API_BASE_URL
var _hero_image: Texture2D
var _device_id := ""
var _request_in_flight := false
var _request_kind := ""
var _input_ready := false
var _loading_track_fill_width := 0.0
var _http_request: HTTPRequest
var _mode: AuthMode = AuthMode.LOGIN

var _title_card: Control
var _auth_block: Control
var _loading_block: Control
var _loading_fill: ColorRect
var _loading_label: Label
var _loading_percent_label: Label
var _paw_row: HBoxContainer
var _tap_hint: Label
var _logout_button: Button

var _form_title: Label
var _display_name_input: LineEdit
var _account_input: LineEdit
var _password_input: LineEdit
var _confirm_password_input: LineEdit
var _primary_button: Button
var _secondary_button: Button
var _guest_button: Button
var _status_label: Label
var _audio_debug_overlay: PanelContainer
var _audio_debug_label: Label
var _oauth_intro_label: Label
var _oauth_button_row: VBoxContainer
var _oauth_google_button: TextureButton
var _oauth_apple_button: TextureButton
var _oauth_line_button: TextureButton
var _logout_revoke_retry := false
var _logout_dialog_open := false
var _loading_fill_tween: Tween
var _loading_percent_tween: Tween
var _loading_animation_finished := false
var _bootstrap_completed := false
var _cdn_warmup_completed := false
var _bootstrap_retry_count: int = 0
var _auth_request_mode: AuthMode = AuthMode.LOGIN
var _bootstrap_retry_timer: Timer
var _oauth_poll_timer: Timer
var _oauth_transaction_id := ""
var _oauth_provider_key := ""
var _oauth_provider_name := ""
var _oauth_poll_elapsed := 0.0
var _pending_retry_login_active := false
var _pending_retry_login_account: String = ""
var _pending_retry_login_password: String = ""
var _guest_account_exists_recovery_attempted := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiAudio.play_menu_bgm()
	_hero_image = load(HERO_IMAGE_PATH) as Texture2D
	var resolved_api_base_url: String = _resolve_api_base_url()
	_api_base_url = resolved_api_base_url
	_device_id = _load_or_create_device_id()
	_build_ui()
	_sync_adaptive_layout()
	get_viewport().size_changed.connect(_sync_adaptive_layout)
	_attach_http_request()
	_play_idle_animation()
	_apply_mode()
	if GameState.load_persisted_auth_session():
		if RuntimeConfig.has_explicit_api_base_url():
			_api_base_url = resolved_api_base_url
			if GameState.api_base_url != _api_base_url:
				GameState.set_auth_session(_api_base_url, GameState.auth_session)
		else:
			_api_base_url = GameState.api_base_url
		_sync_logout_button_visibility()
		_show_loading_state()
		_begin_authenticated_bootstrap(UiText.START_STATUS_BOOTSTRAP_RESTORE)


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = _hero_image
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	var top_overlay := ColorRect.new()
	top_overlay.anchor_right = 1.0
	top_overlay.anchor_bottom = 0.42
	top_overlay.color = Color(0.18, 0.15, 0.11, 0.16)
	add_child(top_overlay)

	var bottom_overlay := ColorRect.new()
	bottom_overlay.anchor_top = 0.58
	bottom_overlay.anchor_right = 1.0
	bottom_overlay.anchor_bottom = 1.0
	bottom_overlay.color = Color(0.18, 0.14, 0.10, 0.16)
	add_child(bottom_overlay)

	var layout := Control.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	_title_card = _build_title_block()
	layout.add_child(_title_card)

	_auth_block = _build_auth_block()
	layout.add_child(_auth_block)

	_loading_block = _build_loading_block()
	_loading_block.visible = false
	layout.add_child(_loading_block)

	_tap_hint = _build_tap_hint()
	_tap_hint.visible = false
	layout.add_child(_tap_hint)

	_logout_button = _build_logout_button()
	layout.add_child(_logout_button)
	_sync_logout_button_visibility()

	if _should_show_audio_debug_overlay():
		_audio_debug_overlay = _build_audio_debug_overlay()
		layout.add_child(_audio_debug_overlay)
		_refresh_audio_debug_overlay(UiAudio.get_debug_snapshot())
		if not UiAudio.debug_state_changed.is_connected(_refresh_audio_debug_overlay):
			UiAudio.debug_state_changed.connect(_refresh_audio_debug_overlay)


func _build_title_block() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.position = Vector2.ZERO
	panel.custom_minimum_size = Vector2(500, 156)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var ribbon := Label.new()
	ribbon.text = UiText.START_RIBBON
	ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_fredoka_semibold(ribbon, UiPalette.FONT_SIZE_BODY_LG)
	ribbon.add_theme_color_override("font_color", Color("f8f3ea"))
	ribbon.add_theme_stylebox_override("normal", _make_ribbon_stylebox())
	content.add_child(ribbon)

	var title := Label.new()
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(title, 46)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	title.add_theme_color_override("font_shadow_color", Color("fffdf9"))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = SUBTITLE_TEXT
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(subtitle, UiPalette.FONT_SIZE_TITLE)
	subtitle.add_theme_color_override("font_color", Color("6a5547"))
	content.add_child(subtitle)

	return panel


func _build_auth_block() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.position = Vector2.ZERO
	panel.custom_minimum_size = Vector2(AUTH_BLOCK_WIDTH, _get_auth_block_height())
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	_form_title = Label.new()
	_form_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(_form_title, UiPalette.FONT_SIZE_HEADING)
	_form_title.add_theme_color_override("font_color", Color("4f3d31"))
	content.add_child(_form_title)

	_display_name_input = _build_input(UiText.START_PLACEHOLDER_DISPLAY_NAME, false)
	content.add_child(_display_name_input)

	_account_input = _build_input(UiText.START_PLACEHOLDER_ACCOUNT, false)
	content.add_child(_account_input)

	_password_input = _build_input(UiText.START_PLACEHOLDER_PASSWORD, true)
	content.add_child(_password_input)

	_confirm_password_input = _build_input(UiText.START_PLACEHOLDER_CONFIRM_PASSWORD, true)
	content.add_child(_confirm_password_input)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	content.add_child(button_row)

	_primary_button = Button.new()
	_primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_primary_button.custom_minimum_size = Vector2(0, 54)
	UiFonts.apply_noto(_primary_button, UiPalette.FONT_SIZE_BODY_LG)
	_primary_button.add_theme_stylebox_override("normal", _make_button_stylebox(Color("9aae8b"), 10))
	_primary_button.add_theme_stylebox_override("hover", _make_button_stylebox(Color("a8bc98"), 10))
	_primary_button.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("869a79"), 8))
	_primary_button.pressed.connect(UiAudio.play_ui_click)
	_primary_button.pressed.connect(_on_primary_pressed)
	button_row.add_child(_primary_button)

	_secondary_button = Button.new()
	_secondary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secondary_button.custom_minimum_size = Vector2(0, 54)
	UiFonts.apply_noto(_secondary_button, UiPalette.FONT_SIZE_BODY_LG)
	_secondary_button.add_theme_stylebox_override("normal", _make_button_stylebox(Color("d4b593"), 10))
	_secondary_button.add_theme_stylebox_override("hover", _make_button_stylebox(Color("ddc19f"), 10))
	_secondary_button.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("c59f78"), 8))
	_secondary_button.pressed.connect(UiAudio.play_ui_click)
	_secondary_button.pressed.connect(_on_secondary_pressed)
	button_row.add_child(_secondary_button)

	_guest_button = Button.new()
	_guest_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guest_button.custom_minimum_size = Vector2(0, 50)
	_guest_button.text = UiText.START_BUTTON_GUEST_LOGIN
	UiFonts.apply_noto(_guest_button, UiPalette.FONT_SIZE_BODY_LG)
	_guest_button.add_theme_stylebox_override("normal", _make_button_stylebox(Color("88a9bb"), 10))
	_guest_button.add_theme_stylebox_override("hover", _make_button_stylebox(Color("96b6c7"), 10))
	_guest_button.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("7698aa"), 8))
	_guest_button.pressed.connect(UiAudio.play_ui_click)
	_guest_button.pressed.connect(_on_guest_pressed)
	content.add_child(_guest_button)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 42)
	UiFonts.apply_noto(_status_label, 15)
	_status_label.add_theme_color_override("font_color", Color("7d2f2f"))
	content.add_child(_status_label)

	if RuntimeConfig.is_oauth_enabled():
		_oauth_intro_label = Label.new()
		_oauth_intro_label.text = OAUTH_DIVIDER_TEXT
		_oauth_intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiFonts.apply_noto(_oauth_intro_label, 14)
		_oauth_intro_label.add_theme_color_override("font_color", Color("6a5547"))
		content.add_child(_oauth_intro_label)

		_oauth_button_row = VBoxContainer.new()
		_oauth_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_oauth_button_row.add_theme_constant_override("separation", 10)
		content.add_child(_oauth_button_row)

		_oauth_google_button = _build_oauth_button(OAUTH_GOOGLE_BUTTON_TEXTURE)
		_oauth_google_button.pressed.connect(UiAudio.play_ui_click)
		_oauth_google_button.pressed.connect(_on_oauth_google_pressed)
		_oauth_button_row.add_child(_oauth_google_button)

		_oauth_apple_button = _build_oauth_button(OAUTH_APPLE_BUTTON_TEXTURE)
		_oauth_apple_button.pressed.connect(UiAudio.play_ui_click)
		_oauth_apple_button.pressed.connect(_on_oauth_apple_pressed)
		_oauth_button_row.add_child(_oauth_apple_button)

		_oauth_line_button = _build_oauth_button(
			OAUTH_LINE_BUTTON_TEXTURE,
			OAUTH_LINE_BUTTON_HOVER_TEXTURE,
			OAUTH_LINE_BUTTON_PRESS_TEXTURE
		)
		_oauth_line_button.pressed.connect(UiAudio.play_ui_click)
		_oauth_line_button.pressed.connect(_on_oauth_line_pressed)
		_oauth_button_row.add_child(_oauth_line_button)

	return panel


func _build_loading_block() -> Control:
	var block := Control.new()
	block.anchor_left = 0.0
	block.anchor_top = 0.0
	block.anchor_right = 0.0
	block.anchor_bottom = 0.0
	block.position = Vector2.ZERO
	block.custom_minimum_size = Vector2(380, 82)

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", _make_card_stylebox())
	block.add_child(frame)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	frame.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	_loading_label = Label.new()
	_loading_label.text = UiText.START_LOADING_GATHERING
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(_loading_label, UiPalette.FONT_SIZE_SUBHEADING)
	_loading_label.add_theme_color_override("font_color", Color("5f4c3f"))
	content.add_child(_loading_label)

	_paw_row = _build_paw_row()
	content.add_child(_paw_row)

	var track := PanelContainer.new()
	track.custom_minimum_size = Vector2(320, 24)
	track.add_theme_stylebox_override("panel", _make_progress_track_stylebox())
	content.add_child(track)

	var fill_holder := Control.new()
	fill_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	track.add_child(fill_holder)

	_loading_fill = ColorRect.new()
	_loading_fill.color = Color("9aae8b")
	_loading_fill.position = Vector2(0, 0)
	_loading_fill.size = Vector2(0, 16)
	fill_holder.add_child(_loading_fill)
	_loading_track_fill_width = 312.0

	_loading_percent_label = Label.new()
	_loading_percent_label.text = UiText.START_LOADING_PERCENT_ZERO
	_loading_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_fredoka_medium(_loading_percent_label, UiPalette.FONT_SIZE_BODY_LG)
	_loading_percent_label.add_theme_color_override("font_color", Color("715b4a"))
	content.add_child(_loading_percent_label)

	return block


func _build_audio_debug_overlay() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -300.0
	panel.offset_top = -188.0
	panel.offset_right = -16.0
	panel.offset_bottom = -16.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.07, 0.90)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.86, 0.72, 0.52, 0.75)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	_audio_debug_label = Label.new()
	_audio_debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_audio_debug_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	UiFonts.apply_noto(_audio_debug_label, 13)
	_audio_debug_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.88, 1.0))
	margin.add_child(_audio_debug_label)

	return panel


func _build_tap_hint() -> Label:
	var hint := Label.new()
	hint.text = TAP_TO_START_TEXT
	hint.anchor_left = 0.0
	hint.anchor_top = 0.0
	hint.anchor_right = 0.0
	hint.anchor_bottom = 0.0
	hint.position = Vector2.ZERO
	hint.size = Vector2(380, 36)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(hint, UiPalette.FONT_SIZE_TITLE)
	hint.add_theme_color_override("font_color", Color("f7f1e7"))
	hint.add_theme_color_override("font_shadow_color", Color("5e4a3d"))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	return hint


func _build_logout_button() -> Button:
	var button := Button.new()
	button.text = UiText.START_LOGOUT_BUTTON
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 0.0
	button.anchor_bottom = 0.0
	button.position = Vector2(720.0 - 156.0, 28.0)
	button.custom_minimum_size = Vector2(128, 52)
	button.visible = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	UiFonts.apply_noto(button, UiPalette.FONT_SIZE_BODY_LG)
	button.add_theme_color_override("font_color", Color("fff8f2"))
	button.add_theme_color_override("font_hover_color", Color("fff8f2"))
	button.add_theme_color_override("font_pressed_color", Color("fff8f2"))
	button.add_theme_color_override("font_disabled_color", Color("f2d8d5"))
	button.add_theme_stylebox_override("normal", _make_button_stylebox(Color("c4574d"), 10))
	button.add_theme_stylebox_override("hover", _make_button_stylebox(Color("d4685d"), 10))
	button.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("a6473e"), 8))
	button.pressed.connect(UiAudio.play_ui_click)
	button.pressed.connect(_on_logout_pressed)
	return button


func _sync_adaptive_layout() -> void:
	var content_origin: Vector2 = AdaptiveViewport.get_content_origin(self)
	var visible_size: Vector2 = AdaptiveViewport.get_visible_size(self)
	var is_compact_auth_focus: bool = _is_compact_auth_focus_active(visible_size)
	var safe_frame_left: float = content_origin.x
	var safe_frame_width: float = AdaptiveViewport.BASE_SIZE.x

	if _title_card != null:
		_title_card.visible = not is_compact_auth_focus
		var title_width: float = _title_card.custom_minimum_size.x
		_title_card.position = Vector2(
			safe_frame_left + (safe_frame_width - title_width) * 0.5,
			content_origin.y + TITLE_CARD_DEFAULT_TOP
		)

	if _auth_block != null:
		var auth_height: float = _auth_block.custom_minimum_size.y
		var auth_width: float = _auth_block.custom_minimum_size.x
		var default_auth_top: float = content_origin.y + AUTH_BLOCK_DEFAULT_TOP
		var min_auth_top: float = content_origin.y + AUTH_BLOCK_FOCUS_MIN_TOP
		var max_auth_top: float = maxf(
			content_origin.y + visible_size.y - auth_height - AUTH_BLOCK_FOCUS_BOTTOM_MARGIN,
			AUTH_BLOCK_FOCUS_BOTTOM_MARGIN
		)
		var auth_top: float = default_auth_top
		if is_compact_auth_focus:
			auth_top = _fit_top_position(default_auth_top, min_auth_top, max_auth_top)
		_auth_block.position = Vector2(
			safe_frame_left + (safe_frame_width - auth_width) * 0.5,
			auth_top
		)

	if _loading_block != null:
		var loading_width: float = _loading_block.custom_minimum_size.x
		_loading_block.position = Vector2(
			safe_frame_left + (safe_frame_width - loading_width) * 0.5,
			content_origin.y + LOADING_BLOCK_DEFAULT_TOP
		)

	if _tap_hint != null:
		var tap_hint_width: float = _tap_hint.size.x
		_tap_hint.position = Vector2(
			safe_frame_left + (safe_frame_width - tap_hint_width) * 0.5,
			content_origin.y + TAP_HINT_DEFAULT_TOP
		)

	if _logout_button != null:
		_logout_button.position = content_origin + Vector2(720.0 - 156.0, 28.0)


func _on_auth_input_focus_changed() -> void:
	call_deferred("_sync_adaptive_layout")


func _is_compact_auth_focus_active(visible_size: Vector2) -> bool:
	return _is_auth_input_focused() and visible_size.y < KEYBOARD_COMPACT_HEIGHT_THRESHOLD


func _is_auth_input_focused() -> bool:
	var inputs: Array[LineEdit] = [
		_display_name_input,
		_account_input,
		_password_input,
		_confirm_password_input,
	]
	for input in inputs:
		if input != null and input.visible and input.has_focus():
			return true
	return false


func _fit_top_position(preferred_top: float, min_top: float, max_top: float) -> float:
	if max_top <= min_top:
		return max_top
	return clampf(preferred_top, min_top, max_top)


func _build_paw_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for _i in range(4):
		var paw := Label.new()
		paw.text = "\u25cf"
		paw.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
		paw.add_theme_color_override("font_color", Color("9aae8b"))
		row.add_child(paw)
	return row


func _build_input(placeholder: String, secret: bool) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size = Vector2(0, 46)
	input.secret = secret
	UiFonts.apply_noto(input, UiPalette.FONT_SIZE_BODY)
	input.text_submitted.connect(_on_input_submitted)
	input.focus_entered.connect(_on_auth_input_focus_changed)
	input.focus_exited.connect(_on_auth_input_focus_changed)
	return input


func _build_oauth_button(normal_texture: Texture2D, hover_texture: Texture2D = null, pressed_texture: Texture2D = null) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = normal_texture
	button.texture_hover = hover_texture if hover_texture != null else normal_texture
	button.texture_pressed = pressed_texture if pressed_texture != null else button.texture_hover
	button.texture_disabled = normal_texture
	button.ignore_texture_size = false
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = normal_texture.get_size()
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _on_oauth_google_pressed() -> void:
	_begin_oauth_sign_in(OAUTH_PROVIDER_GOOGLE, OAUTH_PROVIDER_NAME_GOOGLE)


func _on_oauth_apple_pressed() -> void:
	_begin_oauth_sign_in(OAUTH_PROVIDER_APPLE, OAUTH_PROVIDER_NAME_APPLE)


func _on_oauth_line_pressed() -> void:
	_begin_oauth_sign_in(OAUTH_PROVIDER_LINE, OAUTH_PROVIDER_NAME_LINE)


func _set_oauth_button_enabled(button: TextureButton, enabled: bool) -> void:
	if button == null:
		return
	button.disabled = not enabled
	button.modulate = Color(1.0, 1.0, 1.0, 1.0) if enabled else Color(1.0, 1.0, 1.0, 0.42)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW


func _is_oauth_provider_enabled(provider_key: String) -> bool:
	return not DISABLED_OAUTH_PROVIDER_KEYS.has(provider_key)


func _attach_http_request() -> void:
	_http_request = HTTPRequest.new()
	_http_request.timeout = REQUEST_TIMEOUT_SECONDS
	_http_request.request_completed.connect(_on_request_completed)
	add_child(_http_request)

	_bootstrap_retry_timer = Timer.new()
	_bootstrap_retry_timer.one_shot = true
	_bootstrap_retry_timer.wait_time = BOOTSTRAP_RETRY_DELAY_SECONDS
	_bootstrap_retry_timer.timeout.connect(_on_bootstrap_retry_timeout)
	add_child(_bootstrap_retry_timer)

	_oauth_poll_timer = Timer.new()
	_oauth_poll_timer.one_shot = true
	_oauth_poll_timer.wait_time = OAUTH_POLL_INTERVAL_SECONDS
	_oauth_poll_timer.timeout.connect(_on_oauth_poll_timeout)
	add_child(_oauth_poll_timer)


func _play_idle_animation() -> void:
	if _title_card != null:
		var base_y := _title_card.position.y
		var title_tween := create_tween().set_loops()
		title_tween.tween_property(_title_card, "position:y", base_y + 6.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		title_tween.tween_property(_title_card, "position:y", base_y, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _paw_row != null:
		for i in range(_paw_row.get_child_count()):
			var paw: Label = _paw_row.get_child(i)
			var paw_tween := create_tween().set_loops()
			paw_tween.tween_interval(float(i) * 0.12)
			paw_tween.tween_property(paw, "scale", Vector2.ONE * 1.2, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			paw_tween.parallel().tween_property(paw, "modulate:a", 1.0, 0.24)
			paw_tween.tween_property(paw, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			paw_tween.parallel().tween_property(paw, "modulate:a", 0.45, 0.32)

	if _tap_hint != null:
		var hint_tween := create_tween().set_loops()
		hint_tween.tween_property(_tap_hint, "modulate:a", 0.45, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hint_tween.tween_property(_tap_hint, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _apply_mode() -> void:
	var is_register := _mode == AuthMode.REGISTER
	var is_oauth_profile := _mode == AuthMode.OAUTH_PROFILE
	_form_title.text = OAUTH_PROFILE_TITLE if is_oauth_profile else (UiText.START_FORM_REGISTER if is_register else UiText.START_FORM_LOGIN)
	_display_name_input.visible = is_register or is_oauth_profile
	_display_name_input.placeholder_text = UiText.START_PLACEHOLDER_DISPLAY_NAME if not is_oauth_profile else OAUTH_PROFILE_HINT
	_account_input.visible = not is_oauth_profile
	_password_input.visible = not is_oauth_profile
	_confirm_password_input.visible = is_register
	_primary_button.text = OAUTH_PROFILE_PRIMARY if is_oauth_profile else (UiText.START_BUTTON_REGISTER if is_register else UiText.START_BUTTON_LOGIN)
	_secondary_button.text = OAUTH_PROFILE_SECONDARY if is_oauth_profile else (UiText.START_BUTTON_BACK_TO_LOGIN if is_register else UiText.START_BUTTON_REGISTER)
	if _guest_button != null:
		_guest_button.visible = not is_oauth_profile
	if _oauth_intro_label != null:
		_oauth_intro_label.visible = not is_oauth_profile
	if _oauth_button_row != null:
		_oauth_button_row.visible = not is_oauth_profile
	_status_label.text = ""
	_refresh_auth_block_layout()


func _get_auth_block_height() -> float:
	if _mode == AuthMode.OAUTH_PROFILE:
		return AUTH_BLOCK_HEIGHT_OAUTH_PROFILE
	if RuntimeConfig.is_oauth_enabled():
		return AUTH_BLOCK_HEIGHT_WITH_OAUTH
	if _mode == AuthMode.REGISTER:
		return AUTH_BLOCK_HEIGHT_REGISTER_COMPACT
	return AUTH_BLOCK_HEIGHT_LOGIN_COMPACT


func _refresh_auth_block_layout() -> void:
	if _auth_block == null:
		return
	_auth_block.custom_minimum_size = Vector2(AUTH_BLOCK_WIDTH, _get_auth_block_height())
	_sync_adaptive_layout()


func _set_auth_interactable(editable: bool) -> void:
	_display_name_input.editable = editable
	_account_input.editable = editable
	_password_input.editable = editable
	_confirm_password_input.editable = editable
	_primary_button.disabled = not editable
	_secondary_button.disabled = not editable
	if _guest_button != null:
		_guest_button.disabled = not editable
	if _oauth_google_button != null:
		_set_oauth_button_enabled(_oauth_google_button, editable and _is_oauth_provider_enabled(OAUTH_PROVIDER_GOOGLE))
	if _oauth_apple_button != null:
		_set_oauth_button_enabled(_oauth_apple_button, editable and _is_oauth_provider_enabled(OAUTH_PROVIDER_APPLE))
	if _oauth_line_button != null:
		_set_oauth_button_enabled(_oauth_line_button, editable and _is_oauth_provider_enabled(OAUTH_PROVIDER_LINE))


func _on_input_submitted(_text: String) -> void:
	if _mode == AuthMode.LOGIN:
		_submit_login()
	elif _mode == AuthMode.OAUTH_PROFILE:
		_submit_oauth_profile_name()
	else:
		_submit_register()


func _on_primary_pressed() -> void:
	if _mode == AuthMode.LOGIN:
		_submit_login()
	elif _mode == AuthMode.OAUTH_PROFILE:
		_submit_oauth_profile_name()
	else:
		_submit_register()


func _on_secondary_pressed() -> void:
	if _request_in_flight:
		return
	if _mode == AuthMode.OAUTH_PROFILE:
		_reset_oauth_state()
		_mode = AuthMode.LOGIN
		_apply_mode()
		return
	_mode = AuthMode.LOGIN if _mode == AuthMode.REGISTER else AuthMode.REGISTER
	_apply_mode()


func _on_guest_pressed() -> void:
	_submit_guest_login(true)


func _submit_login() -> void:
	if _request_in_flight:
		return

	var account := _account_input.text.strip_edges()
	var password := _password_input.text
	if account == "" or password.strip_edges() == "":
		_set_status(UiText.START_STATUS_ENTER_ACCOUNT_PASSWORD, true)
		return

	_request_in_flight = true
	_request_kind = REQUEST_KIND_AUTH
	_auth_request_mode = AuthMode.LOGIN
	_pending_retry_login_active = true
	_pending_retry_login_account = account
	_pending_retry_login_password = password
	_set_auth_interactable(false)
	_set_status(UiText.START_STATUS_CONNECTING_SERVER, false)
	_retain_network_loading_overlay(UiText.START_STATUS_CONNECTING_SERVER)

	var headers := _build_request_headers("", true)
	var body := JSON.stringify({
		"account": account,
		"password": password,
		"deviceId": _device_id,
		"deviceName": _build_device_name()
	})
	var error := _http_request.request("%s/auth/login" % _api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_set_auth_interactable(true)
		_restore_pending_login_inputs()
		_set_status(UiText.START_STATUS_REQUEST_ERROR_FORMAT % error, true)


func _submit_guest_login(reset_recovery_state: bool = false) -> void:
	if _request_in_flight:
		return

	_mode = AuthMode.LOGIN
	_apply_mode()
	if reset_recovery_state:
		_guest_account_exists_recovery_attempted = false
	_request_in_flight = true
	_request_kind = REQUEST_KIND_GUEST_LOGIN
	_auth_request_mode = AuthMode.LOGIN
	_set_auth_interactable(false)
	_set_status(UiText.START_STATUS_GUEST_LOGIN, false)
	_retain_network_loading_overlay(UiText.START_STATUS_GUEST_LOGIN)

	var headers: PackedStringArray = _build_request_headers("", true)
	var body: String = JSON.stringify({
		"account": _build_guest_account(),
		"password": _build_guest_password(),
		"deviceId": _device_id,
		"deviceName": _build_device_name()
	})
	var error: int = _http_request.request("%s/auth/login" % _api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_release_network_loading_overlay()
		_set_status(UiText.START_STATUS_REQUEST_ERROR_FORMAT % error, true)


func _submit_guest_register() -> void:
	if _request_in_flight:
		return

	_request_in_flight = true
	_request_kind = REQUEST_KIND_GUEST_REGISTER
	_auth_request_mode = AuthMode.REGISTER
	_set_auth_interactable(false)
	_set_status(UiText.START_STATUS_GUEST_REGISTER, false)
	_retain_network_loading_overlay(UiText.START_STATUS_GUEST_REGISTER)

	var headers: PackedStringArray = _build_request_headers("", true)
	var body: String = JSON.stringify({
		"displayName": _build_guest_display_name(),
		"account": _build_guest_account(),
		"password": _build_guest_password(),
		"confirmPassword": _build_guest_password(),
		"deviceId": _device_id,
		"deviceName": _build_device_name()
	})
	var error: int = _http_request.request("%s/auth/register" % _api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_release_network_loading_overlay()
		_set_status(UiText.START_STATUS_REQUEST_ERROR_FORMAT % error, true)


func _submit_register() -> void:
	if _request_in_flight:
		return

	var display_name := _display_name_input.text.strip_edges()
	var account := _account_input.text.strip_edges()
	var password := _password_input.text
	var confirm_password := _confirm_password_input.text

	if display_name == "" or account == "" or password.strip_edges() == "" or confirm_password.strip_edges() == "":
		_set_status(UiText.START_STATUS_FILL_REGISTER_FIELDS, true)
		return

	if password.length() < 8:
		_set_status(UiText.START_STATUS_PASSWORD_MIN_LENGTH, true)
		return

	if password != confirm_password:
		_set_status(UiText.START_STATUS_PASSWORD_MISMATCH, true)
		return

	_request_in_flight = true
	_request_kind = REQUEST_KIND_AUTH
	_auth_request_mode = AuthMode.REGISTER
	_set_auth_interactable(false)
	_set_status(UiText.START_STATUS_CONNECTING_SERVER, false)
	_retain_network_loading_overlay(UiText.START_STATUS_CONNECTING_SERVER)

	var headers := _build_request_headers("", true)
	var body := JSON.stringify({
		"displayName": display_name,
		"account": account,
		"password": password,
		"confirmPassword": confirm_password,
		"deviceId": _device_id,
		"deviceName": _build_device_name()
	})
	var error := _http_request.request("%s/auth/register" % _api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_set_auth_interactable(true)
		_release_network_loading_overlay()
		_set_status(UiText.START_STATUS_REQUEST_ERROR_FORMAT % error, true)


func _begin_oauth_sign_in(provider_key: String, provider_name: String) -> void:
	if _request_in_flight:
		return
	if not RuntimeConfig.is_oauth_enabled():
		_set_status(UiText.START_STATUS_OAUTH_DISABLED, true)
		return

	_mode = AuthMode.LOGIN
	_apply_mode()
	_request_in_flight = true
	_request_kind = REQUEST_KIND_OAUTH_BEGIN
	_oauth_provider_key = provider_key
	_oauth_provider_name = provider_name
	_set_auth_interactable(false)
	_set_status(UiText.START_STATUS_CONNECTING_SERVER, false)
	_retain_network_loading_overlay(UiText.START_STATUS_CONNECTING_SERVER)

	var headers := _build_request_headers("", true)
	var body := JSON.stringify({
		"platformType": _get_oauth_platform_type(),
		"deviceId": _device_id,
		"deviceName": _build_device_name(),
	})
	var error := _http_request.request("%s/auth/oauth/%s/begin" % [_api_base_url, provider_key], headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_release_network_loading_overlay()
		_set_status(OAUTH_BEGIN_FAILED_STATUS, true)


func _submit_oauth_profile_name() -> void:
	if _request_in_flight:
		return

	var player_name := _display_name_input.text.strip_edges()
	if player_name == "":
		_set_status(OAUTH_PLAYER_NAME_REQUIRED, true)
		return
	if _oauth_transaction_id == "":
		_set_status(OAUTH_BEGIN_FAILED_STATUS, true)
		return

	_request_in_flight = true
	_request_kind = REQUEST_KIND_OAUTH_COMPLETE_PROFILE
	_set_auth_interactable(false)
	_set_status(OAUTH_COMPLETE_PROFILE_STATUS, false)
	_retain_network_loading_overlay(OAUTH_COMPLETE_PROFILE_STATUS)

	var headers := _build_request_headers("", true)
	var body := JSON.stringify({
		"transactionId": _oauth_transaction_id,
		"playerName": player_name,
	})
	var error := _http_request.request("%s/auth/oauth/complete-profile" % _api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_release_network_loading_overlay()
		_set_status(UiText.START_STATUS_REQUEST_ERROR_FORMAT % error, true)


func _begin_oauth_exchange_polling(transaction_id: String) -> void:
	_oauth_transaction_id = transaction_id
	_oauth_poll_elapsed = 0.0
	if _oauth_poll_timer != null:
		_oauth_poll_timer.stop()
		_oauth_poll_timer.wait_time = OAUTH_POLL_INTERVAL_SECONDS
		_oauth_poll_timer.start()


func _stop_oauth_polling() -> void:
	if _oauth_poll_timer != null:
		_oauth_poll_timer.stop()


func _request_oauth_exchange() -> void:
	if _request_in_flight or _oauth_transaction_id == "":
		return

	_request_in_flight = true
	_request_kind = REQUEST_KIND_OAUTH_EXCHANGE
	_set_auth_interactable(false)
	var headers := _build_request_headers("", true)
	var body := JSON.stringify({
		"transactionId": _oauth_transaction_id,
	})
	var error := _http_request.request("%s/auth/oauth/exchange" % _api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_release_network_loading_overlay()
		_set_status(UiText.START_STATUS_REQUEST_ERROR_FORMAT % error, true)


func _handle_oauth_begin_success(data: Dictionary) -> void:
	_release_network_loading_overlay()
	_oauth_transaction_id = str(data.get("transactionId", "")).strip_edges()
	var authorization_url := str(data.get("authorizationUrl", "")).strip_edges()
	if _oauth_transaction_id == "" or authorization_url == "":
		_reset_oauth_state()
		_set_status(OAUTH_BEGIN_FAILED_STATUS, true)
		return

	var open_error := OS.shell_open(authorization_url)
	if open_error != OK:
		_reset_oauth_state()
		_set_status(UiText.START_STATUS_REQUEST_ERROR_FORMAT % open_error, true)
		return

	_set_status(OAUTH_OPENED_STATUS, false)
	_begin_oauth_exchange_polling(_oauth_transaction_id)


func _handle_oauth_exchange_success(data: Dictionary) -> void:
	var status := str(data.get("status", "")).strip_edges().to_lower()
	match status:
		"pending":
			_set_status(OAUTH_PENDING_STATUS, false)
			_schedule_next_oauth_poll()
		"authenticated":
			_stop_oauth_polling()
			_reset_oauth_state(false)
			GameState.set_auth_session(_api_base_url, data.get("authTokens", {}))
			_api_base_url = GameState.api_base_url
			_sync_logout_button_visibility()
			_show_loading_state()
			_begin_authenticated_bootstrap(UiText.START_STATUS_BOOTSTRAP_SYNC)
		"needs_profile_name":
			_stop_oauth_polling()
			_mode = AuthMode.OAUTH_PROFILE
			_apply_mode()
			_display_name_input.text = str(data.get("suggestedPlayerName", "")).strip_edges()
			_display_name_input.grab_focus()
			_set_status("Finish %s sign-in by choosing your player name." % _oauth_provider_name, false)
		"conflict_existing_account_requires_bind":
			_stop_oauth_polling()
			_reset_oauth_state()
			_set_status(str(data.get("errorMessage", OAUTH_CONFLICT_STATUS)), true)
		"cancelled":
			_stop_oauth_polling()
			_reset_oauth_state()
			_set_status(str(data.get("errorMessage", OAUTH_CANCELLED_STATUS)), false)
		"failed":
			_stop_oauth_polling()
			_reset_oauth_state()
			_set_status(str(data.get("errorMessage", UiText.START_STATUS_LOGIN_FAILED)), true)
		_:
			_stop_oauth_polling()
			_reset_oauth_state()
			_set_status(UiText.START_STATUS_INVALID_RESPONSE, true)


func _schedule_next_oauth_poll() -> void:
	if _oauth_transaction_id == "":
		return
	_oauth_poll_elapsed += OAUTH_POLL_INTERVAL_SECONDS
	if _oauth_poll_elapsed >= OAUTH_POLL_TIMEOUT_SECONDS:
		_stop_oauth_polling()
		_reset_oauth_state()
		_set_status(OAUTH_TIMEOUT_STATUS, true)
		return
	if _oauth_poll_timer != null:
		_oauth_poll_timer.stop()
		_oauth_poll_timer.wait_time = OAUTH_POLL_INTERVAL_SECONDS
		_oauth_poll_timer.start()


func _reset_oauth_state(clear_provider: bool = true) -> void:
	_stop_oauth_polling()
	_oauth_transaction_id = ""
	_oauth_poll_elapsed = 0.0
	if clear_provider:
		_oauth_provider_key = ""
		_oauth_provider_name = ""


func _get_oauth_platform_type() -> String:
	var os_name := OS.get_name().to_lower()
	if os_name.find("android") >= 0:
		return "Android"
	if os_name.find("ios") >= 0:
		return "Ios"
	return "Web" if OS.has_feature("web") else "Web"


func _on_oauth_poll_timeout() -> void:
	_request_oauth_exchange()


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_request_in_flight = false
	var completed_request_kind := _request_kind
	_request_kind = ""
	_set_auth_interactable(true)

	if result != HTTPRequest.RESULT_SUCCESS:
		_handle_request_transport_failure(completed_request_kind, result)
		return

	var response_text := body.get_string_from_utf8()
	var response_json := JSON.new()
	if response_text == "" or response_json.parse(response_text) != OK:
		_handle_request_invalid_response(completed_request_kind)
		return

	var payload_variant: Variant = response_json.get_data()
	var payload: Dictionary = payload_variant if payload_variant is Dictionary else {}
	var success := bool(payload.get("success", false))
	var data_variant: Variant = payload.get("data", {})
	var error_variant: Variant = payload.get("error", {})
	var data: Dictionary = data_variant if data_variant is Dictionary else {}
	var error_payload: Dictionary = error_variant if error_variant is Dictionary else {}

	if response_code >= 200 and response_code < 300 and success:
		if completed_request_kind == REQUEST_KIND_AUTH \
			or completed_request_kind == REQUEST_KIND_GUEST_LOGIN \
			or completed_request_kind == REQUEST_KIND_GUEST_REGISTER \
			or completed_request_kind == REQUEST_KIND_REFRESH \
			or completed_request_kind == REQUEST_KIND_OAUTH_COMPLETE_PROFILE:
			GameState.set_auth_session(_api_base_url, data)
			_api_base_url = GameState.api_base_url
			_sync_logout_button_visibility()
			if completed_request_kind == REQUEST_KIND_AUTH \
				or completed_request_kind == REQUEST_KIND_GUEST_LOGIN \
				or completed_request_kind == REQUEST_KIND_GUEST_REGISTER \
				or _loading_block == null \
				or not _loading_block.visible:
				_show_loading_state()
			if completed_request_kind == REQUEST_KIND_OAUTH_COMPLETE_PROFILE:
				_reset_oauth_state()
			_begin_authenticated_bootstrap(UiText.START_STATUS_BOOTSTRAP_SYNC)
			return
		if completed_request_kind == REQUEST_KIND_OAUTH_BEGIN:
			_handle_oauth_begin_success(data)
			return
		if completed_request_kind == REQUEST_KIND_OAUTH_EXCHANGE:
			_release_network_loading_overlay()
			_handle_oauth_exchange_success(data)
			return
		if completed_request_kind == REQUEST_KIND_BOOTSTRAP:
			if not _is_bootstrap_payload_complete(data):
				GameState.clear_persisted_player_state()
				_abort_loading_state()
				_set_status(UiText.START_STATUS_INVALID_RESPONSE, true)
				return
			_cancel_bootstrap_retry()
			GameState.apply_player_bootstrap(data)
			_cdn_warmup_completed = false
			if not CdnTextureLoader.warmup_completed.is_connected(_on_cdn_warmup_completed):
				CdnTextureLoader.warmup_completed.connect(_on_cdn_warmup_completed, CONNECT_ONE_SHOT)
			CdnTextureLoader.warm_cache(AssetResolver.collect_warmup_cdn_urls(GameState.get_owned_cats()))
			_bootstrap_completed = true
			_try_finish_loading()
			return
		if completed_request_kind == REQUEST_KIND_LOGOUT_REFRESH:
			GameState.set_auth_session(GameState.api_base_url, data)
			_sync_logout_button_visibility()
			_begin_logout_revoke()
			return
		if completed_request_kind == REQUEST_KIND_LOGOUT_REVOKE:
			_release_network_loading_overlay()
			_finalize_logout()
			return
		_release_network_loading_overlay()
		GameState.set_auth_session(_api_base_url, data)
		_sync_logout_button_visibility()
		_show_loading_state()
		return

	if completed_request_kind == REQUEST_KIND_BOOTSTRAP and response_code == 401 and GameState.get_refresh_token() != "":
		_begin_refresh_then_bootstrap()
		return

	if completed_request_kind == REQUEST_KIND_BOOTSTRAP and response_code == 401:
		_handle_session_expired(UiText.START_STATUS_LOGIN_EXPIRED)
		return

	if completed_request_kind == REQUEST_KIND_BOOTSTRAP:
		_abort_loading_state()
		var bootstrap_message := str(error_payload.get("message", UiText.START_STATUS_BOOTSTRAP_FAILED))
		_set_status(bootstrap_message, true)
		return

	if completed_request_kind == REQUEST_KIND_REFRESH:
		_handle_session_expired(UiText.START_STATUS_LOGIN_EXPIRED)
		return

	if completed_request_kind == REQUEST_KIND_GUEST_LOGIN:
		_release_network_loading_overlay()
		if _is_account_already_exists_error(error_payload) and not _guest_account_exists_recovery_attempted:
			_guest_account_exists_recovery_attempted = true
			_submit_guest_login()
			return
		if response_code == 401 and not _guest_account_exists_recovery_attempted:
			_submit_guest_register()
			return
		if _guest_account_exists_recovery_attempted and response_code == 401:
			var recovered_guest_login_message: String = str(error_payload.get("message") if error_payload.get("message") != null else UiText.START_STATUS_LOGIN_FAILED)
			_set_status(recovered_guest_login_message, true)
			return
		var guest_login_message: String = str(error_payload.get("message") if error_payload.get("message") != null else UiText.START_STATUS_LOGIN_FAILED)
		_set_status(guest_login_message, true)
		return

	if completed_request_kind == REQUEST_KIND_GUEST_REGISTER:
		_release_network_loading_overlay()
		if _is_account_already_exists_error(error_payload) and not _guest_account_exists_recovery_attempted:
			_guest_account_exists_recovery_attempted = true
			_submit_guest_login()
			return
		var guest_register_message: String = str(error_payload.get("message") if error_payload.get("message") != null else UiText.START_STATUS_LOGIN_FAILED)
		_set_status(guest_register_message, true)
		return

	if completed_request_kind == REQUEST_KIND_OAUTH_BEGIN:
		_release_network_loading_overlay()
		_reset_oauth_state()
		var begin_message = error_payload.get("message") if error_payload.get("message") != null else OAUTH_BEGIN_FAILED_STATUS
		_set_status(begin_message, true)
		return

	if completed_request_kind == REQUEST_KIND_OAUTH_EXCHANGE:
		_release_network_loading_overlay()
		_stop_oauth_polling()
		var exchange_code := str(error_payload.get("code", ""))
		var exchange_message = error_payload.get("message") if error_payload.get("message") != null else UiText.START_STATUS_LOGIN_FAILED
		if exchange_code == "OAUTH.TRANSACTION_NOT_FOUND":
			exchange_message = OAUTH_TIMEOUT_STATUS
		_reset_oauth_state()
		_set_status(exchange_message, true)
		return

	if completed_request_kind == REQUEST_KIND_OAUTH_COMPLETE_PROFILE:
		_release_network_loading_overlay()
		var complete_message = error_payload.get("message") if error_payload.get("message") != null else UiText.START_STATUS_LOGIN_FAILED
		_set_status(complete_message, true)
		return

	if completed_request_kind == REQUEST_KIND_LOGOUT_REVOKE:
		if response_code == 404:
			_release_network_loading_overlay()
			_finalize_logout()
			return
		if response_code == 401 and not _logout_revoke_retry and GameState.get_refresh_token() != "":
			_begin_logout_refresh()
			return
		_release_network_loading_overlay()
		var logout_message = error_payload.get("message") if error_payload.get("message") != null else UiText.START_STATUS_LOGOUT_FAILED
		_set_logout_button_state(true)
		_set_status(logout_message, true)
		return

	if completed_request_kind == REQUEST_KIND_LOGOUT_REFRESH:
		if response_code == 401 or response_code == 404:
			_release_network_loading_overlay()
			_finalize_logout()
			return
		_release_network_loading_overlay()
		var logout_refresh_message = error_payload.get("message") if error_payload.get("message") != null else UiText.START_STATUS_LOGOUT_REFRESH_FAILED
		_set_logout_button_state(true)
		_set_status(logout_refresh_message, true)
		return

	var message = error_payload.get("message") if error_payload.get("message") != null else UiText.START_STATUS_LOGIN_FAILED
	_release_network_loading_overlay()
	if completed_request_kind == REQUEST_KIND_AUTH and _auth_request_mode == AuthMode.LOGIN:
		_restore_pending_login_inputs()
	_set_status(message, true)


func _handle_request_transport_failure(completed_request_kind: String, result: int) -> void:
	_release_network_loading_overlay()
	if completed_request_kind == REQUEST_KIND_BOOTSTRAP and _is_bootstrap_retryable_result(result):
		if _bootstrap_retry_count < BOOTSTRAP_MAX_RETRY_COUNT:
			_schedule_bootstrap_retry()
			return
	if completed_request_kind == REQUEST_KIND_OAUTH_EXCHANGE:
		_schedule_next_oauth_poll()
		return
	var message := _describe_http_request_result(result)
	if completed_request_kind == REQUEST_KIND_BOOTSTRAP or completed_request_kind == REQUEST_KIND_REFRESH:
		_abort_loading_state()
		if completed_request_kind == REQUEST_KIND_REFRESH:
			_handle_session_expired(UiText.START_STATUS_LOGIN_EXPIRED)
			return
	elif completed_request_kind == REQUEST_KIND_OAUTH_BEGIN or completed_request_kind == REQUEST_KIND_OAUTH_COMPLETE_PROFILE:
		_reset_oauth_state()
	elif completed_request_kind == REQUEST_KIND_OAUTH_EXCHANGE:
		_schedule_next_oauth_poll()
		return
	elif completed_request_kind == REQUEST_KIND_LOGOUT_REVOKE or completed_request_kind == REQUEST_KIND_LOGOUT_REFRESH:
		_set_logout_button_state(true)
	elif (completed_request_kind == REQUEST_KIND_AUTH or completed_request_kind == REQUEST_KIND_GUEST_LOGIN) and _auth_request_mode == AuthMode.LOGIN:
		_restore_pending_login_inputs()
	_logout_dialog_open = false if completed_request_kind.begins_with("logout") else _logout_dialog_open
	_set_status(message, true)


func _handle_request_invalid_response(completed_request_kind: String) -> void:
	_release_network_loading_overlay()
	if completed_request_kind == REQUEST_KIND_BOOTSTRAP or completed_request_kind == REQUEST_KIND_REFRESH:
		_abort_loading_state()
		if completed_request_kind == REQUEST_KIND_REFRESH:
			_handle_session_expired(UiText.START_STATUS_LOGIN_EXPIRED)
			return
	elif completed_request_kind == REQUEST_KIND_OAUTH_BEGIN or completed_request_kind == REQUEST_KIND_OAUTH_COMPLETE_PROFILE:
		_reset_oauth_state()
	elif completed_request_kind == REQUEST_KIND_OAUTH_EXCHANGE:
		_schedule_next_oauth_poll()
		return
	elif completed_request_kind == REQUEST_KIND_LOGOUT_REVOKE or completed_request_kind == REQUEST_KIND_LOGOUT_REFRESH:
		_set_logout_button_state(true)
	elif (completed_request_kind == REQUEST_KIND_AUTH or completed_request_kind == REQUEST_KIND_GUEST_LOGIN) and _auth_request_mode == AuthMode.LOGIN:
		_restore_pending_login_inputs()
	_logout_dialog_open = false if completed_request_kind.begins_with("logout") else _logout_dialog_open
	_set_status(UiText.START_STATUS_INVALID_RESPONSE, true)


func _describe_http_request_result(result: int) -> String:
	match result:
		HTTPRequest.RESULT_TIMEOUT:
			return UiText.START_STATUS_TIMEOUT
		HTTPRequest.RESULT_CANT_CONNECT:
			return UiText.START_STATUS_CANT_CONNECT
		HTTPRequest.RESULT_CANT_RESOLVE:
			return UiText.START_STATUS_CANT_RESOLVE
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return UiText.START_STATUS_CONNECTION_ERROR
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return UiText.START_STATUS_TLS_ERROR
		_:
			return UiText.START_STATUS_GENERIC_RESULT_ERROR % result


func _is_bootstrap_payload_complete(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	if not data.has("catCatalog") or not (data.get("catCatalog") is Array):
		return false
	if not data.has("playerCats") or not (data.get("playerCats") is Array):
		return false
	if not data.has("playerTeams") or not (data.get("playerTeams") is Array):
		return false
	if not data.has("stageOpponentConfig") or not (data.get("stageOpponentConfig") is Dictionary):
		return false
	return true


func _handle_session_expired(message: String) -> void:
	_abort_loading_state()
	GameState.clear_auth_and_player_state()
	_api_base_url = _resolve_api_base_url()
	_sync_logout_button_visibility()
	_set_status(message, true)


func _begin_authenticated_bootstrap(status_message: String, reset_retry_count: bool = true) -> void:
	if _request_in_flight:
		return

	var access_token := GameState.get_access_token()
	if access_token == "":
		GameState.clear_auth_session()
		_set_status(UiText.START_STATUS_LOGIN_INFO_MISSING, true)
		return

	if reset_retry_count:
		_cancel_bootstrap_retry()
		_bootstrap_retry_count = 0

	_request_in_flight = true
	_request_kind = REQUEST_KIND_BOOTSTRAP
	_set_auth_interactable(false)
	_set_status(status_message, false)
	_set_loading_message(status_message)

	var headers := _build_request_headers(access_token)
	var error := _http_request.request("%s/auth/bootstrap" % _api_base_url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_abort_loading_state()
		_release_network_loading_overlay()
		_set_status(UiText.START_STATUS_BOOTSTRAP_REQUEST_ERROR_FORMAT % error, true)


func _begin_refresh_then_bootstrap() -> void:
	if _request_in_flight:
		return

	var refresh_token := GameState.get_refresh_token()
	if refresh_token == "":
		GameState.clear_auth_session()
		_set_status(UiText.START_STATUS_LOGIN_EXPIRED, true)
		return

	_request_in_flight = true
	_request_kind = REQUEST_KIND_REFRESH
	_set_auth_interactable(false)
	_retain_network_loading_overlay(UiText.START_STATUS_BOOTSTRAP_SYNC)
	_set_status(UiText.START_STATUS_REFRESHING_SESSION, false)

	var headers := _build_request_headers("", true)
	var body := JSON.stringify({
		"refreshToken": refresh_token
	})
	var error := _http_request.request("%s/auth/refresh" % _api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_abort_loading_state()
		_release_network_loading_overlay()
		_set_status(UiText.START_STATUS_REFRESH_REQUEST_ERROR_FORMAT % error, true)


func _show_loading_state() -> void:
	_input_ready = false
	_bootstrap_completed = false
	_cdn_warmup_completed = false
	_bootstrap_retry_count = 0
	_loading_animation_finished = false
	_cancel_loading_tweens()
	_cancel_bootstrap_retry()
	_sync_logout_button_visibility()
	_set_status("", false)
	if _auth_block != null:
		_auth_block.visible = false
	if _loading_block != null:
		_loading_block.visible = true
		_loading_block.modulate.a = 1.0
	if _tap_hint != null:
		_tap_hint.visible = false
	if _loading_label != null:
		_loading_label.text = UiText.START_LOADING_GATHERING
	_set_loading_progress_visual(0.0)
	_start_fake_loading()


func _start_fake_loading() -> void:
	if _loading_fill == null or _loading_percent_label == null:
		return

	_set_loading_progress_visual(0.0)
	_loading_fill_tween = create_tween()
	_loading_fill_tween.tween_method(
		_set_loading_progress_visual,
		0.0,
		BOOTSTRAP_PROGRESS_MAX_PERCENT,
		BOOTSTRAP_PROGRESS_DURATION_SECONDS
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_loading_fill_tween.finished.connect(_on_loading_animation_finished)
	_loading_percent_tween = _loading_fill_tween


func _on_loading_animation_finished() -> void:
	_loading_fill_tween = null
	_loading_percent_tween = null
	_loading_animation_finished = true
	_try_finish_loading()


func _on_cdn_warmup_completed() -> void:
	_cdn_warmup_completed = true
	_try_finish_loading()


func _try_finish_loading() -> void:
	if _bootstrap_completed and _loading_animation_finished and _cdn_warmup_completed:
		_complete_loading_state()


func _complete_loading_state() -> void:
	if not _bootstrap_completed or _input_ready:
		return

	_cancel_loading_tweens()
	_clear_pending_login_retry()
	_input_ready = true
	_sync_logout_button_visibility()
	if _loading_label != null:
		_loading_label.text = UiText.START_LOADING_COMPLETE
	_set_loading_progress_visual(100.0)
	if _loading_block != null:
		var fade_tween := create_tween()
		fade_tween.tween_property(_loading_block, "modulate:a", 0.0, 0.3)
		fade_tween.finished.connect(_on_loading_block_fade_finished)
	if _tap_hint != null:
		_tap_hint.visible = true


func _cancel_loading_tweens() -> void:
	var shared_tween := _loading_fill_tween != null and _loading_fill_tween == _loading_percent_tween
	if _loading_fill_tween != null:
		_loading_fill_tween.kill()
		_loading_fill_tween = null
	if _loading_percent_tween != null and not shared_tween:
		_loading_percent_tween.kill()
	_loading_percent_tween = null


func _on_loading_block_fade_finished() -> void:
	if _loading_block != null:
		_loading_block.visible = false


func _abort_loading_state() -> void:
	_cancel_loading_tweens()
	_cancel_bootstrap_retry()
	_bootstrap_retry_count = 0
	_bootstrap_completed = false
	_cdn_warmup_completed = false
	_loading_animation_finished = false
	if CdnTextureLoader.warmup_completed.is_connected(_on_cdn_warmup_completed):
		CdnTextureLoader.warmup_completed.disconnect(_on_cdn_warmup_completed)
	if _auth_block != null:
		_auth_block.visible = true
	if _loading_block != null:
		_loading_block.visible = false
		_loading_block.modulate.a = 1.0
	if _tap_hint != null:
		_tap_hint.visible = false
	_set_loading_progress_visual(0.0)
	_restore_pending_login_inputs()


func _restore_pending_login_inputs() -> void:
	if not _pending_retry_login_active:
		return
	if _account_input != null:
		_account_input.text = _pending_retry_login_account
	if _password_input != null:
		_password_input.text = _pending_retry_login_password


func _clear_pending_login_retry() -> void:
	_pending_retry_login_active = false
	_pending_retry_login_account = ""
	_pending_retry_login_password = ""


func _set_loading_progress_visual(value: float) -> void:
	var clamped_value := clampf(value, 0.0, 100.0)
	if _loading_fill != null:
		_loading_fill.size.x = _loading_track_fill_width * (clamped_value / 100.0)
	if _loading_percent_label != null:
		_loading_percent_label.text = UiText.START_LOADING_PERCENT_FORMAT % int(round(clamped_value))


func _set_loading_message(message: String) -> void:
	if _loading_label != null and message != "":
		_loading_label.text = message


func _is_bootstrap_retryable_result(result: int) -> bool:
	return result == HTTPRequest.RESULT_TIMEOUT \
		or result == HTTPRequest.RESULT_CANT_CONNECT \
		or result == HTTPRequest.RESULT_CANT_RESOLVE \
		or result == HTTPRequest.RESULT_CONNECTION_ERROR


func _is_account_already_exists_error(error_payload: Dictionary) -> bool:
	var code: String = str(error_payload.get("code", "")).strip_edges().to_upper()
	if code == "AUTH.ACCOUNT_ALREADY_EXISTS":
		return true
	if code == "AUTH.ACCOUNT_DELETED":
		return true

	var message: String = str(error_payload.get("message", "")).strip_edges().to_lower()
	if message.findn("account already exists") != -1:
		return true
	if message.findn("account deleted") != -1:
		return true
	return message.findn("account is deleted") != -1


func _schedule_bootstrap_retry() -> void:
	_bootstrap_retry_count += 1
	var retry_message := UiText.START_STATUS_RETRY_FORMAT % [
		int(BOOTSTRAP_RETRY_DELAY_SECONDS),
		_bootstrap_retry_count,
		BOOTSTRAP_MAX_RETRY_COUNT
	]
	_set_status(retry_message, true)
	_set_loading_message(retry_message)
	if _bootstrap_retry_timer != null:
		_bootstrap_retry_timer.stop()
		_bootstrap_retry_timer.wait_time = BOOTSTRAP_RETRY_DELAY_SECONDS
		_bootstrap_retry_timer.start()


func _cancel_bootstrap_retry() -> void:
	if _bootstrap_retry_timer != null:
		_bootstrap_retry_timer.stop()


func _on_bootstrap_retry_timeout() -> void:
	if _request_in_flight:
		return
	_begin_authenticated_bootstrap(UiText.START_STATUS_BOOTSTRAP_RETRY, false)


func _start_game() -> void:
	if not _input_ready:
		return
	if GameState.is_new_player:
		SceneNavigator.enter_onboarding()
	else:
		SceneNavigator.enter_home_shell()


func _input(event: InputEvent) -> void:
	if not _input_ready:
		return
	if _logout_dialog_open:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_event_on_logout_button(event.position):
			return
		UiAudio.unlock_from_user_gesture(false)
		_start_game()
	elif event is InputEventScreenTouch and event.pressed:
		if _is_event_on_logout_button(event.position):
			return
		UiAudio.unlock_from_user_gesture(false)
		_start_game()


func _set_status(message: String, is_error: bool) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color("7d2f2f") if is_error else Color("46613d"))


func _refresh_audio_debug_overlay(snapshot: Dictionary) -> void:
	if _audio_debug_label == null:
		return
	var lines: Array[String] = []
	lines.append("Audio Debug")
	lines.append("web=%s" % str(snapshot.get("is_web_runtime", false)))
	lines.append("policy=%s" % str(snapshot.get("autoplay_policy", "")))
	lines.append("unlocked=%s" % str(snapshot.get("web_audio_unlocked", false)))
	lines.append("bgm_playing=%s" % str(snapshot.get("bgm_playing", false)))
	lines.append("pending_restart=%s" % str(snapshot.get("pending_bgm_restart", false)))
	lines.append("retry=%s active=%s" % [str(snapshot.get("retry_attempts", 0)), str(snapshot.get("retry_timer_active", false))])
	lines.append("current=%s" % _short_audio_debug_path(str(snapshot.get("current_bgm_path", ""))))
	lines.append("pending=%s" % _short_audio_debug_path(str(snapshot.get("pending_bgm_path", ""))))
	_audio_debug_label.text = "\n".join(lines)


func _short_audio_debug_path(path: String) -> String:
	if path == "":
		return "-"
	var slash_index: int = path.rfind("/")
	if slash_index == -1:
		return path
	return path.substr(slash_index + 1)


func _should_show_audio_debug_overlay() -> bool:
	if not OS.has_feature("web"):
		return false
	if not ClassDB.class_exists("JavaScriptBridge"):
		return false
	var raw_flag: Variant = JavaScriptBridge.eval("(() => { const params = new URLSearchParams(window.location.search); return params.get('audio_debug') || params.get('audioDebug') || ''; })()", true)
	var normalized: String = str(raw_flag).strip_edges().to_lower()
	return normalized == "1" or normalized == "true" or normalized == "yes"


func _retain_network_loading_overlay(_message: String) -> void:
	pass


func _release_network_loading_overlay() -> void:
	pass


func _sync_logout_button_visibility() -> void:
	if _logout_button == null:
		return
	_logout_button.visible = _input_ready and not GameState.auth_session.is_empty()


func _is_event_on_logout_button(event_position: Vector2) -> bool:
	if _logout_button == null or not _logout_button.visible:
		return false
	return _logout_button.get_global_rect().has_point(event_position)


func _set_logout_button_state(enabled: bool, button_text: String = UiText.START_LOGOUT_BUTTON) -> void:
	if _logout_button == null:
		return
	_logout_button.disabled = not enabled
	_logout_button.text = button_text

func _on_logout_pressed() -> void:
	if _request_in_flight:
		return

	_logout_dialog_open = true
	DialogManager.show_confirm(
		UiText.START_LOGOUT_CONFIRM_TITLE,
		UiText.START_LOGOUT_CONFIRM_BODY,
		Callable(self, "_begin_logout"),
		Callable(self, "_on_logout_dialog_cancelled")
	)


func _on_logout_dialog_cancelled() -> void:
	_logout_dialog_open = false

func _begin_logout() -> void:
	_logout_revoke_retry = false
	_begin_logout_revoke()


func _begin_logout_revoke() -> void:
	var refresh_token := GameState.get_refresh_token()
	if refresh_token == "":
		_finalize_logout()
		return

	var access_token := GameState.get_access_token()
	if access_token == "":
		_begin_logout_refresh()
		return

	_request_in_flight = true
	_request_kind = REQUEST_KIND_LOGOUT_REVOKE
	_set_auth_interactable(false)
	_set_logout_button_state(false, UiText.START_LOGOUT_BUTTON_WORKING)
	_set_status(UiText.START_STATUS_LOGGING_OUT, false)

	var headers := _build_request_headers(access_token, true)
	var body := JSON.stringify({
		"refreshToken": refresh_token,
		"reason": UiText.START_LOGOUT_REASON
	})
	var error := _http_request.request("%s/auth/revoke" % GameState.api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_set_logout_button_state(true)
		_set_status(UiText.START_STATUS_LOGOUT_REQUEST_ERROR_FORMAT % error, true)

func _begin_logout_refresh() -> void:
	var refresh_token := GameState.get_refresh_token()
	if refresh_token == "":
		_finalize_logout()
		return

	_logout_revoke_retry = true
	_request_in_flight = true
	_request_kind = REQUEST_KIND_LOGOUT_REFRESH
	_set_auth_interactable(false)
	_set_logout_button_state(false, UiText.START_REFRESH_BUTTON_WORKING)
	_set_status(UiText.START_STATUS_LOGOUT_REFRESHING, false)

	var headers := _build_request_headers("", true)
	var body := JSON.stringify({
		"refreshToken": refresh_token
	})
	var error := _http_request.request("%s/auth/refresh" % GameState.api_base_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_request_kind = ""
		_set_auth_interactable(true)
		_set_logout_button_state(true)
		_set_status(UiText.START_STATUS_LOGOUT_REFRESH_REQUEST_ERROR_FORMAT % error, true)

func _finalize_logout() -> void:
	_logout_dialog_open = false
	_release_network_loading_overlay()
	_cancel_loading_tweens()
	_cancel_bootstrap_retry()
	_clear_pending_login_retry()
	GameState.clear_auth_and_player_state()
	_api_base_url = _resolve_api_base_url()
	_request_in_flight = false
	_request_kind = ""
	_input_ready = false
	_bootstrap_retry_count = 0
	_bootstrap_completed = false
	_loading_animation_finished = false
	_set_auth_interactable(true)
	_set_logout_button_state(true)
	_sync_logout_button_visibility()
	_mode = AuthMode.LOGIN
	_apply_mode()
	if _auth_block != null:
		_auth_block.visible = true
	if _loading_block != null:
		_loading_block.visible = false
		_loading_block.modulate.a = 1.0
	if _tap_hint != null:
		_tap_hint.visible = false
	if _loading_fill != null:
		_loading_fill.size.x = 0.0
	if _loading_percent_label != null:
		_loading_percent_label.text = UiText.START_LOADING_PERCENT_ZERO
	_account_input.text = ""
	_password_input.text = ""
	_confirm_password_input.text = ""
	_display_name_input.text = ""
	_set_status(UiText.START_STATUS_LOGOUT_SUCCESS, false)


func _build_request_headers(access_token: String = "", include_json_content_type: bool = false) -> PackedStringArray:
	var headers := PackedStringArray([
		"Accept: application/json",
		NGROK_SKIP_WARNING_HEADER
	])
	if include_json_content_type:
		headers.append("Content-Type: application/json")
	if access_token != "":
		headers.append("Authorization: Bearer %s" % access_token)
	return headers

func _resolve_api_base_url() -> String:
	return RuntimeConfig.get_api_base_url(DEFAULT_API_BASE_URL)


func _build_device_name() -> String:
	return "%s-%s" % [OS.get_name(), Engine.get_architecture_name()]


func _build_guest_account() -> String:
	var device_hash: String = _device_id.strip_edges().sha256_text().substr(0, 24)
	return "%s%s" % [GUEST_ACCOUNT_PREFIX, device_hash]


func _build_guest_password() -> String:
	var device_hash: String = _device_id.strip_edges().sha256_text()
	return "%s%s%s" % [GUEST_PASSWORD_PREFIX, device_hash, GUEST_PASSWORD_SUFFIX]


func _build_guest_display_name() -> String:
	var device_hash: String = _device_id.strip_edges().sha256_text().substr(0, 6).to_upper()
	return "%s%s" % [GUEST_DISPLAY_NAME_PREFIX, device_hash]


func _load_or_create_device_id() -> String:
	if FileAccess.file_exists(DEVICE_ID_PATH):
		var existing_file := FileAccess.open(DEVICE_ID_PATH, FileAccess.READ)
		if existing_file != null:
			var existing_id := existing_file.get_as_text().strip_edges()
			existing_file.close()
			if existing_id != "":
				return existing_id

	var generated_id := "%s-%s" % [Time.get_unix_time_from_system(), randi()]
	var file := FileAccess.open(DEVICE_ID_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(generated_id)
		file.close()
	return generated_id


func _make_card_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.88, 0.86)
	style.border_color = Color("6d5948")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.24, 0.18, 0.14, 0.22)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 6)
	style.anti_aliasing = false
	style.border_blend = false
	return style


func _make_ribbon_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("98a48c")
	style.border_color = Color("5e6958")
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 14
	style.content_margin_top = 6
	style.content_margin_right = 14
	style.content_margin_bottom = 6
	style.anti_aliasing = false
	style.border_blend = false
	return style


func _make_button_stylebox(fill_color: Color, bottom_depth: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color("6f5847")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = bottom_depth
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 12
	style.content_margin_top = 16
	style.content_margin_right = 12
	style.content_margin_bottom = 16
	style.shadow_color = Color(0.28, 0.21, 0.16, 0.22)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 6)
	style.anti_aliasing = false
	style.border_blend = false
	return style


func _make_progress_track_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d7c5b0")
	style.border_color = Color("7b6554")
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.anti_aliasing = false
	style.border_blend = false
	return style
