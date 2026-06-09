extends Node

const MutationPickerUIScript = preload("res://ui/MutationPickerUI.gd")
const DB_PATH := "res://data/game_database.tres"

var current_mutations: Dictionary = {}
var _mutations: Dictionary = {}
var _db: GameDatabase

func _init() -> void:
	_db = load(DB_PATH) as GameDatabase
	if not _db:
		return
	for md in _db.mutations:
		var m = md as MutationData
		if not m:
			continue
		_mutations[m.id] = {
			"name": m.display_name,
			"desc": m.description,
			"tier": m.tier,
			"branch": ["PREDATOR", "ARMORED", "SWIFT", "HYBRID"][m.branch],
			"stat": m.stat,
			"val": m.modifier_value,
			"mod_type": m.modifier_type,
			"next": m.next_tier_id,
			"era_min": m.era_min,
			"weight": m.weight,
		}
		if not m.extra_mod.is_empty():
			_mutations[m.id]["extra_mod"] = {
				"stat": m.extra_mod.get("stat", ""),
				"val": m.extra_mod.get("val", 0.0),
				"mod_type": m.extra_mod.get("mod_type", StatsResource.ModType.FLAT),
			}

func _ready() -> void:
	EventBus.mutation_ready.connect(_on_mutation_ready)

func _exit_tree() -> void:
	if EventBus.mutation_ready.is_connected(_on_mutation_ready):
		EventBus.mutation_ready.disconnect(_on_mutation_ready)

func _on_mutation_ready() -> void:
	if get_tree().paused:
		return
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var choices = get_random_choices(3)
	if choices.is_empty():
		return
	get_tree().paused = true
	var screen = MutationPickerUIScript.new()
	var vp = get_viewport().get_visible_rect().size
	get_tree().current_scene.add_child(screen)
	screen.show_choices(choices, vp, func(data):
		get_tree().paused = false
		screen.queue_free()
		if data.get("type", "") == "unique":
			apply_part_unique(data, player)
		else:
			apply_mutation(data.get("id", ""))
	)

func get_random_choices(count: int = 3) -> Array[Dictionary]:
	var pool = _get_available()

	var evo_mgr = get_tree().get_first_node_in_group("evolution_manager")
	if evo_mgr and evo_mgr.has_method("get_part_unique_pool"):
		for up in evo_mgr.get_part_unique_pool():
			var entry = {
				"type": "unique",
				"slot_id": up.get("slot_id", ""),
				"effect": up.get("effect", ""),
				"tier": up.get("tier", 1),
				"mods": up.get("mods", []).duplicate(),
				"name": up.get("name", "Unique"),
				"icon": up.get("icon", "✦"),
				"desc": up.get("desc", ""),
				"part_idx": up.get("part_idx", -1),
			}
			pool.append(entry)

	if pool.is_empty():
		return []
	return _weighted_sample(pool, mini(count, pool.size()))

func _weighted_sample(pool: Array[Dictionary], k: int) -> Array[Dictionary]:
	if k >= pool.size():
		pool.shuffle()
		return pool
	var result: Array[Dictionary] = []
	var work = pool.duplicate()
	for _i in range(k):
		var total := 0.0
		for item in work:
			total += item.get("weight", 1.0)
		var roll = randf() * total
		var cum := 0.0
		var idx := 0
		for i in range(work.size()):
			cum += work[i].get("weight", 1.0)
			if roll <= cum:
				idx = i
				break
		result.append(work[idx])
		work.remove_at(idx)
	return result

func _get_available() -> Array[Dictionary]:
	var era = EraManager.era_index
	var result: Array[Dictionary] = []
	var branch_count = {"PREDATOR": 0, "ARMORED": 0, "SWIFT": 0}
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var evo_mgr = get_tree().get_first_node_in_group("evolution_manager")
		if evo_mgr and evo_mgr.has_method("get_equipped_parts"):
			for ep in evo_mgr.get_equipped_parts():
				var part = ep.get("part")
				if part:
					var b = _slot_type_to_branch(part.slot_type)
					if branch_count.has(b):
						branch_count[b] += 1
	for mid in _mutations:
		var m = _mutations[mid]
		if m.get("era_min", 0) > era:
			continue
		if m.tier > 1:
			var prev = _find_prev_tier(m.branch, m.tier)
			if prev == "" or not current_mutations.has(prev):
				continue
		var dup = m.duplicate(true)
		dup["id"] = mid
		var count = branch_count.get(dup["branch"], 0)
		if count > 0:
			dup["weight"] = dup.get("weight", 1.0) * (1.0 + 0.5 * count)
		result.append(dup)
	return result

func _slot_type_to_branch(slot_type: String) -> String:
	match slot_type:
		"armor": return "ARMORED"
		"organ", "muscle", "leg", "wing": return "SWIFT"
		_: return "PREDATOR"

func _find_prev_tier(branch: String, tier: int) -> String:
	for mid in _mutations:
		var m = _mutations[mid]
		if m.branch == branch and m.tier == tier - 1:
			return mid
	return ""

func apply_part_unique(data: Dictionary, player: Node2D) -> void:
	var evo_mgr = get_tree().get_first_node_in_group("evolution_manager")
	if not evo_mgr or not evo_mgr.has_method("apply_unique_from_pool"):
		return
	var part_idx = data.get("part_idx", -1)
	evo_mgr.apply_unique_from_pool(part_idx, player)

func apply_mutation(mutation_id: String) -> void:
	if mutation_id.is_empty() or not _mutations.has(mutation_id):
		return
	current_mutations[mutation_id] = true
	EventBus.mutation_applied.emit(mutation_id)

func get_mutation_data(mid: String) -> Dictionary:
	return _mutations.get(mid, {})

func reset_run() -> void:
	current_mutations.clear()

func get_save_data() -> Dictionary:
	return { "current_mutations": current_mutations.duplicate() }

func restore_from_save(data: Dictionary) -> void:
	current_mutations = data.get("current_mutations", {})
