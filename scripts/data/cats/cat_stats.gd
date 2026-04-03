class_name CatStats
extends RefCounted

## 純計算層，所有數值公式集中在這裡
## 不依賴任何場景節點，方便快速戰鬥模擬使用

# 回彈距離上下限
const MIN_KNOCKBACK: float = 30.0
const MAX_KNOCKBACK: float = 300.0

# 硬直時間常數
const STAGGER_TIME: float = 0.2
const WALL_STAGGER_TIME: float = 0.3


## DEF 減傷公式：DEF / (DEF + 100)
## DEF=0 → 0%，DEF=100 → 50%，DEF=300 → 75%，永遠不會達到 100%
static func calc_def_reduction(defense: float) -> float:
	if defense <= 0.0:
		return 0.0
	return defense / (defense + 100.0)


## 計算實際傷害
## ignore_def：無視防禦數值（未來屬性），直接削弱對方有效 DEF
static func calc_damage(atk: float, defense: float, ignore_def: float = 0.0) -> float:
	var effective_def: float = maxf(0.0, defense - ignore_def)
	var reduction: float = calc_def_reduction(effective_def)
	return maxf(1.0, atk * (1.0 - reduction))


## 計算回彈距離
## 攻擊方較重 → 被攻擊方回彈較遠，有最小/最大限制
static func calc_knockback_distance(attacker_weight: float, target_weight: float) -> float:
	var weight_diff: float = attacker_weight - target_weight
	var base_knockback: float = 100.0 + weight_diff * 0.5
	return clampf(base_knockback, MIN_KNOCKBACK, MAX_KNOCKBACK)
