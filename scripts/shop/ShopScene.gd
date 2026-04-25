extends Control

const ITEM_SLOT_TEMPLATE = preload("res://scenes/ui/backpack/ItemSlotTemplate.tscn")

const TAB_VALUE := "value_bundle"
const TAB_GROWTH := "growth_bundle"
const TAB_DAILY := "daily_bundle"
const TAB_COLLISION_COIN := "collision_coin"
const TAB_DIAMOND_STORE := "diamond_store"
const TAB_POINT := "point_bundle"
const TRAP_POINTS_CURRENCY_ID := 3
const COLLISION_COIN_ICON_PATH := "res://assets/sprites/ui/rewards/collision_coin.png"
const ARENA_TICKET_ICON_PATH := "res://assets/sprites/ui/rewards/arena_ticket.png"

const CATEGORY_CONFIGS := [
	{"key": TAB_VALUE, "label": "SHOP_SUBMENU_VALUE", "category_type": "valuepack"},
	{"key": TAB_COLLISION_COIN, "label": "SHOP_SUBMENU_COLLISION_COIN"},
	{"key": TAB_DIAMOND_STORE, "label": "SHOP_SUBMENU_DIAMOND_STORE"},
	{"key": TAB_POINT, "label": "SHOP_SUBMENU_POINT", "category_type": "pointpack"},
]

const COLLISION_COIN_ITEMS := [
	{"key": "coin_33", "label": "33" + UiText.SHOP_SUBMENU_COLLISION_COIN, "amount": 33},
	{"key": "coin_170", "label": "170" + UiText.SHOP_SUBMENU_COLLISION_COIN, "amount": 170},
	{"key": "coin_330", "label": "330" + UiText.SHOP_SUBMENU_COLLISION_COIN, "amount": 330},
	{"key": "coin_490", "label": "490" + UiText.SHOP_SUBMENU_COLLISION_COIN, "amount": 490},
	{"key": "coin_990", "label": "990" + UiText.SHOP_SUBMENU_COLLISION_COIN, "amount": 990},
	{"key": "coin_1690", "label": "1690" + UiText.SHOP_SUBMENU_COLLISION_COIN, "amount": 1690},
	{"key": "coin_3290", "label": "3290" + UiText.SHOP_SUBMENU_COLLISION_COIN, "amount": 3290},
]

const DIAMOND_STORE_ITEMS := [
	{"key": "trap_cage", "label": UiText.SHOP_DIAMOND_STORE_TRAP_CAGE},
	{"key": "arena_ticket", "label": UiText.SHOP_DIAMOND_STORE_ARENA_TICKET},
]

const TRAP_CAGE_DIAMOND_COST := 100
const BUNDLE_ACTION_WIDTH := 220.0
const SHOP_PANEL_FILL := Color(0.16, 0.15, 0.18, 0.25)
const SHOP_PAGE_SIDE_MARGIN := 10
const SHOP_REWARD_SLOT_BASE_SIZE := Vector2(512.0, 512.0)
const SHOP_REWARD_SLOT_SCALE := 0.20
const SHOP_REWARD_SLOT_CELL_SIZE := Vector2(118.0, 96.0)
const SHOP_REWARD_SLOT_GAP := 10
const SHOP_PRICE_FILL := Color(0.15, 0.17, 0.21, 0.92)
const SHOP_PRICE_BORDER := Color(0.43, 0.56, 0.68, 0.95)
const SHOP_DISCOUNT_FILL := Color(0.88, 0.27, 0.25, 0.96)
const SHOP_DISCOUNT_BORDER := Color(1.0, 0.87, 0.72, 0.98)
const SHOP_DISCOUNT_TEXT := Color(1.0, 0.97, 0.92, 1.0)
const SHOP_PRICE_LABEL_NTD := "NTD"
const SHOP_BUTTON_ICON_SIZE := Vector2(36.0, 36.0)
const DIAMOND_STORE_MAX_QUANTITY := 999999
const SHOP_PRICE_INSUFFICIENT_COLOR := Color(0.95, 0.36, 0.36, 1.0)
var _active_tab: String = TAB_VALUE
var _active_secondary_keys: Dictionary = {}
var _tab_buttons: Dictionary = {}
var _secondary_buttons: Dictionary = {}
var _content_host: Control
var _diamond_store_quantities: Dictionary = {}
var _diamond_store_keypad_close: Callable = Callable()
var _diamond_store_dialog_close: Callable = Callable()
var _pending_bundle_purchase: Dictionary = {}
var _paid_shop_enabled: bool = true

@onready var _api_client = get_node("/root/ApiClient")


func _ready() -> void:
	_paid_shop_enabled = RuntimeConfig.is_paid_shop_enabled()
	_normalize_active_tab()
	_build_ui()
	GameState.red_dot_state_changed.connect(_refresh_red_dots)
	_refresh_content()


func _build_ui() -> void:
	var dock_items: Array = []
	for item: Dictionary in _get_visible_category_configs():
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
		"panel_fill": SHOP_PANEL_FILL,
	})
	_tab_buttons = chrome.get("dock_buttons", {})

	var content_box: VBoxContainer = chrome.get("content_box")

	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_margin.add_theme_constant_override("margin_left", SHOP_PAGE_SIDE_MARGIN)
	page_margin.add_theme_constant_override("margin_right", SHOP_PAGE_SIDE_MARGIN)
	content_box.add_child(page_margin)

	_content_host = Control.new()
	_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_margin.add_child(_content_host)


func refresh_from_bootstrap(show_error_dialog: bool = true) -> void:
	_api_client.get_authenticated_bootstrap_silent(Callable(self, "_on_shop_bootstrap_refreshed").bind(show_error_dialog))


func _on_shop_bootstrap_refreshed(success: bool, data: Variant, error: Dictionary, show_error_dialog: bool) -> void:
	if success and data is Dictionary:
		GameState.apply_player_bootstrap(data)
		_refresh_content()
		return
	if show_error_dialog:
		ToastManager.error(UiText.SHOP_LOAD_FAILED_TITLE, str(error.get("message", UiText.SHOP_LOAD_FAILED_BODY)))


func _switch_tab(tab_key: String) -> void:
	if not _is_tab_visible(tab_key):
		return
	if _active_tab == tab_key:
		return
	_active_tab = tab_key
	_refresh_content()


func _switch_secondary_item(item_key: String) -> void:
	_active_secondary_keys[_active_tab] = item_key
	_refresh_content()


func _refresh_content() -> void:
	_normalize_active_tab()
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
		"secondary_fill": SHOP_PANEL_FILL,
		"content_border": OverlaySceneChrome.CARD_BORDER,
		"content_fill": SHOP_PANEL_FILL,
		"content_vertical_scroll_mode": ScrollContainer.SCROLL_MODE_SHOW_ALWAYS,
	})
	_secondary_buttons = secondary_submenu.get("secondary_buttons", {})
	var content_list: VBoxContainer = secondary_submenu.get("content_list")

	if secondary_items.is_empty():
		content_list.add_child(_build_empty_state(UiText.SHOP_EMPTY_CATEGORY))
	else:
		content_list.add_child(_build_secondary_detail(_active_tab, active_secondary_key))

	SceneSecondarySubmenu.refresh(_secondary_buttons, active_secondary_key)


func _build_secondary_items(tab_key: String) -> Array:
	if not _is_tab_visible(tab_key):
		return []
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
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)

	for bundle_variant: Variant in bundles:
		if bundle_variant is Dictionary:
			root.add_child(_build_bundle_detail_card(bundle_variant))

	return root


func _build_bundle_detail_card(bundle: Dictionary) -> Control:
	if bundle.is_empty():
		return _build_empty_state(UiText.SHOP_EMPTY_CATEGORY)

	var panel: PanelContainer = _make_shop_panel(OverlaySceneChrome.PANEL_BORDER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	panel.add_child(margin)

	var card: VBoxContainer = VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	margin.add_child(card)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	card.add_child(title_row)

	var title: Label = Label.new()
	title.text = str(bundle.get("displayName", UiText.SHOP_BUNDLE_DEFAULT_NAME))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	title_row.add_child(title)

	var stock_label: Label = Label.new()
	stock_label.text = _build_limit_text(bundle)
	stock_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	stock_label.add_theme_color_override("font_color", Color(0.92, 0.80, 0.48, 1.0))
	title_row.add_child(stock_label)

	card.add_child(_build_bundle_reward_grid(bundle))

	var action_button: Button = Button.new()
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.custom_minimum_size = Vector2(0.0, 48.0)
	if bool(bundle.get("isSoldOut", false)):
		UiPalette.apply_button_kind(action_button, "neutral")
		_set_bundle_action_button_content(action_button, UiText.SHOP_OUT_OF_STOCK, "", UiPalette.BUTTON_DISABLED_FG)
		action_button.disabled = true
	else:
		UiPalette.apply_button_kind(action_button, "confirm")
		_configure_bundle_action_button(action_button, bundle)
		action_button.pressed.connect(Callable(self, "_confirm_bundle_purchase").bind(bundle))
	RedDotService.refresh_dot(action_button, RedDotService.has_shop_bundle_red_dot(bundle) and not action_button.disabled)
	card.add_child(action_button)

	return panel


func _build_bundle_reward_grid(bundle: Dictionary) -> Control:
	var rewards_variant: Variant = bundle.get("rewards", [])
	var rewards: Array = rewards_variant if rewards_variant is Array else []
	if rewards.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = UiText.SHOP_REWARD_SENT
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		empty_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		return empty_label

	var wrapper: CenterContainer = CenterContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var grid: GridContainer = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", SHOP_REWARD_SLOT_GAP)
	grid.add_theme_constant_override("v_separation", SHOP_REWARD_SLOT_GAP)
	var visible_columns: int = mini(5, rewards.size())
	grid.custom_minimum_size = Vector2(
		(SHOP_REWARD_SLOT_CELL_SIZE.x * visible_columns) + (SHOP_REWARD_SLOT_GAP * maxi(0, visible_columns - 1)),
		0.0
	)
	for reward_variant: Variant in rewards:
		if reward_variant is Dictionary:
			grid.add_child(_build_shop_reward_slot(reward_variant))
	wrapper.add_child(grid)
	return wrapper


func _build_shop_reward_slot(reward: Dictionary) -> Control:
	var texture_path: String = _resolve_shop_reward_image_path(reward)
	var display_name: String = str(reward.get("rewardDisplayName", reward.get("rewardType", UiText.SHOP_REWARD_FALLBACK_NAME)))
	var quantity: int = int(reward.get("quantity", 0))
	return _build_shop_slot_cell(texture_path, display_name, quantity)


func _build_centered_shop_slot(image_path: String, display_name: String, quantity: int) -> Control:
	var wrapper: CenterContainer = CenterContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(_build_shop_slot_cell(image_path, display_name, quantity))
	return wrapper


func _build_shop_slot_cell(image_path: String, display_name: String, quantity: int) -> Control:
	var slot: Control = ITEM_SLOT_TEMPLATE.instantiate() as Control
	var frame: TextureRect = slot.get_node("Frame") as TextureRect
	var icon: TextureRect = slot.get_node("ItemIcon") as TextureRect
	var overlay_mask: TextureRect = slot.get_node("OverlayMask") as TextureRect
	var name_label: Label = slot.get_node("ItemNameLabel") as Label
	var qty_label: Label = slot.get_node("CountLabel") as Label
	var texture: Texture2D = AssetResolver.resolve_texture_or_placeholder(image_path)

	if texture != null:
		icon.texture = texture
		icon.visible = true
	else:
		icon.visible = false

	frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
	overlay_mask.modulate = Color(1.0, 1.0, 1.0, 0.42)
	name_label.text = display_name
	name_label.tooltip_text = display_name
	name_label.visible = false
	qty_label.text = GameState.format_number(quantity)
	qty_label.tooltip_text = qty_label.text
	qty_label.add_theme_font_size_override("font_size", 58)

	slot.scale = Vector2(SHOP_REWARD_SLOT_SCALE, SHOP_REWARD_SLOT_SCALE)
	var scaled_size: Vector2 = SHOP_REWARD_SLOT_BASE_SIZE * SHOP_REWARD_SLOT_SCALE
	slot.position = Vector2(
		(SHOP_REWARD_SLOT_CELL_SIZE.x - scaled_size.x) * 0.5,
		0.0
	)

	var cell: Control = Control.new()
	cell.custom_minimum_size = SHOP_REWARD_SLOT_CELL_SIZE
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(slot)
	return cell


func _build_quantity_selector(item_key: String, quantity: int, max_quantity: int) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)

	var minus_button: Button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(54.0, 42.0)
	minus_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	UiPalette.apply_button_kind(minus_button, "minus")
	minus_button.disabled = quantity <= 1
	minus_button.pressed.connect(Callable(self, "_adjust_diamond_store_quantity").bind(item_key, -1, max_quantity))
	row.add_child(minus_button)

	var quantity_button: Button = Button.new()
	quantity_button.text = GameState.format_number(quantity)
	quantity_button.custom_minimum_size = Vector2(120.0, 42.0)
	quantity_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	quantity_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiPalette.apply_button_kind(quantity_button, "neutral")
	quantity_button.disabled = max_quantity <= 0
	quantity_button.pressed.connect(Callable(self, "_open_diamond_store_quantity_keypad").bind(item_key, max_quantity))
	row.add_child(quantity_button)

	var plus_button: Button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(54.0, 42.0)
	plus_button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	UiPalette.apply_button_kind(plus_button, "plus")
	plus_button.disabled = max_quantity <= 0 or quantity >= max_quantity
	plus_button.pressed.connect(Callable(self, "_adjust_diamond_store_quantity").bind(item_key, 1, max_quantity))
	row.add_child(plus_button)

	return row


func _get_diamond_store_quantity(item_key: String, max_quantity: int) -> int:
	if max_quantity <= 0:
		_diamond_store_quantities[item_key] = 0
		return 0

	var raw_quantity: int = int(_diamond_store_quantities.get(item_key, 1))
	var quantity: int = clampi(raw_quantity, 0, max_quantity)
	if quantity != raw_quantity:
		_diamond_store_quantities[item_key] = quantity
	return quantity


func _adjust_diamond_store_quantity(item_key: String, delta: int, max_quantity: int) -> void:
	if max_quantity <= 0:
		return

	var next_quantity: int = clampi(_get_diamond_store_quantity(item_key, max_quantity) + delta, 0, max_quantity)
	_diamond_store_quantities[item_key] = next_quantity
	_refresh_content()


func _open_diamond_store_quantity_keypad(item_key: String, max_quantity: int) -> void:
	if max_quantity <= 0:
		return

	var purchase_state: Dictionary = _get_diamond_store_purchase_state(item_key)
	_close_diamond_store_keypad()
	_diamond_store_keypad_close = _open_quantity_keypad(
		0,
		int(purchase_state.get("maxAffordableQuantity", max_quantity)),
		Callable(self, "_set_diamond_store_quantity").bind(item_key, max_quantity)
	)


func _set_diamond_store_quantity(value: int, item_key: String, max_quantity: int) -> void:
	if max_quantity <= 0:
		return

	_diamond_store_quantities[item_key] = clampi(value, 0, max_quantity)
	_close_diamond_store_keypad()
	_refresh_content()


func _close_diamond_store_keypad() -> void:
	if _diamond_store_keypad_close.is_valid():
		var close_callable: Callable = _diamond_store_keypad_close
		_diamond_store_keypad_close = Callable()
		close_callable.call()


func _close_quantity_keypad_dialog() -> void:
	if _diamond_store_dialog_close.is_valid():
		var dialog_close: Callable = _diamond_store_dialog_close
		_diamond_store_dialog_close = Callable()
		dialog_close.call()


func _refresh_quantity_keypad_display(state: Dictionary, display: Label) -> void:
	display.text = state["buffer"] if str(state["buffer"]) != "" else "0"


func _on_quantity_keypad_button_pressed(
	input_key: String,
	state: Dictionary,
	display: Label,
	max_allowed_value: int,
	on_submit: Callable
) -> void:
	match input_key:
		"C":
			state["buffer"] = "0"
		"OK":
			var value: int = clampi(int(str(state["buffer"])), 0, maxi(0, max_allowed_value))
			if on_submit.is_valid():
				on_submit.call(value)
			return
		_:
			var current_buffer: String = str(state["buffer"])
			var candidate: String = input_key if current_buffer == "0" else current_buffer + input_key
			if int(candidate) <= DIAMOND_STORE_MAX_QUANTITY:
				state["buffer"] = candidate
	_refresh_quantity_keypad_display(state, display)


func _open_quantity_keypad(initial_value: int, max_allowed_value: int, on_submit: Callable) -> Callable:
	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(320.0, 0.0)
	content.add_theme_constant_override("separation", 12)
	var normalized_initial_value: int = clampi(initial_value, 0, DIAMOND_STORE_MAX_QUANTITY)

	var max_label: Label = Label.new()
	max_label.text = UiText.SHOP_MAX_INPUT_FORMAT % GameState.format_number(maxi(0, max_allowed_value))
	max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	max_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	max_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	content.add_child(max_label)

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

	var state: Dictionary = {"buffer": str(normalized_initial_value)}
	_refresh_quantity_keypad_display(state, display)

	for key_label: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]:
		var input_key: String = key_label
		var button: Button = Button.new()
		button.text = input_key
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
		if input_key == "OK":
			UiPalette.apply_button_kind(button, "primary")
			button.disabled = false
		elif input_key == "C":
			UiPalette.apply_button_kind(button, "neutral")
		grid.add_child(button)
		button.pressed.connect(Callable(self, "_on_quantity_keypad_button_pressed").bind(input_key, state, display, max_allowed_value, on_submit))

	_diamond_store_dialog_close = DialogManager.show_info_node(
		UiText.SHOP_TRAP_CAGE_QUANTITY_TITLE,
		content,
		Callable(self, "_on_diamond_store_keypad_closed"),
		"small"
	)
	return Callable(self, "_close_quantity_keypad_dialog")


func _on_diamond_store_keypad_closed() -> void:
	_diamond_store_dialog_close = Callable()
	_diamond_store_keypad_close = Callable()


func _resolve_button_font_color(kind: String) -> Color:
	return UiPalette.get_button_palette(kind).get("fg", UiPalette.BUTTON_PRIMARY_FG)


func _get_owned_diamonds() -> int:
	if GameState.player_data != null:
		return int(GameState.player_data.diamonds)
	return int(GameState.shop_data.get("diamonds", GameState.arena_overview_data.get("diamonds", 0)))


func _get_trap_cage_affordable_quantity() -> int:
	return int(floor(float(_get_owned_diamonds()) / float(TRAP_CAGE_DIAMOND_COST)))


func _get_arena_ticket_affordable_quantity(overview: Dictionary) -> int:
	var remaining_purchase_count: int = _get_arena_ticket_remaining_purchase_count(overview)
	if remaining_purchase_count <= 0:
		return 0

	var diamonds: int = _get_owned_diamonds()
	var total_cost: int = 0
	for quantity in range(1, remaining_purchase_count + 1):
		total_cost = _get_arena_ticket_total_cost(overview, quantity)
		if total_cost > diamonds:
			return quantity - 1
	return remaining_purchase_count


func _get_diamond_store_purchase_state(item_key: String) -> Dictionary:
	var owned_diamonds: int = _get_owned_diamonds()
	match item_key:
		"arena_ticket":
			var overview: Dictionary = GameState.arena_overview_data
			var max_quantity: int = _get_arena_ticket_remaining_purchase_count(overview)
			var quantity: int = _get_diamond_store_quantity(item_key, max_quantity)
			var total_cost: int = _get_arena_ticket_total_cost(overview, quantity)
			return {
				"quantity": quantity,
				"totalCost": total_cost,
				"ownedCurrency": owned_diamonds,
				"maxQuantity": max_quantity,
				"maxAffordableQuantity": mini(max_quantity, _get_arena_ticket_affordable_quantity(overview)),
				"currencyName": str(UiText.REWARD_DIAMONDS),
			}
		_:
			var trap_quantity: int = _get_diamond_store_quantity(item_key, DIAMOND_STORE_MAX_QUANTITY)
			return {
				"quantity": trap_quantity,
				"totalCost": trap_quantity * TRAP_CAGE_DIAMOND_COST,
				"ownedCurrency": owned_diamonds,
				"maxQuantity": DIAMOND_STORE_MAX_QUANTITY,
				"maxAffordableQuantity": mini(DIAMOND_STORE_MAX_QUANTITY, _get_trap_cage_affordable_quantity()),
				"currencyName": str(UiText.REWARD_DIAMONDS),
			}


func _is_diamond_store_cost_affordable(purchase_state: Dictionary) -> bool:
	return int(purchase_state.get("totalCost", 0)) <= int(purchase_state.get("ownedCurrency", 0))


func _show_currency_shortage(currency_name: String) -> void:
	ToastManager.error(UiText.SHOP_PURCHASE_FAILED_TITLE, UiText.SHOP_CURRENCY_SHORTAGE_FORMAT % currency_name)

func _resolve_bundle_price_info(bundle: Dictionary) -> Dictionary:
	var currency_type: String = str(bundle.get("priceCurrencyType", "")).to_lower()
	var price_amount: int = int(bundle.get("priceAmount", 0))
	if price_amount <= 0:
		return {
			"text": UiText.SHOP_FREE_CLAIM,
			"amount": 0,
		}
	if currency_type == "diamonds":
		return {
			"iconPath": AssetResolver.resolve_catalog_path("catalog/currency/diamonds"),
			"amount": price_amount,
		}
	if currency_type == "trappoints":
		return {
			"iconPath": COLLISION_COIN_ICON_PATH,
			"amount": price_amount,
		}
	return {
		"prefixText": SHOP_PRICE_LABEL_NTD,
		"amount": price_amount,
	}


func _configure_bundle_action_button(button: Button, bundle: Dictionary) -> void:
	var price_info: Dictionary = _resolve_bundle_price_info(bundle)
	var button_text: String = str(price_info.get("text", ""))
	var icon_path: String = str(price_info.get("iconPath", ""))
	var prefix_text: String = str(price_info.get("prefixText", ""))
	var price_amount: int = int(price_info.get("amount", 0))
	var font_color: Color = UiPalette.get_button_palette("confirm").get("fg", UiPalette.BUTTON_PRIMARY_FG)

	button.text = ""
	button.icon = null
	button.expand_icon = false
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)

	if button_text != "":
		_set_bundle_action_button_content(button, button_text, "", font_color)
		return

	if prefix_text != "":
		_set_bundle_action_button_content(button, "%s %s" % [prefix_text, GameState.format_number(price_amount)], "", font_color)
		return

	_set_bundle_action_button_content(button, GameState.format_number(price_amount), icon_path, font_color)


func _set_bundle_action_button_content(button: Button, label_text: String, icon_path: String, font_color: Color) -> void:
	for child: Node in button.get_children():
		child.queue_free()

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(row)

	if icon_path != "":
		var icon_texture: Texture2D = AssetResolver.resolve_texture_or_placeholder(icon_path)
		if icon_texture != null:
			var icon: TextureRect = TextureRect.new()
			icon.custom_minimum_size = SHOP_BUTTON_ICON_SIZE
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture = icon_texture
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	label.add_theme_color_override("font_color", font_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)


func _resolve_shop_reward_image_path(reward: Dictionary) -> String:
	var raw_path: String = AssetResolver.resolve_catalog_path(str(reward.get("imagePath", "")))
	if raw_path != "":
		return raw_path

	var reward_type: String = str(reward.get("rewardType", "")).to_lower()
	match reward_type:
		"diamond":
			return AssetResolver.resolve_catalog_path("catalog/currency/diamonds")
		"trapcage":
			return AssetResolver.resolve_catalog_path("catalog/consumable/trap_cages")
		_:
			return ""


func _build_collision_coin_card(item: Dictionary) -> Control:
	var panel: PanelContainer = _make_shop_panel(OverlaySceneChrome.PANEL_BORDER)
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = str(item.get("label", UiText.SHOP_COIN_PACK_TITLE))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	root.add_child(title)

	var amount: int = int(item.get("amount", 0))
	root.add_child(_build_centered_shop_slot(COLLISION_COIN_ICON_PATH, UiText.SHOP_SUBMENU_COLLISION_COIN, amount))

	var button: Button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, 48.0)
	UiPalette.apply_button_kind(button, "confirm")
	_set_bundle_action_button_content(
		button,
		"%s %s" % [SHOP_PRICE_LABEL_NTD, GameState.format_number(amount)],
		"",
		_resolve_button_font_color("confirm")
	)
	button.pressed.connect(Callable(self, "_confirm_collision_coin_purchase").bind(item))
	root.add_child(button)

	return panel


func _build_trap_cage_card() -> Control:
	var panel: PanelContainer = _make_shop_panel(OverlaySceneChrome.PANEL_BORDER)
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var purchase_state: Dictionary = _get_diamond_store_purchase_state("trap_cage")
	var quantity: int = int(purchase_state.get("quantity", 0))
	var total_cost: int = int(purchase_state.get("totalCost", 0))
	var is_affordable: bool = _is_diamond_store_cost_affordable(purchase_state)
	var font_color: Color = _resolve_button_font_color("confirm") if is_affordable else SHOP_PRICE_INSUFFICIENT_COLOR

	var title: Label = Label.new()
	title.text = UiText.SHOP_TRAP_CAGE_ITEM_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	root.add_child(title)

	root.add_child(_build_centered_shop_slot(
		AssetResolver.resolve_catalog_path("catalog/consumable/trap_cages"),
		UiText.SHOP_TRAP_CAGE_ITEM_TITLE,
		quantity
	))

	root.add_child(_build_quantity_selector("trap_cage", quantity, DIAMOND_STORE_MAX_QUANTITY))

	var button: Button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, 48.0)
	if quantity > 0:
		UiPalette.apply_button_kind(button, "confirm")
		_set_bundle_action_button_content(
			button,
			GameState.format_number(total_cost),
			AssetResolver.resolve_catalog_path("catalog/currency/diamonds"),
			font_color
		)
		button.pressed.connect(Callable(self, "_on_trap_cage_purchase_pressed").bind(quantity, is_affordable, str(purchase_state.get("currencyName", UiText.REWARD_DIAMONDS))))
	else:
		UiPalette.apply_button_kind(button, "neutral")
		_set_bundle_action_button_content(button, "0", AssetResolver.resolve_catalog_path("catalog/currency/diamonds"), UiPalette.BUTTON_DISABLED_FG)
		button.disabled = true
	root.add_child(button)

	return panel


func _build_arena_ticket_card() -> Control:
	var overview: Dictionary = GameState.arena_overview_data
	var purchase_state: Dictionary = _get_diamond_store_purchase_state("arena_ticket")
	var max_quantity: int = int(purchase_state.get("maxQuantity", 0))
	var quantity: int = int(purchase_state.get("quantity", 0))
	var total_cost: int = int(purchase_state.get("totalCost", 0))
	var is_affordable: bool = _is_diamond_store_cost_affordable(purchase_state)
	var panel: PanelContainer = _make_shop_panel(OverlaySceneChrome.PANEL_BORDER)
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	panel.add_child(margin)

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title: Label = Label.new()
	title.text = UiText.SHOP_ARENA_TICKET_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	root.add_child(title)

	var tickets_per_purchase: int = int(overview.get("ticketsPerPurchase", 0))
	root.add_child(_build_centered_shop_slot(
		ARENA_TICKET_ICON_PATH,
		UiText.SHOP_ARENA_TICKET_TITLE,
		tickets_per_purchase * quantity
	))

	root.add_child(_build_quantity_selector("arena_ticket", quantity, max_quantity))

	var button: Button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, 48.0)
	if quantity > 0 and _can_purchase_arena_tickets(overview):
		UiPalette.apply_button_kind(button, "confirm")
		_set_bundle_action_button_content(
			button,
			GameState.format_number(total_cost),
			AssetResolver.resolve_catalog_path("catalog/currency/diamonds"),
			_resolve_button_font_color("confirm") if is_affordable else SHOP_PRICE_INSUFFICIENT_COLOR
		)
		button.pressed.connect(Callable(self, "_on_arena_ticket_purchase_pressed").bind(quantity, is_affordable, str(purchase_state.get("currencyName", UiText.REWARD_DIAMONDS))))
	else:
		UiPalette.apply_button_kind(button, "neutral")
		_set_bundle_action_button_content(button, UiText.SHOP_OUT_OF_STOCK, "", UiPalette.BUTTON_DISABLED_FG)
		button.disabled = true
	root.add_child(button)

	return panel


func _on_trap_cage_purchase_pressed(quantity: int, is_affordable: bool, currency_name: String) -> void:
	if not is_affordable:
		_show_currency_shortage(currency_name)
		return
	_purchase_trap_cages(quantity)


func _on_arena_ticket_purchase_pressed(quantity: int, is_affordable: bool, currency_name: String) -> void:
	if not is_affordable:
		_show_currency_shortage(currency_name)
		return
	_purchase_arena_tickets(quantity)


func _build_empty_state(message: String) -> Control:
	var panel: PanelContainer = _make_shop_panel(OverlaySceneChrome.CARD_BORDER)
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


func _make_shop_panel(border: Color, radius: int = 14) -> PanelContainer:
	return OverlaySceneChrome.make_card_panel(border, SHOP_PANEL_FILL, radius)


func _purchase_trap_cages(quantity: int) -> void:
	_api_client.purchase_trap_cages(quantity, _on_purchase_trap_cages_completed)


func _on_purchase_trap_cages_completed(success: bool, _data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SHOP_PURCHASE_FAILED_TITLE, str(error.get("message", UiText.SHOP_TRAP_CAGE_PURCHASE_FAILED_BODY)))
		return
	refresh_from_bootstrap(false)
	ToastManager.success(UiText.SHOP_PURCHASE_SUCCESS_TITLE, UiText.SHOP_TRAP_CAGE_PURCHASE_SUCCESS_BODY)


func _confirm_collision_coin_purchase(item: Dictionary) -> void:
	var amount: int = int(item.get("amount", 0))
	if amount <= 0:
		return
	var message: String = UiText.SHOP_COLLISION_COIN_PURCHASE_CONFIRM_BODY % [amount, amount]
	DialogManager.show_confirm(
		UiText.SHOP_COLLISION_COIN_PURCHASE_TITLE,
		message,
		Callable(self, "_purchase_collision_coin").bind(amount)
	)


func _purchase_collision_coin(amount: int) -> void:
	_api_client.purchase_trap_points(amount, Callable(self, "_on_purchase_collision_coin_completed").bind(amount))


func _on_purchase_collision_coin_completed(success: bool, data: Variant, error: Dictionary, amount: int) -> void:
	if not success:
		ToastManager.error(UiText.SHOP_PURCHASE_FAILED_TITLE, str(error.get("message", UiText.SHOP_COLLISION_COIN_PURCHASE_FAILED_BODY)))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var overview: Dictionary = payload.get("overview", {})
	if not overview.is_empty():
		GameState.update_shop(overview)
	_refresh_content()
	ToastManager.success(UiText.SHOP_PURCHASE_SUCCESS_TITLE, UiText.SHOP_COLLISION_COIN_PURCHASE_SUCCESS_BODY % amount)


func _purchase_arena_tickets(quantity: int) -> void:
	_api_client.purchase_arena_tickets(quantity, _on_purchase_arena_tickets_completed)


func _on_purchase_arena_tickets_completed(success: bool, data: Variant, error: Dictionary) -> void:
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


func _confirm_bundle_purchase(bundle: Dictionary) -> void:
	var bundle_id: int = int(bundle.get("bundleId", 0))
	var bundle_name: String = str(bundle.get("displayName", UiText.SHOP_BUNDLE_DEFAULT_NAME))
	var price_amount: int = int(bundle.get("priceAmount", 0))
	_pending_bundle_purchase = bundle.duplicate(true)
	var message: String = UiText.SHOP_BUNDLE_PURCHASE_CONFIRM_BODY % [price_amount, bundle_name]
	DialogManager.show_confirm(
		UiText.SHOP_PURCHASE_BUNDLE_TITLE,
		message,
		Callable(self, "_execute_bundle_purchase").bind(bundle_id)
	)


func _execute_bundle_purchase(bundle_id: int) -> void:
	_api_client.purchase_shop_bundle(bundle_id, _on_bundle_purchase_completed, _is_daily_free_bundle(_pending_bundle_purchase))


func _on_bundle_purchase_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		if _should_redirect_to_collision_coin_store(error):
			DialogManager.show_confirm(
				UiText.SHOP_COLLISION_COIN_SHORTAGE_TITLE,
				UiText.SHOP_COLLISION_COIN_SHORTAGE_BODY,
				Callable(self, "_redirect_to_collision_coin_store")
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


func _redirect_to_collision_coin_store() -> void:
	_pending_bundle_purchase.clear()
	_active_tab = TAB_COLLISION_COIN
	_active_secondary_keys[TAB_COLLISION_COIN] = "coin_33"
	_refresh_content()


func _should_redirect_to_collision_coin_store(error: Dictionary) -> bool:
	if not _paid_shop_enabled:
		return false
	if str(error.get("code", "")) != "SHOP.NOT_ENOUGH_PAYMENT_CURRENCY":
		return false
	return int(_pending_bundle_purchase.get("priceCurrencyId", 0)) == TRAP_POINTS_CURRENCY_ID


func _get_bundles_for_tab(tab_key: String) -> Array:
	var category_type: String = _get_category_type(tab_key)
	var result: Array = []
	for bundle_variant: Variant in GameState.shop_data.get("bundles", []):
		if not (bundle_variant is Dictionary):
			continue
		var bundle: Dictionary = bundle_variant
		if str(bundle.get("categoryType", "")).to_lower() == category_type and _is_bundle_visible(bundle):
			result.append(bundle)
	result.sort_custom(_sort_visible_bundles)
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
		if not _has_visible_bundle_for_group(tab_key, str(group.get("groupId", ""))):
			continue
		result.append(group)
	result.sort_custom(_sort_shop_groups)
	return result


func _sort_visible_bundles(a: Dictionary, b: Dictionary) -> bool:
	var a_sold_out: bool = bool(a.get("isSoldOut", false))
	var b_sold_out: bool = bool(b.get("isSoldOut", false))
	if a_sold_out != b_sold_out:
		return not a_sold_out
	return int(a.get("sortOrder", 0)) < int(b.get("sortOrder", 0))


func _sort_shop_groups(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("sortOrder", 0)) < int(b.get("sortOrder", 0))


func _get_bundles_for_group(tab_key: String, group_id: String) -> Array:
	var result: Array = []
	for bundle_variant: Variant in _get_bundles_for_tab(tab_key):
		if bundle_variant is Dictionary and str(bundle_variant.get("groupId", "")) == group_id:
			result.append(bundle_variant)
	return result


func _get_bundle_by_id(bundle_id: String) -> Dictionary:
	for bundle_variant: Variant in GameState.shop_data.get("bundles", []):
		if not (bundle_variant is Dictionary):
			continue
		var bundle: Dictionary = bundle_variant
		if str(bundle.get("bundleId", "")) == bundle_id and _is_bundle_visible(bundle):
			return bundle
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
	var price_info: Dictionary = _resolve_bundle_price_info(bundle)
	if str(price_info.get("text", "")) != "":
		return str(price_info.get("text", ""))
	if str(price_info.get("prefixText", "")) != "":
		return "%s %s" % [str(price_info.get("prefixText", "")), GameState.format_number(int(price_info.get("amount", 0)))]
	return GameState.format_number(int(price_info.get("amount", 0)))


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


func _get_arena_ticket_cost(overview: Dictionary) -> int:
	var purchase_count: int = int(overview.get("dailyPurchaseCount", 0))
	var costs: Array = overview.get("ticketPurchaseCosts", [])
	return int(costs[purchase_count]) if purchase_count < costs.size() else 0


func _get_arena_ticket_total_cost(overview: Dictionary, quantity: int) -> int:
	if quantity <= 0:
		return 0

	var purchase_count: int = int(overview.get("dailyPurchaseCount", 0))
	var costs: Array = overview.get("ticketPurchaseCosts", [])
	var total_cost: int = 0
	for offset in range(quantity):
		var cost_index: int = purchase_count + int(offset)
		if cost_index >= costs.size():
			return 0
		total_cost += int(costs[cost_index])
	return total_cost


func _get_arena_ticket_remaining_purchase_count(overview: Dictionary) -> int:
	if overview.is_empty():
		return 0

	var purchase_count: int = int(overview.get("dailyPurchaseCount", 0))
	var max_purchase_count: int = int(overview.get("maxDailyPurchaseCount", 0))
	var costs: Array = overview.get("ticketPurchaseCosts", [])
	var available_purchase_count: int = mini(max_purchase_count, costs.size()) - purchase_count
	return maxi(0, available_purchase_count)


func _can_purchase_arena_tickets(overview: Dictionary) -> bool:
	return _get_arena_ticket_remaining_purchase_count(overview) > 0 and _get_arena_ticket_cost(overview) > 0


func _get_collision_coin_item(item_key: String) -> Dictionary:
	for item: Dictionary in COLLISION_COIN_ITEMS:
		if str(item.get("key", "")) == item_key:
			return item
	return COLLISION_COIN_ITEMS[0]


func _get_visible_category_configs() -> Array:
	var result: Array = []
	for config: Dictionary in CATEGORY_CONFIGS:
		var tab_key: String = str(config.get("key", ""))
		if _is_tab_visible(tab_key):
			result.append(config)
	return result


func _normalize_active_tab() -> void:
	if _is_tab_visible(_active_tab):
		return
	var visible_tabs: Array = _get_visible_category_configs()
	if visible_tabs.is_empty():
		_active_tab = TAB_VALUE
		return
	var first_visible_variant: Variant = visible_tabs[0]
	var first_visible: Dictionary = first_visible_variant if first_visible_variant is Dictionary else {}
	_active_tab = str(first_visible.get("key", TAB_VALUE))


func _is_tab_visible(tab_key: String) -> bool:
	if _paid_shop_enabled:
		return true
	return tab_key != TAB_COLLISION_COIN and tab_key != TAB_POINT


func _is_bundle_visible(bundle: Dictionary) -> bool:
	if _paid_shop_enabled:
		return true
	var price_currency_type: String = str(bundle.get("priceCurrencyType", "")).to_lower()
	var price_currency_id: int = int(bundle.get("priceCurrencyId", 0))
	return price_currency_type != "trappoints" and price_currency_id != TRAP_POINTS_CURRENCY_ID


func _is_daily_free_bundle(bundle: Dictionary) -> bool:
	return str(bundle.get("categoryType", "")).to_lower() == "dailypack" and int(bundle.get("priceAmount", -1)) == 0


func _has_visible_bundle_for_group(tab_key: String, group_id: String) -> bool:
	for bundle_variant: Variant in _get_bundles_for_tab(tab_key):
		if bundle_variant is Dictionary and str(bundle_variant.get("groupId", "")) == group_id:
			return true
	return false


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
	if not _paid_shop_enabled:
		return UiText.SHOP_RESOURCE_FORMAT % [
			GameState.player_data.diamonds,
			GameState.player_data.trap_cages,
		]
	return UiText.SHOP_RESOURCE_WITH_COLLISION_COIN_FORMAT % [
		GameState.player_data.diamonds,
		GameState.player_data.trap_points,
		GameState.player_data.trap_cages,
	]


func _build_tab_summary_right(tab_key: String) -> String:
	var item_count: int = _build_secondary_items(tab_key).size()
	return UiText.SHOP_ITEM_COUNT_FORMAT % item_count


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
