class_name CatRegistry
extends Node

## 貓咪註冊中心
## 新增貓咪類型只需在 _type_map 加一行，不需改其他程式碼
## 新增貓咪角色只需新增 JSON 檔案

const CAT_DATA_PATH: String = "res://data/default/cats/"

## 類型對照表：cat_type 字串 → GDScript 類別
## 新增特殊型只需在此加入一行
var _type_map: Dictionary = {
	"tank":      TankCat,
	"assassin":  AssassinCat,
	"defensive": DefensiveCat,
	"flying":    FlyingCat,
	"elemental": ElementalCat,
	"cute":      CuteCat,
	"speed":     SpeedCat,
	"bouncer":   BouncerCat,
	"base":      BaseCat,  # fallback
}


## 建立貓咪節點，自動依 cat_type 選擇對應子類別
## player_cat 若提供，會將強化加成疊加到 CatData 後再建立
func create_cat(cat_id: String, team: String, skill_states: Array = [], player_cat: PlayerCatData = null) -> BaseCat:
	var path: String = CAT_DATA_PATH + cat_id + ".json"
	var data := CatData.from_json_file(path)
	if data == null:
		push_error("CatRegistry: 無法載入貓咪：" + cat_id)
		return null

	if player_cat != null:
		data.apply_enhancement(player_cat)

	var CatClass = _type_map.get(data.cat_type, BaseCat)
	var cat: BaseCat = CatClass.new()
	cat.setup(data, team, skill_states)
	return cat


## 動態註冊新類型，不需修改 _type_map（例如 plugin 系統用）
func register_type(type_name: String, cat_class) -> void:
	_type_map[type_name] = cat_class


# 共用：名稱+等級
static func get_cat_display_name_with_lv(cat_id: String, lv: int) -> String:
	var data := CatData.from_json_file("res://data/default/cats/" + cat_id + ".json")
	if data != null:
		return "%sLv%d" % [data.display_name, lv]
	return "%sLv%d" % [cat_id, lv]
