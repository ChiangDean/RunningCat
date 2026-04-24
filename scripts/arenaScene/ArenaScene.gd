extends Control

const Helpers = preload("res://scripts/arenaScene/arena_scene_helpers.gd")
const REWARD_ROW_SCENE = preload("res://scenes/ui/arena/rewards/ArenaRewardRowEditor.tscn")

const REROLL_COOLDOWN := 5.0
const OPPONENT_SLOT_FILL := Color(0.19, 0.17, 0.15, 0.96)
const OPPONENT_SLOT_BORDER := Color(0.90, 0.77, 0.46, 0.88)
const OPPONENT_SLOT_TEXT := Color(0.98, 0.95, 0.88, 1.0)
const OPPONENT_SLOT_MUTED := Color(0.86, 0.80, 0.70, 0.95)
const OPPONENT_META_FILL := Color(0.21, 0.18, 0.16, 0.94)
const OPPONENT_META_BORDER := Color(0.52, 0.43, 0.30, 0.92)
const TEAM_SLOT_FILL := Color(0.24, 0.20, 0.16, 0.96)
const TEAM_SLOT_BORDER := Color(0.98, 0.84, 0.54, 0.95)
const TEAM_SLOT_EMPTY_FILL := Color(0.20, 0.18, 0.16, 0.88)
const TEAM_SLOT_EMPTY_BORDER := Color(0.62, 0.54, 0.40, 0.78)
const TEAM_DELAY_BG := Color(0.18, 0.12, 0.08, 0.94)
const STATUS_ACTION_WIDTH := 156.0
const REWARD_ACTION_WIDTH := 132.0
const TEAM_SLOT_WIDTH := 108.0
const OPPONENT_SLOT_WIDTH := 104.0
const TEAM_SLOT_GAP := 6
const OPPONENT_SLOT_GAP := 4

var _overview: Dictionary = {}
var _reroll_cooldown: float = 0.0
var _active_tab: String = "arena"
var _team_panel_expanded: bool = false
var _tab_buttons: Dictionary = {}

var _rank_badge: TextureRect
var _rank_label: Label
var _score_label: Label
var _ticket_label: Label
var _season_label: Label
var _team_toggle_button: Button
var _team_detail_section: VBoxContainer
var _reroll_button: Button
var _opponent_container: VBoxContainer
var _content_scroll: ScrollContainer
var _arena_section: VBoxContainer
var _reward_section: VBoxContainer
var _reward_list: VBoxContainer


func _ready() -> void:
	_build_ui()
	GameState.red_dot_state_changed.connect(_apply_red_dots)
	if not GameState.arena_overview_data.is_empty():
		_apply_overview(GameState.arena_overview_data)
	_refresh_overview([])


func _process(delta: float) -> void:
	if _reroll_cooldown <= 0.0:
		return
	_reroll_cooldown = maxf(0.0, _reroll_cooldown - delta)
	if _reroll_cooldown == 0.0:
		_reroll_button.disabled = false
		_reroll_button.text = UiText.ARENA_REROLL_BUTTON
	else:
		_reroll_button.text = UiText.ARENA_REROLL_COOLDOWN_FORMAT % ceili(_reroll_cooldown)


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "arena", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": [
			{
				"key": "arena",
				"label": UiText.ARENA_TAB_MAIN,
				"shell_description": UiText.ARENA_PAGE_DESC,
				"shell_summary_left": Callable(self, "_build_shell_summary_left"),
				"shell_summary_right": Callable(self, "_build_shell_summary_right").bind("arena"),
			},
			{
				"key": "rewards",
				"label": UiText.ARENA_TAB_REWARDS,
				"shell_description": UiText.ARENA_REWARD_SECTION_DESC,
				"shell_summary_left": Callable(self, "_build_shell_summary_left"),
				"shell_summary_right": Callable(self, "_build_shell_summary_right").bind("rewards"),
			},
		],
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

	var scroll_box: VBoxContainer = VBoxContainer.new()
	scroll_box.add_theme_constant_override("separation", 14)
	scroll_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(scroll_box)

	_arena_section = VBoxContainer.new()
	_arena_section.add_theme_constant_override("separation", 14)
	scroll_box.add_child(_arena_section)

	var status_panel: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.PANEL_BORDER)
	_arena_section.add_child(status_panel)

	var status_margin: MarginContainer = OverlaySceneChrome.make_content_margin(16)
	status_panel.add_child(status_margin)

	var status_row: HBoxContainer = HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 16)
	status_margin.add_child(status_row)

	_rank_badge = TextureRect.new()
	_rank_badge.custom_minimum_size = Vector2(112.0, 112.0)
	_rank_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rank_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rank_badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	status_row.add_child(_rank_badge)

	var status_text: VBoxContainer = VBoxContainer.new()
	status_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_text.add_theme_constant_override("separation", 8)
	status_row.add_child(status_text)

	var rank_header_row: HBoxContainer = HBoxContainer.new()
	rank_header_row.add_theme_constant_override("separation", 10)
	status_text.add_child(rank_header_row)

	_rank_label = Label.new()
	_rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rank_label.add_theme_font_size_override("font_size", 30)
	_rank_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	rank_header_row.add_child(_rank_label)

	var score_chip: PanelContainer = _make_opponent_meta_chip("")
	score_chip.custom_minimum_size = Vector2(STATUS_ACTION_WIDTH, 0.0)
	rank_header_row.add_child(score_chip)

	_score_label = score_chip.get_child(0).get_child(0) as Label
	_score_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)

	_ticket_label = Label.new()
	_ticket_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	status_text.add_child(_ticket_label)

	var season_row: HBoxContainer = HBoxContainer.new()
	season_row.add_theme_constant_override("separation", 10)
	status_text.add_child(season_row)

	_season_label = Label.new()
	_season_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_season_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_season_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
	_season_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	season_row.add_child(_season_label)

	_team_toggle_button = Button.new()
	_team_toggle_button.custom_minimum_size = Vector2(STATUS_ACTION_WIDTH, 38.0)
	_team_toggle_button.pressed.connect(_toggle_team_panel)
	season_row.add_child(_team_toggle_button)
	UiPalette.apply_button_kind(_team_toggle_button, "rank")

	var team_help_button: Button = Button.new()
	team_help_button.text = "?"
	team_help_button.custom_minimum_size = Vector2(38.0, 38.0)
	team_help_button.pressed.connect(_show_team_panel_help)
	season_row.add_child(team_help_button)
	UiPalette.apply_button_kind(team_help_button, "info")

	var team_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	_arena_section.add_child(team_panel)

	var team_margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	team_panel.add_child(team_margin)

	_team_detail_section = VBoxContainer.new()
	_team_detail_section.add_theme_constant_override("separation", 14)
	team_margin.add_child(_team_detail_section)
	team_panel.visible = _team_panel_expanded

	var opponent_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	opponent_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_arena_section.add_child(opponent_panel)

	var opponent_margin: MarginContainer = OverlaySceneChrome.make_content_margin(14)
	opponent_panel.add_child(opponent_margin)

	var opponent_box: VBoxContainer = VBoxContainer.new()
	opponent_box.add_theme_constant_override("separation", 12)
	opponent_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opponent_margin.add_child(opponent_box)

	var opponent_title_row: HBoxContainer = HBoxContainer.new()
	opponent_title_row.add_theme_constant_override("separation", 12)
	opponent_box.add_child(opponent_title_row)

	var opponent_title: Label = Label.new()
	opponent_title.text = UiText.ARENA_OPPONENT_TITLE
	opponent_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opponent_title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
	opponent_title.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	opponent_title_row.add_child(opponent_title)

	_reroll_button = Button.new()
	_reroll_button.text = UiText.ARENA_REROLL_BUTTON
	_reroll_button.custom_minimum_size = Vector2(140.0, 44.0)
	_reroll_button.pressed.connect(_on_reroll_pressed)
	opponent_title_row.add_child(_reroll_button)
	UiPalette.apply_button_kind(_reroll_button, "secondary")

	_opponent_container = VBoxContainer.new()
	_opponent_container.add_theme_constant_override("separation", 10)
	_opponent_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opponent_box.add_child(_opponent_container)

	_reward_section = VBoxContainer.new()
	_reward_section.add_theme_constant_override("separation", 14)
	scroll_box.add_child(_reward_section)

	_reward_list = VBoxContainer.new()
	_reward_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward_list.add_theme_constant_override("separation", 0)
	_reward_section.add_child(_reward_list)

	_refresh_tab_state()
	_apply_overview({})


func _refresh_overview(excluded_opponent_ids: Array) -> void:
	ApiClient.get_arena_overview(excluded_opponent_ids, Callable(self, "_on_arena_overview_received"))


func _on_arena_overview_received(success: bool, data: Variant, error: Dictionary) -> void:
	if success and data is Dictionary:
		GameState.update_arena(data)
		_apply_overview(data)
		return
	if _overview.is_empty():
		_show_dialog(UiText.ARENA_DIALOG_TITLE, Helpers.build_error_message(error))


func _apply_overview(overview: Dictionary) -> void:
	_overview = overview.duplicate(true)
	var rank_texture: Texture2D = Helpers.resolve_rank_texture(
		_overview.get("rankImagePath", ""),
		_overview.get("rankKey", "")
	)
	_rank_badge.texture = rank_texture
	_rank_badge.visible = rank_texture != null
	_rank_label.text = Helpers.get_current_rank(_overview)
	_score_label.text = UiText.ARENA_SCORE_FORMAT % Helpers.get_current_score(_overview)
	_ticket_label.text = UiText.ARENA_TICKETS_FORMAT % Helpers.get_current_tickets(_overview)
	_season_label.text = UiText.ARENA_SEASON_FORMAT % [
		str(_overview.get("seasonDisplayName", UiText.ARENA_SEASON_DEFAULT)),
		str(_overview.get("seasonEndDate", "-"))
	]
	_refresh_team_panel()
	_render_opponents()
	_render_rewards()
	_refresh_tab_state()


func _render_opponents() -> void:
	for child: Node in _opponent_container.get_children():
		child.queue_free()

	var opponents: Array = _overview.get("opponents", [])
	if opponents.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = UiText.ARENA_EMPTY_OPPONENTS
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		empty_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		_opponent_container.add_child(empty_label)
		return

	for opponent_variant: Variant in opponents:
		if opponent_variant is Dictionary:
			_opponent_container.add_child(_build_opponent_card(opponent_variant))


func _build_opponent_card(opponent: Dictionary) -> Control:
	var panel: PanelContainer = OverlaySceneChrome.make_card_panel(
		OverlaySceneChrome.CARD_BORDER,
		Color(0.12, 0.12, 0.14, 0.96),
		12
	)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	box.add_child(title_row)

	var rank_texture: Texture2D = Helpers.resolve_rank_texture(
		opponent.get("rankImagePath", ""),
		opponent.get("rankKey", "")
	)
	if rank_texture != null:
		title_row.add_child(AssetResolver.create_icon_rect(rank_texture, Vector2(54.0, 54.0)))

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 6)
	title_row.add_child(title_box)

	var name_label: Label = Label.new()
	name_label.text = str(opponent.get("playerName", UiText.ARENA_UNKNOWN_OPPONENT))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SUBHEADING)
	name_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	title_box.add_child(name_label)

	var meta_row: HBoxContainer = HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 8)
	title_box.add_child(meta_row)

	var rank_chip: PanelContainer = _make_opponent_meta_chip(Helpers.get_rank_display_name(
		str(opponent.get("rankKey", "")),
		str(opponent.get("rankName", UiText.ARENA_DEFAULT_RANK))
	))
	meta_row.add_child(rank_chip)
	meta_row.add_child(_make_opponent_meta_chip(UiText.ARENA_SCORE_FORMAT % int(opponent.get("score", 0))))

	box.add_child(_build_opponent_member_row(opponent.get("defenseMembers", [])))

	var challenge_button: Button = Button.new()
	challenge_button.text = _get_opponent_action_text()
	challenge_button.custom_minimum_size = Vector2(0.0, 48.0)
	challenge_button.pressed.connect(Callable(self, "_on_opponent_challenge_pressed").bind(opponent))
	box.add_child(challenge_button)
	_apply_opponent_action_style(challenge_button)

	return panel


func _toggle_team_panel() -> void:
	_team_panel_expanded = not _team_panel_expanded
	_refresh_team_panel()


func _show_team_panel_help() -> void:
	_show_dialog(UiText.ARENA_DIALOG_TITLE, UiText.ARENA_TEAM_PANEL_HINT)


func _refresh_team_panel() -> void:
	if _team_toggle_button != null:
		_team_toggle_button.text = UiText.ARENA_TEAM_PANEL_COLLAPSE if _team_panel_expanded else UiText.ARENA_TEAM_PANEL_EXPAND
	if _team_detail_section == null:
		return
	var team_panel: Control = _team_detail_section.get_parent().get_parent() as Control
	team_panel.visible = _team_panel_expanded
	if not _team_panel_expanded:
		return
	for child: Node in _team_detail_section.get_children():
		child.queue_free()
	_team_detail_section.add_child(_build_team_preview_section(
		UiText.ARENA_TEAM_PANEL_ATTACK,
		_get_team_members("ArenaAttack", "Boss"),
		UiText.ARENA_ATTACK_TEAM_FALLBACK
	))
	_team_detail_section.add_child(_build_team_preview_section(
		UiText.ARENA_TEAM_PANEL_DEFENSE,
		_get_team_members("ArenaDefense", ""),
		UiText.ARENA_DEFENSE_TEAM_FALLBACK
	))


func _build_team_preview_section(title_text: String, members: Array, empty_text: String) -> Control:
	var section: VBoxContainer = VBoxContainer.new()
	section.add_theme_constant_override("separation", 10)

	var title_label: Label = Label.new()
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	title_label.add_theme_color_override("font_color", OverlaySceneChrome.TITLE_TEXT_COLOR)
	section.add_child(title_label)

	var has_filled_member: bool = false
	for member_variant: Variant in members:
		if member_variant is Dictionary and not (member_variant as Dictionary).is_empty():
			has_filled_member = true
			break
	if not has_filled_member:
		var empty_label: Label = Label.new()
		empty_label.text = empty_text
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		empty_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		section.add_child(empty_label)
		return section

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", TEAM_SLOT_GAP)
	section.add_child(row)

	for member_variant: Variant in members:
		if not (member_variant is Dictionary):
			continue
		var member_card: PanelContainer = _build_team_member_card(member_variant)
		member_card.custom_minimum_size.x = TEAM_SLOT_WIDTH
		member_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(member_card)

	return section


func _build_team_member_card(member: Dictionary) -> PanelContainer:
	var is_filled: bool = not member.is_empty()
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 142.0)
	card.add_theme_stylebox_override(
		"panel",
		_make_opponent_slot_style(
			TEAM_SLOT_FILL if is_filled else TEAM_SLOT_EMPTY_FILL,
			TEAM_SLOT_BORDER if is_filled else TEAM_SLOT_EMPTY_BORDER,
			14
		)
	)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(3)
	card.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 4)
	column.add_child(top_row)

	var slot_label: Label = Label.new()
	slot_label.text = UiText.CONFIG_SLOT_BADGE_FORMAT % [int(member.get("slotNo", 0)) + 1]
	slot_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
	slot_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.72, 1.0))
	top_row.add_child(slot_label)

	var name_label: Label = Label.new()
	name_label.text = str(member.get("catDisplayName", UiText.CONFIG_TEAM_SLOT_EMPTY_NAME)) if is_filled else UiText.CONFIG_TEAM_SLOT_EMPTY_NAME
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", OPPONENT_SLOT_TEXT if is_filled else OverlaySceneChrome.MUTED_TEXT_COLOR)
	top_row.add_child(name_label)

	var art_panel: PanelContainer = PanelContainer.new()
	art_panel.custom_minimum_size = Vector2(0.0, 68.0)
	art_panel.add_theme_stylebox_override(
		"panel",
		_make_opponent_slot_style(
			TEAM_SLOT_FILL if is_filled else TEAM_SLOT_EMPTY_FILL,
			TEAM_SLOT_BORDER if is_filled else TEAM_SLOT_EMPTY_BORDER,
			12
		)
	)
	column.add_child(art_panel)

	var art_margin: MarginContainer = OverlaySceneChrome.make_content_margin(3)
	art_panel.add_child(art_margin)

	var art_center: CenterContainer = CenterContainer.new()
	art_margin.add_child(art_center)

	var cat_icon: Texture2D = Helpers.resolve_cat_icon_by_catalog_id(int(member.get("catCatalogId", 0))) if is_filled else null
	if cat_icon != null:
		art_center.add_child(AssetResolver.create_icon_rect(cat_icon, Vector2(42.0, 42.0)))
	else:
		var fallback: Label = Label.new()
		fallback.text = Helpers.get_name_fallback(str(member.get("catDisplayName", ""))) if is_filled else UiText.CONFIG_EMPTY_SLOT_ICON
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
		fallback.add_theme_color_override("font_color", OPPONENT_SLOT_TEXT if is_filled else OverlaySceneChrome.MUTED_TEXT_COLOR)
		art_center.add_child(fallback)

	var delay_button: Button = Button.new()
	delay_button.text = UiText.CONFIG_DELAY_BUTTON_FORMAT % [_format_delay_label(float(member.get("initialDelaySeconds", 0.0)))] if is_filled else UiText.CONFIG_DELAY_BUTTON_EMPTY
	delay_button.custom_minimum_size = Vector2(0.0, 16.0)
	delay_button.add_theme_font_size_override("font_size", 11)
	delay_button.disabled = true
	UiPalette.apply_button_palette(delay_button, TEAM_DELAY_BG, Color(0.98, 0.90, 0.72, 1.0))
	column.add_child(delay_button)

	return card


func _get_team_members(team_type: String, fallback_team_type: String = "") -> Array:
	var team: Dictionary = GameState.get_team(team_type)
	var members: Array = team.get("members", [])
	if members.is_empty() and fallback_team_type != "":
		team = GameState.get_team(fallback_team_type)
		members = team.get("members", [])
	var ordered_members: Array = [{}, {}, {}, {}, {}]
	for member_variant: Variant in members:
		if not (member_variant is Dictionary):
			continue
		var member: Dictionary = (member_variant as Dictionary).duplicate(true)
		var slot_no: int = clampi(int(member.get("slotNo", 0)), 0, 4)
		ordered_members[slot_no] = member
	return ordered_members


func _format_delay_label(delay_seconds: float) -> String:
	var seconds: int = maxi(0, int(round(delay_seconds)))
	return str(seconds) + UiText.COMMON_SECONDS


func _build_opponent_member_row(members_variant: Variant) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", OPPONENT_SLOT_GAP)
	var members: Array = _get_opponent_members(members_variant)
	for member_variant: Variant in members:
		if not (member_variant is Dictionary):
			continue
		var member_card: PanelContainer = _build_opponent_member_card(member_variant)
		member_card.custom_minimum_size.x = OPPONENT_SLOT_WIDTH
		member_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(member_card)
	return row


func _build_opponent_member_card(member: Dictionary) -> PanelContainer:
	var is_filled: bool = not member.is_empty()
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 146.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		_make_opponent_slot_style(
			OPPONENT_SLOT_FILL if is_filled else TEAM_SLOT_EMPTY_FILL,
			OPPONENT_SLOT_BORDER if is_filled else TEAM_SLOT_EMPTY_BORDER,
			14
		)
	)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(6)
	card.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var art_panel: PanelContainer = PanelContainer.new()
	art_panel.custom_minimum_size = Vector2(0.0, 72.0)
	art_panel.add_theme_stylebox_override(
		"panel",
		_make_opponent_slot_style(
			Color(0.15, 0.14, 0.12, 0.96) if is_filled else TEAM_SLOT_EMPTY_FILL,
			OPPONENT_SLOT_BORDER if is_filled else TEAM_SLOT_EMPTY_BORDER,
			12
		)
	)
	column.add_child(art_panel)

	var art_margin: MarginContainer = OverlaySceneChrome.make_content_margin(4)
	art_panel.add_child(art_margin)

	var art_center: CenterContainer = CenterContainer.new()
	art_margin.add_child(art_center)

	var cat_catalog_id: int = int(member.get("catCatalogId", 0)) if is_filled else 0
	var cat_icon: Texture2D = Helpers.resolve_cat_icon_by_catalog_id(cat_catalog_id) if is_filled else null
	if cat_icon != null:
		art_center.add_child(AssetResolver.create_icon_rect(cat_icon, Vector2(52.0, 52.0)))
	else:
		var fallback: Label = Label.new()
		fallback.text = Helpers.get_name_fallback(str(member.get("catDisplayName", ""))) if is_filled else UiText.CONFIG_EMPTY_SLOT_ICON
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TITLE)
		fallback.add_theme_color_override("font_color", OPPONENT_SLOT_TEXT if is_filled else OverlaySceneChrome.MUTED_TEXT_COLOR)
		art_center.add_child(fallback)

	var meta_column: VBoxContainer = VBoxContainer.new()
	meta_column.add_theme_constant_override("separation", 3)
	column.add_child(meta_column)

	var level_text: String = UiText.CONFIG_CAT_LEVEL_ONLY_FORMAT % int(member.get("catFoodLevel", 1)) if is_filled else " "
	var rank_text: String = UiText.CONFIG_CAT_STARS_FORMAT % int(member.get("rank", 0)) if is_filled else " "
	meta_column.add_child(_make_opponent_meta_chip(level_text))
	meta_column.add_child(_make_opponent_meta_chip(rank_text))

	return card


func _get_opponent_members(members_variant: Variant) -> Array:
	var members: Array = members_variant if members_variant is Array else []
	var ordered_members: Array = [{}, {}, {}, {}, {}]
	for member_variant: Variant in members:
		if not (member_variant is Dictionary):
			continue
		var member: Dictionary = (member_variant as Dictionary).duplicate(true)
		var slot_no: int = clampi(int(member.get("slotNo", 0)), 0, 4)
		ordered_members[slot_no] = member
	return ordered_members


func _make_opponent_meta_chip(text: String) -> PanelContainer:
	var chip: PanelContainer = PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", _make_opponent_slot_style(OPPONENT_META_FILL, OPPONENT_META_BORDER, 10))

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(5)
	chip.add_child(margin)

	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	label.add_theme_color_override("font_color", OPPONENT_SLOT_MUTED)
	margin.add_child(label)

	return chip


func _make_opponent_slot_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _on_reroll_pressed() -> void:
	if _reroll_cooldown > 0.0:
		return
	_reroll_cooldown = REROLL_COOLDOWN
	_reroll_button.disabled = true
	_refresh_overview(_get_current_opponent_ids())


func _on_challenge_pressed(opponent: Dictionary) -> void:
	if Helpers.get_current_tickets(_overview) <= 0:
		_on_purchase_pressed()
		return
	var effective_team_type: String = Helpers.get_effective_team_type("ArenaAttack", "Boss")
	var attack_team: Array = Helpers.get_team_member_player_cat_ids("ArenaAttack", "Boss")
	if attack_team.is_empty():
		_show_dialog(UiText.ARENA_DIALOG_TITLE, UiText.ARENA_MISSING_TEAM_ERROR)
		return
	if effective_team_type != "":
		GameState.apply_active_team_from_config(effective_team_type)
	else:
		GameState.player_team = attack_team
	GameState.arena_opponent = opponent.duplicate(true)
	get_tree().change_scene_to_file("res://scenes/ArenaBattleScene.tscn")


func _on_opponent_challenge_pressed(opponent: Dictionary) -> void:
	_on_challenge_pressed(opponent)

func _get_opponent_action_text() -> String:
	return UiText.ARENA_PURCHASE_BUTTON if Helpers.get_current_tickets(_overview) <= 0 else UiText.ARENA_CHALLENGE_BUTTON


func _apply_opponent_action_style(button: Button) -> void:
	UiPalette.apply_button_kind(button, "confirm")


func _claim_rank_reward(rank_id: int) -> void:
	ApiClient.claim_arena_rank_reward(rank_id, Callable(self, "_on_claim_rank_reward_completed"))


func _on_claim_rank_reward_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success or not (data is Dictionary):
		ToastManager.error(UiText.ARENA_REWARD_DIALOG_TITLE, Helpers.build_error_message(error))
		return
	var response: Dictionary = data
	var overview: Dictionary = response.get("overview", {})
	if not overview.is_empty():
		GameState.update_arena(overview)
		_apply_overview(overview)
	ToastManager.success(UiText.ARENA_REWARD_DIALOG_TITLE, UiText.ARENA_REWARD_CLAIMED_FORMAT % [
		Helpers.get_rank_display_name(
			str(response.get("rankKey", "")),
			str(response.get("rankName", UiText.ARENA_REWARD_UNKNOWN_RANK))
		),
		Helpers.format_rewards(response.get("rewards", []))
	])


func _on_purchase_pressed() -> void:
	if _overview.is_empty():
		_show_dialog(UiText.ARENA_PURCHASE_DIALOG_TITLE, UiText.ARENA_DATA_MISSING)
		return
	var purchase_count: int = int(_overview.get("dailyPurchaseCount", 0))
	var max_purchase_count: int = int(_overview.get("maxDailyPurchaseCount", 5))
	if purchase_count >= max_purchase_count:
		_show_dialog(UiText.ARENA_PURCHASE_DIALOG_TITLE, UiText.ARENA_PURCHASE_LIMIT)
		return
	var costs: Array = _overview.get("ticketPurchaseCosts", [])
	var cost: int = int(costs[purchase_count]) if purchase_count < costs.size() else -1
	if cost < 0:
		_show_dialog(UiText.ARENA_PURCHASE_DIALOG_TITLE, UiText.ARENA_PURCHASE_NO_PLAN)
		return
	DialogManager.show_confirm(
		UiText.ARENA_PURCHASE_DIALOG_TITLE,
		UiText.ARENA_PURCHASE_CONFIRM_BODY % [cost, int(_overview.get("ticketsPerPurchase", 3))],
		_purchase_tickets_confirmed
	)


func _show_dialog(title_text: String, body_text: String) -> void:
	DialogManager.show_info(title_text, body_text)


func _get_current_opponent_ids() -> Array:
	var ids: Array = []
	for opponent_variant: Variant in _overview.get("opponents", []):
		if not (opponent_variant is Dictionary):
			continue
		var opponent: Dictionary = opponent_variant
		var opponent_id: String = str(opponent.get("opponentId", "")).strip_edges()
		if opponent_id != "":
			ids.append(opponent_id)
	return ids


func _purchase_tickets_confirmed() -> void:
	ApiClient.purchase_arena_tickets(1, _on_purchase_tickets_completed)


func _on_purchase_tickets_completed(success: bool, data: Variant, error: Dictionary) -> void:
	if not success or not (data is Dictionary):
		ToastManager.error(UiText.ARENA_PURCHASE_DIALOG_TITLE, Helpers.build_error_message(error))
		return
	var response: Dictionary = data
	var overview: Dictionary = response.get("overview", {})
	if not overview.is_empty():
		var preserved_opponents: Array = _overview.get("opponents", []).duplicate(true)
		if not preserved_opponents.is_empty():
			overview["opponents"] = preserved_opponents
		GameState.update_arena(overview)
		_apply_overview(overview)
	ToastManager.success(UiText.ARENA_PURCHASE_DIALOG_TITLE, UiText.ARENA_PURCHASE_SUCCESS_FORMAT % int(response.get("addedTickets", 0)))


func _on_back_pressed() -> void:
	SceneNavigator.open_overlay_scene("res://scenes/ActivityScene.tscn")


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
	if _arena_section != null:
		_arena_section.visible = _active_tab == "arena"
	if _reward_section != null:
		_reward_section.visible = _active_tab == "rewards"
	_apply_red_dots()


func _apply_red_dots() -> void:
	RedDotService.refresh_dot(_tab_buttons.get("rewards") as Control, RedDotService.has_arena_red_dot())


func _render_rewards() -> void:
	if _reward_list == null:
		return

	for child: Node in _reward_list.get_children():
		child.queue_free()

	if _overview.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = UiText.ARENA_DATA_MISSING
		empty_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		empty_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		_reward_list.add_child(empty_label)
		return

	for rank_variant: Variant in _overview.get("ranks", []):
		if not (rank_variant is Dictionary):
			continue
		var rank: Dictionary = rank_variant
		_reward_list.add_child(_build_reward_card(rank))


func _build_reward_card(rank: Dictionary) -> Control:
	var shell: Control = REWARD_ROW_SCENE.instantiate() as Control
	if shell == null:
		return Control.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var badge_texture: Texture2D = Helpers.resolve_rank_texture(
		rank.get("imagePath", ""),
		rank.get("rankKey", "")
	)
	var rank_badge: TextureRect = shell.get_node("RankBadge") as TextureRect
	var rank_label: Label = shell.get_node("RankLabel") as Label
	var requirement_hint: Label = shell.get_node("RequirementHintLabel") as Label
	var claim_button: Button = shell.get_node("ClaimButton") as Button
	var claimed_label: Label = shell.get_node("ClaimedLabel") as Label
	var locked_label: Label = shell.get_node("LockedLabel") as Label

	if rank_badge != null:
		rank_badge.texture = badge_texture
		rank_badge.visible = badge_texture != null

	rank_label.text = Helpers.get_rank_display_name(
		str(rank.get("rankKey", "")),
		str(rank.get("displayName", UiText.ARENA_REWARD_UNKNOWN_RANK))
	)
	requirement_hint.text = UiText.ARENA_REQUIRE_SCORE_FORMAT % int(rank.get("scoreMin", 0))
	var reward_slot_paths: Array[String] = [
		"RewardSlot1",
		"RewardSlot2",
		"RewardSlot3",
	]
	var reward_entries: Array[Dictionary] = Helpers.get_reward_entries(rank.get("rewards", []))
	for index: int in range(reward_slot_paths.size()):
		var reward_slot: Control = shell.get_node(reward_slot_paths[index]) as Control
		if reward_slot == null:
			continue
		if index < reward_entries.size():
			_apply_reward_slot(reward_slot, reward_entries[index])
			reward_slot.visible = true
		else:
			reward_slot.visible = false

	claim_button.visible = false
	claimed_label.visible = false
	locked_label.visible = false

	if bool(rank.get("isClaimed", false)):
		claimed_label.visible = true
		claimed_label.text = UiText.COMMON_CLAIMED
	elif bool(rank.get("isClaimable", false)):
		claim_button.visible = true
		claim_button.text = UiText.COMMON_CLAIM
		claim_button.pressed.connect(Callable(self, "_on_reward_claim_button_pressed").bind(int(rank.get("rankId", 0))))
		UiPalette.apply_button_kind(claim_button, "primary")
	else:
		locked_label.visible = true
		locked_label.text = UiText.ARENA_REQUIRE_SCORE_FORMAT % int(rank.get("scoreMin", 0))

	return shell


func _on_reward_claim_button_pressed(rank_id: int) -> void:
	_claim_rank_reward(rank_id)


func _apply_reward_slot(slot: Control, reward_entry: Dictionary) -> void:
	var frame: TextureRect = slot.get_node("Frame") as TextureRect
	var icon: TextureRect = slot.get_node("ItemIcon") as TextureRect
	var overlay_mask: TextureRect = slot.get_node("OverlayMask") as TextureRect
	var name_label: Label = slot.get_node("ItemNameLabel") as Label
	var qty_label: Label = slot.get_node("CountLabel") as Label

	var texture: Texture2D = AssetResolver.resolve_catalog_texture(str(reward_entry.get("path", "")))
	if texture != null:
		icon.texture = texture
		icon.visible = true
	else:
		icon.visible = false

	name_label.text = str(reward_entry.get("name", ""))
	name_label.tooltip_text = name_label.text
	qty_label.text = "x%d" % int(reward_entry.get("qty", 0))
	qty_label.tooltip_text = qty_label.text
	frame.modulate = Color(1.0, 1.0, 1.0, 1.0)
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	overlay_mask.modulate = Color(1.0, 1.0, 1.0, 0.42)


func _build_shell_summary_left() -> String:
	return "%s %d / %s %d" % [
		UiText.REWARD_DIAMONDS,
		GameState.player_data.diamonds,
		"\u9580\u7968",
		Helpers.get_current_tickets(_overview),
	]


func _build_shell_summary_right(tab_key: String) -> String:
	if tab_key == "rewards":
		var claimable_count: int = 0
		for rank_variant: Variant in _overview.get("ranks", []):
			if rank_variant is Dictionary and bool((rank_variant as Dictionary).get("isClaimable", false)):
				claimable_count += 1
		return "\u53ef\u9818\u53d6 %d" % claimable_count

	return "\u7a4d\u5206 %d" % Helpers.get_current_score(_overview)
