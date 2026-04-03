class_name ActiveSkillData
extends SkillData

## 主動技能資料
## 每隔 cooldown 秒自動發動，玩家可設定首次發動時間（0~9 秒）

var cooldown: float = 5.0
var effect_type: String = ""   # "damage", "buff", "debuff", "knockback" ...
var effect_value: float = 0.0
# 作用目標："enemy_front"（敵方前排）、"team"（我方全體）、"self" 等
var target_scope: String = "enemy_front"


static func from_json_file(path: String) -> ActiveSkillData:
	var data := _load_json(path)
	if data.is_empty():
		return null
	return _from_dict(data)


static func _from_dict(data: Dictionary) -> ActiveSkillData:
	var skill := ActiveSkillData.new()
	_fill_base(skill, data)
	skill.skill_type = "active"
	skill.cooldown = data.get("cooldown", 5.0)
	skill.effect_type = data.get("effect_type", "")
	skill.effect_value = data.get("effect_value", 0.0)
	skill.target_scope = data.get("target_scope", "enemy_front")
	return skill
