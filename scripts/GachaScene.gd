extends Control

## 誘捕籠頁面：顯示技術等級、執行抽獎、顯示結果

const SW := 720.0
const SH := 1280.0

var _info_label: Label
var _diamond_label: Label
var _free_btn: Button
var _cage_btn: Button
var _pull_buttons: Dictionary = {}

const PACK_CAGE_COSTS := {1: 1, 11: 10, 35: 30}


func _ready() -> void:
	_build_ui()
	_refresh_info()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 16)
	root_vbox.offset_left   = 20
	root_vbox.offset_top    = 40
	root_vbox.offset_right  = -20
	root_vbox.offset_bottom = -20
	layer.add_child(root_vbox)

	# 頂部列
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "誘捕籠"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	# 技術等級資訊
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 22)
	root_vbox.add_child(_info_label)

	# 鑽石數量
	_diamond_label = Label.new()
	_diamond_label.add_theme_font_size_override("font_size", 22)
	root_vbox.add_child(_diamond_label)

	root_vbox.add_child(_make_separator())

	# 一般誘捕按鈕群
	var pull_title := Label.new()
	pull_title.text = "誘捕"
	pull_title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(pull_title)

	var pull_row := HBoxContainer.new()
	pull_row.add_theme_constant_override("separation", 12)
	root_vbox.add_child(pull_row)

	for pull_pack: Array in [[1, 100], [11, 1000], [35, 3000]]:
		var cnt: int  = pull_pack[0]
		var cost: int = pull_pack[1]
		var btn := Button.new()
		# 文字會在 _refresh_info 中更新為 "誘捕x{count}({owned}/{required})"
		btn.text = "誘捕x%d" % [cnt]
		btn.custom_minimum_size = Vector2(0.0, 80.0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(func(): _on_pull_pressed(cnt, cost))
		_pull_buttons[cnt] = btn
		pull_row.add_child(btn)

	root_vbox.add_child(_make_separator())

	# 每日免費誘捕
	_free_btn = Button.new()
	_free_btn.custom_minimum_size = Vector2(0.0, 70.0)
	_free_btn.add_theme_font_size_override("font_size", 24)
	_free_btn.pressed.connect(_on_free_pull_pressed)
	root_vbox.add_child(_free_btn)

	# 使用誘捕籠道具
	_cage_btn = Button.new()
	_cage_btn.custom_minimum_size = Vector2(0.0, 70.0)
	_cage_btn.add_theme_font_size_override("font_size", 24)
	_cage_btn.pressed.connect(_on_cage_pull_pressed)
	root_vbox.add_child(_cage_btn)

	# 特別誘捕（待開放）
	var special_btn := Button.new()
	special_btn.text = "特別誘捕  🔒 待開放"
	special_btn.custom_minimum_size = Vector2(0.0, 70.0)
	special_btn.add_theme_font_size_override("font_size", 22)
	special_btn.disabled = true
	special_btn.modulate = Color(0.6, 0.6, 0.6, 1.0)
	root_vbox.add_child(special_btn)

	root_vbox.add_child(_make_separator())

	# (結果改為彈窗顯示，移除場景內結果區域)


# ── 抽獎 ───────────────────────────────────────────────

func _on_pull_pressed(count: int, cost: int) -> void:
	var available_cages: int = GameState.player_data.trap_cages
	var required_cages: int = int(PACK_CAGE_COSTS.get(count, count))
	# 足夠誘捕籠：直接使用對應的誘捕籠數量
	if available_cages >= required_cages:
		GameState.player_data.trap_cages -= required_cages
		GameState.save_all()
		_execute_pulls(count)
		return

	# 部分誘捕籠：使用現有誘捕籠，並以鑽石補足剩餘抽數
	if available_cages > 0:
		var used_cages := available_cages
		var remaining_draws: int = count - used_cages
		var diamond_needed: int = GachaSystem.cost_for_count(remaining_draws)
		var msg: String = "誘捕籠不足：您有 %d 個誘捕籠，是否使用它們並以 %d 鑽石補足剩下 %d 抽？" % [used_cages, diamond_needed, remaining_draws]
		DialogManager.show_confirm("補足抽卡", msg, func() -> void:
			if GameState.player_data.diamonds >= diamond_needed:
				GameState.player_data.trap_cages -= used_cages
				GameState.player_data.diamonds -= diamond_needed
				GameState.save_all()
				_execute_pulls(count)
			else:
				DialogManager.show_confirm("鑽石不足", "鑽石不足，是否前往商店頁面購買？", func() -> void:
					get_tree().change_scene_to_file("res://scenes/ShopScene.tscn")
				)
		)
		return

	# 無誘捕籠：詢問是否以鑽石直接誘捕
	var diamond_needed: int = GachaSystem.cost_for_count(count)
	DialogManager.show_confirm("使用鑽石？", "是否直接使用 %d 鑽石誘捕 %d 次貓咪？" % [diamond_needed, count], func() -> void:
		if GameState.player_data.diamonds >= diamond_needed:
			GameState.player_data.diamonds -= diamond_needed
			GameState.save_all()
			_execute_pulls(count)
		else:
			DialogManager.show_confirm("鑽石不足", "鑽石不足，是否前往商店頁面購買？", func() -> void:
				get_tree().change_scene_to_file("res://scenes/ShopScene.tscn")
			)
	)


func _on_free_pull_pressed() -> void:
	if GameState.player_data.has_used_free_pull_today():
		_show_message("今日免費誘捕已使用，明天再來！")
		return
	var count: int = GameState.player_data.free_pull_count
	GameState.player_data.consume_free_pull(GachaSystem.free_pull_cap())
	_execute_pulls(count)


func _on_cage_pull_pressed() -> void:
	if GameState.player_data.trap_cages <= 0:
		_show_message("沒有誘捕籠道具！")
		return
	GameState.player_data.trap_cages -= 1
	_execute_pulls(1)


func _execute_pulls(count: int) -> void:
	var results := GachaSystem.perform_pulls(count)
	GameState.save_all()
	_show_results(results)
	_refresh_info()


# ── 結果顯示 ───────────────────────────────────────────

func _show_results(results: Array) -> void:
	# 使用彈窗顯示抽取結果，內容可滑動
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500.0, 520.0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	for r: Dictionary in results:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		vbox.add_child(row)

		var color_box := ColorRect.new()
		color_box.custom_minimum_size = Vector2(16.0, 44.0)
		var hex: String = r.get("rarity_color", "#FFFFFF")
		color_box.color = Color.html(hex)
		row.add_child(color_box)

		var rarity_lbl := Label.new()
		rarity_lbl.text = "[%s]" % r.get("rarity_name", "")
		rarity_lbl.add_theme_font_size_override("font_size", 20)
		rarity_lbl.custom_minimum_size = Vector2(80.0, 0.0)
		var rarity_color := Color.html(r.get("rarity_color", "#FFFFFF"))
		rarity_lbl.add_theme_color_override("font_color", rarity_color)
		row.add_child(rarity_lbl)

		var name_lbl := Label.new()
		name_lbl.text = r.get("display_name", r.get("cat_id", ""))
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var status_lbl := Label.new()
		status_lbl.add_theme_font_size_override("font_size", 20)
		if r.get("is_new", false):
			status_lbl.text = "NEW ✨"
			status_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
		else:
			var shards: int = r.get("shards_given", 0)
			status_lbl.text = "碎片 +%d" % shards
			status_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5, 1.0))
		row.add_child(status_lbl)

	# show_info_node 支援點擊 overlay 或右上 ✕ 關閉
	DialogManager.show_info_node("抽取結果", scroll)


# ── 刷新顯示 ───────────────────────────────────────────

func _refresh_info() -> void:
	var lv: int = GachaSystem.get_technique_level()
	var total: int = GameState.player_data.total_pulls
	var next: int = GachaSystem.get_next_level_threshold()
	var next_str := "（已滿等）" if next == -1 else "（距下一等級 %d 抽）" % (next - total)
	_info_label.text = "誘捕技術：Lv.%d　累計 %d 抽 %s" % [lv, total, next_str]
	var cage_count_top: int = GameState.player_data.trap_cages
	_diamond_label.text = "誘捕籠：%d　💎 鑽石：%d" % [cage_count_top, GameState.player_data.diamonds]

	# 更新抽卡按鈕文字，顯示擁有 / 需求誘捕籠
	for cnt_key in _pull_buttons.keys():
		var btn: Button = _pull_buttons[cnt_key]
		var required: int = int(PACK_CAGE_COSTS.get(cnt_key, cnt_key))
		btn.text = "誘捕x%d(%d/%d)" % [int(cnt_key), cage_count_top, required]

	var free_count: int = GameState.player_data.free_pull_count
	if GameState.player_data.has_used_free_pull_today():
		_free_btn.text = "每日免費誘捕（今日已使用）"
		_free_btn.disabled = true
		_free_btn.modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		_free_btn.text = "每日免費誘捕（今日 %d 抽）" % free_count
		_free_btn.disabled = false
		_free_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var cage_count: int = GameState.player_data.trap_cages
	if cage_count > 0:
		_cage_btn.text = "使用誘捕籠道具（持有 %d 個）" % cage_count
		_cage_btn.disabled = false
		_cage_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		_cage_btn.text = "使用誘捕籠道具（持有 0 個）"
		_cage_btn.disabled = true
		_cage_btn.modulate = Color(0.6, 0.6, 0.6, 1.0)


func _show_message(msg: String) -> void:
	DialogManager.show_info("提示", msg)


func _make_separator() -> HSeparator:
	return HSeparator.new()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ShopScene.tscn")
