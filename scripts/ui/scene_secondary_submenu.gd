class_name SceneSecondarySubmenu
extends RefCounted



static func build(host: Control, options: Dictionary) -> Dictionary:
	var button_map: Dictionary = {}
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", int(options.get("row_separation", 12)))
	host.add_child(row)

	var secondary_panel: PanelContainer = OverlaySceneChrome.make_card_panel(
		options.get("secondary_border", OverlaySceneChrome.PANEL_BORDER),
		options.get("secondary_fill", OverlaySceneChrome.CARD_FILL),
		int(options.get("secondary_radius", SceneMenuTheme.PANEL_RADIUS))
	)
	secondary_panel.custom_minimum_size = Vector2(float(options.get("secondary_width", SceneMenuTheme.SECONDARY_SUBMENU_WIDTH)), 0.0)
	row.add_child(secondary_panel)

	var secondary_margin: MarginContainer = OverlaySceneChrome.make_content_margin(int(options.get("secondary_margin", SceneMenuTheme.PANEL_MARGIN)))
	secondary_panel.add_child(secondary_margin)

	var secondary_list: VBoxContainer = VBoxContainer.new()
	secondary_list.add_theme_constant_override("separation", int(options.get("secondary_separation", 8)))
	secondary_margin.add_child(secondary_list)

	var button_pressed: Callable = options.get("button_pressed", Callable())
	for item_variant: Variant in options.get("items", []):
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var key: String = str(item.get("key", ""))
		if key == "":
			continue
		var button: Button = Button.new()
		button.text = str(item.get("label", key))
		button.custom_minimum_size = Vector2(0.0, float(options.get("button_height", SceneMenuTheme.SECONDARY_SUBMENU_BUTTON_HEIGHT)))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not button_pressed.is_null():
			button.pressed.connect(button_pressed.bind(key))
		secondary_list.add_child(button)
		button_map[key] = button

	var content_panel: PanelContainer = OverlaySceneChrome.make_card_panel(
		options.get("content_border", OverlaySceneChrome.CARD_BORDER),
		options.get("content_fill", OverlaySceneChrome.CARD_FILL),
		int(options.get("content_radius", SceneMenuTheme.PANEL_RADIUS))
	)
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(content_panel)

	var content_margin: MarginContainer = OverlaySceneChrome.make_content_margin(int(options.get("content_margin", SceneMenuTheme.CONTENT_MARGIN)))
	content_panel.add_child(content_margin)

	var content_scroll: ScrollContainer = ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vertical_scroll_mode: ScrollContainer.ScrollMode = int(
		options.get("content_vertical_scroll_mode", ScrollContainer.SCROLL_MODE_AUTO)
	) as ScrollContainer.ScrollMode
	content_scroll.vertical_scroll_mode = vertical_scroll_mode
	content_margin.add_child(content_scroll)
	InertialScroller.attach(content_scroll, "vertical")

	var content_list: VBoxContainer = VBoxContainer.new()
	content_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_list.add_theme_constant_override("separation", int(options.get("content_separation", SceneMenuTheme.CONTENT_SEPARATION)))
	content_scroll.add_child(content_list)

	refresh(button_map, str(options.get("active_key", "")), options)
	return {
		"row": row,
		"secondary_panel": secondary_panel,
		"secondary_buttons": button_map,
		"content_panel": content_panel,
		"content_scroll": content_scroll,
		"content_list": content_list,
	}


static func refresh(button_map: Dictionary, active_key: String, options: Dictionary = {}) -> void:
	SceneSubmenuBar.refresh(button_map, active_key, {
		"active_color": options.get("active_color", SceneMenuTheme.ACTIVE_COLOR),
		"inactive_color": options.get("inactive_color", SceneMenuTheme.INACTIVE_COLOR),
		"active_font_size": int(options.get("active_font_size", SceneMenuTheme.SECONDARY_SUBMENU_ACTIVE_FONT_SIZE)),
		"inactive_font_size": int(options.get("inactive_font_size", SceneMenuTheme.SECONDARY_SUBMENU_INACTIVE_FONT_SIZE)),
	})
