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
var _equip_list: VBoxContainer  # 裝備列表容器，行動後重建

const TAB_KEYS: Array = ["scooper", "memory", "treasure", "achievement"]
const TAB_DISPLAY: Dictionary = {
	"scooper":     "鏟屎官",
	"memory":      "回憶",
	"treasure":    "寶藏",
	"achievement": "成就",
}

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
		btn.text = TAB_DISPLAY[tab_key]
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

	_switch_tab("scooper")


# ── Tab 切換 ───────────────────────────────────────────────

func _switch_tab(tab_key: String) -> void:
	_current_tab = tab_key
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
	_equip_list  = null

	match _current_tab:
		"scooper":     _build_scooper_tab()
		"memory":      _build_placeholder_tab("回憶",   "回憶系統（Phase 5 開發中）")
		"treasure":    _build_placeholder_tab("寶藏",   "寶藏系統（Phase 6 開發中）")
		"achievement": _build_placeholder_tab("成就",   "成就系統（Phase 7 開發中）")


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

	_tab_content.add_child(_make_separator())

	# ── 特殊能力（占位，Phase 4 實作） ──────────────────────
	var ability_title := Label.new()
	ability_title.text = "特殊能力"
	ability_title.add_theme_font_size_override("font_size", 24)
	_tab_content.add_child(ability_title)

	var ability_ph := Label.new()
	ability_ph.text = "（特殊能力系統 Phase 4 開發中）"
	ability_ph.add_theme_font_size_override("font_size", 18)
	ability_ph.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	_tab_content.add_child(ability_ph)

	_tab_content.add_child(_make_separator())

	# ── 裝備列表（Phase 3）──────────────────────────────────
	var equip_header := Label.new()
	equip_header.text = "裝備"
	equip_header.add_theme_font_size_override("font_size", 24)
	_tab_content.add_child(equip_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 300.0)
	_tab_content.add_child(scroll)

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


## 建立單一裝備卡片
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


# ── 占位 Tab（回憶 / 寶藏 / 成就） ────────────────────────

func _build_placeholder_tab(title_text: String, desc: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(title)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 20.0)
	_tab_content.add_child(gap)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_content.add_child(desc_lbl)


# ── 資源列更新 ─────────────────────────────────────────────

func _refresh_resource_label() -> void:
	_resource_label.text = "💰 金幣：%d　💎 鑽石：%d　💩 屎堆：%d　回憶碎片：%d" % [
		GameState.player_data.gold,
		GameState.player_data.diamonds,
		GameState.player_data.poop_count,
		GameState.player_data.memory_shards,
	]


# ── 輔助 ───────────────────────────────────────────────────

func _make_separator() -> HSeparator:
	return HSeparator.new()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
