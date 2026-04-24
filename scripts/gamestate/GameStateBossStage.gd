class_name GameStateBossStage

## Pure static helpers: Boss stage progress, level display, difficulty multiplier, enemy generation
## All functions are static; no GameState instance required — pass current_stage and boss_cfg at call site.


# ── Progress helpers ───────────────────────────────

## Current Boss stage number (global, 1-indexed)
static func get_boss_stage_number(current_stage: int, boss_cfg: Dictionary) -> int:
	var enc := _enc(boss_cfg)
	return ceili(float(current_stage) / float(enc + 1))


## Current encounter index (1~enc = regular encounter, enc+1 = Boss)
static func get_encounter_index(current_stage: int, boss_cfg: Dictionary) -> int:
	var enc := _enc(boss_cfg)
	return ((current_stage - 1) % (enc + 1)) + 1


## Whether the current stage is a Boss battle
static func is_current_boss(current_stage: int, boss_cfg: Dictionary) -> bool:
	var enc := _enc(boss_cfg)
	return get_encounter_index(current_stage, boss_cfg) == enc + 1


## Global stage number of the last regular encounter for a given Boss stage
static func get_last_encounter_stage_for_boss_stage(boss_stage: int, boss_cfg: Dictionary) -> int:
	var enc: int = _enc(boss_cfg)
	var normalized_boss_stage: int = maxi(boss_stage, 1)
	return normalized_boss_stage * (enc + 1) - 1


## Global stage number of the Boss battle for a given Boss stage
static func get_boss_global_stage_for_boss_stage(boss_stage: int, boss_cfg: Dictionary) -> int:
	var enc: int = _enc(boss_cfg)
	var normalized_boss_stage: int = maxi(boss_stage, 1)
	return normalized_boss_stage * (enc + 1)


## When Boss is unlocked: hold at the last encounter after a win so the player can manually challenge the Boss.
static func should_hold_after_last_encounter_win(current_stage: int, boss_available: bool, boss_cfg: Dictionary) -> bool:
	if not boss_available:
		return false
	if is_current_boss(current_stage, boss_cfg):
		return false

	var enc: int = _enc(boss_cfg)
	return get_encounter_index(current_stage, boss_cfg) == enc


## Boss stage index within the current zone (1~boss_stages_per_zone)
static func get_zone_boss_stage(current_stage: int, boss_cfg: Dictionary) -> int:
	var bsz := _bsz(boss_cfg)
	return ((get_boss_stage_number(current_stage, boss_cfg) - 1) % bsz) + 1


## Zone index within the current territory (1~zones_per_territory)
static func get_zone_in_territory(current_stage: int, boss_cfg: Dictionary) -> int:
	var bsz := _bsz(boss_cfg)
	var zpt := _zpt(boss_cfg)
	var stages_per_territory: int = bsz * zpt
	return floori(float(((get_boss_stage_number(current_stage, boss_cfg) - 1) % stages_per_territory)) / float(bsz)) + 1


## Current territory number (1-indexed)
static func get_territory_number(current_stage: int, boss_cfg: Dictionary) -> int:
	var bsz := _bsz(boss_cfg)
	var zpt := _zpt(boss_cfg)
	var stages_per_territory: int = bsz * zpt
	return floori(float(get_boss_stage_number(current_stage, boss_cfg) - 1) / float(stages_per_territory)) + 1


# ── Level display ──────────────────────────────────

## Display format examples: "Novice I  1-4", "Novice II  3-BOSS"
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
	var arr: Array = boss_cfg.get("territory_names", UiText.BOSSMAP_TERRITORY_NAMES_DEFAULT)
	if t < arr.size():
		return arr[t]
	return UiText.BOSSMAP_TERRITORY_FALLBACK_FORMAT % t


static func _get_zone_suffix(z: int, boss_cfg: Dictionary) -> String:
	var arr: Array = boss_cfg.get("zone_suffixes", ["", "I", "II", "III", "IV", "V"])
	if z < arr.size():
		return arr[z]
	return "%d" % z


# ── Difficulty calculation ───────────────────────────────

## Return the enemy stat multiplier for the current stage
## Regular encounters: +0.3% compound growth per stage (Stage track)
## Boss battles: +2% compound growth per Boss (Boss track)
static func get_difficulty_multiplier(current_stage: int, boss_cfg: Dictionary) -> float:
	var stage_growth: float = float(boss_cfg.get("stage_growth", 1.003))
	var boss_growth: float  = float(boss_cfg.get("boss_growth", 1.02))
	if is_current_boss(current_stage, boss_cfg):
		return pow(boss_growth, get_boss_stage_number(current_stage, boss_cfg))
	else:
		return pow(stage_growth, current_stage - 1)


# ── Enemy generation ───────────────────────────────

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


# ── Private helpers (config integer getters) ────────────────────

static func _enc(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("encounters_per_boss_stage", 4))

static func _bsz(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("boss_stages_per_zone", 10))

static func _zpt(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("zones_per_territory", 5))
