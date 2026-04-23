class_name ScooperScene
extends Control

const SW := 720.0
const SH := 1280.0
const SHELL_SCENE: PackedScene = preload("res://scenes/ui/overlay/SubmenuShellEditor.tscn")

const TAB_CONTENT_LEFT := OverlaySceneChrome.SUBMENU_SHELL_CONTENT_LEFT
const TAB_CONTENT_TOP := OverlaySceneChrome.SUBMENU_SHELL_HEADER_CONTENT_TOP
const TAB_CONTENT_RIGHT := OverlaySceneChrome.SUBMENU_SHELL_CONTENT_RIGHT
const TAB_CONTENT_BOTTOM := -24.0
const TAB_CONTENT_TO_SUBMENU_GAP := OverlaySceneChrome.SUBMENU_SHELL_CONTENT_TO_SUBMENU_GAP

const SUBMENU_TAB_DEFAULT_COLOR := Color(0.9529412, 0.85490197, 0.7176471, 1.0)
const SUBMENU_TAB_ACTIVE_COLOR := Color(0.98, 0.97, 0.92, 1.0)
const SUBMENU_TAB_FONT_SIZE := 18

const SUBMENU_BACK_BUTTON_RECT := Rect2(9.0, 39.0, 102.59459, 78.0)
const SUBMENU_TAB_BUTTON_RECTS := {
	"equipment": Rect2(137.0, 39.0, 107.52432, 78.0),
	"ability": Rect2(244.52432, 39.0, 107.52433, 78.0),
	"memory": Rect2(352.04865, 39.0, 107.52432, 78.0),
	"treasure": Rect2(459.57297, 39.0, 107.52433, 78.0),
	"achievement": Rect2(567.0973, 39.0, 107.52434, 78.0),
}
const SUBMENU_TAB_LABEL_PATHS := {
	"equipment": "TabEquipLabel",
	"ability": "TabAbilityLabel",
	"memory": "TabMemoryLabel",
	"treasure": "TabTreasureLabel",
	"achievement": "TabAchievementLabel",
}

var _current_tab: String = "equipment"
var _tab_btns: Dictionary = {}
var _tab_header_title: Label
var _tab_header_desc: Label
var _tab_header_summary: Label
var _tab_content: VBoxContainer
var _resource_label: Label

var _level_label: Label
var _exp_label: Label
var _equipment_upgrade_cooldown_remaining: float = 0.0
var _equipment_action_cooldown_remaining: float = 0.0
var _equipment_action_cooldown_duration: float = 0.5
var _equipment_cooldown_equipment_id: int = 0
var _equipment_cooldown_action: String = ""
var _equipment_cooldown_nodes: Array[Dictionary] = []
var _ability_list: VBoxContainer
var _equip_list: VBoxContainer
var _memory_summary_label: Label
var _memory_list: VBoxContainer
var _treasure_summary_label: Label
var _treasure_list: VBoxContainer
var _achievement_summary_label: Label
var _achievement_list: VBoxContainer
var _achievement_feedback_label: Label
var _ability_scroller: InertialScroller
var _equip_scroller: InertialScroller
var _memory_scroller: InertialScroller
var _treasure_scroller: InertialScroller
var _achievement_scroller: InertialScroller
var _achievement_claimed_expanded: bool = false
var _api_in_flight: bool = false

const TAB_KEYS: Array = ["equipment", "ability", "memory", "treasure", "achievement"]

@onready var GameState = get_node("/root/GameState")
@onready var ApiClient = get_node("/root/ApiClient")
@onready var DialogManager = get_node("/root/DialogManager")

var _equipment_tab: RefCounted = preload("res://scripts/scooper/scooper_tab_scooper.gd").new()
var _ability_tab: RefCounted = preload("res://scripts/scooper/scooper_tab_ability.gd").new()
var _memory_tab: RefCounted = preload("res://scripts/scooper/scooper_tab_memory.gd").new()
var _treasure_tab: RefCounted = preload("res://scripts/scooper/scooper_tab_treasure.gd").new()
var _achievement_tab: RefCounted = preload("res://scripts/scooper/scooper_tab_achievement.gd").new()


func _ready() -> void:
	_register_helper_shared_state()
	_build_ui()
	GameState.red_dot_state_changed.connect(_refresh_red_dots)
	set_process(true)


func _register_helper_shared_state() -> void:
	# These scene fields are intentionally read and mutated by helper modules.
	var shared_state_snapshot: Array[Variant] = [
		_equipment_action_cooldown_duration,
		_equipment_cooldown_equipment_id,
		_equipment_cooldown_action,
		_achievement_claimed_expanded,
		_api_in_flight,
	]
	if shared_state_snapshot.is_empty():
		return


func _build_ui() -> void:
	var shell_root: Control = SHELL_SCENE.instantiate() as Control
	add_child(shell_root)

	var content_root: Control = shell_root.get_node("ContentRoot") as Control
	var content_frame: TextureRect = shell_root.get_node("ContentRoot/Frame") as TextureRect
	var submenu_root: Control = shell_root.get_node("SubmenuBarRoot") as Control
	var tab_host: MarginContainer = shell_root.get_node("ContentRoot/ShellContentHost") as MarginContainer
	var default_viewport_scroll: ScrollContainer = shell_root.get_node("ContentRoot/ShellContentHost/ShellViewportScroll") as ScrollContainer
	_tab_header_title = shell_root.get_node("ContentRoot/SubmenuTitle") as Label
	_tab_header_desc = shell_root.get_node("ContentRoot/SubmenuDescription") as Label
	_resource_label = shell_root.get_node("ContentRoot/SummaryLeft") as Label
	_tab_header_summary = shell_root.get_node("ContentRoot/SummaryRight") as Label
	_refresh_resource_label()

	tab_host.clip_contents = true
	var default_content_bottom_offset: float = tab_host.offset_bottom
	tab_host.offset_bottom = _resolve_tab_content_bottom_offset(shell_root, content_root, content_frame, default_content_bottom_offset)
	var sync_frame_height: Callable = _sync_content_frame_height.bind(content_root, content_frame, submenu_root)
	sync_frame_height.call_deferred()
	content_root.resized.connect(sync_frame_height)
	content_frame.resized.connect(sync_frame_height)
	submenu_root.resized.connect(sync_frame_height)
	if default_viewport_scroll != null:
		default_viewport_scroll.queue_free()

	_tab_content = VBoxContainer.new()
	_tab_content.clip_contents = true
	_tab_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tab_content.add_theme_constant_override("separation", 12)
	tab_host.add_child(_tab_content)

	_build_shell_submenu(submenu_root)

	_refresh_tab_button_labels()
	_switch_tab(_current_tab)


func _resolve_tab_content_bottom_offset(
	_shell_root: Control,
	_content_root: Control,
	_content_frame: TextureRect,
	default_content_bottom_offset: float
) -> float:
	var target_bottom: float = default_content_bottom_offset
	return target_bottom


func _sync_content_frame_height(content_root: Control, content_frame: TextureRect, submenu_root: Control) -> void:
	if content_root == null or content_frame == null or submenu_root == null:
		return
	var submenu_limit: float = submenu_root.offset_top - content_root.offset_top - TAB_CONTENT_TO_SUBMENU_GAP
	var target_frame_bottom: float = submenu_limit + OverlaySceneChrome.SUBMENU_SHELL_FRAME_EXTRA_BOTTOM
	content_frame.offset_bottom = target_frame_bottom


func _process(delta: float) -> void:
	if _equipment_action_cooldown_remaining > 0.0:
		var previous_action_remaining: float = _equipment_action_cooldown_remaining
		_equipment_action_cooldown_remaining = maxf(0.0, _equipment_action_cooldown_remaining - delta)
		if previous_action_remaining > 0.0 and _equipment_action_cooldown_remaining <= 0.0 and _current_tab == "equipment":
			_equipment_tab.call("_refresh_equipment_tab", self)
	if _equipment_upgrade_cooldown_remaining > 0.0:
		var previous_remaining: float = _equipment_upgrade_cooldown_remaining
		_equipment_upgrade_cooldown_remaining = maxf(0.0, _equipment_upgrade_cooldown_remaining - delta)
		if previous_remaining > 0.0 and _equipment_upgrade_cooldown_remaining <= 0.0 and _current_tab == "equipment":
			_equipment_tab.call("_refresh_equipment_tab", self)
	_equipment_tab.process(self, delta)


func _switch_tab(tab_key: String) -> void:
	if not TAB_KEYS.has(tab_key):
		return
	_current_tab = tab_key
	if _tab_header_summary != null:
		_tab_header_summary.text = ""
	_refresh_tab_button_labels()
	_refresh_tab_header()
	_refresh_shell_submenu(tab_key)
	_refresh_red_dots()
	_rebuild_tab_content()


func _rebuild_tab_content() -> void:
	for child in _tab_content.get_children():
		child.queue_free()
	_level_label = null
	_exp_label = null
	_equipment_cooldown_nodes.clear()
	_ability_list = null
	_equip_list = null
	_memory_summary_label = null
	_memory_list = null
	_treasure_summary_label = null
	_treasure_list = null
	_achievement_summary_label = null
	_achievement_list = null
	_achievement_feedback_label = null
	_ability_scroller = null
	_equip_scroller = null
	_memory_scroller = null
	_treasure_scroller = null
	_achievement_scroller = null

	match _current_tab:
		"equipment":
			_equipment_tab.build(self)
		"ability":
			_ability_tab.build(self)
		"memory":
			_memory_tab.build(self)
		"treasure":
			_treasure_tab.build(self)
		"achievement":
			_achievement_tab.build(self)


func _refresh_tab_header() -> void:
	var meta: Dictionary = _get_tab_meta(_current_tab)
	_tab_header_title.text = str(meta.get("title", UiText.SCOOPER_PAGE_TITLE))
	_tab_header_desc.text = str(meta.get("description", ""))


func _refresh_tab_button_labels() -> void:
	for tab_key: String in _tab_btns.keys():
		var btn: Button = _tab_btns[tab_key]
		if btn == null:
			continue
		_set_shell_button_label(btn, str(_get_tab_meta(tab_key).get("label", tab_key)))
	_refresh_shell_submenu(_current_tab)
	_refresh_red_dots()


func _refresh_red_dots() -> void:
	RedDotService.refresh_dot(_tab_btns.get("equipment") as Control, RedDotService.has_scooper_equipment_red_dot())
	RedDotService.refresh_dot(_tab_btns.get("memory") as Control, RedDotService.has_scooper_memory_red_dot())
	RedDotService.refresh_dot(_tab_btns.get("achievement") as Control, RedDotService.has_scooper_achievement_red_dot())


func _get_tab_meta(tab_key: String) -> Dictionary:
	match tab_key:
		"equipment":
			return {
				"label": UiText.SCOOPER_TAB_EQUIPMENT,
				"title": UiText.SCOOPER_TAB_EQUIPMENT,
				"description": UiText.SCOOPER_DESC_EQUIPMENT,
			}
		"ability":
			return {
				"label": UiText.SCOOPER_TAB_ABILITY,
				"title": UiText.SCOOPER_TAB_ABILITY,
				"description": UiText.SCOOPER_DESC_ABILITY,
			}
		"memory":
			return {
				"label": UiText.SCOOPER_TAB_MEMORY,
				"title": UiText.SCOOPER_TAB_MEMORY,
				"description": UiText.SCOOPER_DESC_MEMORY,
			}
		"treasure":
			return {
				"label": UiText.SCOOPER_TAB_TREASURE,
				"title": UiText.SCOOPER_TAB_TREASURE,
				"description": UiText.SCOOPER_DESC_TREASURE,
			}
		"achievement":
			return {
				"label": UiText.SCOOPER_TAB_ACHIEVEMENT,
				"title": UiText.SCOOPER_TAB_ACHIEVEMENT,
				"description": UiText.SCOOPER_DESC_ACHIEVEMENT,
			}
		_:
			return {
				"label": UiText.SCOOPER_PAGE_TITLE,
				"title": UiText.SCOOPER_PAGE_TITLE,
				"description": "",
			}


func _apply_profile_to_player_data(profile: Dictionary) -> void:
	GameState.update_scooper_profile(profile)
	_refresh_resource_label()


func refresh_from_bootstrap(on_completed: Callable = Callable()) -> void:
	ApiClient.get_authenticated_bootstrap(Callable(self, "_on_refresh_from_bootstrap_completed").bind(on_completed))


func _on_refresh_from_bootstrap_completed(ok: bool, data: Variant, err: Dictionary, on_completed: Callable) -> void:
	if ok and data is Dictionary:
		GameState.apply_player_bootstrap(data)
		_refresh_resource_label()
		if _tab_content != null:
			_rebuild_tab_content()
	elif not on_completed.is_null():
		on_completed.call(false, {}, err)
		return

	if not on_completed.is_null():
		on_completed.call(ok, data, err)


func _refresh_resource_label() -> void:
	_resource_label.text = UiText.SCOOPER_RESOURCE_FORMAT % [
		GameState.player_data.gold,
		GameState.player_data.poop_count,
		GameState.player_data.memory_shards,
	]


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _show_loading_in(container: VBoxContainer) -> void:
	var lbl: Label = Label.new()
	lbl.text = UiText.SCOOPER_EQUIPMENT_LOADING
	lbl.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	container.add_child(lbl)


func _make_card_panel(accent: Color = OverlaySceneChrome.CARD_BORDER) -> PanelContainer:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(accent)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel


func queue_home_reward_floats(entries: Array[Dictionary]) -> void:
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	if battle_scene != null and battle_scene.has_method("queue_home_reward_floats"):
		battle_scene.queue_home_reward_floats(entries)


func make_reward_float_entry(label: String, amount: int, reward_key: String, color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> Dictionary:
	if color.a <= 0.0:
		match reward_key:
			"gold":
				color = Color(1.0, 0.84, 0.25, 1.0)
			"diamonds":
				color = Color(0.35, 0.86, 1.0, 1.0)
			"poop":
				color = Color(0.80, 0.58, 0.35, 1.0)
			"exp":
				color = Color(0.63, 0.96, 0.54, 1.0)
			"memory_shards":
				color = Color(0.87, 0.72, 1.0, 1.0)
			"whiskers":
				color = Color(1.0, 0.66, 0.82, 1.0)
			"cat_food":
				color = Color(1.0, 0.73, 0.43, 1.0)
			_:
				color = Color(0.98, 0.92, 0.76, 1.0)
	return {
		"label": label,
		"amount": amount,
		"key": reward_key,
		"color": color,
	}


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()


func _build_shell_submenu(submenu_root: Control) -> void:
	var back_label: Label = submenu_root.get_node("BackLabel") as Label
	if back_label != null:
		back_label.text = UiText.SCOOPER_BACK
	var back_button: Button = _make_shell_hit_button(SUBMENU_BACK_BUTTON_RECT)
	back_button.pressed.connect(_on_back_pressed)
	submenu_root.add_child(back_button)

	_tab_btns.clear()
	for tab_key: String in TAB_KEYS:
		var label_path: String = str(SUBMENU_TAB_LABEL_PATHS.get(tab_key, ""))
		var label: Label = submenu_root.get_node_or_null(label_path) as Label
		if label == null:
			continue
		var button_rect: Rect2 = SUBMENU_TAB_BUTTON_RECTS.get(tab_key, Rect2())
		var tab_button: Button = _make_shell_hit_button(button_rect)
		tab_button.set_meta("submenu_label", label)
		tab_button.pressed.connect(_switch_tab.bind(tab_key))
		submenu_root.add_child(tab_button)
		_tab_btns[tab_key] = tab_button


func _make_shell_hit_button(button_rect: Rect2) -> Button:
	var button: Button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.text = ""
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = button_rect.position.x
	button.offset_top = button_rect.position.y
	button.offset_right = button_rect.position.x + button_rect.size.x
	button.offset_bottom = button_rect.position.y + button_rect.size.y
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)
	button.add_theme_stylebox_override("disabled", empty_style)
	return button


func _set_shell_button_label(button: Button, text: String) -> void:
	if button == null:
		return
	var label: Label = button.get_meta("submenu_label", null) as Label
	if label != null:
		label.text = text


func _refresh_shell_submenu(active_key: String) -> void:
	for tab_key: String in _tab_btns.keys():
		var button: Button = _tab_btns.get(tab_key) as Button
		if button == null:
			continue
		var label: Label = button.get_meta("submenu_label", null) as Label
		if label == null:
			continue
		var is_active: bool = tab_key == active_key
		label.add_theme_color_override("font_color", SUBMENU_TAB_ACTIVE_COLOR if is_active else SUBMENU_TAB_DEFAULT_COLOR)
		label.add_theme_font_size_override("font_size", SUBMENU_TAB_FONT_SIZE)
