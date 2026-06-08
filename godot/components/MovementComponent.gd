extends Node
class_name MovementComponent

enum Mode { IDLE, CHASE, PLAYER }

@export var mode: Mode = Mode.CHASE
@export var speed: float = 100.0

var target: Node2D = null

func _process(delta: float) -> void:
	var parent = get_parent() as Node2D
	if not parent:
		return

	if parent is Enemy and parent._stunned:
		return

	match mode:
		Mode.CHASE:
			if is_instance_valid(target):
				var dir = (target.global_position - parent.global_position).normalized()
				parent.global_position += dir * speed * delta
		Mode.PLAYER:
			var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if dir.length_squared() > 0.0:
				parent.global_position += dir * speed * delta

			var viewport = get_viewport().get_visible_rect().size
			var center = viewport * 0.5
			var to_center = parent.global_position - center
			var max_dist = (mini(center.x, center.y) - 20.0) * 10.0
			if to_center.length() > max_dist:
				parent.global_position = center + to_center.normalized() * max_dist
