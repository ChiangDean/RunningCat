class_name SkillRegistry
extends Node

## 技能註冊中心，啟動時自動掃描並載入所有技能 JSON

const PASSIVE_PATH: String = "res://data/default/skills/passive/"
const ACTIVE_PATH: String = "res://data/default/skills/active/"

var _passive_skills: Dictionary = {}
var _active_skills: Dictionary = {}


func _ready() -> void:
	_load_all_skills()


func _load_all_skills() -> void:
	_load_from_dir(PASSIVE_PATH, "passive")
	_load_from_dir(ACTIVE_PATH, "active")


func _load_from_dir(path: String, skill_type: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("SkillRegistry: 資料夾不存在：" + path)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path: String = path + file_name
			if skill_type == "passive":
				var skill := PassiveSkillData.from_json_file(full_path)
				if skill:
					_passive_skills[skill.id] = skill
			else:
				var skill := ActiveSkillData.from_json_file(full_path)
				if skill:
					_active_skills[skill.id] = skill
		file_name = dir.get_next()


func get_passive(skill_id: String) -> PassiveSkillData:
	return _passive_skills.get(skill_id, null)


func get_active(skill_id: String) -> ActiveSkillData:
	return _active_skills.get(skill_id, null)
