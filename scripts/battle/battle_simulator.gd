class_name BattleSimulator
extends RefCounted

## 邏輯層預先模擬整場戰鬥，產生事件序列（決定性結果）

const BATTLE_DURATION: float = 60.0
const SIM_STEP: float = 1.0 / 30.0   # 30fps 模擬精度
const WALL_LEFT: float = 40.0         # 左牆 x
const WALL_RIGHT: float = 680.0       # 右牆 x
const CAT_HALF_W: float = 30.0        # 碰撞半寬

# 模擬用輕量貓咪狀態
class SimCat:
	var instance_id: int
	var data: CatData
	var team: String
	var pos_x: float
	var current_hp: int
	var is_alive: bool = true
	var is_staggered: bool = false
	var stagger_timer: float = 0.0
	var facing: int                    # 1 = 往右, -1 = 往左
	var skill_cooldowns: Array = []    # 每個主動技能的剩餘冷卻

	func _init(id: int, cat_data: CatData, team_name: String, x: float) -> void:
		instance_id = id
		data = cat_data
		team = team_name
		pos_x = x
		current_hp = cat_data.max_hp
		facing = 1 if team_name == "player" else -1
		for cfg in cat_data.active_skill_configs:
			skill_cooldowns.append(float(cfg.get("initial_delay", 0)))

## simulate() 是唯一對外介面
## 傳入雙方 CatData 陣列，回傳 Array[BattleEvent]（依時間排序）
func simulate(player_cats: Array, enemy_cats: Array) -> Array:
	var events: Array = []
	var id_counter := 0

	# ── 初始化貓咪（最多 5 隻，間距 60px = CAT_HALF_W*2）──────────
	var p_list: Array = []   # player 隊伍（index 0 = 前排）
	var e_list: Array = []   # enemy  隊伍（index 0 = 前排）

	# Player：前排 x=315，往左排 60px，5 隻最小 x=75（安全距離離左牆 40）
	var p_front_x := 315.0
	var p_spacing := 60.0
	for i in range(player_cats.size()):
		var sc := SimCat.new(id_counter, player_cats[i], "player",
				p_front_x - i * p_spacing)
		p_list.append(sc)
		events.append(BattleEvent.spawn(0.0, sc.instance_id, "player",
				sc.pos_x, sc.current_hp, sc.data.max_hp))
		id_counter += 1

	# Enemy：前排 x=405，往右排 60px，5 隻最大 x=645（安全距離離右牆 680）
	var e_front_x := 405.0
	var e_spacing := 60.0
	for i in range(enemy_cats.size()):
		var sc := SimCat.new(id_counter, enemy_cats[i], "enemy",
				e_front_x + i * e_spacing)
		e_list.append(sc)
		events.append(BattleEvent.spawn(0.0, sc.instance_id, "enemy",
				sc.pos_x, sc.current_hp, sc.data.max_hp))
		id_counter += 1

	# ── 主模擬迴圈 ──────────────────────────
	var sim_time := 0.0
	while sim_time < BATTLE_DURATION:
		# 取得各方存活前排
		var p_front := _get_front(p_list)
		var e_front := _get_front(e_list)

		# 任一方全滅
		if p_front == null:
			events.append(BattleEvent.battle_end(sim_time, "LOSE"))
			events.sort_custom(func(a, b): return a.timestamp < b.timestamp)
			return events
		if e_front == null:
			events.append(BattleEvent.battle_end(sim_time, "WIN"))
			events.sort_custom(func(a, b): return a.timestamp < b.timestamp)
			return events

		# 移動所有存活貓咪（各自速度，開戰後不限制隊列順序）
		for sc in p_list:
			if sc.is_alive:
				_move_cat(sc, SIM_STEP)
		for sc in e_list:
			if sc.is_alive:
				_move_cat(sc, SIM_STEP)

		# 碰撞檢測：逐一比對所有存活的跨隊組合
		_check_all_collisions(p_list, e_list, sim_time, events)

		# 技能計時
		for sc in p_list + e_list:
			if sc.is_alive:
				_tick_skills(sc, SIM_STEP, sim_time, events, p_list, e_list)

		sim_time += SIM_STEP

	events.append(BattleEvent.battle_end(BATTLE_DURATION, "TIMEOUT"))
	events.sort_custom(func(a, b): return a.timestamp < b.timestamp)
	return events

# ── 輔助方法 ─────────────────────────────────

## 取同隊實際最前排：player 取最大 x，enemy 取最小 x
func _get_front(team_list: Array) -> SimCat:
	var best: SimCat = null
	for sc: SimCat in team_list:
		if not sc.is_alive:
			continue
		if best == null:
			best = sc
		elif sc.team == "player" and sc.pos_x > best.pos_x:
			best = sc
		elif sc.team == "enemy" and sc.pos_x < best.pos_x:
			best = sc
	return best

## 檢查所有存活跨隊組合，找出所有重疊對並處理碰撞
func _check_all_collisions(p_list: Array, e_list: Array,
		t: float, events: Array) -> void:
	for p: SimCat in p_list:
		if not p.is_alive:
			continue
		for e: SimCat in e_list:
			if not e.is_alive:
				continue
			if _are_colliding(p, e):
				_handle_collision(p, e, t, events, p_list, e_list)

## 強制同隊貓咪保持最小間距（CAT_HALF_W*2），前排優先
## front_is_leftmost=true → enemy（前排 x 最小），false → player（前排 x 最大）
func _enforce_queue(team_list: Array, front_is_leftmost: bool) -> void:
	var alive: Array = []
	for sc in team_list:
		if sc.is_alive:
			alive.append(sc)
	if alive.size() <= 1:
		return
	var min_dist := CAT_HALF_W * 2.0
	if front_is_leftmost:
		# Enemy：前排 x 最小 → 升序，由前向後推，後排不能比前排更左
		alive.sort_custom(func(a, b): return a.pos_x < b.pos_x)
		for i in range(1, alive.size()):
			var min_x: float = alive[i - 1].pos_x + min_dist
			if alive[i].pos_x < min_x:
				alive[i].pos_x = min_x
	else:
		# Player：前排 x 最大 → 降序，由前向後推，後排不能比前排更右
		alive.sort_custom(func(a, b): return a.pos_x > b.pos_x)
		for i in range(1, alive.size()):
			var max_x: float = alive[i - 1].pos_x - min_dist
			if alive[i].pos_x > max_x:
				alive[i].pos_x = max_x

func _move_cat(sc: SimCat, delta: float) -> void:
	if sc.is_staggered:
		sc.stagger_timer -= delta
		if sc.stagger_timer <= 0.0:
			sc.is_staggered = false
		return
	# 往中心移動
	sc.pos_x += sc.data.speed * sc.facing * delta

func _are_colliding(a: SimCat, b: SimCat) -> bool:
	# a = player front（往右），b = enemy front（往左）
	return a.pos_x + CAT_HALF_W >= b.pos_x - CAT_HALF_W

func _handle_collision(p: SimCat, e: SimCat, t: float, events: Array,
		p_list: Array, e_list: Array) -> void:
	# ── 傷害：硬直中不造成傷害給對方 ────────────────────
	if not p.is_staggered:
		var dmg := int(CatStats.calc_damage(p.data.atk, e.data.defense))
		e.current_hp = maxi(0, e.current_hp - dmg)
	if not e.is_staggered:
		var dmg := int(CatStats.calc_damage(e.data.atk, p.data.defense))
		p.current_hp = maxi(0, p.current_hp - dmg)

	# ── 回彈：不論硬直狀態都發生 ────────────────────────
	var kb_p := CatStats.calc_knockback_distance(e.data.weight, p.data.weight)
	var kb_e := CatStats.calc_knockback_distance(p.data.weight, e.data.weight)

	# 先分開位置避免重疊繼續觸發
	p.pos_x = e.pos_x - CAT_HALF_W * 2.0 - 2.0
	e.pos_x = p.pos_x + CAT_HALF_W * 2.0 + 2.0

	p.pos_x -= kb_p
	e.pos_x += kb_e

	# ── 撞牆修正 ─────────────────────────────────────────
	var p_stagger_t := CatStats.STAGGER_TIME
	if p.pos_x - CAT_HALF_W <= WALL_LEFT:
		p.pos_x = WALL_LEFT + CAT_HALF_W
		p_stagger_t = CatStats.WALL_STAGGER_TIME

	var e_stagger_t := CatStats.STAGGER_TIME
	if e.pos_x + CAT_HALF_W >= WALL_RIGHT:
		e.pos_x = WALL_RIGHT - CAT_HALF_W
		e_stagger_t = CatStats.WALL_STAGGER_TIME

	# ── 硬直：已在硬直中則不重置計時器 ──────────────────
	if not p.is_staggered:
		p.is_staggered = true
		p.stagger_timer = p_stagger_t
	if not e.is_staggered:
		e.is_staggered = true
		e.stagger_timer = e_stagger_t

	# ── 事件 ────────────────────────────────────────────
	events.append(BattleEvent.collision(t, p.instance_id, p.pos_x, p.current_hp, -kb_p))
	events.append(BattleEvent.collision(t, e.instance_id, e.pos_x, e.current_hp, kb_e))

	# ── 死亡判定 ─────────────────────────────────────────
	if e.current_hp <= 0 and e.is_alive:
		e.is_alive = false
		events.append(BattleEvent.cat_die(t, e.instance_id, "enemy", e.pos_x))
	if p.current_hp <= 0 and p.is_alive:
		p.is_alive = false
		events.append(BattleEvent.cat_die(t, p.instance_id, "player", p.pos_x))

func _tick_skills(sc: SimCat, delta: float, t: float, events: Array,
		p_list: Array, e_list: Array) -> void:
	for i in range(sc.skill_cooldowns.size()):
		sc.skill_cooldowns[i] -= delta
		if sc.skill_cooldowns[i] <= 0.0:
			var cfg: Dictionary = sc.data.active_skill_configs[i]
			var sid: String = cfg.get("id", "unknown")
			var cd: float = float(cfg.get("cooldown", 5.0))
			sc.skill_cooldowns[i] = cd
			events.append(BattleEvent.skill_activate(t, sc.instance_id, sid))

			# 技能效果（簡化：造成 ATK * 0.5 傷害給對方前排）
			var targets := p_list if sc.team == "enemy" else e_list
			var front := _get_front(targets)
			if front and front.is_alive:
				var skill_dmg := int(CatStats.calc_damage(
						sc.data.atk * 0.5, front.data.defense))
				front.current_hp = maxi(0, front.current_hp - skill_dmg)
				events.append(BattleEvent.hp_update(t, front.instance_id,
						front.current_hp, front.data.max_hp))
				if front.current_hp <= 0:
					front.is_alive = false
					events.append(BattleEvent.cat_die(t, front.instance_id,
							front.team, front.pos_x))
