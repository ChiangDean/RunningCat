extends Control

const ChatTabScript = preload("res://scripts/chat/chat_channel_tab.gd")
const ChatItemScript = preload("res://scripts/chat/chat_message_item.gd")

var _active_channel: String = "world"
var _tab_buttons: Dictionary = {}
var _initial_channel: String = ""
var _header: HBoxContainer
var _list_root: VBoxContainer
var _scroll: ScrollContainer
var _input: LineEdit
var _send_button: Button
var _hint_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(620.0, 900.0)
	_build_ui()
	GameState.chat_connection_state_changed.connect(_on_connection_state_changed)
	GameState.chat_messages_changed.connect(_on_messages_changed)
	GameState.chat_unread_changed.connect(_on_unread_changed)
	_apply_requested_channel()
	_refresh_tabs()
	_load_history(_active_channel, 0)
	_render_messages()
	_refresh_chat_summary()


func set_initial_channel(channel_key: String) -> void:
	_initial_channel = channel_key.to_lower()


func _build_ui() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 8)
	root.add_child(_header)
	_rebuild_tabs()

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_hint_label)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_scroll)

	_list_root = VBoxContainer.new()
	_list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_root.add_theme_constant_override("separation", 6)
	_scroll.add_child(_list_root)

	var input_row: HBoxContainer = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	root.add_child(input_row)

	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.placeholder_text = "輸入聊天內容"
	_input.text_submitted.connect(func(_text: String) -> void:
		_submit_message()
	)
	input_row.add_child(_input)

	_send_button = Button.new()
	_send_button.text = "送出"
	_send_button.pressed.connect(_submit_message)
	input_row.add_child(_send_button)
	_refresh_input_state()


func _refresh_chat_summary() -> void:
	ApiClient.get_chat_summary(func(success: bool, data: Variant, _error: Dictionary) -> void:
		if not success or not (data is Dictionary):
			return
		GameState.apply_chat_summary(data as Dictionary)
		_rebuild_tabs()
		_apply_requested_channel()
		_refresh_tabs()
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
	for item: Array in _build_channel_defs():
		var tab: Button = ChatTabScript.new()
		tab.configure(item[0], item[1])
		tab.pressed.connect(_on_tab_pressed.bind(item[0]))
		_header.add_child(tab)
		_tab_buttons[item[0]] = tab


func _apply_requested_channel() -> void:
	if _initial_channel != "" and _available_channels().has(_initial_channel):
		_active_channel = _initial_channel
		return
	if _available_channels().has(_active_channel):
		return
	_active_channel = "world"


func _on_tab_pressed(channel_key: String) -> void:
	_active_channel = channel_key
	_refresh_tabs()
	if _get_render_messages_for_channel(channel_key).is_empty():
		_load_history(channel_key, 0)
	_render_messages()
	_mark_active_channel_read()


func _load_history(channel_key: String, before_seq: int) -> void:
	if channel_key == "world":
		_load_channel_history("system", before_seq)
		_load_channel_history("world", before_seq)
		return
	_load_channel_history(channel_key, before_seq)


func _load_channel_history(channel_key: String, before_seq: int) -> void:
	var resolved_channel_key: String = _resolve_channel_key(channel_key)
	if resolved_channel_key == "":
		_refresh_input_state()
		return
	ApiClient.get_chat_history(resolved_channel_key, before_seq, 50, func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			_hint_label.text = str(error.get("message", "讀取聊天紀錄失敗"))
			return
		var payload: Dictionary = data if data is Dictionary else {}
		var messages_variant: Variant = payload.get("messages", [])
		if messages_variant is Array:
			GameState.replace_chat_history(channel_key, messages_variant)
			if channel_key == _active_channel or (_active_channel == "world" and channel_key == "system"):
				_render_messages()
				_mark_active_channel_read()
	)


func _submit_message() -> void:
	var content: String = _input.text.strip_edges()
	if content == "":
		return
	if _active_channel != "world" and _active_channel != "party":
		return

	var resolved_channel_key: String = _resolve_channel_key(_active_channel)
	if resolved_channel_key == "":
		_refresh_input_state()
		return

	ApiClient.post_chat_message(resolved_channel_key, content, func(success: bool, _data: Variant, error: Dictionary) -> void:
		if success:
			_input.text = ""
		else:
			_hint_label.text = str(error.get("message", "送出訊息失敗"))
	)


func _render_messages() -> void:
	for child: Node in _list_root.get_children():
		child.queue_free()

	for message_variant: Variant in _get_render_messages_for_channel(_active_channel):
		if not (message_variant is Dictionary):
			continue
		var message: Dictionary = message_variant
		var item: Control = ChatItemScript.new()
		item.setup(str(message.get("_channelKey", _active_channel)), message)
		_list_root.add_child(item)

	call_deferred("_scroll_to_bottom")
	_refresh_input_state()


func _get_render_messages_for_channel(channel_key: String) -> Array:
	if channel_key != "world":
		return _decorate_messages(channel_key, GameState.get_chat_messages(channel_key))

	var merged: Array = []
	merged.append_array(_decorate_messages("system", GameState.get_chat_messages("system")))
	merged.append_array(_decorate_messages("world", GameState.get_chat_messages("world")))
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


func _scroll_to_bottom() -> void:
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _refresh_tabs() -> void:
	for key: String in _tab_buttons.keys():
		var button: Button = _tab_buttons[key]
		if button == null:
			continue
		button.disabled = key == _active_channel
		button.set_badge_count(_get_tab_unread_count(key))


func _get_tab_unread_count(channel_key: String) -> int:
	if channel_key == "world":
		return int(GameState.chat_unread_counts.get("world", 0)) + int(GameState.chat_unread_counts.get("system", 0))
	return int(GameState.chat_unread_counts.get(channel_key, 0))


func _refresh_input_state() -> void:
	var can_send: bool = _active_channel == "world" or (_active_channel == "party" and _resolve_channel_key("party") != "")
	_input.editable = can_send
	_send_button.disabled = not can_send
	if _active_channel == "party":
		if _resolve_channel_key("party") == "":
			_hint_label.text = "隊伍頻道尚未開放。"
		else:
			_hint_label.text = "只有目前隊伍成員可以使用隊伍頻道。"
	else:
		_hint_label.text = ""


func _mark_active_channel_read() -> void:
	if _active_channel == "world":
		_mark_channel_read("system")
		_mark_channel_read("world")
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
	if channel_key == _active_channel or (_active_channel == "world" and channel_key == "system"):
		_render_messages()


func _on_unread_changed(_channel_key: String, _count: int) -> void:
	_refresh_tabs()


func _build_channel_defs() -> Array:
	var defs: Array = [
		["world", "全頻"],
	]
	if GameState.chat_party_available or GameState.chat_party_channel_key != "" or _initial_channel == "party":
		defs.append(["party", "隊伍"])
	return defs


func _available_channels() -> Array[String]:
	var keys: Array[String] = []
	for item: Array in _build_channel_defs():
		keys.append(String(item[0]))
	return keys


func _resolve_channel_key(channel_key: String) -> String:
	if channel_key == "party":
		return GameState.chat_party_channel_key
	return channel_key
