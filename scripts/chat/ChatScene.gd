extends Control

signal navigation_changed(items: Array, active_key: String)

const ChatTabScript = preload("res://scripts/chat/chat_channel_tab.gd")
const ChatItemScript = preload("res://scripts/chat/chat_message_item.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")

const CHANNEL_WORLD := "world"
const CHANNEL_PARTY := "party"

var _active_channel: String = CHANNEL_WORLD
var _initial_channel: String = ""
var _overlay_mode := false
var _tab_buttons: Dictionary = {}
var _status_override: String = ""
var _header: HBoxContainer
var _section_label: Label
var _list_root: VBoxContainer
var _scroll: ScrollContainer
var _input: LineEdit
var _send_button: Button
var _hint_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(0.0, 860.0)
	_build_ui()
	GameState.chat_connection_state_changed.connect(_on_connection_state_changed)
	GameState.chat_messages_changed.connect(_on_messages_changed)
	GameState.chat_unread_changed.connect(_on_unread_changed)
	_apply_requested_channel()
	_refresh_tabs()
	_refresh_active_channel_ui()
	_load_history(_active_channel, 0)
	_render_messages()
	_refresh_chat_summary()
	_emit_navigation_changed()


func set_overlay_mode(enabled: bool) -> void:
	_overlay_mode = enabled


func set_initial_channel(channel_key: String) -> void:
	_initial_channel = _normalize_channel_key(channel_key)


func get_footer_items() -> Array:
	return _build_channel_defs()


func get_section() -> String:
	return _active_channel


func set_section(section_key: String) -> void:
	var normalized_key: String = _normalize_channel_key(section_key)
	if _active_channel == normalized_key and is_inside_tree():
		_mark_active_channel_read()
		_queue_scroll_to_bottom()
		return

	_active_channel = normalized_key
	if not is_inside_tree():
		return

	_status_override = ""
	_refresh_tabs()
	_refresh_active_channel_ui()
	if _get_render_messages_for_channel(_active_channel).is_empty():
		_load_history(_active_channel, 0)
	_render_messages()
	_mark_active_channel_read()
	_emit_navigation_changed()


func _build_ui() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	if not _overlay_mode:
		_header = HBoxContainer.new()
		_header.add_theme_constant_override("separation", 8)
		root.add_child(_header)
		_rebuild_tabs()

	var shell: PanelContainer = OverlaySceneChrome.make_card_panel()
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(shell)

	var shell_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	shell.add_child(shell_margin)

	var shell_box: VBoxContainer = VBoxContainer.new()
	shell_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell_box.add_theme_constant_override("separation", 12)
	shell_margin.add_child(shell_box)

	_section_label = Label.new()
	_section_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	shell_box.add_child(_section_label)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_hint_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	shell_box.add_child(_hint_label)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.clip_contents = true
	shell_box.add_child(_scroll)
	InertialScroller.attach(_scroll, "vertical")

	_list_root = VBoxContainer.new()
	_list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_root.add_theme_constant_override("separation", 8)
	_scroll.add_child(_list_root)

	var input_row: HBoxContainer = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	shell_box.add_child(input_row)

	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.placeholder_text = "輸入聊天內容"
	_input.text_submitted.connect(func(_text: String) -> void:
		_submit_message()
	)
	input_row.add_child(_input)

	_send_button = Button.new()
	_send_button.text = "送出"
	_send_button.custom_minimum_size = Vector2(132.0, 48.0)
	_send_button.pressed.connect(_submit_message)
	input_row.add_child(_send_button)

	_refresh_active_channel_ui()


func _refresh_chat_summary() -> void:
	ApiClient.get_chat_summary(func(success: bool, data: Variant, _error: Dictionary) -> void:
		if not success or not (data is Dictionary):
			return
		GameState.apply_chat_summary(data as Dictionary)
		_refresh_tabs()
		_refresh_active_channel_ui()
		if _get_render_messages_for_channel(_active_channel).is_empty():
			_load_history(_active_channel, 0)
		_render_messages()
	)


func _rebuild_tabs() -> void:
	if _header == null:
		return
	_tab_buttons.clear()
	for child: Node in _header.get_children():
		child.queue_free()
	for item_variant: Variant in _build_channel_defs():
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var key: String = str(item.get("key", ""))
		if key == "":
			continue
		var tab: Button = ChatTabScript.new()
		tab.configure(key, str(item.get("label", key)))
		tab.pressed.connect(_on_tab_pressed.bind(key))
		_header.add_child(tab)
		_tab_buttons[key] = tab


func _apply_requested_channel() -> void:
	if _initial_channel != "":
		_active_channel = _initial_channel


func _on_tab_pressed(channel_key: String) -> void:
	set_section(channel_key)


func _load_history(channel_key: String, before_seq: int) -> void:
	if channel_key == CHANNEL_WORLD:
		_load_channel_history("system", before_seq)
		_load_channel_history(CHANNEL_WORLD, before_seq)
		return
	_load_channel_history(channel_key, before_seq)


func _load_channel_history(channel_key: String, before_seq: int) -> void:
	var resolved_channel_key: String = _resolve_channel_key(channel_key)
	if resolved_channel_key == "":
		_refresh_active_channel_ui()
		return
	ApiClient.get_chat_history(resolved_channel_key, before_seq, 50, func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			_status_override = str(error.get("message", "載入聊天訊息失敗"))
			_refresh_active_channel_ui()
			return
		var payload: Dictionary = data if data is Dictionary else {}
		var messages_variant: Variant = payload.get("messages", [])
		if messages_variant is Array:
			GameState.replace_chat_history(channel_key, messages_variant)
			if channel_key == _active_channel or (_active_channel == CHANNEL_WORLD and channel_key == "system"):
				_render_messages()
				_mark_active_channel_read()
	)


func _submit_message() -> void:
	var content: String = _input.text.strip_edges()
	if content == "":
		_status_override = "請先輸入聊天內容"
		_refresh_active_channel_ui()
		return
	if _active_channel != CHANNEL_WORLD and _active_channel != CHANNEL_PARTY:
		return

	var resolved_channel_key: String = _resolve_channel_key(_active_channel)
	if resolved_channel_key == "":
		_refresh_active_channel_ui()
		return

	_send_button.disabled = true
	ApiClient.post_chat_message(resolved_channel_key, content, func(success: bool, data: Variant, error: Dictionary) -> void:
		_send_button.disabled = false
		if success:
			var payload: Dictionary = data if data is Dictionary else {}
			var message_variant: Variant = payload.get("message", {})
			var message: Dictionary = message_variant if message_variant is Dictionary else _build_local_echo_message(content)
			var ack_sequence: int = int(payload.get("ackSequence", 0))
			if ack_sequence > 0:
				GameState.append_chat_message_envelope(_active_channel, ack_sequence, message)
			_input.text = ""
			_status_override = ""
			_mark_active_channel_read()
			_queue_scroll_to_bottom()
		else:
			_status_override = str(error.get("message", "送出聊天訊息失敗"))
		_refresh_active_channel_ui()
	)


func _render_messages() -> void:
	for child: Node in _list_root.get_children():
		child.queue_free()

	var rendered_messages: Array = _get_render_messages_for_channel(_active_channel)
	if rendered_messages.is_empty():
		_list_root.add_child(_build_empty_state())
	else:
		for message_variant: Variant in rendered_messages:
			if not (message_variant is Dictionary):
				continue
			var message: Dictionary = message_variant
			var item: Control = ChatItemScript.new()
			item.setup(str(message.get("_channelKey", _active_channel)), message)
			_list_root.add_child(item)

	_queue_scroll_to_bottom()
	_refresh_active_channel_ui()


func _build_empty_state() -> Control:
	var center: CenterContainer = CenterContainer.new()
	center.custom_minimum_size = Vector2(0.0, 320.0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = "目前沒有聊天訊息"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	center.add_child(label)
	return center


func _get_render_messages_for_channel(channel_key: String) -> Array:
	if channel_key != CHANNEL_WORLD:
		return _decorate_messages(channel_key, GameState.get_chat_messages(channel_key))

	var merged: Array = []
	merged.append_array(_decorate_messages("system", GameState.get_chat_messages("system")))
	merged.append_array(_decorate_messages(CHANNEL_WORLD, GameState.get_chat_messages(CHANNEL_WORLD)))
	merged.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_time: String = str(a.get("sentAtUtc", ""))
		var b_time: String = str(b.get("sentAtUtc", ""))
		if a_time == b_time:
			return int(a.get("sequence", 0)) < int(b.get("sequence", 0))
		return a_time < b_time
	)
	return merged


func _decorate_messages(channel_key: String, messages: Array) -> Array:
	var result: Array = []
	for message_variant: Variant in messages:
		if not (message_variant is Dictionary):
			continue
		var entry: Dictionary = (message_variant as Dictionary).duplicate(true)
		entry["_channelKey"] = channel_key
		result.append(entry)
	return result


func _queue_scroll_to_bottom() -> void:
	call_deferred("_scroll_to_bottom_deferred")


func _scroll_to_bottom_deferred() -> void:
	if not is_instance_valid(_scroll):
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(_scroll):
		return
	var scroll_bar: VScrollBar = _scroll.get_v_scroll_bar()
	if scroll_bar == null:
		return
	_scroll.scroll_vertical = int(scroll_bar.max_value)


func _refresh_tabs() -> void:
	for key: String in _tab_buttons.keys():
		var button: Button = _tab_buttons[key]
		if button == null:
			continue
		button.disabled = key == _active_channel
		button.set_badge_count(_get_tab_unread_count(key))


func _get_tab_unread_count(channel_key: String) -> int:
	if channel_key == CHANNEL_WORLD:
		return int(GameState.chat_unread_counts.get(CHANNEL_WORLD, 0)) + int(GameState.chat_unread_counts.get("system", 0))
	return int(GameState.chat_unread_counts.get(channel_key, 0))


func _refresh_active_channel_ui() -> void:
	if _section_label != null:
		_section_label.text = "全頻聊天" if _active_channel == CHANNEL_WORLD else "隊伍聊天"
	if _hint_label != null:
		_hint_label.text = _build_hint_text()
	if _input == null or _send_button == null:
		return

	var can_send: bool = _active_channel == CHANNEL_WORLD or (_active_channel == CHANNEL_PARTY and _resolve_channel_key(CHANNEL_PARTY) != "")
	_input.editable = can_send
	_send_button.disabled = not can_send
	if not can_send and _active_channel == CHANNEL_PARTY:
		_input.placeholder_text = "加入隊伍後即可使用隊伍聊天"
	else:
		_input.placeholder_text = "輸入聊天內容"


func _build_hint_text() -> String:
	if _status_override != "":
		return _status_override
	if _active_channel == CHANNEL_PARTY and _resolve_channel_key(CHANNEL_PARTY) == "":
		return "加入隊伍後即可查看與發送隊伍聊天。"
	return ""


func _mark_active_channel_read() -> void:
	if _active_channel == CHANNEL_WORLD:
		_mark_channel_read("system")
		_mark_channel_read(CHANNEL_WORLD)
		return
	_mark_channel_read(_active_channel)


func _mark_channel_read(channel_key: String) -> void:
	var latest_seq: int = GameState.get_chat_latest_sequence(channel_key)
	if latest_seq <= 0:
		return
	GameState.set_chat_unread_count(channel_key, 0)
	var resolved_channel_key: String = _resolve_channel_key(channel_key)
	if resolved_channel_key != "":
		ChatRealtimeClient.mark_read(resolved_channel_key, latest_seq)


func _on_connection_state_changed(_state: String) -> void:
	pass


func _on_messages_changed(channel_key: String) -> void:
	if channel_key == _active_channel or (_active_channel == CHANNEL_WORLD and channel_key == "system"):
		_render_messages()
		_mark_active_channel_read()


func _on_unread_changed(_channel_key: String, _count: int) -> void:
	_refresh_tabs()
	_emit_navigation_changed()


func _build_channel_defs() -> Array:
	return [
		{"key": CHANNEL_WORLD, "label": "全頻"},
		{"key": CHANNEL_PARTY, "label": "隊伍"},
	]


func _resolve_channel_key(channel_key: String) -> String:
	if channel_key == CHANNEL_PARTY:
		return GameState.chat_party_channel_key
	return channel_key


func _emit_navigation_changed() -> void:
	navigation_changed.emit(get_footer_items(), _active_channel)


func _normalize_channel_key(channel_key: String) -> String:
	var normalized_key: String = channel_key.to_lower().strip_edges()
	return CHANNEL_PARTY if normalized_key == CHANNEL_PARTY else CHANNEL_WORLD


func _build_local_echo_message(content: String) -> Dictionary:
	return {
		"messageId": "local-%d" % Time.get_ticks_usec(),
		"messageType": "PlayerWorldMessage",
		"senderUserId": null,
		"senderDisplayName": GameState.get_profile_display_name(),
		"senderAvatarId": GameState.get_profile_avatar_id(),
		"content": content,
		"sourceType": "None",
		"sourceKey": null,
		"sentAtUtc": Time.get_datetime_string_from_system(true, true),
	}
