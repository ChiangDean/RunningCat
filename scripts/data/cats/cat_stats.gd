class_name CatStats
extends RefCounted

## Pure calculation layer — all stat formulas live here
## No scene-node dependencies, suitable for headless battle simulation

# Knockback distance clamp range
const MIN_KNOCKBACK: float = 30.0
const MAX_KNOCKBACK: float = 300.0

# Stagger duration constants
const STAGGER_TIME: float = 0.2
const WALL_STAGGER_TIME: float = 0.3
const KNOCKBACK_RECOVERY_ACCEL_TIME: float = 1.0


## DEF damage-reduction formula: DEF / (DEF + 100)
## DEF=0 → 0%, DEF=100 → 50%, DEF=300 → 75%; asymptotically approaches but never reaches 100%
static func calc_def_reduction(defense: float) -> float:
	if defense <= 0.0:
		return 0.0
	return defense / (defense + 100.0)


## Compute final damage after defence reduction
## ignore_def: flat DEF penetration (future stat), directly reduces the target's effective DEF
static func calc_damage(atk: float, defense: float, ignore_def: float = 0.0) -> float:
	var effective_def: float = maxf(0.0, defense - ignore_def)
	var reduction: float = calc_def_reduction(effective_def)
	return maxf(1.0, atk * (1.0 - reduction))


## Compute knockback distance
## Heavier attacker → greater knockback; clamped to [MIN_KNOCKBACK, MAX_KNOCKBACK]
static func calc_knockback_distance(attacker_weight: float, target_weight: float) -> float:
	var weight_diff: float = attacker_weight - target_weight
	var base_knockback: float = 200.0 + weight_diff * 0.5
	return clampf(base_knockback, MIN_KNOCKBACK, MAX_KNOCKBACK)
