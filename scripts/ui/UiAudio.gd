extends Node

const MENU_BGM := preload("res://assets/audio/bgm/menu/purring_menu_waltz.mp3")
const BATTLE_BGM := preload("res://assets/audio/bgm/battle/paw_parade_clash.mp3")
const UI_BUTTON_CLICK_SFX := preload("res://assets/audio/sfx/ui/battle_scene.mp3")
const MASTER_BUS_NAME := "Master"
const BGM_BUS_NAME := "BGM"
const SFX_BUS_NAME := "SFX"
const WEB_UNLOCK_RETRY_INTERVAL_SEC := 0.1
const WEB_UNLOCK_RETRY_MAX_ATTEMPTS := 12

var _bgm_player: AudioStreamPlayer
var _current_bgm_path: String = ""
var _web_audio_unlocked: bool = false
var _pending_bgm_stream: AudioStream
var _pending_bgm_restart: bool = false
var _web_unlock_retry_timer: Timer
var _web_unlock_retry_attempts: int = 0

signal debug_state_changed(snapshot: Dictionary)


func _ready() -> void:
	ensure_audio_buses()
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BGM_BUS_NAME
	_bgm_player.stream_paused = false
	add_child(_bgm_player)
	_web_unlock_retry_timer = Timer.new()
	_web_unlock_retry_timer.one_shot = true
	_web_unlock_retry_timer.wait_time = WEB_UNLOCK_RETRY_INTERVAL_SEC
	_web_unlock_retry_timer.timeout.connect(_on_web_unlock_retry_timeout)
	add_child(_web_unlock_retry_timer)
	_install_web_audio_unlock_hooks()
	_notify_debug_state_changed()


func should_play_for_button(button: BaseButton) -> bool:
	if button == null:
		return false
	return button.text != UiText.SCOOPER_BACK


func play_ui_click() -> void:
	unlock_from_user_gesture(true)


func play_menu_bgm(restart: bool = false) -> void:
	play_bgm(MENU_BGM, restart)


func play_battle_bgm(restart: bool = false) -> void:
	play_bgm(BATTLE_BGM, restart)


func unlock_from_user_gesture(play_feedback: bool = false) -> void:
	ensure_audio_buses()
	var should_prime_silently: bool = _is_web_runtime() and not _web_audio_unlocked and not play_feedback
	if _is_web_runtime():
		_web_audio_unlocked = _resume_web_audio_contexts()
		if _web_audio_unlocked:
			_stop_web_unlock_retry()
			_retry_pending_bgm_after_unlock()
		else:
			_schedule_web_audio_unlock_retry()
	if UI_BUTTON_CLICK_SFX == null:
		return
	if should_prime_silently:
		play_sfx(UI_BUTTON_CLICK_SFX, -80.0, 1.0)
	elif play_feedback:
		play_sfx(UI_BUTTON_CLICK_SFX, 0.0, 1.0)
	_notify_debug_state_changed()


func ensure_audio_buses() -> void:
	_ensure_bus(BGM_BUS_NAME, MASTER_BUS_NAME)
	_ensure_bus(SFX_BUS_NAME, MASTER_BUS_NAME)


func apply_settings(settings: Dictionary) -> void:
	ensure_audio_buses()
	_apply_bus_settings(MASTER_BUS_NAME, float(settings.get("masterVolume", 1.0)), bool(settings.get("masterMuted", false)))
	_apply_bus_settings(BGM_BUS_NAME, float(settings.get("bgmVolume", 1.0)), bool(settings.get("bgmMuted", false)))
	_apply_bus_settings(SFX_BUS_NAME, float(settings.get("sfxVolume", 1.0)), bool(settings.get("sfxMuted", false)))
	_notify_debug_state_changed()


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	if _is_web_runtime() and not _web_audio_unlocked:
		_web_audio_unlocked = _resume_web_audio_contexts()
		if _web_audio_unlocked:
			_stop_web_unlock_retry()
		else:
			_schedule_web_audio_unlock_retry()
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = SFX_BUS_NAME
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	_notify_debug_state_changed()


func play_bgm(stream: AudioStream, restart: bool = false) -> void:
	if stream == null:
		return
	ensure_audio_buses()
	_pending_bgm_stream = stream
	_pending_bgm_restart = restart
	if _is_web_runtime() and not _web_audio_unlocked:
		_web_audio_unlocked = _resume_web_audio_contexts()
		if not _web_audio_unlocked:
			_schedule_web_audio_unlock_retry()
			return
		_stop_web_unlock_retry()
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
	_pending_bgm_restart = false
	_notify_debug_state_changed()


func stop_bgm() -> void:
	if _bgm_player == null:
		return
	_bgm_player.stop()
	_current_bgm_path = ""
	_pending_bgm_stream = null
	_pending_bgm_restart = false
	_notify_debug_state_changed()


func get_debug_snapshot() -> Dictionary:
	return {
		"is_web_runtime": _is_web_runtime(),
		"web_audio_unlocked": _web_audio_unlocked,
		"pending_bgm_path": _resource_path_of(_pending_bgm_stream),
		"pending_bgm_restart": _pending_bgm_restart,
		"current_bgm_path": _current_bgm_path,
		"bgm_playing": _bgm_player != null and _bgm_player.playing,
		"retry_attempts": _web_unlock_retry_attempts,
		"retry_timer_active": _web_unlock_retry_timer != null and not _web_unlock_retry_timer.is_stopped(),
		"autoplay_policy": _get_web_autoplay_policy()
	}


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


func _install_web_audio_unlock_hooks() -> void:
	if not _is_web_runtime():
		return
	if not ClassDB.class_exists("JavaScriptBridge"):
		return
	JavaScriptBridge.eval("""
(() => {
	if (window.__mpdAudioUnlock && window.__mpdAudioUnlock.installed) {
		return true;
	}
	const bootstrap = window.__mpdAudioUnlock || {
		contexts: new Set(),
		installed: false,
		registerContext(value) {
			if (!value) return;
			const hasResume = typeof value.resume === 'function';
			const hasState = typeof value.state === 'string';
			if (!hasResume || !hasState) return;
			this.contexts.add(value);
		},
		inspectValue(value) {
			if (!value) return;
			this.registerContext(value);
			if (typeof value !== 'object' && typeof value !== 'function') return;
			try { this.registerContext(value.audioContext); } catch (_err) {}
			try { this.registerContext(value.context); } catch (_err) {}
			try { this.registerContext(value.ctx); } catch (_err) {}
			try { this.registerContext(value.audio && value.audio.context); } catch (_err) {}
		},
		scanWindow() {
			this.inspectValue(window.godotAudioContext);
			for (const key of Object.getOwnPropertyNames(window)) {
				try {
					this.inspectValue(window[key]);
				} catch (_err) {}
			}
		},
		installConstructorHook(name) {
			const Original = window[name];
			if (typeof Original !== 'function' || Original.__mpdWrapped) return;
			const bootstrapRef = this;
			const Wrapped = class extends Original {
				constructor(...args) {
					super(...args);
					bootstrapRef.registerContext(this);
				}
			};
			try { Object.setPrototypeOf(Wrapped, Original); } catch (_err) {}
			Wrapped.__mpdWrapped = true;
			window[name] = Wrapped;
		},
		resumeAllContexts() {
			this.scanWindow();
			let unlocked = false;
			for (const context of this.contexts) {
				if (!context) continue;
				if (context.state !== 'running') {
					try {
						context.resume();
					} catch (_err) {}
				}
				if (context.state === 'running') {
					unlocked = true;
				}
			}
			return unlocked;
		},
		install() {
			if (this.installed) return;
			this.installConstructorHook('AudioContext');
			this.installConstructorHook('webkitAudioContext');
			const resume = () => this.resumeAllContexts();
			['click', 'touchend', 'pointerup', 'keydown'].forEach((eventName) => {
				document.addEventListener(eventName, resume, { capture: true, passive: true });
			});
			document.addEventListener('visibilitychange', () => {
				if (document.visibilityState === 'visible') {
					resume();
				}
			}, true);
			this.installed = true;
		}
	};
	window.__mpdAudioUnlock = bootstrap;
	bootstrap.install();
	return bootstrap.resumeAllContexts();
})();
""", true)


func _resume_web_audio_contexts() -> bool:
	if not _is_web_runtime():
		return true
	if not ClassDB.class_exists("JavaScriptBridge"):
		return false
	_install_web_audio_unlock_hooks()
	var resume_result: Variant = JavaScriptBridge.eval("(() => window.__mpdAudioUnlock ? window.__mpdAudioUnlock.resumeAllContexts() : false)()", true)
	if resume_result is bool:
		return resume_result
	return str(resume_result).to_lower() == "true"


func _retry_pending_bgm_after_unlock() -> void:
	if _pending_bgm_stream == null:
		return
	if _bgm_player == null:
		return
	if _bgm_player.playing and not _pending_bgm_restart:
		return
	play_bgm(_pending_bgm_stream, _pending_bgm_restart)


func _schedule_web_audio_unlock_retry() -> void:
	if not _is_web_runtime():
		return
	if _web_audio_unlocked:
		return
	if _web_unlock_retry_timer == null:
		return
	if not _web_unlock_retry_timer.is_stopped():
		return
	_web_unlock_retry_attempts = 0
	_web_unlock_retry_timer.start()
	_notify_debug_state_changed()


func _stop_web_unlock_retry() -> void:
	if _web_unlock_retry_timer == null:
		return
	_web_unlock_retry_timer.stop()
	_web_unlock_retry_attempts = 0
	_notify_debug_state_changed()


func _on_web_unlock_retry_timeout() -> void:
	if _web_audio_unlocked:
		_stop_web_unlock_retry()
		return
	_web_unlock_retry_attempts += 1
	_web_audio_unlocked = _resume_web_audio_contexts()
	if _web_audio_unlocked:
		_stop_web_unlock_retry()
		_retry_pending_bgm_after_unlock()
		return
	if _web_unlock_retry_attempts < WEB_UNLOCK_RETRY_MAX_ATTEMPTS:
		_web_unlock_retry_timer.start()
	_notify_debug_state_changed()


func _notify_debug_state_changed() -> void:
	debug_state_changed.emit(get_debug_snapshot())


func _resource_path_of(stream: AudioStream) -> String:
	if stream == null:
		return ""
	return str(stream.resource_path)


func _get_web_autoplay_policy() -> String:
	if not _is_web_runtime():
		return "non-web"
	if not ClassDB.class_exists("JavaScriptBridge"):
		return "no-js-bridge"
	var raw_policy: Variant = JavaScriptBridge.eval("(() => { if (!navigator.getAutoplayPolicy) return 'unsupported'; try { return navigator.getAutoplayPolicy('audiocontext'); } catch (_err) { return 'error'; } })()", true)
	return str(raw_policy)
