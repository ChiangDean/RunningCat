class_name CatData
extends Resource

## 貓咪資料容器，從 JSON 載入
## 新增屬性只需在此加欄位並給預設值，舊 JSON 不會壞掉
## 欄位改名只需在 CatDataMigrator.STAT_ALIASES 加一行 alias

# ── 識別 ──────────────────────────────────────────────
var id: String = ""
var display_name: String = ""
var cat_type: String = "base"  # 對應 CatRegistry 的類型鍵值

# ── 基礎屬性（新增屬性在此加，並給預設值） ────────────
var max_hp: int = 100
var atk: int = 10
var defense: int = 0
var speed: float = 100.0
var weight: float = 100.0
# 未來可新增（不影響舊 JSON）：
# var ignore_def: float = 0.0
# var crit_rate: float = 0.0

# ── 強化成長值（每級/每點的固定加成） ─────────────────
## 格式：{ "hp": float, "atk": float, "def": float }
## 普通乾糧每升一級，三個屬性各加對應值
## 特殊乾糧每分配一點到某屬性，該屬性加對應值
var enhancement_growth: Dictionary = {"hp": 1.5, "atk": 1.0, "def": 0.5}

# ── 技能參照 ──────────────────────────────────────────
var passive_skill_ids: Array = []
## 格式：[{ "id": "shield_bash", "initial_delay": 0, "cooldown": 5.0 }]
var active_skill_configs: Array = []


## 從 JSON 檔案載入，自動執行 migration
static func from_json_file(path: String) -> CatData:
	if not FileAccess.file_exists(path):
		push_error("CatData: 找不到檔案：" + path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("CatData: JSON 解析失敗：" + path)
		return null

	var raw: Dictionary = json.get_data()
	var migrated: Dictionary = CatDataMigrator.migrate(raw)
	return _from_dict(migrated)


static func _from_dict(data: Dictionary) -> CatData:
	var cat := CatData.new()
	cat.id = data.get("id", "")
	cat.display_name = data.get("display_name", "")
	cat.cat_type = data.get("cat_type", "base")

	var stats: Dictionary = data.get("base_stats", {})
	cat.max_hp   = stats.get("max_hp",   100)
	cat.atk      = stats.get("atk",      10)
	cat.defense  = stats.get("defense",  0)
	cat.speed    = stats.get("speed",    100.0)
	cat.weight   = stats.get("weight",   100.0)

	var default_growth: Dictionary = {"hp": 1.5, "atk": 1.0, "def": 0.5}
	var growth: Dictionary = data.get("enhancement_growth", {})
	cat.enhancement_growth = {
		"hp":  growth.get("hp",  default_growth["hp"]),
		"atk": growth.get("atk", default_growth["atk"]),
		"def": growth.get("def", default_growth["def"]),
	}

	cat.passive_skill_ids   = data.get("passive_skills", [])
	cat.active_skill_configs = data.get("active_skills", [])

	return cat


## 將玩家強化加成直接疊加到本實例的屬性上
## 普通乾糧：全屬性各加 (level-1) * growth
## 特殊乾糧：各屬性加 special_points * growth
func apply_enhancement(player_cat: PlayerCatData) -> void:
	var food_levels: int = player_cat.cat_food_level - 1
	var sfp: Dictionary = player_cat.special_food_points

	max_hp  += int((food_levels + sfp.get("hp",  0)) * enhancement_growth.get("hp",  0.0))
	atk     += int((food_levels + sfp.get("atk", 0)) * enhancement_growth.get("atk", 0.0))
	defense += int((food_levels + sfp.get("def", 0)) * enhancement_growth.get("def", 0.0))
