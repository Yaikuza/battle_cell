extends Area2D
class_name Player

const AimedShotScript = preload("res://behaviors/weapons/AimedShot.gd")
const CellBurstScript = preload("res://behaviors/weapons/CellBurst.gd")
const WaterJetScript = preload("res://behaviors/weapons/WaterJet.gd")
const TongueLashScript = preload("res://behaviors/weapons/TongueLash.gd")
const StingDartScript = preload("res://behaviors/weapons/StingDart.gd")
const TailSweepScript = preload("res://behaviors/weapons/TailSweep.gd")
const PiercingStingScript = preload("res://behaviors/weapons/PiercingSting.gd")
const CrushingBiteScript = preload("res://behaviors/weapons/CrushingBite.gd")
const SwarmShotScript = preload("res://behaviors/weapons/SwarmShot.gd")
const PincerClawScript = preload("res://behaviors/weapons/PincerClaw.gd")
const FireBreathScript = preload("res://behaviors/weapons/FireBreath.gd")
const ChaosBeamScript = preload("res://behaviors/weapons/ChaosBeam.gd")
const SlashBehaviorScript = preload("res://behaviors/weapons/SlashBehavior.gd")
const PsychicBlastScript = preload("res://behaviors/weapons/PsychicBlast.gd")
const BouncyShotScript = preload("res://behaviors/weapons/BouncyShot.gd")
const SuctionBehaviorScript = preload("res://behaviors/weapons/SuctionBehavior.gd")
const StareBehaviorScript = preload("res://behaviors/weapons/StareBehavior.gd")
const _weapon_map: Dictionary = {
	"aimed_shot": AimedShotScript,
	"cell_burst": CellBurstScript,
	"water_jet": WaterJetScript,
	"tongue_lash": TongueLashScript,
	"sting_dart": StingDartScript,
	"tail_sweep": TailSweepScript,
	"piercing_sting": PiercingStingScript,
	"crushing_bite": CrushingBiteScript,
	"swarm_shot": SwarmShotScript,
	"pincer_claw": PincerClawScript,
	"fire_breath": FireBreathScript,
	"chaos_beam": ChaosBeamScript,
	"slash": SlashBehaviorScript,
	"psychic_blast": PsychicBlastScript,
	"bouncy_shot": BouncyShotScript,
	"suction": SuctionBehaviorScript,
	"stare": StareBehaviorScript,
}

var stats: StatsResource
var health: HealthComponent
var movement: MovementComponent
var weapon: WeaponComponent
var _sprite: Sprite2D

func _ready() -> void:
	add_to_group("player")

	stats = StatsResource.new()
	stats.load_from_dict({
		"speed": 300.0, "max_hp": 100.0,
		"damage": 15.0, "fire_cooldown": 0.8,
		"projectile_speed": 500.0, "range": 400.0
	})

	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 18
	add_child(collision)

	_sprite = Sprite2D.new()
	_sprite.name = "FormSprite"
	var tex = _load_texture("cell")
	if tex:
		_sprite.texture = tex
	add_child(_sprite)

	health = HealthComponent.new()
	health.max_hp = ceili(stats.get_stat("max_hp"))
	add_child(health)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)

	movement = MovementComponent.new()
	movement.mode = MovementComponent.Mode.PLAYER
	movement.speed = stats.get_stat("speed")
	add_child(movement)

	weapon = WeaponComponent.new()
	weapon.fire_cooldown = stats.get_stat("fire_cooldown")
	weapon.stats_ref = stats
	weapon.behavior = SlashBehaviorScript.new()
	add_child(weapon)

func take_damage(amount: int) -> void:
	health.take_damage(amount)
	if not health.invulnerable:
		health.set_invulnerable(0.5)
		modulate = Color(2, 1.5, 1.5)
		await get_tree().create_timer(0.08).timeout
		if not GameManager.game_over:
			modulate = Color.WHITE

func _on_health_changed(current: int, max_hp: int) -> void:
	pass

func _on_died() -> void:
	EventBus.player_died.emit()

func refresh_from_stats() -> void:
	health.max_hp = maxi(ceili(stats.get_stat("max_hp")), 1)
	health.hp = mini(health.hp, health.max_hp)
	movement.speed = stats.get_stat("speed")
	weapon.fire_cooldown = stats.get_stat("fire_cooldown")
	if weapon._timer:
		weapon._timer.wait_time = maxf(stats.get_stat("fire_cooldown"), 0.1)

func apply_form(form_data: Dictionary, effect: bool = false) -> void:
	var form_stats = form_data.get("stats", {})
	for stat in form_stats:
		stats.set_base(stat, form_stats[stat])

	health.max_hp = ceili(stats.get_stat("max_hp"))
	health.hp = health.max_hp

	movement.speed = stats.get_stat("speed")

	weapon.fire_cooldown = stats.get_stat("fire_cooldown")
	if weapon._timer:
		weapon._timer.wait_time = stats.get_stat("fire_cooldown")

	var weapon_id = form_data.get("weapon", "aimed_shot")
	var behavior_script = _weapon_map.get(weapon_id, AimedShotScript)
	weapon.behavior = behavior_script.new()

	var form_id = form_data.get("id", "")
	var tex = _load_texture(form_id)
	if tex:
		_sprite.texture = tex

	modulate = form_data.get("color", Color.GREEN)
	var size = form_data.get("size", 1.0)
	scale = Vector2.ONE * size

	if effect:
		_animate_evolution()

func _animate_evolution() -> void:
	movement.set_process(false)
	weapon.set_process(false)

	var target_scale = scale
	var target_color = modulate

	var t1 = create_tween()
	t1.tween_property(self, "modulate", Color.WHITE, 0.08)
	t1.parallel().tween_property(self, "scale", target_scale * 0.5, 0.12).set_ease(Tween.EASE_IN)
	await t1.finished

	EffectManager.evolution(global_position)
	_spawn_evolution_ring()

	var t2 = create_tween()
	t2.tween_property(self, "scale", target_scale * 1.5, 0.15).set_ease(Tween.EASE_OUT)
	await t2.finished

	var t3 = create_tween()
	t3.set_parallel(true)
	t3.tween_property(self, "scale", target_scale, 0.15).set_ease(Tween.EASE_OUT)
	t3.tween_property(self, "modulate", target_color, 0.15)
	await t3.finished

	movement.set_process(true)
	weapon.set_process(true)

func _spawn_evolution_ring() -> void:
	var ring = Sprite2D.new()
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 64:
		for y in 64:
			var dx = x - 31.5
			var dy = y - 31.5
			var d = sqrt(dx * dx + dy * dy)
			if d >= 28 and d < 32:
				img.set_pixel(x, y, Color.WHITE)
	ring.texture = ImageTexture.create_from_image(img)
	ring.centered = true
	ring.modulate = Color(1, 1, 1, 0.6)
	ring.scale = Vector2.ZERO
	add_child(ring)
	var t = create_tween()
	t.tween_property(ring, "scale", Vector2(3, 3), 0.4).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
	t.tween_callback(ring.queue_free)

func _load_texture(form_id: String) -> Texture2D:
	var path = "res://art/forms/" + form_id + ".png"
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path)
		if tex:
			return tex
	var img = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null
