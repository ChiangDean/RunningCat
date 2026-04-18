extends Control

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const InertialScroller = preload("res://scripts/ui/inertial_scroll.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const ADMIN_CATALOG_SCENE_PATH := "res://scenes/AdminCatalogScene.tscn"

const MUTED_TEXT_COLOR := Color(0.90, 0.88, 0.82, 0.92)
const SECTION_HINT_COLOR := Color(0.84, 0.80, 0.72, 0.88)
const FIELD_BG := Color(0.14, 0.12, 0.11, 0.98)
const FIELD_BORDER := Color(0.42, 0.36, 0.26, 0.96)
const SELECTED_BORDER := Color(0.92, 0.79, 0.44, 1.0)
const UNSELECTED_BORDER := Color(0.42, 0.36, 0.26, 0.96)
const GENDER_OPTIONS := [
	{"label": "?????, "value": "Unspecified"},
	{"label": "??鞎???, "value": "Male"},
	{"label": "?鞈察????, "value": "Female"},
	{"label": "?????, "value": "NonBinary"},
	{"label": "?鞊??????", "value": "PreferNotToSay"},
]

var _profile_dirty: bool = false
var _profile_loading: bool = false
var _profile_saving: bool = false
var _redeem_in_flight: bool = false
var _applying_profile_form: bool = false
var _selected_avatar_id: String = AssetResolver.DEFAULT_PROFILE_AVATAR_ID

var _avatar_preview: TextureRect
var _avatar_name_label: Label
var _avatar_buttons: Dictionary = {}
var _display_name_input: LineEdit
var _player_name_input: LineEdit
var _bio_input: TextEdit
var _birthday_input: LineEdit
var _gender_option: OptionButton
var _region_input: LineEdit
var _save_profile_button: Button
var _save_profile_hint_label: Label
var _account_value_label: LineEdit
var _player_uid_value_label: LineEdit
var _provider_status_labels: Dictionary = {}
var _redeem_input: LineEdit
var _redeem_button: Button
var _audio_value_labels: Dictionary = {}
var _audio_sliders: Dictionary = {}
var _audio_mute_boxes: Dictionary = {}
var _active_section: String = "profile"
var _submenu_buttons: Dictionary = {}
var _section_content: VBoxContainer
var _section_scroll: ScrollContainer


func _ready() -> void:
	_build_ui()
	_apply_profile_data(_build_local_profile_snapshot())
	_apply_audio_settings()
	_load_profile_from_api()


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "config", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": _build_section_items(),
		"active_key": _active_section,
		"button_pressed": Callable(self, "_on_section_selected"),
		"content_separation": 12,
	})
	var content_box: VBoxContainer = chrome.get("content_box") as VBoxContainer
	_submenu_buttons = chrome.get("dock_buttons", {})

	var title: Label = Label.new()
	title.text = "\u8a2d\u5b9a\u4e2d\u5fc3"
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	content_box.add_child(title)


	_section_scroll = ScrollContainer.new()
	_section_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_section_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_section_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_box.add_child(_section_scroll)
	InertialScroller.attach(_section_scroll, "vertical")

	_section_content = VBoxContainer.new()
	_section_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_content.add_theme_constant_override("separation", 12)
	_section_scroll.add_child(_section_content)

	_render_active_section()


func _build_section_items() -> Array:
	var items: Array = [
		{"key": "profile", "label": "\u89d2\u8272\u8cc7\u6599"},
		{"key": "account", "label": "\u5e33\u865f\u8cc7\u6599"},
		{"key": "game", "label": "\u904a\u6232\u8a2d\u5b9a"},
	]
	if GameState.is_admin_session():
		items.append({"key": "admin", "label": "Admin Catalog"})
	return items


func _on_section_selected(section_key: String) -> void:
	if section_key == _active_section:
		return
	_active_section = section_key
	_render_active_section()


func _render_active_section() -> void:
	if _section_content == null:
		return
	_clear_section_control_refs()
	for child: Node in _section_content.get_children():
		child.queue_free()

	match _active_section:
		"account":
			_section_content.add_child(_build_account_section())
		"game":
			_section_content.add_child(_build_game_settings_section())
		"admin":
			if GameState.is_admin_session():
				_section_content.add_child(_build_admin_section())
			else:
				_active_section = "profile"
				_section_content.add_child(_build_profile_section())
		_:
			_section_content.add_child(_build_profile_section())

	_refresh_submenu_buttons()
	_apply_profile_data(_build_local_profile_snapshot())
	_apply_audio_settings()
	if is_instance_valid(_section_scroll):
		_section_scroll.scroll_vertical = 0


func _refresh_submenu_buttons() -> void:
	SceneSubmenuBar.refresh(_submenu_buttons, _active_section)


func _clear_section_control_refs() -> void:
	_avatar_preview = null
	_avatar_name_label = null
	_avatar_buttons = {}
	_display_name_input = null
	_player_name_input = null
	_bio_input = null
	_birthday_input = null
	_gender_option = null
	_region_input = null
	_save_profile_button = null
	_save_profile_hint_label = null
	_account_value_label = null
	_player_uid_value_label = null
	_provider_status_labels = {}
	_redeem_input = null
	_redeem_button = null
	_audio_value_labels = {}
	_audio_sliders = {}
	_audio_mute_boxes = {}


func _build_profile_section() -> Control:
	var section: PanelContainer = OverlaySceneChrome.make_card_panel()
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_section_header("????????", "?????????????????????????拆???鞊?????????????))

	var avatar_row: HBoxContainer = HBoxContainer.new()
	avatar_row.add_theme_constant_override("separation", 14)
	column.add_child(avatar_row)

	var preview_panel: PanelContainer = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(156.0, 184.0)
	preview_panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 16))
	avatar_row.add_child(preview_panel)

	var preview_margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	preview_panel.add_child(preview_margin)

	var preview_box: VBoxContainer = VBoxContainer.new()
	preview_box.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_box.add_theme_constant_override("separation", 8)
	preview_margin.add_child(preview_box)

	_avatar_preview = TextureRect.new()
	_avatar_preview.custom_minimum_size = Vector2(108.0, 108.0)
	_avatar_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_avatar_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_box.add_child(_avatar_preview)

	_avatar_name_label = Label.new()
	_avatar_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	preview_box.add_child(_avatar_name_label)

	var avatar_picker_shell: VBoxContainer = VBoxContainer.new()
	avatar_picker_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avatar_picker_shell.add_theme_constant_override("separation", 8)
	avatar_row.add_child(avatar_picker_shell)

	var avatar_hint: Label = Label.new()
	avatar_hint.text = "???????????"
	avatar_hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	avatar_picker_shell.add_child(avatar_hint)

	var avatar_grid: GridContainer = GridContainer.new()
	avatar_grid.columns = 3
	avatar_grid.add_theme_constant_override("h_separation", 8)
	avatar_grid.add_theme_constant_override("v_separation", 8)
	avatar_picker_shell.add_child(avatar_grid)

	for avatar_id: String in AssetResolver.get_profile_avatar_ids():
		avatar_grid.add_child(_build_avatar_card(avatar_id))

	_player_name_input = _make_line_edit("????????????)
	_birthday_input = _make_line_edit("YYYY-MM-DD")
	_region_input = _make_line_edit("?雓???雓撥????/ Kaohsiung")

	_bio_input = TextEdit.new()
	_bio_input.custom_minimum_size = Vector2(0.0, 112.0)
	_bio_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_bio_input.add_theme_stylebox_override("normal", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 12))

	_gender_option = OptionButton.new()
	_gender_option.custom_minimum_size = Vector2(0.0, 48.0)
	for option: Dictionary in GENDER_OPTIONS:
		_gender_option.add_item(str(option.get("label", "")))

	column.add_child(_build_field_row("??????雓?", _player_name_input))
	column.add_child(_build_field_row("???", _bio_input))
	column.add_child(_build_field_row("???蝮?", _birthday_input))
	column.add_child(_build_field_row("????", _gender_option))
	column.add_child(_build_field_row("???", _region_input))

	var save_row: HBoxContainer = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 12)
	column.add_child(save_row)

	_save_profile_button = Button.new()
	_save_profile_button.text = "???????????"
	_save_profile_button.custom_minimum_size = Vector2(220.0, 50.0)
	UiPalette.apply_button_kind(_save_profile_button, "confirm")
	_save_profile_button.pressed.connect(UiAudio.play_ui_click)
	_save_profile_button.pressed.connect(_on_save_profile_pressed)
	save_row.add_child(_save_profile_button)

	_save_profile_hint_label = Label.new()
	_save_profile_hint_label.text = "????????????蝘?????
	_save_profile_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_profile_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_save_profile_hint_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_save_profile_hint_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	save_row.add_child(_save_profile_hint_label)

	_bind_profile_edit_events()
	_refresh_avatar_selection()
	_refresh_profile_save_state()
	return section


func _build_account_section() -> Control:
	var section: PanelContainer = OverlaySceneChrome.make_card_panel()
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_section_header("????????", "???????怏???????????OAuth ??????????????????鞈ㄜ???))

	_account_value_label = _make_readonly_value("?雓丐?????)
	_player_uid_value_label = _make_readonly_value("?雓丐?????)
	column.add_child(_build_field_row("????", _account_value_label))
	column.add_child(_build_field_row("Player UID", _player_uid_value_label))

	var provider_row: HBoxContainer = HBoxContainer.new()
	provider_row.add_theme_constant_override("separation", 10)
	column.add_child(provider_row)

	provider_row.add_child(_build_provider_card("Google"))
	provider_row.add_child(_build_provider_card("Apple"))

	var redeem_title: Label = Label.new()
	redeem_title.text = "?????
	redeem_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	column.add_child(redeem_title)

	var redeem_hint: Label = Label.new()
	redeem_hint.text = "?雓???????????????????????????
	redeem_hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	redeem_hint.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	column.add_child(redeem_hint)

	var redeem_row: HBoxContainer = HBoxContainer.new()
	redeem_row.add_theme_constant_override("separation", 10)
	column.add_child(redeem_row)

	_redeem_input = _make_line_edit("?????????偃???)
	_redeem_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	redeem_row.add_child(_redeem_input)

	_redeem_button = Button.new()
	_redeem_button.text = "???"
	_redeem_button.custom_minimum_size = Vector2(132.0, 48.0)
	UiPalette.apply_button_kind(_redeem_button, "confirm")
	_redeem_button.pressed.connect(UiAudio.play_ui_click)
	_redeem_button.pressed.connect(_on_redeem_pressed)
	redeem_row.add_child(_redeem_button)

	return section


func _build_game_settings_section() -> Control:
	var section: PanelContainer = OverlaySceneChrome.make_card_panel()
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_section_header("??頩???Ⅹ??", "?????Ⅹ?????????佇?憯??????謚???鞊???????????????))

	column.add_child(_build_audio_row("master", "???瘀賊???))
	column.add_child(_build_audio_row("bgm", "???????"))
	column.add_child(_build_audio_row("sfx", "???"))

	return section


func _build_admin_catalog_row() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 12))

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	var title: Label = Label.new()
	title.text = "Admin Catalog"
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	text_box.add_child(title)

	var hint: Label = Label.new()
	hint.text = "Every visit re-validates admin access before loading catalog settings."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	hint.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	text_box.add_child(hint)

	var button: Button = Button.new()
	button.text = "Open"
	button.custom_minimum_size = Vector2(160.0, 46.0)
	UiPalette.apply_button_kind(button, "confirm")
	button.pressed.connect(UiAudio.play_ui_click)
	button.pressed.connect(func() -> void:
		SceneNavigator.open_overlay_scene(ADMIN_CATALOG_SCENE_PATH)
	)
	row.add_child(button)

	return panel


func _build_admin_section() -> Control:
	var section: PanelContainer = OverlaySceneChrome.make_card_panel()
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_section_header("Admin Catalog", "??? Admin ?????????????????????????????橫???祈???鞊??謅?鞊堊??鞊啣???))
	column.add_child(_build_admin_catalog_row())
	return section


func _build_avatar_card(avatar_id: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 96.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(8)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(54.0, 54.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = AssetResolver.resolve_profile_avatar(avatar_id)
	box.add_child(icon)

	var label: Label = Label.new()
	label.text = AssetResolver.get_profile_avatar_label(avatar_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	box.add_child(label)

	var button: Button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(UiAudio.play_ui_click)
	button.pressed.connect(func() -> void:
		_selected_avatar_id = avatar_id
		_mark_profile_dirty()
		_refresh_avatar_selection()
	)
	panel.add_child(button)

	_avatar_buttons[avatar_id] = {"panel": panel, "label": label}
	return panel


func _build_provider_card(provider_name: String) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(FIELD_BORDER, FIELD_BG, 12)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title: Label = Label.new()
	title.text = provider_name
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	column.add_child(title)

	var status_label: Label = Label.new()
	status_label.text = "?????鞊?"
	status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	status_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	column.add_child(status_label)
	_provider_status_labels[provider_name] = status_label

	var action_button: Button = Button.new()
	action_button.text = "?????鞊?"
	action_button.disabled = true
	action_button.custom_minimum_size = Vector2(0.0, 42.0)
	UiPalette.apply_button_palette(action_button, Color(0.24, 0.21, 0.18, 0.86), Color(0.72, 0.69, 0.64, 1.0))
	column.add_child(action_button)

	return panel


func _build_audio_row(bus_key: String, label_text: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 12))

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(110.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	row.add_child(label)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		_on_audio_slider_changed(bus_key, value)
	)
	row.add_child(slider)
	_audio_sliders[bus_key] = slider

	var value_label: Label = Label.new()
	value_label.custom_minimum_size = Vector2(56.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	row.add_child(value_label)
	_audio_value_labels[bus_key] = value_label

	var mute_box: CheckBox = CheckBox.new()
	mute_box.text = "??垮??"
	mute_box.toggled.connect(func(pressed: bool) -> void:
		_on_audio_mute_toggled(bus_key, pressed)
	)
	row.add_child(mute_box)
	_audio_mute_boxes[bus_key] = mute_box

	return panel


func _make_section_header(title_text: String, subtitle_text: String) -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)

	var title: Label = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	column.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	subtitle.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	column.add_child(subtitle)

	return column


func _build_field_row(label_text: String, field: Control) -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	column.add_child(label)

	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(field)
	return column


func _make_line_edit(placeholder_text: String) -> LineEdit:
	var input: LineEdit = LineEdit.new()
	input.custom_minimum_size = Vector2(0.0, 48.0)
	input.placeholder_text = placeholder_text
	input.add_theme_stylebox_override("normal", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 12))
	return input


func _make_readonly_value(text: String) -> LineEdit:
	var input: LineEdit = LineEdit.new()
	input.text = text
	input.editable = false
	input.custom_minimum_size = Vector2(0.0, 42.0)
	input.add_theme_stylebox_override("normal", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 12))
	return input


func _bind_profile_edit_events() -> void:
	_player_name_input.text_changed.connect(func(_value: String) -> void:
		_mark_profile_dirty()
	)
	_birthday_input.text_changed.connect(func(_value: String) -> void:
		_mark_profile_dirty()
	)
	_region_input.text_changed.connect(func(_value: String) -> void:
		_mark_profile_dirty()
	)
	_bio_input.text_changed.connect(_mark_profile_dirty)
	_gender_option.item_selected.connect(func(_index: int) -> void:
		_mark_profile_dirty()
	)


func _load_profile_from_api() -> void:
	_profile_loading = true
	_refresh_profile_save_state()
	ApiClient.get_profile_me(func(success: bool, data: Variant, error: Dictionary) -> void:
		_profile_loading = false
		_refresh_profile_save_state()
		if not success:
			ToastManager.hint("??Ⅹ?????????????散??", str(error.get("message", "???怏???謘?????蹎????????????)))
			return

		if data is Dictionary:
			var profile: Dictionary = data as Dictionary
			GameState.apply_profile_response(profile)
			_apply_profile_data(profile)
	)


func _apply_profile_data(data: Dictionary) -> void:
	_applying_profile_form = true
	_selected_avatar_id = str(data.get("avatarId", AssetResolver.DEFAULT_PROFILE_AVATAR_ID)).strip_edges()
	if _selected_avatar_id == "":
		_selected_avatar_id = AssetResolver.DEFAULT_PROFILE_AVATAR_ID

	if is_instance_valid(_display_name_input):
		_display_name_input.text = str(data.get("displayName", ""))
	if is_instance_valid(_player_name_input):
		_player_name_input.text = str(data.get("playerName", ""))
	if is_instance_valid(_bio_input):
		_bio_input.text = str(data.get("bio", ""))
	if is_instance_valid(_birthday_input):
		_birthday_input.text = str(data.get("birthday", ""))
	if is_instance_valid(_region_input):
		_region_input.text = str(data.get("region", ""))
	if is_instance_valid(_gender_option):
		_set_gender_value(str(data.get("genderType", "Unspecified")))
	if is_instance_valid(_account_value_label):
		_account_value_label.text = str(data.get("account", ""))
	if is_instance_valid(_player_uid_value_label):
		_player_uid_value_label.text = str(data.get("playerPublicId", ""))
	_refresh_provider_cards(data.get("linkedProviders", []))
	_applying_profile_form = false
	_profile_dirty = false
	_refresh_avatar_selection()
	_refresh_profile_save_state()


func _apply_audio_settings() -> void:
	var settings: Dictionary = ClientSettings.get_settings()
	for bus_key: String in ["master", "bgm", "sfx"]:
		var slider: HSlider = _audio_sliders.get(bus_key) as HSlider
		var mute_box: CheckBox = _audio_mute_boxes.get(bus_key) as CheckBox
		if is_instance_valid(slider):
			slider.value = float(settings.get("%sVolume" % bus_key, 1.0))
		if is_instance_valid(mute_box):
			mute_box.button_pressed = bool(settings.get("%sMuted" % bus_key, false))
		_refresh_audio_value_label(bus_key)


func _build_local_profile_snapshot() -> Dictionary:
	var player = GameState.player_data
	return {
		"account": player.account,
		"displayName": player.display_name,
		"playerPublicId": player.player_public_id,
		"playerName": player.player_name,
		"avatarId": player.avatar_id,
		"bio": player.bio,
		"birthday": player.birthday,
		"genderType": player.gender_type,
		"region": player.region,
		"linkedProviders": player.linked_providers.duplicate(),
	}


func _refresh_avatar_selection() -> void:
	if not is_instance_valid(_avatar_preview) or not is_instance_valid(_avatar_name_label):
		return
	_avatar_preview.texture = AssetResolver.resolve_profile_avatar(_selected_avatar_id)
	_avatar_name_label.text = AssetResolver.get_profile_avatar_label(_selected_avatar_id)
	for avatar_id: String in _avatar_buttons.keys():
		var refs: Dictionary = _avatar_buttons.get(avatar_id, {})
		var panel: PanelContainer = refs.get("panel") as PanelContainer
		var label: Label = refs.get("label") as Label
		if not is_instance_valid(panel) or not is_instance_valid(label):
			continue
		var is_selected: bool = avatar_id == _selected_avatar_id
		panel.add_theme_stylebox_override(
			"panel",
			OverlaySceneChrome.make_panel_style(
				FIELD_BG if not is_selected else Color(0.22, 0.17, 0.10, 0.98),
				SELECTED_BORDER if is_selected else UNSELECTED_BORDER,
				14
			)
		)
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.84, 1.0) if is_selected else MUTED_TEXT_COLOR)


func _refresh_provider_cards(linked_providers_variant: Variant) -> void:
	var linked: Array = linked_providers_variant if linked_providers_variant is Array else []
	for provider_name: String in _provider_status_labels.keys():
		var status_label: Label = _provider_status_labels.get(provider_name) as Label
		if not is_instance_valid(status_label):
			continue
		if linked.has(provider_name):
			status_label.text = "??頦????
			status_label.add_theme_color_override("font_color", Color(0.72, 0.94, 0.72, 1.0))
		else:
			status_label.text = "?????鞊?"
			status_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)


func _refresh_profile_save_state() -> void:
	if not is_instance_valid(_save_profile_button):
		return
	_save_profile_button.disabled = _profile_loading or _profile_saving or not _profile_dirty
	if _profile_saving:
		_save_profile_button.text = "?????.."
	elif _profile_loading:
		_save_profile_button.text = "?雓丐?????.."
	else:
		_save_profile_button.text = "???????????"

	if not is_instance_valid(_save_profile_hint_label):
		return
	if _profile_saving:
		_save_profile_hint_label.text = "???????????????..."
	elif _profile_dirty:
		_save_profile_hint_label.text = "???撕??????????????
	else:
		_save_profile_hint_label.text = "????????????蝘?????


func _refresh_audio_value_label(bus_key: String) -> void:
	var slider: HSlider = _audio_sliders.get(bus_key) as HSlider
	var value_label: Label = _audio_value_labels.get(bus_key) as Label
	if not is_instance_valid(slider) or not is_instance_valid(value_label):
		return
	value_label.text = "%d%%" % int(round(slider.value * 100.0))


func _set_gender_value(value: String) -> void:
	var target_index: int = 0
	for index: int in range(GENDER_OPTIONS.size()):
		if str(GENDER_OPTIONS[index].get("value", "")) == value:
			target_index = index
			break
	_gender_option.select(target_index)


func _get_selected_gender_value() -> String:
	var index: int = maxi(0, _gender_option.selected)
	if index >= GENDER_OPTIONS.size():
		return "Unspecified"
	return str(GENDER_OPTIONS[index].get("value", "Unspecified"))


func _mark_profile_dirty() -> void:
	if _applying_profile_form:
		return
	_profile_dirty = true
	_refresh_profile_save_state()


func _on_save_profile_pressed() -> void:
	if _profile_saving:
		return

	var validation_error: String = _validate_profile_form()
	if validation_error != "":
		ToastManager.error("????????????", validation_error)
		return

	var payload := {
		"displayName": str(GameState.player_data.display_name).strip_edges(),
		"playerName": _player_name_input.text.strip_edges(),
		"avatarId": _selected_avatar_id,
		"bio": _bio_input.text.strip_edges(),
		"birthday": _birthday_input.text.strip_edges(),
		"genderType": _get_selected_gender_value(),
		"region": _region_input.text.strip_edges(),
	}
	if str(payload.get("birthday", "")) == "":
		payload.erase("birthday")

	_profile_saving = true
	_refresh_profile_save_state()
	ApiClient.update_profile_me(payload, func(success: bool, data: Variant, error: Dictionary) -> void:
		_profile_saving = false
		if not success:
			_profile_dirty = true
			_refresh_profile_save_state()
			ToastManager.error("???????????????", str(error.get("message", "??????祈?????謅????)))
			return

		if data is Dictionary:
			var profile: Dictionary = data as Dictionary
			GameState.apply_profile_response(profile)
			_apply_profile_data(profile)
		ToastManager.success("??????????頦????)
	)


func _on_redeem_pressed() -> void:
	if _redeem_in_flight:
		return

	var code: String = _redeem_input.text.strip_edges()
	if code == "":
		ToastManager.error("?????????偃???)
		return

	_redeem_in_flight = true
	_redeem_button.disabled = true
	_redeem_button.text = "?????.."
	ApiClient.redeem_code(code, func(success: bool, data: Variant, error: Dictionary) -> void:
		_redeem_in_flight = false
		_redeem_button.disabled = false
		_redeem_button.text = "???"
		if not success:
			ToastManager.error("???????", str(error.get("message", "??????祈?????謅????)))
			return

		var response: Dictionary = data if data is Dictionary else {}
		var wallet_snapshot: Variant = response.get("walletSnapshot", {})
		if wallet_snapshot is Dictionary:
			GameState.apply_wallet_snapshot(wallet_snapshot)
		_redeem_input.text = ""
		_show_redeem_result(response)
		ToastManager.success("??????", str(response.get("redeemedCode", "")))
	)


func _show_redeem_result(response: Dictionary) -> void:
	var lines: Array[String] = []
	var rewards_variant: Variant = response.get("grantedRewards", [])
	if rewards_variant is Array:
		for reward_variant: Variant in rewards_variant:
			if not (reward_variant is Dictionary):
				continue
			var reward: Dictionary = reward_variant
			var display_name: String = str(reward.get("displayName", reward.get("rewardType", "Reward")))
			lines.append("%s x%d" % [display_name, int(reward.get("quantity", 0))])

	if lines.is_empty():
		lines.append("???????頦????拆????????)

	DialogManager.show_info("??????", "\n".join(lines))


func _on_audio_slider_changed(bus_key: String, value: float) -> void:
	ClientSettings.set_volume(bus_key, value)
	_refresh_audio_value_label(bus_key)


func _on_audio_mute_toggled(bus_key: String, pressed: bool) -> void:
	ClientSettings.set_muted(bus_key, pressed)


func _validate_profile_form() -> String:
	var player_name: String = _player_name_input.text.strip_edges()
	var birthday: String = _birthday_input.text.strip_edges()
	var bio: String = _bio_input.text.strip_edges()

	if player_name == "":
		return "????????????????
	if bio.length() > 140:
		return "???????140 ?????
	if birthday != "" and not _is_valid_birthday_text(birthday):
		return "???蝮??????????YYYY-MM-DD??
	return ""


func _is_valid_birthday_text(text: String) -> bool:
	var parts: PackedStringArray = text.split("-")
	if parts.size() != 3:
		return false
	for part: String in parts:
		if not part.is_valid_int():
			return false

	var year: int = int(parts[0])
	var month: int = int(parts[1])
	var day: int = int(parts[2])
	if year < 1900 or year > 3000:
		return false
	if month < 1 or month > 12:
		return false
	if day < 1 or day > 31:
		return false
	return true


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
