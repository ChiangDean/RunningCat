extends Control

const ContentBottomSubmenu = preload("res://scripts/ui/content_bottom_submenu.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")

var _mode: String = "friend"
var _friend_list: Dictionary = {}
var _friend_gift_in_flight: bool = false
var _party_detail: Dictionary = {}
var _party_cheer_status: Dictionary = {}
var _party_section: String = "overview"
var _party_applications: Array = []

var _root_box: VBoxContainer
var _scroll: ScrollContainer
var _content_box: VBoxContainer
var _footer_panel: PanelContainer
var _party_footer_buttons: Dictionary = {}


func set_mode(mode: String) -> void:
	_mode = mode


func _ready() -> void:
	custom_minimum_size = Vector2(660.0, 960.0)
	_build_shell()
	_refresh_current()


func _build_shell() -> void:
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


func _refresh_current() -> void:
	if _mode == "party":
		_refresh_party()
		return
	_refresh_friend()


func _refresh_friend() -> void:
	var callback := func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.HOME_FRIEND, _error_message(error))
			return
		_friend_list = data if data is Dictionary else {}
		_render_friend()
	ApiClient.get_friends(callback)


func _refresh_party() -> void:
	var cheer_callback := func(success: bool, data: Variant, _error: Dictionary) -> void:
		_party_cheer_status = data if success and data is Dictionary else {}
		_render_party()

	var party_callback := func(success: bool, data: Variant, error: Dictionary) -> void:
		if success:
			_party_detail = data if data is Dictionary else {}
			ApiClient.get_party_cheer_status(int(_party_detail.get("partyId", 0)), cheer_callback)
			return
		if str(error.get("code", "")) == "PARTY.NOT_IN_PARTY":
			_party_detail = {}
			_party_cheer_status = {}
			_render_party()
			return
		ToastManager.error(UiText.HOME_PARTY, _error_message(error))

	ApiClient.get_my_party(party_callback)


func _clear_content() -> void:
	for child: Node in _content_box.get_children():
		child.queue_free()


func _render_friend() -> void:
	_clear_content()
	if _footer_panel != null:
		_footer_panel.visible = false

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

	var add_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ADD, "add")
	add_button.pressed.connect(_open_add_friend_dialog)
	button_row.add_child(add_button)

	var gift_button: Button = _make_action_button(
		UiText.SOCIAL_FRIEND_GIFT_SENT if bool(_friend_list.get("hasSentGiftToday", false)) else UiText.SOCIAL_FRIEND_GIFT_ALL,
		"confirm"
	)
	gift_button.disabled = bool(_friend_list.get("hasSentGiftToday", false))
	gift_button.pressed.connect(_on_friend_gift_pressed)
	button_row.add_child(gift_button)

	var refresh_button: Button = _make_action_button(UiText.SOCIAL_REFRESH, "secondary")
	refresh_button.pressed.connect(_refresh_friend)
	button_row.add_child(refresh_button)

	if friend_rows.is_empty():
		var empty_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
		empty_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_panel.custom_minimum_size = Vector2(0.0, 220.0)
		friends_box.add_child(empty_panel)

		var empty_center: CenterContainer = CenterContainer.new()
		empty_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_panel.add_child(empty_center)
		empty_center.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in friend_rows:
		if not (item_variant is Dictionary):
			continue
		friends_box.add_child(_build_friend_row(item_variant))


func _render_party() -> void:
	_clear_content()
	if _party_detail.is_empty():
		if _footer_panel != null:
			_footer_panel.visible = false
		_render_party_empty()
		return
	_render_party_footer()
	if _party_section == "applications" and _is_party_leader():
		_render_party_applications(_content_box)
		return
	_party_section = "overview"
	_render_party_detail(_content_box)



func _render_party_footer() -> void:
	if _footer_panel == null:
		return
	_footer_panel.visible = true
	var items: Array = [
		{"key": "overview", "label": "\u968a\u4f0d\u8cc7\u8a0a"},
	]
	if _is_party_leader():
		items.append({"key": "applications", "label": UiText.SOCIAL_PARTY_APPLICATIONS})
	var submenu: Dictionary = ContentBottomSubmenu.build(self, {
		"panel": _footer_panel,
		"items": items,
		"active_key": _party_section,
		"button_pressed": Callable(self, "_on_party_section_selected"),
	})
	_party_footer_buttons = submenu.get("buttons", {})




func _on_party_section_selected(section_key: String) -> void:
	if _party_section == section_key:
		return
	_party_section = section_key
	_refresh_party_footer_buttons()
	if _party_section == "applications" and _is_party_leader():
		_load_party_applications()
		return
	_render_party()


func _refresh_party_footer_buttons() -> void:
	ContentBottomSubmenu.refresh(_party_footer_buttons, _party_section)


func _load_party_applications() -> void:
	ApiClient.get_party_applications(int(_party_detail.get("partyId", 0)), func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_APPLICATIONS, _error_message(error))
			return
		_party_applications = data if data is Array else []
		_render_party()
	)


func _render_party_empty() -> void:
	var summary_card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	summary_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_child(summary_card)

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

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	_content_box.add_child(action_row)

	action_row.add_child(_build_party_entry_card(
		UiText.SOCIAL_PARTY_CREATE,
		UiText.SOCIAL_PARTY_CREATE_DESC,
		UiText.SOCIAL_PARTY_CREATE,
		"confirm",
		Callable(self, "_open_create_party_dialog")
	))
	action_row.add_child(_build_party_entry_card(
		UiText.SOCIAL_PARTY_APPLY,
		UiText.SOCIAL_PARTY_APPLY_DESC,
		UiText.SOCIAL_PARTY_APPLY,
		"secondary",
		Callable(self, "_open_apply_party_dialog")
	))
	action_row.add_child(_build_party_entry_card(
		UiText.SOCIAL_PARTY_MY_APPLICATIONS,
		UiText.SOCIAL_PARTY_MY_APPLICATIONS_DESC,
		UiText.SOCIAL_PARTY_MY_APPLICATIONS,
		"info",
		Callable(self, "_show_my_party_applications")
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

	var refresh_button: Button = _make_action_button(UiText.SOCIAL_REFRESH, "secondary")
	refresh_button.pressed.connect(_refresh_party)
	quick_row.add_child(refresh_button)

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


func _render_party_applications(host: VBoxContainer) -> void:
	var card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(card)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	card.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = UiText.SOCIAL_PARTY_APPLICATIONS
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	if _party_applications.is_empty():
		box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in _party_applications:
		if item_variant is Dictionary:
			box.add_child(_build_party_application_row(item_variant))


func _build_party_application_row(item_variant: Variant) -> Control:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var info: Label = Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = str(item.get("applicantDisplayName", ""))
	row.add_child(info)

	var accept_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_ACCEPT, "confirm")
	accept_button.custom_minimum_size = Vector2(96.0, 46.0)
	accept_button.pressed.connect(func() -> void:
		_accept_party_application(int(item.get("applicationId", 0)), str(item.get("applicantDisplayName", "")))
	)
	row.add_child(accept_button)

	var reject_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REJECT, "danger")
	reject_button.custom_minimum_size = Vector2(96.0, 46.0)
	reject_button.pressed.connect(func() -> void:
		_reject_party_application(int(item.get("applicationId", 0)))
	)
	row.add_child(reject_button)

	return panel


func _build_friend_row(item_variant: Variant) -> PanelContainer:
	var item: Dictionary = item_variant
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var name_label: Label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = str(item.get("displayName", ""))
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	box.add_child(name_label)

	var showcase_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_SHOWCASE, "info")
	showcase_button.pressed.connect(_open_showcase_dialog)
	box.add_child(showcase_button)

	var remove_button: Button = _make_action_button(UiText.SOCIAL_FRIEND_REMOVE, "danger")
	remove_button.pressed.connect(func() -> void:
		_confirm_remove_friend(int(item.get("friendUserId", 0)), str(item.get("displayName", "")))
	)
	box.add_child(remove_button)

	return panel


func _build_party_entry_card(
	title_text: String,
	desc_text: String,
	button_text: String,
	button_kind: String,
	pressed: Callable
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

	var button: Button = _make_action_button(button_text, button_kind)
	button.pressed.connect(pressed)
	box.add_child(button)

	return card


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
			_kick_party_member(int(member.get("userId", 0)))
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
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	return label


func _on_friend_gift_pressed() -> void:
	if _friend_gift_in_flight:
		return
	var friend_rows: Array = _friend_list.get("friends", [])
	if friend_rows.is_empty():
		ToastManager.hint(UiText.SOCIAL_FRIEND_GIFT_ALL, UiText.SOCIAL_EMPTY)
		return
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_GIFT_ALL,
		UiText.SOCIAL_FRIEND_GIFT_CONFIRM % friend_rows.size(),
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


func _confirm_remove_friend(friend_user_id: int, friend_name: String) -> void:
	var target_label: String = friend_name.strip_edges()
	if target_label == "":
		target_label = "\u9019\u4f4d\u597d\u53cb"
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_REMOVE,
		"\u4f60\u5c07\u79fb\u9664 %s\u3002" % target_label,
		func() -> void:
			DialogManager.show_confirm(
				UiText.SOCIAL_FRIEND_REMOVE,
				"\u78ba\u8a8d\u5f8c\u9700\u8981\u91cd\u65b0\u52a0\u597d\u53cb\uff0c\u662f\u5426\u78ba\u5b9a\u79fb\u9664 %s\uff1f" % target_label,
				func() -> void:
					_remove_friend(friend_user_id)
			)
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


func _open_text_input(title: String, placeholder: String, on_confirm: Callable) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var input: LineEdit = LineEdit.new()
	input.placeholder_text = placeholder
	box.add_child(input)

	var confirm_button: Button = _make_action_button(UiText.COMMON_CONFIRM, "confirm")
	confirm_button.pressed.connect(func() -> void:
		var value: String = input.text.strip_edges()
		if value == "":
			ToastManager.hint(title, UiText.SOCIAL_INPUT_EMPTY)
			return
		on_confirm.call(value)
	)
	box.add_child(confirm_button)

	DialogManager.show_info_node(title, box, Callable(), "medium")


func _open_add_friend_dialog() -> void:
	_open_text_input(UiText.SOCIAL_FRIEND_ADD, UiText.SOCIAL_FRIEND_UID_PLACEHOLDER, Callable(self, "_submit_add_friend"))


func _submit_add_friend(value: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_FRIEND_ADD, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_FRIEND_ADD, UiText.SOCIAL_FRIEND_ADD_SUCCESS)
		_refresh_friend()
	ApiClient.send_friend_request(value, callback)


func _open_create_party_dialog() -> void:
	_open_text_input(UiText.SOCIAL_PARTY_CREATE, UiText.SOCIAL_PARTY_NAME_PLACEHOLDER, Callable(self, "_submit_create_party"))


func _submit_create_party(value: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_CREATE, UiText.SOCIAL_PARTY_CREATE_SUCCESS % value)
	ApiClient.create_party(value, callback)


func _open_apply_party_dialog() -> void:
	_open_text_input(UiText.SOCIAL_PARTY_APPLY, UiText.SOCIAL_PARTY_SEARCH_PLACEHOLDER, Callable(self, "_submit_apply_party"))


func _submit_apply_party(value: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_APPLY, UiText.SOCIAL_PARTY_APPLY_SUCCESS)
	if value.is_valid_int():
		ApiClient.apply_to_party_by_id(int(value), callback)
	else:
		ApiClient.apply_to_party_by_name(value, callback)


func _show_my_party_applications() -> void:
	var callback := func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_MY_APPLICATIONS, _error_message(error))
			return
		var info: Label = Label.new()
		var lines: Array[String] = []
		for item_variant: Variant in data:
			if item_variant is Dictionary:
				lines.append(str((item_variant as Dictionary).get("partyName", "")))
		info.text = "\n".join(lines) if not lines.is_empty() else UiText.SOCIAL_EMPTY
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		DialogManager.show_info_node(UiText.SOCIAL_PARTY_MY_APPLICATIONS, info, Callable(), "medium")
	ApiClient.get_my_party_applications(callback)


func _open_invite_party_dialog() -> void:
	_open_text_input(UiText.SOCIAL_PARTY_INVITE, UiText.SOCIAL_FRIEND_UID_PLACEHOLDER, Callable(self, "_submit_invite_party"))


func _submit_invite_party(value: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_INVITE, UiText.SOCIAL_PARTY_INVITE_SUCCESS)
	ApiClient.invite_player_to_party(int(_party_detail.get("partyId", 0)), value, callback)


func _kick_party_member(user_id: int) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_KICK, UiText.SOCIAL_PARTY_KICK_SUCCESS)
	ApiClient.kick_party_member(int(_party_detail.get("partyId", 0)), user_id, callback)


func _cheer_party(is_ad_boost: bool) -> void:
	var title: String = UiText.SOCIAL_PARTY_AD_CHEER if is_ad_boost else UiText.SOCIAL_PARTY_FREE_CHEER
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if success:
			GameState.adjust_party_cheer_coupon_count(1)
		_after_party_action(success, error, title, UiText.SOCIAL_PARTY_CHEER_SUCCESS)
	ApiClient.cheer_party(int(_party_detail.get("partyId", 0)), is_ad_boost, callback)


func _use_party_coupon() -> void:
	var callback := func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_USE_COUPON, _error_message(error))
			return
		GameState.adjust_party_cheer_coupon_count(-1)
		var payload: Dictionary = data if data is Dictionary else {}
		ToastManager.success(UiText.SOCIAL_PARTY_USE_COUPON, UiText.SOCIAL_PARTY_USE_COUPON_SUCCESS % int(payload.get("goldGranted", 0)))
		_refresh_party()
	ApiClient.use_party_cheer_coupon(callback)


func _show_party_applications() -> void:
	_party_section = "applications"
	_load_party_applications()


func _open_rename_party_dialog() -> void:
	_open_text_input(UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_NAME_PLACEHOLDER, Callable(self, "_submit_rename_party"))


func _submit_rename_party(value: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
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
		"\u4f60\u5c07\u628a\u968a\u9577\u6b0a\u9650\u4ea4\u7d66 %s\u3002" % target_label,
		func() -> void:
			DialogManager.show_confirm(
				UiText.SOCIAL_PARTY_TRANSFER,
				"\u78ba\u8a8d\u5f8c\u4f60\u6703\u6539\u6210\u4e00\u822c\u968a\u54e1\uff0c\u662f\u5426\u78ba\u5b9a\u8f49\u8b93\u7d66 %s\uff1f" % target_label,
				func() -> void:
					_transfer_party(target_user_id)
			)
	)



func _disband_party() -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_DISBAND, UiText.SOCIAL_PARTY_DISBAND_SUCCESS)
	ApiClient.disband_party(int(_party_detail.get("partyId", 0)), callback)


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
		_disband_party()
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
			ToastManager.error(UiText.SOCIAL_PARTY_APPLICATIONS, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_PARTY_APPLICATIONS, UiText.SOCIAL_PARTY_APPLICATION_ACCEPT_SUCCESS % applicant_name)
		_load_party_applications()
		_refresh_party()
	ApiClient.accept_party_application(application_id, callback)


func _reject_party_application(application_id: int) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_APPLICATIONS, _error_message(error))
			return
		ToastManager.success(UiText.SOCIAL_PARTY_APPLICATIONS, UiText.SOCIAL_PARTY_APPLICATION_REJECT_SUCCESS)
		_load_party_applications()
	ApiClient.reject_party_application(application_id, callback)
