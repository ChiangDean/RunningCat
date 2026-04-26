class_name HomeMiniChatPanel
extends Control

const ChatTabScript = preload("res://scripts/chat/chat_channel_tab.gd")

const CHANNEL_WORLD: String = "world"
const CHANNEL_PARTY: String = "party"
const MAX_VISIBLE_MESSAGES: int = 5

var _active_channel: String = CHANNEL_WORLD
var _panel_active: bool = false
var _status_override: String = ""
var _tab_row: HBoxContainer
var _tab_buttons: Dictionary = {}
var _hint_label: Label
var _message_scroll: ScrollContainer
var _message_list: VBoxContainer
var _input: LineEdit
var _send_button: Button
var _send_request_in_flight: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	GameState.chat_connection_state_changed.connect(_on_connection_state_changed)
	GameState.chat_messages_changed.connect(_on_messages_changed)
	GameState.chat_unread_changed.connect(_on_unread_changed)
	_refresh_tabs()
	_refresh_active_channel_ui()
	_render_messages()


func set_panel_active(active: bool) -> void:
	_panel_active = active
	if not is_inside_tree():
		return
	_refresh_tabs()
	_refresh_active_channel_ui()
	_render_messages()
	if _can_mark_read():
		_mark_active_channel_read()


func set_section(channel_key: String) -> void:
	var normalized_key: String = _normalize_channel_key(channel_key)
	if _active_channel == normalized_key:
		if _can_mark_read():
			_mark_active_channel_read()
			_queue_scroll_to_bottom()
		return
	_active_channel = normalized_key
	if not is_inside_tree():
		return
	_status_override = ""
	_refresh_tabs()
	_refresh_active_channel_ui()
	_render_messages()
	if _can_mark_read():
		_mark_active_channel_read()


func _build_ui() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 8)
	root.add_child(_tab_row)
	_rebuild_tabs()

	_hint_label = Label.new()
	_hint_label.custom_minimum_size = Vector2(0.0, 20.0)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_hint_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	root.add_child(_hint_label)

	_message_scroll = ScrollContainer.new()
	_message_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_message_scroll.clip_contents = true
	root.add_child(_message_scroll)
	InertialScroller.attach(_message_scroll, "vertical")

	_message_list = VBoxContainer.new()
	_message_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_list.add_theme_constant_override("separation", 6)
	_message_scroll.add_child(_message_list)

	var input_row: HBoxContainer = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	root.add_child(input_row)

	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.placeholder_text = UiText.CHAT_INPUT_PLACEHOLDER
	_input.text_submitted.connect(_on_input_text_submitted)
	input_row.add_child(_input)

	_send_button = Button.new()
	_send_button.text = UiText.CHAT_SEND_BUTTON
	_send_button.custom_minimum_size = Vector2(104.0, 40.0)
	_send_button.pressed.connect(_submit_message)
	input_row.add_child(_send_button)


func _rebuild_tabs() -> void:
	if _tab_row == null:
		return
	_tab_buttons.clear()
	for child: Node in _tab_row.get_children():
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
		tab.custom_minimum_size = Vector2(0.0, 38.0)
		tab.pressed.connect(_on_tab_pressed.bind(key))
		_tab_row.add_child(tab)
		_tab_buttons[key] = tab


func _on_tab_pressed(channel_key: String) -> void:
	set_section(channel_key)


func _submit_message() -> void:
	var content: String = _input.text.strip_edges()
	if content == "":
		_status_override = UiText.CHAT_INPUT_EMPTY
		_refresh_active_channel_ui()
		return
	var resolved_channel_key: String = _resolve_channel_key(_active_channel)
	if resolved_channel_key == "":
		_refresh_active_channel_ui()
		return
	_send_request_in_flight = true
	_send_button.disabled = true
	ApiClient.post_chat_message(resolved_channel_key, content, Callable(self, "_on_chat_message_posted").bind(content, _active_channel))


func _on_input_text_submitted(_text: String) -> void:
	_submit_message()


func _on_chat_message_posted(success: bool, data: Variant, error: Dictionary, content: String, channel_key: String) -> void:
	_send_request_in_flight = false
	_send_button.disabled = false
	if success:
		var payload: Dictionary = data if data is Dictionary else {}
		var message_variant: Variant = payload.get("message", {})
		var message: Dictionary = message_variant if message_variant is Dictionary else _build_local_echo_message(content)
		var ack_sequence: int = int(payload.get("ackSequence", 0))
		if ack_sequence > 0:
			GameState.append_chat_message_envelope(channel_key, ack_sequence, message)
		_input.text = ""
		_status_override = ""
		if _can_mark_read():
			_mark_active_channel_read()
		_queue_scroll_to_bottom()
	else:
		_status_override = str(error.get("message", UiText.CHAT_SEND_FAILED))
	_refresh_active_channel_ui()


func _render_messages() -> void:
	if _message_list == null:
		return
	for child: Node in _message_list.get_children():
		child.queue_free()

	var rendered_messages: Array = _get_recent_render_messages(_active_channel)
	if rendered_messages.is_empty():
		_message_list.add_child(_build_empty_state())
	else:
		for message_variant: Variant in rendered_messages:
			if not (message_variant is Dictionary):
				continue
			_message_list.add_child(_build_message_row(message_variant as Dictionary))
	_queue_scroll_to_bottom()


func _build_empty_state() -> Control:
	var center: CenterContainer = CenterContainer.new()
	center.custom_minimum_size = Vector2(0.0, 120.0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = UiText.CHAT_EMPTY_STATE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	center.add_child(label)
	return center


func _build_message_row(message: Dictionary) -> Control:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		OverlaySceneChrome.make_panel_style(
			Color(0.16, 0.12, 0.10, 0.94),
			Color(0.42, 0.31, 0.18, 0.92),
			10
		)
	)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	margin.add_child(body)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	body.add_child(top_row)

	var sender_label: Label = Label.new()
	sender_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sender_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	sender_label.add_theme_color_override("font_color", Color(0.99, 0.89, 0.66, 1.0))
	sender_label.text = _resolve_sender_name(str(message.get("_channelKey", _active_channel)), message)
	top_row.add_child(sender_label)

	var time_label: Label = Label.new()
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	time_label.text = _format_time(str(message.get("sentAtUtc", "")))
	top_row.add_child(time_label)

	var content_label: Label = Label.new()
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	content_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.86, 1.0))
	content_label.text = str(message.get("content", "")).strip_edges()
	body.add_child(content_label)

	return card


func _get_recent_render_messages(channel_key: String) -> Array:
	var merged: Array = []
	if channel_key == CHANNEL_WORLD:
		merged.append_array(_decorate_messages("system", GameState.get_chat_messages("system")))
		merged.append_array(_decorate_messages(CHANNEL_WORLD, GameState.get_chat_messages(CHANNEL_WORLD)))
		merged.sort_custom(_compare_render_messages)
	else:
		merged = _decorate_messages(channel_key, GameState.get_chat_messages(channel_key))
	if merged.size() <= MAX_VISIBLE_MESSAGES:
		return merged
	return merged.slice(merged.size() - MAX_VISIBLE_MESSAGES, merged.size())


func _decorate_messages(channel_key: String, messages: Array) -> Array:
	var result: Array = []
	for message_variant: Variant in messages:
		if not (message_variant is Dictionary):
			continue
		var entry: Dictionary = (message_variant as Dictionary).duplicate(true)
		entry["_channelKey"] = channel_key
		result.append(entry)
	return result


func _compare_render_messages(a: Dictionary, b: Dictionary) -> bool:
	var a_time: String = str(a.get("sentAtUtc", ""))
	var b_time: String = str(b.get("sentAtUtc", ""))
	if a_time == b_time:
		return int(a.get("sequence", 0)) < int(b.get("sequence", 0))
	return a_time < b_time


func _queue_scroll_to_bottom() -> void:
	call_deferred("_scroll_to_bottom_deferred")


func _scroll_to_bottom_deferred() -> void:
	if _message_scroll == null or not is_instance_valid(_message_scroll):
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if _message_scroll == null or not is_instance_valid(_message_scroll):
		return
	var scroll_bar: VScrollBar = _message_scroll.get_v_scroll_bar()
	if scroll_bar == null:
		return
	_message_scroll.scroll_vertical = int(scroll_bar.max_value)


func _refresh_tabs() -> void:
	for key_variant: Variant in _tab_buttons.keys():
		var key: String = str(key_variant)
		var button: Button = _tab_buttons[key] as Button
		if button == null:
			continue
		button.disabled = key == _active_channel
		button.set_badge_count(_get_tab_unread_count(key))


func _get_tab_unread_count(channel_key: String) -> int:
	if channel_key == CHANNEL_WORLD:
		return int(GameState.chat_unread_counts.get(CHANNEL_WORLD, 0)) + int(GameState.chat_unread_counts.get("system", 0))
	return int(GameState.chat_unread_counts.get(channel_key, 0))


func _refresh_active_channel_ui() -> void:
	if _hint_label != null:
		_hint_label.text = _build_hint_text()
	if _input == null or _send_button == null:
		return
	var can_send: bool = _active_channel == CHANNEL_WORLD or (_active_channel == CHANNEL_PARTY and _resolve_channel_key(CHANNEL_PARTY) != "")
	_input.editable = can_send
	_send_button.disabled = (not can_send) or _send_request_in_flight
	_input.placeholder_text = UiText.CHAT_PARTY_INPUT_DISABLED if (not can_send and _active_channel == CHANNEL_PARTY) else UiText.CHAT_INPUT_PLACEHOLDER


func _build_hint_text() -> String:
	if _status_override != "":
		return _status_override
	if _active_channel == CHANNEL_PARTY and _resolve_channel_key(CHANNEL_PARTY) == "":
		return UiText.CHAT_PARTY_HINT
	return ""


func _can_mark_read() -> bool:
	return _panel_active and is_visible_in_tree()


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
	if channel_key != _active_channel and not (_active_channel == CHANNEL_WORLD and channel_key == "system"):
		return
	_render_messages()
	if _can_mark_read():
		_mark_active_channel_read()


func _on_unread_changed(_channel_key: String, _count: int) -> void:
	_refresh_tabs()


func _build_channel_defs() -> Array:
	return [
		{"key": CHANNEL_WORLD, "label": UiText.CHAT_TAB_WORLD},
		{"key": CHANNEL_PARTY, "label": UiText.CHAT_TAB_PARTY},
	]


func _resolve_channel_key(channel_key: String) -> String:
	if channel_key == CHANNEL_PARTY:
		return GameState.chat_party_channel_key
	return channel_key


func _normalize_channel_key(channel_key: String) -> String:
	var normalized_key: String = channel_key.to_lower().strip_edges()
	return CHANNEL_PARTY if normalized_key == CHANNEL_PARTY else CHANNEL_WORLD


func _resolve_sender_name(channel_key: String, message: Dictionary) -> String:
	if channel_key == "system":
		return UiText.CHAT_SENDER_SYSTEM
	var sender_name: String = str(message.get("senderDisplayName", "")).strip_edges()
	return sender_name if sender_name != "" else UiText.CHAT_SENDER_DEFAULT


func _format_time(sent_at: String) -> String:
	if sent_at.contains("T"):
		var parts: PackedStringArray = sent_at.split("T")
		if parts.size() >= 2 and parts[1].length() >= 5:
			return parts[1].substr(0, 5)
	if sent_at.contains(" "):
		var parts_space: PackedStringArray = sent_at.split(" ")
		if parts_space.size() >= 2 and parts_space[1].length() >= 5:
			return parts_space[1].substr(0, 5)
	return sent_at.left(5) if sent_at.length() >= 5 else sent_at


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
