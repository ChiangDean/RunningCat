class_name GameStateBossStage

## 純靜態運算：BOSS 關卡進度計算、關卡顯示、難度倍率、敵方生成
## 所有函式均為 static，不依賴 GameState 實例；呼叫時傳入 current_stage 與 boss_cfg。


# ── 進度輔助計算 ───────────────────────────────

## 當前 Boss 關序號（全局，1 起算）
static func get_boss_stage_number(current_stage: int, boss_cfg: Dictionary) -> int:
	var enc := _enc(boss_cfg)
	return ceili(float(current_stage) / float(enc + 1))


## 當前遭遇戰索引（1~enc = 普通遭遇戰，enc+1 = Boss）
static func get_encounter_index(current_stage: int, boss_cfg: Dictionary) -> int:
	var enc := _enc(boss_cfg)
	return ((current_stage - 1) % (enc + 1)) + 1


## 是否目前是 Boss 戰
static func is_current_boss(current_stage: int, boss_cfg: Dictionary) -> bool:
	var enc := _enc(boss_cfg)
	return get_encounter_index(current_stage, boss_cfg) == enc + 1


## Boss 關在當前區域內的序號（1~boss_stages_per_zone）
static func get_zone_boss_stage(current_stage: int, boss_cfg: Dictionary) -> int:
	var bsz := _bsz(boss_cfg)
	return ((get_boss_stage_number(current_stage, boss_cfg) - 1) % bsz) + 1


## 當前所在領地的區域序號（1~zones_per_territory）
static func get_zone_in_territory(current_stage: int, boss_cfg: Dictionary) -> int:
	var bsz := _bsz(boss_cfg)
	var zpt := _zpt(boss_cfg)
	var stages_per_territory: int = bsz * zpt
	return floori(float(((get_boss_stage_number(current_stage, boss_cfg) - 1) % stages_per_territory)) / float(bsz)) + 1


## 當前領地序號（1 起算）
static func get_territory_number(current_stage: int, boss_cfg: Dictionary) -> int:
	var bsz := _bsz(boss_cfg)
	var zpt := _zpt(boss_cfg)
	var stages_per_territory: int = bsz * zpt
	return floori(float(get_boss_stage_number(current_stage, boss_cfg) - 1) / float(stages_per_territory)) + 1


# ── 關卡顯示 ──────────────────────────────────

## 顯示格式範例：「新手 I  1-4」、「新手 II  3-BOSS」
static func get_level_display(current_stage: int, boss_cfg: Dictionary) -> String:
	var stage_str: String
	if is_current_boss(current_stage, boss_cfg):
		stage_str = "%d-BOSS" % get_zone_boss_stage(current_stage, boss_cfg)
	else:
		stage_str = "%d-%d" % [get_zone_boss_stage(current_stage, boss_cfg), get_encounter_index(current_stage, boss_cfg)]

	return "%s %s  %s" % [
		_get_territory_name(get_territory_number(current_stage, boss_cfg), boss_cfg),
		_get_zone_suffix(get_zone_in_territory(current_stage, boss_cfg), boss_cfg),
		stage_str,
	]


static func _get_territory_name(t: int, boss_cfg: Dictionary) -> String:
	var arr: Array = boss_cfg.get("territory_names", ["", "新手", "普通", "高級", "進階", "菁英"])
	if t < arr.size():
		return arr[t]
	return "領地%d" % t


static func _get_zone_suffix(z: int, boss_cfg: Dictionary) -> String:
	var arr: Array = boss_cfg.get("zone_suffixes", ["", "I", "II", "III", "IV", "V"])
	if z < arr.size():
		return arr[z]
	return "%d" % z


# ── 難度計算 ───────────────────────────────────

## 回傳當前關卡的敵方數值倍率
## 普通遭遇戰：每關 +0.3% 複利成長（Stage 軌道）
## Boss 關：每個 Boss +2% 複利成長（Boss 軌道）
static func get_difficulty_multiplier(current_stage: int, boss_cfg: Dictionary) -> float:
	var stage_growth: float = float(boss_cfg.get("stage_growth", 1.003))
	var boss_growth: float  = float(boss_cfg.get("boss_growth", 1.02))
	if is_current_boss(current_stage, boss_cfg):
		return pow(boss_growth, get_boss_stage_number(current_stage, boss_cfg))
	else:
		return pow(stage_growth, current_stage - 1)


# ── 敵方生成 ───────────────────────────────────

static func get_enemy_ids(current_stage: int, boss_cfg: Dictionary) -> Array:
	var boss_stage := get_boss_stage_number(current_stage, boss_cfg)
	var count: int
	if is_current_boss(current_stage, boss_cfg):
		count = mini(1 + boss_stage, 5)
	else:
		count = mini(1 + floori(float(boss_stage - 1) / 3.0), 5)
	count = maxi(count, 1)
	var ids: Array = []
	for i in range(count):
		ids.append("test_enemy")
	return ids


# ── 私有輔助（取設定整數）────────────────────

static func _enc(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("encounters_per_boss_stage", 4))

static func _bsz(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("boss_stages_per_zone", 10))

static func _zpt(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("zones_per_territory", 5))
