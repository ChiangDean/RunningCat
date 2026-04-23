class_name DungeonSceneUI
extends RefCounted

const DUNGEON_CONTENT_EDITOR_SCENE = preload("res://scenes/ui/activity/dungeon/DungeonContentEditor.tscn")

const DEFAULT_DUNGEON_ICON_BY_KEY := {
	"cat_food": "res://assets/sprites/ui/dungeon/cat_food.png",
	"diamond": "res://assets/sprites/ui/dungeon/diamond.png",
	"whisker": "res://assets/sprites/ui/dungeon/whisker.png",
}

const REWARD_EMPTY_TEXT := "\u672c\u95dc\u66ab\u7121\u984d\u5916\u734e\u52f5\u3002"
const LAYER_LABEL := "\u5c64\u6578"
const AD_TICKET_BUTTON_TEXT := "\u770b\u5ee3\u544a\u7372\u5f97\u9580\u7968"
const DUNGEON_REWARD_KEYS: Array[String] = [
	"cat_food",
	"special_cat_food",
	"diamonds",
	"trap_cages",
	"whisker_shards",
]
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
			"shell_description": _get_dungeon_description(dungeon),
			"shell_summary_left": Callable(DungeonSceneUI, "_build_shell_summary_left").bind(scene, key),
			"shell_summary_right": Callable(DungeonSceneUI, "_build_shell_summary_right").bind(scene, key),
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


static func _build_dungeon_detail_panel(scene, dungeon: Dictionary) -> Control:
	var dungeon_id: int = int(dungeon.get("dungeonId", 0))
	var dungeon_key: String = str(dungeon.get("key", ""))
	var max_floor: int = int(dungeon.get("maxClearedFloor", 0))
	var display_level: int = maxi(max_floor, 1)
	var next_floor: int = max_floor + 1
	var ticket_count: int = int(dungeon.get("remainingTicketCount", 0))
	var ad_count: int = int(dungeon.get("remainingAdTicketCount", 0))
	var local_cfg: Dictionary = scene._get_local_dungeon_cfg(dungeon_key)
	var panel: Control = _instantiate_runtime_panel_from_editor()

	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bind_dungeon_template_header(panel, dungeon, display_level, ticket_count, ad_count)

	var sweep_rewards: Dictionary = _calculate_rewards(dungeon_key, local_cfg, display_level)
	var sweep_button: Button = _ensure_card_hit_button(panel.get_node("SweepCard") as Control)
	var sweep_action_text: String
	if ticket_count <= 0 and ad_count > 0 and max_floor > 0:
		sweep_action_text = AD_TICKET_BUTTON_TEXT
	else:
		sweep_action_text = UiText.DUNGEON_SWEEP_BUTTON_LEVEL_FORMAT % max_floor if max_floor > 0 else UiText.DUNGEON_SWEEP_BUTTON
	sweep_button.text = ""
	sweep_button.disabled = bool(scene._action_inflight) or max_floor <= 0 or (ticket_count <= 0 and ad_count <= 0)
	_bind_reward_card(
		panel.get_node("SweepCard") as Control,
		UiText.DUNGEON_REWARD_LEVEL_FORMAT % display_level,
		sweep_rewards,
		REWARD_EMPTY_TEXT,
		sweep_action_text,
		sweep_button.disabled
	)
	RedDotService.refresh_dot(sweep_button, RedDotService.has_dungeon_action_red_dot(dungeon, "sweep") and not sweep_button.disabled)

	var challenge_rewards: Dictionary = _calculate_rewards(dungeon_key, local_cfg, next_floor)
	var challenge_button: Button = _ensure_card_hit_button(panel.get_node("ChallengeCard") as Control)
	var challenge_action_text: String
	if ticket_count <= 0 and ad_count > 0:
		challenge_action_text = AD_TICKET_BUTTON_TEXT
	else:
		challenge_action_text = UiText.DUNGEON_CHALLENGE_BUTTON_LEVEL_FORMAT % next_floor
	challenge_button.text = ""
	challenge_button.disabled = bool(scene._action_inflight) or (ticket_count <= 0 and ad_count <= 0)
	_bind_reward_card(
		panel.get_node("ChallengeCard") as Control,
		UiText.DUNGEON_REWARD_LEVEL_FORMAT % next_floor,
		challenge_rewards,
		REWARD_EMPTY_TEXT,
		challenge_action_text,
		challenge_button.disabled
	)
	RedDotService.refresh_dot(challenge_button, RedDotService.has_dungeon_action_red_dot(dungeon, "challenge") and not challenge_button.disabled)

	scene._dungeon_panels[dungeon_id] = {
		"panel": panel,
	}

	sweep_button.pressed.connect(Callable(scene, "_on_sweep_pressed").bind(dungeon_id))
	challenge_button.pressed.connect(Callable(scene, "_on_challenge_pressed").bind(dungeon_id))

	return panel


static func _instantiate_runtime_panel_from_editor() -> Control:
	var editor_root: Control = DUNGEON_CONTENT_EDITOR_SCENE.instantiate() as Control
	var editor_content_root: Control = editor_root.get_node("ContentRoot") as Control
	var panel: Control = editor_content_root.duplicate() as Control

	panel.theme = editor_root.theme
	panel.offset_left = 0.0
	panel.offset_top = 0.0

	for editor_only_name: String in ["SectionLabel", "SummaryLabel", "NoteLabel"]:
		var editor_only_node: Node = panel.get_node_or_null(editor_only_name)
		if editor_only_node != null:
			panel.remove_child(editor_only_node)
			editor_only_node.queue_free()

	var max_right: float = 0.0
	var max_bottom: float = 0.0
	for child: Node in panel.get_children():
		if not (child is Control):
			continue
		var child_control: Control = child as Control
		max_right = maxf(max_right, child_control.offset_right)
		max_bottom = maxf(max_bottom, child_control.offset_bottom)

	panel.custom_minimum_size = Vector2(max_right, max_bottom)
	panel.offset_right = max_right
	panel.offset_bottom = max_bottom
	editor_root.queue_free()

	return panel


static func _ensure_card_hit_button(card: Control) -> Button:
	var existing: Node = card.get_node_or_null("HitButton")
	if existing is Button:
		var existing_button: Button = existing as Button
		_configure_card_button(existing_button)
		return existing_button

	var action_texture: TextureRect = card.get_node("ActionButton") as TextureRect
	var button: Button = Button.new()
	button.name = "HitButton"
	button.layout_mode = 0
	button.offset_left = action_texture.offset_left
	button.offset_top = action_texture.offset_top
	button.offset_right = action_texture.offset_right
	button.offset_bottom = action_texture.offset_bottom
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_configure_card_button(button)
	card.add_child(button)

	return button


static func _configure_card_button(button: Button) -> void:
	button.flat = false
	button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	UiPalette.apply_button_kind(button, "primary")


static func _bind_dungeon_template_header(panel: Control, dungeon: Dictionary, display_level: int, ticket_count: int, ad_count: int) -> void:
	var preview_icon: TextureRect = panel.get_node("MainCard/PreviewIcon") as TextureRect
	var name_label: Label = panel.get_node("MainCard/DungeonNameLabel") as Label
	var desc_label: Label = panel.get_node("MainCard/DungeonDescLabel") as Label
	var ticket_label: Label = panel.get_node("MainCard/TicketLabel") as Label
	var ad_label: Label = panel.get_node("MainCard/AdLabel") as Label
	var preview_texture: Texture2D = _resolve_dungeon_preview_texture(dungeon)

	if preview_texture != null:
		preview_icon.texture = preview_texture
		preview_icon.visible = true
	else:
		preview_icon.visible = false

	name_label.text = "%s %s %d" % [str(dungeon.get("displayName", UiText.DUNGEON_PAGE_TITLE)), LAYER_LABEL, display_level]
	desc_label.text = _get_dungeon_description(dungeon)
	desc_label.visible = desc_label.text != ""
	ticket_label.text = UiText.DUNGEON_TICKET_FORMAT % [str(dungeon.get("displayName", UiText.DUNGEON_PAGE_TITLE)), ticket_count]
	ad_label.text = UiText.DUNGEON_AD_REMAIN_FORMAT % ad_count


static func _bind_reward_card(
	card: Control,
	title_text: String,
	rewards: Dictionary,
	empty_text: String,
	action_text: String,
	is_disabled: bool
) -> void:
	var title_label: Label = card.get_node("TitleLabel") as Label
	var action_texture: TextureRect = card.get_node("ActionButton") as TextureRect
	var action_label: Label = card.get_node("ActionLabel") as Label
	var action_button: Button = _ensure_card_hit_button(card)
	var reward_items: Array[Dictionary] = _collect_reward_items(rewards)

	title_label.text = title_text
	action_texture.visible = false
	action_label.visible = false
	action_button.visible = true
	action_button.text = action_text
	action_button.disabled = is_disabled

	_bind_reward_slot(card.get_node("RewardSlotA") as Control, reward_items, 0, empty_text, true)
	_bind_reward_slot(card.get_node("RewardSlotB") as Control, reward_items, 1, empty_text, false)


static func _collect_reward_items(rewards: Dictionary) -> Array[Dictionary]:
	var reward_items: Array[Dictionary] = []
	for reward_key: String in DUNGEON_REWARD_KEYS:
		var amount: int = int(rewards.get(reward_key, 0))
		if amount <= 0:
			continue
		reward_items.append({
			"key": reward_key,
			"amount": amount,
		})
	return reward_items


static func _bind_reward_slot(slot: Control, reward_items: Array[Dictionary], index: int, empty_text: String, show_empty_text: bool) -> void:
	var frame: TextureRect = slot.get_node("Frame") as TextureRect
	var icon: TextureRect = slot.get_node("ItemIcon") as TextureRect
	var overlay_mask: TextureRect = slot.get_node("OverlayMask") as TextureRect
	var item_name_label: Label = slot.get_node("ItemNameLabel") as Label
	var count_label: Label = slot.get_node("CountLabel") as Label

	slot.visible = true

	if index >= reward_items.size():
		frame.visible = false
		icon.visible = false
		overlay_mask.visible = false
		count_label.visible = false
		item_name_label.visible = show_empty_text
		if show_empty_text:
			item_name_label.text = empty_text
			item_name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		else:
			slot.visible = false
		return

	var reward_item: Dictionary = reward_items[index]
	var reward_key: String = str(reward_item.get("key", ""))
	var amount: int = int(reward_item.get("amount", 0))
	var texture: Texture2D = AssetResolver.load_texture(AssetResolver.resolve_catalog_path(_get_reward_catalog_path(reward_key)))

	frame.visible = true
	icon.visible = texture != null
	icon.texture = texture
	overlay_mask.visible = true
	item_name_label.visible = true
	item_name_label.text = _get_reward_label(reward_key)
	item_name_label.add_theme_font_size_override("font_size", 37)
	count_label.visible = true
	count_label.text = GameState.format_number(amount)


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


static func _get_reward_catalog_path(reward_key: String) -> String:
	match reward_key:
		"cat_food":
			return "catalog/consumable/cat_food"
		"special_cat_food":
			return "catalog/consumable/special_cat_food"
		"diamonds":
			return "catalog/currency/diamonds"
		"trap_cages":
			return "catalog/consumable/trap_cages"
		"whisker_shards":
			return "catalog/consumable/whisker_shards"
		_:
			return ""


static func _get_dungeon_description(dungeon: Dictionary) -> String:
	var description: String = str(dungeon.get("description", "")).strip_edges()
	if description.begins_with("Dungeon config for"):
		return ""
	return description


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


static func _build_shell_summary_left(scene, dungeon_key: String) -> String:
	match dungeon_key:
		"cat_food":
			return "%s %d / %s %d" % [
				UiText.REWARD_CAT_FOOD,
				scene.GameState.player_data.cat_food,
				UiText.REWARD_SPECIAL_CAT_FOOD,
				scene.GameState.player_data.special_cat_food,
			]
		"diamond":
			return "%s %d / %s %d" % [
				UiText.REWARD_DIAMONDS,
				scene.GameState.player_data.diamonds,
				UiText.REWARD_TRAP_CAGE,
				scene.GameState.player_data.trap_cages,
			]
		"whisker":
			return "%s %d / %s %d" % [
				UiText.REWARD_DIAMONDS,
				scene.GameState.player_data.diamonds,
				UiText.REWARD_WHISKERS,
				scene.GameState.player_data.whisker_shards,
			]
		_:
			return ""


static func _build_shell_summary_right(scene, dungeon_key: String) -> String:
	var dungeon: Dictionary = scene.GameState.get_dungeon_entry_by_key(dungeon_key)
	if dungeon.is_empty():
		return ""
	return "\u5c64\u6578 %d / \u9580\u7968 %d" % [
		maxi(int(dungeon.get("maxClearedFloor", 0)), 1),
		int(dungeon.get("remainingTicketCount", 0)),
	]
