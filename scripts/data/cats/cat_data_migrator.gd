class_name CatDataMigrator
extends RefCounted

## 負責處理 JSON schema 版本升級與欄位改名
## 未來若屬性改名，在這裡加入 alias，不需要動其他程式碼

const CURRENT_VERSION: int = 1

# 欄位別名對照表：若 JSON 使用舊名稱，自動對應到新名稱
# 格式："舊欄位名" -> "新欄位名"
# 範例：若日後把 atk 改名為 attack，在此加入 "atk": "attack"
const STAT_ALIASES: Dictionary = {
	# "atk": "attack",  # 範例（未啟用）
}


static func migrate(raw: Dictionary) -> Dictionary:
	var data: Dictionary = raw.duplicate(true)

	# 解析 base_stats 中的欄位別名
	if data.has("base_stats"):
		data["base_stats"] = _resolve_aliases(data["base_stats"], STAT_ALIASES)

	# 依版本號執行升級
	var version: int = data.get("schema_version", 0)
	data = _migrate_to_current(data, version)
	data["schema_version"] = CURRENT_VERSION

	return data


static func _resolve_aliases(stats: Dictionary, aliases: Dictionary) -> Dictionary:
	var resolved: Dictionary = stats.duplicate()
	for old_key: String in aliases:
		var new_key: String = aliases[old_key]
		# 若 JSON 有舊欄位且沒有新欄位，自動轉換
		if resolved.has(old_key) and not resolved.has(new_key):
			resolved[new_key] = resolved[old_key]
			resolved.erase(old_key)
	return resolved


static func _migrate_to_current(data: Dictionary, from_version: int) -> Dictionary:
	## 每個版本升級在這裡加一個 if 區塊
	## 範例：
	# if from_version < 1:
	#     data = _migrate_v0_to_v1(data)
	return data
