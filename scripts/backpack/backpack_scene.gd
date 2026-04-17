class_name BackpackScene
extends Control

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")

const ICON_SIZE := Vector2(52.0, 52.0)
const GRID_COLS := 3

@onready var GameState = get_node("/root/GameState")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var chrome: Dictionary = OverlaySceneChrome.build(self, "shop", _on_back_pressed, {
		"show_dock": false,
	})
	_build_content(chrome["content_box"])


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()


func _build_content(box: VBoxContainer) -> void:
	var title := Label.new()
	title.text = UiText.BACKPACK_TITLE
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	box.add_child(title)

	box.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	InertialScroller.attach(scroll, "vertical")

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)

	_build_currency_section(vbox)
	vbox.add_child(HSeparator.new())
	_build_ticket_section(vbox)
	vbox.add_child(HSeparator.new())
	_build_consumable_section(vbox)


func _build_section_header(parent: VBoxContainer, label_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	lbl.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	row.add_child(lbl)

	var sep := HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sep)


func _build_item_grid(parent: VBoxContainer, items: Array) -> void:
	var grid := GridContainer.new()
	grid.columns = GRID_COLS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)

	for item: Dictionary in items:
		grid.add_child(_make_item_card(item))


func _make_item_card(item: Dictionary) -> Control:
	var qty: int = int(item.get("qty", 0))
	var has_qty: bool = qty > 0
	var accent: Color = OverlaySceneChrome.CARD_BORDER if has_qty else Color(0.35, 0.33, 0.28, 0.70)

	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(accent)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := OverlaySceneChrome.make_content_margin(10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var tex: Texture2D = AssetResolver.load_texture(
		AssetResolver.resolve_catalog_path(str(item.get("path", "")))
	)
	if tex != null:
		var icon_row := CenterContainer.new()
		icon_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(icon_row)
		var icon := AssetResolver.create_icon_rect(tex, ICON_SIZE)
		if not has_qty:
			icon.modulate = Color(0.55, 0.55, 0.55, 0.80)
		icon_row.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = str(item.get("name", ""))
	name_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not has_qty:
		name_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.90))
	vbox.add_child(name_lbl)

	var qty_lbl := Label.new()
	qty_lbl.text = str(qty)
	qty_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_lbl.add_theme_color_override(
		"font_color",
		accent if has_qty else Color(0.45, 0.45, 0.45, 0.90)
	)
	vbox.add_child(qty_lbl)

	return panel


func _build_currency_section(parent: VBoxContainer) -> void:
	_build_section_header(parent, UiText.BACKPACK_SECTION_CURRENCY)
	var pd = GameState.player_data
	_build_item_grid(parent, [
		{"path": "catalog/currency/gold", "name": UiText.REWARD_GOLD, "qty": pd.gold},
		{"path": "catalog/currency/diamonds", "name": UiText.REWARD_DIAMONDS, "qty": pd.diamonds},
		{"path": "catalog/currency/trap_points", "name": UiText.BACKPACK_TRAP_POINTS, "qty": pd.trap_points},
	])


func _build_consumable_section(parent: VBoxContainer) -> void:
	_build_section_header(parent, UiText.BACKPACK_SECTION_CONSUMABLE)
	var pd = GameState.player_data
	_build_item_grid(parent, [
		{"path": "catalog/consumable/cat_food", "name": UiText.REWARD_CAT_FOOD, "qty": pd.cat_food},
		{"path": "catalog/consumable/special_cat_food", "name": UiText.REWARD_SPECIAL_CAT_FOOD, "qty": pd.special_cat_food},
		{"path": "catalog/consumable/trap_cages", "name": UiText.REWARD_TRAP_CAGE, "qty": pd.trap_cages},
		{"path": "catalog/consumable/poop_count", "name": UiText.REWARD_POOP, "qty": pd.poop_count},
		{"path": "catalog/consumable/memory_shards", "name": UiText.REWARD_MEMORY_SHARDS, "qty": pd.memory_shards},
		{"path": "catalog/consumable/whisker_shards", "name": UiText.BACKPACK_WHISKER_SHARDS, "qty": pd.whisker_shards},
	])


func _build_ticket_section(parent: VBoxContainer) -> void:
	_build_section_header(parent, UiText.BACKPACK_SECTION_TICKET)

	var items: Array = []

	var arena_overview: Dictionary = \
		GameState.arena_overview_data if GameState.arena_overview_data is Dictionary else {}
	items.append({
		"path": "catalog/arena/bronze_1",
		"name": UiText.BACKPACK_ARENA_TICKET,
		"qty": int(arena_overview.get("tickets", 0)),
	})

	var dungeon_list: Array = \
		GameState.dungeon_overview_data if GameState.dungeon_overview_data is Array else []
	for dungeon_variant: Variant in dungeon_list:
		if not (dungeon_variant is Dictionary):
			continue
		var dungeon: Dictionary = dungeon_variant
		var key: String = str(dungeon.get("key", ""))
		items.append({
			"path": "catalog/dungeon/" + key,
			"name": str(dungeon.get("displayName", UiText.BACKPACK_DUNGEON_TICKET)),
			"qty": int(dungeon.get("remainingTicketCount", 0)),
		})

	_build_item_grid(parent, items)
