extends PanelContainer

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")


func _ready() -> void:
	add_theme_stylebox_override(
		"panel",
		OverlaySceneChrome.make_panel_style(
			Color(0.18, 0.17, 0.20, 0.96),
			Color(0.42, 0.37, 0.28, 0.90),
			12
		)
	)


func setup(channel_key: String, message: Dictionary) -> void:
	for child: Node in get_children():
		child.queue_free()

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var avatar_id: String = str(message.get("senderAvatarId", "")).strip_edges()
	var avatar_rect: TextureRect = AssetResolver.create_icon_rect(
		AssetResolver.resolve_profile_avatar(avatar_id),
		Vector2(34.0, 34.0)
	)
	row.add_child(avatar_rect)

	var body: Label = Label.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	body.text = "%s: %s" % [_resolve_sender_name(channel_key, message), str(message.get("content", "")).strip_edges()]
	row.add_child(body)

	var time_label: Label = Label.new()
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.custom_minimum_size = Vector2(72.0, 0.0)
	time_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	time_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	time_label.text = _format_time(str(message.get("sentAtUtc", "")))
	row.add_child(time_label)


func _resolve_sender_name(channel_key: String, message: Dictionary) -> String:
	if channel_key == "system":
		return "系統"
	var sender_name: String = str(message.get("senderDisplayName", "")).strip_edges()
	return sender_name if sender_name != "" else "鏟屎官"


func _format_time(sent_at: String) -> String:
	if sent_at.contains("T"):
		var parts: PackedStringArray = sent_at.split("T")
		if parts.size() >= 2 and parts[1].length() >= 5:
			return parts[1].substr(0, 5)
	if sent_at.contains(" "):
		var parts: PackedStringArray = sent_at.split(" ")
		if parts.size() >= 2 and parts[1].length() >= 5:
			return parts[1].substr(0, 5)
	return sent_at.left(5) if sent_at.length() >= 5 else sent_at
