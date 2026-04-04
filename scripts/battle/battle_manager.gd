class_name BattleManager
extends Node

## 控制戰鬥視覺播放：速度切換、跳過、重播

signal battle_finished(result: String)

# 事件序列（來自 BattleSimulator）
var _events: Array = []
var _event_idx: int = 0

# 時間
var _sim_time: float = 0.0
var _speed_mult: float = 1.0
var _is_running: bool = false
var _is_finished: bool = false

# 貓咪節點對照表 { instance_id: CatNode }
var _cat_nodes: Dictionary = {}

# 各貓咪的速度與硬直狀態
var _cat_speeds: Dictionary = {}
var _cat_stagger_timers: Dictionary = {}

# 戰鬥場景提供的容器節點
var _player_team_node: Node2D
var _enemy_team_node: Node2D
var _timer_label: Label

var _player_cats: Array = []
var _enemy_cats: Array = []

# ── 技能列追蹤（玩家隊伍，最多 5 槽）────────────────
# 每個 entry: { max_cd, remaining_cd, buff_remaining, panel_nodes }
var _skill_slots: Array = []
# 外部傳入的技能列容器（Control），由 BattleScene 建立
var _skill_bar: Control = null


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
	_cat_speeds.clear()
	_cat_stagger_timers.clear()
	_skill_slots.clear()
	_event_idx = 0
	_sim_time = 0.0
	_is_finished = false
	_is_running = true
	_init_skill_slots()


func set_speed(mult: float) -> void:
	_speed_mult = mult


func skip_to_end() -> void:
	var end_result := "TIMEOUT"
	for ev: BattleEvent in _events:
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
		var remaining := maxf(0.0, 60.0 - _sim_time)
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
	var cat_data: CatData = _find_cat_data(ev.cat_id, ev.team)
	if cat_data == null:
		return
	var node := CatNode.new()
	var parent := _player_team_node if ev.team == "player" else _enemy_team_node
	parent.add_child(node)
	node.setup(ev.cat_id, ev.team, cat_data.display_name, ev.max_hp)
	node.position = Vector2(ev.pos_x, 0.0)
	_cat_nodes[ev.cat_id] = node
	_cat_speeds[ev.cat_id] = cat_data.speed
	_cat_stagger_timers[ev.cat_id] = 0.0


func _on_collision(ev: BattleEvent) -> void:
	var node: CatNode = _cat_nodes.get(ev.cat_id)
	if node == null:
		return
	var prev_hp = node.current_hp
	node.update_hp(ev.current_hp)
	var damage = max(0, prev_hp - ev.current_hp)
	if damage > 0:
		node.show_damage_number(damage)
	node.move_to(ev.pos_x)
	var is_near_wall := (ev.pos_x <= 70.0 or ev.pos_x >= 650.0)
	_cat_stagger_timers[ev.cat_id] = \
		CatStats.WALL_STAGGER_TIME if is_near_wall else CatStats.STAGGER_TIME


func _on_hp_update(ev: BattleEvent) -> void:
	var node: CatNode = _cat_nodes.get(ev.cat_id)
	if node:
		var prev_hp = node.current_hp
		node.update_hp(ev.current_hp)
		var damage = max(0, prev_hp - ev.current_hp)
		if damage > 0:
			node.show_damage_number(damage)


func _on_skill_activate(ev: BattleEvent) -> void:
	var node: CatNode = _cat_nodes.get(ev.cat_id)
	if node:
		node.flash_skill()
	# 找到對應的 player 技能槽並重置 CD 顯示
	if ev.cat_id < _player_cats.size():
		var slot_idx := ev.cat_id
		if slot_idx < _skill_slots.size():
			_skill_slots[slot_idx]["remaining_cd"] = _skill_slots[slot_idx]["max_cd"]


func _on_buff_apply(ev: BattleEvent) -> void:
	# 只追蹤玩家方的 buff 狀態（供 UI 外框顯示）
	if ev.cat_id < _player_cats.size():
		var slot_idx := ev.cat_id
		if slot_idx < _skill_slots.size():
			_skill_slots[slot_idx]["buff_remaining"] = ev.buff_duration


func _on_cat_die(ev: BattleEvent) -> void:
	var node: CatNode = _cat_nodes.get(ev.cat_id)
	if node:
		node.move_to(ev.pos_x)
		node.play_death()
		_cat_nodes.erase(ev.cat_id)
		_cat_speeds.erase(ev.cat_id)
		_cat_stagger_timers.erase(ev.cat_id)


func _on_battle_end(ev: BattleEvent) -> void:
	_is_running = false
	_is_finished = true
	battle_finished.emit(ev.result)


func _update_cat_movement(delta: float) -> void:
	var scaled_delta := delta * _speed_mult
	for id: int in _cat_nodes:
		var node: CatNode = _cat_nodes.get(id)
		if node == null:
			continue
		if _cat_stagger_timers.has(id):
			_cat_stagger_timers[id] -= scaled_delta
			if _cat_stagger_timers[id] > 0.0:
				continue
		var speed: float = _cat_speeds.get(id, 80.0)
		var dir := 1.0 if node.team == "player" else -1.0
		node.position.x = clampf(node.position.x + dir * speed * scaled_delta, 40.0, 680.0)


func _find_cat_data(id: int, team: String) -> CatData:
	var p_count := _player_cats.size()
	if team == "player":
		if id < p_count:
			return _player_cats[id]
	else:
		var e_idx := id - p_count
		if e_idx >= 0 and e_idx < _enemy_cats.size():
			return _enemy_cats[e_idx]
	return null


# ── 技能列 ───────────────────────────────────────────

func _init_skill_slots() -> void:
	_skill_slots.clear()
	for i in range(_player_cats.size()):
		var cat: CatData = _player_cats[i]
		var max_cd := 0.0
		if cat.active_skills_data.size() > 0:
			max_cd = float(cat.active_skills_data[0].get("cooldown", 5.0))
			var initial_delay: float = float(cat.active_skills_data[0].get("initial_delay", 0))
			_skill_slots.append({
				"max_cd": max_cd,
				"remaining_cd": initial_delay if initial_delay > 0.0 else max_cd,
				"buff_remaining": 0.0,
				"skill_name": cat.active_skills_data[0].get("display_name", ""),
			})
		else:
			_skill_slots.append({
				"max_cd": 0.0,
				"remaining_cd": 0.0,
				"buff_remaining": 0.0,
				"skill_name": "",
			})


func _update_skill_bar(delta: float) -> void:
	if _skill_bar == null:
		return
	var scaled_delta := delta * _speed_mult
	for i in range(_skill_slots.size()):
		var slot: Dictionary = _skill_slots[i]
		# CD 倒數
		if slot["remaining_cd"] > 0.0:
			slot["remaining_cd"] = maxf(0.0, slot["remaining_cd"] - scaled_delta)
		# Buff 持續倒數
		if slot["buff_remaining"] > 0.0:
			slot["buff_remaining"] = maxf(0.0, slot["buff_remaining"] - scaled_delta)
		# 更新 UI 節點
		_refresh_skill_slot_ui(i, slot)


func _refresh_skill_slot_ui(i: int, slot: Dictionary) -> void:
	if _skill_bar == null:
		return
	var slot_node: Control = _skill_bar.get_node_or_null("Slot%d" % i)
	if slot_node == null:
		return

	var max_cd: float = slot["max_cd"]
	var remaining: float = slot["remaining_cd"]
	var buff_rem: float = slot["buff_remaining"]

	# 冷卻遮罩
	var overlay: ColorRect = slot_node.get_node_or_null("Overlay")
	if overlay:
		if max_cd > 0.0 and remaining > 0.0:
			overlay.visible = true
			var ratio := remaining / max_cd
			overlay.size.y = slot_node.size.y * ratio
		else:
			overlay.visible = false

	# 冷卻數字
	var cd_label: Label = slot_node.get_node_or_null("CdLabel")
	if cd_label:
		if remaining > 0.0:
			cd_label.text = "%.1f" % remaining
			cd_label.visible = true
		else:
			cd_label.visible = false

	# Buff 持續外框
	var buff_frame: ColorRect = slot_node.get_node_or_null("BuffFrame")
	if buff_frame:
		buff_frame.visible = buff_rem > 0.0
