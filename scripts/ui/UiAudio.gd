extends Node

const UI_BUTTON_CLICK_SFX := preload("res://assets/audio/sfx/ui/battle_scene.mp3")
const MASTER_BUS_NAME := "Master"
const BGM_BUS_NAME := "BGM"
const SFX_BUS_NAME := "SFX"

var _bgm_player: AudioStreamPlayer
var _current_bgm_path: String = ""
var _web_audio_unlocked: bool = false


func _ready() -> void:
	ensure_audio_buses()
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BGM_BUS_NAME
	_bgm_player.stream_paused = false
	add_child(_bgm_player)


func should_play_for_button(button: BaseButton) -> bool:
	if button == null:
		return false
	return button.text != UiText.SCOOPER_BACK


func play_ui_click() -> void:
	unlock_from_user_gesture(true)


func unlock_from_user_gesture(play_feedback: bool = false) -> void:
	ensure_audio_buses()
	var should_prime_silently: bool = _is_web_runtime() and not _web_audio_unlocked and not play_feedback
	if _is_web_runtime() and not _web_audio_unlocked:
		_resume_web_audio_contexts()
		_web_audio_unlocked = true
	if UI_BUTTON_CLICK_SFX == null:
		return
	if should_prime_silently:
		play_sfx(UI_BUTTON_CLICK_SFX, -80.0, 1.0)
	elif play_feedback:
		play_sfx(UI_BUTTON_CLICK_SFX, 0.0, 1.0)


func ensure_audio_buses() -> void:
	_ensure_bus(BGM_BUS_NAME, MASTER_BUS_NAME)
	_ensure_bus(SFX_BUS_NAME, MASTER_BUS_NAME)


func apply_settings(settings: Dictionary) -> void:
	ensure_audio_buses()
	_apply_bus_settings(MASTER_BUS_NAME, float(settings.get("masterVolume", 1.0)), bool(settings.get("masterMuted", false)))
	_apply_bus_settings(BGM_BUS_NAME, float(settings.get("bgmVolume", 1.0)), bool(settings.get("bgmMuted", false)))
	_apply_bus_settings(SFX_BUS_NAME, float(settings.get("sfxVolume", 1.0)), bool(settings.get("sfxMuted", false)))


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = SFX_BUS_NAME
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func play_bgm(stream: AudioStream, restart: bool = false) -> void:
	if stream == null:
		return
	ensure_audio_buses()
	if _bgm_player == null:
		_bgm_player = AudioStreamPlayer.new()
		_bgm_player.bus = BGM_BUS_NAME
		add_child(_bgm_player)

	var stream_path: String = str(stream.resource_path)
	if not restart and _bgm_player.playing and _current_bgm_path == stream_path:
		return

	var playback_stream: AudioStream = stream.duplicate(true) if stream.has_method("duplicate") else stream
	if playback_stream is AudioStreamMP3:
		(playback_stream as AudioStreamMP3).loop = true
	elif playback_stream is AudioStreamOggVorbis:
		(playback_stream as AudioStreamOggVorbis).loop = true

	_current_bgm_path = stream_path
	_bgm_player.stream = playback_stream
	_bgm_player.play()


func stop_bgm() -> void:
	if _bgm_player == null:
		return
	_bgm_player.stop()
	_current_bgm_path = ""


func _ensure_bus(bus_name: String, send_bus_name: String) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)
	var send_index: int = AudioServer.get_bus_index(send_bus_name)
	if send_index != -1:
		AudioServer.set_bus_send(bus_index, send_bus_name)


func _apply_bus_settings(bus_name: String, linear_value: float, muted: bool) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_mute(bus_index, muted)
	AudioServer.set_bus_volume_db(bus_index, _linear_to_db(linear_value))


func _linear_to_db(value: float) -> float:
	if value <= 0.0001:
		return -80.0
	return linear_to_db(value)


func _is_web_runtime() -> bool:
	return OS.has_feature("web")


func _resume_web_audio_contexts() -> void:
	if not _is_web_runtime():
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval("""
(() => {
	const contexts = [];
	if (window.godotAudioContext) contexts.push(window.godotAudioContext);
	if (window.AudioContext && window.__mpdUnlockContext == null) {
		try {
			window.__mpdUnlockContext = new window.AudioContext();
		} catch (_err) {}
	}
	if (window.__mpdUnlockContext) contexts.push(window.__mpdUnlockContext);
	for (const context of contexts) {
		if (context && typeof context.resume === 'function' && context.state !== 'running') {
			try {
				context.resume();
			} catch (_err) {}
		}
	}
})();
""", true)
