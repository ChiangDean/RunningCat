class_name ContentBottomSubmenu
extends RefCounted



static func build(host: Control, options: Dictionary) -> Dictionary:
	var panel: PanelContainer = options.get("panel") as PanelContainer
	if panel == null:
		panel = OverlaySceneChrome.make_card_panel()
		host.add_child(panel)
	else:
		for child: Node in panel.get_children():
			child.queue_free()

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(int(options.get("margin", 12)))
	panel.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", int(options.get("separation", 10)))
	margin.add_child(row)

	var buttons: Dictionary = {}
	var button_pressed: Callable = options.get("button_pressed", Callable())
	for item_variant: Variant in options.get("items", []):
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant as Dictionary
		var key: String = str(item.get("key", ""))
		if key == "":
			continue
		var button: Button = Button.new()
		button.text = str(item.get("label", key))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, float(options.get("button_height", 50.0)))
		button.add_theme_font_size_override("font_size", int(options.get("font_size", UiPalette.FONT_SIZE_BODY_LG)))
		if not button_pressed.is_null():
			button.pressed.connect(button_pressed.bind(key))
		row.add_child(button)
		buttons[key] = button

	refresh(buttons, str(options.get("active_key", "")))
	return {
		"panel": panel,
		"row": row,
		"buttons": buttons,
	}


static func refresh(buttons: Dictionary, active_key: String) -> void:
	for key: String in buttons.keys():
		var button: Button = buttons.get(key) as Button
		if button == null:
			continue
		var is_active: bool = key == active_key
		UiPalette.apply_button_kind(button, "primary" if is_active else "secondary")
		button.modulate = Color(1.0, 0.95, 0.84, 1.0) if is_active else Color(0.92, 0.90, 0.86, 1.0)
