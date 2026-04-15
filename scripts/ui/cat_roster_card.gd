class_name CatRosterCard
extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")


static func build(options: Dictionary) -> PanelContainer:
	var is_selected: bool = bool(options.get("is_selected", false))
	var show_action: bool = bool(options.get("show_action", true))
	var card_fill: Color = options.get("card_fill", Color(0.16, 0.15, 0.18, 0.96))
	var card_border: Color = options.get("card_border", Color(0.50, 0.43, 0.30, 0.92))
	var selected_card_border: Color = options.get("selected_card_border", card_border)
	var selected_card_fill: Color = options.get("selected_card_fill", card_fill)
	var art_fill: Color = options.get("art_fill", Color(0.19, 0.17, 0.15, 0.96))
	var art_border: Color = options.get("art_border", Color(0.90, 0.77, 0.46, 0.88))
	var selected_art_border: Color = options.get("selected_art_border", art_border)
	var selected_art_fill: Color = options.get("selected_art_fill", art_fill)
	var title_color: Color = options.get("title_color", Color(0.98, 0.95, 0.88, 1.0))
	var button_bg: Color = options.get("button_bg", Color(0.94, 0.77, 0.39, 1.0))
	var button_fg: Color = options.get("button_fg", Color(0.16, 0.11, 0.05, 1.0))
	var content_separation: int = int(options.get("content_separation", 10))
	var button_height: float = float(options.get("button_height", 34.0))
	var card_height: float = float(options.get("card_height", 228.0))
	if not show_action:
		card_height = maxf(0.0, card_height - button_height - content_separation)

	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, card_height)
	card.add_theme_stylebox_override(
		"panel",
		OverlaySceneChrome.make_panel_style(
			selected_card_fill if is_selected else card_fill,
			selected_card_border if is_selected else card_border,
			int(options.get("card_radius", 14))
		)
	)

	var margin: MarginContainer = _make_content_margin(int(options.get("outer_margin", 8)))
	card.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", content_separation)
	margin.add_child(root)

	var art_panel: PanelContainer = PanelContainer.new()
	art_panel.custom_minimum_size = Vector2(0.0, float(options.get("art_height", 112.0)))
	art_panel.add_theme_stylebox_override(
		"panel",
		OverlaySceneChrome.make_panel_style(
			selected_art_fill if is_selected else art_fill,
			selected_art_border if is_selected else art_border,
			int(options.get("art_radius", 12))
		)
	)
	root.add_child(art_panel)

	var art_margin: MarginContainer = _make_content_margin(int(options.get("art_margin", 8)))
	art_panel.add_child(art_margin)

	var art_btn: Button = Button.new()
	art_btn.flat = true
	art_btn.text = ""
	art_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	art_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art_pressed: Callable = options.get("art_pressed", Callable())
	if not art_pressed.is_null():
		art_btn.pressed.connect(art_pressed)
	art_panel.add_child(art_btn)

	var art_center: CenterContainer = CenterContainer.new()
	art_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_margin.add_child(art_center)

	var cat_icon: Texture2D = options.get("icon_texture", null)
	if cat_icon != null:
		art_center.add_child(AssetResolver.create_icon_rect(cat_icon, options.get("icon_size", Vector2(86.0, 86.0))))
	else:
		var fallback: Label = Label.new()
		fallback.text = str(options.get("fallback_text", ""))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", int(options.get("fallback_font_size", 40)))
		fallback.add_theme_color_override("font_color", title_color)
		art_center.add_child(fallback)

	var title_label: Label = Label.new()
	var show_title: bool = bool(options.get("show_title", true))
	if show_title:
		title_label.text = str(options.get("title_text", ""))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", int(options.get("title_font_size", 22)))
		title_label.add_theme_color_override("font_color", title_color)
		root.add_child(title_label)

	var chip_wrap: HBoxContainer = HBoxContainer.new()
	chip_wrap.add_theme_constant_override("separation", int(options.get("chip_h_separation", 8)))
	root.add_child(chip_wrap)

	var chips: Array = options.get("chips", [])
	for chip_index: int in range(chips.size()):
		var chip_text_variant: Variant = chips[chip_index]
		var chip_text: String = str(chip_text_variant)
		if chip_text == "":
			continue
		var chip: PanelContainer = _make_meta_chip(chip_text, is_selected, options)
		if chip_index == 0:
			chip.size_flags_horizontal = 0
		else:
			var spacer: Control = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			chip_wrap.add_child(spacer)
		chip_wrap.add_child(chip)

	var action_btn: Button = Button.new()
	if show_action:
		action_btn.text = str(options.get("action_text", ""))
		action_btn.custom_minimum_size = Vector2(0.0, button_height)
		action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_btn.disabled = bool(options.get("action_disabled", false))
		var action_pressed: Callable = options.get("action_pressed", Callable())
		if not action_pressed.is_null() and not action_btn.disabled:
			action_btn.pressed.connect(action_pressed)
		UiPalette.apply_button_palette(action_btn, button_bg, button_fg)
		root.add_child(action_btn)

	var whole_card_pressed: Callable = options.get("whole_card_pressed", Callable())
	var whole_card_gui_input: Callable = options.get("whole_card_gui_input", Callable())
	if not whole_card_pressed.is_null():
		var overlay_btn: Button = Button.new()
		overlay_btn.flat = true
		overlay_btn.text = ""
		overlay_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay_btn.pressed.connect(whole_card_pressed)
		if not whole_card_gui_input.is_null():
			overlay_btn.gui_input.connect(whole_card_gui_input)
		card.add_child(overlay_btn)
	elif not whole_card_gui_input.is_null():
		var overlay_btn_only: Button = Button.new()
		overlay_btn_only.flat = true
		overlay_btn_only.text = ""
		overlay_btn_only.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay_btn_only.gui_input.connect(whole_card_gui_input)
		card.add_child(overlay_btn_only)

	return card


static func _make_meta_chip(text: String, is_selected: bool, options: Dictionary) -> PanelContainer:
	var title_color: Color = options.get("title_color", Color(0.98, 0.95, 0.88, 1.0))
	var selected_chip_fill: Color = options.get("selected_chip_fill", Color(0.31, 0.22, 0.13, 0.95))
	var chip_fill: Color = options.get("chip_fill", Color(0.20, 0.16, 0.18, 0.92))
	var selected_chip_border: Color = options.get("selected_chip_border", options.get("selected_card_border", Color(0.80, 0.67, 0.42, 0.95)))
	var chip_border: Color = options.get("chip_border", Color(0.46, 0.36, 0.26, 0.88))
	var selected_chip_text: Color = options.get("selected_chip_text_color", title_color)

	var chip: PanelContainer = PanelContainer.new()
	chip.custom_minimum_size = Vector2(float(options.get("chip_min_width", 75.0)), 0.0)
	chip.add_theme_stylebox_override(
		"panel",
		OverlaySceneChrome.make_panel_style(
			selected_chip_fill if is_selected else chip_fill,
			selected_chip_border if is_selected else chip_border,
			int(options.get("chip_radius", 12))
		)
	)

	var margin: MarginContainer = _make_content_margin(int(options.get("chip_margin", 6)))
	chip.add_child(margin)

	var label: Label = Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(options.get("chip_font_size", 16)))
	label.add_theme_color_override("font_color", selected_chip_text if is_selected else title_color)
	margin.add_child(label)

	return chip


static func _make_content_margin(value: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_bottom", value)
	return margin
