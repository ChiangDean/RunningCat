class_name BaseCat
extends CharacterBody2D

## Base class for all cats
## Subclasses customise behaviour by overriding specific methods; do not modify this file

# ── Signals ────────────────────────────────────────────
signal died(cat: BaseCat)
signal hp_changed(current: int, maximum: int)

# ── Data references ───────────────────────────────────
var data: CatData
var team: String = "player"      # "player" or "enemy"
var facing_direction: int = 1    # 1 = right, -1 = left

# ── Runtime state ──────────────────────────────────────
var current_hp: int = 0
var is_staggered: bool = false
var stagger_timer: float = 0.0
var is_alive: bool = true

## Active skill runtime states
## Format: [{ "skill": ActiveSkillData, "timer": float }]
var _active_skill_states: Array = []


# ── Initialisation ─────────────────────────────────────

func setup(cat_data: CatData, cat_team: String, skill_states: Array = []) -> void:
	data = cat_data
	team = cat_team
	current_hp = data.max_hp
	facing_direction = 1 if team == "player" else -1
	_active_skill_states = skill_states


# ── Main loop ─────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_process_stagger(delta)
	_process_active_skills(delta)
	if not is_staggered:
		_move_forward(delta)


## Advances the cat each frame; subclasses may override (e.g. assassin speed boost)
func _move_forward(delta: float) -> void:
	velocity.x = data.speed * facing_direction
	move_and_slide()


func _process_stagger(delta: float) -> void:
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			is_staggered = false
			stagger_timer = 0.0


func _process_active_skills(delta: float) -> void:
	for state: Dictionary in _active_skill_states:
		state["timer"] -= delta
		if state["timer"] <= 0.0:
			_trigger_active_skill(state["skill"])
			state["timer"] = state["skill"].cooldown


## Triggers an active skill; subclasses override to implement the effect
func _trigger_active_skill(_skill: ActiveSkillData) -> void:
	pass


# ── Combat methods ────────────────────────────────────

## Takes damage; ignore_def is a future parameter to bypass defence (defaults to 0)
func take_damage(atk: float, ignore_def: float = 0.0) -> void:
	if not is_alive:
		return
	var dmg: float = CatStats.calc_damage(atk, data.defense, ignore_def)
	current_hp -= int(dmg)
	emit_signal("hp_changed", current_hp, data.max_hp)
	if current_hp <= 0:
		_die()


## Called on collision with an enemy; subclasses may override (e.g. defensive cat adds reflect damage)
func on_collision_with(other: BaseCat) -> void:
	if is_staggered or not is_alive:
		return
	take_damage(other.data.atk)
	var knockback: float = CatStats.calc_knockback_distance(other.data.weight, data.weight)
	_apply_knockback(knockback)


func _apply_knockback(distance: float) -> void:
	is_staggered = true
	stagger_timer = get_stagger_time()
	position.x -= facing_direction * distance


## Called when the cat bounces off a wall; subclasses may override (e.g. tank cat reduces stagger)
func on_wall_bounce() -> void:
	is_staggered = true
	stagger_timer = get_wall_stagger_time()
	facing_direction *= -1


# ── Stagger duration (subclasses may override) ─────────

func get_stagger_time() -> float:
	return CatStats.STAGGER_TIME


func get_wall_stagger_time() -> float:
	return CatStats.WALL_STAGGER_TIME


# ── Death ──────────────────────────────────────────────

func _die() -> void:
	is_alive = false
	emit_signal("died", self)
	_play_death_animation()


## Death animation: projectile arc off screen; subclasses may override to customise
func _play_death_animation() -> void:
	queue_free()
