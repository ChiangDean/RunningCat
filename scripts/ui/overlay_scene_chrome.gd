class_name OverlaySceneChrome
extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")

const BOTTOM_DOCK_H := 112.0
const HOME_MAIN_NAV_H := 110.0
const CONTENT_TOP_GAP := 150.0
const TOP_MASK_HEIGHT := 186.0

const PANEL_FILL := Color(0.08, 0.07, 0.08, 0.94)
const PANEL_BORDER := Color(0.80, 0.67, 0.42, 0.95)
const CARD_FILL := Color(0.16, 0.15, 0.18, 0.96)
const CARD_BORDER := Color(0.50, 0.43, 0.30, 0.92)
const MUTED_TEXT_COLOR := Color(0.90, 0.88, 0.82, 0.92)
const TITLE_TEXT_COLOR := Color(0.99, 0.97, 0.90, 1.0)


static func build(scene: Control, background_slot: String, back_pressed: Callable, options: Dictionary = {}) -> Dictionary:
	var background: Control = AssetResolver.make_fullscreen_background(background_slot)
	scene.add_child(background)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.05, 0.34)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.add_child(dim)

	var top_mask: ColorRect = ColorRect.new()
	top_mask.anchor_left = 0.0
	top_mask.anchor_top = 0.0
	top_mask.anchor_right = 1.0
	top_mask.anchor_bottom = 0.0
	top_mask.offset_left = 0.0
	top_mask.offset_top = 0.0
	top_mask.offset_right = 0.0
	top_mask.offset_bottom = float(options.get("top_mask_height", TOP_MASK_HEIGHT))
	top_mask.color = Color(0.03, 0.03, 0.04, 0.58)
	scene.add_child(top_mask)

	var panel_fill: Color = options.get("panel_fill", PANEL_FILL)
	var panel_border: Color = options.get("panel_border", PANEL_BORDER)
	var back_label: String = str(options.get("back_label", UiText.COMMON_BACK))
	var button_pressed: Callable = options.get("button_pressed", Callable())

	var submenu: Dictionary = SceneSubmenuBar.build(scene, {
		"items": options.get("dock_items", []),
		"active_key": str(options.get("active_key", "")),
		"back_label": back_label,
		"back_pressed": back_pressed,
		"button_pressed": button_pressed,
		"panel_fill": panel_fill,
		"panel_border": panel_border,
		"button_height": float(options.get("button_height", 52.0)),
		"font_size": int(options.get("font_size", UiPalette.FONT_SIZE_BODY_LG)),
		"top": float(options.get("dock_top", -(HOME_MAIN_NAV_H + BOTTOM_DOCK_H))),
		"bottom": float(options.get("dock_bottom", -HOME_MAIN_NAV_H)),
	})

	var dock_panel: PanelContainer = submenu.get("dock_panel")
	if dock_panel != null and not bool(options.get("show_dock", false)):
		dock_panel.visible = false
		dock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var content_panel: PanelContainer = PanelContainer.new()
	content_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_panel.offset_left = float(options.get("content_left", 20.0))
	content_panel.offset_top = float(options.get("content_top", CONTENT_TOP_GAP))
	content_panel.offset_right = float(options.get("content_right", -20.0))
	content_panel.offset_bottom = float(options.get("content_bottom", -(HOME_MAIN_NAV_H + BOTTOM_DOCK_H + 12.0)))
	content_panel.add_theme_stylebox_override(
		"panel",
		make_panel_style(
			panel_fill,
			panel_border,
			int(options.get("panel_radius", 18))
		)
	)
	scene.add_child(content_panel)

	var content_margin: MarginContainer = make_content_margin(int(options.get("content_margin", 18)))
	content_panel.add_child(content_margin)

	var content_box: VBoxContainer = VBoxContainer.new()
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", int(options.get("content_separation", 14)))
	content_margin.add_child(content_box)

	return {
		"background": background,
		"dim": dim,
		"top_mask": top_mask,
		"back_panel": submenu.get("back_panel"),
		"back_button": submenu.get("back_button"),
		"dock_panel": dock_panel,
		"dock_buttons": submenu.get("buttons", {}),
		"content_panel": content_panel,
		"content_box": content_box,
	}


static func make_content_margin(value: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_bottom", value)
	return margin


static func make_panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


static func make_card_panel(accent: Color = CARD_BORDER, fill: Color = CARD_FILL, radius: int = 14) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", make_panel_style(fill, accent, radius))
	return panel
