extends Node
class_name WaveManager

const BossScript = preload("res://entities/enemies/Boss.gd")
const MiniBossScript = preload("res://entities/enemies/MiniBoss.gd")
const DB_PATH := "res://data/game_database.tres"

const ANNOUNCEMENT_DURATION: float = 2.0
const INITIAL_ENEMIES: int = 3

@export var spawn_interval: float = 0.9
@export var base_enemies: int = 5
@export var enemies_per_wave: int = 4

var _db: GameDatabase
var _enemy_container: Node
var _spawn_timer: Timer
var _announcement_timer: Timer
var _boss_spawned_this_wave: bool = false
var _spawning_active: bool = false

func _init() -> void:
	_db = load(DB_PATH) as GameDatabase

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
	var mod10 = wave % 10
	var is_boss_wave = wave > 0 and (mod10 == 0 or mod10 == 3 or mod10 == 6)

	if is_boss_wave and not _boss_spawned_this_wave:
		_boss_spawned_this_wave = true
		GameManager.boss_wave_active = true
		if mod10 == 0:
			_spawn_boss()
		else:
			_spawn_mini_boss()
		return

	_spawn_regular()

func _get_era_enemy_ids() -> Array:
	var era = _db.get_era(EraManager.era_index)
	if not era:
		return ["trilo", "anomalo", "jelly"]
	return era.enemy_ids

func _get_era_boss_id() -> String:
	var era = _db.get_era(EraManager.era_index)
	if not era:
		return "boss_anomalo"
	return era.boss_id

func _enemy_data_to_dict(enemy_id: String) -> Dictionary:
	var ed = _db.get_enemy(enemy_id)
	if not ed:
		return _fallback_enemy_dict(enemy_id)
	return {
		"name": ed.display_name,
		"speed": ed.base_speed,
		"damage": ed.damage,
		"hp": ed.base_hp,
		"gp": ed.gp_value,
		"color": ed.color,
		"size": ed.size,
		"sprite": ed.sprite_id,
		"behavior": ed.behavior_id,
		"fire_interval": ed.fire_interval,
		"range": ed.preferred_range,
		"charge_mult": ed.charge_mult,
	}

func _fallback_enemy_dict(id: String) -> Dictionary:
	match id:
		"trilo": return {"name": "Trilobite", "speed": 40, "damage": 6, "hp": 15, "gp": 3, "color": Color(0.6, 0.3, 0.1), "size": 10, "sprite": "trilobite", "behavior": "chase"}
		"anomalo": return {"name": "Anomalocaris", "speed": 55, "damage": 8, "hp": 22, "gp": 4, "color": Color(0.8, 0.4, 0.2), "size": 14, "sprite": "anomalocaris", "behavior": "chase"}
		"jelly": return {"name": "Jellyfish", "speed": 30, "damage": 4, "hp": 12, "gp": 2, "color": Color(0.2, 0.6, 0.8), "size": 11, "sprite": "jellyfish", "behavior": "chase"}
	return {"name": "??", "speed": 60, "damage": 10, "hp": 20, "gp": 5, "color": Color.RED, "size": 14, "sprite": "enemy", "behavior": "chase"}

func _get_spawn_near_player() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return Vector2.ZERO
	var viewport = get_viewport().get_visible_rect().size
	var cam = player.get_node("PlayerCamera") as Camera2D
	var zoom = cam.zoom.x if cam else 1.0
	var half_w = viewport.x / zoom / 2.0
	var half_h = viewport.y / zoom / 2.0
	var margin = 40 + (randi() % 40)
	var side = randi() % 4
	match side:
		0: return player.global_position + Vector2(randf_range(-half_w, half_w), -half_h - margin)
		1: return player.global_position + Vector2(randf_range(-half_w, half_w), half_h + margin)
		2: return player.global_position + Vector2(-half_w - margin, randf_range(-half_h, half_h))
		3: return player.global_position + Vector2(half_w + margin, randf_range(-half_h, half_h))
	return player.global_position

func _spawn_regular() -> void:
	var ids = _get_era_enemy_ids()
	if ids.is_empty():
		return

	var enemy_id = ids[randi() % ids.size()]
	var type = _enemy_data_to_dict(enemy_id)
	var enemy = PoolManager.get_enemy()
	enemy.setup(type)

	enemy.global_position = _get_spawn_near_player()

	var factor = 1.0 + (GameManager.wave - 1) * 0.12
	enemy.hp = ceili(enemy.hp * factor)
	enemy.damage = ceili(enemy.damage * (1.0 + (GameManager.wave - 1) * 0.08))
	enemy.speed = ceili(enemy.speed * (1.0 + (GameManager.wave - 1) * 0.04))

	_enemy_container.add_child(enemy)
	GameManager.register_enemy()

func _spawn_boss() -> void:
	var boss_id = _get_era_boss_id()
	var config = _db.get_boss_config(boss_id) if _db else null
	var boss = BossScript.new()
	boss.setup(_boss_config_to_dict(config, boss_id, false))

	boss.global_position = _get_spawn_near_player()

	_enemy_container.add_child(boss)
	GameManager.register_enemy()

func _spawn_mini_boss() -> void:
	var boss_id = _get_era_mini_boss_id()
	var config = _db.get_boss_config(boss_id) if _db else null
	var boss = MiniBossScript.new()
	boss.setup(_boss_config_to_dict(config, boss_id, true))

	boss.global_position = _get_spawn_near_player()

	_enemy_container.add_child(boss)
	GameManager.register_enemy()
	_boss_label(config.display_name if config else "Mini Boss", true)

func _boss_config_to_dict(config, _id: String, is_mini: bool) -> Dictionary:
	var wave_factor = 1.0 + (GameManager.wave - 1) * 0.08
	if config:
		return {
			"name": config.display_name,
			"hp": ceili(config.base_hp * wave_factor * (0.5 if is_mini else 1.0)),
			"damage": ceili(config.base_damage * (0.6 if is_mini else 1.0)),
			"speed": config.base_speed,
			"size": config.size * (0.75 if is_mini else 1.0),
			"sprite": config.sprite_id,
			"color": config.color,
			"gp": config.gp_value * (0.5 if is_mini else 1.0),
			"skill_ids": config.skill_ids,
		}
	var fallback = _fallback_enemy_dict(_id)
	fallback["skill_ids"] = ["spread"] if is_mini else ["charge", "spread"]
	return fallback

func _get_era_mini_boss_id() -> String:
	var era = _db.get_era(EraManager.era_index)
	if not era or era.mini_boss_id.is_empty():
		return _get_era_boss_id()
	return era.mini_boss_id

func _boss_label(name: String, is_mini: bool = false) -> void:
	var vp = get_viewport().get_visible_rect().size
	var label = Label.new()
	label.text = "⚡ %s ⚡" % name if is_mini else "⚠ %s ⚠" % name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.position = Vector2(0, vp.y * 0.20)
	label.size = Vector2(vp.x, 40)
	label.add_theme_font_size_override("font_size", 28 if is_mini else 36)
	label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0) if is_mini else Color(1.0, 0.6, 0.0))
	label.modulate.a = 0.0
	get_tree().current_scene.add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func fix_update_spawn_interval() -> void:
	if _spawn_timer:
		_spawn_timer.wait_time = maxf(spawn_interval - GameManager.wave * 0.02, 0.3)

func _on_wave_changed(_new_wave: int) -> void:
	_boss_spawned_this_wave = false
	_spawning_active = false
	_spawn_timer.stop()
	fix_update_spawn_interval()
	EventBus.wave_announcement.emit(GameManager.wave, EraManager.get_era_name())
	_announcement_timer.start(ANNOUNCEMENT_DURATION)

func _on_announcement_done() -> void:
	_spawning_active = true
	var w = GameManager.wave
	var mod10 = w % 10
	var is_boss = w > 0 and (mod10 == 0 or mod10 == 3 or mod10 == 6)
	if is_boss:
		_spawn_enemy()
	elif w > 0 and mod10 == 9:
		for i in range(INITIAL_ENEMIES):
			_spawn_enemy()
		_spawn_timer.start()
		_spawn_timer.wait_time = maxf(spawn_interval - w * 0.02, 0.3) * 0.6
		var event_type = ExtinctionManager.EventType.GREAT_DYING
		if w >= 19:
			event_type = ExtinctionManager.EventType.ASTEROID
		EventBus.extinction_started.emit(event_type)
		GameManager.extinction_active = true
	else:
		for i in range(INITIAL_ENEMIES):
			_spawn_enemy()
		_spawn_timer.start()
