extends GutTest

## 測試對象：GameStateBossStage（純靜態計算，無場景依賴）

var _cfg: Dictionary


func before_each() -> void:
	_cfg = BossCfgBuilder.standard().build()
	# 預設：encounters=4，每5關一循環（1-4普通、5 Boss）


# ── get_boss_stage_number ─────────────────────────────────────────

func test_boss_stage_number_stage_1_is_boss_1() -> void:
	assert_eq(GameStateBossStage.get_boss_stage_number(1, _cfg), 1)

func test_boss_stage_number_stage_4_is_boss_1() -> void:
	assert_eq(GameStateBossStage.get_boss_stage_number(4, _cfg), 1)

func test_boss_stage_number_boss_stage_itself_is_boss_1() -> void:
	assert_eq(GameStateBossStage.get_boss_stage_number(5, _cfg), 1)

func test_boss_stage_number_stage_6_is_boss_2() -> void:
	assert_eq(GameStateBossStage.get_boss_stage_number(6, _cfg), 2)

func test_boss_stage_number_stage_10_is_boss_2() -> void:
	assert_eq(GameStateBossStage.get_boss_stage_number(10, _cfg), 2)

func test_boss_stage_number_stage_11_is_boss_3() -> void:
	assert_eq(GameStateBossStage.get_boss_stage_number(11, _cfg), 3)

func test_boss_stage_number_custom_enc_2() -> void:
	var cfg := BossCfgBuilder.standard().with_encounters(2).build()
	# enc=2 → 每3關一循環
	assert_eq(GameStateBossStage.get_boss_stage_number(3, cfg), 1)
	assert_eq(GameStateBossStage.get_boss_stage_number(4, cfg), 2)


# ── get_encounter_index ───────────────────────────────────────────

func test_encounter_index_stage_1_is_1() -> void:
	assert_eq(GameStateBossStage.get_encounter_index(1, _cfg), 1)

func test_encounter_index_stage_4_is_4() -> void:
	assert_eq(GameStateBossStage.get_encounter_index(4, _cfg), 4)

func test_encounter_index_boss_stage_is_enc_plus_1() -> void:
	assert_eq(GameStateBossStage.get_encounter_index(5, _cfg), 5)

func test_encounter_index_wraps_to_1_after_boss() -> void:
	assert_eq(GameStateBossStage.get_encounter_index(6, _cfg), 1)

func test_encounter_index_second_cycle_boss() -> void:
	assert_eq(GameStateBossStage.get_encounter_index(10, _cfg), 5)


# ── is_current_boss ───────────────────────────────────────────────

func test_is_boss_false_on_normal_stage() -> void:
	assert_false(GameStateBossStage.is_current_boss(1, _cfg))
	assert_false(GameStateBossStage.is_current_boss(4, _cfg))

func test_is_boss_true_on_boss_stage() -> void:
	assert_true(GameStateBossStage.is_current_boss(5, _cfg))
	assert_true(GameStateBossStage.is_current_boss(10, _cfg))

func test_is_boss_false_on_stage_after_boss() -> void:
	assert_false(GameStateBossStage.is_current_boss(6, _cfg))


# ── boss challenge hold / jump helpers ────────────────────────────

func test_last_encounter_stage_for_boss_stage_1_is_stage_4() -> void:
	assert_eq(GameStateBossStage.get_last_encounter_stage_for_boss_stage(1, _cfg), 4)

func test_boss_global_stage_for_boss_stage_1_is_stage_5() -> void:
	assert_eq(GameStateBossStage.get_boss_global_stage_for_boss_stage(1, _cfg), 5)

func test_boss_available_last_encounter_win_holds_stage() -> void:
	assert_true(GameStateBossStage.should_hold_after_last_encounter_win(4, true, _cfg))

func test_boss_unavailable_last_encounter_win_can_advance() -> void:
	assert_false(GameStateBossStage.should_hold_after_last_encounter_win(4, false, _cfg))

func test_boss_available_non_last_encounter_win_can_advance() -> void:
	assert_false(GameStateBossStage.should_hold_after_last_encounter_win(3, true, _cfg))

func test_boss_available_boss_stage_win_can_advance() -> void:
	assert_false(GameStateBossStage.should_hold_after_last_encounter_win(5, true, _cfg))

func test_custom_encounter_count_hold_and_jump_helpers() -> void:
	var cfg: Dictionary = BossCfgBuilder.standard().with_encounters(2).build()
	assert_eq(GameStateBossStage.get_last_encounter_stage_for_boss_stage(2, cfg), 5)
	assert_eq(GameStateBossStage.get_boss_global_stage_for_boss_stage(2, cfg), 6)
	assert_true(GameStateBossStage.should_hold_after_last_encounter_win(5, true, cfg))


# ── get_difficulty_multiplier ─────────────────────────────────────

func test_difficulty_stage_1_is_1() -> void:
	assert_almost_eq(GameStateBossStage.get_difficulty_multiplier(1, _cfg), 1.0, 0.0001)

func test_difficulty_normal_stage_uses_stage_growth() -> void:
	# stage 4（普通）: pow(1.003, 3)
	var expected := pow(1.003, 3)
	assert_almost_eq(GameStateBossStage.get_difficulty_multiplier(4, _cfg), expected, 0.0001)

func test_difficulty_boss_stage_uses_boss_growth() -> void:
	# stage 5（Boss 1）: pow(1.02, 1)
	assert_almost_eq(GameStateBossStage.get_difficulty_multiplier(5, _cfg), 1.02, 0.0001)

func test_difficulty_boss_2_is_boss_growth_squared() -> void:
	# stage 10（Boss 2）: pow(1.02, 2)
	assert_almost_eq(GameStateBossStage.get_difficulty_multiplier(10, _cfg), pow(1.02, 2), 0.0001)

func test_difficulty_normal_stage_does_not_use_boss_track() -> void:
	# 普通關的倍率必須小於同位置 Boss 關
	var normal_mult := GameStateBossStage.get_difficulty_multiplier(4, _cfg)
	var boss_mult   := GameStateBossStage.get_difficulty_multiplier(5, _cfg)
	assert_lt(normal_mult, boss_mult)

func test_difficulty_custom_growth_rates() -> void:
	var cfg := BossCfgBuilder.standard().with_stage_growth(1.01).with_boss_growth(1.05).build()
	assert_almost_eq(GameStateBossStage.get_difficulty_multiplier(1, cfg), 1.0,  0.0001)
	assert_almost_eq(GameStateBossStage.get_difficulty_multiplier(5, cfg), 1.05, 0.0001)


# ── get_enemy_ids ─────────────────────────────────────────────────

func test_enemy_ids_stage_1_returns_one_enemy() -> void:
	assert_eq(GameStateBossStage.get_enemy_ids(1, _cfg).size(), 1)

func test_enemy_ids_count_does_not_exceed_5() -> void:
	for stage in [1, 5, 50, 100, 999]:
		var ids := GameStateBossStage.get_enemy_ids(stage, _cfg)
		assert_lte(ids.size(), 5, "stage %d should not exceed 5 enemies" % stage)

func test_enemy_ids_count_is_at_least_1() -> void:
	for stage in [1, 5, 50, 100]:
		var ids := GameStateBossStage.get_enemy_ids(stage, _cfg)
		assert_gte(ids.size(), 1, "stage %d should have at least 1 enemy" % stage)
