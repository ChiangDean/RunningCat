class_name BackpackScene
extends Control

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const ITEM_SLOT_TEMPLATE = preload("res://scenes/ui/ItemSlotTemplate.tscn")

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
	var title: Label = Label.new()
	title.text = UiText.BACKPACK_TITLE
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "切換下方子選單檢視背包內容。"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	subtitle.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	box.add_child(subtitle)

	box.add_child(HSeparator.new())

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
			_build_currency_section(_content_box)
		TAB_TICKET:
			_build_ticket_section(_content_box)
		TAB_CONSUMABLE:
			_build_consumable_section(_content_box)
		_:
			_build_all_section(_content_box)

	SceneSubmenuBar.refresh(_tab_buttons, _active_tab)


func _build_tab_items() -> Array:
	return [
		{"key": TAB_ALL, "label": "全部"},
		{"key": TAB_CURRENCY, "label": UiText.BACKPACK_SECTION_CURRENCY},
		{"key": TAB_TICKET, "label": UiText.BACKPACK_SECTION_TICKET},
		{"key": TAB_CONSUMABLE, "label": UiText.BACKPACK_SECTION_CONSUMABLE},
	]


func _build_section_header(parent: VBoxContainer, label_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	lbl.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	row.add_child(lbl)

	var sep: HSeparator = HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sep)


func _build_item_grid(parent: VBoxContainer, items: Array) -> void:
	var grid_width: float = (
		(BACKPACK_SLOT_CELL_SIZE.x * float(GRID_COLS))
		+ (BACKPACK_GRID_H_SEPARATION * float(max(GRID_COLS - 1, 0)))
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
	var name_lbl: Label = slot.get_node("ItemNameLabel") as Label
	var qty_lbl: Label = slot.get_node("CountLabel") as Label
	var tex: Texture2D = AssetResolver.load_texture(
		AssetResolver.resolve_catalog_path(str(item.get("path", "")))
	)
	name_lbl.text = str(item.get("name", ""))
	name_lbl.tooltip_text = name_lbl.text
	qty_lbl.text = str(qty)
	qty_lbl.tooltip_text = qty_lbl.text

	if tex != null:
		icon.texture = tex
	else:
		icon.visible = false

	if has_qty:
		frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
		icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
		overlay_mask.modulate = Color(1.0, 1.0, 1.0, 0.42)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.97, 0.92, 1.0))
		qty_lbl.add_theme_color_override("font_color", SLOT_COUNT_TEXT)
	else:
		frame.modulate = SLOT_DISABLED_MODULATE
		icon.modulate = SLOT_DISABLED_MODULATE
		overlay_mask.modulate = Color(0.78, 0.78, 0.78, 0.22)
		name_lbl.add_theme_color_override("font_color", SLOT_DISABLED_TEXT)
		qty_lbl.add_theme_color_override("font_color", SLOT_DISABLED_TEXT)

	slot.scale = Vector2(BACKPACK_SLOT_SCALE, BACKPACK_SLOT_SCALE)
	var cell: Control = Control.new()
	cell.custom_minimum_size = BACKPACK_SLOT_CELL_SIZE
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.position = Vector2.ZERO
	cell.add_child(slot)
	return cell


func _build_all_section(parent: VBoxContainer) -> void:
	_build_item_grid(parent, _get_all_items())


func _get_all_items() -> Array:
	var items: Array = []
	items.append_array(_get_currency_items())
	items.append_array(_get_ticket_items())
	items.append_array(_get_consumable_items())
	return items


func _build_currency_section(parent: VBoxContainer) -> void:
	_build_section_header(parent, UiText.BACKPACK_SECTION_CURRENCY)
	_build_item_grid(parent, _get_currency_items())


func _build_consumable_section(parent: VBoxContainer) -> void:
	_build_section_header(parent, UiText.BACKPACK_SECTION_CONSUMABLE)
	_build_item_grid(parent, _get_consumable_items())


func _build_ticket_section(parent: VBoxContainer) -> void:
	_build_section_header(parent, UiText.BACKPACK_SECTION_TICKET)
	_build_item_grid(parent, _get_ticket_items())


func _get_currency_items() -> Array:
	var pd = GameState.player_data
	return [
		{"path": "catalog/currency/gold", "name": UiText.REWARD_GOLD, "qty": pd.gold},
		{"path": "catalog/currency/diamonds", "name": UiText.REWARD_DIAMONDS, "qty": pd.diamonds},
		{"path": "catalog/currency/trap_points", "name": UiText.BACKPACK_TRAP_POINTS, "qty": pd.trap_points},
	]


func _get_consumable_items() -> Array:
	var pd = GameState.player_data
	return [
		{"path": "catalog/consumable/cat_food", "name": UiText.REWARD_CAT_FOOD, "qty": pd.cat_food},
		{"path": "catalog/consumable/special_cat_food", "name": UiText.REWARD_SPECIAL_CAT_FOOD, "qty": pd.special_cat_food},
		{"path": "catalog/consumable/trap_cages", "name": UiText.REWARD_TRAP_CAGE, "qty": pd.trap_cages},
		{"path": "catalog/consumable/poop_count", "name": UiText.REWARD_POOP, "qty": pd.poop_count},
		{"path": "catalog/consumable/memory_shards", "name": UiText.REWARD_MEMORY_SHARDS, "qty": pd.memory_shards},
		{"path": "catalog/consumable/whisker_shards", "name": UiText.BACKPACK_WHISKER_SHARDS, "qty": pd.whisker_shards},
	]


func _get_ticket_items() -> Array:
	var items: Array = []
	var arena_overview: Dictionary = GameState.arena_overview_data if GameState.arena_overview_data is Dictionary else {}
	items.append({
		"path": "catalog/arena/bronze_1",
		"name": UiText.BACKPACK_ARENA_TICKET,
		"qty": int(arena_overview.get("tickets", 0)),
	})
	items.append({
		"path": "catalog/consumable/party_cheer_coupon",
		"name": "收益券(1小時)",
		"qty": int(GameState.get_party_cheer_coupon_count()),
	})

	var dungeon_list: Array = GameState.dungeon_overview_data if GameState.dungeon_overview_data is Array else []
	for dungeon_variant: Variant in dungeon_list:
		if not (dungeon_variant is Dictionary):
			continue
		var dungeon: Dictionary = dungeon_variant as Dictionary
		var key: String = str(dungeon.get("key", ""))
		items.append({
			"path": "catalog/dungeon/" + key,
			"name": str(dungeon.get("displayName", UiText.BACKPACK_DUNGEON_TICKET)),
			"qty": int(dungeon.get("remainingTicketCount", 0)),
		})

	return items
