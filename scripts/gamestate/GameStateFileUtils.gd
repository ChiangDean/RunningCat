class_name GameStateFileUtils

## 通用靜態檔案工具：JSON 載入、檔案刪除、時間字串


## 載入並解析 JSON 檔案，失敗時回傳空 Dictionary
static func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameStateFileUtils: 無法開啟 " + path)
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("GameStateFileUtils: JSON 解析失敗 " + path)
		return {}
	file.close()
	return json.get_data()


## 刪除指定路徑的檔案（若存在）
static func delete_file_if_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute_path)


## 刪除指定目錄下的所有非目錄檔案
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


## 回傳目前時間的 ISO 8601 字串（UTC）
static func now_string() -> String:
	var t := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		t.year, t.month, t.day, t.hour, t.minute, t.second
	]
