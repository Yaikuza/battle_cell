extends Node
class_name BossSkillController

const SkillTelegraphScript = preload("res://ui/SkillTelegraph.gd")

var _boss: Node2D
var _skills: Array = []
var _max_concurrent: int = 1
var _cooldowns: Dictionary = {}
var _active_skills: int = 0
var _telegraph_color: Color = Color(1.0, 0.2, 0.0)

const DB_PATH := "res://data/game_database.tres"

enum {
	CHARGE, SPREAD, SUMMON, AOE, BUFF, DASH,
	CLAW_SNAP, EYE_BEAM, TAIL_FLAIL, ROLL_UP, SPINE_SHOT,
	GROUND_POUND, SLAM_WAVE, JELLY_SPAWN,
	VENOM_SPIT, POUNCE_MARK, PACK_CALL,
	TAIL_SWEEP, BONE_RAIN, FURY_ROAR,
}

func setup(boss: Node2D, skill_ids: Array, concurrent: int = 1, tcolor: Color = Color(1.0, 0.2, 0.0)) -> void:
	_boss = boss
	_max_concurrent = concurrent
	_telegraph_color = tcolor
	var db = load(DB_PATH) as GameDatabase
	if not db:
		return
	for sid in skill_ids:
		var skill = db.get_boss_skill(sid)
		if skill:
			_skills.append(skill)
			_cooldowns[skill.skill_id] = 0.0

func _process(delta: float) -> void:
	if not _boss or _boss.is_queued_for_deletion():
		return
	for sid in _cooldowns.keys():
		if _cooldowns[sid] > 0:
			_cooldowns[sid] -= delta

func can_use_skill() -> bool:
	return _active_skills < _max_concurrent and not _skills.is_empty()

func try_execute_skill() -> bool:
	if not can_use_skill():
		return false
	var player: Node2D = _boss.get_tree().get_first_node_in_group("player")
	if not player:
		return false

	var available: Array = []
	for skill in _skills:
		if _cooldowns[skill.skill_id] <= 0:
			available.append(skill)

	if available.is_empty():
		return false

	var skill = available[randi() % available.size()]
	_cooldowns[skill.skill_id] = skill.cooldown
	_active_skills += 1

	var color = skill.telegraph_color if skill.telegraph_color != Color(1.0, 0.2, 0.0) else _telegraph_color
	_telegraph(skill, player, color)
	return true

func _telegraph(skill, player: Node2D, color: Color) -> void:
	var boss_pos = _boss.global_position
	var player_pos = player.global_position
	var dir_to_player = (player_pos - boss_pos).normalized()

	match skill.type:
		CHARGE:
			var dir = dir_to_player
			var dist = boss_pos.distance_to(player_pos)
			SkillTelegraphScript.warn_line(boss_pos, boss_pos + dir * dist, 12, color, skill.telegraph_time)

		SPREAD:
			SkillTelegraphScript.warn_position(boss_pos, 80, color, skill.telegraph_time)

		AOE:
			SkillTelegraphScript.warn_position(player_pos, 64, color, skill.telegraph_time)

		SUMMON:
			SkillTelegraphScript.warn_position(boss_pos, 40, Color(0.5, 0.0, 1.0), skill.telegraph_time)

		CLAW_SNAP:
			var perp = Vector2(-dir_to_player.y, dir_to_player.x)
			var gap = skill.params.get("gap", 80.0)
			var len = skill.params.get("length", 120.0)
			SkillTelegraphScript.warn_line_pair(boss_pos + dir_to_player * 60, perp, gap * 0.5, len, color, skill.telegraph_time)

		EYE_BEAM:
			var beam_len = skill.params.get("range", 400.0)
			SkillTelegraphScript.warn_line(boss_pos, boss_pos + dir_to_player * beam_len, 8, color, skill.telegraph_time)

		TAIL_FLAIL:
			SkillTelegraphScript.warn_position(boss_pos, 100, color, skill.telegraph_time * 0.5)

		ROLL_UP:
			var dist = boss_pos.distance_to(player_pos)
			SkillTelegraphScript.warn_line(boss_pos, boss_pos + dir_to_player * minf(dist, 300.0), 20, color, skill.telegraph_time)

		SPINE_SHOT:
			SkillTelegraphScript.warn_position(boss_pos, 50, color, skill.telegraph_time)

		GROUND_POUND:
			SkillTelegraphScript.warn_position(boss_pos, 40, color, skill.telegraph_time)

		SLAM_WAVE:
			var dist = boss_pos.distance_to(player_pos)
			var gap = skill.params.get("gap", 60.0)
			var perp = Vector2(-dir_to_player.y, dir_to_player.x)
			var mid = boss_pos + dir_to_player * dist * 0.5
			SkillTelegraphScript.warn_line_pair(mid, perp, gap * 0.5, 100, color, skill.telegraph_time)

		JELLY_SPAWN:
			var count = skill.params.get("count", 3)
			var spread = skill.params.get("spread", 80.0)
			for i in range(count):
				var offset = Vector2(cos(i * 2.094), sin(i * 2.094)) * spread
				SkillTelegraphScript.warn_position(boss_pos + offset, 16, color, skill.telegraph_time)

		VENOM_SPIT:
			var count = skill.params.get("count", 3)
			var spread = skill.params.get("spread", 100.0)
			for i in range(count):
				var angle = atan2(dir_to_player.y, dir_to_player.x) + deg_to_rad((i - 1) * 30.0)
				var offset = Vector2(cos(angle), sin(angle)) * spread
				SkillTelegraphScript.warn_position(boss_pos + offset, 32, color, skill.telegraph_time)

		POUNCE_MARK:
			var radius = skill.params.get("radius", 64.0)
			SkillTelegraphScript.warn_marker(player_pos, radius * 0.5, color, skill.telegraph_time)

		PACK_CALL:
			SkillTelegraphScript.warn_position(boss_pos, 64, Color(0.8, 0.4, 0.0), skill.telegraph_time)

		TAIL_SWEEP:
			var radius = skill.params.get("radius", 150.0)
			var opposite_dir = -dir_to_player
			SkillTelegraphScript.warn_arc(boss_pos, opposite_dir, 180.0, radius, 30.0, color, skill.telegraph_time)

		BONE_RAIN:
			var radius = skill.params.get("radius", 32.0)
			var player_pos_teleg = player_pos
			for w in range(3):
				for i in range(3):
					var offset = Vector2(randf_range(-60, 60), -100 - w * 80 - i * 30)
					SkillTelegraphScript.warn_position(player_pos_teleg + Vector2(offset.x, 0), radius, color, skill.telegraph_time * 0.3)

		BUFF:
			SkillTelegraphScript.warn_position(boss_pos, 90, Color(1.0, 0.8, 0.0), skill.telegraph_time)

		DASH:
			var dash_dir = (boss_pos - player_pos).normalized()
			var dash_dist = skill.params.get("distance", 150.0)
			SkillTelegraphScript.warn_line(boss_pos, boss_pos + dash_dir * dash_dist, 10, color, skill.telegraph_time)

		FURY_ROAR:
			SkillTelegraphScript.warn_position(boss_pos, 120, color, skill.telegraph_time)

	var timer = _boss.get_tree().create_timer(skill.telegraph_time)
	timer.timeout.connect(_execute_skill.bind(skill, player))

func _execute_skill(skill, player: Node2D) -> void:
	if not _boss or _boss.is_queued_for_deletion():
		_active_skills -= 1
		return

	match skill.type:
		CHARGE:
			_do_charge(skill, player)

		SPREAD:
			_do_spread(skill, player)

		AOE:
			_do_aoe(skill, player)

		SUMMON:
			_do_summon(skill)

		BUFF:
			_do_buff(skill)

		DASH:
			_do_dash(skill, player)

		CLAW_SNAP:
			_do_claw_snap(skill, player)

		EYE_BEAM:
			_do_eye_beam(skill, player)

		TAIL_FLAIL:
			_do_tail_flail(skill, player)

		ROLL_UP:
			_do_roll_up(skill, player)

		SPINE_SHOT:
			_do_spine_shot(skill, player)

		GROUND_POUND:
			_do_ground_pound(skill, player)

		SLAM_WAVE:
			_do_slam_wave(skill, player)

		JELLY_SPAWN:
			_do_jelly_spawn(skill, player)

		VENOM_SPIT:
			_do_venom_spit(skill, player)

		POUNCE_MARK:
			_do_pounce_mark(skill, player)

		PACK_CALL:
			_do_pack_call(skill, player)

		TAIL_SWEEP:
			_do_tail_sweep(skill, player)

		BONE_RAIN:
			_do_bone_rain(skill, player)

		FURY_ROAR:
			_do_fury_roar(skill, player)

	_active_skills -= 1

func _fire_projectile(origin: Vector2, dir: Vector2, speed: float, damage: int, max_dist: float = 400.0) -> void:
	var proj = PoolManager.get_bullet()
	if not proj:
		return
	proj.global_position = origin + dir * 20
	proj.direction = dir
	proj.speed = speed
	proj.damage = damage
	proj.max_distance = max_dist
	proj.exclude_group = "enemy"
	_boss.get_tree().current_scene.add_child(proj)

func _do_charge(skill, player: Node2D) -> void:
	var dir = (player.global_position - _boss.global_position).normalized()
	var charge_speed = skill.params.get("speed", 300.0)
	var duration = skill.params.get("duration", 0.3)
	var tween = _boss.create_tween()
	tween.tween_property(_boss, "global_position", _boss.global_position + dir * charge_speed * duration, duration)

func _do_spread(skill, player: Node2D) -> void:
	var count = skill.params.get("count", 5)
	var angle = skill.params.get("angle", 90.0)
	var proj_speed = skill.params.get("projectile_speed", 200.0)
	var dmg = ceili(skill.damage_mult * 10)
	var start_angle = -angle * 0.5
	var step = angle / (count - 1) if count > 1 else 0
	var dir_to_player = (player.global_position - _boss.global_position).normalized()
	var base_angle = atan2(dir_to_player.y, dir_to_player.x)
	for i in range(count):
		var a = base_angle + deg_to_rad(start_angle + step * i)
		var dir = Vector2(cos(a), sin(a))
		_fire_projectile(_boss.global_position, dir, proj_speed, dmg)

func _do_aoe(skill, player: Node2D) -> void:
	var radius = skill.params.get("radius", 64.0)
	var targets = _boss.get_tree().get_nodes_in_group("player")
	for t in targets:
		if t is Node2D and t.global_position.distance_to(player.global_position) <= radius:
			var hb = t.get_node_or_null("HurtboxComponent")
			if hb:
				hb.take_direct_hit(ceili(skill.damage_mult * _boss.damage), 0)

func _do_summon(skill) -> void:
	var count = skill.params.get("count", 2)
	for i in range(count):
		var enemy = PoolManager.get_enemy()
		if not enemy:
			continue
		var ids = _get_era_enemy_ids()
		if ids.is_empty():
			continue
		var type = _enemy_data_to_dict(ids[randi() % ids.size()])
		enemy.setup(type)
		enemy.global_position = _boss.global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		_boss.get_tree().current_scene.add_child(enemy)
		GameManager.register_enemy()

func _do_buff(skill) -> void:
	var duration = skill.params.get("duration", 4.0)
	var speed_mult = skill.params.get("speed_mult", 1.5)
	var dmg_mult = skill.params.get("damage_mult", 1.5)
	_boss.set_meta("_buff_active", true)
	_boss.set_meta("_buff_speed", speed_mult)
	_boss.set_meta("_buff_base_damage", _boss.damage)
	_boss.speed *= speed_mult
	_boss.damage = ceili(_boss.damage * dmg_mult)
	_boss.modulate = Color(1.5, 1.5, 0.5)
	var timer = _boss.get_tree().create_timer(duration)
	timer.timeout.connect(_end_buff)

func _do_dash(skill, player: Node2D) -> void:
	var dash_dir = (_boss.global_position - player.global_position).normalized()
	var dash_dist = skill.params.get("distance", 150.0)
	var dash_speed = skill.params.get("speed", 400.0)
	var target = _boss.global_position + dash_dir * dash_dist
	var tween = _boss.create_tween()
	tween.tween_property(_boss, "global_position", target, dash_dist / dash_speed)

func _do_claw_snap(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var dir_to_player = (player.global_position - boss_pos).normalized()
	var perp = Vector2(-dir_to_player.y, dir_to_player.x)
	var gap = skill.params.get("gap", 80.0)
	var length = skill.params.get("length", 120.0)
	var speed = skill.params.get("speed", 300.0)
	var dmg = ceili(skill.damage_mult * _boss.damage)

	var p1_start = boss_pos + dir_to_player * 60 + perp * gap
	var p2_start = boss_pos + dir_to_player * 60 - perp * gap
	var p1_target = boss_pos + dir_to_player * 60 + perp * 5
	var p2_target = boss_pos + dir_to_player * 60 - perp * 5

	for pair in [[p1_start, p1_target, 1], [p2_start, p2_target, -1]]:
		var claw = ColorRect.new()
		claw.color = Color(1.0, 0.2, 0.1)
		claw.size = Vector2(length, 14)
		claw.position = pair[0] - Vector2(length * 0.5, 7)
		claw.rotation = atan2(perp.y, perp.x) * pair[2]
		claw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var scene = _boss.get_tree().current_scene
		scene.add_child(claw)

		var tween = scene.create_tween()
		tween.tween_method(_claw_snap_move.bind(claw, pair[0], pair[1], length), 0.0, 1.0, 0.3)
		tween.tween_callback(claw.queue_free)

	var hit_timer = _boss.get_tree().create_timer(0.15)
	hit_timer.timeout.connect(func():
		var mid = boss_pos + dir_to_player * 60
		var player_dist = player.global_position.distance_to(mid)
		var dot = (player.global_position - mid).normalized().dot(perp)
		if player_dist < gap * 0.5 and abs(dot) < 0.7:
			var hb = player.get_node_or_null("HurtboxComponent")
			if hb:
				hb.take_direct_hit(dmg, 0)
	)

func _claw_snap_move(progress: float, claw: ColorRect, start: Vector2, target: Vector2, length: float) -> void:
	var pos = start.lerp(target, progress)
	claw.position = pos - Vector2(length * 0.5, 7)

func _do_eye_beam(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var beam_count = skill.params.get("beam_count", 8)
	var range_val = skill.params.get("range", 400.0)
	var speed = skill.params.get("speed", 300.0)
	var dmg = ceili(skill.damage_mult * _boss.damage)
	var dir_to_player = (player.global_position - boss_pos).normalized()
	var base_angle = atan2(dir_to_player.y, dir_to_player.x)
	var step_angle = 360.0 / beam_count

	for i in range(beam_count):
		var angle = base_angle + deg_to_rad(step_angle * i)
		var dir = Vector2(cos(angle), sin(angle))
		var origin = boss_pos + dir * 30
		var beam_timer = _boss.get_tree().create_timer(i * 0.08)
		beam_timer.timeout.connect(_fire_projectile.bind(origin, dir, speed, dmg, range_val))

func _do_tail_flail(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var dir_to_player = (player.global_position - boss_pos).normalized()
	var base_angle = atan2(dir_to_player.y, dir_to_player.x)
	var dmg = ceili(skill.damage_mult * _boss.damage)
	var proj_speed = skill.params.get("speed", 180.0)
	var speed_increment = skill.params.get("speed_increment", 60.0)

	for wave in range(3):
		var wave_timer = _boss.get_tree().create_timer(wave * 0.5)
		wave_timer.timeout.connect(func():
			var current_speed = proj_speed + speed_increment * wave
			for i in range(3):
				var a = base_angle + deg_to_rad(-60.0 + 60.0 * i)
				var dir = Vector2(cos(a), sin(a))
				_fire_projectile(boss_pos, dir, current_speed, dmg, 350.0)
		)

func _do_roll_up(skill, player: Node2D) -> void:
	var dir = (player.global_position - _boss.global_position).normalized()
	var roll_speed = skill.params.get("speed", 350.0)
	var dmg = ceili(skill.damage_mult * _boss.damage)
	var duration = skill.params.get("duration", 0.8)
	var bounce_count = skill.params.get("bounces", 2)

	_boss.modulate = Color(0.8, 0.8, 0.8)
	var roll_dir = dir
	var remaining = duration
	for bounce in range(bounce_count + 1):
		var seg_duration = remaining / (bounce_count + 1 - bounce)
		var target = _boss.global_position + roll_dir * roll_speed * seg_duration
		var viewport = _boss.get_viewport().get_visible_rect()
		if target.x < 0 or target.x > viewport.size.x or target.y < 0 or target.y > viewport.size.y:
			if target.x < 0 or target.x > viewport.size.x:
				roll_dir.x *= -1
			if target.y < 0 or target.y > viewport.size.y:
				roll_dir.y *= -1
			target = _boss.global_position + roll_dir * roll_speed * seg_duration
		var tween = _boss.create_tween()
		tween.tween_property(_boss, "global_position", target, seg_duration)
		if bounce >= bounce_count:
			break
		tween.tween_callback(func():
			var overlap = _boss.get_overlapping_areas()
			for area in overlap:
				if area is HurtboxComponent and area.owner_group == "player":
					area.take_direct_hit(dmg, 0)
		)
		remaining -= seg_duration
		await tween.finished

	_boss.modulate = _telegraph_color

func _do_spine_shot(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var count = skill.params.get("count", 8)
	var dmg = ceili(skill.damage_mult * _boss.damage)
	var speed = skill.params.get("speed", 200.0)

	for burst in range(2):
		var timer = _boss.get_tree().create_timer(burst * 0.4)
		timer.timeout.connect(func():
			var offset_angle = burst * 22.5
			for i in range(count):
				var a = deg_to_rad(360.0 * i / count + offset_angle)
				var dir = Vector2(cos(a), sin(a))
				_fire_projectile(boss_pos, dir, speed, dmg, 300.0)
		)

func _do_ground_pound(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var ring_count = skill.params.get("ring_count", 3)
	var max_radius = skill.params.get("max_radius", 200.0)
	var dmg = ceili(skill.damage_mult * _boss.damage)
	var _speed = skill.params.get("ring_speed", 0.15)

	var ring = ColorRect.new()
	ring.color = Color(1.0, 0.6, 0.0, 0.3)
	ring.size = Vector2(10, 10)
	ring.position = boss_pos - Vector2(5, 5)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scene = _boss.get_tree().current_scene
	scene.add_child(ring)

	var tween = scene.create_tween()
	tween.tween_method(func(s: float):
		var r = max_radius * s
		ring.size = Vector2(r * 2, r * 2)
		ring.position = boss_pos - Vector2(r, r)
		ring.modulate.a = 0.4 * (1.0 - s)
		if s > 0.1 and s < 1.0:
			var dist = player.global_position.distance_to(boss_pos)
			if abs(dist - r) < 15:
				var hb = player.get_node_or_null("HurtboxComponent")
				if hb:
					hb.take_direct_hit(dmg, 0)
	, 0.0, 1.0, 1.0)
	tween.tween_callback(ring.queue_free)

func _do_slam_wave(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var dir_to_player = (player.global_position - boss_pos).normalized()
	var perp = Vector2(-dir_to_player.y, dir_to_player.x)
	var gap = skill.params.get("gap", 60.0)
	var speed = skill.params.get("speed", 250.0)
	var range_val = skill.params.get("range", 400.0)
	var dmg = ceili(skill.damage_mult * _boss.damage)

	for side in [-1, 1]:
		var offset = perp * (gap * 0.5 + 15) * side
		var origin = boss_pos + dir_to_player * 30 + offset
		_fire_projectile(origin, dir_to_player, speed, dmg, range_val)

func _do_jelly_spawn(skill, player: Node2D) -> void:
	var count = skill.params.get("count", 3)
	var spread = skill.params.get("spread", 80.0)
	var hatch_time = skill.params.get("hatch_time", 5.0)
	var boss_pos = _boss.global_position
	var scene = _boss.get_tree().current_scene

	for i in range(count):
		var angle = i * 2.094
		var offset = Vector2(cos(angle), sin(angle)) * spread
		var egg_pos = boss_pos + offset

		var egg = ColorRect.new()
		egg.color = Color(0.4, 0.7, 0.9, 0.8)
		egg.size = Vector2(18, 18)
		egg.position = egg_pos - Vector2(9, 9)
		egg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scene.add_child(egg)

		var hatch_timer = _boss.get_tree().create_timer(hatch_time)
		hatch_timer.timeout.connect(func():
			if egg and is_instance_valid(egg):
				egg.queue_free()
			var enemy = PoolManager.get_enemy()
			if enemy:
				var ids = _get_era_enemy_ids()
				if not ids.is_empty():
					var type = _enemy_data_to_dict(ids[randi() % ids.size()])
					enemy.setup(type)
					enemy.global_position = egg_pos
					scene.add_child(enemy)
					GameManager.register_enemy()
		)

func _do_venom_spit(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var dir_to_player = (player.global_position - boss_pos).normalized()
	var count = skill.params.get("count", 3)
	var spread = skill.params.get("spread", 100.0)
	var zone_radius = skill.params.get("zone_radius", 32.0)
	var duration = skill.params.get("duration", 4.0)
	var dps = skill.params.get("dps", 3)
	var scene = _boss.get_tree().current_scene

	for i in range(count):
		var angle = atan2(dir_to_player.y, dir_to_player.x) + deg_to_rad((i - 1) * 30.0)
		var offset = Vector2(cos(angle), sin(angle)) * spread
		var zone_pos = boss_pos + offset

		var zone = ColorRect.new()
		zone.color = Color(0.2, 0.8, 0.1, 0.3)
		zone.size = Vector2(zone_radius * 2, zone_radius * 2)
		zone.position = zone_pos - Vector2(zone_radius, zone_radius)
		zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scene.add_child(zone)

		var tick = 0.0
		var tick_timer = scene.create_tween().set_loops()
		tick_timer.tween_interval(1.0)
		tick_timer.tween_callback(func():
			tick += 1
			if tick > duration or not is_instance_valid(zone):
				if tick_timer and is_instance_valid(tick_timer):
					tick_timer.kill()
				return
			var dist = player.global_position.distance_to(zone_pos)
			if dist < zone_radius:
				var hb = player.get_node_or_null("HurtboxComponent")
				if hb:
					hb.take_direct_hit(dps, 1)
		)
		var cleanup = scene.create_timer(duration)
		cleanup.timeout.connect(func():
			if zone and is_instance_valid(zone):
				zone.queue_free()
		)

func _do_pounce_mark(skill, player: Node2D) -> void:
	var mark_pos = player.global_position
	var radius = skill.params.get("radius", 64.0)
	var dmg = ceili(skill.damage_mult * _boss.damage)

	var leap_tween = _boss.create_tween()
	leap_tween.tween_property(_boss, "global_position", mark_pos, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	leap_tween.tween_callback(func():
		EffectManager.explosion(mark_pos, radius)
		var dist = player.global_position.distance_to(mark_pos)
		if dist < radius:
			var hb = player.get_node_or_null("HurtboxComponent")
			if hb:
				hb.take_direct_hit(dmg, 0)
	)

func _do_pack_call(skill, player: Node2D) -> void:
	var count = skill.params.get("count", 2)
	var ids = _get_era_enemy_ids()
	if ids.is_empty():
		return
	var scene = _boss.get_tree().current_scene
	for i in range(count):
		var enemy = PoolManager.get_enemy()
		if not enemy:
			continue
		var type = _enemy_data_to_dict(ids[randi() % ids.size()])
		enemy.setup(type)
		var side = Vector2(cos(i * 3.1416), sin(i * 3.1416))
		enemy.global_position = _boss.global_position + side * 50
		scene.add_child(enemy)
		GameManager.register_enemy()
		var dash_dir = (player.global_position - enemy.global_position).normalized()
		var dash_tween = enemy.create_tween()
		dash_tween.tween_property(enemy, "global_position", enemy.global_position + dash_dir * 200, 0.3)

func _do_tail_sweep(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var dir_to_player = (player.global_position - boss_pos).normalized()
	var opposite_dir = -dir_to_player
	var base_angle = atan2(opposite_dir.y, opposite_dir.x)
	var arc = 180.0
	var count = skill.params.get("count", 9)
	var speed = skill.params.get("speed", 220.0)
	var dmg = ceili(skill.damage_mult * _boss.damage)

	var step = arc / (count - 1) if count > 1 else 0
	for i in range(count):
		var a = base_angle + deg_to_rad(-arc * 0.5 + step * i)
		var dir = Vector2(cos(a), sin(a))
		_fire_projectile(boss_pos, dir, speed, dmg, 350.0)

func _do_bone_rain(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var waves = skill.params.get("waves", 3)
	var count = skill.params.get("count", 4)
	var dmg = ceili(skill.damage_mult * _boss.damage)
	var fall_speed = skill.params.get("speed", 280.0)
	var range_val = skill.params.get("range", 500.0)

	for w in range(waves):
		var wave_timer = _boss.get_tree().create_timer(w * 0.35)
		wave_timer.timeout.connect(func():
			var player_pos = player.global_position
			for i in range(count):
				var x_offset = randf_range(-100, 100)
				var y_offset = -50 - randf_range(0, 50)
				var spawn_pos = Vector2(player_pos.x + x_offset, boss_pos.y + y_offset)
				var fall_dir = Vector2(0, 1)
				var bullet_timer = _boss.get_tree().create_timer(i * 0.06)
				bullet_timer.timeout.connect(_fire_projectile.bind(spawn_pos, fall_dir, fall_speed, dmg, range_val))
		)

func _do_fury_roar(skill, player: Node2D) -> void:
	var boss_pos = _boss.global_position
	var radius = skill.params.get("radius", 120.0)
	var push_force = skill.params.get("force", 300.0)
	var stun_duration = skill.params.get("stun_duration", 0.5)

	var dist = player.global_position.distance_to(boss_pos)
	if dist < radius:
		var dir = (player.global_position - boss_pos).normalized()
		var push_target = player.global_position + dir * push_force
		var tween = player.create_tween()
		tween.tween_property(player, "global_position", push_target, 0.15)

func _end_buff() -> void:
	if not _boss or _boss.is_queued_for_deletion():
		return
	_boss.set_meta("_buff_active", false)
	if _boss.has_meta("_buff_speed"):
		_boss.speed /= _boss.get_meta("_buff_speed")
	_boss.set_meta("_buff_speed", null)
	if _boss.has_meta("_buff_base_damage"):
		_boss.damage = _boss.get_meta("_buff_base_damage")
	_boss.set_meta("_buff_base_damage", null)
	_boss.modulate = Color.WHITE

func _get_era_enemy_ids() -> Array:
	var db = load(DB_PATH) as GameDatabase
	if not db:
		return ["trilo"]
	var era = db.get_era(EraManager.era_index)
	if not era:
		return ["trilo"]
	return era.enemy_ids

func _enemy_data_to_dict(enemy_id: String) -> Dictionary:
	var db = load(DB_PATH) as GameDatabase
	if not db:
		return {}
	var ed = db.get_enemy(enemy_id)
	if not ed:
		return {}
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
