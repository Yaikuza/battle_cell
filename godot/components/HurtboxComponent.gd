extends Area2D
class_name HurtboxComponent

signal damage_taken(final_damage: int, damage_type: int)
signal iframe_started()
signal iframe_ended()

var owner_group: String = ""
var armor: int = 0
var damage_multiplier: float = 1.0
var invulnerable: bool = false

var _shape_radius: float = 16.0
var _invuln_timer: Timer

func _init() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true

func _ready() -> void:
	var shape = CollisionShape2D.new()
	shape.name = "HurtboxShape"
	var circle = CircleShape2D.new()
	circle.radius = _shape_radius
	shape.shape = circle
	add_child(shape)

	_invuln_timer = Timer.new()
	_invuln_timer.one_shot = true
	_invuln_timer.timeout.connect(_on_invuln_timeout)
	add_child(_invuln_timer)

func set_shape_radius(radius: float) -> void:
	_shape_radius = radius
	var shape_node = get_node_or_null("HurtboxShape")
	if shape_node and shape_node.shape is CircleShape2D:
		shape_node.shape.radius = radius

func take_hit(hitbox: HitboxComponent) -> void:
	if invulnerable:
		return
	var final_damage = DamageCalculator.calculate(
		hitbox.damage, hitbox.multiplier, armor, hitbox.damage_type
	)
	damage_taken.emit(final_damage, hitbox.damage_type)

func take_direct_hit(amount: int, damage_type: int = 0, mult: float = 1.0) -> void:
	if invulnerable:
		return
	var final_damage = DamageCalculator.calculate(amount, mult, armor, damage_type)
	damage_taken.emit(final_damage, damage_type)

func set_invulnerable(duration: float) -> void:
	if invulnerable:
		return
	invulnerable = true
	iframe_started.emit()
	_invuln_timer.start(duration)

func _on_invuln_timeout() -> void:
	invulnerable = false
	iframe_ended.emit()
