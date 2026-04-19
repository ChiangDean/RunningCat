class_name DungeonSceneUI
extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const PlayerDungeonData = preload("res://scripts/data/player_dungeon_data.gd")
const RedDotService = preload("res://scripts/ui/red_dot_service.gd")

const DEFAULT_DUNGEON_ICON_BY_KEY := {
	"cat_food": "res://assets/sprites/ui/dungeon/cat_food.png",
	"diamond": "res://assets/sprites/ui/dungeon/diamond.png",
	"whisker": "res://assets/sprites/ui/dungeon/whisker.png",
}

const HERO_ART_SIZE := 248.0
const REWARD_EMPTY_TEXT := "\u672c\u95dc\u66ab\u7121\u984d\u5916\u734e\u52f5\u3002"
const LAYER_LABEL := "\u5c64\u6578"
const AD_TICKET_BUTTON_TEXT := "\u770b\u5ee3\u544a\u7372\u5f97\u9580\u7968"


static func build_ui(scene) -> void:
	_clear_scene(scene)

	var dock_items: Array = _build_submenu_items(scene)
	_normalize_active_dungeon(scene, dock_items)

	var chrome: Dictionary = OverlaySceneChrome.build(scene, "dungeon", Callable(scene, "_on_back_pressed"), {
		"show_dock": dock_items.size() > 0,
		"dock_items": dock_items,
		"active_key": scene._active_dungeon_key,
		"button_pressed": Callable(scene, "_switch_dungeon_tab"),
		"button_height": 52.0,
		"font_size": 18,
	})
	scene._root_vbox = chrome.get("content_box")
	scene._submenu_buttons = chrome.get("dock_buttons", {})

	var title: Label = Label.new()
	title.text = UiText.DUNGEON_PAGE_TITLE
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	scene._root_vbox.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.DUNGEON_PAGE_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	scene._root_vbox.add_child(desc)

	scene._scroll = ScrollContainer.new()
	scene._scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scene._root_vbox.add_child(scene._scroll)
	InertialScroller.attach(scene._scroll, "vertical")

	scene._dungeon_list = VBoxContainer.new()
	scene._dungeon_list.name = "DungeonContent"
	scene._dungeon_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene._dungeon_list.add_theme_constant_override("separation", 14)
	scene._scroll.add_child(scene._dungeon_list)

	_populate_dungeon_content(scene)
	refresh_red_dots(scene)


static func rebuild_dungeon_panels(scene) -> void:
	build_ui(scene)


static func refresh_panel(scene, dungeon_id: int) -> void:
	var active_entry: Dictionary = _get_active_dungeon(scene)
	if active_entry.is_empty():
		return
	if int(active_entry.get("dungeonId", 0)) != dungeon_id:
		return
	build_ui(scene)


static func _clear_scene(scene) -> void:
	for child: Node in scene.get_children():
		scene.remove_child(child)
		child.queue_free()


static func _build_submenu_items(scene) -> Array:
	var items: Array = []
	for dungeon_variant: Variant in scene.GameState.dungeon_overview_data:
		if not (dungeon_variant is Dictionary):
			continue
		var dungeon: Dictionary = dungeon_variant
		var key: String = str(dungeon.get("key", ""))
		if key == "":
			continue
		items.append({
			"key": key,
			"label": str(dungeon.get("displayName", key)),
		})
	return items


static func _normalize_active_dungeon(scene, dock_items: Array) -> void:
	if dock_items.is_empty():
		scene._active_dungeon_key = ""
		return
	if scene._active_dungeon_key == "":
		scene._active_dungeon_key = _first_dock_key(dock_items)
		return
	for item_variant: Variant in dock_items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if str(item.get("key", "")) == scene._active_dungeon_key:
			return
	scene._active_dungeon_key = _first_dock_key(dock_items)


static func _first_dock_key(dock_items: Array) -> String:
	if dock_items.is_empty():
		return ""
	var first_item: Variant = dock_items[0]
	if first_item is Dictionary:
		var first_dict: Dictionary = first_item
		return str(first_dict.get("key", ""))
	return ""


static func _populate_dungeon_content(scene) -> void:
	scene._dungeon_panels.clear()

	var container: VBoxContainer = scene._dungeon_list
	if not is_instance_valid(container):
		return

	for child: Node in container.get_children():
		child.queue_free()

	var dungeon: Dictionary = _get_active_dungeon(scene)
	if dungeon.is_empty():
		_add_empty_state(container)
		return

	container.add_child(_build_dungeon_detail_panel(scene, dungeon))


static func _add_empty_state(container: VBoxContainer) -> void:
	var empty_card: PanelContainer = OverlaySceneChrome.make_card_panel()
	empty_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(empty_card)

	var empty_margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	empty_card.add_child(empty_margin)

	var empty_label: Label = Label.new()
	empty_label.text = UiText.DUNGEON_EMPTY_DATA
	empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	empty_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_margin.add_child(empty_label)


static func _get_active_dungeon(scene) -> Dictionary:
	if scene._active_dungeon_key == "":
		return {}
	return scene.GameState.get_dungeon_entry_by_key(scene._active_dungeon_key)


static func _build_dungeon_detail_panel(scene, dungeon: Dictionary) -> PanelContainer:
	var dungeon_id: int = int(dungeon.get("dungeonId", 0))
	var dungeon_key: String = str(dungeon.get("key", ""))
	var max_floor: int = int(dungeon.get("maxClearedFloor", 0))
	var display_level: int = maxi(max_floor, 1)
	var next_floor: int = max_floor + 1
	var ticket_count: int = int(dungeon.get("remainingTicketCount", 0))
	var ad_count: int = int(dungeon.get("remainingAdTicketCount", 0))
	var local_cfg: Dictionary = scene._get_local_dungeon_cfg(dungeon_key)

	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	panel.add_child(margin)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var art_panel: PanelContainer = OverlaySceneChrome.make_card_panel(
		OverlaySceneChrome.CARD_BORDER,
		Color(0.14, 0.13, 0.15, 0.98),
		18
	)
	layout.add_child(art_panel)

	var art_margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	art_panel.add_child(art_margin)

	var art_box: VBoxContainer = VBoxContainer.new()
	art_box.alignment = BoxContainer.ALIGNMENT_CENTER
	art_margin.add_child(art_box)

	var preview_texture: Texture2D = _resolve_dungeon_preview_texture(dungeon)
	if preview_texture != null:
		var preview: TextureRect = AssetResolver.create_icon_rect(preview_texture, Vector2(HERO_ART_SIZE, HERO_ART_SIZE))
		preview.custom_minimum_size = Vector2(HERO_ART_SIZE, HERO_ART_SIZE)
		art_box.add_child(preview)
	else:
		var fallback_label: Label = Label.new()
		fallback_label.text = UiText.DUNGEON_CARD_FALLBACK_ART
		fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
		fallback_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
		art_box.add_child(fallback_label)

	var header_card: PanelContainer = OverlaySceneChrome.make_card_panel()
	layout.add_child(header_card)

	var header_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	header_card.add_child(header_margin)

	var header_box: VBoxContainer = VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 10)
	header_margin.add_child(header_box)

	var name_label: Label = Label.new()
	name_label.text = "%s %s %d" % [str(dungeon.get("displayName", UiText.DUNGEON_PAGE_TITLE)), LAYER_LABEL, display_level]
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	header_box.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = str(dungeon.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	header_box.add_child(desc_label)

	var status_row: HBoxContainer = HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 10)
	header_box.add_child(status_row)

	status_row.add_child(_make_status_chip(UiText.DUNGEON_TICKET_FORMAT % [str(dungeon.get("displayName", UiText.DUNGEON_PAGE_TITLE)), ticket_count]))
	status_row.add_child(_make_status_chip(UiText.DUNGEON_AD_REMAIN_FORMAT % ad_count))

	var reward_row: HBoxContainer = HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 12)
	layout.add_child(reward_row)

	var sweep_rewards: Dictionary = _calculate_rewards(dungeon_key, local_cfg, display_level)
	var sweep_button: Button = Button.new()
	sweep_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sweep_button.custom_minimum_size = Vector2(0.0, 52.0)
	sweep_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	if ticket_count <= 0 and ad_count > 0 and max_floor > 0:
		sweep_button.text = AD_TICKET_BUTTON_TEXT
	else:
		sweep_button.text = UiText.DUNGEON_SWEEP_BUTTON_LEVEL_FORMAT % max_floor if max_floor > 0 else UiText.DUNGEON_SWEEP_BUTTON
	sweep_button.disabled = bool(scene._action_inflight) or max_floor <= 0 or (ticket_count <= 0 and ad_count <= 0)
	RedDotService.refresh_dot(sweep_button, RedDotService.has_dungeon_action_red_dot(dungeon, "sweep") and not sweep_button.disabled)
	reward_row.add_child(_build_action_panel(
		UiText.DUNGEON_REWARD_LEVEL_FORMAT % display_level,
		sweep_rewards,
		REWARD_EMPTY_TEXT,
		sweep_button,
		"confirm"
	))

	var challenge_rewards: Dictionary = _calculate_rewards(dungeon_key, local_cfg, next_floor)
	var challenge_button: Button = Button.new()
	challenge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_button.custom_minimum_size = Vector2(0.0, 52.0)
	challenge_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	if ticket_count <= 0 and ad_count > 0:
		challenge_button.text = AD_TICKET_BUTTON_TEXT
	else:
		challenge_button.text = UiText.DUNGEON_CHALLENGE_BUTTON_LEVEL_FORMAT % next_floor
	challenge_button.disabled = bool(scene._action_inflight) or (ticket_count <= 0 and ad_count <= 0)
	RedDotService.refresh_dot(challenge_button, RedDotService.has_dungeon_action_red_dot(dungeon, "challenge") and not challenge_button.disabled)
	reward_row.add_child(_build_action_panel(
		UiText.DUNGEON_REWARD_LEVEL_FORMAT % next_floor,
		challenge_rewards,
		REWARD_EMPTY_TEXT,
		challenge_button,
		"confirm"
	))

	scene._dungeon_panels[dungeon_id] = {
		"panel": panel,
	}

	sweep_button.pressed.connect(func() -> void: scene._on_sweep_pressed(dungeon_id))
	challenge_button.pressed.connect(func() -> void: scene._on_challenge_pressed(dungeon_id))

	return panel


static func _make_status_chip(text_value: String) -> PanelContainer:
	var chip: PanelContainer = OverlaySceneChrome.make_card_panel(
		OverlaySceneChrome.CARD_BORDER,
		Color(0.12, 0.12, 0.14, 0.96),
		12
	)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(10)
	chip.add_child(margin)

	var label: Label = Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	margin.add_child(label)

	return chip


static func _build_reward_panel(title_text: String, rewards: Dictionary, empty_text: String) -> PanelContainer:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title_label: Label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	title_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title_label)

	var list_box: VBoxContainer = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 6)
	box.add_child(list_box)

	var has_reward: bool = false
	for reward_key: String in ["cat_food", "special_cat_food", "diamonds", "trap_cages", "whisker_shards"]:
		var amount: int = int(rewards.get(reward_key, 0))
		if amount <= 0:
			continue
		has_reward = true
		var reward_label: Label = Label.new()
		reward_label.text = "%s \u00d7%d" % [_get_reward_label(reward_key), amount]
		reward_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		list_box.add_child(reward_label)

	if not has_reward:
		var empty_label: Label = Label.new()
		empty_label.text = empty_text
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		empty_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		list_box.add_child(empty_label)

	return panel


static func _build_action_panel(
	title_text: String,
	rewards: Dictionary,
	empty_text: String,
	action_button: Button,
	button_kind: String
) -> PanelContainer:
	var panel: PanelContainer = _build_reward_panel(title_text, rewards, empty_text)
	var margin: MarginContainer = panel.get_child(0)
	var box: VBoxContainer = margin.get_child(0)
	box.add_theme_constant_override("separation", 12)
	box.add_child(action_button)
	UiPalette.apply_button_kind(action_button, button_kind)
	return panel


static func refresh_red_dots(scene) -> void:
	for key_variant: Variant in scene._submenu_buttons.keys():
		var key: String = str(key_variant)
		var button: Control = scene._submenu_buttons.get(key, null)
		if button == null:
			continue
		var dungeon: Dictionary = scene.GameState.get_dungeon_entry_by_key(key)
		RedDotService.refresh_dot(button, RedDotService.has_dungeon_entry_red_dot(dungeon))


static func _get_reward_label(reward_key: String) -> String:
	match reward_key:
		"cat_food":
			return UiText.REWARD_CAT_FOOD
		"special_cat_food":
			return UiText.REWARD_SPECIAL_CAT_FOOD
		"diamonds":
			return UiText.REWARD_DIAMONDS
		"trap_cages":
			return UiText.REWARD_TRAP_CAGE
		"whisker_shards":
			return UiText.REWARD_WHISKERS
		_:
			return reward_key


static func _calculate_rewards(dungeon_key: String, local_cfg: Dictionary, level: int) -> Dictionary:
	var rewards: Dictionary = PlayerDungeonData.calculate_rewards(local_cfg, level)
	if not rewards.is_empty():
		return rewards

	match dungeon_key:
		"cat_food":
			return {
				"cat_food": level * 5,
				"special_cat_food": level,
			}
		"diamond":
			return {
				"diamonds": level * 2,
				"trap_cages": roundi(float(level) / 5.0 + 0.5),
			}
		"whisker":
			return {
				"diamonds": level * 2,
				"whisker_shards": roundi(float(level) / 10.0 + 0.5),
			}
		_:
			return rewards


static func _resolve_dungeon_preview_texture(dungeon: Dictionary) -> Texture2D:
	var image_path: String = str(dungeon.get("imagePath", ""))
	var preview_texture: Texture2D = AssetResolver.load_texture(AssetResolver.resolve_catalog_path(image_path))
	if preview_texture != null:
		return preview_texture

	var dungeon_key: String = str(dungeon.get("key", "")).to_lower()
	if DEFAULT_DUNGEON_ICON_BY_KEY.has(dungeon_key):
		return AssetResolver.load_texture(str(DEFAULT_DUNGEON_ICON_BY_KEY[dungeon_key]))

	for key: String in DEFAULT_DUNGEON_ICON_BY_KEY.keys():
		if image_path.to_lower().contains(key):
			return AssetResolver.load_texture(str(DEFAULT_DUNGEON_ICON_BY_KEY[key]))

	return null
