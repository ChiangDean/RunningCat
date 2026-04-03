class_name PassiveSkillData
extends SkillData

## 被動技能資料
## 戰鬥開始即生效，可對全隊 buff 或對敵方 debuff

# 作用範圍："team"（我方全體）或 "enemy"（敵方全體）
var scope: String = "team"

## effects 格式：
## [{ "stat": "cooldown", "modifier_type": "percent", "value": -10 }]
## modifier_type 可為 "flat"（固定值）或 "percent"（百分比）
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
