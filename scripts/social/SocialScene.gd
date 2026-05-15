extends Control

const FriendStageFormatter = preload("res://scripts/gamestate/GameStateBossStage.gd")
const BUTTON_BAR_TEXTURE = preload("res://assets/sprites/ui/common/button_bar_s_color2.png")
const BUTTON_BAR_TEXTURE_MEDIUM = preload("res://assets/sprites/ui/common/button_bar_m_color2.png")
const CONTENT_FULL_TEXTURE = preload("res://assets/sprites/ui/common/content_full_default_v1.png")

const PARTY_ACTION_BUTTON_SIZE := Vector2(92.0, 30.0)
const PARTY_CHEER_BUTTON_SIZE := Vector2(128.0, 32.0)
const PARTY_ROW_MIN_HEIGHT := 72.0
const PARTY_PENDING_INFO_ROW_MIN_HEIGHT := 118.0
const PARTY_EDIT_ICON := "\u270E"

signal party_navigation_changed(items: Array, active_key: String)
signal friend_navigation_changed(items: Array, active_key: String)

var _mode: String = "friend"
var _friend_list: Dictionary = {}
var _friend_inbox: Array = []
var _friend_outbox: Array = []
var _friend_gift_in_flight: bool = false
var _friend_section: String = "friends"
var _friend_overlay_mode: bool = false
var _party_detail: Dictionary = {}
var _party_cheer_status: Dictionary = {}
var _party_section: String = "overview"
var _party_overlay_mode: bool = false
var _party_applications: Array = []
var _party_my_applications: Array = []
var _party_cache_recovery_in_flight: bool = false
var _create_party_dialog_state: Dictionary = {}
var _invite_party_dialog_state: Dictionary = {}
var _rename_party_dialog_state: Dictionary = {}

var _root_box: Control
var _scroll: ScrollContainer
var _content_box: VBoxContainer
var _footer_panel: PanelContainer
var _party_overlay_background: TextureRect
var _friend_footer_buttons: Dictionary = {}
var _party_footer_buttons: Dictionary = {}


func set_mode(mode: String) -> void:
	_mode = mode


func set_party_overlay_mode(enabled: bool) -> void:
	_party_overlay_mode = enabled


func set_friend_overlay_mode(enabled: bool) -> void:
	_friend_overlay_mode = enabled


func get_friend_footer_items() -> Array:
	return _get_friend_footer_items()


func get_friend_section() -> String:
	return _friend_section


func set_friend_section(section_key: String) -> void:
	_on_friend_section_selected(section_key)


func get_party_footer_items() -> Array:
	return _get_party_footer_items()


func get_party_section() -> String:
	return _party_section


func set_party_section(section_key: String) -> void:
	_on_party_section_selected(section_key)


func _ready() -> void:
	if not _uses_overlay_layout():
		custom_minimum_size = Vector2(660.0, 960.0)
	GameState.social_state_changed.connect(_on_social_state_changed)
	_build_shell()
	_refresh_current()


func _build_shell() -> void:
	if _uses_overlay_layout():
		_root_box = Control.new()
		_root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(_root_box)

		_party_overlay_background = TextureRect.new()
		_party_overlay_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_party_overlay_background.texture = CONTENT_FULL_TEXTURE
		_party_overlay_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_party_overlay_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_party_overlay_background.stretch_mode = TextureRect.STRETCH_SCALE
		_root_box.add_child(_party_overlay_background)

		var content_margin: MarginContainer = OverlaySceneChrome.make_content_margin(22)
		content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_root_box.add_child(content_margin)

		_scroll = ScrollContainer.new()
		_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content_margin.add_child(_scroll)
		InertialScroller.attach(_scroll, "vertical")

		_content_box = VBoxContainer.new()
		_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_content_box.add_theme_constant_override("separation", 14)
		_scroll.add_child(_content_box)
		return

	var root_panel: PanelContainer = PanelContainer.new()
	root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_panel.add_theme_stylebox_override(
		"panel",
		OverlaySceneChrome.make_panel_style(
			OverlaySceneChrome.PANEL_FILL,
			OverlaySceneChrome.PANEL_BORDER,
			18
		)
	)
	add_child(root_panel)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	root_panel.add_child(margin)

	_root_box = VBoxContainer.new()
	_root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_box.add_theme_constant_override("separation", 12)
	margin.add_child(_root_box)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root_box.add_child(_scroll)
	InertialScroller.attach(_scroll, "vertical")

	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 14)
	_scroll.add_child(_content_box)

	_footer_panel = OverlaySceneChrome.make_card_panel()
	_footer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_panel.custom_minimum_size = Vector2(0.0, 56.0)
	_footer_panel.visible = false
	_root_box.add_child(_footer_panel)


func _uses_overlay_layout() -> bool:
	return (_mode == "party" and _party_overlay_mode) or (_mode == "friend" and _friend_overlay_mode)


func _is_party_overlay_panel_mode() -> bool:
	return _mode == "party" and _party_overlay_mode


func _is_overlay_panel_mode() -> bool:
	return _uses_overlay_layout()


func _refresh_current() -> void:
	if _mode == "party":
		_refresh_party()
		return
	_refresh_friend()


func _sync_friend_red_dot_summary() -> void:
	GameState.update_friend_red_dot_summary(
		RedDotService.build_friend_summary(_friend_list, _friend_inbox)
	)


func _sync_party_red_dot_summary() -> void:
	GameState.update_party_red_dot_summary(
		RedDotService.build_party_summary(_party_detail, _party_cheer_status, _party_applications)
	)


func _refresh_friend() -> void:
	_apply_friend_state_cache()
	_render_friend()


func _refresh_party() -> void:
	_apply_party_state_cache()
	_maybe_recover_party_cache()
	_reload_current_party_section()


func _apply_friend_state_cache() -> void:
	_friend_list = GameState.friend_list_data.duplicate(true)
	_friend_inbox = GameState.friend_inbox_data.duplicate(true)
	_friend_outbox = GameState.friend_outbox_data.duplicate(true)
	_sync_friend_red_dot_summary()


func _apply_party_state_cache() -> void:
	_party_detail = GameState.party_detail_data.duplicate(true)
	_party_cheer_status = GameState.party_cheer_status_data.duplicate(true)
	_party_applications = GameState.party_applications_data.duplicate(true)
	_party_my_applications = GameState.party_my_applications_data.duplicate(true)
	_sync_party_red_dot_summary()


func _maybe_recover_party_cache() -> void:
	if _party_cache_recovery_in_flight:
		return
	if not _party_detail.is_empty():
		return
	_party_cache_recovery_in_flight = true
	ApiClient.get_my_party_silent(Callable(self, "_on_recover_my_party_completed"))


func _recover_party_related_cache(party_detail: Dictionary, party_id: int) -> void:
	var _recovered_cheer_status: Dictionary = {}
	var recovered_applications: Array = []
	var recovered_my_applications: Array = []
	ApiClient.get_party_cheer_status_silent(
		party_id,
		Callable(self, "_on_recover_party_cheer_status_completed").bind(party_detail, party_id, recovered_applications, recovered_my_applications)
	)


func _on_recover_my_party_completed(success: bool, data: Variant, _error: Dictionary) -> void:
	if not success or not (data is Dictionary):
		ApiClient.get_my_party_applications_silent(Callable(self, "_on_recover_my_party_applications_only_completed"))
		return
	var party_detail: Dictionary = data
	var party_id: int = int(party_detail.get("partyId", 0))
	if party_id <= 0:
		GameState.update_party_social_data(party_detail, {}, [], [])
		_party_cache_recovery_in_flight = false
		return
	_recover_party_related_cache(party_detail, party_id)


func _on_recover_my_party_applications_only_completed(my_success: bool, my_data: Variant, _my_error: Dictionary) -> void:
	GameState.update_party_social_data({}, {}, [], my_data if my_success and my_data is Array else [])
	_party_cache_recovery_in_flight = false


func _on_recover_party_cheer_status_completed(
	cheer_success: bool,
	cheer_data: Variant,
	_my_error: Dictionary,
	party_detail: Dictionary,
	party_id: int,
	recovered_applications: Array,
	_recovered_my_applications_unused: Array
) -> void:
	var recovered_cheer_status: Dictionary = cheer_data if cheer_success and cheer_data is Dictionary else {}
	ApiClient.get_my_party_applications_silent(
		Callable(self, "_on_recover_my_party_applications_completed").bind(party_detail, party_id, recovered_cheer_status, recovered_applications)
	)


func _on_recover_my_party_applications_completed(
	my_success: bool,
	my_data: Variant,
	_my_error: Dictionary,
	party_detail: Dictionary,
	party_id: int,
	recovered_cheer_status: Dictionary,
	recovered_applications: Array
) -> void:
	var recovered_my_applications: Array = my_data if my_success and my_data is Array else []
	var leader_name: String = str(party_detail.get("leaderDisplayName", "")).strip_edges()
	var self_names: Array[String] = [
		str(GameState.player_data.display_name).strip_edges(),
		str(GameState.player_data.player_name).strip_edges(),
	]
	if leader_name in self_names:
		ApiClient.get_party_applications_silent(
			party_id,
			Callable(self, "_on_recover_party_applications_completed").bind(party_detail, recovered_cheer_status, recovered_my_applications)
		)
		return
	GameState.update_party_social_data(party_detail, recovered_cheer_status, recovered_applications, recovered_my_applications)
	_party_cache_recovery_in_flight = false


func _on_recover_party_applications_completed(
	app_success: bool,
	app_data: Variant,
	_app_error: Dictionary,
	party_detail: Dictionary,
	recovered_cheer_status: Dictionary,
	recovered_my_applications: Array
) -> void:
	var recovered_applications: Array = app_data if app_success and app_data is Array else []
	GameState.update_party_social_data(party_detail, recovered_cheer_status, recovered_applications, recovered_my_applications)
	_party_cache_recovery_in_flight = false


func _on_social_state_changed(domain_key: String) -> void:
	if domain_key == "friend" and _mode == "friend":
		_apply_friend_state_cache()
		_render_friend()
		return
	if domain_key == "party" and _mode == "party":
		_apply_party_state_cache()
		_reload_current_party_section()


func _clear_content() -> void:
	for child: Node in _content_box.get_children():
		child.queue_free()


func _render_friend() -> void:
	_refresh_overlay_background_visibility()
	_clear_content()
	_ensure_friend_section_valid()
	_render_friend_footer()
	match _friend_section:
		"inbox":
			_render_friend_inbox(_content_box)
			return
		"outbox":
			_render_friend_outbox(_content_box)
			return

	var friend_rows: Array = _friend_list.get("friends", [])
	if _uses_overlay_layout():
		_render_friend_overlay_list(_content_box, friend_rows)
		return

	var friends_card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	friends_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	friends_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_child(friends_card)

	var friends_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	friends_card.add_child(friends_margin)

	var friends_box: VBoxContainer = VBoxContainer.new()
	friends_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	friends_box.add_theme_constant_override("separation", 12)
	friends_margin.add_child(friends_box)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	friends_box.add_child(header_row)

	var count_label: Label = Label.new()
	var friend_cap: int = int(_friend_list.get("maxFriends", 30))
	count_label.text = UiText.SOCIAL_FRIEND_COUNT_FORMAT % [friend_rows.size(), friend_cap]
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	count_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	header_row.add_child(count_label)

	var bonus_label: Label = Label.new()
	bonus_label.text = UiText.SOCIAL_FRIEND_BONUS_FORMAT % friend_rows.size()
	bonus_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	bonus_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45, 1.0))
	friends_box.add_child(bonus_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	header_row.add_child(button_row)

	var add_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ADD, "confirm")
	add_button.custom_minimum_size = Vector2(164.0, 48.0)
	add_button.pressed.connect(_open_add_friend_dialog)
	button_row.add_child(add_button)

	var gift_button: Button = _make_action_button(
		UiText.SOCIAL_FRIEND_GIFT_SENT if bool(_friend_list.get("hasSentGiftToday", false)) else UiText.SOCIAL_FRIEND_GIFT_ALL,
		"confirm"
	)
	gift_button.custom_minimum_size = Vector2(164.0, 48.0)
	gift_button.disabled = _friend_gift_in_flight or friend_rows.is_empty() or bool(_friend_list.get("hasSentGiftToday", false))
	RedDotService.refresh_dot(gift_button, not gift_button.disabled and RedDotService.has_friend_send_all_gift_red_dot())
	gift_button.pressed.connect(_on_friend_gift_pressed)
	button_row.add_child(gift_button)

	if friend_rows.is_empty():
		var empty_center: CenterContainer = CenterContainer.new()
		empty_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_center.custom_minimum_size = Vector2(0.0, 220.0)
		friends_box.add_child(empty_center)
		empty_center.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in friend_rows:
		if not (item_variant is Dictionary):
			continue
		friends_box.add_child(_build_friend_row(item_variant))


func _render_friend_overlay_list(host: VBoxContainer, friend_rows: Array) -> void:
	var content_box: VBoxContainer = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 0)
	host.add_child(content_box)
	content_box.add_child(_make_vertical_spacer(10.0))

	var header_margin: MarginContainer = MarginContainer.new()
	header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_margin.add_theme_constant_override("margin_left", 30)
	header_margin.add_theme_constant_override("margin_right", 30)
	content_box.add_child(header_margin)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 12)
	header_margin.add_child(header_row)

	var left_group: HBoxContainer = HBoxContainer.new()
	left_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_group.alignment = BoxContainer.ALIGNMENT_BEGIN
	left_group.add_theme_constant_override("separation", 8)
	header_row.add_child(left_group)

	var title_label: Label = Label.new()
	title_label.text = UiText.SOCIAL_FRIEND_LIST
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	title_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	left_group.add_child(title_label)

	var count_label: Label = Label.new()
	count_label.text = UiText.SOCIAL_FRIEND_LIST_COUNT_FORMAT % friend_rows.size()
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	count_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	left_group.add_child(count_label)

	var bonus_label: Label = Label.new()
	bonus_label.text = UiText.SOCIAL_FRIEND_BONUS_FORMAT % friend_rows.size()
	bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	bonus_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45, 1.0))
	left_group.add_child(bonus_label)

	var add_button: Button = _make_action_button("+", "confirm")
	_style_party_overlay_button(add_button, Vector2(36.0, 32.0), UiPalette.FONT_SIZE_BODY_LG)
	add_button.pressed.connect(_open_add_friend_dialog)
	left_group.add_child(add_button)

	var gift_button: Button = _make_action_button(
		UiText.SOCIAL_FRIEND_GIFT_SENT if bool(_friend_list.get("hasSentGiftToday", false)) else UiText.SOCIAL_FRIEND_GIFT_ALL,
		"confirm"
	)
	_style_party_overlay_button(gift_button, Vector2(128.0, 48.0))
	gift_button.disabled = _friend_gift_in_flight or friend_rows.is_empty() or bool(_friend_list.get("hasSentGiftToday", false))
	RedDotService.refresh_dot(gift_button, not gift_button.disabled and RedDotService.has_friend_send_all_gift_red_dot())
	gift_button.pressed.connect(_on_friend_gift_pressed)
	header_row.add_child(gift_button)

	if friend_rows.is_empty():
		var empty_center: CenterContainer = CenterContainer.new()
		empty_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_center.custom_minimum_size = Vector2(0.0, 220.0)
		content_box.add_child(empty_center)
		empty_center.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in friend_rows:
		if item_variant is Dictionary:
			content_box.add_child(_build_friend_row(item_variant))


func _render_friend_footer() -> void:
	_notify_friend_navigation_changed()
	if _uses_overlay_layout():
		return
	if _footer_panel == null:
		return
	_footer_panel.visible = true
	var submenu: Dictionary = ContentBottomSubmenu.build(self, {
		"panel": _footer_panel,
		"items": _get_friend_footer_items(),
		"active_key": _friend_section,
		"button_pressed": Callable(self, "_on_friend_section_selected"),
	})
	_friend_footer_buttons = submenu.get("buttons", {})


func _get_friend_footer_items() -> Array:
	return [
		{
			"key": "friends",
			"label": UiText.SOCIAL_FRIEND_LIST,
			"shell_description": UiText.SOCIAL_FRIEND_LIST_DESC,
			"shell_summary_right": Callable(self, "_build_friend_footer_summary").bind("friends"),
		},
		{
			"key": "inbox",
			"label": UiText.SOCIAL_FRIEND_INBOX,
			"shell_description": UiText.SOCIAL_FRIEND_INBOX_DESC,
			"shell_summary_right": Callable(self, "_build_friend_footer_summary").bind("inbox"),
		},
		{
			"key": "outbox",
			"label": UiText.SOCIAL_FRIEND_OUTBOX,
			"shell_description": UiText.SOCIAL_FRIEND_OUTBOX_DESC,
			"shell_summary_right": Callable(self, "_build_friend_footer_summary").bind("outbox"),
		},
	]


func _ensure_friend_section_valid() -> void:
	for item_variant: Variant in _get_friend_footer_items():
		if item_variant is Dictionary and str((item_variant as Dictionary).get("key", "")) == _friend_section:
			return
	_friend_section = "friends"


func _on_friend_section_selected(section_key: String) -> void:
	if _friend_section == section_key:
		return
	_friend_section = section_key
	_refresh_friend_footer_buttons()
	_render_friend()


func _refresh_friend_footer_buttons() -> void:
	if _uses_overlay_layout():
		return
	ContentBottomSubmenu.refresh(_friend_footer_buttons, _friend_section)


func _notify_friend_navigation_changed() -> void:
	friend_navigation_changed.emit(_get_friend_footer_items(), _friend_section)


func _render_friend_inbox(host: VBoxContainer) -> void:
	if _is_overlay_panel_mode():
		var overlay_box: VBoxContainer = VBoxContainer.new()
		overlay_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_theme_constant_override("separation", 0)
		host.add_child(overlay_box)

		if _friend_inbox.is_empty():
			overlay_box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
			return

		for item_variant: Variant in _friend_inbox:
			if item_variant is Dictionary:
				overlay_box.add_child(_build_friend_inbox_row(item_variant))
		return

	var box: VBoxContainer = _make_party_section_box(
		host,
		UiText.SOCIAL_FRIEND_INBOX,
		UiText.SOCIAL_FRIEND_INBOX_DESC
	)

	if _friend_inbox.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in _friend_inbox:
		if item_variant is Dictionary:
			box.add_child(_build_friend_inbox_row(item_variant))


func _render_friend_outbox(host: VBoxContainer) -> void:
	if _is_overlay_panel_mode():
		var overlay_box: VBoxContainer = VBoxContainer.new()
		overlay_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_theme_constant_override("separation", 0)
		host.add_child(overlay_box)

		if _friend_outbox.is_empty():
			overlay_box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
			return

		for item_variant: Variant in _friend_outbox:
			if item_variant is Dictionary:
				overlay_box.add_child(_build_friend_outbox_row(item_variant))
		return

	var box: VBoxContainer = _make_party_section_box(
		host,
		UiText.SOCIAL_FRIEND_OUTBOX,
		UiText.SOCIAL_FRIEND_OUTBOX_DESC
	)

	if _friend_outbox.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in _friend_outbox:
		if item_variant is Dictionary:
			box.add_child(_build_friend_outbox_row(item_variant))


func _render_party() -> void:
	_refresh_overlay_background_visibility()
	_clear_content()
	_ensure_party_section_valid()
	_render_party_footer()
	if _party_section == "invites":
		if _party_detail.is_empty():
			_render_my_party_invites(_content_box)
		else:
			_render_party_pending_invites(_content_box)
		return
	if _party_section == "reviews":
		if _party_detail.is_empty():
			_render_my_party_reviews(_content_box)
		else:
			_render_party_reviews(_content_box)
		return
	_render_party_overview(_content_box)


func _refresh_overlay_background_visibility() -> void:
	if _party_overlay_background == null:
		return
	if _mode == "party" and _party_overlay_mode:
		_party_overlay_background.visible = _party_section != "invites" and _party_section != "reviews"
		return
	if _mode == "friend" and _friend_overlay_mode:
		_party_overlay_background.visible = _friend_section != "inbox" and _friend_section != "outbox"
		return
	_party_overlay_background.visible = true


func _render_party_footer() -> void:
	_notify_party_navigation_changed()
	if _party_overlay_mode:
		return
	if _footer_panel == null:
		return
	_footer_panel.visible = true
	var submenu: Dictionary = ContentBottomSubmenu.build(self, {
		"panel": _footer_panel,
		"items": _get_party_footer_items(),
		"active_key": _party_section,
		"button_pressed": Callable(self, "_on_party_section_selected"),
	})
	_party_footer_buttons = submenu.get("buttons", {})


func _on_party_section_selected(section_key: String) -> void:
	if _party_section == section_key:
		return
	_party_section = section_key
	_refresh_party_footer_buttons()
	_reload_current_party_section()


func _refresh_party_footer_buttons() -> void:
	if _party_overlay_mode:
		return
	ContentBottomSubmenu.refresh(_party_footer_buttons, _party_section)


func _get_party_footer_items() -> Array:
	return [
		{
			"key": "overview",
			"label": UiText.SOCIAL_PARTY_OVERVIEW,
			"shell_description": UiText.SOCIAL_PARTY_OVERLAY_DESC,
			"shell_summary_right": Callable(self, "_build_party_footer_summary").bind("overview"),
		},
		{
			"key": "invites",
			"label": UiText.SOCIAL_PARTY_PENDING_INVITES,
			"shell_description": UiText.SOCIAL_PARTY_PENDING_INVITES_DESC,
			"shell_summary_right": Callable(self, "_build_party_footer_summary").bind("invites"),
		},
		{
			"key": "reviews",
			"label": UiText.SOCIAL_PARTY_PENDING_REVIEW,
			"shell_description": UiText.SOCIAL_PARTY_PENDING_REVIEW_DESC,
			"shell_summary_right": Callable(self, "_build_party_footer_summary").bind("reviews"),
		},
	]


func _ensure_party_section_valid() -> void:
	for item_variant: Variant in _get_party_footer_items():
		if item_variant is Dictionary and str((item_variant as Dictionary).get("key", "")) == _party_section:
			return
	_party_section = "overview"


func _reload_current_party_section() -> void:
	_ensure_party_section_valid()
	if _party_section == "invites":
		if _party_detail.is_empty():
			_load_my_party_applications()
		else:
			_load_party_applications()
		return
	if _party_section == "reviews":
		if _party_detail.is_empty():
			_load_my_party_applications()
		else:
			_load_party_applications()
		return
	_render_party()


func _notify_party_navigation_changed() -> void:
	party_navigation_changed.emit(_get_party_footer_items(), _party_section)


func _get_my_pending_party_invites() -> Array:
	return _party_my_applications.filter(Callable(self, "_is_pending_my_party_invite"))


func _get_my_pending_party_reviews() -> Array:
	return _party_my_applications.filter(Callable(self, "_is_pending_my_party_review"))


func _is_pending_my_party_invite(item_variant: Variant) -> bool:
	if not (item_variant is Dictionary):
		return false
	var item: Dictionary = item_variant as Dictionary
	return _is_party_invite_type(int(item.get("applicationType", 0))) and int(item.get("status", 0)) == 0


func _is_pending_my_party_review(item_variant: Variant) -> bool:
	if not (item_variant is Dictionary):
		return false
	var item: Dictionary = item_variant as Dictionary
	return _is_party_player_apply_type(int(item.get("applicationType", 0))) and int(item.get("status", 0)) == 0


func _build_friend_footer_summary(section_key: String) -> String:
	match section_key:
		"inbox":
			return UiText.SOCIAL_FRIEND_APPLY_COUNT_FORMAT % _friend_inbox.size()
		"outbox":
			return UiText.SOCIAL_FRIEND_SENT_COUNT_FORMAT % _friend_outbox.size()
		_:
			var friends: Array = _friend_list.get("friends", [])
			return UiText.SOCIAL_FRIEND_LIST_COUNT_FORMAT % friends.size()


func _build_party_footer_summary(section_key: String) -> String:
	match section_key:
		"invites":
			var invite_count: int = _get_my_pending_party_invites().size() if _party_detail.is_empty() else _get_party_pending_invites().size()
			return UiText.SOCIAL_PARTY_PENDING_COUNT_FORMAT % invite_count
		"reviews":
			var review_count: int = _get_my_pending_party_reviews().size() if _party_detail.is_empty() else _get_party_pending_reviews().size()
			return UiText.SOCIAL_PARTY_PENDING_COUNT_FORMAT % review_count
		_:
			if _party_detail.is_empty():
				return UiText.SOCIAL_PARTY_NOT_IN_PARTY
			var members: Array = _party_detail.get("members", [])
			return UiText.SOCIAL_PARTY_MEMBER_COUNT_FORMAT % members.size()


func _get_party_pending_reviews() -> Array:
	return _party_applications.filter(Callable(self, "_is_pending_party_review"))


func _get_party_pending_invites() -> Array:
	return _party_applications.filter(Callable(self, "_is_pending_party_invite"))


func _is_pending_party_review(item_variant: Variant) -> bool:
	return item_variant is Dictionary and _is_party_player_apply_type(int((item_variant as Dictionary).get("applicationType", 0)))


func _is_pending_party_invite(item_variant: Variant) -> bool:
	if not (item_variant is Dictionary):
		return false
	var item: Dictionary = item_variant as Dictionary
	return _is_party_invite_type(int(item.get("applicationType", 0))) and int(item.get("status", 0)) == 0


func _load_party_applications() -> void:
	_apply_party_state_cache()
	_render_party()


func _load_my_party_applications() -> void:
	_apply_party_state_cache()
	_render_party()


func _render_party_overview(host: VBoxContainer) -> void:
	if _party_detail.is_empty():
		_render_party_empty(host)
		return
	_render_party_detail(host)


func _render_party_empty(host: VBoxContainer) -> void:
	_make_party_section_box(
		host,
		UiText.SOCIAL_PARTY_EMPTY,
		UiText.SOCIAL_PARTY_EMPTY_DESC,
		OverlaySceneChrome.PANEL_BORDER
	)

	host.add_child(_build_party_input_card(
		UiText.SOCIAL_PARTY_CREATE,
		UiText.SOCIAL_PARTY_CREATE_DESC,
		UiText.SOCIAL_PARTY_NAME_PLACEHOLDER,
		UiText.SOCIAL_PARTY_CREATE,
		"confirm",
		Callable(self, "_submit_create_party_inline")
	))
	host.add_child(_build_party_input_card(
		UiText.SOCIAL_PARTY_APPLY,
		UiText.SOCIAL_PARTY_APPLY_DESC,
		UiText.SOCIAL_PARTY_SEARCH_PLACEHOLDER,
		UiText.SOCIAL_PARTY_APPLY,
		"secondary",
		Callable(self, "_submit_apply_party_inline")
	))


func _render_party_detail(host: VBoxContainer) -> void:
	if _is_party_overlay_panel_mode():
		_render_party_detail_overlay(host)
		return

	var header_card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	header_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(header_card)

	var header_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	header_card.add_child(header_margin)

	var header_box: VBoxContainer = VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 12)
	header_margin.add_child(header_box)

	var members: Array = _party_detail.get("members", [])
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	header_box.add_child(title_row)

	var title: Label = Label.new()
	title.text = "%s (%d/5)" % [str(_party_detail.get("name", "")), members.size()]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	title_row.add_child(title)

	if _is_party_leader():
		var rename_button: Button = _make_action_button(UiText.SOCIAL_PARTY_RENAME, "secondary")
		rename_button.custom_minimum_size = Vector2(140.0, 48.0)
		rename_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		rename_button.pressed.connect(_open_rename_party_dialog)
		title_row.add_child(rename_button)

	var subline: Label = Label.new()
	subline.text = UiText.SOCIAL_PARTY_LEADER_FORMAT % str(_party_detail.get("leaderDisplayName", ""))
	subline.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	subline.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	header_box.add_child(subline)

	var quick_row: HBoxContainer = HBoxContainer.new()
	quick_row.add_theme_constant_override("separation", 10)
	header_box.add_child(quick_row)

	var invite_button: Button = _make_action_button(UiText.SOCIAL_PARTY_INVITE, "add")
	invite_button.pressed.connect(_open_invite_party_dialog)
	quick_row.add_child(invite_button)

	var leave_button: Button = _make_action_button(
		_get_party_exit_button_text(),
		"danger"
	)
	leave_button.pressed.connect(_on_party_exit_pressed)
	quick_row.add_child(leave_button)

	var member_card: PanelContainer = OverlaySceneChrome.make_card_panel()
	member_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(member_card)

	var member_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	member_card.add_child(member_margin)

	var member_box: VBoxContainer = VBoxContainer.new()
	member_box.add_theme_constant_override("separation", 10)
	member_margin.add_child(member_box)

	var member_header: HBoxContainer = HBoxContainer.new()
	member_header.add_theme_constant_override("separation", 10)
	member_box.add_child(member_header)

	var member_title: Label = Label.new()
	member_title.text = UiText.SOCIAL_PARTY_MEMBER_LIST
	member_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	member_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	member_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	member_header.add_child(member_title)

	member_header.add_child(_build_party_cheer_button())

	for member_variant: Variant in members:
		if member_variant is Dictionary:
			member_box.add_child(_build_party_member_row(member_variant))


func _render_party_detail_overlay(host: VBoxContainer) -> void:
	_render_party_detail_overlay_content(host)
	return

func _render_party_detail_overlay_content(host: VBoxContainer) -> void:
	var members: Array = _party_detail.get("members", [])
	var content_box: VBoxContainer = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 12)
	host.add_child(content_box)

	var title_margin: MarginContainer = MarginContainer.new()
	title_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_margin.add_theme_constant_override("margin_left", 30)
	title_margin.add_theme_constant_override("margin_right", 30)
	content_box.add_child(title_margin)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 8)
	title_margin.add_child(title_row)

	var title_left_spacer: Control = Control.new()
	title_left_spacer.custom_minimum_size = Vector2(36.0, 0.0)
	title_row.add_child(title_left_spacer)

	var title: Label = Label.new()
	title.text = str(_party_detail.get("name", "")).strip_edges()
	if title.text == "":
		title.text = UiText.SOCIAL_PARTY_OVERVIEW
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	title_row.add_child(title)

	if _is_party_leader():
		var rename_button: Button = _make_action_button(PARTY_EDIT_ICON, "secondary")
		_style_party_overlay_button(rename_button, Vector2(36.0, 36.0), 18)
		rename_button.pressed.connect(_open_rename_party_dialog)
		title_row.add_child(rename_button)
	else:
		var title_right_spacer: Control = Control.new()
		title_right_spacer.custom_minimum_size = Vector2(36.0, 0.0)
		title_row.add_child(title_right_spacer)

	var title_separator: ColorRect = ColorRect.new()
	title_separator.color = OverlaySceneChrome.PANEL_BORDER
	title_separator.custom_minimum_size = Vector2(0.0, 1.0)
	title_separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_child(title_separator)

	var member_header_margin: MarginContainer = MarginContainer.new()
	member_header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	member_header_margin.add_theme_constant_override("margin_left", 30)
	member_header_margin.add_theme_constant_override("margin_right", 30)
	content_box.add_child(member_header_margin)

	var member_header: HBoxContainer = HBoxContainer.new()
	member_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	member_header.custom_minimum_size = Vector2(0.0, 34.0)
	member_header.alignment = BoxContainer.ALIGNMENT_CENTER
	member_header.add_theme_constant_override("separation", 12)
	member_header_margin.add_child(member_header)

	var member_title: Label = Label.new()
	member_title.text = UiText.SOCIAL_PARTY_MEMBER_LIST
	member_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	member_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	member_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	member_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	member_header.add_child(member_title)
	member_header.add_child(_build_party_cheer_button())

	for slot_entry: Dictionary in _build_party_member_slots(members):
		content_box.add_child(_build_party_member_slot_row(
			str(slot_entry.get("slot_label", "")),
			slot_entry.get("member", {}) as Dictionary
		))


func _render_party_reviews(host: VBoxContainer) -> void:
	var box: VBoxContainer
	if _is_party_overlay_panel_mode():
		box = VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 12)
		host.add_child(box)
	else:
		box = _make_party_section_box(host, UiText.SOCIAL_PARTY_PENDING_REVIEW)

		if not _is_party_leader():
			var hint: Label = Label.new()
			hint.text = UiText.SOCIAL_PARTY_REVIEW_HINT
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
			hint.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
			box.add_child(hint)

	var review_items: Array = _get_party_pending_reviews()
	if review_items.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in review_items:
		if item_variant is Dictionary:
			box.add_child(_build_party_review_row(item_variant, not _is_party_leader()))


func _render_my_party_invites(host: VBoxContainer) -> void:
	var box: VBoxContainer = _make_party_section_box(
		host,
		UiText.SOCIAL_PARTY_PENDING_INVITES,
		UiText.SOCIAL_PARTY_PENDING_INVITES_DESC
	)

	var invite_items: Array = _get_my_pending_party_invites()
	if invite_items.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in invite_items:
		if item_variant is Dictionary:
			box.add_child(_build_my_party_invite_row(item_variant))


func _render_party_pending_invites(host: VBoxContainer) -> void:
	if _is_party_overlay_panel_mode():
		var overlay_box: VBoxContainer = VBoxContainer.new()
		overlay_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_box.add_theme_constant_override("separation", 12)
		host.add_child(overlay_box)

		var overlay_invite_items: Array = _get_party_pending_invites()
		if overlay_invite_items.is_empty():
			overlay_box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
			return

		for item_variant: Variant in overlay_invite_items:
			if item_variant is Dictionary:
				overlay_box.add_child(_build_party_pending_invite_overlay_row(item_variant))
		return

	var card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(card)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	card.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = UiText.SOCIAL_PARTY_PENDING_INVITES
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.SOCIAL_PARTY_SENT_INVITE_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(desc)

	var invite_items: Array = _get_party_pending_invites()
	if invite_items.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in invite_items:
		if item_variant is Dictionary:
			box.add_child(_build_party_pending_invite_row(item_variant))


func _render_my_party_reviews(host: VBoxContainer) -> void:
	var box: VBoxContainer = _make_party_section_box(
		host,
		UiText.SOCIAL_PARTY_PENDING_REVIEW,
		UiText.SOCIAL_PARTY_PENDING_REVIEW_DESC
	)

	var review_items: Array = _get_my_pending_party_reviews()
	if review_items.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in review_items:
		if item_variant is Dictionary:
			box.add_child(_build_my_party_review_row(item_variant))


func _build_party_review_row(item_variant: Variant, read_only: bool = false) -> Control:
	var item: Dictionary = item_variant
	var shell: Dictionary = _create_party_row_shell(
		PARTY_PENDING_INFO_ROW_MIN_HEIGHT,
		OverlaySceneChrome.CARD_BORDER,
		BUTTON_BAR_TEXTURE_MEDIUM,
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control
	RedDotService.refresh_dot(root, not read_only)

	if _is_party_overlay_panel_mode():
		var left_box: VBoxContainer = VBoxContainer.new()
		left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		left_box.size_flags_stretch_ratio = 1.15
		left_box.alignment = BoxContainer.ALIGNMENT_CENTER
		left_box.add_theme_constant_override("separation", 4)
		row.add_child(left_box)

		var counterpart_label: Label = Label.new()
		counterpart_label.text = _party_application_counterpart_name(item)
		_configure_party_pending_info_label(counterpart_label, UiPalette.FONT_SIZE_BODY_LG, OverlaySceneChrome.TITLE_TEXT_COLOR)
		left_box.add_child(counterpart_label)

		var middle_box: VBoxContainer = VBoxContainer.new()
		middle_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		middle_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		middle_box.size_flags_stretch_ratio = 1.0
		middle_box.alignment = BoxContainer.ALIGNMENT_CENTER
		middle_box.add_theme_constant_override("separation", 4)
		row.add_child(middle_box)

		var inviter_name_label: Label = Label.new()
		inviter_name_label.text = UiText.SOCIAL_PARTY_INVITER_FORMAT % _party_application_inviter_name(item)
		_configure_party_pending_info_label(inviter_name_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.TITLE_TEXT_COLOR)
		middle_box.add_child(inviter_name_label)

		var inviter_time_label: Label = Label.new()
		inviter_time_label.text = UiText.SOCIAL_PARTY_INVITE_TIME_FORMAT % _format_relative_datetime(item.get("createdAtUtc", null))
		_configure_party_pending_info_label(inviter_time_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
		middle_box.add_child(inviter_time_label)

		var right_box: VBoxContainer = VBoxContainer.new()
		right_box.custom_minimum_size = Vector2(110.0, 0.0)
		right_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		right_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(right_box)

		var overlay_status_label: Label = Label.new()
		overlay_status_label.text = UiText.SOCIAL_PARTY_WAITING_RESPONSE
		overlay_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		overlay_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_configure_party_pending_info_label(overlay_status_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
		overlay_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		overlay_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		right_box.add_child(overlay_status_label)

		var stage_row_label: Label = Label.new()
		stage_row_label.text = _party_application_progress_line(item)
		_configure_party_pending_info_label(stage_row_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
		left_box.add_child(stage_row_label)

		return root

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var name_label: Label = Label.new()
	name_label.text = UiText.SOCIAL_PARTY_COUNTERPART_FORMAT % _party_application_counterpart_name(item)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var stage_label: Label = Label.new()
	stage_label.text = UiText.SOCIAL_PARTY_SCOOPER_STAGE_FORMAT % [
		_party_application_scooper_level_text(item),
		_party_application_stage_text(item),
	]
	stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	stage_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(stage_label)

	var inviter_label: Label = Label.new()
	inviter_label.text = UiText.SOCIAL_PARTY_INVITER_TIME_FORMAT % [
		_party_application_inviter_name(item),
		_format_relative_datetime(item.get("createdAtUtc", null)),
	]
	inviter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inviter_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	inviter_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(inviter_label)

	var status_label: Label = Label.new()
	status_label.text = UiText.SOCIAL_PARTY_WAITING_RESPONSE
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	status_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(status_label)

	if read_only:
		var readonly_label: Label = Label.new()
		readonly_label.text = UiText.SOCIAL_PARTY_LEADER_ONLY_REVIEW
		readonly_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		readonly_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		row.add_child(readonly_label)
		return root

	var accept_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ACCEPT, "confirm")
	_style_party_overlay_button(accept_button, PARTY_ACTION_BUTTON_SIZE)
	RedDotService.refresh_dot(accept_button, true)
	accept_button.pressed.connect(Callable(self, "_accept_party_application").bind(int(item.get("applicationId", 0)), str(item.get("applicantDisplayName", ""))))
	row.add_child(accept_button)

	var reject_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REJECT, "secondary")
	_style_party_overlay_button(reject_button, PARTY_ACTION_BUTTON_SIZE)
	reject_button.pressed.connect(Callable(self, "_confirm_reject_party_application").bind(int(item.get("applicationId", 0)), str(item.get("applicantDisplayName", ""))))
	row.add_child(reject_button)

	return root


func _build_my_party_invite_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var shell: Dictionary = _create_party_row_shell()
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var party_name_label: Label = Label.new()
	party_name_label.text = str(item.get("partyName", ""))
	party_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	party_name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	party_name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(party_name_label)

	var meta_label: Label = Label.new()
	meta_label.text = UiText.SOCIAL_PARTY_INVITE_META_FORMAT % [
		_party_application_type_text(int(item.get("applicationType", 0))),
		str(item.get("inviterDisplayName", "")).strip_edges() if str(item.get("inviterDisplayName", "")).strip_edges() != "" else UiText.SOCIAL_PARTY_MEMBER_FALLBACK
	]
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	meta_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(meta_label)

	var time_label: Label = Label.new()
	time_label.text = UiText.SOCIAL_PARTY_APPLICATION_TIME_FORMAT % _format_relative_datetime(item.get("createdAtUtc", null))
	time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	var accept_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ACCEPT, "confirm")
	_style_party_overlay_button(accept_button, PARTY_ACTION_BUTTON_SIZE)
	accept_button.pressed.connect(Callable(self, "_accept_party_invite").bind(int(item.get("applicationId", 0)), str(item.get("partyName", ""))))
	row.add_child(accept_button)

	var reject_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REJECT, "secondary")
	_style_party_overlay_button(reject_button, PARTY_ACTION_BUTTON_SIZE)
	reject_button.pressed.connect(Callable(self, "_confirm_reject_party_invite").bind(int(item.get("applicationId", 0)), str(item.get("partyName", ""))))
	row.add_child(reject_button)

	return root


func _build_my_party_review_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var shell: Dictionary = _create_party_row_shell()
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var party_name_label: Label = Label.new()
	party_name_label.text = str(item.get("partyName", ""))
	party_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	party_name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	party_name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(party_name_label)

	var meta_label: Label = Label.new()
	meta_label.text = _party_application_type_text(int(item.get("applicationType", 0)))
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	meta_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(meta_label)

	var time_label: Label = Label.new()
	time_label.text = UiText.SOCIAL_PARTY_APPLICATION_TIME_FORMAT % _format_relative_datetime(item.get("createdAtUtc", null))
	time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	var cancel_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_CANCEL, "secondary")
	_style_party_overlay_button(cancel_button, PARTY_ACTION_BUTTON_SIZE)
	cancel_button.pressed.connect(Callable(self, "_cancel_party_application").bind(int(item.get("applicationId", 0)), str(item.get("partyName", ""))))
	row.add_child(cancel_button)

	return root


func _build_party_pending_invite_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var shell: Dictionary = _create_party_row_shell(PARTY_ROW_MIN_HEIGHT, OverlaySceneChrome.CARD_BORDER, BUTTON_BAR_TEXTURE_MEDIUM)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var player_name_label: Label = Label.new()
	player_name_label.text = str(item.get("applicantDisplayName", "")).strip_edges()
	if player_name_label.text == "":
		player_name_label.text = UiText.SOCIAL_PLAYER_UNNAMED
	player_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	player_name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(player_name_label)

	var meta_label: Label = Label.new()
	meta_label.text = UiText.SOCIAL_PARTY_INVITE_META_FORMAT % [
		_party_application_type_text(int(item.get("applicationType", 0))),
		str(item.get("inviterDisplayName", "")).strip_edges() if str(item.get("inviterDisplayName", "")).strip_edges() != "" else UiText.SOCIAL_PARTY_MEMBER_FALLBACK
	]
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	meta_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(meta_label)

	var time_label: Label = Label.new()
	time_label.text = UiText.SOCIAL_PARTY_INVITE_TIME_FORMAT % _format_relative_datetime(item.get("createdAtUtc", null))
	time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	var readonly_label: Label = Label.new()
	readonly_label.text = UiText.SOCIAL_PARTY_WAITING_RESPONSE_ALT
	readonly_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	readonly_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	row.add_child(readonly_label)

	return root


func _build_party_pending_invite_overlay_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var shell: Dictionary = _create_party_row_shell(
		PARTY_PENDING_INFO_ROW_MIN_HEIGHT,
		OverlaySceneChrome.CARD_BORDER,
		BUTTON_BAR_TEXTURE_MEDIUM,
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	var left_box: VBoxContainer = VBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_box.size_flags_stretch_ratio = 1.15
	left_box.alignment = BoxContainer.ALIGNMENT_CENTER
	left_box.add_theme_constant_override("separation", 4)
	row.add_child(left_box)

	var counterpart_label: Label = Label.new()
	counterpart_label.text = _party_application_counterpart_name(item)
	_configure_party_pending_info_label(counterpart_label, UiPalette.FONT_SIZE_BODY_LG, OverlaySceneChrome.TITLE_TEXT_COLOR)
	left_box.add_child(counterpart_label)

	var stage_label: Label = Label.new()
	stage_label.text = _party_application_progress_line(item)
	_configure_party_pending_info_label(stage_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
	left_box.add_child(stage_label)

	var middle_box: VBoxContainer = VBoxContainer.new()
	middle_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	middle_box.size_flags_stretch_ratio = 1.0
	middle_box.alignment = BoxContainer.ALIGNMENT_CENTER
	middle_box.add_theme_constant_override("separation", 4)
	row.add_child(middle_box)

	var inviter_name_label: Label = Label.new()
	inviter_name_label.text = UiText.SOCIAL_PARTY_INVITER_FORMAT % _party_application_inviter_name(item)
	_configure_party_pending_info_label(inviter_name_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.TITLE_TEXT_COLOR)
	middle_box.add_child(inviter_name_label)

	var inviter_time_label: Label = Label.new()
	inviter_time_label.text = UiText.SOCIAL_PARTY_INVITE_TIME_FORMAT % _format_relative_datetime(item.get("createdAtUtc", null))
	_configure_party_pending_info_label(inviter_time_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
	middle_box.add_child(inviter_time_label)

	var right_box: VBoxContainer = VBoxContainer.new()
	right_box.custom_minimum_size = Vector2(110.0, 0.0)
	right_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right_box)

	var status_label: Label = Label.new()
	status_label.text = UiText.SOCIAL_PARTY_WAITING_RESPONSE
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_configure_party_pending_info_label(status_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right_box.add_child(status_label)

	return root


func _build_friend_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var shell: Dictionary
	if _is_overlay_panel_mode():
		shell = _create_party_row_shell(
			PARTY_PENDING_INFO_ROW_MIN_HEIGHT,
			OverlaySceneChrome.CARD_BORDER,
			BUTTON_BAR_TEXTURE_MEDIUM,
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
	else:
		shell = _create_party_row_shell(92.0)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	if _is_overlay_panel_mode():
		var overlay_remove_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REMOVE, "danger")
		_style_party_overlay_button(overlay_remove_button, Vector2(72.0, 30.0))
		overlay_remove_button.pressed.connect(Callable(self, "_confirm_remove_friend").bind(int(item.get("friendUserId", 0)), str(item.get("displayName", ""))))
		row.add_child(overlay_remove_button)

	var avatar_id: String = str(item.get("avatarId", "")).strip_edges()
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(56.0, 56.0)
	)
	AssetResolver.apply_profile_avatar_texture(avatar_rect, avatar_id)
	row.add_child(avatar_rect)

	if _is_overlay_panel_mode():
		var overlay_info_box: VBoxContainer = VBoxContainer.new()
		overlay_info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		overlay_info_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		overlay_info_box.alignment = BoxContainer.ALIGNMENT_CENTER
		overlay_info_box.add_theme_constant_override("separation", 4)
		row.add_child(overlay_info_box)

		var overlay_name_label: Label = Label.new()
		overlay_name_label.text = str(item.get("displayName", "")).strip_edges()
		if overlay_name_label.text == "":
			overlay_name_label.text = UiText.SOCIAL_PLAYER_UNNAMED
		_configure_party_pending_info_label(overlay_name_label, UiPalette.FONT_SIZE_BODY_LG, OverlaySceneChrome.TITLE_TEXT_COLOR)
		overlay_info_box.add_child(overlay_name_label)

		var overlay_meta_label: Label = Label.new()
		overlay_meta_label.text = UiText.SOCIAL_SCOOPER_LEVEL_FORMAT % [
			int(item.get("scooperLevel", 0)),
			_format_friend_stage_text(item.get("currentStage", 1))
		]
		_configure_party_pending_info_label(overlay_meta_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
		overlay_info_box.add_child(overlay_meta_label)

		var right_box: VBoxContainer = VBoxContainer.new()
		right_box.custom_minimum_size = Vector2(150.0, 0.0)
		right_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		right_box.alignment = BoxContainer.ALIGNMENT_CENTER
		right_box.add_theme_constant_override("separation", 4)
		row.add_child(right_box)

		var overlay_last_login_label: Label = Label.new()
		overlay_last_login_label.text = UiText.SOCIAL_LAST_LOGIN_FORMAT % _format_last_login_text(item.get("lastLoginAtUtc", null))
		_configure_party_pending_info_label(overlay_last_login_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.TITLE_TEXT_COLOR)
		overlay_last_login_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_box.add_child(overlay_last_login_label)

		var overlay_gift_status_label: Label = Label.new()
		var overlay_gift_sent_today: bool = bool(item.get("giftSentToday", false))
		overlay_gift_status_label.text = UiText.SOCIAL_FRIEND_GIFT_STATUS_SENT if overlay_gift_sent_today else UiText.SOCIAL_FRIEND_GIFT_STATUS_UNSENT
		_configure_party_pending_info_label(
			overlay_gift_status_label,
			UiPalette.FONT_SIZE_LABEL,
			OverlaySceneChrome.MUTED_TEXT_COLOR if overlay_gift_sent_today else UiPalette.BUTTON_PRIMARY_BG
		)
		overlay_gift_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_box.add_child(overlay_gift_status_label)

		return root

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var name_label: Label = Label.new()
	name_label.text = str(item.get("displayName", "")).strip_edges()
	if name_label.text == "":
		name_label.text = UiText.SOCIAL_PLAYER_UNNAMED
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var meta_label: Label = Label.new()
	meta_label.text = UiText.SOCIAL_SCOOPER_LEVEL_FORMAT_ALT % [
		int(item.get("scooperLevel", 0)),
		_format_friend_stage_text(item.get("currentStage", 1))
	]
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	meta_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(meta_label)

	var last_login_label: Label = Label.new()
	last_login_label.text = UiText.SOCIAL_LAST_LOGIN_FORMAT % _format_last_login_text(item.get("lastLoginAtUtc", null))
	last_login_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_login_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	last_login_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(last_login_label)

	var gift_sent_today: bool = bool(item.get("giftSentToday", false))
	var gift_status_label: Label = Label.new()
	gift_status_label.text = UiText.SOCIAL_FRIEND_GIFT_STATUS_SENT if gift_sent_today else UiText.SOCIAL_FRIEND_GIFT_STATUS_UNSENT
	gift_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gift_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gift_status_label.custom_minimum_size = Vector2(96.0, 0.0)
	gift_status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	gift_status_label.add_theme_color_override(
		"font_color",
		OverlaySceneChrome.MUTED_TEXT_COLOR if gift_sent_today else UiPalette.BUTTON_PRIMARY_BG
	)
	row.add_child(gift_status_label)

	var remove_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REMOVE, "secondary")
	_style_party_overlay_button(remove_button, PARTY_ACTION_BUTTON_SIZE)
	remove_button.pressed.connect(Callable(self, "_confirm_remove_friend").bind(int(item.get("friendUserId", 0)), str(item.get("displayName", ""))))
	row.add_child(remove_button)

	return root


func _build_friend_inbox_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var shell: Dictionary
	if _is_overlay_panel_mode():
		shell = _create_party_row_shell(
			PARTY_PENDING_INFO_ROW_MIN_HEIGHT,
			OverlaySceneChrome.CARD_BORDER,
			BUTTON_BAR_TEXTURE_MEDIUM,
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
	else:
		shell = _create_party_row_shell(92.0)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	var avatar_id: String = _friend_request_sender_avatar_id(item)
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(56.0, 56.0)
	)
	AssetResolver.apply_profile_avatar_texture(avatar_rect, avatar_id)
	row.add_child(avatar_rect)

	if _is_overlay_panel_mode():
		var left_box: VBoxContainer = VBoxContainer.new()
		left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		left_box.size_flags_stretch_ratio = 1.1
		left_box.alignment = BoxContainer.ALIGNMENT_CENTER
		left_box.add_theme_constant_override("separation", 4)
		row.add_child(left_box)

		var overlay_sender_name: String = _friend_request_sender_name(item)
		var overlay_sender_uid: String = _friend_request_sender_uid(item)

		var overlay_name_label: Label = Label.new()
		overlay_name_label.text = overlay_sender_name if overlay_sender_name != "" else overlay_sender_uid
		_configure_party_pending_info_label(overlay_name_label, UiPalette.FONT_SIZE_BODY_LG, OverlaySceneChrome.TITLE_TEXT_COLOR)
		left_box.add_child(overlay_name_label)

		var overlay_uid_label: Label = Label.new()
		overlay_uid_label.text = "UID %s" % overlay_sender_uid
		_configure_party_pending_info_label(overlay_uid_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
		left_box.add_child(overlay_uid_label)

		var middle_box: VBoxContainer = VBoxContainer.new()
		middle_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		middle_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		middle_box.alignment = BoxContainer.ALIGNMENT_CENTER
		middle_box.add_theme_constant_override("separation", 4)
		row.add_child(middle_box)

		var overlay_time_label: Label = Label.new()
		overlay_time_label.text = UiText.SOCIAL_PARTY_APPLICATION_TIME_FORMAT % _format_relative_datetime(_friend_request_created_at(item))
		_configure_party_pending_info_label(overlay_time_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.TITLE_TEXT_COLOR)
		middle_box.add_child(overlay_time_label)

		var pending_label: Label = Label.new()
		pending_label.text = UiText.SOCIAL_PENDING_RESPONSE
		_configure_party_pending_info_label(pending_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
		middle_box.add_child(pending_label)

		var action_box: HBoxContainer = HBoxContainer.new()
		action_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		action_box.alignment = BoxContainer.ALIGNMENT_CENTER
		action_box.add_theme_constant_override("separation", 8)
		row.add_child(action_box)

		var overlay_accept_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ACCEPT, "confirm")
		_style_party_overlay_button(overlay_accept_button, PARTY_ACTION_BUTTON_SIZE)
		overlay_accept_button.pressed.connect(Callable(self, "_accept_friend_request").bind(_friend_request_id(item)))
		action_box.add_child(overlay_accept_button)

		var overlay_reject_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REJECT, "secondary")
		_style_party_overlay_button(overlay_reject_button, PARTY_ACTION_BUTTON_SIZE)
		overlay_reject_button.pressed.connect(Callable(self, "_confirm_reject_friend_request").bind(_friend_request_id(item), overlay_sender_name))
		action_box.add_child(overlay_reject_button)

		return root

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var sender_name: String = _friend_request_sender_name(item)
	var sender_uid: String = _friend_request_sender_uid(item)

	var name_label: Label = Label.new()
	name_label.text = sender_name if sender_name != "" else sender_uid
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var uid_label: Label = Label.new()
	uid_label.text = "UID %s" % sender_uid
	uid_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	uid_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(uid_label)

	var time_label: Label = Label.new()
	time_label.text = UiText.SOCIAL_PARTY_APPLICATION_TIME_FORMAT % _format_relative_datetime(_friend_request_created_at(item))
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	var accept_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ACCEPT, "confirm")
	_style_party_overlay_button(accept_button, PARTY_ACTION_BUTTON_SIZE)
	accept_button.pressed.connect(Callable(self, "_accept_friend_request").bind(_friend_request_id(item)))
	row.add_child(accept_button)

	var reject_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REJECT, "secondary")
	_style_party_overlay_button(reject_button, PARTY_ACTION_BUTTON_SIZE)
	reject_button.pressed.connect(Callable(self, "_confirm_reject_friend_request").bind(_friend_request_id(item), sender_name))
	row.add_child(reject_button)

	return root


func _build_friend_outbox_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var shell: Dictionary
	if _is_overlay_panel_mode():
		shell = _create_party_row_shell(
			PARTY_PENDING_INFO_ROW_MIN_HEIGHT,
			OverlaySceneChrome.CARD_BORDER,
			BUTTON_BAR_TEXTURE_MEDIUM,
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
	else:
		shell = _create_party_row_shell(92.0)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	var avatar_id: String = _friend_request_receiver_avatar_id(item)
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(56.0, 56.0)
	)
	AssetResolver.apply_profile_avatar_texture(avatar_rect, avatar_id)
	row.add_child(avatar_rect)

	if _is_overlay_panel_mode():
		var left_box: VBoxContainer = VBoxContainer.new()
		left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		left_box.size_flags_stretch_ratio = 1.1
		left_box.alignment = BoxContainer.ALIGNMENT_CENTER
		left_box.add_theme_constant_override("separation", 4)
		row.add_child(left_box)

		var overlay_receiver_name: String = _friend_request_receiver_name(item)
		var overlay_receiver_uid: String = _friend_request_receiver_uid(item)

		var overlay_name_label: Label = Label.new()
		overlay_name_label.text = overlay_receiver_name if overlay_receiver_name != "" else overlay_receiver_uid
		_configure_party_pending_info_label(overlay_name_label, UiPalette.FONT_SIZE_BODY_LG, OverlaySceneChrome.TITLE_TEXT_COLOR)
		left_box.add_child(overlay_name_label)

		var overlay_uid_label: Label = Label.new()
		overlay_uid_label.text = "UID %s" % overlay_receiver_uid
		_configure_party_pending_info_label(overlay_uid_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
		left_box.add_child(overlay_uid_label)

		var middle_box: VBoxContainer = VBoxContainer.new()
		middle_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		middle_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		middle_box.alignment = BoxContainer.ALIGNMENT_CENTER
		middle_box.add_theme_constant_override("separation", 4)
		row.add_child(middle_box)

		var overlay_time_label: Label = Label.new()
		overlay_time_label.text = UiText.SOCIAL_PARTY_APPLICATION_TIME_FORMAT % _format_relative_datetime(_friend_request_created_at(item))
		_configure_party_pending_info_label(overlay_time_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.TITLE_TEXT_COLOR)
		middle_box.add_child(overlay_time_label)

		var overlay_status_label: Label = Label.new()
		overlay_status_label.text = UiText.SOCIAL_STATUS_FORMAT % _friend_request_status_text(int(item.get("status", 0)))
		_configure_party_pending_info_label(overlay_status_label, UiPalette.FONT_SIZE_LABEL, OverlaySceneChrome.MUTED_TEXT_COLOR)
		middle_box.add_child(overlay_status_label)

		if int(item.get("status", 0)) == 0:
			var cancel_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_CANCEL, "secondary")
			_style_party_overlay_button(cancel_button, PARTY_ACTION_BUTTON_SIZE)
			cancel_button.pressed.connect(Callable(self, "_cancel_friend_request").bind(_friend_request_id(item)))
			row.add_child(cancel_button)

		return root

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var receiver_name: String = _friend_request_receiver_name(item)
	var receiver_uid: String = _friend_request_receiver_uid(item)

	var name_label: Label = Label.new()
	name_label.text = receiver_name if receiver_name != "" else receiver_uid
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var uid_label: Label = Label.new()
	uid_label.text = "UID %s" % receiver_uid
	uid_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	uid_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(uid_label)

	var status_label: Label = Label.new()
	status_label.text = _friend_request_status_text(int(item.get("status", 0)))
	status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	status_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(status_label)

	var time_label: Label = Label.new()
	time_label.text = UiText.SOCIAL_PARTY_APPLICATION_TIME_FORMAT % _format_relative_datetime(_friend_request_created_at(item))
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	if int(item.get("status", 0)) == 0:
		var cancel_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_CANCEL, "secondary")
		_style_party_overlay_button(cancel_button, PARTY_ACTION_BUTTON_SIZE)
		cancel_button.pressed.connect(Callable(self, "_cancel_friend_request").bind(_friend_request_id(item)))
		row.add_child(cancel_button)

	return root


func _build_party_input_card(
	title_text: String,
	desc_text: String,
	placeholder_text: String,
	button_text: String,
	button_kind: String,
	submit_handler: Callable
) -> Control:
	var shell: Dictionary = _create_party_item_shell(168.0)
	var card: Control = shell.get("root") as Control
	var margin: Control = shell.get("content") as Control

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	var desc: Label = Label.new()
	desc.text = desc_text
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(desc)

	var input_row: HBoxContainer = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 10)
	box.add_child(input_row)

	var input: LineEdit = LineEdit.new()
	input.placeholder_text = placeholder_text
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_row.add_child(input)

	var button: Button = _make_action_button(button_text, button_kind)
	button.custom_minimum_size = Vector2(132.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.pressed.connect(Callable(self, "_submit_party_inline_input").bind(title_text, input, button, submit_handler))
	input.text_submitted.connect(Callable(self, "_on_party_inline_input_text_submitted").bind(title_text, input, button, submit_handler))
	input_row.add_child(button)

	return card


func _restore_party_inline_input(input: LineEdit, button: Button) -> void:
	if is_instance_valid(input):
		input.editable = true
		input.grab_focus()
	if is_instance_valid(button):
		button.disabled = false


func _submit_party_inline_input(title_text: String, input: LineEdit, button: Button, submit_handler: Callable) -> void:
	if not is_instance_valid(input) or not is_instance_valid(button):
		return
	if button.disabled:
		return
	var value: String = input.text.strip_edges()
	if value == "":
		ToastManager.hint(title_text, UiText.SOCIAL_INPUT_EMPTY)
		return
	button.disabled = true
	input.editable = false
	submit_handler.call(value, input, button)


func _on_party_inline_input_text_submitted(
	_text: String,
	title_text: String,
	input: LineEdit,
	button: Button,
	submit_handler: Callable
) -> void:
	_submit_party_inline_input(title_text, input, button, submit_handler)


func _submit_create_party_inline(value: String, input: LineEdit, button: Button) -> void:
	ApiClient.create_party(value, Callable(self, "_on_create_party_inline_completed").bind(value, input, button))


func _submit_apply_party_inline(value: String, input: LineEdit, button: Button) -> void:
	if value.is_valid_int():
		ApiClient.apply_to_party_by_id(int(value), Callable(self, "_on_apply_party_inline_completed").bind(input, button))
	else:
		ApiClient.apply_to_party_by_name(value, Callable(self, "_on_apply_party_inline_completed").bind(input, button))


func _cancel_party_application(application_id: int, party_name: String) -> void:
	var target_label: String = party_name.strip_edges()
	if target_label == "":
		target_label = UiText.SOCIAL_PARTY_THIS
	DialogManager.show_confirm(
		UiText.SOCIAL_PARTY_MY_APPLICATIONS,
		UiText.SOCIAL_PARTY_CANCEL_APPLICATION_CONFIRM_FORMAT % target_label,
		Callable(self, "_confirm_cancel_party_application").bind(application_id)
	)


func _on_create_party_inline_completed(success: bool, _data: Variant, error: Dictionary, value: String, input: LineEdit, button: Button) -> void:
	if not success:
		_restore_party_inline_input(input, button)
		ToastManager.error(UiText.SOCIAL_PARTY_CREATE, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_PARTY_CREATE, UiText.SOCIAL_PARTY_CREATE_SUCCESS % value)
	_refresh_party()


func _on_apply_party_inline_completed(success: bool, _data: Variant, error: Dictionary, input: LineEdit, button: Button) -> void:
	if not success:
		_restore_party_inline_input(input, button)
		ToastManager.error(UiText.SOCIAL_PARTY_APPLY, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_PARTY_APPLY, UiText.SOCIAL_PARTY_APPLY_SUCCESS)
	_refresh_party()


func _confirm_cancel_party_application(application_id: int) -> void:
	ApiClient.cancel_party_application(application_id, Callable(self, "_on_cancel_party_application_completed"))


func _on_cancel_party_application_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_PARTY_MY_APPLICATIONS, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_PARTY_MY_APPLICATIONS, UiText.SOCIAL_PARTY_APPLICATION_CANCEL_SUCCESS)
	_refresh_party()


func _is_party_invite_type(application_type: int) -> bool:
	return application_type == 2 or application_type == 3


func _is_party_player_apply_type(application_type: int) -> bool:
	return application_type == 1


func _party_application_type_text(application_type: int) -> String:
	match application_type:
		1:
			return UiText.SOCIAL_PARTY_TYPE_PLAYER_APPLY
		2:
			return UiText.SOCIAL_PARTY_TYPE_MEMBER_INVITE
		3:
			return UiText.SOCIAL_PARTY_TYPE_LEADER_INVITE
		_:
			return UiText.SOCIAL_PARTY_TYPE_OTHER


func _party_application_status_text(status: int) -> String:
	match status:
		0:
			return UiText.SOCIAL_PARTY_STATUS_PENDING
		1:
			return UiText.SOCIAL_PARTY_STATUS_ACCEPTED
		2:
			return UiText.SOCIAL_PARTY_STATUS_REJECTED
		3:
			return UiText.SOCIAL_PARTY_STATUS_CANCELLED
		_:
			return UiText.SOCIAL_PARTY_STATUS_UNKNOWN


func _build_party_member_row(member_variant: Variant) -> Control:
	var member: Dictionary = member_variant
	var shell: Dictionary = _create_party_row_shell(PARTY_ROW_MIN_HEIGHT)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var member_name: String = str(member.get("displayName", "")).strip_edges()
	var name_label: Label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text = member_name if member_name != "" else UiText.SOCIAL_PLAYER_UNNAMED
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	if _is_current_player_member(member):
		var current_player_label: Label = Label.new()
		current_player_label.text = UiText.SOCIAL_PLAYER_SELF
		current_player_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		current_player_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		info_box.add_child(current_player_label)

	if _is_party_leader() and not _is_current_player_member(member):
		var transfer_button: Button = _make_action_button(UiText.SOCIAL_PARTY_TRANSFER, "rank")
		transfer_button.custom_minimum_size = Vector2(132.0, 46.0)
		transfer_button.pressed.connect(Callable(self, "_confirm_transfer_party").bind(int(member.get("userId", 0)), member_name))
		row.add_child(transfer_button)

		var kick_button: Button = _make_action_button(UiText.SOCIAL_PARTY_KICK, "danger")
		kick_button.custom_minimum_size = Vector2(96.0, 46.0)
		kick_button.pressed.connect(Callable(self, "_confirm_kick_party_member").bind(int(member.get("userId", 0)), member_name))
		row.add_child(kick_button)

	return root


func _build_party_member_slots(members: Array) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var leader_member: Dictionary = {}
	var team_members: Array[Dictionary] = []

	for member_variant: Variant in members:
		if not (member_variant is Dictionary):
			continue
		var member: Dictionary = (member_variant as Dictionary).duplicate(true)
		if bool(member.get("isLeader", false)) and leader_member.is_empty():
			leader_member = member
			continue
		team_members.append(member)

	slots.append({
		"slot_label": UiText.SOCIAL_PARTY_SLOT_LEADER,
		"member": leader_member,
	})

	for index: int in range(4):
		var member: Dictionary = team_members[index] if index < team_members.size() else {}
		slots.append({
			"slot_label": UiText.SOCIAL_PARTY_SLOT_MEMBER_FORMAT % [index + 1],
			"member": member,
		})

	return slots


func _build_party_member_slot_row(slot_label: String, member: Dictionary) -> Control:
	var shell: Dictionary = _create_party_row_shell(PARTY_ROW_MIN_HEIGHT)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control
	var is_empty: bool = member.is_empty()
	var is_self: bool = not is_empty and _is_current_player_member(member)
	var can_manage_member: bool = not is_empty and _is_party_leader() and not is_self and not bool(member.get("isLeader", false))
	var member_name: String = str(member.get("displayName", "")).strip_edges()
	var can_invite_into_slot: bool = is_empty and slot_label != UiText.SOCIAL_PARTY_SLOT_LEADER

	var name_label: Label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text = "%s：%s" % [
		slot_label,
		member_name if member_name != "" else UiText.SOCIAL_PARTY_SLOT_EMPTY
	]
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override(
		"font_color",
		OverlaySceneChrome.MUTED_TEXT_COLOR if is_empty else OverlaySceneChrome.TITLE_TEXT_COLOR
	)
	row.add_child(name_label)

	if is_self:
		var leave_button: Button = _make_action_button(_get_party_exit_button_text(), "danger")
		_style_party_overlay_button(leave_button, PARTY_ACTION_BUTTON_SIZE)
		leave_button.pressed.connect(_on_party_exit_pressed)
		row.add_child(leave_button)
		return root

	if can_invite_into_slot:
		var invite_button: Button = _make_action_button(UiText.SOCIAL_PARTY_INVITE, "confirm")
		_style_party_overlay_button(invite_button, PARTY_ACTION_BUTTON_SIZE)
		invite_button.pressed.connect(_open_invite_party_dialog)
		row.add_child(invite_button)
		return root

	if can_manage_member:
		var action_box: HBoxContainer = HBoxContainer.new()
		action_box.size_flags_horizontal = Control.SIZE_SHRINK_END
		action_box.alignment = BoxContainer.ALIGNMENT_END
		action_box.add_theme_constant_override("separation", 6)
		row.add_child(action_box)

		var transfer_button: Button = _make_action_button(UiText.SOCIAL_PARTY_TRANSFER, "secondary")
		_style_party_overlay_button(transfer_button, PARTY_ACTION_BUTTON_SIZE)
		transfer_button.pressed.connect(Callable(self, "_confirm_transfer_party").bind(int(member.get("userId", 0)), member_name))
		action_box.add_child(transfer_button)

		var kick_button: Button = _make_action_button(UiText.SOCIAL_PARTY_KICK, "secondary")
		_style_party_overlay_button(kick_button, PARTY_ACTION_BUTTON_SIZE)
		kick_button.pressed.connect(Callable(self, "_confirm_kick_party_member").bind(int(member.get("userId", 0)), member_name))
		action_box.add_child(kick_button)

	return root


func _make_party_section_box(
	host: VBoxContainer,
	title_text: String,
	desc_text: String = "",
	accent: Color = OverlaySceneChrome.PANEL_BORDER
) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	if _is_overlay_panel_mode():
		host.add_child(box)
	else:
		var card: PanelContainer = OverlaySceneChrome.make_card_panel(accent)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host.add_child(card)

		var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
		card.add_child(margin)
		margin.add_child(box)

	if title_text != "":
		if _is_overlay_panel_mode():
			var title_margin: MarginContainer = MarginContainer.new()
			title_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			title_margin.add_theme_constant_override("margin_left", 30)
			title_margin.add_theme_constant_override("margin_right", 30)
			box.add_child(title_margin)

			var title: Label = Label.new()
			title.text = title_text
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
			title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
			title_margin.add_child(title)
		else:
			var title: Label = Label.new()
			title.text = title_text
			title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
			title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
			box.add_child(title)

	if desc_text != "":
		if _is_overlay_panel_mode():
			var desc_margin: MarginContainer = MarginContainer.new()
			desc_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			desc_margin.add_theme_constant_override("margin_left", 30)
			desc_margin.add_theme_constant_override("margin_right", 30)
			box.add_child(desc_margin)

			var desc: Label = Label.new()
			desc.text = desc_text
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
			desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
			desc_margin.add_child(desc)
		else:
			var desc: Label = Label.new()
			desc.text = desc_text
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
			desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
			box.add_child(desc)

	if _is_overlay_panel_mode() and title_text != "":
		var separator_margin: MarginContainer = MarginContainer.new()
		separator_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		separator_margin.add_theme_constant_override("margin_left", 30)
		separator_margin.add_theme_constant_override("margin_right", 30)
		box.add_child(separator_margin)

		var separator: ColorRect = ColorRect.new()
		separator.color = OverlaySceneChrome.PANEL_BORDER
		separator.custom_minimum_size = Vector2(0.0, 1.0)
		separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		separator_margin.add_child(separator)

	return box


func _create_party_item_shell(
	min_height: float = PARTY_ROW_MIN_HEIGHT,
	accent: Color = OverlaySceneChrome.CARD_BORDER,
	texture: Texture2D = BUTTON_BAR_TEXTURE,
	texture_stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_COVERED as TextureRect.StretchMode
) -> Dictionary:
	if _is_overlay_panel_mode():
		var shell: Control = Control.new()
		shell.custom_minimum_size = Vector2(0.0, min_height)
		shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var background: TextureRect = TextureRect.new()
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.texture = texture
		background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = texture_stretch_mode
		shell.add_child(background)

		var margin: MarginContainer = MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 30)
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_right", 30)
		margin.add_theme_constant_override("margin_bottom", 16)
		shell.add_child(margin)

		return {
			"root": shell,
			"content": margin,
		}

	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(accent)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel_margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(panel_margin)

	return {
		"root": panel,
		"content": panel_margin,
	}


func _create_party_row_shell(
	min_height: float = PARTY_ROW_MIN_HEIGHT,
	accent: Color = OverlaySceneChrome.CARD_BORDER,
	texture: Texture2D = BUTTON_BAR_TEXTURE,
	texture_stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_COVERED as TextureRect.StretchMode
) -> Dictionary:
	var shell: Dictionary = _create_party_item_shell(min_height, accent, texture, texture_stretch_mode)
	var content: Control = shell.get("content") as Control
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	shell["row"] = row
	return shell


func _build_party_info_item(label_text: String, value_text: String) -> Control:
	var shell: Dictionary = _create_party_item_shell(86.0)
	var content: Control = shell.get("content") as Control
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	content.add_child(box)

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(label)

	var value: Label = Label.new()
	value.text = value_text if value_text.strip_edges() != "" else "-"
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	value.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(value)

	return shell.get("root") as Control


func _make_action_button(text_value: String, kind: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	UiPalette.apply_button_kind(button, kind)
	return button


func _style_party_overlay_button(button: Button, button_size: Vector2, font_size: int = UiPalette.FONT_SIZE_SMALL) -> void:
	button.custom_minimum_size = button_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", font_size)


func _configure_party_pending_info_label(label: Label, font_size: int, color: Color) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _make_vertical_spacer(height: float) -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	return spacer


func _party_application_counterpart_name(item: Dictionary) -> String:
	var counterpart_name: String = _first_nonempty_string([
		item.get("applicantDisplayName", ""),
		item.get("applicantPlayerName", ""),
		item.get("displayName", ""),
		item.get("playerName", ""),
		item.get("targetDisplayName", ""),
		item.get("targetPlayerName", ""),
		item.get("receiverDisplayName", ""),
		item.get("receiverPlayerName", ""),
	])
	return counterpart_name if counterpart_name != "" else UiText.SOCIAL_PLAYER_UNNAMED


func _party_application_inviter_name(item: Dictionary) -> String:
	var inviter_name: String = _first_nonempty_string([
		item.get("inviterDisplayName", ""),
		item.get("leaderDisplayName", ""),
		item.get("partyLeaderDisplayName", ""),
	])
	return inviter_name if inviter_name != "" else UiText.SOCIAL_PARTY_MEMBER_FALLBACK


func _party_application_scooper_level_text(item: Dictionary) -> String:
	for key: String in ["scooperLevel", "applicantScooperLevel", "targetScooperLevel", "receiverScooperLevel"]:
		if item.has(key):
			var level: int = int(item.get(key, 0))
			if level > 0:
				return "Lv.%d" % level
	return "-"


func _party_application_stage_text(item: Dictionary) -> String:
	for key: String in ["currentStage", "applicantCurrentStage", "targetCurrentStage", "receiverCurrentStage"]:
		if item.has(key):
			var stage_value: int = int(item.get(key, 0))
			if stage_value > 0:
				return _format_friend_stage_text(stage_value)
	return UiText.SOCIAL_STAGE_FALLBACK


func _party_application_progress_line(item: Dictionary) -> String:
	var scooper_level_text: String = _party_application_scooper_level_text(item)
	var stage_text: String = UiText.SOCIAL_STAGE_LABEL_FALLBACK
	for key: String in ["currentStage", "applicantCurrentStage", "targetCurrentStage", "receiverCurrentStage"]:
		if item.has(key):
			var stage_value: int = int(item.get(key, 0))
			if stage_value > 0:
				stage_text = _format_friend_stage_text(stage_value)
				break
	return UiText.SOCIAL_SCOOPER_STAGE_COMPACT_FORMAT % [scooper_level_text, stage_text]


func _make_empty_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	return label


func _friend_request_status_text(status: int) -> String:
	match status:
		0:
			return UiText.SOCIAL_FRIEND_STATUS_PENDING
		1:
			return UiText.SOCIAL_FRIEND_STATUS_ACCEPTED
		2:
			return UiText.SOCIAL_FRIEND_STATUS_REJECTED
		3:
			return UiText.SOCIAL_FRIEND_STATUS_CANCELLED
		_:
			return UiText.SOCIAL_FRIEND_STATUS_UNKNOWN


func _on_friend_gift_pressed() -> void:
	if _friend_gift_in_flight:
		return
	var unsent_friend_rows: Array = _get_unsent_friend_rows()
	if unsent_friend_rows.is_empty():
		ToastManager.hint(UiText.SOCIAL_FRIEND_GIFT_ALL, UiText.SOCIAL_EMPTY)
		return
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_GIFT_ALL,
		UiText.SOCIAL_FRIEND_GIFT_CONFIRM % unsent_friend_rows.size(),
		Callable(self, "_confirm_friend_gift")
	)


func _confirm_friend_gift() -> void:
	if _friend_gift_in_flight:
		return
	_friend_gift_in_flight = true
	ApiClient.send_friend_gifts(Callable(self, "_on_friend_gift_completed"))


func _on_friend_gift_completed(success: bool, data: Variant, error: Dictionary) -> void:
	_friend_gift_in_flight = false
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_GIFT_ALL, _error_message(error))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var recipient_count: int = int(payload.get("recipientCount", 0))
	if recipient_count <= 0:
		ToastManager.hint(UiText.SOCIAL_FRIEND_GIFT_ALL, UiText.SOCIAL_FRIEND_NO_GIFT_TARGETS)
		_refresh_friend()
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_GIFT_ALL, UiText.SOCIAL_FRIEND_GIFT_SUCCESS % recipient_count)
	_refresh_friend()


func _get_unsent_friend_rows() -> Array:
	var unsent_rows: Array = []
	var friend_rows: Array = _friend_list.get("friends", [])
	for item_variant: Variant in friend_rows:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if bool(item.get("giftSentToday", false)):
			continue
		unsent_rows.append(item)
	return unsent_rows


func _confirm_remove_friend(friend_user_id: int, friend_name: String) -> void:
	var target_label: String = friend_name.strip_edges()
	if target_label == "":
		target_label = UiText.SOCIAL_FRIEND_UNNAMED
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REMOVE,
		UiText.SOCIAL_FRIEND_REMOVE_CONFIRM_FORMAT % target_label,
		Callable(self, "_remove_friend").bind(friend_user_id)
	)


func _remove_friend(friend_user_id: int) -> void:
	ApiClient.remove_friend(friend_user_id, Callable(self, "_on_remove_friend_completed"))


func _on_remove_friend_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_REMOVE, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_REMOVE, UiText.SOCIAL_FRIEND_REMOVE_SUCCESS)
	_refresh_friend()


func _open_showcase_dialog() -> void:
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	for cat_variant: Variant in GameState.player_cats_data:
		if not (cat_variant is Dictionary):
			continue
		var cat: Dictionary = cat_variant
		var button: Button = _make_action_button(str(cat.get("displayName", cat.get("catDisplayName", ""))), "info")
		button.pressed.connect(Callable(self, "_set_showcase_cat_from_variant").bind(cat))
		content.add_child(button)

	var clear_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_SHOWCASE_CLEAR, "secondary")
	clear_button.pressed.connect(_clear_showcase_cat)
	content.add_child(clear_button)

	DialogManager.show_info_node(UiText.SOCIAL_FRIEND_SHOWCASE, content, Callable(), "large")


func _set_showcase_cat(player_cat_id: int) -> void:
	ApiClient.set_friend_showcase_cat(player_cat_id, Callable(self, "_on_set_showcase_cat_completed"))


func _set_showcase_cat_from_variant(cat_variant: Dictionary) -> void:
	_set_showcase_cat(int(cat_variant.get("playerCatId", 0)))


func _on_set_showcase_cat_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_SHOWCASE, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_SHOWCASE, UiText.SOCIAL_FRIEND_SHOWCASE_SUCCESS)
	_refresh_friend()


func _clear_showcase_cat() -> void:
	ApiClient.clear_friend_showcase_cat(Callable(self, "_on_clear_showcase_cat_completed"))


func _on_clear_showcase_cat_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_SHOWCASE, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_SHOWCASE, UiText.SOCIAL_FRIEND_SHOWCASE_CLEARED)
	_refresh_friend()


func _open_text_input(title: String, placeholder: String, on_confirm: Callable, close_on_submit: bool = true) -> Dictionary:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var input: LineEdit = LineEdit.new()
	input.placeholder_text = placeholder
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(input)

	var confirm_button: Button = _make_action_button(UiText.COMMON_CONFIRM, "confirm")
	var close_dialog: Callable = Callable()
	var dialog_state: Dictionary = {
		"close": Callable(),
		"confirm_button": confirm_button,
		"input": input,
		"is_submitting": false,
	}
	confirm_button.pressed.connect(Callable(self, "_submit_text_input_dialog").bind(dialog_state, title, close_on_submit, on_confirm))
	box.add_child(confirm_button)
	input.text_submitted.connect(Callable(self, "_on_text_input_dialog_submitted").bind(dialog_state, title, close_on_submit, on_confirm))

	close_dialog = DialogManager.show_info_node(title, box, Callable(), "medium")
	dialog_state["close"] = close_dialog
	input.grab_focus()
	return dialog_state


func _set_text_input_dialog_submitting(dialog_state: Dictionary, is_submitting: bool) -> void:
	dialog_state["is_submitting"] = is_submitting
	var confirm_button_variant: Variant = dialog_state.get("confirm_button")
	if confirm_button_variant is Button and is_instance_valid(confirm_button_variant):
		(confirm_button_variant as Button).disabled = is_submitting
	var input_variant: Variant = dialog_state.get("input")
	if input_variant is LineEdit and is_instance_valid(input_variant):
		(input_variant as LineEdit).editable = not is_submitting


func _submit_text_input_dialog(
	dialog_state: Dictionary,
	title: String,
	close_on_submit: bool,
	on_confirm: Callable
) -> void:
	if bool(dialog_state.get("is_submitting", false)):
		return
	var input_variant: Variant = dialog_state.get("input")
	if not (input_variant is LineEdit) or not is_instance_valid(input_variant):
		return
	var input: LineEdit = input_variant as LineEdit
	var value: String = input.text.strip_edges()
	if value == "":
		ToastManager.hint(title, UiText.SOCIAL_INPUT_EMPTY)
		return
	_set_text_input_dialog_submitting(dialog_state, true)
	var close_dialog_variant: Variant = dialog_state.get("close", Callable())
	if close_dialog_variant is Callable and (close_dialog_variant as Callable).is_valid() and close_on_submit:
		(close_dialog_variant as Callable).call()
	on_confirm.call(value)


func _on_text_input_dialog_submitted(
	_text: String,
	dialog_state: Dictionary,
	title: String,
	close_on_submit: bool,
	on_confirm: Callable
) -> void:
	_submit_text_input_dialog(dialog_state, title, close_on_submit, on_confirm)


func _open_add_friend_dialog() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(0.0, 620.0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)

	var intro_label: Label = Label.new()
	intro_label.text = UiText.SOCIAL_FRIEND_ADD_INTRO
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	intro_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(intro_label)

	var search_row: HBoxContainer = HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 10)
	box.add_child(search_row)

	var input: LineEdit = LineEdit.new()
	input.placeholder_text = UiText.SOCIAL_FRIEND_SEARCH_PLACEHOLDER
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row.add_child(input)

	var confirm_button: Button = _make_action_button(UiText.COMMON_CONFIRM, "confirm")
	confirm_button.custom_minimum_size = Vector2(132.0, 52.0)
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	search_row.add_child(confirm_button)

	var status_label: Label = Label.new()
	status_label.text = UiText.SOCIAL_FRIEND_ADD_SEARCH_HINT
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	status_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(status_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 460.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	InertialScroller.attach(scroll, "vertical")

	var results_box: VBoxContainer = VBoxContainer.new()
	results_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_box.add_theme_constant_override("separation", 10)
	scroll.add_child(results_box)
	results_box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))

	var close_dialog: Callable = Callable()
	var dialog_state: Dictionary = {
		"close": Callable(),
		"input": input,
		"confirm_button": confirm_button,
		"status_label": status_label,
		"results_box": results_box,
		"candidates": [],
		"is_searching": false,
		"is_submitting": false,
	}

	confirm_button.pressed.connect(Callable(self, "_submit_add_friend_search").bind(dialog_state))
	input.text_submitted.connect(Callable(self, "_on_add_friend_search_text_submitted").bind(dialog_state))

	close_dialog = DialogManager.show_info_node(UiText.SOCIAL_FRIEND_ADD, box, Callable(), "xlarge")
	dialog_state["close"] = close_dialog
	input.grab_focus()


func _submit_add_friend(value: String) -> void:
	ApiClient.send_friend_request(value, Callable(self, "_on_submit_add_friend_completed"))


func _submit_add_friend_search(dialog_state: Dictionary) -> void:
	if bool(dialog_state.get("is_searching", false)) or bool(dialog_state.get("is_submitting", false)):
		return
	var input_variant: Variant = dialog_state.get("input")
	if not (input_variant is LineEdit) or not is_instance_valid(input_variant):
		return
	var query: String = (input_variant as LineEdit).text.strip_edges()
	if query == "":
		ToastManager.hint(UiText.SOCIAL_FRIEND_ADD, UiText.SOCIAL_INPUT_EMPTY)
		return
	_search_friend_candidates(dialog_state, query)


func _on_add_friend_search_text_submitted(_text: String, dialog_state: Dictionary) -> void:
	_submit_add_friend_search(dialog_state)


func _on_submit_add_friend_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_ADD, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_ADD, UiText.SOCIAL_FRIEND_ADD_SUCCESS)
	_refresh_friend()


func _search_friend_candidates(dialog_state: Dictionary, query: String) -> void:
	_set_friend_search_dialog_busy(dialog_state, true, false)
	_set_friend_search_dialog_status(dialog_state, UiText.SOCIAL_FRIEND_SEARCHING, OverlaySceneChrome.MUTED_TEXT_COLOR)
	ApiClient.search_friend_candidates(query, Callable(self, "_on_friend_candidates_searched").bind(dialog_state))


func _on_friend_candidates_searched(success: bool, data: Variant, error: Dictionary, dialog_state: Dictionary) -> void:
	_set_friend_search_dialog_busy(dialog_state, false, false)
	if not success:
		_set_friend_search_dialog_status(dialog_state, _error_message(error), UiPalette.BUTTON_DANGER_FG)
		_render_friend_search_candidates(dialog_state, [])
		return
	var candidates: Array = data if data is Array else []
	dialog_state["candidates"] = candidates
	if candidates.is_empty():
		_set_friend_search_dialog_status(dialog_state, UiText.SOCIAL_FRIEND_SEARCH_NO_RESULT, OverlaySceneChrome.MUTED_TEXT_COLOR)
	else:
		_set_friend_search_dialog_status(dialog_state, UiText.SOCIAL_FRIEND_SEARCH_RESULT_FORMAT % candidates.size(), OverlaySceneChrome.MUTED_TEXT_COLOR)
	_render_friend_search_candidates(dialog_state, candidates)


func _set_friend_search_dialog_busy(dialog_state: Dictionary, is_searching: bool, is_submitting: bool) -> void:
	dialog_state["is_searching"] = is_searching
	dialog_state["is_submitting"] = is_submitting
	var input_variant: Variant = dialog_state.get("input")
	if input_variant is LineEdit and is_instance_valid(input_variant):
		(input_variant as LineEdit).editable = not is_searching and not is_submitting
	var confirm_button_variant: Variant = dialog_state.get("confirm_button")
	if confirm_button_variant is Button and is_instance_valid(confirm_button_variant):
		(confirm_button_variant as Button).disabled = is_searching or is_submitting
	var candidates_variant: Variant = dialog_state.get("candidates", [])
	if candidates_variant is Array:
		_render_friend_search_candidates(dialog_state, candidates_variant)


func _set_friend_search_dialog_status(dialog_state: Dictionary, text_value: String, color: Color) -> void:
	var status_variant: Variant = dialog_state.get("status_label")
	if status_variant is Label and is_instance_valid(status_variant):
		var status_label: Label = status_variant as Label
		status_label.text = text_value
		status_label.add_theme_color_override("font_color", color)


func _render_friend_search_candidates(dialog_state: Dictionary, candidates: Array) -> void:
	var results_variant: Variant = dialog_state.get("results_box")
	if not (results_variant is VBoxContainer) or not is_instance_valid(results_variant):
		return
	var results_box: VBoxContainer = results_variant as VBoxContainer
	for child: Node in results_box.get_children():
		child.queue_free()
	if candidates.is_empty():
		results_box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return
	for candidate_variant: Variant in candidates:
		if candidate_variant is Dictionary:
			results_box.add_child(_build_friend_search_candidate_row(dialog_state, candidate_variant))


func _build_friend_search_candidate_row(dialog_state: Dictionary, candidate: Dictionary) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var avatar_id: String = str(candidate.get("avatarId", "")).strip_edges()
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(64.0, 64.0)
	)
	AssetResolver.apply_profile_avatar_texture(avatar_rect, avatar_id)
	row.add_child(avatar_rect)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var player_name: String = str(candidate.get("playerName", "")).strip_edges()
	var name_label: Label = Label.new()
	name_label.text = player_name if player_name != "" else UiText.SOCIAL_PLAYER_UNNAMED
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var uid_label: Label = Label.new()
	uid_label.text = UiText.SOCIAL_SCOOPER_LEVEL_UID_FORMAT % [
		int(candidate.get("scooperLevel", 0)),
		str(candidate.get("playerUid", "")).strip_edges()
	]
	uid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	uid_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	uid_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(uid_label)

	var last_login_label: Label = Label.new()
	last_login_label.text = UiText.SOCIAL_LAST_LOGIN_FORMAT % _format_last_login_text(candidate.get("lastLoginAtUtc", null))
	last_login_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_login_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	last_login_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(last_login_label)

	var add_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ADD, "add")
	add_button.custom_minimum_size = Vector2(120.0, 48.0)
	add_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_button.disabled = bool(dialog_state.get("is_submitting", false))
	add_button.pressed.connect(Callable(self, "_submit_friend_request_from_candidate").bind(dialog_state, candidate))
	row.add_child(add_button)

	return panel


func _submit_friend_request_from_candidate(dialog_state: Dictionary, candidate: Dictionary) -> void:
	if bool(dialog_state.get("is_submitting", false)) or bool(dialog_state.get("is_searching", false)):
		return
	var player_uid: String = str(candidate.get("playerUid", "")).strip_edges()
	var player_name: String = str(candidate.get("playerName", "")).strip_edges()
	if player_uid == "":
		return
	_set_friend_search_dialog_busy(dialog_state, false, true)
	_set_friend_search_dialog_status(dialog_state, UiText.SOCIAL_FRIEND_SENDING_REQUEST_FORMAT % (player_name if player_name != "" else player_uid), OverlaySceneChrome.MUTED_TEXT_COLOR)
	ApiClient.send_friend_request(player_uid, Callable(self, "_on_friend_request_from_candidate_completed").bind(dialog_state))


func _on_friend_request_from_candidate_completed(success: bool, _data: Variant, error: Dictionary, dialog_state: Dictionary) -> void:
	_set_friend_search_dialog_busy(dialog_state, false, false)
	if not success:
		_set_friend_search_dialog_status(dialog_state, _error_message(error), UiPalette.BUTTON_DANGER_FG)
		return
	var close_dialog_variant: Variant = dialog_state.get("close", Callable())
	if close_dialog_variant is Callable and (close_dialog_variant as Callable).is_valid():
		(close_dialog_variant as Callable).call()
	ToastManager.success(UiText.SOCIAL_FRIEND_ADD, UiText.SOCIAL_FRIEND_ADD_SUCCESS)
	_refresh_friend()


func _accept_friend_request(request_id: int) -> void:
	ApiClient.accept_friend_request(request_id, Callable(self, "_on_accept_friend_request_completed"))


func _on_accept_friend_request_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_INBOX, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_INBOX, UiText.SOCIAL_FRIEND_ACCEPT_SUCCESS)
	_refresh_friend()


func _confirm_reject_friend_request(request_id: int, friend_name: String) -> void:
	var target_label: String = friend_name.strip_edges()
	if target_label == "":
		target_label = UiText.SOCIAL_PLAYER_THIS
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REJECT,
		UiText.SOCIAL_FRIEND_REJECT_CONFIRM_FORMAT % target_label,
		Callable(self, "_reject_friend_request").bind(request_id)
	)


func _reject_friend_request(request_id: int) -> void:
	ApiClient.reject_friend_request(request_id, Callable(self, "_on_reject_friend_request_completed"))


func _on_reject_friend_request_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_INBOX, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_INBOX, UiText.SOCIAL_FRIEND_REJECT_SUCCESS)
	_refresh_friend()


func _cancel_friend_request(request_id: int) -> void:
	ApiClient.cancel_friend_request(request_id, Callable(self, "_on_cancel_friend_request_completed"))


func _on_cancel_friend_request_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_OUTBOX, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_OUTBOX, UiText.SOCIAL_FRIEND_CANCEL_SUCCESS)
	_refresh_friend()


func _open_create_party_dialog() -> void:
	_create_party_dialog_state = _open_text_input(UiText.SOCIAL_PARTY_CREATE, UiText.SOCIAL_PARTY_NAME_PLACEHOLDER, Callable(self, "_submit_create_party"), false)


func _submit_create_party(value: String) -> void:
	ApiClient.create_party(value, Callable(self, "_on_submit_create_party_completed").bind(value))


func _on_submit_create_party_completed(success: bool, _data: Variant, error: Dictionary, value: String) -> void:
	if not success:
		_set_text_input_dialog_submitting(_create_party_dialog_state, false)
		_after_party_action(false, error, UiText.SOCIAL_PARTY_CREATE, UiText.SOCIAL_PARTY_CREATE_SUCCESS % value)
		return
	var close_dialog_variant: Variant = _create_party_dialog_state.get("close", Callable())
	if close_dialog_variant is Callable and (close_dialog_variant as Callable).is_valid():
		(close_dialog_variant as Callable).call()
	_create_party_dialog_state = {}
	_after_party_action(success, error, UiText.SOCIAL_PARTY_CREATE, UiText.SOCIAL_PARTY_CREATE_SUCCESS % value)


func _open_apply_party_dialog() -> void:
	_open_text_input(UiText.SOCIAL_PARTY_APPLY, UiText.SOCIAL_PARTY_SEARCH_PLACEHOLDER, Callable(self, "_submit_apply_party"))


func _submit_apply_party(value: String) -> void:
	if value.is_valid_int():
		ApiClient.apply_to_party_by_id(int(value), Callable(self, "_on_submit_apply_party_completed"))
	else:
		ApiClient.apply_to_party_by_name(value, Callable(self, "_on_submit_apply_party_completed"))


func _on_submit_apply_party_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	_after_party_action(success, error, UiText.SOCIAL_PARTY_APPLY, UiText.SOCIAL_PARTY_APPLY_SUCCESS)


func _show_my_party_applications() -> void:
	_party_section = "reviews"
	_refresh_party_footer_buttons()
	_reload_current_party_section()


func _open_invite_party_dialog() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(0.0, 620.0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)

	var intro_label: Label = Label.new()
	intro_label.text = UiText.SOCIAL_PARTY_INVITE_INTRO
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	intro_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(intro_label)

	var search_row: HBoxContainer = HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 10)
	box.add_child(search_row)

	var input: LineEdit = LineEdit.new()
	input.placeholder_text = UiText.SOCIAL_FRIEND_SEARCH_PLACEHOLDER
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row.add_child(input)

	var confirm_button: Button = _make_action_button(UiText.COMMON_CONFIRM, "confirm")
	confirm_button.custom_minimum_size = Vector2(132.0, 52.0)
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	search_row.add_child(confirm_button)

	var status_label: Label = Label.new()
	status_label.text = UiText.SOCIAL_FRIEND_ADD_SEARCH_HINT
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	status_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(status_label)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 460.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	InertialScroller.attach(scroll, "vertical")

	var results_box: VBoxContainer = VBoxContainer.new()
	results_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_box.add_theme_constant_override("separation", 10)
	scroll.add_child(results_box)
	results_box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))

	var close_dialog: Callable = Callable()
	var dialog_state: Dictionary = {
		"close": Callable(),
		"input": input,
		"confirm_button": confirm_button,
		"status_label": status_label,
		"results_box": results_box,
		"candidates": [],
		"is_searching": false,
		"is_inviting": false,
	}

	confirm_button.pressed.connect(Callable(self, "_submit_party_invite_search").bind(dialog_state))
	input.text_submitted.connect(Callable(self, "_on_party_invite_search_text_submitted").bind(dialog_state))

	close_dialog = DialogManager.show_info_node(UiText.SOCIAL_PARTY_INVITE, box, Callable(), "xlarge")
	dialog_state["close"] = close_dialog
	_invite_party_dialog_state = dialog_state
	input.grab_focus()


func _search_party_invite_candidates(dialog_state: Dictionary, query: String) -> void:
	_set_invite_party_dialog_busy(dialog_state, true, false)
	_set_invite_party_dialog_status(dialog_state, UiText.SOCIAL_FRIEND_SEARCHING, OverlaySceneChrome.MUTED_TEXT_COLOR)
	ApiClient.search_party_invite_candidates(
		int(_party_detail.get("partyId", 0)),
		query,
		Callable(self, "_on_party_invite_candidates_searched").bind(dialog_state)
	)


func _submit_party_invite_search(dialog_state: Dictionary) -> void:
	if bool(dialog_state.get("is_searching", false)) or bool(dialog_state.get("is_inviting", false)):
		return
	var input_variant: Variant = dialog_state.get("input")
	if not (input_variant is LineEdit) or not is_instance_valid(input_variant):
		return
	var query: String = (input_variant as LineEdit).text.strip_edges()
	if query == "":
		ToastManager.hint(UiText.SOCIAL_PARTY_INVITE, UiText.SOCIAL_INPUT_EMPTY)
		return
	_search_party_invite_candidates(dialog_state, query)


func _on_party_invite_search_text_submitted(_text: String, dialog_state: Dictionary) -> void:
	_submit_party_invite_search(dialog_state)


func _on_party_invite_candidates_searched(success: bool, data: Variant, error: Dictionary, dialog_state: Dictionary) -> void:
	_set_invite_party_dialog_busy(dialog_state, false, false)
	if not success:
		_set_invite_party_dialog_status(dialog_state, _error_message(error), UiPalette.BUTTON_DANGER_FG)
		_render_invite_party_candidates(dialog_state, [])
		return
	var candidates: Array = data if data is Array else []
	dialog_state["candidates"] = candidates
	if candidates.is_empty():
		_set_invite_party_dialog_status(dialog_state, UiText.SOCIAL_FRIEND_SEARCH_NO_RESULT, OverlaySceneChrome.MUTED_TEXT_COLOR)
	else:
		_set_invite_party_dialog_status(dialog_state, UiText.SOCIAL_PARTY_INVITE_SEARCH_RESULT_FORMAT % candidates.size(), OverlaySceneChrome.MUTED_TEXT_COLOR)
	_render_invite_party_candidates(dialog_state, candidates)


func _set_invite_party_dialog_busy(dialog_state: Dictionary, is_busy: bool, is_inviting: bool) -> void:
	dialog_state["is_searching"] = is_busy
	dialog_state["is_inviting"] = is_inviting
	var input_variant: Variant = dialog_state.get("input")
	if input_variant is LineEdit and is_instance_valid(input_variant):
		(input_variant as LineEdit).editable = not is_busy and not is_inviting
	var confirm_button_variant: Variant = dialog_state.get("confirm_button")
	if confirm_button_variant is Button and is_instance_valid(confirm_button_variant):
		(confirm_button_variant as Button).disabled = is_busy or is_inviting
	var candidates_variant: Variant = dialog_state.get("candidates", [])
	if candidates_variant is Array:
		_render_invite_party_candidates(dialog_state, candidates_variant)


func _set_invite_party_dialog_status(dialog_state: Dictionary, text_value: String, color: Color) -> void:
	var status_variant: Variant = dialog_state.get("status_label")
	if status_variant is Label and is_instance_valid(status_variant):
		var status_label: Label = status_variant as Label
		status_label.text = text_value
		status_label.add_theme_color_override("font_color", color)


func _render_invite_party_candidates(dialog_state: Dictionary, candidates: Array) -> void:
	var results_variant: Variant = dialog_state.get("results_box")
	if not (results_variant is VBoxContainer) or not is_instance_valid(results_variant):
		return
	var results_box: VBoxContainer = results_variant as VBoxContainer
	for child: Node in results_box.get_children():
		child.queue_free()
	if candidates.is_empty():
		results_box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return
	for candidate_variant: Variant in candidates:
		if candidate_variant is Dictionary:
			results_box.add_child(_build_invite_party_candidate_row(dialog_state, candidate_variant))


func _build_invite_party_candidate_row(dialog_state: Dictionary, candidate: Dictionary) -> Control:
	var shell: Dictionary = _create_party_row_shell(108.0)
	var row: HBoxContainer = shell.get("row") as HBoxContainer
	var root: Control = shell.get("root") as Control

	var avatar_id: String = str(candidate.get("avatarId", "")).strip_edges()
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(64.0, 64.0)
	)
	AssetResolver.apply_profile_avatar_texture(avatar_rect, avatar_id)
	row.add_child(avatar_rect)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var player_name: String = str(candidate.get("playerName", "")).strip_edges()
	var name_label: Label = Label.new()
	name_label.text = player_name if player_name != "" else UiText.SOCIAL_PLAYER_UNNAMED
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var uid_label: Label = Label.new()
	uid_label.text = UiText.SOCIAL_SCOOPER_LEVEL_UID_FORMAT % [
		int(candidate.get("scooperLevel", 0)),
		str(candidate.get("playerUid", "")).strip_edges()
	]
	uid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	uid_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	uid_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(uid_label)

	var last_login_label: Label = Label.new()
	last_login_label.text = UiText.SOCIAL_LAST_LOGIN_FORMAT % _format_party_invite_last_login(candidate.get("lastLoginAtUtc", null))
	last_login_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_login_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	last_login_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(last_login_label)

	var invite_button: Button = _make_action_button(UiText.SOCIAL_PARTY_INVITE, "add")
	invite_button.custom_minimum_size = Vector2(118.0, 52.0)
	invite_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	invite_button.disabled = bool(dialog_state.get("is_searching", false)) or bool(dialog_state.get("is_inviting", false))
	invite_button.pressed.connect(Callable(self, "_invite_party_candidate").bind(dialog_state, candidate))
	row.add_child(invite_button)

	return root


func _invite_party_candidate(dialog_state: Dictionary, candidate: Dictionary) -> void:
	if bool(dialog_state.get("is_searching", false)) or bool(dialog_state.get("is_inviting", false)):
		return
	var player_uid: String = str(candidate.get("playerUid", "")).strip_edges()
	if player_uid == "":
		ToastManager.error(UiText.SOCIAL_PARTY_INVITE, UiText.SOCIAL_PARTY_INVITE_MISSING_UID)
		return
	var player_name: String = str(candidate.get("playerName", "")).strip_edges()
	_set_invite_party_dialog_busy(dialog_state, false, true)
	_set_invite_party_dialog_status(dialog_state, UiText.SOCIAL_PARTY_INVITING_FORMAT % (player_name if player_name != "" else player_uid), OverlaySceneChrome.MUTED_TEXT_COLOR)
	ApiClient.invite_player_to_party(
		int(_party_detail.get("partyId", 0)),
		player_uid,
		Callable(self, "_on_invite_party_candidate_completed").bind(dialog_state)
	)


func _on_invite_party_candidate_completed(success: bool, _data: Variant, error: Dictionary, dialog_state: Dictionary) -> void:
	_set_invite_party_dialog_busy(dialog_state, false, false)
	if not success:
		_set_invite_party_dialog_status(dialog_state, _error_message(error), UiPalette.BUTTON_DANGER_FG)
		ToastManager.error(UiText.SOCIAL_PARTY_INVITE, _error_message(error))
		return
	var close_variant: Variant = dialog_state.get("close", Callable())
	if close_variant is Callable and (close_variant as Callable).is_valid():
		(close_variant as Callable).call()
	_invite_party_dialog_state = {}
	ToastManager.success(UiText.SOCIAL_PARTY_INVITE, UiText.SOCIAL_PARTY_INVITE_SUCCESS)
	_refresh_party()


func _format_relative_datetime(datetime_variant: Variant) -> String:
	if datetime_variant == null:
		return UiText.SOCIAL_TIME_UNKNOWN
	var last_login_text: String = str(datetime_variant).strip_edges()
	if last_login_text == "":
		return UiText.SOCIAL_TIME_UNKNOWN
	var unix_time: int = int(Time.get_unix_time_from_datetime_string(last_login_text))
	if unix_time <= 0:
		return last_login_text.replace("T", " ").substr(0, mini(last_login_text.length(), 19))
	var now_unix: int = int(Time.get_unix_time_from_system())
	var diff_seconds: int = maxi(0, now_unix - unix_time)
	if diff_seconds < 60:
		return UiText.SOCIAL_TIME_JUST_NOW
	if diff_seconds < 3600:
		return UiText.SOCIAL_TIME_MINUTES_FORMAT % maxi(1, floori(float(diff_seconds) / 60.0))
	if diff_seconds < 86400:
		return UiText.SOCIAL_TIME_HOURS_FORMAT % maxi(1, floori(float(diff_seconds) / 3600.0))
	if diff_seconds < 604800:
		return UiText.SOCIAL_TIME_DAYS_FORMAT % maxi(1, floori(float(diff_seconds) / 86400.0))
	return last_login_text.replace("T", " ").substr(0, mini(last_login_text.length(), 19))


func _format_last_login_text(last_login_variant: Variant) -> String:
	return _format_relative_datetime(last_login_variant)


func _format_friend_stage_text(stage_variant: Variant) -> String:
	var current_stage: int = max(1, int(stage_variant))
	var boss_cfg: Dictionary = GameState.boss_config if GameState.boss_config is Dictionary else {}
	if boss_cfg.is_empty():
		return UiText.SOCIAL_STAGE_FORMAT % current_stage

	var stage_text: String = FriendStageFormatter.get_level_display(current_stage, boss_cfg).strip_edges()
	while stage_text.contains("  "):
		stage_text = stage_text.replace("  ", " ")
	return stage_text


func _format_party_invite_last_login(last_login_variant: Variant) -> String:
	return _format_relative_datetime(last_login_variant)


func _kick_party_member(user_id: int) -> void:
	ApiClient.kick_party_member(
		int(_party_detail.get("partyId", 0)),
		user_id,
		Callable(self, "_on_party_action_completed").bind(UiText.SOCIAL_PARTY_KICK, UiText.SOCIAL_PARTY_KICK_SUCCESS)
	)


func _confirm_kick_party_member(user_id: int, member_name: String) -> void:
	var target_label: String = member_name.strip_edges()
	if target_label == "":
		target_label = UiText.SOCIAL_PARTY_MEMBER_THIS
	DialogManager.show_confirm(
		UiText.SOCIAL_PARTY_KICK,
		UiText.SOCIAL_PARTY_KICK_CONFIRM_FORMAT % target_label,
		Callable(self, "_kick_party_member").bind(user_id)
	)


func _cheer_party(is_ad_boost: bool) -> void:
	var title: String = UiText.SOCIAL_PARTY_AD_CHEER if is_ad_boost else UiText.SOCIAL_PARTY_FREE_CHEER
	ApiClient.cheer_party(
		int(_party_detail.get("partyId", 0)),
		is_ad_boost,
		Callable(self, "_on_party_action_completed").bind(title, UiText.SOCIAL_PARTY_CHEER_SUCCESS)
	)


func _build_idle_reward_float_entries(rewards: Dictionary) -> Array[Dictionary]:
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	if battle_scene != null and battle_scene.has_method("build_idle_reward_float_entries"):
		return battle_scene.build_idle_reward_float_entries(rewards)

	var reward_entries: Array[Dictionary] = []
	var reward_defs: Array = [
		[UiText.REWARD_GOLD, "gold"],
		[UiText.REWARD_DIAMONDS, "diamonds"],
		[UiText.REWARD_POOP, "poop"],
		[UiText.REWARD_CAT_FOOD, "cat_food"],
		[UiText.REWARD_EXP, "exp"],
		[UiText.REWARD_MEMORY_SHARDS, "memory_shards"],
		[UiText.REWARD_WHISKERS, "whiskers"],
	]
	for entry_variant: Variant in reward_defs:
		if not (entry_variant is Array):
			continue
		var entry: Array = entry_variant
		var reward_key: String = str(entry[1])
		var amount: int = int(rewards.get(reward_key, 0))
		if amount <= 0:
			continue
		reward_entries.append(_make_home_reward_float_entry(str(entry[0]), amount, reward_key))
	return reward_entries


func _make_home_reward_float_entry(label: String, amount: int, reward_key: String) -> Dictionary:
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	if battle_scene != null and battle_scene.has_method("make_reward_float_entry"):
		return battle_scene.make_reward_float_entry(label, amount, reward_key)

	var color: Color = Color(0.98, 0.92, 0.76, 1.0)
	match reward_key:
		"gold":
			color = Color(1.0, 0.84, 0.25, 1.0)
		"diamonds":
			color = Color(0.35, 0.86, 1.0, 1.0)
		"poop":
			color = Color(0.80, 0.58, 0.35, 1.0)
		"exp":
			color = Color(0.63, 0.96, 0.54, 1.0)
		"memory_shards":
			color = Color(0.87, 0.72, 1.0, 1.0)
		"whiskers":
			color = Color(1.0, 0.66, 0.82, 1.0)
		"cat_food":
			color = Color(1.0, 0.73, 0.43, 1.0)
	return {
		"label": label,
		"amount": amount,
		"key": reward_key,
		"color": color,
	}


func _queue_home_reward_floats(entries: Array[Dictionary]) -> void:
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	if battle_scene != null and battle_scene.has_method("queue_home_reward_floats"):
		battle_scene.queue_home_reward_floats(entries)


func _use_party_coupon() -> void:
	ApiClient.use_party_cheer_coupon(Callable(self, "_on_use_party_coupon_completed"))


func _on_use_party_coupon_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_PARTY_USE_COUPON, _error_message(error))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var wallet_snapshot: Variant = payload.get("walletSnapshot", {})
	if wallet_snapshot is Dictionary:
		GameState.apply_wallet_snapshot(wallet_snapshot)
	var reward_entries: Array[Dictionary] = _build_idle_reward_float_entries(payload.get("rewards", {}))
	if not reward_entries.is_empty():
		_queue_home_reward_floats(reward_entries)
	_refresh_party()


func _show_party_applications() -> void:
	_party_section = "reviews"
	_refresh_party_footer_buttons()
	_reload_current_party_section()


func _open_rename_party_dialog() -> void:
	_rename_party_dialog_state = _open_text_input(UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_NAME_PLACEHOLDER, Callable(self, "_submit_rename_party"), false)


func _submit_rename_party(value: String) -> void:
	ApiClient.update_party_name(
		int(_party_detail.get("partyId", 0)),
		value,
		Callable(self, "_on_submit_rename_party_completed")
	)


func _on_submit_rename_party_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		_set_text_input_dialog_submitting(_rename_party_dialog_state, false)
		_after_party_action(false, error, UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_RENAME_SUCCESS)
		return
	var close_dialog_variant: Variant = _rename_party_dialog_state.get("close", Callable())
	if close_dialog_variant is Callable and (close_dialog_variant as Callable).is_valid():
		(close_dialog_variant as Callable).call()
	_rename_party_dialog_state = {}
	_after_party_action(success, error, UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_RENAME_SUCCESS)


func _transfer_party(target_user_id: int) -> void:
	ApiClient.transfer_party_leadership(
		int(_party_detail.get("partyId", 0)),
		target_user_id,
		Callable(self, "_on_party_action_completed").bind(UiText.SOCIAL_PARTY_TRANSFER, UiText.SOCIAL_PARTY_TRANSFER_SUCCESS)
	)


func _confirm_transfer_party(target_user_id: int, member_name: String) -> void:
	var target_label: String = member_name.strip_edges()
	if target_label == "":
		target_label = UiText.SOCIAL_PARTY_MEMBER_THIS
	DialogManager.show_confirm(
		UiText.SOCIAL_PARTY_TRANSFER,
		UiText.SOCIAL_PARTY_TRANSFER_CONFIRM_FORMAT % target_label,
		Callable(self, "_transfer_party").bind(target_user_id)
	)



func _disband_party() -> void:
	ApiClient.disband_party(
		int(_party_detail.get("partyId", 0)),
		Callable(self, "_on_party_action_completed").bind(UiText.SOCIAL_PARTY_DISBAND, UiText.SOCIAL_PARTY_DISBAND_SUCCESS)
	)


func _confirm_disband_party() -> void:
	DialogManager.show_confirm(
		UiText.SOCIAL_PARTY_DISBAND,
		UiText.SOCIAL_PARTY_DISBAND_CONFIRM,
		Callable(self, "_disband_party")
	)


func _on_party_exit_pressed() -> void:
	if bool(_party_detail.get("isUsurpationEligible", false)) and not _is_party_leader():
		_usurp_party()
		return
	_leave_party()


func _usurp_party() -> void:
	ApiClient.usurp_party_leadership(
		int(_party_detail.get("partyId", 0)),
		Callable(self, "_on_party_action_completed").bind(UiText.SOCIAL_PARTY_USURP, UiText.SOCIAL_PARTY_USURP_SUCCESS)
	)


func _leave_party() -> void:
	var member_variants: Array = _party_detail.get("members", [])
	if member_variants.size() <= 1:
		_confirm_disband_party()
		return
	ApiClient.leave_party(
		int(_party_detail.get("partyId", 0)),
		Callable(self, "_on_party_action_completed").bind(UiText.SOCIAL_PARTY_LEAVE, UiText.SOCIAL_PARTY_LEAVE_SUCCESS)
	)


func _on_party_action_completed(success: bool, _data: Variant, error: Dictionary, title: String, success_message: String) -> void:
	_after_party_action(success, error, title, success_message)


func _after_party_action(success: bool, error: Dictionary, title: String, success_message: String) -> void:
	if not success:
		ToastManager.error(title, _error_message(error))
		return
	ToastManager.success(title, success_message)
	_refresh_party()


func _error_message(error: Dictionary) -> String:
	return str(error.get("message", UiText.SOCIAL_ACTION_FAILED))


func _friend_request_id(item: Dictionary) -> int:
	var raw_value: Variant = item.get("requestId", item.get("id", item.get("friendRequestId", 0)))
	return int(raw_value)


func _friend_request_created_at(item: Dictionary) -> Variant:
	if item.has("createdAtUtc"):
		return item.get("createdAtUtc")
	if item.has("createdAt"):
		return item.get("createdAt")
	if item.has("requestedAtUtc"):
		return item.get("requestedAtUtc")
	return null


func _friend_request_sender_name(item: Dictionary) -> String:
	return _first_nonempty_string([
		item.get("senderDisplayName", ""),
		item.get("senderPlayerName", ""),
		item.get("displayName", ""),
		item.get("playerName", ""),
		item.get("senderName", ""),
		item.get("receiverDisplayName", ""),
	])


func _friend_request_sender_uid(item: Dictionary) -> String:
	return _first_nonempty_string([
		item.get("senderPlayerUid", ""),
		item.get("playerUid", ""),
		item.get("senderUid", ""),
		item.get("receiverPlayerUid", ""),
	])


func _friend_request_sender_avatar_id(item: Dictionary) -> String:
	return _first_nonempty_string([
		item.get("senderAvatarId", ""),
		item.get("avatarId", ""),
		item.get("receiverAvatarId", ""),
	])


func _friend_request_receiver_name(item: Dictionary) -> String:
	return _first_nonempty_string([
		item.get("receiverDisplayName", ""),
		item.get("receiverPlayerName", ""),
		item.get("displayName", ""),
		item.get("playerName", ""),
		item.get("senderDisplayName", ""),
	])


func _friend_request_receiver_uid(item: Dictionary) -> String:
	return _first_nonempty_string([
		item.get("receiverPlayerUid", ""),
		item.get("playerUid", ""),
		item.get("receiverUid", ""),
		item.get("senderPlayerUid", ""),
	])


func _friend_request_receiver_avatar_id(item: Dictionary) -> String:
	return _first_nonempty_string([
		item.get("receiverAvatarId", ""),
		item.get("avatarId", ""),
		item.get("senderAvatarId", ""),
	])


func _first_nonempty_string(candidates: Array) -> String:
	for candidate_variant: Variant in candidates:
		var candidate: String = str(candidate_variant).strip_edges()
		if candidate != "":
			return candidate
	return ""


func _is_party_leader() -> bool:
	var self_names: Array[String] = [
		str(GameState.player_data.display_name).strip_edges(),
		str(GameState.player_data.player_name).strip_edges(),
	]
	return str(_party_detail.get("leaderDisplayName", "")).strip_edges() in self_names


func _is_current_player_member(member: Dictionary) -> bool:
	var display_name: String = str(member.get("displayName", "")).strip_edges()
	return display_name == str(GameState.player_data.display_name).strip_edges() or display_name == str(GameState.player_data.player_name).strip_edges()


func _get_free_cheer_button_text() -> String:
	var remaining_count: int = 0 if bool(_party_cheer_status.get("hasCheeredFree", false)) else 1
	return "%s(%d/1)" % [UiText.SOCIAL_PARTY_FREE_CHEER, remaining_count]


func _build_party_cheer_button() -> Button:
	var has_free: bool = bool(_party_cheer_status.get("hasCheeredFree", false))
	var has_ad: bool = bool(_party_cheer_status.get("hasCheeredAd", false))
	var button: Button
	if not has_free:
		button = _make_action_button("%s(1/1)" % UiText.SOCIAL_PARTY_FREE_CHEER, "confirm")
		button.pressed.connect(Callable(self, "_cheer_party").bind(false))
	elif not has_ad:
		var label: String = UiText.SOCIAL_PARTY_FREE_CHEER if GameState.is_ad_free() else UiText.SOCIAL_PARTY_AD_CHEER
		button = _make_action_button("%s(1/1)" % label, "secondary")
		button.pressed.connect(Callable(self, "_cheer_party").bind(true))
	else:
		button = _make_action_button("%s(0/1)" % UiText.SOCIAL_PARTY_AD_CHEER, "secondary")
		button.disabled = true
	_style_party_overlay_button(button, PARTY_CHEER_BUTTON_SIZE)
	RedDotService.refresh_dot(button, RedDotService.has_party_free_cheer_red_dot())
	return button


func _get_party_exit_button_text() -> String:
	if bool(_party_detail.get("isUsurpationEligible", false)) and not _is_party_leader():
		return UiText.SOCIAL_PARTY_USURP
	var member_variants: Array = _party_detail.get("members", [])
	if _is_party_leader() and member_variants.size() <= 1:
		return UiText.SOCIAL_PARTY_DISBAND
	return UiText.SOCIAL_PARTY_LEAVE


func _accept_party_application(application_id: int, applicant_name: String) -> void:
	ApiClient.accept_party_application(
		application_id,
		Callable(self, "_on_accept_party_application_completed").bind(applicant_name)
	)


func _on_accept_party_application_completed(success: bool, _data: Variant, error: Dictionary, applicant_name: String) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_PARTY_PENDING_REVIEW, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_PARTY_PENDING_REVIEW, UiText.SOCIAL_PARTY_APPLICATION_ACCEPT_SUCCESS % applicant_name)
	_load_party_applications()
	_refresh_party()


func _confirm_reject_party_application(application_id: int, applicant_name: String) -> void:
	var target_label: String = applicant_name.strip_edges()
	if target_label == "":
		target_label = UiText.SOCIAL_PLAYER_THIS
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REJECT,
		UiText.SOCIAL_PARTY_REJECT_APPLICATION_CONFIRM_FORMAT % target_label,
		Callable(self, "_reject_party_application").bind(application_id)
	)


func _reject_party_application(application_id: int) -> void:
	ApiClient.reject_party_application(application_id, Callable(self, "_on_reject_party_application_completed"))


func _on_reject_party_application_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_PARTY_PENDING_REVIEW, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_PARTY_PENDING_REVIEW, UiText.SOCIAL_PARTY_APPLICATION_REJECT_SUCCESS)
	_load_party_applications()
	_refresh_party()


func _accept_party_invite(application_id: int, party_name: String) -> void:
	ApiClient.accept_party_invite(
		application_id,
		Callable(self, "_on_accept_party_invite_completed").bind(party_name)
	)


func _on_accept_party_invite_completed(success: bool, _data: Variant, error: Dictionary, party_name: String) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_PARTY_PENDING_INVITES, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_PARTY_PENDING_INVITES, UiText.SOCIAL_PARTY_INVITE_ACCEPT_SUCCESS % party_name)
	_refresh_party()


func _confirm_reject_party_invite(application_id: int, party_name: String) -> void:
	var target_label: String = party_name.strip_edges()
	if target_label == "":
		target_label = UiText.SOCIAL_PARTY_THIS
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REJECT,
		UiText.SOCIAL_PARTY_REJECT_INVITE_CONFIRM_FORMAT % target_label,
		Callable(self, "_reject_party_invite").bind(application_id, target_label)
	)


func _reject_party_invite(application_id: int, party_name: String) -> void:
	ApiClient.reject_party_invite(
		application_id,
		Callable(self, "_on_reject_party_invite_completed").bind(party_name)
	)


func _on_reject_party_invite_completed(success: bool, _data: Variant, error: Dictionary, party_name: String) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_PARTY_PENDING_INVITES, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_PARTY_PENDING_INVITES, UiText.SOCIAL_PARTY_INVITE_REJECT_SUCCESS % party_name)
	_refresh_party()
