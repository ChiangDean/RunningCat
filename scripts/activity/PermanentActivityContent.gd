extends VBoxContainer

signal entry_pressed(entry_key: String)


const CARD_TEMPLATE_SCENE = preload("res://scenes/ui/activity/permanent/PermanentActivityCardTemplate.tscn")

const GACHA_CARD_ART: String = "res://assets/sprites/ui/gacha_background_v1.png"
const DUNGEON_CARD_ART: String = "res://assets/sprites/ui/dungeon_background_v1.png"
const ARENA_CARD_ART: String = "res://assets/sprites/ui/arena_background_v1.png"
const EXPEDITION_CARD_ART: String = "res://assets/sprites/ui/activity_background_v1.png"
const COMBAT_TRIAL_CARD_ART: String = "res://assets/sprites/ui/combat_trial/sofa_trial_card.svg"

const ENTRY_DEFINITIONS: Array[Dictionary] = [
	{
		"key": "gacha",
		"title": UiText.GACHA_PAGE_TITLE,
		"category": UiText.ACTIVITY_CATEGORY_GACHA,
		"status": UiText.ACTIVITY_STATUS_PERMANENT,
		"preview_title": UiText.ACTIVITY_PREVIEW_GACHA,
		"description": UiText.ACTIVITY_GACHA_DESC,
		"rewards": UiText.ACTIVITY_REWARDS_GACHA,
		"button_text": UiText.ACTIVITY_GACHA_BUTTON,
		"art_path": GACHA_CARD_ART,
	},
	{
		"key": "dungeon",
		"title": UiText.DUNGEON_PAGE_TITLE,
		"category": UiText.ACTIVITY_CATEGORY_DUNGEON,
		"status": UiText.ACTIVITY_STATUS_PERMANENT,
		"preview_title": UiText.ACTIVITY_PREVIEW_DUNGEON,
		"description": UiText.ACTIVITY_DUNGEON_DESC,
		"rewards": UiText.ACTIVITY_REWARDS_DUNGEON,
		"button_text": UiText.ACTIVITY_DUNGEON_BUTTON,
		"art_path": DUNGEON_CARD_ART,
	},
	{
		"key": "arena",
		"title": UiText.ARENA_PAGE_TITLE,
		"category": UiText.ACTIVITY_CATEGORY_ARENA,
		"status": UiText.ACTIVITY_STATUS_PERMANENT,
		"preview_title": UiText.ACTIVITY_PREVIEW_ARENA,
		"description": UiText.ACTIVITY_ARENA_DESC,
		"rewards": UiText.ACTIVITY_REWARDS_ARENA,
		"button_text": UiText.ACTIVITY_ARENA_BUTTON,
		"art_path": ARENA_CARD_ART,
	},
	{
		"key": "combat_trial",
		"title": UiText.COMBAT_TRIAL_PAGE_TITLE,
		"category": UiText.ACTIVITY_CATEGORY_COMBAT_TRIAL,
		"status": UiText.ACTIVITY_STATUS_PERMANENT,
		"preview_title": UiText.ACTIVITY_PREVIEW_COMBAT_TRIAL,
		"description": UiText.ACTIVITY_COMBAT_TRIAL_DESC,
		"rewards": UiText.ACTIVITY_REWARDS_COMBAT_TRIAL,
		"button_text": UiText.ACTIVITY_COMBAT_TRIAL_BUTTON,
		"art_path": COMBAT_TRIAL_CARD_ART,
	},
	{
		"key": "expedition",
		"title": UiText.EXPEDITION_PAGE_TITLE,
		"category": UiText.ACTIVITY_CATEGORY_EXPEDITION,
		"status": UiText.ACTIVITY_STATUS_PERMANENT,
		"preview_title": UiText.ACTIVITY_PREVIEW_EXPEDITION,
		"description": UiText.ACTIVITY_EXPEDITION_DESC,
		"rewards": UiText.ACTIVITY_REWARDS_EXPEDITION,
		"button_text": UiText.ACTIVITY_EXPEDITION_BUTTON,
		"art_path": EXPEDITION_CARD_ART,
	},
]

var _entry_buttons: Dictionary = {}


func _ready() -> void:
	if get_child_count() > 0:
		return
	_build_content()
	refresh_red_dots()


func refresh_red_dots() -> void:
	RedDotService.refresh_dot(_entry_buttons.get("gacha") as Control, RedDotService.has_gacha_red_dot())
	RedDotService.refresh_dot(_entry_buttons.get("dungeon") as Control, RedDotService.has_dungeon_red_dot())
	RedDotService.refresh_dot(_entry_buttons.get("arena") as Control, RedDotService.has_arena_red_dot())
	RedDotService.refresh_dot(_entry_buttons.get("expedition") as Control, RedDotService.has_expedition_red_dot())


func _build_content() -> void:
	for index: int in range(ENTRY_DEFINITIONS.size()):
		var entry_data: Dictionary = ENTRY_DEFINITIONS[index]
		add_child(_make_entry_row(entry_data, index < ENTRY_DEFINITIONS.size() - 1))


func _make_entry_row(entry_data: Dictionary, show_separator: bool) -> Control:
	var row: VBoxContainer = VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	row.add_child(_make_entry_card(entry_data))

	if show_separator:
		var separator: ColorRect = ColorRect.new()
		separator.custom_minimum_size = Vector2(0.0, 2.0)
		separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		separator.color = Color(0.86, 0.75, 0.50, 0.55)
		row.add_child(separator)

	return row


func _make_entry_card(entry_data: Dictionary) -> Control:
	var card: Control = CARD_TEMPLATE_SCENE.instantiate() as Control
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label: Label = card.get_node("Margin/ContentCanvas/TitleLabel") as Label
	var category_label: Label = card.get_node("Margin/ContentCanvas/CategoryBadge/Label") as Label
	var status_label: Label = card.get_node("Margin/ContentCanvas/StatusBadge/Label") as Label
	var preview_label: Label = card.get_node("Margin/ContentCanvas/PreviewRoot/PreviewTextLabel") as Label
	var preview_image: TextureRect = card.get_node("Margin/ContentCanvas/PreviewRoot/PreviewImage") as TextureRect
	var description_label: Label = card.get_node("Margin/ContentCanvas/DescriptionLabel") as Label
	var reward_label: Label = card.get_node("Margin/ContentCanvas/RewardLabel") as Label
	var action_button: Button = card.get_node("Margin/ContentCanvas/ActionButton") as Button

	title_label.text = str(entry_data.get("title", ""))
	category_label.text = str(entry_data.get("category", ""))
	status_label.text = str(entry_data.get("status", UiText.ACTIVITY_STATUS_PERMANENT))
	preview_label.text = str(entry_data.get("preview_title", ""))
	description_label.text = str(entry_data.get("description", ""))
	reward_label.text = UiText.ACTIVITY_REWARDS_LABEL_PREFIX + str(entry_data.get("rewards", ""))
	action_button.text = str(entry_data.get("button_text", UiText.ACTIVITY_DEFAULT_BUTTON))
	UiPalette.apply_button_kind(action_button, "primary")

	var entry_key: String = str(entry_data.get("key", ""))
	var art_path: String = str(entry_data.get("art_path", ""))
	preview_image.texture = AssetResolver.resolve_preview_texture(art_path, entry_key)

	action_button.pressed.connect(_emit_entry_pressed.bind(entry_key))
	_entry_buttons[entry_key] = action_button

	return card


func _emit_entry_pressed(entry_key: String) -> void:
	entry_pressed.emit(entry_key)
