class_name ConfigConstants

## ConfigScene 共用常數：尺寸、隊伍類型、標籤、貓咪檔案對映

const SW := 720.0
const SH := 1280.0

## 前端路由用 team type 字串（snake_case）→ 後端 TeamSceneType 名稱（PascalCase）
const TEAM_TYPE_MAP: Dictionary = {
	"boss":          "Boss",
	"dungeon":       "Dungeon",
	"arena_attack":  "ArenaAttack",
	"arena_defense": "ArenaDefense",
}

const TEAM_LABELS: Dictionary = {
	"boss":          "BOSS 推關",
	"dungeon":       "地下城",
	"arena_attack":  "競技場攻擊",
	"arena_defense": "競技場防禦",
}

## 本地 cat catalog ID → 本地 JSON 檔名（用於技能 popup）
const CAT_FILE_MAP: Dictionary = {
	1: "black_cat",
	2: "calico_cat",
	3: "milk_cat",
	4: "ninja_cat",
	5: "orange_cat",
	7: "tuxedo_cat",
}
