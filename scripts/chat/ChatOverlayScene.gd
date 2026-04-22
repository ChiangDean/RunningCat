class_name ChatOverlayScene
extends Control

const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const CHAT_SCENE := preload("res://scenes/chat/ChatScene.tscn")

var _chat_view
var _dock_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_chat_view = CHAT_SCENE.instantiate()
	_chat_view.set_overlay_mode(true)

	var chrome: Dictionary = OverlaySceneChrome.build(self, "chat", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": _chat_view.get_footer_items(),
		"active_key": _chat_view.get_section(),
		"button_pressed": Callable(self, "_on_section_selected"),
		"button_height": 52.0,
		"font_size": 20,
	})
	_dock_buttons = chrome.get("dock_buttons", {})

	var content_box: VBoxContainer = chrome.get("content_box") as VBoxContainer
	if content_box == null:
		push_error("ChatOverlayScene: failed to build overlay content host")
		return

	var chat_control: Control = _chat_view as Control
	if chat_control != null:
		chat_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chat_control.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_chat_view.navigation_changed.connect(_sync_navigation)
	content_box.add_child(_chat_view)
	_sync_navigation(_chat_view.get_footer_items(), _chat_view.get_section())


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()


func _on_section_selected(section_key: String) -> void:
	if _chat_view == null:
		return
	_chat_view.set_section(section_key)


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
		SceneSubmenuBar.apply_shell_metadata(button, item)
		button.visible = true

	SceneSubmenuBar.refresh(_dock_buttons, active_key, {
		"active_font_size": 22,
		"inactive_font_size": 20,
	})
