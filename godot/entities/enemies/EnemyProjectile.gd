extends Area2D
class_name EnemyProjectile

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: int = 5
var _lifetime: float = 2.0

func _init() -> void:
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 4
	add_child(collision)
	var spr = Sprite2D.new()
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 8:
		for y in 8:
			var dx = x - 3.5
			var dy = y - 3.5
			if sqrt(dx * dx + dy * dy) < 3.5:
				img.set_pixel(x, y, Color(0.9, 0.7, 0.1))
	spr.texture = ImageTexture.create_from_image(img)
	add_child(spr)
	area_entered.connect(_on_hit)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("player") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
