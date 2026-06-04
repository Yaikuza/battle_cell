extends Node
class_name WaveManager

const BossScript = preload("res://entities/enemies/Boss.gd")
const ANNOUNCEMENT_DURATION: float = 2.0
const INITIAL_ENEMIES: int = 3

@export var spawn_interval: float = 0.9
@export var base_enemies: int = 5
@export var enemies_per_wave: int = 4

var _enemy_container: Node
var _spawn_timer: Timer
var _announcement_timer: Timer
var _boss_spawned_this_wave: bool = false
var _spawning_active: bool = false
var _era_cache: Dictionary = {}

func restore_from_save() -> void:
	_boss_spawned_this_wave = false
	_spawning_active = true
	fix_update_spawn_interval()
	_spawn_timer.start()

func setup(container: Node) -> void:
	_enemy_container = container

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.autostart = false
	_spawn_timer.timeout.connect(_spawn_enemy)
	add_child(_spawn_timer)

	_announcement_timer = Timer.new()
	_announcement_timer.one_shot = true
	_announcement_timer.timeout.connect(_on_announcement_done)
	add_child(_announcement_timer)

	fix_update_spawn_interval()
	EventBus.wave_changed.connect(_on_wave_changed)

func _exit_tree() -> void:
	if EventBus.wave_changed.is_connected(_on_wave_changed):
		EventBus.wave_changed.disconnect(_on_wave_changed)

func _spawn_enemy() -> void:
	if GameManager.game_over or not _spawning_active:
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
	enemy.speed = ceili(enemy.speed * (1.0 + (GameManager.wave - 1) * 0.04))

	_enemy_container.add_child(enemy)
	GameManager.register_enemy()

func _spawn_boss(pool: Dictionary) -> void:
	var boss_data = pool.get("boss", {})
	if boss_data.is_empty():
		boss_data = _build_boss_dict({})
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
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
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
	var cache_key = "era_%d" % era
	if _era_cache.has(cache_key):
		return _era_cache[cache_key]

	var db = load("res://data/game_database.tres")
	var era_data = db.get_era(era)
	var pool = {"enemies": [], "boss": {}}

	for eid in era_data.enemy_ids:
		var ed = db.get_enemy(eid)
		if ed:
			pool.enemies.append(_build_enemy_dict(ed))

	var boss_data = db.get_enemy(era_data.boss_id)
	if boss_data:
		pool.boss = _build_boss_dict(boss_data)

	_era_cache[cache_key] = pool
	return pool

func _build_enemy_dict(ed) -> Dictionary:
	return {
		"name": ed.display_name, "speed": ed.base_speed,
		"damage": ed.damage, "hp": ed.base_hp, "gp": ed.gp_value,
		"color": ed.color, "size": ed.size, "sprite": ed.sprite_id,
		"behavior": ed.behavior_id,
		"fire_interval": ed.fire_interval, "range": ed.preferred_range,
		"charge_mult": ed.charge_mult,
	}

func _build_boss_dict(ed) -> Dictionary:
	return {
		"name": ed.display_name, "speed": ed.base_speed,
		"damage": ed.damage, "hp": ed.base_hp, "gp": ed.gp_value,
		"color": ed.color, "size": ed.size, "sprite": ed.sprite_id,
	}

func fix_update_spawn_interval() -> void:
	if _spawn_timer:
		_spawn_timer.wait_time = maxf(spawn_interval - GameManager.wave * 0.02, 0.3)

func _on_wave_changed(_new_wave: int) -> void:
	_boss_spawned_this_wave = false
	_spawning_active = false
	_spawn_timer.stop()
	fix_update_spawn_interval()
	EventBus.wave_announcement.emit(GameManager.wave, GameManager.get_era_name())
	_announcement_timer.start(ANNOUNCEMENT_DURATION)

func _on_announcement_done() -> void:
	_spawning_active = true
	var w = GameManager.wave
	var is_boss = w > 0 and w % 5 == 0
	if is_boss:
		_spawn_enemy()
	else:
		for i in range(INITIAL_ENEMIES):
			_spawn_enemy()
	_spawn_timer.start()
