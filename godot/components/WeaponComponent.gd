extends Node
class_name WeaponComponent

@export var fire_cooldown: float = 0.8

var behaviors: Array[Resource] = []
var stats_ref: StatsResource = null
var _timers: Array[Timer] = []

func add_behavior(b: Resource) -> void:
	behaviors.append(b)
	var timer = Timer.new()
	var cd = fire_cooldown
	if "cooldown" in b and b.cooldown > 0:
		cd = b.cooldown
	timer.wait_time = cd
	timer.autostart = true
	var idx = behaviors.size() - 1
	timer.timeout.connect(func(): _on_fire(idx))
	add_child(timer)
	_timers.append(timer)

func clear_behaviors() -> void:
	for t in _timers:
		t.queue_free()
	_timers.clear()
	behaviors.clear()

func _on_fire(idx: int) -> void:
	if GameManager.game_over or idx >= behaviors.size():
		return
	var b = behaviors[idx]
	if not b or not b.has_method("fire"):
		return
	if b.fire(get_parent(), stats_ref, get_tree().current_scene):
		AudioManager.play_sfx("shoot", get_parent().global_position)
