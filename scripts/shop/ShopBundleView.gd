extends VBoxContainer

signal request_refresh

const CARD_BG := Color(0.16, 0.18, 0.22, 1.0)
const CARD_BORDER := Color(0.33, 0.45, 0.54, 1.0)

var _selected_category_id: String = ""

@onready var _api_client = get_node("/root/ApiClient")


func setup(initial_category_id: String = "") -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	if initial_category_id != "":
		_selected_category_id = initial_category_id
	_select_default_category()
	_rebuild()


func _select_default_category() -> void:
	if _selected_category_id != "":
		return
	var categories := GameState.get_shop_bundle_categories()
	if categories.is_empty():
		return
	var first_category: Dictionary = categories[0]
	_selected_category_id = str(first_category.get("categoryId", ""))


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var category_row := HBoxContainer.new()
	category_row.add_theme_constant_override("separation", 8)
	add_child(category_row)

	for category_variant: Variant in GameState.get_shop_bundle_categories():
		if not (category_variant is Dictionary):
			continue
		var category: Dictionary = category_variant
		var category_id := str(category.get("categoryId", ""))
		var button := Button.new()
		button.text = str(category.get("displayName", category.get("categoryType", "\u5206\u985e")))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 48.0)
		if category_id != _selected_category_id:
			button.modulate = Color(0.7, 0.7, 0.7, 1.0)
		button.pressed.connect(_on_category_selected.bind(category_id))
		category_row.add_child(button)

	var intro := Label.new()
	intro.text = "\u5546\u57ce\u79ae\u5305\u6703\u76f4\u63a5\u900f\u904e\u5f8c\u7aef\u6263\u6b3e\u8207\u767c\u734e\uff0c\u5167\u5bb9\u4ee5\u76ee\u524d\u4f3a\u670d\u5668\u8cc7\u6599\u70ba\u6e96\u3002"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 18)
	add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var bundles := GameState.get_shop_bundles_by_category(_selected_category_id)
	if bundles.is_empty():
		var empty_label := Label.new()
		empty_label.text = "\u9019\u500b\u5206\u985e\u76ee\u524d\u6c92\u6709\u79ae\u5305\u3002"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 22)
		list.add_child(empty_label)
		return

	for bundle_variant: Variant in bundles:
		if bundle_variant is Dictionary:
			list.add_child(_build_bundle_card(bundle_variant))


func _build_bundle_card(bundle: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _create_card_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 10)
	margin.add_child(card)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	card.add_child(header)

	var title := Label.new()
	title.text = str(bundle.get("displayName", "\u5546\u57ce\u79ae\u5305"))
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var status := Label.new()
	status.text = _build_limit_text(bundle)
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", Color(0.92, 0.80, 0.48, 1.0))
	header.add_child(status)

	var desc := Label.new()
	desc.text = str(bundle.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	card.add_child(desc)

	var reward_title := Label.new()
	reward_title.text = "\u5167\u5bb9\u7269"
	reward_title.add_theme_font_size_override("font_size", 18)
	card.add_child(reward_title)

	for reward_line: String in _build_reward_lines(bundle):
		var reward_label := Label.new()
		reward_label.text = reward_line
		reward_label.add_theme_font_size_override("font_size", 17)
		reward_label.add_theme_color_override("font_color", Color(0.84, 0.94, 1.0, 1.0))
		card.add_child(reward_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	card.add_child(action_row)

	var cost_label := Label.new()
	cost_label.text = "\u947d\u77f3 %d" % int(bundle.get("priceAmount", 0))
	cost_label.add_theme_font_size_override("font_size", 20)
	action_row.add_child(cost_label)

	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, 46.0)
	if bool(bundle.get("isSoldOut", false)):
		button.text = "\u5df2\u552e\u5b8c"
		button.disabled = true
	else:
		button.text = "\u8cfc\u8cb7"
		button.pressed.connect(_confirm_purchase.bind(
			int(bundle.get("bundleId", 0)),
			str(bundle.get("displayName", "\u5546\u57ce\u79ae\u5305")),
			int(bundle.get("priceAmount", 0))
		))
	action_row.add_child(button)

	return panel


func _confirm_purchase(bundle_id: int, bundle_name: String, price_amount: int) -> void:
	var message := "\u662f\u5426\u82b1\u8cbb %d \u947d\u77f3\u8cfc\u8cb7\u300c%s\u300d\uff1f" % [price_amount, bundle_name]
	DialogManager.show_confirm("\u8cfc\u8cb7\u79ae\u5305", message, func() -> void:
		_api_client.purchase_shop_bundle(bundle_id, _on_purchase_completed)
	)


func _on_category_selected(category_id: String) -> void:
	_selected_category_id = category_id
	_rebuild()


func _on_purchase_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success:
		DialogManager.show_info("\u8cfc\u8cb7\u5931\u6557", _extract_error_message(error, "\u8cfc\u8cb7\u79ae\u5305\u5931\u6557\u3002"))
		return
	var payload: Dictionary = data if data is Dictionary else {}
	var overview: Variant = payload.get("overview", {})
	if overview is Dictionary:
		GameState.update_shop(overview)
	var treasures_variant: Variant = payload.get("scooperTreasures", [])
	if treasures_variant is Array:
		GameState.update_scooper_treasure(treasures_variant)
	_rebuild()
	emit_signal("request_refresh")
	var reward_lines: Array[String] = []
	var rewards_variant: Variant = payload.get("grantedRewards", [])
	if rewards_variant is Array:
		for reward_variant: Variant in rewards_variant:
			if reward_variant is Dictionary:
				var reward: Dictionary = reward_variant
				reward_lines.append("%s x%d" % [
					str(reward.get("rewardDisplayName", reward.get("rewardType", "\u734e\u52f5"))),
					int(reward.get("quantity", 0)),
				])
	if reward_lines.is_empty():
		reward_lines.append("\u734e\u52f5\u5df2\u767c\u9001\u5b8c\u6210\u3002")
	DialogManager.show_info("\u8cfc\u8cb7\u6210\u529f", "\n".join(reward_lines))


func _build_limit_text(bundle: Dictionary) -> String:
	var purchase_count := int(bundle.get("purchaseCount", 0))
	var purchase_limit := int(bundle.get("purchaseLimit", 0))
	if bool(bundle.get("isSoldOut", false)):
		return "\u5df2\u552e\u5b8c"
	if purchase_limit < 0:
		return "\u5df2\u8cfc\u8cb7 %d \u6b21" % purchase_count
	return "\u5df2\u8cfc\u8cb7 %d / %d" % [purchase_count, purchase_limit]


func _build_reward_lines(bundle: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var rewards_variant: Variant = bundle.get("rewards", [])
	if rewards_variant is Array:
		for reward_variant: Variant in rewards_variant:
			if reward_variant is Dictionary:
				var reward: Dictionary = reward_variant
				result.append("%s x%d" % [
					str(reward.get("rewardDisplayName", reward.get("rewardType", "\u734e\u52f5"))),
					int(reward.get("quantity", 0)),
				])
	return result


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
