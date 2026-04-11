extends Node
class_name InertialScroller

# ── Config ─────────────────────────────────────────────

const DEFAULT_FRICTION      := 5.0
const DEFAULT_MIN_VELOCITY  := 0.5
const DEFAULT_DRAG_THRESHOLD := 8.0

# 手感調整（你可以之後自己微調）
const MAX_VELOCITY := 4000.0
const RESISTANCE_FACTOR := 0.25
const SPRING_BACK_SPEED := 15.0
const HAPTIC_DURATION_MS := 20
const HAPTIC_COOLDOWN_MS := 250
const HAPTIC_INTENSITY := 80.0

var target: ScrollContainer = null
var axis: String = "vertical"

var dragging: bool = false
var moved: bool = false
var velocity: float = 0.0

var friction: float = DEFAULT_FRICTION
var min_velocity: float = DEFAULT_MIN_VELOCITY
var drag_threshold: float = DEFAULT_DRAG_THRESHOLD

# drag state
var _last_pos: float = 0.0
var _drag_accum: float = 0.0
var _last_ev_time_us: int = 0
var _last_velocity_sample: float = 0.0
var fade_timer: Timer
var is_scrolling: bool = false
var _last_haptic_us: int = 0
var _last_boundary_state: int = 0 # -1 = over top/left, 0 = inside, 1 = over bottom/right

# ── Static attach ──────────────────────────────────────

static func attach(
	scroll: ScrollContainer,
	axis_in: String = "vertical"
) -> InertialScroller:
	if scroll == null:
		return null

	if scroll.has_meta("inertial_scroller"):
		return scroll.get_meta("inertial_scroller")

	var inst := InertialScroller.new()
	scroll.add_child(inst)

	inst.target = scroll
	inst.axis = axis_in
	inst._init_attach()

	scroll.set_meta("inertial_scroller", inst)
	return inst

# ── Init ───────────────────────────────────────────────

func _init_attach() -> void:
	set_process(true)
	target.mouse_filter = Control.MOUSE_FILTER_STOP

	# ❗重點：預設不顯示，但在互動時顯示（auto）
	target.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	target.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	fade_timer = Timer.new()
	fade_timer.wait_time = 0.5
	fade_timer.one_shot = true
	fade_timer.timeout.connect(_fade_scrollbar)
	add_child(fade_timer)

	_force_hide_scrollbars()

# ── Helpers ────────────────────────────────────────────

func _get_pos(event: InputEvent) -> float:
	return event.position.y if axis == "vertical" else event.position.x

func _get_scroll() -> float:
	return target.get_v_scroll() if axis == "vertical" else target.get_h_scroll()

func _set_scroll(v: float) -> void:
	if axis == "vertical":
		target.set_v_scroll(roundi(v))
	else:
		target.set_h_scroll(roundi(v))

func _get_max_scroll() -> float:
	# Use actual rendered sizes — most accurate and avoids scrollbar timing issues
	if axis == "vertical":
		return max(target.get_v_scroll_bar().max_value - target.get_v_scroll_bar().page, 0.0)
	else:
		return max(target.get_h_scroll_bar().max_value - target.get_h_scroll_bar().page, 0.0)


func _event_inside_target(event: InputEvent) -> bool:
	if target == null:
		return false
	if not (event is InputEventMouseButton \
		or event is InputEventMouseMotion \
		or event is InputEventScreenTouch \
		or event is InputEventScreenDrag):
		return false
	return target.get_global_rect().has_point(event.position)

# ── Input ──────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if target == null:
		return

	# press
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
	or (event is InputEventScreenTouch and event.pressed):
		if not _event_inside_target(event):
			return

		dragging = true
		velocity = 0.0
		_last_velocity_sample = 0.0
		moved = false
		_drag_accum = 0.0
		_last_pos = _get_pos(event)
		_last_ev_time_us = Time.get_ticks_usec()
		_show_scrollbar()
		return

	# release
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) \
	or (event is InputEventScreenTouch and not event.pressed):

		if not dragging:
			return
		dragging = false
		if moved:
			velocity = clamp(_last_velocity_sample, -MAX_VELOCITY, MAX_VELOCITY)
			_show_scrollbar()
		return

	# motion
	if not ((event is InputEventMouseMotion and dragging) or (event is InputEventScreenDrag and dragging)):
		return
	if not _event_inside_target(event):
		return

	var now_us = Time.get_ticks_usec()
	var dt = float(now_us - _last_ev_time_us) / 1_000_000.0

	var cur_pos = _get_pos(event)
	var delta = cur_pos - _last_pos

	_last_pos = cur_pos
	_last_ev_time_us = now_us

	_drag_accum += abs(delta)
	if _drag_accum > drag_threshold:
		moved = true
	else:
		# 尚未超過拖曳門檻時，不攔截按鈕點擊，也不移動 scroll。
		return

	# 使用 desired-scroll 計算 overscroll，以避免方向或 max_scroll 推論錯誤
	var cur_scroll := _get_scroll()
	var max_s = max(_get_max_scroll(), 0.0)
	var desired = cur_scroll - delta

	if desired < 0.0:
		# moved beyond top; clamp scroll
		_set_scroll(0.0)
	elif desired > max_s:
		# moved beyond bottom/right; clamp
		_set_scroll(max_s)
	else:
		_set_scroll(desired)

	# 顯示 scrollbar（互動期間顯示）
	_show_scrollbar()

	# ✨ velocity 計算（升級版）
	if dt > 0.0005:
		var v_sample = -delta / dt
		_last_velocity_sample = v_sample
		velocity = lerp(velocity, v_sample, 0.6)
		velocity = clamp(velocity, -MAX_VELOCITY, MAX_VELOCITY)

	get_viewport().set_input_as_handled()

# ── Process（核心手感）────────────────────────────────

func _process(delta: float) -> void:
	if target == null:
		queue_free()
		return

	# ── 拖曳中 ──────────────────────────────────────────
	if dragging:
		_show_scrollbar()
		return

	# ── 正常慣性滑動 ─────────────────────────────────────
	_last_boundary_state = 0

	if abs(velocity) <= min_velocity:
		velocity = 0.0
		if is_scrolling and not fade_timer.is_stopped():
			return
		if is_scrolling:
			_fade_scrollbar()
		return

	var scroll := _get_scroll()
	var max_scroll = max(_get_max_scroll(), 0.0)
	var desired := scroll + velocity * delta

	if desired < 0.0:
		# inertia would go past top
		_set_scroll(0.0)
		velocity = 0.0
		if _last_boundary_state != -1:
			_last_boundary_state = -1
			_do_haptic_feedback(-1)
		return
	elif desired > max_scroll:
		# inertia would go past bottom/right
		_set_scroll(max_scroll)
		velocity = 0.0
		if _last_boundary_state != 1:
			_last_boundary_state = 1
			_do_haptic_feedback(1)
		return
	else:
		_set_scroll(desired)
		var decay := pow(0.95, delta * 60.0)
		velocity *= decay
		_show_scrollbar()

func consume_moved() -> bool:
	var m := moved
	moved = false
	return m

func _force_hide_scrollbars():
	var vsb = target.get_v_scroll_bar()
	var hsb = target.get_h_scroll_bar()

	if vsb:
		vsb.modulate.a = 0.0
	if hsb:
		hsb.modulate.a = 0.0

func _show_scrollbar():
	if fade_timer == null:
		return
	var vsb = target.get_v_scroll_bar()
	var hsb = target.get_h_scroll_bar()

	if axis == "vertical":
		if vsb:
			vsb.modulate.a = 0.9
		if hsb:
			hsb.modulate.a = 0.0
	else:
		if hsb:
			hsb.modulate.a = 0.9
		if vsb:
			vsb.modulate.a = 0.0

	is_scrolling = true
	fade_timer.start()

func _fade_scrollbar():
	if target == null:
		return
	var vsb = target.get_v_scroll_bar()
	var hsb = target.get_h_scroll_bar()

	var tween = create_tween()

	if axis == "vertical" and vsb:
		tween.tween_property(vsb, "modulate:a", 0.0, 0.4)
	elif axis == "horizontal" and hsb:
		tween.tween_property(hsb, "modulate:a", 0.0, 0.4)

	is_scrolling = false

func _do_haptic_feedback(_direction: int) -> void:
	var now_us = Time.get_ticks_usec()
	if now_us - _last_haptic_us < HAPTIC_COOLDOWN_MS * 1000:
		return
	_last_haptic_us = now_us

	# 📳 真機震動（手機才有效）
	if Input.has_method("vibrate_handheld"):
		Input.callv("vibrate_handheld", [HAPTIC_DURATION_MS])
	elif OS.has_method("vibrate_handheld"):
		OS.callv("vibrate_handheld", [HAPTIC_DURATION_MS])
