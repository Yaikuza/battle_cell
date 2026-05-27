extends Area2D
class_name Enemy

const _behavior_paths: Dictionary = {
	"chase": "res://behaviors/enemy/ChaseBehavior.gd",
	"ranged": "res://behaviors/enemy/RangedBehavior.gd",
	"charge": "res://behaviors/enemy/ChargeBehavior.gd",
	"flank": "res://behaviors/enemy/FlankBehavior.gd",
	"tank": "res://behaviors/enemy/TankBehavior.gd",
	"swoop": "res://behaviors/enemy/SwoopBehavior.gd",
}

var speed: float = 60.0
var damage: int = 10
var gp_value: int = 5
var hp: int = 20
var _damage_cooldown: float = 0.0

var _color: Color = Color.RED
var _size: float = 14.0
var _name_text: String = ""
var _sprite: Sprite2D
var _collision_shape: CollisionShape2D
var _behavior

func _init() -> void:
	add_to_group("enemies")
	_collision_shape = CollisionShape2D.new()
	_collision_shape.shape = CircleShape2D.new()
	_collision_shape.shape.radius = _size + 2
	add_child(_collision_shape)
	_sprite = Sprite2D.new()
	_sprite.name = "EnemySprite"
	add_child(_sprite)

func _pool_init() -> void:
	visible = true
	set_process(true)
	if _behavior and _behavior.has_method("on_reset"):
		_behavior.on_reset(self)

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
	_behavior = null
	modulate = Color.WHITE

func setup(type: Dictionary) -> void:
	speed = type.get("speed", 60)
	damage = type.get("damage", 10)
	hp = type.get("hp", 20)
	gp_value = type.get("gp", 5)
	var color = type.get("color", Color.RED)
	_color = color
	_size = type.get("size", 14.0)
	_name_text = type.get("name", "")
	modulate = color
	if _collision_shape and _collision_shape.shape:
		_collision_shape.shape.radius = _size + 2
	var scale_val = _size / 14.0
	_sprite.scale = Vector2.ONE * scale_val
	var sprite_id = type.get("sprite", "enemy")
	var tex = _load_texture(sprite_id)
	if tex:
		_sprite.texture = tex
	if _name_text:
		var label = Label.new()
		label.text = _name_text
		label.position = Vector2(-_size - 20, -_size - 28)
		label.size = Vector2(_size * 2 + 40, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		add_child(label)
	var behavior_id = type.get("behavior", "chase")
	var path = _behavior_paths.get(behavior_id, _behavior_paths["chase"])
	var script = load(path)
	if script:
		_behavior = script.new()
		_behavior.init(self, type)

static func _load_texture(sprite_id: String) -> Texture2D:
	if sprite_id.is_empty():
		return null
	var path = "res://art/forms/" + sprite_id + ".png"
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path)
		if tex:
			return tex
	var img = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _process(delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player and _behavior:
		_behavior.process(self, player, delta)

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
	EventBus.enemy_killed.emit()
	EffectManager.death(global_position, Color(_color.r, _color.g, _color.b))
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
