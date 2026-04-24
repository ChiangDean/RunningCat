class_name CatDataMigrator
extends RefCounted

## Handles JSON schema version upgrades and field renames
## Add aliases here when fields are renamed — no other code changes needed

const CURRENT_VERSION: int = 1

# Field alias map: if JSON uses an old name it is automatically remapped to the new name
# Format: "old_field_name" -> "new_field_name"
# Example: to rename atk to attack, add "atk": "attack" here
const STAT_ALIASES: Dictionary = {
	# "atk": "attack",  # example (disabled)
}


static func migrate(raw: Dictionary) -> Dictionary:
	var data: Dictionary = raw.duplicate(true)

	# Resolve field aliases within base_stats
	if data.has("base_stats"):
		data["base_stats"] = _resolve_aliases(data["base_stats"], STAT_ALIASES)

	# Run version migrations in sequence
	var version: int = data.get("schema_version", 0)
	data = _migrate_to_current(data, version)
	data["schema_version"] = CURRENT_VERSION

	return data


static func _resolve_aliases(stats: Dictionary, aliases: Dictionary) -> Dictionary:
	var resolved: Dictionary = stats.duplicate()
	for old_key: String in aliases:
		var new_key: String = aliases[old_key]
		# If old key exists and new key does not, remap it
		if resolved.has(old_key) and not resolved.has(new_key):
			resolved[new_key] = resolved[old_key]
			resolved.erase(old_key)
	return resolved


static func _migrate_to_current(data: Dictionary, from_version: int) -> Dictionary:
	## Add one if-block per version upgrade here
	## Example:
	# if from_version < 1:
	#     data = _migrate_v0_to_v1(data)
	return data
