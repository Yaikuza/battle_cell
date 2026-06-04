extends SceneTree

const EvolutionDataScript = preload("res://data/EvolutionData.gd")
const EnemyDataScript = preload("res://data/EnemyData.gd")
const UpgradeDataScript = preload("res://data/UpgradeData.gd")
const HybridRecipeScript = preload("res://data/HybridRecipe.gd")
const EraDataScript = preload("res://data/EraData.gd")
const GameDatabaseScript = preload("res://data/GameDatabase.gd")

func _initialize() -> void:
	var db = GameDatabaseScript.new()

	db.forms = _build_forms()
	db.enemies = _build_enemies()
	db.upgrades = _build_upgrades()
	db.hybrid_recipes = _build_recipes()
	db.eras = _build_eras()

	var err = ResourceSaver.save(db, "res://data/game_database.tres")
	if err == OK:
		print("OK — saved res://data/game_database.tres")
		print("  forms=", db.forms.size(), " enemies=", db.enemies.size())
		print("  upgrades=", db.upgrades.size(), " recipes=", db.hybrid_recipes.size(), " eras=", db.eras.size())
	else:
		print("FAIL — error code: ", err)
	quit()

func _build_forms() -> Array:
	var list = []
	list.append(_f("cell", "Single Cell", {"speed": 300, "max_hp": 100, "damage": 18, "fire_cooldown": 0.3, "range": 400}, Color.GREEN, 1.0, "slash", "form", ["fish", "arthropod", "synapsid", "amphibian", "apex_hunter"]))
	list.append(_f("fish", "Ancient Fish", {"speed": 330, "max_hp": 130, "damage": 18, "fire_cooldown": 0.7, "range": 380}, Color(0.0, 0.8, 1.0), 1.1, "water_jet", "form", ["amphibian"]))
	list.append(_f("amphibian", "Primitive Amphibian", {"speed": 260, "max_hp": 170, "damage": 20, "fire_cooldown": 0.9, "range": 350}, Color(1.0, 0.6, 0.0), 1.2, "tongue_lash", "form", ["reptile"]))
	list.append(_f("arthropod", "Early Arthropod", {"speed": 400, "max_hp": 80, "damage": 12, "fire_cooldown": 0.5, "range": 300}, Color(0.7, 0.2, 0.9), 0.8, "sting_dart", "form", ["winged_insect"]))
	list.append(_f("synapsid", "Pelycosaur", {"speed": 320, "max_hp": 160, "damage": 20, "fire_cooldown": 0.9, "range": 350}, Color(0.6, 0.3, 0.0), 1.2, "crushing_bite", "form", ["cynodont"]))
	list.append(_f("apex_hunter", "Convergent Predator", {"speed": 350, "max_hp": 140, "damage": 22, "fire_cooldown": 0.35, "range": 400}, Color(0.9, 0.3, 0.1), 1.15, "slash", "form", ["cynodont"]))
	list.append(_f("reptile", "Early Reptile", {"speed": 300, "max_hp": 200, "damage": 25, "fire_cooldown": 0.8, "range": 350}, Color(0.2, 0.8, 0.2), 1.3, "tail_sweep", "form", ["primeval_dino"]))
	list.append(_f("winged_insect", "Winged Insect", {"speed": 450, "max_hp": 70, "damage": 14, "fire_cooldown": 0.4, "range": 350}, Color(0.5, 0.0, 0.8), 0.7, "piercing_sting", "form", ["swarm_lord"]))
	list.append(_f("cynodont", "Cynodont", {"speed": 370, "max_hp": 200, "damage": 25, "fire_cooldown": 0.6, "range": 380}, Color(0.8, 0.5, 0.2), 1.1, "swarm_shot", "form", ["mammal"]))
	list.append(_f("primeval_dino", "Primeval Dino", {"speed": 250, "max_hp": 350, "damage": 40, "fire_cooldown": 1.0, "range": 400}, Color(0.8, 0.2, 0.1), 1.6, "crushing_bite", "form", ["tyrant_king"]))
	list.append(_f("swarm_lord", "Swarm Lord", {"speed": 500, "max_hp": 100, "damage": 20, "fire_cooldown": 0.3, "range": 300}, Color(0.9, 0.4, 0.0), 1.2, "swarm_shot", "form", ["chitin_beetle"]))
	list.append(_f("mammal", "Early Mammal", {"speed": 420, "max_hp": 150, "damage": 18, "fire_cooldown": 0.35, "range": 300}, Color(0.3, 0.5, 0.4), 0.7, "sting_dart", "form", ["primate"]))
	list.append(_f("primate", "Primate", {"speed": 350, "max_hp": 220, "damage": 28, "fire_cooldown": 0.65, "range": 400}, Color(0.15, 0.45, 0.55), 1.0, "tongue_lash", "form", ["human"]))
	list.append(_f("human", "Human", {"speed": 380, "max_hp": 350, "damage": 35, "fire_cooldown": 0.7, "range": 500}, Color(0.85, 0.7, 0.55), 1.2, "psychic_blast", "form", []))
	list.append(_f("tyrant_king", "Tyrant King", {"speed": 280, "max_hp": 500, "damage": 55, "fire_cooldown": 1.2, "range": 400}, Color(1.0, 0.1, 0.0), 1.8, "crushing_bite", "form", []))
	list.append(_f("chitin_beetle", "Chitin Beetle", {"speed": 350, "max_hp": 250, "damage": 18, "fire_cooldown": 0.5, "range": 250}, Color(0.9, 0.7, 0.1), 1.4, "swarm_shot", "form", []))
	list.append(_f("crab_like", "Crab-like", {"speed": 320, "max_hp": 220, "damage": 28, "fire_cooldown": 0.7, "range": 280}, Color(1.0, 0.5, 0.1), 1.3, "pincer_claw", "hybrid", []))
	list.append(_f("dragon", "Dragon", {"speed": 310, "max_hp": 400, "damage": 45, "fire_cooldown": 0.9, "range": 450}, Color(1.0, 0.2, 0.0), 1.7, "fire_breath", "hybrid", []))
	list.append(_f("chimera", "Chimera", {"speed": 340, "max_hp": 450, "damage": 50, "fire_cooldown": 0.6, "range": 350}, Color(0.8, 0.0, 0.8), 1.6, "chaos_beam", "hybrid", []))
	list.append(_f("rubber_chicken", "Rubber Chicken", {"speed": 400, "max_hp": 150, "damage": 20, "fire_cooldown": 0.3, "range": 350}, Color(1.0, 0.8, 0.0), 1.0, "bouncy_shot", "wtf", []))
	list.append(_f("roomba_lord", "Roomba Lord", {"speed": 250, "max_hp": 300, "damage": 10, "fire_cooldown": 0.5, "range": 200}, Color(0.3, 0.3, 0.3), 1.3, "suction", "wtf", []))
	list.append(_f("t_pose_tyrant", "T-Pose Tyrant", {"speed": 250, "max_hp": 400, "damage": 30, "fire_cooldown": 1.0, "range": 400}, Color(1.0, 0.3, 0.0), 1.5, "stare", "wtf", []))
	return list

func _f(id: String, name: String, stats: Dictionary, color: Color, size: float, weapon: String, etype: String, next: Array) -> Object:
	var d = EvolutionDataScript.new()
	d.id = id
	d.display_name = name
	d.base_stats = stats
	d.color = color
	d.size = size
	d.weapon = weapon
	d.evolution_type = etype
	d.next_evolution_ids = next
	return d

func _build_enemies() -> Array:
	var list = []
	list.append(_e("trilo", "Trilobite", 15, 40, 6, 3, 10, Color(0.6, 0.3, 0.1), "trilobite", "chase"))
	list.append(_e("anomalo", "Anomalocaris", 22, 55, 8, 4, 14, Color(0.8, 0.4, 0.2), "anomalocaris", "chase"))
	list.append(_e("jelly", "Jellyfish", 12, 30, 4, 2, 11, Color(0.2, 0.6, 0.8), "jellyfish", "chase"))
	list.append(_e("placoderm", "Placoderm", 35, 35, 10, 5, 16, Color(0.4, 0.4, 0.5), "placoderm", "tank"))
	list.append(_e("ammonite", "Ammonite", 25, 50, 12, 5, 13, Color(0.9, 0.6, 0.2), "ammonite", "ranged"))
	list.append(_e("temnospondyl", "Temnospondyl", 40, 45, 14, 6, 18, Color(0.3, 0.6, 0.3), "temnospondyl", "charge"))
	list.append(_e("dilo", "Dilophosaurus", 40, 70, 16, 7, 15, Color(0.7, 0.5, 0.1), "dilophosaurus", "ranged"))
	list.append(_e("stego", "Stegosaurus", 60, 30, 18, 8, 20, Color(0.5, 0.7, 0.2), "stegosaurus", "tank"))
	list.append(_e("ptero", "Pterosaur", 30, 85, 12, 6, 12, Color(0.4, 0.3, 0.7), "pterosaur", "swoop"))
	list.append(_e("raptor", "Velociraptor", 35, 100, 20, 8, 12, Color(0.6, 0.7, 0.1), "velociraptor", "flank"))
	list.append(_e("trike", "Triceratops", 80, 35, 22, 10, 22, Color(0.5, 0.4, 0.3), "triceratops", "charge"))
	list.append(_e("pachy", "Pachycephalosaurus", 50, 60, 25, 9, 16, Color(0.6, 0.3, 0.4), "pachycephalosaurus", "charge"))
	list.append(_e("mutant", "Mutant", 60, 65, 25, 10, 16, Color(0.2, 0.8, 0.3), "mutant", "charge"))
	list.append(_e("crystal", "Crystal Entity", 70, 50, 28, 12, 14, Color(0.5, 0.2, 0.9), "crystal_entity", "ranged"))
	list.append(_e("void_walker", "Void Walker", 40, 90, 20, 11, 11, Color(0.1, 0.1, 0.2), "void_walker", "flank"))
	list.append(_e("boss_anomalo", "Giant Anomalocaris", 150, 35, 15, 30, 30, Color(0.9, 0.3, 0.0), "anomalocaris", "chase"))
	list.append(_e("boss_dimetrodon", "Dimetrodon", 300, 40, 20, 40, 34, Color(0.2, 0.7, 0.5), "dimetrodon", "chase"))
	list.append(_e("boss_allo", "Allosaurus", 500, 45, 25, 60, 36, Color(0.7, 0.2, 0.1), "allosaurus", "chase"))
	list.append(_e("boss_trex", "Tyrannosaurus Rex", 800, 50, 35, 80, 40, Color(0.9, 0.1, 0.0), "tyrant_king", "chase"))
	list.append(_e("boss_omega", "Omega Mutant", 1200, 55, 40, 100, 42, Color(0.0, 0.9, 0.5), "omega_mutant", "chase"))
	return list

func _e(id: String, name: String, hp: float, speed: float, dmg: float, gp: int, sz: float, col: Color, sprite: String, behavior: String) -> Object:
	var d = EnemyDataScript.new()
	d.id = id
	d.display_name = name
	d.base_hp = hp
	d.base_speed = speed
	d.damage = dmg
	d.gp_value = gp
	d.size = sz
	d.color = col
	d.sprite_id = sprite
	d.behavior_id = behavior
	d.is_boss = id.begins_with("boss_")
	return d

func _build_upgrades() -> Array:
	var list = []
	list.append(_u("atk_damage_1", "Sharpened Claws", "+12% Damage", ["atk"], [{"stat": "damage", "val": 0.12, "type": 1}]))
	list.append(_u("atk_damage_2", "Venom Glands", "+12% Damage", ["atk"], [{"stat": "damage", "val": 0.12, "type": 1}]))
	list.append(_u("atk_speed_1", "Rapid Metabolism", "+10% Fire Rate", ["atk"], [{"stat": "fire_cooldown", "val": -0.10, "type": 1}]))
	list.append(_u("atk_speed_2", "Double Heart", "+10% Fire Rate", ["atk"], [{"stat": "fire_cooldown", "val": -0.10, "type": 1}]))
	list.append(_u("def_hp_1", "Thickened Carapace", "+30 Max HP", ["def"], [{"stat": "max_hp", "val": 30, "type": 0}]))
	list.append(_u("def_hp_2", "Bone Plating", "+30 Max HP", ["def"], [{"stat": "max_hp", "val": 30, "type": 0}]))
	list.append(_u("speed_move_1", "Swift Fins", "+10% Move Speed", ["speed"], [{"stat": "speed", "val": 0.10, "type": 1}]))
	list.append(_u("speed_move_2", "Jet Propulsion", "+10% Move Speed", ["speed"], [{"stat": "speed", "val": 0.10, "type": 1}]))
	list.append(_u("weapon_range", "Long Reach", "+15% Attack Range", ["weapon"], [{"stat": "range", "val": 0.15, "type": 1}]))
	list.append(_u("weapon_projectile", "Streamlined Form", "+15% Projectile Speed", ["weapon"], [{"stat": "projectile_speed", "val": 0.15, "type": 1}]))
	list.append(_u("misc_gp", "GP Magnet", "+20% Genetic Point Gain", ["misc"], []))
	return list

func _u(id: String, name: String, desc: String, tags: Array, mods: Array) -> Object:
	var d = UpgradeDataScript.new()
	d.id = id
	d.display_name = name
	d.description = desc
	d.tags = tags
	d.mods = mods
	return d

func _build_recipes() -> Array:
	var list = []
	var s = HybridRecipeScript
	for data in [["crab_like", "Fish + Arthropod", "crab_like", ["fish", "arthropod"], 0], ["dragon", "Reptile + Winged Insect", "dragon", ["reptile", "winged_insect"], 2], ["chimera", "Primeval Dino + Swarm Lord", "chimera", ["primeval_dino", "swarm_lord"], 4]]:
		var r = s.new()
		r.id = data[0]; r.display_name = data[1]; r.result_form_id = data[2]; r.parent_ids = data[3]; r.era_min = data[4]
		list.append(r)
	return list

func _build_eras() -> Array:
	var list = []
	var s = EraDataScript
	for data in [
		[0, "Cambrian", ["trilo", "anomalo", "jelly"], "boss_anomalo", 1.8],
		[1, "Triassic", ["placoderm", "ammonite", "temnospondyl"], "boss_dimetrodon", 1.6],
		[2, "Jurassic", ["dilo", "stego", "ptero"], "boss_allo", 1.4],
		[3, "Cretaceous", ["raptor", "trike", "pachy"], "boss_trex", 1.2],
		[4, "Post-Cretaceous", ["mutant", "crystal", "void_walker"], "boss_omega", 1.0],
	]:
		var r = s.new()
		r.era_id = data[0]; r.display_name = data[1]; r.enemy_ids = data[2]; r.boss_id = data[3]; r.zoom_level = data[4]
		list.append(r)
	return list
