class_name ElementalCat
extends BaseCat

## 元素貓：附加火/水/木元素效果，利用相剋策略

var element: String = "fire"  # "fire", "water", "wood"


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"element_burst":
			# 元素爆發：附加元素狀態效果（戰鬥系統完成後實作）
			pass
