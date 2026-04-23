class_name SkillData
extends Resource

## Base class for skill data
## Both PassiveSkillData and ActiveSkillData extend this class

var id: String = ""
var display_name: String = ""
var description: String = ""
var skill_type: String = ""  # "passive" or "active"
var icon_path: String = ""


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("SkillData: file not found: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	return json.get_data()


static func _fill_base(skill: SkillData, data: Dictionary) -> void:
	skill.id = data.get("id", "")
	skill.display_name = data.get("display_name", "")
	skill.description = data.get("description", "")
	skill.skill_type = data.get("skill_type", "")
	skill.icon_path = data.get("icon_path", "")
