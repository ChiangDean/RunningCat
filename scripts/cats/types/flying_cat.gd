class_name FlyingCat
extends BaseCat

## Flying cat: leaps over the enemy front rank to strike the back row

func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"jump":
			# Jump: leap over the front rank to hit back-row enemies (implement once combat system is complete)
			pass
