extends Resource
class_name GameDatabase

const _BossSkillData = preload("res://data/BossSkillData.gd")
const _BossConfigData = preload("res://data/BossConfigData.gd")

@export var forms: Array = []
@export var enemies: Array = []
@export var upgrades: Array = []
@export var eras: Array = []
@export var mutations: Array = []
@export var boss_skills: Array = []
@export var boss_configs: Array = []

func _init() -> void:
	if boss_skills.is_empty():
		_populate_default_skills()
	if boss_configs.is_empty():
		_populate_default_configs()

func _populate_default_skills() -> void:
	var BD = _BossSkillData
	var s
	s = BD.new()
	s.skill_id = "charge"; s.skill_name = "Charge"; s.type = BD.SkillType.CHARGE
	s.cooldown = 4.0; s.damage_mult = 2.0; s.telegraph_time = 0.6
	s.telegraph_color = Color(1.0, 0.8, 0.0); s.params = {"speed": 300, "duration": 0.3}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "spread"; s.skill_name = "Spread Shot"; s.type = BD.SkillType.SPREAD
	s.cooldown = 3.0; s.damage_mult = 1.0; s.telegraph_time = 0.5
	s.telegraph_color = Color(1.0, 0.2, 0.0); s.params = {"count": 5, "angle": 90.0, "projectile_speed": 200}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "summon"; s.skill_name = "Summon Minions"; s.type = BD.SkillType.SUMMON
	s.cooldown = 6.0; s.damage_mult = 0.0; s.telegraph_time = 0.8
	s.telegraph_color = Color(0.5, 0.0, 1.0); s.params = {"count": 2}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "aoe_circle"; s.skill_name = "Ground Pound"; s.type = BD.SkillType.AOE
	s.cooldown = 4.0; s.damage_mult = 1.5; s.telegraph_time = 0.7
	s.telegraph_color = Color(1.0, 0.0, 0.0); s.params = {"radius": 64.0}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "aoe_cone"; s.skill_name = "Ice Breath"; s.type = BD.SkillType.AOE
	s.cooldown = 5.0; s.damage_mult = 1.2; s.telegraph_time = 0.6
	s.telegraph_color = Color(0.3, 0.7, 1.0); s.params = {"radius": 80.0}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "buff"; s.skill_name = "Enrage"; s.type = BD.SkillType.BUFF
	s.cooldown = 8.0; s.damage_mult = 0.0; s.telegraph_time = 0.4
	s.telegraph_color = Color(1.0, 0.5, 0.0); s.params = {"duration": 4.0, "speed_mult": 1.5, "damage_mult": 1.5}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "dash"; s.skill_name = "Quick Dash"; s.type = BD.SkillType.DASH
	s.cooldown = 3.0; s.damage_mult = 0.0; s.telegraph_time = 0.3
	s.telegraph_color = Color(0.5, 0.8, 1.0); s.params = {"distance": 150, "speed": 400}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "claw_snap"; s.skill_name = "Claw Snap"; s.type = BD.SkillType.CLAW_SNAP
	s.cooldown = 4.0; s.damage_mult = 1.5; s.telegraph_time = 0.6
	s.telegraph_color = Color(0.9, 0.1, 0.1); s.params = {"gap": 80, "length": 120, "speed": 300}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "eye_beam"; s.skill_name = "Eye Beam"; s.type = BD.SkillType.EYE_BEAM
	s.cooldown = 5.0; s.damage_mult = 1.2; s.telegraph_time = 1.0
	s.telegraph_color = Color(1.0, 0.9, 0.3); s.params = {"beam_count": 8, "range": 400, "speed": 300}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "tail_flail"; s.skill_name = "Tail Flail"; s.type = BD.SkillType.TAIL_FLAIL
	s.cooldown = 5.0; s.damage_mult = 1.0; s.telegraph_time = 0.5
	s.telegraph_color = Color(0.8, 0.4, 0.2); s.params = {"speed": 180, "speed_increment": 60}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "roll_up"; s.skill_name = "Roll Up"; s.type = BD.SkillType.ROLL_UP
	s.cooldown = 4.0; s.damage_mult = 1.8; s.telegraph_time = 0.5
	s.telegraph_color = Color(0.7, 0.5, 0.2); s.params = {"speed": 350, "duration": 0.8, "bounces": 2}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "spine_shot"; s.skill_name = "Spine Shot"; s.type = BD.SkillType.SPINE_SHOT
	s.cooldown = 3.5; s.damage_mult = 0.8; s.telegraph_time = 0.5
	s.telegraph_color = Color(0.6, 0.4, 0.1); s.params = {"count": 8, "speed": 200}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "ground_pound"; s.skill_name = "Ground Pound"; s.type = BD.SkillType.GROUND_POUND
	s.cooldown = 5.0; s.damage_mult = 1.3; s.telegraph_time = 0.7
	s.telegraph_color = Color(0.9, 0.5, 0.0); s.params = {"ring_count": 3, "max_radius": 200, "ring_speed": 0.15}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "slam_wave"; s.skill_name = "Slam Wave"; s.type = BD.SkillType.SLAM_WAVE
	s.cooldown = 4.0; s.damage_mult = 1.2; s.telegraph_time = 0.6
	s.telegraph_color = Color(0.4, 0.6, 0.9); s.params = {"gap": 60, "speed": 250, "range": 400}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "jelly_spawn"; s.skill_name = "Jelly Spawn"; s.type = BD.SkillType.JELLY_SPAWN
	s.cooldown = 7.0; s.damage_mult = 0.0; s.telegraph_time = 0.8
	s.telegraph_color = Color(0.3, 0.8, 1.0); s.params = {"count": 3, "spread": 80, "hatch_time": 5.0}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "venom_spit"; s.skill_name = "Venom Spit"; s.type = BD.SkillType.VENOM_SPIT
	s.cooldown = 5.0; s.damage_mult = 0.0; s.telegraph_time = 0.6
	s.telegraph_color = Color(0.1, 0.7, 0.1); s.params = {"count": 3, "spread": 100, "zone_radius": 32, "duration": 4.0, "dps": 3}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "pounce_mark"; s.skill_name = "Pounce Mark"; s.type = BD.SkillType.POUNCE_MARK
	s.cooldown = 4.5; s.damage_mult = 1.8; s.telegraph_time = 0.8
	s.telegraph_color = Color(0.9, 0.2, 0.2); s.params = {"radius": 64}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "pack_call"; s.skill_name = "Pack Call"; s.type = BD.SkillType.PACK_CALL
	s.cooldown = 6.0; s.damage_mult = 0.0; s.telegraph_time = 0.6
	s.telegraph_color = Color(0.8, 0.4, 0.0); s.params = {"count": 2}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "tail_sweep"; s.skill_name = "Tail Sweep"; s.type = BD.SkillType.TAIL_SWEEP
	s.cooldown = 4.0; s.damage_mult = 1.2; s.telegraph_time = 0.6
	s.telegraph_color = Color(0.7, 0.3, 0.5); s.params = {"count": 9, "speed": 220}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "bone_rain"; s.skill_name = "Bone Rain"; s.type = BD.SkillType.BONE_RAIN
	s.cooldown = 5.0; s.damage_mult = 1.0; s.telegraph_time = 0.5
	s.telegraph_color = Color(0.9, 0.85, 0.7); s.params = {"waves": 3, "count": 4, "speed": 280, "range": 500}
	boss_skills.append(s)

	s = BD.new()
	s.skill_id = "fury_roar"; s.skill_name = "Fury Roar"; s.type = BD.SkillType.FURY_ROAR
	s.cooldown = 6.0; s.damage_mult = 0.0; s.telegraph_time = 0.5
	s.telegraph_color = Color(0.9, 0.1, 0.0); s.params = {"radius": 120, "force": 300}
	boss_skills.append(s)

func _populate_default_configs() -> void:
	var CD = _BossConfigData
	var c
	c = CD.new()
	c.boss_id = "boss_cambrian"; c.display_name = "Anomalocaris Prime"
	c.base_hp = 200; c.base_damage = 25; c.base_speed = 35; c.size = 32
	c.sprite_id = "tyrant_king"; c.color = Color(0.8, 0.1, 0.0)
	c.skill_ids = ["claw_snap", "eye_beam", "tail_flail"]; c.max_concurrent_skills = 1; c.gp_value = 50; c.era_min = 0
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_cambrian"; c.display_name = "Trilobite Alpha"; c.is_mini = true
	c.base_hp = 80; c.base_damage = 12; c.base_speed = 45; c.size = 20
	c.sprite_id = "tyrant_king"; c.color = Color(0.6, 0.3, 0.1)
	c.skill_ids = ["roll_up", "spine_shot"]; c.max_concurrent_skills = 1; c.gp_value = 15; c.era_min = 0
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "boss_triassic"; c.display_name = "Placoderm Titan"
	c.base_hp = 350; c.base_damage = 30; c.base_speed = 30; c.size = 38
	c.sprite_id = "tyrant_king"; c.color = Color(0.6, 0.2, 0.4)
	c.skill_ids = ["ground_pound", "slam_wave"]; c.max_concurrent_skills = 2; c.gp_value = 80; c.era_min = 1
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_triassic"; c.display_name = "Giant Jelly"; c.is_mini = true
	c.base_hp = 120; c.base_damage = 15; c.base_speed = 35; c.size = 24
	c.sprite_id = "tyrant_king"; c.color = Color(0.2, 0.6, 0.8)
	c.skill_ids = ["jelly_spawn"]; c.max_concurrent_skills = 1; c.gp_value = 25; c.era_min = 1
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "boss_jurassic"; c.display_name = "Dilophosaurus Rex"
	c.base_hp = 500; c.base_damage = 35; c.base_speed = 50; c.size = 44
	c.sprite_id = "tyrant_king"; c.color = Color(0.9, 0.4, 0.1)
	c.skill_ids = ["venom_spit", "pounce_mark", "buff"]; c.max_concurrent_skills = 2; c.gp_value = 120; c.era_min = 2
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_jurassic"; c.display_name = "Raptor Pack Leader"; c.is_mini = true
	c.base_hp = 150; c.base_damage = 18; c.base_speed = 60; c.size = 26
	c.sprite_id = "tyrant_king"; c.color = Color(0.8, 0.5, 0.2)
	c.skill_ids = ["pack_call"]; c.max_concurrent_skills = 1; c.gp_value = 35; c.era_min = 2
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "boss_cretaceous"; c.display_name = "Tyrant King Supreme"
	c.base_hp = 700; c.base_damage = 40; c.base_speed = 45; c.size = 50
	c.sprite_id = "tyrant_king"; c.color = Color(1.0, 0.1, 0.0)
	c.skill_ids = ["tail_sweep", "bone_rain", "spread"]; c.max_concurrent_skills = 2; c.gp_value = 180; c.era_min = 3
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_cretaceous"; c.display_name = "Spiked Pachy"; c.is_mini = true
	c.base_hp = 180; c.base_damage = 22; c.base_speed = 55; c.size = 28
	c.sprite_id = "tyrant_king"; c.color = Color(0.7, 0.7, 0.2)
	c.skill_ids = ["fury_roar"]; c.max_concurrent_skills = 1; c.gp_value = 45; c.era_min = 3
	boss_configs.append(c)

func get_form(id: String):
	for f in forms:
		if f.id == id:
			return f
	return null

func get_enemy(id: String):
	for e in enemies:
		if e.id == id:
			return e
	return null

func get_upgrade(id: String):
	for u in upgrades:
		if u.id == id:
			return u
	return null

func get_era(index: int):
	if index >= 0 and index < eras.size():
		return eras[index]
	return null

func get_mutation(id: String):
	for m in mutations:
		if m.id == id:
			return m
	return null

func get_boss_skill(id: String):
	for s in boss_skills:
		if s.skill_id == id:
			return s
	return null

func get_boss_config(id: String):
	for c in boss_configs:
		if c.boss_id == id:
			return c
	return null
