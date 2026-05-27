extends EnemyBehavior
class_name ChaseBehavior

func process(enemy: Node2D, player: Node2D, delta: float) -> void:
	var dir = (player.global_position - enemy.global_position).normalized()
	enemy.global_position += dir * enemy.speed * delta
