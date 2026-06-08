extends Area2D
class_name Boss

const BossSkillControllerScript = preload("res://components/BossSkillController.gd")

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
var _hurtbox: HurtboxComponent
var _skill_controller

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	collision_mask = 5
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

	_hurtbox = HurtboxComponent.new()
	_hurtbox.owner_group = "enemy"
	_hurtbox.name = "BossHurtbox"
	_hurtbox.damage_taken.connect(_on_hurtbox_damage_taken)
	add_child(_hurtbox)

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

	var skill_ids: Array = type.get("skill_ids", [])
	if not skill_ids.is_empty():
		_skill_controller = BossSkillControllerScript.new()
		_skill_controller.setup(self, skill_ids, 2, Color(1.0, 0.6, 0.0))
		add_child(_skill_controller)

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
		_check_far_from_player(player)

	if _damage_cooldown > 0:
		_damage_cooldown -= delta
	else:
		for area in get_overlapping_areas():
			if area is HurtboxComponent and area.owner_group == "player":
				area.take_direct_hit(damage, HitboxComponent.DamageType.PHYSICAL)
				_damage_cooldown = 0.5
				break

	if _skill_controller and _skill_controller.can_use_skill() and _damage_cooldown <= 0:
		if randf() < 0.03:
			_skill_controller.try_execute_skill()

	var hp_bar = get_node_or_null("HPBar")
	if hp_bar:
		hp_bar.size.x = maxf((_size * 2 + 18) * (hp as float / _max_hp as float), 0)

func _check_far_from_player(player: Node2D) -> void:
	var viewport = get_viewport().get_visible_rect().size
	var cam = player.get_node("PlayerCamera") as Camera2D
	var zoom = cam.zoom.x if cam else 1.0
	var threshold = 5.0 * maxf(viewport.x / zoom, viewport.y / zoom)
	if global_position.distance_squared_to(player.global_position) > threshold * threshold:
		var viewport_half = Vector2(viewport.x / zoom / 2.0, viewport.y / zoom / 2.0)
		var margin = 60
		var side = randi() % 4
		match side:
			0: global_position = player.global_position + Vector2(randf_range(-viewport_half.x, viewport_half.x), -viewport_half.y - margin)
			1: global_position = player.global_position + Vector2(randf_range(-viewport_half.x, viewport_half.x), viewport_half.y + margin)
			2: global_position = player.global_position + Vector2(-viewport_half.x - margin, randf_range(-viewport_half.y, viewport_half.y))
			3: global_position = player.global_position + Vector2(viewport_half.x + margin, randf_range(-viewport_half.y, viewport_half.y))

func take_damage(amount: int) -> void:
	if is_queued_for_deletion():
		return
	hp -= amount
	if hp <= 0:
		_die()
		return
	_damage_flash()

func _on_hurtbox_damage_taken(damage: int, _damage_type: int) -> void:
	take_damage(damage)

func _damage_flash() -> void:
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
