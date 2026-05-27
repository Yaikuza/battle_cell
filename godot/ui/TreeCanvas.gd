extends Control
class_name TreeCanvas

var _line_data: Array = []

func add_line(from: Vector2, to: Vector2, color: Color = Color(0.4, 0.4, 0.4)) -> void:
	_line_data.append({"from": from, "to": to, "color": color})
	queue_redraw()

func clear() -> void:
	_line_data.clear()
	queue_redraw()

func _draw() -> void:
	for l in _line_data:
		draw_line(l.from, l.to, l.color, 2.0)
		var dir = (l.to - l.from).normalized()
		var arrow_len = 8.0
		var perp = Vector2(-dir.y, dir.x)
		var tip = l.to
		var base = tip - dir * arrow_len
		draw_line(tip, base + perp * arrow_len * 0.4, l.color, 2.0)
		draw_line(tip, base - perp * arrow_len * 0.4, l.color, 2.0)
