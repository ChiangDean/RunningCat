class_name ElementalCat
extends BaseCat

## Elemental cat: applies fire/water/wood elemental effects using type-advantage strategy

var element: String = "fire"  # "fire", "water", "wood"


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"element_burst":
			# Elemental burst: applies elemental status effect (implement once combat system is complete)
			pass
