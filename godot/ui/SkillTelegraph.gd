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
