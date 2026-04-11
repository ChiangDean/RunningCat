extends Node

const RECONNECT_BASE_SECONDS := 2.0
const HEARTBEAT_INTERVAL_SECONDS := 25.0

var _socket = null
var _handshake_sent := false
var _reconnect_attempts := 0
var _next_reconnect_unix := 0.0
var _last_ping_unix := 0.0


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if GameState.chat_token == "" or GameState.chat_endpoint == "":
		_disconnect_internal()
		return

	if _socket == null:
		if Time.get_ticks_msec() / 1000.0 >= _next_reconnect_unix:
			_connect_socket()
		return

	_socket.poll()
	var state: int = _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _handshake_sent:
			_send_json({
				"action": "connect",
				"token": GameState.chat_token,
				"resume": GameState.chat_last_received_seq_by_channel,
			})
			_handshake_sent = true
			GameState.set_chat_connection_state("connecting")
		if Time.get_ticks_msec() / 1000.0 - _last_ping_unix >= HEARTBEAT_INTERVAL_SECONDS:
			_send_json({"action": "ping"})
			_last_ping_unix = Time.get_ticks_msec() / 1000.0
		while _socket.get_available_packet_count() > 0:
			var packet: String = _socket.get_packet().get_string_from_utf8()
			_handle_payload(packet)
	elif state == WebSocketPeer.STATE_CONNECTING:
		GameState.set_chat_connection_state("connecting")
	else:
		_schedule_reconnect()


func send_message(channel_key: String, content: String) -> void:
	if _socket != null and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send_json({"action": "send_message", "channelKey": channel_key, "content": content})


func mark_read(channel_key: String, last_read_sequence: int) -> void:
	if _socket != null and _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send_json({"action": "mark_read", "channelKey": channel_key, "lastReadSequence": last_read_sequence})
	else:
		ApiClient.post_chat_read(channel_key, last_read_sequence, func(_success: bool, _data: Variant, _error: Dictionary) -> void:
			pass
		)


func reconnect_now() -> void:
	_schedule_reconnect(true)


func _connect_socket() -> void:
	_disconnect_internal()
	_socket = WebSocketPeer.new()
	var error: int = _socket.connect_to_url(GameState.chat_endpoint)
	if error != OK:
		_schedule_reconnect()
		return
	_handshake_sent = false
	GameState.set_chat_connection_state("connecting")


func _disconnect_internal() -> void:
	if _socket != null:
		_socket.close()
	_socket = null
	_handshake_sent = false
	_reconnect_attempts = 0
	_next_reconnect_unix = 0.0
	if GameState.chat_connection_state != "disconnected":
		GameState.set_chat_connection_state("disconnected")


func _schedule_reconnect(reset_backoff: bool = false) -> void:
	if reset_backoff:
		_reconnect_attempts = 0
	if _socket != null:
		_socket.close()
	_socket = null
	_handshake_sent = false
	_reconnect_attempts += 1
	var wait_seconds := minf(30.0, RECONNECT_BASE_SECONDS * pow(2.0, float(_reconnect_attempts - 1)))
	_next_reconnect_unix = Time.get_ticks_msec() / 1000.0 + wait_seconds
	GameState.set_chat_connection_state("reconnecting")


func _send_json(payload: Dictionary) -> void:
	if _socket == null:
		return
	_socket.send_text(JSON.stringify(payload))


func _handle_payload(packet: String) -> void:
	var json := JSON.new()
	if json.parse(packet) != OK:
		return
	var payload: Variant = json.get_data()
	if not (payload is Dictionary):
		return
	var data: Dictionary = payload
	var event_type := String(data.get("eventType", ""))
	match event_type:
		"chat.connected":
			_reconnect_attempts = 0
			GameState.set_chat_connection_state("connected")
		"chat.message.received", "chat.message.replay":
			var channel_key := String(data.get("channelKey", data.get("channel", "world"))).to_lower()
			var message_variant: Variant = data.get("message", {})
			if message_variant is Dictionary:
				GameState.append_chat_message_envelope(channel_key, int(data.get("sequence", 0)), message_variant)
		"chat.unread.sync":
			GameState.set_chat_unread_count(String(data.get("channelKey", "")).to_lower(), int(data.get("unreadCount", 0)))
		"chat.pong":
			pass
		"chat.error":
			GameState.set_chat_connection_state("reconnecting")
