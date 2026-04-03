class_name TankCat
extends BaseCat

## 坦克貓：高 HP & 高 Weight，撞牆硬直減少

func get_wall_stagger_time() -> float:
	# 撞牆硬直只有一般的一半
	return CatStats.WALL_STAGGER_TIME * 0.5


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"damage":
			# 盾擊：對前排敵人造成額外傷害（戰鬥系統完成後實作）
			pass
