class_name AssassinCat
extends BaseCat

## Assassin cat: high ATK & high Speed, charges ahead first

const SPEED_MULTIPLIER: float = 1.2


func _move_forward(delta: float) -> void:
	velocity.x = data.speed * facing_direction * SPEED_MULTIPLIER
	move_and_slide()


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"dash":
			# Dash: instantly rush toward the front rank (implement once combat system is complete)
			pass
