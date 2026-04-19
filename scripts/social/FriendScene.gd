class_name FriendScene
extends Control

const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const SOCIAL_SCENE := preload("res://scenes/social/SocialScene.tscn")

var _social_view
var _dock_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_social_view = SOCIAL_SCENE.instantiate()
	_social_view.set_mode("friend")
	_social_view.set_friend_overlay_mode(true)

	var chrome: Dictionary = OverlaySceneChrome.build(self, "chat", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": _social_view.get_friend_footer_items(),
		"active_key": _social_view.get_friend_section(),
		"button_pressed": Callable(self, "_on_section_selected"),
		"button_height": 52.0,
		"font_size": 20,
	})
	_dock_buttons = chrome.get("dock_buttons", {})

	var content_box: VBoxContainer = chrome.get("content_box") as VBoxContainer
	if content_box == null:
		push_error("FriendScene: failed to build overlay content host")
		return

	var title: Label = Label.new()
	title.text = UiText.HOME_FRIEND
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	content_box.add_child(title)

	var social_control: Control = _social_view as Control
	if social_control != null:
		social_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_social_view.friend_navigation_changed.connect(_sync_navigation)
	content_box.add_child(_social_view)
	_sync_navigation(_social_view.get_friend_footer_items(), _social_view.get_friend_section())


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()


func _on_section_selected(section_key: String) -> void:
	if _social_view == null:
		return
	_social_view.set_friend_section(section_key)


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
