class_name FlyingCat
extends BaseCat

## 飛行貓：可跳過敵方前排，直接撞後排

func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"jump":
			# 跳躍：飛越前排，直接命中後排（戰鬥系統完成後實作）
			pass
