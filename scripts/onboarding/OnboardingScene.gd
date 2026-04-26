extends Control

const OT = preload("res://scripts/onboarding/OnboardingUiText.gd")

const ONBOARDING_API_PATH := "/onboarding/complete"
const REQUEST_TIMEOUT_SECONDS := 15.0
const ONBOARDING_PLAYER_NAME_FALLBACK := "鏟屎官"
const ONBOARDING_CAT_NAME_PLACEHOLDER := "貓咪"
const DIALOGUE_SPEAKER_CAT: String = "cat"
const DIALOGUE_SPEAKER_OWNER: String = "owner"
const DIALOGUE_SPEAKER_NONE: String = ""
const DIALOGUE_IMAGE_SPECIAL_CAT_FOOD := "catalog/consumable/special_cat_food"
const DIALOGUE_IMAGE_TRAP_CAGES := "catalog/consumable/trap_cages"
const DIALOGUE_INLINE_KIND_NONE := ""
const DIALOGUE_INLINE_KIND_CATALOG_IMAGE := "catalog_image"
const DIALOGUE_INLINE_KIND_IMAGE_ROW := "image_row"
const DIALOGUE_INLINE_KIND_CAT_FORMATION := "cat_formation"
const DIALOGUE_INLINE_KIND_SCOOP_ANIMATION := "scoop_animation"
const DIALOGUE_PORTRAIT_KIND_NONE := ""
const DIALOGUE_PORTRAIT_KIND_CAT := "cat"
const DIALOGUE_PORTRAIT_KIND_OWNER := "owner"
const DIALOGUE_CAT_PICKER_INSERT_BEAT_INDEX := 7
const DIALOGUE_SELECTED_CAT_REVEAL_BEAT_INDEX := 9
const DIALOGUE_GENERIC_CAT_IMAGE_SIZE := Vector2(220, 220)
const DIALOGUE_SELECTED_CAT_IMAGE_SIZE := Vector2(220, 220)
const DIALOGUE_OWNER_IMAGE_SIZE := Vector2(192, 192)
const DIALOGUE_INLINE_IMAGE_SIZE := Vector2(336, 336)
const DIALOGUE_INLINE_SCOOP_SIZE := Vector2(320, 320)
const DIALOGUE_INLINE_ROW_IMAGE_SIZE := Vector2(112, 112)
const DIALOGUE_INLINE_FORMATION_GENERIC_SIZE := Vector2(92, 92)
const DIALOGUE_INLINE_FORMATION_SELECTED_SIZE := Vector2(224.4, 224.4)
const DIALOGUE_INLINE_FORMATION_STAGE_SIZE := Vector2(520, 336)
const DIALOGUE_INLINE_FORMATION_TRAP_SIZE := Vector2(300, 300)
const PICKER_GENERIC_CAT_IMAGE_SIZE := Vector2(120, 120)
const HOME_SCOOP_SHEET_TEXTURE := preload("res://assets/sprites/ui/home/scooper/clean_litter_button_sheet.png")
const HOME_SCOOP_FRAME_SIZE := Vector2i(256, 256)
const HOME_SCOOP_FRAME_COUNT := 14
const HOME_SCOOP_ANIMATION_START_FRAME := 1
const HOME_SCOOP_ANIMATION_FPS := 8.0
const DIALOGUE_ROW_IMAGE_ENCOUNTERS := [
	"res://assets/sprites/cdn/ui/character_refs/encounters/lipstick/lipstick_ref_right_v1.png",
	"res://assets/sprites/cdn/ui/character_refs/encounters/toilet_paper/toilet_paper_ref_front_v1.png",
	"res://assets/sprites/cdn/ui/character_refs/encounters/remote_control/remote_control_ref_three_quarter_v1.png",
	"res://assets/sprites/cdn/ui/character_refs/encounters/mug/mug_ref_front_v1.png",
]
const DIALOGUE_ROW_IMAGE_VISITORS := [
	"res://assets/sprites/cdn/ui/character_refs/boss/schoolgirl/schoolgirl_ref_three_quarter_v1.png",
	"res://assets/sprites/cdn/ui/character_refs/boss/male_coworker/male_coworker_ref_three_quarter_v1.png",
	"res://assets/sprites/cdn/ui/character_refs/boss/grandma/grandma_ref_front_v1.png",
	"res://assets/sprites/cdn/ui/character_refs/boss/baby/baby_ref_right_v1.png",
]

enum Step { NAME, CAT_PICKER, DIALOGUE, COMPLETE }

# ── UI nodes (built in code) ──
var _background: TextureRect
var _step_dots_row: HBoxContainer
var _content_stack: Control

var _name_panel: PanelContainer
var _name_input: LineEdit
var _name_confirm_btn: Button
var _name_skip_btn: Button
var _name_status: Label

var _picker_panel: PanelContainer
var _picker_grid: GridContainer
var _picker_scroller: InertialScroller
var _picker_confirm_btn: Button
var _picker_status: Label
var _picker_selected_label: Label

var _dialogue_panel: PanelContainer
var _dialogue_cat_image: TextureRect
var _dialogue_speaker_label: Label
var _dialogue_text_label: Label
var _dialogue_inline_image: TextureRect
var _dialogue_inline_image_row: HBoxContainer
var _dialogue_inline_cat_formation: Control
var _dialogue_inline_animation: TextureRect
var _dialogue_next_btn: Button

var _complete_panel: PanelContainer
var _complete_subtitle_label: Label
var _complete_start_btn: Button

# ── HTTP ──
var _http: HTTPRequest
var _request_in_flight := false

# ── State ──
var _step: Step = Step.NAME
var _selected_cat_key := ""
var _selected_cat_name := ""
var _player_name_input := ""
var _onboarding_player_name := ""
var _dialogue_beat_index := 0
var _dialogue_beats: Array = []
var _dialogue_scoop_frames: Array[Texture2D] = []
var _dialogue_scoop_animation_elapsed := 0.0
var _dialogue_scoop_frame_index := 0
var _dialogue_scoop_animation_active := false

const CATS_PER_ROW: int = 4
const CATS_PICKER_CARD_WIDTH: float = 148.0
const CATS_PICKER_CARD_HEIGHT: float = 178.0
const CATS_PICKER_CARD_H_GAP := 12
const CATS_PICKER_CARD_V_GAP := 12

var _cat_picker_cards: Dictionary = {}  # cat_key -> Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_onboarding_player_name = _resolve_onboarding_player_name()
	_player_name_input = _onboarding_player_name
	_build_dialogue_beats()
	_build_dialogue_scoop_frames()
	_build_ui()
	_attach_http()
	set_process(true)
	_apply_step()


# ── Build dialogue beats from text constants ──
func _build_dialogue_beats() -> void:
	var player_name: String = _resolve_onboarding_player_name()
	var cat_name: String = _resolve_dialogue_cat_name()

	var raw_beats := [
		[OT.DIALOGUE_BEAT_NARRATOR_1_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_1_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_2_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_2_TEXT],
		[OT.DIALOGUE_BEAT_CAT_1_SPEAKER,      OT.DIALOGUE_BEAT_CAT_1_TEXT],
		[OT.DIALOGUE_BEAT_PLAYER_1_SPEAKER,   OT.DIALOGUE_BEAT_PLAYER_1_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_3_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_3_TEXT],
		[OT.DIALOGUE_BEAT_CAT_2_SPEAKER,      OT.DIALOGUE_BEAT_CAT_2_TEXT],
		[OT.DIALOGUE_BEAT_PLAYER_2_SPEAKER,   OT.DIALOGUE_BEAT_PLAYER_2_TEXT],
		[OT.DIALOGUE_BEAT_CAT_3_SPEAKER,      OT.DIALOGUE_BEAT_CAT_3_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_4_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_4_TEXT],
		[OT.DIALOGUE_BEAT_CAT_4_SPEAKER,      OT.DIALOGUE_BEAT_CAT_4_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_5_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_5_TEXT],
		[OT.DIALOGUE_BEAT_CAT_5_SPEAKER,      OT.DIALOGUE_BEAT_CAT_5_TEXT],
		[OT.DIALOGUE_BEAT_NARRATOR_6_SPEAKER, OT.DIALOGUE_BEAT_NARRATOR_6_TEXT],
	]

	_dialogue_beats = []
	for index: int in range(raw_beats.size()):
		var raw: Array = raw_beats[index]
		var speaker: String = str(raw[0])
		var speaker_type: String = DIALOGUE_SPEAKER_NONE
		var text: String = str(raw[1])
		var portrait_kind: String = DIALOGUE_PORTRAIT_KIND_NONE
		var portrait_size := Vector2.ZERO
		var inline_kind: String = DIALOGUE_INLINE_KIND_NONE
		var inline_image_path := ""
		var inline_image_paths: Array = []
		if index == 0:
			inline_kind = DIALOGUE_INLINE_KIND_CATALOG_IMAGE
			inline_image_path = DIALOGUE_IMAGE_SPECIAL_CAT_FOOD
		elif index == 1:
			portrait_kind = DIALOGUE_PORTRAIT_KIND_OWNER
			portrait_size = DIALOGUE_OWNER_IMAGE_SIZE
		elif index == 4:
			inline_kind = DIALOGUE_INLINE_KIND_CATALOG_IMAGE
			inline_image_path = DIALOGUE_IMAGE_TRAP_CAGES
		elif index == 8:
			portrait_kind = DIALOGUE_PORTRAIT_KIND_CAT
			inline_kind = DIALOGUE_INLINE_KIND_IMAGE_ROW
			inline_image_paths = DIALOGUE_ROW_IMAGE_ENCOUNTERS.duplicate()
		elif index == 10:
			inline_kind = DIALOGUE_INLINE_KIND_SCOOP_ANIMATION
		elif index == 11:
			inline_kind = DIALOGUE_INLINE_KIND_IMAGE_ROW
			inline_image_paths = DIALOGUE_ROW_IMAGE_VISITORS.duplicate()
		elif index == 12:
			inline_kind = DIALOGUE_INLINE_KIND_CAT_FORMATION
		var inline_size := DIALOGUE_INLINE_IMAGE_SIZE
		if inline_kind == DIALOGUE_INLINE_KIND_SCOOP_ANIMATION:
			inline_size = DIALOGUE_INLINE_SCOOP_SIZE
		elif inline_kind == DIALOGUE_INLINE_KIND_IMAGE_ROW:
			inline_size = DIALOGUE_INLINE_ROW_IMAGE_SIZE
		if speaker == OT.DIALOGUE_BEAT_CAT_1_SPEAKER:
			speaker_type = DIALOGUE_SPEAKER_CAT
			if portrait_kind == DIALOGUE_PORTRAIT_KIND_NONE:
				portrait_kind = DIALOGUE_PORTRAIT_KIND_CAT
		elif speaker == OT.DIALOGUE_BEAT_PLAYER_1_SPEAKER:
			speaker_type = DIALOGUE_SPEAKER_OWNER
			if portrait_kind == DIALOGUE_PORTRAIT_KIND_NONE:
				portrait_kind = DIALOGUE_PORTRAIT_KIND_OWNER
		speaker = speaker.replace("{cat_name}", cat_name) \
			.replace("{player_name}", player_name)
		text = text.replace("{cat_name}", cat_name) \
			.replace("{player_name}", player_name)
		_dialogue_beats.append({
			"speaker": speaker,
			"text": text,
			"speaker_type": speaker_type,
			"portrait_kind": portrait_kind,
			"portrait_size": portrait_size,
			"inline_kind": inline_kind,
			"inline_image_path": inline_image_path,
			"inline_image_paths": inline_image_paths,
			"inline_size": inline_size
		})


# ── UI construction ──
func _build_ui() -> void:
	_background = TextureRect.new()
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.texture = preload("res://assets/sprites/ui/start_scene_homey_v1.png")
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_background)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.06, 0.04, 0.45)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_content_stack = Control.new()
	_content_stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_content_stack)

	_step_dots_row = _build_step_dots()
	_content_stack.add_child(_step_dots_row)

	_name_panel = _build_name_panel()
	_content_stack.add_child(_name_panel)

	_picker_panel = _build_picker_panel()
	_content_stack.add_child(_picker_panel)

	_dialogue_panel = _build_dialogue_panel()
	_content_stack.add_child(_dialogue_panel)

	_complete_panel = _build_complete_panel()
	_content_stack.add_child(_complete_panel)


func _build_step_dots() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.anchor_left = 0.5
	row.anchor_top = 0.06
	row.anchor_right = 0.5
	row.anchor_bottom = 0.06
	row.position = Vector2(-40, 0)
	row.custom_minimum_size = Vector2(80, 32)
	for i in range(3):
		var dot := Label.new()
		dot.text = OT.STEP_DOT_INACTIVE
		UiFonts.apply_noto(dot, 18)
		dot.add_theme_color_override("font_color", Color("f0e8dc"))
		row.add_child(dot)
	return row


func _refresh_step_dots() -> void:
	if _step_dots_row == null:
		return
	var current_dot_index := 1
	if _step == Step.NAME:
		current_dot_index = 0
	elif _step == Step.COMPLETE:
		current_dot_index = 2
	for i in range(_step_dots_row.get_child_count()):
		var dot: Label = _step_dots_row.get_child(i)
		dot.text = OT.STEP_DOT_ACTIVE if i == current_dot_index else OT.STEP_DOT_INACTIVE
		dot.add_theme_color_override("font_color",
			Color("f9e97a") if i == current_dot_index else Color("f0e8dc"))


func _build_name_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-230, -130)
	panel.custom_minimum_size = Vector2(460, 260)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := _make_margin_container()
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = OT.NAME_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(title, UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = OT.NAME_HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(hint, UiPalette.FONT_SIZE_BODY)
	hint.add_theme_color_override("font_color", Color("7a6655"))
	vbox.add_child(hint)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = OT.NAME_PLACEHOLDER
	_name_input.custom_minimum_size = Vector2(0, 48)
	_name_input.text = _get_default_player_name()
	UiFonts.apply_noto(_name_input, UiPalette.FONT_SIZE_BODY_LG)
	_name_input.text_submitted.connect(_on_name_submitted)
	vbox.add_child(_name_input)

	_name_status = Label.new()
	_name_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_status.custom_minimum_size = Vector2(0, 28)
	UiFonts.apply_noto(_name_status, 14)
	_name_status.add_theme_color_override("font_color", Color("8b2e2e"))
	vbox.add_child(_name_status)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	_name_skip_btn = _make_button(OT.NAME_SKIP, Color("bbb0a0"), Color("ccc0b0"), Color("aaa090"))
	_name_skip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_skip_btn.pressed.connect(_on_name_skip_pressed)
	btn_row.add_child(_name_skip_btn)

	_name_confirm_btn = _make_button(OT.NAME_CONFIRM, Color("9aae8b"), Color("a8bc98"), Color("869a79"))
	_name_confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_confirm_btn.pressed.connect(_on_name_confirm_pressed)
	btn_row.add_child(_name_confirm_btn)

	return panel


func _build_picker_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-300, -230)
	panel.custom_minimum_size = Vector2(700, 600)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := _make_margin_container()
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = OT.CAT_PICKER_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(title, UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = OT.CAT_PICKER_SUBTITLE
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(subtitle, UiPalette.FONT_SIZE_BODY)
	subtitle.add_theme_color_override("font_color", Color("7a6655"))
	vbox.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_picker_grid = GridContainer.new()
	_picker_grid.columns = CATS_PER_ROW
	_picker_grid.add_theme_constant_override("h_separation", CATS_PICKER_CARD_H_GAP)
	_picker_grid.add_theme_constant_override("v_separation", CATS_PICKER_CARD_V_GAP)
	_picker_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_picker_grid)

	_picker_scroller = InertialScroller.attach(scroll, "vertical")

	_populate_cat_picker()

	_picker_selected_label = Label.new()
	_picker_selected_label.text = OT.CAT_PICKER_HINT
	_picker_selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(_picker_selected_label, 14)
	_picker_selected_label.add_theme_color_override("font_color", Color("7a6655"))
	vbox.add_child(_picker_selected_label)

	_picker_status = Label.new()
	_picker_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_picker_status.custom_minimum_size = Vector2(0, 24)
	UiFonts.apply_noto(_picker_status, 14)
	_picker_status.add_theme_color_override("font_color", Color("8b2e2e"))
	vbox.add_child(_picker_status)

	_picker_confirm_btn = _make_button(OT.CAT_PICKER_CONFIRM, Color("9aae8b"), Color("a8bc98"), Color("869a79"))
	_picker_confirm_btn.disabled = true
	_picker_confirm_btn.pressed.connect(_on_picker_confirm_pressed)
	vbox.add_child(_picker_confirm_btn)

	return panel


func _populate_cat_picker() -> void:
	if _picker_grid == null:
		return
	for child in _picker_grid.get_children():
		child.queue_free()
	_cat_picker_cards = {}

	for item_variant: Variant in GameState.cat_catalog:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var cat_key: String = str(item.get("id", ""))
		var display_name: String = str(item.get("display_name", cat_key))
		if cat_key == "":
			continue

		var card := _build_cat_card(cat_key, display_name)
		_picker_grid.add_child(card)
		_cat_picker_cards[cat_key] = card


func _build_cat_card(cat_key: String, display_name: String) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CATS_PICKER_CARD_WIDTH, CATS_PICKER_CARD_HEIGHT)
	btn.add_theme_stylebox_override("normal", _make_button_stylebox(Color("f0e8d8"), 6))
	btn.add_theme_stylebox_override("hover", _make_button_stylebox(Color("f8f0e0"), 6))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(Color("d8c8b0"), 4))
	btn.pressed.connect(_on_cat_card_pressed.bind(cat_key, display_name))

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var icon_texture: Texture2D = AssetResolver.resolve_onboarding_generic_cat()
	var icon := TextureRect.new()
	icon.custom_minimum_size = PICKER_GENERIC_CAT_IMAGE_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = icon_texture
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(name_label, 13)
	name_label.add_theme_color_override("font_color", Color("4f3d31"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	return btn


func _build_dialogue_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-310, -300)
	panel.custom_minimum_size = Vector2(620, 600)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := _make_margin_container()
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_dialogue_cat_image = TextureRect.new()
	_dialogue_cat_image.custom_minimum_size = DIALOGUE_SELECTED_CAT_IMAGE_SIZE
	_dialogue_cat_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_cat_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_cat_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dialogue_cat_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_dialogue_cat_image)

	_dialogue_speaker_label = Label.new()
	_dialogue_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(_dialogue_speaker_label, UiPalette.FONT_SIZE_SUBHEADING)
	_dialogue_speaker_label.add_theme_color_override("font_color", Color("c47c30"))
	vbox.add_child(_dialogue_speaker_label)

	var text_frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.96, 0.93, 0.88, 0.72)
	frame_style.corner_radius_top_left = 8
	frame_style.corner_radius_top_right = 8
	frame_style.corner_radius_bottom_right = 8
	frame_style.corner_radius_bottom_left = 8
	frame_style.content_margin_left = 16
	frame_style.content_margin_top = 12
	frame_style.content_margin_right = 16
	frame_style.content_margin_bottom = 12
	text_frame.add_theme_stylebox_override("panel", frame_style)
	text_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(text_frame)

	var text_content := VBoxContainer.new()
	text_content.add_theme_constant_override("separation", 10)
	text_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_frame.add_child(text_content)

	_dialogue_text_label = Label.new()
	_dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiFonts.apply_noto(_dialogue_text_label, UiPalette.FONT_SIZE_BODY_LG)
	_dialogue_text_label.add_theme_color_override("font_color", Color("3d2f20"))
	text_content.add_child(_dialogue_text_label)

	_dialogue_inline_image = TextureRect.new()
	_dialogue_inline_image.custom_minimum_size = DIALOGUE_INLINE_IMAGE_SIZE
	_dialogue_inline_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_inline_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_inline_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dialogue_inline_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_dialogue_inline_image.visible = false
	text_content.add_child(_dialogue_inline_image)

	_dialogue_inline_image_row = HBoxContainer.new()
	_dialogue_inline_image_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dialogue_inline_image_row.add_theme_constant_override("separation", 8)
	_dialogue_inline_image_row.visible = false
	text_content.add_child(_dialogue_inline_image_row)

	_dialogue_inline_cat_formation = Control.new()
	_dialogue_inline_cat_formation.custom_minimum_size = DIALOGUE_INLINE_FORMATION_STAGE_SIZE
	_dialogue_inline_cat_formation.visible = false
	text_content.add_child(_dialogue_inline_cat_formation)

	_dialogue_inline_animation = TextureRect.new()
	_dialogue_inline_animation.custom_minimum_size = DIALOGUE_INLINE_SCOOP_SIZE
	_dialogue_inline_animation.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_inline_animation.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_inline_animation.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dialogue_inline_animation.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_dialogue_inline_animation.visible = false
	text_content.add_child(_dialogue_inline_animation)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	_dialogue_next_btn = _make_button(OT.DIALOGUE_NEXT, Color("9aae8b"), Color("a8bc98"), Color("869a79"))
	_dialogue_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_next_btn.pressed.connect(_on_dialogue_next_pressed)
	btn_row.add_child(_dialogue_next_btn)

	return panel


func _build_complete_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.position = Vector2(-220, -120)
	panel.custom_minimum_size = Vector2(440, 240)
	panel.add_theme_stylebox_override("panel", _make_card_stylebox())

	var margin := _make_margin_container()
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = OT.COMPLETE_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFonts.apply_noto(title, UiPalette.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", Color("4f3d31"))
	vbox.add_child(title)

	_complete_subtitle_label = Label.new()
	_complete_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiFonts.apply_noto(_complete_subtitle_label, UiPalette.FONT_SIZE_BODY_LG)
	_complete_subtitle_label.add_theme_color_override("font_color", Color("7a6655"))
	vbox.add_child(_complete_subtitle_label)
	_refresh_complete_subtitle()

	_complete_start_btn = _make_button(OT.COMPLETE_BUTTON, Color("9aae8b"), Color("a8bc98"), Color("869a79"))
	_complete_start_btn.custom_minimum_size = Vector2(0, 56)
	_complete_start_btn.pressed.connect(_on_complete_start_pressed)
	vbox.add_child(_complete_start_btn)

	return panel


# ── Step transitions ──
func _apply_step() -> void:
	_refresh_step_dots()
	_name_panel.visible = _step == Step.NAME
	_picker_panel.visible = _step == Step.CAT_PICKER
	_dialogue_panel.visible = _step == Step.DIALOGUE
	_complete_panel.visible = _step == Step.COMPLETE

	if _step == Step.DIALOGUE:
		_apply_dialogue_beat()
	else:
		_stop_dialogue_inline_animation()
	if _step == Step.COMPLETE:
		_refresh_complete_subtitle()


func _go_to_step(step: Step) -> void:
	_step = step
	_apply_step()


# ── Name step handlers ──
func _on_name_submitted(_text: String) -> void:
	_on_name_confirm_pressed()


func _on_name_confirm_pressed() -> void:
	var name_text: String = _name_input.text.strip_edges()
	if name_text == "":
		_name_status.text = OT.NAME_ERROR_EMPTY
		return
	_player_name_input = name_text
	_onboarding_player_name = _persist_onboarding_player_name(name_text)
	_name_input.text = _onboarding_player_name
	_build_dialogue_beats()
	_dialogue_beat_index = 0
	_name_status.text = ""
	_go_to_step(Step.DIALOGUE)


func _on_name_skip_pressed() -> void:
	_player_name_input = _resolve_onboarding_player_name()
	_onboarding_player_name = _player_name_input
	_build_dialogue_beats()
	_dialogue_beat_index = 0
	_go_to_step(Step.DIALOGUE)


func _get_default_player_name() -> String:
	return _resolve_onboarding_player_name()


func _resolve_onboarding_player_name() -> String:
	var typed_name := _player_name_input.strip_edges()
	if typed_name != "":
		return typed_name

	var saved_player_name := ""
	if GameState.player_data != null:
		saved_player_name = str(GameState.player_data.player_name).strip_edges()
		if saved_player_name != "":
			return saved_player_name
		saved_player_name = str(GameState.player_data.display_name).strip_edges()
		if saved_player_name != "":
			return saved_player_name
	return ONBOARDING_PLAYER_NAME_FALLBACK


func _persist_onboarding_player_name(name_text: String) -> String:
	var normalized_name := name_text.strip_edges()
	if normalized_name == "":
		return _resolve_onboarding_player_name()

	if GameState.player_data == null:
		GameState.player_data = PlayerData.load_or_default()

	GameState.player_data.player_name = normalized_name
	if str(GameState.player_data.display_name).strip_edges() == "":
		GameState.player_data.display_name = normalized_name
	GameState.player_data.save()
	return normalized_name


# ── Cat picker step handlers ──
func _on_cat_card_pressed(cat_key: String, display_name: String) -> void:
	if _picker_scroller != null and _picker_scroller.consume_moved():
		return

	_selected_cat_key = cat_key
	_selected_cat_name = display_name
	_picker_selected_label.text = OT.CAT_PICKER_SELECTED_FORMAT % display_name
	_picker_confirm_btn.disabled = false
	_picker_status.text = ""

	for key: String in _cat_picker_cards:
		var card: Control = _cat_picker_cards[key]
		var is_selected := key == cat_key
		var fill_color: Color = Color("d4e8c8") if is_selected else Color("f0e8d8")
		card.add_theme_stylebox_override("normal", _make_button_stylebox(fill_color, 6))


func _on_picker_confirm_pressed() -> void:
	if _selected_cat_key == "" or _request_in_flight:
		return
	_submit_onboarding()


func _submit_onboarding() -> void:
	_request_in_flight = true
	_picker_confirm_btn.disabled = true
	_picker_status.text = OT.CAT_PICKER_LOADING

	var access_token: String = GameState.get_access_token()
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Authorization: Bearer %s" % access_token,
	])

	var body_dict: Dictionary = {"catKey": _selected_cat_key}
	var resolved_player_name := _resolve_onboarding_player_name()
	if resolved_player_name != "" and resolved_player_name != ONBOARDING_PLAYER_NAME_FALLBACK:
		body_dict["playerName"] = resolved_player_name

	var body: String = JSON.stringify(body_dict)
	var url: String = "%s%s" % [GameState.api_base_url, ONBOARDING_API_PATH]
	var error: int = _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		_request_in_flight = false
		_picker_confirm_btn.disabled = false
		_picker_status.text = OT.CAT_PICKER_ERROR


func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_request_in_flight = false
	_picker_confirm_btn.disabled = false

	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_picker_status.text = OT.CAT_PICKER_ERROR
		return

	var response_text: String = body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(response_text) != OK:
		_picker_status.text = OT.CAT_PICKER_ERROR
		return

	var payload: Variant = json.get_data()
	if not (payload is Dictionary):
		_picker_status.text = OT.CAT_PICKER_ERROR
		return

	var success: bool = bool((payload as Dictionary).get("success", false))
	if not success:
		var error_variant: Variant = (payload as Dictionary).get("error", {})
		var error_dict: Dictionary = error_variant if error_variant is Dictionary else {}
		_picker_status.text = str(error_dict.get("message", OT.CAT_PICKER_ERROR))
		return

	_sync_onboarding_starter((payload as Dictionary))
	_picker_status.text = ""
	GameState.is_new_player = false
	_build_dialogue_beats()
	_dialogue_beat_index = DIALOGUE_CAT_PICKER_INSERT_BEAT_INDEX
	_update_cat_dialogue_image()
	_go_to_step(Step.DIALOGUE)


func _sync_onboarding_starter(payload: Dictionary) -> void:
	var data_variant: Variant = payload.get("data", {})
	if not (data_variant is Dictionary):
		return
	var data: Dictionary = data_variant as Dictionary
	var starter_variant: Variant = data.get("starterCat", {})
	if not (starter_variant is Dictionary):
		return

	var starter_cat: Dictionary = starter_variant as Dictionary
	var player_cat_id: int = _read_starter_int(starter_cat, ["playerCatId", "PlayerCatId"])
	var catalog_id: int = _read_starter_int(starter_cat, ["catCatalogId", "CatCatalogId"])
	if player_cat_id <= 0 or catalog_id <= 0:
		return

	var starter_row: Dictionary = {
		"playerCatId": player_cat_id,
		"catCatalogId": catalog_id,
		"displayName": str(starter_cat.get("displayName", starter_cat.get("DisplayName", ""))),
		"catFoodLevel": _read_starter_int(starter_cat, ["catFoodLevel", "CatFoodLevel"]),
		"rank": _read_starter_int(starter_cat, ["rank", "Rank"]),
		"isOwned": bool(starter_cat.get("isOwned", starter_cat.get("IsOwned", true))),
	}
	GameState.update_player_cats([starter_row])

	var boss_team: Dictionary = {
		"teamType": "Boss",
		"members": [{
			"slotNo": 0,
			"playerCatId": player_cat_id,
			"catCatalogId": catalog_id,
			"catDisplayName": str(starter_row.get("displayName", "")),
			"catFoodLevel": int(starter_row.get("catFoodLevel", 1)),
			"rank": int(starter_row.get("rank", 0)),
			"initialDelaySeconds": 0.0,
		}],
	}
	GameState.update_player_teams([boss_team])

	if GameState.player_data == null:
		GameState.player_data = PlayerData.load_or_default()
	GameState.player_data.boss_team = [player_cat_id]
	GameState.player_data.save()


func _read_starter_int(data: Dictionary, candidate_keys: Array[String]) -> int:
	for key: String in candidate_keys:
		if data.has(key):
			return int(data.get(key, 0))
	return 0


# ── Dialogue step handlers ──
func _apply_dialogue_beat() -> void:
	if _dialogue_beat_index >= _dialogue_beats.size():
		_go_to_step(Step.COMPLETE)
		return

	var beat: Dictionary = _dialogue_beats[_dialogue_beat_index]
	var speaker: String = str(beat.get("speaker", DIALOGUE_SPEAKER_NONE))
	var speaker_type: String = str(beat.get("speaker_type", DIALOGUE_SPEAKER_NONE))
	var text: String = str(beat.get("text", ""))
	var portrait_kind: String = str(beat.get("portrait_kind", DIALOGUE_PORTRAIT_KIND_NONE))
	var portrait_size: Variant = beat.get("portrait_size", Vector2.ZERO)
	var inline_kind: String = str(beat.get("inline_kind", DIALOGUE_INLINE_KIND_NONE))
	var inline_image_path: String = str(beat.get("inline_image_path", ""))
	var inline_image_paths: Array = beat.get("inline_image_paths", [])
	var inline_size: Variant = beat.get("inline_size", DIALOGUE_INLINE_IMAGE_SIZE)

	_dialogue_speaker_label.text = speaker
	_dialogue_speaker_label.visible = speaker != ""
	_dialogue_text_label.text = text
	_apply_dialogue_inline_media(inline_kind, inline_image_path, inline_image_paths, inline_size)
	_apply_dialogue_portrait(portrait_kind, portrait_size, speaker_type)

	var is_last_beat: bool = _dialogue_beat_index >= _dialogue_beats.size() - 1
	_dialogue_next_btn.text = OT.DIALOGUE_START if is_last_beat else OT.DIALOGUE_NEXT


func _update_cat_dialogue_image() -> void:
	if _dialogue_cat_image == null:
		return
	if _dialogue_beat_index >= DIALOGUE_SELECTED_CAT_REVEAL_BEAT_INDEX:
		_dialogue_cat_image.custom_minimum_size = DIALOGUE_SELECTED_CAT_IMAGE_SIZE
		_dialogue_cat_image.texture = AssetResolver.resolve_cat_showcase_art(_selected_cat_key)
	else:
		_dialogue_cat_image.custom_minimum_size = DIALOGUE_GENERIC_CAT_IMAGE_SIZE
		_dialogue_cat_image.texture = AssetResolver.resolve_onboarding_generic_cat()


func _update_owner_dialogue_image() -> void:
	if _dialogue_cat_image == null:
		return
	_dialogue_cat_image.custom_minimum_size = DIALOGUE_OWNER_IMAGE_SIZE
	_dialogue_cat_image.texture = AssetResolver.resolve_onboarding_owner_avatar()


func _on_dialogue_next_pressed() -> void:
	if _dialogue_beat_index + 1 == DIALOGUE_CAT_PICKER_INSERT_BEAT_INDEX and _selected_cat_key == "":
		_go_to_step(Step.CAT_PICKER)
		return
	_dialogue_beat_index += 1
	if _dialogue_beat_index >= _dialogue_beats.size():
		_go_to_step(Step.COMPLETE)
	else:
		_apply_dialogue_beat()
func _process(delta: float) -> void:
	_update_dialogue_scoop_animation(delta)


# ── Complete step handler ──
func _on_complete_start_pressed() -> void:
	SceneNavigator.enter_home_shell()


# ── HTTP setup ──
func _attach_http() -> void:
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SECONDS
	_http.request_completed.connect(_on_http_request_completed)
	add_child(_http)


# ── Style helpers (same theme as StartScene) ──
func _make_card_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.88, 0.90)
	style.border_color = Color("6d5948")
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0.24, 0.18, 0.14, 0.28)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 8)
	style.anti_aliasing = false
	style.border_blend = false
	return style


func _make_margin_container() -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_bottom", 20)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	return m


func _refresh_complete_subtitle() -> void:
	if _complete_subtitle_label == null:
		return
	var player_name: String = _resolve_onboarding_player_name()
	var cat_name: String = _resolve_dialogue_cat_name()
	_complete_subtitle_label.text = OT.COMPLETE_SUBTITLE_FORMAT % [player_name, cat_name]


func _resolve_dialogue_cat_name() -> String:
	var resolved_name := _selected_cat_name.strip_edges()
	return resolved_name if resolved_name != "" else ONBOARDING_CAT_NAME_PLACEHOLDER


func _apply_dialogue_portrait(portrait_kind: String, portrait_size_variant: Variant, speaker_type: String) -> void:
	if _dialogue_cat_image == null:
		return

	var resolved_portrait_kind := portrait_kind
	if resolved_portrait_kind == DIALOGUE_PORTRAIT_KIND_NONE:
		if speaker_type == DIALOGUE_SPEAKER_CAT:
			resolved_portrait_kind = DIALOGUE_PORTRAIT_KIND_CAT
		elif speaker_type == DIALOGUE_SPEAKER_OWNER:
			resolved_portrait_kind = DIALOGUE_PORTRAIT_KIND_OWNER

	if resolved_portrait_kind == DIALOGUE_PORTRAIT_KIND_CAT:
		_update_cat_dialogue_image()
		if portrait_size_variant is Vector2 and portrait_size_variant != Vector2.ZERO:
			_dialogue_cat_image.custom_minimum_size = portrait_size_variant
		_dialogue_cat_image.visible = true
	elif resolved_portrait_kind == DIALOGUE_PORTRAIT_KIND_OWNER:
		_update_owner_dialogue_image()
		if portrait_size_variant is Vector2 and portrait_size_variant != Vector2.ZERO:
			_dialogue_cat_image.custom_minimum_size = portrait_size_variant
		_dialogue_cat_image.visible = true
	else:
		_dialogue_cat_image.visible = false


func _apply_dialogue_inline_media(inline_kind: String, inline_image_path: String, inline_image_paths: Array, inline_size_variant: Variant) -> void:
	if _dialogue_inline_image == null or _dialogue_inline_image_row == null or _dialogue_inline_cat_formation == null or _dialogue_inline_animation == null:
		return

	_dialogue_inline_image.visible = false
	_dialogue_inline_image_row.visible = false
	_dialogue_inline_cat_formation.visible = false
	_dialogue_inline_animation.visible = false
	_stop_dialogue_inline_animation()
	_clear_dialogue_inline_image_row()
	_clear_dialogue_inline_cat_formation()

	var inline_size := DIALOGUE_INLINE_IMAGE_SIZE
	if inline_size_variant is Vector2 and inline_size_variant != Vector2.ZERO:
		inline_size = inline_size_variant

	if inline_kind == DIALOGUE_INLINE_KIND_CATALOG_IMAGE and inline_image_path != "":
		_dialogue_inline_image.custom_minimum_size = inline_size
		_dialogue_inline_image.texture = AssetResolver.resolve_catalog_texture(inline_image_path)
		_dialogue_inline_image.visible = true
	elif inline_kind == DIALOGUE_INLINE_KIND_IMAGE_ROW:
		_populate_dialogue_inline_image_row(inline_image_paths, inline_size)
	elif inline_kind == DIALOGUE_INLINE_KIND_CAT_FORMATION:
		_populate_dialogue_inline_cat_formation()
	elif inline_kind == DIALOGUE_INLINE_KIND_SCOOP_ANIMATION:
		_dialogue_inline_animation.custom_minimum_size = inline_size
		_start_dialogue_inline_animation()


func _build_dialogue_scoop_frames() -> void:
	_dialogue_scoop_frames.clear()
	if HOME_SCOOP_SHEET_TEXTURE == null:
		return

	for frame_index: int in range(HOME_SCOOP_FRAME_COUNT):
		var atlas_texture: AtlasTexture = AtlasTexture.new()
		atlas_texture.atlas = HOME_SCOOP_SHEET_TEXTURE
		atlas_texture.region = Rect2(
			float(frame_index * HOME_SCOOP_FRAME_SIZE.x),
			0.0,
			float(HOME_SCOOP_FRAME_SIZE.x),
			float(HOME_SCOOP_FRAME_SIZE.y)
		)
		_dialogue_scoop_frames.append(atlas_texture)


func _clear_dialogue_inline_image_row() -> void:
	if _dialogue_inline_image_row == null:
		return
	for child in _dialogue_inline_image_row.get_children():
		child.queue_free()


func _clear_dialogue_inline_cat_formation() -> void:
	if _dialogue_inline_cat_formation == null:
		return
	for child in _dialogue_inline_cat_formation.get_children():
		child.queue_free()


func _populate_dialogue_inline_image_row(image_paths: Array, inline_size: Vector2) -> void:
	if _dialogue_inline_image_row == null:
		return

	for path_variant: Variant in image_paths:
		var image_path: String = str(path_variant).strip_edges()
		if image_path == "":
			continue
		var image := TextureRect.new()
		image.custom_minimum_size = inline_size
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		image.texture = AssetResolver.resolve_texture_or_placeholder(image_path)
		_dialogue_inline_image_row.add_child(image)

	_dialogue_inline_image_row.visible = _dialogue_inline_image_row.get_child_count() > 0


func _populate_dialogue_inline_cat_formation() -> void:
	if _dialogue_inline_cat_formation == null:
		return

	_dialogue_inline_cat_formation.custom_minimum_size = DIALOGUE_INLINE_FORMATION_STAGE_SIZE

	var trap_cage := _build_dialogue_inline_cat_sprite(
		AssetResolver.resolve_catalog_texture(DIALOGUE_IMAGE_TRAP_CAGES),
		DIALOGUE_INLINE_FORMATION_TRAP_SIZE
	)
	trap_cage.position = Vector2(110, 30)
	trap_cage.modulate = Color(1, 1, 1, 0.5)
	_dialogue_inline_cat_formation.add_child(trap_cage)

	var top_left := _build_dialogue_inline_cat_sprite(
		AssetResolver.resolve_onboarding_generic_cat(),
		DIALOGUE_INLINE_FORMATION_GENERIC_SIZE
	)
	top_left.position = Vector2(40, 22)
	_dialogue_inline_cat_formation.add_child(top_left)

	var top_right := _build_dialogue_inline_cat_sprite(
		AssetResolver.resolve_onboarding_generic_cat(),
		DIALOGUE_INLINE_FORMATION_GENERIC_SIZE
	)
	top_right.position = Vector2(388, 22)
	_dialogue_inline_cat_formation.add_child(top_right)

	var lower_left := _build_dialogue_inline_cat_sprite(
		AssetResolver.resolve_onboarding_generic_cat(),
		DIALOGUE_INLINE_FORMATION_GENERIC_SIZE
	)
	lower_left.position = Vector2(126, 110)
	_dialogue_inline_cat_formation.add_child(lower_left)

	var lower_right := _build_dialogue_inline_cat_sprite(
		AssetResolver.resolve_onboarding_generic_cat(),
		DIALOGUE_INLINE_FORMATION_GENERIC_SIZE
	)
	lower_right.position = Vector2(302, 110)
	_dialogue_inline_cat_formation.add_child(lower_right)

	var selected_cat := _build_dialogue_inline_cat_sprite(
		AssetResolver.resolve_cat_showcase_art(_selected_cat_key),
		DIALOGUE_INLINE_FORMATION_SELECTED_SIZE
	)
	selected_cat.position = Vector2(128, 108)
	_dialogue_inline_cat_formation.add_child(selected_cat)

	_dialogue_inline_cat_formation.visible = true


func _build_dialogue_inline_cat_sprite(texture: Texture2D, sprite_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.position = Vector2.ZERO
	image.size = sprite_size
	image.custom_minimum_size = sprite_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.texture = texture
	return image


func _start_dialogue_inline_animation() -> void:
	if _dialogue_inline_animation == null or _dialogue_scoop_frames.is_empty():
		return

	_dialogue_scoop_animation_active = true
	_dialogue_scoop_animation_elapsed = 0.0
	_dialogue_inline_animation.visible = true
	_set_dialogue_scoop_frame(HOME_SCOOP_ANIMATION_START_FRAME)


func _stop_dialogue_inline_animation() -> void:
	_dialogue_scoop_animation_active = false
	_dialogue_scoop_animation_elapsed = 0.0


func _set_dialogue_scoop_frame(frame_index: int) -> void:
	if _dialogue_inline_animation == null or _dialogue_scoop_frames.is_empty():
		return

	var safe_index: int = clampi(frame_index, 0, _dialogue_scoop_frames.size() - 1)
	_dialogue_scoop_frame_index = safe_index
	_dialogue_inline_animation.texture = _dialogue_scoop_frames[safe_index]


func _update_dialogue_scoop_animation(delta: float) -> void:
	if not _dialogue_scoop_animation_active or _dialogue_scoop_frames.size() <= 1:
		return

	var animated_frame_count: int = _dialogue_scoop_frames.size() - HOME_SCOOP_ANIMATION_START_FRAME
	if animated_frame_count <= 0:
		return

	_dialogue_scoop_animation_elapsed += delta
	var frame_offset: int = int(floor(_dialogue_scoop_animation_elapsed * HOME_SCOOP_ANIMATION_FPS)) % animated_frame_count
	var frame_index: int = HOME_SCOOP_ANIMATION_START_FRAME + frame_offset
	if frame_index != _dialogue_scoop_frame_index:
		_set_dialogue_scoop_frame(frame_index)


func _make_button(label: String, normal: Color, hover: Color, pressed: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 50)
	UiFonts.apply_noto(btn, UiPalette.FONT_SIZE_BODY_LG)
	btn.add_theme_color_override("font_color", Color("fff8f2"))
	btn.add_theme_color_override("font_hover_color", Color("fff8f2"))
	btn.add_theme_color_override("font_pressed_color", Color("fff8f2"))
	btn.add_theme_stylebox_override("normal", _make_button_stylebox(normal, 8))
	btn.add_theme_stylebox_override("hover", _make_button_stylebox(hover, 8))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(pressed, 6))
	return btn


func _make_button_stylebox(fill_color: Color, bottom_depth: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color("6f5847")
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = bottom_depth
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 10
	style.content_margin_top = 12
	style.content_margin_right = 10
	style.content_margin_bottom = 12
	style.anti_aliasing = false
	style.border_blend = false
	return style
