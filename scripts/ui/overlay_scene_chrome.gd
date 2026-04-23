class_name OverlaySceneChrome
extends RefCounted

const SUBMENU_SHELL_SCENE = preload("res://scenes/ui/overlay/SubmenuShellEditor.tscn")

const BOTTOM_DOCK_H := 112.0
const HOME_MAIN_NAV_H := 110.0
const CONTENT_TOP_GAP := 150.0
const TOP_MASK_HEIGHT := 186.0
const SUBMENU_SHELL_CONTENT_LEFT := 28.0
const SUBMENU_SHELL_CONTENT_RIGHT := -26.0
const SUBMENU_SHELL_CONTENT_TOP := 22.0
const SUBMENU_SHELL_HEADER_CONTENT_TOP := 184.0
const SUBMENU_SHELL_CONTENT_TO_SUBMENU_GAP := 14.0
const SUBMENU_SHELL_FRAME_EXTRA_BOTTOM := 46.0
const SUBMENU_SHELL_MIN_CONTENT_H := 220.0

const PANEL_FILL := Color(0.08, 0.07, 0.08, 0.94)
const PANEL_BORDER := Color(0.80, 0.67, 0.42, 0.95)
const CARD_FILL := Color(0.16, 0.15, 0.18, 0.96)
const CARD_BORDER := Color(0.50, 0.43, 0.30, 0.92)
const MUTED_TEXT_COLOR := Color(0.90, 0.88, 0.82, 0.92)
const TITLE_TEXT_COLOR := Color(0.99, 0.97, 0.90, 1.0)


static func build(scene: Control, background_slot: String, back_pressed: Callable, options: Dictionary = {}) -> Dictionary:
	if bool(options.get("show_dock", false)) and bool(options.get("use_submenu_shell", true)):
		return _build_submenu_shell(scene, background_slot, back_pressed, options)

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


static func _build_submenu_shell(scene: Control, background_slot: String, back_pressed: Callable, options: Dictionary) -> Dictionary:
	var shell_root: Control = SUBMENU_SHELL_SCENE.instantiate() as Control
	scene.add_child(shell_root)

	var background: TextureRect = shell_root.get_node("Background") as TextureRect
	var dim: ColorRect = shell_root.get_node("Dim") as ColorRect
	var top_mask: ColorRect = shell_root.get_node("TopMask") as ColorRect
	var content_root: Control = shell_root.get_node("ContentRoot") as Control
	var frame: TextureRect = shell_root.get_node("ContentRoot/Frame") as TextureRect
	var submenu_root: Control = shell_root.get_node("SubmenuBarRoot") as Control
	var content_host: MarginContainer = shell_root.get_node("ContentRoot/ShellContentHost") as MarginContainer
	var viewport_scroll: ScrollContainer = shell_root.get_node("ContentRoot/ShellContentHost/ShellViewportScroll") as ScrollContainer
	var content_box: VBoxContainer = shell_root.get_node("ContentRoot/ShellContentHost/ShellViewportScroll/ShellContentBox") as VBoxContainer
	var title_label: Label = shell_root.get_node("ContentRoot/SubmenuTitle") as Label
	var desc_label: Label = shell_root.get_node("ContentRoot/SubmenuDescription") as Label
	var summary_left_label: Label = shell_root.get_node("ContentRoot/SummaryLeft") as Label
	var summary_right_label: Label = shell_root.get_node("ContentRoot/SummaryRight") as Label

	_apply_shell_background(background, background_slot)
	dim.color = Color(0.03, 0.02, 0.03, 0.56)
	top_mask.color = Color(0.03, 0.03, 0.04, 0.62)
	_apply_shell_header(title_label, desc_label, summary_left_label, summary_right_label, options)

	var show_header: bool = _should_show_shell_header(options)
	var default_content_top: float = content_host.offset_top
	var default_content_bottom_offset: float = content_host.offset_bottom
	if not show_header and is_equal_approx(default_content_top, SUBMENU_SHELL_HEADER_CONTENT_TOP):
		default_content_top = SUBMENU_SHELL_CONTENT_TOP
	var content_top: float = float(options.get("shell_content_top", default_content_top))
	if options.has("shell_content_left"):
		content_host.offset_left = float(options.get("shell_content_left", content_host.offset_left))
	if options.has("shell_content_top"):
		content_host.offset_top = content_top
	else:
		content_host.offset_top = default_content_top
	if options.has("shell_content_right"):
		content_host.offset_right = float(options.get("shell_content_right", content_host.offset_right))
	content_host.offset_bottom = _resolve_shell_content_bottom_offset(content_root, frame, submenu_root, content_top, default_content_bottom_offset, options)
	viewport_scroll.clip_contents = true
	viewport_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	viewport_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	viewport_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_scroll.mouse_filter = Control.MOUSE_FILTER_STOP

	content_box.clip_contents = true
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.size_flags_vertical = 0
	content_box.add_theme_constant_override("separation", int(options.get("content_separation", 14)))

	var submenu: Dictionary = SceneSubmenuBar.build_on_shell(submenu_root, {
		"items": options.get("dock_items", []),
		"active_key": str(options.get("active_key", "")),
		"back_label": str(options.get("back_label", UiText.COMMON_BACK)),
		"back_pressed": back_pressed,
		"button_pressed": options.get("button_pressed", Callable()),
		"button_height": float(options.get("button_height", 52.0)),
		"font_size": int(options.get("font_size", UiPalette.FONT_SIZE_BODY_LG)),
		"separation": int(options.get("separation", 8)),
		"shell_title_label": title_label,
		"shell_description_label": desc_label,
		"shell_summary_left_label": summary_left_label,
		"shell_summary_right_label": summary_right_label,
		"sync_title_to_active_button": bool(options.get("sync_title_to_active_button", true)),
	})

	_connect_shell_height_sync(content_box, content_host, viewport_scroll, content_root, frame, submenu_root, content_top, default_content_bottom_offset, options)

	return {
		"background": background,
		"dim": dim,
		"top_mask": top_mask,
		"back_panel": submenu.get("back_panel"),
		"back_button": submenu.get("back_button"),
		"dock_panel": submenu.get("dock_panel"),
		"dock_buttons": submenu.get("buttons", {}),
		"content_panel": frame,
		"content_box": content_box,
		"shell_root": shell_root,
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


static func _apply_shell_background(background: TextureRect, slot: String) -> void:
	if background == null:
		return
	background.texture = AssetResolver.load_texture(str(AssetResolver.BACKGROUNDS.get(slot, "")))
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.38, 0.38, 0.42, 1.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = AssetResolver.BACKGROUND_SHADER
	material.set_shader_parameter("desaturate_strength", 0.42)
	background.material = material


static func _should_show_shell_header(options: Dictionary) -> bool:
	if options.has("shell_show_header"):
		return bool(options.get("shell_show_header", false))
	var dock_items: Array = options.get("dock_items", [])
	if bool(options.get("sync_title_to_active_button", true)) and not dock_items.is_empty():
		return true
	return (
		str(options.get("shell_title", "")) != ""
		or str(options.get("shell_description", "")) != ""
		or str(options.get("shell_summary_left", "")) != ""
		or str(options.get("shell_summary_right", "")) != ""
	)


static func _apply_shell_header(
	title_label: Label,
	desc_label: Label,
	summary_left_label: Label,
	summary_right_label: Label,
	options: Dictionary
) -> void:
	var show_header: bool = _should_show_shell_header(options)
	var title_text: String = str(options.get("shell_title", ""))
	var desc_text: String = str(options.get("shell_description", ""))
	var summary_left_text: String = str(options.get("shell_summary_left", ""))
	var summary_right_text: String = str(options.get("shell_summary_right", ""))

	if title_label != null:
		title_label.text = title_text
		title_label.visible = show_header and title_text != ""
	if desc_label != null:
		desc_label.text = desc_text
		desc_label.visible = show_header and desc_text != ""
	if summary_left_label != null:
		summary_left_label.text = summary_left_text
		summary_left_label.visible = show_header and summary_left_text != ""
	if summary_right_label != null:
		summary_right_label.text = summary_right_text
		summary_right_label.visible = show_header and summary_right_text != ""


static func _connect_shell_height_sync(
	content_box: VBoxContainer,
	content_host: MarginContainer,
	viewport_scroll: ScrollContainer,
	content_root: Control,
	frame: TextureRect,
	submenu_root: Control,
	content_top: float,
	default_content_bottom_offset: float,
	options: Dictionary
) -> void:
	var sync: Callable = _run_shell_height_sync.bind(
		content_box,
		content_host,
		viewport_scroll,
		content_root,
		frame,
		submenu_root,
		content_top,
		default_content_bottom_offset,
		options
	)
	var sync_from_child: Callable = _run_shell_height_sync_from_child.bind(
		content_box,
		content_host,
		viewport_scroll,
		content_root,
		frame,
		submenu_root,
		content_top,
		default_content_bottom_offset,
		options
	)

	content_box.child_entered_tree.connect(sync_from_child)
	content_box.child_exiting_tree.connect(sync_from_child)
	content_box.resized.connect(sync)
	content_root.resized.connect(sync)
	frame.resized.connect(sync)
	submenu_root.resized.connect(sync)
	sync.call()


static func _resolve_shell_content_bottom_offset(
	content_root: Control,
	_frame: TextureRect,
	_submenu_root: Control,
	content_top: float,
	default_content_bottom_offset: float,
	options: Dictionary
) -> float:
	if content_root == null:
		return content_top + float(options.get("shell_min_content_height", SUBMENU_SHELL_MIN_CONTENT_H))

	var target_bottom: float = float(options.get("shell_content_bottom", default_content_bottom_offset))
	return target_bottom


static func _sync_shell_height(
	content_box: VBoxContainer,
	content_host: MarginContainer,
	viewport_scroll: ScrollContainer,
	content_root: Control,
	frame: TextureRect,
	submenu_root: Control,
	content_top: float,
	default_content_bottom_offset: float,
	options: Dictionary
) -> void:
	if content_box == null or content_host == null or viewport_scroll == null or content_root == null or frame == null or submenu_root == null:
		return

	_sync_shell_scroll_behavior(content_box, viewport_scroll)

	var submenu_limit: float = submenu_root.offset_top - content_root.offset_top - SUBMENU_SHELL_CONTENT_TO_SUBMENU_GAP
	var resolved_bottom_offset: float = _resolve_shell_content_bottom_offset(
		content_root,
		frame,
		submenu_root,
		content_top,
		default_content_bottom_offset,
		options
	)
	var resolved_bottom: float = resolved_bottom_offset
	var target_content_height: float = maxf(0.0, resolved_bottom - content_top)
	var content_box_min_height: float = target_content_height if _content_box_has_expand_child(content_box) else 0.0

	content_host.offset_bottom = resolved_bottom_offset
	viewport_scroll.custom_minimum_size = Vector2(0.0, target_content_height)
	content_box.custom_minimum_size = Vector2(maxf(0.0, content_host.size.x), content_box_min_height)
	var frame_extra_bottom: float = float(options.get("shell_frame_extra_bottom", SUBMENU_SHELL_FRAME_EXTRA_BOTTOM))
	frame.offset_bottom = minf(resolved_bottom + frame_extra_bottom, submenu_limit + frame_extra_bottom)


static func _sync_shell_scroll_behavior(content_box: VBoxContainer, viewport_scroll: ScrollContainer) -> void:
	if content_box == null or viewport_scroll == null:
		return

	var has_inner_scroll: bool = _content_box_has_expand_child(content_box)
	if has_inner_scroll:
		InertialScroller.detach(viewport_scroll)
		viewport_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		viewport_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		viewport_scroll.set_v_scroll(0)
		return

	viewport_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	viewport_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	InertialScroller.attach(viewport_scroll, "vertical")


static func _content_box_has_expand_child(content_box: VBoxContainer) -> bool:
	for child: Node in content_box.get_children():
		if not (child is Control):
			continue
		var control_child: Control = child as Control
		if not control_child.visible:
			continue
		if control_child is ScrollContainer:
			return true
		if (control_child.size_flags_vertical & Control.SIZE_EXPAND) != 0:
			return true
	return false


static func _run_shell_height_sync(
	content_box: VBoxContainer,
	content_host: MarginContainer,
	viewport_scroll: ScrollContainer,
	content_root: Control,
	frame: TextureRect,
	submenu_root: Control,
	content_top: float,
	default_content_bottom_offset: float,
	options: Dictionary
) -> void:
	_sync_shell_height(
		content_box,
		content_host,
		viewport_scroll,
		content_root,
		frame,
		submenu_root,
		content_top,
		default_content_bottom_offset,
		options
	)


static func _run_shell_height_sync_from_child(
	_child: Node,
	content_box: VBoxContainer,
	content_host: MarginContainer,
	viewport_scroll: ScrollContainer,
	content_root: Control,
	frame: TextureRect,
	submenu_root: Control,
	content_top: float,
	default_content_bottom_offset: float,
	options: Dictionary
) -> void:
	_run_shell_height_sync(
		content_box,
		content_host,
		viewport_scroll,
		content_root,
		frame,
		submenu_root,
		content_top,
		default_content_bottom_offset,
		options
	)
