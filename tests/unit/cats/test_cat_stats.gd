extends GutTest

## 測試對象：CatStats（DEF 減傷、傷害計算、回彈距離）

const DELTA := 0.0001


# ── calc_def_reduction ────────────────────────────────────────────

func test_def_0_gives_0_reduction() -> void:
	assert_almost_eq(CatStats.calc_def_reduction(0.0), 0.0, DELTA)

func test_def_negative_gives_0_reduction() -> void:
	assert_almost_eq(CatStats.calc_def_reduction(-50.0), 0.0, DELTA)

func test_def_100_gives_50_percent_reduction() -> void:
	assert_almost_eq(CatStats.calc_def_reduction(100.0), 0.5, DELTA)

func test_def_300_gives_75_percent_reduction() -> void:
	assert_almost_eq(CatStats.calc_def_reduction(300.0), 0.75, DELTA)

func test_reduction_never_reaches_1() -> void:
	assert_lt(CatStats.calc_def_reduction(99999.0), 1.0)

func test_reduction_increases_with_defense() -> void:
	var prev := CatStats.calc_def_reduction(0.0)
	for d in [50.0, 100.0, 200.0, 500.0, 1000.0]:
		var cur := CatStats.calc_def_reduction(d)
		assert_gt(cur, prev, "reduction should increase as def increases")
		prev = cur


# ── calc_damage ───────────────────────────────────────────────────

func test_damage_with_0_def_equals_atk() -> void:
	assert_almost_eq(CatStats.calc_damage(100.0, 0.0), 100.0, DELTA)

func test_damage_with_100_def_is_half_atk() -> void:
	assert_almost_eq(CatStats.calc_damage(100.0, 100.0), 50.0, DELTA)

func test_damage_with_300_def_is_quarter_atk() -> void:
	assert_almost_eq(CatStats.calc_damage(100.0, 300.0), 25.0, DELTA)

func test_damage_minimum_is_1() -> void:
	# 即使 ATK 很低、DEF 很高，傷害最小為 1
	assert_almost_eq(CatStats.calc_damage(1.0, 99999.0), 1.0, DELTA)

func test_damage_with_ignore_def_reduces_effective_defense() -> void:
	# ignore_def=50 使有效 DEF 從 100 降到 50
	var with_ignore    := CatStats.calc_damage(100.0, 100.0, 50.0)
	var without_ignore := CatStats.calc_damage(100.0, 100.0)
	assert_gt(with_ignore, without_ignore)

func test_damage_ignore_def_exceeding_defense_clamps_to_0() -> void:
	# ignore_def > defense → 等同 defense=0
	assert_almost_eq(CatStats.calc_damage(100.0, 50.0, 200.0), 100.0, DELTA)


# ── calc_knockback_distance ───────────────────────────────────────

func test_equal_weights_returns_100() -> void:
	assert_almost_eq(CatStats.calc_knockback_distance(100.0, 100.0), 100.0, DELTA)

func test_heavier_attacker_increases_knockback() -> void:
	var light := CatStats.calc_knockback_distance(100.0, 100.0)
	var heavy := CatStats.calc_knockback_distance(200.0, 100.0)
	assert_gt(heavy, light)

func test_lighter_attacker_decreases_knockback() -> void:
	var normal := CatStats.calc_knockback_distance(100.0, 100.0)
	var light  := CatStats.calc_knockback_distance(50.0,  100.0)
	assert_lt(light, normal)

func test_knockback_clamped_to_min_30() -> void:
	# 攻擊方極輕 → 回彈距離不低於 MIN_KNOCKBACK=30
	assert_almost_eq(CatStats.calc_knockback_distance(1.0, 99999.0), CatStats.MIN_KNOCKBACK, DELTA)

func test_knockback_clamped_to_max_300() -> void:
	# 攻擊方極重 → 回彈距離不超過 MAX_KNOCKBACK=300
	assert_almost_eq(CatStats.calc_knockback_distance(99999.0, 1.0), CatStats.MAX_KNOCKBACK, DELTA)
