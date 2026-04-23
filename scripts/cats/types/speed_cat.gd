class_name SpeedCat
extends BaseCat

## Speed cat: extremely fast, charges first, short-range penetration

const SPEED_MULTIPLIER: float = 1.5


func _move_forward(delta: float) -> void:
	velocity.x = data.speed * facing_direction * SPEED_MULTIPLIER
	move_and_slide()


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"penetrate":
			# Penetrate dash: pass through the front rank at short range (implement once combat system is complete)
			pass
