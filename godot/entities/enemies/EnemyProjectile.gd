extends Area2D
class_name EnemyProjectile

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: int = 5:
	set(value):
		damage = value
		if _hitbox:
			_hitbox.damage = value
			_hitbox.multiplier = 1.0
var _lifetime: float = 2.0
var _hitbox: HitboxComponent

func _init() -> void:
	_hitbox = HitboxComponent.new()
	_hitbox._shape_radius = 4.0
	_hitbox.name = "ProjHitbox"
	add_child(_hitbox)
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

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()
