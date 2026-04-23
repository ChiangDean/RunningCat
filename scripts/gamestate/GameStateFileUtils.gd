class_name GameStateFileUtils

## General static file utilities: JSON loading, file deletion, timestamp strings


## Loads and parses a JSON file; returns an empty Dictionary on failure
static func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameStateFileUtils: cannot open " + path)
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("GameStateFileUtils: JSON parse failed " + path)
		return {}
	file.close()
	return json.get_data()


## Deletes the file at the given path if it exists
static func delete_file_if_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute_path)


## Deletes all non-directory files in the specified directory
static func delete_files_in_directory(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	while true:
		var entry_name := directory.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == ".." or directory.current_is_dir():
			continue
		directory.remove(entry_name)
	directory.list_dir_end()


## Returns the current time as an ISO 8601 string (UTC)
static func now_string() -> String:
	var t := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		t.year, t.month, t.day, t.hour, t.minute, t.second
	]
