class_name ExpeditionScene
extends Control

const CARD_TEMPLATE_SCENE = preload("res://scenes/ui/activity/expedition/ExpeditionZoneCardTemplate.tscn")
const EXPEDITION_SUBMENU_KEY: String = "expedition"

var _content_scroll: ScrollContainer
var _zone_list: VBoxContainer
var _dock_buttons: Dictionary = {}
var _countdown_labels: Dictionary = {}
var _is_loading: bool = false
var _cat_picker_close: Callable = Callable()

@onready var GameState = get_node("/root/GameState")
@onready var ApiClient = get_node("/root/ApiClient")
@onready var DialogManager = get_node("/root/DialogManager")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	set_process(true)


func _process(_delta: float) -> void:
	var now_unix: int = Time.get_unix_time_from_system()
	var should_refresh: bool = false
	for zone_key_variant: Variant in _countdown_labels.keys():
		var entry_variant: Variant = _countdown_labels.get(zone_key_variant, {})
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var button: Button = entry.get("button")
		if button == null or not is_instance_valid(button):
			continue
		var remaining: int = maxi(int(entry.get("completesAtUnixSeconds", 0)) - now_unix, 0)
		if remaining <= 0:
			should_refresh = true
			continue
		button.text = UiText.EXPEDITION_REMAINING_TIME_FORMAT % _format_remaining_time(remaining)

	if should_refresh:
		_refresh_zone_cards()


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "expedition", Callable(self, "_on_back_pressed"), {
		"show_dock": true,
		"dock_items": [
			{
				"key": EXPEDITION_SUBMENU_KEY,
				"label": UiText.EXPEDITION_TAB_LABEL,
				"shell_title": UiText.EXPEDITION_PAGE_TITLE,
				"shell_description": UiText.EXPEDITION_PAGE_DESC,
				"shell_summary_left": Callable(self, "_build_shell_summary_left"),
				"shell_summary_right": Callable(self, "_build_shell_summary_right"),
			},
		],
		"active_key": EXPEDITION_SUBMENU_KEY,
		"button_pressed": Callable(self, "_on_submenu_pressed"),
		"button_height": 52.0,
		"font_size": 20,
	})
	var content_box: VBoxContainer = chrome.get("content_box")
	_dock_buttons = chrome.get("dock_buttons", {})

	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_box.add_child(_content_scroll)
	InertialScroller.attach(_content_scroll, "vertical")

	_zone_list = VBoxContainer.new()
	_zone_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zone_list.add_theme_constant_override("separation", 14)
	_content_scroll.add_child(_zone_list)

	_refresh_shell_state()
	_refresh_zone_cards()


func _fetch_expeditions() -> void:
	if _is_loading:
		return
	_is_loading = true
	ApiClient.get_expedition(_on_fetch_expeditions_completed)


func _on_fetch_expeditions_completed(ok: bool, data: Variant, err: Dictionary) -> void:
	_is_loading = false
	if ok and data is Dictionary:
		var response: Dictionary = data
		var expeditions_variant: Variant = response.get("activeExpeditions", [])
		GameState.apply_expedition_data(expeditions_variant if expeditions_variant is Array else [])
		_refresh_zone_cards()
		return
	_refresh_zone_cards()
	DialogManager.show_info(
		UiText.EXPEDITION_LOAD_FAILED_TITLE,
		str(err.get("message", UiText.EXPEDITION_LOAD_FAILED_DEFAULT))
	)


func _refresh_zone_cards() -> void:
	_countdown_labels = {}
	if _zone_list == null:
		return
	for child: Node in _zone_list.get_children():
		child.queue_free()

	if GameState.expedition_zones.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = UiText.EXPEDITION_NO_ZONES
		UiFonts.apply_noto(empty_label, UiPalette.FONT_SIZE_BODY)
		empty_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
		_zone_list.add_child(empty_label)
		_refresh_shell_state()
		return

	for zone_variant: Variant in GameState.expedition_zones:
		if zone_variant is Dictionary:
			_zone_list.add_child(_make_zone_card(zone_variant))
	_refresh_shell_state()


func _refresh_shell_state() -> void:
	if _dock_buttons.is_empty():
		return
	SceneSubmenuBar.refresh(_dock_buttons, EXPEDITION_SUBMENU_KEY, {
		"active_color": Color(1.0, 0.95, 0.82, 1.0),
		"inactive_color": Color(0.65, 0.65, 0.68, 1.0),
		"active_font_size": 22,
		"inactive_font_size": 20,
	})


func _build_shell_summary_left() -> String:
	return UiText.EXPEDITION_UNLOCKED_FORMAT % [_get_unlocked_zone_count(), GameState.expedition_zones.size()]


func _build_shell_summary_right() -> String:
	var active_count: int = _get_active_expedition_count()
	var claimable_count: int = _get_claimable_expedition_count()
	if claimable_count > 0:
		return UiText.EXPEDITION_CLAIMABLE_FORMAT % claimable_count
	return UiText.EXPEDITION_ACTIVE_FORMAT % active_count


func _get_unlocked_zone_count() -> int:
	var unlocked_count: int = 0
	for zone_variant: Variant in GameState.expedition_zones:
		if not (zone_variant is Dictionary):
			continue
		var zone: Dictionary = zone_variant
		if _is_zone_unlocked(zone):
			unlocked_count += 1
	return unlocked_count


func _get_active_expedition_count() -> int:
	var active_count: int = 0
	for expedition_variant: Variant in GameState.expedition_data:
		if expedition_variant is Dictionary:
			active_count += 1
	return active_count


func _get_claimable_expedition_count() -> int:
	var claimable_count: int = 0
	var now_unix: int = Time.get_unix_time_from_system()
	for expedition_variant: Variant in GameState.expedition_data:
		if not (expedition_variant is Dictionary):
			continue
		var expedition: Dictionary = expedition_variant
		if bool(expedition.get("isClaimable", false)) or now_unix >= int(expedition.get("completesAtUnixSeconds", 0)):
			claimable_count += 1
	return claimable_count


func _on_submenu_pressed(tab_key: String) -> void:
	if tab_key != EXPEDITION_SUBMENU_KEY:
		return


func _make_zone_card(zone: Dictionary) -> Control:
	var zone_id: int = int(zone.get("id", 0))
	var zone_name: String = str(zone.get("displayName", ""))
	var duration_hours: int = int(zone.get("durationHours", 0))
	var expedition: Dictionary = GameState.get_expedition_for_zone(zone_id)
	var unlocked: bool = _is_zone_unlocked(zone)
	var is_claimable: bool = false
	if not expedition.is_empty():
		is_claimable = bool(expedition.get("isClaimable", false))
		if not is_claimable:
			is_claimable = Time.get_unix_time_from_system() >= int(expedition.get("completesAtUnixSeconds", 0))

	var accent: Color = OverlaySceneChrome.CARD_BORDER
	if not unlocked:
		accent = Color(0.38, 0.38, 0.40, 0.90)
	elif is_claimable:
		accent = Color(0.92, 0.78, 0.38, 1.0)

	var card: Panel = CARD_TEMPLATE_SCENE.instantiate() as Panel
	if card == null:
		return Control.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_zone_card_style(accent))

	var title: Label = card.get_node("Margin/ContentCanvas/TitleLabel") as Label
	var duration: Label = card.get_node("Margin/ContentCanvas/DurationLabel") as Label
	var preview_root: Control = card.get_node("Margin/ContentCanvas/PreviewRoot") as Control
	var status_badge: PanelContainer = card.get_node("Margin/ContentCanvas/PreviewRoot/StatusBadge") as PanelContainer
	var description_label: Label = card.get_node("Margin/ContentCanvas/DescriptionLabel") as Label
	var detail_label: Label = card.get_node("Margin/ContentCanvas/DetailLabel") as Label
	var countdown_label: Label = card.get_node("Margin/ContentCanvas/CountdownLabel") as Label
	var action_button: Button = card.get_node("Margin/ContentCanvas/ActionButton") as Button
	var preview_image: TextureRect = card.get_node("Margin/ContentCanvas/PreviewRoot/PreviewImage") as TextureRect

	title.text = zone_name
	duration.text = UiText.EXPEDITION_DURATION_FORMAT % duration_hours
	description_label.text = UiText.EXPEDITION_PAGE_DESC
	detail_label.text = UiText.EXPEDITION_DETAIL_IDLE
	countdown_label.visible = false
	status_badge.visible = false
	if preview_image != null:
		AssetResolver.apply_background_texture(preview_image, "expedition")

	if not unlocked:
		_add_preview_locked_overlay(preview_root)
		description_label.text = UiText.EXPEDITION_ZONE_LOCKED_DESC % _get_territory_requirement_name(zone)
		detail_label.text = UiText.EXPEDITION_ZONE_LOCKED_DESC % _get_territory_requirement_name(zone)
		action_button.text = UiText.EXPEDITION_BTN_LOCKED
		action_button.disabled = true
		UiPalette.apply_button_kind(action_button, "neutral")
		return card

	if expedition.is_empty():
		description_label.text = UiText.EXPEDITION_DETAIL_DEPLOY
		detail_label.text = UiText.EXPEDITION_STATUS_IDLE
		action_button.text = UiText.EXPEDITION_BTN_DEPLOY
		action_button.disabled = _is_loading
		UiPalette.apply_button_kind(action_button, "primary")
		action_button.pressed.connect(Callable(self, "_on_zone_deploy_pressed").bind(zone))
		return card

	var cat_id: String = str(expedition.get("catId", "")).strip_edges()
	var cat_name: String = _get_cat_display_name(cat_id)
	if is_claimable:
		description_label.text = UiText.EXPEDITION_DETAIL_CLAIMABLE
		detail_label.text = "%s：%s" % [UiText.EXPEDITION_IN_PROGRESS, cat_name]
		action_button.text = UiText.EXPEDITION_BTN_CLAIM
		action_button.disabled = _is_loading
		UiPalette.apply_button_kind(action_button, "primary")
		action_button.pressed.connect(Callable(self, "_on_zone_claim_pressed").bind(zone_id))
		return card

	description_label.text = "%s：%s" % [UiText.EXPEDITION_IN_PROGRESS, cat_name]
	detail_label.text = UiText.EXPEDITION_DETAIL_IN_PROGRESS
	countdown_label.visible = false
	_countdown_labels[zone_id] = {
		"button": action_button,
		"completesAtUnixSeconds": int(expedition.get("completesAtUnixSeconds", 0)),
	}

	action_button.text = UiText.EXPEDITION_REMAINING_TIME_FORMAT % _format_remaining_time(maxi(int(expedition.get("completesAtUnixSeconds", 0)) - Time.get_unix_time_from_system(), 0))
	action_button.disabled = true
	UiPalette.apply_button_kind(action_button, "neutral")
	return card


func _on_zone_deploy_pressed(zone: Dictionary) -> void:
	_show_cat_picker(zone)


func _on_zone_claim_pressed(zone_id: int) -> void:
	_claim_expedition(zone_id)


func _make_zone_card_style(accent: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.19, 0.17, 0.15, 0.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = accent
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	return style


func _add_preview_locked_overlay(preview_root: Control) -> void:
	if preview_root == null:
		return

	var overlay: ColorRect = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0.0, 0.0, 0.0, 0.66)
	preview_root.add_child(overlay)

	var locked_label: Label = Label.new()
	locked_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	locked_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	locked_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	locked_label.add_theme_color_override("font_outline_color", Color(0.16, 0.07, 0.03, 1.0))
	locked_label.add_theme_constant_override("outline_size", 4)
	locked_label.add_theme_font_size_override("font_size", 22)
	locked_label.text = UiText.EXPEDITION_BTN_LOCKED
	preview_root.add_child(locked_label)


func _show_cat_picker(zone: Dictionary) -> void:
	var available_cats: Array[String] = _get_available_cat_ids()
	if available_cats.is_empty():
		DialogManager.show_info(UiText.EXPEDITION_SELECT_CAT_TITLE, UiText.EXPEDITION_EMPTY_CAT_PICKER)
		return

	if not _cat_picker_close.is_null():
		_cat_picker_close.call()

	var zone_name: String = str(zone.get("displayName", ""))
	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size = Vector2(0.0, 460.0)
	content.add_theme_constant_override("separation", 10)

	var desc: Label = Label.new()
	desc.text = UiText.EXPEDITION_SELECT_CAT_DESC
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(desc, UiPalette.FONT_SIZE_LABEL)
	content.add_child(desc)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 360.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	InertialScroller.attach(scroll, "vertical")

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for cat_id: String in available_cats:
		list.add_child(_make_cat_picker_row(zone_name, int(zone.get("id", 0)), cat_id))

	_cat_picker_close = DialogManager.show_info_node(UiText.EXPEDITION_SELECT_CAT_TITLE, content, Callable(), "medium")


func _make_cat_picker_row(zone_name: String, zone_id: int, cat_id: String) -> Control:
	var player_cat = GameState.get_player_cat(cat_id)
	var row: PanelContainer = OverlaySceneChrome.make_card_panel(OverlaySceneChrome.CARD_BORDER)

	var margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	row.add_child(margin)

	var layout: HBoxContainer = HBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var icon: TextureRect = AssetResolver.create_icon_rect(AssetResolver.resolve_cat_icon(cat_id), Vector2(56.0, 56.0))
	layout.add_child(icon)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	layout.add_child(text_box)

	var name_label: Label = Label.new()
	name_label.text = _get_cat_display_name(cat_id)
	UiFonts.apply_noto(name_label, UiPalette.FONT_SIZE_BODY_LG)
	text_box.add_child(name_label)

	var detail_label: Label = Label.new()
	detail_label.text = UiText.EXPEDITION_CAT_FOOD_LEVEL_FORMAT % int(player_cat.cat_food_level)
	UiFonts.apply_noto(detail_label, UiPalette.FONT_SIZE_LABEL)
	detail_label.add_theme_color_override("font_color", OverlaySceneChrome.MUTED_TEXT_COLOR)
	text_box.add_child(detail_label)

	var action_button: Button = Button.new()
	action_button.text = UiText.EXPEDITION_BTN_DEPLOY
	action_button.custom_minimum_size = Vector2(110.0, 42.0)
	UiFonts.apply_noto(action_button, UiPalette.FONT_SIZE_BODY)
	UiPalette.apply_button_kind(action_button, "primary")
	action_button.pressed.connect(Callable(self, "_on_cat_picker_deploy_pressed").bind(zone_name, zone_id, cat_id))
	layout.add_child(action_button)
	return row


func _on_cat_picker_deploy_pressed(zone_name: String, zone_id: int, cat_id: String) -> void:
	if not _cat_picker_close.is_null():
		_cat_picker_close.call()
		_cat_picker_close = Callable()
	DialogManager.show_confirm(
		UiText.EXPEDITION_CONFIRM,
		UiText.EXPEDITION_DEPLOY_CONFIRM_BODY_FORMAT % [_get_cat_display_name(cat_id), zone_name],
		Callable(self, "_start_expedition").bind(zone_id, cat_id)
	)


func _start_expedition(zone_id: int, cat_id: String) -> void:
	if _is_loading:
		return
	_is_loading = true
	ApiClient.start_expedition(zone_id, cat_id, _on_start_expedition_completed)


func _on_start_expedition_completed(ok: bool, _data: Variant, err: Dictionary) -> void:
	_is_loading = false
	if not ok:
		DialogManager.show_info(
			UiText.EXPEDITION_START_FAILED_TITLE,
			_get_expedition_error_message(err, UiText.EXPEDITION_START_FAILED_DEFAULT)
		)
		if _should_refresh_after_expedition_error(err):
			_fetch_expeditions()
		else:
			_refresh_zone_cards()
		return
	_fetch_expeditions()


func _claim_expedition(zone_id: int) -> void:
	if _is_loading:
		return
	var expedition: Dictionary = GameState.get_expedition_for_zone(zone_id)
	var cat_id: String = str(expedition.get("catId", "")).strip_edges()
	_is_loading = true
	ApiClient.claim_expedition(zone_id, Callable(self, "_on_claim_expedition_completed").bind(cat_id))


func _on_claim_expedition_completed(ok: bool, data: Variant, err: Dictionary, cat_id: String) -> void:
	_is_loading = false
	if not ok:
		DialogManager.show_info(
			UiText.EXPEDITION_CLAIM_FAILED_TITLE,
			_get_expedition_error_message(err, UiText.EXPEDITION_CLAIM_FAILED_DEFAULT)
		)
		if _should_refresh_after_expedition_error(err):
			_fetch_expeditions()
		else:
			_refresh_zone_cards()
		return

	var result: Dictionary = data if data is Dictionary else {}
	var wallet_variant: Variant = result.get("walletSnapshot", {})
	if wallet_variant is Dictionary:
		GameState.apply_wallet_snapshot(wallet_variant)

	var rewards_variant: Variant = result.get("rewards", [])
	if rewards_variant is Array:
		var reward_entries: Array[Dictionary] = []
		for reward_variant: Variant in rewards_variant:
			if not (reward_variant is Dictionary):
				continue
			var reward: Dictionary = reward_variant
			var float_entry: Dictionary = _make_reward_float_entry(reward)
			if not float_entry.is_empty():
				reward_entries.append(float_entry)
			if str(reward.get("rewardType", "")).to_lower() == "whiskershard" and cat_id != "":
				_apply_local_cat_shards(cat_id, int(reward.get("quantity", 0)))
		if not reward_entries.is_empty():
			queue_home_reward_floats(reward_entries)
	_fetch_expeditions()


func _apply_local_cat_shards(cat_id: String, quantity: int) -> void:
	if quantity <= 0:
		return
	var player_cat = GameState.get_player_cat(cat_id)
	player_cat.cat_shards += quantity
	player_cat.save()
	for item_variant: Variant in GameState.enhance_data:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var target_cat_id: String = GameState.get_cat_file_id_by_catalog_id(int(item.get("catCatalogId", 0)))
		if target_cat_id != cat_id:
			continue
		item["catShards"] = int(item.get("catShards", 0)) + quantity
		break


func _make_reward_float_entry(reward: Dictionary) -> Dictionary:
	var reward_type: String = str(reward.get("rewardType", "")).to_lower()
	var quantity: int = int(reward.get("quantity", 0))
	var display_name: String = str(reward.get("displayName", "")).strip_edges()
	if quantity <= 0:
		return {}
	match reward_type:
		"gold":
			return _queue_reward_entry(UiText.REWARD_GOLD, quantity, "gold")
		"diamond":
			return _queue_reward_entry(UiText.REWARD_DIAMONDS, quantity, "diamonds")
		"poopcount":
			return _queue_reward_entry(UiText.REWARD_POOP, quantity, "poop")
		"catfood":
			return _queue_reward_entry(UiText.REWARD_CAT_FOOD, quantity, "cat_food")
		"specialcatfood":
			return _queue_reward_entry(UiText.REWARD_SPECIAL_CAT_FOOD, quantity, "special_cat_food")
		"memoryshard":
			return _queue_reward_entry(UiText.REWARD_MEMORY_SHARDS, quantity, "memory_shards")
		"whiskershard":
			return _queue_reward_entry(display_name if display_name != "" else UiText.REWARD_WHISKERS, quantity, "whiskers")
		_:
			return _queue_reward_entry(display_name if display_name != "" else reward_type, quantity, reward_type)


func _queue_reward_entry(label: String, amount: int, reward_key: String) -> Dictionary:
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	if battle_scene != null and battle_scene.has_method("make_reward_float_entry"):
		return battle_scene.make_reward_float_entry(label, amount, reward_key)

	var color := Color(0.98, 0.92, 0.76, 1.0)
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
	return {
		"label": label,
		"amount": amount,
		"key": reward_key,
		"color": color,
	}


func queue_home_reward_floats(entries: Array[Dictionary]) -> void:
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	if battle_scene != null and battle_scene.has_method("queue_home_reward_floats"):
		battle_scene.queue_home_reward_floats(entries)


func _get_expedition_error_message(err: Dictionary, fallback: String) -> String:
	var code: String = str(err.get("code", "")).strip_edges()
	match code:
		"EXPEDITION.ZONE_BUSY":
			return UiText.EXPEDITION_ERROR_ZONE_BUSY
		"EXPEDITION.CAT_BUSY":
			return UiText.EXPEDITION_ERROR_CAT_BUSY
		"EXPEDITION.NOT_READY":
			return UiText.EXPEDITION_ERROR_NOT_READY
		"EXPEDITION.ACTIVE_NOT_FOUND":
			return UiText.EXPEDITION_ERROR_ACTIVE_NOT_FOUND
		"EXPEDITION.ZONE_LOCKED":
			return UiText.EXPEDITION_ERROR_ZONE_LOCKED
		_:
			var message: String = str(err.get("message", "")).strip_edges()
			if message != "" and message != "The request conflicts with the current resource state.":
				return message
			return fallback


func _should_refresh_after_expedition_error(err: Dictionary) -> bool:
	var code: String = str(err.get("code", "")).strip_edges()
	return code in [
		"COMMON.CONFLICT",
		"EXPEDITION.ZONE_BUSY",
		"EXPEDITION.CAT_BUSY",
		"EXPEDITION.NOT_READY",
		"EXPEDITION.ACTIVE_NOT_FOUND",
	]


func _get_available_cat_ids() -> Array[String]:
	var result: Array[String] = []
	for cat_id_variant: Variant in GameState.get_owned_cats():
		var cat_id: String = str(cat_id_variant).strip_edges()
		if cat_id == "" or GameState.is_cat_on_expedition(cat_id):
			continue
		result.append(cat_id)
	return result


func _is_zone_unlocked(zone: Dictionary) -> bool:
	return GameState.get_territory_number() >= int(zone.get("territoryRequirement", 99))


func _get_territory_requirement_name(zone: Dictionary) -> String:
	var territory_index: int = int(zone.get("territoryRequirement", 0))
	var territory_names_variant: Variant = GameState.boss_config.get("territory_names", [])
	if territory_names_variant is Array:
		var territory_names: Array = territory_names_variant
		if territory_index >= 0 and territory_index < territory_names.size():
			var territory_name: String = str(territory_names[territory_index]).strip_edges()
			if territory_name != "":
				return territory_name
	return UiText.EXPEDITION_TERRITORY_FALLBACK_FORMAT % territory_index


func _get_cat_display_name(cat_id: String) -> String:
	for cat_variant: Variant in GameState.cat_catalog:
		if not (cat_variant is Dictionary):
			continue
		var cat_row: Dictionary = cat_variant
		if str(cat_row.get("id", "")).strip_edges() == cat_id:
			return str(cat_row.get("display_name", cat_row.get("displayName", cat_id)))
	return cat_id


func _format_remaining_time(seconds_left: int) -> String:
	var hours: int = seconds_left / 3600
	var minutes: int = (seconds_left % 3600) / 60
	var seconds: int = seconds_left % 60
	return UiText.EXPEDITION_TIME_FORMAT % [hours, minutes, seconds]


func _on_back_pressed() -> void:
	if not _cat_picker_close.is_null():
		_cat_picker_close.call()
	SceneNavigator.open_overlay_scene("res://scenes/ActivityScene.tscn")
