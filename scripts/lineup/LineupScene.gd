extends Control

const Constants = preload("res://scripts/lineup/LineupConstants.gd")
const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const CatRosterCard = preload("res://scripts/ui/cat_roster_card.gd")

const DANGER_BUTTON_COLOR := Color(0.94, 0.48, 0.42, 1.0)
const MUTED_TEXT_COLOR := Color(0.90, 0.88, 0.82, 0.92)
const DISABLED_TEXT_COLOR := Color(0.70, 0.70, 0.72, 0.92)
const EMPTY_SLOT_TEXT_COLOR := Color(0.75, 0.70, 0.62, 0.9)
const SLOT_IMAGE_BG := Color(0.24, 0.20, 0.16, 0.96)
const SLOT_IMAGE_BORDER := Color(0.98, 0.84, 0.54, 0.95)
const SLOT_DELAY_BG := Color(0.18, 0.12, 0.08, 0.94)
const SLOT_HOLD_SECONDS := 0.4
const SLOT_EMPTY_FILL := Color(0.20, 0.18, 0.16, 0.88)
const SLOT_EMPTY_BORDER := Color(0.62, 0.54, 0.40, 0.78)
const SLOT_NAME_COLOR := Color(0.98, 0.95, 0.88, 1.0)
const SLOT_META_COLOR := Color(0.88, 0.80, 0.67, 0.92)
const SLOT_REMOVE_BG := Color(0.56, 0.18, 0.18, 0.96)
const CAT_CARD_HOLD_SECONDS := 2.0

var _current_team_type: String = "boss"
var _api_in_flight: bool = false

var _team_type_btns: Dictionary = {}
var _page_title: Label
var _team_summary_label: Label
var _team_container: GridContainer
var _cats_title: Label
var _cats_sort_btns: Dictionary = {}
var _cats_scroll: ScrollContainer
var _cats_container: GridContainer
var _save_team_btn: Button
var _cats_scroller: InertialScroller

var _team_drafts: Dictionary = {}
var _team_dirty: Dictionary = {}
var _cats_sort_mode: String = "level"


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg: Control = AssetResolver.make_fullscreen_background("config")
	add_child(bg)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.05, 0.34)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var content_panel: PanelContainer = PanelContainer.new()
	content_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_panel.offset_left = 20.0
	content_panel.offset_top = OverlaySceneChrome.CONTENT_TOP_GAP
	content_panel.offset_right = -20.0
	content_panel.offset_bottom = -(OverlaySceneChrome.HOME_MAIN_NAV_H + OverlaySceneChrome.BOTTOM_DOCK_H + 12.0)
	content_panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(OverlaySceneChrome.PANEL_FILL, OverlaySceneChrome.PANEL_BORDER, 18))
	add_child(content_panel)

	var content_margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	content_panel.add_child(content_margin)

	var content_vbox: VBoxContainer = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 14)
	content_margin.add_child(content_vbox)

	_page_title = Label.new()
	_page_title.text = UiText.CONFIG_PAGE_TITLE
	_page_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	content_vbox.add_child(_page_title)

	var page_desc: Label = Label.new()
	page_desc.text = UiText.CONFIG_PAGE_DESC
	page_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	page_desc.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	content_vbox.add_child(page_desc)

	var main_split: VBoxContainer = VBoxContainer.new()
	main_split.add_theme_constant_override("separation", 12)
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(main_split)

	var team_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	team_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_panel.size_flags_vertical = 0
	main_split.add_child(team_panel)

	var team_margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	team_panel.add_child(team_margin)

	var team_vbox: VBoxContainer = VBoxContainer.new()
	team_vbox.add_theme_constant_override("separation", 10)
	team_vbox.size_flags_vertical = 0
	team_margin.add_child(team_vbox)

	_team_summary_label = Label.new()
	_team_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_team_summary_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	_team_summary_label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	_team_summary_label.visible = false
	team_vbox.add_child(_team_summary_label)

	_team_container = GridContainer.new()
	_team_container.columns = 5
	_team_container.add_theme_constant_override("separation", 6)
	_team_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_team_container.size_flags_vertical = 0
	team_vbox.add_child(_team_container)

	_save_team_btn = Button.new()
	_save_team_btn.text = UiText.CONFIG_SAVE_BUTTON
	_save_team_btn.custom_minimum_size = Vector2(0.0, 52.0)
	_save_team_btn.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	_save_team_btn.pressed.connect(_on_save_team_pressed)
	UiPalette.apply_button_kind(_save_team_btn, "confirm")
	team_vbox.add_child(_save_team_btn)

	var cats_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	cats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cats_panel.size_flags_stretch_ratio = 1.05
	main_split.add_child(cats_panel)

	var cats_margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	cats_panel.add_child(cats_margin)

	var cats_vbox: VBoxContainer = VBoxContainer.new()
	cats_vbox.add_theme_constant_override("separation", 10)
	cats_margin.add_child(cats_vbox)

	var cats_header: HBoxContainer = HBoxContainer.new()
	cats_header.add_theme_constant_override("separation", 8)
	cats_vbox.add_child(cats_header)

	_cats_title = Label.new()
	_cats_title.text = UiText.CONFIG_OWNED_CATS_TITLE
	_cats_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	_cats_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cats_header.add_child(_cats_title)

	var sort_row: HBoxContainer = HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 6)
	cats_header.add_child(sort_row)

	for sort_key: String in ["level", "rank"]:
		var sort_btn: Button = Button.new()
		sort_btn.text = UiText.CONFIG_SORT_LEVEL if sort_key == "level" else UiText.CONFIG_SORT_RANK
		sort_btn.custom_minimum_size = Vector2(64.0, 28.0)
		sort_btn.add_theme_font_size_override("font_size", 13)
		sort_btn.pressed.connect(func() -> void:
			_set_cats_sort_mode(sort_key)
		)
		sort_row.add_child(sort_btn)
		_cats_sort_btns[sort_key] = sort_btn

	_cats_scroll = ScrollContainer.new()
	_cats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cats_vbox.add_child(_cats_scroll)

	_cats_container = GridContainer.new()
	_cats_container.columns = 3
	_cats_container.add_theme_constant_override("separation", 12)
	_cats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cats_scroll.add_child(_cats_container)
	_cats_scroller = InertialScroller.attach(_cats_scroll, "vertical")

	var submenu_items: Array = []
	for type_key: String in ["boss", "dungeon", "arena_attack", "arena_defense"]:
		submenu_items.append({
			"key": type_key,
			"label": str(Constants.TEAM_LABELS[type_key]),
		})
	var submenu: Dictionary = SceneSubmenuBar.build(self, {
		"items": submenu_items,
		"active_key": _current_team_type,
		"back_label": UiText.CONFIG_BACK,
		"back_pressed": Callable(self, "_on_back_pressed"),
		"button_pressed": Callable(self, "_switch_team_type"),
		"panel_fill": OverlaySceneChrome.PANEL_FILL,
		"panel_border": OverlaySceneChrome.PANEL_BORDER,
		"top": -(OverlaySceneChrome.HOME_MAIN_NAV_H + OverlaySceneChrome.BOTTOM_DOCK_H),
		"bottom": -OverlaySceneChrome.HOME_MAIN_NAV_H,
	})
	_team_type_btns = submenu.get("buttons", {})

	_switch_team_type("boss")


func _switch_team_type(type_key: String) -> void:
	_ensure_team_draft(type_key)
	_current_team_type = type_key

	SceneSubmenuBar.refresh(_team_type_btns, type_key, {
		"active_color": SceneMenuTheme.ACTIVE_COLOR,
		"inactive_color": SceneMenuTheme.INACTIVE_COLOR,
	})

	_refresh_team()
	_refresh_cats_list()
	_update_team_title()
	_update_save_section()
	_refresh_cats_sort_buttons()


func _get_team_type_key(type_key: String = "") -> String:
	if type_key == "":
		type_key = _current_team_type
	return str(Constants.TEAM_TYPE_MAP.get(type_key, "Boss"))


func _get_editing_team_members() -> Array:
	_ensure_team_draft(_current_team_type)
	var team: Dictionary = _team_drafts[_current_team_type]
	return team.get("members", [])


func _get_filled_editing_team_members() -> Array:
	var filled: Array = []
	for member_variant: Variant in _get_editing_team_members():
		if member_variant is Dictionary and not (member_variant as Dictionary).is_empty():
			filled.append(member_variant)
	return filled


func _ensure_team_draft(type_key: String) -> void:
	if _team_drafts.has(type_key):
		return
	_reset_team_draft(type_key, GameState.get_team(_get_team_type_key(type_key)))


func _reset_team_draft(type_key: String, source_team: Dictionary) -> void:
	var draft: Dictionary = source_team.duplicate(true)
	draft["teamType"] = _get_team_type_key(type_key)
	draft["members"] = _normalize_members(draft.get("members", []), type_key)
	_team_drafts[type_key] = draft
	_team_dirty[type_key] = false


func _normalize_members(members: Array, type_key: String = "") -> Array:
	if type_key == "":
		type_key = _current_team_type
	var max_count: int = _get_max_team_size_for(type_key)
	var normalized: Array = []
	normalized.resize(max_count)
	for index: int in range(max_count):
		normalized[index] = {}

	for member_variant: Variant in members:
		if member_variant is Dictionary and (member_variant as Dictionary).is_empty():
			continue
		if not (member_variant is Dictionary):
			continue

		var member: Dictionary = (member_variant as Dictionary).duplicate(true)
		var slot_no: int = int(member.get("slotNo", -1))
		if slot_no < 0 or slot_no >= max_count:
			slot_no = _find_first_empty_slot_index(normalized)
			if slot_no < 0:
				continue

		member["slotNo"] = slot_no
		member["initialDelaySeconds"] = float(member.get("initialDelaySeconds", 0.0))
		normalized[slot_no] = member
	return normalized


func _find_first_empty_slot_index(members: Array) -> int:
	for index: int in range(members.size()):
		var slot_variant: Variant = members[index]
		if slot_variant is Dictionary and (slot_variant as Dictionary).is_empty():
			return index
	return -1


func _get_max_team_size_for(type_key: String) -> int:
	match type_key:
		"boss":
			return int(GameState.boss_config.get("max_team_size", 5))
		"dungeon":
			return int(GameState.dungeon_config.get("max_team_size", 5))
		"arena_attack", "arena_defense":
			return int(GameState.arena_config.get("max_team_size", 5))
	return 5


func _is_current_team_dirty() -> bool:
	return bool(_team_dirty.get(_current_team_type, false))


func _mark_current_team_dirty() -> void:
	_team_dirty[_current_team_type] = true
	_update_save_section()


func _update_team_title() -> void:
	var mode_label: String = str(Constants.TEAM_LABELS.get(_current_team_type, _current_team_type))
	var members: Array = _get_filled_editing_team_members()
	var max_count: int = _get_max_team_size()
	var title_text: String = UiText.CONFIG_TEAM_TITLE_FORMAT % [mode_label, members.size(), max_count]
	_page_title.text = title_text

	_team_summary_label.text = UiText.CONFIG_TEAM_SUMMARY_WITH_DELAY


func _refresh_team() -> void:
	for child: Node in _team_container.get_children():
		child.queue_free()

	var members: Array = _get_editing_team_members()
	var max_count: int = _get_max_team_size()
	_team_container.columns = maxi(1, max_count)
	for i: int in range(max_count):
		var member: Dictionary = members[i] if i < members.size() else {}
		_team_container.add_child(_make_team_slot_card(i, member))

	_update_team_title()
	_update_save_section()


func _make_team_slot_card(slot_index: int, member: Dictionary) -> PanelContainer:
	var is_filled: bool = not member.is_empty()
	var card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER if is_filled else SLOT_EMPTY_BORDER)
	card.custom_minimum_size = Vector2(0.0, 166.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(4)
	card.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var cat_name: String = str(member.get("catDisplayName", "")) if is_filled else UiText.CONFIG_EMPTY_SLOT
	var cat_catalog_id: int = int(member.get("catCatalogId", 0)) if is_filled else 0
	var delay_seconds: float = float(member.get("initialDelaySeconds", 0.0)) if is_filled else 0.0
	var cat_file_id: String = GameState.get_cat_file_id_by_catalog_id(cat_catalog_id) if is_filled else ""

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 4)
	column.add_child(top_row)

	var slot_badge: Label = Label.new()
	slot_badge.text = UiText.CONFIG_SLOT_BADGE_FORMAT % [slot_index + 1]
	slot_badge.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
	slot_badge.add_theme_color_override("font_color", Color(0.98, 0.90, 0.72, 1.0))
	top_row.add_child(slot_badge)

	var top_name: Label = Label.new()
	top_name.text = cat_name if is_filled else UiText.CONFIG_TEAM_SLOT_EMPTY_NAME
	top_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_name.clip_text = true
	top_name.add_theme_font_size_override("font_size", 17)
	top_name.add_theme_color_override("font_color", SLOT_NAME_COLOR if is_filled else EMPTY_SLOT_TEXT_COLOR)
	top_row.add_child(top_name)

	var image_shell: PanelContainer = PanelContainer.new()
	image_shell.custom_minimum_size = Vector2(0.0, 96.0)
	image_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_shell.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(SLOT_IMAGE_BG if is_filled else SLOT_EMPTY_FILL, SLOT_IMAGE_BORDER if is_filled else SLOT_EMPTY_BORDER, 14))
	image_shell.mouse_filter = Control.MOUSE_FILTER_STOP
	column.add_child(image_shell)

	var image_button: Button = Button.new()
	image_button.flat = true
	image_button.text = UiText.CONFIG_EMPTY_SLOT_ICON if not is_filled else ""
	image_button.custom_minimum_size = Vector2(0.0, 96.0)
	image_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_button.clip_text = true
	image_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	image_button.add_theme_color_override("font_color", EMPTY_SLOT_TEXT_COLOR)
	image_shell.add_child(image_button)

	var overlay_root: Control = Control.new()
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_shell.add_child(overlay_root)

	var image_margin: MarginContainer = OverlaySceneChrome.make_content_margin(4)
	image_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_root.add_child(image_margin)

	var icon_holder: CenterContainer = CenterContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_margin.add_child(icon_holder)

	var team_icon: Texture2D = AssetResolver.resolve_cat_showcase_art(cat_file_id)
	if team_icon != null:
		icon_holder.add_child(AssetResolver.create_icon_rect(team_icon, Vector2(72.0, 72.0)))
	elif is_filled:
		var fallback_name: Label = Label.new()
		fallback_name.text = _get_cat_visual_fallback(cat_name)
		fallback_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback_name.add_theme_font_size_override("font_size", 30)
		fallback_name.add_theme_color_override("font_color", SLOT_NAME_COLOR)
		icon_holder.add_child(fallback_name)

	if is_filled:
		var remove_btn: Button = Button.new()
		remove_btn.text = "－"
		remove_btn.custom_minimum_size = Vector2(22.0, 22.0)
		remove_btn.add_theme_font_size_override("font_size", 11)
		remove_btn.add_theme_color_override("font_color", Color(1.0, 0.97, 0.95, 1.0))
		remove_btn.anchor_left = 1.0
		remove_btn.anchor_top = 0.0
		remove_btn.anchor_right = 1.0
		remove_btn.anchor_bottom = 0.0
		remove_btn.offset_left = -20.0
		remove_btn.offset_top = -10.0
		remove_btn.offset_right = 2.0
		remove_btn.offset_bottom = 12.0
		remove_btn.disabled = _api_in_flight
		var remove_style: StyleBoxFlat = StyleBoxFlat.new()
		remove_style.bg_color = SLOT_REMOVE_BG
		remove_style.corner_radius_top_left = 999
		remove_style.corner_radius_top_right = 999
		remove_style.corner_radius_bottom_left = 999
		remove_style.corner_radius_bottom_right = 999
		remove_style.border_width_left = 1
		remove_style.border_width_right = 1
		remove_style.border_width_top = 1
		remove_style.border_width_bottom = 1
		remove_style.border_color = Color(1.0, 0.82, 0.78, 0.95)
		remove_btn.add_theme_stylebox_override("normal", remove_style)
		var remove_hover: StyleBoxFlat = remove_style.duplicate()
		remove_hover.bg_color = SLOT_REMOVE_BG.lightened(0.08)
		var remove_pressed: StyleBoxFlat = remove_style.duplicate()
		remove_pressed.bg_color = SLOT_REMOVE_BG.darkened(0.08)
		remove_btn.add_theme_stylebox_override("hover", remove_hover)
		remove_btn.add_theme_stylebox_override("pressed", remove_pressed)
		if not _api_in_flight:
			remove_btn.pressed.connect(func() -> void:
				_remove_member_from_draft(slot_index)
			)
		overlay_root.add_child(remove_btn)

	image_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_filled and cat_file_id != "":
		image_shell.gui_input.connect(func(event: InputEvent) -> void:
			if not (event is InputEventMouseButton):
				return
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
				return
			_show_skill_popup(cat_file_id)
			image_shell.accept_event()
		)
	else:
		image_button.disabled = true

	var delay_button: Button = Button.new()
	delay_button.text = UiText.CONFIG_DELAY_BUTTON_FORMAT % [_format_delay_label(delay_seconds)] if is_filled else UiText.CONFIG_DELAY_BUTTON_EMPTY
	delay_button.custom_minimum_size = Vector2(0.0, 24.0)
	delay_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delay_button.add_theme_font_size_override("font_size", 13)
	delay_button.disabled = not is_filled or _api_in_flight
	UiPalette.apply_button_palette(delay_button, SLOT_DELAY_BG, Color(0.98, 0.90, 0.72, 1.0))
	if is_filled and not _api_in_flight:
		delay_button.pressed.connect(func() -> void:
			_update_member_delay_in_draft(slot_index, _get_next_delay_value(delay_seconds))
		)
	column.add_child(delay_button)

	return card


func _refresh_cats_list() -> void:
	for child: Node in _cats_container.get_children():
		child.queue_free()

	var in_team_ids: Array = _get_editing_team_members().map(func(member: Dictionary) -> int:
		return int(member.get("playerCatId", 0))
	)
	in_team_ids = in_team_ids.filter(func(id: int) -> bool:
		return id > 0
	)
	var owned_cats: Array = _get_sorted_owned_cats()
	for cat_variant: Variant in owned_cats:
		if cat_variant is Dictionary:
			_cats_container.add_child(_make_cat_card(cat_variant as Dictionary, in_team_ids))


func _make_cat_card(cat: Dictionary, in_team_ids: Array) -> PanelContainer:
	var player_cat_id: int = int(cat.get("playerCatId", 0))
	var display_name: String = str(cat.get("displayName", ""))
	var lv: int = int(cat.get("catFoodLevel", 1))
	var rank: int = int(cat.get("rank", 0))
	var cat_catalog_id: int = int(cat.get("catCatalogId", 0))
	var already_in: bool = player_cat_id in in_team_ids
	var team_full: bool = _get_filled_editing_team_members().size() >= _get_max_team_size()
	var action_disabled: bool = (not already_in and team_full) or _api_in_flight

	var local_cat_id: String = GameState.get_cat_file_id_by_catalog_id(cat_catalog_id)
	var cat_icon: Texture2D = AssetResolver.resolve_cat_showcase_art(local_cat_id)
	var hold_timer: Timer = Timer.new()
	hold_timer.one_shot = true
	hold_timer.wait_time = CAT_CARD_HOLD_SECONDS
	var pointer_down: Array[bool] = [false]
	var long_press_triggered: Array[bool] = [false]
	hold_timer.timeout.connect(func() -> void:
		if not pointer_down[0]:
			return
		if local_cat_id == "":
			return
		if _cats_scroller != null and _cats_scroller.consume_moved():
			return
		long_press_triggered[0] = true
		_show_skill_popup(local_cat_id)
	)

	var whole_card_gui_input: Callable = func(event: InputEvent) -> void:
		if not (event is InputEventMouseButton):
			return
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			pointer_down[0] = true
			long_press_triggered[0] = false
			if local_cat_id != "":
				hold_timer.start()
			return

		var was_pressed: bool = pointer_down[0]
		pointer_down[0] = false
		hold_timer.stop()
		if not was_pressed:
			return
		if _cats_scroller != null and _cats_scroller.consume_moved():
			return
		if long_press_triggered[0]:
			long_press_triggered[0] = false
			return
		if action_disabled:
			return
		_toggle_member_in_draft(player_cat_id)

	var card: PanelContainer = CatRosterCard.build({
		"is_selected": already_in,
		"title_text": display_name,
		"show_title": false,
		"icon_texture": cat_icon,
		"fallback_text": _get_cat_visual_fallback(display_name),
		"chips": [
			UiText.CONFIG_CAT_LEVEL_ONLY_FORMAT % [lv],
			UiText.CONFIG_CAT_STARS_FORMAT % [rank],
		],
		"show_action": false,
		"whole_card_gui_input": whole_card_gui_input,
		"card_height": 228.0,
		"art_height": 108.0,
		"icon_size": Vector2(84.0, 84.0),
		"card_fill": OverlaySceneChrome.CARD_FILL,
		"card_border": OverlaySceneChrome.CARD_BORDER,
		"selected_card_border": OverlaySceneChrome.PANEL_BORDER,
		"selected_card_fill": Color(0.24, 0.20, 0.13, 0.98),
		"art_fill": Color(0.19, 0.17, 0.15, 0.96),
		"art_border": Color(0.90, 0.77, 0.46, 0.88),
		"selected_art_border": Color(0.90, 0.77, 0.46, 0.88),
		"selected_art_fill": Color(0.26, 0.21, 0.14, 0.98),
		"title_color": SLOT_NAME_COLOR,
		"selected_chip_fill": Color(0.42, 0.29, 0.14, 0.98),
		"selected_chip_border": Color(0.98, 0.83, 0.48, 1.0),
		"selected_chip_text_color": Color(1.0, 0.97, 0.86, 1.0),
	})
	card.add_child(hold_timer)
	return card


func _set_cats_sort_mode(sort_mode: String) -> void:
	if _cats_sort_mode == sort_mode:
		return
	_cats_sort_mode = sort_mode
	_refresh_cats_sort_buttons()
	_refresh_cats_list()


func _refresh_cats_sort_buttons() -> void:
	for key: String in _cats_sort_btns.keys():
		var button: Button = _cats_sort_btns[key]
		var is_active: bool = key == _cats_sort_mode
		if is_active:
			UiPalette.apply_button_palette(button, Color(0.58, 0.48, 0.26, 0.88), Color(0.97, 0.93, 0.84, 1.0))
		else:
			UiPalette.apply_button_palette(button, Color(0.20, 0.18, 0.17, 0.88), Color(0.62, 0.58, 0.54, 1.0))


func _get_sorted_owned_cats() -> Array:
	var owned_cats: Array = GameState.get_config_owned_cats().duplicate(true)
	owned_cats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if _cats_sort_mode == "rank":
			var a_rank: int = int(a.get("rank", 0))
			var b_rank: int = int(b.get("rank", 0))
			if a_rank != b_rank:
				return a_rank > b_rank
			var a_level: int = int(a.get("catFoodLevel", 1))
			var b_level: int = int(b.get("catFoodLevel", 1))
			if a_level != b_level:
				return a_level > b_level
			return int(a.get("playerCatId", 0)) < int(b.get("playerCatId", 0))

		var a_level_default: int = int(a.get("catFoodLevel", 1))
		var b_level_default: int = int(b.get("catFoodLevel", 1))
		if a_level_default != b_level_default:
			return a_level_default > b_level_default
		var a_rank_default: int = int(a.get("rank", 0))
		var b_rank_default: int = int(b.get("rank", 0))
		if a_rank_default != b_rank_default:
			return a_rank_default > b_rank_default
		return int(a.get("playerCatId", 0)) < int(b.get("playerCatId", 0))
	)
	return owned_cats


func _build_member_from_player_cat(player_cat_id: int) -> Dictionary:
	for cat_variant: Variant in GameState.get_config_owned_cats():
		if not (cat_variant is Dictionary):
			continue

		var cat: Dictionary = cat_variant as Dictionary
		if int(cat.get("playerCatId", 0)) != player_cat_id:
			continue

		return {
			"slotNo": 0,
			"playerCatId": player_cat_id,
			"catCatalogId": int(cat.get("catCatalogId", 0)),
			"catDisplayName": str(cat.get("displayName", "")),
			"catFoodLevel": int(cat.get("catFoodLevel", 1)),
			"rank": int(cat.get("rank", 0)),
			"initialDelaySeconds": 0.0,
		}

	return {}


func _draft_has_player_cat(members: Array, player_cat_id: int) -> bool:
	for member_variant: Variant in members:
		if member_variant is Dictionary:
			var member: Dictionary = member_variant
			if int(member.get("playerCatId", 0)) == player_cat_id:
				return true
	return false


func _find_member_slot_no_by_player_cat_id(player_cat_id: int) -> int:
	for member_variant: Variant in _get_editing_team_members():
		if not (member_variant is Dictionary):
			continue
		var member: Dictionary = member_variant as Dictionary
		if member.is_empty():
			continue
		if int(member.get("playerCatId", 0)) == player_cat_id:
			return int(member.get("slotNo", -1))
	return -1


func _toggle_member_in_draft(player_cat_id: int) -> void:
	if _api_in_flight:
		return

	var slot_no: int = _find_member_slot_no_by_player_cat_id(player_cat_id)
	if slot_no >= 0:
		_remove_member_from_draft(slot_no)
		return

	_add_member_to_draft(player_cat_id)


func _add_member_to_draft(player_cat_id: int) -> void:
	if _api_in_flight:
		return

	var members: Array = _get_editing_team_members().duplicate(true)
	if _get_filled_editing_team_members().size() >= _get_max_team_size():
		return
	if _draft_has_player_cat(members, player_cat_id):
		return

	var new_member: Dictionary = _build_member_from_player_cat(player_cat_id)
	if new_member.is_empty():
		return

	var target_index: int = -1
	for index: int in range(members.size()):
		var slot_variant: Variant = members[index]
		if slot_variant is Dictionary and (slot_variant as Dictionary).is_empty():
			target_index = index
			break

	if target_index >= 0:
		new_member["slotNo"] = target_index
		members[target_index] = new_member
	else:
		new_member["slotNo"] = members.size()
		members.append(new_member)

	_team_drafts[_current_team_type]["members"] = _normalize_members(members)
	_mark_current_team_dirty()
	_refresh_team()
	_refresh_cats_list()


func _remove_member_from_draft(slot_no: int) -> void:
	if _api_in_flight:
		return

	var members: Array = _get_editing_team_members().duplicate(true)
	if slot_no < 0 or slot_no >= members.size():
		return

	members[slot_no] = {}
	_team_drafts[_current_team_type]["members"] = _normalize_members(members)
	_mark_current_team_dirty()
	_refresh_team()
	_refresh_cats_list()


func _update_member_delay_in_draft(slot_no: int, delay_seconds: float) -> void:
	if _api_in_flight:
		return

	var members: Array = _get_editing_team_members().duplicate(true)
	if slot_no < 0 or slot_no >= members.size():
		return

	var member: Dictionary = members[slot_no]
	member["initialDelaySeconds"] = maxf(0.0, delay_seconds)
	members[slot_no] = member
	_team_drafts[_current_team_type]["members"] = _normalize_members(members)
	_mark_current_team_dirty()
	_refresh_team()


func _update_save_section() -> void:
	var dirty: bool = _is_current_team_dirty()
	_save_team_btn.disabled = _api_in_flight or not dirty
	if dirty and not _api_in_flight:
		UiPalette.apply_button_kind(_save_team_btn, "confirm")
	else:
		UiPalette.apply_button_palette(_save_team_btn, Color(0.24, 0.21, 0.18, 0.86), Color(0.72, 0.69, 0.64, 1.0))


func _on_save_team_pressed() -> void:
	if _api_in_flight or not _is_current_team_dirty():
		return

	var request_members: Array = []
	for member: Dictionary in _get_editing_team_members():
		if member.is_empty():
			continue
		request_members.append({
			"slotNo": int(member.get("slotNo", 0)),
			"playerCatId": int(member.get("playerCatId", 0)),
			"initialDelaySeconds": float(member.get("initialDelaySeconds", 0.0)),
		})

	_api_in_flight = true
	_update_save_section()
	_refresh_team()
	_refresh_cats_list()

	ApiClient.replace_team(_current_team_type, request_members, func(success: bool, data: Variant, error: Dictionary) -> void:
		_api_in_flight = false
		if not success:
			ToastManager.error(UiText.CONFIG_SAVE_FAILED_TITLE, str(error.get("message", UiText.CONFIG_UNKNOWN_ERROR)))
			_refresh_team()
			_refresh_cats_list()
			return

		if data is Dictionary:
			var team_response: Dictionary = data as Dictionary
			_apply_team_update(team_response)
			var saved_type_key: String = _team_scene_type_to_key(str(team_response.get("teamType", "")))
			if saved_type_key != "":
				_reset_team_draft(saved_type_key, team_response)
				_restart_home_battle_if_needed(saved_type_key)

		_refresh_team()
		_refresh_cats_list()
		ToastManager.success(UiText.CONFIG_SAVE_HINT_CLEAN)
	)


func _team_scene_type_to_key(team_type: String) -> String:
	for key: String in Constants.TEAM_TYPE_MAP.keys():
		if str(Constants.TEAM_TYPE_MAP[key]) == team_type:
			return key
	return ""


func _apply_team_update(team_response: Dictionary) -> void:
	var type_str: String = str(team_response.get("teamType", ""))
	if type_str == "":
		return

	GameState.teams_data[type_str] = team_response
	GameState._save_config_cache("teams", GameState.teams_data.values())

	if type_str == "Boss":
		GameState.apply_active_team_from_config("Boss")


func _restart_home_battle_if_needed(type_key: String) -> void:
	if type_key != "boss":
		return
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	if battle_scene != null and battle_scene.has_method("restart_with_latest_team"):
		battle_scene.call_deferred("restart_with_latest_team")


func _show_skill_popup(cat_file_id: String) -> void:
	var cat_data: Variant = CatData.from_json_file(cat_file_id + ".json")
	if cat_data == null:
		return

	var lines: Array = [str(cat_data.display_name) + UiText.CONFIG_SKILL_DIALOG_SUFFIX]

	for sid: String in cat_data.passive_skill_ids:
		var passive_skill: Dictionary = CatData._read_skill_json(sid)
		if passive_skill.is_empty():
			continue
		lines.append(UiText.CONFIG_SKILL_PASSIVE_FORMAT % passive_skill.get("display_name", sid))
		lines.append("  " + str(passive_skill.get("description", "")))

	for active_skill: Dictionary in cat_data.active_skills_data:
		lines.append(UiText.CONFIG_SKILL_ACTIVE_FORMAT % [
			active_skill.get("display_name", ""),
			float(active_skill.get("cooldown", 0.0)),
		])
		lines.append("  " + str(active_skill.get("description", "")))

	DialogManager.show_info(UiText.CONFIG_SKILL_DIALOG_TITLE, "\n".join(lines))


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _make_chip_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = OverlaySceneChrome.make_panel_style(fill, border, radius)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	return style


func _get_next_delay_value(current_delay: float) -> float:
	var current_seconds: int = maxi(0, int(round(current_delay)))
	return float((current_seconds + 1) % 10)


func _format_delay_label(delay_seconds: float) -> String:
	var seconds: int = maxi(0, int(round(delay_seconds)))
	return str(seconds) + "秒"


func _get_cat_visual_fallback(cat_name: String) -> String:
	var trimmed: String = cat_name.strip_edges()
	if trimmed == "":
		return "?"
	return trimmed.substr(0, 1)


func _get_max_team_size() -> int:
	match _current_team_type:
		"boss":
			return int(GameState.boss_config.get("max_team_size", 5))
		"dungeon":
			return int(GameState.dungeon_config.get("max_team_size", 5))
		"arena_attack", "arena_defense":
			return int(GameState.arena_config.get("max_team_size", 5))
	return 5


func _on_back_pressed() -> void:
	var boss_team: Dictionary = GameState.get_team("Boss")
	var boss_members: Array = boss_team.get("members", [])
	GameState.player_team = boss_members.map(func(member: Dictionary) -> int:
		return int(member.get("playerCatId", 0))
	)
	SceneNavigator.return_to_battle()
