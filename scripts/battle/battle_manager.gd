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

# 戰鬥場景提供的容器節點
var _player_team_node: Node2D
var _enemy_team_node: Node2D
var _timer_label: Label

# 貓咪資料（setup 時傳入）
var _player_cats: Array = []
var _enemy_cats: Array = []

func setup(events: Array, player_cats: Array, enemy_cats: Array,
		player_node: Node2D, enemy_node: Node2D, timer_lbl: Label) -> void:
	_events = events
	_player_cats = player_cats
	_enemy_cats = enemy_cats
	_player_team_node = player_node
	_enemy_team_node = enemy_node
	_timer_label = timer_lbl
	_is_running = true

func set_speed(mult: float) -> void:
	_speed_mult = mult

func skip_to_end() -> void:
	# 直接跳到最後一個事件，找結果
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

	# 更新計時器顯示（倒數 60 秒）
	if _timer_label:
		var remaining := maxf(0.0, 60.0 - _sim_time)
		_timer_label.text = "%.1f" % remaining

	# 處理到時間點的事件
	while _event_idx < _events.size():
		var ev: BattleEvent = _events[_event_idx]
		if ev.timestamp > _sim_time:
			break
		_apply_event(ev)
		_event_idx += 1

	# 移動存活貓咪（插值動畫）
	_update_cat_movement(delta)

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

func _on_collision(ev: BattleEvent) -> void:
	var node: CatNode = _cat_nodes.get(ev.cat_id)
	if node == null:
		return
	node.update_hp(ev.current_hp)
	node.apply_knockback(ev.knockback)

func _on_hp_update(ev: BattleEvent) -> void:
	var node: CatNode = _cat_nodes.get(ev.cat_id)
	if node:
		node.update_hp(ev.current_hp)

func _on_skill_activate(ev: BattleEvent) -> void:
	var node: CatNode = _cat_nodes.get(ev.cat_id)
	if node:
		node.flash_skill()

func _on_cat_die(ev: BattleEvent) -> void:
	var node: CatNode = _cat_nodes.get(ev.cat_id)
	if node:
		node.play_death()
		_cat_nodes.erase(ev.cat_id)

func _on_battle_end(ev: BattleEvent) -> void:
	_is_running = false
	_is_finished = true
	battle_finished.emit(ev.result)

func _update_cat_movement(delta: float) -> void:
	# 讓存活貓咪持續朝中心移動（視覺補間）
	for id: int in _cat_nodes:
		var node: CatNode = _cat_nodes[id]
		if node == null:
			continue
		# 根據隊伍決定移動方向
		var dir := 1.0 if node.team == "player" else -1.0
		# 簡單地讓節點緩慢向前移（視覺效果，模擬已在 simulator 計算過）
		node.position.x += dir * 60.0 * delta * _speed_mult
		# 夾在牆壁之間
		node.position.x = clampf(node.position.x, 40.0, 680.0)

func _find_cat_data(id: int, team: String) -> CatData:
	# 根據 spawn 順序找 CatData
	# player id 從 0 開始，enemy 緊接在後
	var p_count := _player_cats.size()
	if team == "player":
		if id < p_count:
			return _player_cats[id]
	else:
		var e_idx := id - p_count
		if e_idx >= 0 and e_idx < _enemy_cats.size():
			return _enemy_cats[e_idx]
	return null
