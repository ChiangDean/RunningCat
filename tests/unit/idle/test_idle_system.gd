extends GutTest

## 測試對象：IdleSystem（掛機產出計算、鏟屎掉落機率）


# ── calculate_rewards ─────────────────────────────────────────────

func test_zero_minutes_returns_all_zeros() -> void:
	var rates  := { "gold": 600, "poop": 5, "cat_food": 5, "diamonds": 10, "whiskers": 1 }
	var result := IdleSystem.calculate_rewards(0, rates)
	for key in result:
		assert_eq(result[key], 0, "%s should be 0 at 0 minutes" % key)

func test_negative_minutes_returns_all_zeros() -> void:
	var rates  := { "gold": 600 }
	var result := IdleSystem.calculate_rewards(-10, rates)
	assert_eq(result["gold"], 0)

func test_floor_semantics_poop_5_per_hour_at_11_minutes_is_0() -> void:
	# floor(5 × 11 / 60) = floor(0.916) = 0
	var result := IdleSystem.calculate_rewards(11, { "poop": 5 })
	assert_eq(result["poop"], 0)

func test_floor_semantics_poop_5_per_hour_at_12_minutes_is_1() -> void:
	# floor(5 × 12 / 60) = floor(1.0) = 1
	var result := IdleSystem.calculate_rewards(12, { "poop": 5 })
	assert_eq(result["poop"], 1)

func test_gold_60_per_hour_at_60_minutes_is_60() -> void:
	var result := IdleSystem.calculate_rewards(60, { "gold": 60 })
	assert_eq(result["gold"], 60)

func test_gold_1_per_hour_at_1_minute_is_0() -> void:
	# floor(1 × 1 / 60) = 0
	var result := IdleSystem.calculate_rewards(1, { "gold": 1 })
	assert_eq(result["gold"], 0)

func test_whiskers_rate_1_per_hour_at_59_minutes_is_0() -> void:
	# floor(1 × 59 / 60) = 0
	var result := IdleSystem.calculate_rewards(59, { "whiskers": 1 })
	assert_eq(result["whiskers"], 0)

func test_whiskers_rate_1_per_hour_at_60_minutes_is_1() -> void:
	var result := IdleSystem.calculate_rewards(60, { "whiskers": 1 })
	assert_eq(result["whiskers"], 1)

func test_missing_rate_key_defaults_to_0() -> void:
	var result := IdleSystem.calculate_rewards(60, {})
	for key in ["gold", "poop", "cat_food", "diamonds", "whiskers"]:
		assert_eq(result[key], 0, "%s should default to 0" % key)

func test_all_resources_calculated_independently() -> void:
	var rates := { "gold": 600, "poop": 60, "cat_food": 120, "diamonds": 6, "whiskers": 2 }
	var result := IdleSystem.calculate_rewards(60, rates)
	assert_eq(result["gold"],     600)
	assert_eq(result["poop"],     60)
	assert_eq(result["cat_food"], 120)
	assert_eq(result["diamonds"], 6)
	assert_eq(result["whiskers"], 2)


# ── calculate_rates ───────────────────────────────────────────────

func test_rates_at_stage_0_use_base_values() -> void:
	var cfg := {
		"base_gold_per_hour":            1000,
		"stage_bonus_interval":          50,
		"stage_gold_bonus_per_interval": 100,
		"scooper_gold_per_level_per_hour": 500,
		"base_poop_per_hour":            5,
		"stage_poop_bonus_per_interval": 2,
		"scooper_poop_per_level_per_hour": 5,
		"base_cat_food_per_hour":        5,
		"stage_cat_food_bonus_per_interval": 2,
		"scooper_cat_food_per_level_per_hour": 5,
		"base_diamonds_per_hour":        10,
		"stage_diamonds_bonus_per_interval": 2,
		"scooper_diamonds_per_level_per_hour": 10,
		"base_whiskers_per_hour":        1,
		"whisker_stage_bonus_interval":  150,
		"whisker_stage_bonus_per_interval": 1,
	}
	var rates := IdleSystem.calculate_rates(cfg, 0, 0)
	assert_eq(rates["gold"],     1000)
	assert_eq(rates["poop"],     5)
	assert_eq(rates["whiskers"], 1)

func test_rates_stage_50_triggers_one_stage_bonus() -> void:
	var cfg := {
		"base_gold_per_hour":            1000,
		"stage_bonus_interval":          50,
		"stage_gold_bonus_per_interval": 100,
		"scooper_gold_per_level_per_hour": 0,
		"base_poop_per_hour":            0,
		"stage_poop_bonus_per_interval": 0,
		"scooper_poop_per_level_per_hour": 0,
		"base_cat_food_per_hour":        0,
		"stage_cat_food_bonus_per_interval": 0,
		"scooper_cat_food_per_level_per_hour": 0,
		"base_diamonds_per_hour":        0,
		"stage_diamonds_bonus_per_interval": 0,
		"scooper_diamonds_per_level_per_hour": 0,
		"base_whiskers_per_hour":        0,
		"whisker_stage_bonus_interval":  150,
		"whisker_stage_bonus_per_interval": 1,
	}
	var rates := IdleSystem.calculate_rates(cfg, 50, 0)
	# floor(50/50) = 1 tier → gold = 1000 + 1×100 = 1100
	assert_eq(rates["gold"], 1100)

func test_rates_scooper_level_adds_bonus() -> void:
	var cfg := {
		"base_gold_per_hour":            0,
		"stage_bonus_interval":          50,
		"stage_gold_bonus_per_interval": 0,
		"scooper_gold_per_level_per_hour": 1000,
		"base_poop_per_hour":            0,
		"stage_poop_bonus_per_interval": 0,
		"scooper_poop_per_level_per_hour": 0,
		"base_cat_food_per_hour":        0,
		"stage_cat_food_bonus_per_interval": 0,
		"scooper_cat_food_per_level_per_hour": 0,
		"base_diamonds_per_hour":        0,
		"stage_diamonds_bonus_per_interval": 0,
		"scooper_diamonds_per_level_per_hour": 0,
		"base_whiskers_per_hour":        0,
		"whisker_stage_bonus_interval":  150,
		"whisker_stage_bonus_per_interval": 0,
	}
	var rates := IdleSystem.calculate_rates(cfg, 0, 3)
	assert_eq(rates["gold"], 3000)


# ── scoop_once ────────────────────────────────────────────────────

func test_scoop_once_always_gives_exp_when_chance_is_1() -> void:
	var cfg := { "scoop_exp_chance": 1.0, "scoop_exp_amount": 1,
				 "scoop_memory_shard_base_chance": 0.0,
				 "scoop_memory_shard_chance_per_two_scooper_levels": 0.0,
				 "scoop_whisker_base_chance": 0.0,
				 "scoop_whisker_chance_per_scooper_level": 0.0 }
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var result := IdleSystem.scoop_once(cfg, rng, 0)
	assert_eq(result["exp"], 1)

func test_scoop_once_never_gives_exp_when_chance_is_0() -> void:
	var cfg := { "scoop_exp_chance": 0.0, "scoop_exp_amount": 1,
				 "scoop_memory_shard_base_chance": 0.0,
				 "scoop_memory_shard_chance_per_two_scooper_levels": 0.0,
				 "scoop_whisker_base_chance": 0.0,
				 "scoop_whisker_chance_per_scooper_level": 0.0 }
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var result := IdleSystem.scoop_once(cfg, rng, 0)
	assert_eq(result["exp"], 0)

func test_scoop_once_result_has_required_keys() -> void:
	var cfg := { "scoop_exp_chance": 1.0, "scoop_exp_amount": 1,
				 "scoop_memory_shard_base_chance": 0.0,
				 "scoop_memory_shard_chance_per_two_scooper_levels": 0.0,
				 "scoop_whisker_base_chance": 0.0,
				 "scoop_whisker_chance_per_scooper_level": 0.0 }
	var rng := RandomNumberGenerator.new()
	var result := IdleSystem.scoop_once(cfg, rng, 0)
	assert_true(result.has("exp"))
	assert_true(result.has("memory_shards"))
	assert_true(result.has("whiskers"))
