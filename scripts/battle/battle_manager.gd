class_name BattleManager
extends Node

const CAT_COLLISION_SFX_1 := preload("res://assets/audio/sfx/battle/cat_collision_v1.mp3")
const CAT_COLLISION_SFX_2 := preload("res://assets/audio/sfx/battle/cat_collision_v2.mp3")
const CAT_SKILL_SFX := preload("res://assets/audio/sfx/battle/cat_skill_v1.mp3")
const CAT_DIED_SFX_1 := preload("res://assets/audio/sfx/battle/cat_died_v1.mp3")
const CAT_DIED_SFX_2 := preload("res://assets/audio/sfx/battle/cat_died_v2.mp3")
const CAT_DIED_SFX_3 := preload("res://assets/audio/sfx/battle/cat_died_v3.mp3")
const CAT_DIED_SFX_4 := preload("res://assets/audio/sfx/battle/cat_died_v4.mp3")
const CAT_DIED_SFXS := [
	CAT_DIED_SFX_1,
	CAT_DIED_SFX_2,
	CAT_DIED_SFX_3,
	CAT_DIED_SFX_4,
]
const SKILL_SLOT_DISPLAY_CAP: int = 10
const BATTLE_WALL_LEFT: float = 20.0
const BATTLE_WALL_RIGHT: float = 700.0
const CAT_HALF_W: float = 48.0
const PLAYER_FRONT_START_X: float = 220.0
const ENEMY_FRONT_START_X: float = 500.0
const TEAM_ROW_SPACING: float = 60.0
const BASE_CRIT_DAMAGE_MULT: float = 1.5
const WALL_COUNTER_DISTANCE_MULT: float = 2.0
const WALL_COUNTER_MIN_RETREAT_X: float = 100.0
const WALL_COUNTER_HEIGHT_MULT: float = 2.0
const WALL_COUNTER_MIN_ARC_HEIGHT: float = 200.0
const WALL_COUNTER_MAX_ARC_HEIGHT: float = 400.0
const WALL_COUNTER_DURATION: float = 0.6

signal battle_finished(result: String)
var _events: Array = []
var _event_idx: int = 0

var _sim_time: float = 0.0
var _speed_mult: float = 1.0
var _is_running: bool = false
var _is_finished: bool = false
var _collision_sfx_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _last_collision_sfx_time: float = -1.0

var _cat_nodes: Dictionary = {}
var _cat_data_by_instance_id: Dictionary = {}
var _cat_runtime: Dictionary = {}
var _cat_speeds: Dictionary = {}
var _cat_stagger_timers: Dictionary = {}
var _cat_knockback_timers: Dictionary = {}
var _cat_accel_timers: Dictionary = {}
var _cat_skip_recovery_accel: Dictionary = {}
var _pending_recycled_cats: Dictionary = {}
var _pending_recycle_count: int = 0

var _player_team_node: Node2D
var _enemy_team_node: Node2D
var _timer_label: Label

var _player_cats: Array = []
var _enemy_cats: Array = []

var _player_skill_slots: Array = []
var _enemy_skill_slots: Array = []
var _skill_bar: Control = null
var _skill_bar_filter: String = "scoop"
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(_events_param: Array, player_cats: Array, enemy_cats: Array,
		player_node: Node2D, enemy_node: Node2D, timer_lbl: Label,
		skill_bar: Control = null) -> void:
	_events = []
	_player_cats = player_cats
	_enemy_cats = enemy_cats
	_player_team_node = player_node
	_enemy_team_node = enemy_node
	_timer_label = timer_lbl
	_skill_bar = skill_bar
	_cat_nodes.clear()
	_cat_data_by_instance_id.clear()
	_cat_runtime.clear()
	_cat_speeds.clear()
	_cat_stagger_timers.clear()
	_cat_knockback_timers.clear()
	_cat_accel_timers.clear()
	_cat_skip_recovery_accel.clear()
	_pending_recycled_cats.clear()
	_pending_recycle_count = 0
	_player_skill_slots.clear()
	_enemy_skill_slots.clear()
	_event_idx = 0
	_sim_time = 0.0
	_is_finished = false
	_is_running = true
	_collision_sfx_rng.randomize()
	_rng.randomize()
	_last_collision_sfx_time = -1.0
	for i in range(_player_cats.size()):
		_cat_data_by_instance_id[i] = _player_cats[i]
	for i in range(_enemy_cats.size()):
		_cat_data_by_instance_id[_player_cats.size() + i] = _enemy_cats[i]
	_init_skill_slots()
	_refresh_skill_bar_display()
	_spawn_initial_cat_nodes()
	_apply_all_passives()


func prime_initial_spawn_state() -> void:
	while _event_idx < _events.size():
		var ev: BattleEvent = _events[_event_idx]
		if ev.timestamp > 0.0:
			break
		if ev.type != BattleEvent.Type.SPAWN:
			break
		_apply_event(ev)
		_event_idx += 1


func _ensure_initial_spawn_nodes() -> void:
	for ev_variant: Variant in _events:
		if not (ev_variant is BattleEvent):
			continue
		var ev: BattleEvent = ev_variant
		if ev.timestamp > 0.0:
			break
		if ev.type != BattleEvent.Type.SPAWN:
			continue
		_spawn_cat_node(ev)
	_update_spawn_event_index()


func _update_spawn_event_index() -> void:
	while _event_idx < _events.size():
		var ev: BattleEvent = _events[_event_idx]
		if ev.timestamp > 0.0:
			break
		if ev.type != BattleEvent.Type.SPAWN:
			break
		_event_idx += 1


func _spawn_initial_cat_nodes() -> void:
	for i in range(_player_cats.size()):
		var cat_data: CatData = _player_cats[i]
		_spawn_runtime_cat(i, "player", cat_data, PLAYER_FRONT_START_X - float(i) * TEAM_ROW_SPACING)
	for i in range(_enemy_cats.size()):
		var cat_data: CatData = _enemy_cats[i]
		var cat_id: int = _player_cats.size() + i
		_spawn_runtime_cat(cat_id, "enemy", cat_data, ENEMY_FRONT_START_X + float(i) * TEAM_ROW_SPACING)


func _spawn_runtime_cat(cat_id: int, team_name: String, cat_data: CatData, pos_x: float) -> void:
	if cat_data == null:
		return
	var node: CatNode = CatNode.new()
	var parent: Node2D = _player_team_node if team_name == "player" else _enemy_team_node
	parent.add_child(node)
	node.setup(cat_id, team_name, cat_data.display_name, cat_data.max_hp, cat_data.id)
	node.position = Vector2(pos_x, 0.0)
	node.play_run()
	_cat_nodes[cat_id] = node
	_cat_speeds[cat_id] = cat_data.speed
	_cat_stagger_timers[cat_id] = 0.0
	_cat_accel_timers[cat_id] = 0.0
	_cat_runtime[cat_id] = {
		"team": team_name,
		"data": cat_data,
		"max_hp": cat_data.max_hp,
		"current_hp": cat_data.max_hp,
		"atk": float(cat_data.atk),
		"defense": float(cat_data.defense),
		"speed": float(cat_data.speed),
		"weight": float(cat_data.weight),
		"damage_reduction": 0.0,
		"crit_rate": 0.0,
		"crit_damage_bonus": 0.0,
		"reflect": 0.0,
		"buffs": [],
	}
	_update_skill_slot_spawn_state(cat_id, cat_data.max_hp, cat_data.max_hp)


func pause_battle() -> void:
	_is_running = false


func resume_battle() -> void:
	if _is_finished:
		return
	_is_running = true


func set_speed(mult: float) -> void:
	_speed_mult = mult


func set_skill_bar_filter(filter_mode: String) -> void:
	_skill_bar_filter = filter_mode
	_refresh_skill_bar_display()


func skip_to_end() -> void:
	_is_running = false
	_is_finished = true
	battle_finished.emit(_get_current_result())


func _process(delta: float) -> void:
	if not _is_running or _is_finished:
		return
	_sim_time += delta * _speed_mult

	if _timer_label:
		var remaining: float = maxf(0.0, 60.0 - _sim_time)
		_timer_label.text = "%.1f" % remaining

	_update_cat_movement(delta)
	_check_runtime_collision()
	_update_runtime_skills(delta)
	_tick_runtime_buffs(delta)
	_check_runtime_battle_end()
	_refresh_skill_bar_display()


func _apply_event(ev: BattleEvent) -> void:
	match ev.type:
		BattleEvent.Type.SPAWN:
			_spawn_cat_node(ev)
		BattleEvent.Type.COLLISION:
			_on_collision(ev)
		BattleEvent.Type.HP_UPDATE:
			_on_hp_update(ev)
		BattleEvent.Type.SKILL_ACTIVATE:
			_on_skill_activate(ev)
		BattleEvent.Type.BUFF_APPLY:
			_on_buff_apply(ev)
		BattleEvent.Type.WALL_COUNTER:
			_on_wall_counter(ev)
		BattleEvent.Type.CAT_DIE:
			_on_cat_die(ev)
		BattleEvent.Type.BATTLE_END:
			_on_battle_end(ev)


func _spawn_cat_node(ev: BattleEvent) -> void:
	if _cat_nodes.has(ev.cat_id):
		return
	var cat_data: CatData = _find_cat_data(ev.cat_id, ev.team)
	if cat_data == null:
		return
	var node: CatNode = CatNode.new()
	var parent: Node2D = _player_team_node if ev.team == "player" else _enemy_team_node
	parent.add_child(node)
	node.setup(ev.cat_id, ev.team, cat_data.display_name, ev.max_hp, cat_data.id)
	node.position = Vector2(ev.pos_x, 0.0)
	node.play_run()
	_cat_nodes[ev.cat_id] = node
	_cat_speeds[ev.cat_id] = cat_data.speed
	_cat_stagger_timers[ev.cat_id] = 0.0
	_cat_accel_timers[ev.cat_id] = 0.0
	_update_skill_slot_spawn_state(ev.cat_id, ev.current_hp, ev.max_hp)


func _on_collision(ev: BattleEvent) -> void:
	var node: CatNode = _get_cat_node(ev.cat_id)
	if node == null:
		return
	var prev_hp: int = node.current_hp
	node.update_hp(ev.current_hp)
	var damage: int = max(0, prev_hp - ev.current_hp)
	if damage > 0:
		node.show_damage_number(damage)
	_update_skill_slot_hp(ev.cat_id, ev.current_hp)
	var speed: float = float(_cat_speeds.get(ev.cat_id, 80.0))
	var knockback_distance: float = absf(ev.pos_x - node.position.x)
	var knockback_duration: float = CatStats.calc_knockback_deceleration_time(
		knockback_distance,
		speed
	)
	node.move_to(ev.pos_x, knockback_duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
	node.play_collision(ev.knockback)
	_play_collision_sfx(ev.timestamp)
	var is_near_wall: bool = (
		ev.pos_x <= BATTLE_WALL_LEFT + CAT_HALF_W or
		ev.pos_x >= BATTLE_WALL_RIGHT - CAT_HALF_W
	)
	_cat_stagger_timers[ev.cat_id] = CatStats.STAGGER_TIME + (CatStats.WALL_STAGGER_TIME if is_near_wall else 0.0)
	_cat_knockback_timers[ev.cat_id] = knockback_duration
	_cat_accel_timers[ev.cat_id] = 0.0
	_cat_skip_recovery_accel[ev.cat_id] = ev.skip_recovery_accel
	node.play_stagger()


func _on_hp_update(ev: BattleEvent) -> void:
	var node: CatNode = _get_cat_node(ev.cat_id)
	if node == null:
		return
	var prev_hp: int = node.current_hp
	node.update_hp(ev.current_hp)
	var damage: int = max(0, prev_hp - ev.current_hp)
	if damage > 0:
		node.show_damage_number(damage)
	_update_skill_slot_hp(ev.cat_id, ev.current_hp)


func _on_skill_activate(ev: BattleEvent) -> void:
	var node: CatNode = _get_cat_node(ev.cat_id)
	if node:
		node.play_skill()
		node.flash_skill()
		_play_audio_sfx(CAT_SKILL_SFX, -6.0, 1.0)
	_reset_skill_slot_cooldown(ev.cat_id)


func _on_buff_apply(ev: BattleEvent) -> void:
	_update_skill_slot_buff(ev.cat_id, ev.buff_duration)


func _on_wall_counter(ev: BattleEvent) -> void:
	var node: CatNode = _get_cat_node(ev.cat_id)
	if node == null:
		return
	node.play_wall_counter(ev.pos_x, ev.arc_height, ev.buff_duration)
	_cat_stagger_timers[ev.cat_id] = ev.buff_duration
	_cat_knockback_timers[ev.cat_id] = ev.buff_duration
	_cat_accel_timers[ev.cat_id] = 0.0
	_cat_skip_recovery_accel[ev.cat_id] = false


func _on_cat_die(ev: BattleEvent) -> void:
	var node: CatNode = _get_cat_node(ev.cat_id)
	if node:
		node.move_to(ev.pos_x)
		node.play_death()
		_track_cat_recycle(ev.cat_id)
		var died_sfx_index: int = _collision_sfx_rng.randi_range(0, CAT_DIED_SFXS.size() - 1)
		var died_sfx: AudioStream = CAT_DIED_SFXS[died_sfx_index]
		_play_audio_sfx(died_sfx, -4.0, 1.0)
	_mark_skill_slot_dead(ev.cat_id)
	_remove_cat_runtime_state(ev.cat_id)


func _on_battle_end(ev: BattleEvent) -> void:
	_is_running = false
	_is_finished = true
	battle_finished.emit(ev.result)


func _update_cat_movement(delta: float) -> void:
	var scaled_delta: float = delta * _speed_mult
	var cat_ids: Array = _cat_nodes.keys()
	for id_variant: Variant in cat_ids:
		var id: int = int(id_variant)
		var node: CatNode = _get_cat_node(id)
		if node == null:
			continue
		if _cat_stagger_timers.has(id):
			var previous_stagger_timer: float = float(_cat_stagger_timers[id])
			_cat_stagger_timers[id] = maxf(0.0, previous_stagger_timer - scaled_delta)
			if previous_stagger_timer > 0.0:
				if float(_cat_stagger_timers[id]) <= 0.0:
					_cat_stagger_timers.erase(id)
		if _cat_knockback_timers.has(id):
			var previous_knockback_timer: float = float(_cat_knockback_timers[id])
			_cat_knockback_timers[id] = maxf(0.0, previous_knockback_timer - scaled_delta)
			if float(_cat_knockback_timers[id]) > 0.0:
				continue
			if previous_knockback_timer > 0.0:
				var skip_recovery_accel: bool = bool(_cat_skip_recovery_accel.get(id, false))
				_cat_accel_timers[id] = 0.0 if skip_recovery_accel else CatStats.KNOCKBACK_RECOVERY_ACCEL_TIME
				_cat_skip_recovery_accel.erase(id)
				_cat_knockback_timers.erase(id)
		var speed: float = float(_cat_speeds.get(id, 80.0))
		var speed_scale: float = 1.0
		if _cat_accel_timers.has(id) and float(_cat_accel_timers[id]) > 0.0:
			speed_scale = clampf(
				(CatStats.KNOCKBACK_RECOVERY_ACCEL_TIME - float(_cat_accel_timers[id])) /
						CatStats.KNOCKBACK_RECOVERY_ACCEL_TIME,
				0.0,
				1.0
			)
			_cat_accel_timers[id] = maxf(0.0, float(_cat_accel_timers[id]) - scaled_delta)
		var dir: float = 1.0 if node.team == "player" else -1.0
		node.position.x = clampf(
			node.position.x + dir * speed * speed_scale * scaled_delta,
			BATTLE_WALL_LEFT + CAT_HALF_W,
			BATTLE_WALL_RIGHT - CAT_HALF_W
		)
		node.play_run()


func _check_runtime_collision() -> void:
	var p_front: CatNode = _get_front_runtime_node("player")
	var e_front: CatNode = _get_front_runtime_node("enemy")
	if p_front == null or e_front == null:
		return
	if absf(p_front.position.x - e_front.position.x) > CAT_HALF_W * 2.0:
		return
	var p_staggered: bool = _is_cat_staggered(p_front.instance_id)
	var e_staggered: bool = _is_cat_staggered(e_front.instance_id)
	if p_staggered and e_staggered:
		return
	_handle_runtime_collision(p_front, e_front)


func _handle_runtime_collision(p_node: CatNode, e_node: CatNode) -> void:
	var p_id: int = p_node.instance_id
	var e_id: int = e_node.instance_id
	var p_runtime: Dictionary = _cat_runtime.get(p_id, {})
	var e_runtime: Dictionary = _cat_runtime.get(e_id, {})
	if p_runtime.is_empty() or e_runtime.is_empty():
		return

	var p_staggered: bool = _is_cat_staggered(p_id)
	var e_staggered: bool = _is_cat_staggered(e_id)
	var p_damage: int = 0
	var e_damage: int = 0
	if not p_staggered:
		e_damage = _calc_runtime_attack_damage(p_id, e_id, _get_runtime_atk(p_id))
		_apply_runtime_damage(e_id, e_damage)
	if not e_staggered:
		p_damage = _calc_runtime_attack_damage(e_id, p_id, _get_runtime_atk(e_id))
		_apply_runtime_damage(p_id, p_damage)
	if e_damage > 0:
		var reflect_to_p: int = int(float(e_damage) * _get_runtime_reflect(e_id))
		_apply_runtime_damage(p_id, reflect_to_p)
	if p_damage > 0:
		var reflect_to_e: int = int(float(p_damage) * _get_runtime_reflect(p_id))
		_apply_runtime_damage(e_id, reflect_to_e)

	var p_weight: float = float(p_runtime.get("weight", 100.0))
	var e_weight: float = float(e_runtime.get("weight", 100.0))
	var kb_p: float = CatStats.calc_knockback_distance(e_weight, p_weight)
	var kb_e: float = CatStats.calc_knockback_distance(p_weight, e_weight)
	var contact_p_x: float = e_node.position.x - CAT_HALF_W * 2.0 - 2.0
	var contact_e_x: float = contact_p_x + CAT_HALF_W * 2.0 + 2.0
	var p_target_x: float = contact_p_x - kb_p
	var e_target_x: float = contact_e_x + kb_e
	var p_hit_wall: bool = false
	var e_hit_wall: bool = false
	var p_causes_wall_hit: bool = false
	var e_causes_wall_hit: bool = false
	if p_target_x - CAT_HALF_W <= BATTLE_WALL_LEFT:
		p_target_x = BATTLE_WALL_LEFT + CAT_HALF_W
		p_hit_wall = true
		e_causes_wall_hit = not e_staggered
	if e_target_x + CAT_HALF_W >= BATTLE_WALL_RIGHT:
		e_target_x = BATTLE_WALL_RIGHT - CAT_HALF_W
		e_hit_wall = true
		p_causes_wall_hit = not p_staggered

	_apply_runtime_knockback(p_id, p_target_x, -kb_p, p_hit_wall)
	_apply_runtime_knockback(e_id, e_target_x, kb_e, e_hit_wall)

	if p_causes_wall_hit:
		_apply_runtime_wall_counter(p_id, _get_wall_counter_target_x(p_node, kb_e), _get_wall_counter_arc_height(kb_e))
	if e_causes_wall_hit:
		_apply_runtime_wall_counter(e_id, _get_wall_counter_target_x(e_node, kb_p), _get_wall_counter_arc_height(kb_p))

	_check_runtime_death(e_id)
	_check_runtime_death(p_id)


func _apply_runtime_knockback(cat_id: int, target_x: float, knockback: float, hit_wall: bool) -> void:
	var node: CatNode = _get_cat_node(cat_id)
	if node == null:
		return
	var speed: float = float(_cat_speeds.get(cat_id, 80.0))
	var knockback_distance: float = absf(target_x - node.position.x)
	var knockback_duration: float = CatStats.calc_knockback_deceleration_time(knockback_distance, speed)
	node.move_to(target_x, knockback_duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
	node.play_collision(knockback)
	_play_collision_sfx(_sim_time)
	_cat_stagger_timers[cat_id] = maxf(
		float(_cat_stagger_timers.get(cat_id, 0.0)),
		CatStats.STAGGER_TIME + (CatStats.WALL_STAGGER_TIME if hit_wall else 0.0)
	)
	_cat_knockback_timers[cat_id] = knockback_duration
	_cat_accel_timers[cat_id] = 0.0
	_cat_skip_recovery_accel[cat_id] = hit_wall


func _apply_runtime_wall_counter(cat_id: int, target_x: float, arc_height: float) -> void:
	var node: CatNode = _get_cat_node(cat_id)
	if node == null:
		return
	node.play_wall_counter(target_x, arc_height, WALL_COUNTER_DURATION)
	_cat_stagger_timers[cat_id] = WALL_COUNTER_DURATION
	_cat_knockback_timers[cat_id] = WALL_COUNTER_DURATION
	_cat_accel_timers[cat_id] = 0.0
	_cat_skip_recovery_accel[cat_id] = false


func _get_front_runtime_node(team_name: String) -> CatNode:
	var best: CatNode = null
	for id_variant: Variant in _cat_nodes.keys():
		var cat_id: int = int(id_variant)
		var node: CatNode = _get_cat_node(cat_id)
		if node == null or node.team != team_name:
			continue
		if best == null:
			best = node
		elif team_name == "player" and node.position.x > best.position.x:
			best = node
		elif team_name == "enemy" and node.position.x < best.position.x:
			best = node
	return best


func _is_cat_staggered(cat_id: int) -> bool:
	return float(_cat_stagger_timers.get(cat_id, 0.0)) > 0.0


func _get_wall_counter_target_x(node: CatNode, target_knockback: float) -> float:
	var retreat_distance: float = maxf(WALL_COUNTER_MIN_RETREAT_X, target_knockback * WALL_COUNTER_DISTANCE_MULT)
	if node.team == "player":
		return maxf(BATTLE_WALL_LEFT + CAT_HALF_W, node.position.x - retreat_distance)
	return minf(BATTLE_WALL_RIGHT - CAT_HALF_W, node.position.x + retreat_distance)


func _get_wall_counter_arc_height(target_knockback: float) -> float:
	return clampf(
		target_knockback * WALL_COUNTER_HEIGHT_MULT,
		WALL_COUNTER_MIN_ARC_HEIGHT,
		WALL_COUNTER_MAX_ARC_HEIGHT
	)


func _apply_runtime_damage(cat_id: int, damage: int) -> void:
	if damage <= 0:
		return
	if not _cat_runtime.has(cat_id):
		return
	var runtime: Dictionary = _cat_runtime[cat_id]
	var current_hp: int = maxi(0, int(runtime.get("current_hp", 0)) - damage)
	runtime["current_hp"] = current_hp
	_cat_runtime[cat_id] = runtime
	var node: CatNode = _get_cat_node(cat_id)
	if node != null:
		node.update_hp(current_hp)
		node.show_damage_number(damage)
	_update_skill_slot_hp(cat_id, current_hp)


func _check_runtime_death(cat_id: int) -> void:
	if not _cat_runtime.has(cat_id):
		return
	var runtime: Dictionary = _cat_runtime[cat_id]
	if int(runtime.get("current_hp", 0)) > 0:
		return
	var node: CatNode = _get_cat_node(cat_id)
	if node != null:
		node.play_death()
		_track_cat_recycle(cat_id)
		var died_sfx_index: int = _collision_sfx_rng.randi_range(0, CAT_DIED_SFXS.size() - 1)
		var died_sfx: AudioStream = CAT_DIED_SFXS[died_sfx_index]
		_play_audio_sfx(died_sfx, -4.0, 1.0)
	_mark_skill_slot_dead(cat_id)
	_remove_cat_runtime_state(cat_id)


func _check_runtime_battle_end() -> void:
	if _is_finished:
		return
	if _get_front_runtime_node("player") == null:
		_is_running = false
		_is_finished = true
		battle_finished.emit("LOSE")
		return
	if _get_front_runtime_node("enemy") == null:
		_is_running = false
		_is_finished = true
		battle_finished.emit("WIN")
		return
	if _sim_time >= 60.0:
		_is_running = false
		_is_finished = true
		battle_finished.emit("TIMEOUT")


func _get_current_result() -> String:
	if _get_front_runtime_node("enemy") == null:
		return "WIN"
	if _get_front_runtime_node("player") == null:
		return "LOSE"
	return "TIMEOUT"


func _apply_all_passives() -> void:
	for id_variant: Variant in _cat_runtime.keys():
		var cat_id: int = int(id_variant)
		var runtime: Dictionary = _cat_runtime[cat_id]
		var cat_data_variant: Variant = runtime.get("data", null)
		var cat_data: CatData = cat_data_variant as CatData
		if cat_data == null:
			continue
		for passive: Dictionary in cat_data.passive_skills_data:
			var effects: Array = passive.get("effects", [])
			for eff_idx in range(effects.size()):
				var eff: Dictionary = effects[eff_idx]
				var value: float = _get_scaled_value(passive, eff_idx, eff.get("value", 0.0), cat_data.rank)
				var target_ids: Array = _resolve_passive_target_ids(cat_id, str(eff.get("target", "self")))
				for target_id_variant: Variant in target_ids:
					_apply_runtime_passive_effect(
						int(target_id_variant),
						str(eff.get("type", "")),
						str(eff.get("stat", "")),
						value,
						str(eff.get("value_type", "percent"))
					)


func _resolve_passive_target_ids(caster_id: int, target: String) -> Array:
	if target == "team":
		var caster_runtime: Dictionary = _cat_runtime.get(caster_id, {})
		return _get_team_cat_ids(str(caster_runtime.get("team", "")))
	return [caster_id]


func _apply_runtime_passive_effect(cat_id: int, effect_type: String, stat: String,
		value: float, value_type: String) -> void:
	if not _cat_runtime.has(cat_id):
		return
	var runtime: Dictionary = _cat_runtime[cat_id]
	match effect_type:
		"stat_boost":
			var bonus_base: float = float(runtime.get(stat, 0.0))
			var bonus: float = bonus_base * value if value_type == "percent" else value
			if stat == "max_hp":
				runtime["max_hp"] = int(runtime.get("max_hp", 0)) + int(bonus)
				runtime["current_hp"] = int(runtime.get("current_hp", 0)) + int(bonus)
				var node: CatNode = _get_cat_node(cat_id)
				if node != null:
					node.max_hp = int(runtime["max_hp"])
					node.update_hp(int(runtime["current_hp"]))
				_update_skill_slot_spawn_state(cat_id, int(runtime["current_hp"]), int(runtime["max_hp"]))
			elif runtime.has(stat):
				runtime[stat] = bonus_base + bonus
				if stat == "speed":
					_cat_speeds[cat_id] = float(runtime[stat])
		"damage_reduction":
			runtime["damage_reduction"] = minf(float(runtime.get("damage_reduction", 0.0)) + value, 0.9)
		"cooldown_reduction":
			runtime["cooldown_reduction"] = minf(float(runtime.get("cooldown_reduction", 0.0)) + value, 0.5)
	_cat_runtime[cat_id] = runtime


func _update_runtime_skills(delta: float) -> void:
	var scaled_delta: float = delta * _speed_mult
	for id_variant: Variant in _cat_runtime.keys():
		var cat_id: int = int(id_variant)
		var runtime: Dictionary = _cat_runtime.get(cat_id, {})
		var cat_data_variant: Variant = runtime.get("data", null)
		var cat_data: CatData = cat_data_variant as CatData
		if cat_data == null or cat_data.active_skills_data.is_empty():
			continue
		var slot: Dictionary = _get_skill_slot_entry(cat_id)
		if slot.is_empty():
			continue
		var remaining_cd: float = maxf(0.0, float(slot.get("remaining_cd", 0.0)) - scaled_delta)
		slot["remaining_cd"] = remaining_cd
		if remaining_cd > 0.0:
			continue
		if _is_cat_staggered(cat_id):
			continue
		var skill_d: Dictionary = cat_data.active_skills_data[0]
		var cdr_mult: float = 1.0 - float(runtime.get("cooldown_reduction", 0.0))
		slot["remaining_cd"] = float(skill_d.get("cooldown", 5.0)) * cdr_mult
		_execute_runtime_skill(cat_id, skill_d)


func _execute_runtime_skill(caster_id: int, skill_d: Dictionary) -> void:
	var caster_node: CatNode = _get_cat_node(caster_id)
	if caster_node == null:
		return
	var caster_runtime: Dictionary = _cat_runtime.get(caster_id, {})
	var caster_data_variant: Variant = caster_runtime.get("data", null)
	var caster_data: CatData = caster_data_variant as CatData
	if caster_data == null:
		return
	caster_node.play_skill()
	caster_node.flash_skill()
	_play_audio_sfx(CAT_SKILL_SFX, -6.0, 1.0)
	var rank: int = caster_data.rank
	var effects: Array = skill_d.get("effects", [])
	for eff_idx in range(effects.size()):
		var eff: Dictionary = effects[eff_idx]
		var effect_type: String = str(eff.get("type", ""))
		var value: float = _get_scaled_value(skill_d, eff_idx, eff.get("value", 0.0), rank)
		match effect_type:
			"damage":
				var target_id: int = _resolve_runtime_target_id(caster_id, str(eff.get("target", "enemy_front")))
				if target_id < 0:
					continue
				var hits: int = int(eff.get("hits", 1))
				for _hit_index in range(hits):
					var damage: int = _calc_runtime_attack_damage(caster_id, target_id, _get_runtime_atk(caster_id) * value)
					_apply_runtime_damage(target_id, damage)
					if _is_runtime_dead(target_id):
						_check_runtime_death(target_id)
						break
				var extra_kb: float = float(eff.get("extra_knockback", 0.0))
				if extra_kb > 0.0 and _cat_runtime.has(target_id):
					_apply_skill_extra_knockback(caster_id, target_id, extra_kb)
			"buff_stat":
				var buff_target_id: int = _resolve_runtime_buff_target_id(caster_id, str(eff.get("target", "self")))
				if buff_target_id < 0:
					continue
				_apply_runtime_buff(buff_target_id, str(eff.get("stat", "")), value, str(eff.get("value_type", "percent")), float(eff.get("duration", 3.0)))
			"reflect":
				_apply_runtime_reflect(caster_id, value, float(eff.get("duration", 4.0)))


func _tick_runtime_buffs(delta: float) -> void:
	var scaled_delta: float = delta * _speed_mult
	_tick_skill_slot_buffs(_player_skill_slots, scaled_delta)
	_tick_skill_slot_buffs(_enemy_skill_slots, scaled_delta)
	for id_variant: Variant in _cat_runtime.keys():
		var cat_id: int = int(id_variant)
		var runtime: Dictionary = _cat_runtime[cat_id]
		if float(runtime.get("reflect_remaining", 0.0)) > 0.0:
			runtime["reflect_remaining"] = maxf(0.0, float(runtime["reflect_remaining"]) - scaled_delta)
			if float(runtime["reflect_remaining"]) <= 0.0:
				runtime["reflect"] = 0.0
		var buffs: Array = runtime.get("buffs", [])
		for i in range(buffs.size() - 1, -1, -1):
			var buff: Dictionary = buffs[i]
			buff["remaining"] = maxf(0.0, float(buff.get("remaining", 0.0)) - scaled_delta)
			if float(buff["remaining"]) <= 0.0:
				var stat: String = str(buff.get("stat", ""))
				runtime[stat] = float(runtime.get(stat, 0.0)) - float(buff.get("amount", 0.0))
				if stat == "speed":
					_cat_speeds[cat_id] = float(runtime.get("speed", 80.0))
				buffs.remove_at(i)
			else:
				buffs[i] = buff
		runtime["buffs"] = buffs
		_cat_runtime[cat_id] = runtime


func _tick_skill_slot_buffs(slot_array: Array, scaled_delta: float) -> void:
	for i in range(slot_array.size()):
		var slot: Dictionary = slot_array[i]
		if float(slot.get("buff_remaining", 0.0)) > 0.0:
			slot["buff_remaining"] = maxf(0.0, float(slot["buff_remaining"]) - scaled_delta)


func _apply_runtime_buff(cat_id: int, stat: String, value: float, value_type: String, duration: float) -> void:
	if not _cat_runtime.has(cat_id):
		return
	var runtime: Dictionary = _cat_runtime[cat_id]
	var base_value: float = float(runtime.get(stat, 0.0))
	var amount: float = base_value * value if value_type == "percent" else value
	runtime[stat] = base_value + amount
	var buffs: Array = runtime.get("buffs", [])
	buffs.append({"stat": stat, "amount": amount, "remaining": duration})
	runtime["buffs"] = buffs
	_cat_runtime[cat_id] = runtime
	if stat == "speed":
		_cat_speeds[cat_id] = float(runtime[stat])
	_update_skill_slot_buff(cat_id, duration)


func _apply_runtime_reflect(cat_id: int, value: float, duration: float) -> void:
	if not _cat_runtime.has(cat_id):
		return
	var runtime: Dictionary = _cat_runtime[cat_id]
	runtime["reflect"] = value
	runtime["reflect_remaining"] = duration
	_cat_runtime[cat_id] = runtime
	_update_skill_slot_buff(cat_id, duration)


func _apply_skill_extra_knockback(caster_id: int, target_id: int, extra_kb: float) -> void:
	var caster_node: CatNode = _get_cat_node(caster_id)
	var target_node: CatNode = _get_cat_node(target_id)
	if caster_node == null or target_node == null:
		return
	var direction: float = 1.0 if caster_node.team == "player" else -1.0
	var target_x: float = clampf(
		target_node.position.x + extra_kb * direction,
		BATTLE_WALL_LEFT + CAT_HALF_W,
		BATTLE_WALL_RIGHT - CAT_HALF_W
	)
	_apply_runtime_knockback(target_id, target_x, extra_kb * direction, target_x <= BATTLE_WALL_LEFT + CAT_HALF_W or target_x >= BATTLE_WALL_RIGHT - CAT_HALF_W)


func _resolve_runtime_target_id(caster_id: int, target: String) -> int:
	var caster_runtime: Dictionary = _cat_runtime.get(caster_id, {})
	var caster_team: String = str(caster_runtime.get("team", ""))
	var enemy_team: String = "enemy" if caster_team == "player" else "player"
	match target:
		"enemy_lowest_hp":
			return _get_lowest_hp_cat_id(enemy_team)
		"ally_lowest_hp":
			return _get_lowest_hp_cat_id(caster_team)
		"self":
			return caster_id
		_:
			var front: CatNode = _get_front_runtime_node(enemy_team)
			return -1 if front == null else front.instance_id


func _resolve_runtime_buff_target_id(caster_id: int, target: String) -> int:
	if target == "ally_lowest_hp":
		var caster_runtime: Dictionary = _cat_runtime.get(caster_id, {})
		var caster_team: String = str(caster_runtime.get("team", ""))
		return _get_lowest_hp_cat_id(caster_team)
	return caster_id


func _get_lowest_hp_cat_id(team_name: String) -> int:
	var best_id: int = -1
	var best_hp: int = 0
	for id_variant: Variant in _cat_runtime.keys():
		var cat_id: int = int(id_variant)
		var runtime: Dictionary = _cat_runtime[cat_id]
		if str(runtime.get("team", "")) != team_name:
			continue
		var hp: int = int(runtime.get("current_hp", 0))
		if best_id < 0 or hp < best_hp:
			best_id = cat_id
			best_hp = hp
	return best_id


func _get_team_cat_ids(team_name: String) -> Array:
	var ids: Array = []
	for id_variant: Variant in _cat_runtime.keys():
		var cat_id: int = int(id_variant)
		var runtime: Dictionary = _cat_runtime[cat_id]
		if str(runtime.get("team", "")) == team_name:
			ids.append(cat_id)
	return ids


func _calc_runtime_attack_damage(attacker_id: int, defender_id: int, raw_atk: float) -> int:
	var damage: int = int(CatStats.calc_damage(raw_atk, _get_runtime_defense(defender_id)))
	if damage <= 0:
		return 0
	if _rng.randf() < _get_runtime_crit_rate(attacker_id):
		damage = int(float(damage) * (BASE_CRIT_DAMAGE_MULT + _get_runtime_crit_damage_bonus(attacker_id)))
	var defender_runtime: Dictionary = _cat_runtime.get(defender_id, {})
	var reduction: float = float(defender_runtime.get("damage_reduction", 0.0))
	return int(float(damage) * (1.0 - reduction))


func _get_runtime_atk(cat_id: int) -> float:
	var runtime: Dictionary = _cat_runtime.get(cat_id, {})
	return float(runtime.get("atk", 0.0))


func _get_runtime_defense(cat_id: int) -> float:
	var runtime: Dictionary = _cat_runtime.get(cat_id, {})
	return float(runtime.get("defense", 0.0))


func _get_runtime_crit_rate(cat_id: int) -> float:
	var runtime: Dictionary = _cat_runtime.get(cat_id, {})
	return float(runtime.get("crit_rate", 0.0))


func _get_runtime_crit_damage_bonus(cat_id: int) -> float:
	var runtime: Dictionary = _cat_runtime.get(cat_id, {})
	return float(runtime.get("crit_damage_bonus", 0.0))


func _get_runtime_reflect(cat_id: int) -> float:
	var runtime: Dictionary = _cat_runtime.get(cat_id, {})
	return float(runtime.get("reflect", 0.0))


func _is_runtime_dead(cat_id: int) -> bool:
	if not _cat_runtime.has(cat_id):
		return true
	var runtime: Dictionary = _cat_runtime[cat_id]
	return int(runtime.get("current_hp", 0)) <= 0


func _get_scaled_value(skill_d: Dictionary, eff_idx: int, base_value: float, rank: int) -> float:
	var rank_scaling: Array = skill_d.get("rank_scaling", [])
	for rs: Dictionary in rank_scaling:
		if int(rs.get("effect_index", -1)) == eff_idx and str(rs.get("property", "")) == "value":
			var per_5: float = float(rs.get("per_5_ranks", 0.0))
			return base_value + floorf(float(rank) / 5.0) * per_5
	return base_value


func _get_cat_node(cat_id: int) -> CatNode:
	if not _cat_nodes.has(cat_id):
		return null
	var node_variant: Variant = _cat_nodes.get(cat_id)
	if not (node_variant is CatNode):
		_remove_cat_runtime_state(cat_id)
		return null
	var node: CatNode = node_variant as CatNode
	if not is_instance_valid(node):
		_remove_cat_runtime_state(cat_id)
		return null
	return node


func _track_cat_recycle(cat_id: int) -> void:
	if _pending_recycled_cats.has(cat_id):
		return

	var node: CatNode = _get_cat_node(cat_id)
	if node == null:
		return

	_pending_recycled_cats[cat_id] = true
	_pending_recycle_count += 1
	node.died.connect(_on_cat_node_recycled.bind(cat_id), CONNECT_ONE_SHOT)


func _on_cat_node_recycled(_node: CatNode, cat_id: int) -> void:
	if not _pending_recycled_cats.has(cat_id):
		return

	_pending_recycled_cats.erase(cat_id)
	_pending_recycle_count = maxi(0, _pending_recycle_count - 1)


func await_cat_recycles() -> void:
	while _pending_recycle_count > 0:
		await get_tree().process_frame


func _remove_cat_runtime_state(cat_id: int) -> void:
	_cat_nodes.erase(cat_id)
	_cat_runtime.erase(cat_id)
	_cat_speeds.erase(cat_id)
	_cat_stagger_timers.erase(cat_id)
	_cat_knockback_timers.erase(cat_id)
	_cat_accel_timers.erase(cat_id)
	_cat_skip_recovery_accel.erase(cat_id)


func _play_collision_sfx(event_time: float) -> void:
	if absf(event_time - _last_collision_sfx_time) < 0.001:
		return
	_last_collision_sfx_time = event_time
	var collision_stream: AudioStream = CAT_COLLISION_SFX_1 if _collision_sfx_rng.randf() < 0.5 else CAT_COLLISION_SFX_2
	var collision_volume_db: float = -6.0 if collision_stream == CAT_COLLISION_SFX_1 else -8.0
	_play_audio_sfx(collision_stream, collision_volume_db, _collision_sfx_rng.randf_range(0.98, 1.02))


func _play_audio_sfx(stream: AudioStream, volume_db: float, pitch_scale: float) -> void:
	if stream == null:
		return
	if not _should_play_battle_audio():
		return
	UiAudio.play_sfx(stream, volume_db, pitch_scale)


func _should_play_battle_audio() -> bool:
	return SceneNavigator.get_current_overlay_scene_path().is_empty()


func _find_cat_data(id: int, _team: String) -> CatData:
	var cat_data_variant: Variant = _cat_data_by_instance_id.get(id, null)
	return cat_data_variant as CatData


func _init_skill_slots() -> void:
	_player_skill_slots = _build_skill_slot_entries(_player_cats)
	_enemy_skill_slots = _build_skill_slot_entries(_enemy_cats)


func _build_skill_slot_entries(cats: Array) -> Array:
	var entries: Array = []
	for cat_variant: Variant in cats:
		if not (cat_variant is CatData):
			continue
		var cat: CatData = cat_variant
		var max_cd: float = 0.0
		var remaining_cd: float = 0.0
		var skill_id: String = ""
		var skill_name: String = ""
		if cat.active_skills_data.size() > 0:
			skill_id = str(cat.active_skills_data[0].get("id", ""))
			max_cd = float(cat.active_skills_data[0].get("cooldown", 5.0))
			var initial_delay: float = float(cat.active_skills_data[0].get("initial_delay", 0))
			remaining_cd = initial_delay
			skill_name = str(cat.active_skills_data[0].get("display_name", ""))
		entries.append({
			"max_cd": max_cd,
			"remaining_cd": remaining_cd,
			"buff_remaining": 0.0,
			"max_hp": cat.max_hp,
			"current_hp": cat.max_hp,
			"is_dead": false,
			"cat_id": cat.id,
			"skill_id": skill_id,
			"skill_name": skill_name,
		})
	return entries


func _update_skill_bar(delta: float) -> void:
	if _skill_bar == null:
		return
	var scaled_delta: float = delta * _speed_mult
	_tick_skill_slot_array(_player_skill_slots, scaled_delta)
	_tick_skill_slot_array(_enemy_skill_slots, scaled_delta)
	_refresh_skill_bar_display()


func _tick_skill_slot_array(slot_array: Array, scaled_delta: float) -> void:
	for i in range(slot_array.size()):
		var slot: Dictionary = slot_array[i]
		if float(slot.get("remaining_cd", 0.0)) > 0.0:
			slot["remaining_cd"] = maxf(0.0, float(slot["remaining_cd"]) - scaled_delta)
		if float(slot.get("buff_remaining", 0.0)) > 0.0:
			slot["buff_remaining"] = maxf(0.0, float(slot["buff_remaining"]) - scaled_delta)


func _refresh_skill_bar_display() -> void:
	if _skill_bar == null:
		return
	var display_slots: Array = _get_display_skill_slots()
	for i in range(SKILL_SLOT_DISPLAY_CAP):
		var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
		if slot_node == null:
			continue
		if i >= display_slots.size() or not (display_slots[i] is Dictionary):
			slot_node.visible = false
			continue
		slot_node.visible = true
		_refresh_skill_slot_ui(i, display_slots[i])


func _get_display_skill_slots() -> Array:
	if _skill_bar_filter == "all":
		return _player_skill_slots + _enemy_skill_slots
	return []


func _refresh_skill_slot_ui(i: int, slot: Dictionary) -> void:
	if _skill_bar == null:
		return
	var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
	if slot_node == null:
		return

	var max_cd: float = float(slot.get("max_cd", 0.0))
	var remaining: float = float(slot.get("remaining_cd", 0.0))
	var buff_rem: float = float(slot.get("buff_remaining", 0.0))
	var max_hp: int = int(slot.get("max_hp", 0))
	var current_hp: int = int(slot.get("current_hp", max_hp))
	var is_dead: bool = bool(slot.get("is_dead", false))
	var cat_id: String = str(slot.get("cat_id", ""))

	var icon_rect: TextureRect = slot_node.get_node_or_null("Icon")
	if icon_rect:
		var cat_icon: Texture2D = AssetResolver.resolve_cat_icon(cat_id)
		if cat_icon != null:
			icon_rect.texture = cat_icon
			icon_rect.visible = true
		else:
			icon_rect.texture = null
			icon_rect.visible = false
		icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var death_overlay: ColorRect = slot_node.get_node_or_null("DeathOverlay")
	if death_overlay:
		death_overlay.visible = is_dead

	var overlay: ColorRect = slot_node.get_node_or_null("Overlay")
	if overlay:
		overlay.visible = false
		overlay.position.y = float(overlay.get_meta("base_y", overlay.position.y))
		overlay.size.y = float(overlay.get_meta("base_height", overlay.size.y))

	var cd_label: Label = slot_node.get_node_or_null("CdLabel")
	if cd_label:
		if remaining > 0.0:
			cd_label.text = "%.1f" % remaining
			cd_label.visible = true
		else:
			cd_label.visible = false

	var hp_bar_fill: ColorRect = slot_node.get_node_or_null("HpBarBg/HpBarFill")
	if hp_bar_fill:
		var hp_ratio: float = clampf(float(current_hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
		var hp_base_width: float = hp_bar_fill.get_parent().size.x - 2.0
		hp_bar_fill.size.x = hp_base_width * hp_ratio
		hp_bar_fill.color = Color(0.92, 0.28, 0.22, 1.0) if hp_ratio <= 0.3 else (Color(0.94, 0.76, 0.18, 1.0) if hp_ratio <= 0.6 else Color(0.30, 0.92, 0.40, 1.0))

	var hp_value_label: Label = slot_node.get_node_or_null("HpValueLabel")
	if hp_value_label:
		hp_value_label.text = "%s/%s" % [GameState.format_number(max(0, current_hp)), GameState.format_number(max(max_hp, 0))]

	var cooldown_bar_fill: ColorRect = slot_node.get_node_or_null("CooldownBarBg/CooldownBarFill")
	if cooldown_bar_fill:
		var cooldown_progress: float = 0.0 if max_cd <= 0.0 else clampf(1.0 - (remaining / max_cd), 0.0, 1.0)
		var cooldown_base_width: float = cooldown_bar_fill.get_parent().size.x - 2.0
		cooldown_bar_fill.size.x = cooldown_base_width * cooldown_progress

	var buff_frame: ColorRect = slot_node.get_node_or_null("BuffFrame")
	if buff_frame:
		buff_frame.visible = buff_rem > 0.0
		buff_frame.color = Color(1.0, 0.86, 0.32, 0.14) if buff_rem > 0.0 else Color(1.0, 0.86, 0.32, 0.0)


func _get_skill_slot_array_for_cat(cat_id: int) -> Array:
	if cat_id < _player_cats.size():
		return _player_skill_slots
	return _enemy_skill_slots


func _get_skill_slot_index_for_cat(cat_id: int) -> int:
	if cat_id < _player_cats.size():
		return cat_id
	return cat_id - _player_cats.size()


func _get_skill_slot_entry(cat_id: int) -> Dictionary:
	var slot_array: Array = _get_skill_slot_array_for_cat(cat_id)
	var slot_index: int = _get_skill_slot_index_for_cat(cat_id)
	if slot_index < 0 or slot_index >= slot_array.size():
		return {}
	return slot_array[slot_index]


func _update_skill_slot_spawn_state(cat_id: int, current_hp: int, max_hp: int) -> void:
	var slot: Dictionary = _get_skill_slot_entry(cat_id)
	if slot.is_empty():
		return
	slot["current_hp"] = current_hp
	slot["max_hp"] = max_hp
	slot["is_dead"] = false


func _update_skill_slot_hp(cat_id: int, current_hp: int) -> void:
	var slot: Dictionary = _get_skill_slot_entry(cat_id)
	if slot.is_empty():
		return
	slot["current_hp"] = current_hp


func _reset_skill_slot_cooldown(cat_id: int) -> void:
	var slot: Dictionary = _get_skill_slot_entry(cat_id)
	if slot.is_empty():
		return
	slot["remaining_cd"] = float(slot.get("max_cd", 0.0))


func _update_skill_slot_buff(cat_id: int, buff_duration: float) -> void:
	var slot: Dictionary = _get_skill_slot_entry(cat_id)
	if slot.is_empty():
		return
	slot["buff_remaining"] = buff_duration


func _mark_skill_slot_dead(cat_id: int) -> void:
	var slot: Dictionary = _get_skill_slot_entry(cat_id)
	if slot.is_empty():
		return
	slot["current_hp"] = 0
	slot["is_dead"] = true
