extends Resource
class_name CellBurst

const BULLET_COUNT := 6

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> void:
	var damage = stats.get_stat("damage", 10.0)
	var speed = stats.get_stat("projectile_speed", 500.0)
	var range = stats.get_stat("range", 250.0)

	var angle_step = TAU / BULLET_COUNT
	for i in range(BULLET_COUNT):
		var angle = angle_step * i
		var dir = Vector2(cos(angle), sin(angle))

		var bullet = PoolManager.get_bullet()
		bullet.global_position = user.global_position + dir * 10.0
		bullet.direction = dir
		bullet.speed = speed
		bullet.damage = maxi(ceili(damage * 0.5), 1)
		bullet.max_distance = range
		spawn_parent.add_child(bullet)
