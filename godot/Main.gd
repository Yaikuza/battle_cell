extends Node

const EvolutionManagerScript = preload("res://managers/EvolutionManager.gd")
const VirtualJoystickScript = preload("res://ui/VirtualJoystick.gd")

func _ready() -> void:
	_setup_input_map()
	RenderingServer.set_default_clear_color(Color(0.05, 0.05, 0.12))

	var enemy_container = Node.new()
	enemy_container.name = "Enemies"
	add_child(enemy_container)

	var player = Player.new()
	add_child(player)
	player.position = get_viewport().get_visible_rect().size / 2

	var evolution_manager = EvolutionManagerScript.new()
	add_child(evolution_manager)

	var hud = HUD.new()
	add_child(hud)

	var wave_manager = WaveManager.new()
	wave_manager.setup(enemy_container)
	add_child(wave_manager)

	var joystick = VirtualJoystickScript.new()
	add_child(joystick)

	GameManager.start_next_wave()

func _setup_input_map() -> void:
	var actions = ["move_left", "move_right", "move_up", "move_down"]
	for action in actions:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action)

	var left_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	left_events[0].keycode = KEY_A
	left_events[1].keycode = KEY_LEFT
	left_events[2].axis = JOY_AXIS_LEFT_X
	left_events[2].axis_value = -1.0
	left_events[3].button_index = 12
	for e in left_events:
		InputMap.action_add_event("move_left", e)

	var right_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	right_events[0].keycode = KEY_D
	right_events[1].keycode = KEY_RIGHT
	right_events[2].axis = JOY_AXIS_LEFT_X
	right_events[2].axis_value = 1.0
	right_events[3].button_index = 13
	for e in right_events:
		InputMap.action_add_event("move_right", e)

	var up_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	up_events[0].keycode = KEY_W
	up_events[1].keycode = KEY_UP
	up_events[2].axis = JOY_AXIS_LEFT_Y
	up_events[2].axis_value = -1.0
	up_events[3].button_index = 10
	for e in up_events:
		InputMap.action_add_event("move_up", e)

	var down_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	down_events[0].keycode = KEY_S
	down_events[1].keycode = KEY_DOWN
	down_events[2].axis = JOY_AXIS_LEFT_Y
	down_events[2].axis_value = 1.0
	down_events[3].button_index = 11
	for e in down_events:
		InputMap.action_add_event("move_down", e)


