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

	# ── 裝備（占位，Phase 3 實作） ──────────────────────────
	var equip_title := Label.new()
	equip_title.text = "裝備"
	equip_title.add_theme_font_size_override("font_size", 24)
	_tab_content.add_child(equip_title)

	var equip_ph := Label.new()
	equip_ph.text = "（裝備系統 Phase 3 開發中）"
	equip_ph.add_theme_font_size_override("font_size", 18)
	equip_ph.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	_tab_content.add_child(equip_ph)

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
