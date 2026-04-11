extends VBoxContainer

const RESULT_COLORS := {
	"Common": Color(0.78, 0.78, 0.78, 1.0),
	"Rare": Color(0.43, 0.73, 1.0, 1.0),
	"Epic": Color(0.78, 0.50, 1.0, 1.0),
	"Legendary": Color(1.0, 0.78, 0.36, 1.0),
}


func setup(results: Array) -> void:
	add_theme_constant_override("separation", 8)
	for result_variant: Variant in results:
		if result_variant is Dictionary:
			add_child(_build_row(result_variant))


func _build_row(result: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var rarity := str(result.get("rarityDisplayName", result.get("rarityType", "稀有度")))
	var rarity_label := Label.new()
	rarity_label.text = "[%s]" % rarity
	rarity_label.custom_minimum_size = Vector2(110.0, 0.0)
	rarity_label.add_theme_font_size_override("font_size", 20)
	rarity_label.add_theme_color_override("font_color", _resolve_color(result))
	row.add_child(rarity_label)

	var cat_label := Label.new()
	cat_label.text = str(result.get("catDisplayName", "未知貓咪"))
	cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_label.add_theme_font_size_override("font_size", 22)
	row.add_child(cat_label)

	var state_label := Label.new()
	if bool(result.get("isNewCat", false)):
		state_label.text = "NEW"
		state_label.add_theme_color_override("font_color", Color(0.36, 1.0, 0.62, 1.0))
	else:
		state_label.text = "%s +%d" % [
			str(result.get("duplicateRewardDisplayName", "碎片")),
			int(result.get("duplicateRewardAmount", 0)),
		]
		state_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.52, 1.0))
	state_label.add_theme_font_size_override("font_size", 18)
	row.add_child(state_label)

	return row


func _resolve_color(result: Dictionary) -> Color:
	var html := str(result.get("rarityColor", ""))
	if html != "" and html.begins_with("#"):
		return Color.html(html)
	return RESULT_COLORS.get(str(result.get("rarityType", "")), Color.WHITE)
