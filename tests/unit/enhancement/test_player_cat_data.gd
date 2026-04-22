extends GutTest

## 測試對象：PlayerCatData 靜態費用計算函式


# ── cat_food_cost_for_level ───────────────────────────────────────

func test_cost_level_0_is_1() -> void:
	# (0+1)² = 1
	assert_eq(PlayerCatData.cat_food_cost_for_level(0), 1)

func test_cost_level_1_is_4() -> void:
	# (1+1)² = 4
	assert_eq(PlayerCatData.cat_food_cost_for_level(1), 4)

func test_cost_level_9_is_100() -> void:
	# (9+1)² = 100
	assert_eq(PlayerCatData.cat_food_cost_for_level(9), 100)

func test_cost_level_29_is_900() -> void:
	# (29+1)² = 900
	assert_eq(PlayerCatData.cat_food_cost_for_level(29), 900)

func test_cost_grows_quadratically() -> void:
	# 每一級的費用必須嚴格遞增
	var prev := PlayerCatData.cat_food_cost_for_level(0)
	for lv in range(1, 30):
		var cur := PlayerCatData.cat_food_cost_for_level(lv)
		assert_gt(cur, prev, "level %d cost should be > level %d cost" % [lv, lv - 1])
		prev = cur


# ── cat_food_total_cost ───────────────────────────────────────────

func test_total_cost_same_level_is_0() -> void:
	assert_eq(PlayerCatData.cat_food_total_cost(5, 5), 0)

func test_total_cost_0_to_1_equals_single_cost() -> void:
	assert_eq(PlayerCatData.cat_food_total_cost(0, 1), PlayerCatData.cat_food_cost_for_level(0))

func test_total_cost_0_to_3_is_sum_of_three_levels() -> void:
	# 1 + 4 + 9 = 14
	assert_eq(PlayerCatData.cat_food_total_cost(0, 3), 14)

func test_total_cost_is_additive() -> void:
	# cost(0→5) = cost(0→3) + cost(3→5)
	var full  := PlayerCatData.cat_food_total_cost(0, 5)
	var part1 := PlayerCatData.cat_food_total_cost(0, 3)
	var part2 := PlayerCatData.cat_food_total_cost(3, 5)
	assert_eq(full, part1 + part2)


# ── special_food_next_cost ────────────────────────────────────────

func test_next_cost_at_0_allocated_is_1() -> void:
	assert_eq(PlayerCatData.special_food_next_cost(0), 1)

func test_next_cost_at_5_allocated_is_6() -> void:
	assert_eq(PlayerCatData.special_food_next_cost(5), 6)

func test_next_cost_grows_linearly() -> void:
	for n in range(0, 10):
		assert_eq(PlayerCatData.special_food_next_cost(n), n + 1)


# ── special_food_total_spent ──────────────────────────────────────

func test_total_spent_0_points_is_0() -> void:
	assert_eq(PlayerCatData.special_food_total_spent(0), 0)

func test_total_spent_1_point_is_1() -> void:
	assert_eq(PlayerCatData.special_food_total_spent(1), 1)

func test_total_spent_3_points_is_6() -> void:
	# 1 + 2 + 3 = 6
	assert_eq(PlayerCatData.special_food_total_spent(3), 6)

func test_total_spent_5_points_is_15() -> void:
	# 1+2+3+4+5 = 15
	assert_eq(PlayerCatData.special_food_total_spent(5), 15)

func test_total_spent_equals_sum_of_next_costs() -> void:
	# total_spent(n) 應等於 sum of next_cost(0..n-1)
	for n in range(0, 8):
		var expected := 0
		for i in range(n):
			expected += PlayerCatData.special_food_next_cost(i)
		assert_eq(PlayerCatData.special_food_total_spent(n), expected,
			"total_spent(%d) mismatch" % n)


# ── rank_upgrade_cost ─────────────────────────────────────────────

func test_rank_cost_to_rank_1_is_20() -> void:
	assert_eq(PlayerCatData.rank_upgrade_cost(1), 20)

func test_rank_cost_to_rank_5_is_100() -> void:
	assert_eq(PlayerCatData.rank_upgrade_cost(5), 100)

func test_rank_cost_grows_linearly_with_target_rank() -> void:
	for r in range(1, 10):
		assert_eq(PlayerCatData.rank_upgrade_cost(r), r * 20)
