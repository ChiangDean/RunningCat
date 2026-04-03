class_name PlayerCatData
extends Resource

## 玩家的貓咪存檔模型（每位玩家各自一份）
## 只記錄「玩家改變了什麼」，不重複存 default 的原始數值
## 執行時搭配 CatData（default）合併計算出實際數值

const SAVE_DIR: String = "res://data/saves/player_cats/"
const MAX_CAT_FOOD_LEVEL: int = 30

# ── 識別 ──────────────────────────────────────────────
var cat_id: String = ""

# ── 普通乾糧升級 ───────────────────────────────────────
## 當前等級（預設 1），每升一級花費 (lv+1)² 普通乾糧
## 升級後全屬性依 CatData.enhancement_growth 成長
var cat_food_level: int = 1

# ── 特殊乾糧分配 ───────────────────────────────────────
## 玩家自由分配給各屬性的點數；第 N 點（0-based）花費 N+1 特殊乾糧
## 格式：{ "hp": int, "atk": int, "def": int }
var special_food_points: Dictionary = {"hp": 0, "atk": 0, "def": 0}

# ── 其他強化（預留，不影響現有邏輯） ─────────────────────
var cat_can_fed: int = 0      # 罐頭投入量 → Weight（未來實作）
var cat_shards: int = 0       # 持有鬍鬚 → 升星/技能升級（未來實作）

# ── 配置設定 ──────────────────────────────────────────
## 格式：[{ "skill_id": "shield_bash", "initial_delay": 0 }]
var active_skill_settings: Array = []


# ── 費用計算（純函式）─────────────────────────────────

## 升一級的普通乾糧費用：cost(lv) = (lv + 1)²
static func cat_food_cost_for_level(current_level: int) -> int:
	return (current_level + 1) * (current_level + 1)

## 從 from_level 升到 to_level 的總費用
static func cat_food_total_cost(from_level: int, to_level: int) -> int:
	var total := 0
	for lv in range(from_level, to_level):
		total += cat_food_cost_for_level(lv)
	return total

## 特殊乾糧下一點的費用：已分配總點數 + 1
static func special_food_next_cost(total_points_allocated: int) -> int:
	return total_points_allocated + 1

## 計算目前已花費的特殊乾糧總量
## 設 n = total_points_allocated - 1（0-based index）
## f(n) = 0+1+2+...+(n+1) = (n+1)(n+2)/2
## 代換回 T（total_points_allocated = n+1）：T*(T+1)/2
## 範例：已分配 3 點 → 1+2+3 = 6 → 3*4/2 = 6
static func special_food_total_spent(total_points_allocated: int) -> int:
	return total_points_allocated * (total_points_allocated + 1) / 2


# ── 查詢輔助 ──────────────────────────────────────────

func get_total_special_points() -> int:
	return (special_food_points.get("hp", 0)
		+ special_food_points.get("atk", 0)
		+ special_food_points.get("def", 0))


# ── 序列化 ────────────────────────────────────────────

## 從 Dictionary 解析，自動處理舊格式 migration
static func from_dict(data: Dictionary) -> PlayerCatData:
	var p := PlayerCatData.new()
	p.cat_id = data.get("cat_id", "")

	# Migration：舊格式使用 cat_food_fed，新格式使用 cat_food_level
	if data.has("cat_food_level"):
		p.cat_food_level = data.get("cat_food_level", 1)
	else:
		# 舊存檔無法換算等級，重置為 1（素材無法退回）
		p.cat_food_level = 1

	var sfp: Dictionary = data.get("special_food_points", {})
	p.special_food_points = {
		"hp":  sfp.get("hp",  0),
		"atk": sfp.get("atk", 0),
		"def": sfp.get("def", 0),
	}
	p.cat_can_fed = data.get("cat_can_fed", 0)
	p.cat_shards  = data.get("cat_shards",  0)
	p.active_skill_settings = data.get("active_skill_settings", [])
	return p


func to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"cat_id": cat_id,
		"cat_food_level": cat_food_level,
		"special_food_points": special_food_points.duplicate(),
		"cat_can_fed": cat_can_fed,
		"cat_shards": cat_shards,
		"active_skill_settings": active_skill_settings,
	}


# ── 檔案 IO ───────────────────────────────────────────

static func load_or_default(p_cat_id: String) -> PlayerCatData:
	var path := SAVE_DIR + p_cat_id + ".json"
	if not FileAccess.file_exists(path):
		var p := PlayerCatData.new()
		p.cat_id = p_cat_id
		return p
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		var p := PlayerCatData.new()
		p.cat_id = p_cat_id
		return p
	file.close()
	return from_dict(json.get_data())


func save() -> void:
	var path := SAVE_DIR + cat_id + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PlayerCatData: 無法寫入存檔：" + path)
		return
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
