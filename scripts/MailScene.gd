class_name MailSceneController
extends Control

signal navigation_changed(items: Array, active_key: String)

const ITEM_SLOT_TEMPLATE = preload("res://scenes/ui/backpack/ItemSlotTemplate.tscn")

const SECTION_UNREAD := "unread"
const SECTION_READ := "read"


const LIST_ITEM_FILL := Color(0.17, 0.16, 0.19, 0.96)
const LIST_ITEM_FILL_SELECTED := Color(0.24, 0.21, 0.16, 0.98)
const LIST_ITEM_BORDER := Color(0.40, 0.35, 0.28, 0.90)
const LIST_ITEM_BORDER_SELECTED := Color(0.83, 0.69, 0.43, 0.98)
const MAIL_CONTAINER_FILL := Color(0.16, 0.15, 0.18, 0.25)
const MAIL_PAGE_SIDE_MARGIN := 10
const ATTACHMENT_SLOT_BASE_SIZE := Vector2(512.0, 512.0)
const ATTACHMENT_SLOT_SCALE := 0.27
const ATTACHMENT_SLOT_CELL_SIZE := Vector2(148.0, 148.0)

var _active_section: String = SECTION_UNREAD
var _mail_list_scroll: ScrollContainer
var _mail_empty_state: CenterContainer
var _empty_mail_label: Label
var _mail_button_list: VBoxContainer
var _mail_buttons: Dictionary = {}
var _detail_title: Label
var _detail_meta_row: HBoxContainer
var _detail_empty_state: CenterContainer
var _detail_content_scroll: ScrollContainer
var _detail_content: Label
var _expire_label: Label
var _attachment_title: Label
var _attachment_section: VBoxContainer
var _attachment_box: HFlowContainer
var _claim_btn: Button
var _claim_all_btn: Button
var _delete_read_btn: Button
var _empty_detail_label: Label
var _api_in_flight: bool = false
var _selected_mail_id: int = 0
var _mail_state_refresh_in_progress: bool = false
var _mail_cache_recovery_in_flight: bool = false
var _mail_detail_recovery_ids: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_render_detail({})
	_refresh_action_buttons()
	GameState.mail_state_changed.connect(_on_mail_state_changed)
	GameState.red_dot_state_changed.connect(_refresh_action_buttons)
	_apply_mail_cache()
	_emit_navigation_changed()


func set_overlay_mode(_enabled: bool) -> void:
	pass


func get_footer_items() -> Array:
	return [
		{
			"key": SECTION_UNREAD,
			"label": UiText.MAIL_UNREAD,
			"shell_description": UiText.MAIL_UNREAD_SECTION_DESC,
			"shell_summary_right": Callable(self, "_build_footer_summary_right").bind(SECTION_UNREAD),
		},
		{
			"key": SECTION_READ,
			"label": UiText.MAIL_READ,
			"shell_description": UiText.MAIL_READ_SECTION_DESC,
			"shell_summary_right": Callable(self, "_build_footer_summary_right").bind(SECTION_READ),
		},
	]


func get_section() -> String:
	return _active_section


func _build_footer_summary_right(section_key: String) -> String:
	var unread_count: int = int(GameState.mail_summary_data.get("unreadCount", 0))
	var claimable_count: int = int(GameState.mail_summary_data.get("claimableCount", 0))
	var total_count: int = int(GameState.mail_summary_data.get("totalCount", 0))
	if section_key == SECTION_READ:
		return UiText.MAIL_READ_COUNT_FORMAT % maxi(0, total_count - unread_count)
	return UiText.MAIL_UNREAD_CLAIMABLE_FORMAT % [unread_count, claimable_count]


func set_section(section_key: String) -> void:
	var normalized_key: String = _normalize_section(section_key)
	if _active_section == normalized_key and is_inside_tree():
		return
	_active_section = normalized_key
	if not is_inside_tree():
		return
	_rebuild_mail_buttons()
	_ensure_selected_mail_visible()
	_refresh_action_buttons()
	_emit_navigation_changed()


func _build_ui() -> void:
	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_margin.add_theme_constant_override("margin_left", MAIL_PAGE_SIDE_MARGIN)
	page_margin.add_theme_constant_override("margin_right", MAIL_PAGE_SIDE_MARGIN)
	add_child(page_margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	page_margin.add_child(root)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	root.add_child(action_row)

	var action_spacer: Control = Control.new()
	action_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(action_spacer)

	_claim_all_btn = Button.new()
	_claim_all_btn.text = UiText.MAIL_CLAIM_ALL
	_claim_all_btn.custom_minimum_size = Vector2(132.0, 46.0)
	UiPalette.apply_button_kind(_claim_all_btn, "confirm")
	_claim_all_btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	_claim_all_btn.pressed.connect(_on_claim_all_pressed)
	action_row.add_child(_claim_all_btn)

	_delete_read_btn = Button.new()
	_delete_read_btn.text = UiText.MAIL_DELETE_READ
	_delete_read_btn.custom_minimum_size = Vector2(172.0, 46.0)
	UiPalette.apply_button_kind(_delete_read_btn, "danger")
	_delete_read_btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	_delete_read_btn.pressed.connect(_on_delete_read_pressed)
	action_row.add_child(_delete_read_btn)

	var body_row: HBoxContainer = HBoxContainer.new()
	body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_theme_constant_override("separation", 14)
	root.add_child(body_row)

	var left_panel: PanelContainer = OverlaySceneChrome.make_card_panel(
		OverlaySceneChrome.CARD_BORDER,
		MAIL_CONTAINER_FILL
	)
	left_panel.custom_minimum_size = Vector2(248.0, 0.0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(left_panel)

	var left_margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	left_panel.add_child(left_margin)

	var left_box: VBoxContainer = VBoxContainer.new()
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_theme_constant_override("separation", 12)
	left_margin.add_child(left_box)

	_mail_list_scroll = ScrollContainer.new()
	_mail_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mail_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_box.add_child(_mail_list_scroll)
	InertialScroller.attach(_mail_list_scroll, "vertical")

	_mail_button_list = VBoxContainer.new()
	_mail_button_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_button_list.add_theme_constant_override("separation", 8)
	_mail_list_scroll.add_child(_mail_button_list)

	_mail_empty_state = CenterContainer.new()
	_mail_empty_state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_empty_state.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_child(_mail_empty_state)

	_empty_mail_label = Label.new()
	_empty_mail_label.text = UiText.MAIL_EMPTY
	_empty_mail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_mail_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	_empty_mail_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	_mail_empty_state.add_child(_empty_mail_label)

	var right_panel: PanelContainer = OverlaySceneChrome.make_card_panel(
		OverlaySceneChrome.CARD_BORDER,
		MAIL_CONTAINER_FILL
	)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_child(right_panel)

	var right_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	right_panel.add_child(right_margin)

	var right_box: VBoxContainer = VBoxContainer.new()
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_theme_constant_override("separation", 12)
	right_margin.add_child(right_box)

	_detail_title = Label.new()
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	_detail_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	right_box.add_child(_detail_title)

	_detail_meta_row = HBoxContainer.new()
	_detail_meta_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.add_child(_detail_meta_row)

	var meta_spacer: Control = Control.new()
	meta_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_meta_row.add_child(meta_spacer)

	_expire_label = Label.new()
	_expire_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_expire_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_expire_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	_detail_meta_row.add_child(_expire_label)

	_detail_empty_state = CenterContainer.new()
	_detail_empty_state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_empty_state.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_child(_detail_empty_state)

	_empty_detail_label = Label.new()
	_empty_detail_label.text = UiText.MAIL_SELECT_PROMPT
	_empty_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_detail_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	_empty_detail_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	_detail_empty_state.add_child(_empty_detail_label)

	_detail_content_scroll = ScrollContainer.new()
	_detail_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_box.add_child(_detail_content_scroll)
	InertialScroller.attach(_detail_content_scroll, "vertical")

	var detail_content_margin: MarginContainer = MarginContainer.new()
	detail_content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content_margin.add_theme_constant_override("margin_right", 6)
	_detail_content_scroll.add_child(detail_content_margin)

	_detail_content = Label.new()
	_detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_content.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	_detail_content.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	detail_content_margin.add_child(_detail_content)

	_attachment_section = VBoxContainer.new()
	_attachment_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_section.add_theme_constant_override("separation", 10)
	right_box.add_child(_attachment_section)

	_attachment_title = Label.new()
	_attachment_title.text = UiText.MAIL_ATTACHMENT
	_attachment_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	_attachment_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	_attachment_section.add_child(_attachment_title)

	_attachment_box = HFlowContainer.new()
	_attachment_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_box.add_theme_constant_override("h_separation", 12)
	_attachment_box.add_theme_constant_override("v_separation", 12)
	_attachment_section.add_child(_attachment_box)

	_claim_btn = Button.new()
	_claim_btn.text = UiText.MAIL_CLAIM_ATTACHMENT
	_claim_btn.custom_minimum_size = Vector2(0.0, 50.0)
	UiPalette.apply_button_kind(_claim_btn, "confirm")
	_claim_btn.pressed.connect(_on_claim_pressed)
	right_box.add_child(_claim_btn)


func _apply_mail_cache() -> void:
	if _mail_state_refresh_in_progress:
		return
	_mail_state_refresh_in_progress = true
	_rebuild_mail_buttons()
	_ensure_selected_mail_visible()
	_refresh_action_buttons()
	_mail_state_refresh_in_progress = false
	_emit_navigation_changed()
	_maybe_recover_mail_cache()


func _on_mail_state_changed() -> void:
	_apply_mail_cache()


func _rebuild_mail_buttons() -> void:
	for child: Node in _mail_button_list.get_children():
		child.queue_free()
	_mail_buttons.clear()

	var visible_items: Array = _get_visible_mail_items()
	if visible_items.is_empty():
		_mail_list_scroll.visible = false
		_mail_empty_state.visible = true
		return
	_mail_list_scroll.visible = true
	_mail_empty_state.visible = false

	for item_variant: Variant in visible_items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var mail_id: int = int(item.get("mailId", 0))
		if mail_id <= 0:
			continue
		var card: PanelContainer = _build_mail_list_item(item)
		_mail_button_list.add_child(card)
		_mail_buttons[mail_id] = card

	_refresh_mail_button_states()
func _build_mail_list_item(item: Dictionary) -> PanelContainer:
	var mail_id: int = int(item.get("mailId", 0))
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_mail_item_style(mail_id == _selected_mail_id))

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	if not bool(item.get("isRead", false)):
		var unread_dot: ColorRect = ColorRect.new()
		unread_dot.color = LIST_ITEM_BORDER_SELECTED
		unread_dot.custom_minimum_size = Vector2(10.0, 10.0)
		row.add_child(unread_dot)

	var title_label: Label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.text = str(item.get("title", UiText.MAIL_UNTITLED))
	title_label.add_theme_font_size_override("font_size", SceneMenuTheme.SECONDARY_SUBMENU_INACTIVE_FONT_SIZE)
	title_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	row.add_child(title_label)

	var click_button: Button = Button.new()
	click_button.flat = true
	click_button.focus_mode = Control.FOCUS_NONE
	click_button.text = ""
	click_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_button.pressed.connect(Callable(self, "_select_mail").bind(mail_id))
	panel.add_child(click_button)

	return panel


func _make_mail_item_style(is_selected: bool) -> StyleBoxFlat:
	return OverlaySceneChrome.make_panel_style(
		LIST_ITEM_FILL_SELECTED if is_selected else LIST_ITEM_FILL,
		LIST_ITEM_BORDER_SELECTED if is_selected else LIST_ITEM_BORDER,
		12
	)


func _get_visible_mail_items() -> Array:
	var items: Array = []
	for item_variant: Variant in GameState.mail_list_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if _is_expired_mail(item):
			continue
		var is_processed: bool = _is_processed_mail(item)
		if _active_section == SECTION_UNREAD and is_processed:
			continue
		if _active_section == SECTION_READ and not is_processed:
			continue
		items.append(item)
	return items


func _is_expired_mail(item: Dictionary) -> bool:
	return str(item.get("status", "")) == "Expired"


func _is_processed_mail(item: Dictionary) -> bool:
	var is_read: bool = bool(item.get("isRead", false))
	var is_claimed: bool = bool(item.get("isClaimed", false))
	var has_attachment: bool = bool(item.get("hasAttachment", false))
	return is_read and (is_claimed or not has_attachment)


func _mail_item_has_detail(item: Dictionary) -> bool:
	return item.has("content") or item.has("attachments") or item.has("canClaim")


func _select_mail(mail_id: int) -> void:
	if mail_id <= 0:
		return
	_selected_mail_id = mail_id
	_refresh_mail_button_states()
	_load_mail_detail(mail_id)


func _refresh_mail_button_states() -> void:
	for mail_id_variant: Variant in _mail_buttons.keys():
		var mail_id: int = int(mail_id_variant)
		var panel: PanelContainer = _mail_buttons.get(mail_id) as PanelContainer
		if panel == null:
			continue
		panel.add_theme_stylebox_override("panel", _make_mail_item_style(mail_id == _selected_mail_id))


func _load_mail_detail(mail_id: int) -> void:
	var detail: Dictionary = _get_mail_detail_from_cache(mail_id)
	if detail.is_empty():
		GameState.update_selected_mail({})
		_render_detail_placeholder({}, UiText.MAIL_CONTENT_LOADING)
		_refresh_action_buttons()
		_recover_mail_detail_silent(mail_id)
		return
	if not _mail_item_has_detail(detail):
		GameState.update_selected_mail(detail)
		_render_detail_placeholder(detail, UiText.MAIL_CONTENT_LOADING)
		_refresh_action_buttons()
		_recover_mail_detail_silent(mail_id)
		return
	if _is_expired_mail(detail):
		if not GameState.selected_mail_data.is_empty():
			GameState.update_selected_mail({})
		_selected_mail_id = 0
		_apply_mail_cache()
		return

	GameState.update_selected_mail(detail)
	_render_detail(detail)
	_refresh_action_buttons()

	if not bool(detail.get("isRead", false)):
		GameState.mark_mail_read_local(mail_id)
		ApiClient.mark_mail_read_silent(mail_id, Callable(self, "_on_mark_mail_read_completed"))


func _maybe_recover_mail_cache() -> void:
	if _mail_cache_recovery_in_flight:
		return
	if not GameState.mail_list_data.is_empty():
		return
	if int(GameState.mail_summary_data.get("totalCount", 0)) <= 0:
		return
	_mail_cache_recovery_in_flight = true
	var page_size: int = mini(maxi(int(GameState.mail_summary_data.get("totalCount", 0)), 1), 100)
	ApiClient.get_mail_list_silent(Callable(self, "_on_mail_list_recovered"), 1, page_size)


func _recover_mail_detail_silent(mail_id: int) -> void:
	if mail_id <= 0:
		return
	if _mail_detail_recovery_ids.has(mail_id):
		return
	_mail_detail_recovery_ids.append(mail_id)
	ApiClient.get_mail_detail_silent(mail_id, Callable(self, "_on_mail_detail_recovered").bind(mail_id))


func _render_detail(detail: Dictionary) -> void:
	for child: Node in _attachment_box.get_children():
		child.queue_free()

	var has_detail: bool = not detail.is_empty()
	_detail_empty_state.visible = not has_detail
	_detail_title.visible = has_detail
	_detail_meta_row.visible = has_detail
	_detail_content_scroll.visible = has_detail
	_detail_content.visible = has_detail
	_expire_label.visible = has_detail
	_attachment_section.visible = has_detail

	if not has_detail:
		_empty_detail_label.text = UiText.MAIL_SELECT_PROMPT
		_detail_title.text = ""
		_detail_content.text = ""
		_expire_label.text = ""
		_detail_meta_row.visible = false
		_attachment_section.visible = false
		_claim_btn.visible = false
		return

	_detail_title.text = str(detail.get("title", UiText.MAIL_UNTITLED))
	_detail_content.text = str(detail.get("content", "")).strip_edges()
	_expire_label.text = _format_expire_days(detail.get("expireAtUtc", null))
	_detail_meta_row.visible = _expire_label.text != ""

	var attachments_variant: Variant = detail.get("attachments", [])
	var attachments: Array = attachments_variant if attachments_variant is Array else []
	var has_attachments: bool = not attachments.is_empty()
	_attachment_section.visible = has_attachments
	_attachment_title.visible = has_attachments
	_attachment_box.visible = has_attachments

	if not has_attachments:
		_claim_btn.visible = false
		return

	for attachment_variant: Variant in attachments:
		if not (attachment_variant is Dictionary):
			continue
		_attachment_box.add_child(_build_attachment_slot(attachment_variant))

	var can_claim: bool = bool(detail.get("canClaim", false))
	var is_claimed: bool = bool(detail.get("isClaimed", false))
	_claim_btn.visible = not is_claimed
	_claim_btn.disabled = _api_in_flight or not can_claim
	_claim_btn.text = UiText.MAIL_CLAIM_ATTACHMENT


func _format_expire_days(expire_at_value: Variant) -> String:
	if expire_at_value == null:
		return ""

	var expire_text: String = str(expire_at_value).strip_edges()
	if expire_text == "":
		return ""

	var expire_unix: int = Time.get_unix_time_from_datetime_string(expire_text)
	if expire_unix <= 0:
		return ""

	var remaining_seconds: int = max(0, expire_unix - Time.get_unix_time_from_system())
	var remaining_days: int = int(ceil(float(remaining_seconds) / 86400.0))
	if remaining_days <= 0:
		remaining_days = 1
	return UiText.MAIL_EXPIRE_DAYS_FORMAT % remaining_days


func _render_detail_placeholder(detail: Dictionary, message: String) -> void:
	for child: Node in _attachment_box.get_children():
		child.queue_free()

	_detail_empty_state.visible = false
	_detail_title.visible = true
	_detail_meta_row.visible = false
	_detail_content_scroll.visible = true
	_detail_content.visible = true
	_expire_label.visible = false
	_attachment_section.visible = false
	_claim_btn.visible = false
	_detail_title.text = str(detail.get("title", UiText.MAIL_UNTITLED)) if not detail.is_empty() else UiText.MAIL_UNTITLED
	_detail_content.text = message
	_expire_label.text = ""


func _build_attachment_slot(attachment_variant: Variant) -> Control:
	var attachment: Dictionary = attachment_variant
	var slot: Control = ITEM_SLOT_TEMPLATE.instantiate() as Control
	var frame: TextureRect = slot.get_node("Frame") as TextureRect
	var icon: TextureRect = slot.get_node("ItemIcon") as TextureRect
	var overlay_mask: TextureRect = slot.get_node("OverlayMask") as TextureRect
	var name_label: Label = slot.get_node("ItemNameLabel") as Label
	var qty_label: Label = slot.get_node("CountLabel") as Label
	var quantity: int = int(attachment.get("quantity", 0))
	var image_path: String = str(attachment.get("imagePath", ""))
	var display_name: String = str(attachment.get("displayName", attachment.get("rewardType", "")))
	AssetResolver.apply_catalog_texture(icon, image_path)
	icon.visible = image_path != ""

	frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
	overlay_mask.modulate = Color(1.0, 1.0, 1.0, 0.42)
	name_label.text = display_name
	name_label.tooltip_text = display_name
	qty_label.text = GameState.format_number(quantity)
	qty_label.tooltip_text = qty_label.text

	slot.scale = Vector2(ATTACHMENT_SLOT_SCALE, ATTACHMENT_SLOT_SCALE)
	var scaled_size: Vector2 = ATTACHMENT_SLOT_BASE_SIZE * ATTACHMENT_SLOT_SCALE
	slot.position = Vector2(
		(ATTACHMENT_SLOT_CELL_SIZE.x - scaled_size.x) * 0.5,
		(ATTACHMENT_SLOT_CELL_SIZE.y - scaled_size.y) * 0.5
	)

	var cell: Control = Control.new()
	cell.custom_minimum_size = ATTACHMENT_SLOT_CELL_SIZE
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(slot)
	return cell


func _on_claim_pressed() -> void:
	if _api_in_flight:
		return
	var mail_id: int = int(GameState.selected_mail_data.get("mailId", 0))
	if mail_id <= 0:
		return

	_api_in_flight = true
	_refresh_action_buttons()
	ApiClient.claim_mail(mail_id, Callable(self, "_on_claim_mail_completed").bind(mail_id))


func _on_claim_all_pressed() -> void:
	if _api_in_flight:
		return
	if int(GameState.mail_summary_data.get("claimableCount", 0)) <= 0:
		ToastManager.hint(UiText.MAIL_NO_CLAIMABLE)
		return

	DialogManager.show_confirm(UiText.MAIL_CONFIRM_CLAIM_ALL_TITLE, UiText.MAIL_CONFIRM_CLAIM_ALL_BODY, Callable(self, "_confirm_claim_all_mails"))


func _on_delete_read_pressed() -> void:
	if _api_in_flight:
		return
	if _count_deletable_mails() <= 0:
		ToastManager.hint(UiText.MAIL_NO_DELETABLE)
		return

	DialogManager.show_confirm(UiText.MAIL_CONFIRM_DELETE_READ_TITLE, UiText.MAIL_CONFIRM_DELETE_READ_BODY, Callable(self, "_confirm_delete_read_mails"))


func _on_mark_mail_read_completed(mark_success: bool, mark_data: Variant, _mark_error: Dictionary) -> void:
	if mark_success and mark_data is Dictionary:
		GameState.update_mail_summary(mark_data)


func _on_mail_list_recovered(success: bool, data: Variant, _error: Dictionary) -> void:
	_mail_cache_recovery_in_flight = false
	if not success or not (data is Dictionary):
		return
	var payload: Dictionary = data
	var items_variant: Variant = payload.get("items", [])
	if items_variant is Array:
		GameState.update_mail_list(items_variant)


func _on_mail_detail_recovered(success: bool, data: Variant, error: Dictionary, mail_id: int) -> void:
	_mail_detail_recovery_ids.erase(mail_id)
	if not success or not (data is Dictionary):
		var error_message: String = str(error.get("message", UiText.MAIL_CONTENT_FAILED))
		var cached_detail: Dictionary = _get_mail_detail_from_cache(mail_id)
		GameState.update_selected_mail(cached_detail)
		_render_detail_placeholder(cached_detail, error_message)
		_refresh_action_buttons()
		_show_error_toast(UiText.MAIL_CONTENT_FAILED, error_message)
		return
	GameState.update_selected_mail(data)
	_render_detail(GameState.selected_mail_data)
	_refresh_action_buttons()


func _on_claim_mail_completed(success: bool, data: Variant, error: Dictionary, mail_id: int) -> void:
	_api_in_flight = false
	if not success:
		_refresh_action_buttons()
		_show_error_toast(UiText.MAIL_CLAIM_FAILED, str(error.get("message", UiText.MAIL_CLAIM_FAILED)))
		return

	var payload: Dictionary = data if data is Dictionary else {}
	GameState.apply_wallet_snapshot(payload.get("walletSnapshot", {}))
	GameState.update_mail_summary(payload.get("mailSummary", {}))
	GameState.mark_mail_claimed_local(mail_id)
	_rebuild_mail_buttons()
	_ensure_selected_mail_visible()
	_refresh_action_buttons()
	_render_reward_dialog(payload.get("grantedRewards", []), UiText.MAIL_CLAIM_SUCCESS)


func _confirm_claim_all_mails() -> void:
	_api_in_flight = true
	_refresh_action_buttons()
	ApiClient.claim_all_mails(Callable(self, "_on_claim_all_mails_completed"))


func _on_claim_all_mails_completed(success: bool, data: Variant, error: Dictionary) -> void:
	_api_in_flight = false
	if not success:
		_refresh_action_buttons()
		_show_error_toast(UiText.MAIL_CLAIM_ALL_FAILED, str(error.get("message", UiText.MAIL_CLAIM_ALL_FAILED)))
		return

	var payload: Dictionary = data if data is Dictionary else {}
	GameState.apply_wallet_snapshot(payload.get("walletSnapshot", {}))
	GameState.update_mail_summary(payload.get("mailSummary", {}))
	GameState.mark_mail_claimed_many_local(payload.get("claimedMailIds", []))
	_rebuild_mail_buttons()
	_ensure_selected_mail_visible()
	_refresh_action_buttons()
	_render_reward_dialog(payload.get("grantedRewards", []), UiText.MAIL_CLAIM_ALL_SUCCESS)


func _confirm_delete_read_mails() -> void:
	_api_in_flight = true
	_refresh_action_buttons()
	ApiClient.delete_read_mails(Callable(self, "_on_delete_read_mails_completed"))


func _on_delete_read_mails_completed(success: bool, data: Variant, error: Dictionary) -> void:
	_api_in_flight = false
	if not success:
		_refresh_action_buttons()
		_show_error_toast(UiText.MAIL_DELETE_READ_FAILED, str(error.get("message", UiText.MAIL_DELETE_READ_FAILED)))
		return

	if data is Dictionary:
		GameState.update_mail_summary(data)
	GameState.remove_processed_mails_local()
	GameState.update_selected_mail({})
	_selected_mail_id = 0
	_apply_mail_cache()
	ToastManager.success(UiText.MAIL_DELETE_READ_SUCCESS)


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
		lines.append(UiText.MAIL_REWARD_EMPTY)
	DialogManager.show_info(title, "\n".join(lines), Callable(), "large")


func _count_deletable_mails() -> int:
	var count: int = 0
	for item_variant: Variant in GameState.mail_list_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if _is_expired_mail(item):
			continue
		if _is_processed_mail(item):
			count += 1
	return count


func _show_error_toast(title: String, detail: String = "") -> void:
	var normalized_title: String = title.strip_edges()
	var normalized_detail: String = detail.strip_edges()
	if normalized_detail == "" or normalized_detail == normalized_title:
		ToastManager.error(normalized_title)
		return
	ToastManager.error(normalized_title, normalized_detail)


func _refresh_action_buttons() -> void:
	if _claim_all_btn != null:
		_claim_all_btn.disabled = _api_in_flight or int(GameState.mail_summary_data.get("claimableCount", 0)) <= 0
		RedDotService.refresh_dot(_claim_all_btn, RedDotService.has_mail_claimable_red_dot())
	if _delete_read_btn != null:
		_delete_read_btn.disabled = _api_in_flight or _count_deletable_mails() <= 0
	if _claim_btn != null:
		var has_attachment: bool = bool(GameState.selected_mail_data.get("hasAttachment", false))
		var is_claimed: bool = bool(GameState.selected_mail_data.get("isClaimed", false))
		var can_claim: bool = bool(GameState.selected_mail_data.get("canClaim", false))
		_claim_btn.visible = has_attachment and not is_claimed
		_claim_btn.disabled = _api_in_flight or not can_claim
		RedDotService.refresh_dot(_claim_btn, _claim_btn.visible and not _claim_btn.disabled)


func _ensure_selected_mail_visible() -> void:
	var visible_items: Array = _get_visible_mail_items()
	if visible_items.is_empty():
		_selected_mail_id = 0
		if not GameState.selected_mail_data.is_empty():
			GameState.update_selected_mail({})
		_render_detail({})
		return

	for item_variant: Variant in visible_items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if int(item.get("mailId", 0)) == _selected_mail_id:
			_refresh_mail_button_states()
			_render_detail(GameState.selected_mail_data)
			return

	var first_item: Dictionary = visible_items[0]
	_select_mail(int(first_item.get("mailId", 0)))


func _normalize_section(section_key: String) -> String:
	var normalized_key: String = section_key.to_lower().strip_edges()
	if normalized_key == SECTION_READ:
		return SECTION_READ
	return SECTION_UNREAD


func _get_mail_detail_from_cache(mail_id: int) -> Dictionary:
	for item_variant: Variant in GameState.mail_list_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if int(item.get("mailId", 0)) == mail_id:
			return item
	return {}


func _emit_navigation_changed() -> void:
	navigation_changed.emit(get_footer_items(), _active_section)
