extends Node
class_name PartBehaviorManager

var _player: Player

func _ready() -> void:
	_player = get_parent() as Player
	if not _player:
		return
	EventBus.part_equipped.connect(_on_part_equipped)
	EventBus.part_unequipped.connect(_on_part_unequipped)

func _exit_tree() -> void:
	if EventBus.part_equipped.is_connected(_on_part_equipped):
		EventBus.part_equipped.disconnect(_on_part_equipped)
	if EventBus.part_unequipped.is_connected(_on_part_unequipped):
		EventBus.part_unequipped.disconnect(_on_part_unequipped)

func _on_part_unequipped(part_id: String) -> void:
	if not _player or not _player.weapon:
		return
	var evo = get_tree().get_first_node_in_group("evolution_manager") as EvolutionManager
	if not evo:
		return
	var pd: Dictionary = evo._body_part_pool.get(part_id, {})
	var behavior_id: String = pd.get("behavior", "")
	if behavior_id == "":
		return
	_player.weapon.remove_part_behavior(behavior_id)

func _on_part_equipped(part_id: String) -> void:
	if not _player or not _player.weapon:
		return
	var evo = get_tree().get_first_node_in_group("evolution_manager") as EvolutionManager
	if not evo:
		return
	var pd: Dictionary = evo._body_part_pool.get(part_id, {})
	var behavior_id: String = pd.get("behavior", "")
	if behavior_id == "":
		return
	_activate_behavior(behavior_id, pd)


func _activate_behavior(behavior_id: String, pd: Dictionary) -> void:
	match behavior_id:
		"flagellum_dash":
			_player.weapon.add_part_behavior(behavior_id, 0.1)
		"cilia_passive":
			_player.weapon.add_part_behavior(behavior_id, 0.2)
		"membrane_reflect":
			_player.weapon.add_part_behavior(behavior_id, 0.5)
		"eyespot_warn":
			_player.weapon.add_part_behavior(behavior_id, 0.3)
		"pseudopod_sweep":
			_player.weapon.add_part_behavior(behavior_id, 1.5)
		"tail_fin_swift":
			_player.weapon.add_part_behavior(behavior_id, 5.0)
		"fang_lunge":
			_player.weapon.add_part_behavior(behavior_id, 3.0)
		"thick_skin_thorns":
			_player.weapon.add_part_behavior(behavior_id, 2.0)
		"webbed_sprint":
			_player.weapon.add_part_behavior(behavior_id, 6.0)


func on_behavior_tick(behavior_id: String) -> void:
	if not _player or GameManager.game_over:
		return
	match behavior_id:
		"flagellum_dash":
			_tick_flagellum_dash()
		"cilia_passive":
			_tick_cilia_passive()
		"membrane_reflect":
			_tick_membrane_reflect()
		"eyespot_warn":
			_tick_eyespot_warn()
		"pseudopod_sweep":
			_tick_pseudopod_sweep()
		"tail_fin_swift":
			_tick_tail_fin_swift()
		"fang_lunge":
			_tick_fang_lunge()
		"thick_skin_thorns":
			_tick_thick_skin_thorns()
		"webbed_sprint":
			_tick_webbed_sprint()


func _tick_flagellum_dash() -> void:
	var player_pos = _player.global_position
	var trail = Sprite2D.new()
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 12:
		for y in 12:
			var dx = x - 5.5
			var dy = y - 5.5
			if abs(dx) + abs(dy) < 5:
				img.set_pixel(x, y, Color(0.3, 1.0, 0.5, 0.6))
	trail.texture = ImageTexture.create_from_image(img)
	trail.position = player_pos + Vector2(randf_range(-4, 4), randf_range(-4, 4))
	trail.modulate.a = 0.0
	get_tree().current_scene.add_child(trail)
	var tween = create_tween()
	tween.tween_property(trail, "modulate:a", 0.6, 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(trail, "modulate:a", 0.0, 0.6)
	tween.tween_callback(trail.queue_free)


func _tick_cilia_passive() -> void:
	var orbs = get_tree().get_nodes_in_group("genetic_orbs")
	var player_pos = _player.global_position
	for orb in orbs:
		if not is_instance_valid(orb):
			continue
		var dist = orb.global_position.distance_to(player_pos)
		if dist < 80:
			var dir = (player_pos - orb.global_position).normalized()
			orb.global_position += dir * 300.0 * 0.2


func _tick_membrane_reflect() -> void:
	var bodies = _player.get_overlapping_areas()
	for body in bodies:
		if not is_instance_valid(body):
			continue
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			var dmg = 10
			if "damage" in body:
				dmg = body.damage
			body.take_damage(ceili(dmg * 0.5))


func _tick_eyespot_warn() -> void:
	var vp = get_viewport().get_visible_rect()
	var margin = 50
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var ep = enemy.global_position
		var is_outside = ep.x < vp.position.x - margin or ep.x > vp.position.x + vp.size.x + margin or ep.y < vp.position.y - margin or ep.y > vp.position.y + vp.size.y + margin
		if is_outside:
			var dist = ep.distance_to(_player.global_position)
			var dir = (ep - _player.global_position).normalized()
			var edge_pos = _player.global_position + dir * 400
			var warn = Sprite2D.new()
			var wimg = Image.create(8, 8, false, Image.FORMAT_RGBA8)
			wimg.fill(Color(0, 0, 0, 0))
			for x in 8:
				for y in 8:
					var dx = x - 3.5
					var dy = y - 3.5
					if abs(dx) + abs(dy) < 4:
						wimg.set_pixel(x, y, Color(1.0, 0.2, 0.2, 0.8))
			warn.texture = ImageTexture.create_from_image(wimg)
			warn.global_position = edge_pos
			warn.z_index = 100
			get_tree().current_scene.add_child(warn)
			var tween = create_tween()
			tween.tween_interval(0.5)
			tween.tween_callback(warn.queue_free)


func _tick_pseudopod_sweep() -> void:
	var move_dir = Vector2.RIGHT
	var input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vec.length_squared() > 0.01:
		move_dir = input_vec.normalized()
	var sweep_angle = 120.0
	var half = deg_to_rad(sweep_angle * 0.5)
	var base = move_dir.angle()
	var arc_points = 6
	for i in range(arc_points):
		var a = base - half + (i * deg_to_rad(sweep_angle) / (arc_points - 1))
		var dir = Vector2(cos(a), sin(a))
		var dist = 60.0
		var hit_pos = _player.global_position + dir * dist
		var hit = get_tree().current_scene
		for body in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(body):
				continue
			var bdist = body.global_position.distance_to(hit_pos)
			if bdist < 30 and body.has_method("take_damage"):
				body.take_damage(ceili(_player.stats.get_stat("damage") * 0.6))
				EventBus.player_dealt_damage.emit(ceili(_player.stats.get_stat("damage") * 0.6))
	var vis = Sprite2D.new()
	var vimg = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	vimg.fill(Color(0, 0, 0, 0))
	for x in 24:
		for y in 24:
			var dx = x - 11.5
			var dy = y - 11.5
			if abs(dx) + abs(dy) < 10:
				vimg.set_pixel(x, y, Color(1.0, 0.8, 0.4, 0.5))
	vis.texture = ImageTexture.create_from_image(vimg)
	vis.global_position = _player.global_position + move_dir * 40
	vis.rotation = base
	get_tree().current_scene.add_child(vis)
	var tw = create_tween()
	tw.tween_property(vis, "modulate:a", 0.0, 0.2)
	tw.tween_callback(vis.queue_free)

func _tick_tail_fin_swift() -> void:
	_player.stats.remove_modifiers_from("tail_fin_boost")
	_player.stats.add_modifier_raw("speed", 0.40, 1, "tail_fin_boost")
	_player.refresh_from_stats()
	var t = get_tree().create_timer(1.0)
	t.timeout.connect(func():
		if is_instance_valid(_player):
			_player.stats.remove_modifiers_from("tail_fin_boost")
			_player.refresh_from_stats()
	)

func _tick_fang_lunge() -> void:
	var nearest = null
	var nearest_dist = 150.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var d = enemy.global_position.distance_to(_player.global_position)
		if d < nearest_dist:
			nearest = enemy
			nearest_dist = d
	if not nearest:
		return
	var dir = (nearest.global_position - _player.global_position).normalized()
	_player.global_position += dir * 80.0
	if nearest.has_method("take_damage"):
		var dmg = ceili(_player.stats.get_stat("damage") * 0.75)
		nearest.take_damage(dmg)
		EventBus.player_dealt_damage.emit(dmg)
	var vis = Sprite2D.new()
	var vimg = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	vimg.fill(Color(0, 0, 0, 0))
	for x in 12:
		for y in 12:
			if abs(x - 5.5) + abs(y - 5.5) < 5:
				vimg.set_pixel(x, y, Color(1.0, 0.3, 0.3, 0.7))
	vis.texture = ImageTexture.create_from_image(vimg)
	vis.global_position = _player.global_position + dir * 20
	get_tree().current_scene.add_child(vis)
	var vt = create_tween()
	vt.tween_property(vis, "modulate:a", 0.0, 0.3)
	vt.tween_callback(vis.queue_free)

func _tick_thick_skin_thorns() -> void:
	for body in _player.get_overlapping_areas():
		if not is_instance_valid(body):
			continue
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(20)
			EventBus.player_dealt_damage.emit(20)
	var vis = Sprite2D.new()
	var vimg = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	vimg.fill(Color(0, 0, 0, 0))
	for x in 20:
		for y in 20:
			if abs(x - 9.5) + abs(y - 9.5) < 9:
				vimg.set_pixel(x, y, Color(0.5, 0.5, 0.2, 0.5))
	vis.texture = ImageTexture.create_from_image(vimg)
	vis.global_position = _player.global_position
	get_tree().current_scene.add_child(vis)
	var vt = create_tween()
	vt.tween_property(vis, "modulate:a", 0.0, 0.25)
	vt.tween_callback(vis.queue_free)

func _tick_webbed_sprint() -> void:
	_player.stats.remove_modifiers_from("webbed_sprint_boost")
	_player.stats.add_modifier_raw("speed", 0.60, 1, "webbed_sprint_boost")
	_player.refresh_from_stats()
	var t = get_tree().create_timer(0.8)
	t.timeout.connect(func():
		if is_instance_valid(_player):
			_player.stats.remove_modifiers_from("webbed_sprint_boost")
			_player.refresh_from_stats()
	)
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT
	else:
		dir = dir.normalized()
	var vis = Sprite2D.new()
	var vimg = Image.create(8, 14, false, Image.FORMAT_RGBA8)
	vimg.fill(Color(0, 0, 0, 0))
	for x in 8:
		for y in 14:
			if abs(x - 3.5) < 2 and y > 2:
				vimg.set_pixel(x, y, Color(0.2, 0.6, 1.0, 0.6))
	vis.texture = ImageTexture.create_from_image(vimg)
	vis.global_position = _player.global_position + dir * 30
	vis.rotation = dir.angle()
	get_tree().current_scene.add_child(vis)
	var vt = create_tween()
	vt.tween_property(vis, "modulate:a", 0.0, 0.3)
	vt.tween_callback(vis.queue_free)
