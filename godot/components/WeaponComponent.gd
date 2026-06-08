extends Node
class_name WeaponComponent

@export var fire_cooldown: float = 0.8

var behaviors: Array[Resource] = []
var behavior_ids: Array[String] = []
var stats_ref: StatsResource = null
var _timers: Array[Timer] = []
var _timer_base_cooldowns: Array[float] = []
var _generation: int = 0

func _log(msg: String) -> void:
	var f = FileAccess.open("user://weapon_dbg.txt", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)
	else:
		f = FileAccess.open("user://weapon_dbg.txt", FileAccess.WRITE)
		if f:
			f.store_line(msg)

func add_behavior(b: Resource, behavior_id: String = "") -> void:
	behaviors.append(b)
	behavior_ids.append(behavior_id)
	var timer = Timer.new()
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	var cd = fire_cooldown
	if "cooldown" in b and b.cooldown > 0:
		cd = b.cooldown
	timer.wait_time = cd
	timer.autostart = true
	var sname = ""
	var scr = b.get_script()
	if scr:
		sname = scr.get_global_name()
	print("  [WeaponComponent] add_behavior idx=", behaviors.size()-1, " class=", sname, " cd=", cd)
	_log("ADD_BEHAVIOR idx=" + str(behaviors.size()-1) + " class=" + sname + " cd=" + str(cd) + " fire_cooldown=" + str(fire_cooldown) + " gen=" + str(_generation))
	var idx = behaviors.size() - 1
	var gen = _generation
	timer.timeout.connect(func():
		if _generation != gen:
			_log("STALE_TIMER idx=" + str(idx) + " gen=" + str(gen) + " cur_gen=" + str(_generation))
			return
		_on_fire(idx)
	)
	add_child(timer)
	_timers.append(timer)
	_timer_base_cooldowns.append(cd)

func clear_behaviors() -> void:
	_generation += 1
	for t in _timers:
		t.stop()
		t.queue_free()
	_timers.clear()
	_timer_base_cooldowns.clear()
	behaviors.clear()
	behavior_ids.clear()

var _fire_count: int = 0

func _on_fire(idx: int) -> void:
	if GameManager.game_over or idx >= behaviors.size():
		print("  [WeaponComponent] FIRE BLOCKED idx=", idx, " game_over=", GameManager.game_over, " size=", behaviors.size())
		return
	var b = behaviors[idx]
	if not b or not b.has_method("fire"):
		print("  [WeaponComponent] FIRE NO_METHOD idx=", idx, " b=", b)
		return
	if b.fire(get_parent(), stats_ref, get_tree().current_scene):
		AudioManager.play_sfx("shoot", get_parent().global_position)
		_fire_count += 1
		var bid = behavior_ids[idx] if idx < behavior_ids.size() else ""
		_try_double_attack(b, idx, bid)
		var sname = ""
		var scr = b.get_script()
		if scr:
			sname = scr.get_global_name()
		if _fire_count <= 5 or _fire_count % 10 == 0:
			var t = _timers[idx] if idx < _timers.size() else null
			print("  [WeaponComponent] FIRE idx=", idx, " class=", sname, " cd=", fire_cooldown, " count=", _fire_count)
			_log("FIRE idx=" + str(idx) + " class=" + sname + " wait_time=" + str(t.wait_time if t else -1) + " cd=" + str(fire_cooldown) + " count=" + str(_fire_count))
	else:
		var sname = ""
		var scr = b.get_script()
		if scr: sname = scr.get_global_name()
		print("  [WeaponComponent] FIRE FAILED idx=", idx, " class=", sname)

func _try_double_attack(b, idx: int, behavior_id: String = "") -> void:
	var player = get_parent() as Player
	if not player or not player._part_effects:
		return
	var chance = player._part_effects.get_double_attack_chance(behavior_id)
	if chance <= 0.0:
		return
	if randf() >= chance:
		return
	if b.fire(get_parent(), stats_ref, get_tree().current_scene):
		AudioManager.play_sfx("shoot", get_parent().global_position)
		_fire_count += 1
