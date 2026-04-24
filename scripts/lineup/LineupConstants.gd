class_name LineupConstants

## Shared constants for ConfigScene: sizes, team types, labels, cat file mapping

const SW := 720.0
const SH := 1280.0

## Maps frontend route team-type strings (snake_case) to backend TeamSceneType names (PascalCase)
const TEAM_TYPE_MAP: Dictionary = {
	"boss":          "Boss",
	"dungeon":       "Dungeon",
	"arena_attack":  "ArenaAttack",
	"arena_defense": "ArenaDefense",
}

const TEAM_LABELS: Dictionary = {
	"boss":          UiText.LINEUP_TEAM_LABEL_BOSS,
	"dungeon":       UiText.LINEUP_TEAM_LABEL_DUNGEON,
	"arena_attack":  UiText.LINEUP_TEAM_LABEL_ARENA_ATTACK,
	"arena_defense": UiText.LINEUP_TEAM_LABEL_ARENA_DEFENSE,
}

## Maps local cat catalog ID to local JSON filename (used for skill popups)
const CAT_FILE_MAP: Dictionary = {
	1: "black_cat",
	2: "calico_cat",
	3: "milk_cat",
	4: "ninja_cat",
	5: "orange_cat",
	7: "tuxedo_cat",
}
