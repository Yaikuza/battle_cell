extends Resource
class_name WaterJet

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> bool:
	var damage = stats.get_stat("damage", 10.0)
	var speed = stats.get_stat("projectile_speed", 500.0)
	var range = stats.get_stat("range", 380.0)

	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return false

	var nearest = _nearest_in_range(user, enemies, range)
	if not nearest:
		return false

	var dir = (nearest.global_position - user.global_position).normalized()
	var spread_deg = 20.0
	var count = 3
	var start_angle = atan2(dir.y, dir.x) - deg_to_rad(spread_deg)

	for i in range(count):
		var angle = start_angle + deg_to_rad(spread_deg * 2.0 / (count - 1)) * i
		var d = Vector2(cos(angle), sin(angle))
		var bullet = PoolManager.get_bullet()
		bullet.global_position = user.global_position + d * 12.0
		bullet.direction = d
		bullet.speed = speed
		bullet.damage = maxi(ceili(damage * 0.7), 1)
		bullet.max_distance = range
		spawn_parent.add_child(bullet)
	return true

func _nearest_in_range(user: Node2D, enemies: Array, range: float) -> Node2D:
	var nearest: Node2D = null
	var min_dist = range
	for enemy in enemies:
		var d = user.global_position.distance_to(enemy.global_position)
		if d < min_dist:
			min_dist = d
			nearest = enemy
	return nearest
