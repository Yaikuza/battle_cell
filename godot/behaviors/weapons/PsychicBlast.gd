extends Resource
class_name PsychicBlast

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> bool:
	var damage = stats.get_stat("damage", 10.0)
	var speed = stats.get_stat("projectile_speed", 500.0)
	var range = stats.get_stat("range", 500.0)

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
	bullet.global_position = user.global_position + dir * 12.0
	bullet.direction = dir
	bullet.speed = speed * 1.2
	var evo_count = maxi(1, spawn_parent.get_tree().get_first_node_in_group("evolution_manager")._evolution_path.size())
	bullet.damage = maxi(ceili(damage * (1.0 + 0.03 * evo_count)), 1)
	bullet.max_distance = range
	bullet.piercing = true

	var spr = bullet.get_node_or_null("FormSprite")
	if not spr:
		spr = Sprite2D.new()
		spr.name = "FormSprite"
		bullet.add_child(spr)
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 24:
		for y in 24:
			var dx = x - 11.5
			var dy = y - 11.5
			var d = sqrt(dx * dx + dy * dy)
			if d < 11: img.set_pixel(x, y, Color(0.4, 0.6, 1.0))
			if d < 7: img.set_pixel(x, y, Color(0.7, 0.8, 1.0))
			if d < 3: img.set_pixel(x, y, Color.WHITE)
	spr.texture = ImageTexture.create_from_image(img)
	spr.scale = Vector2.ONE
	spawn_parent.add_child(bullet)
	return true
