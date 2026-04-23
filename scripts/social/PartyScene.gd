class_name PartyScene
extends Control

const SOCIAL_SCENE := preload("res://scenes/social/SocialScene.tscn")

var _social_view
var _dock_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_social_view = SOCIAL_SCENE.instantiate()
	_social_view.set_mode("party")
	_social_view.set_party_overlay_mode(true)

	var chrome: Dictionary = OverlaySceneChrome.build(self, "activity", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": _social_view.get_party_footer_items(),
		"active_key": _social_view.get_party_section(),
		"button_pressed": Callable(self, "_on_section_selected"),
		"button_height": 52.0,
		"font_size": 20,
	})
	_dock_buttons = chrome.get("dock_buttons", {})

	var content_box := chrome.get("content_box") as VBoxContainer
	if content_box == null:
		push_error("PartyScene: failed to build overlay content host")
		return

	var social_control := _social_view as Control
	if social_control != null:
		social_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		social_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_social_view.party_navigation_changed.connect(_sync_navigation)
	GameState.red_dot_state_changed.connect(_apply_red_dots)
	content_box.add_child(_social_view)
	_sync_navigation(_social_view.get_party_footer_items(), _social_view.get_party_section())


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()


func _on_section_selected(section_key: String) -> void:
	if _social_view == null:
		return
	_social_view.set_party_section(section_key)


func _sync_navigation(items: Array, active_key: String) -> void:
	var ordered_keys: Array[String] = []
	for item_variant: Variant in items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var key: String = str(item.get("key", ""))
		if key == "":
			continue
		ordered_keys.append(key)
		var button: Button = _dock_buttons.get(key) as Button
		if button == null:
			continue
		button.text = str(item.get("label", key))
		SceneSubmenuBar.apply_shell_metadata(button, item)
		button.visible = true

	for key_variant: Variant in _dock_buttons.keys():
		var key: String = str(key_variant)
		if key in ordered_keys:
			continue
		var button: Button = _dock_buttons.get(key) as Button
		if button == null:
			continue
		button.visible = false

	SceneSubmenuBar.refresh(_dock_buttons, active_key, {
		"active_font_size": 22,
		"inactive_font_size": 20,
	})
	_apply_red_dots()


func _apply_red_dots() -> void:
	RedDotService.refresh_dot(_dock_buttons.get("reviews") as Control, RedDotService.has_party_review_red_dot())
