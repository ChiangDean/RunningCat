class_name BouncerCat
extends BaseCat

## 反彈貓：利用牆壁/敵人排列造成連鎖傷害

func on_wall_bounce() -> void:
	# 撞牆後不進入硬直，直接反彈回去繼續攻擊
	facing_direction *= -1


func _trigger_active_skill(skill: ActiveSkillData) -> void:
	match skill.effect_type:
		"chain_bounce":
			# 連鎖反彈：依序傷害多個敵人（戰鬥系統完成後實作）
			pass
