extends Resource
class_name SlashBehavior

const SlashEffectScript = preload("res://behaviors/weapons/SlashEffect.gd")
const BASE_ARC := deg_to_rad(90.0)
const COMBO_WINDOW := 0.5

var _combo_step: int = 0
var _last_fire_time: float = 0.0

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	var elapsed = now - _last_fire_time
	_last_fire_time = now

	if elapsed < COMBO_WINDOW:
		_combo_step = (_combo_step + 1) % 3
	else:
		_combo_step = 0

	var damage = stats.get_stat("damage", 10.0)
	var range = stats.get_stat("range", 400.0) * 0.35
	var arc_angle = BASE_ARC + _combo_step * deg_to_rad(30.0)
	var mult = 1.0 + _combo_step * 0.3

	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	var dir := Vector2.RIGHT
	if not enemies.is_empty():
		var nearest: Node2D = null
		var min_dist = range * 2
		for e in enemies:
			var d = user.global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
		if nearest:
			dir = (nearest.global_position - user.global_position).normalized()

	var hit_count := 0
	for e in enemies:
		var to_e = e.global_position - user.global_position
		if to_e.length() > range + 20:
			continue
		if abs(to_e.angle_to(dir)) > arc_angle * 0.5:
			continue
		e.take_damage(ceili(damage * mult))
		hit_count += 1

	AudioManager.play_sfx("swing", user.global_position)

	var slash = SlashEffectScript.new()
	slash.global_position = user.global_position
	slash.dir = dir
	slash.arc_angle = arc_angle
	slash.range = range
	slash.color = Color(1.0, 1.0 - _combo_step * 0.3, 0.2 + _combo_step * 0.3, 0.7)
	spawn_parent.add_child(slash)
	return true
