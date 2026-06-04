extends Node
class_name BossSkillController

var _boss: Node2D
var _skills: Array[BossSkillData] = []
var _max_concurrent: int = 1
var _cooldowns: Dictionary = {}
var _active_skills: int = 0
var _telegraph_color: Color = Color(1.0, 0.2, 0.0)

const DB_PATH := "res://data/game_database.tres"

func setup(boss: Node2D, skill_ids: Array[String], concurrent: int = 1, tcolor: Color = Color(1.0, 0.2, 0.0)) -> void:
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

	var available: Array[BossSkillData] = []
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

func _telegraph(skill: BossSkillData, player: Node2D, color: Color) -> void:
	match skill.type:
		BossSkillData.SkillType.CHARGE:
			var dir = (player.global_position - _boss.global_position).normalized()
			var dist = _boss.global_position.distance_to(player.global_position)
			SkillTelegraph.warn_line(_boss.global_position, _boss.global_position + dir * dist, 12, color, skill.telegraph_time)

		BossSkillData.SkillType.SPREAD:
			SkillTelegraph.warn_position(_boss.global_position, 80, color, skill.telegraph_time)

		BossSkillData.SkillType.AOE:
			SkillTelegraph.warn_position(player.global_position, 64, color, skill.telegraph_time)

		BossSkillData.SkillType.SUMMON:
			SkillTelegraph.warn_position(_boss.global_position, 40, Color(0.5, 0.0, 1.0), skill.telegraph_time)

	var timer = _boss.get_tree().create_timer(skill.telegraph_time)
	timer.timeout.connect(_execute_skill.bind(skill, player))

func _execute_skill(skill: BossSkillData, player: Node2D) -> void:
	if not _boss or _boss.is_queued_for_deletion():
		_active_skills -= 1
		return

	match skill.type:
		BossSkillData.SkillType.CHARGE:
			var dir = (player.global_position - _boss.global_position).normalized()
			var charge_speed = skill.params.get("speed", 300.0)
			var duration = skill.params.get("duration", 0.3)
			var tween = _boss.create_tween()
			tween.tween_property(_boss, "global_position", _boss.global_position + dir * charge_speed * duration, duration)

		BossSkillData.SkillType.SPREAD:
			var count = skill.params.get("count", 5)
			var angle = skill.params.get("angle", 90.0)
			var proj_speed = skill.params.get("projectile_speed", 200.0)
			var start_angle = -angle * 0.5
			var step = angle / (count - 1) if count > 1 else 0
			for i in range(count):
				var a = start_angle + step * i
				var proj = PoolManager.get_bullet()
				if not proj:
					continue
				var dir = Vector2.RIGHT.rotated(atan2(player.global_position.y - _boss.global_position.y, player.global_position.x - _boss.global_position.x) + deg_to_rad(a))
				proj.global_position = _boss.global_position + dir * 20
				proj.direction = dir
				proj.speed = proj_speed
				proj.damage = ceili(skill.damage_mult * 10)
				proj.max_distance = 400
				_boss.get_tree().current_scene.add_child(proj)

		BossSkillData.SkillType.AOE:
			var radius = skill.params.get("radius", 64.0)
			var targets = _boss.get_tree().get_nodes_in_group("player")
			for t in targets:
				if t is Node2D and t.global_position.distance_to(player.global_position) <= radius:
					var hb = t.get_node_or_null("HurtboxComponent")
					if hb:
						hb.take_direct_hit(ceili(skill.damage_mult * _boss.damage), HitboxComponent.DamageType.PHYSICAL)

		BossSkillData.SkillType.SUMMON:
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

		BossSkillData.SkillType.BUFF:
			var duration = skill.params.get("duration", 4.0)
			var speed_mult = skill.params.get("speed_mult", 1.5)
			var dmg_mult = skill.params.get("damage_mult", 1.5)
			_boss.set_meta("_buff_active", true)
			_boss.set_meta("_buff_speed", speed_mult)
			_boss.speed *= speed_mult
			_boss.damage = ceili(_boss.damage * dmg_mult)
			_boss.modulate = Color(1.5, 1.5, 0.5)
			var timer = _boss.get_tree().create_timer(duration)
			timer.timeout.connect(_end_buff)

		BossSkillData.SkillType.DASH:
			var dash_dir = (_boss.global_position - player.global_position).normalized()
			var dash_dist = skill.params.get("distance", 150.0)
			var dash_speed = skill.params.get("speed", 400.0)
			var target = _boss.global_position + dash_dir * dash_dist
			var tween = _boss.create_tween()
			tween.tween_property(_boss, "global_position", target, dash_dist / dash_speed)

	_active_skills -= 1

func _end_buff() -> void:
	if not _boss or _boss.is_queued_for_deletion():
		return
	_boss.set_meta("_buff_active", false)
	if _boss.has_meta("_buff_speed"):
		_boss.speed /= _boss.get_meta("_buff_speed")
	_boss.set_meta("_buff_speed", null)
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
