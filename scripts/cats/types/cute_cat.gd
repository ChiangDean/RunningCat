class_name CuteCat
extends BaseCat

## Cute cat: high HP low ATK, novelty skills that disrupt enemies

func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"bubble":
			# Bubble: disrupts enemy movement (implement once combat system is complete)
			pass
