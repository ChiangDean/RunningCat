class_name GameConstants
extends RefCounted

## Rarity tiers
enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

## Color for each rarity
const RARITY_COLORS := {
	Rarity.COMMON: Color(0.78, 0.78, 0.78, 1.0),
	Rarity.RARE: Color(0.43, 0.73, 1.0, 1.0),
	Rarity.EPIC: Color(0.78, 0.50, 1.0, 1.0),
	Rarity.LEGENDARY: Color(1.0, 0.78, 0.36, 1.0),
}

## Maps API rarityType string to the Rarity enum
const RARITY_NAME_MAP := {
	"Common": Rarity.COMMON,
	"Rare": Rarity.RARE,
	"Epic": Rarity.EPIC,
	"Legendary": Rarity.LEGENDARY,
}


static func get_rarity_color(rarity: Rarity) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)


static func get_rarity_color_from_string(rarity_type: String) -> Color:
	var rarity: Rarity = RARITY_NAME_MAP.get(rarity_type, Rarity.COMMON)
	return get_rarity_color(rarity)
