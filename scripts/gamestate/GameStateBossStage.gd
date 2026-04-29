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

## Returns enemy_key strings for the current stage using 3-layer priority.
## Falls back to ["silver_cat"] when opponent_cfg is empty (pre-bootstrap).
static func get_enemy_ids(current_stage: int, boss_cfg: Dictionary, opponent_cfg: Dictionary = {}) -> Array:
	if opponent_cfg.is_empty():
		return _placeholder_ids(current_stage, boss_cfg)
	if is_current_boss(current_stage, boss_cfg):
		return [_resolve_boss_key(current_stage, boss_cfg, opponent_cfg)]
	else:
		return _resolve_encounter_keys(current_stage, boss_cfg, opponent_cfg)


# ── Private helpers (opponent config query) ────────────────────

static func _resolve_encounter_keys(current_stage: int, boss_cfg: Dictionary, opponent_cfg: Dictionary) -> Array:
	var enc_idx: int = -(get_encounter_index(current_stage, boss_cfg))  # DB uses -1..-4
	var territory: int = get_territory_number(current_stage, boss_cfg)

	# 1. Level override
	for lo: Variant in opponent_cfg.get("levelOverrides", []):
		if lo is Dictionary and int(lo.get("globalStage", 0)) == current_stage:
			var cfg_id: int = int(lo.get("encounterConfigId", 0))
			if cfg_id > 0:
				return _keys_from_encounter_id(cfg_id, opponent_cfg)

	# 2. Territory encounter override
	for teo: Variant in opponent_cfg.get("territoryEncounterOverrides", []):
		if teo is Dictionary and int(teo.get("territoryOrder", 0)) == territory \
				and int(teo.get("encounterIndex", 0)) == enc_idx:
			var cfg_id: int = int(teo.get("enemyConfigId", 0))
			if cfg_id > 0:
				return _keys_from_encounter_id(cfg_id, opponent_cfg)

	# 3. Global default
	for ec: Variant in opponent_cfg.get("encounterConfigs", []):
		if ec is Dictionary and bool(ec.get("isGlobalDefault", false)) \
				and int(ec.get("encounterIndex", 0)) == enc_idx:
			return _keys_from_members(ec.get("members", []), opponent_cfg)

	return ["silver_cat"]


static func _resolve_boss_key(current_stage: int, boss_cfg: Dictionary, opponent_cfg: Dictionary) -> String:
	var territory: int = get_territory_number(current_stage, boss_cfg)
	var boss_pos: int  = get_zone_boss_stage(current_stage, boss_cfg)  # 1-10

	# 1. Level override
	for lo: Variant in opponent_cfg.get("levelOverrides", []):
		if lo is Dictionary and int(lo.get("globalStage", 0)) == current_stage:
			var enemy_id: int = int(lo.get("enemyId", 0))
			if enemy_id > 0:
				return _key_from_enemy_id(enemy_id, opponent_cfg)

	# 2. Territory Boss override
	for tbo: Variant in opponent_cfg.get("territoryBossOverrides", []):
		if tbo is Dictionary and int(tbo.get("territoryOrder", 0)) == territory \
				and int(tbo.get("bossPosition", 0)) == boss_pos:
			return _key_from_enemy_id(int(tbo.get("enemyId", 0)), opponent_cfg)

	# 3. Territory template → global default template
	var template_id: int = 0
	for tbt: Variant in opponent_cfg.get("territoryBossTemplates", []):
		if tbt is Dictionary and int(tbt.get("territoryOrder", 0)) == territory:
			template_id = int(tbt.get("bossTemplateId", 0))
			break
	if template_id == 0:
		for bt: Variant in opponent_cfg.get("bossTemplates", []):
			if bt is Dictionary and bool(bt.get("isGlobalDefault", false)):
				template_id = int(bt.get("id", 0))
				break

	for bt: Variant in opponent_cfg.get("bossTemplates", []):
		if bt is Dictionary and int(bt.get("id", 0)) == template_id:
			for m: Variant in bt.get("members", []):
				if m is Dictionary and int(m.get("bossPosition", 0)) == boss_pos:
					return _key_from_enemy_id(int(m.get("enemyId", 0)), opponent_cfg)

	return "silver_cat"


static func _keys_from_encounter_id(config_id: int, opponent_cfg: Dictionary) -> Array:
	for ec: Variant in opponent_cfg.get("encounterConfigs", []):
		if ec is Dictionary and int(ec.get("id", 0)) == config_id:
			return _keys_from_members(ec.get("members", []), opponent_cfg)
	return ["silver_cat"]


static func _keys_from_members(members: Variant, opponent_cfg: Dictionary) -> Array:
	if not (members is Array):
		return ["silver_cat"]
	var sorted: Array = (members as Array).duplicate()
	sorted.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int((a as Dictionary).get("slotNo", 0)) < int((b as Dictionary).get("slotNo", 0)))
	var keys: Array = []
	for m: Variant in sorted:
		if m is Dictionary:
			var k: String = _key_from_enemy_id(int(m.get("enemyId", 0)), opponent_cfg)
			if not k.is_empty():
				keys.append(k)
	return keys if not keys.is_empty() else ["silver_cat"]


static func _key_from_enemy_id(enemy_id: int, opponent_cfg: Dictionary) -> String:
	for e: Variant in opponent_cfg.get("enemies", []):
		if e is Dictionary and int(e.get("id", 0)) == enemy_id:
			return str(e.get("enemyKey", ""))
	return "silver_cat"


static func _placeholder_ids(current_stage: int, boss_cfg: Dictionary) -> Array:
	var boss_stage := get_boss_stage_number(current_stage, boss_cfg)
	var count: int
	if is_current_boss(current_stage, boss_cfg):
		count = mini(1 + boss_stage, 5)
	else:
		count = mini(1 + floori(float(boss_stage - 1) / 3.0), 5)
	var ids: Array = []
	for i: int in range(maxi(count, 1)):
		ids.append("silver_cat")
	return ids


# ── Private helpers (config integer getters) ────────────────────

static func _enc(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("encounters_per_boss_stage", 4))

static func _bsz(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("boss_stages_per_zone", 10))

static func _zpt(boss_cfg: Dictionary) -> int:
	return int(boss_cfg.get("zones_per_territory", 5))
