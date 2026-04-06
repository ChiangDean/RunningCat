extends Control

## 商店主畫面：各功能入口按鈕 + 商城禮包列表

const SW := 720.0
const SH := 1280.0

var _title_label: Label
var _diamond_label: Label
var _content_root: VBoxContainer
var _current_view: String = "root"
var _current_bundle_category: String = "value_pack"
var _bundle_scroller: InertialScroller

@onready var GameState = get_node("/root/GameState")


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 18)
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

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(_title_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	_diamond_label = Label.new()
	_diamond_label.add_theme_font_size_override("font_size", 22)
	_diamond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(_diamond_label)

	root_vbox.add_child(_make_separator())

	_content_root = VBoxContainer.new()
	_content_root.add_theme_constant_override("separation", 16)
	_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_content_root)

	_show_main_menu()


func _show_main_menu() -> void:
	_current_view = "root"
	_bundle_scroller = null
	_set_title("商店")
	_clear_content()

	var items: Array = [
		["誘捕籠", true, _on_gacha_pressed],
		["商城禮包", true, _on_bundle_shop_pressed],
		["購買鑽石", false, Callable()],
		["每日特賣", false, Callable()],
		["道具兌換", false, Callable()],
	]

	for item: Array in items:
		var btn_label: String = item[0]
		var available: bool = item[1]
		var callback: Callable = item[2]

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0.0, 80.0)
		btn.add_theme_font_size_override("font_size", 26)

		if available:
			btn.text = btn_label
			btn.pressed.connect(callback)
		else:
			btn.text = btn_label + "  🔒 待開放"
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6, 1.0)

		_content_root.add_child(btn)

	_refresh_currency_labels()


func _show_bundle_shop(category_id: String = "value_pack") -> void:
	_current_view = "bundle_shop"
	_current_bundle_category = category_id
	_set_title("商城禮包")
	_clear_content()

	var category_row := HBoxContainer.new()
	category_row.add_theme_constant_override("separation", 8)
	_content_root.add_child(category_row)

	for category: Dictionary in GameState.get_shop_bundle_categories():
		var key: String = category.get("id", "")
		var btn := Button.new()
		btn.text = category.get("name", key)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 50.0)
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if key == category_id else Color(0.65, 0.65, 0.65, 1.0)
		btn.pressed.connect(func() -> void:
			_show_bundle_shop(key)
		)
		category_row.add_child(btn)

	var hint := Label.new()
	hint.text = "超值禮包會直接發送寶藏到收藏，重複取得會疊加生效。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	_content_root.add_child(hint)

	_content_root.add_child(_make_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_root.add_child(scroll)
	_bundle_scroller = InertialScroller.attach(scroll, "vertical")

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var bundles: Array = GameState.get_shop_bundles_by_category(category_id)
	if bundles.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "目前沒有可購買的禮包"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 20)
		list.add_child(empty_lbl)
	else:
		for bundle: Dictionary in bundles:
			list.add_child(_make_bundle_card(bundle))

	_refresh_currency_labels()


func _make_bundle_card(bundle: Dictionary) -> Control:
	var bundle_id: String = bundle.get("id", "")
	var purchase_limit: int = int(bundle.get("purchase_limit", 1))
	var purchased: int = GameState.get_bundle_purchase_count(bundle_id)
	var sold_out: bool = purchase_limit >= 0 and purchased >= purchase_limit

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.33, 0.45, 0.54, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 10)
	margin.add_child(card)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	card.add_child(header)

	var title := Label.new()
	title.text = bundle.get("name", bundle_id)
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var state := Label.new()
	state.text = "已售完" if sold_out else _bundle_limit_text(purchased, purchase_limit)
	state.add_theme_font_size_override("font_size", 16)
	state.add_theme_color_override("font_color",
			Color(0.95, 0.75, 0.45, 1.0) if sold_out else Color(0.78, 0.84, 0.92, 1.0))
	header.add_child(state)

	var desc := Label.new()
	desc.text = bundle.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82, 1.0))
	card.add_child(desc)

	var rewards_title := Label.new()
	rewards_title.text = "內容物"
	rewards_title.add_theme_font_size_override("font_size", 18)
	card.add_child(rewards_title)

	for reward_text: String in _bundle_reward_lines(bundle):
		var reward_lbl := Label.new()
		reward_lbl.text = reward_text
		reward_lbl.add_theme_font_size_override("font_size", 17)
		reward_lbl.add_theme_color_override("font_color", Color(0.84, 0.94, 1.0, 1.0))
		card.add_child(reward_lbl)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	card.add_child(action_row)

	var cost_lbl := Label.new()
	cost_lbl.text = "💎 %d" % int(bundle.get("diamond_cost", 0))
	cost_lbl.custom_minimum_size = Vector2(100.0, 42.0)
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 20)
	action_row.add_child(cost_lbl)

	var buy_btn := Button.new()
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.custom_minimum_size = Vector2(0.0, 44.0)
	if sold_out:
		buy_btn.text = "已達購買上限"
		buy_btn.disabled = true
	else:
		buy_btn.text = "購買"
		buy_btn.pressed.connect(func() -> void:
			_confirm_purchase_bundle(bundle)
		)
	action_row.add_child(buy_btn)

	return panel


func _confirm_purchase_bundle(bundle: Dictionary) -> void:
	var bundle_id: String = bundle.get("id", "")
	var reward_lines := _bundle_reward_lines(bundle)
	var body := "是否花費 %d 鑽石購買「%s」？\n\n%s" % [
		int(bundle.get("diamond_cost", 0)),
		bundle.get("name", bundle_id),
		"\n".join(reward_lines),
	]
	DialogManager.show_confirm("購買禮包", body, func() -> void:
		var result = GameState.purchase_shop_bundle(bundle_id)
		if not result.get("success", false):
			DialogManager.show_info("購買失敗", result.get("error", ""))
			_refresh_current_view()
			return
		_refresh_current_view()
		var lines: Array[String] = []
		for granted: Dictionary in result.get("granted", []):
			lines.append("%s ×%d（目前持有 %d）" % [
				granted.get("name", granted.get("id", "")),
				int(granted.get("quantity", 1)),
				int(granted.get("total_quantity", 1)),
			])
		DialogManager.show_info("購買成功", "已獲得：\n%s" % "\n".join(lines))
	)


func _bundle_reward_lines(bundle: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for reward: Dictionary in bundle.get("rewards", []):
		if reward.get("type", "") != "treasure":
			continue
		var treasure = GameState.get_treasure_item(reward.get("id", ""))
		if treasure.is_empty():
			continue
		lines.append("• %s ×%d" % [treasure.get("name", reward.get("id", "")), int(reward.get("quantity", 1))])
		for effect: Dictionary in treasure.get("effects", []):
			lines.append("  %s" % _format_effect_line(effect))
	return lines


func _format_effect_line(effect: Dictionary) -> String:
	var target: String = effect.get("target", "all")
	var target_text: String = "全隊" if target == "all" else "%s系" % target
	var stat: String = effect.get("stat", "")
	var value: float = float(effect.get("value", 0.0))
	match stat:
		"atk_percent":
			return "%s ATK +%.1f%%" % [target_text, value * 100.0]
		"def_percent":
			return "%s DEF +%.1f%%" % [target_text, value * 100.0]
		"max_hp_percent":
			return "%s HP +%.1f%%" % [target_text, value * 100.0]
		"crit_rate":
			return "%s 暴擊率 +%.1f%%" % [target_text, value * 100.0]
		"crit_damage":
			return "%s 暴擊傷害 +%.1f%%" % [target_text, value * 100.0]
		"damage_reduction":
			return "%s 減傷 +%.1f%%" % [target_text, value * 100.0]
		"cooldown_reduction":
			return "%s 技能 CD -%.1f%%" % [target_text, value * 100.0]
		"idle_poop_percent":
			return "掛機屎堆 +%.1f%%" % [value * 100.0]
		_:
			return "%s %s %.2f" % [target_text, stat, value]


func _bundle_limit_text(purchased: int, purchase_limit: int) -> String:
	if purchase_limit < 0:
		return "已購買 %d 次" % purchased
	return "已購買 %d / %d" % [purchased, purchase_limit]


func _refresh_current_view() -> void:
	if _current_view == "bundle_shop":
		_show_bundle_shop(_current_bundle_category)
	else:
		_show_main_menu()


func _set_title(text: String) -> void:
	_title_label.text = text


func _refresh_currency_labels() -> void:
	_diamond_label.text = "💎 鑽石：%d" % GameState.player_data.diamonds


func _clear_content() -> void:
	for child in _content_root.get_children():
		child.queue_free()


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _on_back_pressed() -> void:
	if _current_view != "root":
		_show_main_menu()
		return
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")


func _on_gacha_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/GachaScene.tscn")


func _on_bundle_shop_pressed() -> void:
	_show_bundle_shop("value_pack")
