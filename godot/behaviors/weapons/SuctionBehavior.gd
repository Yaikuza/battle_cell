extends Resource
class_name SuctionBehavior

const PULL_RADIUS := 180.0
const PULL_FORCE := 400.0
const DAMAGE_INTERVAL := 0.5

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> bool:
	var damage = stats.get_stat("damage", 10.0)
	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return false

	var hit_any := false
	for e in enemies:
		var dist = user.global_position.distance_to(e.global_position)
		if dist > PULL_RADIUS:
			continue

		var dir = (user.global_position - e.global_position).normalized()
		var pull = PULL_FORCE * (1.0 - dist / PULL_RADIUS)

		if e.has_method("take_damage"):
			e.take_damage(maxi(ceili(damage * 0.3), 1))
			hit_any = true

		if e is CharacterBody2D or e is RigidBody2D:
			e.velocity += dir * pull * 0.016
		elif e is Area2D:
			e.global_position += dir * pull * 0.016 * 60.0

	AudioManager.play_sfx("swing", user.global_position)

	var effect = Sprite2D.new()
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 40:
		for y in 40:
			var dx = x - 19.5; var dy = y - 19.5
			var d = sqrt(dx * dx + dy * dy)
			if d < 20: img.set_pixel(x, y, Color(0.6, 0.7, 0.9, 0.3 * (1.0 - d / 20.0)))
	effect.texture = ImageTexture.create_from_image(img)
	effect.centered = true
	effect.global_position = user.global_position
	spawn_parent.add_child(effect)
	if spawn_parent is Node:
		var t = spawn_parent.create_tween()
		t.tween_property(effect, "scale", Vector2(1.5, 1.5), 0.2)
		t.parallel().tween_property(effect, "modulate:a", 0.0, 0.2)
		t.tween_callback(effect.queue_free)

	return hit_any
