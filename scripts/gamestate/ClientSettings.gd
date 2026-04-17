extends Node

const SAVE_PATH := "user://client_settings.json"
const DEFAULT_SETTINGS := {
	"masterVolume": 1.0,
	"bgmVolume": 0.72,
	"sfxVolume": 0.9,
	"masterMuted": false,
	"bgmMuted": false,
	"sfxMuted": false,
}

signal settings_changed(settings: Dictionary)

var _settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)


func _ready() -> void:
	_load_settings()
	UiAudio.ensure_audio_buses()
	UiAudio.apply_settings(_settings)


func get_settings() -> Dictionary:
	return _settings.duplicate(true)


func get_setting(key: String) -> Variant:
	return _settings.get(key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	if not DEFAULT_SETTINGS.has(key):
		return

	var normalized: Variant = _normalize_value(key, value)
	if _settings.has(key) and _values_match(_settings[key], normalized):
		return

	_settings[key] = normalized
	_save_settings()
	UiAudio.apply_settings(_settings)
	settings_changed.emit(get_settings())


func set_volume(bus_key: String, value: float) -> void:
	set_setting("%sVolume" % bus_key, clampf(value, 0.0, 1.0))


func set_muted(bus_key: String, muted: bool) -> void:
	set_setting("%sMuted" % bus_key, muted)


func _load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("ClientSettings: failed to open save file")
		return

	var json := JSON.new()
	var parse_result: int = json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		push_error("ClientSettings: failed to parse save file")
		return

	var payload: Variant = json.get_data()
	if not (payload is Dictionary):
		return

	var data: Dictionary = payload
	for key: String in DEFAULT_SETTINGS.keys():
		if not data.has(key):
			continue
		_settings[key] = _normalize_value(key, data.get(key))


func _save_settings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ClientSettings: failed to open save file")
		return
	file.store_string(JSON.stringify(_settings, "\t"))
	file.close()


func _normalize_value(key: String, value: Variant) -> Variant:
	match key:
		"masterMuted", "bgmMuted", "sfxMuted":
			return bool(value)
		_:
			return clampf(float(value), 0.0, 1.0)


func _values_match(left: Variant, right: Variant) -> bool:
	if typeof(left) == TYPE_FLOAT or typeof(right) == TYPE_FLOAT:
		return is_equal_approx(float(left), float(right))
	return left == right
