extends Node

const EvolutionManagerScript = preload("res://managers/EvolutionManager.gd")
const EvolutionScreenScript = preload("res://ui/EvolutionScreen.gd")
const VirtualJoystickScript = preload("res://ui/VirtualJoystick.gd")
const PauseMenuScript = preload("res://ui/PauseMenu.gd")

const ZOOM_LEVELS: Array[float] = [1.8, 1.6, 1.4, 1.2, 1.0]

var _current_zoom: float = 1.8

func _ready() -> void:
	_setup_input_map()
	RenderingServer.set_default_clear_color(Color(0.35, 0.55, 0.75))
	_setup_background()
	_set_zoom(ZOOM_LEVELS[0])

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
	hud.add_child(joystick)

	AudioManager.play_bgm()
	EventBus.era_changed.connect(_on_era_changed)

	var run_data = SaveManager.load_run()
	if not run_data.is_empty():
		_restore_run(run_data, player, evolution_manager, wave_manager, hud)
		SaveManager.delete_saved_run()
	else:
		call_deferred("_check_start_form")

func _exit_tree() -> void:
	if EventBus.era_changed.is_connected(_on_era_changed):
		EventBus.era_changed.disconnect(_on_era_changed)

func _set_zoom(z: float) -> void:
	_current_zoom = z
	get_viewport().canvas_transform = Transform2D().scaled(Vector2(z, z))

func _on_era_changed(_era_name: String, idx: int) -> void:
	var target = ZOOM_LEVELS[mini(idx, ZOOM_LEVELS.size() - 1)]
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_zoom, _current_zoom, target, 1.0)

func _check_start_form() -> void:
	var evo = get_tree().get_first_node_in_group("evolution_manager") as EvolutionManager
	var player = get_tree().get_first_node_in_group("player") as Player
	if not evo or not player:
		return
	var unlocked: Array[Dictionary] = []
	for form_id in MetaManager.LEGACY:
		if MetaManager.is_legacy_unlocked(form_id):
			var f = evo._tree.get(form_id)
			if f:
				var dup = f.duplicate(true)
				dup["id"] = form_id
				dup["type"] = "form"
				unlocked.append(dup)

	if unlocked.is_empty():
		_apply_head_start()
		GameManager.start_next_wave()
		return

	unlocked.append({"name": "Stay as Cell", "desc": "เริ่มต้นเป็นเซลล์เหมือนเดิม", "type": "stay_cell", "id": "cell"})

	get_tree().paused = true
	var screen = EvolutionScreenScript.new()
	var vp = get_viewport().get_visible_rect().size
	screen.show_choices(unlocked, vp, func(data):
		get_tree().paused = false
		screen.queue_free()
		var f_id = data.get("id", "cell")
		if f_id != "cell":
			var f = evo._tree.get(f_id)
			if f:
				var dup = f.duplicate(true)
				dup["id"] = f_id
				evo.current_form_id = f_id
				evo._evolution_path.append(f_id)
				player.apply_form(dup, false)
				SaveManager.unlock_form(f_id)
		_apply_head_start()
		GameManager.start_next_wave()
	)
	add_child(screen)

func _restore_run(data: Dictionary, player: Player, evo: EvolutionManager, wm: WaveManager, hud: HUD) -> void:
	var gd = data.get("game", {})
	if not gd.is_empty():
		GameManager.restore_from_save(gd)

	var ed = data.get("evolution", {})
	if not ed.is_empty():
		evo.restore_from_save(ed)
		var form_data = evo.get_current_form().duplicate(true)
		form_data["id"] = evo.current_form_id
		form_data["type"] = "form"
		player.apply_form(form_data)
		for up_id in evo._used_upgrades:
			var up = evo.get_upgrade_data(up_id)
			if not up.is_empty():
				for m in up.get("mods", []):
					player.stats.add_modifier_raw(m.stat, m.val, m.type, "evolution_upgrade")
				if up_id == "misc_gp":
					GameManager.gp_multiplier = 1.2
		player.refresh_from_stats()

	var pd = data.get("player", {})
	if not pd.is_empty():
		var hp = pd.get("hp", player.health.max_hp)
		player.health.hp = mini(hp, player.health.max_hp)
		player.position = Vector2(pd.get("position_x", 0), pd.get("position_y", 0))
		if pd.has("used_second_chance"):
			player._used_second_chance = pd["used_second_chance"]

	GameManager.enemies_alive = 0
	hud.refresh()
	EventBus.era_changed.emit(GameManager.get_era_name(), GameManager.era_index)
	wm.restore_from_save()

func _apply_head_start() -> void:
	var hs = MetaManager.get_head_start_gp()
	if hs > 0:
		EventBus.gp_collected.emit(hs)

var _bg_root: Node2D
var _bg_layers: Array[Node2D] = []
var _bg_factors: Array[float] = [0.005, 0.025]
var _viewport_center: Vector2

func _setup_background() -> void:
	_viewport_center = get_viewport().get_visible_rect().size / 2
	_bg_root = Node2D.new()
	_bg_root.name = "Background"
	add_child(_bg_root)

	var vp = get_viewport().get_visible_rect().size
	var extend = 1024
	var tile_w = 1024

	_make_sky(vp, extend)
	_make_cloud_layer(Color(1, 1, 1), 0.08, 3.0, 0.45, tile_w, extend)
	_make_cloud_layer(Color(1, 1, 1), 0.15, 5.0, 0.35, tile_w, extend)

func _make_sky(vp: Vector2, extend: float) -> void:
	var sky = ColorRect.new()
	sky.color = Color(0.35, 0.55, 0.75)
	sky.size = vp + Vector2(extend * 2, extend * 2)
	sky.position = Vector2(-extend, -extend)
	_bg_root.add_child(sky)

	var img = Image.create(64, 512, false, Image.FORMAT_RGBA8)
	for py in 512:
		var t = float(py) / 511.0
		var bottom = Color(0.55, 0.72, 0.88, 1.0)
		var top = Color(0.28, 0.48, 0.70, 1.0)
		var c = top.lerp(bottom, t)
		for px in 64:
			img.set_pixel(px, py, c)
	var tex = ImageTexture.create_from_image(img)
	var grad = Sprite2D.new()
	grad.texture = tex
	grad.centered = false
	grad.scale = Vector2((vp.x + extend * 2) / 64.0, (vp.y + extend * 2) / 512.0)
	grad.position = Vector2(-extend, -extend)
	grad.z_index = -1
	_bg_root.add_child(grad)

func _make_cloud_layer(color: Color, alpha: float, freq: float, threshold: float, tile_w: int, extend: float) -> void:
	var layer = Node2D.new()
	_bg_root.add_child(layer)
	_bg_layers.append(layer)

	var img = Image.create(tile_w, tile_w, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for py in tile_w:
		for px in tile_w:
			var fx = float(px) / tile_w * freq
			var fy = float(py) / tile_w * freq
			var v = 0.0
			v += sin(fx * TAU) * cos(fy * TAU) * 0.4
			v += sin(fx * 2.7 + fy * 1.3) * 0.25
			v += cos(fx * 0.9 - fy * 2.1) * 0.15
			v += sin(fx * 3.5 + fy * 0.8) * 0.1
			v += cos(fx * 1.5 - fy * 3.3) * 0.1
			v = v * 0.5 + 0.5
			var cloud = maxf(v - threshold, 0) / (1.0 - threshold)
			cloud = pow(cloud, 1.4)
			var a = alpha * cloud
			if a > 0.005:
				img.set_pixel(px, py, Color(color.r, color.g, color.b, a))

	var tex = ImageTexture.create_from_image(img)
	var vp = get_viewport().get_visible_rect().size
	var tiles_x = ceili((vp.x + extend * 2) / tile_w) + 2
	var tiles_y = ceili((vp.y + extend * 2) / tile_w) + 2
	for ox in range(tiles_x):
		for oy in range(tiles_y):
			var s = Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = Vector2(ox * tile_w - extend, oy * tile_w - extend)
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not GameManager.game_over:
		if get_tree().paused:
			get_tree().paused = false
			var pm = get_node_or_null("PauseMenu")
			if pm:
				pm.queue_free()
		else:
			get_tree().paused = true
			var pm = PauseMenuScript.new()
			pm.name = "PauseMenu"
			add_child(pm)
		get_viewport().set_input_as_handled()

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
