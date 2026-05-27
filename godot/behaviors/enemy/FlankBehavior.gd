extends EnemyBehavior
class_name FlankBehavior

var _circle_dir: float = 1.0
var _dart_timer: float = 0.0

func init(_enemy: Node2D, _type: Dictionary) -> void:
	_circle_dir = 1.0 if randf() > 0.5 else -1.0
	_dart_timer = 2.0

func process(enemy: Node2D, player: Node2D, delta: float) -> void:
	var to_player = player.global_position - enemy.global_position
	var dist = to_player.length()
	var dir = to_player.normalized()

	_dart_timer -= delta
	if _dart_timer <= 0:
		enemy.global_position += dir * enemy.speed * 2.5 * delta
		if _dart_timer <= -0.4:
			_dart_timer = randf_range(1.5, 3.0)

	var lateral = Vector2(-dir.y, dir.x) * _circle_dir
	enemy.global_position += lateral * enemy.speed * 0.6 * delta

func on_reset(_enemy: Node2D) -> void:
	_circle_dir = 1.0 if randf() > 0.5 else -1.0
	_dart_timer = 2.0
