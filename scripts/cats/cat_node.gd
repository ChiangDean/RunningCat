class_name CatNode
extends Node2D

const AssetResolver = preload("res://scripts/ui/asset_resolver.gd")

signal died(node: CatNode)

var instance_id: int = -1
var team: String = ""
var cat_display_name: String = ""
var max_hp: int = 100
var current_hp: int = 100
var cat_file_id: String = ""

var _body_rect: ColorRect
var _animated_sprite: AnimatedSprite2D
var _hp_bar_bg: ColorRect
var _hp_bar_fill: ColorRect
var _name_label: Label
var _active_animation: String = ""
var _revert_timer: SceneTreeTimer
var _revert_token: int = 0

const BODY_W := 56.0
const BODY_H := 72.0
const HP_BAR_W := 64.0
const HP_BAR_H := 8.0
const FRAME_SIZE := Vector2i(160, 160)
const FRAME_COUNT := 6
const SPRITE_TARGET_SIZE := Vector2(56.0, 72.0)


func setup(id: int, team_name: String, name_str: String, hp: int, file_id: String = "") -> void:
	instance_id = id
	team = team_name
	cat_display_name = name_str
	max_hp = hp
	current_hp = hp
	cat_file_id = file_id
	_build_visuals()


func _build_visuals() -> void:
	_build_body()

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_bg.position = Vector2(-HP_BAR_W / 2.0, -BODY_H - 14.0)
	_hp_bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	add_child(_hp_bar_bg)

	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_fill.position = _hp_bar_bg.position
	_hp_bar_fill.color = Color(0.2, 0.9, 0.3, 1.0)
	add_child(_hp_bar_fill)

	_name_label = Label.new()
	_name_label.text = cat_display_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(-HP_BAR_W / 2.0, -BODY_H - 32.0)
	_name_label.size = Vector2(HP_BAR_W, 20.0)
	_name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
	add_child(_name_label)

	play_idle()


func _build_body() -> void:
	var frames := _build_sprite_frames()
	if frames != null:
		var visible_rect := _get_visible_rect_for_alignment()
		_animated_sprite = AnimatedSprite2D.new()
		_animated_sprite.sprite_frames = frames
		_animated_sprite.centered = true
		var visible_size := Vector2(maxf(1.0, visible_rect.size.x), maxf(1.0, visible_rect.size.y))
		var scale_ratio := minf(
			SPRITE_TARGET_SIZE.x / visible_size.x,
			SPRITE_TARGET_SIZE.y / visible_size.y
		)
		_animated_sprite.scale = Vector2(scale_ratio, scale_ratio)
		var frame_center := Vector2(float(FRAME_SIZE.x) * 0.5, float(FRAME_SIZE.y) * 0.5)
		var visible_center_x := visible_rect.position.x + visible_rect.size.x * 0.5
		var visible_bottom_y := visible_rect.position.y + visible_rect.size.y
		_animated_sprite.position = Vector2(
			-(visible_center_x - frame_center.x) * scale_ratio,
			-(visible_bottom_y - frame_center.y) * scale_ratio
		)
		_animated_sprite.flip_h = team != "player"
		_animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		add_child(_animated_sprite)
		return

	_body_rect = ColorRect.new()
	_body_rect.size = Vector2(BODY_W, BODY_H)
	_body_rect.position = Vector2(-BODY_W / 2.0, -BODY_H)
	_body_rect.color = Color(0.2, 0.5, 0.9, 1.0) if team == "player" else Color(0.9, 0.3, 0.2, 1.0)
	add_child(_body_rect)


func _build_sprite_frames() -> SpriteFrames:
	var idle_path := AssetResolver.resolve_cat_battle_animation_path(cat_file_id, "idle")
	if idle_path == "":
		return null

	var frames := SpriteFrames.new()
	for animation_name: String in ["idle", "run", "collide", "knockback", "stagger", "skill", "death_fly"]:
		var sheet_path := AssetResolver.resolve_cat_battle_animation_path(cat_file_id, animation_name)
		var sheet := AssetResolver.load_texture(sheet_path)
		if sheet == null:
			continue
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 12.0)
		frames.set_animation_loop(animation_name, animation_name == "idle" or animation_name == "run")
		for frame_index in range(FRAME_COUNT):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(frame_index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
			atlas.filter_clip = true
			frames.add_frame(animation_name, atlas)
	return frames


func _get_visible_rect_for_alignment() -> Rect2:
	var idle_path := AssetResolver.resolve_cat_battle_animation_path(cat_file_id, "idle")
	var idle_sheet := AssetResolver.load_texture(idle_path)
	if idle_sheet == null:
		return Rect2(Vector2.ZERO, Vector2(FRAME_SIZE))
	var image := idle_sheet.get_image()
	if image == null:
		return Rect2(Vector2.ZERO, Vector2(FRAME_SIZE))
	var frame_image := image.get_region(Rect2i(0, 0, FRAME_SIZE.x, FRAME_SIZE.y))
	var used_rect := frame_image.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Rect2(Vector2.ZERO, Vector2(FRAME_SIZE))
	return Rect2(used_rect.position, used_rect.size)


func update_hp(hp: int) -> void:
	current_hp = maxi(0, hp)
	var ratio := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	_hp_bar_fill.size.x = HP_BAR_W * ratio
	_hp_bar_fill.color = Color(1.0 - ratio, ratio * 0.9, 0.1, 1.0)


func show_damage_number(damage: int) -> void:
	if damage <= 0:
		return
	var dmg_label := Label.new()
	dmg_label.text = "-" + str(damage)
	dmg_label.position = Vector2(-HP_BAR_W / 2.0, -BODY_H - 32.0)
	dmg_label.size = Vector2(HP_BAR_W, 20.0)
	dmg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmg_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_BODY)
	dmg_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 1))
	dmg_label.add_theme_constant_override("outline_size", 2)
	if team == "player":
		dmg_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
	else:
		dmg_label.add_theme_color_override("font_color", Color(0.7, 0.3, 1.0, 1))
	add_child(dmg_label)

	var tween := create_tween()
	tween.tween_property(dmg_label, "position:y", dmg_label.position.y - 24.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(dmg_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func():
		if is_instance_valid(dmg_label):
			dmg_label.queue_free()
	)


func move_to(target_x: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:x", target_x, 0.12).set_ease(Tween.EASE_OUT)


func play_idle() -> void:
	_play_loop("idle")


func play_run() -> void:
	_play_loop("run")


func play_collision(knockback: float = 0.0) -> void:
	if absf(knockback) >= 18.0:
		_play_temporary("knockback", 0.32)
	else:
		_play_temporary("collide", 0.24)


func play_stagger() -> void:
	_play_temporary("stagger", 0.28)


func play_skill() -> void:
	_play_temporary("skill", 0.35)


func play_death() -> void:
	_cancel_revert()
	if _has_animation("death_fly"):
		_active_animation = "death_fly"
		_animated_sprite.play("death_fly")

	var dir := -1.0 if team == "player" else 1.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:x", position.x + dir * 400.0, 0.8)
	tween.tween_property(self, "position:y", position.y - 200.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "position:y", position.y + 600.0, 0.4).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		died.emit(self)
		queue_free()
	)


func flash_skill() -> void:
	play_skill()
	var target: CanvasItem = _animated_sprite if _animated_sprite != null else _body_rect
	if target == null:
		return
	var tween := create_tween()
	tween.tween_property(target, "modulate:a", 0.3, 0.1)
	tween.tween_property(target, "modulate:a", 1.0, 0.1)
	tween.tween_property(target, "modulate:a", 0.3, 0.1)
	tween.tween_property(target, "modulate:a", 1.0, 0.1)


func _play_loop(animation_name: String) -> void:
	if not _has_animation(animation_name):
		return
	_cancel_revert()
	if _active_animation == animation_name:
		return
	_active_animation = animation_name
	_animated_sprite.play(animation_name)


func _play_temporary(animation_name: String, duration: float) -> void:
	if not _has_animation(animation_name):
		return
	_cancel_revert()
	_revert_token += 1
	var revert_token := _revert_token
	_active_animation = animation_name
	_animated_sprite.play(animation_name)
	_revert_timer = get_tree().create_timer(duration)
	_revert_timer.timeout.connect(func():
		if revert_token != _revert_token:
			return
		_revert_timer = null
		play_run()
	, CONNECT_ONE_SHOT)


func _cancel_revert() -> void:
	_revert_token += 1
	_revert_timer = null


func _has_animation(animation_name: String) -> bool:
	return _animated_sprite != null and _animated_sprite.sprite_frames != null and _animated_sprite.sprite_frames.has_animation(animation_name)
