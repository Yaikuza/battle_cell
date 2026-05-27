extends Resource
class_name StareBehavior

const STARE_RANGE := 400.0
const SLOW_FACTOR := 0.3
const SLOW_DURATION := 1.5

var _marked: Dictionary = {}

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> bool:
	var damage = stats.get_stat("damage", 10.0)
	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return false

	var hit_any := false
	var now = Time.get_ticks_msec()
	var dir := Vector2.RIGHT

	var nearest: Node2D = null
	var min_dist = STARE_RANGE
	for e in enemies:
		var d = user.global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	if nearest:
		dir = (nearest.global_position - user.global_position).normalized()

	for e in enemies:
		var to_e = e.global_position - user.global_position
		var dist = to_e.length()
		if dist > STARE_RANGE:
			continue

		var angle_diff = abs(to_e.angle_to(dir))
		if angle_diff > deg_to_rad(30.0):
			continue

		e.take_damage(maxi(ceili(damage * 0.4), 1))
		hit_any = true

		if e.has_method("slow_down"):
			e.slow_down(SLOW_FACTOR, SLOW_DURATION)
		elif e is CharacterBody2D:
			e.speed_multiplier = SLOW_FACTOR
			_marked[e.get_instance_id()] = now
			_setup_slow_cleanup(e, now)

	AudioManager.play_sfx("swing", user.global_position)

	var effect = Sprite2D.new()
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 24:
		for y in 24:
			var dx = x - 11.5; var dy = y - 11.5
			var d = sqrt(dx * dx + dy * dy)
			if d < 11: img.set_pixel(x, y, Color(1.0, 0.1, 0.0, 0.5 * (1.0 - d / 11.0)))
	effect.texture = ImageTexture.create_from_image(img)
	effect.centered = true
	effect.global_position = user.global_position + dir * 30.0
	spawn_parent.add_child(effect)
	if spawn_parent is Node:
		var t = spawn_parent.create_tween()
		t.tween_property(effect, "scale", Vector2(0.2, 0.2), 0.3)
		t.tween_callback(effect.queue_free)

	return hit_any

func _setup_slow_cleanup(e: CharacterBody2D, start_ms: int) -> void:
	var timer = Timer.new()
	timer.wait_time = SLOW_DURATION
	timer.one_shot = true
	timer.timeout.connect(func():
		if is_instance_valid(e):
			e.speed_multiplier = 1.0
		_marked.erase(e.get_instance_id())
		timer.queue_free())
	e.add_child(timer)
	timer.start()
