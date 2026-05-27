extends Area2D
class_name Bullet

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 10
var max_distance: float = 600.0
var piercing: bool = false
var explosion_radius: float = 0.0
var explosion_damage: int = 0
var _distance_traveled: float = 0.0

func _init() -> void:
	add_to_group("projectiles")
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 6
	add_child(collision)
	area_entered.connect(_on_hit)

func _pool_init() -> void:
	_distance_traveled = 0.0
	visible = true
	set_process(true)

func _pool_reset() -> void:
	visible = false
	set_process(false)
	direction = Vector2.RIGHT
	speed = 500.0
	damage = 0
	max_distance = 600.0
	piercing = false
	explosion_radius = 0.0
	explosion_damage = 0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7, Color.YELLOW)
	draw_circle(Vector2.ZERO, 4, Color.WHITE)

func _process(delta: float) -> void:
	var move = direction * speed * delta
	global_position += move
	_distance_traveled += move.length()
	if _distance_traveled >= max_distance:
		PoolManager.release_bullet(self)

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(damage)
		if explosion_radius > 0:
			_explode()
		if not piercing:
			PoolManager.release_bullet(self)

func _explode() -> void:
	var space = get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1
	for result in space.intersect_shape(query):
		var area = result.collider
		if area.is_in_group("enemies") and area.has_method("take_damage"):
			area.take_damage(explosion_damage)
