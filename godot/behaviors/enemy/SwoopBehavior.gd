extends EnemyBehavior
class_name SwoopBehavior

var _move_dir: Vector2 = Vector2.RIGHT
var _timer: float = 0.0
var _phase: int = 0

func init(_enemy: Node2D, _type: Dictionary) -> void:
	_move_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))
	_timer = 2.0

func process(enemy: Node2D, player: Node2D, delta: float) -> void:
	var vp = enemy.get_viewport().get_visible_rect().size
	var margin = 60.0

	match _phase:
		0:
			_timer -= delta
			if _timer <= 0:
				var to = player.global_position - enemy.global_position
				_move_dir = to.normalized()
				_timer = 1.5
				_phase = 1
			var dir = (player.global_position - enemy.global_position).normalized()
			enemy.global_position += dir * enemy.speed * 0.3 * delta
		1:
			_timer -= delta
			enemy.global_position += _move_dir * enemy.speed * 2.0 * delta
			if _timer <= 0:
				_phase = 0
				_timer = randf_range(0.5, 1.5)

	if enemy.global_position.x < -margin:
		_move_dir.x = absf(_move_dir.x)
		_phase = 0
		_timer = 0.5
	elif enemy.global_position.x > vp.x + margin:
		_move_dir.x = -absf(_move_dir.x)
		_phase = 0
		_timer = 0.5
	if enemy.global_position.y < -margin:
		_move_dir.y = absf(_move_dir.y)
		_phase = 0
		_timer = 0.5
	elif enemy.global_position.y > vp.y + margin:
		_move_dir.y = -absf(_move_dir.y)
		_phase = 0
		_timer = 0.5

func on_reset(_enemy: Node2D) -> void:
	_move_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))
	_timer = 2.0
	_phase = 0
