extends Resource
class_name SwarmShot

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> void:
	var damage = stats.get_stat("damage", 10.0)
	var speed = stats.get_stat("projectile_speed", 500.0)
	var range = stats.get_stat("range", 300.0)

	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	var base_dir := Vector2.RIGHT
	if not enemies.is_empty():
		var nearest: Node2D = null
		var min_dist = range * 1.5
		for enemy in enemies:
			var d = user.global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				nearest = enemy
		if nearest:
			base_dir = (nearest.global_position - user.global_position).normalized()

	var count = 6
	var spread_deg = 90.0
	var start_angle = atan2(base_dir.y, base_dir.x) - deg_to_rad(spread_deg / 2.0)

	for i in range(count):
		var angle = start_angle + deg_to_rad(spread_deg / (count - 1)) * i
		var jitter = deg_to_rad(randf_range(-8.0, 8.0))
		var d = Vector2(cos(angle + jitter), sin(angle + jitter))
		var bullet = PoolManager.get_bullet()
		bullet.global_position = user.global_position + d * 8.0
		bullet.direction = d
		bullet.speed = speed * randf_range(0.8, 1.2)
		bullet.damage = maxi(ceili(damage * 0.4), 1)
		bullet.max_distance = range
		spawn_parent.add_child(bullet)
