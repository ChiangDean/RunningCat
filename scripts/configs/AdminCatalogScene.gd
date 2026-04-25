extends Control

const SECTION_HINTS := {
	"core": "管理貨幣與消耗品 catalog。數值修改會在後續請求生效。",
	"cats": "管理貓咪基礎素質、稀有度與主被動技能綁定。請勿手動改動既有 id。",
	"skills": "管理主動/被動技能與其效果、rank scaling。",
	"stages": "管理 stage 公式、boss 世界設定、territory 與 zone suffix。",
	"dungeons": "管理地城靜態數值與每層獎勵公式。",
	"arena": "管理競技場全域設定、rank 區間與 bot 內容。",
	"gacha": "管理 gacha 設定、pull option、技巧等級與稀有度展示。",
	"scooper": "管理 idle 設定、裝備與特殊能力 catalog。",
	"memories": "管理記憶 catalog。",
	"treasures": "管理寶物與效果。",
	"achievements": "管理成就條件與獎勵。",
	"shop": "管理 shop category、group、bundle 與獎勵。",
	"combat-power": "管理戰力換算權重；bootstrap 會回傳權重表，前端用目前資料本機計算 combatScore。",
}

var _access_payload: Dictionary = {}
var _references: Dictionary = {}
var _section_buttons: Dictionary = {}
var _current_section_key := ""
var _current_section_data: Dictionary = {}
var _dirty := false
var _loading_access := false
var _loading_section := false
var _saving := false
var _updating_editor := false

var _status_label: Label
var _section_list: VBoxContainer
var _section_title_label: Label
var _section_hint_label: Label
var _save_button: Button
var _reload_button: Button
var _discard_button: Button
var _editor: TextEdit
var _reference_label: RichTextLabel
var _left_panel: VBoxContainer
var _renderer_host: VBoxContainer
var _active_renderer: Control


func _ready() -> void:
	_build_ui()
	_load_access()


func _build_ui() -> void:
	var chrome: Dictionary = OverlaySceneChrome.build(self, "config", Callable(self, "_on_back_pressed"), {
		"show_dock": false,
		"content_bottom": -(OverlaySceneChrome.HOME_MAIN_NAV_H + 14.0),
		"content_separation": 12,
	})
	var content_box: VBoxContainer = chrome.get("content_box") as VBoxContainer

	var title: Label = Label.new()
	title.text = "Admin Catalog"
	title.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_DISPLAY)
	content_box.add_child(title)

	_status_label = Label.new()
	_status_label.text = "驗證中..."
	_status_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	content_box.add_child(_status_label)

	var split: HSplitContainer = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 220
	content_box.add_child(split)

	var nav_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	split.add_child(nav_panel)
	var nav_margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	nav_panel.add_child(nav_margin)
	_section_list = VBoxContainer.new()
	_section_list.add_theme_constant_override("separation", 8)
	nav_margin.add_child(_section_list)

	var right_panel: PanelContainer = OverlaySceneChrome.make_card_panel()
	split.add_child(right_panel)
	var right_margin: MarginContainer = OverlaySceneChrome.make_content_margin(12)
	right_panel.add_child(right_margin)
	var right_column: VBoxContainer = VBoxContainer.new()
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 10)
	right_margin.add_child(right_column)

	_section_title_label = Label.new()
	_section_title_label.text = "尚未載入"
	_section_title_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY_LG)
	right_column.add_child(_section_title_label)

	_section_hint_label = Label.new()
	_section_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_section_hint_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_SMALL)
	right_column.add_child(_section_hint_label)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	right_column.add_child(action_row)

	_save_button = Button.new()
	_save_button.text = "儲存"
	_save_button.custom_minimum_size = Vector2(120.0, 42.0)
	UiPalette.apply_button_kind(_save_button, "confirm")
	_save_button.pressed.connect(UiAudio.play_ui_click)
	_save_button.pressed.connect(_on_save_pressed)
	action_row.add_child(_save_button)

	_reload_button = Button.new()
	_reload_button.text = "重新載入"
	_reload_button.custom_minimum_size = Vector2(120.0, 42.0)
	UiPalette.apply_button_kind(_reload_button, "secondary")
	_reload_button.pressed.connect(UiAudio.play_ui_click)
	_reload_button.pressed.connect(_on_reload_pressed)
	action_row.add_child(_reload_button)

	_discard_button = Button.new()
	_discard_button.text = "放棄變更"
	_discard_button.custom_minimum_size = Vector2(120.0, 42.0)
	UiPalette.apply_button_kind(_discard_button, "secondary")
	_discard_button.pressed.connect(UiAudio.play_ui_click)
	_discard_button.pressed.connect(_on_discard_pressed)
	action_row.add_child(_discard_button)

	var content_split: HSplitContainer = HSplitContainer.new()
	content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.split_offset = 760
	right_column.add_child(content_split)

	_left_panel = VBoxContainer.new()
	_left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.add_child(_left_panel)

	_editor = TextEdit.new()
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	_editor.text_changed.connect(_on_editor_text_changed)
	_left_panel.add_child(_editor)

	_renderer_host = VBoxContainer.new()
	_renderer_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_renderer_host.visible = false
	_left_panel.add_child(_renderer_host)

	_reference_label = RichTextLabel.new()
	_reference_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reference_label.fit_content = false
	_reference_label.bbcode_enabled = true
	_reference_label.scroll_active = true
	content_split.add_child(_reference_label)

	_refresh_action_state()


func _load_access() -> void:
	_loading_access = true
	_refresh_action_state()
	_status_label.text = "驗證 Admin 權限..."
	ApiClient.admin_get_catalog_access(func(success: bool, data: Variant, error: Dictionary) -> void:
		_loading_access = false
		if not success:
			_status_label.text = "驗權失敗"
			DialogManager.show_info("無法進入 Admin Catalog", str(error.get("message", "驗證失敗。")))
			SceneNavigator.return_to_battle()
			_refresh_action_state()
			return

		_access_payload = data if data is Dictionary else {}
		_references = _access_payload.get("references", {}) if _access_payload.get("references", {}) is Dictionary else {}
		_build_section_buttons()
		var sections: Array = _access_payload.get("sections", []) if _access_payload.get("sections", []) is Array else []
		if sections.is_empty():
			_status_label.text = "沒有可用 section"
			_refresh_action_state()
			return
		var first_section: Dictionary = sections[0] if sections[0] is Dictionary else {}
		_request_section_switch(str(first_section.get("sectionKey", "")).strip_edges())
	)


func _build_section_buttons() -> void:
	for child: Node in _section_list.get_children():
		child.queue_free()
	_section_buttons.clear()

	var sections: Array = _access_payload.get("sections", []) if _access_payload.get("sections", []) is Array else []
	for section_variant: Variant in sections:
		if not (section_variant is Dictionary):
			continue
		var section: Dictionary = section_variant
		var section_key := str(section.get("sectionKey", "")).strip_edges()
		if section_key == "":
			continue

		var button: Button = Button.new()
		button.text = str(section.get("displayName", section_key))
		button.custom_minimum_size = Vector2(0.0, 42.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiPalette.apply_button_kind(button, "secondary")
		button.pressed.connect(UiAudio.play_ui_click)
		button.pressed.connect(func() -> void:
			_request_section_switch(section_key)
		)
		_section_buttons[section_key] = button
		_section_list.add_child(button)


func _request_section_switch(section_key: String) -> void:
	if section_key == "" or section_key == _current_section_key and not _current_section_data.is_empty():
		return
	if _dirty:
		DialogManager.show_confirm("放棄未儲存變更", "切換 section 會丟棄目前未儲存的內容，是否繼續？", func() -> void:
			_load_section(section_key)
		)
		return
	_load_section(section_key)


func _load_section(section_key: String) -> void:
	_loading_section = true
	_refresh_action_state()
	_status_label.text = "載入 %s..." % section_key
	ApiClient.admin_get_catalog_section(section_key, func(success: bool, data: Variant, error: Dictionary) -> void:
		_loading_section = false
		if not success:
			_status_label.text = "載入失敗"
			DialogManager.show_info("載入失敗", str(error.get("message", "無法載入 section。")))
			_refresh_action_state()
			return

		_current_section_key = section_key
		_current_section_data = (data if data is Dictionary else {}).duplicate(true)
		_set_editor_payload(_current_section_data)
		_dirty = false
		_refresh_section_visuals()
		_refresh_action_state()
	)


func _set_editor_payload(payload: Dictionary) -> void:
	if _active_renderer != null:
		_renderer_host.remove_child(_active_renderer)
		_active_renderer.queue_free()
		_active_renderer = null

	var renderer: Control = _create_renderer(_current_section_key)
	if renderer != null:
		_active_renderer = renderer
		_active_renderer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_active_renderer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_active_renderer.changed.connect(func() -> void:
			_dirty = true
			_refresh_action_state()
		)
		_renderer_host.add_child(_active_renderer)
		_active_renderer.setup(payload)
		_editor.visible = false
		_renderer_host.visible = true
	else:
		_editor.visible = true
		_renderer_host.visible = false
		_updating_editor = true
		_editor.text = JSON.stringify(payload, "\t")
		_updating_editor = false


func _create_renderer(section_key: String) -> Control:
	match section_key:
		"core":
			return AdminCatalogCoreRenderer.new()
		"gacha":
			return AdminCatalogGachaRenderer.new()
		"arena":
			return AdminCatalogArenaRenderer.new()
		"memories":
			return AdminCatalogMemoriesRenderer.new()
		"treasures":
			return AdminCatalogTreasuresRenderer.new()
		"dungeons":
			return AdminCatalogDungeonsRenderer.new()
		"achievements":
			return AdminCatalogAchievementsRenderer.new()
		"shop":
			return AdminCatalogShopRenderer.new()
		"stages":
			return AdminCatalogStagesRenderer.new()
		"scooper":
			return AdminCatalogScooperRenderer.new()
		"cats":
			return AdminCatalogCatsRenderer.new()
		"skills":
			return AdminCatalogSkillsRenderer.new()
		"combat-power":
			return AdminCatalogCombatPowerRenderer.new()
		_:
			return null


func _refresh_section_visuals() -> void:
	for key: String in _section_buttons.keys():
		var button: Button = _section_buttons.get(key)
		if button == null:
			continue
		button.disabled = _loading_access or _loading_section or _saving
		if key == _current_section_key:
			UiPalette.apply_button_kind(button, "confirm")
		else:
			UiPalette.apply_button_kind(button, "secondary")

	var title_text := _current_section_key
	var sections: Array = _access_payload.get("sections", []) if _access_payload.get("sections", []) is Array else []
	for section_variant: Variant in sections:
		if section_variant is Dictionary and str((section_variant as Dictionary).get("sectionKey", "")) == _current_section_key:
			title_text = str((section_variant as Dictionary).get("displayName", _current_section_key))
			break

	_section_title_label.text = title_text
	_section_hint_label.text = str(SECTION_HINTS.get(_current_section_key, ""))
	_reference_label.text = _build_reference_text(_current_section_key)
	_status_label.text = _build_status_text()


func _build_status_text() -> String:
	if _saving:
		return "儲存中..."
	if _loading_access:
		return "驗證中..."
	if _loading_section:
		return "載入中..."
	if _current_section_key == "":
		return "尚未選擇 section"
	return "目前 section: %s%s" % [_current_section_key, " (未儲存)" if _dirty else ""]


func _build_reference_text(section_key: String) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]Section Hint[/b]")
	lines.append(str(SECTION_HINTS.get(section_key, "")))
	lines.append("")
	lines.append("[b]Common References[/b]")
	lines.append(_format_reference_group("skills"))
	lines.append(_format_reference_group("cats"))
	if section_key == "shop":
		lines.append(_format_reference_group("currencies"))
		lines.append(_format_reference_group("treasures"))
		lines.append(_format_reference_group("shopBundleGroups"))
	return "\n".join(lines)


func _format_reference_group(key: String) -> String:
	var items: Array = _references.get(key, []) if _references.get(key, []) is Array else []
	if items.is_empty():
		return "%s: none" % key
	var result: PackedStringArray = []
	result.append("%s:" % key)
	var limit := mini(items.size(), 24)
	for i in range(limit):
		var item: Dictionary = items[i] if items[i] is Dictionary else {}
		result.append("- %s | %s | %s" % [str(item.get("id", "")), str(item.get("key", "")), str(item.get("displayName", ""))])
	if items.size() > limit:
		result.append("- ... %d more" % [items.size() - limit])
	return "\n".join(result)


func _on_editor_text_changed() -> void:
	if _updating_editor:
		return
	_dirty = true
	_refresh_action_state()


func _on_save_pressed() -> void:
	if _saving or _loading_section or _current_section_key == "":
		return
	DialogManager.show_confirm("確認儲存", "儲存後會立即生效，是否繼續？", func() -> void:
		_save_current_section()
	)


func _save_current_section() -> void:
	var payload: Variant
	if _active_renderer != null:
		payload = _active_renderer.get_data()
	else:
		var parser := JSON.new()
		if parser.parse(_editor.text) != OK:
			DialogManager.show_info("JSON 格式錯誤", "請先修正 JSON 內容後再儲存。")
			return
		payload = parser.get_data()
		if not (payload is Dictionary):
			DialogManager.show_info("格式錯誤", "Section payload 必須是 JSON object。")
			return

	_saving = true
	_refresh_action_state()
	ApiClient.admin_save_catalog_section(_current_section_key, payload, func(success: bool, data: Variant, error: Dictionary) -> void:
		_saving = false
		if not success:
			_status_label.text = "儲存失敗"
			DialogManager.show_info("儲存失敗", str(error.get("message", "無法儲存 section。")))
			_refresh_action_state()
			return

		_current_section_data = (data if data is Dictionary else {}).duplicate(true)
		_set_editor_payload(_current_section_data)
		_dirty = false
		_refresh_action_state()
		_refresh_section_visuals()
	)


func _on_reload_pressed() -> void:
	if _current_section_key == "" or _loading_section or _saving:
		return
	if _dirty:
		DialogManager.show_confirm("重新載入 section", "重新載入會放棄目前未儲存的內容，是否繼續？", func() -> void:
			_load_section(_current_section_key)
		)
		return
	_load_section(_current_section_key)


func _on_discard_pressed() -> void:
	if _dirty:
		_load_section(_current_section_key)


func _refresh_action_state() -> void:
	var can_edit := not _loading_access and not _loading_section and _current_section_key != ""
	if _active_renderer == null:
		_editor.editable = can_edit and not _saving
	_save_button.disabled = not can_edit or not _dirty or _saving
	_reload_button.disabled = not can_edit or _saving
	_discard_button.disabled = not can_edit or not _dirty or _saving
	_refresh_section_visuals()


func _on_back_pressed() -> void:
	if _dirty:
		DialogManager.show_confirm("離開 Admin Catalog", "目前有未儲存的變更，離開會直接放棄，是否離開？", func() -> void:
			SceneNavigator.return_to_battle()
		)
		return
	SceneNavigator.return_to_battle()
