extends VBoxContainer


const CARD_TEMPLATE_SCENE = preload("res://scenes/ui/activity/limited/LimitedActivityCardTemplate.tscn")
const COMBAT_TRIAL_CARD_ART: String = "res://assets/sprites/cdn/ui/activity/combat_trial/sofa_trial_card.svg"

const ENTRY_DEFINITIONS: Array[Dictionary] = [
	{
		"key": "combat_trial",
		"title": UiText.COMBAT_TRIAL_PAGE_TITLE,
		"category": UiText.ACTIVITY_CATEGORY_COMBAT_TRIAL,
		"status": UiText.ACTIVITY_TAB_LIMITED,
		"preview_title": UiText.ACTIVITY_PREVIEW_COMBAT_TRIAL,
		"description": UiText.ACTIVITY_COMBAT_TRIAL_DESC,
		"rewards": UiText.ACTIVITY_REWARDS_COMBAT_TRIAL,
		"button_text": UiText.ACTIVITY_COMBAT_TRIAL_BUTTON,
		"art_path": COMBAT_TRIAL_CARD_ART,
		"is_hidden": true,
	},
]


func _ready() -> void:
	if get_child_count() > 0:
		return
	_build_content()


func _build_content() -> void:
	var visible_entries: Array[Dictionary] = []
	for entry_variant: Dictionary in ENTRY_DEFINITIONS:
		if bool(entry_variant.get("is_hidden", false)):
			continue
		visible_entries.append(entry_variant)

	if not visible_entries.is_empty():
		for entry: Dictionary in visible_entries:
			add_child(_make_activity_card(entry))
		return

	var card: Control = CARD_TEMPLATE_SCENE.instantiate() as Control
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var action_button: Button = card.get_node("Margin/ContentCanvas/ActionButton") as Button
	UiPalette.apply_button_kind(action_button, "primary")
	action_button.disabled = true

	add_child(card)


func _make_activity_card(entry_data: Dictionary) -> Control:
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
	status_label.text = str(entry_data.get("status", ""))
	preview_label.text = str(entry_data.get("preview_title", ""))
	description_label.text = str(entry_data.get("description", ""))
	reward_label.text = UiText.ACTIVITY_REWARDS_LABEL_PREFIX + str(entry_data.get("rewards", ""))
	action_button.text = str(entry_data.get("button_text", UiText.ACTIVITY_DEFAULT_BUTTON))
	action_button.disabled = true
	UiPalette.apply_button_kind(action_button, "secondary")

	var entry_key: String = str(entry_data.get("key", ""))
	var art_path: String = str(entry_data.get("art_path", ""))
	AssetResolver.apply_preview_texture(preview_image, art_path, entry_key)

	return card
