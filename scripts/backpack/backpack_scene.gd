class_name BackpackScene
extends Control

const ITEM_SLOT_TEMPLATE = preload("res://scenes/ui/backpack/ItemSlotTemplate.tscn")

const TAB_ALL := "all"
const TAB_CURRENCY := "currency"
const TAB_TICKET := "ticket"
const TAB_CONSUMABLE := "consumable"

const GRID_COLS := 5
const SLOT_TEMPLATE_BASE_SIZE := Vector2(512.0, 512.0)
const BACKPACK_SLOT_SCALE := 0.25
const BACKPACK_SLOT_CELL_SIZE := Vector2(128.0, 128.0)
const BACKPACK_GRID_H_SEPARATION := 2
const BACKPACK_GRID_V_SEPARATION := 10
const SLOT_DISABLED_MODULATE := Color(0.58, 0.58, 0.58, 0.82)
const SLOT_DISABLED_TEXT := Color(0.70, 0.68, 0.63, 0.92)
const SLOT_COUNT_TEXT := Color(1.0, 0.98, 0.92, 1.0)

var _active_tab: String = TAB_ALL
var _tab_buttons: Dictionary = {}
var _content_box: VBoxContainer

@onready var GameState = get_node("/root/GameState")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var chrome: Dictionary = OverlaySceneChrome.build(self, "shop", _on_back_pressed, {
		"show_dock": true,
		"dock_items": _build_tab_items(),
		"active_key": _active_tab,
		"button_pressed": Callable(self, "_switch_tab"),
	})
	_tab_buttons = chrome.get("dock_buttons", {})
	_build_content(chrome.get("content_box") as VBoxContainer)
	_refresh_content()


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()


func _switch_tab(tab_key: String) -> void:
	if _active_tab == tab_key:
		return
	_active_tab = tab_key
	_refresh_content()


func _build_content(box: VBoxContainer) -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	InertialScroller.attach(scroll, "vertical")

	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 16)
	scroll.add_child(_content_box)


func _refresh_content() -> void:
	if _content_box == null:
		return
	for child: Node in _content_box.get_children():
		child.queue_free()

	match _active_tab:
		TAB_CURRENCY:
			_build_item_grid(_content_box, _get_currency_items())
		TAB_TICKET:
			_build_item_grid(_content_box, _get_ticket_items())
		TAB_CONSUMABLE:
			_build_item_grid(_content_box, _get_consumable_items())
		_:
			_build_item_grid(_content_box, _get_all_items())

	SceneSubmenuBar.refresh(_tab_buttons, _active_tab)


func _build_tab_items() -> Array:
	return [
		{
			"key": TAB_ALL,
			"label": UiText.BACKPACK_TAB_ALL,
			"shell_description": UiText.BACKPACK_ALL_DESC,
			"shell_summary_left": Callable(self, "_build_shell_summary_left").bind(TAB_ALL),
			"shell_summary_right": Callable(self, "_build_shell_summary_right").bind(TAB_ALL),
		},
		{
			"key": TAB_CURRENCY,
			"label": UiText.BACKPACK_SECTION_CURRENCY,
			"shell_description": UiText.BACKPACK_CURRENCY_DESC,
			"shell_summary_left": Callable(self, "_build_shell_summary_left").bind(TAB_CURRENCY),
			"shell_summary_right": Callable(self, "_build_shell_summary_right").bind(TAB_CURRENCY),
		},
		{
			"key": TAB_TICKET,
			"label": UiText.BACKPACK_SECTION_TICKET,
			"shell_description": UiText.BACKPACK_TICKET_DESC,
			"shell_summary_left": Callable(self, "_build_shell_summary_left").bind(TAB_TICKET),
			"shell_summary_right": Callable(self, "_build_shell_summary_right").bind(TAB_TICKET),
		},
		{
			"key": TAB_CONSUMABLE,
			"label": UiText.BACKPACK_SECTION_CONSUMABLE,
			"shell_description": UiText.BACKPACK_CONSUMABLE_DESC,
			"shell_summary_left": Callable(self, "_build_shell_summary_left").bind(TAB_CONSUMABLE),
			"shell_summary_right": Callable(self, "_build_shell_summary_right").bind(TAB_CONSUMABLE),
		},
	]


func _build_item_grid(parent: VBoxContainer, items: Array) -> void:
	var grid_width: float = (
		(BACKPACK_SLOT_CELL_SIZE.x * float(GRID_COLS))
		+ (BACKPACK_GRID_H_SEPARATION * float(maxi(GRID_COLS - 1, 0)))
	)
	var center: CenterContainer = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(center)

	var grid: GridContainer = GridContainer.new()
	grid.columns = GRID_COLS
	grid.custom_minimum_size = Vector2(grid_width, 0.0)
	grid.add_theme_constant_override("h_separation", BACKPACK_GRID_H_SEPARATION)
	grid.add_theme_constant_override("v_separation", BACKPACK_GRID_V_SEPARATION)
	center.add_child(grid)

	for item_variant: Variant in items:
		if item_variant is Dictionary:
			grid.add_child(_make_item_card(item_variant as Dictionary))


func _make_item_card(item: Dictionary) -> Control:
	var qty: int = int(item.get("qty", 0))
	var has_qty: bool = qty > 0
	var slot: Control = ITEM_SLOT_TEMPLATE.instantiate() as Control
	var frame: TextureRect = slot.get_node("Frame") as TextureRect
	var icon: TextureRect = slot.get_node("ItemIcon") as TextureRect
	var overlay_mask: TextureRect = slot.get_node("OverlayMask") as TextureRect
	var name_label: Label = slot.get_node("ItemNameLabel") as Label
	var qty_label: Label = slot.get_node("CountLabel") as Label
	var texture: Texture2D = AssetResolver.resolve_catalog_texture(str(item.get("path", "")))

	name_label.text = str(item.get("name", ""))
	name_label.tooltip_text = name_label.text
	qty_label.text = GameState.format_number(qty)
	qty_label.tooltip_text = qty_label.text

	if texture != null:
		icon.texture = texture
	else:
		icon.visible = false

	if has_qty:
		frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
		icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
		overlay_mask.modulate = Color(1.0, 1.0, 1.0, 0.42)
		name_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.92, 1.0))
		qty_label.add_theme_color_override("font_color", SLOT_COUNT_TEXT)
	else:
		frame.modulate = SLOT_DISABLED_MODULATE
		icon.modulate = SLOT_DISABLED_MODULATE
		overlay_mask.modulate = Color(0.78, 0.78, 0.78, 0.22)
		name_label.add_theme_color_override("font_color", SLOT_DISABLED_TEXT)
		qty_label.add_theme_color_override("font_color", SLOT_DISABLED_TEXT)

	slot.scale = Vector2(BACKPACK_SLOT_SCALE, BACKPACK_SLOT_SCALE)

	var cell: Control = Control.new()
	cell.custom_minimum_size = BACKPACK_SLOT_CELL_SIZE
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(slot)

	var btn: Button = Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	btn.pressed.connect(_show_item_detail.bind(item))
	cell.add_child(btn)
	return cell


func _show_item_detail(item: Dictionary) -> void:
	var item_name: String = str(item.get("name", ""))
	var qty: int = int(item.get("qty", 0))
	var desc: String = str(item.get("desc", ""))

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)

	var qty_label: Label = Label.new()
	qty_label.text = UiText.BACKPACK_DETAIL_QTY_FORMAT % GameState.format_number(qty)
	qty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	qty_label.add_theme_color_override("font_color", Color(0.82, 0.70, 0.42, 1.0))
	content.add_child(qty_label)

	if desc != "":
		var desc_label: Label = Label.new()
		desc_label.text = desc
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		content.add_child(desc_label)

	DialogManager.show_info_node(item_name, content, Callable(), "small")


func _get_all_items() -> Array:
	var items: Array = []
	items.append_array(_get_currency_items())
	items.append_array(_get_ticket_items())
	items.append_array(_get_consumable_items())
	return items


func _get_currency_items() -> Array:
	var player_data = GameState.player_data
	return [
		{"path": "catalog/currency/gold", "name": UiText.REWARD_GOLD, "qty": int(player_data.gold), "desc": UiText.BACKPACK_ITEM_DESC_GOLD},
		{"path": "catalog/currency/diamonds", "name": UiText.REWARD_DIAMONDS, "qty": int(player_data.diamonds), "desc": UiText.BACKPACK_ITEM_DESC_DIAMONDS},
		{"path": "catalog/currency/trap_points", "name": UiText.BACKPACK_TRAP_POINTS, "qty": int(player_data.trap_points), "desc": UiText.BACKPACK_ITEM_DESC_TRAP_POINTS},
		{"path": "catalog/currency/collision_coin", "name": UiText.BACKPACK_COLLISION_COIN, "qty": int(player_data.collision_coin), "desc": UiText.BACKPACK_ITEM_DESC_COLLISION_COIN},
	]


func _get_ticket_items() -> Array:
	var items: Array = []
	var arena_overview: Dictionary = GameState.arena_overview_data if GameState.arena_overview_data is Dictionary else {}
	items.append({
		"path": "catalog/consumable/arena_ticket",
		"name": UiText.BACKPACK_ARENA_TICKET,
		"qty": int(arena_overview.get("tickets", 0)),
		"desc": UiText.BACKPACK_ITEM_DESC_ARENA_TICKET,
	})
	items.append({
		"path": "catalog/consumable/party_cheer_coupon",
		"name": UiText.SOCIAL_PARTY_USE_COUPON,
		"qty": int(GameState.get_party_cheer_coupon_count()),
		"desc": UiText.BACKPACK_ITEM_DESC_PARTY_CHEER_COUPON,
	})

	var dungeon_list: Array = GameState.dungeon_overview_data if GameState.dungeon_overview_data is Array else []
	for dungeon_variant: Variant in dungeon_list:
		if not (dungeon_variant is Dictionary):
			continue
		var dungeon: Dictionary = dungeon_variant as Dictionary
		var key: String = str(dungeon.get("key", ""))
		var ticket_name: String = str(dungeon.get("ticketDisplayName", ""))
		if ticket_name == "":
			ticket_name = str(dungeon.get("displayName", UiText.BACKPACK_DUNGEON_TICKET))
			if not ticket_name.ends_with("券"):
				ticket_name += "券"
		var ticket_desc: String = str(dungeon.get("ticketDescription", ""))
		items.append({
			"path": "catalog/consumable/" + key + "_dungeon_ticket",
			"name": ticket_name,
			"qty": int(dungeon.get("remainingTicketCount", 0)),
			"desc": ticket_desc,
		})
	return items


func _get_consumable_items() -> Array:
	var player_data = GameState.player_data
	return [
		{"path": "catalog/consumable/cat_food", "name": UiText.REWARD_CAT_FOOD, "qty": int(player_data.cat_food), "desc": UiText.BACKPACK_ITEM_DESC_CAT_FOOD},
		{"path": "catalog/consumable/special_cat_food", "name": UiText.REWARD_SPECIAL_CAT_FOOD, "qty": int(player_data.special_cat_food), "desc": UiText.BACKPACK_ITEM_DESC_SPECIAL_CAT_FOOD},
		{"path": "catalog/consumable/trap_cages", "name": UiText.REWARD_TRAP_CAGE, "qty": int(player_data.trap_cages), "desc": UiText.BACKPACK_ITEM_DESC_TRAP_CAGES},
		{"path": "catalog/consumable/poop_count", "name": UiText.REWARD_POOP, "qty": int(player_data.poop_count), "desc": UiText.BACKPACK_ITEM_DESC_POOP},
		{"path": "catalog/consumable/memory_shards", "name": UiText.REWARD_MEMORY_SHARDS, "qty": int(player_data.memory_shards), "desc": UiText.BACKPACK_ITEM_DESC_MEMORY_SHARDS},
		{"path": "catalog/consumable/whisker_shards", "name": UiText.BACKPACK_WHISKER_SHARDS, "qty": int(player_data.whisker_shards), "desc": UiText.BACKPACK_ITEM_DESC_WHISKER_SHARDS},
	]


func _build_shell_summary_left(tab_key: String) -> String:
	var player_data = GameState.player_data
	match tab_key:
		TAB_CURRENCY:
			return "%s %d / %s %d / %s %d" % [
				UiText.REWARD_GOLD,
				int(player_data.gold),
				UiText.REWARD_DIAMONDS,
				int(player_data.diamonds),
				UiText.BACKPACK_TRAP_POINTS,
				int(player_data.trap_points),
			]
		TAB_TICKET:
			var arena_overview: Dictionary = GameState.arena_overview_data if GameState.arena_overview_data is Dictionary else {}
			return "%s %d / %s %d" % [
				UiText.BACKPACK_ARENA_TICKET,
				int(arena_overview.get("tickets", 0)),
				UiText.SOCIAL_PARTY_USE_COUPON,
				int(GameState.get_party_cheer_coupon_count()),
			]
		TAB_CONSUMABLE:
			return "%s %d / %s %d / %s %d / %s %d" % [
				UiText.REWARD_CAT_FOOD,
				int(player_data.cat_food),
				UiText.REWARD_TRAP_CAGE,
				int(player_data.trap_cages),
				UiText.REWARD_MEMORY_SHARDS,
				int(player_data.memory_shards),
				UiText.BACKPACK_WHISKER_SHARDS,
				int(player_data.whisker_shards),
			]
		_:
			return "%s %d / %s %d / %s %d / %s %d" % [
				UiText.REWARD_GOLD,
				int(player_data.gold),
				UiText.REWARD_DIAMONDS,
				int(player_data.diamonds),
				UiText.REWARD_TRAP_CAGE,
				int(player_data.trap_cages),
				UiText.REWARD_MEMORY_SHARDS,
				int(player_data.memory_shards),
			]


func _build_shell_summary_right(tab_key: String) -> String:
	var items: Array = []
	match tab_key:
		TAB_CURRENCY:
			items = _get_currency_items()
		TAB_TICKET:
			items = _get_ticket_items()
		TAB_CONSUMABLE:
			items = _get_consumable_items()
		_:
			items = _get_all_items()

	var owned_count: int = 0
	for item_variant: Variant in items:
		if item_variant is Dictionary and int((item_variant as Dictionary).get("qty", 0)) > 0:
			owned_count += 1
	return UiText.BACKPACK_OWNED_COUNT_FORMAT % owned_count
