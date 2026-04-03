extends Node

## 全局遊戲狀態，跨場景共享

# ── 玩家配置 ──────────────────────────────────
## 出戰隊伍（cat_id 陣列，最多 5 隻）
var player_team: Array = ["milk_cat", "milk_cat", "milk_cat"]
## 技能起始延遲 dict：slot_index (int) -> delay (int 0-9)
var skill_delays: Dictionary = {}

# ── 關卡進度 ──────────────────────────────────
var current_level: String = "1-1"
var cleared_levels: Array = []

# ── 可用貓咪（MVP：硬編碼，未來改從存檔讀取）──
const OWNED_CATS: Array = ["milk_cat"]

# ── 關卡定義 ─────────────────────────────────
const LEVELS: Dictionary = {
	"1-1": {
		"world": 1, "stage": 1, "is_boss": false,
		"enemy_ids": ["test_enemy", "test_enemy"]
	},
	"1-2": {
		"world": 1, "stage": 2, "is_boss": false,
		"enemy_ids": ["test_enemy", "test_enemy", "test_enemy"]
	},
	"1-3": {
		"world": 1, "stage": 3, "is_boss": false,
		"enemy_ids": ["test_enemy", "test_enemy", "test_enemy", "test_enemy"]
	},
	"1-Boss": {
		"world": 1, "stage": 4, "is_boss": true,
		"enemy_ids": ["test_enemy", "test_enemy", "test_enemy", "test_enemy", "test_enemy"]
	},
}
const WORLD_ORDER: Array = ["1-1", "1-2", "1-3", "1-Boss"]

# ── 公開方法 ──────────────────────────────────

func is_level_unlocked(level_id: String) -> bool:
	var idx: int = WORLD_ORDER.find(level_id)
	if idx <= 0:
		return true
	return WORLD_ORDER[idx - 1] in cleared_levels

func get_enemy_ids() -> Array:
	if current_level in LEVELS:
		return LEVELS[current_level]["enemy_ids"]
	return []

func mark_cleared(level_id: String) -> void:
	if level_id not in cleared_levels:
		cleared_levels.append(level_id)

func get_delay(slot_index: int) -> int:
	return skill_delays.get(slot_index, 0)

func set_delay(slot_index: int, delay: int) -> void:
	skill_delays[slot_index] = clampi(delay, 0, 9)
