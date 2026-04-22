extends Control

const Constants = preload("res://scripts/lineup/LineupConstants.gd")
const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const CatRosterCard = preload("res://scripts/ui/cat_roster_card.gd")
const TOP_SECTION_SCENE = preload("res://scenes/ui/lineup/LineupTopSectionEditor.tscn")
const BOTTOM_SECTION_SCENE = preload("res://scenes/ui/lineup/LineupBottomSectionEditor.tscn")

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
var _team_title_label: Label
var _team_summary_label: Label
var _team_slot_views: Array[Dictionary] = []
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
	var submenu_items: Array = []
	for type_key: String in ["boss", "dungeon", "arena_attack", "arena_defense"]:
		submenu_items.append({
			"key": type_key,
			"label": str(Constants.TEAM_LABELS[type_key]),
			"shell_description": _get_team_type_description(type_key),
			"shell_summary_right": Callable(self, "_build_team_type_summary").bind(type_key),
		})

	var chrome: Dictionary = OverlaySceneChrome.build(self, "config", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": submenu_items,
		"active_key": _current_team_type,
		"back_label": UiText.CONFIG_BACK,
		"button_pressed": Callable(self, "_switch_team_type"),
		"content_separation": 14,
	})
	_team_type_btns = chrome.get("dock_buttons", {})

	var content_vbox: VBoxContainer = chrome.get("content_box") as VBoxContainer

	var main_split: VBoxContainer = VBoxContainer.new()
	main_split.add_theme_constant_override("separation", 12)
	main_split.clip_contents = true
	main_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(main_split)

	var top_section: Control = TOP_SECTION_SCENE.instantiate() as Control
	top_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_split.add_child(top_section)

	_team_title_label = top_section.get_node_or_null("TitleLabel") as Label
	_team_summary_label = top_section.get_node_or_null("SummaryLabel") as Label
	_team_slot_views.clear()
	for slot_index: int in range(5):
		var slot_root: Control = top_section.get_node_or_null("TeamGridHost/Slot" + str(slot_index + 1)) as Control
		if slot_root == null:
			continue
		var card_host: Control = slot_root.get_node_or_null("CardHost") as Control
		var badge_label: Label = slot_root.get_node_or_null("SlotBadgeLabel") as Label
		var name_label: Label = slot_root.get_node_or_null("SlotNameLabel") as Label
		var remove_button: Button = slot_root.get_node_or_null("RemoveButton") as Button
		var delay_button: Button = slot_root.get_node_or_null("DelayButton") as Button
		if remove_button != null:
			remove_button.pressed.connect(_on_team_slot_remove_pressed.bind(slot_index))
			_apply_team_slot_remove_button_style(remove_button)
		if delay_button != null:
			delay_button.pressed.connect(_on_team_slot_delay_pressed.bind(slot_index))
		_team_slot_views.append({
			"root": slot_root,
			"card_host": card_host,
			"badge_label": badge_label,
			"name_label": name_label,
			"remove_button": remove_button,
			"delay_button": delay_button,
			"placeholder_name": name_label.text if name_label != null else "",
			"placeholder_delay": delay_button.text if delay_button != null else "",
		})

	_save_team_btn = top_section.get_node_or_null("ConfirmButton") as Button
	if _save_team_btn != null:
		_save_team_btn.text = UiText.CONFIG_SAVE_BUTTON
		_save_team_btn.pressed.connect(_on_save_team_pressed)
		UiPalette.apply_button_kind(_save_team_btn, "confirm")
	var bottom_section: Control = BOTTOM_SECTION_SCENE.instantiate() as Control
	bottom_section.custom_minimum_size = Vector2.ZERO
	bottom_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_child(bottom_section)

	_cats_title = bottom_section.get_node_or_null("TitleLabel") as Label
	if _cats_title != null:
		_cats_title.text = UiText.CONFIG_OWNED_CATS_TITLE

	var sort_row: HBoxContainer = HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 6)
	sort_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sort_host: Control = bottom_section.get_node_or_null("SortHost") as Control
	if sort_host != null:
		sort_host.add_child(sort_row)

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
	_cats_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cats_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cats_list_host: Control = bottom_section.get_node_or_null("CatsListHost") as Control
	if cats_list_host != null:
		cats_list_host.custom_minimum_size = Vector2.ZERO
		cats_list_host.add_child(_cats_scroll)

	_cats_container = GridContainer.new()
	_cats_container.columns = 4
	_cats_container.add_theme_constant_override("h_separation", 4)
	_cats_container.add_theme_constant_override("v_separation", 4)
	_cats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cats_scroll.add_child(_cats_container)
	_cats_scroller = InertialScroller.attach(_cats_scroll, "vertical")

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
	if _team_title_label != null:
		_team_title_label.text = "編隊陣容"
	if _team_summary_label != null:
		_team_summary_label.text = UiText.CONFIG_TEAM_SUMMARY_WITH_DELAY
func _refresh_team() -> void:
	var members: Array = _get_editing_team_members()
	var max_count: int = _get_max_team_size()
	for slot_index: int in range(_team_slot_views.size()):
		var slot_view: Dictionary = _team_slot_views[slot_index]
		var slot_root: Control = slot_view.get("root", null) as Control
		if slot_root == null:
			continue
		slot_root.visible = slot_index < max_count
		if slot_index >= max_count:
			continue

		var badge_label: Label = slot_view.get("badge_label", null) as Label
		var name_label: Label = slot_view.get("name_label", null) as Label
		var remove_button: Button = slot_view.get("remove_button", null) as Button
		var delay_button: Button = slot_view.get("delay_button", null) as Button
		var card_host: Control = slot_view.get("card_host", null) as Control
		var member: Dictionary = members[slot_index] if slot_index < members.size() else {}
		var is_filled: bool = not member.is_empty()
		var cat_name: String = str(member.get("catDisplayName", "")) if is_filled else str(slot_view.get("placeholder_name", ""))
		var delay_seconds: float = float(member.get("initialDelaySeconds", 0.0)) if is_filled else 0.0

		if badge_label != null:
			badge_label.text = UiText.CONFIG_SLOT_BADGE_FORMAT % [slot_index + 1]
		if name_label != null:
			name_label.text = cat_name
		if remove_button != null:
			remove_button.visible = is_filled
			remove_button.disabled = _api_in_flight or not is_filled
		if delay_button != null:
			delay_button.text = UiText.CONFIG_DELAY_BUTTON_FORMAT % [_format_delay_label(delay_seconds)] if is_filled else UiText.CONFIG_DELAY_BUTTON_EMPTY
			delay_button.disabled = _api_in_flight or not is_filled
			UiPalette.apply_button_palette(delay_button, SLOT_DELAY_BG, Color(0.98, 0.90, 0.72, 1.0))

		if card_host != null:
			for child: Node in card_host.get_children():
				child.queue_free()
			var slot_card: Control = _make_team_slot_card(slot_index, member, card_host.size)
			slot_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			card_host.add_child(slot_card)

	_update_team_title()
	_update_save_section()
	SceneSubmenuBar.refresh(_team_type_btns, _current_team_type, {
		"active_color": SceneMenuTheme.ACTIVE_COLOR,
		"inactive_color": SceneMenuTheme.INACTIVE_COLOR,
	})


func _make_team_slot_card(slot_index: int, member: Dictionary, host_size: Vector2) -> Control:
	var is_filled: bool = not member.is_empty()
	var cat_name: String = str(member.get("catDisplayName", "")) if is_filled else UiText.CONFIG_EMPTY_SLOT
	var cat_catalog_id: int = int(member.get("catCatalogId", 0)) if is_filled else 0
	var delay_seconds: float = float(member.get("initialDelaySeconds", 0.0)) if is_filled else 0.0
	var cat_file_id: String = GameState.get_cat_file_id_by_catalog_id(cat_catalog_id) if is_filled else ""
	var team_icon: Texture2D = AssetResolver.resolve_cat_icon(cat_file_id)
	var cat_data: CatData = CatData.from_json_file(cat_file_id + ".json") if cat_file_id != "" else null
	var resolved_host_size: Vector2 = host_size
	if resolved_host_size.x <= 0.0:
		resolved_host_size.x = 110.0
	if resolved_host_size.y <= 0.0:
		resolved_host_size.y = 232.0

	var card_gui_input: Callable = Callable()
	if is_filled and cat_file_id != "":
		card_gui_input = func(event: InputEvent) -> void:
			if not (event is InputEventMouseButton):
				return
			var mouse_event: InputEventMouseButton = event as InputEventMouseButton
			if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
				return
			_show_skill_popup(cat_file_id)

	var slot_card: PanelContainer = CatRosterCard.build({
		"template_key": "lineup_team",
		"title_text": "",
		"icon_texture": team_icon,
		"fallback_text": _get_cat_visual_fallback(cat_name),
		"level_value": int(member.get("catFoodLevel", 1)) if is_filled else 0,
		"rank_value": int(member.get("rank", 0)) if is_filled else 0,
		"cat_type": cat_data.cat_type if cat_data != null else "base",
		"rarity_key": cat_data.rarity if cat_data != null else "common",
		"whole_card_gui_input": card_gui_input,
		"card_height": resolved_host_size.y,
		"icon_size": Vector2(92.0, 92.0),
		"frame_margin": 0,
		"card_border": Color(0.0, 0.0, 0.0, 0.0),
		"selected_card_border": Color(0.0, 0.0, 0.0, 0.0),
		"title_color": Color(0.42, 0.28, 0.15, 1.0) if is_filled else EMPTY_SLOT_TEXT_COLOR,
		"title_font_size": 13,
		"show_type_icon": is_filled,
		"show_rarity_label": is_filled,
		"show_level_label": is_filled,
		"show_rank_label": is_filled,
	})
	slot_card.custom_minimum_size = resolved_host_size
	slot_card.size_flags_horizontal = 0
	return slot_card


func _on_team_slot_remove_pressed(slot_index: int) -> void:
	_remove_member_from_draft(slot_index)


func _on_team_slot_delay_pressed(slot_index: int) -> void:
	var members: Array = _get_editing_team_members()
	if slot_index < 0 or slot_index >= members.size():
		return
	var member_variant: Variant = members[slot_index]
	if not (member_variant is Dictionary):
		return
	var member: Dictionary = member_variant as Dictionary
	if member.is_empty():
		return
	var delay_seconds: float = float(member.get("initialDelaySeconds", 0.0))
	_update_member_delay_in_draft(slot_index, _get_next_delay_value(delay_seconds))

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
	var cat_icon: Texture2D = AssetResolver.resolve_cat_icon(local_cat_id)
	var cat_data: CatData = CatData.from_json_file(local_cat_id + ".json") if local_cat_id != "" else null
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
		"template_key": "lineup_owned",
		"title_text": display_name,
		"icon_texture": cat_icon,
		"fallback_text": _get_cat_visual_fallback(display_name),
		"level_value": lv,
		"rank_value": rank,
		"cat_type": cat_data.cat_type if cat_data != null else "base",
		"rarity_key": cat_data.rarity if cat_data != null else "common",
		"whole_card_gui_input": whole_card_gui_input,
		"card_height": 232.0,
		"icon_size": Vector2(110.0, 110.0),
		"frame_margin": 0,
		"card_border": Color(0.0, 0.0, 0.0, 0.0),
		"selected_card_border": Color(0.0, 0.0, 0.0, 0.0),
		"title_color": Color(0.42, 0.28, 0.15, 1.0),
	})
	card.custom_minimum_size = Vector2(146.0, 168.0)
	card.size_flags_horizontal = 0
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
	if _save_team_btn == null:
		return
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


func _apply_team_slot_remove_button_style(remove_button: Button) -> void:
	if remove_button == null:
		return
	remove_button.add_theme_font_size_override("font_size", 11)
	remove_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.95, 1.0))
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
	remove_button.add_theme_stylebox_override("normal", remove_style)
	var remove_hover: StyleBoxFlat = remove_style.duplicate()
	remove_hover.bg_color = SLOT_REMOVE_BG.lightened(0.08)
	var remove_pressed: StyleBoxFlat = remove_style.duplicate()
	remove_pressed.bg_color = SLOT_REMOVE_BG.darkened(0.08)
	remove_button.add_theme_stylebox_override("hover", remove_hover)
	remove_button.add_theme_stylebox_override("pressed", remove_pressed)


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


func _get_team_type_description(type_key: String) -> String:
	match type_key:
		"boss":
			return "調整 BOSS 推圖隊伍與初始出手延遲。"
		"dungeon":
			return "調整地下城挑戰隊伍與關卡用貓編排。"
		"arena_attack":
			return "調整競技場進攻隊伍與出手順序。"
		"arena_defense":
			return "調整競技場防守隊伍與防禦編成。"
		_:
			return UiText.CONFIG_PAGE_DESC
func _build_team_type_summary(type_key: String) -> String:
	_ensure_team_draft(type_key)
	var team: Dictionary = _team_drafts.get(type_key, {})
	var members_variant: Variant = team.get("members", [])
	var members: Array = members_variant if members_variant is Array else []
	var filled_count: int = 0
	for member_variant: Variant in members:
		if member_variant is Dictionary and not (member_variant as Dictionary).is_empty():
			filled_count += 1
	return "已編隊 %d/%d" % [filled_count, _get_max_team_size_for(type_key)]
func _on_back_pressed() -> void:
	var boss_team: Dictionary = GameState.get_team("Boss")
	var boss_members: Array = boss_team.get("members", [])
	GameState.player_team = boss_members.map(func(member: Dictionary) -> int:
		return int(member.get("playerCatId", 0))
	)
	SceneNavigator.return_to_battle()
