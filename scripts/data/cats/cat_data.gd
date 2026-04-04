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

# ── 稀有度 ────────────────────────────────────────────
var rarity: String = "common"
var gacha_available: bool = false

# ── 強化成長值 ─────────────────────────────────────────
var enhancement_growth: Dictionary = {"hp": 1.5, "atk": 1.0, "def": 0.5}

# ── 品階成長值 ─────────────────────────────────────────
var rank_growth: Dictionary = {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0}

# ── 當前品階（apply_rank_bonus 後設定，供模擬器計算技能加成）──
var rank: int = 0

# ── 技能參照（原始 id 列表） ───────────────────────────
var passive_skill_ids: Array = []
## 格式：[{ "id": "milk_shield", "initial_delay": 0, "cooldown": 5.0 }]
var active_skill_configs: Array = []

# ── 已解析技能 Dictionary（模擬器 / UI 使用）──────────
## 被動技能完整資料（含 effects、rank_scaling）
var passive_skills_data: Array = []
## 主動技能完整資料：技能 JSON 合併 cat config（含 initial_delay、cooldown override）
var active_skills_data: Array = []


## 從 JSON 檔案載入，自動執行 migration 並解析技能
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

	cat.rarity          = data.get("rarity",          "common")
	cat.gacha_available = data.get("gacha_available", false)

	var default_growth: Dictionary = {"hp": 1.5, "atk": 1.0, "def": 0.5}
	var growth: Dictionary = data.get("enhancement_growth", {})
	cat.enhancement_growth = {
		"hp":  growth.get("hp",  default_growth["hp"]),
		"atk": growth.get("atk", default_growth["atk"]),
		"def": growth.get("def", default_growth["def"]),
	}

	var default_rank_growth: Dictionary = {"hp_percent": 1.0, "atk_percent": 1.0, "def_percent": 1.0}
	var rg: Dictionary = data.get("rank_growth", {})
	cat.rank_growth = {
		"hp_percent":  rg.get("hp_percent",  default_rank_growth["hp_percent"]),
		"atk_percent": rg.get("atk_percent", default_rank_growth["atk_percent"]),
		"def_percent": rg.get("def_percent", default_rank_growth["def_percent"]),
	}

	cat.passive_skill_ids    = data.get("passive_skills", [])
	cat.active_skill_configs = data.get("active_skills", [])

	# ── 解析技能完整資料 ──────────────────────────────
	cat._load_skill_data()

	return cat


## 解析技能 JSON 並合併到 passive_skills_data / active_skills_data
func _load_skill_data() -> void:
	passive_skills_data.clear()
	active_skills_data.clear()

	for sid: String in passive_skill_ids:
		var d := _read_skill_json("res://data/default/skills/passive/" + sid + ".json")
		if not d.is_empty():
			passive_skills_data.append(d)

	for cfg: Dictionary in active_skill_configs:
		var sid: String = cfg.get("id", "")
		var d := _read_skill_json("res://data/default/skills/active/" + sid + ".json")
		if not d.is_empty():
			d = d.duplicate(true)
			# cat config 的 initial_delay / cooldown 覆蓋技能預設值
			d["initial_delay"] = cfg.get("initial_delay", 0)
			if cfg.has("cooldown"):
				d["cooldown"] = cfg["cooldown"]
			active_skills_data.append(d)


static func _read_skill_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("CatData: 找不到技能檔案：" + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	var result = json.get_data()
	if result is Dictionary:
		return result
	return {}


## 將玩家強化加成直接疊加到本實例的屬性上
func apply_enhancement(player_cat: PlayerCatData) -> void:
	var food_levels: int = player_cat.cat_food_level - 1
	var sfp: Dictionary = player_cat.special_food_points

	max_hp  += int((food_levels + sfp.get("hp",  0)) * enhancement_growth.get("hp",  0.0))
	atk     += int((food_levels + sfp.get("atk", 0)) * enhancement_growth.get("atk", 0.0))
	defense += int((food_levels + sfp.get("def", 0)) * enhancement_growth.get("def", 0.0))


## 將品階百分比加成疊加到當前屬性，並記錄 rank 供技能加成計算
func apply_rank_bonus(player_cat: PlayerCatData) -> void:
	rank = player_cat.rank
	if rank <= 0:
		return
	var rg: Dictionary = rank_growth
	max_hp  = int(max_hp  * (1.0 + rank * rg.get("hp_percent",  1.0) / 100.0))
	atk     = int(atk     * (1.0 + rank * rg.get("atk_percent", 1.0) / 100.0))
	defense = int(defense * (1.0 + rank * rg.get("def_percent", 1.0) / 100.0))


## 計算技能品階加成後的 effect value
## 每 5 品階：effect.value += per_5_ranks
static func get_scaled_effect_value(base_value: float, per_5_ranks: float, current_rank: int) -> float:
	return base_value + floorf(current_rank / 5.0) * per_5_ranks
