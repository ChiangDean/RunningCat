class_name BattleEvent
extends RefCounted

## Battle event data produced by the simulator, consumed by the visual layer

enum Type {
	SPAWN,          # Cat enters the field
	COLLISION,      # Collision (includes damage and knockback)
	HP_UPDATE,      # HP update (skill damage)
	SKILL_ACTIVATE, # Active skill triggered
	BUFF_APPLY,     # Buff / Debuff applied (for UI duration display)
	WALL_COUNTER,   # Attacker bounces back after hitting a wall-staggered target
	CAT_DIE,        # Cat dies
	BATTLE_END,     # Battle ends
}

var type: Type
var timestamp: float = 0.0

# General fields
var cat_id: int = -1
var team: String = ""

# SPAWN / COLLISION position
var pos_x: float = 0.0

# HP-related
var current_hp: int = 0
var max_hp: int = 0

# COLLISION: knockback distance (positive = right, negative = left)
var knockback: float = 0.0
var skip_recovery_accel: bool = false

# SKILL_ACTIVATE
var skill_id: String = ""

# BUFF_APPLY: duration in seconds, used by UI to display status border.
# WALL_COUNTER: duration for the arc and stagger timer.
var buff_duration: float = 0.0

# WALL_COUNTER visual arc height
var arc_height: float = 0.0

# BATTLE_END result: "WIN" / "LOSE" / "TIMEOUT"
var result: String = ""

# ── Factory methods ───────────────────────────────

static func spawn(time: float, id: int, team_name: String, x: float, hp: int, mhp: int) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.SPAWN
	e.timestamp = time
	e.cat_id = id
	e.team = team_name
	e.pos_x = x
	e.current_hp = hp
	e.max_hp = mhp
	return e

static func collision(time: float, id: int, x: float, hp: int, kb: float, skip_accel: bool = false) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.COLLISION
	e.timestamp = time
	e.cat_id = id
	e.pos_x = x
	e.current_hp = hp
	e.knockback = kb
	e.skip_recovery_accel = skip_accel
	return e

static func hp_update(time: float, id: int, hp: int, mhp: int) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.HP_UPDATE
	e.timestamp = time
	e.cat_id = id
	e.current_hp = hp
	e.max_hp = mhp
	return e

static func skill_activate(time: float, id: int, sid: String) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.SKILL_ACTIVATE
	e.timestamp = time
	e.cat_id = id
	e.skill_id = sid
	return e

static func buff_apply(time: float, id: int, duration: float) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.BUFF_APPLY
	e.timestamp = time
	e.cat_id = id
	e.buff_duration = duration
	return e

static func wall_counter(time: float, id: int, x: float, duration: float, height: float) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.WALL_COUNTER
	e.timestamp = time
	e.cat_id = id
	e.pos_x = x
	e.buff_duration = duration
	e.arc_height = height
	return e

static func cat_die(time: float, id: int, team_name: String, x: float) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.CAT_DIE
	e.timestamp = time
	e.cat_id = id
	e.team = team_name
	e.pos_x = x
	return e

static func battle_end(time: float, res: String) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.BATTLE_END
	e.timestamp = time
	e.result = res
	return e
