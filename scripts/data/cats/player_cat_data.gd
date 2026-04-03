class_name PlayerCatData
extends Resource

## 玩家的貓咪存檔模型（每位玩家各自一份）
## 只記錄「玩家改變了什麼」，不重複存 default 的原始數值
## 執行時搭配 CatData（default）合併計算出實際數值

# ── 識別 ──────────────────────────────────────────────
var cat_id: String = ""       # 對應 default/cats/{cat_id}.json
var level: int = 1

# ── 強化記錄（只存投入量，實際數值由公式計算）─────────
var cat_food_fed: int = 0     # 投入乾糧總量 → 影響 HP / ATK / DEF
var cat_can_fed: int = 0      # 投入罐頭總量 → 影響 Weight
var cat_shards: int = 0       # 持有鬍鬚數量 → 升星/技能升級

# ── 配置設定（出戰畫面設定，每次可調整）────────────────
## 格式：[{ "skill_id": "shield_bash", "initial_delay": 0 }]
var active_skill_settings: Array = []

# ── 未來擴充（加欄位不影響舊存檔）──────────────────────
# var star_level: int = 0
# var equipped_item_ids: Array = []


## 從 Dictionary 解析（對應 JSON 或 Firebase 讀取的資料）
static func from_dict(data: Dictionary) -> PlayerCatData:
	var p := PlayerCatData.new()
	p.cat_id = data.get("cat_id", "")
	p.level = data.get("level", 1)
	p.cat_food_fed = data.get("cat_food_fed", 0)
	p.cat_can_fed = data.get("cat_can_fed", 0)
	p.cat_shards = data.get("cat_shards", 0)
	p.active_skill_settings = data.get("active_skill_settings", [])
	return p


## 轉為 Dictionary（用於存檔到 JSON 或 Firebase）
func to_dict() -> Dictionary:
	return {
		"cat_id": cat_id,
		"level": level,
		"cat_food_fed": cat_food_fed,
		"cat_can_fed": cat_can_fed,
		"cat_shards": cat_shards,
		"active_skill_settings": active_skill_settings,
	}
