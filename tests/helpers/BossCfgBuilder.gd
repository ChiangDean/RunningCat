class_name BossCfgBuilder
extends RefCounted

## Builder：組裝 boss_cfg Dictionary，讓測試不需要重複寫 key。
## 預設值對應 GameStateBossStage 的私有 _enc / _bsz / _zpt 預設。

var _cfg: Dictionary = {
	"encounters_per_boss_stage": 4,
	"boss_stages_per_zone":      10,
	"zones_per_territory":       5,
	"stage_growth":              1.003,
	"boss_growth":               1.02,
}


static func standard() -> BossCfgBuilder:
	return BossCfgBuilder.new()


func with_encounters(n: int) -> BossCfgBuilder:
	_cfg["encounters_per_boss_stage"] = n
	return self


func with_boss_stages_per_zone(n: int) -> BossCfgBuilder:
	_cfg["boss_stages_per_zone"] = n
	return self


func with_zones_per_territory(n: int) -> BossCfgBuilder:
	_cfg["zones_per_territory"] = n
	return self


func with_stage_growth(r: float) -> BossCfgBuilder:
	_cfg["stage_growth"] = r
	return self


func with_boss_growth(r: float) -> BossCfgBuilder:
	_cfg["boss_growth"] = r
	return self


func build() -> Dictionary:
	return _cfg.duplicate()
