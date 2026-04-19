class_name UiFonts
extends RefCounted

const NOTO_SANS_TC_REGULAR: FontFile = preload("res://assets/fonts/NotoSansTC-Regular.ttf")

const FREDOKA_REGULAR: FontFile = preload("res://assets/fonts/Fredoka/Fredoka-Regular.ttf")
const FREDOKA_MEDIUM: FontFile = preload("res://assets/fonts/Fredoka/Fredoka-Medium.ttf")
const FREDOKA_SEMIBOLD: FontFile = preload("res://assets/fonts/Fredoka/Fredoka-SemiBold.ttf")
const FREDOKA_BOLD: FontFile = preload("res://assets/fonts/Fredoka/Fredoka-Bold.ttf")


static func apply_noto(control: Control, font_size: int = -1) -> void:
	_apply_font(control, NOTO_SANS_TC_REGULAR, font_size)


static func apply_fredoka_regular(control: Control, font_size: int = -1) -> void:
	_apply_font(control, _make_fredoka_font(FREDOKA_REGULAR), font_size)


static func apply_fredoka_medium(control: Control, font_size: int = -1) -> void:
	_apply_font(control, _make_fredoka_font(FREDOKA_MEDIUM), font_size)


static func apply_fredoka_semibold(control: Control, font_size: int = -1) -> void:
	_apply_font(control, _make_fredoka_font(FREDOKA_SEMIBOLD), font_size)


static func apply_fredoka_bold(control: Control, font_size: int = -1) -> void:
	_apply_font(control, _make_fredoka_font(FREDOKA_BOLD), font_size)


static func _apply_font(control: Control, font: Font, font_size: int) -> void:
	control.add_theme_font_override("font", font)
	if font_size > 0:
		control.add_theme_font_size_override("font_size", font_size)


static func _make_fredoka_font(base_font: FontFile) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = base_font
	font.fallbacks = [NOTO_SANS_TC_REGULAR]
	return font
