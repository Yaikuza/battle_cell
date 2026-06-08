extends Node
class_name PartEffectHandler

var player: Player
var _effects: Dictionary = {}
var _venom_timer: Timer

func _ready() -> void:
	player = get_parent() as Player
	EventBus.player_hit_enemy.connect(_on_player_hit_enemy)
	EventBus.part_unique_activated.connect(_on_unique_activated)
	_venom_timer = Timer.new()
	_venom_timer.one_shot = false
	_venom_timer.timeout.connect(_spawn_venom_trail)
	add_child(_venom_timer)

func _exit_tree() -> void:
	if EventBus.player_hit_enemy.is_connected(_on_player_hit_enemy):
		EventBus.player_hit_enemy.disconnect(_on_player_hit_enemy)
	if EventBus.part_unique_activated.is_connected(_on_unique_activated):
		EventBus.part_unique_activated.disconnect(_on_unique_activated)

func _on_unique_activated(effect: String, tier: int, behavior_id: String = "") -> void:
	_effects[effect] = {"tier": tier, "behavior_id": behavior_id}
	match effect:
		"venom_trail":
			_venom_timer.start(0.5)
		"break":
			pass
		"lifesteal":
			pass
		"double_attack":
			pass
		"stun":
			pass
		"pull":
			pass
		"deflect":
			if not player._hurtbox.damage_taken.is_connected(_on_player_damage_taken):
				player._hurtbox.damage_taken.connect(_on_player_damage_taken)

func has_effect(effect: String) -> bool:
	return _effects.has(effect)

func get_tier(effect: String) -> int:
	var e = _effects.get(effect)
	return e["tier"] if e else 1

func get_effect_behavior_id(effect: String) -> String:
	var e = _effects.get(effect)
	return e.get("behavior_id", "") if e else ""

func get_double_attack_chance(behavior_id: String = "") -> float:
	if not _effects.has("double_attack"):
		return 0.0
	var e = _effects["double_attack"]
	var bid = e.get("behavior_id", "")
	if bid != "" and bid != behavior_id:
		return 0.0
	return [0.20, 0.35, 0.50][e["tier"] - 1]

func _effect_tier(effect: String) -> int:
	var e = _effects.get(effect)
	return e["tier"] if e else 1

func _on_player_hit_enemy(enemy: Node2D, damage: int) -> void:
	if _effects.has("lifesteal"):
		var pct = [0.05, 0.10, 0.18][_effect_tier("lifesteal") - 1]
		var heal = maxi(1, ceili(damage * pct))
		player.health.heal(heal)

	if _effects.has("stun") and enemy.has_method("apply_stun"):
		var chance = [0.15, 0.30, 0.50][_effect_tier("stun") - 1]
		if randf() < chance:
			enemy.apply_stun(0.5)

	if _effects.has("break") and enemy is Enemy:
		var mult = [0.10, 0.20, 0.35][_effect_tier("break") - 1]
		enemy._break_bonus = mult
		enemy._break_timer.start(3.0)

	if _effects.has("pull") and enemy is Enemy:
		var strength = [150.0, 250.0, 400.0][_effect_tier("pull") - 1]
		var dir = (player.global_position - enemy.global_position).normalized()
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		tween.tween_property(enemy, "global_position", enemy.global_position + dir * strength, 0.25)

func _on_player_damage_taken(damage: int, _damage_type: int) -> void:
	if not _effects.has("deflect"):
		return
	var pct = [0.08, 0.15, 0.25][_effect_tier("deflect") - 1]
	var reflected = maxi(1, ceili(damage * pct))
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var nearest: Node2D = null
	var min_dist = INF
	for e in enemies:
		var d = player.global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	if nearest and nearest.has_method("take_damage"):
		nearest.take_damage(reflected)
		EffectManager.hit(nearest.global_position, Color(0.3, 0.6, 1.0))

func _spawn_venom_trail() -> void:
	if not _effects.has("venom_trail"):
		return
	var damage = [5, 10, 18][_effect_tier("venom_trail") - 1]
	var cloud = Area2D.new()
	cloud.collision_layer = 0
	cloud.collision_mask = 4
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24
	shape.shape = circle
	cloud.add_child(shape)
	var sprite = Sprite2D.new()
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 48:
		for y in 48:
			var dx = x - 23.5
			var dy = y - 23.5
			if sqrt(dx * dx + dy * dy) < 22:
				var a = 1.0 - sqrt(dx * dx + dy * dy) / 22.0
				img.set_pixel(x, y, Color(0.3, 0.9, 0.3, a * 0.4))
			elif sqrt(dx * dx + dy * dy) < 24:
				img.set_pixel(x, y, Color(0.3, 0.9, 0.3, 0.15))
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = true
	cloud.add_child(sprite)
	cloud.global_position = player.global_position
	cloud.area_entered.connect(func(area: Area2D) -> void:
		if area is HurtboxComponent and area.owner_group == "enemy":
			area.take_direct_hit(damage, HitboxComponent.DamageType.MAGIC)
	)
	get_tree().current_scene.add_child(cloud)
	var tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(cloud.queue_free)
