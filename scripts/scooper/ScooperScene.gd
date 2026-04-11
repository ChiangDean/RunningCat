class_name ScooperScene
extends Control

## 鏟屎官主頁面，含四個 Tab：鏟屎官、回憶、寶藏、成就
## 所有資料操作透過 ApiClient 呼叫後端 API，不再使用本地 JSON 設定。

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

# API 請求鎖定狀態
var _api_in_flight: bool = false

const TAB_KEYS: Array = ["scooper", "memory", "treasure", "achievement"]
const TAB_DISPLAY: Dictionary = {
	"scooper":     "鏟屎官",
	"memory":      "回憶",
	"treasure":    "寶藏",
	"achievement": "成就",
}

@onready var GameState = get_node("/root/GameState")
@onready var ApiClient = get_node("/root/ApiClient")
@onready var DialogManager = get_node("/root/DialogManager")

# Tab helpers
var _scooper_tab     := preload("res://scripts/scooper/scooper_tab_scooper.gd").new()
var _memory_tab      := preload("res://scripts/scooper/scooper_tab_memory.gd").new()
var _treasure_tab    := preload("res://scripts/scooper/scooper_tab_treasure.gd").new()
var _achievement_tab := preload("res://scripts/scooper/scooper_tab_achievement.gd").new()


func _ready() -> void:
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
		"scooper":     _scooper_tab.build(self)
		"memory":      _memory_tab.build(self)
		"treasure":    _treasure_tab.build(self)
		"achievement": _achievement_tab.build(self)


func _refresh_tab_button_labels() -> void:
	var unclaimed_count := 0
	for item: Dictionary in GameState.scooper_achievement_data:
		if bool(item.get("isCompleted", false)) and not bool(item.get("isClaimed", false)):
			unclaimed_count += 1
	for tab_key: String in _tab_btns.keys():
		var btn: Button = _tab_btns[tab_key]
		if btn == null:
			continue
		btn.text = TAB_DISPLAY[tab_key]
		if tab_key == "achievement" and unclaimed_count > 0:
			btn.text += " ●"


func _process(delta: float) -> void:
	_scooper_tab.process(self, delta)


func _apply_profile_to_player_data(profile: Dictionary) -> void:
	GameState.player_data.scooper_level = int(profile.get("scooperLevel", GameState.player_data.scooper_level))
	GameState.player_data.scooper_exp = int(profile.get("scooperExp", GameState.player_data.scooper_exp))
	GameState.player_data.gold = int(profile.get("gold", GameState.player_data.gold))
	GameState.player_data.poop_count = int(profile.get("poopCount", GameState.player_data.poop_count))
	GameState.player_data.memory_shards = int(profile.get("memoryShards", GameState.player_data.memory_shards))
	GameState.player_data.whisker_shards = int(profile.get("whiskers", GameState.player_data.whisker_shards))
	_refresh_resource_label()


func refresh_from_bootstrap(on_completed: Callable = Callable()) -> void:
	ApiClient.get_authenticated_bootstrap(func(ok: bool, data: Variant, err: Dictionary) -> void:
		if ok and data is Dictionary:
			GameState.apply_player_bootstrap(data)
			_refresh_resource_label()
			if _tab_content != null:
				_rebuild_tab_content()
		elif not on_completed.is_null():
			on_completed.call(false, {}, err)
			return

		if not on_completed.is_null():
			on_completed.call(ok, data, err)
	)


# ── 資源列更新 ─────────────────────────────────────────────

func _refresh_resource_label() -> void:
	_resource_label.text = "💰 金幣：%d　💩 屎堆：%d" % [
		GameState.player_data.gold,
		GameState.player_data.poop_count,
	]


# ── 輔助 ───────────────────────────────────────────────────

func _make_separator() -> HSeparator:
	return HSeparator.new()


func _show_loading_in(container: VBoxContainer) -> void:
	var lbl := Label.new()
	lbl.text = "載入中..."
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
	container.add_child(lbl)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")
