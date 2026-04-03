class_name BaseCat
extends CharacterBody2D

## 所有貓咪的基底類別
## 子類別透過 override 特定方法來客製化行為，不需修改此檔案

# ── 信號 ──────────────────────────────────────────────
signal died(cat: BaseCat)
signal hp_changed(current: int, maximum: int)

# ── 資料參照 ──────────────────────────────────────────
var data: CatData
var team: String = "player"      # "player" 或 "enemy"
var facing_direction: int = 1    # 1=向右，-1=向左

# ── 運行時狀態 ────────────────────────────────────────
var current_hp: int = 0
var is_staggered: bool = false
var stagger_timer: float = 0.0
var is_alive: bool = true

## 主動技能運行狀態
## 格式：[{ "skill": ActiveSkillData, "timer": float }]
var _active_skill_states: Array = []


# ── 初始化 ────────────────────────────────────────────

func setup(cat_data: CatData, cat_team: String, skill_states: Array = []) -> void:
	data = cat_data
	team = cat_team
	current_hp = data.max_hp
	facing_direction = 1 if team == "player" else -1
	_active_skill_states = skill_states


# ── 主循環 ────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_process_stagger(delta)
	_process_active_skills(delta)
	if not is_staggered:
		_move_forward(delta)


## 每幀前進，子類別可 override（例如刺客加速）
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


## 發動主動技能，子類別 override 實作具體效果
func _trigger_active_skill(_skill: ActiveSkillData) -> void:
	pass


# ── 戰鬥方法 ──────────────────────────────────────────

## 受到傷害（ignore_def 為未來無視防禦屬性，預設 0）
func take_damage(atk: float, ignore_def: float = 0.0) -> void:
	if not is_alive:
		return
	var dmg: float = CatStats.calc_damage(atk, data.defense, ignore_def)
	current_hp -= int(dmg)
	emit_signal("hp_changed", current_hp, data.max_hp)
	if current_hp <= 0:
		_die()


## 與敵方碰撞時呼叫，子類別可 override（例如防守貓加反彈傷害）
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


## 撞牆時呼叫，子類別可 override（例如坦克貓減少撞牆硬直）
func on_wall_bounce() -> void:
	is_staggered = true
	stagger_timer = get_wall_stagger_time()
	facing_direction *= -1


# ── 硬直時間（子類別可 override 調整） ───────────────

func get_stagger_time() -> float:
	return CatStats.STAGGER_TIME


func get_wall_stagger_time() -> float:
	return CatStats.WALL_STAGGER_TIME


# ── 死亡 ──────────────────────────────────────────────

func _die() -> void:
	is_alive = false
	emit_signal("died", self)
	_play_death_animation()


## 死亡動畫：拋物線彈飛出畫面，子類別可 override 客製化
func _play_death_animation() -> void:
	queue_free()
