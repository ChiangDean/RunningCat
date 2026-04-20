class_name AssetResolver
extends RefCounted

const UI_ROOT := "res://assets/sprites/ui/"
const BACKGROUND_SHADER := preload("res://scripts/ui/background_desaturate_shader.gdshader")
const DEFAULT_PROFILE_AVATAR_ID := "black_cat"
const CAT_CARD_FRAME := UI_ROOT + "cards/cat_card_frame_homey_v1.png"
const CAT_CARD_EMPTY_SILHOUETTE := UI_ROOT + "cards/cat_card_empty_silhouette_v1.png"
const CAT_CARD_SQUARE_FRAMES := {
	"common": UI_ROOT + "cards/square/cat_card_square_common.png",
	"uncommon": UI_ROOT + "cards/square/cat_card_square_common.png",
	"fine": UI_ROOT + "cards/square/cat_card_square_common.png",
	"special": UI_ROOT + "cards/square/cat_card_square_common.png",
	"precious": UI_ROOT + "cards/square/cat_card_square_common.png",
	"excellent": UI_ROOT + "cards/square/cat_card_square_common.png",
	"rare": UI_ROOT + "cards/square/cat_card_square_common.png",
	"epic": UI_ROOT + "cards/square/cat_card_square_common.png",
	"legendary": UI_ROOT + "cards/square/cat_card_square_common.png",
	"master": UI_ROOT + "cards/square/cat_card_square_common.png",
}
const CAT_TYPE_ICONS := {
	"tank": UI_ROOT + "cards/type_icons/cat_type_tank_v1.png",
	"assassin": UI_ROOT + "cards/type_icons/cat_type_assassin_v1.png",
	"defensive": UI_ROOT + "cards/type_icons/cat_type_defensive_v1.png",
	"flying": UI_ROOT + "cards/type_icons/cat_type_flying_v1.png",
	"elemental": UI_ROOT + "cards/type_icons/cat_type_elemental_v1.png",
	"cute": UI_ROOT + "cards/type_icons/cat_type_cute_v1.png",
	"speed": UI_ROOT + "cards/type_icons/cat_type_speed_v1.png",
	"bouncer": UI_ROOT + "cards/type_icons/cat_type_bouncer_v1.png",
	"base": UI_ROOT + "cards/type_icons/cat_type_tank_v1.png",
}

const BACKGROUNDS := {
	"activity": UI_ROOT + "activity_background_v1.png",
	"arena": UI_ROOT + "arena_background_v1.png",
	"chat": UI_ROOT + "chat_background_v1.png",
	"config": UI_ROOT + "config_background_v1.png",
	"dungeon": UI_ROOT + "dungeon_background_v1.png",
	"enhance": UI_ROOT + "enhance_background_v1.png",
	"expedition": UI_ROOT + "activity_background_v1.png",
	"gacha": UI_ROOT + "gacha_background_v1.png",
	"mail": UI_ROOT + "mail_background_v1.png",
	"scooper": UI_ROOT + "scooper_background_v1.png",
	"shop": UI_ROOT + "shop_background_v1.png",
}

const CAT_ICONS := {
	"black_cat": UI_ROOT + "character_refs/black_cat/black_cat_icon_v1.png",
	"calico_cat": UI_ROOT + "character_refs/calico_cat/calico_cat_icon_v1.png",
	"milk_cat": UI_ROOT + "character_refs/milk_cat/milk_cat_icon_v1.png",
	"ninja_cat": UI_ROOT + "character_refs/ninja_cat/ninja_cat_icon_v1.png",
	"orange_cat": UI_ROOT + "character_refs/orange_cat/orange_cat_icon_v1.png",
	"test_enemy": UI_ROOT + "character_refs/test_enemy/test_enemy_icon_v1.png",
	"tuxedo_cat": UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_icon_v1.png",
}

const PROFILE_AVATAR_IDS := [
	"black_cat",
	"calico_cat",
	"milk_cat",
	"ninja_cat",
	"orange_cat",
	"tuxedo_cat",
]

const PROFILE_AVATAR_LABELS := {
	"black_cat": "黑貓",
	"calico_cat": "三花貓",
	"milk_cat": "乳牛貓",
	"ninja_cat": "忍者貓",
	"orange_cat": "橘貓",
	"tuxedo_cat": "燕尾服貓",
}

const CAT_SHOWCASE_TEXTURES := {
	"black_cat": [
		UI_ROOT + "character_refs/black_cat/black_cat_ref_right_v1.png",
		UI_ROOT + "character_refs/black_cat/black_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/black_cat/black_cat_icon_v1.png",
	],
	"calico_cat": [
		UI_ROOT + "character_refs/calico_cat/calico_cat_ref_three_quarter_v1-Photoroom.png",
		UI_ROOT + "character_refs/calico_cat/calico_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/calico_cat/calico_cat_icon_v1.png",
	],
	"milk_cat": [
		UI_ROOT + "character_refs/milk_cat/milk_cat_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/milk_cat/milk_cat_ref_right_v1.png",
		UI_ROOT + "character_refs/milk_cat/milk_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/milk_cat/milk_cat_icon_v1.png",
	],
	"ninja_cat": [
		UI_ROOT + "character_refs/ninja_cat/ninja_cat_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/ninja_cat/ninja_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/ninja_cat/ninja_cat_icon_v1.png",
	],
	"orange_cat": [
		UI_ROOT + "character_refs/orange_cat/orange_cat_ref_right_v1.png",
		UI_ROOT + "character_refs/orange_cat/orange_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/orange_cat/orange_cat_icon_v1.png",
	],
	"test_enemy": [
		UI_ROOT + "character_refs/test_enemy/test_enemy_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/test_enemy/test_enemy_ref_right_v1.png",
		UI_ROOT + "character_refs/test_enemy/test_enemy_ref_front_v1.png",
		UI_ROOT + "character_refs/test_enemy/test_enemy_icon_v1.png",
	],
	"tuxedo_cat": [
		UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_ref_right_v1.png",
		UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_icon_v1.png",
	],
}

const CAT_BATTLE_STATIC_ARTS := {
	"black_cat": [
		UI_ROOT + "character_refs/black_cat/black_cat_ref_right_v1.png",
		UI_ROOT + "character_refs/black_cat/black_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/black_cat/black_cat_icon_v1.png",
	],
	"calico_cat": [
		UI_ROOT + "character_refs/calico_cat/calico_cat_ref_three_quarter_v1-Photoroom.png",
		UI_ROOT + "character_refs/calico_cat/calico_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/calico_cat/calico_cat_icon_v1.png",
	],
	"milk_cat": [
		UI_ROOT + "character_refs/milk_cat/milk_cat_ref_right_v1.png",
		UI_ROOT + "character_refs/milk_cat/milk_cat_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/milk_cat/milk_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/milk_cat/milk_cat_icon_v1.png",
	],
	"ninja_cat": [
		UI_ROOT + "character_refs/ninja_cat/ninja_cat_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/ninja_cat/ninja_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/ninja_cat/ninja_cat_icon_v1.png",
	],
	"orange_cat": [
		UI_ROOT + "character_refs/orange_cat/orange_cat_ref_right_v1.png",
		UI_ROOT + "character_refs/orange_cat/orange_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/orange_cat/orange_cat_icon_v1.png",
	],
	"test_enemy": [
		UI_ROOT + "character_refs/test_enemy/test_enemy_ref_right_v1.png",
		UI_ROOT + "character_refs/test_enemy/test_enemy_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/test_enemy/test_enemy_ref_front_v1.png",
		UI_ROOT + "character_refs/test_enemy/test_enemy_icon_v1.png",
	],
	"tuxedo_cat": [
		UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_ref_right_v1.png",
		UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_ref_front_v1.png",
		UI_ROOT + "character_refs/tuxedo_cat/tuxedo_cat_icon_v1.png",
	],
}

const CAT_BATTLE_SPRITES_ROOT := "res://assets/sprites/battle/cats/"
const CAT_BATTLE_DEFAULT_SHEET_WIDTH := 1100
const CAT_BATTLE_DEFAULT_SHEET_HEIGHT := 335
const CAT_BATTLE_DEFAULT_FRAME_WIDTH := 275
const CAT_BATTLE_DEFAULT_FRAME_HEIGHT := 335
const CAT_BATTLE_ANIMATION_NAMES: Array[String] = [
	"idle",
	"run",
	"collide",
	"knockback",
	"stagger",
	"skill",
	"death_fly",
]
const CAT_BATTLE_ANIMATION_SUFFIXES := {
	"idle": ["idle_right"],
	"run": ["run_right"],
	"collide": ["collide_right", "collide_righ"],
	"knockback": ["knockback_right"],
	"stagger": ["stagger_right"],
	"skill": ["skill_right"],
	"death_fly": ["death_fly_right"],
}
const CAT_BATTLE_ANIMATION_FPS := {
	"idle": 8.0,
	"run": 12.0,
	"collide": 12.0,
	"knockback": 12.0,
	"stagger": 12.0,
	"skill": 12.0,
	"death_fly": 12.0,
}
const CAT_BATTLE_LOOPING_ANIMATIONS := {
	"idle": true,
	"run": true,
	"collide": false,
	"knockback": false,
	"stagger": false,
	"skill": false,
	"death_fly": false,
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
				if key == "party_cheer_coupon":
					return UI_ROOT + "rewards/party_cheer_coupon.svg"
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


static func get_profile_avatar_ids() -> Array[String]:
	var avatar_ids: Array[String] = []
	for avatar_id_variant: Variant in PROFILE_AVATAR_IDS:
		avatar_ids.append(str(avatar_id_variant))
	return avatar_ids


static func get_profile_avatar_label(avatar_id: String) -> String:
	var normalized_id: String = avatar_id if avatar_id != "" else DEFAULT_PROFILE_AVATAR_ID
	return str(PROFILE_AVATAR_LABELS.get(normalized_id, normalized_id))


static func resolve_profile_avatar(avatar_id: String) -> Texture2D:
	var normalized_id: String = avatar_id if avatar_id != "" else DEFAULT_PROFILE_AVATAR_ID
	var texture: Texture2D = resolve_cat_icon(normalized_id)
	if texture != null:
		return texture
	return resolve_cat_icon(DEFAULT_PROFILE_AVATAR_ID)


static func resolve_cat_showcase_art(cat_id: String) -> Texture2D:
	var candidates: Array = CAT_SHOWCASE_TEXTURES.get(cat_id, [])
	for candidate_variant: Variant in candidates:
		var candidate_path: String = str(candidate_variant)
		var texture: Texture2D = load_texture(candidate_path)
		if texture != null:
			return texture
	return resolve_cat_icon(cat_id)


static func resolve_cat_battle_static_art(cat_id: String) -> Texture2D:
	var candidates: Array = CAT_BATTLE_STATIC_ARTS.get(cat_id, [])
	for candidate_variant: Variant in candidates:
		var candidate_path: String = str(candidate_variant)
		var texture: Texture2D = load_texture(candidate_path)
		if texture != null:
			return texture
	return resolve_cat_showcase_art(cat_id)


static func resolve_cat_battle_idle(cat_id: String) -> Texture2D:
	return load_texture(resolve_cat_battle_animation_path(cat_id, "idle"))


static func resolve_cat_battle_animation_path(cat_id: String, animation_name: String) -> String:
	var suffixes: Variant = CAT_BATTLE_ANIMATION_SUFFIXES.get(animation_name, [])
	if not (suffixes is Array):
		return ""
	for suffix_variant: Variant in suffixes:
		var suffix: String = str(suffix_variant)
		for extension: String in [".png", ".png.png"]:
			var candidate_path: String = (
				CAT_BATTLE_SPRITES_ROOT
				+ cat_id
				+ "/"
				+ cat_id
				+ "_"
				+ suffix
				+ extension
			)
			if ResourceLoader.exists(candidate_path):
				return candidate_path
	return ""


static func resolve_cat_battle_animation_spec(_cat_id: String, animation_name: String) -> Dictionary:
	return {
		"sheet_width": CAT_BATTLE_DEFAULT_SHEET_WIDTH,
		"sheet_height": CAT_BATTLE_DEFAULT_SHEET_HEIGHT,
		"frame_width": CAT_BATTLE_DEFAULT_FRAME_WIDTH,
		"frame_height": CAT_BATTLE_DEFAULT_FRAME_HEIGHT,
		"fps": float(CAT_BATTLE_ANIMATION_FPS.get(animation_name, 12.0)),
		"loop": bool(CAT_BATTLE_LOOPING_ANIMATIONS.get(animation_name, false)),
	}


static func get_cat_battle_animation_names() -> Array[String]:
	var animation_names: Array[String] = []
	for animation_name: String in CAT_BATTLE_ANIMATION_NAMES:
		animation_names.append(animation_name)
	return animation_names


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


static func resolve_cat_card_frame() -> Texture2D:
	return load_texture(CAT_CARD_FRAME)


static func resolve_cat_card_empty_silhouette() -> Texture2D:
	return load_texture(CAT_CARD_EMPTY_SILHOUETTE)


static func resolve_cat_card_square_frame(rarity_key: String) -> Texture2D:
	var normalized: String = rarity_key.strip_edges().to_lower()
	return load_texture(CAT_CARD_SQUARE_FRAMES.get(normalized, CAT_CARD_SQUARE_FRAMES["common"]))


static func resolve_cat_type_icon(cat_type: String) -> Texture2D:
	var normalized: String = cat_type.strip_edges().to_lower()
	return load_texture(CAT_TYPE_ICONS.get(normalized, CAT_TYPE_ICONS["base"]))


static func create_icon_rect(texture: Texture2D, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.texture = texture
	return rect
