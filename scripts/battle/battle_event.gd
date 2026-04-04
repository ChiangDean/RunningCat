class_name BattleEvent
extends RefCounted

## 戰鬥事件資料（模擬器輸出，供視覺層播放用）

enum Type {
	SPAWN,          # 貓咪出場
	COLLISION,      # 碰撞（含傷害+回彈）
	HP_UPDATE,      # 血量更新（技能傷害）
	SKILL_ACTIVATE, # 主動技能發動
	BUFF_APPLY,     # Buff / Debuff 施加（供 UI 顯示持續狀態用）
	CAT_DIE,        # 貓咪死亡
	BATTLE_END,     # 戰鬥結束
}

var type: Type
var timestamp: float = 0.0

# 通用欄位
var cat_id: int = -1
var team: String = ""

# SPAWN / COLLISION 位置
var pos_x: float = 0.0

# 血量相關
var current_hp: int = 0
var max_hp: int = 0

# COLLISION：回彈距離（正 = 往右，負 = 往左）
var knockback: float = 0.0

# SKILL_ACTIVATE
var skill_id: String = ""

# BUFF_APPLY：持續時間（秒），ui 用於顯示外框
var buff_duration: float = 0.0

# BATTLE_END 結果："WIN" / "LOSE" / "TIMEOUT"
var result: String = ""

# ── 工廠方法 ──────────────────────────────

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

static func collision(time: float, id: int, x: float, hp: int, kb: float) -> BattleEvent:
	var e := BattleEvent.new()
	e.type = Type.COLLISION
	e.timestamp = time
	e.cat_id = id
	e.pos_x = x
	e.current_hp = hp
	e.knockback = kb
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
