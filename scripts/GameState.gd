extends Node

## 全局遊戲狀態，跨場景共享

# ── 玩家配置 ──────────────────────────────────
var player_team: Array = ["milk_cat", "milk_cat", "milk_cat"]
var skill_delays: Dictionary = {}

# ── 關卡進度 ──────────────────────────────────
## 章節 1=新手I, 2=新手II, ...
var current_chapter: int = 1
## 世界 1-10
var current_world: int = 1
## 關卡 1-3（普通），0=Boss
var current_stage: int = 1
## stage 3 通關後為 true，顯示「挑戰Boss」按鈕
var boss_available: bool = false

# ── 常數 ──────────────────────────────────────
const OWNED_CATS: Array = ["milk_cat"]
const MAX_WORLD: int = 10
const MAX_CHAPTER: int = 10

const CHAPTER_NAMES: Array = [
	"",
	"新手I", "新手II", "新手III", "新手IV", "新手V",
	"中級I", "中級II", "中級III", "中級IV", "中級V",
]

# ── 關卡顯示 ──────────────────────────────────

func get_level_display() -> String:
	var chapter_name: String = _get_chapter_name()
	if current_stage == 0:
		return "%s %d-Boss" % [chapter_name, current_world]
	return "%s %d-%d" % [chapter_name, current_world, current_stage]

func _get_chapter_name() -> String:
	if current_chapter < CHAPTER_NAMES.size():
		return CHAPTER_NAMES[current_chapter]
	return "章節%d" % current_chapter

# ── 敵方生成（MVP：依難度調整數量，未來改為關卡設定檔）──

func get_enemy_ids() -> Array:
	var count: int
	if current_stage == 0:
		count = mini(1 + current_world, 5)
	else:
		count = mini(current_stage + maxi(current_world - 1, 0), 5)
	count = maxi(count, 1)
	var ids: Array = []
	for i in range(count):
		ids.append("test_enemy")
	return ids

# ── 進度邏輯 ──────────────────────────────────

## 勝利後推進關卡
func advance_after_win() -> void:
	if current_stage == 0:
		# Boss 勝利 → 下一世界
		boss_available = false
		current_world += 1
		if current_world > MAX_WORLD:
			current_world = 1
			current_chapter += 1
			if current_chapter > MAX_CHAPTER:
				current_chapter = MAX_CHAPTER  # 封頂（未來可擴充）
		current_stage = 1
	elif current_stage < 3:
		current_stage += 1
	else:
		# stage 3 通關 → 直接進 Boss
		current_stage = 0
		boss_available = false

## Boss 失敗後退回 stage 3，顯示「挑戰Boss」按鈕
func on_boss_fail() -> void:
	current_stage = 3
	boss_available = true

## 切換到 Boss 關卡
func challenge_boss() -> void:
	current_stage = 0

# ── 技能延遲 ──────────────────────────────────

func get_delay(slot_index: int) -> int:
	return skill_delays.get(slot_index, 0)

func set_delay(slot_index: int, delay: int) -> void:
	skill_delays[slot_index] = clampi(delay, 0, 9)
