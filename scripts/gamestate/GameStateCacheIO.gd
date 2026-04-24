class_name GameStateCacheIO

## Static JSON cache read/write helpers for catalog, scooper, and config cache dirs

const SCOOPER_CACHE_DIR := "user://player_data/scooper"
const CONFIG_CACHE_DIR  := "user://config"
const CATALOG_CACHE_DIR := "user://catalog"


# ── Catalog cache ──────────────────────────────

static func save_catalog(catalog_name: String, data: Array) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CATALOG_CACHE_DIR))
	var path := "%s/%s.json" % [CATALOG_CACHE_DIR, catalog_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("GameStateCacheIO: failed to write catalog cache " + path)
		return
	file.store_string(JSON.stringify(data))
	file.close()


static func load_catalog(catalog_name: String) -> Array:
	var path := "%s/%s.json" % [CATALOG_CACHE_DIR, catalog_name]
	return _load_json_array(path)


# ── Scooper cache ──────────────────────────────

static func save_scooper(cache_name: String, data: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCOOPER_CACHE_DIR))
	var path := "%s/%s.json" % [SCOOPER_CACHE_DIR, cache_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("GameStateCacheIO: failed to write scooper cache " + path)
		return
	file.store_string(JSON.stringify(data))
	file.close()


static func load_scooper_array(cache_name: String) -> Array:
	var path := "%s/%s.json" % [SCOOPER_CACHE_DIR, cache_name]
	return _load_json_array(path)


static func load_scooper_dict(cache_name: String) -> Dictionary:
	var path := "%s/%s.json" % [SCOOPER_CACHE_DIR, cache_name]
	return _load_json_dict(path)


# ── Config cache ───────────────────────────────

static func save_config(cache_name: String, data: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CONFIG_CACHE_DIR))
	var path := "%s/%s.json" % [CONFIG_CACHE_DIR, cache_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("GameStateCacheIO: failed to write config cache " + path)
		return
	file.store_string(JSON.stringify(data))
	file.close()


static func load_config_array(cache_name: String) -> Array:
	var path := "%s/%s.json" % [CONFIG_CACHE_DIR, cache_name]
	return _load_json_array(path)


static func load_config_dict(cache_name: String) -> Dictionary:
	var path := "%s/%s.json" % [CONFIG_CACHE_DIR, cache_name]
	return _load_json_dict(path)


# ── Private helpers ──────────────────────────────────

static func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return []
	file.close()
	var result: Variant = json.get_data()
	return result if result is Array else []


static func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	var result: Variant = json.get_data()
	return result if result is Dictionary else {}
