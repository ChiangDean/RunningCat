extends Control

const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const SceneMenuTheme = preload("res://scripts/ui/scene_menu_theme.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const SceneSecondarySubmenu = preload("res://scripts/ui/scene_secondary_submenu.gd")
const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const RedDotService = preload("res://scripts/ui/red_dot_service.gd")

const TAB_VALUE := "value_bundle"
const TAB_GROWTH := "growth_bundle"
const TAB_DAILY := "daily_bundle"
const TAB_COLLISION_COIN := "collision_coin"
const TAB_DIAMOND_STORE := "diamond_store"
const TAB_POINT := "point_bundle"
const COLLISION_COIN_ICON_PATH := "res://assets/sprites/ui/rewards/collision_coin.png"

const CATEGORY_CONFIGS := [
	{"key": TAB_VALUE, "label": "SHOP_SUBMENU_VALUE", "category_type": "valuepack"},
	{"key": TAB_COLLISION_COIN, "label": "SHOP_SUBMENU_COLLISION_COIN"},
	{"key": TAB_DIAMOND_STORE, "label": "SHOP_SUBMENU_DIAMOND_STORE"},
	{"key": TAB_POINT, "label": "SHOP_SUBMENU_POINT", "category_type": "pointpack"},
]

const COLLISION_COIN_ITEMS := [
	{"key": "coin_33", "label": "33衝撞幣", "amount": 33},
	{"key": "coin_170", "label": "170衝撞幣", "amount": 170},
	{"key": "coin_330", "label": "330衝撞幣", "amount": 330},
	{"key": "coin_490", "label": "490衝撞幣", "amount": 490},
	{"key": "coin_990", "label": "990衝撞幣", "amount": 990},
	{"key": "coin_1690", "label": "1690衝撞幣", "amount": 1690},
	{"key": "coin_3290", "label": "3290衝撞幣", "amount": 3290},
]

const DIAMOND_STORE_ITEMS := [
	{"key": "trap_cage", "label": "誘捕籠"},
	{"key": "arena_ticket", "label": "競技券"},
]

const TRAP_CAGE_DIAMOND_COST := 100
const BUNDLE_ACTION_WIDTH := 220.0

var _active_tab: String = TAB_VALUE
var _active_secondary_keys: Dictionary = {}
var _tab_buttons: Dictionary = {}
var _secondary_buttons: Dictionary = {}
var _content_host: Control
var _trap_cage_quantity_dialog_close: Callable = Callable()
var _trap_cage_keypad_close: Callable = Callable()
var _trap_cage_quantity: int = 1
var _trap_cage_quantity_button: Button
var _trap_cage_preview_label: Label
var _pending_bundle_purchase: Dictionary = {}

@onready var _api_client = get_node("/root/ApiClient")


func _ready() -> void:
	_build_ui()
	GameState.red_dot_state_changed.connect(_refresh_red_dots)
	_refresh_content()


func _build_ui() -> void:
	var dock_items: Array = []
	for item: Dictionary in CATEGORY_CONFIGS:
		var tab_key: String = str(item.get("key", ""))
		var tab_meta: Dictionary = _get_tab_meta(tab_key)
		dock_items.append({
			"key": tab_key,
			"label": _get_top_label(tab_key),
			"shell_description": str(tab_meta.get("description", "")),
			"shell_summary_left": Callable(self, "_get_shell_summary_left"),
			"shell_summary_right": Callable(self, "_build_tab_summary_right").bind(tab_key),
		})

	var chrome: Dictionary = OverlaySceneChrome.build(self, "shop", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": dock_items,
		"active_key": _active_tab,
		"button_pressed": Callable(self, "_switch_tab"),
		"button_height": SceneMenuTheme.SUBMENU_BUTTON_HEIGHT,
		"font_size": SceneMenuTheme.SUBMENU_FONT_SIZE,
	})
	_tab_buttons = chrome.get("dock_buttons", {})

	var content_box: VBoxContainer = chrome.get("content_box")

	_content_host = Control.new()
	_content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_child(_content_host)


func refresh_from_bootstrap(show_error_dialog: bool = true) -> void:
	_api_client.get_authenticated_bootstrap(func(success: bool, data: Variant, error: Dictionary) -> void:
		if success and data is Dictionary:
			GameState.apply_player_bootstrap(data)
			_refresh_content()
			return
		if show_error_dialog:
			ToastManager.error(UiText.SHOP_LOAD_FAILED_TITLE, str(error.get("message", UiText.SHOP_LOAD_FAILED_BODY)))
	)


func _switch_tab(tab_key: String) -> void:
	if _active_tab == tab_key:
		return
	_active_tab = tab_key
	_refresh_content()


func _switch_secondary_item(item_key: String) -> void:
	_active_secondary_keys[_active_tab] = item_key
	_refresh_content()


func _refresh_content() -> void:
	_rebuild_content()
	SceneSubmenuBar.refresh(_tab_buttons, _active_tab, {
		"active_color": SceneMenuTheme.ACTIVE_COLOR,
		"inactive_color": SceneMenuTheme.INACTIVE_COLOR,
	})
	_refresh_red_dots()


func _rebuild_content() -> void:
	for child in _content_host.get_children():
		child.queue_free()
	_secondary_buttons.clear()

	var secondary_items: Array = _build_secondary_items(_active_tab)
	var active_secondary_key: String = _ensure_active_secondary_key(_active_tab, secondary_items)

	var secondary_submenu: Dictionary = SceneSecondarySubmenu.build(_content_host, {
		"items": secondary_items,
		"active_key": active_secondary_key,
		"button_pressed": Callable(self, "_switch_secondary_item"),
		"secondary_border": OverlaySceneChrome.PANEL_BORDER,
		"content_border": OverlaySceneChrome.CARD_BORDER,
	})
	_secondary_buttons = secondary_submenu.get("secondary_buttons", {})
	var content_list: VBoxContainer = secondary_submenu.get("content_list")

	if secondary_items.is_empty():
		content_list.add_child(_build_empty_state(UiText.SHOP_EMPTY_CATEGORY))
	else:
		content_list.add_child(_build_secondary_detail(_active_tab, active_secondary_key))

	SceneSecondarySubmenu.refresh(_secondary_buttons, active_secondary_key)


func _build_secondary_items(tab_key: String) -> Array:
	match tab_key:
		TAB_COLLISION_COIN:
			return COLLISION_COIN_ITEMS
		TAB_DIAMOND_STORE:
			return DIAMOND_STORE_ITEMS
		_:
			var groups: Array = _get_bundle_groups_for_tab(tab_key)
			if not groups.is_empty():
				var group_items: Array = []
				for group_variant: Variant in groups:
					if group_variant is Dictionary:
						var group: Dictionary = group_variant
						group_items.append({
							"key": str(group.get("groupId", "")),
							"label": str(group.get("displayName", UiText.SHOP_BUNDLE_DEFAULT_NAME)),
						})
				return group_items
			var bundles: Array = _get_bundles_for_tab(tab_key)
			var items: Array = []
			for bundle: Dictionary in bundles:
				items.append({
					"key": str(bundle.get("bundleId", "")),
					"label": str(bundle.get("displayName", UiText.SHOP_BUNDLE_DEFAULT_NAME)),
				})
			return items


func _ensure_active_secondary_key(tab_key: String, items: Array) -> String:
	if items.is_empty():
		_active_secondary_keys.erase(tab_key)
		return ""
	var current_key: String = str(_active_secondary_keys.get(tab_key, ""))
	for item_variant: Variant in items:
		if item_variant is Dictionary and str(item_variant.get("key", "")) == current_key:
			return current_key
	var first_item: Dictionary = items[0]
	var first_key: String = str(first_item.get("key", ""))
	_active_secondary_keys[tab_key] = first_key
	return first_key


func _build_secondary_detail(tab_key: String, item_key: String) -> Control:
	match tab_key:
		TAB_COLLISION_COIN:
			return _build_collision_coin_card(_get_collision_coin_item(item_key))
		TAB_DIAMOND_STORE:
			if item_key == "arena_ticket":
				return _build_arena_ticket_card()
			return _build_trap_cage_card()
		_:
			if not _get_bundle_groups_for_tab(tab_key).is_empty():
				return _build_bundle_group_detail(tab_key, item_key)
			return _build_bundle_detail_card(_get_bundle_by_id(item_key))


func _build_bundle_group_detail(tab_key: String, group_id: String) -> Control:
	var bundles: Array = _get_bundles_for_group(tab_key, group_id)
	if bundles.is_empty():
		return _build_empty_state(UiText.SHOP_EMPTY_CATEGORY)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)

	for bundle_variant: Variant in bundles:
		if bundle_variant is Dictionary:
			root.add_child(_build_bundle_detail_card(bundle_variant))

	return root


func _build_bundle_detail_card(bundle: Dictionary) -> Control:
	if bundle.is_empty():
		return _build_empty_state(UiText.SHOP_EMPTY_CATEGORY)

	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	panel.add_child(margin)

	var card: VBoxContainer = VBoxContainer.new()
	card.add_theme_constant_override("separation", 12)
	margin.add_child(card)

	var bundle_art: Texture2D = AssetResolver.resolve_bundle_art(bundle)
	if bundle_art != null:
		var art_shell: PanelContainer = OverlaySceneChrome.make_card_panel(
			OverlaySceneChrome.CARD_BORDER,
			Color(0.14, 0.13, 0.15, 0.98),
			16
		)
		art_shell.custom_minimum_size = Vector2(0.0, 216.0)
		card.add_child(art_shell)

		var art: TextureRect = TextureRect.new()
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.texture = bundle_art
		art_shell.add_child(art)

		var art_overlay: ColorRect = ColorRect.new()
		art_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art_overlay.color = Color(0.02, 0.02, 0.03, 0.22)
		art_shell.add_child(art_overlay)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	card.add_child(title_row)

	var title: Label = Label.new()
	title.text = str(bundle.get("displayName", UiText.SHOP_BUNDLE_DEFAULT_NAME))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	title_row.add_child(title)

	var stock_label: Label = Label.new()
	stock_label.text = _build_limit_text(bundle)
	stock_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	stock_label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.48, 1.0))
	title_row.add_child(stock_label)

	var desc: Label = Label.new()
	desc.text = str(bundle.get("description", UiText.SHOP_BUNDLE_NO_DESC))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	card.add_child(desc)

	var reward_title: Label = Label.new()
	reward_title.text = UiText.SHOP_REWARD_TITLE
	reward_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	card.add_child(reward_title)

	for reward_line: String in _build_reward_lines(bundle):
		var reward_label: Label = Label.new()
		reward_label.text = reward_line
		reward_label.add_theme_font_size_override("font_size", 17)
		reward_label.add_theme_color_override("font_color", Color(0.84, 0.94, 1.0, 1.0))
		card.add_child(reward_label)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	card.add_child(action_row)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)

	var action_button: Button = Button.new()
	action_button.custom_minimum_size = Vector2(BUNDLE_ACTION_WIDTH, 48.0)
	action_button.text = _build_bundle_button_text(bundle)
	if bool(bundle.get("isSoldOut", false)):
		action_button.disabled = true
		UiPalette.apply_button_kind(action_button, "neutral")
	else:
		UiPalette.apply_button_kind(action_button, "confirm")
		action_button.pressed.connect(func() -> void:
			_confirm_bundle_purchase(bundle)
		)
	RedDotService.refresh_dot(action_button, RedDotService.has_shop_bundle_red_dot(bundle) and not action_button.disabled)
	action_row.add_child(action_button)

	return panel


func _build_collision_coin_card(item: Dictionary) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var coin_texture: Texture2D = AssetResolver.load_texture(COLLISION_COIN_ICON_PATH)
	if coin_texture != null:
		var icon_shell: PanelContainer = OverlaySceneChrome.make_card_panel(
			OverlaySceneChrome.CARD_BORDER,
			Color(0.11, 0.09, 0.15, 0.98),
			18
		)
		icon_shell.custom_minimum_size = Vector2(140.0, 140.0)
		icon_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		root.add_child(icon_shell)

		var icon_margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
		icon_shell.add_child(icon_margin)

		var icon: TextureRect = AssetResolver.create_icon_rect(coin_texture, Vector2(112.0, 112.0))
		icon_margin.add_child(icon)

	var title: Label = Label.new()
	title.text = str(item.get("label", UiText.SHOP_COIN_PACK_TITLE))
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	root.add_child(title)

	var amount: int = int(item.get("amount", 0))
	var desc: Label = Label.new()
	desc.text = UiText.SHOP_COIN_PACK_DESC + "\n" + (UiText.SHOP_COLLISION_COIN_TEMP_PURCHASE_NOTICE % [amount, amount])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	root.add_child(desc)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	root.add_child(action_row)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)

	var button: Button = Button.new()
	button.text = UiText.SHOP_NT_PRICE_FORMAT % amount
	button.custom_minimum_size = Vector2(BUNDLE_ACTION_WIDTH, 48.0)
	UiPalette.apply_button_kind(button, "primary")
	button.pressed.connect(func() -> void:
		_confirm_collision_coin_purchase(item)
	)
	action_row.add_child(button)

	return panel


func _build_trap_cage_card() -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = UiText.SHOP_TRAP_CAGE_ITEM_TITLE
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	root.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.SHOP_TRAP_CAGE_ITEM_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	root.add_child(desc)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	root.add_child(action_row)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)

	var button: Button = Button.new()
	button.text = UiText.SHOP_ACTION_BUY
	button.custom_minimum_size = Vector2(BUNDLE_ACTION_WIDTH, 48.0)
	button.pressed.connect(_open_trap_cage_quantity_dialog)
	UiPalette.apply_button_kind(button, "primary")
	action_row.add_child(button)

	return panel


func _build_arena_ticket_card() -> Control:
	var overview: Dictionary = GameState.arena_overview_data
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = UiText.SHOP_ARENA_TICKET_TITLE
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	root.add_child(title)

	var desc: Label = Label.new()
	desc.text = _build_arena_ticket_desc(overview)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	root.add_child(desc)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	root.add_child(action_row)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)

	var button: Button = Button.new()
	button.text = _build_arena_ticket_button_text(overview)
	button.custom_minimum_size = Vector2(BUNDLE_ACTION_WIDTH, 48.0)
	if _can_purchase_arena_tickets(overview):
		button.pressed.connect(_purchase_arena_tickets)
		UiPalette.apply_button_kind(button, "primary")
	else:
		button.disabled = true
		UiPalette.apply_button_kind(button, "neutral")
	action_row.add_child(button)

	return panel


func _build_empty_state(message: String) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.CARD_BORDER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	panel.add_child(margin)

	var label: Label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	margin.add_child(label)

	return panel


func _open_trap_cage_quantity_dialog() -> void:
	_close_trap_cage_quantity_dialog()
	_trap_cage_quantity = 1

	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(480.0, 0.0)
	content.add_theme_constant_override("separation", 14)

	var desc: Label = Label.new()
	desc.text = UiText.SHOP_TRAP_CAGE_QUANTITY_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	content.add_child(desc)

	var quantity_row: HBoxContainer = HBoxContainer.new()
	quantity_row.add_theme_constant_override("separation", 10)
	content.add_child(quantity_row)

	var minus_button: Button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(60.0, 56.0)
	minus_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	quantity_row.add_child(minus_button)

	_trap_cage_quantity_button = Button.new()
	_trap_cage_quantity_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trap_cage_quantity_button.custom_minimum_size = Vector2(220.0, 56.0)
	_trap_cage_quantity_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	quantity_row.add_child(_trap_cage_quantity_button)

	var plus_button: Button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(60.0, 56.0)
	plus_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	quantity_row.add_child(plus_button)

	_trap_cage_preview_label = Label.new()
	_trap_cage_preview_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	_trap_cage_preview_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	content.add_child(_trap_cage_preview_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	content.add_child(button_row)

	var cancel_button: Button = Button.new()
	cancel_button.text = UiText.COMMON_CANCEL
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.custom_minimum_size = Vector2(0.0, 46.0)
	cancel_button.pressed.connect(_close_trap_cage_quantity_dialog)
	UiPalette.apply_button_kind(cancel_button, "danger")
	button_row.add_child(cancel_button)

	var confirm_button: Button = Button.new()
	confirm_button.text = UiText.SHOP_DIRECT_BUY_BUTTON
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.custom_minimum_size = Vector2(0.0, 46.0)
	confirm_button.pressed.connect(_confirm_trap_cage_quantity_purchase)
	UiPalette.apply_button_kind(confirm_button, "primary")
	button_row.add_child(confirm_button)

	minus_button.pressed.connect(_decrement_trap_cage_quantity)
	plus_button.pressed.connect(_increment_trap_cage_quantity)
	_trap_cage_quantity_button.pressed.connect(_open_trap_cage_keypad_dialog)

	_refresh_trap_cage_quantity_ui()
	_trap_cage_quantity_dialog_close = DialogManager.show_info_node(
		UiText.SHOP_TRAP_CAGE_QUANTITY_TITLE,
		content,
		Callable(self, "_on_trap_cage_quantity_dialog_closed"),
		"medium"
	)


func _open_quantity_keypad(anchor: Control, initial_value: int, on_submit: Callable) -> Callable:
	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(320.0, 0.0)
	content.add_theme_constant_override("separation", 12)

	var display: Label = Label.new()
	display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display.custom_minimum_size = Vector2(0.0, 52.0)
	display.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	display.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	content.add_child(display)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	var state := {"buffer": "" if initial_value <= 0 else str(initial_value)}
	var close_dialog: Callable = Callable()
	var ok_button: Button = null
	var refresh_display := func() -> void:
		display.text = state["buffer"] if str(state["buffer"]) != "" else "0"
		var has_value: bool = str(state["buffer"]) != "" and int(str(state["buffer"])) > 0
		if ok_button != null:
			ok_button.disabled = not has_value

	for key_label: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]:
		var button: Button = Button.new()
		button.text = key_label
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
		if key_label == "OK":
			ok_button = button
			UiPalette.apply_button_kind(button, "primary")
			button.disabled = true
		elif key_label == "C":
			UiPalette.apply_button_kind(button, "neutral")
		grid.add_child(button)
		button.pressed.connect(func() -> void:
			match key_label:
				"C":
					state["buffer"] = ""
				"OK":
					if str(state["buffer"]) == "" or int(str(state["buffer"])) <= 0:
						refresh_display.call()
						return
					var value: int = int(str(state["buffer"]))
					if on_submit.is_valid():
						on_submit.call(value)
					if close_dialog.is_valid():
						var dialog_close: Callable = close_dialog
						close_dialog = Callable()
						dialog_close.call()
					return
				_:
					var candidate: String = str(state["buffer"]) + key_label
					if int(candidate) <= 999:
						state["buffer"] = candidate
			refresh_display.call()
		)

	refresh_display.call()
	close_dialog = DialogManager.show_info_node(
		UiText.SHOP_TRAP_CAGE_QUANTITY_TITLE,
		content,
		Callable(),
		"small"
	)
	return func() -> void:
		if close_dialog.is_valid():
			var dialog_close: Callable = close_dialog
			close_dialog = Callable()
			dialog_close.call()


func _purchase_trap_cages(quantity: int) -> void:
	_api_client.purchase_trap_cages(quantity, func(success: bool, _data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SHOP_PURCHASE_FAILED_TITLE, str(error.get("message", UiText.SHOP_TRAP_CAGE_PURCHASE_FAILED_BODY)))
			return
		refresh_from_bootstrap(false)
		ToastManager.success(UiText.SHOP_PURCHASE_SUCCESS_TITLE, UiText.SHOP_TRAP_CAGE_PURCHASE_SUCCESS_BODY)
	)


func _confirm_collision_coin_purchase(item: Dictionary) -> void:
	var amount: int = int(item.get("amount", 0))
	if amount <= 0:
		return
	var message: String = UiText.SHOP_COLLISION_COIN_PURCHASE_CONFIRM_BODY % [amount, amount]
	DialogManager.show_confirm(
		UiText.SHOP_COLLISION_COIN_PURCHASE_TITLE,
		message,
		func() -> void:
			_purchase_collision_coin(amount)
	)


func _purchase_collision_coin(amount: int) -> void:
	_api_client.purchase_trap_points(amount, func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SHOP_PURCHASE_FAILED_TITLE, str(error.get("message", UiText.SHOP_COLLISION_COIN_PURCHASE_FAILED_BODY)))
			return
		var payload: Dictionary = data if data is Dictionary else {}
		var overview: Dictionary = payload.get("overview", {})
		if not overview.is_empty():
			GameState.update_shop(overview)
		_refresh_content()
		ToastManager.success(UiText.SHOP_PURCHASE_SUCCESS_TITLE, UiText.SHOP_COLLISION_COIN_PURCHASE_SUCCESS_BODY % amount)
	)


func _refresh_trap_cage_quantity_ui() -> void:
	_trap_cage_quantity = clampi(_trap_cage_quantity, 1, 999)
	if _trap_cage_quantity_button != null:
		_trap_cage_quantity_button.text = str(_trap_cage_quantity)
	if _trap_cage_preview_label != null:
		_trap_cage_preview_label.text = UiText.SHOP_TRAP_CAGE_TOTAL_COST_FORMAT % [
			_trap_cage_quantity,
			_trap_cage_quantity * TRAP_CAGE_DIAMOND_COST,
		]


func _decrement_trap_cage_quantity() -> void:
	_trap_cage_quantity = maxi(1, _trap_cage_quantity - 1)
	_refresh_trap_cage_quantity_ui()


func _increment_trap_cage_quantity() -> void:
	_trap_cage_quantity = mini(999, _trap_cage_quantity + 1)
	_refresh_trap_cage_quantity_ui()


func _open_trap_cage_keypad_dialog() -> void:
	_close_trap_cage_keypad()
	if _trap_cage_quantity_button == null:
		return
	_trap_cage_keypad_close = _open_quantity_keypad(
		_trap_cage_quantity_button,
		0,
		Callable(self, "_set_trap_cage_quantity")
	)


func _set_trap_cage_quantity(value: int) -> void:
	_trap_cage_quantity = clampi(value, 1, 999)
	_refresh_trap_cage_quantity_ui()


func _confirm_trap_cage_quantity_purchase() -> void:
	var quantity: int = _trap_cage_quantity
	_close_trap_cage_quantity_dialog()
	_purchase_trap_cages(quantity)


func _close_trap_cage_keypad() -> void:
	if _trap_cage_keypad_close.is_valid():
		var close_callable: Callable = _trap_cage_keypad_close
		_trap_cage_keypad_close = Callable()
		close_callable.call()


func _close_trap_cage_quantity_dialog() -> void:
	_close_trap_cage_keypad()
	if _trap_cage_quantity_dialog_close.is_valid():
		var close_callable: Callable = _trap_cage_quantity_dialog_close
		_trap_cage_quantity_dialog_close = Callable()
		close_callable.call()
	_on_trap_cage_quantity_dialog_closed()


func _on_trap_cage_quantity_dialog_closed() -> void:
	_trap_cage_quantity_dialog_close = Callable()
	_trap_cage_keypad_close = Callable()
	_trap_cage_quantity_button = null
	_trap_cage_preview_label = null


func _purchase_arena_tickets() -> void:
	_api_client.purchase_arena_tickets(func(success: bool, data: Variant, error: Dictionary) -> void:
		if not success:
			ToastManager.error(UiText.SHOP_PURCHASE_FAILED_TITLE, str(error.get("message", UiText.SHOP_ARENA_TICKET_PURCHASE_FAILED_BODY)))
			return
		if data is Dictionary:
			var response: Dictionary = data
			var overview: Dictionary = response.get("overview", {})
			if not overview.is_empty():
				GameState.update_arena(overview)
		refresh_from_bootstrap(false)
		ToastManager.success(UiText.SHOP_PURCHASE_SUCCESS_TITLE, UiText.SHOP_ARENA_TICKET_TITLE)
	)


func _confirm_bundle_purchase(bundle: Dictionary) -> void:
	var bundle_id: int = int(bundle.get("bundleId", 0))
	var bundle_name: String = str(bundle.get("displayName", UiText.SHOP_BUNDLE_DEFAULT_NAME))
	var price_amount: int = int(bundle.get("priceAmount", 0))
	_pending_bundle_purchase = bundle.duplicate(true)
	var message: String = UiText.SHOP_BUNDLE_PURCHASE_CONFIRM_BODY % [price_amount, bundle_name]
	DialogManager.show_confirm(UiText.SHOP_PURCHASE_BUNDLE_TITLE, message, func() -> void:
		_api_client.purchase_shop_bundle(bundle_id, _on_bundle_purchase_completed)
	)


func _on_bundle_purchase_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		if _should_redirect_to_collision_coin_store(error):
			DialogManager.show_confirm(
				UiText.SHOP_COLLISION_COIN_SHORTAGE_TITLE,
				UiText.SHOP_COLLISION_COIN_SHORTAGE_BODY,
				func() -> void:
					_pending_bundle_purchase.clear()
					_active_tab = TAB_COLLISION_COIN
					_active_secondary_keys[TAB_COLLISION_COIN] = "coin_33"
					_refresh_content()
			)
			return
		_pending_bundle_purchase.clear()
		ToastManager.error(UiText.SHOP_PURCHASE_FAILED_TITLE, str(error.get("message", UiText.SHOP_BUNDLE_PURCHASE_FAILED_BODY)))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	_pending_bundle_purchase.clear()
	refresh_from_bootstrap(false)

	var reward_lines: Array[String] = []
	var rewards_variant: Variant = payload.get("grantedRewards", [])
	if rewards_variant is Array:
		for reward_variant: Variant in rewards_variant:
			if reward_variant is Dictionary:
				var reward: Dictionary = reward_variant
				reward_lines.append(UiText.SHOP_REWARD_LINE_FORMAT % [
					str(reward.get("rewardDisplayName", reward.get("rewardType", UiText.SHOP_REWARD_FALLBACK_NAME))),
					int(reward.get("quantity", 0)),
				])
	if reward_lines.is_empty():
		reward_lines.append(UiText.SHOP_REWARD_SENT)
	ToastManager.success(UiText.SHOP_PURCHASE_SUCCESS_TITLE, " / ".join(reward_lines))


func _should_redirect_to_collision_coin_store(error: Dictionary) -> bool:
	if str(error.get("code", "")) != "SHOP.NOT_ENOUGH_PAYMENT_CURRENCY":
		return false
	return int(_pending_bundle_purchase.get("priceCurrencyId", 0)) == 3


func _get_bundles_for_tab(tab_key: String) -> Array:
	var category_type: String = _get_category_type(tab_key)
	var result: Array = []
	for bundle_variant: Variant in GameState.shop_data.get("bundles", []):
		if not (bundle_variant is Dictionary):
			continue
		var bundle: Dictionary = bundle_variant
		if str(bundle.get("categoryType", "")).to_lower() == category_type:
			result.append(bundle)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_sold_out: bool = bool(a.get("isSoldOut", false))
		var b_sold_out: bool = bool(b.get("isSoldOut", false))
		if a_sold_out != b_sold_out:
			return not a_sold_out
		return int(a.get("sortOrder", 0)) < int(b.get("sortOrder", 0))
	)
	return result


func _get_bundle_groups_for_tab(tab_key: String) -> Array:
	var category_type: String = _get_category_type(tab_key)
	if category_type == "":
		return []
	var result: Array = []
	for group_variant: Variant in GameState.shop_data.get("bundleGroups", []):
		if not (group_variant is Dictionary):
			continue
		var group: Dictionary = group_variant
		if str(group.get("categoryType", "")).to_lower() != category_type:
			continue
		result.append(group)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sortOrder", 0)) < int(b.get("sortOrder", 0))
	)
	return result


func _get_bundles_for_group(tab_key: String, group_id: String) -> Array:
	var result: Array = []
	for bundle_variant: Variant in _get_bundles_for_tab(tab_key):
		if bundle_variant is Dictionary and str(bundle_variant.get("groupId", "")) == group_id:
			result.append(bundle_variant)
	return result


func _get_bundle_by_id(bundle_id: String) -> Dictionary:
	for bundle_variant: Variant in GameState.shop_data.get("bundles", []):
		if bundle_variant is Dictionary and str(bundle_variant.get("bundleId", "")) == bundle_id:
			return bundle_variant
	return {}


func _build_limit_text(bundle: Dictionary) -> String:
	var purchase_count: int = int(bundle.get("purchaseCount", 0))
	var purchase_limit: int = int(bundle.get("purchaseLimit", 0))
	if bool(bundle.get("isSoldOut", false)):
		return UiText.SHOP_OUT_OF_STOCK
	if purchase_limit <= 0:
		return UiText.SHOP_PURCHASED_COUNT_FORMAT % purchase_count
	var remaining: int = maxi(0, purchase_limit - purchase_count)
	return UiText.SHOP_CAN_PURCHASE_FORMAT % [remaining, purchase_limit]


func _build_bundle_button_text(bundle: Dictionary) -> String:
	if bool(bundle.get("isSoldOut", false)):
		return UiText.SHOP_OUT_OF_STOCK
	return UiText.SHOP_COLLISION_COIN_FORMAT % int(bundle.get("priceAmount", 0))


func _refresh_red_dots() -> void:
	for tab_key_variant: Variant in _tab_buttons.keys():
		var tab_key: String = str(tab_key_variant)
		var tab_button: Control = _tab_buttons.get(tab_key, null)
		if tab_button == null:
			continue
		RedDotService.refresh_dot(tab_button, _has_shop_tab_red_dot(tab_key))

	for secondary_key_variant: Variant in _secondary_buttons.keys():
		var secondary_key: String = str(secondary_key_variant)
		var secondary_button: Control = _secondary_buttons.get(secondary_key, null)
		if secondary_button == null:
			continue
		RedDotService.refresh_dot(secondary_button, _has_shop_secondary_red_dot(_active_tab, secondary_key))


func _has_shop_tab_red_dot(tab_key: String) -> bool:
	for bundle_variant: Variant in _get_bundles_for_tab(tab_key):
		if not (bundle_variant is Dictionary):
			continue
		var bundle: Dictionary = bundle_variant
		if RedDotService.has_shop_bundle_red_dot(bundle):
			return true
	return false


func _has_shop_secondary_red_dot(tab_key: String, item_key: String) -> bool:
	match tab_key:
		TAB_COLLISION_COIN, TAB_DIAMOND_STORE:
			return false
		_:
			pass

	var bundle_groups: Array = _get_bundle_groups_for_tab(tab_key)
	if not bundle_groups.is_empty():
		for bundle_variant: Variant in _get_bundles_for_group(tab_key, item_key):
			if not (bundle_variant is Dictionary):
				continue
			var bundle: Dictionary = bundle_variant
			if RedDotService.has_shop_bundle_red_dot(bundle):
				return true
		return false

	return RedDotService.has_shop_bundle_red_dot(_get_bundle_by_id(item_key))


func _build_reward_lines(bundle: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var rewards_variant: Variant = bundle.get("rewards", [])
	if rewards_variant is Array:
		for reward_variant: Variant in rewards_variant:
			if reward_variant is Dictionary:
				var reward: Dictionary = reward_variant
				result.append(UiText.SHOP_REWARD_LINE_FORMAT % [
					str(reward.get("rewardDisplayName", reward.get("rewardType", UiText.SHOP_REWARD_FALLBACK_NAME))),
					int(reward.get("quantity", 0)),
				])
	return result


func _build_arena_ticket_desc(overview: Dictionary) -> String:
	var purchase_count: int = int(overview.get("dailyPurchaseCount", 0))
	var max_purchase_count: int = int(overview.get("maxDailyPurchaseCount", 5))
	var tickets_per_purchase: int = int(overview.get("ticketsPerPurchase", 3))
	var costs: Array = overview.get("ticketPurchaseCosts", [])
	var current_cost: int = int(costs[purchase_count]) if purchase_count < costs.size() else -1
	if current_cost > 0:
		return UiText.SHOP_ARENA_TICKET_DESC_WITH_COST % [current_cost, tickets_per_purchase, max_purchase_count - purchase_count]
	return UiText.SHOP_ARENA_TICKET_DESC_EMPTY


func _build_arena_ticket_button_text(overview: Dictionary) -> String:
	if not _can_purchase_arena_tickets(overview):
		return UiText.SHOP_OUT_OF_STOCK
	var purchase_count: int = int(overview.get("dailyPurchaseCount", 0))
	var costs: Array = overview.get("ticketPurchaseCosts", [])
	var current_cost: int = int(costs[purchase_count]) if purchase_count < costs.size() else 0
	return UiText.SHOP_DIAMOND_COST_FORMAT % current_cost


func _can_purchase_arena_tickets(overview: Dictionary) -> bool:
	if overview.is_empty():
		return false
	var purchase_count: int = int(overview.get("dailyPurchaseCount", 0))
	var max_purchase_count: int = int(overview.get("maxDailyPurchaseCount", 5))
	if purchase_count >= max_purchase_count:
		return false
	var costs: Array = overview.get("ticketPurchaseCosts", [])
	if purchase_count >= costs.size():
		return false
	return int(costs[purchase_count]) > 0


func _get_collision_coin_item(item_key: String) -> Dictionary:
	for item: Dictionary in COLLISION_COIN_ITEMS:
		if str(item.get("key", "")) == item_key:
			return item
	return COLLISION_COIN_ITEMS[0]


func _get_category_type(tab_key: String) -> String:
	for config: Dictionary in CATEGORY_CONFIGS:
		if str(config.get("key", "")) == tab_key:
			return str(config.get("category_type", "")).to_lower()
	return ""


func _get_top_label(tab_key: String) -> String:
	match tab_key:
		TAB_VALUE:
			return UiText.SHOP_SUBMENU_VALUE
		TAB_GROWTH:
			return UiText.SHOP_SUBMENU_GROWTH
		TAB_DAILY:
			return UiText.SHOP_SUBMENU_DAILY
		TAB_COLLISION_COIN:
			return UiText.SHOP_SUBMENU_COLLISION_COIN
		TAB_DIAMOND_STORE:
			return UiText.SHOP_SUBMENU_DIAMOND_STORE
		TAB_POINT:
			return UiText.SHOP_SUBMENU_POINT
		_:
			return UiText.NAV_SHOP


func _get_tab_meta(tab_key: String) -> Dictionary:
	match tab_key:
		TAB_VALUE:
			return {"title": UiText.SHOP_SUBMENU_VALUE, "description": UiText.SHOP_TAB_DESC_VALUE}
		TAB_GROWTH:
			return {"title": UiText.SHOP_SUBMENU_GROWTH, "description": UiText.SHOP_TAB_DESC_GROWTH}
		TAB_DAILY:
			return {"title": UiText.SHOP_SUBMENU_DAILY, "description": UiText.SHOP_TAB_DESC_DAILY}
		TAB_COLLISION_COIN:
			return {"title": UiText.SHOP_SUBMENU_COLLISION_COIN, "description": UiText.SHOP_TAB_DESC_COLLISION_COIN}
		TAB_DIAMOND_STORE:
			return {"title": UiText.SHOP_SUBMENU_DIAMOND_STORE, "description": UiText.SHOP_TAB_DESC_DIAMOND_STORE}
		TAB_POINT:
			return {"title": UiText.SHOP_SUBMENU_POINT, "description": UiText.SHOP_TAB_DESC_POINT}
		_:
			return {"title": UiText.NAV_SHOP, "description": UiText.SHOP_PAGE_DESC}


func _get_shell_summary_left() -> String:
	return UiText.SHOP_RESOURCE_WITH_COLLISION_COIN_FORMAT % [
		GameState.player_data.diamonds,
		GameState.player_data.trap_points,
		GameState.player_data.trap_cages,
	]


func _build_tab_summary_right(tab_key: String) -> String:
	var item_count: int = _build_secondary_items(tab_key).size()
	return "\u9805\u76ee %d" % item_count


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
