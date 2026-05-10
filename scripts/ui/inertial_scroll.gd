extends Node
class_name InertialScroller

# ── Config ─────────────────────────────────────────────

const DEFAULT_FRICTION      := 5.0
const DEFAULT_MIN_VELOCITY  := 0.5
const DEFAULT_DRAG_THRESHOLD := 8.0

# Feel tweaks (adjust these to taste)
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
var _last_handled_event_id: int = 0
var _last_velocity_sample: float = 0.0
var fade_timer: Timer
var is_scrolling: bool = false
var _last_haptic_us: int = 0
var _last_boundary_state: int = 0 # -1 = over top/left, 0 = inside, 1 = over bottom/right
var _canvas_layer_depth: int = 0
var _drag_input_device: int = -99  # tracks which device started the drag

# ── Static registry — used for canvas-layer priority ───

static var _instances: Array[WeakRef] = []

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


static func detach(scroll: ScrollContainer) -> void:
	if scroll == null:
		return
	if not scroll.has_meta("inertial_scroller"):
		return

	var inst: Variant = scroll.get_meta("inertial_scroller")
	scroll.remove_meta("inertial_scroller")
	if inst is InertialScroller:
		var scroller: InertialScroller = inst as InertialScroller
		if is_instance_valid(scroller):
			scroller.queue_free()

# ── Init ───────────────────────────────────────────────

func _init_attach() -> void:
	set_process(true)
	target.mouse_filter = Control.MOUSE_FILTER_STOP

	# Disable Godot's built-in drag scrolling — InertialScroller owns all drag
	# positioning. Without this, ScrollContainer._gui_input() also moves the
	# scroll on every drag event, causing a double-move jump. Setting
	# scroll_deadzone to INT_MAX makes the native drag threshold unreachable.
	target.scroll_deadzone = 2147483647

	if not target.gui_input.is_connected(_on_target_gui_input):
		target.gui_input.connect(_on_target_gui_input)

	# Only override the managed axis; leave the other axis untouched so callers
	# can explicitly disable horizontal/vertical scrolling before attaching.
	if axis == "vertical":
		target.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	else:
		target.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	fade_timer = Timer.new()
	fade_timer.wait_time = 0.5
	fade_timer.one_shot = true
	fade_timer.timeout.connect(_fade_scrollbar)
	add_child(fade_timer)

	_force_hide_scrollbars()

	# Compute canvas layer depth for priority resolution
	_canvas_layer_depth = _compute_canvas_layer_depth()
	_instances.append(weakref(self))


func _exit_tree() -> void:
	# Remove self from the static registry
	for i in range(_instances.size() - 1, -1, -1):
		var ref: WeakRef = _instances[i]
		var inst = ref.get_ref()
		if inst == null or inst == self:
			_instances.remove_at(i)


func _enter_tree() -> void:
	# Recompute canvas layer depth when (re-)added to the tree, since the
	# scroller may have been attached before its ScrollContainer was parented
	# under the final CanvasLayer (e.g. DialogManager adds content later).
	_canvas_layer_depth = _compute_canvas_layer_depth()


func _compute_canvas_layer_depth() -> int:
	var depth: int = 0
	var node: Node = target
	while node:
		if node is CanvasLayer:
			depth = maxi(depth, node.layer)
		node = node.get_parent()
	return depth

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
	if not target.get_global_rect().has_point(event.position):
		return false
	if not target.is_visible_in_tree():
		return false
	return true


## Returns true if another visible InertialScroller covers the same point
## at a higher canvas layer, meaning this scroller should yield.
func _is_occluded_at(pos: Vector2) -> bool:
	for ref: WeakRef in _instances:
		var inst = ref.get_ref() as InertialScroller
		if inst == null or inst == self:
			continue
		if inst.target == null or not inst.target.is_visible_in_tree():
			continue
		if inst._canvas_layer_depth <= _canvas_layer_depth:
			continue
		if inst.target.get_global_rect().has_point(pos):
			return true
	return false

# ── Input ──────────────────────────────────────────────

# NOTE: We use ONLY gui_input (not _input) so that event positions are always
# in the same coordinate space as the ScrollContainer. Using _input() gives
# viewport-global coordinates which differ from gui_input's CanvasLayer-local
# coordinates, causing two PRESS events with different _last_pos values and a
# huge spurious delta on the first MOTION.

func _on_target_gui_input(event: InputEvent) -> void:
	_handle_scroll_input(event)


func _handle_scroll_input(event: InputEvent) -> void:
	if target == null:
		return
	var event_id: int = event.get_instance_id()
	if event_id == _last_handled_event_id:
		return

	# ── Skip touch-emulated mouse events to avoid double processing ──
	if dragging and _drag_input_device >= 0:
		if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device < 0:
			return

	# press
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) \
	or (event is InputEventScreenTouch and event.pressed):
		if not _event_inside_target(event):
			return
		if _is_occluded_at(event.position):
			return

		_last_handled_event_id = event_id
		dragging = true
		velocity = 0.0
		_last_velocity_sample = 0.0
		moved = false
		_drag_accum = 0.0
		_last_pos = _get_pos(event)
		_last_ev_time_us = Time.get_ticks_usec()
		_drag_input_device = event.device
		_show_scrollbar()
		return

	# release
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) \
	or (event is InputEventScreenTouch and not event.pressed):
		if not dragging:
			return
		_last_handled_event_id = event_id
		dragging = false
		_drag_input_device = -99
		if moved:
			velocity = clamp(_last_velocity_sample, -MAX_VELOCITY, MAX_VELOCITY)
			_show_scrollbar()
			get_viewport().set_input_as_handled()
		return

	# motion
	if not ((event is InputEventMouseMotion and dragging) or (event is InputEventScreenDrag and dragging)):
		return
	if not _event_inside_target(event):
		return
	_last_handled_event_id = event_id

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
		return

	var cur_scroll := _get_scroll()
	var max_s = max(_get_max_scroll(), 0.0)
	var desired = cur_scroll - delta

	if desired < 0.0:
		_set_scroll(0.0)
	elif desired > max_s:
		_set_scroll(max_s)
	else:
		_set_scroll(desired)

	_show_scrollbar()

	if dt > 0.0005:
		var v_sample = -delta / dt
		_last_velocity_sample = v_sample
		velocity = lerp(velocity, v_sample, 0.6)
		velocity = clamp(velocity, -MAX_VELOCITY, MAX_VELOCITY)

	get_viewport().set_input_as_handled()

# ── Process (core feel) ─────────────────────────────────

func _process(delta: float) -> void:
	if target == null:
		queue_free()
		return

	# ── Dragging ──────────────────────────────────────────
	if dragging:
		_show_scrollbar()
		return

	# ── Normal inertial scroll ─────────────────────────────────────
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
		vsb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hsb:
		hsb.modulate.a = 0.0
		hsb.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_scrollbar():
	if fade_timer == null:
		return
	var vsb = target.get_v_scroll_bar()
	var hsb = target.get_h_scroll_bar()

	# Always keep scrollbars non-interactive — InertialScroller owns scroll positioning.
	# Scrollbars are visual-only indicators.
	if vsb:
		vsb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hsb:
		hsb.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	# Haptic feedback (only works on real devices)
	if Input.has_method("vibrate_handheld"):
		Input.callv("vibrate_handheld", [HAPTIC_DURATION_MS])
	elif OS.has_method("vibrate_handheld"):
		OS.callv("vibrate_handheld", [HAPTIC_DURATION_MS])
