extends Node

var dna_total: int = 0
var dna_balance: int = 0
var upgrades: Dictionary = {}
var start_forms: Dictionary = {}
var active_title: String = ""

const TRAITS: Dictionary = {
	"hardened_membrane": {"name": "Hardened Membrane", "desc": "+5% Max HP / level", "stat": "max_hp", "val": 0.05, "max_lv": 5, "cost_b": 100, "cost_m": 2.0},
	"efficient_mito": {"name": "Efficient Mitochondria", "desc": "+3% Move Speed / level", "stat": "speed", "val": 0.03, "max_lv": 5, "cost_b": 100, "cost_m": 2.0},
	"sharpened_genes": {"name": "Sharpened Genes", "desc": "+5% Damage / level", "stat": "damage", "val": 0.05, "max_lv": 5, "cost_b": 100, "cost_m": 2.0},
	"rapid_division": {"name": "Rapid Division", "desc": "-3% Fire Cooldown / level", "stat": "fire_cooldown", "val": -0.03, "max_lv": 5, "cost_b": 100, "cost_m": 2.0},
}
const STARTERS: Dictionary = {
	"head_start": {"name": "Head Start", "desc": "Start with GP", "vals": [50, 100, 150], "max_lv": 3, "cost_b": 300, "cost_m": 2.0},
	"lucky_mutation": {"name": "Lucky Mutation", "desc": "Rerolls per run", "vals": [1, 2, 3], "max_lv": 3, "cost_b": 400, "cost_m": 2.0},
	"genetic_momentum": {"name": "Genetic Momentum", "desc": "+GP gain %", "vals": [10, 20, 30], "max_lv": 3, "cost_b": 500, "cost_m": 2.0},
	"second_chance": {"name": "Second Chance", "desc": "Revive 1x/run at HP%", "vals": [25, 50, 75], "max_lv": 3, "cost_b": 1000, "cost_m": 2.0},
}
const LEGACY: Dictionary = {
	"fish": {"name": "Start as Fish", "desc": "Begin as Ancient Fish", "cost": 500},
	"arthropod": {"name": "Start as Arthropod", "desc": "Begin as Early Arthropod", "cost": 800},
	"amphibian": {"name": "Start as Amphibian", "desc": "Begin as Primitive Amphibian", "cost": 1000},
	"synapsid": {"name": "Start as Synapsid", "desc": "Begin as Pelycosaur", "cost": 1200},
	"apex_hunter": {"name": "Start as Apex Hunter", "desc": "Begin as Convergent Predator", "cost": 1500},
}
const WTF_SHORTCUTS: Dictionary = {
	"rubber_shortcut": {"name": "Rubber Chicken Edge", "desc": "Kill requirement -10/level", "max_lv": 3, "cost_b": 400, "cost_m": 2.0},
	"roomba_shortcut": {"name": "Roomba Lord Edge", "desc": "GP requirement -100/level", "max_lv": 3, "cost_b": 400, "cost_m": 2.0},
	"tyrant_shortcut": {"name": "T-Pose Tyrant Edge", "desc": "Hit tolerance +1/level", "max_lv": 3, "cost_b": 600, "cost_m": 2.0},
}
const TITLES: Array[Dictionary] = [
	{"id": "prokaryote", "name": "Prokaryote", "dna": 0},
	{"id": "eukaryote", "name": "Eukaryote", "dna": 1000},
	{"id": "multicellular", "name": "Multicellular", "dna": 5000},
	{"id": "cambrian_survivor", "name": "Cambrian Survivor", "dna": 15000},
	{"id": "apex_predator", "name": "Apex Predator", "dna": 50000},
	{"id": "whatif_being", "name": "What-If Being", "dna": 150000},
	{"id": "transcendent", "name": "Transcendent", "dna": 500000},
]

func _ready() -> void:
	load_meta()

func load_meta() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://battle_cell.cfg") != OK:
		return
	if cfg.has_section_key("meta", "dna_total"):
		dna_total = cfg.get_value("meta", "dna_total", 0)
	if cfg.has_section_key("meta", "dna_balance"):
		dna_balance = cfg.get_value("meta", "dna_balance", 0)
	if cfg.has_section_key("meta", "upgrades"):
		var raw = cfg.get_value("meta", "upgrades", {})
		if raw is Dictionary:
			upgrades = raw
	if cfg.has_section_key("meta", "start_forms"):
		var raw2 = cfg.get_value("meta", "start_forms", {})
		if raw2 is Dictionary:
			start_forms = raw2
	if cfg.has_section_key("meta", "active_title"):
		active_title = cfg.get_value("meta", "active_title", "")

func save_meta() -> void:
	var cfg = ConfigFile.new()
	cfg.load("user://battle_cell.cfg")
	cfg.set_value("meta", "dna_total", dna_total)
	cfg.set_value("meta", "dna_balance", dna_balance)
	cfg.set_value("meta", "upgrades", upgrades)
	cfg.set_value("meta", "start_forms", start_forms)
	cfg.set_value("meta", "active_title", active_title)
	cfg.save("user://battle_cell.cfg")

func add_dna(amount: int) -> void:
	if amount <= 0:
		return
	dna_total += amount
	dna_balance += amount
	_update_titles()
	save_meta()

func spend_dna(amount: int) -> bool:
	if dna_balance < amount:
		return false
	dna_balance -= amount
	save_meta()
	return true

func get_upgrade_level(up_id: String) -> int:
	return upgrades.get(up_id, 0)

func get_upgrade_cost(up_id: String, defs: Dictionary) -> int:
	var lv = get_upgrade_level(up_id)
	var d = defs.get(up_id, {})
	var max_lv = d.get("max_lv", 1)
	if lv >= max_lv:
		return -1
	return ceili(d.get("cost_b", 100) * pow(d.get("cost_m", 2.0), lv))

func purchase_upgrade(up_id: String, defs: Dictionary) -> bool:
	var cost = get_upgrade_cost(up_id, defs)
	if cost < 0:
		return false
	if not spend_dna(cost):
		return false
	var lv = get_upgrade_level(up_id) + 1
	upgrades[up_id] = lv
	if defs == LEGACY:
		start_forms[up_id] = true
	save_meta()
	return true

func purchase_legacy(form_id: String) -> bool:
	var d = LEGACY.get(form_id)
	if not d:
		return false
	if start_forms.has(form_id):
		return false
	var cost = d.get("cost", 500)
	if not spend_dna(cost):
		return false
	start_forms[form_id] = true
	save_meta()
	return true

func is_legacy_unlocked(form_id: String) -> bool:
	return start_forms.has(form_id)

func get_title_for_dna() -> String:
	var best = "prokaryote"
	for t in TITLES:
		if dna_total >= t.dna:
			best = t.id
	return best

func _update_titles() -> void:
	var tid = get_title_for_dna()
	if active_title.is_empty():
		active_title = tid

func get_title_name(tid: String) -> String:
	for t in TITLES:
		if t.id == tid:
			return t.name
	return ""

func has_title(tid: String) -> bool:
	return dna_total >= _get_title_dna(tid)

func _get_title_dna(tid: String) -> int:
	for t in TITLES:
		if t.id == tid:
			return t.dna
	return 999999

func get_first_wtf_needed_lv(up_id: String) -> int:
	match up_id:
		"rubber_shortcut": return 10 * (3 - get_upgrade_level(up_id))
		"roomba_shortcut": return 100 * (3 - get_upgrade_level(up_id))
		"tyrant_shortcut": return get_upgrade_level(up_id)
	return 0

func get_head_start_gp() -> int:
	var lv = get_upgrade_level("head_start")
	return STARTERS.head_start.vals[lv - 1] if lv > 0 else 0

func get_rerolls() -> int:
	var lv = get_upgrade_level("lucky_mutation")
	return STARTERS.lucky_mutation.vals[lv - 1] if lv > 0 else 0

func get_gp_multiplier() -> float:
	var lv = get_upgrade_level("genetic_momentum")
	return 1.0 + (STARTERS.genetic_momentum.vals[lv - 1] if lv > 0 else 0) / 100.0

func has_second_chance() -> bool:
	return get_upgrade_level("second_chance") > 0

func get_second_chance_hp() -> int:
	var lv = get_upgrade_level("second_chance")
	return STARTERS.second_chance.vals[lv - 1] if lv > 0 else 0
