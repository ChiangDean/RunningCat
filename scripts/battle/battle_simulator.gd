class_name BattleSimulator
extends RefCounted

## 邏輯層預先模擬整場戰鬥，產生事件序列（決定性結果）
## 技能系統：被動在戰鬥開始時套用；主動每冷卻結束自動發動；
## Buff/Debuff 追蹤持續時間（輕量 Dictionary，每 tick 倒數）

const BATTLE_DURATION: float = 60.0
const SIM_STEP: float = 1.0 / 30.0   # 30fps 模擬精度
const WALL_LEFT: float = 20.0
const WALL_RIGHT: float = 700.0
const CAT_HALF_W: float = 30.0
const BASE_CRIT_DAMAGE_MULT: float = 1.5
const PLAYER_FRONT_START_X: float = 280.0
const ENEMY_FRONT_START_X: float = 440.0
const TEAM_ROW_SPACING: float = 60.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ── 模擬用輕量貓咪狀態 ───────────────────────────────
class SimCat:
	var instance_id: int
	var data: CatData
	var team: String
	var pos_x: float
	var is_alive: bool = true
	var is_staggered: bool = false
	var stagger_timer: float = 0.0
	var facing: int          # 1 = 往右，-1 = 往左

	# 技能冷卻（對應 data.active_skills_data 的索引）
	var skill_cooldowns: Array = []      # 剩餘冷卻秒數
	var skill_max_cds: Array = []        # 每次重置用的 max cd（已套用 CDR）

	# 有效屬性（套用被動後的基礎值）
	var base_hp: int = 0
	var current_hp: int = 0
	var base_atk: int = 0
	var base_def: int = 0
	var base_speed: float = 0.0

	# 被動 — 永久效果（僅需查詢，不倒數）
	var passive_damage_reduction: float = 0.0   # 0.08 = 減少 8% 傷害
	var crit_rate: float = 0.0
	var crit_damage_bonus: float = 0.0

	# 主動 Buff / Debuff（持續時間）
	# 每個 entry: { "type": String, "stat": String, "value": float,
	#               "value_type": String, "remaining": float }
	var active_buffs: Array = []

	func _init(id: int, cat_data: CatData, team_name: String, x: float) -> void:
		instance_id = id
		data = cat_data
		team = team_name
		pos_x = x
		facing = 1 if team_name == "player" else -1
		base_hp    = cat_data.max_hp
		current_hp = cat_data.max_hp
		base_atk   = cat_data.atk
		base_def   = cat_data.defense
		base_speed = cat_data.speed
		passive_damage_reduction = clampf(float(cat_data.get_meta("damage_reduction_bonus", 0.0)), 0.0, 0.9)
		crit_rate = clampf(float(cat_data.get_meta("crit_rate", 0.0)), 0.0, 1.0)
		crit_damage_bonus = maxf(0.0, float(cat_data.get_meta("crit_damage_bonus", 0.0)))

	# ── 有效屬性（含 active buff 疊加）───────────────
	func get_effective_def() -> int:
		var val := float(base_def)
		for b: Dictionary in active_buffs:
			if b.get("stat", "") == "defense":
				if b.get("value_type", "percent") == "percent":
					val *= (1.0 + b["value"])
				else:
					val += b["value"]
		return int(val)

	func get_effective_atk() -> int:
		var val := float(base_atk)
		for b: Dictionary in active_buffs:
			if b.get("stat", "") == "atk":
				if b.get("value_type", "percent") == "percent":
					val *= (1.0 + b["value"])
				else:
					val += b["value"]
		return int(val)

	func get_effective_speed() -> float:
		var val := base_speed
		for b: Dictionary in active_buffs:
			if b.get("stat", "") == "speed":
				if b.get("value_type", "percent") == "percent":
					val *= (1.0 + b["value"])
				else:
					val += b["value"]
		return val

	## 反彈傷害比例（0 表示沒有 reflect buff）
	func get_reflect_value() -> float:
		for b: Dictionary in active_buffs:
			if b.get("type", "") == "reflect":
				return b.get("value", 0.0)
		return 0.0

	## 施加一個 buff（同類型刷新持續時間）
	func apply_buff(buff_type: String, stat: String, value: float,
			value_type: String, duration: float) -> void:
		for b: Dictionary in active_buffs:
			if b.get("type", "") == buff_type and b.get("stat", "") == stat:
				b["remaining"] = duration
				b["value"] = value
				return
		active_buffs.append({
			"type": buff_type, "stat": stat, "value": value,
			"value_type": value_type, "remaining": duration
		})

	## 施加 reflect buff（無 stat 欄位，用 type 識別）
	func apply_reflect(value: float, duration: float) -> void:
		for b: Dictionary in active_buffs:
			if b.get("type", "") == "reflect":
				b["remaining"] = duration
				b["value"] = value
				return
		active_buffs.append({
			"type": "reflect", "stat": "", "value": value,
			"value_type": "flat", "remaining": duration
		})

	## 每 tick 更新 buff 倒數
	func tick_buffs(delta: float) -> void:
		var i := active_buffs.size() - 1
		while i >= 0:
			active_buffs[i]["remaining"] -= delta
			if active_buffs[i]["remaining"] <= 0.0:
				active_buffs.remove_at(i)
			i -= 1


# ── 模擬主流程 ───────────────────────────────────────

## 傳入雙方 CatData 陣列，回傳 Array[BattleEvent]（依時間排序）
func simulate(player_cats: Array, enemy_cats: Array) -> Array:
	_rng.randomize()
	var events: Array = []
	var id_counter := 0

	var p_list: Array = []
	var e_list: Array = []

	# Player：前排 x=315，往左排 60px
	var p_front_x := PLAYER_FRONT_START_X
	for i in range(player_cats.size()):
		var sc := SimCat.new(id_counter, player_cats[i], "player",
				p_front_x - i * TEAM_ROW_SPACING)
		p_list.append(sc)
		events.append(BattleEvent.spawn(0.0, sc.instance_id, "player",
				sc.pos_x, sc.current_hp, sc.base_hp))
		id_counter += 1

	# Enemy：前排 x=405，往右排 60px
	var e_front_x := ENEMY_FRONT_START_X
	for i in range(enemy_cats.size()):
		var sc := SimCat.new(id_counter, enemy_cats[i], "enemy",
				e_front_x + i * TEAM_ROW_SPACING)
		e_list.append(sc)
		events.append(BattleEvent.spawn(0.0, sc.instance_id, "enemy",
				sc.pos_x, sc.current_hp, sc.base_hp))
		id_counter += 1

	# ── 套用被動技能 ──────────────────────────────────
	_apply_all_passives(p_list, e_list)

	# ── 初始化主動技能冷卻 ────────────────────────────
	for sc: SimCat in p_list + e_list:
		_init_skill_cooldowns(sc)

	# ── 主模擬迴圈 ───────────────────────────────────
	var sim_time := 0.0
	while sim_time < BATTLE_DURATION:
		var p_front := _get_front(p_list)
		var e_front := _get_front(e_list)

		if p_front == null:
			events.append(BattleEvent.battle_end(sim_time, "LOSE"))
			events.sort_custom(func(a, b): return a.timestamp < b.timestamp)
			return events
		if e_front == null:
			events.append(BattleEvent.battle_end(sim_time, "WIN"))
			events.sort_custom(func(a, b): return a.timestamp < b.timestamp)
			return events

		# 移動
		for sc: SimCat in p_list:
			if sc.is_alive:
				_move_cat(sc, SIM_STEP)
		for sc: SimCat in e_list:
			if sc.is_alive:
				_move_cat(sc, SIM_STEP)

		# 碰撞
		_check_all_collisions(p_list, e_list, sim_time, events)

		# 技能計時 + 觸發
		for sc: SimCat in p_list + e_list:
			if sc.is_alive:
				_tick_skills(sc, SIM_STEP, sim_time, events, p_list, e_list)

		# Buff 倒數
		for sc: SimCat in p_list + e_list:
			if sc.is_alive:
				sc.tick_buffs(SIM_STEP)

		sim_time += SIM_STEP

	events.append(BattleEvent.battle_end(BATTLE_DURATION, "TIMEOUT"))
	events.sort_custom(func(a, b): return a.timestamp < b.timestamp)
	return events


# ── 被動技能套用 ─────────────────────────────────────

func _apply_all_passives(p_list: Array, e_list: Array) -> void:
	_apply_passives_for_team(p_list, p_list)
	_apply_passives_for_team(e_list, e_list)


func _apply_passives_for_team(casters: Array, team_list: Array) -> void:
	for sc: SimCat in casters:
		for passive: Dictionary in sc.data.passive_skills_data:
			var rank: int = sc.data.rank
			for eff: Dictionary in passive.get("effects", []):
				var eff_idx: int = passive.get("effects", []).find(eff)
				var value: float = _get_scaled_value(passive, eff_idx, eff.get("value", 0.0), rank)
				var target: String = eff.get("target", "self")
				var eff_type: String = eff.get("type", "")
				var targets: Array = _resolve_passive_targets(sc, target, team_list)
				for t: SimCat in targets:
					_apply_passive_effect(t, eff_type, eff.get("stat", ""), value,
							eff.get("value_type", "percent"))


func _resolve_passive_targets(caster: SimCat, target: String, team_list: Array) -> Array:
	match target:
		"self":   return [caster]
		"team":   return team_list.filter(func(sc): return sc.is_alive)
		_:        return [caster]


func _apply_passive_effect(sc: SimCat, eff_type: String, stat: String,
		value: float, value_type: String) -> void:
	match eff_type:
		"stat_boost":
			match stat:
				"max_hp":
					var bonus := int(sc.base_hp * value) if value_type == "percent" else int(value)
					sc.base_hp    += bonus
					sc.current_hp += bonus
				"atk":
					var bonus := int(sc.base_atk * value) if value_type == "percent" else int(value)
					sc.base_atk += bonus
				"defense":
					var bonus := int(sc.base_def * value) if value_type == "percent" else int(value)
					sc.base_def += bonus
				"speed":
					var bonus := sc.base_speed * value if value_type == "percent" else value
					sc.base_speed += bonus
		"damage_reduction":
			sc.passive_damage_reduction = minf(sc.passive_damage_reduction + value, 0.9)
		"cooldown_reduction":
			# CDR 儲存在 data 層，init_skill_cooldowns 時套用
			# 這裡暫存於 data 的臨時欄位
			if not sc.data.get_meta("cdr", 0.0) is float:
				sc.data.set_meta("cdr", 0.0)
			sc.data.set_meta("cdr", minf(sc.data.get_meta("cdr", 0.0) + value, 0.5))


func _init_skill_cooldowns(sc: SimCat) -> void:
	sc.skill_cooldowns.clear()
	sc.skill_max_cds.clear()
	var cdr: float = sc.data.get_meta("cdr", 0.0)
	var cdr_mult: float = 1.0 - cdr
	for skill_d: Dictionary in sc.data.active_skills_data:
		var base_cd: float = float(skill_d.get("cooldown", 5.0))
		var eff_cd: float = base_cd * cdr_mult
		var delay: float = float(skill_d.get("initial_delay", 0)) * cdr_mult
		sc.skill_cooldowns.append(delay)
		sc.skill_max_cds.append(eff_cd)


# ── 移動 ─────────────────────────────────────────────

func _move_cat(sc: SimCat, delta: float) -> void:
	if sc.is_staggered:
		sc.stagger_timer -= delta
		if sc.stagger_timer <= 0.0:
			sc.is_staggered = false
		return
	sc.pos_x += sc.get_effective_speed() * sc.facing * delta


# ── 碰撞 ─────────────────────────────────────────────

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


func _get_lowest_hp(team_list: Array) -> SimCat:
	var best: SimCat = null
	for sc: SimCat in team_list:
		if not sc.is_alive:
			continue
		if best == null or sc.current_hp < best.current_hp:
			best = sc
	return best


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


func _enforce_queue(team_list: Array, front_is_leftmost: bool) -> void:
	var alive: Array = []
	for sc in team_list:
		if sc.is_alive:
			alive.append(sc)
	if alive.size() <= 1:
		return
	var min_dist := CAT_HALF_W * 2.0
	if front_is_leftmost:
		alive.sort_custom(func(a, b): return a.pos_x < b.pos_x)
		for i in range(1, alive.size()):
			var min_x: float = alive[i - 1].pos_x + min_dist
			if alive[i].pos_x < min_x:
				alive[i].pos_x = min_x
	else:
		alive.sort_custom(func(a, b): return a.pos_x > b.pos_x)
		for i in range(1, alive.size()):
			var max_x: float = alive[i - 1].pos_x - min_dist
			if alive[i].pos_x > max_x:
				alive[i].pos_x = max_x


func _are_colliding(a: SimCat, b: SimCat) -> bool:
	return a.pos_x + CAT_HALF_W >= b.pos_x - CAT_HALF_W


func _handle_collision(p: SimCat, e: SimCat, t: float, events: Array,
		p_list: Array, e_list: Array) -> void:
	# ── 傷害（含被動 damage_reduction 與有效防禦）────
	var dmg_to_e := 0
	var dmg_to_p := 0
	if not p.is_staggered:
		dmg_to_e = _calc_attack_damage(p, e, p.get_effective_atk())
		e.current_hp = maxi(0, e.current_hp - dmg_to_e)
	if not e.is_staggered:
		dmg_to_p = _calc_attack_damage(e, p, e.get_effective_atk())
		p.current_hp = maxi(0, p.current_hp - dmg_to_p)

	# ── Reflect：被攻擊方的 reflect 傷害反彈給攻擊方 ──
	if dmg_to_e > 0:
		var rf := e.get_reflect_value()
		if rf > 0.0:
			var ref_dmg := int(dmg_to_e * rf)
			p.current_hp = maxi(0, p.current_hp - ref_dmg)
			events.append(BattleEvent.hp_update(t, p.instance_id, p.current_hp, p.base_hp))
	if dmg_to_p > 0:
		var rf := p.get_reflect_value()
		if rf > 0.0:
			var ref_dmg := int(dmg_to_p * rf)
			e.current_hp = maxi(0, e.current_hp - ref_dmg)
			events.append(BattleEvent.hp_update(t, e.instance_id, e.current_hp, e.base_hp))

	# ── 回彈 ──────────────────────────────────────────
	var kb_p := CatStats.calc_knockback_distance(e.data.weight, p.data.weight)
	var kb_e := CatStats.calc_knockback_distance(p.data.weight, e.data.weight)

	p.pos_x = e.pos_x - CAT_HALF_W * 2.0 - 2.0
	e.pos_x = p.pos_x + CAT_HALF_W * 2.0 + 2.0
	p.pos_x -= kb_p
	e.pos_x += kb_e

	# ── 撞牆修正 ──────────────────────────────────────
	var p_stagger_t := CatStats.STAGGER_TIME
	if p.pos_x - CAT_HALF_W <= WALL_LEFT:
		p.pos_x = WALL_LEFT + CAT_HALF_W
		p_stagger_t = CatStats.WALL_STAGGER_TIME

	var e_stagger_t := CatStats.STAGGER_TIME
	if e.pos_x + CAT_HALF_W >= WALL_RIGHT:
		e.pos_x = WALL_RIGHT - CAT_HALF_W
		e_stagger_t = CatStats.WALL_STAGGER_TIME

	# ── 硬直 ──────────────────────────────────────────
	if not p.is_staggered:
		p.is_staggered = true
		p.stagger_timer = p_stagger_t
	if not e.is_staggered:
		e.is_staggered = true
		e.stagger_timer = e_stagger_t

	events.append(BattleEvent.collision(t, p.instance_id, p.pos_x, p.current_hp, -kb_p))
	events.append(BattleEvent.collision(t, e.instance_id, e.pos_x, e.current_hp, kb_e))

	# ── 死亡判定 ──────────────────────────────────────
	_check_death(e, t, events)
	_check_death(p, t, events)


func _check_death(sc: SimCat, t: float, events: Array) -> void:
	if sc.current_hp <= 0 and sc.is_alive:
		sc.is_alive = false
		events.append(BattleEvent.cat_die(t, sc.instance_id, sc.team, sc.pos_x))


func _calc_attack_damage(attacker: SimCat, defender: SimCat, raw_atk: float) -> int:
	var damage := int(CatStats.calc_damage(raw_atk, defender.get_effective_def()))
	if damage <= 0:
		return 0
	if _rng.randf() < attacker.crit_rate:
		damage = int(float(damage) * (BASE_CRIT_DAMAGE_MULT + attacker.crit_damage_bonus))
	return int(float(damage) * (1.0 - defender.passive_damage_reduction))


# ── 主動技能計時與觸發 ───────────────────────────────

func _tick_skills(sc: SimCat, delta: float, t: float, events: Array,
		p_list: Array, e_list: Array) -> void:
	for i in range(sc.skill_cooldowns.size()):
		sc.skill_cooldowns[i] -= delta
		if sc.skill_cooldowns[i] <= 0.0:
			# 硬直中：冷卻繼續計時，硬直結束後才發動（延後至下一 tick）
			if sc.is_staggered:
				sc.skill_cooldowns[i] = 0.0   # 等硬直結束
				continue
			var skill_d: Dictionary = sc.data.active_skills_data[i]
			sc.skill_cooldowns[i] = sc.skill_max_cds[i]
			events.append(BattleEvent.skill_activate(t, sc.instance_id,
					skill_d.get("id", "")))
			_execute_skill(sc, skill_d, t, events, p_list, e_list)


func _execute_skill(caster: SimCat, skill_d: Dictionary, t: float, events: Array,
		p_list: Array, e_list: Array) -> void:
	var rank: int = caster.data.rank
	var enemy_list := p_list if caster.team == "enemy" else e_list
	var ally_list  := e_list if caster.team == "enemy" else p_list

	var effects: Array = skill_d.get("effects", [])
	for eff_idx in range(effects.size()):
		var eff: Dictionary = effects[eff_idx]
		var eff_type: String = eff.get("type", "")
		var value: float = _get_scaled_value(skill_d, eff_idx, eff.get("value", 0.0), rank)
		var target_str: String = eff.get("target", "enemy_front")

		match eff_type:
			"damage":
				var hits: int = eff.get("hits", 1)
				var target := _resolve_target(target_str, enemy_list, ally_list, caster)
				if target == null or not target.is_alive:
					continue
				for _h in range(hits):
					var dmg := _calc_attack_damage(caster, target, caster.get_effective_atk() * value)
					target.current_hp = maxi(0, target.current_hp - dmg)
					events.append(BattleEvent.hp_update(t, target.instance_id,
							target.current_hp, target.base_hp))
					if target.current_hp <= 0:
						_check_death(target, t, events)
						break
				# 額外擊退
				var extra_kb: float = eff.get("extra_knockback", 0.0)
				if extra_kb > 0.0 and target.is_alive:
					if caster.team == "player":
						target.pos_x += extra_kb
						if target.pos_x + CAT_HALF_W >= WALL_RIGHT:
							target.pos_x = WALL_RIGHT - CAT_HALF_W
					else:
						target.pos_x -= extra_kb
						if target.pos_x - CAT_HALF_W <= WALL_LEFT:
							target.pos_x = WALL_LEFT + CAT_HALF_W

			"buff_stat":
				var stat: String = eff.get("stat", "")
				var duration: float = eff.get("duration", 3.0)
				var value_type: String = eff.get("value_type", "percent")
				var buff_target := _resolve_buff_target(eff.get("target", "self"),
						caster, ally_list)
				if buff_target == null:
					continue
				buff_target.apply_buff("buff_stat", stat, value, value_type, duration)
				events.append(BattleEvent.buff_apply(t, buff_target.instance_id, duration))

			"reflect":
				var duration: float = eff.get("duration", 4.0)
				var scaled_val: float = _get_scaled_value(skill_d, eff_idx, eff.get("value", 0.0), rank)
				caster.apply_reflect(scaled_val, duration)
				events.append(BattleEvent.buff_apply(t, caster.instance_id, duration))


func _resolve_target(target_str: String, enemy_list: Array,
		ally_list: Array, caster: SimCat) -> SimCat:
	match target_str:
		"enemy_front":
			return _get_front(enemy_list)
		"enemy_lowest_hp":
			return _get_lowest_hp(enemy_list)
		"ally_lowest_hp":
			return _get_lowest_hp(ally_list)
		"self":
			return caster
		_:
			return _get_front(enemy_list)


func _resolve_buff_target(target_str: String, caster: SimCat,
		ally_list: Array) -> SimCat:
	match target_str:
		"self":   return caster
		"team":   return caster   # team buff 已在 apply 時處理；此處傳 self 備用
		_:        return caster


# ── 品階加成計算 ─────────────────────────────────────

## 取得套用品階加成後的 effect value
## rank_scaling 中找對應 effect_index 的 per_5_ranks
func _get_scaled_value(skill_d: Dictionary, eff_idx: int,
		base_value: float, rank: int) -> float:
	var rank_scaling: Array = skill_d.get("rank_scaling", [])
	for rs: Dictionary in rank_scaling:
		if rs.get("effect_index", -1) == eff_idx and rs.get("property", "") == "value":
			var per_5: float = rs.get("per_5_ranks", 0.0)
			return base_value + floorf(rank / 5.0) * per_5
	return base_value
