extends Area2D
class_name Bullet

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 10
var max_distance: float = 600.0
var piercing: bool = false
var explosion_radius: float = 0.0
var explosion_damage: int = 0
var bounce_count: int = 0
var _distance_traveled: float = 0.0

func _init() -> void:
	add_to_group("projectiles")
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 6
	add_child(collision)
	var spr = Sprite2D.new()
	var img = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 12:
		for y in 12:
			var dx = x - 5.5
			var dy = y - 5.5
			var d = sqrt(dx * dx + dy * dy)
			if d < 6: img.set_pixel(x, y, Color(1.0, 0.85, 0.1))
			if d < 3.5: img.set_pixel(x, y, Color.WHITE)
	spr.texture = ImageTexture.create_from_image(img)
	add_child(spr)
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
	bounce_count = 0

func _process(delta: float) -> void:
	var move = direction * speed * delta
	global_position += move
	_distance_traveled += move.length()
	if _distance_traveled >= max_distance:
		PoolManager.release_bullet(self)

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(damage)
		EffectManager.hit(global_position)
		AudioManager.play_sfx("hit", global_position)
		if explosion_radius > 0:
			_explode()
		if bounce_count > 0:
			bounce_count -= 1
			direction = (global_position - area.global_position).normalized()
			return
		if not piercing:
			PoolManager.release_bullet(self)

func _explode() -> void:
	EffectManager.explosion(global_position, explosion_radius)
	AudioManager.play_sfx("explosion", global_position)
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
