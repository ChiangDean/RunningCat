class_name EnhanceSceneUI
extends RefCounted

const Refresh = preload("res://scripts/enhance/EnhanceSceneRefresh.gd")
const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const CatRosterCard = preload("res://scripts/ui/cat_roster_card.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")

const DETAIL_TAB_FILL := Color(0.20, 0.16, 0.18, 0.92)
const DETAIL_TAB_ACTIVE_FILL := Color(0.43, 0.31, 0.14, 0.98)
const MUTED_TEXT_COLOR := Color(0.90, 0.88, 0.82, 0.92)
const SLOT_NAME_COLOR := Color(0.98, 0.95, 0.88, 1.0)
const ART_FILL := Color(0.19, 0.17, 0.15, 0.96)
const ART_BORDER := Color(0.90, 0.77, 0.46, 0.88)
const DETAIL_DIALOG_CONTENT_W := 608.0


class IdlePreviewPlayer:
	extends Control

	var frames: Array[Texture2D] = []
	var frame_index: int = 0
	var preview_rect: TextureRect
	var frame_timer: Timer
	var cooldown_timer: Timer

	func setup(preview_size: Vector2, preview_frames: Array[Texture2D], fps: float) -> void:
		custom_minimum_size = preview_size
		process_mode = Node.PROCESS_MODE_ALWAYS
		frames = preview_frames

		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(center)

		preview_rect = TextureRect.new()
		preview_rect.custom_minimum_size = preview_size
		preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview_rect.texture = frames[0]
		center.add_child(preview_rect)

		if frames.size() <= 1:
			return

		frame_timer = Timer.new()
		frame_timer.one_shot = false
		frame_timer.wait_time = 1.0 / maxf(1.0, fps)
		frame_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		frame_timer.timeout.connect(_on_frame_timer_timeout)
		add_child(frame_timer)

		cooldown_timer = Timer.new()
		cooldown_timer.one_shot = true
		cooldown_timer.wait_time = 10.0
		cooldown_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		cooldown_timer.autostart = true
		cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
		add_child(cooldown_timer)

	func _on_frame_timer_timeout() -> void:
		if preview_rect == null or frames.is_empty():
			return
		frame_index += 1
		if frame_index >= frames.size():
			frame_timer.stop()
			frame_index = 0
			preview_rect.texture = frames[0]
			if cooldown_timer != null:
				cooldown_timer.start()
			return
		preview_rect.texture = frames[frame_index]

	func _on_cooldown_timer_timeout() -> void:
		if preview_rect == null or frames.size() <= 1:
			return
		frame_index = 0
		preview_rect.texture = frames[0]
		if frame_timer != null:
			frame_timer.start()

static func build_ui(scene) -> void:
	var bg := AssetResolver.make_fullscreen_background("enhance")
	scene.add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.05, 0.34)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.add_child(dim)

	var submenu: Dictionary = SceneSubmenuBar.build(scene, {
		"items": [
			{"key": "main", "label": UiText.ENHANCE_SUBMENU_MAIN},
			{"key": "catalog", "label": UiText.ENHANCE_SUBMENU_CATALOG},
		],
		"active_key": scene._active_submenu,
		"back_label": UiText.ENHANCE_BACK,
		"back_pressed": Callable(scene, "_on_back_pressed"),
		"button_pressed": Callable(scene, "_switch_submenu"),
		"panel_fill": OverlaySceneChrome.PANEL_FILL,
		"panel_border": OverlaySceneChrome.PANEL_BORDER,
		"button_height": 52.0,
		"back_anchor_top": 1.0,
		"back_anchor_bottom": 1.0,
		"dock_anchor_top": 1.0,
		"dock_anchor_bottom": 1.0,
		"top": -(OverlaySceneChrome.HOME_MAIN_NAV_H + OverlaySceneChrome.BOTTOM_DOCK_H),
		"bottom": -OverlaySceneChrome.HOME_MAIN_NAV_H,
	})
	scene._submenu_btns = submenu.get("buttons", {})

	var content_panel := PanelContainer.new()
	content_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_panel.offset_left = 20.0
	content_panel.offset_top = OverlaySceneChrome.CONTENT_TOP_GAP
	content_panel.offset_right = -20.0
	content_panel.offset_bottom = -(OverlaySceneChrome.HOME_MAIN_NAV_H + OverlaySceneChrome.BOTTOM_DOCK_H + 12.0)
	content_panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(OverlaySceneChrome.PANEL_FILL, OverlaySceneChrome.PANEL_BORDER, 18))
	scene.add_child(content_panel)

	var content_margin := _make_content_margin(18)
	content_panel.add_child(content_margin)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 14)
	content_margin.add_child(content_vbox)

	scene._resource_label = Label.new()
	scene._resource_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	scene._resource_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	content_vbox.add_child(scene._resource_label)
	Refresh.refresh_resource_label(scene)

	scene._main_section = VBoxContainer.new()
	scene._main_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._main_section.add_theme_constant_override("separation", 12)
	content_vbox.add_child(scene._main_section)

	var cats_panel := _make_card_panel()
	cats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cats_panel.size_flags_stretch_ratio = 1.0
	scene._main_section.add_child(cats_panel)

	var cats_margin := _make_content_margin(14)
	cats_panel.add_child(cats_margin)

	var cats_vbox := VBoxContainer.new()
	cats_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cats_vbox.add_theme_constant_override("separation", 10)
	cats_margin.add_child(cats_vbox)

	var cats_title := Label.new()
	cats_title.text = UiText.ENHANCE_CAT_LIST_TITLE
	cats_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	cats_vbox.add_child(cats_title)

	scene._cat_hscroll = ScrollContainer.new()
	scene._cat_hscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._cat_hscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cats_vbox.add_child(scene._cat_hscroll)

	scene._cats_container = GridContainer.new()
	scene._cats_container.columns = 3
	scene._cats_container.add_theme_constant_override("separation", 12)
	scene._cats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._cat_hscroll.add_child(scene._cats_container)
	scene._cat_scroller = InertialScroller.attach(scene._cat_hscroll, "vertical")

	scene._catalog_section = _make_card_panel()
	scene._catalog_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(scene._catalog_section)

	var catalog_margin := _make_content_margin(20)
	scene._catalog_section.add_child(catalog_margin)

	var catalog_box := VBoxContainer.new()
	catalog_box.alignment = BoxContainer.ALIGNMENT_CENTER
	catalog_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalog_box.add_theme_constant_override("separation", 12)
	catalog_margin.add_child(catalog_box)

	var catalog_title := Label.new()
	catalog_title.text = UiText.ENHANCE_CATALOG_TITLE
	catalog_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catalog_title.add_theme_font_size_override("font_size", 30)
	catalog_box.add_child(catalog_title)

	var catalog_desc := Label.new()
	catalog_desc.text = UiText.ENHANCE_CATALOG_TODO_BODY
	catalog_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catalog_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	catalog_desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	catalog_desc.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	catalog_box.add_child(catalog_desc)

	refresh_submenu_state(scene)
	populate_cat_buttons(scene)


static func refresh_submenu_state(scene) -> void:
	SceneSubmenuBar.refresh(scene._submenu_btns, scene._active_submenu, {
		"active_color": SceneMenuTheme.ACTIVE_COLOR,
		"inactive_color": SceneMenuTheme.INACTIVE_COLOR,
	})

	if scene._main_section != null:
		scene._main_section.visible = scene._active_submenu == "main"
	if scene._catalog_section != null:
		scene._catalog_section.visible = scene._active_submenu == "catalog"


static func populate_cat_buttons(scene) -> void:
	if scene._cats_container == null:
		return

	for child in scene._cats_container.get_children():
		child.queue_free()

	var owned: Array = scene.GameState.get_owned_cats()
	if scene._selected_cat_id == "" and owned.size() > 0:
		scene._selected_cat_id = owned[0]
	if scene._selected_cat_id != "" and not owned.has(scene._selected_cat_id):
		scene._selected_cat_id = owned[0] if owned.size() > 0 else ""

	if owned.is_empty():
		var empty_label := Label.new()
		empty_label.text = UiText.ENHANCE_NO_CATS
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
		empty_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
		scene._cats_container.add_child(empty_label)
		return

	for cat_id: String in owned:
		var player_cat: PlayerCatData = scene.GameState.get_player_cat(cat_id)
		scene._cats_container.add_child(_make_cat_card(scene, cat_id, player_cat, cat_id == scene._selected_cat_id))


static func rebuild_detail_panel(scene) -> void:
	if scene._detail_panel == null:
		return

	for child in scene._detail_panel.get_children():
		child.queue_free()

	scene._stat_labels.clear()
	scene._special_point_labels.clear()
	scene._special_plus_btns.clear()
	scene._special_minus_btns.clear()
	scene._special_apply_btn = null
	scene._special_reset_btn = null
	scene._rank_stars_label = null
	scene._rank_progress_bar = null
	scene._rank_progress_label = null
	scene._rank_upgrade_btn = null
	scene._food_upgrade_btn = null
	scene._food_max_btn = null
	scene._food_progress_bar = null
	scene._food_progress_label = null
	scene._detail_resource_label = null
	scene._detail_tab_btns.clear()
	scene._detail_upgrade_tab = null
	scene._detail_skill_tab = null
	scene._detail_rank_tab = null
	scene._cat_name_label = null

	if scene._selected_cat_id == "":
		var empty_label := Label.new()
		empty_label.text = UiText.ENHANCE_SELECT_CAT_EMPTY
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
		empty_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
		scene._detail_panel.add_child(empty_label)
		return

	var player_cat: PlayerCatData = scene.GameState.get_player_cat(scene._selected_cat_id)
	var cat_data := CatData.from_json_file(scene._selected_cat_id + ".json")
	if cat_data == null:
		return

	var summary_panel := _make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_panel.add_child(summary_panel)

	var summary_margin := _make_content_margin(16)
	summary_panel.add_child(summary_margin)

	var summary_stack := VBoxContainer.new()
	summary_stack.add_theme_constant_override("separation", 12)
	summary_margin.add_child(summary_stack)

	scene._detail_resource_label = Label.new()
	scene._detail_resource_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scene._detail_resource_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	scene._detail_resource_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	summary_stack.add_child(scene._detail_resource_label)

	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 14)
	summary_stack.add_child(summary_row)

	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(152.0, 0.0)
	left_column.add_theme_constant_override("separation", 8)
	summary_row.add_child(left_column)

	var icon_shell := PanelContainer.new()
	icon_shell.custom_minimum_size = Vector2(152.0, 152.0)
	icon_shell.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(ART_FILL, ART_BORDER, 14))
	left_column.add_child(icon_shell)

	var icon_center := CenterContainer.new()
	icon_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_shell.add_child(icon_center)
	icon_center.add_child(_make_idle_preview(scene._selected_cat_id, Vector2(120.0, 120.0)))

	var left_meta_row := HBoxContainer.new()
	left_meta_row.add_theme_constant_override("separation", 8)
	left_meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	left_column.add_child(left_meta_row)

	scene._food_level_label = Label.new()
	scene._food_level_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	scene._food_level_label.add_theme_color_override("font_color", SLOT_NAME_COLOR)
	scene._food_level_label.text = UiText.ENHANCE_CAT_LEVEL_FORMAT % [player_cat.cat_food_level]
	var level_chip := _make_info_chip(scene._food_level_label, Color(0.20, 0.16, 0.18, 0.92), OverlaySceneChrome.CARD_BORDER)
	left_meta_row.add_child(level_chip)

	scene._rank_stars_label = Label.new()
	scene._rank_stars_label.add_theme_font_size_override("font_size", 17)
	scene._rank_stars_label.add_theme_color_override("font_color", SLOT_NAME_COLOR)
	var rank_chip := _make_info_chip(scene._rank_stars_label, Color(0.20, 0.16, 0.18, 0.92), OverlaySceneChrome.CARD_BORDER)
	left_meta_row.add_child(rank_chip)

	var summary_body := VBoxContainer.new()
	summary_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_body.alignment = BoxContainer.ALIGNMENT_END
	summary_body.add_theme_constant_override("separation", 12)
	summary_row.add_child(summary_body)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	tab_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_body.add_child(tab_row)

	for tab_item: Dictionary in [
		{"key": "upgrade", "label": UiText.ENHANCE_LEVEL_TAB_LABEL},
		{"key": "skill", "label": UiText.ENHANCE_SKILL_TITLE},
		{"key": "rank", "label": UiText.ENHANCE_RANK_TAB_LABEL},
	]:
		var tab_btn := Button.new()
		tab_btn.text = str(tab_item.get("label", ""))
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.custom_minimum_size = Vector2(0.0, 42.0)
		tab_btn.pressed.connect(Callable(scene, "_switch_detail_tab").bind(str(tab_item.get("key", ""))))
		tab_row.add_child(tab_btn)
		scene._detail_tab_btns[str(tab_item.get("key", ""))] = tab_btn

	scene._detail_upgrade_tab = VBoxContainer.new()
	scene._detail_upgrade_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_upgrade_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._detail_upgrade_tab.alignment = BoxContainer.ALIGNMENT_END
	scene._detail_upgrade_tab.add_theme_constant_override("separation", 8)
	summary_body.add_child(scene._detail_upgrade_tab)

	var upgrade_spacer := Control.new()
	upgrade_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._detail_upgrade_tab.add_child(upgrade_spacer)

	scene._food_cost_label = Label.new()
	scene._food_cost_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	scene._food_cost_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	scene._detail_upgrade_tab.add_child(scene._food_cost_label)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 8)
	progress_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_upgrade_tab.add_child(progress_row)

	var food_progress_shell := Control.new()
	food_progress_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	food_progress_shell.custom_minimum_size = Vector2(0.0, 36.0)
	progress_row.add_child(food_progress_shell)

	scene._food_progress_bar = ProgressBar.new()
	scene._food_progress_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene._food_progress_bar.show_percentage = false
	food_progress_shell.add_child(scene._food_progress_bar)

	scene._food_progress_label = Label.new()
	scene._food_progress_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene._food_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._food_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene._food_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene._food_progress_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	food_progress_shell.add_child(scene._food_progress_label)

	var reset_btn := Button.new()
	reset_btn.text = UiText.ENHANCE_RESET_BUTTON
	reset_btn.pressed.connect(scene._on_reset_pressed)
	reset_btn.custom_minimum_size = Vector2(108.0, 36.0)
	progress_row.add_child(reset_btn)
	UiPalette.apply_button_kind(reset_btn, "danger")

	var upgrade_row := HBoxContainer.new()
	upgrade_row.add_theme_constant_override("separation", 8)
	upgrade_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_upgrade_tab.add_child(upgrade_row)

	scene._food_upgrade_btn = Button.new()
	scene._food_upgrade_btn.pressed.connect(scene._on_upgrade_one_pressed)
	scene._food_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._food_upgrade_btn.custom_minimum_size = Vector2(0.0, 46.0)
	upgrade_row.add_child(scene._food_upgrade_btn)

	scene._food_max_btn = Button.new()
	scene._food_max_btn.pressed.connect(scene._on_upgrade_max_pressed)
	scene._food_max_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._food_max_btn.custom_minimum_size = Vector2(0.0, 46.0)
	upgrade_row.add_child(scene._food_max_btn)

	UiPalette.apply_button_kind(scene._food_upgrade_btn, "confirm")
	UiPalette.apply_button_kind(scene._food_max_btn, "confirm")

	scene._detail_skill_tab = VBoxContainer.new()
	scene._detail_skill_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_skill_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._detail_skill_tab.alignment = BoxContainer.ALIGNMENT_END
	scene._detail_skill_tab.add_theme_constant_override("separation", 10)
	summary_body.add_child(scene._detail_skill_tab)
	var skill_root: VBoxContainer = scene._detail_panel
	scene._detail_panel = scene._detail_skill_tab
	Refresh.build_skill_section(scene, cat_data, player_cat)
	scene._detail_panel = skill_root

	scene._detail_rank_tab = VBoxContainer.new()
	scene._detail_rank_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_rank_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._detail_rank_tab.alignment = BoxContainer.ALIGNMENT_END
	scene._detail_rank_tab.add_theme_constant_override("separation", 10)
	summary_body.add_child(scene._detail_rank_tab)

	var rank_progress_shell := Control.new()
	rank_progress_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_progress_shell.custom_minimum_size = Vector2(0.0, 36.0)
	var rank_progress_row := HBoxContainer.new()
	rank_progress_row.add_theme_constant_override("separation", 8)
	rank_progress_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_rank_tab.add_child(rank_progress_row)
	rank_progress_row.add_child(rank_progress_shell)

	scene._rank_progress_bar = ProgressBar.new()
	scene._rank_progress_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene._rank_progress_bar.show_percentage = false
	UiPalette.style_exp_progress_bar(scene._rank_progress_bar, "normal")
	rank_progress_shell.add_child(scene._rank_progress_bar)

	scene._rank_progress_label = Label.new()
	scene._rank_progress_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene._rank_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._rank_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene._rank_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene._rank_progress_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	scene._rank_progress_label.add_theme_color_override("font_color", UiPalette.EXP_BAR_TEXT)
	rank_progress_shell.add_child(scene._rank_progress_label)

	var rank_info_btn := Button.new()
	rank_info_btn.text = UiText.ENHANCE_INFO_BUTTON
	rank_info_btn.custom_minimum_size = Vector2(40.0, 36.0)
	rank_info_btn.pressed.connect(Callable(scene, "_show_rank_bonus_info").bind(cat_data, player_cat.rank))
	rank_progress_row.add_child(rank_info_btn)
	UiPalette.apply_button_kind(rank_info_btn, "info")

	scene._rank_upgrade_btn = Button.new()
	scene._rank_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._rank_upgrade_btn.custom_minimum_size = Vector2(0.0, 46.0)
	scene._rank_upgrade_btn.pressed.connect(scene._on_rank_upgrade_pressed)
	scene._detail_rank_tab.add_child(scene._rank_upgrade_btn)
	UiPalette.apply_button_kind(scene._rank_upgrade_btn, "confirm")

	Refresh.refresh_resource_label(scene)
	Refresh.refresh_rank_labels(scene, player_cat)
	Refresh.refresh_food_labels(scene, player_cat)
	refresh_detail_tab_state(scene)

	var stats_panel := _make_card_panel(ART_BORDER)
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._detail_panel.add_child(stats_panel)

	var stats_margin := _make_content_margin(12)
	stats_panel.add_child(stats_margin)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	stats_margin.add_child(stats_vbox)

	var stats_header := HBoxContainer.new()
	stats_header.add_theme_constant_override("separation", 12)
	stats_vbox.add_child(stats_header)

	var stats_title := Label.new()
	stats_title.text = UiText.ENHANCE_STATS_TITLE
	stats_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	stats_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_header.add_child(stats_title)

	scene._special_cost_label = Label.new()
	scene._special_cost_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	scene._special_cost_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	stats_header.add_child(scene._special_cost_label)

	for stat_key: String in ["hp", "atk", "def"]:
		var row_card := PanelContainer.new()
		row_card.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(Color(0.13, 0.12, 0.14, 0.94), OverlaySceneChrome.CARD_BORDER, 12))
		stats_vbox.add_child(row_card)

		var row_margin := _make_content_margin(10)
		row_card.add_child(row_margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row_margin.add_child(row)

		var stat_stack := VBoxContainer.new()
		stat_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_stack.add_theme_constant_override("separation", 4)
		row.add_child(stat_stack)

		var stat_lbl := Label.new()
		stat_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
		stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scene._stat_labels[stat_key] = stat_lbl
		stat_stack.add_child(stat_lbl)

		var plus_btn := Button.new()
		plus_btn.text = UiText.ENHANCE_ADD_POINT_BUTTON
		plus_btn.custom_minimum_size = Vector2(30.0, 30.0)
		plus_btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		plus_btn.pressed.connect(Callable(scene, "_on_special_add_pressed").bind(stat_key))
		scene._special_plus_btns[stat_key] = plus_btn
		row.add_child(plus_btn)

		UiPalette.apply_button_kind(plus_btn, "plus")

	Refresh.refresh_stat_labels(scene, cat_data, player_cat)
	Refresh.refresh_special_cost_label(scene, player_cat)
	Refresh.refresh_special_point_labels(scene, player_cat)
	Refresh.refresh_special_buttons(scene, player_cat)

	var special_action_row := HBoxContainer.new()
	special_action_row.add_theme_constant_override("separation", 8)
	special_action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_vbox.add_child(special_action_row)

	scene._special_apply_btn = Button.new()
	scene._special_apply_btn.text = UiText.ENHANCE_APPLY_SPECIAL_BUTTON
	scene._special_apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._special_apply_btn.custom_minimum_size = Vector2(0.0, 52.0)
	scene._special_apply_btn.pressed.connect(scene._on_apply_special_points_pressed)
	special_action_row.add_child(scene._special_apply_btn)

	scene._special_reset_btn = Button.new()
	scene._special_reset_btn.text = UiText.ENHANCE_RESET_SPECIAL_BUTTON
	scene._special_reset_btn.custom_minimum_size = Vector2(108.0, 52.0)
	scene._special_reset_btn.pressed.connect(scene._on_reset_special_points_pressed)
	special_action_row.add_child(scene._special_reset_btn)

	UiPalette.apply_button_kind(scene._special_apply_btn, "primary")
	UiPalette.apply_button_kind(scene._special_reset_btn, "danger")
	Refresh.refresh_special_buttons(scene, player_cat)


static func open_selected_cat_dialog(scene) -> void:
	close_selected_cat_dialog(scene)

	var detail_scroll: ScrollContainer = ScrollContainer.new()
	detail_scroll.custom_minimum_size = Vector2(DETAIL_DIALOG_CONTENT_W, 780.0)
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var detail_margin: MarginContainer = _make_content_margin(4)
	detail_margin.custom_minimum_size = Vector2(DETAIL_DIALOG_CONTENT_W, 0.0)
	detail_scroll.add_child(detail_margin)

	var detail_root: VBoxContainer = VBoxContainer.new()
	detail_root.custom_minimum_size = Vector2(DETAIL_DIALOG_CONTENT_W - 8.0, 0.0)
	detail_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_root.add_theme_constant_override("separation", 12)
	detail_margin.add_child(detail_root)

	scene._detail_dialog_scroll = detail_scroll
	scene._detail_dialog_scroller = InertialScroller.attach(detail_scroll, "vertical")
	scene._detail_panel = detail_root
	rebuild_detail_panel(scene)

	var dialog_title: String = Refresh.get_display_name(scene._selected_cat_id)
	scene._detail_dialog_close = DialogManager.show_info_node(
		dialog_title,
		detail_scroll,
		Callable(scene, "_on_detail_dialog_closed"),
		"large"
	)


static func close_selected_cat_dialog(scene) -> void:
	if scene._detail_dialog_close.is_valid():
		scene._detail_dialog_close.call()
	on_detail_dialog_closed(scene)


static func on_detail_dialog_closed(scene) -> void:
	scene._detail_dialog_close = Callable()
	scene._detail_dialog_scroll = null
	scene._detail_dialog_scroller = null
	scene._detail_panel = null
	scene._stat_labels.clear()
	scene._special_point_labels.clear()
	scene._special_plus_btns.clear()
	scene._special_minus_btns.clear()
	scene._special_apply_btn = null
	scene._special_reset_btn = null
	scene._rank_stars_label = null
	scene._rank_progress_bar = null
	scene._rank_progress_label = null
	scene._rank_upgrade_btn = null
	scene._food_upgrade_btn = null
	scene._food_max_btn = null
	scene._food_level_label = null
	scene._food_progress_bar = null
	scene._food_progress_label = null
	scene._detail_resource_label = null
	scene._detail_tab_btns.clear()
	scene._detail_upgrade_tab = null
	scene._detail_skill_tab = null
	scene._detail_rank_tab = null
	scene._cat_name_label = null
	scene._food_cost_label = null
	scene._special_cost_label = null


static func _make_cat_card(scene, cat_id: String, player_cat: PlayerCatData, is_selected: bool) -> PanelContainer:
	var cat_icon: Texture2D = AssetResolver.resolve_cat_icon(cat_id)
	var cat_data: CatData = CatData.from_json_file(cat_id + ".json")
	var select_button_bg: Color = Color(0.27, 0.29, 0.21, 0.96) if is_selected else UiPalette.BUTTON_PRIMARY_BG
	var select_button_fg: Color = Color(0.88, 0.90, 0.74, 1.0) if is_selected else Color(0.16, 0.11, 0.05, 1.0)
	return CatRosterCard.build({
		"is_selected": is_selected,
		"template_key": "enhance_list",
		"title_text": Refresh.get_display_name(cat_id),
		"icon_texture": cat_icon,
		"fallback_text": Refresh.get_display_name(cat_id).substr(0, 1),
		"level_value": player_cat.cat_food_level,
		"rank_value": player_cat.rank,
		"cat_type": cat_data.cat_type if cat_data != null else "base",
		"rarity_key": cat_data.rarity if cat_data != null else "common",
		"whole_card_pressed": Callable(scene, "_on_cat_button_pressed").bind(cat_id),
		"card_height": 232.0,
		"icon_size": Vector2(110.0, 110.0),
		"card_border": OverlaySceneChrome.CARD_BORDER,
		"selected_card_border": OverlaySceneChrome.PANEL_BORDER,
		"title_color": Color(0.42, 0.28, 0.15, 1.0),
		"button_bg": select_button_bg,
		"button_fg": select_button_fg,
	})


static func _make_idle_preview(cat_id: String, preview_size: Vector2) -> Control:
	var idle_path: String = AssetResolver.resolve_cat_battle_animation_path(cat_id, "idle")
	var idle_texture: Texture2D = AssetResolver.load_texture(idle_path)
	if idle_texture == null:
		var fallback := Control.new()
		var cat_icon: Texture2D = AssetResolver.resolve_cat_icon(cat_id)
		if cat_icon != null:
			fallback.add_child(AssetResolver.create_icon_rect(cat_icon, preview_size))
		return fallback

	var animation_spec: Dictionary = AssetResolver.resolve_cat_battle_animation_spec(cat_id, "idle")
	var frame_width: int = int(animation_spec.get("frame_width", 275))
	var fps: float = float(animation_spec.get("fps", 8.0))
	var sheet_width: int = idle_texture.get_width()
	var sheet_height: int = idle_texture.get_height()
	var frame_count: int = maxi(1, int(sheet_width / max(1, frame_width)))

	var source_image: Image = idle_texture.get_image()
	var frames: Array[Texture2D] = []
	for frame_index: int in range(frame_count):
		var frame_image: Image = source_image.get_region(Rect2i(frame_index * frame_width, 0, frame_width, sheet_height))
		var frame_texture: ImageTexture = ImageTexture.create_from_image(frame_image)
		frames.append(frame_texture)

	var holder := IdlePreviewPlayer.new()
	holder.setup(preview_size, frames, fps)
	return holder


static func _make_card_panel(accent: Color = OverlaySceneChrome.CARD_BORDER) -> PanelContainer:
	return OverlaySceneChrome.make_card_panel(accent)


static func refresh_detail_tab_state(scene) -> void:
	for tab_key: String in scene._detail_tab_btns.keys():
		var tab_btn: Button = scene._detail_tab_btns[tab_key]
		var is_active: bool = tab_key == scene._detail_tab
		UiPalette.apply_button_palette(
			tab_btn,
			DETAIL_TAB_ACTIVE_FILL if is_active else DETAIL_TAB_FILL,
			SceneMenuTheme.ACTIVE_COLOR if is_active else SceneMenuTheme.INACTIVE_COLOR
		)

	if scene._detail_upgrade_tab != null:
		scene._detail_upgrade_tab.visible = scene._detail_tab == "upgrade"
	if scene._detail_skill_tab != null:
		scene._detail_skill_tab.visible = scene._detail_tab == "skill"
	if scene._detail_rank_tab != null:
		scene._detail_rank_tab.visible = scene._detail_tab == "rank"


static func _make_meta_chip(text: String, is_selected: bool) -> PanelContainer:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.97, 0.86, 1.0) if is_selected else SLOT_NAME_COLOR
	)
	return _make_info_chip(
		label,
		Color(0.42, 0.29, 0.14, 0.98) if is_selected else Color(0.20, 0.16, 0.18, 0.92),
		Color(0.98, 0.83, 0.48, 1.0) if is_selected else OverlaySceneChrome.CARD_BORDER
	)


static func _make_info_chip(content: Control, fill: Color, border: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(fill, border, 12))
	var margin := _make_content_margin(8)
	chip.add_child(margin)
	margin.add_child(content)
	return chip


static func _make_content_margin(value: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_bottom", value)
	return margin
