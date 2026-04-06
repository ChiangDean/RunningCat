class_name ScooperScene
extends Control

## 鏟屎官主頁面，含四個 Tab：鏟屎官、回憶、寶藏、成就

const SW := 720.0
const SH := 1280.0

var _current_tab: String = "scooper"
var _tab_btns: Dictionary = {}    # tab_key -> Button
var _tab_content: VBoxContainer
var _resource_label: Label

# 鏟屎官 Tab 的動態節點引用（切換 Tab 時會清空）
var _level_label: Label
var _exp_bar: ProgressBar
var _exp_label: Label
var _scoop_button: Button
var _scoop_overlay: ColorRect
var _scoop_cd_label: Label
var _scoop_result_label: Label
const SCOOP_COOLDOWN := 0.5
var _scoop_cooldown_remaining := 0.0
var _ability_list: VBoxContainer
var _equip_list: VBoxContainer  # 裝備列表容器，行動後重建
var _memory_summary_label: Label
var _memory_list: VBoxContainer
var _treasure_summary_label: Label
var _treasure_list: VBoxContainer
var _achievement_summary_label: Label
var _achievement_list: VBoxContainer
var _ability_scroller: InertialScroller
var _equip_scroller: InertialScroller
var _memory_scroller: InertialScroller
var _treasure_scroller: InertialScroller
var _achievement_scroller: InertialScroller
var _achievement_claimed_expanded: bool = false

const TAB_KEYS: Array = ["scooper", "memory", "treasure", "achievement"]
const TAB_DISPLAY: Dictionary = {
	"scooper":     "鏟屎官",
	"memory":      "回憶",
	"treasure":    "寶藏",
	"achievement": "成就",
}

@onready var GameState = get_node("/root/GameState")


func _ready() -> void:
	var achievement_changed_cb := Callable(self, "_on_achievements_changed")
	if not GameState.achievements_changed.is_connected(achievement_changed_cb):
		GameState.achievements_changed.connect(achievement_changed_cb)
	_build_ui()
	set_process(true)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.133, 0.157, 0.192, 1.0)
	bg.size = Vector2(SW, SH)
	add_child(bg)

	var layer := CanvasLayer.new()
	add_child(layer)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 14)
	root_vbox.offset_left   = 20
	root_vbox.offset_top    = 40
	root_vbox.offset_right  = -20
	root_vbox.offset_bottom = -20
	layer.add_child(root_vbox)

	# ── 頂部列：返回 + 標題 ─────────────────────────────────
	var top_row := HBoxContainer.new()
	root_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(100.0, 50.0)
	back_btn.pressed.connect(_on_back_pressed)
	top_row.add_child(back_btn)

	var title := Label.new()
	title.text = "鏟屎官"
	title.add_theme_font_size_override("font_size", 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title)

	# 對稱佔位，讓標題保持置中
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	# ── 資源列 ──────────────────────────────────────────────
	_resource_label = Label.new()
	_resource_label.add_theme_font_size_override("font_size", 20)
	root_vbox.add_child(_resource_label)
	_refresh_resource_label()

	root_vbox.add_child(_make_separator())

	# ── Tab 切換列 ─────────────────────────────────────────
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	root_vbox.add_child(tab_row)

	for tab_key: String in TAB_KEYS:
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 48.0)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(func(): _switch_tab(tab_key))
		tab_row.add_child(btn)
		_tab_btns[tab_key] = btn

	root_vbox.add_child(_make_separator())

	# ── Tab 內容區（佔滿剩餘空間） ─────────────────────────
	_tab_content = VBoxContainer.new()
	_tab_content.add_theme_constant_override("separation", 12)
	_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_tab_content)

	_refresh_tab_button_labels()
	_switch_tab("scooper")


# ── Tab 切換 ───────────────────────────────────────────────

func _switch_tab(tab_key: String) -> void:
	_current_tab = tab_key
	_refresh_tab_button_labels()
	# 選中 Tab 正常亮度，其餘偏暗
	for key: String in _tab_btns:
		var btn: Button = _tab_btns[key]
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if key == tab_key else Color(0.6, 0.6, 0.6, 1.0)
	_rebuild_tab_content()


func _rebuild_tab_content() -> void:
	for child in _tab_content.get_children():
		child.queue_free()
	_level_label = null
	_exp_bar     = null
	_exp_label   = null
	_scoop_button = null
	_scoop_overlay = null
	_scoop_cd_label = null
	_scoop_result_label = null
	_ability_list = null
	_equip_list  = null
	_memory_summary_label = null
	_memory_list = null
	_treasure_summary_label = null
	_treasure_list = null
	_achievement_summary_label = null
	_achievement_list = null
	_ability_scroller = null
	_equip_scroller = null
	_memory_scroller = null
	_treasure_scroller = null
	_achievement_scroller = null

	match _current_tab:
		"scooper":     _build_scooper_tab()
		"memory":      _build_memory_tab()
		"treasure":    _build_treasure_tab()
		"achievement": _build_achievement_tab()


func _refresh_tab_button_labels() -> void:
	var unclaimed_count: int = GameState.get_unclaimed_achievement_count()
	for tab_key: String in _tab_btns.keys():
		var btn: Button = _tab_btns[tab_key]
		if btn == null:
			continue
		btn.text = TAB_DISPLAY[tab_key]
		if tab_key == "achievement" and unclaimed_count > 0:
			btn.text += " ●"


func _on_achievements_changed() -> void:
	_refresh_resource_label()
	_refresh_tab_button_labels()
	if _current_tab == "achievement":
		_refresh_achievement_tab()


# ── 鏟屎官 Tab ─────────────────────────────────────────────

func _build_scooper_tab() -> void:
	# 等級標題
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 32)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(_level_label)

	# EXP 進度條 + 數字標籤（並排）
	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 10)
	_tab_content.add_child(exp_row)

	_exp_bar = ProgressBar.new()
	_exp_bar.min_value = 0
	_exp_bar.show_percentage = false
	_exp_bar.custom_minimum_size = Vector2(0.0, 36.0)
	_exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_row.add_child(_exp_bar)

	_exp_label = Label.new()
	_exp_label.add_theme_font_size_override("font_size", 18)
	_exp_label.custom_minimum_size = Vector2(140.0, 36.0)
	_exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_row.add_child(_exp_label)

	_scoop_button = Button.new()
	_scoop_button.custom_minimum_size = Vector2(0.0, 48.0)
	_scoop_button.add_theme_font_size_override("font_size", 18)
	_scoop_button.pressed.connect(_on_scoop_pressed)
	_tab_content.add_child(_scoop_button)

	_scoop_overlay = ColorRect.new()
	_scoop_overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	_scoop_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scoop_overlay.visible = false
	_scoop_button.add_child(_scoop_overlay)

	_scoop_cd_label = Label.new()
	_scoop_cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scoop_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scoop_cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scoop_cd_label.add_theme_font_size_override("font_size", 18)
	_scoop_cd_label.visible = false
	_scoop_button.add_child(_scoop_cd_label)

	_scoop_result_label = Label.new()
	_scoop_result_label.text = ""
	_scoop_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scoop_result_label.add_theme_font_size_override("font_size", 16)
	_scoop_result_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.7, 1.0))
	_tab_content.add_child(_scoop_result_label)

	_tab_content.add_child(_make_separator())

	# ── 特殊能力 ──────────────────────────────────────
	var ability_title := Label.new()
	ability_title.text = "特殊能力"
	ability_title.add_theme_font_size_override("font_size", 24)
	_tab_content.add_child(ability_title)

	var ability_scroll := ScrollContainer.new()
	ability_scroll.custom_minimum_size = Vector2(0.0, 88.0)
	_tab_content.add_child(ability_scroll)
	_ability_scroller = InertialScroller.attach(ability_scroll, "vertical")

	_ability_list = VBoxContainer.new()
	_ability_list.add_theme_constant_override("separation", 8)
	_ability_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability_scroll.add_child(_ability_list)


	# ── 裝備列表（Phase 3）──────────────────────────────────
	var equip_header := Label.new()
	equip_header.text = "裝備"
	equip_header.add_theme_font_size_override("font_size", 24)
	_tab_content.add_child(equip_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 300.0)
	_tab_content.add_child(scroll)
	_equip_scroller = InertialScroller.attach(scroll, "vertical")

	_equip_list = VBoxContainer.new()
	_equip_list.add_theme_constant_override("separation", 8)
	_equip_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_equip_list)

	_rebuild_equip_list()
	_refresh_scooper_tab()


func _refresh_scooper_tab() -> void:
	var pd        = GameState.player_data
	var level     = pd.scooper_level
	var exp       = pd.scooper_exp
	var threshold := _exp_threshold(level)

	if _level_label != null:
		_level_label.text = "鏟屎官 Lv.%d" % level

	if _exp_bar != null:
		_exp_bar.max_value = threshold
		_exp_bar.value     = exp

	if _exp_label != null:
		_exp_label.text = "EXP %d / %d" % [exp, threshold]

	_refresh_scoop_ui()
	_refresh_ability_ui()


## 從 Lv.N 升至 Lv.N+1 所需的 EXP（每級遞增，公式：(N+1) × base）
func _exp_threshold(level: int) -> int:
	var base: int = int(GameState.idle_config.get("scooper_exp_per_level", 10))
	return (level + 1) * base


# ── 裝備列表 UI ────────────────────────────────────────────

## 清空並重建裝備列表（購買 / 升級 / 修復 / 就醫後呼叫）
func _rebuild_equip_list() -> void:
	if _equip_list == null:
		return
	for child in _equip_list.get_children():
		child.queue_free()

	var items: Array = GameState.equipment_config.get("items", [])
	var scooper_lv: int = GameState.player_data.scooper_level
	var exp_per_lv: int = int(GameState.equipment_config.get("exp_per_level", 10))

	for item: Dictionary in items:
		_equip_list.add_child(_make_equip_card(item, scooper_lv, exp_per_lv))


func _refresh_ability_ui() -> void:
	if _ability_list == null:
		return

	for child in _ability_list.get_children():
		child.queue_free()

	var owned: Array = GameState.get_owned_special_abilities()
	if owned.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "尚未擁有特殊能力"
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		_ability_list.add_child(empty_lbl)
		return

	for item: Dictionary in owned:
		_ability_list.add_child(_make_ability_card(item))

func _make_ability_card(item: Dictionary) -> Control:
	var btn := Button.new()
	btn.text = item.get("name", item.get("id", ""))
	btn.custom_minimum_size = Vector2(0.0, 52.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func() -> void:
		_show_ability_dialog(item)
	)
	return btn


func _show_ability_dialog(item: Dictionary) -> void:
	var lines: Array[String] = [
		"效果：%s" % item.get("description", ""),
	]
	var source_text: String = item.get("source_text", "")
	if source_text != "":
		lines.append("")
		lines.append(source_text)
	DialogManager.show_info(item.get("name", item.get("id", "")), "\n".join(lines))


## 建立單一裝備卡片
func _process(delta: float) -> void:
	if _scoop_cooldown_remaining <= 0.0:
		return
	_scoop_cooldown_remaining = maxf(0.0, _scoop_cooldown_remaining - delta)
	_refresh_scoop_ui()


func _refresh_scoop_ui() -> void:
	if _scoop_button == null:
		return
	var poop_count: int = GameState.player_data.poop_count
	var scoop_amount: int = _get_scoop_amount()
	var cooling_down: bool = _scoop_cooldown_remaining > 0.0

	_scoop_button.text = "🪣 鏟屎(%d/%d)" % [poop_count, scoop_amount]
	_scoop_button.disabled = cooling_down or poop_count <= 0

	if _scoop_overlay != null and _scoop_cd_label != null:
		if cooling_down:
			var button_size := _scoop_button.size
			if button_size.x <= 0.0 or button_size.y <= 0.0:
				button_size = _scoop_button.custom_minimum_size
			var ratio := clampf(_scoop_cooldown_remaining / SCOOP_COOLDOWN, 0.0, 1.0)
			_scoop_overlay.visible = true
			_scoop_overlay.position = Vector2(button_size.x * (1.0 - ratio), 0.0)
			_scoop_overlay.size = Vector2(button_size.x * ratio, button_size.y)
			_scoop_cd_label.visible = false
			_scoop_cd_label.text = "%.1f" % _scoop_cooldown_remaining
			_scoop_cd_label.position = Vector2.ZERO
			_scoop_cd_label.size = button_size
		else:
			_scoop_overlay.visible = false
			_scoop_cd_label.visible = false


func _get_scoop_amount() -> int:
	return 1


func _on_scoop_pressed() -> void:
	if _scoop_cooldown_remaining > 0.0 or GameState.player_data.poop_count <= 0:
		return

	var scoop_count := mini(GameState.player_data.poop_count, _get_scoop_amount())
	var total_exp := 0
	var total_memory := 0
	var total_whiskers := 0

	for _i in range(scoop_count):
		var result = GameState.scoop_poop()
		total_exp += int(result.get("exp", 0))
		total_memory += int(result.get("memory_shards", 0))
		total_whiskers += int(result.get("whiskers", 0))

	if _scoop_result_label != null:
		_scoop_result_label.text = _format_scoop_result({
			"exp": total_exp,
			"memory_shards": total_memory,
			"whiskers": total_whiskers,
		})

	_scoop_cooldown_remaining = SCOOP_COOLDOWN
	_refresh_resource_label()
	_refresh_scooper_tab()


func _format_scoop_result(result: Dictionary) -> String:
	if result.is_empty():
		return "目前沒有可鏟的屎堆"

	var parts: Array[String] = []
	if result.get("exp", 0) > 0:
		parts.append("EXP +%d" % result["exp"])
	if result.get("memory_shards", 0) > 0:
		parts.append("回憶碎片 +%d" % result["memory_shards"])
	if result.get("whiskers", 0) > 0:
		parts.append("鬍鬚 +%d" % result["whiskers"])
	return "這次沒有掉落額外獎勵" if parts.is_empty() else "獲得：" + "、".join(parts)


func _make_equip_card(item: Dictionary, scooper_lv: int, exp_per_lv: int) -> Control:
	var equip_id: String  = item.get("id",   "")
	var name_str: String  = item.get("name", equip_id)
	var unlock_lv: int    = item.get("unlock_level", 1)
	var owned: bool       = GameState.is_equipment_owned(equip_id)
	var state: Dictionary = GameState.player_data.equipments.get(equip_id, {})
	var level: int        = state.get("level", 0)
	var exp: int          = state.get("exp",   0)
	var broken: bool      = state.get("broken", false)
	var sick_cat_id: String = state.get("sick_cat_id", "")
	var locked: bool      = not owned and scooper_lv < unlock_lv

	# 背景容器
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)
	var card_bg := ColorRect.new()
	card_bg.color = Color(0.18, 0.20, 0.25, 1.0) if owned else Color(0.14, 0.15, 0.18, 1.0)
	card_bg.custom_minimum_size = Vector2(0.0, 4.0)
	card.add_child(card_bg)

	# ── 標題行：名稱 + 等級 ──
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
	elif sick_cat_id != "":
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

	# ── 說明行：加成描述 / 鎖定提示 / 狀態 ──
	var desc_lbl := Label.new()
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	if locked:
		desc_lbl.text = "解鎖需要鏟屎官 Lv.%d　%s" % [unlock_lv, _bonus_desc(item, 0)]
	elif broken:
		desc_lbl.text = "損壞中，加成暫停　EXP %d / %d" % [exp, exp_per_lv]
	elif sick_cat_id != "":
		desc_lbl.text = "🐱 %s 生病中，無法升級　%s" % [sick_cat_id, _bonus_desc(item, level)]
	elif owned:
		var exp_str: String = "  EXP %d / %d" % [exp, exp_per_lv] if level < scooper_lv else "  已滿等"
		desc_lbl.text = _bonus_desc(item, level) + exp_str
	else:
		desc_lbl.text = "%s　購買後解鎖" % _bonus_desc(item, 1)
	card.add_child(desc_lbl)

	# ── 操作按鈕行 ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	card.add_child(btn_row)

	if locked:
		pass  # 無按鈕
	elif not owned:
		# 購買按鈕
		var buy_btn := Button.new()
		buy_btn.text = "購買 %d 💰" % item.get("buy_cost", 0)
		buy_btn.custom_minimum_size = Vector2(160.0, 42.0)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.pressed.connect(func() -> void:
			var err = GameState.buy_equipment(equip_id)
			if err != "":
				DialogManager.show_info("購買失敗", err)
			else:
				_refresh_resource_label()
				_rebuild_equip_list()
		)
		btn_row.add_child(buy_btn)
	else:
		if broken:
			# 修復按鈕
			var repair_btn := Button.new()
			repair_btn.text = "修復 %d 💰" % item.get("repair_cost", 0)
			repair_btn.custom_minimum_size = Vector2(160.0, 42.0)
			repair_btn.add_theme_font_size_override("font_size", 16)
			repair_btn.pressed.connect(func() -> void:
				var err = GameState.repair_equipment(equip_id)
				if err != "":
					DialogManager.show_info("修復失敗", err)
				else:
					_refresh_resource_label()
					_rebuild_equip_list()
			)
			btn_row.add_child(repair_btn)
		else:
			if sick_cat_id != "":
				# 就醫按鈕
				var heal_btn := Button.new()
				heal_btn.text = "就醫 %d 💰" % item.get("heal_cost", 0)
				heal_btn.custom_minimum_size = Vector2(160.0, 42.0)
				heal_btn.add_theme_font_size_override("font_size", 16)
				heal_btn.pressed.connect(func() -> void:
					var err = GameState.heal_sick_cat(equip_id)
					if err != "":
						DialogManager.show_info("就醫失敗", err)
					else:
						_refresh_resource_label()
						_rebuild_equip_list()
				)
				btn_row.add_child(heal_btn)

			# 升級按鈕（生病時 disabled）
			var up_btn := Button.new()
			up_btn.text = "升級 %d 💰" % item.get("upgrade_cost", 0)
			up_btn.custom_minimum_size = Vector2(160.0, 42.0)
			up_btn.add_theme_font_size_override("font_size", 16)
			up_btn.disabled = sick_cat_id != "" or level >= scooper_lv
			up_btn.pressed.connect(func() -> void:
				var result = GameState.upgrade_equipment(equip_id)
				if not result.get("success", false):
					DialogManager.show_info("升級失敗", result.get("error", ""))
				else:
					_refresh_resource_label()
					_rebuild_equip_list()
					var msg_parts: Array = []
					var gained: int = result.get("exp", 0)
					msg_parts.append("獲得 EXP +%d" % gained)
					if result.get("leveled_up", false):
						msg_parts.append("裝備升級！")
					if result.get("broken", false):
						msg_parts.append("⚠ 裝備損壞了！")
					if result.get("sick_cat_id", "") != "":
						msg_parts.append("🤒 %s 生病了！" % result["sick_cat_id"])
					DialogManager.show_info("升級結果", "\n".join(msg_parts))
			)
			btn_row.add_child(up_btn)

	# 分隔線
	card.add_child(_make_separator())
	return card


## 產生加成描述文字，level=0 時顯示「每級 +X%」
func _bonus_desc(item: Dictionary, level: int) -> String:
	var stat: String   = item.get("bonus_stat",    "")
	var target: String = item.get("bonus_target",  "all")
	var per_lv: float  = float(item.get("bonus_per_level", 0.0))

	var target_str: String = "全隊" if target == "all" else "%s系" % target
	var stat_str: String
	match stat:
		"atk_percent":    stat_str = "ATK"
		"def_percent":    stat_str = "DEF"
		"max_hp_percent": stat_str = "HP"
		_:                stat_str = stat

	if level <= 0:
		return "%s %s +%.1f%%/級" % [target_str, stat_str, per_lv * 100.0]
	else:
		return "%s %s +%.1f%%" % [target_str, stat_str, per_lv * level * 100.0]


# ── 回憶 Tab ───────────────────────────────────────────────

func _build_memory_tab() -> void:
	var title := Label.new()
	title.text = "回憶收藏"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(title)

	_memory_summary_label = Label.new()
	_memory_summary_label.add_theme_font_size_override("font_size", 18)
	_memory_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(_memory_summary_label)

	var hint := Label.new()
	hint.text = "回憶碎片足夠時，可自由選擇要解鎖哪一張回憶。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(hint)

	_tab_content.add_child(_make_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_content.add_child(scroll)
	_memory_scroller = InertialScroller.attach(scroll, "vertical")

	_memory_list = VBoxContainer.new()
	_memory_list.add_theme_constant_override("separation", 12)
	_memory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_memory_list)

	_refresh_memory_tab()


func _refresh_memory_tab() -> void:
	if _memory_summary_label != null:
		var total: int = GameState.get_all_memories().size()
		var unlocked: int = GameState.player_data.unlocked_memory_ids.size()
		_memory_summary_label.text = "回憶碎片：%d　已解鎖：%d / %d" % [
			GameState.player_data.memory_shards,
			unlocked,
			total,
		]

	if _memory_list == null:
		return

	for child in _memory_list.get_children():
		child.queue_free()

	var items: Array = GameState.get_all_memories()
	if items.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "目前沒有可展示的回憶"
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_memory_list.add_child(empty_lbl)
		return

	for item: Dictionary in items:
		_memory_list.add_child(_make_memory_card(item))


func _make_memory_card(item: Dictionary) -> Control:
	var memory_id: String = item.get("id", "")
	var unlocked: bool = GameState.is_memory_unlocked(memory_id)
	var cost: int = int(item.get("unlock_cost", 0))
	var can_unlock: bool = not unlocked and GameState.player_data.memory_shards >= cost
	var accent := _get_memory_placeholder_color(item)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = accent if unlocked else Color(0.25, 0.27, 0.31, 1.0)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", panel_style)

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
	title.text = item.get("name", memory_id)
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not unlocked:
		title.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1.0))
	header.add_child(title)

	var state := Label.new()
	state.text = "已解鎖" if unlocked else "未解鎖"
	state.add_theme_font_size_override("font_size", 16)
	state.add_theme_color_override("font_color", accent if unlocked else Color(0.75, 0.75, 0.75, 1.0))
	header.add_child(state)

	var preview := Control.new()
	preview.custom_minimum_size = Vector2(0.0, 170.0)
	card.add_child(preview)

	var preview_bg := ColorRect.new()
	preview_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_bg.color = accent
	preview.add_child(preview_bg)

	var photo_path: String = item.get("photo_path", "")
	if photo_path != "" and ResourceLoader.exists(photo_path):
		var texture := load(photo_path)
		if texture is Texture2D:
			var photo := TextureRect.new()
			photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			photo.texture = texture
			photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			preview.add_child(photo)

	var preview_text := Label.new()
	preview_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_text.add_theme_font_size_override("font_size", 28)
	preview_text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	preview_text.text = item.get("name", memory_id) if unlocked else "LOCKED"
	preview.add_child(preview_text)

	if not unlocked:
		var overlay := ColorRect.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.color = Color(0.0, 0.0, 0.0, 0.62)
		preview.add_child(overlay)

		var lock_lbl := Label.new()
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 26)
		lock_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		lock_lbl.text = "🔒"
		preview.add_child(lock_lbl)

	var desc := Label.new()
	desc.text = item.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	card.add_child(desc)

	var bonus := Label.new()
	bonus.text = _memory_bonus_desc(item)
	bonus.add_theme_font_size_override("font_size", 17)
	bonus.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0, 1.0))
	card.add_child(bonus)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	card.add_child(action_row)

	var detail_btn := Button.new()
	detail_btn.text = "查看詳情"
	detail_btn.custom_minimum_size = Vector2(130.0, 42.0)
	detail_btn.pressed.connect(func() -> void:
		_show_memory_dialog(item, unlocked)
	)
	action_row.add_child(detail_btn)

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(190.0, 42.0)
	action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(action_btn)

	if unlocked:
		action_btn.text = "已收藏"
		action_btn.disabled = true
	elif can_unlock:
		action_btn.text = "消耗 %d 碎片解鎖" % cost
		action_btn.pressed.connect(func() -> void:
			_confirm_unlock_memory(memory_id)
		)
	else:
		action_btn.text = "需要 %d 碎片" % cost
		action_btn.disabled = true

	return panel


func _show_memory_dialog(item: Dictionary, unlocked: bool) -> void:
	var lines: Array[String] = [
		item.get("description", ""),
		"",
		"效果：%s" % _memory_bonus_desc(item),
		"解鎖需求：回憶碎片 %d" % int(item.get("unlock_cost", 0)),
		"目前狀態：%s" % ("已解鎖" if unlocked else "未解鎖"),
	]
	DialogManager.show_info(item.get("name", item.get("id", "")), "\n".join(lines))


func _confirm_unlock_memory(memory_id: String) -> void:
	var memory= GameState.get_memory_item(memory_id)
	if memory.is_empty():
		DialogManager.show_info("解鎖失敗", "找不到回憶")
		return
	var cost: int = int(memory.get("unlock_cost", 0))
	DialogManager.show_confirm(
		"解鎖回憶",
		"要消耗 %d 個回憶碎片解鎖「%s」嗎？\n\n%s" % [
			cost,
			memory.get("name", memory_id),
			_memory_bonus_desc(memory),
		],
		func() -> void:
			var result = GameState.unlock_memory(memory_id)
			if not result.get("success", false):
				DialogManager.show_info("解鎖失敗", result.get("error", ""))
				return
			_refresh_memory_tab()
			DialogManager.show_info(
				"解鎖成功",
				"已解鎖「%s」\n%s" % [
					memory.get("name", memory_id),
					_memory_bonus_desc(memory),
				]
			)
	)


func _memory_bonus_desc(item: Dictionary) -> String:
	var target: String = item.get("bonus_target", "all")
	var stat: String = item.get("bonus_stat", "")
	var value: float = float(item.get("bonus_value", 0.0))
	var target_str: String = "全隊" if target == "all" else "%s系" % target
	var stat_str: String
	match stat:
		"atk_percent":
			stat_str = "ATK"
		"def_percent":
			stat_str = "DEF"
		"max_hp_percent":
			stat_str = "HP"
		_:
			stat_str = stat
	return "%s %s +%.1f%%" % [target_str, stat_str, value * 100.0]


func _get_memory_placeholder_color(item: Dictionary) -> Color:
	var raw_color: String = item.get("placeholder_color", "#6B7280")
	return Color.from_string(raw_color, Color(0.42, 0.45, 0.5, 1.0))


# ── 寶藏 Tab ───────────────────────────────────────────────

func _build_treasure_tab() -> void:
	var title := Label.new()
	title.text = "寶藏收藏"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(title)

	_treasure_summary_label = Label.new()
	_treasure_summary_label.add_theme_font_size_override("font_size", 18)
	_treasure_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(_treasure_summary_label)

	var hint := Label.new()
	hint.text = "商城禮包取得的寶藏會直接納入收藏，重複取得會重複生效。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(hint)

	_tab_content.add_child(_make_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_content.add_child(scroll)
	_treasure_scroller = InertialScroller.attach(scroll, "vertical")

	_treasure_list = VBoxContainer.new()
	_treasure_list.add_theme_constant_override("separation", 12)
	_treasure_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_treasure_list)

	_refresh_treasure_tab()


func _refresh_treasure_tab() -> void:
	if _treasure_summary_label != null:
		var owned: Array = GameState.get_owned_treasures()
		var total_types: int = owned.size()
		var total_quantity := 0
		for item: Dictionary in owned:
			total_quantity += int(item.get("quantity", 0))
		_treasure_summary_label.text = "已收藏：%d 種　總持有：%d 件" % [total_types, total_quantity]

	if _treasure_list == null:
		return

	for child in _treasure_list.get_children():
		child.queue_free()

	var treasures: Array = GameState.get_owned_treasures()
	if treasures.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "目前還沒有收藏到任何寶藏"
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_treasure_list.add_child(empty_lbl)
		return

	for item: Dictionary in treasures:
		_treasure_list.add_child(_make_treasure_card(item))


func _make_treasure_card(item: Dictionary) -> Control:
	var accent := _get_treasure_placeholder_color(item)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = accent
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
	card.add_theme_constant_override("separation", 8)
	margin.add_child(card)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	card.add_child(header)

	var title := Label.new()
	title.text = item.get("name", item.get("id", ""))
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var qty := Label.new()
	qty.text = "x%d" % int(item.get("quantity", 0))
	qty.add_theme_font_size_override("font_size", 18)
	qty.add_theme_color_override("font_color", accent)
	header.add_child(qty)

	var desc := Label.new()
	desc.text = item.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1.0))
	card.add_child(desc)

	var source := Label.new()
	source.text = item.get("source_text", "")
	source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source.add_theme_font_size_override("font_size", 15)
	source.add_theme_color_override("font_color", Color(0.74, 0.82, 0.92, 1.0))
	card.add_child(source)

	var time_lbl := Label.new()
	time_lbl.text = "最近取得：%s" % item.get("latest_obtained_at", "-")
	time_lbl.add_theme_font_size_override("font_size", 15)
	time_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	card.add_child(time_lbl)

	var bonus := Label.new()
	bonus.text = _treasure_bonus_desc(item)
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus.add_theme_font_size_override("font_size", 17)
	bonus.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0, 1.0))
	card.add_child(bonus)

	return panel


func _treasure_bonus_desc(item: Dictionary) -> String:
	var lines: Array[String] = []
	for effect: Dictionary in item.get("effects", []):
		lines.append(_format_treasure_effect(effect))
	return "\n".join(lines)


func _format_treasure_effect(effect: Dictionary) -> String:
	var target: String = effect.get("target", "all")
	var target_str: String = "全隊" if target == "all" else "%s系" % target
	var stat: String = effect.get("stat", "")
	var value: float = float(effect.get("value", 0.0))
	match stat:
		"atk_percent":
			return "%s ATK +%.1f%%" % [target_str, value * 100.0]
		"def_percent":
			return "%s DEF +%.1f%%" % [target_str, value * 100.0]
		"max_hp_percent":
			return "%s HP +%.1f%%" % [target_str, value * 100.0]
		"crit_rate":
			return "%s 暴擊率 +%.1f%%" % [target_str, value * 100.0]
		"crit_damage":
			return "%s 暴擊傷害 +%.1f%%" % [target_str, value * 100.0]
		"damage_reduction":
			return "%s 減傷 +%.1f%%" % [target_str, value * 100.0]
		"cooldown_reduction":
			return "%s 技能 CD -%.1f%%" % [target_str, value * 100.0]
		"idle_poop_percent":
			return "掛機屎堆 +%.1f%%" % [value * 100.0]
		_:
			return "%s %s %.2f" % [target_str, stat, value]


func _get_treasure_placeholder_color(item: Dictionary) -> Color:
	var raw_color: String = item.get("placeholder_color", "#6B7280")
	return Color.from_string(raw_color, Color(0.42, 0.45, 0.5, 1.0))


# ── 成就 Tab ───────────────────────────────────────────────

func _build_achievement_tab() -> void:
	var title := Label.new()
	title.text = "成就"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(title)

	_achievement_summary_label = Label.new()
	_achievement_summary_label.add_theme_font_size_override("font_size", 18)
	_achievement_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(_achievement_summary_label)

	var hint := Label.new()
	hint.text = "成就達成後需手動領取。已領取成就會收納到最下方的收合區。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(hint)

	_tab_content.add_child(_make_separator())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_content.add_child(scroll)
	_achievement_scroller = InertialScroller.attach(scroll, "vertical")

	_achievement_list = VBoxContainer.new()
	_achievement_list.add_theme_constant_override("separation", 12)
	_achievement_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_achievement_list)

	_refresh_achievement_tab()


func _refresh_achievement_tab() -> void:
	var groups = GameState.get_achievement_display_groups()
	if _achievement_summary_label != null:
		_achievement_summary_label.text = "可領取：%d　已完成：%d / %d" % [
			int(groups.get("claimable_count", 0)),
			int(groups.get("completed_count", 0)),
			int(groups.get("total_count", 0)),
		]

	if _achievement_list == null:
		return

	for child in _achievement_list.get_children():
		child.queue_free()

	_add_claimed_achievement_section(groups.get("claimed", []))
	_achievement_list.add_child(_make_separator())
	_add_achievement_section(
		"成就列表",
		groups.get("active", []),
		"目前沒有可顯示的未領取成就"
	)


func _add_achievement_section(title_text: String, entries: Array, empty_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 1.0))
	_achievement_list.add_child(title)

	if entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = empty_text
		empty_lbl.add_theme_font_size_override("font_size", 17)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
		_achievement_list.add_child(empty_lbl)
		return

	for entry: Dictionary in entries:
		_achievement_list.add_child(_make_achievement_card(entry))


func _add_claimed_achievement_section(entries: Array) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	_achievement_list.add_child(header)

	var title := Label.new()
	title.text = "已領取"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var count_lbl := Label.new()
	count_lbl.text = "%d 項" % entries.size()
	count_lbl.add_theme_font_size_override("font_size", 18)
	count_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	header.add_child(count_lbl)

	var toggle_btn := Button.new()
	toggle_btn.text = "收合" if _achievement_claimed_expanded else "展開"
	toggle_btn.custom_minimum_size = Vector2(100.0, 38.0)
	toggle_btn.pressed.connect(func() -> void:
		_achievement_claimed_expanded = not _achievement_claimed_expanded
		_refresh_achievement_tab()
	)
	header.add_child(toggle_btn)

	if not _achievement_claimed_expanded:
		var collapsed_lbl := Label.new()
		collapsed_lbl.text = "已領取成就預設收合，避免干擾目前可操作項目。"
		collapsed_lbl.add_theme_font_size_override("font_size", 16)
		collapsed_lbl.add_theme_color_override("font_color", Color(0.58, 0.58, 0.58, 1.0))
		collapsed_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_achievement_list.add_child(collapsed_lbl)
		return

	if entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "目前還沒有已領取的成就"
		empty_lbl.add_theme_font_size_override("font_size", 17)
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
		_achievement_list.add_child(empty_lbl)
		return

	for entry: Dictionary in entries:
		_achievement_list.add_child(_make_achievement_card(entry))


func _make_achievement_card(entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_color = _achievement_border_color(entry)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	margin.add_child(card)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	card.add_child(header)

	var name_lbl := Label.new()
	name_lbl.text = entry.get("name", entry.get("id", ""))
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)

	var state_lbl := Label.new()
	state_lbl.text = _achievement_state_text(entry)
	state_lbl.add_theme_font_size_override("font_size", 16)
	state_lbl.add_theme_color_override("font_color", _achievement_border_color(entry))
	header.add_child(state_lbl)

	var condition_lbl := Label.new()
	condition_lbl.text = entry.get("condition_text", "")
	condition_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	condition_lbl.add_theme_font_size_override("font_size", 16)
	condition_lbl.add_theme_color_override("font_color", Color(0.84, 0.84, 0.84, 1.0))
	card.add_child(condition_lbl)

	var progress_lbl := Label.new()
	progress_lbl.text = _achievement_progress_text(entry)
	progress_lbl.add_theme_font_size_override("font_size", 16)
	progress_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95, 1.0))
	card.add_child(progress_lbl)

	var reward_lbl := Label.new()
	reward_lbl.text = "獎勵：%s" % entry.get("reward_text", "")
	reward_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_lbl.add_theme_font_size_override("font_size", 17)
	reward_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.66, 1.0))
	card.add_child(reward_lbl)

	if bool(entry.get("completed", false)):
		var time_lbl := Label.new()
		time_lbl.text = "完成時間：%s" % entry.get("completed_at", "-")
		if bool(entry.get("claimed", false)):
			time_lbl.text += "　領取時間：%s" % entry.get("claimed_at", "-")
		time_lbl.add_theme_font_size_override("font_size", 15)
		time_lbl.add_theme_color_override("font_color", Color(0.66, 0.66, 0.66, 1.0))
		card.add_child(time_lbl)

	var action_btn := Button.new()
	action_btn.custom_minimum_size = Vector2(0.0, 42.0)
	action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(action_btn)

	if bool(entry.get("claimable", false)):
		action_btn.text = "領取獎勵"
		action_btn.pressed.connect(Callable(self, "_claim_achievement").bind(String(entry.get("id", ""))))
	elif bool(entry.get("claimed", false)):
		action_btn.text = "已領取"
		action_btn.disabled = true
	else:
		action_btn.text = "尚未達成"
		action_btn.disabled = true

	return panel


func _claim_achievement(achievement_id: String) -> void:
	var result: Dictionary = GameState.claim_achievement(achievement_id)
	if not result.get("success", false):
		DialogManager.show_info("領取失敗", result.get("error", ""))
		return
	var lines: Array[String] = []
	for grant: Dictionary in result.get("granted", []):
		lines.append("• %s" % grant.get("text", ""))
	var achievement_name: String = result.get("achievement", {}).get("name", achievement_id)
	if lines.is_empty():
		lines.append("• 已成功發放獎勵")
	DialogManager.show_info(
		"領取成功",
		"已領取「%s」\n\n%s" % [
			achievement_name,
			"\n".join(lines),
		]
	)


func _achievement_border_color(entry: Dictionary) -> Color:
	if bool(entry.get("claimed", false)):
		return Color(0.48, 0.48, 0.48, 1.0)
	if bool(entry.get("claimable", false)):
		return Color(0.94, 0.78, 0.36, 1.0)
	return Color(0.28, 0.3, 0.34, 1.0)


func _achievement_state_text(entry: Dictionary) -> String:
	if bool(entry.get("claimed", false)):
		return "已領取"
	if bool(entry.get("claimable", false)):
		return "可領取"
	return "未達成"


func _achievement_progress_text(entry: Dictionary) -> String:
	if bool(entry.get("claimable", false)):
		return "進度：已達成"
	if bool(entry.get("claimed", false)):
		return "進度：已領取"
	return entry.get("progress_text", "")


# ── 資源列更新 ─────────────────────────────────────────────

func _refresh_resource_label() -> void:
	_resource_label.text = "💰 金幣：%d　💩 屎堆：%d" % [
		GameState.player_data.gold,
		GameState.player_data.poop_count,
	]


# ── 輔助 ───────────────────────────────────────────────────

func _make_separator() -> HSeparator:
	return HSeparator.new()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
