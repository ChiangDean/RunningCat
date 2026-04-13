## DialogManager.gd — 全域對話框管理（Autoload）
##
## 一般資訊框：右上 ✕ 按鈕 + 點擊任意處可關閉
##   DialogManager.show_info(title, text)
##   DialogManager.show_info(title, text, on_close_callable)
##   DialogManager.show_info_node(title, content_node)
##   DialogManager.show_info_node(title, content_node, on_close_callable)
##
## 二次確認框：確定 / 取消，overlay 不可點擊關閉
##   DialogManager.show_confirm(title, text, on_confirm_callable)
##   DialogManager.show_confirm(title, text, on_confirm_callable, on_cancel_callable)

extends Node

const _PANEL_MIN_W := 480.0
const _PANEL_W_MEDIUM := 560.0
const _PANEL_W_LARGE := 640.0
const _PANEL_W_XLARGE := 700.0
const _PANEL_MIN_H := 0.0
const _FONT_TITLE   := 22
const _FONT_CONTENT := 18
const _FONT_BTN     := 18
const _FONT_HINT    := 16

const _INERTIAL_SCROLL := preload("res://scripts/ui/inertial_scroll.gd")


# ── 公開 API ────────────────────────────────────────────

func show_info(title: String, text: String, on_close: Callable = Callable(), width_size: String = "small") -> Callable:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", _FONT_CONTENT)
	return _build(title, lbl, false, on_close, Callable(), "確定", "取消", width_size)


## 回傳一個 Callable，呼叫它可從外部主動關閉這個 dialog
func show_info_node(title: String, content: Control, on_close: Callable = Callable(), width_size: String = "small") -> Callable:
	# If the content is a ScrollContainer, attach the inertial scroller helper so touch drag has inertia/bounce
	if content is ScrollContainer:
		# Prefer calling the registered class; fallback to the preloaded script if needed
		if typeof(InertialScroller) != TYPE_NIL:
			InertialScroller.attach(content)
		elif _INERTIAL_SCROLL != null:
			_INERTIAL_SCROLL.attach(content)
	return _build(title, content, false, on_close, Callable(), "確定", "取消", width_size)


func show_confirm(
		title: String,
		text: String,
		on_confirm: Callable,
		on_cancel: Callable = Callable(),
		ok_text: String = "確定",
		cancel_text: String = "取消",
		width_size: String = "small"
) -> Callable:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", _FONT_CONTENT)
	return _build(title, lbl, true, on_confirm, on_cancel, ok_text, cancel_text, width_size)


func _resolve_panel_width(width_size: String) -> float:
	match width_size.to_lower():
		"medium":
			return _PANEL_W_MEDIUM
		"large":
			return _PANEL_W_LARGE
		"xlarge":
			return _PANEL_W_XLARGE
		_:
			return _PANEL_MIN_W


func _measure_label_min_size(label: Label, content_width: float) -> Vector2:
	var font: Font = label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if font == null:
		return Vector2(content_width, 4.0 * 24.0)

	var line_height := font.get_height(font_size)
	var measured_lines := 0
	for raw_line: String in label.text.split("\n", false):
		var line_text := raw_line if raw_line != "" else " "
		var line_width := font.get_string_size(line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		measured_lines += maxi(1, ceili(line_width / maxf(1.0, content_width)))

	measured_lines = maxi(measured_lines, 1)
	return Vector2(content_width, measured_lines * line_height)


func _get_content_min_size(content: Control, content_width: float) -> Vector2:
	if content is Label:
		return _measure_label_min_size(content as Label, content_width)

	var min_size := content.get_combined_minimum_size()
	min_size.x = maxf(min_size.x, content_width)
	return min_size


# ── 內部建構 ────────────────────────────────────────────

## 回傳 close callable（供呼叫者主動關閉）
func _build(
		title: String,
		content: Control,
		is_confirm: bool,
		on_ok: Callable,
		on_cancel: Callable,
		ok_text: String = "確定",
		cancel_text: String = "取消",
		width_size: String = "small"
) -> Callable:
	var panel_width := _resolve_panel_width(width_size)
	var content_width := panel_width - 32.0
	if content is Label or content is RichTextLabel:
		content.custom_minimum_size.x = content_width
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = 0

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	# 半透明底層 overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.68)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	if not is_confirm:
		# 點擊 overlay（panel 外側）即關閉
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		overlay.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				canvas.queue_free()
				if on_ok.is_valid():
					on_ok.call()
		)
	else:
		# Confirm 框：overlay 不可點擊關閉
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(center)

	var dialog_stack := VBoxContainer.new()
	dialog_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	dialog_stack.add_theme_constant_override("separation", 10)
	dialog_stack.custom_minimum_size.x = panel_width
	dialog_stack.size_flags_vertical = 0
	center.add_child(dialog_stack)

	# 主面板（吸收點擊，避免穿透到 overlay）
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(panel_width, _PANEL_MIN_H)
	panel.size_flags_vertical = 0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.12, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.9, 0.9, 0.9, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_stack.add_child(panel)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = 0
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_vertical = 0
	margin.add_child(vbox)
	var hint_lbl: Label = null
	var btn_row: HBoxContainer = null

	# 標題列
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.size_flags_vertical = 0
	vbox.add_child(title_row)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", _FONT_TITLE)
	title_row.add_child(title_lbl)

	if not is_confirm:
		var close_btn := Button.new()
		close_btn.text = "✕"
		close_btn.custom_minimum_size = Vector2(36.0, 36.0)
		close_btn.flat = false
		close_btn.pressed.connect(func() -> void:
			canvas.queue_free()
			if on_ok.is_valid():
				on_ok.call()
		)
		title_row.add_child(close_btn)

	# 內容
	vbox.add_child(content)

	if not is_confirm:
		hint_lbl = Label.new()
		hint_lbl.text = "點擊任意處關閉視窗"
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_lbl.add_theme_font_size_override("font_size", _FONT_HINT)
		hint_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		dialog_stack.add_child(hint_lbl)

	if is_confirm:
		btn_row = HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_row.add_theme_constant_override("separation", 16)
		vbox.add_child(btn_row)

		var cancel_btn := Button.new()
		cancel_btn.text = cancel_text
		cancel_btn.custom_minimum_size = Vector2(110.0, 44.0)
		cancel_btn.add_theme_font_size_override("font_size", _FONT_BTN)
		cancel_btn.pressed.connect(func() -> void:
			canvas.queue_free()
			if on_cancel.is_valid():
				on_cancel.call()
		)
		var ok_btn := Button.new()
		ok_btn.text = ok_text
		ok_btn.custom_minimum_size = Vector2(110.0, 44.0)
		ok_btn.add_theme_font_size_override("font_size", _FONT_BTN)
		ok_btn.pressed.connect(func() -> void:
			canvas.queue_free()
			if on_ok.is_valid():
				on_ok.call()
		)
		btn_row.add_child(ok_btn)
		btn_row.add_child(cancel_btn)

	var content_min := _get_content_min_size(content, content_width)
	var title_min := title_row.get_combined_minimum_size()
	var button_min := btn_row.get_combined_minimum_size() if is_confirm else Vector2.ZERO
	var hint_min := hint_lbl.get_combined_minimum_size() if not is_confirm else Vector2.ZERO
	var vertical_gap := 12.0
	var body_height := title_min.y + content_min.y
	if is_confirm:
		body_height += vertical_gap + button_min.y
	panel.custom_minimum_size = Vector2(
		panel_width,
		maxf(_PANEL_MIN_H, body_height + 32.0)
	)
	panel.size = panel.custom_minimum_size
	dialog_stack.custom_minimum_size = Vector2(panel.custom_minimum_size.x, panel.custom_minimum_size.y + hint_min.y + (10.0 if not is_confirm else 0.0))
	call_deferred("_fit_dialog_to_content", panel, margin, vbox, dialog_stack, hint_lbl, panel_width)
	return func() -> void: canvas.queue_free()


func _fit_dialog_to_content(
		panel: PanelContainer,
		margin: MarginContainer,
		vbox: VBoxContainer,
		dialog_stack: VBoxContainer,
		hint_lbl: Label,
		panel_width: float
) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(margin) or not is_instance_valid(vbox) or not is_instance_valid(dialog_stack):
		return

	var body_height := vbox.get_combined_minimum_size().y
	var panel_height := maxf(_PANEL_MIN_H, body_height + 32.0)
	panel.custom_minimum_size = Vector2(panel_width, panel_height)
	panel.size = panel.custom_minimum_size

	var hint_height := 0.0
	if is_instance_valid(hint_lbl):
		hint_height = hint_lbl.get_combined_minimum_size().y + 10.0

	dialog_stack.custom_minimum_size = Vector2(panel_width, panel_height + hint_height)
