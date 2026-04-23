class_name RuntimeConfig
extends RefCounted

const CONFIG_PATH := "res://config/runtime_config.json"
const LOCAL_CONFIG_PATH := "res://config/runtime_config.local.json"
const DEFAULT_ENVIRONMENT := "Local"


static func get_config() -> Dictionary:
	var local_config: Dictionary = _load_json_config(LOCAL_CONFIG_PATH)
	if not local_config.is_empty():
		return local_config
	return _load_json_config(CONFIG_PATH)


static func get_api_base_url(default_api_base_url: String) -> String:
	var config: Dictionary = get_config()
	if config.has("api_base_url"):
		return str(config.get("api_base_url", default_api_base_url)).rstrip("/")

	var environment_config: Dictionary = _get_active_environment_config(config)
	var api_base_url: Variant = environment_config.get("api_base_url", default_api_base_url)
	return str(api_base_url).rstrip("/")


static func is_oauth_enabled() -> bool:
	var config: Dictionary = get_config()
	var top_level_value: Variant = _read_oauth_flag(config)
	if top_level_value != null:
		return bool(top_level_value)

	var environment_config: Dictionary = _get_active_environment_config(config)
	var environment_value: Variant = _read_oauth_flag(environment_config)
	if environment_value != null:
		return bool(environment_value)

	return true


static func _get_active_environment_config(config: Dictionary) -> Dictionary:
	var configured_environment: Variant = config.get("environment", DEFAULT_ENVIRONMENT)
	var environment_name: String = _normalize_environment_name(str(configured_environment))
	var environments_variant: Variant = config.get("environments", {})
	var environments: Dictionary = environments_variant if environments_variant is Dictionary else {}
	var environment_variant: Variant = environments.get(environment_name, {})
	return environment_variant if environment_variant is Dictionary else {}


static func _read_oauth_flag(config: Dictionary) -> Variant:
	if config.has("oauth_enabled"):
		return config.get("oauth_enabled")

	var feature_flags_variant: Variant = config.get("feature_flags", {})
	var feature_flags: Dictionary = feature_flags_variant if feature_flags_variant is Dictionary else {}
	if feature_flags.has("oauth_enabled"):
		return feature_flags.get("oauth_enabled")

	return null


static func _load_json_config(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json := JSON.new()
	var content: String = file.get_as_text()
	file.close()
	if json.parse(content) != OK:
		return {}

	var data: Variant = json.get_data()
	return data if data is Dictionary else {}


static func _normalize_environment_name(environment_name: String) -> String:
	var normalized: String = environment_name.strip_edges()
	if normalized.to_lower() == "dev":
		return "DEV"
	if normalized.to_lower() == "sandbox":
		return "Sandbox"
	if normalized.to_lower() == "production":
		return "Production"
	return "Local"
