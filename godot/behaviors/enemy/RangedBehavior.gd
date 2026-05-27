extends EnemyBehavior
class_name RangedBehavior

const EnemyProjectile = preload("res://entities/enemies/EnemyProjectile.gd")
var _fire_cooldown: float = 0.0
var _fire_interval: float = 1.5
var _preferred_range: float = 180.0

func init(enemy: Node2D, type: Dictionary) -> void:
	_fire_interval = type.get("fire_interval", 1.5)
	_preferred_range = type.get("range", 180.0)
	_fire_cooldown = 0.0

func process(enemy: Node2D, player: Node2D, delta: float) -> void:
	var dir = (player.global_position - enemy.global_position)
	var dist = dir.length()
	dir = dir.normalized()

	if dist < _preferred_range * 0.6:
		enemy.global_position -= dir * enemy.speed * delta
	elif dist > _preferred_range:
		enemy.global_position += dir * enemy.speed * delta
	else:
		var lateral = Vector2(-dir.y, dir.x)
		enemy.global_position += lateral * enemy.speed * 0.5 * delta

	_fire_cooldown -= delta
	if _fire_cooldown <= 0 and dist < _preferred_range * 1.3:
		var proj = EnemyProjectile.new()
		proj.global_position = enemy.global_position
		proj.direction = dir
		proj.damage = enemy.damage
		get_tree().current_scene.add_child(proj)
		_fire_cooldown = _fire_interval
