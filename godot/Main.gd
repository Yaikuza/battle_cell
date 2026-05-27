extends Node

const EvolutionManagerScript = preload("res://managers/EvolutionManager.gd")
const VirtualJoystickScript = preload("res://ui/VirtualJoystick.gd")

func _ready() -> void:
	_setup_input_map()
	RenderingServer.set_default_clear_color(Color(0.15, 0.25, 0.42))
	_setup_background()

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

	AudioManager.play_bgm()
	GameManager.start_next_wave()

var _bg_root: Node2D
var _bg_layers: Array[Node2D] = []
var _bg_factors: Array[float] = [0.02, 0.06, 0.12]
var _viewport_center: Vector2

func _setup_background() -> void:
	_viewport_center = get_viewport().get_visible_rect().size / 2
	_bg_root = Node2D.new()
	_bg_root.name = "Background"
	add_child(_bg_root)

	var vp = get_viewport().get_visible_rect().size
	var tex_w = ceili(vp.x * 2)
	var tex_h = ceili(vp.y * 2)

	var layer_defs = [
		{ "color": Color(0.3, 0.6, 0.9), "alpha": 0.07, "freq": 2.5 },
		{ "color": Color(0.5, 0.8, 1.0), "alpha": 0.10, "freq": 4.0 },
		{ "color": Color(0.7, 0.9, 1.0), "alpha": 0.15, "freq": 7.0 },
	]
	for li in layer_defs:
		var layer = Node2D.new()
		_bg_root.add_child(layer)
		_bg_layers.append(layer)

		var img = Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for py in tex_h:
			for px in tex_w:
				var v = 0.0
				var fx = float(px) / tex_w * li["freq"]
				var fy = float(py) / tex_h * li["freq"]
				v += sin(fx * TAU) * cos(fy * TAU) * 0.6
				v += sin(fx * 2.3 + fy * 1.7) * 0.3
				v += cos(fx * 0.7 - fy * 1.1) * 0.1
				v = v * 0.5 + 0.5
				var a = li["alpha"] * v
				if a > 0.003:
					img.set_pixel(px, py, Color(li["color"].r, li["color"].g, li["color"].b, a))
		var tex = ImageTexture.create_from_image(img)

		var s = Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.position = Vector2.ZERO
		layer.add_child(s)

func _process(_delta: float) -> void:
	if not _bg_root:
		return
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var offset = player.position - _viewport_center
	for i in len(_bg_layers):
		_bg_layers[i].position = -offset * _bg_factors[i]

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


