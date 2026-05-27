extends Node
class_name WaveManager

const BossScript = preload("res://entities/enemies/Boss.gd")

const ERA_POOLS: Dictionary = {
	0: { # Cambrian
		"enemies": [
			{"name": "Trilobite", "speed": 40, "damage": 6, "hp": 15, "gp": 3, "color": Color(0.6, 0.3, 0.1), "size": 10},
			{"name": "Anomalocaris", "speed": 55, "damage": 8, "hp": 22, "gp": 4, "color": Color(0.8, 0.4, 0.2), "size": 14},
			{"name": "Jellyfish", "speed": 30, "damage": 4, "hp": 12, "gp": 2, "color": Color(0.2, 0.6, 0.8), "size": 11},
		],
		"boss": {"name": "Giant Anomalocaris", "speed": 35, "damage": 15, "hp": 150, "gp": 30, "color": Color(0.9, 0.3, 0.0), "size": 30},
	},
	1: { # Triassic
		"enemies": [
			{"name": "Placoderm", "speed": 35, "damage": 10, "hp": 35, "gp": 5, "color": Color(0.4, 0.4, 0.5), "size": 16},
			{"name": "Ammonite", "speed": 50, "damage": 12, "hp": 25, "gp": 5, "color": Color(0.9, 0.6, 0.2), "size": 13},
			{"name": "Temnospondyl", "speed": 45, "damage": 14, "hp": 40, "gp": 6, "color": Color(0.3, 0.6, 0.3), "size": 18},
		],
		"boss": {"name": "Dimetrodon", "speed": 40, "damage": 20, "hp": 300, "gp": 40, "color": Color(0.2, 0.7, 0.5), "size": 34},
	},
	2: { # Jurassic
		"enemies": [
			{"name": "Dilophosaurus", "speed": 70, "damage": 16, "hp": 40, "gp": 7, "color": Color(0.7, 0.5, 0.1), "size": 15},
			{"name": "Stegosaurus", "speed": 30, "damage": 18, "hp": 60, "gp": 8, "color": Color(0.5, 0.7, 0.2), "size": 20},
			{"name": "Pterosaur", "speed": 85, "damage": 12, "hp": 30, "gp": 6, "color": Color(0.4, 0.3, 0.7), "size": 12},
		],
		"boss": {"name": "Allosaurus", "speed": 45, "damage": 25, "hp": 500, "gp": 60, "color": Color(0.7, 0.2, 0.1), "size": 36},
	},
	3: { # Cretaceous
		"enemies": [
			{"name": "Velociraptor", "speed": 100, "damage": 20, "hp": 35, "gp": 8, "color": Color(0.6, 0.7, 0.1), "size": 12},
			{"name": "Triceratops", "speed": 35, "damage": 22, "hp": 80, "gp": 10, "color": Color(0.5, 0.4, 0.3), "size": 22},
			{"name": "Pachycephalosaurus", "speed": 60, "damage": 25, "hp": 50, "gp": 9, "color": Color(0.6, 0.3, 0.4), "size": 16},
		],
		"boss": {"name": "Tyrannosaurus Rex", "speed": 50, "damage": 35, "hp": 800, "gp": 80, "color": Color(0.9, 0.1, 0.0), "size": 40},
	},
	4: { # Post-Cretaceous
		"enemies": [
			{"name": "Mutant", "speed": 65, "damage": 25, "hp": 60, "gp": 10, "color": Color(0.2, 0.8, 0.3), "size": 16},
			{"name": "Crystal Entity", "speed": 50, "damage": 28, "hp": 70, "gp": 12, "color": Color(0.5, 0.2, 0.9), "size": 14},
			{"name": "Void Walker", "speed": 90, "damage": 20, "hp": 40, "gp": 11, "color": Color(0.1, 0.1, 0.2), "size": 11},
		],
		"boss": {"name": "Omega Mutant", "speed": 55, "damage": 40, "hp": 1200, "gp": 100, "color": Color(0.0, 0.9, 0.5), "size": 42},
	},
}

@export var spawn_interval: float = 1.5
@export var base_enemies: int = 5
@export var enemies_per_wave: int = 3

var _enemy_container: Node
var _spawn_timer: Timer
var _boss_spawned_this_wave: bool = false

func setup(container: Node) -> void:
	_enemy_container = container
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_spawn_enemy)
	add_child(_spawn_timer)
	fix_update_spawn_interval()
	EventBus.wave_changed.connect(_on_wave_changed)

func _exit_tree() -> void:
	if EventBus.wave_changed.is_connected(_on_wave_changed):
		EventBus.wave_changed.disconnect(_on_wave_changed)

func _spawn_enemy() -> void:
	if GameManager.game_over:
		return

	var max_enemies = base_enemies + GameManager.wave * enemies_per_wave
	if _enemy_container.get_child_count() >= max_enemies:
		return

	var wave = GameManager.wave
	var is_boss_wave = wave > 0 and wave % 5 == 0
	var pool = _get_current_pool()

	if is_boss_wave and not _boss_spawned_this_wave:
		_spawn_boss(pool)
		_boss_spawned_this_wave = true
		return

	_spawn_regular(pool)

func _spawn_regular(pool: Dictionary) -> void:
	var type_list = pool.get("enemies", [])
	if type_list.is_empty():
		return

	var type = type_list[randi() % type_list.size()]
	var viewport = get_viewport().get_visible_rect().size
	var enemy = PoolManager.get_enemy()
	enemy.setup(type)

	var side = randi() % 4
	match side:
		0: enemy.global_position = Vector2(randf_range(0, viewport.x), -40)
		1: enemy.global_position = Vector2(randf_range(0, viewport.x), viewport.y + 40)
		2: enemy.global_position = Vector2(-40, randf_range(0, viewport.y))
		3: enemy.global_position = Vector2(viewport.x + 40, randf_range(0, viewport.y))

	var factor = 1.0 + (GameManager.wave - 1) * 0.12
	enemy.hp = ceili(enemy.hp * factor)
	enemy.damage = ceili(enemy.damage * (1.0 + (GameManager.wave - 1) * 0.08))

	_enemy_container.add_child(enemy)
	GameManager.register_enemy()

func _spawn_boss(pool: Dictionary) -> void:
	var boss_data = pool.get("boss", ERA_POOLS[0]["boss"])
	var viewport = get_viewport().get_visible_rect().size
	var boss = BossScript.new()
	boss.setup(boss_data)

	var factor = 1.0 + (GameManager.wave - 1) * 0.08
	boss.hp = ceili(boss.hp * factor)
	boss._max_hp = boss.hp

	var side = randi() % 4
	match side:
		0: boss.global_position = Vector2(viewport.x / 2, -60)
		1: boss.global_position = Vector2(viewport.x / 2, viewport.y + 60)
		2: boss.global_position = Vector2(-60, viewport.y / 2)
		3: boss.global_position = Vector2(viewport.x + 60, viewport.y / 2)

	_enemy_container.add_child(boss)
	GameManager.register_enemy()
	_boss_label(boss_data.get("name", "Boss"))

func _boss_label(name: String) -> void:
	var vp = get_viewport().get_visible_rect().size
	var label = Label.new()
	label.text = "⚠ %s ⚠" % name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, vp.y * 0.20)
	label.size = Vector2(vp.x, 40)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
	label.modulate.a = 0.0
	get_tree().current_scene.add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _get_current_pool() -> Dictionary:
	var era = clampi(GameManager.era_index, 0, 4)
	return ERA_POOLS[era]

func fix_update_spawn_interval() -> void:
	if _spawn_timer:
		_spawn_timer.wait_time = maxf(spawn_interval - GameManager.wave * 0.02, 0.3)

func _on_wave_changed(_new_wave: int) -> void:
	_boss_spawned_this_wave = false
	fix_update_spawn_interval()
