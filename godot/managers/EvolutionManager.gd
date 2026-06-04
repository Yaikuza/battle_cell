extends Node
class_name EvolutionManager

const EvolutionScreenScript = preload("res://ui/EvolutionScreen.gd")

var current_form_id: String = "cell"
var _evolution_path: Array[String] = ["cell"]
var _used_upgrades: Dictionary = {}
var _tree: Dictionary = {}
var _upgrades: Dictionary = {}
var _hybrid_recipes: Dictionary = {}
var _wtf_unlocked: Dictionary = {}
var _wtf_progress: Dictionary = {}

func _init() -> void:
	var db = load("res://data/game_database.tres")
	for f in db.forms:
		_tree[f.id] = {
			"name": f.display_name, "desc": f.description,
			"stats": f.base_stats.duplicate(true),
			"color": f.color, "size": f.size, "weapon": f.weapon,
			"tags": f.tags.duplicate(), "type": f.evolution_type,
			"next": f.next_evolution_ids.duplicate(),
		}
	for u in db.upgrades:
		_upgrades[u.id] = {
			"name": u.display_name, "desc": u.description,
			"tags": u.tags.duplicate(), "mods": u.mods.duplicate(true),
		}
	for r in db.hybrid_recipes:
		_hybrid_recipes[r.id] = {
			"parents": r.parent_ids.duplicate(),
			"result_id": r.result_form_id, "era_min": r.era_min,
		}

func _on_enemy_killed() -> void:
	var kills = _wtf_progress.get("enemy_kills", 0) + 1
	_wtf_progress["enemy_kills"] = kills
	var need = 10 * (3 - MetaManager.get_upgrade_level("rubber_shortcut"))
	if kills >= maxi(need, 10):
		_wtf_unlocked["rubber_chicken"] = true

func _on_gp_collected(amount: int) -> void:
	var total = _wtf_progress.get("total_gp", 0) + amount
	_wtf_progress["total_gp"] = total
	var need = 100 * (3 - MetaManager.get_upgrade_level("roomba_shortcut"))
	if total >= maxi(need, 100):
		_wtf_unlocked["roomba_lord"] = true

var _boss_killed_no_damage: bool = true

func _ready() -> void:
	add_to_group("evolution_manager")
	EventBus.evolution_ready.connect(_on_evolution_ready)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.gp_collected.connect(_on_gp_collected)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.boss_killed.connect(_on_boss_killed)

func _exit_tree() -> void:
	if EventBus.evolution_ready.is_connected(_on_evolution_ready):
		EventBus.evolution_ready.disconnect(_on_evolution_ready)
	if EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.disconnect(_on_enemy_killed)
	if EventBus.gp_collected.is_connected(_on_gp_collected):
		EventBus.gp_collected.disconnect(_on_gp_collected)
	if EventBus.player_damaged.is_connected(_on_player_damaged):
		EventBus.player_damaged.disconnect(_on_player_damaged)
	if EventBus.boss_killed.is_connected(_on_boss_killed):
		EventBus.boss_killed.disconnect(_on_boss_killed)

func _on_boss_killed() -> void:
	var tolerance = MetaManager.get_upgrade_level("tyrant_shortcut")
	if _boss_killed_no_damage or tolerance > 0:
		_wtf_unlocked["t_pose_tyrant"] = true
	_boss_killed_no_damage = true

func _on_player_damaged(_current: int, _max_hp: int) -> void:
	_boss_killed_no_damage = false

func reset_run() -> void:
	_wtf_unlocked.clear()
	_wtf_progress.clear()
	_boss_killed_no_damage = true

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
	get_tree().current_scene.add_child(screen)
	screen.show_choices(choices, viewport, func(data): _on_choice_made(data, player))

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
		SaveManager.unlock_form(form_id)
		player.apply_form(data, true)
		EventBus.evolution_chosen.emit(current_form_id)
		if data_type == "hybrid":
			EventBus.hybrid_unlocked.emit(form_id)
	get_tree().paused = false

func get_save_data() -> Dictionary:
	return {
		"current_form_id": current_form_id,
		"evolution_path": _evolution_path.duplicate(),
		"used_upgrades": _used_upgrades.duplicate(),
		"wtf_progress": _wtf_progress.duplicate(),
		"boss_killed_no_damage": _boss_killed_no_damage,
	}

func restore_from_save(data: Dictionary) -> void:
	current_form_id = data.get("current_form_id", "cell")
	_evolution_path = data.get("evolution_path", ["cell"])
	_used_upgrades = data.get("used_upgrades", {})
	_wtf_progress = data.get("wtf_progress", {})
	_boss_killed_no_damage = data.get("boss_killed_no_damage", true)

func get_upgrade_data(up_id: String) -> Dictionary:
	return _upgrades.get(up_id, {})

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

func _get_wtf_choices() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for wtf_id in ["rubber_chicken", "roomba_lord", "t_pose_tyrant"]:
		if _wtf_unlocked.get(wtf_id, false):
			var f = _tree.get(wtf_id)
			if f:
				var dup = f.duplicate(true)
				dup["id"] = wtf_id
				dup["type"] = "wtf"
				result.append(dup)
	return result

func _get_choices() -> Array[Dictionary]:
	var form = get_current_form()
	var form_choices: Array[Dictionary] = []
	var upgrade_choices: Array[Dictionary] = []
	var max_cards = 3

	for next_id in form.get("next", []):
		var f = _tree.get(next_id)
		if f:
			var dup = f.duplicate(true)
			dup["id"] = next_id
			form_choices.append(dup)

	for recipe in _get_hybrid_choices(form):
		form_choices.append(recipe)

	for wtf in _get_wtf_choices():
		form_choices.append(wtf)

	for up_id in _upgrades:
		if not _used_upgrades.has(up_id):
			var up = _upgrades[up_id].duplicate(true)
			up["id"] = up_id
			up["type"] = "upgrade"
			upgrade_choices.append(up)

	var result: Array[Dictionary] = []

	form_choices.shuffle()
	upgrade_choices.shuffle()

	var form_count = mini(form_choices.size(), 3)
	if form_choices.size() > 0:
		form_count = maxi(form_count, 1)
	for i in range(form_count):
		result.append(form_choices[i])

	var remaining = max_cards - result.size()
	var up_count = mini(upgrade_choices.size(), remaining)
	for i in range(up_count):
		result.append(upgrade_choices[i])

	result.shuffle()
	return result
