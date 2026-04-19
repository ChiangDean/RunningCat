class_name MailOverlayScene
extends Control

const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const RedDotService = preload("res://scripts/ui/red_dot_service.gd")
const MAIL_SCENE := preload("res://scenes/MailScene.tscn")

var _mail_view: Control
var _dock_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_mail_view = MAIL_SCENE.instantiate() as Control
	if _mail_view == null:
		push_error("MailOverlayScene: failed to instantiate mail scene")
		return
	_mail_view.call("set_overlay_mode", true)

	var chrome: Dictionary = OverlaySceneChrome.build(self, "mail", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": _mail_view.call("get_footer_items"),
		"active_key": _mail_view.call("get_section"),
		"button_pressed": Callable(self, "_on_section_selected"),
		"button_height": 52.0,
		"font_size": 20,
	})
	_dock_buttons = chrome.get("dock_buttons", {})

	var content_box: VBoxContainer = chrome.get("content_box") as VBoxContainer
	if content_box == null:
		push_error("MailOverlayScene: failed to build overlay content host")
		return

	var title: Label = Label.new()
	title.text = UiText.HOME_MAIL
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	content_box.add_child(title)

	_mail_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mail_view.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_mail_view.connect("navigation_changed", Callable(self, "_sync_navigation"))
	GameState.red_dot_state_changed.connect(_apply_red_dots)
	content_box.add_child(_mail_view)
	_sync_navigation(_mail_view.call("get_footer_items"), _mail_view.call("get_section"))


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()


func _on_section_selected(section_key: String) -> void:
	if _mail_view == null:
		return
	_mail_view.call("set_section", section_key)


func _sync_navigation(items: Array, active_key: String) -> void:
	for item_variant: Variant in items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var key: String = str(item.get("key", ""))
		var button: Button = _dock_buttons.get(key) as Button
		if button == null:
			continue
		button.text = str(item.get("label", key))
		button.visible = true

	SceneSubmenuBar.refresh(_dock_buttons, active_key, {
		"active_font_size": 22,
		"inactive_font_size": 20,
	})
	_apply_red_dots()


func _apply_red_dots() -> void:
	RedDotService.refresh_dot(_dock_buttons.get("unread") as Control, RedDotService.has_mail_unread_red_dot())
