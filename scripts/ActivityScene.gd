extends Control

const OverlaySceneChrome = preload("res://scripts/ui/overlay_scene_chrome.gd")
const UiPalette = preload("res://scripts/ui/ui_palette.gd")
const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")
const SceneSubmenuBar = preload("res://scripts/ui/scene_submenu_bar.gd")
const RedDotService = preload("res://scripts/ui/red_dot_service.gd")

const DUNGEON_CARD_ART := "res://assets/sprites/ui/dungeon_background_v1.png"
const ARENA_CARD_ART := "res://assets/sprites/ui/arena_background_v1.png"
const GACHA_CARD_ART := "res://assets/sprites/ui/gacha_background_v1.png"

var _active_tab: String = "permanent"
var _tab_buttons: Dictionary = {}
var _entry_buttons: Dictionary = {}
var _permanent_section: VBoxContainer
var _limited_section: VBoxContainer


func _ready() -> void:
	_build_ui()
	GameState.red_dot_state_changed.connect(_refresh_red_dots)


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "activity", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": [
			{"key": "permanent", "label": UiText.ACTIVITY_TAB_PERMANENT},
			{"key": "limited", "label": UiText.ACTIVITY_TAB_LIMITED},
		],
		"active_key": _active_tab,
		"button_pressed": Callable(self, "_switch_tab"),
		"button_height": 52.0,
		"font_size": 20,
	})
	var content_box: VBoxContainer = chrome.get("content_box")
	_tab_buttons = chrome.get("dock_buttons", {})

	var title: Label = Label.new()
	title.text = UiText.ACTIVITY_PAGE_TITLE
	UiFonts.apply_noto(title, UiPalette.FONT_SIZE_DISPLAY)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	content_box.add_child(title)

	var desc: Label = Label.new()
	desc.text = UiText.ACTIVITY_PAGE_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(desc, UiPalette.FONT_SIZE_BODY)
	desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	content_box.add_child(desc)

	var content_scroll: ScrollContainer = ScrollContainer.new()
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_box.add_child(content_scroll)
	InertialScroller.attach(content_scroll, "vertical")

	var scroll_box: VBoxContainer = VBoxContainer.new()
	scroll_box.add_theme_constant_override("separation", 14)
	scroll_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.add_child(scroll_box)

	_permanent_section = VBoxContainer.new()
	_permanent_section.add_theme_constant_override("separation", 14)
	scroll_box.add_child(_permanent_section)

	_permanent_section.add_child(_make_entry_card(
		"gacha",
		UiText.GACHA_PAGE_TITLE,
		UiText.ACTIVITY_GACHA_DESC,
		GACHA_CARD_ART,
		UiText.ACTIVITY_GACHA_BUTTON,
		Callable(self, "_on_gacha_pressed")
	))

	_permanent_section.add_child(_make_entry_card(
		"dungeon",
		UiText.DUNGEON_PAGE_TITLE,
		UiText.ACTIVITY_DUNGEON_DESC,
		DUNGEON_CARD_ART,
		UiText.ACTIVITY_DUNGEON_BUTTON,
		Callable(self, "_on_dungeon_pressed")
	))

	_permanent_section.add_child(_make_entry_card(
		"arena",
		UiText.ARENA_PAGE_TITLE,
		UiText.ACTIVITY_ARENA_DESC,
		ARENA_CARD_ART,
		UiText.ACTIVITY_ARENA_BUTTON,
		Callable(self, "_on_arena_pressed")
	))

	_limited_section = VBoxContainer.new()
	_limited_section.add_theme_constant_override("separation", 12)
	scroll_box.add_child(_limited_section)

	var empty_card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	_limited_section.add_child(empty_card)

	var empty_margin: MarginContainer = OverlaySceneChrome.make_content_margin(18)
	empty_card.add_child(empty_margin)

	var empty_box: VBoxContainer = VBoxContainer.new()
	empty_box.add_theme_constant_override("separation", 10)
	empty_margin.add_child(empty_box)

	var empty_title: Label = Label.new()
	empty_title.text = UiText.ACTIVITY_LIMITED_EMPTY_TITLE
	UiFonts.apply_noto(empty_title, UiPalette.FONT_SIZE_HEADING)
	empty_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	empty_box.add_child(empty_title)

	var empty_desc: Label = Label.new()
	empty_desc.text = UiText.ACTIVITY_LIMITED_EMPTY_BODY
	empty_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(empty_desc, 17)
	empty_desc.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	empty_box.add_child(empty_desc)

	_refresh_tab_state()
	_refresh_red_dots()


func _make_entry_card(
	entry_key: String,
	title_text: String,
	subtitle_text: String,
	art_path: String,
	button_text: String,
	callback: Callable
) -> PanelContainer:
	var card: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 320.0)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	card.add_child(margin)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var art_shell: PanelContainer = OverlaySceneChrome.make_card_panel(
		OverlaySceneChrome.CARD_BORDER,
		Color(0.14, 0.13, 0.15, 0.98),
		16
	)
	art_shell.custom_minimum_size = Vector2(0.0, 188.0)
	layout.add_child(art_shell)

	var art: TextureRect = TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.texture = AssetResolver.load_texture(art_path)
	art_shell.add_child(art)

	var art_overlay: ColorRect = ColorRect.new()
	art_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_overlay.color = Color(0.02, 0.02, 0.03, 0.30)
	art_shell.add_child(art_overlay)

	var body_row: HBoxContainer = HBoxContainer.new()
	body_row.add_theme_constant_override("separation", 12)
	body_row.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(body_row)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 8)
	body_row.add_child(text_box)

	var title: Label = Label.new()
	title.text = title_text
	UiFonts.apply_noto(title, UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	text_box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(0.0, 52.0)
	UiFonts.apply_noto(subtitle, 17)
	subtitle.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	text_box.add_child(subtitle)

	var text_spacer: Control = Control.new()
	text_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_box.add_child(text_spacer)

	var action_button: Button = Button.new()
	action_button.text = button_text
	action_button.custom_minimum_size = Vector2(168.0, 56.0)
	UiFonts.apply_noto(action_button, UiPalette.FONT_SIZE_BODY_LG)
	action_button.size_flags_vertical = Control.SIZE_SHRINK_END
	action_button.pressed.connect(callback)
	UiPalette.apply_button_kind(action_button, "primary")
	body_row.add_child(action_button)
	_entry_buttons[entry_key] = action_button

	return card


func _switch_tab(tab_key: String) -> void:
	if _active_tab == tab_key:
		return
	_active_tab = tab_key
	_refresh_tab_state()


func _refresh_tab_state() -> void:
	SceneSubmenuBar.refresh(_tab_buttons, _active_tab, {
		"active_color": Color(1.0, 0.95, 0.82, 1.0),
		"inactive_color": Color(0.65, 0.65, 0.68, 1.0),
	})
	if _permanent_section != null:
		_permanent_section.visible = _active_tab == "permanent"
	if _limited_section != null:
		_limited_section.visible = _active_tab == "limited"


func _refresh_red_dots() -> void:
	RedDotService.refresh_dot(_entry_buttons.get("gacha") as Control, RedDotService.has_gacha_red_dot())
	RedDotService.refresh_dot(_entry_buttons.get("dungeon") as Control, RedDotService.has_dungeon_red_dot())
	RedDotService.refresh_dot(_entry_buttons.get("arena") as Control, RedDotService.has_arena_red_dot())


func _on_dungeon_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/DungeonScene.tscn")


func _on_arena_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ArenaScene.tscn")


func _on_gacha_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/GachaScene.tscn")


func _on_back_pressed() -> void:
	SceneNavigator.return_to_battle()
