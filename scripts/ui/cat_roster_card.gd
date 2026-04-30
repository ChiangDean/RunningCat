class_name CatRosterCard
extends RefCounted

const SquareTemplateScene = preload("res://scenes/ui/cats/CatCardSquareTemplate.tscn")
const LineupTeamTemplateScene = preload("res://scenes/ui/lineup/CatCardLineupTeamTemplate.tscn")
const LineupOwnedTemplateScene = preload("res://scenes/ui/lineup/CatCardLineupOwnedTemplate.tscn")
const EnhanceListTemplateScene = preload("res://scenes/ui/cats/CatCardEnhanceListTemplate.tscn")

const CARD_RATIO := 0.6666667
const FRAME_MARGIN := 6.0
const TITLE_COLOR := Color(1.0, 0.93, 0.72, 1.0)
const TITLE_OUTLINE := Color(0.12, 0.08, 0.05, 0.95)
const BADGE_TARGET_META_KEY := "_badge_target"


static func build(options: Dictionary) -> PanelContainer:
	var is_selected: bool = bool(options.get("is_selected", false))
	var card_border: Color = options.get("card_border", Color(0.42, 0.35, 0.25, 0.0))
	var selected_card_border: Color = options.get("selected_card_border", Color(0.96, 0.86, 0.60, 1.0))
	var card_height: float = float(options.get("card_height", 248.0))
	var frame_margin: int = int(options.get("frame_margin", FRAME_MARGIN))
	var rarity_key: String = str(options.get("rarity_key", "common")).to_lower()
	var cat_icon: Texture2D = options.get("icon_texture", null)
	var empty_texture: Texture2D = AssetResolver.resolve_cat_card_empty_silhouette()
	var cat_type: String = str(options.get("cat_type", "base")).to_lower()
	var level_value: int = int(options.get("level_value", 1))
	var rank_value: int = int(options.get("rank_value", 0))
	var title_text: String = str(options.get("title_text", ""))
	var title_color: Color = options.get("title_color", TITLE_COLOR)
	var title_outline: Color = options.get("title_outline_color", TITLE_OUTLINE)
	var template_key: String = str(options.get("template_key", "square")).to_lower()
	var show_type_icon: bool = bool(options.get("show_type_icon", true))
	var show_rarity_label: bool = bool(options.get("show_rarity_label", true))
	var show_level_label: bool = bool(options.get("show_level_label", true))
	var show_rank_label: bool = bool(options.get("show_rank_label", true))

	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, card_height)
	card.add_theme_stylebox_override(
		"panel",
		OverlaySceneChrome.make_panel_style(
			Color(0.0, 0.0, 0.0, 0.0),
			selected_card_border if is_selected else card_border,
			int(options.get("card_radius", 18))
		)
	)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", frame_margin)
	margin.add_theme_constant_override("margin_top", frame_margin)
	margin.add_theme_constant_override("margin_right", frame_margin)
	margin.add_theme_constant_override("margin_bottom", frame_margin)
	card.add_child(margin)

	var aspect: AspectRatioContainer = AspectRatioContainer.new()
	aspect.ratio = CARD_RATIO
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(aspect)

	var fit_box: Control = Control.new()
	fit_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fit_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aspect.add_child(fit_box)

	var template_scene: PackedScene = _resolve_template_scene(template_key)
	var template: Control = template_scene.instantiate()
	template.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fit_box.add_child(template)
	var template_size: Vector2 = _measure_template_size(template)
	var template_values: Dictionary = {
		"frame_texture": AssetResolver.resolve_cat_card_square_frame(rarity_key),
		"type_icon": AssetResolver.resolve_cat_type_icon(cat_type),
		"portrait_texture": cat_icon if cat_icon != null else empty_texture,
		"rarity_text": _format_rarity_label(rarity_key),
		"level_text": "Lv.%d" % level_value,
		"name_text": title_text,
		"rank_text": str(rank_value),
		"title_color": title_color,
		"title_outline": title_outline,
		"show_type_icon": show_type_icon,
		"show_rarity_label": show_rarity_label,
		"show_level_label": show_level_label,
		"show_rank_label": show_rank_label,
	}
	if options.has("title_font_size"):
		template_values["title_font_size"] = int(options.get("title_font_size", 27))

	_apply_template(template, template_values)
	_fit_template(fit_box, template, template_size)
	fit_box.resized.connect(_fit_template.bind(fit_box, template, template_size))

	var badge_anchor: Control = Control.new()
	badge_anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(badge_anchor)
	card.set_meta(BADGE_TARGET_META_KEY, badge_anchor)

	var whole_card_pressed: Callable = options.get("whole_card_pressed", Callable())
	var whole_card_gui_input: Callable = options.get("whole_card_gui_input", Callable())
	if not whole_card_pressed.is_null() or not whole_card_gui_input.is_null():
		var overlay_button: Button = Button.new()
		overlay_button.flat = true
		overlay_button.text = ""
		overlay_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if not whole_card_pressed.is_null():
			overlay_button.pressed.connect(whole_card_pressed)
		if not whole_card_gui_input.is_null():
			overlay_button.gui_input.connect(whole_card_gui_input)
		card.add_child(overlay_button)

	return card


static func get_badge_target(card: Control) -> Control:
	if card == null or not card.has_meta(BADGE_TARGET_META_KEY):
		return card
	var target: Variant = card.get_meta(BADGE_TARGET_META_KEY)
	return target as Control


static func _apply_template(template: Control, values: Dictionary) -> void:
	var frame_rect: TextureRect = template.get_node("CardFrame")
	var type_rect: TextureRect = template.get_node("TypeIcon")
	var portrait_rect: TextureRect = template.get_node("Portrait")
	var rarity_label: Label = template.get_node("RarityLabel")
	var level_label: Label = template.get_node("LevelLabel")
	var name_label: Label = template.get_node("NameLabel")
	var rank_label: Label = template.get_node("RankLabel")

	frame_rect.texture = values.get("frame_texture", null)
	type_rect.texture = values.get("type_icon", null)
	type_rect.visible = bool(values.get("show_type_icon", true)) and type_rect.texture != null

	portrait_rect.texture = values.get("portrait_texture", null)
	rarity_label.text = str(values.get("rarity_text", ""))
	rarity_label.visible = bool(values.get("show_rarity_label", true))
	level_label.text = str(values.get("level_text", ""))
	level_label.visible = bool(values.get("show_level_label", true))
	name_label.text = str(values.get("name_text", ""))
	rank_label.text = str(values.get("rank_text", ""))
	rank_label.visible = bool(values.get("show_rank_label", true))

	var font_color: Color = values.get("title_color", TITLE_COLOR)
	var outline_color: Color = values.get("title_outline", TITLE_OUTLINE)
	for node: Label in [rarity_label, level_label, name_label, rank_label]:
		node.add_theme_color_override("font_color", font_color)
		node.add_theme_color_override("font_outline_color", outline_color)

	if values.has("title_font_size"):
		name_label.add_theme_font_size_override("font_size", int(values.get("title_font_size", 27)))


static func _resolve_template_scene(template_key: String) -> PackedScene:
	match template_key:
		"lineup_team":
			return LineupTeamTemplateScene
		"lineup_owned":
			return LineupOwnedTemplateScene
		"enhance_list":
			return EnhanceListTemplateScene
	return SquareTemplateScene


static func _fit_template(fit_box: Control, template: Control, template_size: Vector2) -> void:
	if fit_box == null or template == null:
		return
	var available: Vector2 = fit_box.size
	if available.x <= 0.0 or available.y <= 0.0:
		return
	var base_size: Vector2 = Vector2(maxf(1.0, template_size.x), maxf(1.0, template_size.y))
	var scale_ratio: float = minf(available.x / base_size.x, available.y / base_size.y)
	template.scale = Vector2(scale_ratio, scale_ratio)
	var scaled_size: Vector2 = base_size * scale_ratio
	template.position = ((available - scaled_size) * 0.5).floor()


static func _measure_template_size(template: Control) -> Vector2:
	var measured_size: Vector2 = template.size
	for child_node: Node in template.get_children():
		var child := child_node as Control
		if child == null:
			continue
		var child_bottom_right: Vector2 = child.position + child.size
		measured_size.x = maxf(measured_size.x, child_bottom_right.x)
		measured_size.y = maxf(measured_size.y, child_bottom_right.y)
	return Vector2(maxf(1.0, measured_size.x), maxf(1.0, measured_size.y))


static func _format_rarity_label(rarity_key: String) -> String:
	var normalized: String = rarity_key.strip_edges().to_lower()
	match normalized:
		"n", "common":
			return "N"
		"r", "rare", "uncommon":
			return "R"
		"sr", "super_rare", "epic", "fine":
			return "SR"
		"ssr", "ultra_rare", "legendary", "precious", "excellent":
			return "SSR"
		"sp", "special", "master":
			return "SP"
	if normalized == "":
		return "N"
	return normalized.to_upper()
