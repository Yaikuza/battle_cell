extends Resource
class_name BouncyShot

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
	bullet.global_position = user.global_position + dir * 8.0
	bullet.direction = dir
	bullet.speed = speed * 1.1
	bullet.damage = maxi(ceili(damage), 1)
	bullet.max_distance = range
	bullet.bounce_count = 3

	var spr = bullet.get_node_or_null("FormSprite")
	if not spr:
		spr = Sprite2D.new()
		spr.name = "FormSprite"
		bullet.add_child(spr)
	var img = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 14:
		for y in 14:
			var dx = x - 6.5
			var dy = y - 6.5
			var d = sqrt(dx * dx + dy * dy)
			if d < 6: img.set_pixel(x, y, Color(1.0, 0.9, 0.2))
			if d < 3: img.set_pixel(x, y, Color(1.0, 1.0, 0.6))
	spr.texture = ImageTexture.create_from_image(img)
	spawn_parent.add_child(bullet)
	return true
