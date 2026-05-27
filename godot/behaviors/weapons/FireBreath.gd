extends Resource
class_name FireBreath

const BULLET_COUNT := 5
const CONE_ANGLE := 1.2

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> bool:
	var damage = stats.get_stat("damage", 10.0)
	var speed = stats.get_stat("projectile_speed", 500.0)
	var range = stats.get_stat("range", 400.0)

	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	var target_dir := Vector2.RIGHT
	if not enemies.is_empty():
		var nearest: Node2D = null
		var min_dist = range
		for enemy in enemies:
			var d = user.global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				nearest = enemy
		if nearest:
			target_dir = (nearest.global_position - user.global_position).normalized()

	var base_angle = atan2(target_dir.y, target_dir.x)
	var angle_step = CONE_ANGLE / (BULLET_COUNT - 1)
	var start_angle = base_angle - CONE_ANGLE / 2

	for i in range(BULLET_COUNT):
		var angle = start_angle + angle_step * i
		var dir = Vector2(cos(angle), sin(angle))

		var bullet = PoolManager.get_bullet()
		bullet.global_position = user.global_position + dir * 12.0
		bullet.direction = dir
		bullet.speed = speed * 0.8
		bullet.damage = ceili(damage * 0.6)
		bullet.max_distance = range * 0.7
		spawn_parent.add_child(bullet)
	return true
