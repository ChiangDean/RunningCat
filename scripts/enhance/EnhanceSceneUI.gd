class_name EnhanceSceneUI
extends RefCounted

const Refresh = preload("res://scripts/enhance/EnhanceSceneRefresh.gd")


static func build_ui(scene) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(scene.SW, scene.SH)
	scene.add_child(bg)

	var layer := CanvasLayer.new()
	scene.add_child(layer)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 14)
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
	back_btn.pressed.connect(scene._on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "強化"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	scene._resource_label = Label.new()
	scene._resource_label.add_theme_font_size_override("font_size", 22)
	root_vbox.add_child(scene._resource_label)
	Refresh.refresh_resource_label(scene)

	root_vbox.add_child(Refresh.make_separator())

	scene._detail_panel = VBoxContainer.new()
	scene._detail_panel.add_theme_constant_override("separation", 12)
	scene._detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scene._detail_panel)

	var cat_select_title := Label.new()
	cat_select_title.text = "選擇貓咪"
	cat_select_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(Refresh.make_separator())
	root_vbox.add_child(cat_select_title)

	scene._cat_hscroll = ScrollContainer.new()
	scene._cat_hscroll.custom_minimum_size = Vector2(0, 88)
	scene._cat_hscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cat_row := HBoxContainer.new()
	cat_row.add_theme_constant_override("separation", 12)
	scene._cat_hscroll.add_child(cat_row)
	root_vbox.add_child(scene._cat_hscroll)
	scene._cat_scroller = InertialScroller.attach(scene._cat_hscroll, "horizontal")

	populate_cat_buttons(scene)

	for child in scene._cat_hscroll.get_children():
		if child is HScrollBar:
			child.hide()


static func populate_cat_buttons(scene) -> void:
	if scene._cat_hscroll == null or scene._cat_hscroll.get_child_count() == 0:
		return

	var cat_row = scene._cat_hscroll.get_child(0)
	for child in cat_row.get_children():
		child.queue_free()

	var owned: Array = scene.GameState.get_owned_cats()
	for cat_id: String in owned:
		var btn := Button.new()
		btn.text = Refresh.get_display_name(cat_id)
		btn.custom_minimum_size = Vector2(140.0, 64.0)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.pressed.connect(Callable(scene, "_on_cat_button_pressed").bind(cat_id))
		cat_row.add_child(btn)

	if scene._selected_cat_id == "" and owned.size() > 0:
		scene._selected_cat_id = owned[0]
	if scene._selected_cat_id != "" and not owned.has(scene._selected_cat_id):
		scene._selected_cat_id = owned[0] if owned.size() > 0 else ""

	rebuild_detail_panel(scene)


static func rebuild_detail_panel(scene) -> void:
	for child in scene._detail_panel.get_children():
		child.queue_free()

	scene._stat_labels.clear()
	scene._special_point_labels.clear()
	scene._special_plus_btns.clear()
	scene._special_minus_btns.clear()
	scene._rank_stars_label = null
	scene._rank_upgrade_btn = null
	scene._food_upgrade_btn = null
	scene._food_max_btn = null
	scene._cat_name_label = null

	if scene._selected_cat_id == "":
		return

	var player_cat: PlayerCatData = scene.GameState.get_player_cat(scene._selected_cat_id)
	var cat_data := CatData.from_json_file(scene._selected_cat_id + ".json")
	if cat_data == null:
		return

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	scene._detail_panel.add_child(name_row)

	scene._cat_name_label = Label.new()
	scene._cat_name_label.text = CatRegistry.get_cat_display_name_with_lv(scene._selected_cat_id, player_cat.cat_food_level)
	scene._cat_name_label.add_theme_font_size_override("font_size", 28)
	name_row.add_child(scene._cat_name_label)

	scene._rank_stars_label = Label.new()
	scene._rank_stars_label.add_theme_font_size_override("font_size", 20)
	scene._rank_stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	name_row.add_child(scene._rank_stars_label)

	var rank_info_btn := Button.new()
	rank_info_btn.text = "?"
	rank_info_btn.custom_minimum_size = Vector2(36.0, 36.0)
	rank_info_btn.pressed.connect(Callable(scene, "_show_rank_bonus_info").bind(cat_data, player_cat.rank))
	name_row.add_child(rank_info_btn)

	var name_spacer := Control.new()
	name_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_spacer)

	scene._rank_upgrade_btn = Button.new()
	scene._rank_upgrade_btn.custom_minimum_size = Vector2(160.0, 44.0)
	scene._rank_upgrade_btn.pressed.connect(scene._on_rank_upgrade_pressed)
	name_row.add_child(scene._rank_upgrade_btn)
	Refresh.refresh_rank_labels(scene, player_cat)

	var stats_title := Label.new()
	stats_title.text = "屬性"
	stats_title.add_theme_font_size_override("font_size", 22)
	scene._detail_panel.add_child(stats_title)

	scene._special_cost_label = Label.new()
	scene._special_cost_label.add_theme_font_size_override("font_size", 18)
	scene._detail_panel.add_child(scene._special_cost_label)

	for stat_key: String in ["hp", "atk", "def"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		scene._detail_panel.add_child(row)

		var stat_lbl := Label.new()
		stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_lbl.add_theme_font_size_override("font_size", 20)
		scene._stat_labels[stat_key] = stat_lbl
		row.add_child(stat_lbl)

		var minus_btn := Button.new()
		minus_btn.text = "−"
		minus_btn.custom_minimum_size = Vector2(44.0, 44.0)
		minus_btn.pressed.connect(Callable(scene, "_on_special_remove_pressed").bind(stat_key))
		scene._special_minus_btns[stat_key] = minus_btn
		row.add_child(minus_btn)

		var pt_lbl := Label.new()
		pt_lbl.add_theme_font_size_override("font_size", 20)
		pt_lbl.custom_minimum_size = Vector2(40.0, 0.0)
		pt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scene._special_point_labels[stat_key] = pt_lbl
		row.add_child(pt_lbl)

		var plus_btn := Button.new()
		plus_btn.custom_minimum_size = Vector2(44.0, 44.0)
		plus_btn.pressed.connect(Callable(scene, "_on_special_add_pressed").bind(stat_key))
		scene._special_plus_btns[stat_key] = plus_btn
		row.add_child(plus_btn)

	Refresh.refresh_stat_labels(scene, cat_data, player_cat)
	Refresh.refresh_special_cost_label(scene, player_cat)
	Refresh.refresh_special_point_labels(scene, player_cat)
	Refresh.refresh_special_buttons(scene, player_cat)

	scene._detail_panel.add_child(Refresh.make_separator())
	Refresh.build_skill_section(scene, cat_data, player_cat)
	scene._detail_panel.add_child(Refresh.make_separator())

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 16)
	scene._detail_panel.add_child(action_row)

	scene._food_upgrade_btn = Button.new()
	scene._food_upgrade_btn.pressed.connect(scene._on_upgrade_one_pressed)
	scene._food_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(scene._food_upgrade_btn)

	scene._food_max_btn = Button.new()
	scene._food_max_btn.pressed.connect(scene._on_upgrade_max_pressed)
	scene._food_max_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(scene._food_max_btn)

	var reset_btn := Button.new()
	reset_btn.text = "重置"
	reset_btn.pressed.connect(scene._on_reset_pressed)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(reset_btn)

	scene._food_upgrade_btn.custom_minimum_size = Vector2(0, 52.0)
	scene._food_max_btn.custom_minimum_size = Vector2(0, 52.0)
	reset_btn.custom_minimum_size = Vector2(0, 52.0)
	scene._food_upgrade_btn.size_flags_stretch_ratio = 4
	scene._food_max_btn.size_flags_stretch_ratio = 4
	reset_btn.size_flags_stretch_ratio = 2

	scene._food_cost_label = Label.new()
	scene._food_cost_label.add_theme_font_size_override("font_size", 20)
	scene._detail_panel.add_child(scene._food_cost_label)
	Refresh.refresh_food_labels(scene, player_cat)
