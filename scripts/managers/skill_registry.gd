class_name SkillRegistry
extends Node

const StaticGameData = preload("res://scripts/data/static_game_data.gd")

var _passive: Dictionary = {}
var _active: Dictionary = {}


func _ready() -> void:
	_passive = StaticGameData.get_all_passive_skills()
	_active = StaticGameData.get_all_active_skills()


func get_skill(id: String) -> Dictionary:
	if _passive.has(id):
		return _passive[id].duplicate(true)
	if _active.has(id):
		return _active[id].duplicate(true)
	return {}


func get_passive(id: String) -> Dictionary:
	return _passive.get(id, {}).duplicate(true)


func get_active(id: String) -> Dictionary:
	return _active.get(id, {}).duplicate(true)


func get_all_passive() -> Dictionary:
	return _passive.duplicate(true)


func get_all_active() -> Dictionary:
	return _active.duplicate(true)
