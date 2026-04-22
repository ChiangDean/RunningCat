extends Control

const ContentBottomSubmenu = preload("res://scripts/ui/content_bottom_submenu.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const FriendStageFormatter = preload("res://scripts/gamestate/GameStateBossStage.gd")
const RedDotService = preload("res://scripts/ui/red_dot_service.gd")

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

var _root_box: VBoxContainer
var _scroll: ScrollContainer
var _content_box: VBoxContainer
var _footer_panel: PanelContainer
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
		_root_box = VBoxContainer.new()
		_root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(_root_box)

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
	var recovered_cheer_status: Dictionary = {}
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
	count_label.text = UiText.SOCIAL_FRIEND_COUNT_FORMAT % [friend_rows.size(), 30]
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	count_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	header_row.add_child(count_label)

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
	var card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(card)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	card.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = UiText.SOCIAL_FRIEND_INBOX
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.SOCIAL_FRIEND_INBOX_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(desc)

	if _friend_inbox.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in _friend_inbox:
		if item_variant is Dictionary:
			box.add_child(_build_friend_inbox_row(item_variant))


func _render_friend_outbox(host: VBoxContainer) -> void:
	var card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(card)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	card.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = UiText.SOCIAL_FRIEND_OUTBOX
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.SOCIAL_FRIEND_OUTBOX_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(desc)

	if _friend_outbox.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in _friend_outbox:
		if item_variant is Dictionary:
			box.add_child(_build_friend_outbox_row(item_variant))


func _render_party() -> void:
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
	return _party_my_applications.filter(func(item_variant: Variant) -> bool:
		if not (item_variant is Dictionary):
			return false
		var item: Dictionary = item_variant as Dictionary
		return _is_party_invite_type(int(item.get("applicationType", 0))) and int(item.get("status", 0)) == 0
	)


func _get_my_pending_party_reviews() -> Array:
	return _party_my_applications.filter(func(item_variant: Variant) -> bool:
		if not (item_variant is Dictionary):
			return false
		var item: Dictionary = item_variant as Dictionary
		return _is_party_player_apply_type(int(item.get("applicationType", 0))) and int(item.get("status", 0)) == 0
	)


func _build_friend_footer_summary(section_key: String) -> String:
	match section_key:
		"inbox":
			return "\u7533\u8acb %d" % _friend_inbox.size()
		"outbox":
			return "\u9001\u51fa %d" % _friend_outbox.size()
		_:
			var friends: Array = _friend_list.get("friends", [])
			return "\u597d\u53cb %d/30" % friends.size()


func _build_party_footer_summary(section_key: String) -> String:
	match section_key:
		"invites":
			var invite_count: int = _get_my_pending_party_invites().size() if _party_detail.is_empty() else _get_party_pending_invites().size()
			return "\u5f85\u8655\u7406 %d" % invite_count
		"reviews":
			var review_count: int = _get_my_pending_party_reviews().size() if _party_detail.is_empty() else _get_party_pending_reviews().size()
			return "\u5f85\u8655\u7406 %d" % review_count
		_:
			if _party_detail.is_empty():
				return "\u672a\u52a0\u5165\u968a\u4f0d"
			var members: Array = _party_detail.get("members", [])
			return "\u6210\u54e1 %d/5" % members.size()


func _get_party_pending_reviews() -> Array:
	return _party_applications.filter(func(item_variant: Variant) -> bool:
		return item_variant is Dictionary and _is_party_player_apply_type(int((item_variant as Dictionary).get("applicationType", 0)))
	)


func _get_party_pending_invites() -> Array:
	return _party_applications.filter(func(item_variant: Variant) -> bool:
		if not (item_variant is Dictionary):
			return false
		var item: Dictionary = item_variant as Dictionary
		return _is_party_invite_type(int(item.get("applicationType", 0))) and int(item.get("status", 0)) == 0
	)


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
	var summary_card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	summary_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(summary_card)

	var summary_margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	summary_card.add_child(summary_margin)

	var summary_box: VBoxContainer = VBoxContainer.new()
	summary_box.add_theme_constant_override("separation", 10)
	summary_margin.add_child(summary_box)

	var title: Label = Label.new()
	title.text = UiText.SOCIAL_PARTY_EMPTY
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	summary_box.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.SOCIAL_PARTY_EMPTY_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	summary_box.add_child(desc)

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


func _render_party_reviews(host: VBoxContainer) -> void:
	var card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(card)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	card.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = UiText.SOCIAL_PARTY_PENDING_REVIEW
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	if not _is_party_leader():
		var hint: Label = Label.new()
		hint.text = "\u968a\u54e1\u53ef\u4ee5\u6aa2\u8996\u7533\u8acb\uff0c\u4f46\u53ea\u6709\u968a\u9577\u53ef\u4ee5\u5be9\u6838\u3002\u968a\u4f0d\u9080\u8acb\u6703\u7531\u88ab\u9080\u8acb\u8005\u81ea\u884c\u56de\u61c9\u3002"
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
	desc.text = UiText.SOCIAL_PARTY_PENDING_INVITES_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(desc)

	var invite_items: Array = _get_my_pending_party_invites()
	if invite_items.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in invite_items:
		if item_variant is Dictionary:
			box.add_child(_build_my_party_invite_row(item_variant))


func _render_party_pending_invites(host: VBoxContainer) -> void:
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
	desc.text = "檢視隊伍已送出、正在等待對方回應的邀請。"
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
	var card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(card)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	card.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = UiText.SOCIAL_PARTY_PENDING_REVIEW
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.SOCIAL_PARTY_PENDING_REVIEW_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(desc)

	var review_items: Array = _get_my_pending_party_reviews()
	if review_items.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in review_items:
		if item_variant is Dictionary:
			box.add_child(_build_my_party_review_row(item_variant))


func _build_party_review_row(item_variant: Variant, read_only: bool = false) -> Control:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	RedDotService.refresh_dot(panel, not read_only)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var name_label: Label = Label.new()
	name_label.text = str(item.get("applicantDisplayName", ""))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var type_label: Label = Label.new()
	type_label.text = _party_application_type_text(int(item.get("applicationType", 0)))
	if str(item.get("inviterDisplayName", "")).strip_edges() != "":
		type_label.text += "  |  \u9080\u8acb\u4eba %s" % str(item.get("inviterDisplayName", "")).strip_edges()
	type_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	type_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	type_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(type_label)

	var time_label: Label = Label.new()
	time_label.text = "\u7533\u8acb\u6642\u9593\uff1a%s" % _format_relative_datetime(item.get("createdAtUtc", null))
	time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	if read_only:
		var readonly_label: Label = Label.new()
		readonly_label.text = "\u50c5\u968a\u9577\u53ef\u5be9\u6838"
		readonly_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		readonly_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		row.add_child(readonly_label)
		return panel

	var accept_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ACCEPT, "confirm")
	accept_button.custom_minimum_size = Vector2(96.0, 46.0)
	RedDotService.refresh_dot(accept_button, true)
	accept_button.pressed.connect(func() -> void:
		_accept_party_application(int(item.get("applicationId", 0)), str(item.get("applicantDisplayName", "")))
	)
	row.add_child(accept_button)

	var reject_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REJECT, "danger")
	reject_button.custom_minimum_size = Vector2(96.0, 46.0)
	reject_button.pressed.connect(func() -> void:
		_confirm_reject_party_application(int(item.get("applicationId", 0)), str(item.get("applicantDisplayName", "")))
	)
	row.add_child(reject_button)

	return panel


func _build_my_party_invite_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

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
	meta_label.text = "%s  |  \u9080\u8acb\u4eba %s" % [
		_party_application_type_text(int(item.get("applicationType", 0))),
		str(item.get("inviterDisplayName", "")).strip_edges() if str(item.get("inviterDisplayName", "")).strip_edges() != "" else "\u968a\u4f0d\u6210\u54e1"
	]
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	meta_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(meta_label)

	var time_label: Label = Label.new()
	time_label.text = "\u7533\u8acb\u6642\u9593\uff1a%s" % _format_relative_datetime(item.get("createdAtUtc", null))
	time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	var accept_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ACCEPT, "confirm")
	accept_button.custom_minimum_size = Vector2(96.0, 46.0)
	accept_button.pressed.connect(func() -> void:
		_accept_party_invite(int(item.get("applicationId", 0)), str(item.get("partyName", "")))
	)
	row.add_child(accept_button)

	var reject_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REJECT, "danger")
	reject_button.custom_minimum_size = Vector2(96.0, 46.0)
	reject_button.pressed.connect(func() -> void:
		_confirm_reject_party_invite(int(item.get("applicationId", 0)), str(item.get("partyName", "")))
	)
	row.add_child(reject_button)

	return panel


func _build_my_party_review_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

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
	time_label.text = "\u7533\u8acb\u6642\u9593\uff1a%s" % _format_relative_datetime(item.get("createdAtUtc", null))
	time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	var cancel_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_CANCEL, "secondary")
	cancel_button.custom_minimum_size = Vector2(96.0, 46.0)
	cancel_button.pressed.connect(func() -> void:
		_cancel_party_application(int(item.get("applicationId", 0)), str(item.get("partyName", "")))
	)
	row.add_child(cancel_button)

	return panel


func _build_party_pending_invite_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var player_name_label: Label = Label.new()
	player_name_label.text = str(item.get("applicantDisplayName", "")).strip_edges()
	if player_name_label.text == "":
		player_name_label.text = "未命名玩家"
	player_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	player_name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(player_name_label)

	var meta_label: Label = Label.new()
	meta_label.text = "%s  |  邀請人 %s" % [
		_party_application_type_text(int(item.get("applicationType", 0))),
		str(item.get("inviterDisplayName", "")).strip_edges() if str(item.get("inviterDisplayName", "")).strip_edges() != "" else "隊伍成員"
	]
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	meta_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(meta_label)

	var time_label: Label = Label.new()
	time_label.text = "邀請時間：%s" % _format_relative_datetime(item.get("createdAtUtc", null))
	time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	var readonly_label: Label = Label.new()
	readonly_label.text = "等待對方回應"
	readonly_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	readonly_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	row.add_child(readonly_label)

	return panel


func _build_friend_row(item_variant: Variant) -> PanelContainer:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var remove_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REMOVE, "danger")
	remove_button.custom_minimum_size = Vector2(64.0, 40.0)
	remove_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	remove_button.pressed.connect(func() -> void:
		_confirm_remove_friend(int(item.get("friendUserId", 0)), str(item.get("displayName", "")))
	)
	row.add_child(remove_button)

	var avatar_id: String = str(item.get("avatarId", "")).strip_edges()
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(56.0, 56.0)
	)
	row.add_child(avatar_rect)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var name_label: Label = Label.new()
	name_label.text = str(item.get("displayName", "")).strip_edges()
	if name_label.text == "":
		name_label.text = "\u672a\u547d\u540d\u73a9\u5bb6"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var meta_label: Label = Label.new()
	meta_label.text = "\u93df\u5c4e\u5b98 Lv.%d  |  %s" % [
		int(item.get("scooperLevel", 0)),
		_format_friend_stage_text(item.get("currentStage", 1))
	]
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	meta_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(meta_label)

	var last_login_label: Label = Label.new()
	last_login_label.text = "\u6700\u5f8c\u4e0a\u7dda\uff1a%s" % _format_last_login_text(item.get("lastLoginAtUtc", null))
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

	return panel


func _build_friend_inbox_row(item_variant: Variant) -> PanelContainer:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var avatar_id: String = _friend_request_sender_avatar_id(item)
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(56.0, 56.0)
	)
	row.add_child(avatar_rect)

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
	time_label.text = "\u7533\u8acb\u6642\u9593\uff1a%s" % _format_relative_datetime(_friend_request_created_at(item))
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	var accept_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ACCEPT, "confirm")
	accept_button.custom_minimum_size = Vector2(96.0, 46.0)
	accept_button.pressed.connect(func() -> void:
		_accept_friend_request(_friend_request_id(item))
	)
	row.add_child(accept_button)

	var reject_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REJECT, "danger")
	reject_button.custom_minimum_size = Vector2(96.0, 46.0)
	reject_button.pressed.connect(func() -> void:
		_confirm_reject_friend_request(
			_friend_request_id(item),
			sender_name
		)
	)
	row.add_child(reject_button)

	return panel


func _build_friend_outbox_row(item_variant: Variant) -> PanelContainer:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var avatar_id: String = _friend_request_receiver_avatar_id(item)
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(56.0, 56.0)
	)
	row.add_child(avatar_rect)

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
	time_label.text = "\u7533\u8acb\u6642\u9593\uff1a%s" % _format_relative_datetime(_friend_request_created_at(item))
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(time_label)

	if int(item.get("status", 0)) == 0:
		var cancel_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_CANCEL, "secondary")
		cancel_button.custom_minimum_size = Vector2(96.0, 46.0)
		cancel_button.pressed.connect(func() -> void:
			_cancel_friend_request(_friend_request_id(item))
		)
		row.add_child(cancel_button)

	return panel


func _build_party_input_card(
	title_text: String,
	desc_text: String,
	placeholder_text: String,
	button_text: String,
	button_kind: String,
	submit_handler: Callable
) -> PanelContainer:
	var card: PanelContainer = OverlaySceneChrome.make_card_panel()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	card.add_child(margin)

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
	var submit := func() -> void:
		if button.disabled:
			return
		var value: String = input.text.strip_edges()
		if value == "":
			ToastManager.hint(title_text, UiText.SOCIAL_INPUT_EMPTY)
			return
		button.disabled = true
		input.editable = false
		submit_handler.call(value, input, button)
	button.pressed.connect(submit)
	input.text_submitted.connect(func(_text: String) -> void:
		submit.call()
	)
	input_row.add_child(button)

	return card


func _restore_party_inline_input(input: LineEdit, button: Button) -> void:
	if is_instance_valid(input):
		input.editable = true
		input.grab_focus()
	if is_instance_valid(button):
		button.disabled = false


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
		target_label = "\u9019\u500b\u968a\u4f0d"
	DialogManager.show_confirm(
		UiText.SOCIAL_PARTY_MY_APPLICATIONS,
		"\u78ba\u5b9a\u8981\u53d6\u6d88\u5c0d %s \u7684\u7533\u8acb\u55ce\uff1f" % target_label,
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
			return "\u73a9\u5bb6\u7533\u8acb"
		2:
			return "\u968a\u54e1\u9080\u8acb"
		3:
			return "\u968a\u9577\u9080\u8acb"
		_:
			return "\u5176\u4ed6"


func _party_application_status_text(status: int) -> String:
	match status:
		0:
			return "\u5f85\u5be9\u6838"
		1:
			return "\u5df2\u63a5\u53d7"
		2:
			return "\u5df2\u62d2\u7d55"
		3:
			return "\u5df2\u53d6\u6d88"
		_:
			return "\u672a\u77e5"


func _build_party_member_row(member_variant: Variant) -> PanelContainer:
	var member: Dictionary = member_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var name_label: Label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = "%s / %s" % [
		str(member.get("displayName", "")),
		UiText.SOCIAL_PARTY_ROLE_LEADER if bool(member.get("isLeader", false)) else UiText.SOCIAL_PARTY_ROLE_MEMBER
	]
	row.add_child(name_label)

	if _is_party_leader() and not _is_current_player_member(member):
		var member_name: String = str(member.get("displayName", ""))
		var transfer_button: Button = _make_action_button(UiText.SOCIAL_PARTY_TRANSFER, "rank")
		transfer_button.custom_minimum_size = Vector2(132.0, 46.0)
		transfer_button.pressed.connect(func() -> void:
			_confirm_transfer_party(int(member.get("userId", 0)), member_name)
		)
		row.add_child(transfer_button)

		var kick_button: Button = _make_action_button(UiText.SOCIAL_PARTY_KICK, "danger")
		kick_button.custom_minimum_size = Vector2(96.0, 46.0)
		kick_button.pressed.connect(func() -> void:
			_confirm_kick_party_member(int(member.get("userId", 0)), member_name)
		)
		row.add_child(kick_button)

	return panel


func _make_action_button(text_value: String, kind: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	UiPalette.apply_button_kind(button, kind)
	return button


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
			return "\u5f85\u56de\u61c9"
		1:
			return "\u5df2\u63a5\u53d7"
		2:
			return "\u5df2\u62d2\u7d55"
		3:
			return "\u5df2\u53d6\u6d88"
		_:
			return "\u672a\u77e5"


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
	var callback := func(success: bool, data: Variant, error: Dictionary) -> void:
		_friend_gift_in_flight = false
		if not success:
			ToastManager.error(UiText.SOCIAL_FRIEND_GIFT_ALL, _error_message(error))
			return
		var payload: Dictionary = data if data is Dictionary else {}
		var recipient_count: int = int(payload.get("recipientCount", 0))
		if recipient_count <= 0:
			ToastManager.hint(UiText.SOCIAL_FRIEND_GIFT_ALL, "\u76ee\u524d\u6c92\u6709\u53ef\u9001\u79ae\u7684\u597d\u53cb")
			_refresh_friend()
			return
		ToastManager.success(UiText.SOCIAL_FRIEND_GIFT_ALL, UiText.SOCIAL_FRIEND_GIFT_SUCCESS % recipient_count)
		_refresh_friend()
	ApiClient.send_friend_gifts(callback)


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
		target_label = "\u9019\u4f4d\u597d\u53cb"
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REMOVE,
		"\u78ba\u5b9a\u8981\u79fb\u9664 %s \u55ce\uff1f" % target_label,
		func() -> void:
			_remove_friend(friend_user_id)
	)


func _remove_friend(friend_user_id: int) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_FRIEND_REMOVE, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_FRIEND_REMOVE, UiText.SOCIAL_FRIEND_REMOVE_SUCCESS)
		_refresh_friend()
	ApiClient.remove_friend(friend_user_id, callback)


func _open_showcase_dialog() -> void:
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	for cat_variant: Variant in GameState.player_cats_data:
		if not (cat_variant is Dictionary):
			continue
		var cat: Dictionary = cat_variant
		var button: Button = _make_action_button(str(cat.get("displayName", cat.get("catDisplayName", ""))), "info")
		button.pressed.connect(func() -> void:
			_set_showcase_cat(int(cat.get("playerCatId", 0)))
		)
		content.add_child(button)

	var clear_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_SHOWCASE_CLEAR, "secondary")
	clear_button.pressed.connect(_clear_showcase_cat)
	content.add_child(clear_button)

	DialogManager.show_info_node(UiText.SOCIAL_FRIEND_SHOWCASE, content, Callable(), "large")


func _set_showcase_cat(player_cat_id: int) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_FRIEND_SHOWCASE, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_FRIEND_SHOWCASE, UiText.SOCIAL_FRIEND_SHOWCASE_SUCCESS)
		_refresh_friend()
	ApiClient.set_friend_showcase_cat(player_cat_id, callback)


func _clear_showcase_cat() -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_FRIEND_SHOWCASE, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_FRIEND_SHOWCASE, UiText.SOCIAL_FRIEND_SHOWCASE_CLEARED)
		_refresh_friend()
	ApiClient.clear_friend_showcase_cat(callback)


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
	var submit_input := func() -> void:
		if bool(dialog_state.get("is_submitting", false)):
			return
		var value: String = input.text.strip_edges()
		if value == "":
			ToastManager.hint(title, UiText.SOCIAL_INPUT_EMPTY)
			return
		_set_text_input_dialog_submitting(dialog_state, true)
		if close_dialog.is_valid():
			dialog_state["close"] = close_dialog
			if close_on_submit:
				close_dialog.call()
		on_confirm.call(value)
	confirm_button.pressed.connect(submit_input)
	box.add_child(confirm_button)
	input.text_submitted.connect(func(_text: String) -> void:
		submit_input.call()
	)

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


func _open_add_friend_dialog() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.custom_minimum_size = Vector2(0.0, 620.0)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)

	var intro_label: Label = Label.new()
	intro_label.text = "\u8f38\u5165\u5c0d\u65b9\u904a\u6232\u540d\u7a31\uff0c\u6309\u78ba\u5b9a\u5f8c\u6703\u5217\u51fa\u53ef\u52a0\u597d\u53cb\u7684\u73a9\u5bb6\u3002"
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
	status_label.text = "\u8f38\u5165\u540d\u7a31\u5f8c\u6309\u78ba\u5b9a\u9032\u884c\u641c\u5c0b\u3002"
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

	var submit_search := func() -> void:
		if bool(dialog_state.get("is_searching", false)) or bool(dialog_state.get("is_submitting", false)):
			return
		var query: String = input.text.strip_edges()
		if query == "":
			ToastManager.hint(UiText.SOCIAL_FRIEND_ADD, UiText.SOCIAL_INPUT_EMPTY)
			return
		_search_friend_candidates(dialog_state, query)

	confirm_button.pressed.connect(submit_search)
	input.text_submitted.connect(func(_text: String) -> void:
		submit_search.call()
	)

	close_dialog = DialogManager.show_info_node(UiText.SOCIAL_FRIEND_ADD, box, Callable(), "xlarge")
	dialog_state["close"] = close_dialog
	input.grab_focus()


func _submit_add_friend(value: String) -> void:
	ApiClient.send_friend_request(value, Callable(self, "_on_submit_add_friend_completed"))


func _on_submit_add_friend_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SOCIAL_FRIEND_ADD, _error_message(error))
		return
	ToastManager.success(UiText.SOCIAL_FRIEND_ADD, UiText.SOCIAL_FRIEND_ADD_SUCCESS)
	_refresh_friend()


func _search_friend_candidates(dialog_state: Dictionary, query: String) -> void:
	_set_friend_search_dialog_busy(dialog_state, true, false)
	_set_friend_search_dialog_status(dialog_state, "\u641c\u5c0b\u4e2d...", OverlaySceneChrome.MUTED_TEXT_COLOR)
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
		_set_friend_search_dialog_status(dialog_state, "\u627e\u4e0d\u5230\u7b26\u5408\u7684\u73a9\u5bb6\u3002", OverlaySceneChrome.MUTED_TEXT_COLOR)
	else:
		_set_friend_search_dialog_status(dialog_state, "\u627e\u5230 %d \u4f4d\u73a9\u5bb6\uff0c\u53ef\u76f4\u63a5\u9001\u51fa\u597d\u53cb\u7533\u8acb\u3002" % candidates.size(), OverlaySceneChrome.MUTED_TEXT_COLOR)
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
	row.add_child(avatar_rect)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var player_name: String = str(candidate.get("playerName", "")).strip_edges()
	var name_label: Label = Label.new()
	name_label.text = player_name if player_name != "" else "\u672a\u547d\u540d\u73a9\u5bb6"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var uid_label: Label = Label.new()
	uid_label.text = "\u93df\u5c4e\u5b98 Lv.%d  |  UID %s" % [
		int(candidate.get("scooperLevel", 0)),
		str(candidate.get("playerUid", "")).strip_edges()
	]
	uid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	uid_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	uid_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(uid_label)

	var last_login_label: Label = Label.new()
	last_login_label.text = "\u6700\u5f8c\u4e0a\u7dda\uff1a%s" % _format_last_login_text(candidate.get("lastLoginAtUtc", null))
	last_login_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_login_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	last_login_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(last_login_label)

	var add_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ADD, "add")
	add_button.custom_minimum_size = Vector2(120.0, 48.0)
	add_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_button.disabled = bool(dialog_state.get("is_submitting", false))
	add_button.pressed.connect(func() -> void:
		_submit_friend_request_from_candidate(dialog_state, candidate)
	)
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
	_set_friend_search_dialog_status(dialog_state, "\u6b63\u5728\u9001\u51fa %s \u7684\u597d\u53cb\u7533\u8acb..." % (player_name if player_name != "" else player_uid), OverlaySceneChrome.MUTED_TEXT_COLOR)
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
		target_label = "\u9019\u4f4d\u73a9\u5bb6"
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REJECT,
		"\u78ba\u5b9a\u8981\u62d2\u7d55 %s \u7684\u597d\u53cb\u7533\u8acb\u55ce\uff1f" % target_label,
		func() -> void:
			_reject_friend_request(request_id)
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
	intro_label.text = "\u8f38\u5165\u5c0d\u65b9\u904a\u6232\u540d\u7a31\uff0c\u6309\u78ba\u5b9a\u5f8c\u6703\u5217\u51fa\u53ef\u9080\u8acb\u7684\u73a9\u5bb6\u3002"
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	intro_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(intro_label)

	var search_row: HBoxContainer = HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 10)
	box.add_child(search_row)

	var input: LineEdit = LineEdit.new()
	input.placeholder_text = "\u8f38\u5165\u5c0d\u65b9\u904a\u6232\u540d\u7a31"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row.add_child(input)

	var confirm_button: Button = _make_action_button(UiText.COMMON_CONFIRM, "confirm")
	confirm_button.custom_minimum_size = Vector2(132.0, 52.0)
	confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	search_row.add_child(confirm_button)

	var status_label: Label = Label.new()
	status_label.text = "\u8f38\u5165\u540d\u7a31\u5f8c\u6309\u78ba\u5b9a\u9032\u884c\u641c\u5c0b\u3002"
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

	var submit_search := func() -> void:
		if bool(dialog_state.get("is_searching", false)) or bool(dialog_state.get("is_inviting", false)):
			return
		var query: String = input.text.strip_edges()
		if query == "":
			ToastManager.hint(UiText.SOCIAL_PARTY_INVITE, UiText.SOCIAL_INPUT_EMPTY)
			return
		_search_party_invite_candidates(dialog_state, query)

	confirm_button.pressed.connect(submit_search)
	input.text_submitted.connect(func(_text: String) -> void:
		submit_search.call()
	)

	close_dialog = DialogManager.show_info_node(UiText.SOCIAL_PARTY_INVITE, box, Callable(), "xlarge")
	dialog_state["close"] = close_dialog
	_invite_party_dialog_state = dialog_state
	input.grab_focus()


func _search_party_invite_candidates(dialog_state: Dictionary, query: String) -> void:
	_set_invite_party_dialog_busy(dialog_state, true, false)
	_set_invite_party_dialog_status(dialog_state, "\u641c\u5c0b\u4e2d...", OverlaySceneChrome.MUTED_TEXT_COLOR)
	ApiClient.search_party_invite_candidates(
		int(_party_detail.get("partyId", 0)),
		query,
		Callable(self, "_on_party_invite_candidates_searched").bind(dialog_state)
	)


func _on_party_invite_candidates_searched(success: bool, data: Variant, error: Dictionary, dialog_state: Dictionary) -> void:
	_set_invite_party_dialog_busy(dialog_state, false, false)
	if not success:
		_set_invite_party_dialog_status(dialog_state, _error_message(error), UiPalette.BUTTON_DANGER_FG)
		_render_invite_party_candidates(dialog_state, [])
		return
	var candidates: Array = data if data is Array else []
	dialog_state["candidates"] = candidates
	if candidates.is_empty():
		_set_invite_party_dialog_status(dialog_state, "\u627e\u4e0d\u5230\u7b26\u5408\u7684\u73a9\u5bb6\u3002", OverlaySceneChrome.MUTED_TEXT_COLOR)
	else:
		_set_invite_party_dialog_status(dialog_state, "\u627e\u5230 %d \u4f4d\u73a9\u5bb6\uff0c\u53ef\u76f4\u63a5\u9001\u51fa\u9080\u8acb\u3002" % candidates.size(), OverlaySceneChrome.MUTED_TEXT_COLOR)
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
	row.add_child(avatar_rect)

	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	row.add_child(info_box)

	var player_name: String = str(candidate.get("playerName", "")).strip_edges()
	var name_label: Label = Label.new()
	name_label.text = player_name if player_name != "" else "\u672a\u547d\u540d\u73a9\u5bb6"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	info_box.add_child(name_label)

	var uid_label: Label = Label.new()
	uid_label.text = "\u93df\u5c4e\u5b98 Lv.%d  |  UID %s" % [
		int(candidate.get("scooperLevel", 0)),
		str(candidate.get("playerUid", "")).strip_edges()
	]
	uid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	uid_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	uid_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(uid_label)

	var last_login_label: Label = Label.new()
	last_login_label.text = "\u6700\u5f8c\u4e0a\u7dda\uff1a%s" % _format_party_invite_last_login(candidate.get("lastLoginAtUtc", null))
	last_login_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_login_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	last_login_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	info_box.add_child(last_login_label)

	var invite_button: Button = _make_action_button(UiText.SOCIAL_PARTY_INVITE, "add")
	invite_button.custom_minimum_size = Vector2(118.0, 52.0)
	invite_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	invite_button.disabled = bool(dialog_state.get("is_searching", false)) or bool(dialog_state.get("is_inviting", false))
	invite_button.pressed.connect(func() -> void:
		_invite_party_candidate(dialog_state, candidate)
	)
	row.add_child(invite_button)

	return panel


func _invite_party_candidate(dialog_state: Dictionary, candidate: Dictionary) -> void:
	if bool(dialog_state.get("is_searching", false)) or bool(dialog_state.get("is_inviting", false)):
		return
	var player_uid: String = str(candidate.get("playerUid", "")).strip_edges()
	if player_uid == "":
		ToastManager.error(UiText.SOCIAL_PARTY_INVITE, "\u9080\u8acb\u76ee\u6a19\u7f3a\u5c11 UID\u3002")
		return
	var player_name: String = str(candidate.get("playerName", "")).strip_edges()
	_set_invite_party_dialog_busy(dialog_state, false, true)
	_set_invite_party_dialog_status(dialog_state, "\u6b63\u5728\u9080\u8acb %s..." % (player_name if player_name != "" else player_uid), OverlaySceneChrome.MUTED_TEXT_COLOR)
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
		return "\u672a\u77e5"
	var last_login_text: String = str(datetime_variant).strip_edges()
	if last_login_text == "":
		return "\u672a\u77e5"
	var unix_time: int = int(Time.get_unix_time_from_datetime_string(last_login_text))
	if unix_time <= 0:
		return last_login_text.replace("T", " ").substr(0, mini(last_login_text.length(), 19))
	var now_unix: int = int(Time.get_unix_time_from_system())
	var diff_seconds: int = maxi(0, now_unix - unix_time)
	if diff_seconds < 60:
		return "\u525b\u525b"
	if diff_seconds < 3600:
		return "%d \u5206\u9418\u524d" % maxi(1, diff_seconds / 60)
	if diff_seconds < 86400:
		return "%d \u5c0f\u6642\u524d" % maxi(1, diff_seconds / 3600)
	if diff_seconds < 604800:
		return "%d \u5929\u524d" % maxi(1, diff_seconds / 86400)
	return last_login_text.replace("T", " ").substr(0, mini(last_login_text.length(), 19))


func _format_last_login_text(last_login_variant: Variant) -> String:
	return _format_relative_datetime(last_login_variant)


func _format_friend_stage_text(stage_variant: Variant) -> String:
	var current_stage: int = max(1, int(stage_variant))
	var boss_cfg: Dictionary = GameState.boss_config if GameState.boss_config is Dictionary else {}
	if boss_cfg.is_empty():
		return "\u95dc\u5361 %d" % current_stage

	var stage_text: String = FriendStageFormatter.get_level_display(current_stage, boss_cfg).strip_edges()
	while stage_text.contains("  "):
		stage_text = stage_text.replace("  ", " ")
	return stage_text


func _format_party_invite_last_login(last_login_variant: Variant) -> String:
	return _format_relative_datetime(last_login_variant)


func _kick_party_member(user_id: int) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_KICK, UiText.SOCIAL_PARTY_KICK_SUCCESS)
	ApiClient.kick_party_member(int(_party_detail.get("partyId", 0)), user_id, callback)


func _confirm_kick_party_member(user_id: int, member_name: String) -> void:
	var target_label: String = member_name.strip_edges()
	if target_label == "":
		target_label = "\u9019\u4f4d\u968a\u54e1"
	DialogManager.show_confirm(
		UiText.SOCIAL_PARTY_KICK,
		"\u78ba\u5b9a\u8981\u8acb %s \u96e2\u968a\u4f0d\u55ce\uff1f" % target_label,
		func() -> void:
			_kick_party_member(user_id)
	)


func _cheer_party(is_ad_boost: bool) -> void:
	var title: String = UiText.SOCIAL_PARTY_AD_CHEER if is_ad_boost else UiText.SOCIAL_PARTY_FREE_CHEER
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, title, UiText.SOCIAL_PARTY_CHEER_SUCCESS)
	ApiClient.cheer_party(int(_party_detail.get("partyId", 0)), is_ad_boost, callback)


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
	var callback := func(success: bool, data: Variant, error: Dictionary) -> void:
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
	ApiClient.use_party_cheer_coupon(callback)


func _show_party_applications() -> void:
	_party_section = "reviews"
	_refresh_party_footer_buttons()
	_reload_current_party_section()


func _open_rename_party_dialog() -> void:
	_rename_party_dialog_state = _open_text_input(UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_NAME_PLACEHOLDER, Callable(self, "_submit_rename_party"), false)


func _submit_rename_party(value: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			_set_text_input_dialog_submitting(_rename_party_dialog_state, false)
			_after_party_action(false, error, UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_RENAME_SUCCESS)
			return
		var close_dialog_variant: Variant = _rename_party_dialog_state.get("close", Callable())
		if close_dialog_variant is Callable and (close_dialog_variant as Callable).is_valid():
			(close_dialog_variant as Callable).call()
		_rename_party_dialog_state = {}
		_after_party_action(success, error, UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_RENAME_SUCCESS)
	ApiClient.update_party_name(int(_party_detail.get("partyId", 0)), value, callback)


func _transfer_party(target_user_id: int) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_TRANSFER, UiText.SOCIAL_PARTY_TRANSFER_SUCCESS)
	ApiClient.transfer_party_leadership(int(_party_detail.get("partyId", 0)), target_user_id, callback)


func _confirm_transfer_party(target_user_id: int, member_name: String) -> void:
	var target_label: String = member_name.strip_edges()
	if target_label == "":
		target_label = "\u9019\u4f4d\u968a\u54e1"
	DialogManager.show_confirm(
		UiText.SOCIAL_PARTY_TRANSFER,
		"\u78ba\u8a8d\u5f8c\u4f60\u6703\u6539\u6210\u4e00\u822c\u968a\u54e1\uff0c\u662f\u5426\u78ba\u5b9a\u8f49\u8b93\u7d66 %s\uff1f" % target_label,
		func() -> void:
			_transfer_party(target_user_id)
	)



func _disband_party() -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_DISBAND, UiText.SOCIAL_PARTY_DISBAND_SUCCESS)
	ApiClient.disband_party(int(_party_detail.get("partyId", 0)), callback)


func _confirm_disband_party() -> void:
	DialogManager.show_confirm(
		UiText.SOCIAL_PARTY_DISBAND,
		"\u89e3\u6563\u5f8c\u968a\u4f0d\u8207\u6210\u54e1\u8cc7\u6599\u6703\u88ab\u6e05\u9664\uff0c\u662f\u5426\u78ba\u5b9a\u8981\u89e3\u6563\u968a\u4f0d\uff1f",
		func() -> void:
			_disband_party()
	)


func _on_party_exit_pressed() -> void:
	if bool(_party_detail.get("isUsurpationEligible", false)) and not _is_party_leader():
		_usurp_party()
		return
	_leave_party()


func _usurp_party() -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_USURP, UiText.SOCIAL_PARTY_USURP_SUCCESS)
	ApiClient.usurp_party_leadership(int(_party_detail.get("partyId", 0)), callback)


func _leave_party() -> void:
	var member_variants: Array = _party_detail.get("members", [])
	if member_variants.size() <= 1:
		_confirm_disband_party()
		return
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_LEAVE, UiText.SOCIAL_PARTY_LEAVE_SUCCESS)
	ApiClient.leave_party(int(_party_detail.get("partyId", 0)), callback)


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
		button.pressed.connect(func() -> void:
			_cheer_party(false)
		)
	elif not has_ad:
		button = _make_action_button("%s(1/1)" % UiText.SOCIAL_PARTY_AD_CHEER, "secondary")
		button.pressed.connect(func() -> void:
			_cheer_party(true)
		)
	else:
		button = _make_action_button("%s(0/1)" % UiText.SOCIAL_PARTY_AD_CHEER, "secondary")
		button.disabled = true
	button.custom_minimum_size = Vector2(220.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
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
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_PENDING_REVIEW, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_PARTY_PENDING_REVIEW, UiText.SOCIAL_PARTY_APPLICATION_ACCEPT_SUCCESS % applicant_name)
		_load_party_applications()
		_refresh_party()
	ApiClient.accept_party_application(application_id, callback)


func _confirm_reject_party_application(application_id: int, applicant_name: String) -> void:
	var target_label: String = applicant_name.strip_edges()
	if target_label == "":
		target_label = "\u9019\u4f4d\u73a9\u5bb6"
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REJECT,
		"\u78ba\u5b9a\u8981\u62d2\u7d55 %s \u7684\u7533\u8acb\u55ce\uff1f" % target_label,
		func() -> void:
			_reject_party_application(application_id)
	)


func _reject_party_application(application_id: int) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_PENDING_REVIEW, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_PARTY_PENDING_REVIEW, UiText.SOCIAL_PARTY_APPLICATION_REJECT_SUCCESS)
		_load_party_applications()
		_refresh_party()
	ApiClient.reject_party_application(application_id, callback)


func _accept_party_invite(application_id: int, party_name: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_PENDING_INVITES, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_PARTY_PENDING_INVITES, UiText.SOCIAL_PARTY_INVITE_ACCEPT_SUCCESS % party_name)
		_refresh_party()
	ApiClient.accept_party_invite(application_id, callback)


func _confirm_reject_party_invite(application_id: int, party_name: String) -> void:
	var target_label: String = party_name.strip_edges()
	if target_label == "":
		target_label = "\u9019\u500b\u968a\u4f0d"
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REJECT,
		"\u78ba\u5b9a\u8981\u62d2\u7d55 %s \u7684\u9080\u8acb\u55ce\uff1f" % target_label,
		func() -> void:
			_reject_party_invite(application_id, target_label)
	)


func _reject_party_invite(application_id: int, party_name: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_PENDING_INVITES, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_PARTY_PENDING_INVITES, UiText.SOCIAL_PARTY_INVITE_REJECT_SUCCESS % party_name)
		_refresh_party()
	ApiClient.reject_party_invite(application_id, callback)
