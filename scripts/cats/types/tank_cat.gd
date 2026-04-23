class_name TankCat
extends BaseCat

## Tank cat: high HP & high Weight, reduced wall stagger

func get_wall_stagger_time() -> float:
	# Wall stagger is half the normal duration
	return CatStats.WALL_STAGGER_TIME * 0.5


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"damage":
			# Shield bash: deal extra damage to the front-rank enemy (implement once combat system is complete)
			pass
