class_name SpecialAbilitySystem
extends RefCounted


static func summarize(owned_ids: Array, config: Dictionary) -> Dictionary:
	var summary := {
		"idle_reward_multiplier": 1.0,
		"idle_max_hours_bonus": 0,
		"battle_speed_cap": 1.0,
		"battle_skip_unlocked": false,
		"scaled_scoop_by_level": false,
		"diamond_scoop_slot_unlocked": false,
		"battle_speed_charge_unlocked": false,
		"battle_speed_rate_upgrade_unlocked": false,
		"ad_free": false,
		"friend_capacity_unlocked": false,
		"lifetime_privilege": false,
		"monthly_privilege": false,
		"max_team_slots": 1,
	}

	var items: Array = config.get("items", [])
	for item: Dictionary in items:
		if not owned_ids.has(item.get("id", "")):
			continue
		var effect_type: String = item.get("effect_type", "")
		var value = item.get("value", 0)
		match effect_type:
			"idle_reward_multiplier":
				summary["idle_reward_multiplier"] += float(value)
			"idle_max_hours_bonus":
				summary["idle_max_hours_bonus"] += int(value)
			"unlock_battle_speed":
				summary["battle_speed_cap"] = maxf(summary["battle_speed_cap"], float(value))
			"unlock_battle_skip":
				summary["battle_skip_unlocked"] = bool(value)
			"scaled_scoop_by_level":
				summary["scaled_scoop_by_level"] = true
			"unlock_diamond_scoop_slot":
				summary["diamond_scoop_slot_unlocked"] = true
			"unlock_battle_speed_charge":
				summary["battle_speed_charge_unlocked"] = true
			"unlock_battle_speed_rate_upgrade":
				summary["battle_speed_rate_upgrade_unlocked"] = true
			"unlock_ad_free":
				summary["ad_free"] = true
			"unlock_friend_capacity_upgrade":
				summary["friend_capacity_unlocked"] = true
			"lifetime_privilege":
				summary["lifetime_privilege"] = true
			"monthly_privilege":
				summary["monthly_privilege"] = true
			"unlock_team_slot":
				summary["max_team_slots"] = maxi(summary["max_team_slots"], int(value))

	return summary
