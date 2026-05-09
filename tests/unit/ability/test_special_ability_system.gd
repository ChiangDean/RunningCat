extends GutTest

## 測試對象：SpecialAbilitySystem（特殊能力摘要計算）


# ── Helper ────────────────────────────────────────────────────────

func _make_config(items: Array) -> Dictionary:
	return {"items": items}


func _make_item(id: String, effect_type: String, value: Variant) -> Dictionary:
	return {"id": id, "effect_type": effect_type, "value": value}


# ── 基本結構 ──────────────────────────────────────────────────────

func test_empty_owned_returns_defaults() -> void:
	var config := _make_config([
		_make_item("1", "idle_reward_multiplier", 0.05),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_almost_eq(result["idle_reward_multiplier"], 1.0, 0.0001)
	assert_eq(result["idle_max_hours_bonus"], 0)
	assert_almost_eq(result["battle_speed_cap"], 1.0, 0.0001)
	assert_false(result["battle_skip_unlocked"])
	assert_false(result["scaled_scoop_by_level"])
	assert_false(result["diamond_scoop_slot_unlocked"])
	assert_false(result["battle_speed_charge_unlocked"])
	assert_false(result["battle_speed_rate_upgrade_unlocked"])
	assert_false(result["ad_free"])
	assert_false(result["friend_capacity_unlocked"])
	assert_false(result["lifetime_privilege"])
	assert_false(result["monthly_privilege"])
	assert_eq(result["max_team_slots"], 1)


func test_empty_config_returns_defaults() -> void:
	var result := SpecialAbilitySystem.summarize(["1", "2"], _make_config([]))
	assert_almost_eq(result["idle_reward_multiplier"], 1.0, 0.0001)
	assert_eq(result["max_team_slots"], 1)


# ── idle_reward_multiplier ────────────────────────────────────────

func test_idle_reward_multiplier_adds_value() -> void:
	var config := _make_config([
		_make_item("12", "idle_reward_multiplier", 0.05),
	])
	var result := SpecialAbilitySystem.summarize(["12"], config)
	assert_almost_eq(result["idle_reward_multiplier"], 1.05, 0.0001)


func test_idle_reward_multiplier_stacks() -> void:
	var config := _make_config([
		_make_item("12", "idle_reward_multiplier", 0.05),
		_make_item("99", "idle_reward_multiplier", 0.10),
	])
	var result := SpecialAbilitySystem.summarize(["12", "99"], config)
	assert_almost_eq(result["idle_reward_multiplier"], 1.15, 0.0001)


func test_idle_reward_multiplier_not_owned_ignored() -> void:
	var config := _make_config([
		_make_item("12", "idle_reward_multiplier", 0.05),
	])
	var result := SpecialAbilitySystem.summarize(["99"], config)
	assert_almost_eq(result["idle_reward_multiplier"], 1.0, 0.0001)


# ── idle_max_hours_bonus ──────────────────────────────────────────

func test_idle_max_hours_bonus_adds_value() -> void:
	var config := _make_config([
		_make_item("11", "idle_max_hours_bonus", 1),
	])
	var result := SpecialAbilitySystem.summarize(["11"], config)
	assert_eq(result["idle_max_hours_bonus"], 1)


func test_idle_max_hours_bonus_stacks() -> void:
	var config := _make_config([
		_make_item("11", "idle_max_hours_bonus", 1),
		_make_item("98", "idle_max_hours_bonus", 2),
	])
	var result := SpecialAbilitySystem.summarize(["11", "98"], config)
	assert_eq(result["idle_max_hours_bonus"], 3)


# ── unlock_battle_speed ───────────────────────────────────────────

func test_unlock_battle_speed_sets_cap() -> void:
	var config := _make_config([
		_make_item("3", "unlock_battle_speed", 2.0),
	])
	var result := SpecialAbilitySystem.summarize(["3"], config)
	assert_almost_eq(result["battle_speed_cap"], 2.0, 0.0001)


func test_unlock_battle_speed_takes_max() -> void:
	var config := _make_config([
		_make_item("3", "unlock_battle_speed", 2.0),
		_make_item("4", "unlock_battle_speed", 3.0),
	])
	var result := SpecialAbilitySystem.summarize(["3", "4"], config)
	assert_almost_eq(result["battle_speed_cap"], 3.0, 0.0001)


func test_unlock_battle_speed_partial_ownership() -> void:
	var config := _make_config([
		_make_item("3", "unlock_battle_speed", 2.0),
		_make_item("4", "unlock_battle_speed", 3.0),
	])
	var result := SpecialAbilitySystem.summarize(["3"], config)
	assert_almost_eq(result["battle_speed_cap"], 2.0, 0.0001)


# ── unlock_battle_skip ────────────────────────────────────────────

func test_unlock_battle_skip_true() -> void:
	var config := _make_config([
		_make_item("6", "unlock_battle_skip", 1),
	])
	var result := SpecialAbilitySystem.summarize(["6"], config)
	assert_true(result["battle_skip_unlocked"])


func test_unlock_battle_skip_not_owned_false() -> void:
	var config := _make_config([
		_make_item("6", "unlock_battle_skip", 1),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["battle_skip_unlocked"])


# ── scaled_scoop_by_level ────────────────────────────────────────

func test_scaled_scoop_by_level_owned() -> void:
	var config := _make_config([
		_make_item("7", "scaled_scoop_by_level", 1),
	])
	var result := SpecialAbilitySystem.summarize(["7"], config)
	assert_true(result["scaled_scoop_by_level"])


func test_scaled_scoop_by_level_not_owned() -> void:
	var config := _make_config([
		_make_item("7", "scaled_scoop_by_level", 1),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["scaled_scoop_by_level"])


# ── unlock_diamond_scoop_slot ────────────────────────────────────

func test_diamond_scoop_slot_owned() -> void:
	var config := _make_config([
		_make_item("8", "unlock_diamond_scoop_slot", 1),
	])
	var result := SpecialAbilitySystem.summarize(["8"], config)
	assert_true(result["diamond_scoop_slot_unlocked"])


func test_diamond_scoop_slot_not_owned() -> void:
	var config := _make_config([
		_make_item("8", "unlock_diamond_scoop_slot", 1),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["diamond_scoop_slot_unlocked"])


# ── unlock_battle_speed_charge ───────────────────────────────────

func test_battle_speed_charge_owned() -> void:
	var config := _make_config([
		_make_item("9", "unlock_battle_speed_charge", 1),
	])
	var result := SpecialAbilitySystem.summarize(["9"], config)
	assert_true(result["battle_speed_charge_unlocked"])


func test_battle_speed_charge_not_owned() -> void:
	var config := _make_config([
		_make_item("9", "unlock_battle_speed_charge", 1),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["battle_speed_charge_unlocked"])


# ── unlock_battle_speed_rate_upgrade ─────────────────────────────

func test_battle_speed_rate_upgrade_owned() -> void:
	var config := _make_config([
		_make_item("10", "unlock_battle_speed_rate_upgrade", 0.05),
	])
	var result := SpecialAbilitySystem.summarize(["10"], config)
	assert_true(result["battle_speed_rate_upgrade_unlocked"])


func test_battle_speed_rate_upgrade_not_owned() -> void:
	var config := _make_config([
		_make_item("10", "unlock_battle_speed_rate_upgrade", 0.05),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["battle_speed_rate_upgrade_unlocked"])


# ── unlock_ad_free ────────────────────────────────────────────────

func test_ad_free_owned() -> void:
	var config := _make_config([
		_make_item("13", "unlock_ad_free", 1),
	])
	var result := SpecialAbilitySystem.summarize(["13"], config)
	assert_true(result["ad_free"])


func test_ad_free_not_owned() -> void:
	var config := _make_config([
		_make_item("13", "unlock_ad_free", 1),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["ad_free"])


# ── unlock_friend_capacity_upgrade ───────────────────────────────

func test_friend_capacity_owned() -> void:
	var config := _make_config([
		_make_item("14", "unlock_friend_capacity_upgrade", 1),
	])
	var result := SpecialAbilitySystem.summarize(["14"], config)
	assert_true(result["friend_capacity_unlocked"])


func test_friend_capacity_not_owned() -> void:
	var config := _make_config([
		_make_item("14", "unlock_friend_capacity_upgrade", 1),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["friend_capacity_unlocked"])


# ── lifetime_privilege ────────────────────────────────────────────

func test_lifetime_privilege_owned() -> void:
	var config := _make_config([
		_make_item("15", "lifetime_privilege", 1),
	])
	var result := SpecialAbilitySystem.summarize(["15"], config)
	assert_true(result["lifetime_privilege"])


func test_lifetime_privilege_not_owned() -> void:
	var config := _make_config([
		_make_item("15", "lifetime_privilege", 1),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["lifetime_privilege"])


# ── monthly_privilege ─────────────────────────────────────────────

func test_monthly_privilege_owned() -> void:
	var config := _make_config([
		_make_item("16", "monthly_privilege", 1),
	])
	var result := SpecialAbilitySystem.summarize(["16"], config)
	assert_true(result["monthly_privilege"])


func test_monthly_privilege_not_owned() -> void:
	var config := _make_config([
		_make_item("16", "monthly_privilege", 1),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_false(result["monthly_privilege"])


# ── unlock_team_slot ──────────────────────────────────────────────

func test_team_slot_single_unlock() -> void:
	var config := _make_config([
		_make_item("17", "unlock_team_slot", 2),
	])
	var result := SpecialAbilitySystem.summarize(["17"], config)
	assert_eq(result["max_team_slots"], 2)


func test_team_slot_multiple_unlocks_takes_max() -> void:
	var config := _make_config([
		_make_item("17", "unlock_team_slot", 2),
		_make_item("18", "unlock_team_slot", 3),
		_make_item("19", "unlock_team_slot", 4),
	])
	var result := SpecialAbilitySystem.summarize(["17", "18", "19"], config)
	assert_eq(result["max_team_slots"], 4)


func test_team_slot_partial_ownership() -> void:
	var config := _make_config([
		_make_item("17", "unlock_team_slot", 2),
		_make_item("18", "unlock_team_slot", 3),
		_make_item("19", "unlock_team_slot", 4),
		_make_item("20", "unlock_team_slot", 5),
	])
	var result := SpecialAbilitySystem.summarize(["17", "18"], config)
	assert_eq(result["max_team_slots"], 3)


func test_team_slot_none_owned_stays_1() -> void:
	var config := _make_config([
		_make_item("17", "unlock_team_slot", 2),
	])
	var result := SpecialAbilitySystem.summarize([], config)
	assert_eq(result["max_team_slots"], 1)


func test_team_slot_all_five_unlocked() -> void:
	var config := _make_config([
		_make_item("17", "unlock_team_slot", 2),
		_make_item("18", "unlock_team_slot", 3),
		_make_item("19", "unlock_team_slot", 4),
		_make_item("20", "unlock_team_slot", 5),
	])
	var result := SpecialAbilitySystem.summarize(["17", "18", "19", "20"], config)
	assert_eq(result["max_team_slots"], 5)


# ── 綜合測試 ──────────────────────────────────────────────────────

func test_full_config_all_owned() -> void:
	var config := _make_config([
		_make_item("6",  "unlock_battle_skip", 1),
		_make_item("7",  "scaled_scoop_by_level", 1),
		_make_item("8",  "unlock_diamond_scoop_slot", 1),
		_make_item("9",  "unlock_battle_speed_charge", 1),
		_make_item("10", "unlock_battle_speed_rate_upgrade", 0.05),
		_make_item("11", "idle_max_hours_bonus", 1),
		_make_item("12", "idle_reward_multiplier", 0.05),
		_make_item("13", "unlock_ad_free", 1),
		_make_item("14", "unlock_friend_capacity_upgrade", 1),
		_make_item("15", "lifetime_privilege", 1),
		_make_item("16", "monthly_privilege", 1),
		_make_item("17", "unlock_team_slot", 2),
		_make_item("18", "unlock_team_slot", 3),
		_make_item("19", "unlock_team_slot", 4),
		_make_item("20", "unlock_team_slot", 5),
	])
	var owned: Array = ["6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"]
	var result := SpecialAbilitySystem.summarize(owned, config)

	assert_true(result["battle_skip_unlocked"])
	assert_true(result["scaled_scoop_by_level"])
	assert_true(result["diamond_scoop_slot_unlocked"])
	assert_true(result["battle_speed_charge_unlocked"])
	assert_true(result["battle_speed_rate_upgrade_unlocked"])
	assert_eq(result["idle_max_hours_bonus"], 1)
	assert_almost_eq(result["idle_reward_multiplier"], 1.05, 0.0001)
	assert_true(result["ad_free"])
	assert_true(result["friend_capacity_unlocked"])
	assert_true(result["lifetime_privilege"])
	assert_true(result["monthly_privilege"])
	assert_eq(result["max_team_slots"], 5)


func test_full_config_none_owned() -> void:
	var config := _make_config([
		_make_item("6",  "unlock_battle_skip", 1),
		_make_item("7",  "scaled_scoop_by_level", 1),
		_make_item("8",  "unlock_diamond_scoop_slot", 1),
		_make_item("9",  "unlock_battle_speed_charge", 1),
		_make_item("10", "unlock_battle_speed_rate_upgrade", 0.05),
		_make_item("11", "idle_max_hours_bonus", 1),
		_make_item("12", "idle_reward_multiplier", 0.05),
		_make_item("13", "unlock_ad_free", 1),
		_make_item("14", "unlock_friend_capacity_upgrade", 1),
		_make_item("15", "lifetime_privilege", 1),
		_make_item("16", "monthly_privilege", 1),
		_make_item("17", "unlock_team_slot", 2),
	])
	var result := SpecialAbilitySystem.summarize([], config)

	assert_false(result["battle_skip_unlocked"])
	assert_false(result["scaled_scoop_by_level"])
	assert_false(result["diamond_scoop_slot_unlocked"])
	assert_false(result["battle_speed_charge_unlocked"])
	assert_false(result["battle_speed_rate_upgrade_unlocked"])
	assert_eq(result["idle_max_hours_bonus"], 0)
	assert_almost_eq(result["idle_reward_multiplier"], 1.0, 0.0001)
	assert_false(result["ad_free"])
	assert_false(result["friend_capacity_unlocked"])
	assert_false(result["lifetime_privilege"])
	assert_false(result["monthly_privilege"])
	assert_eq(result["max_team_slots"], 1)


func test_unknown_effect_type_ignored() -> void:
	var config := _make_config([
		_make_item("99", "some_unknown_effect", 42),
	])
	var result := SpecialAbilitySystem.summarize(["99"], config)
	assert_almost_eq(result["idle_reward_multiplier"], 1.0, 0.0001)
	assert_eq(result["max_team_slots"], 1)


func test_owned_id_not_in_config_ignored() -> void:
	var config := _make_config([
		_make_item("6", "unlock_battle_skip", 1),
	])
	var result := SpecialAbilitySystem.summarize(["6", "999"], config)
	assert_true(result["battle_skip_unlocked"])
	assert_eq(result["max_team_slots"], 1)


func test_mixed_partial_ownership() -> void:
	var config := _make_config([
		_make_item("6",  "unlock_battle_skip", 1),
		_make_item("11", "idle_max_hours_bonus", 1),
		_make_item("13", "unlock_ad_free", 1),
		_make_item("17", "unlock_team_slot", 2),
		_make_item("18", "unlock_team_slot", 3),
	])
	# 只擁有 6, 11, 17
	var result := SpecialAbilitySystem.summarize(["6", "11", "17"], config)
	assert_true(result["battle_skip_unlocked"])
	assert_eq(result["idle_max_hours_bonus"], 1)
	assert_false(result["ad_free"])
	assert_eq(result["max_team_slots"], 2)
