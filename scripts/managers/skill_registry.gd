class_name SkillRegistry
extends Node

var _passive: Dictionary = {}
var _active: Dictionary = {}


func _ready() -> void:
	_reload_from_cache()


func _reload_from_cache() -> void:
	_passive = {}
	_active = {}

	for item: Variant in GameState.passive_skill_catalog:
		if item is Dictionary:
			_passive[str(item.get("id", ""))] = item

	for item: Variant in GameState.active_skill_catalog:
		if item is Dictionary:
			_active[str(item.get("id", ""))] = item


func get_skill(id: String) -> Dictionary:
	if _passive.has(id):
		return _passive[id]
	if _active.has(id):
		return _active[id]
	return {}


func get_passive(id: String) -> Dictionary:
	return _passive.get(id, {})


func get_active(id: String) -> Dictionary:
	return _active.get(id, {})


func get_all_passive() -> Dictionary:
	return _passive


func get_all_active() -> Dictionary:
	return _active
