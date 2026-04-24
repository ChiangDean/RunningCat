class_name CatNode
extends Node2D

const DAMAGE_GRADIENT_SHADER := preload("res://scripts/ui/damage_number_gradient.gdshader")
const DAMAGE_NUMBER_FONT := preload("res://assets/fonts/Fredoka/Fredoka-Bold.ttf")

signal died(node: CatNode)

var instance_id: int = -1
var team: String = ""
var cat_display_name: String = ""
var max_hp: int = 100
var current_hp: int = 100
var cat_file_id: String = ""

var _body_rect: ColorRect
var _shadow_polygon: Polygon2D
var _animated_sprite: AnimatedSprite2D
var _static_sprite: Sprite2D
var _hp_bar_bg: ColorRect
var _hp_bar_fill: ColorRect
var _name_label: Label
var _active_animation: String = ""
var _move_tween: Tween
var _revert_timer: SceneTreeTimer
var _revert_token: int = 0
var _damage_pop_index: int = 0
var _damage_rng: RandomNumberGenerator = RandomNumberGenerator.new()

const BODY_W := 56.0
const BODY_H := 72.0
const HP_BAR_W := 64.0
const HP_BAR_H := 8.0
const SPRITE_TARGET_W := 96.0
const SPRITE_TARGET_H := 128.0
const SPRITE_TARGET_SIZE := Vector2(SPRITE_TARGET_W, SPRITE_TARGET_H)
const SPRITE_VERTICAL_OFFSET_Y := 10.0
const SHADOW_RADIUS_X := 28.0
const SHADOW_RADIUS_Y := 9.0
const SHADOW_OFFSET_Y := -10.0
const SHADOW_POINT_COUNT := 20
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.22)
const HP_BAR_OFFSET_Y := 170.0
const NAME_LABEL_OFFSET_Y := 198.0
const DAMAGE_DIGIT_SPACING := 18.0
const DAMAGE_POP_BASE_Y := 172.0
const DAMAGE_POP_STACK_STEP := 18.0
const DAMAGE_POP_LIFETIME := 0.52
const DAMAGE_POP_FLOAT_Y := 54.0
const DAMAGE_POP_DRIFT_X := 18.0
const DAMAGE_TEAM_OFFSET_X := 10.0
const DAMAGE_POP_LABEL_W := 40.0
const DAMAGE_POP_LABEL_H := 42.0
const DAMAGE_DIGIT_DELAY := 0.05
const DEATH_ARC_MIN_X := 400.0
const DEATH_ARC_MAX_X := 1000.0
const DEATH_ARC_MIN_HEIGHT := 400.0
const DEATH_ARC_MAX_HEIGHT := 800.0
const DEATH_ARC_MIN_DURATION := 0.7
const DEATH_ARC_MAX_DURATION := 1.2
const DEATH_ROLL_MIN_TURNS := 1.5
const DEATH_ROLL_MAX_TURNS := 3.0


func setup(id: int, team_name: String, name_str: String, hp: int, file_id: String = "") -> void:
	instance_id = id
	team = team_name
	cat_display_name = name_str
	max_hp = hp
	current_hp = hp
	cat_file_id = file_id
	_damage_rng.randomize()
	_build_visuals()
	reset_for_spawn()


func reset_for_spawn() -> void:
	_cancel_revert()
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = null
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	visible = true
	if _animated_sprite != null:
		_animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_animated_sprite.scale = Vector2(absf(_animated_sprite.scale.x), absf(_animated_sprite.scale.y))
	if _static_sprite != null:
		_static_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_static_sprite.scale = Vector2(absf(_static_sprite.scale.x), absf(_static_sprite.scale.y))
	if _body_rect != null:
		_body_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_body_rect.scale = Vector2.ONE
	if _hp_bar_bg != null:
		_hp_bar_bg.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_hp_bar_bg.scale = Vector2.ONE
	if _hp_bar_fill != null:
		_hp_bar_fill.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_hp_bar_fill.scale = Vector2.ONE
	if _name_label != null:
		_name_label.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _build_visuals() -> void:
	_build_body()

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_bg.position = Vector2(-HP_BAR_W / 2.0, -HP_BAR_OFFSET_Y)
	_hp_bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	add_child(_hp_bar_bg)

	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_fill.position = _hp_bar_bg.position
	_hp_bar_fill.color = Color(0.2, 0.9, 0.3, 1.0)
	add_child(_hp_bar_fill)
	_hp_bar_bg.visible = false
	_hp_bar_fill.visible = false

	_name_label = Label.new()
	_name_label.text = cat_display_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(-HP_BAR_W / 2.0, -NAME_LABEL_OFFSET_Y)
	_name_label.size = Vector2(HP_BAR_W, 20.0)
	_name_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_TINY)
	add_child(_name_label)
	_name_label.visible = false

	play_idle()


func _build_body() -> void:
	_build_shadow()
	_build_animated_body()

	var sprite_texture: Texture2D = AssetResolver.resolve_cat_battle_static_art(cat_file_id)
	if sprite_texture != null:
		_static_sprite = Sprite2D.new()
		_static_sprite.texture = sprite_texture
		_static_sprite.centered = true
		_static_sprite.flip_h = team != "player"
		_static_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var visible_rect: Rect2 = _get_texture_visible_rect(sprite_texture)
		var safe_width: float = maxf(1.0, visible_rect.size.x)
		var safe_height: float = maxf(1.0, visible_rect.size.y)
		var scale_ratio: float = minf(
			SPRITE_TARGET_SIZE.x / safe_width,
			SPRITE_TARGET_SIZE.y / safe_height
		)
		_static_sprite.scale = Vector2(scale_ratio, scale_ratio)
		var texture_size: Vector2 = sprite_texture.get_size()
		var texture_center: Vector2 = texture_size * 0.5
		var visible_center_x: float = visible_rect.position.x + visible_rect.size.x * 0.5
		var visible_bottom_y: float = visible_rect.position.y + visible_rect.size.y
		_static_sprite.position = Vector2(
			-(visible_center_x - texture_center.x) * scale_ratio,
			-(visible_bottom_y - texture_center.y) * scale_ratio - SPRITE_VERTICAL_OFFSET_Y
		)
		_static_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		add_child(_static_sprite)
		return

	_body_rect = ColorRect.new()
	_body_rect.size = Vector2(BODY_W, BODY_H)
	_body_rect.position = Vector2(-BODY_W / 2.0, -BODY_H)
	_body_rect.color = Color(0.2, 0.5, 0.9, 1.0) if team == "player" else Color(0.9, 0.3, 0.2, 1.0)
	add_child(_body_rect)


func _build_shadow() -> void:
	_shadow_polygon = Polygon2D.new()
	_shadow_polygon.position = Vector2(0.0, SHADOW_OFFSET_Y)
	_shadow_polygon.color = SHADOW_COLOR
	_shadow_polygon.antialiased = true
	var points: PackedVector2Array = PackedVector2Array()
	for point_index: int in range(SHADOW_POINT_COUNT):
		var angle_ratio: float = float(point_index) / float(SHADOW_POINT_COUNT)
		var angle: float = TAU * angle_ratio
		points.append(Vector2(cos(angle) * SHADOW_RADIUS_X, sin(angle) * SHADOW_RADIUS_Y))
	_shadow_polygon.polygon = points
	add_child(_shadow_polygon)


func _build_animated_body() -> void:
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	var preview_texture: Texture2D = null
	for animation_name: String in AssetResolver.get_cat_battle_animation_names():
		var animation_path: String = AssetResolver.resolve_cat_battle_animation_path(cat_file_id, animation_name)
		if animation_path == "":
			continue

		var sheet_texture: Texture2D = AssetResolver.load_texture(animation_path)
		if sheet_texture == null:
			continue

		var animation_spec: Dictionary = AssetResolver.resolve_cat_battle_animation_spec(cat_file_id, animation_name)
		var sheet_width: int = int(animation_spec.get("sheet_width", sheet_texture.get_width()))
		var sheet_height: int = int(animation_spec.get("sheet_height", sheet_texture.get_height()))
		var frame_width: int = int(animation_spec.get("frame_width", 0))
		var frame_height: int = int(animation_spec.get("frame_height", sheet_texture.get_height()))
		var fps: float = float(animation_spec.get("fps", 12.0))
		var should_loop: bool = bool(animation_spec.get("loop", false))
		if sheet_width <= 0 or sheet_height <= 0 or frame_width <= 0 or frame_height <= 0:
			continue

		var effective_sheet_width: int = mini(sheet_texture.get_width(), sheet_width)
		var effective_sheet_height: int = mini(sheet_texture.get_height(), sheet_height)
		var effective_frame_height: int = mini(frame_height, effective_sheet_height)
		var frame_count: int = floori(float(effective_sheet_width) / float(frame_width))
		if frame_count <= 0:
			continue

		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_loop(animation_name, should_loop)
		sprite_frames.set_animation_speed(animation_name, fps)
		for frame_index: int in range(frame_count):
			var atlas_texture: AtlasTexture = AtlasTexture.new()
			atlas_texture.atlas = sheet_texture
			atlas_texture.region = Rect2(
				float(frame_index * frame_width),
				0.0,
				float(frame_width),
				float(effective_frame_height)
			)
			sprite_frames.add_frame(animation_name, atlas_texture)
			if preview_texture == null:
				preview_texture = atlas_texture

	if preview_texture == null:
		return

	_animated_sprite = AnimatedSprite2D.new()
	_animated_sprite.sprite_frames = sprite_frames
	_animated_sprite.centered = true
	_animated_sprite.flip_h = team != "player"
	_animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_animated_sprite.visible = false

	var visible_rect: Rect2 = _get_texture_visible_rect(preview_texture)
	var safe_width: float = maxf(1.0, visible_rect.size.x)
	var safe_height: float = maxf(1.0, visible_rect.size.y)
	var scale_ratio: float = minf(
		SPRITE_TARGET_SIZE.x / safe_width,
		SPRITE_TARGET_SIZE.y / safe_height
	)
	_animated_sprite.scale = Vector2(scale_ratio, scale_ratio)
	var texture_size: Vector2 = preview_texture.get_size()
	var texture_center: Vector2 = texture_size * 0.5
	var visible_center_x: float = visible_rect.position.x + visible_rect.size.x * 0.5
	var visible_bottom_y: float = visible_rect.position.y + visible_rect.size.y
	_animated_sprite.position = Vector2(
		-(visible_center_x - texture_center.x) * scale_ratio,
		-(visible_bottom_y - texture_center.y) * scale_ratio - SPRITE_VERTICAL_OFFSET_Y
	)
	add_child(_animated_sprite)


func _get_texture_visible_rect(texture: Texture2D) -> Rect2:
	var texture_size: Vector2 = texture.get_size()
	var image: Image = texture.get_image()
	if image == null:
		return Rect2(Vector2.ZERO, texture_size)
	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Rect2(Vector2.ZERO, texture_size)
	return Rect2(Vector2(used_rect.position), Vector2(used_rect.size))

func update_hp(hp: int) -> void:
	current_hp = maxi(0, hp)
	var ratio := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	_hp_bar_fill.size.x = HP_BAR_W * ratio
	_hp_bar_fill.color = Color(1.0 - ratio, ratio * 0.9, 0.1, 1.0)


func show_damage_number(damage: int) -> void:
	if damage <= 0:
		return
	if not SceneNavigator.get_current_overlay_scene_path().is_empty():
		return
	var pop_root := Node2D.new()
	var stack_slot: int = _damage_pop_index % 4
	_damage_pop_index += 1
	var anchor_offset := Vector2(
		(_damage_rng.randf_range(-10.0, 10.0) - DAMAGE_TEAM_OFFSET_X) if team == "player" else (_damage_rng.randf_range(-10.0, 10.0) + DAMAGE_TEAM_OFFSET_X),
		-DAMAGE_POP_BASE_Y - float(stack_slot) * DAMAGE_POP_STACK_STEP
	)
	pop_root.top_level = false
	pop_root.z_as_relative = false
	pop_root.z_index = 1
	var damage_host: Node = self
	var battle_scene: Node = get_tree().get_first_node_in_group("battle_scene")
	if battle_scene != null and battle_scene.has_method("get_damage_fx_host"):
		damage_host = battle_scene.call("get_damage_fx_host")
	elif battle_scene != null:
		damage_host = battle_scene
	damage_host.add_child(pop_root)
	pop_root.global_position = global_position + anchor_offset
	pop_root.rotation = deg_to_rad(_damage_rng.randf_range(-4.0, 4.0))
	pop_root.scale = Vector2(0.45, 0.45)

	var palette: Dictionary = _get_damage_palette()
	var damage_text: String = str(damage)
	var digit_count: int = damage_text.length()
	var total_width: float = maxf(0.0, float(digit_count - 1) * DAMAGE_DIGIT_SPACING)
	var label_nodes: Array[Control] = []
	for i in range(digit_count):
		var digit_text: String = damage_text.substr(i, 1)
		var digit_x: float = float(i) * DAMAGE_DIGIT_SPACING - total_width * 0.5
		var digit_y: float = sin(float(i) * 0.85) * 4.0
		var nodes: Array[Control] = _add_damage_digit(
			pop_root,
			digit_text,
			Vector2(digit_x, digit_y),
			palette.get("front_top", Color.WHITE),
			palette.get("front_mid", Color.WHITE),
			palette.get("front_bottom", Color.WHITE),
			palette.get("outline", Color.BLACK),
			float(i) * DAMAGE_DIGIT_DELAY
		)
		label_nodes.append_array(nodes)

	_play_hit_feedback()

	var drift_target_x: float = _damage_rng.randf_range(-DAMAGE_POP_DRIFT_X, DAMAGE_POP_DRIFT_X)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pop_root, "scale", Vector2(1.22, 1.22), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for label_node: Control in label_nodes:
		if label_node == null:
			continue
		var start_pos: Vector2 = label_node.position
		var offset_x: float = drift_target_x
		var fade_delay: float = 0.24 + float(label_node.get_meta("digit_delay", 0.0))
		tween.tween_property(label_node, "position:y", start_pos.y - DAMAGE_POP_FLOAT_Y, DAMAGE_POP_LIFETIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(label_node, "position:x", start_pos.x + offset_x, DAMAGE_POP_LIFETIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(label_node, "modulate:a", 0.0, 0.18).set_delay(fade_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(pop_root, "scale", Vector2(0.96, 0.96), 0.12).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(Callable(pop_root, "queue_free"))


func move_to(
		target_x: float,
		duration: float = 0.12,
		transition_type: Tween.TransitionType = Tween.TRANS_SINE,
		ease_type: Tween.EaseType = Tween.EASE_OUT) -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position:x", target_x, duration).set_trans(transition_type).set_ease(ease_type)


func play_idle() -> void:
	_cancel_revert()
	_active_animation = "idle"
	if _has_animation("idle"):
		_set_animation_visual_active(true)
		_animated_sprite.play("idle")
		return
	_set_animation_visual_active(false)


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


func play_wall_counter(target_x: float, arc_height: float, duration: float) -> void:
	_play_temporary("knockback", duration)
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	var start_position: Vector2 = position
	var end_position: Vector2 = Vector2(target_x, 0.0)
	var roll_dir: float = -1.0 if team == "player" else 1.0
	var end_rotation: float = rotation + roll_dir * TAU
	_move_tween = create_tween()
	_move_tween.set_parallel(true)
	_move_tween.tween_method(
		Callable(self, "_set_wall_counter_arc_progress").bind(start_position, end_position, arc_height),
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "rotation", end_rotation, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_move_tween.chain().tween_callback(Callable(self, "_finish_wall_counter_arc"))


func play_death() -> void:
	_cancel_revert()
	if _has_animation("death_fly"):
		_active_animation = "death_fly"
		_set_animation_visual_active(true)
		_animated_sprite.play("death_fly")

	var dir: float = -1.0 if team == "player" else 1.0
	var start_position: Vector2 = position
	var end_position: Vector2 = start_position + Vector2(
		dir * _damage_rng.randf_range(DEATH_ARC_MIN_X, DEATH_ARC_MAX_X),
		_damage_rng.randf_range(DEATH_ARC_MIN_HEIGHT, DEATH_ARC_MAX_HEIGHT)
	)
	var peak_height: float = _damage_rng.randf_range(DEATH_ARC_MIN_HEIGHT, DEATH_ARC_MAX_HEIGHT)
	var flight_duration: float = _damage_rng.randf_range(DEATH_ARC_MIN_DURATION, DEATH_ARC_MAX_DURATION)
	var roll_turns: float = _damage_rng.randf_range(DEATH_ROLL_MIN_TURNS, DEATH_ROLL_MAX_TURNS)
	var end_rotation: float = rotation + dir * TAU * roll_turns
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(
		Callable(self, "_set_death_arc_progress").bind(start_position, end_position, peak_height),
		0.0,
		1.0,
		flight_duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation", end_rotation, flight_duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(Callable(self, "_on_death_tween_finished"))


func flash_skill() -> void:
	play_skill()
	var target: Variant = null
	if _animated_sprite != null and _animated_sprite.visible:
		target = _animated_sprite
	else:
		target = _static_sprite
	if target == null:
		target = _body_rect
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
		_set_animation_visual_active(true)
		if not _animated_sprite.is_playing():
			_animated_sprite.play(animation_name)
		return
	_active_animation = animation_name
	_set_animation_visual_active(true)
	_animated_sprite.play(animation_name)


func _play_temporary(animation_name: String, duration: float) -> void:
	if not _has_animation(animation_name):
		return
	_cancel_revert()
	_revert_token += 1
	var revert_token := _revert_token
	_active_animation = animation_name
	_set_animation_visual_active(true)
	_animated_sprite.play(animation_name)
	_revert_timer = get_tree().create_timer(duration)
	_revert_timer.timeout.connect(Callable(self, "_on_revert_timer_timeout").bind(revert_token), CONNECT_ONE_SHOT)


func _cancel_revert() -> void:
	_revert_token += 1
	_revert_timer = null


func _set_death_arc_progress(progress: float, start_position: Vector2, end_position: Vector2, peak_height: float) -> void:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var linear_position: Vector2 = start_position.lerp(end_position, clamped_progress)
	var arc_offset_y: float = -4.0 * peak_height * clamped_progress * (1.0 - clamped_progress)
	position = linear_position + Vector2(0.0, arc_offset_y)


func _set_wall_counter_arc_progress(progress: float, start_position: Vector2, end_position: Vector2, peak_height: float) -> void:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var linear_position: Vector2 = start_position.lerp(end_position, clamped_progress)
	var arc_offset_y: float = -4.0 * peak_height * clamped_progress * (1.0 - clamped_progress)
	position = linear_position + Vector2(0.0, arc_offset_y)


func _finish_wall_counter_arc() -> void:
	position.y = 0.0
	rotation = 0.0


func _on_death_tween_finished() -> void:
	died.emit(self)
	queue_free()


func _on_revert_timer_timeout(revert_token: int) -> void:
	if revert_token != _revert_token:
		return
	_revert_timer = null
	play_run()


func _has_animation(animation_name: String) -> bool:
	return _animated_sprite != null and _animated_sprite.sprite_frames != null and _animated_sprite.sprite_frames.has_animation(animation_name)


func _set_animation_visual_active(is_active: bool) -> void:
	if _animated_sprite != null:
		_animated_sprite.visible = is_active
		if not is_active:
			_animated_sprite.stop()
	if _static_sprite != null:
		_static_sprite.visible = not is_active
	if _body_rect != null:
		_body_rect.visible = not is_active


func _get_damage_palette() -> Dictionary:
	if team == "player":
		return {
			"front_top": Color(1.0, 0.82, 0.98, 1.0),
			"front_mid": Color(0.96, 0.34, 0.88, 1.0),
			"front_bottom": Color(0.56, 0.10, 0.84, 1.0),
			"outline": Color(0.42, 0.03, 0.03, 1.0),
		}
	return {
		"front_top": Color(1.0, 0.62, 0.26, 1.0),
		"front_mid": Color(1.0, 0.24, 0.14, 1.0),
		"front_bottom": Color(0.78, 0.04, 0.06, 1.0),
		"outline": Color(0.53, 0.19, 0.0, 1.0),
	}


func _add_damage_digit(parent_node: Node2D, damage_text: String, digit_position: Vector2,
		front_top_color: Color, front_mid_color: Color, front_bottom_color: Color,
		_outline_color: Color,
		digit_delay: float) -> Array[Control]:
	var digit_rotation: float = deg_to_rad(_damage_rng.randf_range(-8.0, 8.0))
	var black_outline_label := Label.new()
	black_outline_label.name = "DamageBlackOutline%s" % damage_text
	black_outline_label.text = damage_text
	black_outline_label.position = digit_position
	black_outline_label.size = Vector2(DAMAGE_POP_LABEL_W, DAMAGE_POP_LABEL_H)
	black_outline_label.rotation = digit_rotation
	black_outline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	black_outline_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	black_outline_label.add_theme_font_override("font", DAMAGE_NUMBER_FONT)
	black_outline_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING + 15)
	black_outline_label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.0))
	black_outline_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	black_outline_label.add_theme_constant_override("outline_size", 10)
	black_outline_label.modulate.a = 0.0
	black_outline_label.set_meta("digit_delay", digit_delay)
	parent_node.add_child(black_outline_label)

	var front_label := Label.new()
	front_label.name = "DamageLabel%s" % damage_text
	front_label.text = damage_text
	front_label.position = digit_position
	front_label.size = Vector2(DAMAGE_POP_LABEL_W, DAMAGE_POP_LABEL_H)
	front_label.rotation = digit_rotation
	front_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	front_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	front_label.add_theme_font_override("font", DAMAGE_NUMBER_FONT)
	front_label.add_theme_font_size_override("font_size", UiPalette.FONT_SIZE_HEADING + 15)
	front_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	front_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 1.0))
	front_label.add_theme_constant_override("outline_size", 6)
	front_label.modulate.a = 0.0
	front_label.set_meta("digit_delay", digit_delay)
	var gradient_material := ShaderMaterial.new()
	gradient_material.shader = DAMAGE_GRADIENT_SHADER
	gradient_material.set_shader_parameter("top_color", front_top_color)
	gradient_material.set_shader_parameter("mid_color", front_mid_color)
	gradient_material.set_shader_parameter("bottom_color", front_bottom_color)
	front_label.material = gradient_material
	parent_node.add_child(front_label)

	var reveal_tween: Tween = create_tween()
	reveal_tween.set_parallel(true)
	reveal_tween.tween_property(front_label, "modulate:a", 1.0, 0.04).set_delay(digit_delay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(black_outline_label, "modulate:a", 1.0, 0.04).set_delay(digit_delay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(front_label, "scale", Vector2(1.16, 1.16), 0.08).set_delay(digit_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(black_outline_label, "scale", Vector2(1.16, 1.16), 0.08).set_delay(digit_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal_tween.chain().tween_property(front_label, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	reveal_tween.parallel().tween_property(black_outline_label, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return [black_outline_label, front_label]


func _play_hit_feedback() -> void:
	var body_target: Variant = null
	if _animated_sprite != null and _animated_sprite.visible:
		body_target = _animated_sprite
	else:
		body_target = _static_sprite
	if body_target == null:
		body_target = _body_rect
	if body_target != null:
		var body_base_position: Vector2 = body_target.position
		var body_base_scale: Vector2 = body_target.scale
		var body_tween: Tween = create_tween()
		body_tween.set_parallel(true)
		body_tween.tween_property(
			body_target,
			"position",
			body_base_position + Vector2(6.0 if team == "player" else -6.0, -4.0),
			0.05
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		body_tween.tween_property(
			body_target,
			"scale",
			Vector2(body_base_scale.x * 1.08, body_base_scale.y * 0.93),
			0.06
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		body_tween.tween_property(
			body_target,
			"modulate",
			Color(1.25, 1.25, 1.25, 1.0),
			0.04
		).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		body_tween.chain().tween_property(body_target, "position", body_base_position, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		body_tween.parallel().tween_property(body_target, "scale", body_base_scale, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		body_tween.parallel().tween_property(body_target, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if _hp_bar_fill != null:
		var hp_fill_base_scale: Vector2 = _hp_bar_fill.scale
		var hp_tween: Tween = create_tween()
		hp_tween.tween_property(_hp_bar_fill, "scale", Vector2(1.12, 1.35), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		hp_tween.tween_property(_hp_bar_fill, "scale", hp_fill_base_scale, 0.10).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
