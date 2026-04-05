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
const _PANEL_MIN_H := 0.0
const _FONT_TITLE   := 22
const _FONT_CONTENT := 18
const _FONT_BTN     := 18
const _FONT_HINT    := 16

const _INERTIAL_SCROLL := preload("res://scripts/ui/inertial_scroll.gd")


# ── 公開 API ────────────────────────────────────────────

func show_info(title: String, text: String, on_close: Callable = Callable()) -> Callable:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", _FONT_CONTENT)
	return _build(title, lbl, false, on_close, Callable())


## 回傳一個 Callable，呼叫它可從外部主動關閉這個 dialog
func show_info_node(title: String, content: Control, on_close: Callable = Callable()) -> Callable:
	# If the content is a ScrollContainer, attach the inertial scroller helper so touch drag has inertia/bounce
	if content is ScrollContainer:
		# Prefer calling the registered class; fallback to the preloaded script if needed
		if typeof(InertialScroller) != TYPE_NIL:
			InertialScroller.attach(content)
		elif _INERTIAL_SCROLL != null:
			_INERTIAL_SCROLL.attach(content)
	return _build(title, content, false, on_close, Callable())


func show_confirm(
		title: String,
		text: String,
		on_confirm: Callable,
		on_cancel: Callable = Callable(),
		ok_text: String = "確定",
		cancel_text: String = "取消"
) -> Callable:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", _FONT_CONTENT)
	return _build(title, lbl, true, on_confirm, on_cancel, ok_text, cancel_text)


# ── 內部建構 ────────────────────────────────────────────

## 回傳 close callable（供呼叫者主動關閉）
func _build(
		title: String,
		content: Control,
		is_confirm: bool,
		on_ok: Callable,
		on_cancel: Callable,
		ok_text: String = "確定",
		cancel_text: String = "取消"
) -> Callable:
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
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(center)

	var dialog_stack := VBoxContainer.new()
	dialog_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	dialog_stack.add_theme_constant_override("separation", 10)
	center.add_child(dialog_stack)

	# 主面板（吸收點擊，避免穿透到 overlay）
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_PANEL_MIN_W, _PANEL_MIN_H)
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
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# 標題列
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
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
		var hint_lbl := Label.new()
		hint_lbl.text = "點擊任意處關閉視窗"
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_lbl.add_theme_font_size_override("font_size", _FONT_HINT)
		hint_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		dialog_stack.add_child(hint_lbl)

	if is_confirm:
		var btn_row := HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_row.add_theme_constant_override("separation", 16)
		vbox.add_child(btn_row)

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

		var cancel_btn := Button.new()
		cancel_btn.text = cancel_text
		cancel_btn.custom_minimum_size = Vector2(110.0, 44.0)
		cancel_btn.add_theme_font_size_override("font_size", _FONT_BTN)
		cancel_btn.pressed.connect(func() -> void:
			canvas.queue_free()
			if on_cancel.is_valid():
				on_cancel.call()
		)
		btn_row.add_child(cancel_btn)

	return func() -> void: canvas.queue_free()
