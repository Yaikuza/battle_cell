extends Resource
class_name TailSweep

const SlashEffectScript = preload("res://behaviors/weapons/SlashEffect.gd")

func fire(user: Node2D, stats: StatsResource, spawn_parent: Node) -> bool:
	var damage = stats.get_stat("damage", 10.0)
	var range = stats.get_stat("range", 350.0) * 0.4

	var enemies = spawn_parent.get_tree().get_nodes_in_group("enemies")
	var hit_count := 0
	for e in enemies:
		var to_e = e.global_position - user.global_position
		if to_e.length() > range + 20:
			continue
		e.take_damage(ceili(damage))
		hit_count += 1

	var slash = SlashEffectScript.new()
	slash.global_position = user.global_position
	slash.dir = Vector2.RIGHT
	slash.arc_angle = deg_to_rad(360.0)
	slash.range = range
	slash.color = Color(0.2, 0.8, 0.3, 0.6)
	spawn_parent.add_child(slash)

	if hit_count > 0:
		AudioManager.play_sfx("swing", user.global_position)
	return true
