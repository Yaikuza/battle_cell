extends Resource
class_name GameDatabase

const _BossSkillData = preload("res://data/BossSkillData.gd")
const _BossConfigData = preload("res://data/BossConfigData.gd")

@export var forms: Array = []
@export var enemies: Array = []
@export var upgrades: Array = []
@export var hybrid_recipes: Array = []
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

func _populate_default_configs() -> void:
	var CD = _BossConfigData
	var c
	c = CD.new()
	c.boss_id = "boss_cambrian"; c.display_name = "Anomalocaris Prime"
	c.base_hp = 200; c.base_damage = 25; c.base_speed = 35; c.size = 32
	c.sprite_id = "tyrant_king"; c.color = Color(0.8, 0.1, 0.0)
	c.skill_ids = ["charge", "spread"]; c.max_concurrent_skills = 1; c.gp_value = 50; c.era_min = 0
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_cambrian"; c.display_name = "Trilobite Alpha"; c.is_mini = true
	c.base_hp = 80; c.base_damage = 12; c.base_speed = 45; c.size = 20
	c.sprite_id = "tyrant_king"; c.color = Color(0.6, 0.3, 0.1)
	c.skill_ids = ["spread"]; c.max_concurrent_skills = 1; c.gp_value = 15; c.era_min = 0
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "boss_triassic"; c.display_name = "Placoderm Titan"
	c.base_hp = 350; c.base_damage = 30; c.base_speed = 30; c.size = 38
	c.sprite_id = "tyrant_king"; c.color = Color(0.6, 0.2, 0.4)
	c.skill_ids = ["aoe_circle", "summon"]; c.max_concurrent_skills = 2; c.gp_value = 80; c.era_min = 1
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_triassic"; c.display_name = "Giant Jelly"; c.is_mini = true
	c.base_hp = 120; c.base_damage = 15; c.base_speed = 35; c.size = 24
	c.sprite_id = "tyrant_king"; c.color = Color(0.2, 0.6, 0.8)
	c.skill_ids = ["aoe_circle"]; c.max_concurrent_skills = 1; c.gp_value = 25; c.era_min = 1
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "boss_jurassic"; c.display_name = "Dilophosaurus Rex"
	c.base_hp = 500; c.base_damage = 35; c.base_speed = 50; c.size = 44
	c.sprite_id = "tyrant_king"; c.color = Color(0.9, 0.4, 0.1)
	c.skill_ids = ["charge", "aoe_cone", "buff"]; c.max_concurrent_skills = 2; c.gp_value = 120; c.era_min = 2
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_jurassic"; c.display_name = "Raptor Pack Leader"; c.is_mini = true
	c.base_hp = 150; c.base_damage = 18; c.base_speed = 60; c.size = 26
	c.sprite_id = "tyrant_king"; c.color = Color(0.8, 0.5, 0.2)
	c.skill_ids = ["charge"]; c.max_concurrent_skills = 1; c.gp_value = 35; c.era_min = 2
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "boss_cretaceous"; c.display_name = "Tyrant King Supreme"
	c.base_hp = 700; c.base_damage = 40; c.base_speed = 45; c.size = 50
	c.sprite_id = "tyrant_king"; c.color = Color(1.0, 0.1, 0.0)
	c.skill_ids = ["spread", "summon", "dash"]; c.max_concurrent_skills = 2; c.gp_value = 180; c.era_min = 3
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_cretaceous"; c.display_name = "Spiked Pachy"; c.is_mini = true
	c.base_hp = 180; c.base_damage = 22; c.base_speed = 55; c.size = 28
	c.sprite_id = "tyrant_king"; c.color = Color(0.7, 0.7, 0.2)
	c.skill_ids = ["dash"]; c.max_concurrent_skills = 1; c.gp_value = 45; c.era_min = 3
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "boss_postcretaceous"; c.display_name = "Void Walker"
	c.base_hp = 1000; c.base_damage = 50; c.base_speed = 55; c.size = 56
	c.sprite_id = "tyrant_king"; c.color = Color(0.2, 0.0, 0.6)
	c.skill_ids = ["charge", "aoe_circle", "summon", "buff", "dash"]; c.max_concurrent_skills = 3; c.gp_value = 250; c.era_min = 4
	boss_configs.append(c)

	c = CD.new()
	c.boss_id = "miniboss_postcretaceous"; c.display_name = "Crystal Scout"; c.is_mini = true
	c.base_hp = 220; c.base_damage = 25; c.base_speed = 65; c.size = 30
	c.sprite_id = "tyrant_king"; c.color = Color(0.5, 0.0, 0.8)
	c.skill_ids = ["spread"]; c.max_concurrent_skills = 1; c.gp_value = 55; c.era_min = 4
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

func get_hybrid_recipe(result_id: String):
	for r in hybrid_recipes:
		if r.result_form_id == result_id:
			return r
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
