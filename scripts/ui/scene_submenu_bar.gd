class_name SceneSubmenuBar
extends RefCounted

const SceneMenuTheme = preload("res://scripts/ui/scene_menu_theme.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const SHELL_TAB_LABEL_PATHS: Array[String] = [
	"TabEquipLabel",
	"TabAbilityLabel",
	"TabMemoryLabel",
	"TabTreasureLabel",
	"TabAchievementLabel",
]

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


static func build_on_shell(submenu_root: Control, options: Dictionary) -> Dictionary:
	var button_map: Dictionary = {}
	var back_button: Button = null
	if submenu_root == null:
		return {
			"back_panel": null,
			"back_button": null,
			"dock_panel": null,
			"buttons": button_map,
		}

	var back_panel: Control = submenu_root.get_node_or_null("BackButton") as Control
	var back_label: Label = submenu_root.get_node_or_null("BackLabel") as Label
	var dock_panel: Control = submenu_root.get_node_or_null("SubmenuFrame") as Control
	var button_height: float = float(options.get("button_height", SceneMenuTheme.SUBMENU_BUTTON_HEIGHT))
	var font_size: int = int(options.get("font_size", SceneMenuTheme.SUBMENU_FONT_SIZE))
	var back_pressed: Callable = options.get("back_pressed", Callable())
	var button_pressed: Callable = options.get("button_pressed", Callable())

	if back_label != null:
		back_label.text = str(options.get("back_label", UiText.SCOOPER_BACK))
		back_label.visible = true

	for label_path: String in SHELL_TAB_LABEL_PATHS:
		var label: Label = submenu_root.get_node_or_null(label_path) as Label
		if label != null:
			label.visible = false

	if back_panel != null:
		back_button = _make_shell_hit_button(_get_control_rect(back_panel))
		if not back_pressed.is_null():
			back_button.pressed.connect(back_pressed)
		submenu_root.add_child(back_button)
		button_map["_back"] = back_button

	var dock_row: HBoxContainer = HBoxContainer.new()
	dock_row.name = "DynamicDockRow"
	dock_row.anchor_left = 0.0
	dock_row.anchor_top = 0.0
	dock_row.anchor_right = 0.0
	dock_row.anchor_bottom = 0.0
	dock_row.offset_left = 129.0
	dock_row.offset_top = 47.0
	dock_row.offset_right = 682.0
	dock_row.offset_bottom = 109.0
	dock_row.add_theme_constant_override("separation", int(options.get("separation", 8)))
	submenu_root.add_child(dock_row)

	if dock_panel != null:
		var dock_rect: Rect2 = _get_control_rect(dock_panel)
		dock_row.offset_left = dock_rect.position.x + 14.0
		dock_row.offset_top = dock_rect.position.y + 8.0
		dock_row.offset_right = dock_rect.position.x + dock_rect.size.x - 14.0
		dock_row.offset_bottom = dock_rect.position.y + dock_rect.size.y - 8.0

	for item_variant: Variant in options.get("items", []):
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var key: String = str(item.get("key", ""))
		if key == "":
			continue
		var button: Button = _make_shell_tab_button(str(item.get("label", key)), button_height, font_size)
		apply_shell_metadata(button, item, options)
		if not button_pressed.is_null():
			button.pressed.connect(button_pressed.bind(key))
		dock_row.add_child(button)
		button_map[key] = button

	var active_key: String = str(options.get("active_key", ""))
	refresh(button_map, active_key, options)
	button_map.erase("_back")
	return {
		"back_panel": back_panel,
		"back_button": back_button,
		"dock_panel": dock_panel,
		"buttons": button_map,
	}


static func refresh(button_map: Dictionary, active_key: String, options: Dictionary = {}) -> void:
	var active_color: Color = options.get("active_color", SceneMenuTheme.ACTIVE_COLOR)
	var inactive_color: Color = options.get("inactive_color", SceneMenuTheme.INACTIVE_COLOR)
	var active_font_size: int = int(options.get("active_font_size", SceneMenuTheme.SUBMENU_ACTIVE_FONT_SIZE))
	var inactive_font_size: int = int(options.get("inactive_font_size", SceneMenuTheme.SUBMENU_INACTIVE_FONT_SIZE))
	var active_button: Button = button_map.get(active_key) as Button

	for key: String in button_map.keys():
		var btn: Button = button_map[key]
		if btn == null:
			continue
		var is_active: bool = key == active_key
		btn.modulate = active_color if is_active else inactive_color
		btn.add_theme_font_size_override("font_size", active_font_size if is_active else inactive_font_size)

	if active_button != null:
		_refresh_shell_header(active_button)


static func apply_shell_metadata(button: Button, item: Dictionary, options: Dictionary = {}) -> void:
	if button == null:
		return
	button.set_meta("shell_meta", item.duplicate())
	var title_label: Label = options.get("shell_title_label", null) as Label
	var description_label: Label = options.get("shell_description_label", null) as Label
	var summary_left_label: Label = options.get("shell_summary_left_label", null) as Label
	var summary_right_label: Label = options.get("shell_summary_right_label", null) as Label
	if title_label == null and button.has_meta("shell_title_label"):
		title_label = button.get_meta("shell_title_label") as Label
	if description_label == null and button.has_meta("shell_description_label"):
		description_label = button.get_meta("shell_description_label") as Label
	if summary_left_label == null and button.has_meta("shell_summary_left_label"):
		summary_left_label = button.get_meta("shell_summary_left_label") as Label
	if summary_right_label == null and button.has_meta("shell_summary_right_label"):
		summary_right_label = button.get_meta("shell_summary_right_label") as Label
	button.set_meta("shell_title_label", title_label)
	button.set_meta("shell_description_label", description_label)
	button.set_meta("shell_summary_left_label", summary_left_label)
	button.set_meta("shell_summary_right_label", summary_right_label)
	button.set_meta("sync_title_to_active_button", bool(options.get("sync_title_to_active_button", true)))


static func _refresh_shell_header(active_button: Button) -> void:
	var shell_meta: Dictionary = _get_shell_meta(active_button)
	var title_text: String = _resolve_shell_title(active_button, shell_meta)
	var description_text: String = _resolve_shell_text(shell_meta.get("shell_description", ""))
	var summary_left_text: String = _resolve_shell_text(shell_meta.get("shell_summary_left", ""))
	var summary_right_text: String = _resolve_shell_text(shell_meta.get("shell_summary_right", ""))

	_apply_shell_label(_get_meta_label(active_button, "shell_title_label"), title_text)
	_apply_shell_label(_get_meta_label(active_button, "shell_description_label"), description_text)
	_apply_shell_label(_get_meta_label(active_button, "shell_summary_left_label"), summary_left_text)
	_apply_shell_label(_get_meta_label(active_button, "shell_summary_right_label"), summary_right_text)


static func _resolve_shell_title(active_button: Button, shell_meta: Dictionary) -> String:
	var explicit_title: String = _resolve_shell_text(shell_meta.get("shell_title", ""))
	if explicit_title != "":
		return explicit_title
	if _get_meta_bool(active_button, "sync_title_to_active_button", false):
		return active_button.text.strip_edges()
	return ""


static func _get_shell_meta(active_button: Button) -> Dictionary:
	var meta_variant: Variant = {}
	if active_button != null and active_button.has_meta("shell_meta"):
		meta_variant = active_button.get_meta("shell_meta")
	if meta_variant is Dictionary:
		return meta_variant as Dictionary
	return {}


static func _get_meta_label(control: Object, key: String) -> Label:
	if control == null or not control.has_meta(key):
		return null
	return control.get_meta(key) as Label


static func _get_meta_bool(control: Object, key: String, default_value: bool) -> bool:
	if control == null or not control.has_meta(key):
		return default_value
	return bool(control.get_meta(key))


static func _resolve_shell_text(value: Variant) -> String:
	if value is Callable:
		var callback: Callable = value as Callable
		if callback.is_valid():
			return _variant_to_shell_text(callback.call())
		return ""
	return _variant_to_shell_text(value)


static func _variant_to_shell_text(value: Variant) -> String:
	if value == null:
		return ""
	return str(value).strip_edges()


static func _apply_shell_label(label: Label, text: String) -> void:
	if label == null:
		return
	label.text = text
	label.visible = text != ""


static func _make_content_margin(value: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_bottom", value)
	return margin


static func _make_shell_hit_button(button_rect: Rect2) -> Button:
	var button: Button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.text = ""
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = button_rect.position.x
	button.offset_top = button_rect.position.y
	button.offset_right = button_rect.position.x + button_rect.size.x
	button.offset_bottom = button_rect.position.y + button_rect.size.y
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	return button


static func _make_shell_tab_button(label_text: String, button_height: float, font_size: int) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, button_height)
	button.add_theme_font_size_override("font_size", font_size)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	return button


static func _get_control_rect(control: Control) -> Rect2:
	if control == null:
		return Rect2()
	return Rect2(
		Vector2(control.offset_left, control.offset_top),
		Vector2(control.offset_right - control.offset_left, control.offset_bottom - control.offset_top)
	)
