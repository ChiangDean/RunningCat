class_name CatNode
extends Node2D

## 貓咪視覺節點：彩色方塊 + 血量條 + 名稱標籤

signal died(node: CatNode)

# 節點身份
var instance_id: int = -1
var team: String = ""
var cat_display_name: String = ""
var max_hp: int = 100
var current_hp: int = 100

# 子節點
var _body_rect: ColorRect
var _hp_bar_bg: ColorRect
var _hp_bar_fill: ColorRect
var _name_label: Label

# 尺寸
const BODY_W := 56.0
const BODY_H := 72.0
const HP_BAR_W := 64.0
const HP_BAR_H := 8.0

func setup(id: int, team_name: String, name_str: String, hp: int) -> void:
	instance_id = id
	team = team_name
	cat_display_name = name_str
	max_hp = hp
	current_hp = hp
	_build_visuals()

func _build_visuals() -> void:
	# 身體方塊
	_body_rect = ColorRect.new()
	_body_rect.size = Vector2(BODY_W, BODY_H)
	_body_rect.position = Vector2(-BODY_W / 2.0, -BODY_H)
	_body_rect.color = Color(0.2, 0.5, 0.9, 1.0) if team == "player" else Color(0.9, 0.3, 0.2, 1.0)
	add_child(_body_rect)

	# 血量條背景
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_bg.position = Vector2(-HP_BAR_W / 2.0, -BODY_H - 14.0)
	_hp_bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	add_child(_hp_bar_bg)

	# 血量條填充
	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_fill.position = _hp_bar_bg.position
	_hp_bar_fill.color = Color(0.2, 0.9, 0.3, 1.0)
	add_child(_hp_bar_fill)

	# 名稱標籤
	_name_label = Label.new()
	_name_label.text = cat_display_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(-HP_BAR_W / 2.0, -BODY_H - 32.0)
	_name_label.size = Vector2(HP_BAR_W, 20.0)
	_name_label.add_theme_font_size_override("font_size", 12)
	add_child(_name_label)

func update_hp(hp: int) -> void:
	current_hp = maxi(0, hp)
	var ratio := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	_hp_bar_fill.size.x = HP_BAR_W * ratio
	# 顏色從綠到紅
	_hp_bar_fill.color = Color(1.0 - ratio, ratio * 0.9, 0.1, 1.0)

func apply_knockback(direction: float) -> void:
	# 簡單位移 tween
	var target_x := position.x + direction
	var tween := create_tween()
	tween.tween_property(self, "position:x", target_x, 0.15).set_ease(Tween.EASE_OUT)

func play_death() -> void:
	# 往反方向拋物線飛出
	var dir := -1.0 if team == "player" else 1.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", position.x + dir * 400.0, 0.8)
	tween.tween_property(self, "position:y", position.y - 200.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "position:y", position.y + 600.0, 0.4).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		died.emit(self)
		queue_free()
	)

func flash_skill() -> void:
	# 技能發動：閃爍效果
	var tween := create_tween()
	tween.tween_property(_body_rect, "color:a", 0.3, 0.1)
	tween.tween_property(_body_rect, "color:a", 1.0, 0.1)
	tween.tween_property(_body_rect, "color:a", 0.3, 0.1)
	tween.tween_property(_body_rect, "color:a", 1.0, 0.1)
