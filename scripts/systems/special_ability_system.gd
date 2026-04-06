class_name SpecialAbilitySystem
extends RefCounted


static func summarize(owned_ids: Array, config: Dictionary) -> Dictionary:
	var summary := {
		"idle_reward_multiplier": 1.0,
		"idle_max_hours_bonus": 0,
		"battle_speed_cap": 1.0,
		"battle_skip_unlocked": false,
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

	return summary
