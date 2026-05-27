extends EnemyBehavior
class_name ChargeBehavior

var _phase: int = 0
var _timer: float = 0.0
var _charge_speed: float = 0.0
var _direction: Vector2 = Vector2.ZERO

func init(enemy: Node2D, type: Dictionary) -> void:
	_charge_speed = enemy.speed * type.get("charge_mult", 3.5)
	_phase = 0
	_timer = 1.0

func process(enemy: Node2D, player: Node2D, delta: float) -> void:
	_timer -= delta
	match _phase:
		0:
			if _timer <= 0:
				_phase = 1
				_direction = (player.global_position - enemy.global_position).normalized()
				_timer = 0.25
		1:
			enemy.global_position += _direction * _charge_speed * delta
			if _timer <= 0:
				_phase = 2
				_timer = 0.6
		2:
			var dir = (player.global_position - enemy.global_position).normalized()
			enemy.global_position += dir * enemy.speed * 0.4 * delta
			if _timer <= 0:
				_phase = 1
				_direction = (player.global_position - enemy.global_position).normalized()
				_timer = 0.3

func on_reset(_enemy: Node2D) -> void:
	_phase = 0
	_timer = 1.0
