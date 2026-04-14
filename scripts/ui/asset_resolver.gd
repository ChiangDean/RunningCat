class_name AssetResolver
extends RefCounted

const UI_ROOT := "res://assets/sprites/ui/"
const BACKGROUND_SHADER := preload("res://scripts/ui/background_desaturate_shader.gdshader")

const BACKGROUNDS := {
	"activity": UI_ROOT + "activity_background_v1.png",
	"arena": UI_ROOT + "arena_background_v1.png",
	"chat": UI_ROOT + "chat_background_v1.png",
	"config": UI_ROOT + "config_background_v1.png",
	"dungeon": UI_ROOT + "dungeon_background_v1.png",
	"enhance": UI_ROOT + "enhance_background_v1.png",
	"gacha": UI_ROOT + "gacha_background_v1.png",
	"mail": UI_ROOT + "mail_background_v1.png",
	"scooper": UI_ROOT + "scooper_background_v1.png",
	"shop": UI_ROOT + "shop_background_v1.png",
}

const CAT_ICONS := {
	"black_cat": UI_ROOT + "character_refs/black_cat/black_cat_icon_v1.png",
}

const CAT_BATTLE_IDLE := {
	"black_cat": "res://assets/sprites/battle/cats/black_cat/black_cat_idle_right.png",
}

const CAT_BATTLE_ANIMATIONS := {
	"black_cat": {
		"idle": "res://assets/sprites/battle/cats/black_cat/black_cat_idle_right.png",
		"run": "res://assets/sprites/battle/cats/black_cat/black_cat_run_right.png",
		"collide": "res://assets/sprites/battle/cats/black_cat/black_cat_collide_right.png",
		"knockback": "res://assets/sprites/battle/cats/black_cat/black_cat_knockback_right.png",
		"stagger": "res://assets/sprites/battle/cats/black_cat/black_cat_stagger_right.png",
		"skill": "res://assets/sprites/battle/cats/black_cat/black_cat_skill_right.png",
		"death_fly": "res://assets/sprites/battle/cats/black_cat/black_cat_death_fly_right.png",
	},
}

const GACHA_FRAMES := {
	"common": UI_ROOT + "gacha/rarity_common_frame_v1.png",
	"uncommon": UI_ROOT + "gacha/rarity_uncommon_frame_v1.png",
	"fine": UI_ROOT + "gacha/rarity_fine_frame_v1.png",
	"special": UI_ROOT + "gacha/rarity_special_frame_v1.png",
	"precious": UI_ROOT + "gacha/rarity_precious_frame_v1.png",
	"excellent": UI_ROOT + "gacha/rarity_excellent_frame_v1.png",
	"rare": UI_ROOT + "gacha/rarity_rare_frame_v1.png",
	"epic": UI_ROOT + "gacha/rarity_epic_frame_v1.png",
	"legendary": UI_ROOT + "gacha/rarity_legendary_frame_v1.png",
}

const SCOOPER_EQUIPMENT := {
	1: UI_ROOT + "scooper_equipment/food_bowl.png",
	2: UI_ROOT + "scooper_equipment/scratcher.png",
	3: UI_ROOT + "scooper_equipment/teaser_wand.png",
	4: UI_ROOT + "scooper_equipment/grooming_brush.png",
	5: UI_ROOT + "scooper_equipment/camera.png",
	6: UI_ROOT + "scooper_equipment/warm_pad.png",
	7: UI_ROOT + "scooper_equipment/cardboard_box.png",
	8: UI_ROOT + "scooper_equipment/toy_doll.png",
}

const SCOOPER_ABILITIES := {
	1: UI_ROOT + "scooper_abilities/diligent_scooper.png",
	2: UI_ROOT + "scooper_abilities/golden_scooper.png",
	3: UI_ROOT + "scooper_abilities/overtime_photo.png",
	4: UI_ROOT + "scooper_abilities/double_speed.png",
	5: UI_ROOT + "scooper_abilities/triple_speed.png",
	6: UI_ROOT + "scooper_abilities/instant_finish.png",
}

const SHOP_BUNDLES := {
	1: UI_ROOT + "shop_bundles/starter_cleanup_set.png",
	2: UI_ROOT + "shop_bundles/rush_combo_set.png",
	3: UI_ROOT + "shop_bundles/ambush_hunter_set.png",
	4: UI_ROOT + "shop_bundles/guard_tenacity_set.png",
	5: UI_ROOT + "shop_bundles/night_crit_set.png",
	6: UI_ROOT + "shop_bundles/frontline_tank_set.png",
	7: UI_ROOT + "shop_bundles/rush_combo_set.png",
	8: UI_ROOT + "shop_bundles/frontline_tank_set.png",
	9: UI_ROOT + "shop_bundles/rush_combo_set.png",
	10: UI_ROOT + "shop_bundles/ambush_hunter_set.png",
	11: UI_ROOT + "shop_bundles/guard_tenacity_set.png",
	12: UI_ROOT + "shop_bundles/starter_cleanup_set.png",
	13: UI_ROOT + "shop_bundles/frontline_tank_set.png",
	14: UI_ROOT + "shop_bundles/starter_cleanup_set.png",
	15: UI_ROOT + "shop_bundles/starter_cleanup_set.png",
	16: UI_ROOT + "shop_bundles/rush_combo_set.png",
	17: UI_ROOT + "shop_bundles/starter_cleanup_set.png",
	18: UI_ROOT + "shop_bundles/frontline_tank_set.png",
}


static func make_fullscreen_background(slot: String) -> TextureRect:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = load_texture(BACKGROUNDS.get(slot, ""))
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.38, 0.38, 0.42, 1.0)
	var material := ShaderMaterial.new()
	material.shader = BACKGROUND_SHADER
	material.set_shader_parameter("desaturate_strength", 0.42)
	background.material = material

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0.02, 0.03, 0.05, 0.48)
	background.add_child(overlay)
	return background


static func load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var texture := load(path)
	return texture as Texture2D


static func resolve_catalog_path(raw_path: Variant) -> String:
	var image_path := str(raw_path if raw_path != null else "").strip_edges()
	if image_path == "":
		return ""
	if image_path.begins_with("res://"):
		return image_path
	if image_path.begins_with("catalog/"):
		var suffix := image_path.trim_prefix("catalog/")
		var parts := suffix.split("/")
		if parts.size() < 2:
			return ""
		var folder := str(parts[0])
		var key := str(parts[1])
		match folder:
			"currency", "consumable":
				if key == "gold":
					return UI_ROOT + "rewards/gold.png.png"
				return UI_ROOT + "rewards/%s.png" % key
			"dungeon":
				return UI_ROOT + "dungeon/%s.png" % key
			"arena":
				return UI_ROOT + "arena_ranks/%s.png" % key
			"memory":
				return UI_ROOT + "memory/%s.png" % key
			"treasure":
				return UI_ROOT + "treasure/%s.png" % key
			"cat":
				return CAT_ICONS.get(key, "")
	return image_path


static func resolve_cat_icon(cat_id: String) -> Texture2D:
	return load_texture(CAT_ICONS.get(cat_id, ""))


static func resolve_cat_battle_idle(cat_id: String) -> Texture2D:
	return load_texture(CAT_BATTLE_IDLE.get(cat_id, ""))


static func resolve_cat_battle_animation_path(cat_id: String, animation_name: String) -> String:
	var animation_map: Dictionary = CAT_BATTLE_ANIMATIONS.get(cat_id, {})
	return str(animation_map.get(animation_name, ""))


static func resolve_gacha_frame(result: Dictionary) -> Texture2D:
	var rarity_key := str(result.get("rarityKey", "")).to_lower()
	if rarity_key == "":
		rarity_key = str(result.get("rarityType", "")).to_lower()
	return load_texture(GACHA_FRAMES.get(rarity_key, ""))


static func resolve_equipment_icon(item: Dictionary) -> Texture2D:
	return load_texture(SCOOPER_EQUIPMENT.get(int(item.get("equipmentId", 0)), ""))


static func resolve_ability_icon(item: Dictionary) -> Texture2D:
	return load_texture(SCOOPER_ABILITIES.get(int(item.get("abilityId", 0)), ""))


static func resolve_bundle_art(bundle: Dictionary) -> Texture2D:
	return load_texture(SHOP_BUNDLES.get(int(bundle.get("bundleId", 0)), ""))


static func create_icon_rect(texture: Texture2D, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.texture = texture
	return rect
