class_name AssetResolver
extends RefCounted

const UI_LOCAL_ROOT := "res://assets/sprites/ui/"
const UI_CDN_ROOT := "res://assets/sprites/cdn/ui/"
const UI_CDN_CARDS_ROOT := UI_CDN_ROOT + "cards/"
const UI_CDN_CHARACTER_REF_ROOT := UI_CDN_ROOT + "character_refs/"
const UI_CDN_MEMORY_ROOT := UI_CDN_ROOT + "memory/"
const UI_CDN_GACHA_ROOT := UI_CDN_ROOT + "gacha/"
const UI_CDN_REWARDS_ROOT := UI_CDN_ROOT + "rewards/"
const UI_CDN_ARENA_RANKS_ROOT := UI_CDN_ROOT + "arena_ranks/"
const UI_CDN_DUNGEON_ROOT := UI_CDN_ROOT + "dungeon/"
const UI_CDN_SCOOPER_EQUIPMENT_ROOT := UI_CDN_ROOT + "scooper_equipment/"
const UI_CDN_SCOOPER_ABILITIES_ROOT := UI_CDN_ROOT + "scooper_abilities/"
const UI_CDN_TREASURE_ROOT := UI_CDN_ROOT + "treasure/"
const UI_CDN_ACTIVITY_ROOT := UI_CDN_ROOT + "activity/"
const UI_ROOT := UI_LOCAL_ROOT
const BACKGROUND_SHADER := preload("res://scripts/ui/background_desaturate_shader.gdshader")
const DEFAULT_PROFILE_AVATAR_ID := "black_cat"
const CAT_CARD_FRAME := UI_CDN_CARDS_ROOT + "cat_card_frame_homey_v1.png"
const CAT_CARD_EMPTY_SILHOUETTE := UI_CDN_CARDS_ROOT + "cat_card_empty_silhouette_v1.png"
const ONBOARDING_OWNER_AVATAR_PATH := UI_LOCAL_ROOT + "onboarding/onboarding_owner_avatar_no_face_v1.png"
const ONBOARDING_GENERIC_CAT_PATH := UI_LOCAL_ROOT + "onboarding/onboarding_generic_cat_v3.png"
const DEFAULT_ICON_PLACEHOLDER_PATH := CAT_CARD_EMPTY_SILHOUETTE
const DEFAULT_BACKGROUND_SLOT := "activity"
const SHARED_OVERLAY_BACKGROUND_PATH := UI_CDN_ACTIVITY_ROOT + "activity_background_v1.png"
const DEFAULT_GACHA_FRAME_KEY := "common"
const CAT_CARD_SQUARE_FRAMES := {
	"n": UI_CDN_CARDS_ROOT + "square/cat_card_square_n_v1.png",
	"r": UI_CDN_CARDS_ROOT + "square/cat_card_square_r_v1.png",
	"sr": UI_CDN_CARDS_ROOT + "square/cat_card_square_sr_v1.png",
	"ssr": UI_CDN_CARDS_ROOT + "square/cat_card_square_ssr_v1.png",
	"sp": UI_CDN_CARDS_ROOT + "square/cat_card_square_sp_v1.png",
	"common": UI_CDN_CARDS_ROOT + "square/cat_card_square_n_v1.png",
	"uncommon": UI_CDN_CARDS_ROOT + "square/cat_card_square_r_v1.png",
	"fine": UI_CDN_CARDS_ROOT + "square/cat_card_square_sr_v1.png",
	"special": UI_CDN_CARDS_ROOT + "square/cat_card_square_sr_v1.png",
	"precious": UI_CDN_CARDS_ROOT + "square/cat_card_square_ssr_v1.png",
	"excellent": UI_CDN_CARDS_ROOT + "square/cat_card_square_ssr_v1.png",
	"rare": UI_CDN_CARDS_ROOT + "square/cat_card_square_r_v1.png",
	"epic": UI_CDN_CARDS_ROOT + "square/cat_card_square_sr_v1.png",
	"legendary": UI_CDN_CARDS_ROOT + "square/cat_card_square_ssr_v1.png",
	"master": UI_CDN_CARDS_ROOT + "square/cat_card_square_sp_v1.png",
}
const CAT_TYPE_ICONS := {
	"tank": UI_CDN_CARDS_ROOT + "type_icons/cat_type_tank_v2.png",
	"crusader": UI_CDN_CARDS_ROOT + "type_icons/cat_type_crusader_v2.png",
	"paladin": UI_CDN_CARDS_ROOT + "type_icons/cat_type_crusader_v2.png",
	"striker": UI_CDN_CARDS_ROOT + "type_icons/cat_type_striker_v2.png",
	"assassin": UI_CDN_CARDS_ROOT + "type_icons/cat_type_assassin_v2.png",
	"support": UI_CDN_CARDS_ROOT + "type_icons/cat_type_support_v2.png",
	"defensive": UI_CDN_CARDS_ROOT + "type_icons/cat_type_tank_v2.png",
	"speed": UI_CDN_CARDS_ROOT + "type_icons/cat_type_striker_v2.png",
	"bouncer": UI_CDN_CARDS_ROOT + "type_icons/cat_type_striker_v2.png",
	"flying": UI_CDN_CARDS_ROOT + "type_icons/cat_type_assassin_v2.png",
	"elemental": UI_CDN_CARDS_ROOT + "type_icons/cat_type_crusader_v2.png",
	"cute": UI_CDN_CARDS_ROOT + "type_icons/cat_type_support_v2.png",
	"base": UI_CDN_CARDS_ROOT + "type_icons/cat_type_tank_v2.png",
}

const BACKGROUNDS := {
	"activity": SHARED_OVERLAY_BACKGROUND_PATH,
	"arena": SHARED_OVERLAY_BACKGROUND_PATH,
	"chat": SHARED_OVERLAY_BACKGROUND_PATH,
	"combat_trial": SHARED_OVERLAY_BACKGROUND_PATH,
	"config": SHARED_OVERLAY_BACKGROUND_PATH,
	"dungeon": SHARED_OVERLAY_BACKGROUND_PATH,
	"enhance": SHARED_OVERLAY_BACKGROUND_PATH,
	"expedition": SHARED_OVERLAY_BACKGROUND_PATH,
	"gacha": SHARED_OVERLAY_BACKGROUND_PATH,
	"mail": SHARED_OVERLAY_BACKGROUND_PATH,
	"scooper": SHARED_OVERLAY_BACKGROUND_PATH,
	"shop": SHARED_OVERLAY_BACKGROUND_PATH,
}

const CAT_ICONS := {
	"baby": UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_icon_v1.png",
	"abyssinian_cat": UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_icon_v1.png",
	"american_shorthair_cat": UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_icon_v1.png",
	"bengal_cat": UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_icon_v1.png",
	"bird": UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_icon_v1.png",
	"black_cat": UI_CDN_CHARACTER_REF_ROOT + "black_cat/black_cat_icon_v1.png",
	"british_shorthair_cat": UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_icon_v1.png",
	"calico_cat": UI_CDN_CHARACTER_REF_ROOT + "calico_cat/calico_cat_icon_v1.png",
	"chihuahua": UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_icon_v1.png",
	"cow_cat": UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_icon_v1.png",
	"cream_cat": UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_icon_v1.png",
	"crazy_neighbor_boy": UI_CDN_CHARACTER_REF_ROOT + "boss/crazy_neighbor_boy/crazy_neighbor_boy_icon_v1.png",
	"grandma": UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_icon_v1.png",
	"maine_coon_cat": UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_icon_v1.png",
	"milk_cat": UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_icon_v1.png",
	"munchkin_cat": UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_icon_v1.png",
	"ninja_cat": UI_CDN_CHARACTER_REF_ROOT + "ninja_cat/ninja_cat_icon_v1.png",
	"norwegian_forest_cat": UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_icon_v1.png",
	"orange_cat": UI_CDN_CHARACTER_REF_ROOT + "orange_cat/orange_cat_icon_v1.png",
	"persian_cat": UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_icon_v1.png",
	"ragdoll_cat": UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_icon_v1.png",
	"russian_blue_cat": UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_icon_v1.png",
	"schoolgirl": UI_CDN_CHARACTER_REF_ROOT + "boss/schoolgirl/schoolgirl_icon_v1.png",
	"scottish_fold_cat": UI_CDN_CHARACTER_REF_ROOT + "scottish_fold_cat/scottish_fold_cat_icon_v1.png",
	"siamese_cat": UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_icon_v1.png",
	"silver_cat": UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_icon_v1.png",
	"smoke_cat": UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_icon_v1.png",
	"sphinx_cat": UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_icon_v1.png",
	"tabby_cat": UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_icon_v1.png",
	"tortoiseshell_cat": UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_icon_v1.png",
	"tuxedo_cat": UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_icon_v1.png",
	"white_cat": UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_icon_v1.png",
}

const PROFILE_AVATAR_IDS := [
	"black_cat",
	"calico_cat",
	"milk_cat",
	"ninja_cat",
	"orange_cat",
	"siamese_cat",
	"tuxedo_cat",
]

const PROFILE_AVATAR_LABELS := {
	"black_cat": UiText.AVATAR_BLACK_CAT,
	"calico_cat": UiText.AVATAR_CALICO_CAT,
	"milk_cat": UiText.AVATAR_MILK_CAT,
	"ninja_cat": UiText.AVATAR_NINJA_CAT,
	"orange_cat": UiText.AVATAR_ORANGE_CAT,
	"siamese_cat": UiText.AVATAR_SIAMESE_CAT,
	"tuxedo_cat": UiText.AVATAR_TUXEDO_CAT,
}

const CAT_SHOWCASE_TEXTURES := {
	"baby": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_icon_v1.png",
	],
	"abyssinian_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_icon_v1.png",
	],
	"american_shorthair_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_icon_v1.png",
	],
	"bengal_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_icon_v1.png",
	],
	"bird": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_icon_v1.png",
	],
	"chihuahua": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_icon_v1.png",
	],
	"grandma": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_icon_v1.png",
	],
	"schoolgirl": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/schoolgirl/schoolgirl_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/schoolgirl/schoolgirl_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/schoolgirl/schoolgirl_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/schoolgirl/schoolgirl_icon_v1.png",
	],
	"black_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "black_cat/black_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "black_cat/black_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "black_cat/black_cat_icon_v1.png",
	],
	"british_shorthair_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_icon_v1.png",
	],
	"calico_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "calico_cat/calico_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "calico_cat/calico_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "calico_cat/calico_cat_icon_v1.png",
	],
	"cow_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_icon_v1.png",
	],
	"cream_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_icon_v1.png",
	],
	"maine_coon_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_icon_v1.png",
	],
	"milk_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_icon_v1.png",
	],
	"munchkin_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_icon_v1.png",
	],
	"ninja_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "ninja_cat/ninja_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ninja_cat/ninja_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ninja_cat/ninja_cat_icon_v1.png",
	],
	"norwegian_forest_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_icon_v1.png",
	],
	"orange_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "orange_cat/orange_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "orange_cat/orange_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "orange_cat/orange_cat_icon_v1.png",
	],
	"persian_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_icon_v1.png",
	],
	"ragdoll_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_icon_v1.png",
	],
	"russian_blue_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_icon_v1.png",
	],
	"siamese_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_icon_v1.png",
	],
	"silver_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_icon_v1.png",
	],
	"scottish_fold_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "scottish_fold_cat/scottish_fold_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "scottish_fold_cat/scottish_fold_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "scottish_fold_cat/scottish_fold_cat_icon_v1.png",
	],
	"smoke_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_icon_v1.png",
	],
	"sphinx_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_icon_v1.png",
	],
	"tabby_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_icon_v1.png",
	],
	"tortoiseshell_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_icon_v1.png",
	],
	"tuxedo_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_icon_v1.png",
	],
	"white_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_icon_v1.png",
	],
}

const CAT_BATTLE_STATIC_ARTS := {
	"baby": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/baby/baby_icon_v1.png",
	],
	"abyssinian_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "abyssinian_cat/abyssinian_cat_icon_v1.png",
	],
	"american_shorthair_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "american_shorthair_cat/american_shorthair_cat_icon_v1.png",
	],
	"bengal_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "bengal_cat/bengal_cat_icon_v1.png",
	],
	"bird": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/bird/bird_icon_v1.png",
	],
	"chihuahua": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/chihuahua/chihuahua_icon_v1.png",
	],
	"grandma": [
		UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "boss/grandma/grandma_icon_v1.png",
	],
	"black_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "black_cat/black_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "black_cat/black_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "black_cat/black_cat_icon_v1.png",
	],
	"british_shorthair_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "british_shorthair_cat/british_shorthair_cat_icon_v1.png",
	],
	"calico_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "calico_cat/calico_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "calico_cat/calico_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "calico_cat/calico_cat_icon_v1.png",
	],
	"cow_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cow_cat/cow_cat_icon_v1.png",
	],
	"cream_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "cream_cat/cream_cat_icon_v1.png",
	],
	"maine_coon_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "maine_coon_cat/maine_coon_cat_icon_v1.png",
	],
	"milk_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "milk_cat/milk_cat_icon_v1.png",
	],
	"munchkin_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "munchkin_cat/munchkin_cat_icon_v1.png",
	],
	"ninja_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "ninja_cat/ninja_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ninja_cat/ninja_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ninja_cat/ninja_cat_icon_v1.png",
	],
	"norwegian_forest_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "norwegian_forest_cat/norwegian_forest_cat_icon_v1.png",
	],
	"orange_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "orange_cat/orange_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "orange_cat/orange_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "orange_cat/orange_cat_icon_v1.png",
	],
	"persian_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "persian_cat/persian_cat_icon_v1.png",
	],
	"ragdoll_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "ragdoll_cat/ragdoll_cat_icon_v1.png",
	],
	"russian_blue_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "russian_blue_cat/russian_blue_cat_icon_v1.png",
	],
	"siamese_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "siamese_cat/siamese_cat_icon_v1.png",
	],
	"silver_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "silver_cat/silver_cat_icon_v1.png",
	],
	"scottish_fold_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "scottish_fold_cat/scottish_fold_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "scottish_fold_cat/scottish_fold_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "scottish_fold_cat/scottish_fold_cat_icon_v1.png",
	],
	"smoke_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "smoke_cat/smoke_cat_icon_v1.png",
	],
	"sphinx_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "sphinx_cat/sphinx_cat_icon_v1.png",
	],
	"tabby_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tabby_cat/tabby_cat_icon_v1.png",
	],
	"tortoiseshell_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tortoiseshell_cat/tortoiseshell_cat_icon_v1.png",
	],
	"tuxedo_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "tuxedo_cat/tuxedo_cat_icon_v1.png",
	],
	"white_cat": [
		UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_ref_right_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_ref_three_quarter_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_ref_front_v1.png",
		UI_CDN_CHARACTER_REF_ROOT + "white_cat/white_cat_icon_v1.png",
	],
}

const CAT_BATTLE_SPRITES_ROOT := "res://assets/sprites/battle/cats/"
const ENCOUNTER_BATTLE_SPRITES_ROOT := "res://assets/sprites/battle/encounter/"
const BOSS_BATTLE_SPRITES_ROOT := "res://assets/sprites/battle/boss/"
const ENCOUNTER_CHARACTER_REF_ROOT := UI_CDN_CHARACTER_REF_ROOT + "encounters/"
const BOSS_CHARACTER_REF_ROOT := UI_CDN_CHARACTER_REF_ROOT + "boss/"
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
	"tortoiseshell_128": {
		"sheet_height": 128,
		"frame_width": 128,
		"frame_height": 128,
		"sheet_widths": {
			"idle": 768,
			"run": 768,
			"collide": 512,
			"knockback": 512,
			"stagger": 384,
			"skill": 768,
			"death_fly": 768,
		},
	},
	"russian_blue_128": {
		"sheet_height": 128,
		"frame_width": 128,
		"frame_height": 128,
		"sheet_widths": {
			"idle": 768,
			"run": 768,
			"collide": 512,
			"knockback": 512,
			"stagger": 384,
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
	"abyssinian_cat": "standard_256",
	"american_shorthair_cat": "standard_256",
	"baby": "baby_256",
	"bengal_cat": "standard_256",
	"bird": "bird_256",
	"black_cat": "standard_256",
	"british_shorthair_cat": "standard_256",
	"calico_cat": "small_128",
	"chihuahua": "boss_standard_128",
	"cow_cat": "standard_256",
	"cream_cat": "standard_256",
	"crazy_neighbor_boy": "boss_standard_128",
	"cucumber": "boss_standard_128",
	"grandma": "boss_standard_128",
	"lipstick": "standard_256",
	"maine_coon_cat": "standard_256",
	"male_coworker": "boss_standard_128",
	"milk_cat": "small_128",
	"munchkin_cat": "standard_256",
	"mouse": "boss_standard_128",
	"mug": "standard_256",
	"ninja_cat": "standard_256",
	"norwegian_forest_cat": "standard_256",
	"orange_cat": "standard_256",
	"persian_cat": "standard_256",
	"potted_plant": "standard_256",
	"ragdoll_cat": "standard_256",
	"remote_control": "standard_256",
	"robot_vacuum": "boss_standard_128",
	"russian_blue_cat": "russian_blue_128",
	"schoolgirl": "boss_standard_128",
	"scottish_fold_cat": "standard_256",
	"siamese_cat": "standard_256",
	"silver_cat": "standard_256",
	"smoke_cat": "standard_256",
	"sphinx_cat": "tortoiseshell_128",
	"tabby_cat": "standard_256",
	"toilet_paper": "standard_256",
	"tortoiseshell_cat": "tortoiseshell_128",
	"tuxedo_cat": "standard_256",
	"white_cat": "standard_256",
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
	"common": UI_CDN_GACHA_ROOT + "rarity_common_frame_v1.png",
	"uncommon": UI_CDN_GACHA_ROOT + "rarity_uncommon_frame_v1.png",
	"fine": UI_CDN_GACHA_ROOT + "rarity_fine_frame_v1.png",
	"special": UI_CDN_GACHA_ROOT + "rarity_special_frame_v1.png",
	"precious": UI_CDN_GACHA_ROOT + "rarity_precious_frame_v1.png",
	"excellent": UI_CDN_GACHA_ROOT + "rarity_excellent_frame_v1.png",
	"rare": UI_CDN_GACHA_ROOT + "rarity_rare_frame_v1.png",
	"epic": UI_CDN_GACHA_ROOT + "rarity_epic_frame_v1.png",
	"legendary": UI_CDN_GACHA_ROOT + "rarity_legendary_frame_v1.png",
}

const SCOOPER_EQUIPMENT := {
	1: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "straw_sleeve.png",
	2: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "scratcher.png",
	3: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "teaser_wand.png",
	4: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "grooming_brush.png",
	5: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "camera.png",
	6: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "warm_pad.png",
	7: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "cardboard_box.png",
	8: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "toy_doll.png",
	9: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "catnip_ball.png",
	10: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "electric_roller.png",
	11: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "spring_worm_doll.png",
	12: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "feather_top.png",
	13: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "glow_fish_line.png",
	14: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "fake_lizard.png",
	15: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "shadow_spider.png",
	16: UI_CDN_SCOOPER_EQUIPMENT_ROOT + "crystal_music_ball.png",
}

const SCOOPER_ABILITIES := {
	1: UI_CDN_SCOOPER_ABILITIES_ROOT + "diligent_scooper.png",
	2: UI_CDN_SCOOPER_ABILITIES_ROOT + "golden_scooper.png",
	3: UI_CDN_SCOOPER_ABILITIES_ROOT + "overtime_photo.png",
	4: UI_CDN_SCOOPER_ABILITIES_ROOT + "double_speed.png",
	5: UI_CDN_SCOOPER_ABILITIES_ROOT + "triple_speed.png",
	6: UI_CDN_SCOOPER_ABILITIES_ROOT + "instant_finish.png",
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
	_apply_remote_texture(texture_rect, asset_path, fallback_texture)


static func apply_preview_texture(texture_rect: TextureRect, path: String, fallback_slot: String = DEFAULT_BACKGROUND_SLOT) -> void:
	if texture_rect == null:
		return
	var fallback_texture: Texture2D = resolve_preview_texture(path, fallback_slot)
	_apply_remote_texture(texture_rect, path, fallback_texture)


static func apply_catalog_texture(texture_rect: TextureRect, raw_path: Variant) -> void:
	if texture_rect == null:
		return
	var resolved_path: String = resolve_catalog_path(raw_path)
	var fallback_texture: Texture2D = resolve_catalog_texture(raw_path)
	_apply_remote_texture(texture_rect, resolved_path, fallback_texture)


static func apply_cat_icon_texture(texture_rect: TextureRect, cat_id: String) -> void:
	if texture_rect == null:
		return
	var resolved_path: String = _resolve_cat_icon_path(cat_id)
	var fallback_texture: Texture2D = resolve_cat_icon(cat_id)
	_apply_remote_texture(texture_rect, resolved_path, fallback_texture)


static func apply_profile_avatar_texture(texture_rect: TextureRect, avatar_id: String) -> void:
	if texture_rect == null:
		return
	var normalized_id: String = avatar_id if avatar_id != "" else DEFAULT_PROFILE_AVATAR_ID
	var resolved_path: String = str(CAT_ICONS.get(normalized_id, CAT_ICONS.get(DEFAULT_PROFILE_AVATAR_ID, "")))
	var fallback_texture: Texture2D = resolve_profile_avatar(normalized_id)
	_apply_remote_texture(texture_rect, resolved_path, fallback_texture)


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


static func _apply_remote_texture(texture_rect: TextureRect, asset_path: String, fallback_texture: Texture2D) -> void:
	CdnTextureLoader.apply_texture(texture_rect, resolve_cdn_asset_url(asset_path), fallback_texture)


static func _get_background_path(slot: String) -> String:
	var resolved_slot: String = slot.strip_edges().to_lower()
	return str(BACKGROUNDS.get(resolved_slot, ""))


static func resolve_catalog_path(raw_path: Variant) -> String:
	var image_path: String = str(raw_path if raw_path != null else "").strip_edges()
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
		var suffix: String = normalized_path.trim_prefix("catalog/")
		var parts: PackedStringArray = suffix.split("/")
		if parts.size() < 2:
			return ""
		var folder: String = str(parts[0])
		var key: String = str(parts[1])
		match folder:
			"currency", "consumable":
				if key == "gold":
					return UI_LOCAL_ROOT + "rewards/gold.png.png"
				if key == "diamonds":
					return UI_LOCAL_ROOT + "rewards/diamonds.png"
				if key == "collision_coin":
					return UI_LOCAL_ROOT + "rewards/collision_coin.png"
				if key == "evil_cat_power_icon":
					return UI_LOCAL_ROOT + "rewards/evil_cat_power_icon.png"
				if key == "poop_count":
					return UI_LOCAL_ROOT + "rewards/poop_count.png"
				if key == "party_cheer_coupon":
					return UI_CDN_REWARDS_ROOT + "party_cheer_coupon.png"
				return UI_CDN_REWARDS_ROOT + "%s.png" % key
			"dungeon":
				return UI_CDN_DUNGEON_ROOT + "%s.png" % key
			"arena":
				return UI_CDN_ARENA_RANKS_ROOT + "%s.png" % key
			"memory":
				return UI_CDN_MEMORY_ROOT + "%s.png" % key
			"treasure":
				return UI_CDN_TREASURE_ROOT + "%s.png" % key
			"cat":
				return CAT_ICONS.get(key, "")
	return image_path


static func resolve_cat_icon(cat_id: String) -> Texture2D:
	return resolve_texture_or_placeholder(_resolve_cat_icon_path(cat_id))


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
	for suffix: String in ["ref_right_v1", "ref_three_quarter_v1", "ref_front_v1", "icon_v1"]:
		var resolved_path: String = _resolve_character_ref_path(cat_id, suffix)
		var resolved_texture: Texture2D = load_texture(resolved_path)
		if resolved_texture != null:
			return resolved_texture
	return resolve_cat_icon(cat_id)


static func resolve_onboarding_owner_avatar() -> Texture2D:
	var texture: Texture2D = load_texture(ONBOARDING_OWNER_AVATAR_PATH)
	if texture != null:
		return texture
	return resolve_placeholder_icon()


static func resolve_onboarding_generic_cat() -> Texture2D:
	var texture: Texture2D = load_texture(ONBOARDING_GENERIC_CAT_PATH)
	if texture != null:
		return texture
	return resolve_cat_icon(DEFAULT_PROFILE_AVATAR_ID)


static func resolve_cat_battle_static_art(cat_id: String) -> Texture2D:
	var candidates: Array = CAT_BATTLE_STATIC_ARTS.get(cat_id, [])
	for candidate_variant: Variant in candidates:
		var candidate_path: String = str(candidate_variant)
		var texture: Texture2D = load_texture(candidate_path)
		if texture != null:
			return texture
	for suffix: String in ["ref_right_v1", "ref_three_quarter_v1", "ref_front_v1", "icon_v1"]:
		var resolved_path: String = _resolve_character_ref_path(cat_id, suffix)
		var resolved_texture: Texture2D = load_texture(resolved_path)
		if resolved_texture != null:
			return resolved_texture
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


static func _resolve_cat_icon_path(cat_id: String) -> String:
	var mapped_path: String = str(CAT_ICONS.get(cat_id, ""))
	if mapped_path != "" and ResourceLoader.exists(mapped_path):
		return mapped_path
	return _resolve_character_ref_path(cat_id, "icon_v1")


static func _resolve_character_ref_path(cat_id: String, suffix: String) -> String:
	if cat_id.strip_edges().is_empty():
		return ""
	for root: String in _get_character_ref_roots(cat_id):
		var candidate_path: String = "%s%s/%s_%s.png" % [root, cat_id, cat_id, suffix]
		if ResourceLoader.exists(candidate_path):
			return candidate_path
	return ""


static func _get_character_ref_roots(cat_id: String) -> Array[String]:
	var roots: Array[String] = []
	if CAT_BATTLE_ENCOUNTER_CHARACTER_IDS.has(cat_id):
		roots.append(ENCOUNTER_CHARACTER_REF_ROOT)
	if CAT_BATTLE_BOSS_CHARACTER_IDS.has(cat_id):
		roots.append(BOSS_CHARACTER_REF_ROOT)
	roots.append(UI_CDN_CHARACTER_REF_ROOT)
	return roots


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
