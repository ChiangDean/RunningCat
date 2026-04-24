extends Control


const ADMIN_CATALOG_SCENE_PATH := "res://scenes/AdminCatalogScene.tscn"
const START_SCENE_PATH := "res://scenes/StartScene.tscn"

const MUTED_TEXT_COLOR := Color(0.90, 0.88, 0.82, 0.92)
const SECTION_HINT_COLOR := Color(0.84, 0.80, 0.72, 0.88)
const FIELD_BG := Color(0.14, 0.12, 0.11, 0.98)
const FIELD_BORDER := Color(0.42, 0.36, 0.26, 0.96)
const SELECTED_BORDER := Color(0.92, 0.79, 0.44, 1.0)
const UNSELECTED_BORDER := Color(0.42, 0.36, 0.26, 0.96)

const PROFILE_NAME_MAX_LENGTH := 15
const BIO_MAX_LENGTH := 140
const BIRTHDAY_MIN_YEAR := 1900

const OPTIONAL_TEXT := UiText.SETTINGS_OPTIONAL_TEXT
const EMPTY_SELECT_TEXT := UiText.SETTINGS_EMPTY_SELECT_TEXT
const AVATAR_CHANGE_BUTTON_TEXT := UiText.SETTINGS_AVATAR_CHANGE_BUTTON
const AVATAR_DIALOG_TITLE := UiText.SETTINGS_AVATAR_DIALOG_TITLE
const AVATAR_DIALOG_HINT := UiText.SETTINGS_AVATAR_DIALOG_HINT
const BIRTHDAY_DIALOG_TITLE := UiText.SETTINGS_BIRTHDAY_DIALOG_TITLE
const BIRTHDAY_DIALOG_HINT := UiText.SETTINGS_BIRTHDAY_DIALOG_HINT
const BIRTHDAY_PICK_BUTTON_TEXT := UiText.SETTINGS_BIRTHDAY_PICK_BUTTON
const BIRTHDAY_CLEAR_BUTTON_TEXT := UiText.SETTINGS_BIRTHDAY_CLEAR_BUTTON
const BIRTHDAY_YEAR_LABEL := UiText.SETTINGS_BIRTHDAY_YEAR_LABEL
const BIRTHDAY_MONTH_LABEL := UiText.SETTINGS_BIRTHDAY_MONTH_LABEL
const BIRTHDAY_DAY_LABEL := UiText.SETTINGS_BIRTHDAY_DAY_LABEL
const BIRTHDAY_FUTURE_ERROR := UiText.SETTINGS_BIRTHDAY_FUTURE_ERROR
const REGION_DIALOG_TITLE := UiText.SETTINGS_REGION_DIALOG_TITLE
const REGION_DIALOG_HINT := UiText.SETTINGS_REGION_DIALOG_HINT
const REGION_PICK_BUTTON_TEXT := UiText.SETTINGS_REGION_PICK_BUTTON
const REGION_CLEAR_BUTTON_TEXT := UiText.SETTINGS_REGION_CLEAR_BUTTON
const ACCOUNT_UID_COPY_BUTTON_TEXT := UiText.SETTINGS_ACCOUNT_UID_COPY_BUTTON
const ACCOUNT_UID_COPY_SUCCESS := UiText.SETTINGS_ACCOUNT_UID_COPY_SUCCESS
const ACCOUNT_UID_COPY_EMPTY := UiText.SETTINGS_ACCOUNT_UID_COPY_EMPTY
const ACCOUNT_UID_HINT := UiText.SETTINGS_ACCOUNT_UID_HINT
const ACCOUNT_LINKED_TITLE := "OAuth"
const ACCOUNT_LINKED_DESC := UiText.SETTINGS_ACCOUNT_LINKED_DESC
const ACCOUNT_SUPPORT_TITLE := UiText.SETTINGS_ACCOUNT_SUPPORT_TITLE
const ACCOUNT_SUPPORT_DESC := UiText.SETTINGS_ACCOUNT_SUPPORT_DESC
const ACCOUNT_SESSION_TITLE := UiText.SETTINGS_ACCOUNT_SESSION_TITLE
const ACCOUNT_SESSION_DESC := UiText.SETTINGS_ACCOUNT_SESSION_DESC
const ACCOUNT_CURRENT_LOGIN_TITLE := UiText.SETTINGS_ACCOUNT_CURRENT_LOGIN_TITLE
const ACCOUNT_CURRENT_LOGIN_UNKNOWN := UiText.SETTINGS_ACCOUNT_CURRENT_LOGIN_UNKNOWN
const ACCOUNT_PROVIDER_LINK_ACTION := UiText.SETTINGS_ACCOUNT_PROVIDER_LINK_ACTION
const ACCOUNT_PROVIDER_UNLINK_ACTION := UiText.SETTINGS_ACCOUNT_PROVIDER_UNLINK_ACTION
const ACCOUNT_PROVIDER_BUSY_ACTION := UiText.SETTINGS_ACCOUNT_PROVIDER_BUSY_ACTION
const ACCOUNT_PROVIDER_CURRENT_HINT := UiText.SETTINGS_ACCOUNT_PROVIDER_CURRENT_HINT
const ACCOUNT_PROVIDER_LAST_METHOD_HINT := UiText.SETTINGS_ACCOUNT_PROVIDER_LAST_METHOD_HINT
const ACCOUNT_PROVIDER_PASSWORD_FALLBACK_HINT := UiText.SETTINGS_ACCOUNT_PROVIDER_PASSWORD_FALLBACK_HINT
const ACCOUNT_PROVIDER_OAUTH_OPENED := UiText.SETTINGS_ACCOUNT_PROVIDER_OAUTH_OPENED
const ACCOUNT_PROVIDER_LINK_SUCCESS := UiText.SETTINGS_ACCOUNT_PROVIDER_LINK_SUCCESS
const ACCOUNT_PROVIDER_UNLINK_SUCCESS := UiText.SETTINGS_ACCOUNT_PROVIDER_UNLINK_SUCCESS
const ACCOUNT_PROVIDER_UNLINK_CURRENT_SUCCESS := UiText.SETTINGS_ACCOUNT_PROVIDER_UNLINK_CURRENT_SUCCESS
const ACCOUNT_PROVIDER_CANCELLED := UiText.SETTINGS_ACCOUNT_PROVIDER_CANCELLED
const ACCOUNT_PROVIDER_TIMEOUT := UiText.SETTINGS_ACCOUNT_PROVIDER_TIMEOUT
const ACCOUNT_PROVIDER_CONFLICT := UiText.SETTINGS_ACCOUNT_PROVIDER_CONFLICT
const ACCOUNT_PROVIDER_PENDING := UiText.SETTINGS_ACCOUNT_PROVIDER_PENDING
const ACCOUNT_PROVIDER_DISABLED_HINT_FORMAT := UiText.SETTINGS_ACCOUNT_PROVIDER_DISABLED_HINT_FORMAT
const ACCOUNT_SUPPORT_EMAIL_TITLE := UiText.SETTINGS_ACCOUNT_SUPPORT_EMAIL_TITLE
const ACCOUNT_SUPPORT_EMAIL_COPY_TEXT := UiText.SETTINGS_ACCOUNT_SUPPORT_EMAIL_COPY
const ACCOUNT_SUPPORT_EMAIL_COPY_SUCCESS := UiText.SETTINGS_ACCOUNT_SUPPORT_EMAIL_COPY_SUCCESS
const ACCOUNT_SUPPORT_EMAIL_COPY_EMPTY := UiText.SETTINGS_ACCOUNT_SUPPORT_EMAIL_COPY_EMPTY
const ACCOUNT_SUPPORT_PAGE_TITLE := UiText.SETTINGS_ACCOUNT_SUPPORT_PAGE_TITLE
const ACCOUNT_SUPPORT_PAGE_HINT := UiText.SETTINGS_ACCOUNT_SUPPORT_PAGE_HINT
const ACCOUNT_PRIVACY_TITLE := UiText.SETTINGS_ACCOUNT_PRIVACY_TITLE
const ACCOUNT_PRIVACY_HINT := UiText.SETTINGS_ACCOUNT_PRIVACY_HINT
const ACCOUNT_DELETION_WEB_TITLE := UiText.SETTINGS_ACCOUNT_DELETION_WEB_TITLE
const ACCOUNT_DELETION_WEB_HINT := UiText.SETTINGS_ACCOUNT_DELETION_WEB_HINT
const ACCOUNT_LINK_ACTION := UiText.SETTINGS_ACCOUNT_LINK_ACTION
const ACCOUNT_LINK_MISSING := UiText.SETTINGS_ACCOUNT_LINK_MISSING
const ACCOUNT_LINK_OPEN_SUCCESS := UiText.SETTINGS_ACCOUNT_LINK_OPEN_SUCCESS
const ACCOUNT_LINK_OPEN_FAILED_TITLE := UiText.SETTINGS_ACCOUNT_LINK_OPEN_FAILED_TITLE
const ACCOUNT_LINK_OPEN_FAILED_FORMAT := UiText.SETTINGS_ACCOUNT_LINK_OPEN_FAILED_FORMAT
const ACCOUNT_DELETE_TITLE := UiText.SETTINGS_ACCOUNT_DELETE_TITLE
const ACCOUNT_DELETE_DESC := UiText.SETTINGS_ACCOUNT_DELETE_DESC
const ACCOUNT_DELETE_BUTTON_TEXT := UiText.SETTINGS_ACCOUNT_DELETE_BUTTON
const ACCOUNT_DELETE_BUTTON_WORKING_TEXT := UiText.SETTINGS_ACCOUNT_DELETE_BUTTON_WORKING
const ACCOUNT_DELETE_CONFIRM_TITLE := UiText.SETTINGS_ACCOUNT_DELETE_CONFIRM_TITLE
const ACCOUNT_DELETE_CONFIRM_BODY := UiText.SETTINGS_ACCOUNT_DELETE_CONFIRM_BODY
const ACCOUNT_DELETE_SUCCESS_TITLE := UiText.SETTINGS_ACCOUNT_DELETE_SUCCESS_TITLE
const ACCOUNT_DELETE_SUCCESS_BODY := UiText.SETTINGS_ACCOUNT_DELETE_SUCCESS_BODY
const ACCOUNT_DELETE_FAILED_TITLE := UiText.SETTINGS_ACCOUNT_DELETE_FAILED_TITLE
const ACCOUNT_DELETE_FAILED_DEFAULT := UiText.SETTINGS_ACCOUNT_DELETE_FAILED_DEFAULT
const OAUTH_BRAND_GOOGLE_TEXTURE := preload("res://assets/sprites/ui/oauth/google/google_signin_neutral_square_220.png")
const OAUTH_BRAND_APPLE_TEXTURE := preload("res://assets/sprites/ui/oauth/apple/apple_signin_left_black_220x50.png")
const OAUTH_BRAND_LINE_TEXTURE := preload("res://assets/sprites/ui/oauth/line/line_login_base_220.png")
const DISABLED_OAUTH_PROVIDER_KEYS: Array[String] = ["apple"]
const DEVICE_ID_PATH := "user://device_id.txt"
const OAUTH_LINK_POLL_INTERVAL_SECONDS := 1.5
const OAUTH_LINK_TIMEOUT_SECONDS := 90.0
const PROFILE_SUMMARY_TITLE := UiText.SETTINGS_PROFILE_SUMMARY_TITLE
const PROFILE_SUMMARY_DESC := UiText.SETTINGS_PROFILE_SUMMARY_DESC

const COUNTRY_OPTIONS: Array[String] = [
	"Taiwan",
	"Afghanistan",
	"Albania",
	"Algeria",
	"Andorra",
	"Angola",
	"Antigua and Barbuda",
	"Argentina",
	"Armenia",
	"Australia",
	"Austria",
	"Azerbaijan",
	"Bahamas",
	"Bahrain",
	"Bangladesh",
	"Barbados",
	"Belarus",
	"Belgium",
	"Belize",
	"Benin",
	"Bhutan",
	"Bolivia",
	"Bosnia and Herzegovina",
	"Botswana",
	"Brazil",
	"Brunei",
	"Bulgaria",
	"Burkina Faso",
	"Burundi",
	"Cabo Verde",
	"Cambodia",
	"Cameroon",
	"Canada",
	"Central African Republic",
	"Chad",
	"Chile",
	"China",
	"Colombia",
	"Comoros",
	"Congo",
	"Costa Rica",
	"Croatia",
	"Cuba",
	"Cyprus",
	"Czech Republic",
	"Democratic Republic of the Congo",
	"Denmark",
	"Djibouti",
	"Dominica",
	"Dominican Republic",
	"Ecuador",
	"Egypt",
	"El Salvador",
	"Equatorial Guinea",
	"Eritrea",
	"Estonia",
	"Eswatini",
	"Ethiopia",
	"Fiji",
	"Finland",
	"France",
	"Gabon",
	"Gambia",
	"Georgia",
	"Germany",
	"Ghana",
	"Greece",
	"Grenada",
	"Guatemala",
	"Guinea",
	"Guinea-Bissau",
	"Guyana",
	"Haiti",
	"Honduras",
	"Hong Kong",
	"Hungary",
	"Iceland",
	"India",
	"Indonesia",
	"Iran",
	"Iraq",
	"Ireland",
	"Israel",
	"Italy",
	"Jamaica",
	"Japan",
	"Jordan",
	"Kazakhstan",
	"Kenya",
	"Kiribati",
	"Korea, North",
	"Korea, South",
	"Kosovo",
	"Kuwait",
	"Kyrgyzstan",
	"Laos",
	"Latvia",
	"Lebanon",
	"Lesotho",
	"Liberia",
	"Libya",
	"Liechtenstein",
	"Lithuania",
	"Luxembourg",
	"Macau",
	"Madagascar",
	"Malawi",
	"Malaysia",
	"Maldives",
	"Mali",
	"Malta",
	"Marshall Islands",
	"Mauritania",
	"Mauritius",
	"Mexico",
	"Micronesia",
	"Moldova",
	"Monaco",
	"Mongolia",
	"Montenegro",
	"Morocco",
	"Mozambique",
	"Myanmar",
	"Namibia",
	"Nauru",
	"Nepal",
	"Netherlands",
	"New Zealand",
	"Nicaragua",
	"Niger",
	"Nigeria",
	"North Macedonia",
	"Norway",
	"Oman",
	"Pakistan",
	"Palau",
	"Palestine",
	"Panama",
	"Papua New Guinea",
	"Paraguay",
	"Peru",
	"Philippines",
	"Poland",
	"Portugal",
	"Qatar",
	"Romania",
	"Russia",
	"Rwanda",
	"Saint Kitts and Nevis",
	"Saint Lucia",
	"Saint Vincent and the Grenadines",
	"Samoa",
	"San Marino",
	"Sao Tome and Principe",
	"Saudi Arabia",
	"Senegal",
	"Serbia",
	"Seychelles",
	"Sierra Leone",
	"Singapore",
	"Slovakia",
	"Slovenia",
	"Solomon Islands",
	"Somalia",
	"South Africa",
	"South Sudan",
	"Spain",
	"Sri Lanka",
	"Sudan",
	"Suriname",
	"Sweden",
	"Switzerland",
	"Syria",
	"Tajikistan",
	"Tanzania",
	"Thailand",
	"Timor-Leste",
	"Togo",
	"Tonga",
	"Trinidad and Tobago",
	"Tunisia",
	"Turkey",
	"Turkmenistan",
	"Tuvalu",
	"Uganda",
	"Ukraine",
	"United Arab Emirates",
	"United Kingdom",
	"United States",
	"Uruguay",
	"Uzbekistan",
	"Vanuatu",
	"Vatican City",
	"Venezuela",
	"Vietnam",
	"Yemen",
	"Zambia",
	"Zimbabwe",
]

const GENDER_OPTIONS := [
	{"label": UiText.SETTINGS_GENDER_UNSPECIFIED, "value": "Unspecified"},
	{"label": UiText.SETTINGS_GENDER_MALE, "value": "Male"},
	{"label": UiText.SETTINGS_GENDER_FEMALE, "value": "Female"},
	{"label": UiText.SETTINGS_GENDER_NON_BINARY, "value": "NonBinary"},
	{"label": UiText.SETTINGS_GENDER_PREFER_NOT_TO_SAY, "value": "PreferNotToSay"},
]

var _profile_dirty: bool = false
var _profile_loading: bool = false
var _profile_saving: bool = false
var _redeem_in_flight: bool = false
var _logout_in_flight: bool = false
var _account_delete_in_flight: bool = false
var _applying_profile_form: bool = false
var _clamping_bio_text: bool = false
var _selected_avatar_id: String = AssetResolver.DEFAULT_PROFILE_AVATAR_ID
var _selected_region_value: String = ""
var _avatar_preview: TextureRect
var _avatar_name_label: Label
var _avatar_buttons: Dictionary = {}
var _avatar_dialog_close: Callable = Callable()
var _player_name_input: LineEdit
var _player_name_counter_label: Label
var _bio_input: TextEdit
var _bio_counter_label: Label
var _birthday_input: LineEdit
var _birthday_dialog_close: Callable = Callable()
var _birthday_year_spin: SpinBox
var _birthday_month_spin: SpinBox
var _birthday_day_spin: SpinBox
var _gender_option: OptionButton
var _region_input: LineEdit
var _region_dialog_close: Callable = Callable()
var _save_profile_button: Button
var _save_profile_hint_label: Label
var _account_value_label: LineEdit
var _player_uid_value_label: LineEdit
var _account_logout_button: Button
var _account_delete_button: Button
var _account_current_login_label: LineEdit
var _provider_card_refs: Dictionary = {}
var _redeem_input: LineEdit
var _redeem_button: Button
var _audio_value_labels: Dictionary = {}
var _audio_sliders: Dictionary = {}
var _audio_mute_boxes: Dictionary = {}
var _active_section: String = "profile"
var _submenu_buttons: Dictionary = {}
var _section_content: VBoxContainer
var _section_scroll: ScrollContainer
var _oauth_link_poll_timer: Timer
var _oauth_link_transaction_id: String = ""
var _oauth_link_provider_name: String = ""
var _oauth_link_provider_key: String = ""
var _oauth_link_elapsed: float = 0.0
var _account_oauth_busy: bool = false


func _ready() -> void:
	_build_ui()
	_oauth_link_poll_timer = Timer.new()
	_oauth_link_poll_timer.one_shot = true
	_oauth_link_poll_timer.wait_time = OAUTH_LINK_POLL_INTERVAL_SECONDS
	_oauth_link_poll_timer.timeout.connect(_on_oauth_link_poll_timeout)
	add_child(_oauth_link_poll_timer)
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


func _build_birthday_spin_group(label_text: String, property_name: String, min_value: int, max_value: int) -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)

	var spin: SpinBox = SpinBox.new()
	spin.min_value = float(min_value)
	spin.max_value = float(max_value)
	spin.step = 1.0
	spin.rounded = true
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.custom_minimum_size = Vector2(0.0, 48.0)
	column.add_child(spin)

	match property_name:
		"_birthday_year_spin":
			_birthday_year_spin = spin
		"_birthday_month_spin":
			_birthday_month_spin = spin
		_:
			_birthday_day_spin = spin
	return column


func _build_section_items() -> Array:
	var items: Array = [
		{
			"key": "profile",
			"label": UiText.SETTINGS_SECTION_PROFILE,
			"shell_description": UiText.SETTINGS_SECTION_PROFILE_DESC,
		},
		{
			"key": "account",
			"label": UiText.SETTINGS_SECTION_ACCOUNT,
			"shell_description": UiText.SETTINGS_SECTION_ACCOUNT_DESC,
		},
		{
			"key": "game",
			"label": UiText.SETTINGS_SECTION_GAME,
			"shell_description": UiText.SETTINGS_SECTION_GAME_DESC,
		},
	]
	if GameState.is_admin_session():
		items.append({
			"key": "admin",
			"label": "Admin Catalog",
			"shell_description": UiText.CONFIG_ADMIN_SECTION_DESC,
		})
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
	_refresh_logout_button_state()
	if is_instance_valid(_section_scroll):
		_section_scroll.scroll_vertical = 0


func _refresh_submenu_buttons() -> void:
	SceneSubmenuBar.refresh(_submenu_buttons, _active_section)


func _clear_section_control_refs() -> void:
	_avatar_preview = null
	_avatar_name_label = null
	_avatar_buttons = {}
	_player_name_input = null
	_player_name_counter_label = null
	_bio_input = null
	_bio_counter_label = null
	_birthday_input = null
	_gender_option = null
	_region_input = null
	_save_profile_button = null
	_save_profile_hint_label = null
	_account_value_label = null
	_player_uid_value_label = null
	_account_current_login_label = null
	_account_logout_button = null
	_account_delete_button = null
	_provider_card_refs = {}
	_redeem_input = null
	_redeem_button = null
	_audio_value_labels = {}
	_audio_sliders = {}
	_audio_mute_boxes = {}


func _build_profile_section() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.add_child(_build_profile_summary_card())
	root.add_child(_build_profile_form_card())
	return root


func _build_profile_summary_card() -> Control:
	var shell: Dictionary = _create_card_shell()
	var panel: PanelContainer = shell.get("panel") as PanelContainer
	var column: VBoxContainer = shell.get("column") as VBoxContainer
	column.add_child(_make_section_header(PROFILE_SUMMARY_TITLE, PROFILE_SUMMARY_DESC))

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)

	var preview_panel: PanelContainer = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(156.0, 180.0)
	preview_panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 16))
	row.add_child(preview_panel)

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

	var preview_button: Button = Button.new()
	preview_button.flat = true
	preview_button.focus_mode = Control.FOCUS_NONE
	preview_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_button.pressed.connect(UiAudio.play_ui_click)
	preview_button.pressed.connect(_open_avatar_dialog)
	preview_panel.add_child(preview_button)

	var info_column: VBoxContainer = VBoxContainer.new()
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_column.alignment = BoxContainer.ALIGNMENT_CENTER
	info_column.add_theme_constant_override("separation", 10)
	row.add_child(info_column)

	var title: Label = Label.new()
	title.text = UiText.SETTINGS_SECTION_PROFILE_TITLE
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	info_column.add_child(title)

	var hint: Label = Label.new()
	hint.text = UiText.SETTINGS_AVATAR_HINT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	hint.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	info_column.add_child(hint)

	var action_button: Button = _make_action_button(AVATAR_CHANGE_BUTTON_TEXT, "secondary", 180.0)
	action_button.pressed.connect(UiAudio.play_ui_click)
	action_button.pressed.connect(_open_avatar_dialog)
	info_column.add_child(action_button)

	return panel


func _build_profile_form_card() -> Control:
	var shell: Dictionary = _create_card_shell()
	var panel: PanelContainer = shell.get("panel") as PanelContainer
	var column: VBoxContainer = shell.get("column") as VBoxContainer
	column.add_child(_make_section_header(UiText.SETTINGS_SECTION_PROFILE_TITLE, UiText.SETTINGS_SECTION_PROFILE_DESC))

	_player_name_input = _make_line_edit(UiText.SETTINGS_PLAYER_NAME_PLACEHOLDER)
	_player_name_input.max_length = PROFILE_NAME_MAX_LENGTH
	var player_name_field: Dictionary = _build_counter_field(UiText.SETTINGS_FIELD_PLAYER_NAME, _player_name_input)
	_player_name_counter_label = player_name_field.get("counter") as Label
	column.add_child(player_name_field.get("root") as Control)

	_bio_input = TextEdit.new()
	_bio_input.custom_minimum_size = Vector2(0.0, 132.0)
	_bio_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_bio_input.add_theme_stylebox_override("normal", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 12))
	var bio_field: Dictionary = _build_counter_field(UiText.SETTINGS_FIELD_BIO, _bio_input)
	_bio_counter_label = bio_field.get("counter") as Label
	column.add_child(bio_field.get("root") as Control)

	_birthday_input = _make_readonly_value("")
	_birthday_input.placeholder_text = EMPTY_SELECT_TEXT
	var birthday_row: HBoxContainer = HBoxContainer.new()
	birthday_row.add_theme_constant_override("separation", 8)
	_birthday_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	birthday_row.add_child(_birthday_input)

	var birthday_pick_button: Button = _make_action_button(BIRTHDAY_PICK_BUTTON_TEXT, "secondary", 144.0)
	birthday_pick_button.pressed.connect(UiAudio.play_ui_click)
	birthday_pick_button.pressed.connect(_open_birthday_dialog)
	birthday_row.add_child(birthday_pick_button)

	var birthday_clear_button: Button = _make_action_button(BIRTHDAY_CLEAR_BUTTON_TEXT, "secondary", 110.0)
	birthday_clear_button.pressed.connect(UiAudio.play_ui_click)
	birthday_clear_button.pressed.connect(_clear_birthday_value)
	birthday_row.add_child(birthday_clear_button)
	column.add_child(_build_field_row("%s (%s)" % [UiText.SETTINGS_FIELD_BIRTHDAY, OPTIONAL_TEXT], birthday_row))

	var lower_grid: GridContainer = GridContainer.new()
	lower_grid.columns = 2
	lower_grid.add_theme_constant_override("h_separation", 10)
	lower_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(lower_grid)

	_gender_option = _make_option_button()
	for option: Dictionary in GENDER_OPTIONS:
		_gender_option.add_item(str(option.get("label", "")))
	lower_grid.add_child(_build_field_row(UiText.SETTINGS_FIELD_GENDER, _gender_option))

	_region_input = _make_readonly_value("")
	_region_input.placeholder_text = EMPTY_SELECT_TEXT
	var region_pick_button: Button = _make_action_button(REGION_PICK_BUTTON_TEXT, "secondary", 144.0)
	region_pick_button.pressed.connect(UiAudio.play_ui_click)
	region_pick_button.pressed.connect(_open_region_dialog)
	var region_clear_button: Button = _make_action_button(REGION_CLEAR_BUTTON_TEXT, "secondary", 110.0)
	region_clear_button.pressed.connect(UiAudio.play_ui_click)
	region_clear_button.pressed.connect(_clear_region_value)
	lower_grid.add_child(_build_inline_action_field(UiText.SETTINGS_FIELD_REGION, _region_input, [region_pick_button, region_clear_button]))

	var save_row: HBoxContainer = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 12)
	column.add_child(save_row)

	_save_profile_button = Button.new()
	_save_profile_button.text = UiText.SETTINGS_PROFILE_SAVE
	_save_profile_button.custom_minimum_size = Vector2(220.0, 50.0)
	UiPalette.apply_button_kind(_save_profile_button, "confirm")
	_save_profile_button.pressed.connect(UiAudio.play_ui_click)
	_save_profile_button.pressed.connect(_on_save_profile_pressed)
	save_row.add_child(_save_profile_button)

	_save_profile_hint_label = Label.new()
	_save_profile_hint_label.text = UiText.SETTINGS_PROFILE_HINT_CLEAN
	_save_profile_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_profile_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_save_profile_hint_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_save_profile_hint_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	save_row.add_child(_save_profile_hint_label)

	_bind_profile_edit_events()
	_refresh_avatar_selection()
	_refresh_profile_counters()
	_refresh_profile_save_state()
	return panel


func _build_account_section() -> Control:
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.add_child(_build_account_identity_card())
	if RuntimeConfig.is_oauth_enabled():
		root.add_child(_build_account_linked_card())
	root.add_child(_build_redeem_card())
	root.add_child(_build_account_support_card())
	root.add_child(_build_account_session_card())
	return root


func _build_account_identity_card() -> Control:
	var shell: Dictionary = _create_card_shell()
	var panel: PanelContainer = shell.get("panel") as PanelContainer
	var column: VBoxContainer = shell.get("column") as VBoxContainer
	column.add_child(_make_section_header(UiText.SETTINGS_SECTION_ACCOUNT_TITLE, UiText.SETTINGS_SECTION_ACCOUNT_DESC))

	_account_value_label = _make_readonly_value(UiText.SETTINGS_ACCOUNT_LOADING)
	column.add_child(_build_field_row(UiText.SETTINGS_FIELD_ACCOUNT, _account_value_label))

	_player_uid_value_label = _make_readonly_value(UiText.SETTINGS_ACCOUNT_LOADING)
	var copy_uid_button: Button = _make_action_button(ACCOUNT_UID_COPY_BUTTON_TEXT, "secondary", 108.0)
	copy_uid_button.pressed.connect(UiAudio.play_ui_click)
	copy_uid_button.pressed.connect(_on_copy_uid_pressed)
	column.add_child(_build_inline_action_field("Player UID", _player_uid_value_label, [copy_uid_button]))

	var uid_hint: Label = Label.new()
	uid_hint.text = ACCOUNT_UID_HINT
	uid_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	uid_hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	uid_hint.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	column.add_child(uid_hint)

	return panel


func _build_account_linked_card() -> Control:
	var shell: Dictionary = _create_card_shell()
	var panel: PanelContainer = shell.get("panel") as PanelContainer
	var column: VBoxContainer = shell.get("column") as VBoxContainer
	column.add_child(_make_section_header(ACCOUNT_LINKED_TITLE, ACCOUNT_LINKED_DESC))

	var provider_list: VBoxContainer = VBoxContainer.new()
	provider_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	provider_list.add_theme_constant_override("separation", 10)
	column.add_child(provider_list)

	provider_list.add_child(_build_provider_card("Google", "google"))
	provider_list.add_child(_build_provider_card("Apple", "apple"))
	provider_list.add_child(_build_provider_card("LINE", "line"))
	return panel


func _build_redeem_card() -> Control:
	var shell: Dictionary = _create_card_shell()
	var panel: PanelContainer = shell.get("panel") as PanelContainer
	var column: VBoxContainer = shell.get("column") as VBoxContainer
	column.add_child(_make_section_header(UiText.SETTINGS_REDEEM_TITLE, UiText.SETTINGS_REDEEM_HINT))

	var redeem_row: HBoxContainer = HBoxContainer.new()
	redeem_row.add_theme_constant_override("separation", 10)
	column.add_child(redeem_row)

	_redeem_input = _make_line_edit(UiText.SETTINGS_REDEEM_PLACEHOLDER)
	_redeem_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	redeem_row.add_child(_redeem_input)

	_redeem_button = Button.new()
	_redeem_button.text = UiText.SETTINGS_REDEEM_ACTION
	_redeem_button.custom_minimum_size = Vector2(132.0, 48.0)
	UiPalette.apply_button_kind(_redeem_button, "confirm")
	_redeem_button.pressed.connect(UiAudio.play_ui_click)
	_redeem_button.pressed.connect(_on_redeem_pressed)
	redeem_row.add_child(_redeem_button)
	return panel


func _build_account_session_card() -> Control:
	var shell: Dictionary = _create_card_shell()
	var panel: PanelContainer = shell.get("panel") as PanelContainer
	var column: VBoxContainer = shell.get("column") as VBoxContainer
	column.add_child(_make_section_header(ACCOUNT_SESSION_TITLE, ACCOUNT_SESSION_DESC))

	_account_current_login_label = _make_readonly_value(ACCOUNT_CURRENT_LOGIN_UNKNOWN)
	column.add_child(_build_field_row(ACCOUNT_CURRENT_LOGIN_TITLE, _account_current_login_label))

	_account_logout_button = Button.new()
	_account_logout_button.custom_minimum_size = Vector2(0.0, 50.0)
	UiPalette.apply_button_kind(_account_logout_button, "danger")
	_account_logout_button.pressed.connect(UiAudio.play_ui_click)
	_account_logout_button.pressed.connect(_on_logout_pressed)
	column.add_child(_account_logout_button)
	return panel


func _build_account_support_card() -> Control:
	var shell: Dictionary = _create_card_shell()
	var panel: PanelContainer = shell.get("panel") as PanelContainer
	var column: VBoxContainer = shell.get("column") as VBoxContainer
	column.add_child(_make_section_header(ACCOUNT_SUPPORT_TITLE, ACCOUNT_SUPPORT_DESC))

	var support_email: String = RuntimeConfig.get_support_email()
	var support_email_value: LineEdit = _make_readonly_value(support_email if support_email != "" else ACCOUNT_LINK_MISSING)
	var copy_support_button: Button = _make_action_button(ACCOUNT_SUPPORT_EMAIL_COPY_TEXT, "secondary", 108.0)
	copy_support_button.disabled = support_email == ""
	copy_support_button.pressed.connect(UiAudio.play_ui_click)
	copy_support_button.pressed.connect(_on_copy_support_email_pressed)
	column.add_child(_build_inline_action_field(ACCOUNT_SUPPORT_EMAIL_TITLE, support_email_value, [copy_support_button]))

	column.add_child(_build_external_link_row(
		ACCOUNT_SUPPORT_PAGE_TITLE,
		ACCOUNT_SUPPORT_PAGE_HINT,
		RuntimeConfig.get_support_url(),
		Callable(self, "_on_open_support_page_pressed")
	))
	column.add_child(_build_external_link_row(
		ACCOUNT_PRIVACY_TITLE,
		ACCOUNT_PRIVACY_HINT,
		RuntimeConfig.get_privacy_policy_url(),
		Callable(self, "_on_open_privacy_policy_pressed")
	))
	column.add_child(_build_external_link_row(
		ACCOUNT_DELETION_WEB_TITLE,
		ACCOUNT_DELETION_WEB_HINT,
		RuntimeConfig.get_account_deletion_url(),
		Callable(self, "_on_open_account_deletion_page_pressed")
	))

	var delete_hint: Label = Label.new()
	delete_hint.text = ACCOUNT_DELETE_DESC
	delete_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	delete_hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	delete_hint.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	column.add_child(delete_hint)

	_account_delete_button = Button.new()
	_account_delete_button.custom_minimum_size = Vector2(0.0, 50.0)
	UiPalette.apply_button_kind(_account_delete_button, "danger")
	_account_delete_button.pressed.connect(UiAudio.play_ui_click)
	_account_delete_button.pressed.connect(_on_delete_account_pressed)
	column.add_child(_account_delete_button)
	return panel


func _build_game_settings_section() -> Control:
	var section: PanelContainer = OverlaySceneChrome.make_card_panel()
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_section_header(UiText.SETTINGS_SECTION_GAME_TITLE, UiText.SETTINGS_SECTION_GAME_DESC))
	column.add_child(_build_audio_row("master", UiText.SETTINGS_AUDIO_MASTER))
	column.add_child(_build_audio_row("bgm", UiText.SETTINGS_AUDIO_BGM))
	column.add_child(_build_audio_row("sfx", UiText.SETTINGS_AUDIO_SFX))
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

	var button: Button = _make_action_button("Open", "confirm", 160.0)
	button.pressed.connect(UiAudio.play_ui_click)
	button.pressed.connect(_open_admin_catalog_scene)
	row.add_child(button)
	return panel


func _build_admin_section() -> Control:
	var section: PanelContainer = OverlaySceneChrome.make_card_panel()
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	section.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_make_section_header("Admin Catalog", UiText.SETTINGS_ADMIN_DESC))
	column.add_child(_build_admin_catalog_row())
	return section


func _build_external_link_row(title_text: String, hint_text: String, url: String, callback: Callable) -> Control:
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
	title.text = title_text
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	text_box.add_child(title)

	var hint: Label = Label.new()
	hint.text = hint_text if url.strip_edges() != "" else ACCOUNT_LINK_MISSING
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	hint.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	text_box.add_child(hint)

	var button: Button = _make_action_button(ACCOUNT_LINK_ACTION, "secondary", 132.0)
	button.disabled = url.strip_edges() == ""
	button.pressed.connect(UiAudio.play_ui_click)
	button.pressed.connect(callback)
	row.add_child(button)
	return panel


func _build_avatar_card(avatar_id: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 120.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(10)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(64.0, 64.0)
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
	button.pressed.connect(Callable(self, "_on_avatar_selected").bind(avatar_id))
	panel.add_child(button)

	_avatar_buttons[avatar_id] = {"panel": panel, "label": label}
	return panel


func _build_provider_card(provider_name: String, provider_key: String) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(FIELD_BORDER, FIELD_BG, 12)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var brand_preview_box: CenterContainer = CenterContainer.new()
	brand_preview_box.custom_minimum_size = _get_provider_brand_texture(provider_key).get_size()
	row.add_child(brand_preview_box)

	var brand_preview: TextureRect = TextureRect.new()
	brand_preview.texture = _get_provider_brand_texture(provider_key)
	brand_preview.custom_minimum_size = _get_provider_brand_texture(provider_key).get_size()
	brand_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	brand_preview_box.add_child(brand_preview)

	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	row.add_child(column)

	var title: Label = Label.new()
	title.text = provider_name
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	column.add_child(title)

	var status_label: Label = Label.new()
	status_label.text = UiText.SETTINGS_PROVIDER_UNLINKED
	status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	status_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	column.add_child(status_label)

	var hint_label: Label = Label.new()
	hint_label.text = ""
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	hint_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	column.add_child(hint_label)

	var action_button: Button = Button.new()
	action_button.text = ACCOUNT_PROVIDER_LINK_ACTION
	action_button.custom_minimum_size = Vector2(148.0, 42.0)
	UiPalette.apply_button_kind(action_button, "secondary")
	action_button.pressed.connect(UiAudio.play_ui_click)
	action_button.pressed.connect(Callable(self, "_on_provider_action_pressed").bind(provider_name, provider_key))
	column.add_child(action_button)

	_provider_card_refs[provider_name] = {
		"status": status_label,
		"hint": hint_label,
		"button": action_button,
		"provider_key": provider_key,
	}
	return panel


func _get_provider_brand_texture(provider_key: String) -> Texture2D:
	match provider_key:
		"google":
			return OAUTH_BRAND_GOOGLE_TEXTURE
		"apple":
			return OAUTH_BRAND_APPLE_TEXTURE
		"line":
			return OAUTH_BRAND_LINE_TEXTURE
		_:
			return OAUTH_BRAND_GOOGLE_TEXTURE


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
	slider.value_changed.connect(Callable(self, "_on_audio_slider_changed").bind(bus_key))
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
	mute_box.text = UiText.SETTINGS_AUDIO_MUTE
	mute_box.toggled.connect(Callable(self, "_on_audio_mute_toggled").bind(bus_key))
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


func _build_counter_field(label_text: String, field: Control) -> Dictionary:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)

	var label_row: HBoxContainer = HBoxContainer.new()
	label_row.add_theme_constant_override("separation", 8)
	column.add_child(label_row)

	var label: Label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	label_row.add_child(label)

	var counter: Label = Label.new()
	counter.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	counter.add_theme_color_override("font_color", SECTION_HINT_COLOR)
	label_row.add_child(counter)

	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(field)
	return {"root": column, "counter": counter}


func _build_inline_action_field(label_text: String, field: Control, buttons: Array) -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	column.add_child(label)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)

	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)

	for button_variant: Variant in buttons:
		if button_variant is Control:
			row.add_child(button_variant)
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
	input.custom_minimum_size = Vector2(0.0, 48.0)
	input.add_theme_stylebox_override("normal", OverlaySceneChrome.make_panel_style(FIELD_BG, FIELD_BORDER, 12))
	return input


func _make_action_button(text: String, kind: String, width: float) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 48.0)
	UiPalette.apply_button_kind(button, kind)
	return button


func _make_option_button() -> OptionButton:
	var button: OptionButton = OptionButton.new()
	button.custom_minimum_size = Vector2(0.0, 48.0)
	UiPalette.apply_button_kind(button, "secondary")
	return button


func _create_card_shell(margin_value: int = 16) -> Dictionary:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(margin_value)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	return {"panel": panel, "column": column}


func _bind_profile_edit_events() -> void:
	_player_name_input.text_changed.connect(_on_player_name_text_changed)
	_bio_input.text_changed.connect(_on_bio_text_changed)
	_gender_option.item_selected.connect(_on_gender_option_item_selected)


func _on_player_name_text_changed(_value: String) -> void:
	_refresh_profile_counters()
	_mark_profile_dirty()


func _on_gender_option_item_selected(_index: int) -> void:
	_mark_profile_dirty()


func _load_profile_from_api() -> void:
	_profile_loading = true
	_refresh_profile_save_state()
	ApiClient.get_profile_me(Callable(self, "_on_profile_loaded"))


func _on_profile_loaded(success: bool, data: Variant, error: Dictionary) -> void:
	_profile_loading = false
	_refresh_profile_save_state()
	if not success:
		ToastManager.hint(UiText.SETTINGS_LOAD_FAILED_TITLE, str(error.get("message", UiText.SETTINGS_LOAD_FAILED_DEFAULT)))
		return

	if data is Dictionary:
		var profile: Dictionary = data as Dictionary
		GameState.apply_profile_response(profile)
		_apply_profile_data(profile)


func _apply_profile_data(data: Dictionary) -> void:
	_applying_profile_form = true
	_selected_avatar_id = "" if data.get("avatarId") == null else str(data.get("avatarId", AssetResolver.DEFAULT_PROFILE_AVATAR_ID)).strip_edges()
	if _selected_avatar_id == "":
		_selected_avatar_id = AssetResolver.DEFAULT_PROFILE_AVATAR_ID

	if is_instance_valid(_player_name_input):
		_player_name_input.text = "" if data.get("playerName") == null else str(data.get("playerName", ""))
	if is_instance_valid(_bio_input):
		_bio_input.text = "" if data.get("bio") == null else str(data.get("bio", ""))
	if is_instance_valid(_birthday_input):
		_birthday_input.text = "" if data.get("birthday") == null else str(data.get("birthday", ""))
	if is_instance_valid(_gender_option):
		_set_gender_value(str(data.get("genderType", "Unspecified")))
	if is_instance_valid(_region_input):
		_set_region_value("" if data.get("region") == null else str(data.get("region", "")))
	if is_instance_valid(_account_value_label):
		_account_value_label.text = "" if data.get("account") == null else str(data.get("account", ""))
	if is_instance_valid(_player_uid_value_label):
		_player_uid_value_label.text = "" if data.get("playerPublicId") == null else str(data.get("playerPublicId", ""))
	if is_instance_valid(_account_current_login_label):
		_account_current_login_label.text = _get_current_login_method_label()

	_refresh_provider_cards(data.get("linkedProviders", []), bool(data.get("passwordLoginEnabled", true)))
	_applying_profile_form = false
	_profile_dirty = false
	_refresh_avatar_selection()
	_refresh_profile_counters()
	_refresh_profile_save_state()
	_refresh_logout_button_state()


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
	var player: PlayerData = GameState.player_data
	if player == null:
		return {
			"account": "",
			"displayName": "",
			"playerPublicId": "",
			"playerName": "",
			"avatarId": AssetResolver.DEFAULT_PROFILE_AVATAR_ID,
			"bio": "",
			"birthday": "",
			"genderType": "Unspecified",
			"region": "",
			"linkedProviders": [],
			"passwordLoginEnabled": true,
		}

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
		"passwordLoginEnabled": player.password_login_enabled,
	}


func _refresh_avatar_selection() -> void:
	if is_instance_valid(_avatar_preview):
		_avatar_preview.texture = AssetResolver.resolve_profile_avatar(_selected_avatar_id)
	if is_instance_valid(_avatar_name_label):
		_avatar_name_label.text = AssetResolver.get_profile_avatar_label(_selected_avatar_id)

	for avatar_id: String in _avatar_buttons.keys():
		var refs: Dictionary = _avatar_buttons.get(avatar_id, {})
		var panel_variant: Variant = refs.get("panel", null)
		var label_variant: Variant = refs.get("label", null)
		if not is_instance_valid(panel_variant) or not is_instance_valid(label_variant):
			continue
		var panel: PanelContainer = panel_variant as PanelContainer
		var label: Label = label_variant as Label
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


func _refresh_provider_cards(linked_providers_variant: Variant, password_login_enabled: bool = true) -> void:
	var linked: Array = linked_providers_variant if linked_providers_variant is Array else []
	for provider_name: String in _provider_card_refs.keys():
		var refs: Dictionary = _provider_card_refs.get(provider_name, {})
		var status_label: Label = refs.get("status") as Label
		var hint_label: Label = refs.get("hint") as Label
		var action_button: Button = refs.get("button") as Button
		var provider_key: String = str(refs.get("provider_key", ""))
		if not is_instance_valid(status_label) or not is_instance_valid(hint_label) or not is_instance_valid(action_button):
			continue
		var is_linked: bool = linked.has(provider_name)
		var is_current_login: bool = _is_current_login_provider(provider_name)
		var can_unlink: bool = _can_unlink_provider(provider_name, linked, password_login_enabled)
		var is_provider_disabled: bool = _is_oauth_provider_disabled(provider_key)
		if is_linked:
			status_label.text = UiText.SETTINGS_PROVIDER_LINKED
			status_label.add_theme_color_override("font_color", Color(0.72, 0.94, 0.72, 1.0))
			if is_provider_disabled:
				action_button.text = UiText.SETTINGS_PROVIDER_ACTION_UNAVAILABLE
				action_button.disabled = true
				UiPalette.apply_button_kind(action_button, "secondary")
			else:
				action_button.text = ACCOUNT_PROVIDER_BUSY_ACTION if _account_oauth_busy and _oauth_link_provider_name == provider_name else ACCOUNT_PROVIDER_UNLINK_ACTION
				action_button.disabled = _account_oauth_busy or not can_unlink
				UiPalette.apply_button_kind(action_button, "danger" if can_unlink else "secondary")
		else:
			status_label.text = UiText.SETTINGS_PROVIDER_UNLINKED
			status_label.add_theme_color_override("font_color", SECTION_HINT_COLOR)
			if is_provider_disabled:
				action_button.text = UiText.SETTINGS_PROVIDER_ACTION_UNAVAILABLE
				action_button.disabled = true
				UiPalette.apply_button_kind(action_button, "secondary")
			else:
				action_button.text = ACCOUNT_PROVIDER_BUSY_ACTION if _account_oauth_busy and _oauth_link_provider_name == provider_name else ACCOUNT_PROVIDER_LINK_ACTION
				action_button.disabled = _account_oauth_busy
				UiPalette.apply_button_kind(action_button, "secondary")

		if is_provider_disabled:
			hint_label.text = ACCOUNT_PROVIDER_DISABLED_HINT_FORMAT % provider_name
		elif _account_oauth_busy and _oauth_link_provider_name == provider_name:
			hint_label.text = ACCOUNT_PROVIDER_PENDING
		elif is_current_login:
			hint_label.text = ACCOUNT_PROVIDER_CURRENT_HINT
		elif is_linked and not can_unlink:
			hint_label.text = ACCOUNT_PROVIDER_LAST_METHOD_HINT
		elif password_login_enabled and is_linked:
			hint_label.text = ACCOUNT_PROVIDER_PASSWORD_FALLBACK_HINT
		else:
			hint_label.text = ""


func _refresh_profile_counters() -> void:
	if is_instance_valid(_player_name_counter_label) and is_instance_valid(_player_name_input):
		_player_name_counter_label.text = "%d/%d" % [_player_name_input.text.length(), PROFILE_NAME_MAX_LENGTH]
	if is_instance_valid(_bio_counter_label) and is_instance_valid(_bio_input):
		_bio_counter_label.text = "%d/%d" % [_bio_input.text.length(), BIO_MAX_LENGTH]


func _refresh_profile_save_state() -> void:
	if is_instance_valid(_save_profile_button):
		_save_profile_button.disabled = _profile_loading or _profile_saving or not _profile_dirty
		if _profile_saving:
			_save_profile_button.text = UiText.SETTINGS_PROFILE_SAVE_WORKING
		elif _profile_loading:
			_save_profile_button.text = UiText.SETTINGS_PROFILE_SAVE_LOADING
		else:
			_save_profile_button.text = UiText.SETTINGS_PROFILE_SAVE

	if is_instance_valid(_save_profile_hint_label):
		if _profile_saving:
			_save_profile_hint_label.text = UiText.SETTINGS_PROFILE_HINT_WORKING
		elif _profile_dirty:
			_save_profile_hint_label.text = UiText.SETTINGS_PROFILE_HINT_DIRTY
		else:
			_save_profile_hint_label.text = UiText.SETTINGS_PROFILE_HINT_CLEAN


func _refresh_logout_button_state() -> void:
	if is_instance_valid(_account_current_login_label):
		_account_current_login_label.text = _get_current_login_method_label()
	if is_instance_valid(_account_logout_button):
		_account_logout_button.disabled = _logout_in_flight or _account_delete_in_flight
		_account_logout_button.text = UiText.START_LOGOUT_BUTTON_WORKING if _logout_in_flight else UiText.START_LOGOUT_BUTTON
	if is_instance_valid(_account_delete_button):
		_account_delete_button.disabled = _logout_in_flight or _account_delete_in_flight
		_account_delete_button.text = ACCOUNT_DELETE_BUTTON_WORKING_TEXT if _account_delete_in_flight else ACCOUNT_DELETE_BUTTON_TEXT


func _get_current_login_method_label() -> String:
	var method_key: String = GameState.get_current_login_method().strip_edges().to_lower()
	match method_key:
		"google":
			return "Google"
		"apple":
			return "Apple"
		"line":
			return "LINE"
		"password":
			return UiText.SETTINGS_LOGIN_METHOD_PASSWORD
		_:
			return ACCOUNT_CURRENT_LOGIN_UNKNOWN


func _is_current_login_provider(provider_name: String) -> bool:
	return _get_current_login_method_label() == provider_name


func _can_unlink_provider(provider_name: String, linked: Array, password_login_enabled: bool) -> bool:
	if not linked.has(provider_name):
		return false
	if password_login_enabled:
		return true
	return linked.size() > 1


func _on_provider_action_pressed(provider_name: String, provider_key: String) -> void:
	if _account_oauth_busy:
		return
	if not RuntimeConfig.is_oauth_enabled():
		ToastManager.hint(UiText.START_STATUS_OAUTH_DISABLED)
		return
	if _is_oauth_provider_disabled(provider_key):
		ToastManager.hint(ACCOUNT_PROVIDER_DISABLED_HINT_FORMAT % provider_name)
		return

	var linked: Array = GameState.get_linked_providers()
	if linked.has(provider_name):
		var can_unlink: bool = _can_unlink_provider(provider_name, linked, GameState.is_password_login_enabled())
		if not can_unlink:
			ToastManager.hint(ACCOUNT_PROVIDER_LAST_METHOD_HINT)
			return
		DialogManager.show_confirm(
			"%s %s" % [ACCOUNT_PROVIDER_UNLINK_ACTION, provider_name],
			UiText.SETTINGS_ACCOUNT_PROVIDER_UNLINK_CONFIRM_BODY_FORMAT % provider_name,
			Callable(self, "_unlink_oauth_provider").bind(provider_name, provider_key),
			Callable(self, "_noop")
		)
		return

	_begin_oauth_link_flow(provider_name, provider_key)


func _is_oauth_provider_disabled(provider_key: String) -> bool:
	return DISABLED_OAUTH_PROVIDER_KEYS.has(provider_key)


func _begin_oauth_link_flow(provider_name: String, provider_key: String) -> void:
	_account_oauth_busy = true
	_oauth_link_provider_name = provider_name
	_oauth_link_provider_key = provider_key
	_oauth_link_transaction_id = ""
	_oauth_link_elapsed = 0.0
	_refresh_provider_cards(GameState.get_linked_providers(), GameState.is_password_login_enabled())

	ApiClient.begin_oauth_link(provider_key, {
		"platformType": _get_oauth_platform_type(),
		"deviceId": _load_or_create_device_id(),
		"deviceName": _build_device_name(),
	}, Callable(self, "_on_begin_oauth_link_completed").bind(provider_name))


func _on_begin_oauth_link_completed(success: bool, data: Variant, error: Dictionary, provider_name: String) -> void:
	if not success:
		_stop_oauth_link_flow(true)
		ToastManager.error(provider_name, str(error.get("message", ACCOUNT_PROVIDER_CONFLICT)))
		return

	var payload: Dictionary = data if data is Dictionary else {}
	_oauth_link_transaction_id = str(payload.get("transactionId", "")).strip_edges()
	var authorization_url: String = str(payload.get("authorizationUrl", "")).strip_edges()
	if _oauth_link_transaction_id == "" or authorization_url == "":
		_stop_oauth_link_flow(true)
		ToastManager.error(provider_name, ACCOUNT_PROVIDER_CONFLICT)
		return

	var open_error: int = OS.shell_open(authorization_url)
	if open_error != OK:
		_stop_oauth_link_flow(true)
		ToastManager.error(provider_name, UiText.START_STATUS_REQUEST_ERROR_FORMAT % open_error)
		return

	ToastManager.hint(ACCOUNT_PROVIDER_OAUTH_OPENED)
	_schedule_next_oauth_link_poll()


func _schedule_next_oauth_link_poll() -> void:
	if _oauth_link_transaction_id == "":
		return
	_oauth_link_elapsed += OAUTH_LINK_POLL_INTERVAL_SECONDS
	if _oauth_link_elapsed >= OAUTH_LINK_TIMEOUT_SECONDS:
		_stop_oauth_link_flow(true)
		ToastManager.hint(ACCOUNT_PROVIDER_TIMEOUT)
		return
	if _oauth_link_poll_timer != null:
		_oauth_link_poll_timer.stop()
		_oauth_link_poll_timer.wait_time = OAUTH_LINK_POLL_INTERVAL_SECONDS
		_oauth_link_poll_timer.start()


func _on_oauth_link_poll_timeout() -> void:
	if _oauth_link_transaction_id == "":
		return
	ApiClient.exchange_oauth_link(_oauth_link_transaction_id, Callable(self, "_on_exchange_oauth_link_completed"))


func _on_exchange_oauth_link_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		_stop_oauth_link_flow(true)
		ToastManager.error(_oauth_link_provider_name, str(error.get("message", ACCOUNT_PROVIDER_CONFLICT)))
		return

	var payload: Dictionary = data if data is Dictionary else {}
	var status: String = str(payload.get("status", "")).strip_edges().to_lower()
	match status:
		"pending":
			_schedule_next_oauth_link_poll()
		"linked":
			var linked_provider_name: String = _oauth_link_provider_name
			_stop_oauth_link_flow(true)
			var profile: Dictionary = payload.get("profile", {}) if payload.get("profile") is Dictionary else {}
			if not profile.is_empty():
				GameState.apply_profile_response(profile)
				_apply_profile_data(profile)
			ToastManager.success(ACCOUNT_PROVIDER_LINK_SUCCESS, linked_provider_name)
		"cancelled":
			_stop_oauth_link_flow(true)
			ToastManager.hint(ACCOUNT_PROVIDER_CANCELLED)
		"failed":
			_stop_oauth_link_flow(true)
			var message: String = str(payload.get("errorMessage", ACCOUNT_PROVIDER_CONFLICT))
			ToastManager.error(_oauth_link_provider_name, message)
		_:
			_schedule_next_oauth_link_poll()


func _stop_oauth_link_flow(clear_provider: bool) -> void:
	if _oauth_link_poll_timer != null:
		_oauth_link_poll_timer.stop()
	_account_oauth_busy = false
	_oauth_link_transaction_id = ""
	_oauth_link_elapsed = 0.0
	if clear_provider:
		_oauth_link_provider_name = ""
		_oauth_link_provider_key = ""
	_refresh_provider_cards(GameState.get_linked_providers(), GameState.is_password_login_enabled())


func _unlink_oauth_provider(provider_name: String, provider_key: String) -> void:
	_account_oauth_busy = true
	_oauth_link_provider_name = provider_name
	_oauth_link_provider_key = provider_key
	_refresh_provider_cards(GameState.get_linked_providers(), GameState.is_password_login_enabled())

	ApiClient.unlink_oauth_provider(
		provider_key,
		GameState.get_refresh_token(),
		Callable(self, "_on_unlink_oauth_provider_completed").bind(provider_name)
	)


func _on_unlink_oauth_provider_completed(success: bool, data: Variant, error: Dictionary, provider_name: String) -> void:
	_account_oauth_busy = false
	_refresh_provider_cards(GameState.get_linked_providers(), GameState.is_password_login_enabled())
	if not success:
		ToastManager.error(provider_name, str(error.get("message", ACCOUNT_PROVIDER_CONFLICT)))
		return

	var profile: Dictionary = data if data is Dictionary else {}
	if not profile.is_empty():
		GameState.apply_profile_response(profile)
		_apply_profile_data(profile)

	if _is_current_login_provider(provider_name):
		ToastManager.success(ACCOUNT_PROVIDER_UNLINK_CURRENT_SUCCESS)
		_finalize_logout()
		return

	ToastManager.success(ACCOUNT_PROVIDER_UNLINK_SUCCESS, provider_name)


func _get_oauth_platform_type() -> String:
	var os_name: String = OS.get_name().to_lower()
	if os_name.find("android") >= 0:
		return "Android"
	if os_name.find("ios") >= 0:
		return "Ios"
	return "Web" if OS.has_feature("web") else "Web"


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


func _set_region_value(value: String) -> void:
	var target_value: String = value.strip_edges()
	if target_value == "":
		_selected_region_value = ""
		if is_instance_valid(_region_input):
			_region_input.text = ""
		return

	for country_name: String in COUNTRY_OPTIONS:
		if country_name == target_value:
			_selected_region_value = target_value
			if is_instance_valid(_region_input):
				_region_input.text = target_value
			return

	_selected_region_value = ""
	if is_instance_valid(_region_input):
		_region_input.text = ""


func _get_selected_region_value() -> String:
	return _selected_region_value


func _mark_profile_dirty() -> void:
	if _applying_profile_form:
		return
	_profile_dirty = true
	_refresh_profile_save_state()


func _on_avatar_selected(avatar_id: String) -> void:
	if _profile_saving or _profile_loading:
		return

	var previous_avatar_id: String = _selected_avatar_id
	_selected_avatar_id = avatar_id
	_refresh_avatar_selection()
	_avatar_dialog_close = _close_dialog(_avatar_dialog_close)
	_avatar_buttons = {}

	var payload: Dictionary = _build_profile_payload(true)
	_profile_saving = true
	_refresh_profile_save_state()
	ApiClient.update_profile_me(payload, Callable(self, "_on_avatar_profile_updated").bind(previous_avatar_id))


func _on_avatar_profile_updated(success: bool, data: Variant, error: Dictionary, previous_avatar_id: String) -> void:
	_profile_saving = false
	if not success:
		_selected_avatar_id = previous_avatar_id
		_refresh_avatar_selection()
		_refresh_profile_save_state()
		ToastManager.error(UiText.SETTINGS_PROFILE_SAVE_FAILED_TITLE, str(error.get("message", UiText.SETTINGS_PROFILE_SAVE_FAILED_DEFAULT)))
		return

	if data is Dictionary:
		var profile: Dictionary = data as Dictionary
		GameState.apply_profile_response(profile)
		_apply_profile_data(profile)
	ToastManager.success(UiText.SETTINGS_PROFILE_SAVE_SUCCESS)


func _open_avatar_dialog() -> void:
	if _avatar_dialog_close.is_valid():
		return
	var content: VBoxContainer = _build_avatar_dialog_content()
	_refresh_avatar_selection()
	_avatar_dialog_close = DialogManager.show_info_node(AVATAR_DIALOG_TITLE, content, Callable(self, "_on_avatar_dialog_closed"), "medium")


func _open_birthday_dialog() -> void:
	if _birthday_dialog_close.is_valid():
		return
	var content: VBoxContainer = _build_birthday_dialog_content()

	var birthday_text: String = _birthday_input.text.strip_edges() if is_instance_valid(_birthday_input) else ""
	var parsed: Dictionary = _parse_birthday_text(birthday_text)
	if parsed.is_empty():
		var now: Dictionary = Time.get_date_dict_from_system()
		_birthday_year_spin.value = float(now.get("year", _get_current_year()))
		_birthday_month_spin.value = float(now.get("month", 1))
		_birthday_day_spin.value = float(now.get("day", 1))
	else:
		_birthday_year_spin.value = float(parsed.get("year", _get_current_year()))
		_birthday_month_spin.value = float(parsed.get("month", 1))
		_birthday_day_spin.value = float(parsed.get("day", 1))

	_refresh_birthday_day_limit()
	_birthday_dialog_close = DialogManager.show_info_node(BIRTHDAY_DIALOG_TITLE, content, Callable(self, "_on_birthday_dialog_closed"), "small")


func _clear_birthday_value() -> void:
	if not is_instance_valid(_birthday_input):
		return
	if _birthday_input.text == "":
		return
	_birthday_input.text = ""
	_mark_profile_dirty()


func _on_birthday_confirm_pressed() -> void:
	if not is_instance_valid(_birthday_input):
		return
	var birthday_text: String = "%04d-%02d-%02d" % [
		int(_birthday_year_spin.value),
		int(_birthday_month_spin.value),
		int(_birthday_day_spin.value),
	]
	if _is_future_date(int(_birthday_year_spin.value), int(_birthday_month_spin.value), int(_birthday_day_spin.value)):
		ToastManager.error(UiText.SETTINGS_PROFILE_VALIDATION_TITLE, BIRTHDAY_FUTURE_ERROR)
		return
	_birthday_input.text = birthday_text
	_mark_profile_dirty()
	_birthday_dialog_close = _close_dialog(_birthday_dialog_close)
	_birthday_year_spin = null
	_birthday_month_spin = null
	_birthday_day_spin = null


func _on_birthday_clear_pressed() -> void:
	_clear_birthday_value()
	_birthday_dialog_close = _close_dialog(_birthday_dialog_close)
	_birthday_year_spin = null
	_birthday_month_spin = null
	_birthday_day_spin = null


func _refresh_birthday_day_limit() -> void:
	if _birthday_day_spin == null:
		return
	var year: int = int(_birthday_year_spin.value)
	var month: int = int(_birthday_month_spin.value)
	var day_limit: int = _get_days_in_month(year, month)
	_birthday_day_spin.max_value = float(day_limit)
	if int(_birthday_day_spin.value) > day_limit:
		_birthday_day_spin.value = float(day_limit)


func _parse_birthday_text(text: String) -> Dictionary:
	if text == "":
		return {}
	var parts: PackedStringArray = text.split("-")
	if parts.size() != 3:
		return {}
	for part: String in parts:
		if not part.is_valid_int():
			return {}
	return {
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2]),
	}


func _get_days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if _is_leap_year(year) else 28
		_:
			return 31


func _is_leap_year(year: int) -> bool:
	if year % 400 == 0:
		return true
	if year % 100 == 0:
		return false
	return year % 4 == 0


func _get_current_year() -> int:
	var now: Dictionary = Time.get_date_dict_from_system()
	return int(now.get("year", 2026))


func _on_bio_text_changed() -> void:
	if not is_instance_valid(_bio_input):
		return

	if _clamping_bio_text:
		return

	if _bio_input.text.length() > BIO_MAX_LENGTH:
		_clamping_bio_text = true
		_bio_input.text = _bio_input.text.substr(0, BIO_MAX_LENGTH)
		var last_line: int = maxi(_bio_input.get_line_count() - 1, 0)
		_bio_input.set_caret_line(last_line)
		_bio_input.set_caret_column(_bio_input.get_line(last_line).length())
		_clamping_bio_text = false

	_refresh_profile_counters()
	_mark_profile_dirty()


func _open_region_dialog() -> void:
	if _region_dialog_close.is_valid():
		return
	var content: VBoxContainer = _build_region_dialog_content()
	_region_dialog_close = DialogManager.show_info_node(REGION_DIALOG_TITLE, content, Callable(self, "_on_region_dialog_closed"), "medium")


func _clear_region_value() -> void:
	if _selected_region_value == "":
		return
	_set_region_value("")
	_mark_profile_dirty()


func _on_region_selected(region_value: String) -> void:
	if _selected_region_value == region_value:
		_region_dialog_close = _close_dialog(_region_dialog_close)
		return
	_set_region_value(region_value)
	_mark_profile_dirty()
	_region_dialog_close = _close_dialog(_region_dialog_close)


func _on_save_profile_pressed() -> void:
	if _profile_saving:
		return

	var validation_error: String = _validate_profile_form()
	if validation_error != "":
		ToastManager.error(UiText.SETTINGS_PROFILE_VALIDATION_TITLE, validation_error)
		return

	var payload: Dictionary = _build_profile_payload(true)
	_profile_saving = true
	_refresh_profile_save_state()
	ApiClient.update_profile_me(payload, Callable(self, "_on_profile_save_completed"))


func _on_copy_uid_pressed() -> void:
	if not is_instance_valid(_player_uid_value_label):
		return
	var player_uid: String = _player_uid_value_label.text.strip_edges()
	if player_uid == "":
		ToastManager.error(ACCOUNT_UID_COPY_EMPTY)
		return
	DisplayServer.clipboard_set(player_uid)
	ToastManager.success(ACCOUNT_UID_COPY_SUCCESS, player_uid)


func _on_copy_support_email_pressed() -> void:
	var support_email: String = RuntimeConfig.get_support_email()
	if support_email == "":
		ToastManager.error(ACCOUNT_SUPPORT_EMAIL_COPY_EMPTY)
		return
	DisplayServer.clipboard_set(support_email)
	ToastManager.success(ACCOUNT_SUPPORT_EMAIL_COPY_SUCCESS, support_email)


func _on_open_support_page_pressed() -> void:
	_open_external_url(RuntimeConfig.get_support_url(), ACCOUNT_SUPPORT_PAGE_TITLE)


func _on_open_privacy_policy_pressed() -> void:
	_open_external_url(RuntimeConfig.get_privacy_policy_url(), ACCOUNT_PRIVACY_TITLE)


func _on_open_account_deletion_page_pressed() -> void:
	_open_external_url(RuntimeConfig.get_account_deletion_url(), ACCOUNT_DELETION_WEB_TITLE)


func _open_external_url(url: String, label_text: String) -> void:
	var trimmed_url: String = url.strip_edges()
	if trimmed_url == "":
		ToastManager.hint(ACCOUNT_LINK_MISSING)
		return

	var open_error: int = OS.shell_open(trimmed_url)
	if open_error != OK:
		ToastManager.error(ACCOUNT_LINK_OPEN_FAILED_TITLE, ACCOUNT_LINK_OPEN_FAILED_FORMAT % [label_text, str(open_error)])
		return

	ToastManager.success(ACCOUNT_LINK_OPEN_SUCCESS, label_text)


func _on_profile_save_completed(success: bool, data: Variant, error: Dictionary) -> void:
	_profile_saving = false
	if not success:
		_profile_dirty = true
		_refresh_profile_save_state()
		ToastManager.error(UiText.SETTINGS_PROFILE_SAVE_FAILED_TITLE, str(error.get("message", UiText.SETTINGS_PROFILE_SAVE_FAILED_DEFAULT)))
		return

	if data is Dictionary:
		var profile: Dictionary = data as Dictionary
		GameState.apply_profile_response(profile)
		_apply_profile_data(profile)
	ToastManager.success(UiText.SETTINGS_PROFILE_SAVE_SUCCESS)


func _on_logout_pressed() -> void:
	if _logout_in_flight or _account_delete_in_flight:
		return
	DialogManager.show_confirm(
		UiText.START_LOGOUT_CONFIRM_TITLE,
		UiText.START_LOGOUT_CONFIRM_BODY,
		Callable(self, "_begin_logout"),
		Callable(self, "_noop")
	)


func _begin_logout() -> void:
	if _logout_in_flight or _account_delete_in_flight:
		return

	var refresh_token: String = GameState.get_refresh_token()
	if refresh_token == "":
		_finalize_logout()
		return

	_logout_in_flight = true
	_refresh_logout_button_state()
	ApiClient.revoke_refresh_token(refresh_token, UiText.START_LOGOUT_REASON, Callable(self, "_on_revoke_refresh_token_completed"))


func _on_revoke_refresh_token_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	_logout_in_flight = false
	_refresh_logout_button_state()
	if success:
		_finalize_logout()
		return

	var error_code: String = str(error.get("code", ""))
	if error_code == "AUTH.REFRESH_TOKEN_NOT_FOUND" or error_code == "AUTH.SESSION_EXPIRED":
		_finalize_logout()
		return

	ToastManager.error(UiText.START_LOGOUT_CONFIRM_TITLE, str(error.get("message", UiText.START_STATUS_LOGOUT_FAILED)))


func _on_delete_account_pressed() -> void:
	if _account_delete_in_flight or _logout_in_flight:
		return

	DialogManager.show_confirm(
		ACCOUNT_DELETE_CONFIRM_TITLE,
		ACCOUNT_DELETE_CONFIRM_BODY,
		Callable(self, "_begin_delete_account"),
		Callable(self, "_noop")
	)


func _begin_delete_account() -> void:
	if _account_delete_in_flight or _logout_in_flight:
		return

	_account_delete_in_flight = true
	_refresh_logout_button_state()
	ApiClient.delete_profile_me(Callable(self, "_on_delete_account_completed"))


func _on_delete_account_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	_account_delete_in_flight = false
	_refresh_logout_button_state()
	if success:
		DialogManager.show_info(ACCOUNT_DELETE_SUCCESS_TITLE, ACCOUNT_DELETE_SUCCESS_BODY, Callable(self, "_finalize_logout"))
		return

	var error_code: String = str(error.get("code", ""))
	if error_code == "AUTH.USER_INACTIVE" or error_code == "AUTH.UNAUTHORIZED":
		_finalize_logout()
		return

	ToastManager.error(ACCOUNT_DELETE_FAILED_TITLE, str(error.get("message", ACCOUNT_DELETE_FAILED_DEFAULT)))


func _finalize_logout() -> void:
	GameState.clear_auth_and_player_state()
	get_tree().change_scene_to_file(START_SCENE_PATH)


func _noop() -> void:
	pass


func _on_redeem_pressed() -> void:
	if _redeem_in_flight:
		return

	var code: String = _redeem_input.text.strip_edges()
	if code == "":
		ToastManager.error(UiText.SETTINGS_REDEEM_EMPTY)
		return

	_redeem_in_flight = true
	_redeem_button.disabled = true
	_redeem_button.text = UiText.SETTINGS_REDEEM_ACTION_WORKING
	ApiClient.redeem_code(code, Callable(self, "_on_redeem_code_completed"))


func _on_redeem_code_completed(success: bool, data: Variant, error: Dictionary) -> void:
	_redeem_in_flight = false
	_redeem_button.disabled = false
	_redeem_button.text = UiText.SETTINGS_REDEEM_ACTION
	if not success:
		ToastManager.error(UiText.SETTINGS_REDEEM_FAILED_TITLE, str(error.get("message", UiText.SETTINGS_REDEEM_FAILED_DEFAULT)))
		return

	var response: Dictionary = data if data is Dictionary else {}
	var wallet_snapshot: Variant = response.get("walletSnapshot", {})
	if wallet_snapshot is Dictionary:
		GameState.apply_wallet_snapshot(wallet_snapshot)
	_redeem_input.text = ""
	_show_redeem_result(response)
	ToastManager.success(UiText.SETTINGS_REDEEM_SUCCESS, str(response.get("redeemedCode", "")))


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
		lines.append(UiText.SETTINGS_REDEEM_RESULT_EMPTY)

	DialogManager.show_info(UiText.SETTINGS_REDEEM_RESULT_TITLE, "\n".join(lines))


func _on_audio_slider_changed(value: float, bus_key: String) -> void:
	ClientSettings.set_volume(bus_key, value)
	_refresh_audio_value_label(bus_key)


func _on_audio_mute_toggled(pressed: bool, bus_key: String) -> void:
	ClientSettings.set_muted(bus_key, pressed)


func _validate_profile_form() -> String:
	var player_name: String = _player_name_input.text.strip_edges()
	var birthday: String = _birthday_input.text.strip_edges()
	var bio: String = _bio_input.text.strip_edges()

	if player_name == "":
		return UiText.SETTINGS_VALIDATE_PLAYER_NAME
	if bio.length() > BIO_MAX_LENGTH:
		return UiText.SETTINGS_VALIDATE_BIO_LENGTH
	if birthday != "" and not _is_valid_birthday_text(birthday):
		return UiText.SETTINGS_VALIDATE_BIRTHDAY
	return ""


func _is_valid_birthday_text(text: String) -> bool:
	var parsed: Dictionary = _parse_birthday_text(text)
	if parsed.is_empty():
		return false

	var year: int = int(parsed.get("year", 0))
	var month: int = int(parsed.get("month", 0))
	var day: int = int(parsed.get("day", 0))
	if year < BIRTHDAY_MIN_YEAR or year > _get_current_year():
		return false
	if month < 1 or month > 12:
		return false
	if day < 1 or day > _get_days_in_month(year, month):
		return false
	return not _is_future_date(year, month, day)


func _build_profile_payload(use_form_values: bool) -> Dictionary:
	var player: PlayerData = GameState.player_data
	var payload := {
		"displayName": "" if player == null else str(player.display_name).strip_edges(),
		"playerName": "",
		"avatarId": _selected_avatar_id,
		"bio": "",
		"birthday": "",
		"genderType": "Unspecified",
		"region": "",
	}

	if use_form_values:
		payload["playerName"] = _player_name_input.text.strip_edges()
		payload["bio"] = _bio_input.text.strip_edges()
		payload["birthday"] = _birthday_input.text.strip_edges()
		payload["genderType"] = _get_selected_gender_value()
		payload["region"] = _get_selected_region_value()
	else:
		payload["playerName"] = "" if player == null else str(player.player_name).strip_edges()
		payload["bio"] = "" if player == null else str(player.bio)
		payload["birthday"] = "" if player == null else str(player.birthday).strip_edges()
		payload["genderType"] = "Unspecified" if player == null else str(player.gender_type).strip_edges()
		payload["region"] = "" if player == null else str(player.region).strip_edges()

	if str(payload.get("birthday", "")) == "":
		payload.erase("birthday")
	return payload


func _build_avatar_dialog_content() -> VBoxContainer:
	_avatar_buttons = {}

	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(0.0, 420.0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)

	var hint: Label = Label.new()
	hint.text = AVATAR_DIALOG_HINT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	hint.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	column.add_child(hint)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 320.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	InertialScroller.attach(scroll, "vertical")

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for avatar_id: String in AssetResolver.get_profile_avatar_ids():
		grid.add_child(_build_avatar_card(avatar_id))
	return column


func _build_birthday_dialog_content() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(0.0, 196.0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)

	var hint: Label = Label.new()
	hint.text = BIRTHDAY_DIALOG_HINT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	hint.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	column.add_child(hint)

	var picker_row: HBoxContainer = HBoxContainer.new()
	picker_row.add_theme_constant_override("separation", 10)
	column.add_child(picker_row)

	picker_row.add_child(_build_birthday_spin_group(BIRTHDAY_YEAR_LABEL, "_birthday_year_spin", BIRTHDAY_MIN_YEAR, _get_current_year()))
	picker_row.add_child(_build_birthday_spin_group(BIRTHDAY_MONTH_LABEL, "_birthday_month_spin", 1, 12))
	picker_row.add_child(_build_birthday_spin_group(BIRTHDAY_DAY_LABEL, "_birthday_day_spin", 1, 31))

	_birthday_year_spin.value_changed.connect(_on_birthday_year_changed)
	_birthday_month_spin.value_changed.connect(_on_birthday_month_changed)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)

	var clear_button: Button = _make_action_button(BIRTHDAY_CLEAR_BUTTON_TEXT, "secondary", 96.0)
	clear_button.pressed.connect(UiAudio.play_ui_click)
	clear_button.pressed.connect(_on_birthday_clear_pressed)
	actions.add_child(clear_button)

	var confirm_button: Button = _make_action_button(UiText.COMMON_CONFIRM, "confirm", 112.0)
	confirm_button.pressed.connect(UiAudio.play_ui_click)
	confirm_button.pressed.connect(_on_birthday_confirm_pressed)
	actions.add_child(confirm_button)
	return column


func _build_region_dialog_content() -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(0.0, 560.0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)

	var hint: Label = Label.new()
	hint.text = REGION_DIALOG_HINT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	hint.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	column.add_child(hint)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 468.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)
	InertialScroller.attach(scroll, "vertical")

	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	list.add_child(_build_region_dialog_button(EMPTY_SELECT_TEXT, ""))
	for country_name: String in COUNTRY_OPTIONS:
		list.add_child(_build_region_dialog_button(country_name, country_name))
	return column


func _build_region_dialog_button(label_text: String, region_value: String) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var is_selected: bool = region_value == _selected_region_value
	if is_selected:
		UiPalette.apply_button_kind(button, "confirm")
	else:
		UiPalette.apply_button_kind(button, "secondary")
	button.pressed.connect(UiAudio.play_ui_click)
	button.pressed.connect(Callable(self, "_on_region_selected").bind(region_value))
	return button


func _on_avatar_dialog_closed() -> void:
	_avatar_dialog_close = Callable()
	_avatar_buttons = {}


func _on_birthday_dialog_closed() -> void:
	_birthday_dialog_close = Callable()
	_birthday_year_spin = null
	_birthday_month_spin = null
	_birthday_day_spin = null


func _on_region_dialog_closed() -> void:
	_region_dialog_close = Callable()


func _on_birthday_year_changed(_value: float) -> void:
	_refresh_birthday_day_limit()


func _on_birthday_month_changed(_value: float) -> void:
	_refresh_birthday_day_limit()


func _open_admin_catalog_scene() -> void:
	SceneNavigator.open_overlay_scene(ADMIN_CATALOG_SCENE_PATH)


func _close_dialog(close_dialog: Callable) -> Callable:
	if close_dialog.is_valid():
		close_dialog.call()
	return Callable()


func _is_future_date(year: int, month: int, day: int) -> bool:
	var now: Dictionary = Time.get_date_dict_from_system()
	var current_year: int = int(now.get("year", _get_current_year()))
	var current_month: int = int(now.get("month", 1))
	var current_day: int = int(now.get("day", 1))
	if year != current_year:
		return year > current_year
	if month != current_month:
		return month > current_month
	return day > current_day


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
