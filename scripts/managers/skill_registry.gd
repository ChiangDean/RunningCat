class_name SkillRegistry
extends Node

## 全域技能資料庫（Autoload）
## 從 JSON 資料夾自動載入所有技能，提供 id → Dictionary 查詢
## UI 使用：get_skill(id)、get_all_passive()、get_all_active()

const PASSIVE_PATH: String = "res://data/default/skills/passive/"
const ACTIVE_PATH: String  = "res://data/default/skills/active/"

var _passive: Dictionary = {}   # id → Dictionary
var _active: Dictionary = {}    # id → Dictionary


func _ready() -> void:
	_load_dir(PASSIVE_PATH, _passive)
	_load_dir(ACTIVE_PATH,  _active)


func _load_dir(dir_path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("SkillRegistry: 資料夾不存在：" + dir_path)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var d := _read_json(dir_path + fname)
			if not d.is_empty():
				target[d.get("id", fname.get_basename())] = d
		fname = dir.get_next()


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	var data = json.get_data()
	if data is Dictionary:
		return data
	return {}


## 取得單一技能（被動或主動皆可）
func get_skill(id: String) -> Dictionary:
	if _passive.has(id):
		return _passive[id]
	if _active.has(id):
		return _active[id]
	return {}


func get_passive(id: String) -> Dictionary:
	return _passive.get(id, {})


func get_active(id: String) -> Dictionary:
	return _active.get(id, {})


func get_all_passive() -> Dictionary:
	return _passive


func get_all_active() -> Dictionary:
	return _active
