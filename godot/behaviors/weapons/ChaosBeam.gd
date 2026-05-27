extends Resource
class_name ChaosBeam

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> void:
	var damage = stats.get_stat("damage", 10.0)
	var speed = stats.get_stat("projectile_speed", 500.0)
	var range = stats.get_stat("range", 400.0)

	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var nearest: Node2D = null
	var min_dist = range * 1.5
	for enemy in enemies:
		var d = user.global_position.distance_to(enemy.global_position)
		if d < min_dist:
			min_dist = d
			nearest = enemy

	if not nearest:
		return

	var base_dir = (nearest.global_position - user.global_position).normalized()
	var spread = randf_range(-0.8, 0.8)
	var angle = atan2(base_dir.y, base_dir.x) + spread
	var dir = Vector2(cos(angle), sin(angle))

	var bullet = PoolManager.get_bullet()
	bullet.global_position = user.global_position + dir * 15.0
	bullet.direction = dir
	bullet.speed = speed * (0.9 if randf() > 0.3 else 1.5)
	bullet.damage = ceili(damage * randf_range(0.5, 1.8))
	bullet.max_distance = range * randf_range(0.5, 1.2)
	spawn_parent.add_child(bullet)
