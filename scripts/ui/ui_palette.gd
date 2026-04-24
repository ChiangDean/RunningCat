class_name UiPalette
extends RefCounted

const BUTTON_PRIMARY_BG := Color(0.80, 0.70, 0.43, 0.98)
const BUTTON_PRIMARY_FG := Color(0.22, 0.17, 0.10, 1.0)
const BUTTON_DISABLED_BG := Color(0.28, 0.26, 0.24, 0.84)
const BUTTON_DISABLED_BORDER := Color(0.41, 0.38, 0.35, 0.92)
const BUTTON_DISABLED_FG := Color(0.67, 0.64, 0.60, 0.92)
const BUTTON_SECONDARY_BG := Color(0.63, 0.46, 0.20, 0.96)
const BUTTON_SECONDARY_FG := Color(0.98, 0.95, 0.88, 1.0)
const BUTTON_RANK_BG := Color(0.30, 0.22, 0.10, 0.96)
const BUTTON_RANK_FG := Color(0.98, 0.95, 0.88, 1.0)
const BUTTON_INFO_BG := Color(0.22, 0.19, 0.17, 0.96)
const BUTTON_INFO_FG := Color(0.98, 0.95, 0.88, 1.0)
const BUTTON_DANGER_BG := Color(0.42, 0.18, 0.16, 0.96)
const BUTTON_DANGER_FG := Color(0.98, 0.95, 0.88, 1.0)
const BUTTON_MINUS_BG := Color(0.24, 0.21, 0.18, 0.92)
const BUTTON_MINUS_FG := Color(0.98, 0.95, 0.88, 1.0)
const BUTTON_PLUS_BG := Color(0.55, 0.41, 0.16, 0.98)
const BUTTON_PLUS_FG := Color(1.0, 0.97, 0.86, 1.0)

const RANK_BAR_BORDER := Color(0.86, 0.72, 0.38, 0.96)
const RANK_BAR_FILL := Color(0.79, 0.60, 0.20, 0.98)
const RANK_BAR_EMPTY := Color(0.22, 0.18, 0.13, 0.96)
const RANK_BAR_TEXT := Color(1.0, 0.97, 0.88, 1.0)
const EXP_BAR_BORDER := Color(0.53, 0.66, 0.53, 0.98)
const EXP_BAR_FILL := Color(0.43, 0.62, 0.44, 0.98)
const EXP_BAR_EMPTY := Color(0.17, 0.24, 0.18, 0.96)
const EXP_BAR_TEXT := Color(0.94, 0.99, 0.93, 1.0)
const EXP_BAR_READY_BORDER := Color(0.61, 0.77, 0.60, 1.0)
const EXP_BAR_READY_FILL := Color(0.52, 0.72, 0.50, 1.0)
const EXP_BAR_READY_EMPTY := Color(0.18, 0.27, 0.19, 0.96)
const EXP_BAR_READY_TEXT := Color(0.97, 1.0, 0.96, 1.0)
const EXP_BAR_MAX_BORDER := Color(0.72, 0.88, 0.70, 1.0)
const EXP_BAR_MAX_FILL := Color(0.57, 0.79, 0.55, 1.0)
const EXP_BAR_MAX_EMPTY := Color(0.20, 0.29, 0.21, 0.96)
const EXP_BAR_MAX_TEXT := Color(0.98, 1.0, 0.98, 1.0)


## Button type reference (semantic alias → colour name)
## Colour names:  confirm   cancel    neutral  info     destruct  remove   add
## Semantic alias: primary   secondary rank     info     danger    minus    plus
## ─── Font size constants ───────────────────────────────────────────────
## Change these values to adjust every text element at a given level game-wide.
##
## Level reference:
##   DISPLAY    → oversized display numbers (power value, large countdown)
##   HEADING    → scene main title, large header
##   TITLE      → secondary heading, dialog title
##   SUBHEADING → tab labels, sub-headings
##   BODY_LG    → primary button text, slightly larger body copy
##   BODY       → main body copy, standard buttons (most common)
##   LABEL      → labels, secondary descriptions
##   SMALL      → supplementary info, chip text
##   TINY       → badges, minimum-size info text
const FONT_SIZE_DISPLAY    := 34
const FONT_SIZE_HEADING    := 28
const FONT_SIZE_TITLE      := 24
const FONT_SIZE_SUBHEADING := 22
const FONT_SIZE_BODY_LG    := 20
const FONT_SIZE_BODY       := 18
const FONT_SIZE_LABEL      := 16
const FONT_SIZE_SMALL      := 14
const FONT_SIZE_TINY       := 12


static func get_button_palette(kind: String) -> Dictionary:
	match kind.to_lower():
		"secondary", "cancel":
			return {"bg": BUTTON_SECONDARY_BG, "fg": BUTTON_SECONDARY_FG}
		"rank", "neutral":
			return {"bg": BUTTON_RANK_BG, "fg": BUTTON_RANK_FG}
		"info":
			return {"bg": BUTTON_INFO_BG, "fg": BUTTON_INFO_FG}
		"danger", "destruct":
			return {"bg": BUTTON_DANGER_BG, "fg": BUTTON_DANGER_FG}
		"minus", "remove":
			return {"bg": BUTTON_MINUS_BG, "fg": BUTTON_MINUS_FG}
		"plus", "add":
			return {"bg": BUTTON_PLUS_BG, "fg": BUTTON_PLUS_FG}
		_: # primary / confirm
			return {"bg": BUTTON_PRIMARY_BG, "fg": BUTTON_PRIMARY_FG}


static func apply_button_kind(button: Button, kind: String) -> void:
	var palette: Dictionary = get_button_palette(kind)
	apply_button_palette(button, palette.get("bg", BUTTON_PRIMARY_BG), palette.get("fg", BUTTON_PRIMARY_FG))


static func apply_button_palette(button: Button, bg: Color, fg: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.border_color = bg.lightened(0.12)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = bg.lightened(0.08)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = bg.darkened(0.08)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = BUTTON_DISABLED_BG
	disabled.border_color = BUTTON_DISABLED_BORDER
	disabled.shadow_color = Color(0.0, 0.0, 0.0, 0.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", fg)
	button.add_theme_color_override("font_disabled_color", BUTTON_DISABLED_FG)


static func style_rank_progress_bar(bar: ProgressBar) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = RANK_BAR_EMPTY
	background.border_width_left = 2
	background.border_width_right = 2
	background.border_width_top = 2
	background.border_width_bottom = 2
	background.border_color = RANK_BAR_BORDER
	background.corner_radius_top_left = 10
	background.corner_radius_top_right = 10
	background.corner_radius_bottom_left = 10
	background.corner_radius_bottom_right = 10

	var fill: StyleBoxFlat = background.duplicate()
	fill.bg_color = RANK_BAR_FILL

	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)


static func style_exp_progress_bar(bar: ProgressBar, state: String = "normal") -> void:
	var background := StyleBoxFlat.new()
	var border_color := EXP_BAR_BORDER
	var fill_color := EXP_BAR_FILL
	var empty_color := EXP_BAR_EMPTY
	match state.to_lower():
		"max":
			border_color = EXP_BAR_MAX_BORDER
			fill_color = EXP_BAR_MAX_FILL
			empty_color = EXP_BAR_MAX_EMPTY
		"ready":
			border_color = EXP_BAR_READY_BORDER
			fill_color = EXP_BAR_READY_FILL
			empty_color = EXP_BAR_READY_EMPTY
	background.bg_color = empty_color
	background.border_width_left = 2
	background.border_width_right = 2
	background.border_width_top = 2
	background.border_width_bottom = 2
	background.border_color = border_color
	background.corner_radius_top_left = 10
	background.corner_radius_top_right = 10
	background.corner_radius_bottom_left = 10
	background.corner_radius_bottom_right = 10

	var fill: StyleBoxFlat = background.duplicate()
	fill.bg_color = fill_color

	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
