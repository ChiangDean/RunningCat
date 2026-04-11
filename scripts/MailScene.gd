extends Control

const BATTLE_SCENE_PATH := "res://scenes/BattleScene.tscn"

var _summary_label: Label
var _mail_list: ItemList
var _detail_title: Label
var _detail_meta: Label
var _detail_content: RichTextLabel
var _attachment_box: VBoxContainer
var _claim_btn: Button
var _claim_all_btn: Button
var _status_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_summary()
	_populate_mail_list()
	if _mail_list.item_count > 0:
		_mail_list.select(0)
		_on_mail_selected(0)
	else:
		_render_detail({})


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.11, 0.12, 0.15, 1.0)
	add_child(bg)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_right", 24)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	root.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(92, 48)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
	)
	header.add_child(back_btn)

	var title := Label.new()
	title.text = "郵件"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	header.add_child(title)

	_claim_all_btn = Button.new()
	_claim_all_btn.text = "全部領取"
	_claim_all_btn.custom_minimum_size = Vector2(140, 48)
	_claim_all_btn.pressed.connect(_on_claim_all_pressed)
	header.add_child(_claim_all_btn)

	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_summary_label)

	var split := VSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(split)

	_mail_list = ItemList.new()
	_mail_list.custom_minimum_size = Vector2(0, 360)
	_mail_list.item_selected.connect(_on_mail_selected)
	split.add_child(_mail_list)

	var detail_panel := PanelContainer.new()
	split.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 16)
	detail_margin.add_theme_constant_override("margin_top", 16)
	detail_margin.add_theme_constant_override("margin_right", 16)
	detail_margin.add_theme_constant_override("margin_bottom", 16)
	detail_panel.add_child(detail_margin)

	var detail_layout := VBoxContainer.new()
	detail_layout.add_theme_constant_override("separation", 10)
	detail_margin.add_child(detail_layout)

	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 24)
	detail_layout.add_child(_detail_title)

	_detail_meta = Label.new()
	_detail_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_layout.add_child(_detail_meta)

	_detail_content = RichTextLabel.new()
	_detail_content.fit_content = true
	_detail_content.scroll_active = true
	_detail_content.custom_minimum_size = Vector2(0, 180)
	detail_layout.add_child(_detail_content)

	var attachment_title := Label.new()
	attachment_title.text = "附件"
	attachment_title.add_theme_font_size_override("font_size", 20)
	detail_layout.add_child(attachment_title)

	var attachment_scroll := ScrollContainer.new()
	attachment_scroll.custom_minimum_size = Vector2(0, 180)
	attachment_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attachment_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_layout.add_child(attachment_scroll)

	_attachment_box = VBoxContainer.new()
	_attachment_box.add_theme_constant_override("separation", 8)
	_attachment_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_box.custom_minimum_size = Vector2(360, 0)
	attachment_scroll.add_child(_attachment_box)

	_claim_btn = Button.new()
	_claim_btn.text = "領取"
	_claim_btn.custom_minimum_size = Vector2(0, 50)
	_claim_btn.pressed.connect(_on_claim_pressed)
	detail_layout.add_child(_claim_btn)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status_label)


func _load_mail_list(select_first: bool = true) -> void:
	_set_status("正在同步郵件...", false)
	ApiClient.get_mail_list(func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			_set_status(error.get("message", "讀取郵件失敗。"), true)
			return
		var payload: Dictionary = data if data is Dictionary else {}
		var items_variant: Variant = payload.get("items", [])
		var items: Array = items_variant if items_variant is Array else []
		GameState.update_mail_list(items)
		_refresh_summary()
		_populate_mail_list()
		_set_status("", false)
		if select_first and _mail_list.item_count > 0:
			_mail_list.select(0)
			_on_mail_selected(0)
		elif _mail_list.item_count == 0:
			GameState.update_selected_mail({})
			_render_detail({})
	)


func _populate_mail_list() -> void:
	_mail_list.clear()
	for item_variant: Variant in GameState.mail_list_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var title := str(item.get("title", "未命名郵件"))
		var label := title
		if not bool(item.get("isClaimed", false)) and bool(item.get("hasAttachment", false)):
			label = "獎 " + label
		if not bool(item.get("isRead", false)):
			label = "● " + label
		if str(item.get("status", "")) == "Expired":
			label += " [已過期]"
		_mail_list.add_item(label)


func _on_mail_selected(index: int) -> void:
	if index < 0 or index >= GameState.mail_list_data.size():
		return
	var detail_variant: Variant = GameState.mail_list_data[index]
	if not (detail_variant is Dictionary):
		return
	var detail: Dictionary = detail_variant
	var mail_id := int(detail.get("mailId", 0))
	if mail_id <= 0:
		return

	GameState.update_selected_mail(detail)
	_render_detail(detail)
	_set_status("", false)

	if not bool(detail.get("isRead", false)):
		GameState.mark_mail_read_local(mail_id)
		_refresh_summary()
		ApiClient.mark_mail_read(mail_id, func(mark_success: bool, mark_data: Variant, _mark_error: Dictionary) -> void:
			if mark_success and mark_data is Dictionary:
				GameState.update_mail_summary(mark_data)
				_refresh_summary()
		)


func _render_detail(detail: Dictionary) -> void:
	for child in _attachment_box.get_children():
		child.queue_free()

	if detail.is_empty():
		_detail_title.text = "尚未選擇郵件"
		_detail_meta.text = ""
		_detail_content.text = ""
		_claim_btn.disabled = true
		_claim_btn.text = "領取"
		return

	_detail_title.text = str(detail.get("title", "未命名郵件"))
	var expire_text := "無"
	var expire_variant: Variant = detail.get("expireAtUtc", null)
	if expire_variant != null:
		expire_text = str(expire_variant).substr(0, 19)
	_detail_meta.text = "類型：%s | 狀態：%s | 到期：%s" % [
		str(detail.get("mailType", "")),
		str(detail.get("status", "")),
		expire_text
	]
	_detail_content.text = str(detail.get("content", ""))

	var attachments_variant: Variant = detail.get("attachments", [])
	var attachments: Array = attachments_variant if attachments_variant is Array else []
	for attachment_variant: Variant in attachments:
		if not (attachment_variant is Dictionary):
			continue
		var attachment: Dictionary = attachment_variant
		var row := Label.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(340, 0)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var prefix := "已領取" if bool(attachment.get("isClaimed", false)) else "可領取"
		row.text = "%s %s x%d\n%s" % [
			prefix,
			str(attachment.get("displayName", attachment.get("rewardType", ""))),
			int(attachment.get("quantity", 0)),
			str(attachment.get("description", ""))
		]
		_attachment_box.add_child(row)

	_claim_btn.disabled = not bool(detail.get("canClaim", false))
	_claim_btn.text = "已領取" if bool(detail.get("isClaimed", false)) else "領取"


func _on_claim_pressed() -> void:
	var mail_id := int(GameState.selected_mail_data.get("mailId", 0))
	if mail_id <= 0:
		return
	_claim_btn.disabled = true
	ApiClient.claim_mail(mail_id, func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			_claim_btn.disabled = false
			_set_status(error.get("message", "領取失敗。"), true)
			return
		var payload: Dictionary = data if data is Dictionary else {}
		GameState.apply_wallet_snapshot(payload.get("walletSnapshot", {}))
		GameState.update_mail_summary(payload.get("mailSummary", {}))
		GameState.mark_mail_claimed_local(mail_id)
		_refresh_summary()
		_render_detail(GameState.selected_mail_data)
		_populate_mail_list()
		_render_reward_dialog(payload.get("grantedRewards", []), "領取成功")
	)


func _on_claim_all_pressed() -> void:
	if int(GameState.mail_summary_data.get("claimableCount", 0)) <= 0:
		_set_status("目前沒有可領取的郵件。", true)
		return
	DialogManager.show_confirm("全部領取", "確定要領取目前所有可領取附件嗎？", func() -> void:
		_claim_all_btn.disabled = true
		ApiClient.claim_all_mails(func(success: bool, data: Variant, error: Dictionary) -> void:
			_claim_all_btn.disabled = false
			if not success:
				_set_status(error.get("message", "全部領取失敗。"), true)
				return
			var payload: Dictionary = data if data is Dictionary else {}
			GameState.apply_wallet_snapshot(payload.get("walletSnapshot", {}))
			GameState.update_mail_summary(payload.get("mailSummary", {}))
			GameState.mark_mail_claimed_many_local(payload.get("claimedMailIds", []))
			_refresh_summary()
			_render_detail(GameState.selected_mail_data)
			_populate_mail_list()
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
	DialogManager.show_info(title, "\n".join(lines))


func _refresh_summary() -> void:
	_summary_label.text = "未讀 %d | 可領 %d | 總數 %d" % [
		int(GameState.mail_summary_data.get("unreadCount", 0)),
		int(GameState.mail_summary_data.get("claimableCount", 0)),
		int(GameState.mail_summary_data.get("totalCount", 0))
	]
	_claim_all_btn.disabled = int(GameState.mail_summary_data.get("claimableCount", 0)) <= 0


func _set_status(message: String, is_error: bool) -> void:
	_status_label.text = message
	_status_label.modulate = Color(1.0, 0.45, 0.45, 1.0) if is_error else Color(0.9, 0.9, 0.9, 1.0)
