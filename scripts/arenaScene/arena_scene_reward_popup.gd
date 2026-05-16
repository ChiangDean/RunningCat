class_name ArenaSceneRewardPopup
extends RefCounted



static func show(scene: Control, overview: Dictionary, claim_callback: Callable) -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520.0, 620.0)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var dialog_state: Dictionary = {"close_dialog": Callable()}
	for rank_variant: Variant in overview.get("ranks", []):
		if not (rank_variant is Dictionary):
			continue
		var rank: Dictionary = rank_variant
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		list.add_child(row)

		var badge_icon: TextureRect = TextureRect.new()
		badge_icon.custom_minimum_size = Vector2(44.0, 44.0)
		badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ArenaSceneHelpers.apply_rank_badge_texture(badge_icon, rank.get("imagePath", ""), rank.get("rankKey", ""))
		row.add_child(badge_icon)

		var name_label: Label = Label.new()
		name_label.text = str(rank.get("displayName", UiText.ARENA_REWARD_UNKNOWN_RANK))
		name_label.custom_minimum_size = Vector2(120.0, 0.0)
		name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
		row.add_child(name_label)

		var reward_label: Label = Label.new()
		reward_label.text = ArenaSceneHelpers.format_rewards(rank.get("rewards", []))
		reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
		row.add_child(reward_label)

		if bool(rank.get("isClaimed", false)):
			var claimed_label: Label = Label.new()
			claimed_label.text = UiText.COMMON_CLAIMED
			claimed_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
			row.add_child(claimed_label)
		elif bool(rank.get("isClaimable", false)):
			var claim_button: Button = Button.new()
			claim_button.text = UiText.COMMON_CLAIM
			claim_button.custom_minimum_size = Vector2(90.0, 36.0)
			claim_button.pressed.connect(Callable(ArenaSceneRewardPopup, "_on_claim_button_pressed").bind(
				dialog_state,
				claim_callback,
				int(rank.get("rankId", 0))
			))
			row.add_child(claim_button)
		else:
			var requirement_label: Label = Label.new()
			requirement_label.text = UiText.ARENA_REQUIRE_SCORE_FORMAT % int(rank.get("scoreMin", 0))
			requirement_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_LABEL)
			row.add_child(requirement_label)

	dialog_state["close_dialog"] = DialogManager.show_info_node(UiText.ARENA_REWARD_DIALOG_TITLE, scroll)


static func _on_claim_button_pressed(dialog_state: Dictionary, claim_callback: Callable, rank_id: int) -> void:
	var close_dialog: Callable = dialog_state.get("close_dialog", Callable())
	if close_dialog.is_valid():
		close_dialog.call()
	claim_callback.call(rank_id)
