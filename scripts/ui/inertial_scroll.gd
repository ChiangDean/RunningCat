extends Node
class_name InertialScroller

# Attach to a ScrollContainer to provide touch/mouse inertia and boundary bounce.
# Usage: InertialScroller.attach(scroll_container)

const DEFAULT_FRICTION := 6.0
const DEFAULT_MIN_VELOCITY := 20.0
const DEFAULT_BOUNCE_SPEED := 6.0

var target: ScrollContainer = null
var velocity: float = 0.0
var dragging: bool = false
var friction: float = DEFAULT_FRICTION
var min_velocity: float = DEFAULT_MIN_VELOCITY
var bounce_speed: float = DEFAULT_BOUNCE_SPEED

static func attach(scroll: ScrollContainer) -> InertialScroller:
	if scroll == null:
		return null
	# reuse existing instance if already attached
	if scroll.has_meta("inertial_scroller"):
		return scroll.get_meta("inertial_scroller")
	var inst := InertialScroller.new()
	scroll.add_child(inst)
	inst.target = scroll
	inst._init_attach()
	scroll.set_meta("inertial_scroller", inst)
	return inst

func _init_attach() -> void:
	set_process(true)
	if target != null:
		# connect to control gui input to receive drag/touch/mouse events
		# connect using a Callable (Godot 4 API)
		target.gui_input.connect(Callable(self, "_on_gui_input"))
		# ensure the scroll container accepts events
		target.mouse_filter = Control.MOUSE_FILTER_STOP

func _find_v_scrollbar() -> ScrollBar:
	if target == null:
		return null
	# prefer built-in getter if present
	if target.has_method("get_v_scrollbar"):
		return target.get_v_scrollbar()

	# recursive search for a ScrollBar child (fallback)
	var found := _search_for_scrollbar(target)
	return found

func _search_for_scrollbar(node: Node) -> ScrollBar:
	for child in node.get_children():
		if child is ScrollBar:
			return child
		var res := _search_for_scrollbar(child)
		if res != null:
			return res
	return null

func _on_gui_input(event: InputEvent) -> void:
	if target == null:
		return
	var vbar: ScrollBar = _find_v_scrollbar()
	if vbar == null:
		return

	if event is InputEventScreenDrag:
		dragging = true
		var rel_y: float = event.relative.y
		vbar.value -= rel_y
		velocity = -rel_y * 60.0
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
			velocity = 0.0
		else:
			dragging = false
		return

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			dragging = true
			var rel_y: float = event.relative.y
			vbar.value -= rel_y
			velocity = -rel_y * 60.0
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			return

func _process(delta: float) -> void:
	if target == null:
		queue_free()
		return
	var vbar: ScrollBar = _find_v_scrollbar()
	if vbar == null:
		return

	# if no meaningful scrollable range, skip
	if vbar.max_value <= vbar.min_value:
		velocity = 0.0
		return

	if dragging:
		# while dragging, lightly damp velocity
		velocity = lerp(velocity, 0.0, clamp(10.0 * delta, 0.0, 1.0))
		return

	# inertia
	if abs(velocity) > min_velocity:
		vbar.value += velocity * delta
		# exponential decay for smooth slowdown
		velocity *= exp(-friction * delta)
	else:
		velocity = 0.0

	# bounce back if out of range
	if vbar.value < vbar.min_value:
		vbar.value = lerp(vbar.value, vbar.min_value, clamp(bounce_speed * delta, 0.0, 1.0))
		velocity = 0.0
	elif vbar.value > vbar.max_value:
		vbar.value = lerp(vbar.value, vbar.max_value, clamp(bounce_speed * delta, 0.0, 1.0))
		velocity = 0.0
