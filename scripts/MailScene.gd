extends Control

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")

const SELECTED_BUTTON_COLOR := Color(1.0, 0.94, 0.78, 1.0)
const UNSELECTED_BUTTON_COLOR := Color(0.92, 0.90, 0.86, 1.0)
const ERROR_COLOR := Color(1.0, 0.45, 0.45, 1.0)
const NORMAL_COLOR := Color(0.92, 0.92, 0.92, 1.0)

var _summary_label: Label
var _mail_button_list: VBoxContainer
var _mail_buttons: Dictionary = {}
var _detail_title: Label
var _detail_meta: Label
var _detail_content: RichTextLabel
var _attachment_box: VBoxContainer
var _claim_btn: Button
var _claim_all_btn: Button
var _status_label: Label
var _close_action: Callable = Callable()
var _api_in_flight: bool = false
var _selected_mail_id: int = 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(620.0, 900.0)
	_build_ui()
	_refresh_summary()
	_render_detail({})
	_load_mail_summary()
	_load_mail_list()


func set_close_action(action: Callable) -> void:
	_close_action = action


func _build_ui() -> void:
	add_child(AssetResolver.make_fullscreen_background("mail"))

	var root: MarginContainer = MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_right", 24)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	root.add_child(layout)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var back_btn: Button = Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(92.0, 48.0)
	back_btn.pressed.connect(func() -> void:
		if _close_action.is_valid():
			_close_action.call()
		else:
			SceneNavigator.return_to_battle()
	)
	header.add_child(back_btn)

	var title: Label = Label.new()
	title.text = "信箱"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	header.add_child(title)

	var body_row: HBoxContainer = HBoxContainer.new()
	body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_theme_constant_override("separation", 16)
	layout.add_child(body_row)

	var left_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	left_panel.custom_minimum_size = Vector2(240.0, 0.0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(left_panel)

	var left_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	left_panel.add_child(left_margin)

	var left_box: VBoxContainer = VBoxContainer.new()
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_theme_constant_override("separation", 12)
	left_margin.add_child(left_box)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	left_box.add_child(_summary_label)

	_claim_all_btn = Button.new()
	_claim_all_btn.text = "全部領取"
	_claim_all_btn.custom_minimum_size = Vector2(0.0, 48.0)
	UiPalette.apply_button_kind(_claim_all_btn, "confirm")
	_claim_all_btn.pressed.connect(_on_claim_all_pressed)
	left_box.add_child(_claim_all_btn)

	var list_scroll: ScrollContainer = ScrollContainer.new()
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_box.add_child(list_scroll)
	InertialScroller.attach(list_scroll, "vertical")

	_mail_button_list = VBoxContainer.new()
	_mail_button_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_button_list.add_theme_constant_override("separation", 8)
	list_scroll.add_child(_mail_button_list)

	var right_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(right_panel)

	var right_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	right_panel.add_child(right_margin)

	var right_box: VBoxContainer = VBoxContainer.new()
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_theme_constant_override("separation", 10)
	right_margin.add_child(right_box)

	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	right_box.add_child(_detail_title)

	_detail_meta = Label.new()
	_detail_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_meta.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_detail_meta.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	right_box.add_child(_detail_meta)

	var detail_scroll: ScrollContainer = ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_box.add_child(detail_scroll)
	InertialScroller.attach(detail_scroll, "vertical")

	var detail_layout: VBoxContainer = VBoxContainer.new()
	detail_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_layout.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(detail_layout)

	_detail_content = RichTextLabel.new()
	_detail_content.fit_content = true
	_detail_content.scroll_active = false
	_detail_content.bbcode_enabled = false
	_detail_content.custom_minimum_size = Vector2(0.0, 220.0)
	detail_layout.add_child(_detail_content)

	var attachment_title: Label = Label.new()
	attachment_title.text = "附件"
	attachment_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	detail_layout.add_child(attachment_title)

	_attachment_box = VBoxContainer.new()
	_attachment_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_box.add_theme_constant_override("separation", 8)
	detail_layout.add_child(_attachment_box)

	_claim_btn = Button.new()
	_claim_btn.text = "領取"
	_claim_btn.custom_minimum_size = Vector2(0.0, 50.0)
	UiPalette.apply_button_kind(_claim_btn, "confirm")
	_claim_btn.pressed.connect(_on_claim_pressed)
	right_box.add_child(_claim_btn)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status_label)


func _load_mail_list() -> void:
	_set_status("正在同步信箱...", false)
	ApiClient.get_mail_list(func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			_set_status(str(error.get("message", "讀取信箱失敗。")), true)
			return

		var payload: Dictionary = data if data is Dictionary else {}
		var items_variant: Variant = payload.get("items", [])
		var items: Array = items_variant if items_variant is Array else []
		GameState.update_mail_list(items)
		_refresh_summary()
		_rebuild_mail_buttons()
		_set_status("", false)

		var target_mail_id: int = _selected_mail_id
		if target_mail_id <= 0 and not GameState.mail_list_data.is_empty():
			target_mail_id = int((GameState.mail_list_data[0] as Dictionary).get("mailId", 0))
		if target_mail_id > 0:
			_select_mail(target_mail_id)
		else:
			GameState.update_selected_mail({})
			_selected_mail_id = 0
			_render_detail({})
	)


func _load_mail_summary() -> void:
	ApiClient.get_mail_summary(func(success: bool, data: Variant, _error: Dictionary) -> void:
		if success and data is Dictionary:
			GameState.update_mail_summary(data)
			_refresh_summary()
	)


func _rebuild_mail_buttons() -> void:
	for child: Node in _mail_button_list.get_children():
		child.queue_free()
	_mail_buttons.clear()

	for item_variant: Variant in GameState.mail_list_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var mail_id: int = int(item.get("mailId", 0))
		if mail_id <= 0:
			continue
		var button: Button = Button.new()
		button.text = _build_mail_button_text(item)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0.0, 60.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			_select_mail(mail_id)
		)
		_mail_button_list.add_child(button)
		_mail_buttons[mail_id] = button

	_refresh_mail_button_states()


func _build_mail_button_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	if not bool(item.get("isRead", false)):
		parts.append("●")
	if bool(item.get("hasAttachment", false)) and not bool(item.get("isClaimed", false)):
		parts.append("可領")
	parts.append(str(item.get("title", "未命名郵件")))
	if str(item.get("status", "")) == "Expired":
		parts.append("[已過期]")
	return " ".join(parts)


func _select_mail(mail_id: int) -> void:
	if mail_id <= 0:
		return
	_selected_mail_id = mail_id
	_refresh_mail_button_states()
	_load_mail_detail(mail_id)


func _refresh_mail_button_states() -> void:
	for mail_id_variant: Variant in _mail_buttons.keys():
		var mail_id: int = int(mail_id_variant)
		var button: Button = _mail_buttons.get(mail_id) as Button
		if button == null:
			continue
		button.modulate = SELECTED_BUTTON_COLOR if mail_id == _selected_mail_id else UNSELECTED_BUTTON_COLOR


func _load_mail_detail(mail_id: int) -> void:
	_set_status("正在讀取郵件內容...", false)
	ApiClient.get_mail_detail(mail_id, func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			_set_status(str(error.get("message", "讀取郵件內容失敗。")), true)
			return

		var detail: Dictionary = data if data is Dictionary else {}
		GameState.update_selected_mail(detail)
		_render_detail(detail)
		_set_status("", false)

		if not bool(detail.get("isRead", false)):
			GameState.mark_mail_read_local(mail_id)
			_refresh_summary()
			_rebuild_mail_buttons()
			ApiClient.mark_mail_read(mail_id, func(mark_success: bool, mark_data: Variant, _mark_error: Dictionary) -> void:
				if mark_success and mark_data is Dictionary:
					GameState.update_mail_summary(mark_data)
					_refresh_summary()
			)
	)


func _render_detail(detail: Dictionary) -> void:
	for child: Node in _attachment_box.get_children():
		child.queue_free()

	if detail.is_empty():
		_detail_title.text = "尚未選擇郵件"
		_detail_meta.text = ""
		_detail_content.text = ""
		_claim_btn.disabled = true
		_claim_btn.text = "領取"
		return

	_detail_title.text = str(detail.get("title", "未命名郵件"))
	_detail_meta.text = "類型：%s | 狀態：%s | 到期：%s" % [
		str(detail.get("mailType", "")),
		str(detail.get("status", "")),
		_format_expire_text(detail.get("expireAtUtc", null))
	]
	_detail_content.text = str(detail.get("content", ""))

	var attachments_variant: Variant = detail.get("attachments", [])
	var attachments: Array = attachments_variant if attachments_variant is Array else []
	for attachment_variant: Variant in attachments:
		if not (attachment_variant is Dictionary):
			continue
		_attachment_box.add_child(_build_attachment_row(attachment_variant))

	_claim_btn.disabled = _api_in_flight or not bool(detail.get("canClaim", false))
	_claim_btn.text = "已領取" if bool(detail.get("isClaimed", false)) else "領取"


func _build_attachment_row(attachment_variant: Variant) -> Control:
	var attachment: Dictionary = attachment_variant
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var texture: Texture2D = AssetResolver.load_texture(AssetResolver.resolve_catalog_path(attachment.get("imagePath", "")))
	if texture != null:
		row.add_child(AssetResolver.create_icon_rect(texture, Vector2(48.0, 48.0)))

	var body: Label = Label.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "%s %s x%d\n%s" % [
		"已領取" if bool(attachment.get("isClaimed", false)) else "可領取",
		str(attachment.get("displayName", attachment.get("rewardType", ""))),
		int(attachment.get("quantity", 0)),
		str(attachment.get("description", ""))
	]
	row.add_child(body)
	return row


func _format_expire_text(expire_variant: Variant) -> String:
	if expire_variant == null:
		return "無"
	var expire_text: String = str(expire_variant)
	if expire_text == "":
		return "無"
	return expire_text.substr(0, 19)


func _on_claim_pressed() -> void:
	if _api_in_flight:
		return
	var mail_id: int = int(GameState.selected_mail_data.get("mailId", 0))
	if mail_id <= 0:
		return

	_api_in_flight = true
	_refresh_action_buttons()
	ApiClient.claim_mail(mail_id, func(success: bool, data: Variant, error: Dictionary) -> void:
		_api_in_flight = false
		if not success:
			_refresh_action_buttons()
			_set_status(str(error.get("message", "領取失敗。")), true)
			return

		var payload: Dictionary = data if data is Dictionary else {}
		GameState.apply_wallet_snapshot(payload.get("walletSnapshot", {}))
		GameState.update_mail_summary(payload.get("mailSummary", {}))
		GameState.mark_mail_claimed_local(mail_id)
		_refresh_summary()
		_rebuild_mail_buttons()
		_render_detail(GameState.selected_mail_data)
		_refresh_action_buttons()
		_render_reward_dialog(payload.get("grantedRewards", []), "領取成功")
	)


func _on_claim_all_pressed() -> void:
	if _api_in_flight:
		return
	if int(GameState.mail_summary_data.get("claimableCount", 0)) <= 0:
		_set_status("目前沒有可領取的郵件。", true)
		return

	DialogManager.show_confirm("全部領取", "確定要領取目前所有可領取附件嗎？", func() -> void:
		_api_in_flight = true
		_refresh_action_buttons()
		ApiClient.claim_all_mails(func(success: bool, data: Variant, error: Dictionary) -> void:
			_api_in_flight = false
			if not success:
				_refresh_action_buttons()
				_set_status(str(error.get("message", "全部領取失敗。")), true)
				return

			var payload: Dictionary = data if data is Dictionary else {}
			GameState.apply_wallet_snapshot(payload.get("walletSnapshot", {}))
			GameState.update_mail_summary(payload.get("mailSummary", {}))
			GameState.mark_mail_claimed_many_local(payload.get("claimedMailIds", []))
			_refresh_summary()
			_rebuild_mail_buttons()
			_render_detail(GameState.selected_mail_data)
			_refresh_action_buttons()
			_render_reward_dialog(payload.get("grantedRewards", []), "全部領取完成")
		)
	)


func _render_reward_dialog(rewards: Variant, title: String) -> void:
	var lines: Array[String] = []
	if rewards is Array:
		for reward_variant: Variant in rewards:
			if not (reward_variant is Dictionary):
				continue
			var reward: Dictionary = reward_variant
			lines.append("%s x%d" % [
				str(reward.get("displayName", reward.get("rewardType", ""))),
				int(reward.get("quantity", 0))
			])
	if lines.is_empty():
		lines.append("沒有可顯示的獎勵。")
	DialogManager.show_info(title, "\n".join(lines), Callable(), "large")


func _refresh_summary() -> void:
	_summary_label.text = "未讀 %d\n可領 %d\n總數 %d" % [
		int(GameState.mail_summary_data.get("unreadCount", 0)),
		int(GameState.mail_summary_data.get("claimableCount", 0)),
		int(GameState.mail_summary_data.get("totalCount", 0))
	]
	_refresh_action_buttons()


func _set_status(message: String, is_error: bool) -> void:
	_status_label.text = message
	_status_label.modulate = ERROR_COLOR if is_error else NORMAL_COLOR


func _refresh_action_buttons() -> void:
	if _claim_all_btn != null:
		_claim_all_btn.disabled = _api_in_flight or int(GameState.mail_summary_data.get("claimableCount", 0)) <= 0
	if _claim_btn != null:
		var can_claim: bool = bool(GameState.selected_mail_data.get("canClaim", false))
		_claim_btn.disabled = _api_in_flight or not can_claim
