class_name BattleManager
extends Node

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
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
var _cat_speeds: Dictionary = {}
var _cat_stagger_timers: Dictionary = {}

var _player_team_node: Node2D
var _enemy_team_node: Node2D
var _timer_label: Label

var _player_cats: Array = []
var _enemy_cats: Array = []

var _player_skill_slots: Array = []
var _enemy_skill_slots: Array = []
var _skill_bar: Control = null
var _skill_bar_filter: String = "scoop"


func setup(events: Array, player_cats: Array, enemy_cats: Array,
		player_node: Node2D, enemy_node: Node2D, timer_lbl: Label,
		skill_bar: Control = null) -> void:
	_events = events
	_player_cats = player_cats
	_enemy_cats = enemy_cats
	_player_team_node = player_node
	_enemy_team_node = enemy_node
	_timer_label = timer_lbl
	_skill_bar = skill_bar
	_cat_nodes.clear()
	_cat_data_by_instance_id.clear()
	_cat_speeds.clear()
	_cat_stagger_timers.clear()
	_player_skill_slots.clear()
	_enemy_skill_slots.clear()
	_event_idx = 0
	_sim_time = 0.0
	_is_finished = false
	_is_running = true
	_collision_sfx_rng.randomize()
	_last_collision_sfx_time = -1.0
	for i in range(_player_cats.size()):
		_cat_data_by_instance_id[i] = _player_cats[i]
	for i in range(_enemy_cats.size()):
		_cat_data_by_instance_id[_player_cats.size() + i] = _enemy_cats[i]
	_init_skill_slots()
	_refresh_skill_bar_display()


func prime_initial_spawn_state() -> void:
	var scan_idx: int = _event_idx
	while scan_idx < _events.size():
		var ev: BattleEvent = _events[scan_idx]
		if ev.timestamp > 0.0:
			break
		if ev.type == BattleEvent.Type.SPAWN:
			_apply_event(ev)
		scan_idx += 1


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
	var end_result: String = "TIMEOUT"
	for ev_variant: Variant in _events:
		if not (ev_variant is BattleEvent):
			continue
		var ev: BattleEvent = ev_variant
		if ev.type == BattleEvent.Type.BATTLE_END:
			end_result = ev.result
			break
	_is_running = false
	_is_finished = true
	battle_finished.emit(end_result)


func _process(delta: float) -> void:
	if not _is_running or _is_finished:
		return
	_sim_time += delta * _speed_mult

	if _timer_label:
		var remaining: float = maxf(0.0, 60.0 - _sim_time)
		_timer_label.text = "%.1f" % remaining

	while _event_idx < _events.size():
		var ev: BattleEvent = _events[_event_idx]
		if ev.timestamp > _sim_time:
			break
		_apply_event(ev)
		_event_idx += 1

	_update_cat_movement(delta)
	_update_skill_bar(delta)


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
	node.move_to(ev.pos_x)
	node.play_collision(ev.knockback)
	_play_collision_sfx(ev.timestamp)
	var is_near_wall: bool = (ev.pos_x <= 50.0 or ev.pos_x >= 670.0)
	_cat_stagger_timers[ev.cat_id] = \
		CatStats.WALL_STAGGER_TIME if is_near_wall else CatStats.STAGGER_TIME
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


func _on_cat_die(ev: BattleEvent) -> void:
	var node: CatNode = _get_cat_node(ev.cat_id)
	if node:
		node.move_to(ev.pos_x)
		node.play_death()
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
			_cat_stagger_timers[id] -= scaled_delta
			if float(_cat_stagger_timers[id]) > 0.0:
				node.play_stagger()
				continue
		var speed: float = float(_cat_speeds.get(id, 80.0))
		var dir: float = 1.0 if node.team == "player" else -1.0
		node.position.x = clampf(node.position.x + dir * speed * scaled_delta, 20.0, 700.0)
		node.play_run()


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


func _remove_cat_runtime_state(cat_id: int) -> void:
	_cat_nodes.erase(cat_id)
	_cat_speeds.erase(cat_id)
	_cat_stagger_timers.erase(cat_id)


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


func _find_cat_data(id: int, team: String) -> CatData:
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
			remaining_cd = initial_delay if initial_delay > 0.0 else max_cd
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
