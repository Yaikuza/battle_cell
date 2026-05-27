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
}

var stats: StatsResource
var health: HealthComponent
var movement: MovementComponent
var weapon: WeaponComponent

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

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20, Color.GREEN)
	draw_arc(Vector2.ZERO, 18, 0, TAU, 32, Color.DARK_GREEN, 2.0)

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

func apply_form(form_data: Dictionary) -> void:
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

	modulate = form_data.get("color", Color.GREEN)
	var size = form_data.get("size", 1.0)
	scale = Vector2.ONE * size

	queue_redraw()
