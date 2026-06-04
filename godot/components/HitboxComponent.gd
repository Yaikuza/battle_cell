extends Area2D
class_name HitboxComponent

signal hit_detected(hurtbox: HurtboxComponent)

enum DamageType { PHYSICAL, MAGIC, TRUE }

var damage: int = 0
var damage_type: int = DamageType.PHYSICAL
var multiplier: float = 1.0

var _shape_radius: float = 6.0

func _init() -> void:
	collision_layer = 2
	collision_mask = 4
	monitoring = true
	monitorable = true

	var shape = CollisionShape2D.new()
	shape.name = "HitboxShape"
	var circle = CircleShape2D.new()
	circle.radius = _shape_radius
	shape.shape = circle
	add_child(shape)

	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		area.take_hit(self)
		hit_detected.emit(area)
