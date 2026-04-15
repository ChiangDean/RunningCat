class_name SceneSubmenuBar
extends RefCounted

const SceneMenuTheme = preload("res://scripts/ui/scene_menu_theme.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")

static func build(host: Control, options: Dictionary) -> Dictionary:
	var button_map: Dictionary = {}
	var panel_fill: Color = options.get("panel_fill", SceneMenuTheme.PANEL_FILL)
	var panel_border: Color = options.get("panel_border", SceneMenuTheme.PANEL_BORDER)
	var button_height: float = float(options.get("button_height", SceneMenuTheme.SUBMENU_BUTTON_HEIGHT))
	var font_size: int = int(options.get("font_size", SceneMenuTheme.SUBMENU_FONT_SIZE))
	var left: float = float(options.get("left", 20.0))
	var right: float = float(options.get("right", -20.0))
	var back_right: float = float(options.get("back_right", 128.0))
	var panel_gap: float = float(options.get("panel_gap", 12.0))
	var back_label: String = str(options.get("back_label", UiText.SCOOPER_BACK))
	var active_key: String = str(options.get("active_key", ""))
	var button_pressed: Callable = options.get("button_pressed", Callable())
	var back_pressed: Callable = options.get("back_pressed", Callable())
	var items: Array = options.get("items", [])

	var back_panel := PanelContainer.new()
	back_panel.anchor_left = float(options.get("back_anchor_left", 0.0))
	back_panel.anchor_top = float(options.get("back_anchor_top", 1.0))
	back_panel.anchor_right = float(options.get("back_anchor_right", 0.0))
	back_panel.anchor_bottom = float(options.get("back_anchor_bottom", 1.0))
	back_panel.offset_left = left
	back_panel.offset_top = float(options.get("top", -222.0))
	back_panel.offset_right = back_right
	back_panel.offset_bottom = float(options.get("bottom", -110.0))
	back_panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(panel_fill, panel_border, 16))
	host.add_child(back_panel)

	var back_margin := _make_content_margin(int(options.get("margin", 12)))
	back_panel.add_child(back_margin)

	var back_btn := Button.new()
	back_btn.text = back_label
	back_btn.custom_minimum_size = Vector2(float(options.get("back_button_width", 84.0)), button_height)
	back_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_btn.add_theme_font_size_override("font_size", font_size)
	if not back_pressed.is_null():
		back_btn.pressed.connect(back_pressed)
	back_margin.add_child(back_btn)

	var dock_panel := PanelContainer.new()
	dock_panel.anchor_left = float(options.get("dock_anchor_left", 0.0))
	dock_panel.anchor_top = float(options.get("dock_anchor_top", 1.0))
	dock_panel.anchor_right = float(options.get("dock_anchor_right", 1.0))
	dock_panel.anchor_bottom = float(options.get("dock_anchor_bottom", 1.0))
	dock_panel.offset_left = float(options.get("dock_left", back_right + panel_gap))
	dock_panel.offset_top = float(options.get("top", -222.0))
	dock_panel.offset_right = right
	dock_panel.offset_bottom = float(options.get("bottom", -110.0))
	dock_panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(panel_fill, panel_border, 16))
	host.add_child(dock_panel)

	var dock_margin := _make_content_margin(int(options.get("margin", 12)))
	dock_panel.add_child(dock_margin)

	var dock_row := HBoxContainer.new()
	dock_row.add_theme_constant_override("separation", int(options.get("separation", 8)))
	dock_margin.add_child(dock_row)

	for item_variant: Variant in items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var key: String = str(item.get("key", ""))
		if key == "":
			continue
		var btn := Button.new()
		btn.text = str(item.get("label", key))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, button_height)
		btn.add_theme_font_size_override("font_size", font_size)
		if not button_pressed.is_null():
			btn.pressed.connect(button_pressed.bind(key))
		dock_row.add_child(btn)
		button_map[key] = btn

	refresh(button_map, active_key, options)
	return {
		"back_panel": back_panel,
		"back_button": back_btn,
		"dock_panel": dock_panel,
		"buttons": button_map,
	}


static func refresh(button_map: Dictionary, active_key: String, options: Dictionary = {}) -> void:
	var active_color: Color = options.get("active_color", SceneMenuTheme.ACTIVE_COLOR)
	var inactive_color: Color = options.get("inactive_color", SceneMenuTheme.INACTIVE_COLOR)
	var active_font_size: int = int(options.get("active_font_size", SceneMenuTheme.SUBMENU_ACTIVE_FONT_SIZE))
	var inactive_font_size: int = int(options.get("inactive_font_size", SceneMenuTheme.SUBMENU_INACTIVE_FONT_SIZE))

	for key: String in button_map.keys():
		var btn: Button = button_map[key]
		if btn == null:
			continue
		var is_active: bool = key == active_key
		btn.modulate = active_color if is_active else inactive_color
		btn.add_theme_font_size_override("font_size", active_font_size if is_active else inactive_font_size)


static func _make_content_margin(value: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_bottom", value)
	return margin
