extends Area2D
class_name Enemy

var speed: float = 60.0
var damage: int = 10
var gp_value: int = 5
var hp: int = 20
var _damage_cooldown: float = 0.0

var _color: Color = Color.RED
var _size: float = 14.0
var _name_text: String = ""
var _collision_shape: CollisionShape2D

func _init() -> void:
	add_to_group("enemies")
	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = CircleShape2D.new()
	_collision_shape.shape.radius = _size + 2
	add_child(_collision_shape)

func _pool_init() -> void:
	visible = true
	set_process(true)

func _pool_reset() -> void:
	visible = false
	set_process(false)
	for c in get_children():
		if c is Label:
			c.queue_free()
	speed = 60.0
	damage = 10
	gp_value = 5
	hp = 0
	_damage_cooldown = 0.0
	_color = Color.RED
	_size = 14.0
	_name_text = ""
	modulate = Color.WHITE

func setup(type: Dictionary) -> void:
	speed = type.get("speed", 60)
	damage = type.get("damage", 10)
	hp = type.get("hp", 20)
	gp_value = type.get("gp", 5)
	_color = type.get("color", Color.RED)
	_size = type.get("size", 14.0)
	_name_text = type.get("name", "")
	if _collision_shape and _collision_shape.shape:
		_collision_shape.shape.radius = _size + 2
	if _name_text:
		var label = Label.new()
		label.text = _name_text
		label.position = Vector2(-_size - 20, -_size - 28)
		label.size = Vector2(_size * 2 + 40, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		add_child(label)

func _draw() -> void:
	draw_circle(Vector2.ZERO, _size + 2, _color)
	draw_arc(Vector2.ZERO, _size, 0, TAU, 32, _color.darkened(0.4), 2.0)

func _process(delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player:
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * speed * delta

	if _damage_cooldown > 0:
		_damage_cooldown -= delta
	else:
		for area in get_overlapping_areas():
			if area.is_in_group("player"):
				area.take_damage(damage)
				_damage_cooldown = 0.5
				break

func take_damage(amount: int) -> void:
	if is_queued_for_deletion():
		return
	hp -= amount
	if hp <= 0:
		_die()
		return
	modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.04).timeout
	if is_queued_for_deletion():
		return
	modulate = Color.WHITE

func _die() -> void:
	EventBus.enemy_died.emit(self, global_position, gp_value)
	_show_damage_number(0)
	var orb = PoolManager.get_orb()
	orb.global_position = global_position
	orb.gp_value = gp_value
	get_tree().current_scene.call_deferred("add_child", orb)
	PoolManager.release_enemy(self)

func _show_damage_number(amount: int) -> void:
	var label = Label.new()
	label.text = str(amount) if amount > 0 else ""
	label.position = Vector2(-10, -_size - 25)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position:y", -_size - 45, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)
