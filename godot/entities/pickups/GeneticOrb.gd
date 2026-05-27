extends Area2D
class_name GeneticOrb

var gp_value: int = 5
var _attract_speed: float = 250.0
var _attract_radius: float = 100.0
var _being_attracted: bool = false

func _init() -> void:
	add_to_group("items")
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
			if d < 6: img.set_pixel(x, y, Color(0.2, 1.0, 0.3))
			if d < 3.5: img.set_pixel(x, y, Color.WHITE)
	spr.texture = ImageTexture.create_from_image(img)
	add_child(spr)
	area_entered.connect(_on_collected)

func _pool_init() -> void:
	visible = true
	set_process(true)

func _pool_reset() -> void:
	visible = false
	set_process(false)
	gp_value = 5
	_attract_speed = 250.0
	_attract_radius = 100.0
	_being_attracted = false

func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)
	if _being_attracted or dist < _attract_radius:
		_being_attracted = true
		global_position += (player.global_position - global_position).normalized() * _attract_speed * delta

func _on_collected(area: Area2D) -> void:
	if area.is_in_group("player"):
		EffectManager.collect(global_position)
		EventBus.gp_collected.emit(gp_value)
		PoolManager.release_orb(self)
