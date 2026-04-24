extends Control

const PermanentActivityContentScene = preload("res://scenes/activity/permanent/PermanentActivityContent.tscn")
const LimitedActivityContentScene = preload("res://scenes/activity/limited/LimitedActivityContent.tscn")

var _active_tab: String = "permanent"
var _tab_buttons: Dictionary = {}
var _content_scroll: ScrollContainer
var _scroll_box: VBoxContainer
var _permanent_content: Control
var _limited_content: Control
var _show_unfinished_content: bool = true


func _ready() -> void:
	_show_unfinished_content = RuntimeConfig.should_show_unfinished_content()
	if not _show_unfinished_content and _active_tab == "limited":
		_active_tab = "permanent"
	_build_ui()
	GameState.red_dot_state_changed.connect(_refresh_red_dots)


func _build_ui() -> void:
	var dock_items: Array[Dictionary] = [
		{
			"key": "permanent",
			"label": UiText.ACTIVITY_TAB_PERMANENT,
			"shell_description": UiText.ACTIVITY_PAGE_DESC,
			"shell_summary_right": Callable(self, "_build_tab_summary_right").bind("permanent"),
		},
	]
	if _show_unfinished_content:
		dock_items.append({
			"key": "limited",
			"label": UiText.ACTIVITY_TAB_LIMITED,
			"shell_description": UiText.ACTIVITY_LIMITED_EMPTY_BODY,
			"shell_summary_right": Callable(self, "_build_tab_summary_right").bind("limited"),
		})

	var chrome: Dictionary = OverlaySceneChrome.build(self, "activity", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": dock_items,
		"active_key": _active_tab,
		"button_pressed": Callable(self, "_switch_tab"),
		"button_height": 52.0,
		"font_size": 20,
	})
	var content_box: VBoxContainer = chrome.get("content_box")
	_tab_buttons = chrome.get("dock_buttons", {})

	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_box.add_child(_content_scroll)
	InertialScroller.attach(_content_scroll, "vertical")

	_scroll_box = VBoxContainer.new()
	_scroll_box.add_theme_constant_override("separation", 14)
	_scroll_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_scroll_box)

	_refresh_tab_state()
	_refresh_red_dots()
	_rebuild_tab_content()


func _switch_tab(tab_key: String) -> void:
	if tab_key == "limited" and not _show_unfinished_content:
		return
	if _active_tab == tab_key:
		return
	_active_tab = tab_key
	_refresh_tab_state()
	_rebuild_tab_content()


func _refresh_tab_state() -> void:
	SceneSubmenuBar.refresh(_tab_buttons, _active_tab, {
		"active_color": Color(1.0, 0.95, 0.82, 1.0),
		"inactive_color": Color(0.65, 0.65, 0.68, 1.0),
	})


func _rebuild_tab_content() -> void:
	if _scroll_box == null:
		return
	for child: Node in _scroll_box.get_children():
		child.queue_free()
	_permanent_content = null
	_limited_content = null

	match _active_tab:
		"limited":
			_build_limited_content()
		_:
			_build_permanent_content()


func _build_permanent_content() -> void:
	_permanent_content = PermanentActivityContentScene.instantiate() as Control
	if _permanent_content != null:
		_permanent_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_permanent_content.connect("entry_pressed", Callable(self, "_on_permanent_entry_pressed"))
		_scroll_box.add_child(_permanent_content)


func _build_limited_content() -> void:
	_limited_content = LimitedActivityContentScene.instantiate() as Control
	if _limited_content != null:
		_limited_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_scroll_box.add_child(_limited_content)


func _refresh_red_dots() -> void:
	if _permanent_content != null and _permanent_content.has_method("refresh_red_dots"):
		_permanent_content.call("refresh_red_dots")


func _build_tab_summary_right(tab_key: String) -> String:
	if tab_key == "limited":
		return UiText.ACTIVITY_LIMITED_CURRENT
	return UiText.ACTIVITY_PERMANENT_ENTER


func _on_dungeon_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/DungeonScene.tscn")


func _on_arena_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ArenaScene.tscn")


func _on_gacha_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/GachaScene.tscn")


func _on_expedition_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ExpeditionScene.tscn")


func _on_combat_trial_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/CombatTrialScene.tscn")


func _on_permanent_entry_pressed(entry_key: String) -> void:
	match entry_key:
		"gacha":
			_on_gacha_pressed()
		"dungeon":
			_on_dungeon_pressed()
		"arena":
			_on_arena_pressed()
		"combat_trial":
			_on_combat_trial_pressed()
		"expedition":
			_on_expedition_pressed()


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
