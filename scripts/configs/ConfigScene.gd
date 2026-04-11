extends Control

const Constants = preload("res://scripts/configs/ConfigConstants.gd")

var _current_team_type: String = "boss"
var _api_in_flight: bool = false

var _team_container: VBoxContainer
var _team_type_btns: Dictionary = {}
var _team_title: Label
var cats_container: VBoxContainer
var _save_hint_label: Label
var _save_team_btn: Button

var _team_drafts: Dictionary = {}
var _team_dirty: Dictionary = {}


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(Constants.SW, Constants.SH)
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 16)
	root_vbox.offset_left = 20
	root_vbox.offset_top = 40
	root_vbox.offset_right = -20
	root_vbox.offset_bottom = -20
	layer.add_child(root_vbox)

	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "配置"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 6)
	root_vbox.add_child(type_row)

	for type_key: String in ["boss", "dungeon", "arena_attack", "arena_defense"]:
		var btn := Button.new()
		btn.text = Constants.TEAM_LABELS[type_key]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 48.0)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(): _switch_team_type(type_key))
		type_row.add_child(btn)
		_team_type_btns[type_key] = btn

	root_vbox.add_child(_make_separator())

	_team_title = Label.new()
	_team_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(_team_title)

	_team_container = VBoxContainer.new()
	_team_container.add_theme_constant_override("separation", 8)
	root_vbox.add_child(_team_container)

	_save_hint_label = Label.new()
	_save_hint_label.add_theme_font_size_override("font_size", 18)
	root_vbox.add_child(_save_hint_label)

	_save_team_btn = Button.new()
	_save_team_btn.text = "套用隊伍變更"
	_save_team_btn.custom_minimum_size = Vector2(0.0, 52.0)
	_save_team_btn.pressed.connect(_on_save_team_pressed)
	root_vbox.add_child(_save_team_btn)

	root_vbox.add_child(_make_separator())

	var cats_title := Label.new()
	cats_title.text = "持有貓咪"
	cats_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(cats_title)

	cats_container = VBoxContainer.new()
	cats_container.add_theme_constant_override("separation", 8)
	root_vbox.add_child(cats_container)

	root_vbox.add_child(_make_separator())

	_switch_team_type("boss")


func _switch_team_type(type_key: String) -> void:
	_ensure_team_draft(type_key)
	_current_team_type = type_key

	for key: String in _team_type_btns:
		var btn: Button = _team_type_btns[key]
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if key == type_key else Color(0.6, 0.6, 0.6, 1.0)

	_refresh_team()
	_update_team_title()
	_update_save_section()


func _get_team_type_key(type_key: String = "") -> String:
	if type_key == "":
		type_key = _current_team_type
	return Constants.TEAM_TYPE_MAP.get(type_key, "Boss")


func _get_editing_team_members() -> Array:
	_ensure_team_draft(_current_team_type)
	var team: Dictionary = _team_drafts[_current_team_type]
	return team.get("members", [])


func _ensure_team_draft(type_key: String) -> void:
	if _team_drafts.has(type_key):
		return
	_reset_team_draft(type_key, GameState.get_team(_get_team_type_key(type_key)))


func _reset_team_draft(type_key: String, source_team: Dictionary) -> void:
	var draft := source_team.duplicate(true)
	draft["teamType"] = _get_team_type_key(type_key)
	draft["members"] = _normalize_members(draft.get("members", []), type_key)
	_team_drafts[type_key] = draft
	_team_dirty[type_key] = false


func _normalize_members(members: Array, type_key: String = "") -> Array:
	if type_key == "":
		type_key = _current_team_type
	var normalized: Array = []
	for index in range(members.size()):
		var member_variant: Variant = members[index]
		if not (member_variant is Dictionary):
			continue

		var member := (member_variant as Dictionary).duplicate(true)
		member["slotNo"] = index
		member["initialDelaySeconds"] = 0.0 if type_key == "arena_defense" else float(member.get("initialDelaySeconds", 0.0))
		normalized.append(member)
	return normalized


func _is_current_team_dirty() -> bool:
	return bool(_team_dirty.get(_current_team_type, false))


func _mark_current_team_dirty() -> void:
	_team_dirty[_current_team_type] = true
	_update_save_section()


func _update_team_title() -> void:
	var mode_label: String = Constants.TEAM_LABELS.get(_current_team_type, _current_team_type)
	var members := _get_editing_team_members()
	var max_count := _get_max_team_size()
	_team_title.text = "%s Team (%d/%d)" % [mode_label, members.size(), max_count]


func _refresh_team() -> void:
	for child in _team_container.get_children():
		child.queue_free()

	var members := _get_editing_team_members()
	var max_count := _get_max_team_size()
	for i in range(max_count):
		var member: Dictionary = members[i] if i < members.size() else {}
		_team_container.add_child(_make_team_slot_row(i, member))

	_refresh_cats_list()
	_update_team_title()
	_update_save_section()


func _make_team_slot_row(slot_index: int, member: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var is_filled := not member.is_empty()
	var cat_name: String = String(member.get("catDisplayName", "")) if is_filled else ""
	var cat_lv: int = int(member.get("catFoodLevel", 1)) if is_filled else 1
	var cat_catalog_id: int = int(member.get("catCatalogId", 0)) if is_filled else 0
	var delay_seconds: float = float(member.get("initialDelaySeconds", 0.0)) if is_filled else 0.0

	var name_lbl := Label.new()
	name_lbl.text = "%d. %s Lv.%d" % [slot_index + 1, cat_name, cat_lv] if is_filled else "%d." % [slot_index + 1]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(name_lbl)

	var skill_btn := Button.new()
	skill_btn.text = "技能"
	skill_btn.custom_minimum_size = Vector2(64.0, 44.0)
	skill_btn.disabled = not is_filled or not Constants.CAT_FILE_MAP.has(cat_catalog_id)
	if is_filled and Constants.CAT_FILE_MAP.has(cat_catalog_id):
		var press_time: float = 0.0
		var local_cat_id: String = Constants.CAT_FILE_MAP[cat_catalog_id]
		skill_btn.button_down.connect(func(): press_time = Time.get_ticks_msec() / 1000.0)
		skill_btn.button_up.connect(func():
			if Time.get_ticks_msec() / 1000.0 - press_time >= 0.4:
				_show_skill_popup(local_cat_id)
		)
	row.add_child(skill_btn)

	if _current_team_type != "arena_defense":
		var delay_lbl := Label.new()
		delay_lbl.text = "延遲:"
		delay_lbl.add_theme_font_size_override("font_size", 20)
		row.add_child(delay_lbl)

		var minus_btn := Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(44.0, 44.0)
		minus_btn.disabled = not is_filled or _api_in_flight
		row.add_child(minus_btn)

		var delay_val := Label.new()
		delay_val.text = str(int(delay_seconds)) if is_filled else "-"
		delay_val.custom_minimum_size = Vector2(30.0, 44.0)
		delay_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		delay_val.add_theme_font_size_override("font_size", 22)
		row.add_child(delay_val)

		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(44.0, 44.0)
		plus_btn.disabled = not is_filled or _api_in_flight
		row.add_child(plus_btn)

		if is_filled and not _api_in_flight:
			minus_btn.pressed.connect(func():
				var new_val := maxi(0, int(float(delay_val.text)) - 1)
				_update_member_delay_in_draft(slot_index, float(new_val))
			)
			plus_btn.pressed.connect(func():
				var new_val := int(float(delay_val.text)) + 1
				_update_member_delay_in_draft(slot_index, float(new_val))
			)

	var remove_btn := Button.new()
	remove_btn.text = "移除"
	remove_btn.custom_minimum_size = Vector2(96.0, 44.0)
	remove_btn.disabled = not is_filled or _api_in_flight
	if is_filled and not _api_in_flight:
		remove_btn.pressed.connect(func(): _remove_member_from_draft(slot_index))
	row.add_child(remove_btn)

	return row


func _refresh_cats_list() -> void:
	for child in cats_container.get_children():
		child.queue_free()

	var in_team_ids := _get_editing_team_members().map(func(m: Dictionary) -> int: return int(m.get("playerCatId", 0)))
	var owned_cats := GameState.get_config_owned_cats()
	for cat: Variant in owned_cats:
		if cat is Dictionary:
			cats_container.add_child(_make_cat_row(cat, in_team_ids))


func _make_cat_row(cat: Dictionary, in_team_ids: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var player_cat_id: int = int(cat.get("playerCatId", 0))
	var display_name: String = String(cat.get("displayName", ""))
	var lv: int = int(cat.get("catFoodLevel", 1))

	var name_lbl := Label.new()
	name_lbl.text = "%s Lv.%d" % [display_name, lv]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 22)
	row.add_child(name_lbl)

	var add_btn := Button.new()
	add_btn.text = "加入"
	add_btn.custom_minimum_size = Vector2(100.0, 50.0)
	var already_in := player_cat_id in in_team_ids
	var team_full := _get_editing_team_members().size() >= _get_max_team_size()
	add_btn.disabled = already_in or team_full or _api_in_flight
	if not add_btn.disabled:
		add_btn.pressed.connect(func(): _add_member_to_draft(player_cat_id))
	row.add_child(add_btn)

	return row


func _build_member_from_player_cat(player_cat_id: int) -> Dictionary:
	for cat_variant: Variant in GameState.get_config_owned_cats():
		if not (cat_variant is Dictionary):
			continue

		var cat := cat_variant as Dictionary
		if int(cat.get("playerCatId", 0)) != player_cat_id:
			continue

		return {
			"slotNo": 0,
			"playerCatId": player_cat_id,
			"catCatalogId": int(cat.get("catCatalogId", 0)),
			"catDisplayName": String(cat.get("displayName", "")),
			"catFoodLevel": int(cat.get("catFoodLevel", 1)),
			"rank": int(cat.get("rank", 0)),
			"initialDelaySeconds": 0.0,
		}

	return {}


func _draft_has_player_cat(members: Array, player_cat_id: int) -> bool:
	for member_variant: Variant in members:
		if member_variant is Dictionary:
			var member: Dictionary = member_variant
			if int(member.get("playerCatId", 0)) == player_cat_id:
				return true
	return false


func _add_member_to_draft(player_cat_id: int) -> void:
	if _api_in_flight:
		return

	var members := _get_editing_team_members().duplicate(true)
	if members.size() >= _get_max_team_size():
		return
	if _draft_has_player_cat(members, player_cat_id):
		return

	var new_member := _build_member_from_player_cat(player_cat_id)
	if new_member.is_empty():
		return

	members.append(new_member)
	_team_drafts[_current_team_type]["members"] = _normalize_members(members)
	_mark_current_team_dirty()
	_refresh_team()


func _remove_member_from_draft(slot_no: int) -> void:
	if _api_in_flight:
		return

	var members := _get_editing_team_members().duplicate(true)
	if slot_no < 0 or slot_no >= members.size():
		return

	members.remove_at(slot_no)
	_team_drafts[_current_team_type]["members"] = _normalize_members(members)
	_mark_current_team_dirty()
	_refresh_team()


func _update_member_delay_in_draft(slot_no: int, delay_seconds: float) -> void:
	if _api_in_flight or _current_team_type == "arena_defense":
		return

	var members := _get_editing_team_members().duplicate(true)
	if slot_no < 0 or slot_no >= members.size():
		return

	var member: Dictionary = members[slot_no]
	member["initialDelaySeconds"] = maxf(0.0, delay_seconds)
	members[slot_no] = member
	_team_drafts[_current_team_type]["members"] = _normalize_members(members)
	_mark_current_team_dirty()
	_refresh_team()


func _update_save_section() -> void:
	var dirty := _is_current_team_dirty()
	if _api_in_flight:
		_save_hint_label.text = "儲存中..."
	elif dirty:
		_save_hint_label.text = "尚有未儲存的隊伍變更。"
	else:
		_save_hint_label.text = "隊伍已同步。"

	_save_team_btn.disabled = _api_in_flight or not dirty


func _on_save_team_pressed() -> void:
	if _api_in_flight or not _is_current_team_dirty():
		return

	var request_members: Array = []
	for member: Dictionary in _get_editing_team_members():
		request_members.append({
			"playerCatId": int(member.get("playerCatId", 0)),
			"initialDelaySeconds": 0.0 if _current_team_type == "arena_defense" else float(member.get("initialDelaySeconds", 0.0)),
		})

	_api_in_flight = true
	_update_save_section()
	_refresh_team()

	ApiClient.replace_team(_current_team_type, request_members, func(success: bool, data: Variant, error: Dictionary):
		_api_in_flight = false
		if not success:
			DialogManager.show_info("儲存失敗", "更新隊伍失敗：%s" % error.get("message", "未知錯誤"))
			_refresh_team()
			return

		if data is Dictionary:
			var team_response := data as Dictionary
			_apply_team_update(team_response)
			var saved_type_key := _team_scene_type_to_key(String(team_response.get("teamType", "")))
			if saved_type_key != "":
				_reset_team_draft(saved_type_key, team_response)

		_refresh_team()
	)


func _team_scene_type_to_key(team_type: String) -> String:
	for key: String in Constants.TEAM_TYPE_MAP:
		if Constants.TEAM_TYPE_MAP[key] == team_type:
			return key
	return ""


func _apply_team_update(team_response: Dictionary) -> void:
	var type_str: String = String(team_response.get("teamType", ""))
	if type_str == "":
		return

	GameState.teams_data[type_str] = team_response
	GameState._save_config_cache("teams", GameState.teams_data.values())

	if type_str == "Boss":
		var members: Array = team_response.get("members", [])
		GameState.player_team = members.map(func(m: Dictionary) -> int: return int(m.get("playerCatId", 0)))


func _show_skill_popup(cat_file_id: String) -> void:
	var cat_data := CatData.from_json_file("res://cats/" + cat_file_id + ".json")
	if cat_data == null:
		return

	var lines: Array = [cat_data.display_name + " 技能"]

	for sid: String in cat_data.passive_skill_ids:
		var skill_d := CatData._read_skill_json("res://skills/passive/" + sid + ".json")
		if not skill_d.is_empty():
			lines.append("被動：%s" % skill_d.get("display_name", sid))
			lines.append("  " + skill_d.get("description", ""))

	for skill_d: Dictionary in cat_data.active_skills_data:
		lines.append("主動：%s  CD: %.1fs" % [
			skill_d.get("display_name", ""),
			skill_d.get("cooldown", 0.0),
		])
		lines.append("  " + skill_d.get("description", ""))

	DialogManager.show_info("技能", "\n".join(lines))


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _get_max_team_size() -> int:
	match _current_team_type:
		"boss":
			return int(GameState.boss_config.get("max_team_size", 5))
		"dungeon":
			return int(GameState.dungeon_config.get("max_team_size", 5))
		"arena_attack", "arena_defense":
			return int(GameState.arena_config.get("max_team_size", 5))
	return 5


func _on_back_pressed() -> void:
	var boss_team: Dictionary = GameState.get_team("Boss")
	var boss_members: Array = boss_team.get("members", [])
	GameState.player_team = boss_members.map(func(m: Dictionary) -> int: return int(m.get("playerCatId", 0)))
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
