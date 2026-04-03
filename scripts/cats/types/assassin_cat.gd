class_name AssassinCat
extends BaseCat

## 刺客貓：高 ATK & 高 Speed，先手衝刺

const SPEED_MULTIPLIER: float = 1.2


func _move_forward(delta: float) -> void:
	velocity.x = data.speed * facing_direction * SPEED_MULTIPLIER
	move_and_slide()


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"dash":
			# 衝刺：瞬間加速衝向前排（戰鬥系統完成後實作）
			pass
