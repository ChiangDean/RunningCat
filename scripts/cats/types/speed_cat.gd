class_name SpeedCat
extends BaseCat

## 高速貓：極高速度，先手衝撞，短距離穿透

const SPEED_MULTIPLIER: float = 1.5


func _move_forward(delta: float) -> void:
	velocity.x = data.speed * facing_direction * SPEED_MULTIPLIER
	move_and_slide()


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"penetrate":
			# 穿透衝刺：短距離穿過前排（戰鬥系統完成後實作）
			pass
