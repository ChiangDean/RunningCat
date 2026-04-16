extends Control

const CHAT_SCENE := preload("res://scenes/chat/ChatScene.tscn")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")

var _mode: String = "friend"
var _friend_list: Dictionary = {}
var _party_detail: Dictionary = {}
var _party_cheer_status: Dictionary = {}

var _root_box: VBoxContainer
var _scroll: ScrollContainer
var _content_box: VBoxContainer


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
	_root_box.add_theme_constant_override("separation", 14)
	margin.add_child(_root_box)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_root_box.add_child(header)

	var title: Label = Label.new()
	title.text = UiText.HOME_FRIEND_DIALOG_TITLE if _mode == "friend" else UiText.HOME_PARTY_DIALOG_TITLE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	header.add_child(title)

	var refresh_button: Button = Button.new()
	refresh_button.text = UiText.SOCIAL_REFRESH
	refresh_button.custom_minimum_size = Vector2(120.0, 44.0)
	UiPalette.apply_button_kind(refresh_button, "secondary")
	refresh_button.pressed.connect(_refresh_current)
	header.add_child(refresh_button)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root_box.add_child(_scroll)

	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 14)
	_scroll.add_child(_content_box)


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

	var friend_rows: Array = _friend_list.get("friends", [])
	var friends_card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	friends_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_child(friends_card)

	var friends_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	friends_card.add_child(friends_margin)

	var friends_box: VBoxContainer = VBoxContainer.new()
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

	if friend_rows.is_empty():
		friends_box.add_child(_make_empty_label(UiText.SOCIAL_EMPTY))
		return

	for item_variant: Variant in friend_rows:
		if not (item_variant is Dictionary):
			continue
		friends_box.add_child(_build_friend_row(item_variant))


func _render_party() -> void:
	_clear_content()
	if _party_detail.is_empty():
		_render_party_empty()
		return
	_render_party_detail()


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


func _render_party_detail() -> void:
	var header_card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	header_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_child(header_card)

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

	var free_button: Button = _make_action_button(_get_free_cheer_button_text(), "confirm")
	free_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	free_button.custom_minimum_size = Vector2(220.0, 52.0)
	free_button.disabled = bool(_party_cheer_status.get("hasCheeredFree", false))
	free_button.pressed.connect(func() -> void:
		_cheer_party(false)
	)
	title_row.add_child(free_button)

	var subline: Label = Label.new()
	subline.text = UiText.SOCIAL_PARTY_LEADER_FORMAT % str(_party_detail.get("leaderDisplayName", ""))
	subline.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	subline.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	header_box.add_child(subline)

	var quick_row: HBoxContainer = HBoxContainer.new()
	quick_row.add_theme_constant_override("separation", 10)
	header_box.add_child(quick_row)

	var chat_button: Button = _make_action_button(UiText.SOCIAL_PARTY_CHAT, "info")
	chat_button.pressed.connect(_open_party_chat)
	quick_row.add_child(chat_button)

	var invite_button: Button = _make_action_button(UiText.SOCIAL_PARTY_INVITE, "add")
	invite_button.pressed.connect(_open_invite_party_dialog)
	quick_row.add_child(invite_button)

	var leave_button: Button = _make_action_button(
		UiText.SOCIAL_PARTY_USURP if bool(_party_detail.get("isUsurpationEligible", false)) and not _is_party_leader() else UiText.SOCIAL_PARTY_LEAVE,
		"danger"
	)
	leave_button.pressed.connect(_on_party_exit_pressed)
	quick_row.add_child(leave_button)

	var member_card: PanelContainer = OverlaySceneChrome.make_card_panel()
	member_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_child(member_card)

	var member_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	member_card.add_child(member_margin)

	var member_box: VBoxContainer = VBoxContainer.new()
	member_box.add_theme_constant_override("separation", 10)
	member_margin.add_child(member_box)

	var member_title: Label = Label.new()
	member_title.text = UiText.SOCIAL_PARTY_MEMBER_LIST
	member_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	member_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	member_box.add_child(member_title)

	for member_variant: Variant in members:
		if member_variant is Dictionary:
			member_box.add_child(_build_party_member_row(member_variant))

	var action_card: PanelContainer = OverlaySceneChrome.make_card_panel()
	action_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_child(action_card)

	var action_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	action_card.add_child(action_margin)

	var action_box: VBoxContainer = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 12)
	action_margin.add_child(action_box)

	var action_title: Label = Label.new()
	action_title.text = UiText.SOCIAL_PARTY_CHEER_TITLE
	action_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	action_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	action_box.add_child(action_title)

	var cheer_grid: GridContainer = GridContainer.new()
	cheer_grid.columns = 1
	cheer_grid.add_theme_constant_override("h_separation", 10)
	cheer_grid.add_theme_constant_override("v_separation", 10)
	action_box.add_child(cheer_grid)

	var ad_button: Button = _make_action_button(
		UiText.SOCIAL_PARTY_AD_CHEER_DONE if bool(_party_cheer_status.get("hasCheeredAd", false)) else UiText.SOCIAL_PARTY_AD_CHEER,
		"secondary"
	)
	ad_button.disabled = bool(_party_cheer_status.get("hasCheeredAd", false))
	ad_button.pressed.connect(func() -> void:
		_cheer_party(true)
	)
	cheer_grid.add_child(ad_button)

	if _is_party_leader():
		var manage_card: PanelContainer = OverlaySceneChrome.make_card_panel()
		manage_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_content_box.add_child(manage_card)

		var manage_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
		manage_card.add_child(manage_margin)

		var manage_box: VBoxContainer = VBoxContainer.new()
		manage_box.add_theme_constant_override("separation", 12)
		manage_margin.add_child(manage_box)

		var manage_title: Label = Label.new()
		manage_title.text = UiText.SOCIAL_PARTY_MANAGE
		manage_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
		manage_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
		manage_box.add_child(manage_title)

		var manage_grid: GridContainer = GridContainer.new()
		manage_grid.columns = 2
		manage_grid.add_theme_constant_override("h_separation", 10)
		manage_grid.add_theme_constant_override("v_separation", 10)
		manage_box.add_child(manage_grid)

		var applications_button: Button = _make_action_button(UiText.SOCIAL_PARTY_APPLICATIONS, "info")
		applications_button.pressed.connect(_show_party_applications)
		manage_grid.add_child(applications_button)

		var rename_button: Button = _make_action_button(UiText.SOCIAL_PARTY_RENAME, "secondary")
		rename_button.pressed.connect(_open_rename_party_dialog)
		manage_grid.add_child(rename_button)

		var transfer_button: Button = _make_action_button(UiText.SOCIAL_PARTY_TRANSFER, "rank")
		transfer_button.pressed.connect(_transfer_party)
		manage_grid.add_child(transfer_button)

		var disband_button: Button = _make_action_button(UiText.SOCIAL_PARTY_DISBAND, "danger")
		disband_button.pressed.connect(_disband_party)
		manage_grid.add_child(disband_button)


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
		_remove_friend(int(item.get("friendUserId", 0)))
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
		var kick_button: Button = _make_action_button(UiText.SOCIAL_PARTY_KICK, "danger")
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
	var friend_rows: Array = _friend_list.get("friends", [])
	DialogManager.show_confirm(
		UiText.SOCIAL_FRIEND_GIFT_ALL,
		UiText.SOCIAL_FRIEND_GIFT_CONFIRM % friend_rows.size(),
		Callable(self, "_confirm_friend_gift")
	)


func _confirm_friend_gift() -> void:
	var callback := func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_FRIEND_GIFT_ALL, _error_message(error))
			return
		var payload: Dictionary = data if data is Dictionary else {}
		ToastManager.success(UiText.SOCIAL_FRIEND_GIFT_ALL, UiText.SOCIAL_FRIEND_GIFT_SUCCESS % int(payload.get("recipientCount", 0)))
		_refresh_friend()
	ApiClient.send_friend_gifts(callback)


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


func _open_party_chat() -> void:
	var chat_view: Control = CHAT_SCENE.instantiate()
	chat_view.set_initial_channel("party")
	DialogManager.show_info_node(UiText.SOCIAL_PARTY_CHAT, chat_view, Callable(), "large")


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
	var callback := func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SOCIAL_PARTY_APPLICATIONS, _error_message(error))
			return
		var info: Label = Label.new()
		var lines: Array[String] = []
		for item_variant: Variant in data:
			if item_variant is Dictionary:
				lines.append(str((item_variant as Dictionary).get("applicantDisplayName", "")))
		info.text = "\n".join(lines) if not lines.is_empty() else UiText.SOCIAL_EMPTY
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		DialogManager.show_info_node(UiText.SOCIAL_PARTY_APPLICATIONS, info, Callable(), "medium")
	ApiClient.get_party_applications(int(_party_detail.get("partyId", 0)), callback)


func _open_rename_party_dialog() -> void:
	_open_text_input(UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_NAME_PLACEHOLDER, Callable(self, "_submit_rename_party"))


func _submit_rename_party(value: String) -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_RENAME, UiText.SOCIAL_PARTY_RENAME_SUCCESS)
	ApiClient.update_party_name(int(_party_detail.get("partyId", 0)), value, callback)


func _transfer_party() -> void:
	var callback := func(success: bool, _data: Variant, error: Dictionary) -> void:
		_after_party_action(success, error, UiText.SOCIAL_PARTY_TRANSFER, UiText.SOCIAL_PARTY_TRANSFER_SUCCESS)
	ApiClient.transfer_party_leadership(int(_party_detail.get("partyId", 0)), callback)


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
