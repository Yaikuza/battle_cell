extends Node
class_name EvolutionManager

const EvolutionScreenScript = preload("res://ui/EvolutionScreen.gd")

var current_form_id: String = "cell"
var _evolution_path: Array[String] = ["cell"]
var _used_upgrades: Dictionary = {}
var _tree: Dictionary = {}
var _upgrades: Dictionary = {}
var _hybrid_recipes: Dictionary = {}

func _init() -> void:
	_tree = {
		"cell": {
			"name": "Single Cell", "desc": "จุดเริ่มต้นของทุกชีวิต — ฟันแหลก!",
			"stats": {"speed": 300, "max_hp": 100, "damage": 18, "fire_cooldown": 0.3, "range": 400},
			"color": Color.GREEN, "size": 1.0, "weapon": "slash",
			"tags": ["evolution"], "type": "form",
			"next": ["fish", "amphibian", "bug", "predator"]
		},
		"predator": {
			"name": "Simple Predator", "desc": "นักล่ายุคแรก — จู่โจมด้วยคมฟัน",
			"stats": {"speed": 350, "max_hp": 140, "damage": 22, "fire_cooldown": 0.35, "range": 400},
			"color": Color(0.9, 0.3, 0.1), "size": 1.15, "weapon": "slash",
			"tags": ["evolution"], "type": "form",
			"next": ["reptile"]
		},
		"fish": {
			"name": "Ancient Fish", "desc": "สัตว์มีกระดูกสันหลังชนิดแรก — ว่องไว",
			"stats": {"speed": 330, "max_hp": 130, "damage": 18, "fire_cooldown": 0.7, "range": 380},
			"color": Color(0.0, 0.8, 1.0), "size": 1.1, "weapon": "water_jet",
			"tags": ["evolution"], "type": "form",
			"next": ["reptile"]
		},
		"amphibian": {
			"name": "Primitive Amphibian", "desc": "ก้าวแรกสู่พื้นดิน — อึด ถึก ทน",
			"stats": {"speed": 260, "max_hp": 170, "damage": 20, "fire_cooldown": 0.9, "range": 350},
			"color": Color(1.0, 0.6, 0.0), "size": 1.2, "weapon": "tongue_lash",
			"tags": ["evolution"], "type": "form",
			"next": ["reptile"]
		},
		"bug": {
			"name": "Giant Insect", "desc": "แมลงยุคคาร์บอนิเฟอรัส — เล็ก เร็ว",
			"stats": {"speed": 400, "max_hp": 80, "damage": 12, "fire_cooldown": 0.5, "range": 300},
			"color": Color(0.7, 0.2, 0.9), "size": 0.8, "weapon": "sting_dart",
			"tags": ["evolution"], "type": "form",
			"next": ["winged_insect"]
		},
		"reptile": {
			"name": "Early Reptile", "desc": "สัตว์เลื้อยคลานยุคแรก — สมดุลทุกด้าน",
			"stats": {"speed": 300, "max_hp": 200, "damage": 25, "fire_cooldown": 0.8, "range": 350},
			"color": Color(0.2, 0.8, 0.2), "size": 1.3, "weapon": "tail_sweep",
			"tags": ["evolution"], "type": "form",
			"next": ["primeval_dino"]
		},
		"winged_insect": {
			"name": "Winged Insect", "desc": "แมลงมีปีก — เร้นลับและแม่นยำ",
			"stats": {"speed": 450, "max_hp": 70, "damage": 14, "fire_cooldown": 0.4, "range": 350},
			"color": Color(0.5, 0.0, 0.8), "size": 0.7, "weapon": "piercing_sting",
			"tags": ["evolution"], "type": "form",
			"next": ["swarm_lord"]
		},
		"primeval_dino": {
			"name": "Primeval Dino", "desc": "ไดโนเสาร์ยุคแรกเริ่ม — พลังทำลายล้าง",
			"stats": {"speed": 250, "max_hp": 350, "damage": 40, "fire_cooldown": 1.0, "range": 400},
			"color": Color(0.8, 0.2, 0.1), "size": 1.6, "weapon": "crushing_bite",
			"tags": ["evolution"], "type": "form",
			"next": ["tyrant_king"]
		},
		"swarm_lord": {
			"name": "Swarm Lord", "desc": "จอมแมลง — เร็ว จัดหนัก จัดเบา",
			"stats": {"speed": 500, "max_hp": 100, "damage": 20, "fire_cooldown": 0.3, "range": 300},
			"color": Color(0.9, 0.4, 0.0), "size": 1.2, "weapon": "swarm_shot",
			"tags": ["evolution"], "type": "form",
			"next": ["chitin_beetle"]
		},
		"tyrant_king": {
			"name": "Tyrant King", "desc": "จ้าวไดโนเสาร์ — พิบัติแก่ศัตรูทั้งปวง",
			"stats": {"speed": 280, "max_hp": 500, "damage": 55, "fire_cooldown": 1.2, "range": 400},
			"color": Color(1.0, 0.1, 0.0), "size": 1.8, "weapon": "crushing_bite",
			"tags": ["evolution"], "type": "form",
			"next": []
		},
		"chitin_beetle": {
			"name": "Chitin Beetle", "desc": "แมลงปีกแข็งยักษ์ — เกราะหนา ทนทาน",
			"stats": {"speed": 350, "max_hp": 250, "damage": 18, "fire_cooldown": 0.5, "range": 250},
			"color": Color(0.9, 0.7, 0.1), "size": 1.4, "weapon": "swarm_shot",
			"tags": ["evolution"], "type": "form",
			"next": []
		},
		"crab_like": {
			"name": "Crab-like", "desc": "ลูกผสมปลา-แมลง — เกราะแข็ง ก้ามทะลวง",
			"stats": {"speed": 320, "max_hp": 220, "damage": 28, "fire_cooldown": 0.7, "range": 280},
			"color": Color(1.0, 0.5, 0.1), "size": 1.3, "weapon": "pincer_claw",
			"tags": ["evolution"], "type": "hybrid",
			"next": []
		},
		"dragon": {
			"name": "Dragon", "desc": "สัตว์เลื้อยคลานมีปีก — เพลิงผลาญทุกสิ่ง",
			"stats": {"speed": 310, "max_hp": 400, "damage": 45, "fire_cooldown": 0.9, "range": 450},
			"color": Color(1.0, 0.2, 0.0), "size": 1.7, "weapon": "fire_breath",
			"tags": ["evolution"], "type": "hybrid",
			"next": []
		},
		"chimera": {
			"name": "Chimera", "desc": "ลูกผสมไดโนเสาร์-แมลง — หัวสามหัว สามอาวุธ",
			"stats": {"speed": 340, "max_hp": 450, "damage": 50, "fire_cooldown": 0.6, "range": 350},
			"color": Color(0.8, 0.0, 0.8), "size": 1.6, "weapon": "chaos_beam",
			"tags": ["evolution"], "type": "hybrid",
			"next": []
		}
	}

	_upgrades = {
		"atk_damage_1": {"name": "Sharpened Claws", "desc": "+12% Damage", "tags": ["atk"], "mods": [{"stat": "damage", "val": 0.12, "type": 1}]},
		"atk_damage_2": {"name": "Venom Glands", "desc": "+12% Damage", "tags": ["atk"], "mods": [{"stat": "damage", "val": 0.12, "type": 1}]},
		"atk_speed_1": {"name": "Rapid Metabolism", "desc": "+10% Fire Rate", "tags": ["atk"], "mods": [{"stat": "fire_cooldown", "val": -0.10, "type": 1}]},
		"atk_speed_2": {"name": "Double Heart", "desc": "+10% Fire Rate", "tags": ["atk"], "mods": [{"stat": "fire_cooldown", "val": -0.10, "type": 1}]},
		"def_hp_1": {"name": "Thickened Carapace", "desc": "+30 Max HP", "tags": ["def"], "mods": [{"stat": "max_hp", "val": 30, "type": 0}]},
		"def_hp_2": {"name": "Bone Plating", "desc": "+30 Max HP", "tags": ["def"], "mods": [{"stat": "max_hp", "val": 30, "type": 0}]},
		"speed_move_1": {"name": "Swift Fins", "desc": "+10% Move Speed", "tags": ["speed"], "mods": [{"stat": "speed", "val": 0.10, "type": 1}]},
		"speed_move_2": {"name": "Jet Propulsion", "desc": "+10% Move Speed", "tags": ["speed"], "mods": [{"stat": "speed", "val": 0.10, "type": 1}]},
		"weapon_range": {"name": "Long Reach", "desc": "+15% Attack Range", "tags": ["weapon"], "mods": [{"stat": "range", "val": 0.15, "type": 1}]},
		"weapon_projectile": {"name": "Streamlined Form", "desc": "+15% Projectile Speed", "tags": ["weapon"], "mods": [{"stat": "projectile_speed", "val": 0.15, "type": 1}]},
		"misc_gp": {"name": "GP Magnet", "desc": "+20% Genetic Point Gain", "tags": ["misc"], "mods": []},
	}

	_hybrid_recipes = {
		"crab_like": {
			"parents": ["fish", "bug"],
			"result_id": "crab_like",
			"era_min": 0,
		},
		"dragon": {
			"parents": ["reptile", "winged_insect"],
			"result_id": "dragon",
			"era_min": 2,
		},
		"chimera": {
			"parents": ["primeval_dino", "swarm_lord"],
			"result_id": "chimera",
			"era_min": 4,
		},
	}

func _ready() -> void:
	EventBus.evolution_ready.connect(_on_evolution_ready)

func _exit_tree() -> void:
	if EventBus.evolution_ready.is_connected(_on_evolution_ready):
		EventBus.evolution_ready.disconnect(_on_evolution_ready)

func _on_evolution_ready() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	var choices = _get_choices()
	if choices.is_empty():
		_show_adaptive_upgrades(player)
		return

	get_tree().paused = true
	_show_evolution_screen(choices, player)

func _show_evolution_screen(choices: Array[Dictionary], player: Player) -> void:
	var screen = EvolutionScreenScript.new()
	var viewport = get_viewport().get_visible_rect().size
	screen.show_choices(choices, viewport, func(data): _on_choice_made(data, player))
	get_tree().current_scene.add_child(screen)

func _show_adaptive_upgrades(player: Player) -> void:
	var available: Array[Dictionary] = []
	for up_id in _upgrades:
		if not _used_upgrades.has(up_id):
			var up = _upgrades[up_id].duplicate(true)
			up["id"] = up_id
			up["type"] = "upgrade"
			available.append(up)

	if available.is_empty():
		return

	available.shuffle()
	var pick = mini(3, available.size())
	var choices: Array[Dictionary] = []
	for i in range(pick):
		choices.append(available[i])

	get_tree().paused = true
	_show_evolution_screen(choices, player)

func _on_choice_made(data: Dictionary, player: Player) -> void:
	var data_type = data.get("type", "form")
	if data_type == "upgrade":
		var up_id = data.get("id", "")
		_used_upgrades[up_id] = true
		var mods = data.get("mods", [])
		for m in mods:
			player.stats.add_modifier_raw(m.stat, m.val, m.type, "evolution_upgrade")
		if up_id == "misc_gp":
			GameManager.gp_multiplier = 1.2
		player.refresh_from_stats()
	else:
		var form_id = data.get("id", current_form_id)
		_evolution_path.append(form_id)
		current_form_id = form_id
		player.apply_form(data)
		EventBus.evolution_chosen.emit(current_form_id)
		if data_type == "hybrid":
			EventBus.hybrid_unlocked.emit(form_id)
	get_tree().paused = false

func get_current_form() -> Dictionary:
	return _tree.get(current_form_id, _tree["cell"])

func get_evolution_path() -> Array[String]:
	return _evolution_path.duplicate()

func get_hybrid_recipes() -> Dictionary:
	return _hybrid_recipes.duplicate(true)

func _get_hybrid_choices(form: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var era = GameManager.era_index

	for recipe_id in _hybrid_recipes:
		var recipe = _hybrid_recipes[recipe_id]
		if era < recipe.get("era_min", 0):
			continue
		if not _is_hybrid_eligible(recipe, form):
			continue
		var form_id = recipe.get("result_id", "")
		var f = _tree.get(form_id)
		if not f:
			continue
		var dup = f.duplicate(true)
		dup["id"] = form_id
		dup["type"] = "hybrid"
		result.append(dup)

	return result

func _is_hybrid_eligible(recipe: Dictionary, form: Dictionary) -> bool:
	var parents = recipe.get("parents", [])
	var next = form.get("next", [])
	for p in parents:
		if not p in next:
			return false
	return true

func _get_choices() -> Array[Dictionary]:
	var form = get_current_form()
	var result: Array[Dictionary] = []

	for next_id in form.get("next", []):
		var f = _tree.get(next_id)
		if f:
			var dup = f.duplicate(true)
			dup["id"] = next_id
			result.append(dup)

	for recipe in _get_hybrid_choices(form):
		result.append(recipe)

	var available: Array[Dictionary] = []
	for up_id in _upgrades:
		if not _used_upgrades.has(up_id):
			var up = _upgrades[up_id].duplicate(true)
			up["id"] = up_id
			up["type"] = "upgrade"
			available.append(up)
	available.shuffle()
	var pick = mini(2, available.size())
	for i in range(pick):
		result.append(available[i])

	result.shuffle()
	return result
