extends Control
class_name VirtualJoystick

var _active := false
var _base_pos := Vector2.ZERO
var _knob_pos := Vector2.ZERO
var _touch_id := -1
var _radius: float = 60.0
var _deadzone: float = 10.0

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	mouse_filter = MOUSE_FILTER_IGNORE
	anchor_right = 1.0
	anchor_bottom = 1.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _is_left_side(event.position):
			_active = true
			_touch_id = event.index
			_base_pos = event.position
			_knob_pos = _base_pos
			queue_redraw()
		elif not event.pressed and event.index == _touch_id:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var delta = event.position - _base_pos
		var dist = delta.length()
		if dist > _radius:
			delta = delta.normalized() * _radius
		_knob_pos = _base_pos + delta
		_update_input(delta / _radius)
		queue_redraw()

func _is_left_side(pos: Vector2) -> bool:
	return pos.x < get_viewport().get_visible_rect().size.x * 0.5

func _release() -> void:
	_active = false
	_touch_id = -1
	_update_input(Vector2.ZERO)
	queue_redraw()

func _update_input(normalized: Vector2) -> void:
	var x = normalized.x
	var y = normalized.y
	var len = normalized.length()

	if len < 0.15:
		Input.action_release("move_left")
		Input.action_release("move_right")
		Input.action_release("move_up")
		Input.action_release("move_down")
		return

	if x < -_deadzone / _radius:
		Input.action_press("move_left", absf(x))
		Input.action_release("move_right")
	elif x > _deadzone / _radius:
		Input.action_press("move_right", x)
		Input.action_release("move_left")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

	if y < -_deadzone / _radius:
		Input.action_press("move_up", absf(y))
		Input.action_release("move_down")
	elif y > _deadzone / _radius:
		Input.action_press("move_down", y)
		Input.action_release("move_up")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")

func _draw() -> void:
	if not _active:
		return
	var base_color := Color(1, 1, 1, 0.15)
	var knob_color := Color(1, 1, 1, 0.4)
	draw_circle(_base_pos, _radius, base_color)
	draw_circle(_base_pos, _radius, Color(1, 1, 1, 0.25), false, 2.0)
	draw_circle(_knob_pos, _radius * 0.35, knob_color)
