extends Area2D
class_name Boss

var speed: float = 40.0
var damage: int = 25
var gp_value: int = 50
var hp: int = 200
var _damage_cooldown: float = 0.0

var _color: Color = Color(0.8, 0.1, 0.0)
var _size: float = 32.0
var _boss_name: String = "Boss"
var _max_hp: int = 200
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = _size + 4
	add_child(collision)

	_sprite = Sprite2D.new()
	_sprite.name = "BossSprite"
	var tex = _load_texture("tyrant_king")
	if tex:
		_sprite.texture = tex
	_sprite.scale = Vector2.ONE * (_size / 16.0)
	add_child(_sprite)

	var label = Label.new()
	label.text = _boss_name
	label.position = Vector2(-_size - 30, -_size - 35)
	label.size = Vector2(_size * 2 + 60, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	add_child(label)

	var hp_bar_outer = ColorRect.new()
	hp_bar_outer.color = Color(0.2, 0.02, 0.02)
	hp_bar_outer.size = Vector2(_size * 2 + 20, 6)
	hp_bar_outer.position = Vector2(-_size - 10, -_size - 14)
	add_child(hp_bar_outer)

	var hp_bar = ColorRect.new()
	hp_bar.color = Color(1.0, 0.1, 0.0)
	hp_bar.size = Vector2(_size * 2 + 18, 4)
	hp_bar.position = Vector2(-_size - 9, -_size - 13)
	hp_bar.name = "HPBar"
	add_child(hp_bar)

func setup(type: Dictionary) -> void:
	speed = type.get("speed", 40)
	damage = type.get("damage", 25)
	hp = type.get("hp", 200)
	_max_hp = hp
	gp_value = type.get("gp", 50)
	_color = type.get("color", Color(0.8, 0.1, 0.0))
	modulate = _color
	_size = type.get("size", 32.0)
	_boss_name = type.get("name", "Boss")
	if _sprite:
		_sprite.scale = Vector2.ONE * (_size / 16.0)
		var sprite_id = type.get("sprite", "tyrant_king")
		var tex = _load_texture(sprite_id)
		if tex:
			_sprite.texture = tex

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

	var hp_bar = get_node_or_null("HPBar")
	if hp_bar:
		hp_bar.size.x = maxf((_size * 2 + 18) * (hp as float / _max_hp as float), 0)

func take_damage(amount: int) -> void:
	if is_queued_for_deletion():
		return
	hp -= amount
	if hp <= 0:
		_die()
		return
	modulate = Color(1.0, 0.7, 0.7)
	await get_tree().create_timer(0.06).timeout
	if is_queued_for_deletion():
		return
	modulate = Color.WHITE

static func _load_texture(sprite_id: String) -> Texture2D:
	var path = "res://art/forms/" + sprite_id + ".png"
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path)
		if tex:
			return tex
	var img = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _die() -> void:
	EventBus.enemy_died.emit(self, global_position, gp_value)
	EventBus.enemy_killed.emit()
	EventBus.boss_killed.emit()
	for i in range(5):
		var orb = PoolManager.get_orb()
		orb.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		orb.gp_value = ceili(gp_value / 2)
		get_tree().current_scene.call_deferred("add_child", orb)
	queue_free()
