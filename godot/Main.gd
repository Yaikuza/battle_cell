extends Node

const EvolutionManagerScript = preload("res://managers/EvolutionManager.gd")
const EvolutionScreenScript = preload("res://ui/EvolutionScreen.gd")
const VirtualJoystickScript = preload("res://ui/VirtualJoystick.gd")
const PauseMenuScript = preload("res://ui/PauseMenu.gd")


const ZOOM_LEVELS: Array[float] = [1.8, 1.6, 1.4, 1.2, 1.0]

const ERA_BG: Dictionary = {
	0: { # Cambrian-Devonian — underwater
		"sky_top": Color(0.1, 0.2, 0.4),
		"sky_bot": Color(0.2, 0.5, 0.6),
		"clear": Color(0.1, 0.25, 0.45),
		"layers": [
			{"color": Color(0.4, 0.7, 0.8, 0.06), "freq": 2.0, "thresh": 0.55, "factor": 0.003},
			{"color": Color(0.2, 0.5, 0.4, 0.08), "freq": 4.0, "thresh": 0.50, "factor": 0.020},
			{"color": Color(0.3, 0.3, 0.2, 0.10), "freq": 6.0, "thresh": 0.45, "factor": 0.060},
		],
	},
	1: { # Carboniferous-Triassic — swamp
		"sky_top": Color(0.3, 0.3, 0.15),
		"sky_bot": Color(0.5, 0.55, 0.3),
		"clear": Color(0.3, 0.35, 0.2),
		"layers": [
			{"color": Color(0.6, 0.7, 0.5, 0.07), "freq": 2.5, "thresh": 0.50, "factor": 0.003},
			{"color": Color(0.3, 0.5, 0.3, 0.09), "freq": 4.5, "thresh": 0.45, "factor": 0.020},
			{"color": Color(0.2, 0.3, 0.15, 0.12), "freq": 5.0, "thresh": 0.40, "factor": 0.060},
		],
	},
	2: { # Jurassic — lush jungle
		"sky_top": Color(0.25, 0.5, 0.6),
		"sky_bot": Color(0.5, 0.7, 0.5),
		"clear": Color(0.25, 0.5, 0.45),
		"layers": [
			{"color": Color(0.7, 0.8, 0.6, 0.06), "freq": 2.0, "thresh": 0.52, "factor": 0.003},
			{"color": Color(0.3, 0.6, 0.3, 0.08), "freq": 3.5, "thresh": 0.48, "factor": 0.020},
			{"color": Color(0.15, 0.3, 0.15, 0.10), "freq": 5.5, "thresh": 0.42, "factor": 0.060},
		],
	},
}

var _current_zoom: float = 1.8

func _ready() -> void:
	_setup_input_map()
	RenderingServer.set_default_clear_color(Color(0.35, 0.55, 0.75))
	_setup_background()
	_setup_boundary_visuals()
	var enemy_container = Node.new()
	enemy_container.name = "Enemies"
	add_child(enemy_container)

	var player = Player.new()
	player.position = get_viewport().get_visible_rect().size / 2
	add_child(player)
	_set_zoom(ZOOM_LEVELS[EraManager.era_index])

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
	if EventBus.era_transition_midpoint.is_connected(_on_era_transition_midpoint):
		EventBus.era_transition_midpoint.disconnect(_on_era_transition_midpoint)

func _set_zoom(z: float) -> void:
	_current_zoom = z
	var player = get_tree().get_first_node_in_group("player") as Player
	if player and player._camera:
		player._camera.zoom = Vector2(z, z)

func _on_era_changed(_era_name: String, idx: int) -> void:
	var target = ZOOM_LEVELS[mini(idx, ZOOM_LEVELS.size() - 1)]
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(_set_zoom, _current_zoom, target, 1.0)
	EventBus.era_transition_midpoint.connect(_on_era_transition_midpoint.bind(idx), CONNECT_ONE_SHOT)

func _restore_background() -> void:
	_rebuild_era_layers(EraManager.era_index)
	_start_sky_tween(EraManager.era_index)
	var target = ZOOM_LEVELS[mini(EraManager.era_index, ZOOM_LEVELS.size() - 1)]
	_set_zoom(target)
	_current_zoom = target

func _on_era_transition_midpoint(idx: int) -> void:
	_rebuild_era_layers(idx)
	_start_sky_tween(idx)

func _start_sky_tween(idx: int) -> void:
	var cfg = ERA_BG.get(idx, ERA_BG[0])
	var src_top = _sky_top
	var src_bot = _sky_bot
	var ft = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	ft.tween_property(_sky_rect, "color", cfg["clear"], 1.5)
	ft.parallel().tween_method(_update_sky_grad.bind(src_top, src_bot, cfg["sky_top"], cfg["sky_bot"]), 0.0, 1.0, 1.5)
	ft.finished.connect(func(): _sky_top = cfg["sky_top"]; _sky_bot = cfg["sky_bot"])

func _update_sky_grad(t: float, src_top: Color, src_bot: Color, dst_top: Color, dst_bot: Color) -> void:
	if not _sky_grad or not _sky_grad.texture:
		return
	var img = _sky_grad.texture.get_image()
	if not img:
		return
	var h = img.get_height()
	var top = src_top.lerp(dst_top, t)
	var bot = src_bot.lerp(dst_bot, t)
	for py in h:
		var c = top.lerp(bot, float(py) / (h - 1))
		for px in img.get_width():
			img.set_pixel(px, py, c)
	_sky_grad.texture.update(img)

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
	print("\n=== RESUME: _restore_run ===")
	print("  data keys = ", data.keys())

	var gd = data.get("game", {})
	if not gd.is_empty():
		GameManager.restore_from_save(gd)
		EraManager.restore_from_save(gd)

	var ed = data.get("evolution", {})
	print("  evolution data keys = ", ed.keys())
	print("  evolution data = ", ed)
	if not ed.is_empty():
		var saved_form_id = str(ed.get("current_form_id", "MISSING"))
		print("  >>> SAVED form_id = ", saved_form_id)
		_log("RESTORE evolution found form_id=" + saved_form_id)
		var extra = evo.restore_from_save(ed)
		print("  evo.current_form_id AFTER restore = ", evo.current_form_id)
		var form_data = evo.get_current_form().duplicate(true)
		form_data["id"] = evo.current_form_id
		form_data["type"] = "form"
		if not extra.get("weapon_id", "").is_empty():
			print("  >>> Overriding weapon with saved weapon_id: ", extra.weapon_id)
			form_data["weapon"] = extra.weapon_id
		if not extra.get("form_stats", {}).is_empty():
			print("  >>> Overriding stats with saved form_stats")
			form_data["stats"] = extra.form_stats.duplicate()
		print("  form_data weapon = ", form_data.get("weapon", "NO_WEAPON_KEY"))
		print("  form_data id = ", form_data.get("id", "NO_ID_KEY"))
		print("  form_data keys = ", form_data.keys())
		player.apply_form(form_data)
		player.refresh_from_stats()
		evo._reapply_equipped_parts(player)
		print("  AFTER apply_form: weapon behaviors = ", player.weapon.behaviors.size())
		for i in player.weapon.behaviors.size():
			var b = player.weapon.behaviors[i]
			print("    behavior[", i, "] = ", b)
		_log("RESTORE after apply cd=" + str(player.weapon.fire_cooldown))
	else:
		print("  >>> NO evolution data found! (cell form default)")
		_log("RESTORE NO evolution data found!")

	var pd = data.get("player", {})
	if not pd.is_empty():
		var hp = pd.get("hp", player.health.max_hp)
		player.health.hp = mini(hp, player.health.max_hp)
		player.position = Vector2(pd.get("position_x", 0), pd.get("position_y", 0))
		if pd.has("used_second_chance"):
			player._used_second_chance = pd["used_second_chance"]

	var mdata = data.get("mutation", {})
	print("  mutation data = ", mdata)
	_log("RESTORE mutation data keys: " + str(mdata.keys()))
	MutationManager.restore_from_save(mdata)
	for mid in MutationManager.current_mutations:
		_log("RESTORE emit mutation_applied: " + mid)
		EventBus.mutation_applied.emit(mid)

	GameManager.enemies_alive = 0
	hud.refresh()
	_restore_background()
	wm.restore_from_save()
	print("  FINAL: weapon behaviors = ", player.weapon.behaviors.size())
	for i in player.weapon.behaviors.size():
		var b = player.weapon.behaviors[i]
		print("    behavior[", i, "] = ", b)
	_log("RESTORE COMPLETE fire_cooldown=" + str(player.weapon.fire_cooldown) + " timers=" + str(player.weapon._timers.size()))
	print("=== RESUME END ===")

func _apply_head_start() -> void:
	var hs = MetaManager.get_head_start_gp()
	if hs > 0:
		EventBus.gp_collected.emit(hs)

var _bg_root: Node2D
var _bg_layers: Array[Node2D] = []
var _bg_factors: Array[float] = []
var _viewport_center: Vector2
var _sky_rect: ColorRect
var _sky_grad: Sprite2D
var _sky_top: Color = Color(0.1, 0.2, 0.4)
var _sky_bot: Color = Color(0.2, 0.5, 0.6)

func _setup_background() -> void:
	_viewport_center = get_viewport().get_visible_rect().size / 2
	_bg_root = Node2D.new()
	_bg_root.name = "Background"
	add_child(_bg_root)

	var vp = get_viewport().get_visible_rect().size
	_make_sky(vp, 512)
	_rebuild_era_layers(EraManager.era_index)

func _rebuild_era_layers(era_idx: int) -> void:
	for l in _bg_layers:
		l.queue_free()
	_bg_layers.clear()
	_bg_factors.clear()
	var cfg = ERA_BG.get(era_idx, ERA_BG[0])
	var vp = get_viewport().get_visible_rect().size
	var extend = 512
	var tile_w = 256
	for lc in cfg["layers"]:
		_make_cloud_layer(lc["color"], lc["freq"], lc["thresh"], tile_w, extend)
		_bg_factors.append(lc["factor"])

func _setup_boundary_visuals() -> void:
	var vp = get_viewport().get_visible_rect().size
	var center = vp * 0.5
	var radius = (mini(center.x, center.y) - 20.0) * 10.0
	var ext = radius + maxi(vp.x, vp.y)

	var dark = ColorRect.new()
	dark.color = Color(0, 0, 0, 1)
	dark.size = Vector2(ext * 2, ext * 2)
	dark.position = Vector2(center.x - ext, center.y - ext)
	dark.z_index = -1
	add_child(dark)

	var mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/circle_boundary.gdshader")
	mat.set_shader_parameter("u_center", center)
	mat.set_shader_parameter("u_radius", radius)
	mat.set_shader_parameter("u_offset", dark.position)
	mat.set_shader_parameter("u_size", dark.size)
	dark.material = mat

func _make_sky(vp: Vector2, extend: float) -> void:
	var cfg = ERA_BG.get(EraManager.era_index, ERA_BG[0])
	_sky_top = cfg["sky_top"]
	_sky_bot = cfg["sky_bot"]
	_sky_rect = ColorRect.new()
	_sky_rect.color = cfg["clear"]
	_sky_rect.size = vp + Vector2(extend * 2, extend * 2)
	_sky_rect.position = Vector2(-extend, -extend)
	_bg_root.add_child(_sky_rect)

	var img = Image.create(64, 512, false, Image.FORMAT_RGBA8)
	for py in 512:
		var t = float(py) / 511.0
		var c = _sky_top.lerp(_sky_bot, t)
		for px in 64:
			img.set_pixel(px, py, c)
	var tex = ImageTexture.create_from_image(img)
	_sky_grad = Sprite2D.new()
	_sky_grad.texture = tex
	_sky_grad.centered = false
	_sky_grad.scale = Vector2((vp.x + extend * 2) / 64.0, (vp.y + extend * 2) / 512.0)
	_sky_grad.position = Vector2(-extend, -extend)
	_sky_grad.z_index = -1
	_bg_root.add_child(_sky_grad)

func _make_cloud_layer(color: Color, freq: float, threshold: float, tile_w: int, extend: float) -> void:
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
			var a = color.a * cloud
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
	var actions = ["move_left", "move_right", "move_up", "move_down", "dodge"]
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
	left_events[3].button_index = 14
	for e in left_events:
		InputMap.action_add_event("move_left", e)

	var right_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	right_events[0].keycode = KEY_D
	right_events[1].keycode = KEY_RIGHT
	right_events[2].axis = JOY_AXIS_LEFT_X
	right_events[2].axis_value = 1.0
	right_events[3].button_index = 15
	for e in right_events:
		InputMap.action_add_event("move_right", e)

	var up_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	up_events[0].keycode = KEY_W
	up_events[1].keycode = KEY_UP
	up_events[2].axis = JOY_AXIS_LEFT_Y
	up_events[2].axis_value = -1.0
	up_events[3].button_index = 12
	for e in up_events:
		InputMap.action_add_event("move_up", e)

	var down_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	down_events[0].keycode = KEY_S
	down_events[1].keycode = KEY_DOWN
	down_events[2].axis = JOY_AXIS_LEFT_Y
	down_events[2].axis_value = 1.0
	down_events[3].button_index = 13
	for e in down_events:
		InputMap.action_add_event("move_down", e)

	var dodge_events = [InputEventKey.new(), InputEventJoypadButton.new()]
	dodge_events[0].keycode = KEY_SPACE
	dodge_events[1].button_index = JOY_BUTTON_A
	for e in dodge_events:
		InputMap.action_add_event("dodge", e)

func _log(msg: String) -> void:
	var f = FileAccess.open("user://weapon_dbg.txt", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)
	else:
		f = FileAccess.open("user://weapon_dbg.txt", FileAccess.WRITE)
		if f:
			f.store_line(msg)
