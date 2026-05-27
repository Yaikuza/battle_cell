extends Resource
class_name PiercingSting

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> bool:
	var damage = stats.get_stat("damage", 10.0)
	var speed = stats.get_stat("projectile_speed", 500.0)
	var range = stats.get_stat("range", 350.0)

	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return false

	var nearest: Node2D = null
	var min_dist = range
	for enemy in enemies:
		var d = user.global_position.distance_to(enemy.global_position)
		if d < min_dist:
			min_dist = d
			nearest = enemy
	if not nearest:
		return false

	var dir = (nearest.global_position - user.global_position).normalized()
	var bullet = PoolManager.get_bullet()
	bullet.global_position = user.global_position + dir * 10.0
	bullet.direction = dir
	bullet.speed = speed * 1.3
	bullet.damage = maxi(ceili(damage * 0.9), 1)
	bullet.max_distance = range
	bullet.piercing = true
	spawn_parent.add_child(bullet)
	return true
