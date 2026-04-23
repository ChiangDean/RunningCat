extends VBoxContainer


const CARD_TEMPLATE_SCENE = preload("res://scenes/ui/activity/limited/LimitedActivityCardTemplate.tscn")


func _ready() -> void:
	if get_child_count() > 0:
		return
	_build_content()


func _build_content() -> void:
	var card: Control = CARD_TEMPLATE_SCENE.instantiate() as Control
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var action_button: Button = card.get_node("Margin/ContentCanvas/ActionButton") as Button
	UiPalette.apply_button_kind(action_button, "primary")
	action_button.disabled = true

	add_child(card)
