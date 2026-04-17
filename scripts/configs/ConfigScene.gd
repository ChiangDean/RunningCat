extends Control

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")

const MUTED_TEXT_COLOR := Color(0.90, 0.88, 0.82, 0.92)
const SECTION_HINT_COLOR := Color(0.84, 0.80, 0.72, 0.88)
const FIELD_BG := Color(0.14, 0.12, 0.11, 0.98)
const FIELD_BORDER := Color(0.42, 0.36, 0.26, 0.96)
const SELECTED_BORDER := Color(0.92, 0.79, 0.44, 1.0)
const UNSELECTED_BORDER := Color(0.42, 0.36, 0.26, 0.96)
const GENDER_OPTIONS := [
	{"label": "未指定", "value": "Unspecified"},
	{"label": "男性", "value": "Male"},
	{"label": "女性", "value": "Female"},
	{"label": "非二元", "value": "NonBinary"},
	{"label": "不透露", "value": "PreferNotToSay"},
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


func _ready() -> void:
	_build_ui()
	_apply_profile_data(_build_local_profile_snapshot())
	_apply_audio_settings()
	_load_profile_from_api()


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "config", Callable(self, "_on_back_pressed"), {
		"show_dock": false,
		"content_bottom": -(OverlaySceneChrome.HOME_MAIN_NAV_H + 14.0),
		"content_separation": 12,
	})
	var content_box: VBoxContainer = chrome.get("content_box") as VBoxContainer

	var title: Label = Label.new()
	title.text = "設定中心"
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	content_box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "管理角色資料、帳號資訊與本機遊戲設定。"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	subtitle.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	content_box.add_child(subtitle)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_box.add_child(scroll)

	var body: VBoxContainer = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)

	body.add_child(_build_profile_section())
	body.add_child(_build_account_section())
	body.add_child(_build_game_settings_section())


func _build_profile_section() -> Control:
	var section: PanelContainer = OverlaySceneChrome.make_card_panel()
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_section_header("角色資料", "可設定頭像、暱稱、自介、生日與性別。"))

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
	avatar_hint.text = "選擇預設頭像"
	avatar_hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	avatar_picker_shell.add_child(avatar_hint)

	var avatar_grid: GridContainer = GridContainer.new()
	avatar_grid.columns = 3
	avatar_grid.add_theme_constant_override("h_separation", 8)
	avatar_grid.add_theme_constant_override("v_separation", 8)
	avatar_picker_shell.add_child(avatar_grid)

	for avatar_id: String in AssetResolver.get_profile_avatar_ids():
		avatar_grid.add_child(_build_avatar_card(avatar_id))

	_display_name_input = _make_line_edit("請輸入暱稱")
	_player_name_input = _make_line_edit("請輸入角色名稱")
	_birthday_input = _make_line_edit("YYYY-MM-DD")
	_region_input = _make_line_edit("例如：台北 / Kaohsiung")

	_bio_input = TextEdit.new()
	_bio_input.custom_minimum_size = Vector2(0.0, 112.0)
	_bio_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_bio_input.add_theme_stylebox_override("normal", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 12))

	_gender_option = OptionButton.new()
	_gender_option.custom_minimum_size = Vector2(0.0, 48.0)
	for option: Dictionary in GENDER_OPTIONS:
		_gender_option.add_item(str(option.get("label", "")))

	column.add_child(_build_field_row("暱稱", _display_name_input))
	column.add_child(_build_field_row("角色名稱", _player_name_input))
	column.add_child(_build_field_row("自介", _bio_input))
	column.add_child(_build_field_row("生日", _birthday_input))
	column.add_child(_build_field_row("性別", _gender_option))
	column.add_child(_build_field_row("地區", _region_input))

	var save_row: HBoxContainer = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 12)
	column.add_child(save_row)

	_save_profile_button = Button.new()
	_save_profile_button.text = "儲存角色資料"
	_save_profile_button.custom_minimum_size = Vector2(220.0, 50.0)
	UiPalette.apply_button_kind(_save_profile_button, "confirm")
	_save_profile_button.pressed.connect(UiAudio.play_ui_click)
	_save_profile_button.pressed.connect(_on_save_profile_pressed)
	save_row.add_child(_save_profile_button)

	_save_profile_hint_label = Label.new()
	_save_profile_hint_label.text = "資料會同步到帳號。"
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

	column.add_child(_make_section_header("帳號資料", "顯示目前綁定狀態，OAuth 入口先以佔位方式展示。"))

	_account_value_label = _make_readonly_value("載入中")
	_player_uid_value_label = _make_readonly_value("載入中")
	column.add_child(_build_field_row("帳號", _account_value_label))
	column.add_child(_build_field_row("Player UID", _player_uid_value_label))

	var provider_row: HBoxContainer = HBoxContainer.new()
	provider_row.add_theme_constant_override("separation", 10)
	column.add_child(provider_row)

	provider_row.add_child(_build_provider_card("Google"))
	provider_row.add_child(_build_provider_card("Apple"))

	var redeem_title: Label = Label.new()
	redeem_title.text = "兌換碼"
	redeem_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	column.add_child(redeem_title)

	var redeem_hint: Label = Label.new()
	redeem_hint.text = "輸入活動碼即可直接領取獎勵。"
	redeem_hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	redeem_hint.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	column.add_child(redeem_hint)

	var redeem_row: HBoxContainer = HBoxContainer.new()
	redeem_row.add_theme_constant_override("separation", 10)
	column.add_child(redeem_row)

	_redeem_input = _make_line_edit("請輸入兌換碼")
	_redeem_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	redeem_row.add_child(_redeem_input)

	_redeem_button = Button.new()
	_redeem_button.text = "兌換"
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

	column.add_child(_make_section_header("遊戲設定", "音量設定保存在本機裝置，不會覆蓋其他裝置。"))

	column.add_child(_build_audio_row("master", "總音量"))
	column.add_child(_build_audio_row("bgm", "背景音樂"))
	column.add_child(_build_audio_row("sfx", "音效"))

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
	status_label.text = "即將開放"
	status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	status_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	column.add_child(status_label)
	_provider_status_labels[provider_name] = status_label

	var action_button: Button = Button.new()
	action_button.text = "即將開放"
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
	mute_box.text = "靜音"
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
	_display_name_input.text_changed.connect(func(_value: String) -> void:
		_mark_profile_dirty()
	)
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
			ToastManager.hint("設定資料使用快取", str(error.get("message", "目前改用本地快取顯示。")))
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

	_display_name_input.text = str(data.get("displayName", ""))
	_player_name_input.text = str(data.get("playerName", ""))
	_bio_input.text = str(data.get("bio", ""))
	_birthday_input.text = str(data.get("birthday", ""))
	_region_input.text = str(data.get("region", ""))
	_set_gender_value(str(data.get("genderType", "Unspecified")))
	_account_value_label.text = str(data.get("account", ""))
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
		if slider != null:
			slider.value = float(settings.get("%sVolume" % bus_key, 1.0))
		if mute_box != null:
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
	_avatar_preview.texture = AssetResolver.resolve_profile_avatar(_selected_avatar_id)
	_avatar_name_label.text = AssetResolver.get_profile_avatar_label(_selected_avatar_id)
	for avatar_id: String in _avatar_buttons.keys():
		var refs: Dictionary = _avatar_buttons.get(avatar_id, {})
		var panel: PanelContainer = refs.get("panel") as PanelContainer
		var label: Label = refs.get("label") as Label
		if panel == null or label == null:
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
		if status_label == null:
			continue
		if linked.has(provider_name):
			status_label.text = "已綁定"
			status_label.add_theme_color_override("font_color", Color(0.72, 0.94, 0.72, 1.0))
		else:
			status_label.text = "即將開放"
			status_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)


func _refresh_profile_save_state() -> void:
	if _save_profile_button == null:
		return
	_save_profile_button.disabled = _profile_loading or _profile_saving or not _profile_dirty
	if _profile_saving:
		_save_profile_button.text = "儲存中..."
	elif _profile_loading:
		_save_profile_button.text = "載入中..."
	else:
		_save_profile_button.text = "儲存角色資料"

	if _save_profile_hint_label == null:
		return
	if _profile_saving:
		_save_profile_hint_label.text = "正在同步角色資料..."
	elif _profile_dirty:
		_save_profile_hint_label.text = "有未儲存的修改。"
	else:
		_save_profile_hint_label.text = "資料會同步到帳號。"


func _refresh_audio_value_label(bus_key: String) -> void:
	var slider: HSlider = _audio_sliders.get(bus_key) as HSlider
	var value_label: Label = _audio_value_labels.get(bus_key) as Label
	if slider == null or value_label == null:
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
		ToastManager.error("角色資料有誤", validation_error)
		return

	var payload := {
		"displayName": _display_name_input.text.strip_edges(),
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
			ToastManager.error("角色資料儲存失敗", str(error.get("message", "請稍後再試。")))
			return

		if data is Dictionary:
			var profile: Dictionary = data as Dictionary
			GameState.apply_profile_response(profile)
			_apply_profile_data(profile)
		ToastManager.success("角色資料已更新")
	)


func _on_redeem_pressed() -> void:
	if _redeem_in_flight:
		return

	var code: String = _redeem_input.text.strip_edges()
	if code == "":
		ToastManager.error("請輸入兌換碼")
		return

	_redeem_in_flight = true
	_redeem_button.disabled = true
	_redeem_button.text = "兌換中..."
	ApiClient.redeem_code(code, func(success: bool, data: Variant, error: Dictionary) -> void:
		_redeem_in_flight = false
		_redeem_button.disabled = false
		_redeem_button.text = "兌換"
		if not success:
			ToastManager.error("兌換失敗", str(error.get("message", "請稍後再試。")))
			return

		var response: Dictionary = data if data is Dictionary else {}
		var wallet_snapshot: Variant = response.get("walletSnapshot", {})
		if wallet_snapshot is Dictionary:
			GameState.apply_wallet_snapshot(wallet_snapshot)
		_redeem_input.text = ""
		_show_redeem_result(response)
		ToastManager.success("兌換成功", str(response.get("redeemedCode", "")))
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
		lines.append("獎勵已發送到帳號。")

	DialogManager.show_info("兌換成功", "\n".join(lines))


func _on_audio_slider_changed(bus_key: String, value: float) -> void:
	ClientSettings.set_volume(bus_key, value)
	_refresh_audio_value_label(bus_key)


func _on_audio_mute_toggled(bus_key: String, pressed: bool) -> void:
	ClientSettings.set_muted(bus_key, pressed)


func _validate_profile_form() -> String:
	var display_name: String = _display_name_input.text.strip_edges()
	var player_name: String = _player_name_input.text.strip_edges()
	var birthday: String = _birthday_input.text.strip_edges()
	var bio: String = _bio_input.text.strip_edges()

	if display_name == "":
		return "請填寫暱稱。"
	if player_name == "":
		return "請填寫角色名稱。"
	if bio.length() > 140:
		return "自介最多 140 字。"
	if birthday != "" and not _is_valid_birthday_text(birthday):
		return "生日格式請使用 YYYY-MM-DD。"
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
