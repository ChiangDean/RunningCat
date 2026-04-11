extends Button

var channel_key: String = ""
var _badge_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(0, 46)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_badge_label = Label.new()
	_badge_label.anchor_left = 1.0
	_badge_label.anchor_top = 0.0
	_badge_label.anchor_right = 1.0
	_badge_label.anchor_bottom = 0.0
	_badge_label.position = Vector2(-26, 4)
	_badge_label.size = Vector2(24, 20)
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge_label.add_theme_font_size_override("font_size", 12)
	add_child(_badge_label)
	set_badge_count(0)


func configure(key: String, title: String) -> void:
	channel_key = key
	text = title


func set_badge_count(count: int) -> void:
	_badge_label.visible = count > 0
	_badge_label.text = str(mini(count, 99))
