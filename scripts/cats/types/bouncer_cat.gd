class_name BouncerCat
extends BaseCat

## Bouncer cat: uses walls and enemy positioning to deal chain damage

func on_wall_bounce() -> void:
	# No stagger on wall bounce — immediately reverses direction and continues attacking
	facing_direction *= -1


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"chain_bounce":
			# Chain bounce: hit multiple enemies in sequence (implement once combat system is complete)
			pass
