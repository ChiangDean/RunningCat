class_name DefensiveCat
extends BaseCat

## 防守貓：高 DEF & 中 Weight，碰撞時反彈傷害給攻擊者

const REFLECT_RATIO: float = 0.3  # 反彈 30% 傷害


func on_collision_with(other: BaseCat) -> void:
	if is_staggered or not is_alive:
		return
	# 先承受傷害
	take_damage(other.data.atk)
	# 反彈傷害給對方
	var reflect_dmg: float = data.defense * REFLECT_RATIO
	other.take_damage(reflect_dmg)
	# 回彈
	var knockback: float = CatStats.calc_knockback_distance(other.data.weight, data.weight)
	_apply_knockback(knockback)
