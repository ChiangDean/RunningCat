extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")


func build(scene: Control) -> void:
	scene._exp_label = scene._tab_header_summary
	if scene._exp_label == null:
		var summary_row: HBoxContainer = HBoxContainer.new()
		summary_row.add_theme_constant_override("separation", 10)
		scene._tab_content.add_child(summary_row)

		var section_label: Label = Label.new()
		section_label.text = UiText.SCOOPER_TAB_ABILITY
		section_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_row.add_child(section_label)

		var summary: Label = Label.new()
		summary.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary_row.add_child(summary)
		scene._exp_label = summary

		scene._tab_content.add_child(scene._make_separator())

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene._tab_content.add_child(scroll)
	scene._ability_scroller = InertialScroller.attach(scroll, "vertical")

	scene._ability_list = VBoxContainer.new()
	scene._ability_list.add_theme_constant_override("separation", 10)
	scene._ability_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._ability_list)

	_refresh_ability_ui(scene)


func _refresh_ability_ui(scene: Control) -> void:
	var owned: Array = scene.GameState.scooper_ability_data
	if owned.is_empty():
		owned = scene.GameState.get_owned_special_abilities()

	if scene._exp_label != null:
		scene._exp_label.text = UiText.SCOOPER_ABILITY_SUMMARY_FORMAT % owned.size()

	if scene._ability_list == null:
		return

	for child: Node in scene._ability_list.get_children():
		child.queue_free()

	if owned.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = UiText.SCOOPER_ABILITY_EMPTY
		empty_lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._ability_list.add_child(empty_lbl)
		return

	var first_item: bool = true
	for item: Dictionary in owned:
		if not first_item:
			scene._ability_list.add_child(scene._make_separator())
		scene._ability_list.add_child(_make_ability_card(scene, item))
		first_item = false


func _make_ability_card(scene: Control, item: Dictionary) -> Control:
	var panel: PanelContainer = scene._make_card_panel(Color(0.54, 0.76, 0.92, 0.95))
	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	panel.add_child(margin)

	var card: VBoxContainer = VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	margin.add_child(card)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	card.add_child(header)

	var icon: Texture2D = AssetResolver.resolve_ability_icon(item)
	if icon != null:
		header.add_child(AssetResolver.create_icon_rect(icon, Vector2(52.0, 52.0)))

	var title: Label = Label.new()
	title.text = str(item.get("displayName", item.get("display_name", "")))
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var source_chip: Label = Label.new()
	source_chip.text = UiText.SCOOPER_ABILITY_SOURCE_VALUE
	source_chip.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	source_chip.add_theme_color_override("font_color", Color(0.90, 0.82, 0.60, 1.0))
	source_chip.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	source_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(source_chip)

	var desc: Label = Label.new()
	desc.text = str(item.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	desc.add_theme_color_override("font_color", Color(0.86, 0.86, 0.84, 1.0))
	card.add_child(desc)

	return panel
