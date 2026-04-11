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
	intro.text = "\u4f7f\u7528\u947d\u77f3\u76f4\u63a5\u8cfc\u8cb7\u8a98\u6355\u7c60\uff0c\u8cfc\u8cb7\u6210\u529f\u5f8c\u6703\u540c\u6b65\u66f4\u65b0\u76ee\u524d\u6301\u6709\u6578\u91cf\u3002"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 18)
	add_child(intro)

	var offers_variant: Variant = GameState.shop_data.get("trapCageOffers", [])
	var offers: Array = offers_variant if offers_variant is Array else []
	if offers.is_empty():
		var empty_label := Label.new()
		empty_label.text = "\u76ee\u524d\u6c92\u6709\u53ef\u8cfc\u8cb7\u7684\u8a98\u6355\u7c60\u65b9\u6848\u3002"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 22)
		add_child(empty_label)
		return

	for offer_variant: Variant in offers:
		if offer_variant is Dictionary:
			add_child(_build_offer_card(offer_variant))


func _build_offer_card(offer: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _create_card_style())

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
	title.text = "\u8a98\u6355\u7c60 x%d" % count
	title.add_theme_font_size_override("font_size", 24)
	info.add_child(title)

	var desc := Label.new()
	desc.text = "\u8cfc\u8cb7\u5f8c\u53ef\u76f4\u63a5\u5728\u8a98\u6355\u4e2d\u4f7f\u7528\u3002"
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82, 1.0))
	info.add_child(desc)

	var cost_label := Label.new()
	cost_label.text = "\u947d\u77f3 %d" % cost
	cost_label.add_theme_font_size_override("font_size", 20)
	row.add_child(cost_label)

	var button := Button.new()
	button.text = "\u8cfc\u8cb7"
	button.custom_minimum_size = Vector2(140.0, 48.0)
	button.pressed.connect(_confirm_purchase.bind(count, cost))
	row.add_child(button)

	return panel


func _confirm_purchase(count: int, cost: int) -> void:
	var message := "\u662f\u5426\u82b1\u8cbb %d \u947d\u77f3\u8cfc\u8cb7\u8a98\u6355\u7c60 x%d\uff1f" % [cost, count]
	DialogManager.show_confirm("\u8cfc\u8cb7\u8a98\u6355\u7c60", message, func() -> void:
		_api_client.purchase_trap_cages(count, _on_purchase_completed)
	)


func _on_purchase_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		DialogManager.show_info("\u8cfc\u8cb7\u5931\u6557", _extract_error_message(error, "\u8cfc\u8cb7\u8a98\u6355\u7c60\u5931\u6557\u3002"))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var overview: Variant = payload.get("overview", {})
	if overview is Dictionary:
		GameState.update_shop(overview)
	_rebuild()
	emit_signal("request_refresh")
	DialogManager.show_info("\u8cfc\u8cb7\u6210\u529f", "\u5df2\u6210\u529f\u8cfc\u8cb7\u8a98\u6355\u7c60\u3002")


func _create_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.border_color = CARD_BORDER
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style


func _extract_error_message(error: Dictionary, fallback: String) -> String:
	return str(error.get("message", fallback))
