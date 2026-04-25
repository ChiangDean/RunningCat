class_name AssetResolver
extends RefCounted

const UI_ROOT := "res://assets/sprites/ui/"
const BACKGROUND_SHADER := preload("res://scripts/ui/background_desaturate_shader.gdshader")
const DEFAULT_PROFILE_AVATAR_ID := "black_cat"
const CAT_CARD_FRAME := UI_ROOT + "cards/cat_card_frame_homey_v1.png"
const CAT_CARD_EMPTY_SILHOUETTE := UI_ROOT + "cards/cat_card_empty_silhouette_v1.png"
const DEFAULT_ICON_PLACEHOLDER_PATH := CAT_CARD_EMPTY_SILHOUETTE
const DEFAULT_BACKGROUND_SLOT := "activity"
const DEFAULT_GACHA_FRAME_KEY := "common"
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
	"combat_trial": UI_ROOT + "combat_trial/bath_trial_bg.svg",
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
	"baby": UI_ROOT + "character_refs/boss/baby/baby_icon_v1.png",
	"bird": UI_ROOT + "character_refs/boss/bird/bird_icon_v1.png",
	"black_cat": UI_ROOT + "character_refs/black_cat/black_cat_icon_v1.png",
	"calico_cat": UI_ROOT + "character_refs/calico_cat/calico_cat_icon_v1.png",
	"chihuahua": UI_ROOT + "character_refs/boss/chihuahua/chihuahua_icon_v1.png",
	"crazy_neighbor_boy": UI_ROOT + "character_refs/boss/crazy_neighbor_boy/crazy_neighbor_boy_icon_v1.png",
	"grandma": UI_ROOT + "character_refs/boss/grandma/grandma_icon_v1.png",
	"milk_cat": UI_ROOT + "character_refs/milk_cat/milk_cat_icon_v1.png",
	"ninja_cat": UI_ROOT + "character_refs/ninja_cat/ninja_cat_icon_v1.png",
	"orange_cat": UI_ROOT + "character_refs/orange_cat/orange_cat_icon_v1.png",
	"schoolgirl": UI_ROOT + "character_refs/boss/schoolgirl/schoolgirl_icon_v1.png",
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
	"black_cat": UiText.AVATAR_BLACK_CAT,
	"calico_cat": UiText.AVATAR_CALICO_CAT,
	"milk_cat": UiText.AVATAR_MILK_CAT,
	"ninja_cat": UiText.AVATAR_NINJA_CAT,
	"orange_cat": UiText.AVATAR_ORANGE_CAT,
	"tuxedo_cat": UiText.AVATAR_TUXEDO_CAT,
}

const CAT_SHOWCASE_TEXTURES := {
	"baby": [
		UI_ROOT + "character_refs/boss/baby/baby_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/baby/baby_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/baby/baby_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/baby/baby_icon_v1.png",
	],
	"bird": [
		UI_ROOT + "character_refs/boss/bird/bird_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/bird/bird_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/bird/bird_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/bird/bird_icon_v1.png",
	],
	"chihuahua": [
		UI_ROOT + "character_refs/boss/chihuahua/chihuahua_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/chihuahua/chihuahua_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/chihuahua/chihuahua_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/chihuahua/chihuahua_icon_v1.png",
	],
	"grandma": [
		UI_ROOT + "character_refs/boss/grandma/grandma_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/grandma/grandma_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/grandma/grandma_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/grandma/grandma_icon_v1.png",
	],
	"schoolgirl": [
		UI_ROOT + "character_refs/boss/schoolgirl/schoolgirl_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/schoolgirl/schoolgirl_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/schoolgirl/schoolgirl_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/schoolgirl/schoolgirl_icon_v1.png",
	],
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
	"baby": [
		UI_ROOT + "character_refs/boss/baby/baby_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/baby/baby_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/baby/baby_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/baby/baby_icon_v1.png",
	],
	"bird": [
		UI_ROOT + "character_refs/boss/bird/bird_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/bird/bird_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/bird/bird_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/bird/bird_icon_v1.png",
	],
	"chihuahua": [
		UI_ROOT + "character_refs/boss/chihuahua/chihuahua_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/chihuahua/chihuahua_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/chihuahua/chihuahua_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/chihuahua/chihuahua_icon_v1.png",
	],
	"grandma": [
		UI_ROOT + "character_refs/boss/grandma/grandma_ref_right_v1.png",
		UI_ROOT + "character_refs/boss/grandma/grandma_ref_three_quarter_v1.png",
		UI_ROOT + "character_refs/boss/grandma/grandma_ref_front_v1.png",
		UI_ROOT + "character_refs/boss/grandma/grandma_icon_v1.png",
	],
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
const ENCOUNTER_BATTLE_SPRITES_ROOT := "res://assets/sprites/battle/encounter/"
const BOSS_BATTLE_SPRITES_ROOT := "res://assets/sprites/battle/boss/"
const ENCOUNTER_CHARACTER_REF_ROOT := UI_ROOT + "character_refs/encounters/"
const BOSS_CHARACTER_REF_ROOT := UI_ROOT + "character_refs/boss/"
const CAT_BATTLE_DEFAULT_SHEET_WIDTH := 1100
const CAT_BATTLE_DEFAULT_SHEET_HEIGHT := 335
const CAT_BATTLE_DEFAULT_FRAME_WIDTH := 275
const CAT_BATTLE_DEFAULT_FRAME_HEIGHT := 335
const CAT_BATTLE_SPEC_PROFILES := {
	"baby_256": {
		"sheet_height": 128,
		"frame_width": 128,
		"frame_height": 128,
		"sheet_widths": {
			"idle": 768,
			"run": 1024,
			"collide": 512,
			"knockback": 768,
			"stagger": 512,
			"skill": 768,
			"death_fly": 768,
		},
	},
	"standard_256": {
		"sheet_height": 128,
		"frame_width": 128,
		"frame_height": 128,
		"sheet_widths": {
			"idle": 768,
			"run": 1024,
			"collide": 512,
			"knockback": 768,
			"stagger": 512,
			"skill": 768,
			"death_fly": 768,
		},
	},
	"boss_standard_128": {
		"sheet_height": 128,
		"frame_width": 128,
		"frame_height": 128,
		"sheet_widths": {
			"idle": 768,
			"run": 1024,
			"collide": 512,
			"knockback": 768,
			"stagger": 512,
			"skill": 768,
			"death_fly": 768,
		},
	},
	"bird_256": {
		"sheet_height": 128,
		"frame_width": 128,
		"frame_height": 128,
		"sheet_widths": {
			"idle": 768,
			"run": 1024,
			"collide": 512,
			"knockback": 768,
			"stagger": 512,
			"skill": 640,
			"death_fly": 768,
		},
	},
	"small_128": {
		"sheet_height": 128,
		"frame_width": 128,
		"frame_height": 128,
		"sheet_widths": {
			"idle": 512,
			"run": 768,
			"collide": 512,
			"knockback": 512,
			"stagger": 512,
			"skill": 768,
			"death_fly": 768,
		},
	},
}
const CAT_BATTLE_ENCOUNTER_CHARACTER_IDS: Array[String] = [
	"lipstick",
	"mug",
	"potted_plant",
	"remote_control",
	"toilet_paper",
]
const CAT_BATTLE_BOSS_CHARACTER_IDS: Array[String] = [
	"baby",
	"bird",
	"chihuahua",
	"cucumber",
	"crazy_neighbor_boy",
	"grandma",
	"male_coworker",
	"mouse",
	"robot_vacuum",
	"schoolgirl",
]
const BATTLE_SPEC_PROFILE_BY_CHARACTER := {
	"baby": "baby_256",
	"bird": "bird_256",
	"black_cat": "standard_256",
	"calico_cat": "small_128",
	"chihuahua": "boss_standard_128",
	"crazy_neighbor_boy": "boss_standard_128",
	"cucumber": "boss_standard_128",
	"grandma": "boss_standard_128",
	"lipstick": "standard_256",
	"male_coworker": "boss_standard_128",
	"milk_cat": "small_128",
	"mouse": "boss_standard_128",
	"mug": "standard_256",
	"ninja_cat": "standard_256",
	"orange_cat": "standard_256",
	"potted_plant": "standard_256",
	"remote_control": "standard_256",
	"robot_vacuum": "boss_standard_128",
	"schoolgirl": "boss_standard_128",
	"test_enemy": "standard_256",
	"toilet_paper": "standard_256",
	"tuxedo_cat": "standard_256",
}
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
const CAT_BATTLE_ANIMATION_FALLBACKS := {
	"idle": ["run"],
	"run": ["idle"],
	"collide": ["run", "idle"],
	"knockback": ["stagger", "collide", "run", "idle"],
	"stagger": ["knockback", "collide", "run", "idle"],
	"skill": ["run", "collide", "idle"],
	"death_fly": ["knockback", "stagger", "collide", "run", "idle"],
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
	apply_background_texture(background, slot)
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


static func resolve_cdn_asset_url(path: String) -> String:
	if not RuntimeConfig.should_use_cdn_assets():
		return ""
	var normalized_path: String = path.strip_edges()
	if normalized_path == "" or not normalized_path.begins_with("res://assets/"):
		return ""
	return "%s/%s" % [RuntimeConfig.get_assets_base_url(), normalized_path.trim_prefix("res://")]


static func apply_background_texture(texture_rect: TextureRect, slot: String) -> void:
	if texture_rect == null:
		return
	var asset_path: String = _get_background_path(slot)
	var fallback_texture: Texture2D = resolve_background_texture(slot)
	CdnTextureLoader.apply_texture(texture_rect, resolve_cdn_asset_url(asset_path), fallback_texture)


static func apply_preview_texture(texture_rect: TextureRect, path: String, fallback_slot: String = DEFAULT_BACKGROUND_SLOT) -> void:
	if texture_rect == null:
		return
	var fallback_texture: Texture2D = resolve_preview_texture(path, fallback_slot)
	CdnTextureLoader.apply_texture(texture_rect, resolve_cdn_asset_url(path), fallback_texture)


static func resolve_background_texture(slot: String) -> Texture2D:
	var texture: Texture2D = load_texture(_get_background_path(slot))
	if texture != null:
		return texture
	return load_texture(str(BACKGROUNDS.get(DEFAULT_BACKGROUND_SLOT, "")))


static func resolve_placeholder_icon() -> Texture2D:
	return load_texture(DEFAULT_ICON_PLACEHOLDER_PATH)


static func resolve_texture_or_placeholder(path: String) -> Texture2D:
	var texture: Texture2D = load_texture(path)
	if texture != null:
		return texture
	return resolve_placeholder_icon()


static func resolve_catalog_texture(raw_path: Variant) -> Texture2D:
	return resolve_texture_or_placeholder(resolve_catalog_path(raw_path))


static func resolve_preview_texture(path: String, fallback_slot: String = DEFAULT_BACKGROUND_SLOT) -> Texture2D:
	var texture: Texture2D = load_texture(path)
	if texture != null:
		return texture
	return resolve_background_texture(fallback_slot)


static func _get_background_path(slot: String) -> String:
	var resolved_slot: String = slot.strip_edges().to_lower()
	return str(BACKGROUNDS.get(resolved_slot, ""))


static func resolve_catalog_path(raw_path: Variant) -> String:
	var image_path := str(raw_path if raw_path != null else "").strip_edges()
	if image_path == "":
		return ""
	if image_path.begins_with("res://"):
		return image_path
	var normalized_path: String = image_path
	if not normalized_path.begins_with("catalog/"):
		var legacy_parts: PackedStringArray = normalized_path.split("/")
		if legacy_parts.size() >= 2:
			normalized_path = "catalog/%s/%s" % [str(legacy_parts[0]), str(legacy_parts[1])]
	if normalized_path.begins_with("catalog/"):
		var suffix := normalized_path.trim_prefix("catalog/")
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
					return UI_ROOT + "rewards/party_cheer_coupon.png"
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
	return resolve_texture_or_placeholder(str(CAT_ICONS.get(cat_id, "")))


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
	if CAT_BATTLE_ENCOUNTER_CHARACTER_IDS.has(cat_id):
		for suffix: String in ["ref_right_v1", "ref_three_quarter_v1", "ref_front_v1", "icon_v1"]:
			var encounter_path: String = ENCOUNTER_CHARACTER_REF_ROOT + cat_id + "/" + cat_id + "_" + suffix + ".png"
			var encounter_texture: Texture2D = load_texture(encounter_path)
			if encounter_texture != null:
				return encounter_texture
	if CAT_BATTLE_BOSS_CHARACTER_IDS.has(cat_id):
		for suffix: String in ["ref_right_v1", "ref_three_quarter_v1", "ref_front_v1", "icon_v1"]:
			var boss_path: String = BOSS_CHARACTER_REF_ROOT + cat_id + "/" + cat_id + "_" + suffix + ".png"
			var boss_texture: Texture2D = load_texture(boss_path)
			if boss_texture != null:
				return boss_texture
	return resolve_cat_showcase_art(cat_id)


static func resolve_cat_battle_idle(cat_id: String) -> Texture2D:
	return load_texture(resolve_cat_battle_animation_path(cat_id, "idle"))


static func resolve_cat_battle_animation_path(cat_id: String, animation_name: String) -> String:
	return _resolve_cat_battle_animation_path_with_fallback(cat_id, animation_name, [])


static func _resolve_cat_battle_animation_path_with_fallback(cat_id: String, animation_name: String, visited: Array[String]) -> String:
	if visited.has(animation_name):
		return ""

	var direct_path: String = _resolve_cat_battle_animation_path_exact(cat_id, animation_name)
	if direct_path != "":
		return direct_path

	var next_visited: Array[String] = visited.duplicate()
	next_visited.append(animation_name)
	var fallback_variant: Variant = CAT_BATTLE_ANIMATION_FALLBACKS.get(animation_name, [])
	var fallback_names: Array = fallback_variant if fallback_variant is Array else []
	for fallback_name_variant: Variant in fallback_names:
		var fallback_name: String = str(fallback_name_variant)
		var fallback_path: String = _resolve_cat_battle_animation_path_with_fallback(cat_id, fallback_name, next_visited)
		if fallback_path != "":
			return fallback_path
	return ""


static func _resolve_cat_battle_animation_path_exact(cat_id: String, animation_name: String) -> String:
	var suffixes: Variant = CAT_BATTLE_ANIMATION_SUFFIXES.get(animation_name, [])
	if not (suffixes is Array):
		return ""
	var sprite_roots: Array[String] = [CAT_BATTLE_SPRITES_ROOT]
	if CAT_BATTLE_ENCOUNTER_CHARACTER_IDS.has(cat_id):
		sprite_roots.append(ENCOUNTER_BATTLE_SPRITES_ROOT)
	if CAT_BATTLE_BOSS_CHARACTER_IDS.has(cat_id):
		sprite_roots.append(BOSS_BATTLE_SPRITES_ROOT)
	for suffix_variant: Variant in suffixes:
		var suffix: String = str(suffix_variant)
		for extension: String in [".png", ".png.png"]:
			for sprite_root: String in sprite_roots:
				var candidate_path: String = (
					sprite_root
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


static func resolve_cat_battle_animation_spec(cat_id: String, animation_name: String) -> Dictionary:
	var spec: Dictionary = {
		"sheet_width": CAT_BATTLE_DEFAULT_SHEET_WIDTH,
		"sheet_height": CAT_BATTLE_DEFAULT_SHEET_HEIGHT,
		"frame_width": CAT_BATTLE_DEFAULT_FRAME_WIDTH,
		"frame_height": CAT_BATTLE_DEFAULT_FRAME_HEIGHT,
		"fps": float(CAT_BATTLE_ANIMATION_FPS.get(animation_name, 12.0)),
		"loop": bool(CAT_BATTLE_LOOPING_ANIMATIONS.get(animation_name, false)),
	}
	var profile_name: String = str(BATTLE_SPEC_PROFILE_BY_CHARACTER.get(cat_id, ""))
	if profile_name == "":
		return spec

	var profile_variant: Variant = CAT_BATTLE_SPEC_PROFILES.get(profile_name, {})
	var profile: Dictionary = profile_variant if profile_variant is Dictionary else {}
	var sheet_widths_variant: Variant = profile.get("sheet_widths", {})
	var sheet_widths: Dictionary = sheet_widths_variant if sheet_widths_variant is Dictionary else {}
	var sheet_width: int = int(sheet_widths.get(animation_name, 0))
	if sheet_width <= 0:
		return spec

	spec["sheet_width"] = sheet_width
	spec["sheet_height"] = int(profile.get("sheet_height", spec["sheet_height"]))
	spec["frame_width"] = int(profile.get("frame_width", spec["frame_width"]))
	spec["frame_height"] = int(profile.get("frame_height", spec["frame_height"]))
	return spec


static func get_cat_battle_animation_names() -> Array[String]:
	var animation_names: Array[String] = []
	for animation_name: String in CAT_BATTLE_ANIMATION_NAMES:
		animation_names.append(animation_name)
	return animation_names


static func resolve_gacha_frame(result: Dictionary) -> Texture2D:
	var rarity_key := str(result.get("rarityKey", "")).to_lower()
	if rarity_key == "":
		rarity_key = str(result.get("rarityType", "")).to_lower()
	var frame_path: String = str(GACHA_FRAMES.get(rarity_key, GACHA_FRAMES.get(DEFAULT_GACHA_FRAME_KEY, "")))
	var frame_texture: Texture2D = load_texture(frame_path)
	if frame_texture != null:
		return frame_texture
	return load_texture(str(GACHA_FRAMES.get(DEFAULT_GACHA_FRAME_KEY, "")))


static func resolve_equipment_icon(item: Dictionary) -> Texture2D:
	return resolve_texture_or_placeholder(str(SCOOPER_EQUIPMENT.get(int(item.get("equipmentId", 0)), "")))


static func resolve_ability_icon(item: Dictionary) -> Texture2D:
	return resolve_texture_or_placeholder(str(SCOOPER_ABILITIES.get(int(item.get("abilityId", 0)), "")))


static func resolve_bundle_art(bundle: Dictionary) -> Texture2D:
	return resolve_texture_or_placeholder(str(SHOP_BUNDLES.get(int(bundle.get("bundleId", 0)), "")))


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
