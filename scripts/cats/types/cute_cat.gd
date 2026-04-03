class_name CuteCat
extends BaseCat

## 趣味萌寵貓：高 HP 低 ATK，趣味技能干擾敵人

func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"bubble":
			# 吐泡泡：干擾敵人移動（戰鬥系統完成後實作）
			pass
