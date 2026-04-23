class_name PassiveSkillData
extends SkillData

## Passive skill data
## Takes effect at battle start; can buff allies or debuff enemies

# Scope: "team" (all allies) or "enemy" (all enemies)
var scope: String = "team"

## effects format:
## [{ "stat": "cooldown", "modifier_type": "percent", "value": -10 }]
## modifier_type is either "flat" (fixed amount) or "percent" (percentage)
var effects: Array = []


static func from_json_file(path: String) -> PassiveSkillData:
	var data := _load_json(path)
	if data.is_empty():
		return null
	return _from_dict(data)


static func _from_dict(data: Dictionary) -> PassiveSkillData:
	var skill := PassiveSkillData.new()
	_fill_base(skill, data)
	skill.skill_type = "passive"
	skill.scope = data.get("scope", "team")
	skill.effects = data.get("effects", [])
	return skill
