extends RefCounted

## 鏟屎官 Tab — 個人資料、鏟屎、特殊能力、裝備列表


func _scene_valid(scene: Control) -> bool:
	return scene != null and is_instance_valid(scene)


func build(scene: Control) -> void:
	scene._level_label = Label.new()
	scene._level_label.add_theme_font_size_override("font_size", 32)
	scene._level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._tab_content.add_child(scene._level_label)

	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 10)
	scene._tab_content.add_child(exp_row)

	scene._exp_bar = ProgressBar.new()
	scene._exp_bar.min_value = 0
	scene._exp_bar.show_percentage = false
	scene._exp_bar.custom_minimum_size = Vector2(0.0, 36.0)
	scene._exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_row.add_child(scene._exp_bar)

	scene._exp_label = Label.new()
	scene._exp_label.add_theme_font_size_override("font_size", 18)
	scene._exp_label.custom_minimum_size = Vector2(140.0, 36.0)
	scene._exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_row.add_child(scene._exp_label)

	scene._scoop_button = Button.new()
	scene._scoop_button.custom_minimum_size = Vector2(0.0, 48.0)
	scene._scoop_button.add_theme_font_size_override("font_size", 18)
	scene._scoop_button.pressed.connect(_on_scoop_pressed.bind(scene))
	scene._tab_content.add_child(scene._scoop_button)

	scene._scoop_overlay = ColorRect.new()
	scene._scoop_overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	scene._scoop_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene._scoop_overlay.visible = false
	scene._scoop_button.add_child(scene._scoop_overlay)

	scene._scoop_cd_label = Label.new()
	scene._scoop_cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene._scoop_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene._scoop_cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene._scoop_cd_label.add_theme_font_size_override("font_size", 18)
	scene._scoop_cd_label.visible = false
	scene._scoop_button.add_child(scene._scoop_cd_label)

	scene._scoop_result_label = Label.new()
	scene._scoop_result_label.text = ""
	scene._scoop_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scene._scoop_result_label.add_theme_font_size_override("font_size", 16)
	scene._scoop_result_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.7, 1.0))
	scene._tab_content.add_child(scene._scoop_result_label)

	scene._tab_content.add_child(scene._make_separator())

	var ability_title := Label.new()
	ability_title.text = "特殊能力"
	ability_title.add_theme_font_size_override("font_size", 24)
	scene._tab_content.add_child(ability_title)

	var ability_scroll := ScrollContainer.new()
	ability_scroll.custom_minimum_size = Vector2(0.0, 88.0)
	scene._tab_content.add_child(ability_scroll)
	scene._ability_scroller = InertialScroller.attach(ability_scroll, "vertical")

	scene._ability_list = VBoxContainer.new()
	scene._ability_list.add_theme_constant_override("separation", 8)
	scene._ability_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_scroll.add_child(scene._ability_list)

	var equip_header := Label.new()
	equip_header.text = "裝備"
	equip_header.add_theme_font_size_override("font_size", 24)
	scene._tab_content.add_child(equip_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 300.0)
	scene._tab_content.add_child(scroll)
	scene._equip_scroller = InertialScroller.attach(scroll, "vertical")

	scene._equip_list = VBoxContainer.new()
	scene._equip_list.add_theme_constant_override("separation", 8)
	scene._equip_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scene._equip_list)

	_refresh_scooper_tab_from_local(scene)


func process(scene: Control, delta: float) -> void:
	var needs_refresh := false
	if scene._scoop_cooldown_remaining > 0.0:
		scene._scoop_cooldown_remaining = maxf(0.0, scene._scoop_cooldown_remaining - delta)
		needs_refresh = true
	if _tick_equipment_upgrade_cooldowns(scene, delta):
		needs_refresh = true
	if needs_refresh:
		_refresh_scoop_ui(scene)


func _refresh_scooper_tab_from_local(scene: Control) -> void:
	_refresh_scooper_profile_ui(scene)
	_refresh_scoop_ui(scene)
	_refresh_ability_ui(scene)
	_rebuild_equip_list(scene)


func _refresh_scooper_profile_ui(scene: Control) -> void:
	if not _scene_valid(scene):
		return
	var profile: Dictionary = scene.GameState.scooper_profile_data
	var level: int = int(profile.get("scooperLevel", 0))
	var exp: int = int(profile.get("scooperExp", 0))
	var threshold: int = max(1, int(profile.get("expThreshold", 1)))

	if scene._level_label != null:
		scene._level_label.text = "鏟屎官 Lv.%d" % level

	if scene._exp_bar != null:
		scene._exp_bar.max_value = threshold
		scene._exp_bar.value = exp

	if scene._exp_label != null:
		scene._exp_label.text = "EXP %d / %d" % [exp, threshold]


func _rebuild_equip_list(scene: Control) -> void:
	if not _scene_valid(scene) or scene._equip_list == null:
		return
	for child in scene._equip_list.get_children():
		child.queue_free()

	var items: Array = scene.GameState.scooper_equipment_data
	if items.is_empty():
		var loading_lbl := Label.new()
		loading_lbl.text = "載入中..."
		loading_lbl.add_theme_font_size_override("font_size", 18)
		loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._equip_list.add_child(loading_lbl)
		return

	for item: Dictionary in items:
		scene._equip_list.add_child(_make_equip_card(scene, item))


func _refresh_ability_ui(scene: Control) -> void:
	if not _scene_valid(scene) or scene._ability_list == null:
		return

	for child in scene._ability_list.get_children():
		child.queue_free()

	var owned: Array = scene.GameState.scooper_ability_data
	if owned.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "尚未擁有特殊能力"
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		scene._ability_list.add_child(empty_lbl)
		return

	for item: Dictionary in owned:
		scene._ability_list.add_child(_make_ability_card(scene, item))


func _make_ability_card(scene: Control, item: Dictionary) -> Control:
	var btn := Button.new()
	btn.text = item.get("displayName") if item.get("displayName") != null else ""
	btn.custom_minimum_size = Vector2(0.0, 52.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func() -> void:
		_show_ability_dialog(scene, item)
	)
	return btn


func _show_ability_dialog(scene: Control, item: Dictionary) -> void:
	if not _scene_valid(scene):
		return
	var lines: Array[String] = [
		"效果：%s" % item.get("description", ""),
	]
	var source_text: String = item.get("sourceText") if item.get("sourceText") != null else ""
	if source_text != "":
		lines.append("")
		lines.append(source_text)
	scene.DialogManager.show_info(str(item.get("displayName", "")), "\n".join(lines))


func _refresh_scoop_ui(scene: Control) -> void:
	if not _scene_valid(scene) or scene._scoop_button == null:
		return
	var poop_count: int = scene.GameState.player_data.poop_count
	var scoop_amount: int = _get_scoop_amount()
	var cooling_down: bool = scene._scoop_cooldown_remaining > 0.0

	scene._scoop_button.text = "🪣 鏟屎(%d/%d)" % [poop_count, scoop_amount]
	scene._scoop_button.disabled = cooling_down or poop_count <= 0 or scene._api_in_flight

	if scene._scoop_overlay != null and scene._scoop_cd_label != null:
		if cooling_down:
			var button_size = scene._scoop_button.size
			if button_size.x <= 0.0 or button_size.y <= 0.0:
				button_size = scene._scoop_button.custom_minimum_size
			var ratio := clampf(scene._scoop_cooldown_remaining / scene.SCOOP_COOLDOWN, 0.0, 1.0)
			scene._scoop_overlay.visible = true
			scene._scoop_overlay.position = Vector2(button_size.x * (1.0 - ratio), 0.0)
			scene._scoop_overlay.size = Vector2(button_size.x * ratio, button_size.y)
			scene._scoop_cd_label.visible = false
			scene._scoop_cd_label.position = Vector2.ZERO
			scene._scoop_cd_label.size = button_size
		else:
			scene._scoop_overlay.visible = false
			scene._scoop_cd_label.visible = false

	_refresh_equipment_upgrade_button_states(scene)


func _tick_equipment_upgrade_cooldowns(scene: Control, delta: float) -> bool:
	if not _scene_valid(scene):
		return false
	var changed := false
	var expired: Array[int] = []
	for equip_id_variant: Variant in scene._equipment_upgrade_cooldowns.keys():
		var equip_id := int(equip_id_variant)
		var remaining := maxf(0.0, float(scene._equipment_upgrade_cooldowns[equip_id]) - delta)
		if remaining <= 0.0:
			expired.append(equip_id)
		else:
			scene._equipment_upgrade_cooldowns[equip_id] = remaining
		_refresh_equipment_upgrade_button_state(scene, equip_id)
		changed = true

	for equip_id: int in expired:
		scene._equipment_upgrade_cooldowns.erase(equip_id)
		_refresh_equipment_upgrade_button_state(scene, equip_id)
		changed = true

	return changed


func _refresh_equipment_upgrade_button_states(scene: Control) -> void:
	if not _scene_valid(scene):
		return
	for equip_id_variant: Variant in scene._equipment_upgrade_button_refs.keys():
		_refresh_equipment_upgrade_button_state(scene, int(equip_id_variant))


func _register_equipment_upgrade_button(scene: Control, equip_id: int, button: Button) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	button.add_child(overlay)

	var cooldown_label := Label.new()
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 16)
	cooldown_label.visible = false
	button.add_child(cooldown_label)

	scene._equipment_upgrade_button_refs[equip_id] = {
		"button": button,
		"overlay": overlay,
		"label": cooldown_label,
		"base_disabled": button.disabled,
	}
	_refresh_equipment_upgrade_button_state(scene, equip_id)


func _refresh_equipment_upgrade_button_state(scene: Control, equip_id: int) -> void:
	if not _scene_valid(scene):
		return
	var entry: Variant = scene._equipment_upgrade_button_refs.get(equip_id, null)
	if not entry is Dictionary:
		return

	var entry_dict: Dictionary = entry
	var button := entry_dict.get("button") as Button
	var overlay := entry_dict.get("overlay") as ColorRect
	var cooldown_label := entry_dict.get("label") as Label
	if button == null or overlay == null or cooldown_label == null:
		return

	var remaining := float(scene._equipment_upgrade_cooldowns.get(equip_id, 0.0))
	var cooling_down := remaining > 0.0
	button.disabled = bool(entry_dict.get("base_disabled", false)) or cooling_down or scene._api_in_flight

	if cooling_down:
		var button_size := button.size
		if button_size.x <= 0.0 or button_size.y <= 0.0:
			button_size = button.custom_minimum_size
		var ratio := clampf(remaining / scene.SCOOP_COOLDOWN, 0.0, 1.0)
		overlay.visible = true
		overlay.position = Vector2(button_size.x * (1.0 - ratio), 0.0)
		overlay.size = Vector2(button_size.x * ratio, button_size.y)
		cooldown_label.visible = false
		cooldown_label.position = Vector2.ZERO
		cooldown_label.size = button_size
	else:
		overlay.visible = false
		cooldown_label.visible = false


func _get_scoop_amount() -> int:
	return 1


func _on_scoop_pressed(scene: Control) -> void:
	if not _scene_valid(scene):
		return
	if scene._scoop_cooldown_remaining > 0.0 or scene.GameState.player_data.poop_count <= 0 or scene._api_in_flight:
		return

	var scoop_count := mini(scene.GameState.player_data.poop_count, _get_scoop_amount())
	scene._scoop_cooldown_remaining = scene.SCOOP_COOLDOWN
	scene._api_in_flight = true
	_refresh_scoop_ui(scene)

	scene.ApiClient.scoop_poop(scoop_count, func(ok: bool, data: Variant, err: Dictionary) -> void:
		if not _scene_valid(scene):
			return
		if not ok:
			scene._api_in_flight = false
			var msg: String = str(err.get("message", "鏟屎失敗"))
			if scene._scoop_result_label != null:
				scene._scoop_result_label.text = msg
			_refresh_scoop_ui(scene)
			return

		var result: Dictionary = data if data is Dictionary else {}
		var updated_profile: Variant = result.get("updatedProfile", {})
		if updated_profile is Dictionary:
			scene._apply_profile_to_player_data(updated_profile)

		if scene._scoop_result_label != null:
			scene._scoop_result_label.text = _format_scoop_result(result)

		scene.ApiClient.get_achievements(func(achievements_ok: bool, achievements_data: Variant, _achievements_err: Dictionary) -> void:
			if not _scene_valid(scene):
				return
			if achievements_ok and achievements_data is Array:
				scene.GameState.update_scooper_achievement(achievements_data)
				scene._refresh_tab_button_labels()
			scene._api_in_flight = false
			_refresh_scooper_profile_ui(scene)
			_refresh_scoop_ui(scene)
		, false)
	, false)


func _format_scoop_result(result: Dictionary) -> String:
	if result.is_empty():
		return "目前沒有可鏟的屎堆"

	var parts: Array[String] = []
	if int(result.get("expGained", 0)) > 0:
		parts.append("EXP +%d" % int(result["expGained"]))
	if int(result.get("memoryShardsGained", 0)) > 0:
		parts.append("回憶碎片 +%d" % int(result["memoryShardsGained"]))
	if int(result.get("whiskersGained", 0)) > 0:
		parts.append("鬍鬚 +%d" % int(result["whiskersGained"]))
	return "這次沒有掉落額外獎勵" if parts.is_empty() else "獲得：" + "、".join(parts)


func _make_equip_card(scene: Control, item: Dictionary) -> Control:
	var equip_id: int = int(item.get("equipmentId", 0))
	var name_str: String = item.get("displayName") if item.get("displayName") != null else ""
	var unlock_lv: int = int(item.get("unlockLevel", 1))
	var owned: bool = bool(item.get("isOwned", false))
	var level: int = int(item.get("level", 0))
	var exp_val: int = int(item.get("currentExp", 0))
	var broken: bool = bool(item.get("isBroken", false))
	var sick_cat_name: String = item.get("sickCatName") if item.get("sickCatName") != null else ""
	var scooper_lv: int = int(item.get("scooperLevel", scene.GameState.player_data.scooper_level))
	var exp_per_lv: int = int(item.get("expPerLevel", 10))
	var locked: bool = not owned and scooper_lv < unlock_lv

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)
	var card_bg := ColorRect.new()
	card_bg.color = Color(0.18, 0.20, 0.25, 1.0) if owned else Color(0.14, 0.15, 0.18, 1.0)
	card_bg.custom_minimum_size = Vector2(0.0, 4.0)
	card.add_child(card_bg)

	var header_row := HBoxContainer.new()
	card.add_child(header_row)

	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if locked:
		name_lbl.text = "🔒 %s" % name_str
		name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	elif broken:
		name_lbl.text = "⚠ %s" % name_str
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 1.0))
	elif sick_cat_name != "":
		name_lbl.text = "🤒 %s" % name_str
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	else:
		name_lbl.text = name_str
	header_row.add_child(name_lbl)

	if owned:
		var lv_lbl := Label.new()
		lv_lbl.text = "Lv.%d / %d" % [level, scooper_lv]
		lv_lbl.add_theme_font_size_override("font_size", 18)
		lv_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
		header_row.add_child(lv_lbl)

	var desc_lbl := Label.new()
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	if locked:
		desc_lbl.text = "解鎖需要鏟屎官 Lv.%d　%s" % [unlock_lv, _bonus_desc(item, 0)]
	elif broken:
		desc_lbl.text = "損壞中，加成暫停　EXP %d / %d" % [exp_val, exp_per_lv]
	elif sick_cat_name != "":
		desc_lbl.text = "🐱 %s 生病中，無法升級　%s" % [sick_cat_name, _bonus_desc(item, level)]
	elif owned:
		var exp_gain: int = int(scene._equipment_upgrade_gain_map.get(equip_id, 0))
		var gain_suffix := " (+%d)" % exp_gain if exp_gain > 0 else ""
		var exp_str: String = "  EXP %d / %d%s" % [exp_val, exp_per_lv, gain_suffix] if level < scooper_lv else "  已滿等%s" % gain_suffix
		desc_lbl.text = _bonus_desc(item, level) + exp_str
	else:
		desc_lbl.text = "%s　購買後解鎖" % _bonus_desc(item, 1)
	card.add_child(desc_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	card.add_child(btn_row)

	if locked:
		pass
	elif not owned:
		var buy_btn := Button.new()
		buy_btn.text = "購買 %d 💰" % int(item.get("purchaseCost", 0))
		buy_btn.custom_minimum_size = Vector2(160.0, 42.0)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.pressed.connect(func() -> void:
			_do_equipment_action(scene, "purchase", equip_id)
		)
		btn_row.add_child(buy_btn)
	else:
		if broken:
			var repair_btn := Button.new()
			repair_btn.text = "修復 %d 💰" % int(item.get("repairCost", 0))
			repair_btn.custom_minimum_size = Vector2(160.0, 42.0)
			repair_btn.add_theme_font_size_override("font_size", 16)
			repair_btn.pressed.connect(func() -> void:
				_do_equipment_action(scene, "repair", equip_id)
			)
			btn_row.add_child(repair_btn)
		else:
			if sick_cat_name != "":
				var heal_btn := Button.new()
				heal_btn.text = "就醫 %d 💰" % int(item.get("treatCost", 0))
				heal_btn.custom_minimum_size = Vector2(160.0, 42.0)
				heal_btn.add_theme_font_size_override("font_size", 16)
				heal_btn.pressed.connect(func() -> void:
					_do_equipment_action(scene, "treat", equip_id)
				)
				btn_row.add_child(heal_btn)

			var up_btn := Button.new()
			up_btn.text = "升級 %d 💰" % int(item.get("upgradeCost", 0))
			up_btn.custom_minimum_size = Vector2(160.0, 42.0)
			up_btn.add_theme_font_size_override("font_size", 16)
			up_btn.disabled = sick_cat_name != "" or level >= scooper_lv
			up_btn.pressed.connect(func() -> void:
				_do_equipment_action(scene, "upgrade", equip_id)
			)
			_register_equipment_upgrade_button(scene, equip_id, up_btn)
			btn_row.add_child(up_btn)

	card.add_child(scene._make_separator())
	return card


func _do_equipment_action(scene: Control, action: String, equip_id: int) -> void:
	if not _scene_valid(scene):
		return
	if scene._api_in_flight:
		return

	if action == "upgrade":
		scene._equipment_upgrade_cooldowns[equip_id] = scene.SCOOP_COOLDOWN
		scene._equipment_upgrade_gain_map.erase(equip_id)

	scene._api_in_flight = true
	_refresh_equipment_upgrade_button_states(scene)

	var action_labels: Dictionary = {
		"purchase": "購買",
		"upgrade": "升級",
		"repair": "修復",
		"treat": "就醫",
	}
	var label: String = action_labels.get(action, action)

	var callback := func(ok: bool, data: Variant, err: Dictionary) -> void:
		if not _scene_valid(scene):
			return
		if not ok:
			scene._api_in_flight = false
			_refresh_equipment_upgrade_button_states(scene)
			scene.DialogManager.show_info("%s失敗" % label, str(err.get("message", "操作失敗")))
			return

		var result: Dictionary = data if data is Dictionary else {}
		if action == "upgrade":
			var gained: int = int(result.get("expGained", 0))
			if gained > 0:
				scene._equipment_upgrade_gain_map[equip_id] = gained
			else:
				scene._equipment_upgrade_gain_map.erase(equip_id)

		_refresh_resource_after_action(scene, action == "upgrade", func() -> void:
			if not _scene_valid(scene):
				return
			scene._api_in_flight = false
			_refresh_equipment_upgrade_button_states(scene)
		)

	match action:
		"purchase":
			scene.ApiClient.purchase_equipment(equip_id, callback)
		"upgrade":
			scene.ApiClient.upgrade_equipment(equip_id, callback, false)
		"repair":
			scene.ApiClient.repair_equipment(equip_id, callback)
		"treat":
			scene.ApiClient.treat_equipment(equip_id, callback)


func _refresh_resource_after_action(scene: Control, refresh_upgrade_data: bool = false, on_completed: Callable = Callable()) -> void:
	if not _scene_valid(scene):
		return
	if not refresh_upgrade_data:
		scene.refresh_from_bootstrap(func(ok: bool, _data: Variant, err: Dictionary) -> void:
			if not _scene_valid(scene):
				return
			if not ok:
				scene.DialogManager.show_info("同步失敗", str(err.get("message", "鏟屎官資料同步失敗")))
			if not on_completed.is_null():
				on_completed.call()
		)
		return

	var request_state := {
		"remaining": 3,
		"ok": true,
		"err": {},
	}

	var finish_request := func(request_ok: bool, request_err: Dictionary) -> void:
		if not _scene_valid(scene):
			return
		if not request_ok and bool(request_state["ok"]):
			request_state["ok"] = false
			request_state["err"] = request_err
		request_state["remaining"] = int(request_state["remaining"]) - 1
		if int(request_state["remaining"]) > 0:
			return

		scene._refresh_resource_label()
		_refresh_scooper_profile_ui(scene)
		scene._refresh_tab_button_labels()
		_rebuild_equip_list(scene)
		_refresh_scoop_ui(scene)

		if not bool(request_state["ok"]):
			var sync_err: Dictionary = request_state["err"]
			scene.DialogManager.show_info("同步失敗", str(sync_err.get("message", "鏟屎官資料同步失敗")))
		if not on_completed.is_null():
			on_completed.call()

	scene.ApiClient.get_scooper_profile(func(ok: bool, data: Variant, err: Dictionary) -> void:
		if not _scene_valid(scene):
			return
		if ok and data is Dictionary:
			scene.GameState.update_scooper_profile(data)
		finish_request.call(ok, err)
	, false)

	scene.ApiClient.get_equipment_list(func(ok: bool, data: Variant, err: Dictionary) -> void:
		if not _scene_valid(scene):
			return
		if ok and data is Array:
			scene.GameState.update_scooper_equipment(data)
		finish_request.call(ok, err)
	, false)

	scene.ApiClient.get_achievements(func(ok: bool, data: Variant, err: Dictionary) -> void:
		if not _scene_valid(scene):
			return
		if ok and data is Array:
			scene.GameState.update_scooper_achievement(data)
		finish_request.call(ok, err)
	, false)


func _bonus_desc(item: Dictionary, level: int) -> String:
	var stat: String = item.get("bonusStat") if item.get("bonusStat") != null else ""
	var target: String = item.get("bonusTarget") if item.get("bonusTarget") != null else "All"
	var per_lv: float = float(item.get("bonusPerLevel", 0.0))

	var target_str: String = "全隊" if target.to_lower() == "all" else "%s系" % target
	var stat_str: String
	match stat:
		"atk_percent", "AtkPercent":
			stat_str = "ATK"
		"def_percent", "DefPercent":
			stat_str = "DEF"
		"max_hp_percent", "MaxHpPercent":
			stat_str = "HP"
		_:
			stat_str = stat

	if level <= 0:
		return "%s %s +%.1f%%/級" % [target_str, stat_str, per_lv * 100.0]
	return "%s %s +%.1f%%" % [target_str, stat_str, per_lv * level * 100.0]
