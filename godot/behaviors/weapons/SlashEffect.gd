extends Node2D
class_name SlashEffect

var dir: Vector2 = Vector2.RIGHT
var arc_angle: float = deg_to_rad(90.0)
var range: float = 140.0
var color: Color = Color.WHITE

var _elapsed: float = 0.0
var _duration: float = 0.15

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var t = minf(_elapsed / _duration, 1.0)
	var alpha = 1.0 - t
	var radius = range * (0.3 + 0.7 * t)

	var start_angle = dir.angle() - arc_angle * 0.5
	var end_angle = dir.angle() + arc_angle * 0.5
	var segs = maxi(ceili(arc_angle * radius * 0.02), 6)

	var fill_color = Color(color.r, color.g, color.b, alpha * 0.35)
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	for i in range(segs + 1):
		var a = start_angle + (end_angle - start_angle) * (float(i) / segs)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	draw_polygon(pts, [fill_color])

	var line_color = Color(color.r, color.g, color.b, alpha * 0.85)
	draw_arc(Vector2.ZERO, radius, start_angle, end_angle, segs, line_color, 2.5 + (1.0 - t) * 1.5)
