extends PanelContainer


func setup(channel_key: String, message: Dictionary) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	var header := Label.new()
	var sender := str(message.get("senderDisplayName", "System"))
	var time_text := str(message.get("sentAtUtc", "")).replace("T", " ").replace("Z", "")
	header.text = "[%s] %s  %s" % [channel_key.capitalize(), sender, time_text]
	header.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	content.add_child(header)

	var body := Label.new()
	body.text = str(message.get("content", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	content.add_child(body)
