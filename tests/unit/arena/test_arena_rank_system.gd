extends GutTest

## 測試對象：ArenaRankSystem（段位查表、可領獎勵邏輯）


# ── score_to_rank_key ─────────────────────────────────────────────

func test_score_0_is_bronze_3() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_key(0), "bronze_3")

func test_score_negative_clamps_to_bronze_3() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_key(-999), "bronze_3")

func test_score_99_is_bronze_3() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_key(99), "bronze_3")

func test_score_100_is_bronze_2() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_key(100), "bronze_2")

func test_score_199_is_bronze_2() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_key(199), "bronze_2")

func test_score_200_is_bronze_1() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_key(200), "bronze_1")

func test_score_at_each_threshold() -> void:
	var cases := {
		300:  "silver_3",
		600:  "gold_3",
		900:  "platinum_3",
		1200: "diamond_3",
		1500: "master_3",
		2000: "elite",
	}
	for score: int in cases:
		assert_eq(ArenaRankSystem.score_to_rank_key(score), cases[score],
			"score %d should be %s" % [score, cases[score]])

func test_score_9999_is_elite() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_key(9999), "elite")

func test_score_just_below_threshold_stays_lower_rank() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_key(599), "silver_1")
	assert_eq(ArenaRankSystem.score_to_rank_key(1999), "master_1")


# ── score_to_rank_name ────────────────────────────────────────────

func test_rank_name_returns_chinese_string() -> void:
	assert_eq(ArenaRankSystem.score_to_rank_name(0),    "銅牌 III")
	assert_eq(ArenaRankSystem.score_to_rank_name(2000), "菁英")

func test_rank_name_matches_key_lookup() -> void:
	var key  := ArenaRankSystem.score_to_rank_key(1200)
	var name := ArenaRankSystem.score_to_rank_name(1200)
	assert_eq(name, ArenaRankSystem.RANK_NAMES[key])


# ── rank_key_to_index ─────────────────────────────────────────────

func test_bronze_3_index_is_0() -> void:
	assert_eq(ArenaRankSystem.rank_key_to_index("bronze_3"), 0)

func test_elite_index_is_last() -> void:
	var last := ArenaRankSystem.RANK_ORDER.size() - 1
	assert_eq(ArenaRankSystem.rank_key_to_index("elite"), last)

func test_higher_rank_has_higher_index() -> void:
	var bronze := ArenaRankSystem.rank_key_to_index("bronze_3")
	var gold   := ArenaRankSystem.rank_key_to_index("gold_1")
	var elite  := ArenaRankSystem.rank_key_to_index("elite")
	assert_lt(bronze, gold)
	assert_lt(gold, elite)

func test_unknown_key_returns_minus_1() -> void:
	assert_eq(ArenaRankSystem.rank_key_to_index("nonexistent"), -1)


# ── get_claimable_rewards ─────────────────────────────────────────

func test_score_0_with_empty_claimed_returns_bronze_3() -> void:
	var result := ArenaRankSystem.get_claimable_rewards(0, [])
	assert_eq(result, ["bronze_3"])

func test_score_200_with_empty_claimed_returns_first_3_ranks() -> void:
	var result := ArenaRankSystem.get_claimable_rewards(200, [])
	assert_true(result.has("bronze_3"))
	assert_true(result.has("bronze_2"))
	assert_true(result.has("bronze_1"))
	assert_false(result.has("silver_3"))

func test_already_claimed_ranks_excluded() -> void:
	var result := ArenaRankSystem.get_claimable_rewards(200, ["bronze_3", "bronze_2"])
	assert_false(result.has("bronze_3"))
	assert_false(result.has("bronze_2"))
	assert_true(result.has("bronze_1"))

func test_score_below_threshold_not_claimable() -> void:
	var result := ArenaRankSystem.get_claimable_rewards(99, [])
	assert_false(result.has("bronze_2"))

func test_all_claimed_returns_empty() -> void:
	var all_keys := ArenaRankSystem.RANK_ORDER.duplicate()
	var result := ArenaRankSystem.get_claimable_rewards(9999, all_keys)
	assert_eq(result.size(), 0)

func test_result_preserves_rank_order() -> void:
	var result := ArenaRankSystem.get_claimable_rewards(600, [])
	for i in range(result.size() - 1):
		var idx_a := ArenaRankSystem.rank_key_to_index(result[i])
		var idx_b := ArenaRankSystem.rank_key_to_index(result[i + 1])
		assert_lt(idx_a, idx_b, "rewards should be in ascending rank order")


# ── get_reward ────────────────────────────────────────────────────

func test_bronze_3_reward_has_diamonds() -> void:
	var reward := ArenaRankSystem.get_reward("bronze_3")
	assert_true(reward.has("diamonds"))
	assert_gt(reward["diamonds"], 0)

func test_elite_reward_is_largest_diamonds() -> void:
	var elite_diamonds  := ArenaRankSystem.get_reward("elite").get("diamonds", 0)
	var bronze_diamonds := ArenaRankSystem.get_reward("bronze_3").get("diamonds", 0)
	assert_gt(elite_diamonds, bronze_diamonds)

func test_unknown_rank_key_returns_empty_dict() -> void:
	assert_eq(ArenaRankSystem.get_reward("nonexistent"), {})
