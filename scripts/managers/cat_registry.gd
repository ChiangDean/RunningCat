class_name CatRegistry
extends Node

var _type_map: Dictionary = {
	"tank": TankCat,
	"assassin": AssassinCat,
	"defensive": DefensiveCat,
	"flying": FlyingCat,
	"elemental": ElementalCat,
	"cute": CuteCat,
	"speed": SpeedCat,
	"bouncer": BouncerCat,
	"base": BaseCat,
}


func create_cat(cat_id: String, team: String, skill_states: Array = [], player_cat: PlayerCatData = null) -> BaseCat:
	var data := CatData.from_json_file(cat_id + ".json")
	if data == null:
		push_error("CatRegistry: failed to load cat " + cat_id)
		return null

	if player_cat != null:
		data.apply_enhancement(player_cat)

	var CatClass = _type_map.get(data.cat_type, BaseCat)
	var cat: BaseCat = CatClass.new()
	cat.setup(data, team, skill_states)
	return cat


func register_type(type_name: String, cat_class) -> void:
	_type_map[type_name] = cat_class


static func get_cat_display_name_with_lv(cat_id: String, lv: int) -> String:
	var data := CatData.from_json_file(cat_id + ".json")
	if data != null:
		return "%sLv%d" % [data.display_name, lv]
	return "%sLv%d" % [cat_id, lv]
