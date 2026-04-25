extends Control

const OT := OnboardingUiText

const ONBOARDING_API_PATH := "/onboarding/complete"
const REQUEST_TIMEOUT_SECONDS := 15.0

enum Step { NAME, CAT_PICKER, DIALOGUE, COMPLETE }

# ── UI nodes (built in code) ──
var _background: TextureRect
var _step_dots_row: HBoxContainer
var _content_stack: Control

var _name_panel: PanelContainer
var _name_input: LineEdit
var _name_confirm_btn: Button
var _name_skip_btn: Button
var _name_status: Label

var _picker_panel: PanelContainer
var _picker_grid: HFlowContainer
var _picker_confirm_btn: Button
var _picker_status: Label
var _picker_selected_label: Label

var _dialogue_panel: PanelContainer
var _dialogue_cat_image: TextureRect
var _dialogue_speaker_label: Label
var _dialogue_text_label: Label
var _dialogue_next_btn: Button
var _dialogue_skip_btn: Button

var _complete_panel: PanelContainer
var _complete_start_btn: Button

# ── HTTP ──
var _http: HTTPRequest
var _request_in_flight := false

# ── State ──
var _step: Step = Step.NAME
var _selected_cat_key := ""
var _selected_cat_name := ""
var _player_name_input := ""
var _dialogue_beat_index := 0
var _dialogue_beats: Array = []

var _cat_picker_cards: Dictionary = {}  # cat_key -> Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_dialogue_beats()
	_build_ui()
	_attach_http()
	_apply_step()


# ── Build dialogue beats from text constants ──
func _build_dialogue_beats() -> void:
	var player_name: String = GameState.player_data.player_name \
		if GameState.player_data != null else "你"
	if player_name.strip_edges() == "":
		player_name = GameState.player_data.display_name \
			if GameState.player_data != null else "你"

	var raw_beats := [
		[OT.DIALOGUE_BEAT_NARRATOR_1_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_1_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_2_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_2_TEXT],
		[OT.DIALOGUE_BEAT_CAT_1_SPEAKER,      OT.DIALOGUE_BEAT_CAT_1_TEXT],
		[OT.DIALOGUE_BEAT_PLAYER_1_SPEAKER,   OT.DIALOGUE_BEAT_PLAYER_1_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_3_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_3_TEXT],
		[OT.DIALOGUE_BEAT_CAT_2_SPEAKER,      OT.DIALOGUE_BEAT_CAT_2_TEXT],
		[OT.DIALOGUE_BEAT_PLAYER_2_SPEAKER,   OT.DIALOGUE_BEAT_PLAYER_2_TEXT],
		[OT.DIALOGUE_BEAT_CAT_3_SPEAKER,      OT.DIALOGUE_BEAT_CAT_3_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_4_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_4_TEXT],
		[OT.DIALOGUE_BEAT_CAT_4_SPEAKER,      OT.DIALOGUE_BEAT_CAT_4_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_5_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_5_TEXT],
		[OT.DIALOGUE_BEAT_CAT_5_SPEAKER,      OT.DIALOGUE_BEAT_CAT_5_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_6_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_6_TEXT],
	]

	_dialogue_beats = []
	for raw: Array in raw_beats:
		var speaker: String = str(raw[0])
		var text: String = str(raw[1])
		speaker = speaker.replace("{cat_name}", _selected_cat_name) \
			.replace("{player_name}", player_name)
		text = text.replace("{cat_name}", _selected_cat_name) \
			.replace("{player_name}", player_name)
		_dialogue_beats.append({"speaker": speaker, "text": text})


# ── UI construction ──
func _build_ui() -> void:
	_background = TextureRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.texture = preload("res://assets/sprites/ui/start_scene_homey_v1.png")
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_background)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.06, 0.04, 0.45)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_content_stack = Control.new()
	_content_stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_content_stack)

	_step_dots_row = _build_step_dots()
	_content_stack.add_child(_step_dots_row)

	_name_panel = _build_name_panel()
	_content_stack.add_child(_name_panel)

	_picker_panel = _build_picker_panel()
	_content_stack.add_child(_picker_panel)

	_dialogue_panel = _build_dialogue_panel()
	_content_stack.add_child(_dialogue_panel)

	_complete_panel = _build_complete_panel()
	_content_stack.add_child(_complete_panel)


func _build_step_dots() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.anchor_left = 0.5
	row.anchor_top = 0.06
	row.anchor_right = 0.5
	row.anchor_bottom = 0.06
	row.position = Vector2(-40, 0)
	row.custom_minimum_size = Vector2(80, 32)
	for i in range(3):
		var dot := Label.new()
		dot.text = OT.STEP_DOT_INACTIVE
		UiFonts.apply_noto(dot, 18)
		dot.add_theme_color_override("font_color", Color("f0e8dc"))
		row.add_child(dot)
	return row


func _refresh_step_dots() -> void:
	if _step_dots_row == null:
		return
	var current_dot_index := int(_step)
	for i in range(_step_dots_row.get_child_count()):
		var dot: Label = _step_dots_row.get_child(i)
		dot.text = OT.STEP_DOT_ACTIVE if i == current_dot_index else OT.STEP_DOT_INACTIVE
		dot.add_theme_color_override("font_color",
			Color("f9e97a") if i == current_dot_index else Color("f0e8dc"))


func _build_name_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-230, -130)
	panel.custom_minimum_size = Vector2(460, 260)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := _make_margin_container()
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = OT.NAME_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(title, UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = OT.NAME_HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(hint, UiPalette.FONT_SIZE_BODY)
	hint.add_theme_color_override("font_color", Color("7a6655"))
	vbox.add_child(hint)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = OT.NAME_PLACEHOLDER
	_name_input.custom_minimum_size = Vector2(0, 48)
	_name_input.text = _get_default_player_name()
	UiFonts.apply_noto(_name_input, UiPalette.FONT_SIZE_BODY_LG)
	_name_input.text_submitted.connect(_on_name_submitted)
	vbox.add_child(_name_input)

	_name_status = Label.new()
	_name_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_status.custom_minimum_size = Vector2(0, 28)
	UiFonts.apply_noto(_name_status, 14)
	_name_status.add_theme_color_override("font_color", Color("8b2e2e"))
	vbox.add_child(_name_status)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	_name_skip_btn = _make_button(OT.NAME_SKIP, Color("bbb0a0"), Color("ccc0b0"), Color("aaa090"))
	_name_skip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_skip_btn.pressed.connect(_on_name_skip_pressed)
	btn_row.add_child(_name_skip_btn)

	_name_confirm_btn = _make_button(OT.NAME_CONFIRM, Color("9aae8b"), Color("a8bc98"), Color("869a79"))
	_name_confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_confirm_btn.pressed.connect(_on_name_confirm_pressed)
	btn_row.add_child(_name_confirm_btn)

	return panel


func _build_picker_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-300, -200)
	panel.custom_minimum_size = Vector2(600, 400)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := _make_margin_container()
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = OT.CAT_PICKER_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(title, UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = OT.CAT_PICKER_SUBTITLE
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(subtitle, UiPalette.FONT_SIZE_BODY)
	subtitle.add_theme_color_override("font_color", Color("7a6655"))
	vbox.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_picker_grid = HFlowContainer.new()
	_picker_grid.add_theme_constant_override("h_separation", 12)
	_picker_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_picker_grid)

	_populate_cat_picker()

	_picker_selected_label = Label.new()
	_picker_selected_label.text = OT.CAT_PICKER_HINT
	_picker_selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(_picker_selected_label, 14)
	_picker_selected_label.add_theme_color_override("font_color", Color("7a6655"))
	vbox.add_child(_picker_selected_label)

	_picker_status = Label.new()
	_picker_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_picker_status.custom_minimum_size = Vector2(0, 24)
	UiFonts.apply_noto(_picker_status, 14)
	_picker_status.add_theme_color_override("font_color", Color("8b2e2e"))
	vbox.add_child(_picker_status)

	_picker_confirm_btn = _make_button(OT.CAT_PICKER_CONFIRM, Color("9aae8b"), Color("a8bc98"), Color("869a79"))
	_picker_confirm_btn.disabled = true
	_picker_confirm_btn.pressed.connect(_on_picker_confirm_pressed)
	vbox.add_child(_picker_confirm_btn)

	return panel


func _populate_cat_picker() -> void:
	if _picker_grid == null:
		return
	for child in _picker_grid.get_children():
		child.queue_free()
	_cat_picker_cards = {}

	for item_variant: Variant in GameState.cat_catalog:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var cat_key: String = str(item.get("id", ""))
		var display_name: String = str(item.get("display_name", cat_key))
		if cat_key == "":
			continue

		var card := _build_cat_card(cat_key, display_name)
		_picker_grid.add_child(card)
		_cat_picker_cards[cat_key] = card


func _build_cat_card(cat_key: String, display_name: String) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(110, 140)
	btn.add_theme_stylebox_override("normal", _make_button_stylebox(Color("f0e8d8"), 6))
	btn.add_theme_stylebox_override("hover", _make_button_stylebox(Color("f8f0e0"), 6))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("d8c8b0"), 4))
	btn.pressed.connect(_on_cat_card_pressed.bind(cat_key, display_name))

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var icon_texture: Texture2D = AssetResolver.resolve_cat_icon(cat_key)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = icon_texture
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(name_label, 13)
	name_label.add_theme_color_override("font_color", Color("4f3d31"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	return btn


func _build_dialogue_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-260, -210)
	panel.custom_minimum_size = Vector2(520, 420)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := _make_margin_container()
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_dialogue_cat_image = TextureRect.new()
	_dialogue_cat_image.custom_minimum_size = Vector2(160, 160)
	_dialogue_cat_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_cat_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_cat_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dialogue_cat_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_dialogue_cat_image)

	_dialogue_speaker_label = Label.new()
	_dialogue_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(_dialogue_speaker_label, UiPalette.FONT_SIZE_SUBHEADING)
	_dialogue_speaker_label.add_theme_color_override("font_color", Color("c47c30"))
	vbox.add_child(_dialogue_speaker_label)

	var text_frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.96, 0.93, 0.88, 0.72)
	frame_style.corner_radius_top_left = 8
	frame_style.corner_radius_top_right = 8
	frame_style.corner_radius_bottom_right = 8
	frame_style.corner_radius_bottom_left = 8
	frame_style.content_margin_left = 16
	frame_style.content_margin_top = 12
	frame_style.content_margin_right = 16
	frame_style.content_margin_bottom = 12
	text_frame.add_theme_stylebox_override("panel", frame_style)
	text_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(text_frame)

	_dialogue_text_label = Label.new()
	_dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiFonts.apply_noto(_dialogue_text_label, UiPalette.FONT_SIZE_BODY_LG)
	_dialogue_text_label.add_theme_color_override("font_color", Color("3d2f20"))
	text_frame.add_child(_dialogue_text_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	_dialogue_skip_btn = _make_button(OT.DIALOGUE_SKIP, Color("bbb0a0"), Color("ccc0b0"), Color("aaa090"))
	_dialogue_skip_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_dialogue_skip_btn.pressed.connect(_on_dialogue_skip_pressed)
	btn_row.add_child(_dialogue_skip_btn)

	_dialogue_next_btn = _make_button(OT.DIALOGUE_NEXT, Color("9aae8b"), Color("a8bc98"), Color("869a79"))
	_dialogue_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_next_btn.pressed.connect(_on_dialogue_next_pressed)
	btn_row.add_child(_dialogue_next_btn)

	return panel


func _build_complete_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-220, -120)
	panel.custom_minimum_size = Vector2(440, 240)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := _make_margin_container()
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = OT.COMPLETE_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(title, UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	vbox.add_child(title)

	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(sub, UiPalette.FONT_SIZE_BODY_LG)
	sub.add_theme_color_override("font_color", Color("7a6655"))
	var player_name: String = GameState.player_data.player_name \
		if GameState.player_data != null else ""
	if player_name.strip_edges() == "":
		player_name = GameState.player_data.display_name \
			if GameState.player_data != null else "鏟屎官"
	sub.text = OT.COMPLETE_SUBTITLE_FORMAT % [player_name, _selected_cat_name]
	vbox.add_child(sub)

	_complete_start_btn = _make_button(OT.COMPLETE_BUTTON, Color("9aae8b"), Color("a8bc98"), Color("869a79"))
	_complete_start_btn.custom_minimum_size = Vector2(0, 56)
	_complete_start_btn.pressed.connect(_on_complete_start_pressed)
	vbox.add_child(_complete_start_btn)

	return panel


# ── Step transitions ──
func _apply_step() -> void:
	_refresh_step_dots()
	_name_panel.visible = _step == Step.NAME
	_picker_panel.visible = _step == Step.CAT_PICKER
	_dialogue_panel.visible = _step == Step.DIALOGUE
	_complete_panel.visible = _step == Step.COMPLETE

	if _step == Step.DIALOGUE:
		_apply_dialogue_beat()


func _go_to_step(step: Step) -> void:
	_step = step
	_apply_step()


# ── Name step handlers ──
func _on_name_submitted(_text: String) -> void:
	_on_name_confirm_pressed()


func _on_name_confirm_pressed() -> void:
	var name_text: String = _name_input.text.strip_edges()
	if name_text == "":
		_name_status.text = OT.NAME_ERROR_EMPTY
		return
	_player_name_input = name_text
	_name_status.text = ""
	_go_to_step(Step.CAT_PICKER)


func _on_name_skip_pressed() -> void:
	_player_name_input = ""
	_go_to_step(Step.CAT_PICKER)


func _get_default_player_name() -> String:
	if GameState.player_data == null:
		return ""
	var name: String = GameState.player_data.player_name
	if name.strip_edges() == "":
		name = GameState.player_data.display_name
	return name


# ── Cat picker step handlers ──
func _on_cat_card_pressed(cat_key: String, display_name: String) -> void:
	_selected_cat_key = cat_key
	_selected_cat_name = display_name
	_picker_selected_label.text = OT.CAT_PICKER_SELECTED_FORMAT % display_name
	_picker_confirm_btn.disabled = false
	_picker_status.text = ""

	for key: String in _cat_picker_cards:
		var card: Control = _cat_picker_cards[key]
		var is_selected := key == cat_key
		var fill_color: Color = Color("d4e8c8") if is_selected else Color("f0e8d8")
		card.add_theme_stylebox_override("normal", _make_button_stylebox(fill_color, 6))


func _on_picker_confirm_pressed() -> void:
	if _selected_cat_key == "" or _request_in_flight:
		return
	_submit_onboarding()


func _submit_onboarding() -> void:
	_request_in_flight = true
	_picker_confirm_btn.disabled = true
	_picker_status.text = OT.CAT_PICKER_LOADING

	var access_token: String = GameState.get_access_token()
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Authorization: Bearer %s" % access_token,
	])

	var body_dict: Dictionary = {"catKey": _selected_cat_key}
	if _player_name_input.strip_edges() != "":
		body_dict["playerName"] = _player_name_input.strip_edges()

	var body: String = JSON.stringify(body_dict)
	var url: String = "%s%s" % [GameState.api_base_url, ONBOARDING_API_PATH]
	var error: int = _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_picker_confirm_btn.disabled = false
		_picker_status.text = OT.CAT_PICKER_ERROR


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_request_in_flight = false
	_picker_confirm_btn.disabled = false

	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_picker_status.text = OT.CAT_PICKER_ERROR
		return

	var response_text: String = body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(response_text) != OK:
		_picker_status.text = OT.CAT_PICKER_ERROR
		return

	var payload: Variant = json.get_data()
	if not (payload is Dictionary):
		_picker_status.text = OT.CAT_PICKER_ERROR
		return

	var success: bool = bool((payload as Dictionary).get("success", false))
	if not success:
		var error_variant: Variant = (payload as Dictionary).get("error", {})
		var error_dict: Dictionary = error_variant if error_variant is Dictionary else {}
		_picker_status.text = str(error_dict.get("message", OT.CAT_PICKER_ERROR))
		return

	_picker_status.text = ""
	GameState.is_new_player = false
	_build_dialogue_beats()
	_dialogue_beat_index = 0
	_update_cat_dialogue_image()
	_go_to_step(Step.DIALOGUE)


# ── Dialogue step handlers ──
func _apply_dialogue_beat() -> void:
	if _dialogue_beat_index >= _dialogue_beats.size():
		_go_to_step(Step.COMPLETE)
		return

	var beat: Dictionary = _dialogue_beats[_dialogue_beat_index]
	var speaker: String = str(beat.get("speaker", ""))
	var text: String = str(beat.get("text", ""))

	_dialogue_speaker_label.text = speaker
	_dialogue_speaker_label.visible = speaker != ""
	_dialogue_text_label.text = text

	var is_cat_speaking: bool = speaker == _selected_cat_name
	_dialogue_cat_image.visible = is_cat_speaking

	var is_last_beat: bool = _dialogue_beat_index >= _dialogue_beats.size() - 1
	_dialogue_next_btn.text = OT.DIALOGUE_START if is_last_beat else OT.DIALOGUE_NEXT


func _update_cat_dialogue_image() -> void:
	if _dialogue_cat_image == null:
		return
	_dialogue_cat_image.texture = AssetResolver.resolve_cat_showcase_art(_selected_cat_key)


func _on_dialogue_next_pressed() -> void:
	_dialogue_beat_index += 1
	if _dialogue_beat_index >= _dialogue_beats.size():
		_go_to_step(Step.COMPLETE)
	else:
		_apply_dialogue_beat()


func _on_dialogue_skip_pressed() -> void:
	_go_to_step(Step.COMPLETE)


# ── Complete step handler ──
func _on_complete_start_pressed() -> void:
	SceneNavigator.enter_home_shell()


# ── HTTP setup ──
func _attach_http() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	_http.request_completed.connect(_on_http_request_completed)
	add_child(_http)


# ── Style helpers (same theme as StartScene) ──
func _make_card_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.88, 0.90)
	style.border_color = Color("6d5948")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0.24, 0.18, 0.14, 0.28)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 8)
	style.anti_aliasing = false
	style.border_blend = false
	return style


func _make_margin_container() -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_bottom", 20)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	return m


func _make_button(label: String, normal: Color, hover: Color, pressed: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 50)
	UiFonts.apply_noto(btn, UiPalette.FONT_SIZE_BODY_LG)
	btn.add_theme_color_override("font_color", Color("fff8f2"))
	btn.add_theme_color_override("font_hover_color", Color("fff8f2"))
	btn.add_theme_color_override("font_pressed_color", Color("fff8f2"))
	btn.add_theme_stylebox_override("normal", _make_button_stylebox(normal, 8))
	btn.add_theme_stylebox_override("hover", _make_button_stylebox(hover, 8))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(pressed, 6))
	return btn


func _make_button_stylebox(fill_color: Color, bottom_depth: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color("6f5847")
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = bottom_depth
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 10
	style.content_margin_top = 12
	style.content_margin_right = 10
	style.content_margin_bottom = 12
	style.anti_aliasing = false
	style.border_blend = false
	return style
