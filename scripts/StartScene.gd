extends Control

const HERO_IMAGE := preload("res://assets/sprites/ui/start_scene_homey_v1.png")
const TITLE_TEXT := UiText.START_TITLE
const SUBTITLE_TEXT := UiText.START_SUBTITLE
const TAP_TO_START_TEXT := UiText.START_TAP_TO_START
const CONFIG_PATH := "res://config/runtime_config.json"
const LOCAL_CONFIG_PATH := "res://config/runtime_config.local.json"
const DEVICE_ID_PATH := "user://device_id.txt"
const DEFAULT_ENVIRONMENT := "Local"
const DEFAULT_API_BASE_URL := "http://localhost:5000/api"
const REQUEST_TIMEOUT_SECONDS := 15.0
const BOOTSTRAP_MAX_RETRY_COUNT := 2
const BOOTSTRAP_RETRY_DELAY_SECONDS := 5.0
const BOOTSTRAP_PROGRESS_MAX_PERCENT := 96.0
const BOOTSTRAP_PROGRESS_DURATION_SECONDS := 12.0
const REQUEST_KIND_AUTH := "auth"
const REQUEST_KIND_BOOTSTRAP := "bootstrap"
const REQUEST_KIND_REFRESH := "refresh"
const REQUEST_KIND_LOGOUT_REVOKE := "logout_revoke"
const REQUEST_KIND_LOGOUT_REFRESH := "logout_refresh"

enum AuthMode
{
	LOGIN,
	REGISTER
}

var _api_base_url := DEFAULT_API_BASE_URL
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
var _status_label: Label
var _logout_revoke_retry := false
var _logout_dialog_open := false
var _loading_fill_tween: Tween
var _loading_percent_tween: Tween
var _loading_animation_finished := false
var _bootstrap_completed := false
var _bootstrap_retry_count: int = 0
var _bootstrap_retry_timer: Timer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_api_base_url = _resolve_api_base_url()
	_device_id = _load_or_create_device_id()
	_build_ui()
	_attach_http_request()
	_play_idle_animation()
	_apply_mode()
	if GameState.load_persisted_auth_session():
		_api_base_url = GameState.api_base_url
		_sync_logout_button_visibility()
		_show_loading_state()
		_begin_authenticated_bootstrap(UiText.START_STATUS_BOOTSTRAP_RESTORE)


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = HERO_IMAGE
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


func _build_title_block() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.24
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.24
	panel.position = Vector2(-250, 0)
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
	ribbon.add_theme_font_size_override("font_size", 18)
	ribbon.add_theme_color_override("font_color", Color("f8f3ea"))
	ribbon.add_theme_stylebox_override("normal", _make_ribbon_stylebox())
	content.add_child(ribbon)

	var title := Label.new()
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	title.add_theme_color_override("font_shadow_color", Color("fffdf9"))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = SUBTITLE_TEXT
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color("6a5547"))
	content.add_child(subtitle)

	return panel


func _build_auth_block() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.63
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.63
	panel.position = Vector2(-220, 0)
	panel.custom_minimum_size = Vector2(440, 240)
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
	_form_title.add_theme_font_size_override("font_size", 28)
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
	_primary_button.add_theme_stylebox_override("normal", _make_button_stylebox(Color("9aae8b"), 10))
	_primary_button.add_theme_stylebox_override("hover", _make_button_stylebox(Color("a8bc98"), 10))
	_primary_button.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("869a79"), 8))
	_primary_button.pressed.connect(_on_primary_pressed)
	button_row.add_child(_primary_button)

	_secondary_button = Button.new()
	_secondary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secondary_button.custom_minimum_size = Vector2(0, 54)
	_secondary_button.add_theme_stylebox_override("normal", _make_button_stylebox(Color("d4b593"), 10))
	_secondary_button.add_theme_stylebox_override("hover", _make_button_stylebox(Color("ddc19f"), 10))
	_secondary_button.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("c59f78"), 8))
	_secondary_button.pressed.connect(_on_secondary_pressed)
	button_row.add_child(_secondary_button)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 42)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", Color("7d2f2f"))
	content.add_child(_status_label)

	return panel


func _build_loading_block() -> Control:
	var block := Control.new()
	block.anchor_left = 0.5
	block.anchor_top = 0.80
	block.anchor_right = 0.5
	block.anchor_bottom = 0.80
	block.position = Vector2(-190, 0)
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
	_loading_label.add_theme_font_size_override("font_size", 22)
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
	_loading_percent_label.add_theme_font_size_override("font_size", 18)
	_loading_percent_label.add_theme_color_override("font_color", Color("715b4a"))
	content.add_child(_loading_percent_label)

	return block


func _build_tap_hint() -> Label:
	var hint := Label.new()
	hint.text = TAP_TO_START_TEXT
	hint.anchor_left = 0.5
	hint.anchor_top = 0.84
	hint.anchor_right = 0.5
	hint.anchor_bottom = 0.84
	hint.position = Vector2(-190, 0)
	hint.size = Vector2(380, 36)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color("f7f1e7"))
	hint.add_theme_color_override("font_shadow_color", Color("5e4a3d"))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	return hint


func _build_logout_button() -> Button:
	var button := Button.new()
	button.text = UiText.START_LOGOUT_BUTTON
	button.anchor_left = 1.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.position = Vector2(-140, 28)
	button.custom_minimum_size = Vector2(112, 48)
	button.visible = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_stylebox_override("normal", _make_button_stylebox(Color("d4b593"), 10))
	button.add_theme_stylebox_override("hover", _make_button_stylebox(Color("ddc19f"), 10))
	button.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("c59f78"), 8))
	button.pressed.connect(_on_logout_pressed)
	return button


func _build_paw_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for _i in range(4):
		var paw := Label.new()
		paw.text = "\u25cf"
		paw.add_theme_font_size_override("font_size", 14)
		paw.add_theme_color_override("font_color", Color("9aae8b"))
		row.add_child(paw)
	return row


func _build_input(placeholder: String, secret: bool) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size = Vector2(0, 46)
	input.secret = secret
	input.add_theme_font_size_override("font_size", 18)
	input.text_submitted.connect(_on_input_submitted)
	return input


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
	_form_title.text = UiText.START_FORM_REGISTER if is_register else UiText.START_FORM_LOGIN
	_display_name_input.visible = is_register
	_confirm_password_input.visible = is_register
	_primary_button.text = UiText.START_BUTTON_REGISTER if is_register else UiText.START_BUTTON_LOGIN
	_secondary_button.text = UiText.START_BUTTON_BACK_TO_LOGIN if is_register else UiText.START_BUTTON_REGISTER
	_status_label.text = ""


func _set_auth_interactable(editable: bool) -> void:
	_display_name_input.editable = editable
	_account_input.editable = editable
	_password_input.editable = editable
	_confirm_password_input.editable = editable
	_primary_button.disabled = not editable
	_secondary_button.disabled = not editable


func _on_input_submitted(_text: String) -> void:
	if _mode == AuthMode.LOGIN:
		_submit_login()
	else:
		_submit_register()


func _on_primary_pressed() -> void:
	if _mode == AuthMode.LOGIN:
		_submit_login()
	else:
		_submit_register()


func _on_secondary_pressed() -> void:
	if _request_in_flight:
		return
	_mode = AuthMode.LOGIN if _mode == AuthMode.REGISTER else AuthMode.REGISTER
	_apply_mode()


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
	_set_auth_interactable(false)
	_set_status(UiText.START_STATUS_CONNECTING_SERVER, false)
	_retain_network_loading_overlay(UiText.START_STATUS_CONNECTING_SERVER)

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json"
	])
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
	_set_auth_interactable(false)
	_set_status(UiText.START_STATUS_CONNECTING_SERVER, false)
	_retain_network_loading_overlay(UiText.START_STATUS_CONNECTING_SERVER)

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json"
	])
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
		if completed_request_kind == REQUEST_KIND_AUTH or completed_request_kind == REQUEST_KIND_REFRESH:
			GameState.set_auth_session(_api_base_url, data)
			_api_base_url = GameState.api_base_url
			_sync_logout_button_visibility()
			if completed_request_kind == REQUEST_KIND_AUTH or _loading_block == null or not _loading_block.visible:
				_show_loading_state()
			_begin_authenticated_bootstrap(UiText.START_STATUS_BOOTSTRAP_SYNC)
			return
		if completed_request_kind == REQUEST_KIND_BOOTSTRAP:
			_cancel_bootstrap_retry()
			GameState.apply_player_bootstrap(data)
			_bootstrap_completed = true
			_complete_loading_state()
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

	if completed_request_kind == REQUEST_KIND_BOOTSTRAP:
		_abort_loading_state()
		var bootstrap_message := str(error_payload.get("message", UiText.START_STATUS_BOOTSTRAP_FAILED))
		_set_status(bootstrap_message, true)
		return

	if completed_request_kind == REQUEST_KIND_REFRESH:
		_abort_loading_state()
		GameState.clear_auth_session()
		_api_base_url = _resolve_api_base_url()
		_sync_logout_button_visibility()
		_set_status(UiText.START_STATUS_LOGIN_EXPIRED, true)
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
	_set_status(message, true)


func _handle_request_transport_failure(completed_request_kind: String, result: int) -> void:
	_release_network_loading_overlay()
	if completed_request_kind == REQUEST_KIND_BOOTSTRAP and _is_bootstrap_retryable_result(result):
		if _bootstrap_retry_count < BOOTSTRAP_MAX_RETRY_COUNT:
			_schedule_bootstrap_retry()
			return
	var message := _describe_http_request_result(result)
	if completed_request_kind == REQUEST_KIND_BOOTSTRAP or completed_request_kind == REQUEST_KIND_REFRESH:
		_abort_loading_state()
	elif completed_request_kind == REQUEST_KIND_LOGOUT_REVOKE or completed_request_kind == REQUEST_KIND_LOGOUT_REFRESH:
		_set_logout_button_state(true)
	_logout_dialog_open = false if completed_request_kind.begins_with("logout") else _logout_dialog_open
	_set_status(message, true)


func _handle_request_invalid_response(completed_request_kind: String) -> void:
	_release_network_loading_overlay()
	if completed_request_kind == REQUEST_KIND_BOOTSTRAP or completed_request_kind == REQUEST_KIND_REFRESH:
		_abort_loading_state()
	elif completed_request_kind == REQUEST_KIND_LOGOUT_REVOKE or completed_request_kind == REQUEST_KIND_LOGOUT_REFRESH:
		_set_logout_button_state(true)
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

	var headers := PackedStringArray([
		"Accept: application/json",
		"Authorization: Bearer %s" % access_token
	])
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

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json"
	])
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
	if _bootstrap_completed:
		_complete_loading_state()


func _complete_loading_state() -> void:
	if not _bootstrap_completed or _input_ready:
		return

	_cancel_loading_tweens()
	_input_ready = true
	_sync_logout_button_visibility()
	if _loading_label != null:
		_loading_label.text = UiText.START_LOADING_COMPLETE
	_set_loading_progress_visual(100.0)
	if _loading_block != null:
		var fade_tween := create_tween()
		fade_tween.tween_property(_loading_block, "modulate:a", 0.0, 0.3)
		fade_tween.finished.connect(func():
			if _loading_block != null:
				_loading_block.visible = false
		)
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


func _abort_loading_state() -> void:
	_cancel_loading_tweens()
	_cancel_bootstrap_retry()
	_bootstrap_retry_count = 0
	_bootstrap_completed = false
	_loading_animation_finished = false
	if _auth_block != null:
		_auth_block.visible = true
	if _loading_block != null:
		_loading_block.visible = false
		_loading_block.modulate.a = 1.0
	if _tap_hint != null:
		_tap_hint.visible = false
	_set_loading_progress_visual(0.0)


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
	SceneNavigator.enter_home_shell()


func _input(event: InputEvent) -> void:
	if not _input_ready:
		return
	if _logout_dialog_open:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_event_on_logout_button(event.position):
			return
		_start_game()
	elif event is InputEventScreenTouch and event.pressed:
		if _is_event_on_logout_button(event.position):
			return
		_start_game()


func _set_status(message: String, is_error: bool) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Color("7d2f2f") if is_error else Color("46613d"))


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
		func() -> void: _logout_dialog_open = false
	)

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

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Authorization: Bearer %s" % access_token
	])
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

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json"
	])
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

func _resolve_api_base_url() -> String:
	var config := _load_runtime_config()
	if config.has("api_base_url"):
		return str(config.get("api_base_url", DEFAULT_API_BASE_URL)).rstrip("/")

	var configured_environment = config.get("environment") if config.get("environment") != null else DEFAULT_ENVIRONMENT
	var environment_name := _normalize_environment_name(configured_environment)
	var environments_variant: Variant = config.get("environments", {})
	var environments: Dictionary = environments_variant if environments_variant is Dictionary else {}
	var environment_variant: Variant = environments.get(environment_name, {})
	var environment_config: Dictionary = environment_variant if environment_variant is Dictionary else {}
	var api_base_url = environment_config.get("api_base_url") if environment_config.get("api_base_url") != null else DEFAULT_API_BASE_URL
	return api_base_url.rstrip("/")


func _load_runtime_config() -> Dictionary:
	var local_config := _load_json_config(LOCAL_CONFIG_PATH)
	if not local_config.is_empty():
		return local_config

	return _load_json_config(CONFIG_PATH)


func _load_json_config(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json := JSON.new()
	var content := file.get_as_text()
	file.close()
	if json.parse(content) != OK:
		return {}

	var data: Variant = json.get_data()
	return data if data is Dictionary else {}


func _normalize_environment_name(environment_name: String) -> String:
	var normalized := environment_name.strip_edges()
	if normalized.to_lower() == "dev":
		return "DEV"
	if normalized.to_lower() == "sandbox":
		return "Sandbox"
	if normalized.to_lower() == "production":
		return "Production"
	return "Local"


func _build_device_name() -> String:
	return "%s-%s" % [OS.get_name(), Engine.get_architecture_name()]


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
