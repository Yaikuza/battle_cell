extends Resource
class_name TailSweep

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> void:
	var damage = stats.get_stat("damage", 10.0)
	var speed = stats.get_stat("projectile_speed", 500.0)
	var range = stats.get_stat("range", 350.0)

	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	var behind_dir := Vector2.DOWN
	if not enemies.is_empty():
		var nearest: Node2D = null
		var min_dist = range
		for enemy in enemies:
			var d = user.global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				nearest = enemy
		if nearest:
			behind_dir = (user.global_position - nearest.global_position).normalized()

	var count = 5
	var arc_deg = 160.0
	var start_angle = atan2(behind_dir.y, behind_dir.x) - deg_to_rad(arc_deg / 2.0)

	for i in range(count):
		var angle = start_angle + deg_to_rad(arc_deg / (count - 1)) * i
		var d = Vector2(cos(angle), sin(angle))
		var bullet = PoolManager.get_bullet()
		bullet.global_position = user.global_position + d * 12.0
		bullet.direction = d
		bullet.speed = speed * 0.8
		bullet.damage = maxi(ceili(damage * 0.8), 1)
		bullet.max_distance = range * 0.8
		spawn_parent.add_child(bullet)
