class_name PlayerData
extends Resource

## 玩家全域資源存檔
## 新增資源欄位只需加上預設值，舊存檔讀取時不會因缺少欄位而壞掉

const SAVE_PATH: String = "res://data/saves/player_data.json"

# ── 資源 ───────────────────────────────────────────────
var cat_food: int = 0           # 普通乾糧
var special_cat_food: int = 0   # 特殊乾糧
var gold: int = 0               # 金幣
var diamonds: int = 0           # 鑽石（未來消費強化重置費用）
# 未來擴充（加欄位不影響舊存檔）：
# var cat_cans: int = 0
# var cat_shards: int = 0


# ── 載入 ───────────────────────────────────────────────

static func load_or_default() -> PlayerData:
	if not FileAccess.file_exists(SAVE_PATH):
		return PlayerData.new()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("PlayerData: 存檔解析失敗，使用預設值")
		return PlayerData.new()
	file.close()
	return _from_dict(json.get_data())


static func _from_dict(data: Dictionary) -> PlayerData:
	var p := PlayerData.new()
	p.cat_food        = data.get("cat_food",        0)
	p.special_cat_food = data.get("special_cat_food", 0)
	p.gold            = data.get("gold",            0)
	p.diamonds        = data.get("diamonds",        0)
	return p


# ── 儲存 ───────────────────────────────────────────────

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("PlayerData: 無法寫入存檔：" + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_to_dict(), "\t"))
	file.close()


func _to_dict() -> Dictionary:
	return {
		"schema_version": 1,
		"cat_food":         cat_food,
		"special_cat_food": special_cat_food,
		"gold":             gold,
		"diamonds":         diamonds,
	}
