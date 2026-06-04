extends Node
class_name EvolutionManager

const EvolutionScreenScript = preload("res://ui/EvolutionScreen.gd")
const DB_PATH := "res://data/game_database.tres"

const _FORM_META: Dictionary = {
	"cell": {"desc": "จุดเริ่มต้นของทุกชีวิต — เซลล์โปรคาริโอตในมหาสมุทรยุคแรกเริ่ม", "sprite": "cell"},
	"apex_hunter": {"desc": "วิวัฒนาการแบบลู่เข้า — สัตว์นักล่ายุคแรกจากหลายสายพันธุ์", "sprite": "apex_hunter"},
	"fish": {"desc": "สัตว์มีกระดูกสันหลังชนิดแรก — ปลาไม่มีขากรรไกรยุคแคมเบรียน", "sprite": "fish"},
	"amphibian": {"desc": "เททราโพดยุคแรก — รอยต่อระหว่างปลากับสัตว์บก", "sprite": "amphibian"},
	"arthropod": {"desc": "สัตว์ขาปล้องยุคแคมเบรียน — โครงร่างภายนอกแข็ง ข้อต่อหลายปล้อง", "sprite": "arthropod"},
	"synapsid": {"desc": "สัตว์คล้ายสัตว์เลี้ยงลูกด้วยนมยุคแรก — ใบเรือหลังใหญ่ควบคุมอุณหภูมิ", "sprite": "synapsid"},
	"reptile": {"desc": "สัตว์เลื้อยคลานยุคคาร์บอนิเฟอรัส — ไข่มีเปลือก อิสระจากน้ำ", "sprite": "reptile"},
	"winged_insect": {"desc": "แมลงมีปีกยุคคาร์บอนิเฟอรัส — ปีกช่วยหนี predators และล่า", "sprite": "winged_insect"},
	"cynodont": {"desc": "สัตว์เลื้อยคลานคล้ายสัตว์เลี้ยงลูกด้วยนม — บรรพบุรุษโดยตรงของสัตว์เลี้ยงลูกด้วยนม", "sprite": "cynodont"},
	"primeval_dino": {"desc": "ไดโนเสาร์ยุคแรกเริ่ม — เทอโรพอดขนาดกลาง นักล่าสองขา", "sprite": "primeval_dino"},
	"swarm_lord": {"desc": "จอมแมลงสังคม — อยู่รวมกันเป็นฝูง ล่าและป้องกันร่วมกัน", "sprite": "swarm_lord"},
	"mammal": {"desc": "สัตว์เลี้ยงลูกด้วยนมยุคแรก — เล็ก ออกหากินเวลากลางคืน เลือดอุ่น", "sprite": "mammal"},
	"primate": {"desc": "สัตว์ตระกูลลิง — สมองใหญ่ นิ้วหัวแม่มือตรงข้าม มองเห็นสี", "sprite": "primate"},
	"human": {"desc": "โฮโม เซเปียนส์ — สมองใหญ่ที่สุด เทคนิค ภาษา และวัฒนธรรม", "sprite": "human"},
	"tyrant_king": {"desc": "ไทแรนโนซอรัส เร็กซ์ — นักล่าสูงสุดแห่งยุคครีเทเชียส", "sprite": "tyrant_king"},
	"chitin_beetle": {"desc": "แมลงปีกแข็งยักษ์ — ปีกแข็งหนาป้องกันตัว ค่อยๆ บดขยี้", "sprite": "chitin_beetle"},
	"crab_like": {"desc": "ลูกผสมปลา-แมลง — เกราะแข็ง ก้ามทะลวง", "sprite": "crab_like", "type": "hybrid"},
	"dragon": {"desc": "สัตว์เลื้อยคลานมีปีก — เพลิงผลาญทุกสิ่ง", "sprite": "dragon", "type": "hybrid"},
	"chimera": {"desc": "ลูกผสมไดโนเสาร์-แมลง — หัวสามหัว สามอาวุธ", "sprite": "chimera", "type": "hybrid"},
	"rubber_chicken": {"desc": "ไก่ยางเด้งดึ๋ง — ใครจะไปกลัวไก่ยาง? (เดี๋ยวก็รู้)", "sprite": "rubber_chicken", "type": "wtf"},
	"roomba_lord": {"desc": "หุ่นดูดฝุ่นครองโลก — ดูดทุกอย่างที่ขวางหน้า", "sprite": "roomba_lord", "type": "wtf"},
	"t_pose_tyrant": {"desc": "ไดโนเสาร์ T-Pose — ข่มขวัญจนศัตรูสั่น", "sprite": "t_pose_tyrant", "type": "wtf"},
}

var current_form_id: String = "cell"
var _evolution_path: Array[String] = ["cell"]
var _tree: Dictionary = {}
var _hybrid_recipes: Dictionary = {}
var _wtf_unlocked: Dictionary = {}
var _wtf_progress: Dictionary = {}

func _init() -> void:
	_load_from_database()

func _load_from_database() -> void:
	var db = load(DB_PATH) as GameDatabase
	if not db:
		push_error("EvolutionManager: failed to load game_database.tres")
		return

	_tree.clear()
	for form_data in db.forms:
		var ed = form_data as EvolutionData
		if not ed:
			continue
		var meta = _FORM_META.get(ed.id, {})
		_tree[ed.id] = {
			"name": ed.display_name,
			"desc": meta.get("desc", ed.description),
			"stats": ed.base_stats.duplicate(),
			"color": ed.color,
			"size": ed.size,
			"weapon": ed.weapon,
			"sprite": meta.get("sprite", ed.sprite_id),
			"tags": ed.tags.duplicate(),
			"type": meta.get("type", ed.evolution_type),
			"next": ed.next_evolution_ids.duplicate(),
		}

	_hybrid_recipes.clear()
	for recipe_data in db.hybrid_recipes:
		var hr = recipe_data as HybridRecipe
		if not hr:
			continue
		_hybrid_recipes[hr.id] = {
			"parents": hr.parent_ids.duplicate(),
			"result_id": hr.result_form_id,
			"era_min": hr.era_min,
		}

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
		return

	get_tree().paused = true
	_show_evolution_screen(choices, player)

func _show_evolution_screen(choices: Array[Dictionary], player: Player) -> void:
	var screen = EvolutionScreenScript.new()
	var viewport = get_viewport().get_visible_rect().size
	get_tree().current_scene.add_child(screen)
	screen.show_choices(choices, viewport, func(data): _on_choice_made(data, player))

func _on_choice_made(data: Dictionary, player: Player) -> void:
	var form_id = data.get("id", current_form_id)
	var data_type = data.get("type", "form")
	_evolution_path.append(form_id)
	current_form_id = form_id
	SaveManager.unlock_form(form_id)
	player.apply_form(data, true)
	EventBus.evolution_chosen.emit(current_form_id)
	if data_type == "hybrid":
		EventBus.hybrid_unlocked.emit(form_id)
	get_tree().paused = false

var _boss_killed_no_damage: bool = true

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

func get_save_data() -> Dictionary:
	return {
		"current_form_id": current_form_id,
		"evolution_path": _evolution_path.duplicate(),
		"wtf_progress": _wtf_progress.duplicate(),
		"boss_killed_no_damage": _boss_killed_no_damage,
	}

func restore_from_save(data: Dictionary) -> void:
	current_form_id = data.get("current_form_id", "cell")
	_evolution_path = data.get("evolution_path", ["cell"])
	_wtf_progress = data.get("wtf_progress", {})
	_boss_killed_no_damage = data.get("boss_killed_no_damage", true)

func get_current_form() -> Dictionary:
	return _tree.get(current_form_id, _tree.get("cell", {}))

func get_evolution_path() -> Array[String]:
	return _evolution_path.duplicate()

func get_hybrid_recipes() -> Dictionary:
	return _hybrid_recipes.duplicate(true)

func _get_hybrid_choices(form: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var era = EraManager.era_index

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
	var result: Array[Dictionary] = []

	for next_id in form.get("next", []):
		var f = _tree.get(next_id)
		if f:
			var dup = f.duplicate(true)
			dup["id"] = next_id
			result.append(dup)

	for recipe in _get_hybrid_choices(form):
		result.append(recipe)

	for wtf in _get_wtf_choices():
		result.append(wtf)

	result.shuffle()
	return result
