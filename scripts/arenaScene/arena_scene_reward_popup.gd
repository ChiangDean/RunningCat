class_name ArenaSceneRewardPopup
extends RefCounted

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")


static func show(scene: Control, overview: Dictionary, claim_callback: Callable) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520.0, 620.0)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var close_dialog: Callable
	for rank_variant: Variant in overview.get("ranks", []):
		if not (rank_variant is Dictionary):
			continue
		var rank: Dictionary = rank_variant
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		list.add_child(row)

		var badge_texture := AssetResolver.load_texture(AssetResolver.resolve_catalog_path(rank.get("imagePath", "")))
		if badge_texture != null:
			row.add_child(AssetResolver.create_icon_rect(badge_texture, Vector2(44.0, 44.0)))

		var name_label := Label.new()
		name_label.text = str(rank.get("displayName", "未知牌位"))
		name_label.custom_minimum_size = Vector2(120.0, 0.0)
		name_label.add_theme_font_size_override("font_size", 18)
		row.add_child(name_label)

		var reward_label := Label.new()
		reward_label.text = ArenaSceneHelpers.format_rewards(rank.get("rewards", []))
		reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward_label.add_theme_font_size_override("font_size", 16)
		row.add_child(reward_label)

		if bool(rank.get("isClaimed", false)):
			var claimed_label := Label.new()
			claimed_label.text = "已領取"
			claimed_label.add_theme_font_size_override("font_size", 16)
			row.add_child(claimed_label)
		elif bool(rank.get("isClaimable", false)):
			var claim_button := Button.new()
			claim_button.text = "領取"
			claim_button.custom_minimum_size = Vector2(90.0, 36.0)
			claim_button.pressed.connect(func() -> void:
				if close_dialog.is_valid():
					close_dialog.call()
				claim_callback.call(int(rank.get("rankId", 0)))
			)
			row.add_child(claim_button)
		else:
			var requirement_label := Label.new()
			requirement_label.text = "需達 %d 分" % int(rank.get("scoreMin", 0))
			requirement_label.add_theme_font_size_override("font_size", 16)
			row.add_child(requirement_label)

	close_dialog = DialogManager.show_info_node("牌位獎勵", scroll)
