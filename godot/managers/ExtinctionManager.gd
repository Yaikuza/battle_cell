extends Node

enum EventType { GREAT_DYING, ASTEROID }

var _active: bool = false
var _event_type: int = -1
var _duration: float = 0.0
var _hazard_accum: float = 0.0
var _dot_accum: float = 0.0
var _overlay_layer: CanvasLayer = null
var _hazards: Array[Node] = []

const EXTINCTION_TIME: float = 25.0
const HAZARD_INTERVAL: float = 2.5

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	EventBus.extinction_started.connect(_on_extinction_started)
	EventBus.game_over.connect(_cleanup)

func _exit_tree() -> void:
	if EventBus.extinction_started.is_connected(_on_extinction_started):
		EventBus.extinction_started.disconnect(_on_extinction_started)
	if EventBus.game_over.is_connected(_cleanup):
		EventBus.game_over.disconnect(_cleanup)

func _on_extinction_started(event_type: int) -> void:
	_active = true
	_event_type = event_type
	_duration = EXTINCTION_TIME
	_hazard_accum = 0.0
	_dot_accum = 0.0
	_show_announcement()
	if event_type == EventType.ASTEROID:
		_overlay_layer = CanvasLayer.new()
		_overlay_layer.layer = 64
		var ov = ColorRect.new()
		ov.color = Color(0, 0, 0, 0)
		ov.size = get_viewport().get_visible_rect().size
		ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay_layer.add_child(ov)
		get_tree().current_scene.add_child(_overlay_layer)
		var tw = create_tween()
		tw.tween_property(ov, "color", Color(0, 0, 0, 0.35), 0.8)

func _process(delta: float) -> void:
	if not _active:
		return
	_duration -= delta

	_hazard_accum += delta
	while _hazard_accum >= HAZARD_INTERVAL:
		_hazard_accum -= HAZARD_INTERVAL
		_spawn_hazard()

	if _event_type == EventType.GREAT_DYING:
		_dot_accum += delta
		while _dot_accum >= 1.0:
			_dot_accum -= 1.0
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("take_damage"):
				player.take_damage(1)

	if _duration <= 0.0:
		_end_extinction()

func _spawn_hazard() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var angle = randf() * TAU
	var dist = 80 + randi() % 120
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist

	var hazard = Area2D.new()
	hazard.collision_layer = 0
	hazard.collision_mask = 4

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	hazard.add_child(shape)

	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if _event_type == EventType.GREAT_DYING:
		for x in 64:
			for y in 64:
				var d = Vector2(x - 32, y - 32).length()
				if d < 28:
					img.set_pixel(x, y, Color(1, 0.3, 0, 0.35 - d * 0.005))
	else:
		for x in 64:
			for y in 64:
				var d = Vector2(x - 32, y - 32).length()
				if d < 28:
					var a = 0.4 - d * 0.007
					img.set_pixel(x, y, Color(0.5, 0.5, 0.5, maxf(a, 0)))
	var sprite = Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = true
	hazard.add_child(sprite)

	var dmg_timer = Timer.new()
	dmg_timer.one_shot = false
	dmg_timer.wait_time = 0.6
	dmg_timer.timeout.connect(func():
		if not is_instance_valid(hazard):
			return
		for area in hazard.get_overlapping_areas():
			var owner = area.get_parent()
			if owner and owner.has_method("take_damage"):
				owner.take_damage(3))
	hazard.add_child(dmg_timer)
	dmg_timer.start()

	hazard.position = pos
	get_tree().current_scene.add_child(hazard)
	_hazards.append(hazard)

	var kill = Timer.new()
	kill.one_shot = true
	kill.wait_time = 5.0
	kill.timeout.connect(func():
		if is_instance_valid(hazard):
			hazard.queue_free())
	hazard.add_child(kill)
	kill.start()

func _show_announcement() -> void:
	var vp = get_viewport().get_visible_rect().size
	var label = Label.new()
	if _event_type == EventType.GREAT_DYING:
		label.text = "☠ THE GREAT DYING ☠"
	else:
		label.text = "☄ THE ASTEROID ☄"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = vp
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", Color(1, 0.3, 0) if _event_type == EventType.GREAT_DYING else Color(0.7, 0.7, 0.7))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.modulate.a = 0.0
	get_tree().current_scene.add_child(label)
	var tw = create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.5)
	tw.tween_property(label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(label.queue_free)

	var subtitle = Label.new()
	subtitle.text = "เอาชีวิตรอด %.0f วิ!" % EXTINCTION_TIME
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 55)
	subtitle.size = vp
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	subtitle.add_theme_constant_override("outline_size", 2)
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	subtitle.modulate.a = 0.0
	get_tree().current_scene.add_child(subtitle)
	var tw2 = create_tween()
	tw2.tween_property(subtitle, "modulate:a", 1.0, 0.5)
	tw2.tween_interval(2.0)
	tw2.tween_property(subtitle, "modulate:a", 0.0, 0.3)
	tw2.tween_callback(subtitle.queue_free)

func _end_extinction() -> void:
	_active = false
	_cleanup()
	EventBus.extinction_ended.emit()

func _cleanup() -> void:
	_active = false
	for h in _hazards:
		if is_instance_valid(h):
			h.queue_free()
	_hazards.clear()
	if _overlay_layer and is_instance_valid(_overlay_layer):
		_overlay_layer.queue_free()
		_overlay_layer = null

func is_extinction_active() -> bool:
	return _active
