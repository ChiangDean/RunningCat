extends VBoxContainer

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")


func setup(results: Array) -> void:
	add_theme_constant_override("separation", 8)
	for result_variant: Variant in results:
		if result_variant is Dictionary:
			add_child(_build_row(result_variant))


func _build_row(result: Dictionary) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.16, 0.2, 0.92)
	style.border_color = _resolve_color(result)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var frame_texture: Texture2D = AssetResolver.resolve_gacha_frame(result)
	if frame_texture != null:
		row.add_child(AssetResolver.create_icon_rect(frame_texture, Vector2(74.0, 74.0)))

	var cat_icon: Texture2D = AssetResolver.resolve_cat_icon(str(result.get("catId", "")))
	if cat_icon != null:
		row.add_child(AssetResolver.create_icon_rect(cat_icon, Vector2(56.0, 56.0)))

	var rarity: String = str(result.get("rarityDisplayName", result.get("rarityType", UiText.GACHA_RESULT_RARITY_FALLBACK)))
	var rarity_label: Label = Label.new()
	rarity_label.text = "[%s]" % rarity
	rarity_label.custom_minimum_size = Vector2(110.0, 0.0)
	rarity_label.add_theme_font_size_override("font_size", 20)
	rarity_label.add_theme_color_override("font_color", _resolve_color(result))
	row.add_child(rarity_label)

	var cat_label: Label = Label.new()
	cat_label.text = str(result.get("catDisplayName", UiText.GACHA_RESULT_CAT_FALLBACK))
	cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_label.add_theme_font_size_override("font_size", 22)
	row.add_child(cat_label)

	var state_label: Label = Label.new()
	if bool(result.get("isNewCat", false)):
		state_label.text = UiText.GACHA_RESULT_NEW
		state_label.add_theme_color_override("font_color", Color(0.36, 1.0, 0.62, 1.0))
	else:
		state_label.text = UiText.GACHA_RESULT_DUPLICATE_REWARD_FORMAT % [
			str(result.get("duplicateRewardDisplayName", UiText.GACHA_RESULT_DUPLICATE_FALLBACK)),
			int(result.get("duplicateRewardAmount", 0)),
		]
		state_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.52, 1.0))
	state_label.add_theme_font_size_override("font_size", 18)
	row.add_child(state_label)

	return panel


func _resolve_color(result: Dictionary) -> Color:
	var html: String = str(result.get("rarityColor", ""))
	if html != "" and html.begins_with("#"):
		return Color.html(html)
	return GameConstants.get_rarity_color_from_string(str(result.get("rarityType", "")))
