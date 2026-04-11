extends Control

const ShopTrapCageView = preload("res://scripts/shop/ShopTrapCageView.gd")
const ShopBundleView = preload("res://scripts/shop/ShopBundleView.gd")

const SW := 720.0
const SH := 1280.0

var _title_label: Label
var _currency_label: Label
var _content_root: VBoxContainer
var _current_view: String = "menu"

@onready var _api_client = get_node("/root/ApiClient")


func _ready() -> void:
	_build_ui()
	_refresh_currency()
	call_deferred("_refresh_shop_overview", false)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.133, 0.157, 0.192, 1.0)
	background.size = Vector2(SW, SH)
	add_child(background)

	var layer := CanvasLayer.new()
	add_child(layer)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_top = 40
	root.offset_right = -20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 16)
	layer.add_child(root)

	var top_row := HBoxContainer.new()
	root.add_child(top_row)

	var back_button := Button.new()
	back_button.text = "\u8fd4\u56de"
	back_button.custom_minimum_size = Vector2(100.0, 50.0)
	back_button.pressed.connect(_on_back_pressed)
	top_row.add_child(back_button)

	_title_label = Label.new()
	_title_label.text = "\u5546\u5e97"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	top_row.add_child(_title_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(100.0, 50.0)
	top_row.add_child(spacer)

	_currency_label = Label.new()
	_currency_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_currency_label)

	root.add_child(HSeparator.new())

	_content_root = VBoxContainer.new()
	_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_root.add_theme_constant_override("separation", 14)
	root.add_child(_content_root)

	_show_menu()
	_refresh_currency()


func _show_menu() -> void:
	_current_view = "menu"
	_title_label.text = "\u5546\u5e97"
	_clear_content()

	var intro := Label.new()
	intro.text = "\u8acb\u9078\u64c7\u8981\u524d\u5f80\u7684\u5546\u5e97\u9801\u9762\u3002"
	intro.add_theme_font_size_override("font_size", 20)
	_content_root.add_child(intro)

	_content_root.add_child(_create_menu_button("\u8a98\u6355\u7c60\u5546\u5e97", _show_trap_cage_view))
	_content_root.add_child(_create_menu_button("\u5546\u57ce\u79ae\u5305", _show_bundle_view))
	_content_root.add_child(_create_menu_button("\u524d\u5f80\u8a98\u6355", _open_gacha_scene))


func _show_trap_cage_view() -> void:
	_current_view = "trap_cages"
	_title_label.text = "\u8a98\u6355\u7c60\u5546\u5e97"
	_clear_content()
	var view = ShopTrapCageView.new()
	_content_root.add_child(view)
	view.request_refresh.connect(_refresh_currency)
	view.setup()


func _show_bundle_view() -> void:
	_current_view = "bundles"
	_title_label.text = "\u5546\u57ce\u79ae\u5305"
	_clear_content()
	var view = ShopBundleView.new()
	_content_root.add_child(view)
	view.request_refresh.connect(_refresh_currency)
	view.setup()


func _refresh_shop_overview(show_error_dialog: bool) -> void:
	_api_client.get_shop_overview(func(success: bool, data: Variant, error: Dictionary) -> void:
		if success:
			if data is Dictionary:
				GameState.update_shop(data)
			_refresh_currency()
			if _current_view == "trap_cages":
				_show_trap_cage_view()
			elif _current_view == "bundles":
				_show_bundle_view()
			return
		if show_error_dialog:
			DialogManager.show_info("\u8b80\u53d6\u5931\u6557", str(error.get("message", "\u7121\u6cd5\u53d6\u5f97\u5546\u5e97\u8cc7\u6599\u3002")))
	)


func _refresh_currency() -> void:
	_currency_label.text = "\u947d\u77f3 %d  |  \u8a98\u6355\u7c60 %d" % [
		GameState.player_data.diamonds,
		GameState.player_data.trap_cages,
	]


func _create_menu_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 78.0)
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(callback)
	return button


func _clear_content() -> void:
	for child in _content_root.get_children():
		child.queue_free()


func _on_back_pressed() -> void:
	if _current_view != "menu":
		_show_menu()
		return
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")


func _open_gacha_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/GachaScene.tscn")
