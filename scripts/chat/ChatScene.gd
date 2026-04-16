extends Control

const ChatTabScript = preload("res://scripts/chat/chat_channel_tab.gd")
const ChatItemScript = preload("res://scripts/chat/chat_message_item.gd")
const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")

var _active_channel := "system"
var _tab_buttons: Dictionary = {}
var _initial_channel := ""
var _status_label: Label
var _list_root: VBoxContainer
var _scroll: ScrollContainer
var _input: LineEdit
var _send_button: Button
var _hint_label: Label
var _load_more_button: Button


func _ready() -> void:
	custom_minimum_size = Vector2(620, 900)
	_build_ui()
	GameState.chat_connection_state_changed.connect(_on_connection_state_changed)
	GameState.chat_messages_changed.connect(_on_messages_changed)
	GameState.chat_unread_changed.connect(_on_unread_changed)
	if _initial_channel != "" and _available_channels().has(_initial_channel):
		_active_channel = _initial_channel
	_refresh_tabs()
	_refresh_connection_state(GameState.chat_connection_state)
	_load_history(_active_channel, 0)


func set_initial_channel(channel_key: String) -> void:
	_initial_channel = channel_key.to_lower()


func _build_ui() -> void:
	add_child(AssetResolver.make_fullscreen_background("chat"))
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	for item: Array in _build_channel_defs():
		var tab := ChatTabScript.new()
		tab.configure(item[0], item[1])
		tab.pressed.connect(_on_tab_pressed.bind(item[0]))
		header.add_child(tab)
		_tab_buttons[item[0]] = tab

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_status_label)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_hint_label)

	_load_more_button = Button.new()
	_load_more_button.text = "Load older messages"
	_load_more_button.pressed.connect(_on_load_more_pressed)
	root.add_child(_load_more_button)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_scroll)

	_list_root = VBoxContainer.new()
	_list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_root.add_theme_constant_override("separation", 6)
	_scroll.add_child(_list_root)

	var input_row := HBoxContainer.new()
	root.add_child(input_row)

	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.placeholder_text = "Enter message"
	_input.text_submitted.connect(func(_text: String) -> void: _submit_message())
	input_row.add_child(_input)

	_send_button = Button.new()
	_send_button.text = "Send"
	_send_button.pressed.connect(_submit_message)
	input_row.add_child(_send_button)


func _on_tab_pressed(channel_key: String) -> void:
	_active_channel = channel_key
	_refresh_tabs()
	if GameState.get_chat_messages(channel_key).is_empty():
		_load_history(channel_key, 0)
	_render_messages()
	_mark_active_channel_read()


func _on_load_more_pressed() -> void:
	var messages := GameState.get_chat_messages(_active_channel)
	var before_seq := int(messages[0].get("sequence", 0)) if not messages.is_empty() else 0
	_load_history(_active_channel, before_seq)


func _load_history(channel_key: String, before_seq: int) -> void:
	var resolved_channel_key := _resolve_channel_key(channel_key)
	if resolved_channel_key == "":
		return
	ApiClient.get_chat_history(resolved_channel_key, before_seq, 50, func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			_hint_label.text = str(error.get("message", "Failed to load chat history."))
			return
		var payload: Dictionary = data if data is Dictionary else {}
		var messages_variant: Variant = payload.get("messages", [])
		if messages_variant is Array:
			GameState.replace_chat_history(channel_key, messages_variant)
			if channel_key == _active_channel:
				_render_messages()
				_mark_active_channel_read()
	)


func _submit_message() -> void:
	var content := _input.text.strip_edges()
	if content == "":
		return
	if _active_channel != "world":
		if _active_channel != "party":
			return
	var resolved_channel_key := _resolve_channel_key(_active_channel)
	if resolved_channel_key == "":
		return
	ApiClient.post_chat_message(resolved_channel_key, content, func(success: bool, _data: Variant, error: Dictionary) -> void:
		if success:
			_input.text = ""
		else:
			_hint_label.text = str(error.get("message", "Failed to send chat message."))
	)


func _render_messages() -> void:
	for child in _list_root.get_children():
		child.queue_free()
	var messages := GameState.get_chat_messages(_active_channel)
	for message: Dictionary in messages:
		var item := ChatItemScript.new()
		item.setup(_active_channel, message)
		_list_root.add_child(item)
	call_deferred("_scroll_to_bottom")
	_refresh_input_state()


func _scroll_to_bottom() -> void:
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _refresh_tabs() -> void:
	for key: String in _tab_buttons.keys():
		var button: Button = _tab_buttons[key]
		button.disabled = key == _active_channel
		button.set_badge_count(int(GameState.chat_unread_counts.get(key, 0)))


func _refresh_input_state() -> void:
	var can_send := _active_channel == "world" or (_active_channel == "party" and GameState.chat_party_available)
	_input.editable = can_send
	_send_button.disabled = not can_send
	if _active_channel == "guild":
		_hint_label.text = "Guild chat unlocks after guild system is implemented."
	elif _active_channel == "system":
		_hint_label.text = "System messages are read only."
	elif _active_channel == "party":
		_hint_label.text = "Party chat is available to current party members only."
	else:
		_hint_label.text = ""


func _mark_active_channel_read() -> void:
	var latest_seq := GameState.get_chat_latest_sequence(_active_channel)
	if latest_seq <= 0:
		return
	GameState.set_chat_unread_count(_active_channel, 0)
	var resolved_channel_key := _resolve_channel_key(_active_channel)
	if resolved_channel_key != "":
		ChatRealtimeClient.mark_read(resolved_channel_key, latest_seq)


func _on_connection_state_changed(state: String) -> void:
	_refresh_connection_state(state)


func _refresh_connection_state(state: String) -> void:
	_status_label.text = "Connection: %s" % state


func _on_messages_changed(channel_key: String) -> void:
	if channel_key == _active_channel:
		_render_messages()


func _on_unread_changed(_channel_key: String, _count: int) -> void:
	_refresh_tabs()


func _build_channel_defs() -> Array:
	var defs: Array = [
		["system", "System"],
		["world", "World"],
		["guild", "Guild"],
	]
	if GameState.chat_party_available:
		defs.append(["party", "Party"])
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
