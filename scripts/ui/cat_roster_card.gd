class_name CatRosterCard
extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const SquareTemplateScene = preload("res://scenes/ui/CatCardSquareTemplate.tscn")
const LineupTeamTemplateScene = preload("res://scenes/ui/CatCardLineupTeamTemplate.tscn")
const LineupOwnedTemplateScene = preload("res://scenes/ui/CatCardLineupOwnedTemplate.tscn")
const EnhanceListTemplateScene = preload("res://scenes/ui/CatCardEnhanceListTemplate.tscn")

const CARD_RATIO := 1.0
const FRAME_MARGIN := 6.0
const TITLE_COLOR := Color(0.42, 0.28, 0.15, 1.0)
const TITLE_OUTLINE := Color(0.96, 0.92, 0.81, 0.86)
const TEMPLATE_SIZE := Vector2(520.0, 520.0)
const BADGE_TARGET_META_KEY := "_badge_target"


static func build(options: Dictionary) -> PanelContainer:
	var is_selected: bool = bool(options.get("is_selected", false))
	var card_border: Color = options.get("card_border", Color(0.42, 0.35, 0.25, 0.0))
	var selected_card_border: Color = options.get("selected_card_border", Color(0.96, 0.86, 0.60, 1.0))
	var card_height: float = float(options.get("card_height", 248.0))
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
	margin.add_theme_constant_override("margin_left", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_top", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_right", int(FRAME_MARGIN))
	margin.add_theme_constant_override("margin_bottom", int(FRAME_MARGIN))
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

	_apply_template(template, {
		"frame_texture": AssetResolver.resolve_cat_card_square_frame(rarity_key),
		"type_icon": AssetResolver.resolve_cat_type_icon(cat_type),
		"portrait_texture": cat_icon if cat_icon != null else empty_texture,
		"rarity_text": _format_rarity_label(rarity_key),
		"level_text": "Lv.%d" % level_value,
		"name_text": title_text,
		"rank_text": "R%d" % rank_value,
		"title_color": title_color,
		"title_outline": title_outline,
		"title_font_size": int(options.get("title_font_size", 27)),
		"show_type_icon": show_type_icon,
		"show_rarity_label": show_rarity_label,
		"show_level_label": show_level_label,
		"show_rank_label": show_rank_label,
	})
	_fit_template(fit_box, template)
	fit_box.resized.connect(_fit_template.bind(fit_box, template))

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


static func _fit_template(fit_box: Control, template: Control) -> void:
	if fit_box == null or template == null:
		return
	var available: Vector2 = fit_box.size
	if available.x <= 0.0 or available.y <= 0.0:
		return
	var scale_ratio: float = minf(available.x / TEMPLATE_SIZE.x, available.y / TEMPLATE_SIZE.y)
	template.scale = Vector2(scale_ratio, scale_ratio)
	var scaled_size: Vector2 = TEMPLATE_SIZE * scale_ratio
	template.position = ((available - scaled_size) * 0.5).floor()


static func _format_rarity_label(rarity_key: String) -> String:
	var text: String = rarity_key.strip_edges()
	if text == "":
		return "COMMON"
	return text.to_upper()
