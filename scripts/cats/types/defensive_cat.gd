class_name DefensiveCat
extends BaseCat

## Defensive cat: high DEF & medium Weight, reflects damage on collision

const REFLECT_RATIO: float = 0.3  # reflects 30% of damage


func on_collision_with(other: BaseCat) -> void:
	if is_staggered or not is_alive:
		return
	# take incoming damage first
	take_damage(other.data.atk)
	# reflect damage to the attacker
	var reflect_dmg: float = data.defense * REFLECT_RATIO
	other.take_damage(reflect_dmg)
	# apply knockback
	var knockback: float = CatStats.calc_knockback_distance(other.data.weight, data.weight)
	_apply_knockback(knockback)
