extends Node2D

static func warn_position(target: Vector2, radius: float, color: Color, duration: float) -> void:
	var ring = ColorRect.new()
	ring.color = color
	ring.size = Vector2(radius * 2, radius * 2)
	ring.position = target - Vector2(radius, radius)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.modulate.a = 0.4

	var border = ColorRect.new()
	border.color = color
	border.size = Vector2(radius * 2 + 6, radius * 2 + 6)
	border.position = target - Vector2(radius + 3, radius + 3)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.modulate.a = 0.6
	border.z_index = -1

	var scene = Engine.get_main_loop().current_scene
	if not scene:
		return
	scene.add_child(border)
	scene.add_child(ring)

	var tween = scene.create_tween().set_parallel(true)
	tween.tween_property(ring, "modulate:a", 0.8, duration * 0.5)
	tween.tween_property(border, "modulate:a", 1.0, duration * 0.5)
	tween.tween_property(ring, "scale", Vector2(1.3, 1.3), duration)
	tween.tween_property(border, "scale", Vector2(1.3, 1.3), duration)
	tween.set_parallel(false)
	tween.tween_interval(duration * 0.5)
	tween.tween_callback(ring.queue_free)
	tween.tween_callback(border.queue_free)

static func warn_line(from: Vector2, to: Vector2, width: float, color: Color, duration: float) -> void:
	var dir = (to - from).normalized()
	var len = from.distance_to(to)
	var rect = ColorRect.new()
	rect.color = color
	rect.size = Vector2(len, width)
	rect.position = from + dir * len * 0.5 - Vector2(len * 0.5, width * 0.5)
	rect.rotation = atan2(dir.y, dir.x)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.5

	var scene = Engine.get_main_loop().current_scene
	if not scene:
		return
	scene.add_child(rect)

	var tween = scene.create_tween()
	tween.tween_property(rect, "modulate:a", 0.8, duration * 0.5)
	tween.tween_interval(duration * 0.5)
	tween.tween_callback(rect.queue_free)

static func warn_arc(center: Vector2, direction: Vector2, angle_deg: float, radius: float, width: float, color: Color, duration: float) -> void:
	var scene = Engine.get_main_loop().current_scene
	if not scene:
		return
	var seg_count = maxi(ceili(angle_deg / 10.0), 3)
	var half = deg_to_rad(angle_deg * 0.5)
	var base_angle = atan2(direction.y, direction.x)
	for i in range(seg_count):
		var a = base_angle - half + (half * 2.0 * i / (seg_count - 1))
		var p = center + Vector2(cos(a), sin(a)) * radius
		warn_line(p, p + Vector2(cos(a), sin(a)) * width, 4, color, duration)

static func warn_marker(target: Vector2, size: float, color: Color, duration: float) -> void:
	var scene = Engine.get_main_loop().current_scene
	if not scene:
		return
	var offset = Vector2(size, size)
	warn_line(target - offset, target + offset, 4, color, duration)
	var offset2 = Vector2(size, -size)
	warn_line(target - offset2, target + offset2, 4, color, duration)

static func warn_line_pair(center: Vector2, perp_dir: Vector2, half_gap: float, length: float, color: Color, duration: float) -> void:
	var p = perp_dir.normalized()
	var along = Vector2(-p.y, p.x)
	var p1 = center + p * half_gap
	var p2 = center - p * half_gap
	warn_line(p1 - along * length * 0.5, p1 + along * length * 0.5, 12, color, duration)
	warn_line(p2 - along * length * 0.5, p2 + along * length * 0.5, 12, color, duration)
