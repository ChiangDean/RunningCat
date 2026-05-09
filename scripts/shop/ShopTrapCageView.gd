extends VBoxContainer

signal request_refresh

const CARD_BG := Color(0.16, 0.18, 0.22, 1.0)
const CARD_BORDER := Color(0.33, 0.45, 0.54, 1.0)

@onready var _api_client = get_node("/root/ApiClient")


func setup() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var intro := Label.new()
	intro.text = UiText.SHOP_TRAP_CAGE_INTRO
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	add_child(intro)

	var offers_variant: Variant = GameState.shop_data.get("trapCageOffers", [])
	var offers: Array = offers_variant if offers_variant is Array else []
	if offers.is_empty():
		var empty_label := Label.new()
		empty_label.text = UiText.SHOP_TRAP_CAGE_EMPTY
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
		add_child(empty_label)
		return

	for offer_variant: Variant in offers:
		if offer_variant is Dictionary:
			add_child(_build_offer_card(offer_variant))


func _build_offer_card(offer: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", OverlaySceneChrome.make_panel_style(CARD_BG, CARD_BORDER, 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)

	var count := int(offer.get("trapCageCount", 0))
	var cost := int(offer.get("diamondCost", 0))

	var title := Label.new()
	title.text = UiText.SHOP_TRAP_CAGE_ITEM_TITLE_COUNT_FORMAT % GameState.format_number(count)
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	info.add_child(title)

	var desc := Label.new()
	desc.text = UiText.SHOP_TRAP_CAGE_ITEM_DESC_SHORT
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82, 1.0))
	info.add_child(desc)

	var cost_label := Label.new()
	cost_label.text = UiText.SHOP_DIAMOND_COST_S_FORMAT % GameState.format_number(cost)
	cost_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	row.add_child(cost_label)

	var button := Button.new()
	button.text = UiText.SHOP_ACTION_BUY
	button.custom_minimum_size = Vector2(140.0, 48.0)
	UiPalette.apply_button_kind(button, "confirm")
	button.pressed.connect(_confirm_purchase.bind(count, cost))
	row.add_child(button)

	return panel


func _confirm_purchase(count: int, cost: int) -> void:
	var message := UiText.SHOP_TRAP_CAGE_PURCHASE_CONFIRM_S_BODY % [GameState.format_number(cost), GameState.format_number(count)]
	DialogManager.show_confirm(
		UiText.SHOP_TRAP_CAGE_PURCHASE_TITLE,
		message,
		Callable(self, "_execute_trap_cage_purchase").bind(count)
	)


func _execute_trap_cage_purchase(count: int) -> void:
	_api_client.purchase_trap_cages(count, _on_purchase_completed)


func _on_purchase_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		ToastManager.error(UiText.SHOP_PURCHASE_FAILED_TITLE, _extract_error_message(error, UiText.SHOP_TRAP_CAGE_PURCHASE_FAILED_BODY))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var overview: Dictionary = payload.get("overview", {})
	if not overview.is_empty():
		GameState.update_shop(overview)
	emit_signal("request_refresh")
	var owner := get_parent()
	if owner != null and owner.has_method("get_parent"):
		var scene := owner.get_parent()
		if scene != null and scene.has_method("_refresh_content"):
			scene._refresh_content()
	ToastManager.success(UiText.SHOP_PURCHASE_SUCCESS_TITLE, UiText.SHOP_TRAP_CAGE_PURCHASE_SUCCESS_BODY)


func _extract_error_message(error: Dictionary, fallback: String) -> String:
	return str(error.get("message", fallback))
