extends Node
class_name EvolutionManager

const EvolutionScreenScript = preload("res://ui/EvolutionScreen.gd")
const FormPartConfigScript = preload("res://data/FormPartConfig.gd")
const DB_PATH := "res://data/game_database.tres"

const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS := {
	0: Color(0.7, 0.7, 0.7),
	1: Color(0.2, 0.9, 0.2),
	2: Color(0.2, 0.5, 1.0),
	3: Color(0.7, 0.2, 1.0),
	4: Color(1.0, 0.7, 0.1),
}
const RARITY_MULT := [1.0, 1.4, 2.0, 3.0, 5.0]
const RARITY_CHANCES := [0.50, 0.30, 0.14, 0.05, 0.01]

const PART_UNIQUES := {
	"spike_tail": {
		"name": "หนามแหลม",
		"icon": "⚔",
		"effect": "double_attack",
		"tiers": [
			{"desc": "Double attack 20%", "mods": []},
			{"desc": "Double attack 35%", "mods": []},
			{"desc": "Double attack 50%", "mods": []},
		]
	},
	"stinger": {
		"name": "ทะลวง",
		"icon": "🗡",
		"effect": "range_up",
		"tiers": [
			{"desc": "+15% Range", "mods": [{"stat": "range", "val": 0.15, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "+30% Range", "mods": [{"stat": "range", "val": 0.30, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "+50% Range", "mods": [{"stat": "range", "val": 0.50, "type": StatsResource.ModType.PERCENT}]},
		]
	},
	"pincer": {
		"name": "บดขยี้",
		"icon": "🦀",
		"effect": "break",
		"tiers": [
			{"desc": "Break +10% dmg 3s", "mods": []},
			{"desc": "Break +20% dmg 3s", "mods": []},
			{"desc": "Break +35% dmg 3s", "mods": []},
		]
	},
	"crushing_jaw": {
		"name": "ตะกละ",
		"icon": "🦷",
		"effect": "lifesteal",
		"tiers": [
			{"desc": "Lifesteal 5%", "mods": []},
			{"desc": "Lifesteal 10%", "mods": []},
			{"desc": "Lifesteal 18%", "mods": []},
		]
	},
	"barbed_tentacle": {
		"name": "หนามขา",
		"icon": "🦵",
		"effect": "pull",
		"tiers": [
			{"desc": "Pull ระยะใกล้", "mods": []},
			{"desc": "Pull ระยะกลาง", "mods": []},
			{"desc": "Pull ระยะไกล", "mods": []},
		]
	},
	"radiant_eye": {
		"name": "สะกด",
		"icon": "👁",
		"effect": "stun",
		"tiers": [
			{"desc": "Stun 0.5s 15%", "mods": []},
			{"desc": "Stun 0.5s 30%", "mods": []},
			{"desc": "Stun 0.5s 50%", "mods": []},
		]
	},
	"venom_gland": {
		"name": "ต่อมพิษ",
		"icon": "☠",
		"effect": "venom_trail",
		"tiers": [
			{"desc": "Venom 5 dmg/s 3s", "mods": []},
			{"desc": "Venom 10 dmg/s 3s", "mods": []},
			{"desc": "Venom 18 dmg/s 3s", "mods": []},
		]
	},
	"armor_plate": {
		"name": "เกราะหนา",
		"icon": "🛡",
		"effect": "deflect",
		"tiers": [
			{"desc": "Deflect 8% dmg", "mods": [{"stat": "armor", "val": 2, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Deflect 15% dmg", "mods": [{"stat": "armor", "val": 4, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Deflect 25% dmg", "mods": [{"stat": "armor", "val": 6, "type": StatsResource.ModType.FLAT}]},
		]
	},
	"speed_gland": {
		"name": "วายุ",
		"icon": "💨",
		"effect": "haste",
		"tiers": [
			{"desc": "Haste +10% move 3s", "mods": [{"stat": "speed", "val": 0.10, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Haste +20% move 3s", "mods": [{"stat": "speed", "val": 0.20, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Haste +35% move 3s", "mods": [{"stat": "speed", "val": 0.35, "type": StatsResource.ModType.PERCENT}]},
		]
	},
	"venom_sac": {
		"name": "พิษร้าย",
		"icon": "☠",
		"effect": "poison_cloud",
		"tiers": [
			{"desc": "Poison cloud 8 dmg/s", "mods": [{"stat": "damage", "val": 3, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Poison cloud 14 dmg/s", "mods": [{"stat": "damage", "val": 6, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Poison cloud 22 dmg/s", "mods": [{"stat": "damage", "val": 10, "type": StatsResource.ModType.FLAT}]},
		]
	},
	"quick_fiber": {
		"name": "ไวไฟ",
		"icon": "⚡",
		"effect": "overclock",
		"tiers": [
			{"desc": "Overclock +15% atk spd", "mods": [{"stat": "fire_cooldown", "val": -0.08, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Overclock +25% atk spd", "mods": [{"stat": "fire_cooldown", "val": -0.15, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Overclock +40% atk spd", "mods": [{"stat": "fire_cooldown", "val": -0.22, "type": StatsResource.ModType.PERCENT}]},
		]
	},
	"shell": {
		"name": "กระดอง",
		"icon": "🐢",
		"effect": "turtle",
		"tiers": [
			{"desc": "Turtle +15% armor", "mods": [{"stat": "armor", "val": 1, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Turtle +25% armor", "mods": [{"stat": "armor", "val": 2, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Turtle +40% armor", "mods": [{"stat": "armor", "val": 3, "type": StatsResource.ModType.FLAT}]},
		]
	},
	"hydro_jet": {
		"name": "น้ำพุ",
		"icon": "🌊",
		"effect": "knockback",
		"tiers": [
			{"desc": "Knockback 100 force", "mods": [{"stat": "damage", "val": 2, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Knockback 180 force", "mods": [{"stat": "damage", "val": 5, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Knockback 300 force", "mods": [{"stat": "damage", "val": 9, "type": StatsResource.ModType.FLAT}]},
		]
	},
	"charge_cell": {
		"name": "ประจุ",
		"icon": "⚡",
		"effect": "overcharge",
		"tiers": [
			{"desc": "Overcharge +12% dmg", "mods": [{"stat": "damage", "val": 0.12, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Overcharge +20% dmg", "mods": [{"stat": "damage", "val": 0.20, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Overcharge +35% dmg", "mods": [{"stat": "damage", "val": 0.35, "type": StatsResource.ModType.PERCENT}]},
		]
	},
	"dragon_maw": {
		"name": "เพลิง",
		"icon": "🔥",
		"effect": "burn",
		"tiers": [
			{"desc": "Burn 5 dmg/s 3s", "mods": [{"stat": "damage", "val": 4, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Burn 10 dmg/s 3s", "mods": [{"stat": "damage", "val": 8, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Burn 18 dmg/s 3s", "mods": [{"stat": "damage", "val": 14, "type": StatsResource.ModType.FLAT}]},
		]
	},
	"psychic_node": {
		"name": "จิตพิสัย",
		"icon": "🧠",
		"effect": "psi_boost",
		"tiers": [
			{"desc": "Psi +15% range", "mods": [{"stat": "range", "val": 0.15, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Psi +30% range", "mods": [{"stat": "range", "val": 0.30, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Psi +50% range", "mods": [{"stat": "range", "val": 0.50, "type": StatsResource.ModType.PERCENT}]},
		]
	},
	"chaos_eye": {
		"name": "อลวน",
		"icon": "🌀",
		"effect": "chaos",
		"tiers": [
			{"desc": "Chaos +10% dmg", "mods": [{"stat": "damage", "val": 0.10, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Chaos +20% dmg", "mods": [{"stat": "damage", "val": 0.20, "type": StatsResource.ModType.PERCENT}]},
			{"desc": "Chaos +35% dmg", "mods": [{"stat": "damage", "val": 0.35, "type": StatsResource.ModType.PERCENT}]},
		]
	},
	"bouncy_chitin": {
		"name": "เด้ง",
		"icon": "🔵",
		"effect": "ricochet",
		"tiers": [
			{"desc": "Ricochet +1 bounce", "mods": [{"stat": "armor", "val": 1, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Ricochet +2 bounce", "mods": [{"stat": "armor", "val": 2, "type": StatsResource.ModType.FLAT}]},
			{"desc": "Ricochet +3 bounce", "mods": [{"stat": "armor", "val": 3, "type": StatsResource.ModType.FLAT}]},
		]
	},
}

const PART_CATEGORIES: Dictionary = {
	"spike_tail": "attack",
	"stinger": "attack",
	"pincer": "attack",
	"crushing_jaw": "attack",
	"barbed_tentacle": "mobility",
	"radiant_eye": "attack",
	"venom_gland": "defense",
	"armor_plate": "defense",
	"speed_gland": "mobility",
	"venom_sac": "attack",
	"quick_fiber": "mobility",
	"shell": "defense",
	"hydro_jet": "attack",
	"charge_cell": "attack",
	"dragon_maw": "attack",
	"psychic_node": "attack",
	"chaos_eye": "attack",
	"bouncy_chitin": "defense",
}

const PART_COMMON_MUTATIONS: Dictionary = {
	"attack": [
		{"id": "atk_spd", "name": "รัว", "desc": "atk speed +8%", "stat": "fire_cooldown", "val": -0.08, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "atk_dmg", "name": "หนัก", "desc": "atk damage +8%", "stat": "damage", "val": 0.08, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "range_up", "name": "ไกล", "desc": "range +10%", "stat": "range", "val": 0.10, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "proj_spd", "name": "เร็ว", "desc": "projectile speed +15%", "stat": "projectile_speed", "val": 0.15, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "gp_mult", "name": "รวย", "desc": "GP +25%", "stat": "gp_mult", "val": 0.25, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "gp_range", "name": "ดูด", "desc": "GP collect range +40", "stat": "collect_range", "val": 40, "mod_type": StatsResource.ModType.FLAT},
	],
	"mobility": [
		{"id": "move_spd", "name": "ว่องไว", "desc": "move speed +8%", "stat": "speed", "val": 0.08, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "dodge_cd", "name": "คล่อง", "desc": "dodge CD -0.15s", "stat": "dodge_cooldown", "val": -0.15, "mod_type": StatsResource.ModType.FLAT},
		{"id": "dash_spd", "name": "พุ่ง", "desc": "dodge CD -8%", "stat": "dodge_cooldown", "val": -0.08, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "gp_mult", "name": "รวย", "desc": "GP +25%", "stat": "gp_mult", "val": 0.25, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "gp_range", "name": "ดูด", "desc": "GP collect range +40", "stat": "collect_range", "val": 40, "mod_type": StatsResource.ModType.FLAT},
	],
	"defense": [
		{"id": "hp_up", "name": "ทนทาน", "desc": "max HP +20", "stat": "max_hp", "val": 20, "mod_type": StatsResource.ModType.FLAT},
		{"id": "armor_up", "name": "แข็ง", "desc": "armor +2", "stat": "armor", "val": 2, "mod_type": StatsResource.ModType.FLAT},
		{"id": "hp_pct", "name": "ใหญ่", "desc": "max HP +12%", "stat": "max_hp", "val": 0.12, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "armor_pct", "name": "เกราะ", "desc": "armor +15%", "stat": "armor", "val": 0.15, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "gp_mult", "name": "รวย", "desc": "GP +25%", "stat": "gp_mult", "val": 0.25, "mod_type": StatsResource.ModType.PERCENT},
		{"id": "gp_range", "name": "ดูด", "desc": "GP collect range +40", "stat": "collect_range", "val": 40, "mod_type": StatsResource.ModType.FLAT},
	],
}

const _FORM_META: Dictionary = {
	"cell": {"desc": "จุดเริ่มต้นของทุกชีวิต — เซลล์โปรคาริโอตในมหาสมุทรยุคแรกเริ่ม", "sprite": "cell"},
	"dunkleosteus": {"desc": "ปลาเกราะยักษ์ยุคดีโวเนียน — ขากรรไกรเหล็กบดขยี้ทุกสิ่ง", "sprite": "dunkleosteus"},
	"tiktaalik": {"desc": "ปลาครึ่งบกครึ่งน้ำยุคดีโวเนียน — ก้าวแรกของสัตว์สี่ขาสู่แผ่นดิน", "sprite": "tiktaalik"},
	"scutosaurus": {"desc": "กิ้งก่าโล่ยุคเพอร์เมียน — สัตว์เลื้อยคลานหุ้มเกราะชนิดแรกของโลก", "sprite": "scutosaurus", "require": {"slots": ["tail", "armor", "leg"], "min": 2, "path_req": "dunkleosteus", "era_min": 1}},
	"stegosaurus": {"desc": "ไดโนเสาร์เกราะหลังหนามยุคจูราสสิค — เกราะธรรมชาติที่แข็งแกร่งที่สุด", "sprite": "stegosaurus", "require": {"slots": ["tail", "armor", "leg", "head"], "min": 3, "path_req": "scutosaurus", "era_min": 2}},
	"hylonomus": {"desc": "สัตว์เลื้อยคลานแรกเริ่มยุคคาร์บอนิเฟอรัส — เล็ก ว่องไว ไข่มีเปลือก", "sprite": "hylonomus", "require": {"slots": ["tail", "leg", "head"], "min": 2, "path_req": "tiktaalik", "era_min": 1}},
	"coelophysis": {"desc": "ไดโนเสาร์นักล่ายุคไทรแอสซิก — ปราดเปรียว ล่าเป็นฝูง", "sprite": "coelophysis", "require": {"slots": ["tail", "mouth", "leg"], "min": 2, "path_req": "hylonomus", "era_min": 1}},
	"allosaurus": {"desc": "นักล่าจูราสสิค — เขี้ยวเล็บสังหาร จ่าโดน", "sprite": "allosaurus", "require": {"slots": ["tail", "mouth", "leg", "head"], "min": 3, "path_req": "coelophysis", "era_min": 2}},
}

var current_form_id: String = "cell"
var _evolution_path: Array[String] = ["cell"]
var _tree: Dictionary = {}
var _wtf_unlocked: Dictionary = {}
var _wtf_progress: Dictionary = {}
var _part_slots_used: int = 0
var _equipped_parts: Array[Dictionary] = []
var _part_unique_pool: Array[Dictionary] = []

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
			push_error("[EvolutionManager] _load_from_database: corrupt form data in db.forms")
			continue
		var meta = _FORM_META.get(ed.id, {})
		var parts_arr = ed.parts
		if parts_arr.is_empty():
			parts_arr = _get_default_parts(ed.id)
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
			"parts": parts_arr,
			"evo_min": ed.evo_min,
		}


func _ready() -> void:
	add_to_group("evolution_manager")
	EventBus.evolution_ready.connect(_on_evolution_ready)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.gp_collected.connect(_on_gp_collected)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.boss_killed.connect(_on_boss_killed)
	EventBus.mini_boss_killed.connect(_on_mini_boss_killed)

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
	if EventBus.mini_boss_killed.is_connected(_on_mini_boss_killed):
		EventBus.mini_boss_killed.disconnect(_on_mini_boss_killed)

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
	_part_slots_used = 0
	_equipped_parts.clear()
	_part_unique_pool.clear()

func _on_evolution_ready() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		push_error("[EvolutionManager] _on_evolution_ready: player node not found")
		return

	var choices = _get_choices()
	if choices.is_empty():
		push_error("[EvolutionManager] _get_choices returned empty! Forcing stay")
		var form = get_current_form()
		var stay = form.duplicate(true) if not form.is_empty() else {}
		stay["id"] = current_form_id
		stay["name"] = "อยู่ต่อ"
		stay["desc"] = "อยู่ต่อ (forced fallback)"
		choices = [stay]

	get_tree().paused = true
	_show_evolution_screen(choices, player)

func _show_evolution_screen(choices: Array[Dictionary], player: Player) -> void:
	var screen = EvolutionScreenScript.new()
	var viewport = get_viewport().get_visible_rect().size
	get_tree().current_scene.add_child(screen)
	screen.show_choices(choices, viewport, func(data): _on_choice_made(data, player))

func _on_choice_made(data: Dictionary, player: Player) -> void:
	var data_type = data.get("type", "form")

	if data_type == "unique":
		var ud = data.get("unique_data", {})
		var part_idx = ud.get("part_idx", -1)
		if part_idx >= 0 and part_idx < _equipped_parts.size():
			_equipped_parts[part_idx]["unique_applied"] = true
			for um in ud.get("mods", []):
				var um_stat = um.get("stat", "")
				var um_val = um.get("val", 0.0)
				var um_type = um.get("type", StatsResource.ModType.FLAT)
				player.stats.add_modifier_raw(um_stat, um_val, um_type, "part_unique")
			player.refresh_from_stats()
		_part_unique_pool.erase(ud)
		print("=== UNIQUE UPGRADE applied: ", ud.get("name", ""))
		get_tree().paused = false
		return

	var form_id = data.get("id", current_form_id)
	_evolution_path.append(form_id)
	current_form_id = form_id
	SaveManager.unlock_form(form_id)
	print("=== EVOLUTION: applying form=", form_id, " equipped_parts=", _equipped_parts.size())
	for ei in _equipped_parts.size():
		var ep = _equipped_parts[ei]
		var pcfg = ep.get("part") as FormPartConfig
		print("  equipped[", ei, "] id=", pcfg.slot_id, " weapon=", pcfg.weapon_behavior_id)
	player.apply_form(data, true)
	print("  AFTER apply_form: behaviors=", player.weapon.behaviors.size())
	_reapply_equipped_parts(player)
	print("  AFTER reapply: behaviors=", player.weapon.behaviors.size())
	for i in player.weapon.behaviors.size():
		var b = player.weapon.behaviors[i]
		var sname = ""
		var scr = b.get_script()
		if scr: sname = scr.get_global_name()
		print("    behavior[", i, "] = ", sname)
	EventBus.evolution_chosen.emit(current_form_id)
	if data_type == "hybrid":
		EventBus.hybrid_unlocked.emit(form_id)
	get_tree().paused = false

var _boss_killed_no_damage: bool = true

func _get_max_part_slots(era: int) -> int:
	match era:
		0: return 2
		1: return 4
		_: return 6

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
	var current_form = get_current_form()
	var part_data: Array[Dictionary] = []
	for entry in _equipped_parts:
		var p: FormPartConfig = entry.get("part")
		part_data.append({
			"slot_id": p.slot_id,
			"slot_type": p.slot_type,
			"weapon_behavior_id": p.weapon_behavior_id,
			"weapon_cooldown": p.weapon_cooldown,
			"stat_mods": p.stat_mods.duplicate(),
			"draw_type": p.draw_type,
			"draw_params": p.draw_params.duplicate(),
			"pos_x": p.position.x,
			"pos_y": p.position.y,
			"color_r": p.color.r8,
			"color_g": p.color.g8,
			"color_b": p.color.b8,
			"color_a": p.color.a8,
			"rarity": entry.get("rarity", 0),
			"unique_mods": entry.get("unique_mods", []).duplicate(),
			"unique_effect": entry.get("unique_effect", ""),
			"unique_tier": entry.get("unique_tier", 1),
			"unique_applied": entry.get("unique_applied", false),
			"common_mutation": entry.get("common_mutation", {}).duplicate(),
		})
	var pool_data: Array[Dictionary] = []
	for pu in _part_unique_pool:
		pool_data.append(pu.duplicate(true))
	return {
		"current_form_id": current_form_id,
		"evolution_path": _evolution_path.duplicate(),
		"wtf_progress": _wtf_progress.duplicate(),
		"boss_killed_no_damage": _boss_killed_no_damage,
		"part_slots_used": _part_slots_used,
		"weapon_id": current_form.get("weapon", "aimed_shot"),
		"form_stats": current_form.get("stats", {}).duplicate(),
		"equipped_parts": part_data,
		"part_unique_pool": pool_data,
	}

func restore_from_save(data: Dictionary) -> Dictionary:
	current_form_id = data.get("current_form_id", "cell")
	_evolution_path = data.get("evolution_path", ["cell"])
	print("  [EvolutionManager] restore_from_save: form_id=", current_form_id, " path=", _evolution_path)
	print("  [EvolutionManager] tree has '", current_form_id, "' = ", _tree.has(current_form_id))
	if _tree.has(current_form_id):
		print("  [EvolutionManager] form weapon = ", _tree[current_form_id].get("weapon", "?"))
	_log("EVO_RESTORE form_id=" + current_form_id + " path=" + str(_evolution_path) + " tree_has=" + str(_tree.has(current_form_id)))
	_wtf_progress = data.get("wtf_progress", {})
	_boss_killed_no_damage = data.get("boss_killed_no_damage", true)
	_part_slots_used = data.get("part_slots_used", 0)
	_equipped_parts.clear()
	for pd in data.get("equipped_parts", []):
		var cfg = FormPartConfigScript.new()
		cfg.slot_id = pd.get("slot_id", "")
		cfg.slot_type = pd.get("slot_type", "body")
		cfg.draw_type = pd.get("draw_type", "circle")
		cfg.draw_params = pd.get("draw_params", {}).duplicate(true)
		cfg.position = Vector2(pd.get("pos_x", 0.0), pd.get("pos_y", 0.0))
		cfg.color = Color8(pd.get("color_r", 255), pd.get("color_g", 255), pd.get("color_b", 255), pd.get("color_a", 255))
		cfg.weapon_behavior_id = pd.get("weapon_behavior_id", "")
		cfg.weapon_cooldown = pd.get("weapon_cooldown", 0.0)
		cfg.stat_mods = pd.get("stat_mods", []).duplicate(true)
		_equipped_parts.append({
			"part": cfg,
			"rarity": pd.get("rarity", 0),
			"unique_mods": pd.get("unique_mods", []).duplicate(true),
			"unique_effect": pd.get("unique_effect", ""),
			"unique_tier": pd.get("unique_tier", 1),
			"unique_applied": pd.get("unique_applied", false),
			"common_mutation": pd.get("common_mutation", {}).duplicate(true),
		})
	_part_unique_pool = data.get("part_unique_pool", []).duplicate(true)
	return {
		"weapon_id": data.get("weapon_id", ""),
		"form_stats": data.get("form_stats", {}),
	}

func get_current_form() -> Dictionary:
	return _tree.get(current_form_id, _tree.get("cell", {}))

func get_part_unique_pool() -> Array[Dictionary]:
	return _part_unique_pool

func apply_unique_from_pool(pool_idx: int, player: Node2D) -> void:
	if pool_idx < 0 or pool_idx >= _part_unique_pool.size():
		return
	var ud = _part_unique_pool[pool_idx]
	var part_idx = ud.get("part_idx", -1)
	if part_idx >= 0 and part_idx < _equipped_parts.size():
		_equipped_parts[part_idx]["unique_applied"] = true
		for um in ud.get("mods", []):
			var um_stat = um.get("stat", "")
			var um_val = um.get("val", 0.0)
			var um_type = um.get("type", StatsResource.ModType.FLAT)
			player.stats.add_modifier_raw(um_stat, um_val, um_type, "part_unique")
		player.refresh_from_stats()
	var effect = ud.get("effect", "")
	var behavior_id = ""
	part_idx = ud.get("part_idx", -1)
	if part_idx >= 0 and part_idx < _equipped_parts.size():
		var pcfg = _equipped_parts[part_idx].get("part") as FormPartConfig
		if pcfg:
			behavior_id = pcfg.weapon_behavior_id
	if effect != "":
		EventBus.part_unique_activated.emit(effect, ud.get("tier", 1), behavior_id)
	_part_unique_pool.remove_at(pool_idx)
	print("=== UNIQUE UPGRADE applied: ", ud.get("name", ""))

func get_evolution_path() -> Array[String]:
	return _evolution_path.duplicate()

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
	var equipped_slots = _get_equipped_slot_types()
	var pool: Array[Dictionary] = []

	for next_id in form.get("next", []):
		var f = _tree.get(next_id)
		if not f:
			push_error("[EvolutionManager] _get_choices: form '" + next_id + "' not found in _tree")
			continue
		var meta = _FORM_META.get(next_id, {})
		if not _check_requirement(meta.get("require", {}), equipped_slots, f):
			continue
		var dup = f.duplicate(true)
		dup["id"] = next_id
		pool.append(dup)

	for wtf in _get_wtf_choices():
		pool.append(wtf)

	if pool.is_empty():
		var stay = form.duplicate(true)
		stay["id"] = current_form_id
		stay["name"] = "อยู่ต่อ"
		stay["desc"] = "ยังไม่พร้อมวิวัฒนาการ — สะสมพาร์ทให้มากขึ้น"
		pool.append(stay)

	pool.shuffle()
	return pool.slice(0, 3)

func _check_requirement(require: Dictionary, equipped_slots: Array[String], form_data: Dictionary = {}) -> bool:
	if require.is_empty() and form_data.is_empty():
		return true
	var slots: Array = require.get("slots", [])
	var min_count = require.get("min", slots.size())
	var matched = 0
	for s in slots:
		if s in equipped_slots:
			matched += 1
	if matched < min_count:
		return false
	if require.has("era_min") and EraManager.era_index < require["era_min"]:
		return false
	if require.has("path_req") and not require["path_req"] in _evolution_path:
		return false
	var evo_min = form_data.get("evo_min", 0)
	if evo_min > 0 and _evolution_path.size() - 1 < evo_min:
		return false
	return true

func _get_equipped_slot_types() -> Array[String]:
	var slots: Array[String] = []
	for entry in _equipped_parts:
		var p: FormPartConfig = entry.get("part")
		if p and p.slot_type not in slots:
			slots.append(p.slot_type)
	return slots

func _get_default_parts(form_id: String) -> Array:
	var p = func(slot_type, slot_id, draw_type, pos, clr, params = {}):
		var cfg = FormPartConfigScript.new()
		cfg.slot_id = slot_id
		cfg.slot_type = slot_type
		cfg.draw_type = draw_type
		cfg.position = pos
		cfg.color = clr
		cfg.draw_params = params
		return cfg

	match form_id:
		"cell":
			return [p.call("body", "body", "circle", Vector2.ZERO, Color(0.3, 0.8, 0.3), {"radius": 16})]
		"dunkleosteus":
			return [
				p.call("body", "body", "rect", Vector2.ZERO, Color(0.3, 0.35, 0.4), {"size": Vector2(32, 18)}),
				p.call("tail", "tail", "triangle", Vector2(-18, 0), Color(0.3, 0.35, 0.4), {"base": 16, "height": 18}),
				p.call("mouth", "mouth", "triangle", Vector2(18, 0), Color(0.5, 0.5, 0.5), {"base": 12, "height": 10}),
			]
		"tiktaalik":
			return [
				p.call("body", "body", "rect", Vector2(0, 2), Color(0.8, 0.4, 0.2), {"size": Vector2(22, 12)}),
				p.call("head", "head", "circle", Vector2(14, -2), Color(0.85, 0.45, 0.25), {"radius": 9}),
				p.call("leg", "leg_fl", "circle", Vector2(6, 10), Color(0.8, 0.4, 0.2), {"radius": 4}),
				p.call("leg", "leg_fr", "circle", Vector2(-2, 10), Color(0.8, 0.4, 0.2), {"radius": 4}),
				p.call("leg", "leg_bl", "circle", Vector2(-8, 10), Color(0.8, 0.4, 0.2), {"radius": 4}),
				p.call("leg", "leg_br", "circle", Vector2(-14, 10), Color(0.8, 0.4, 0.2), {"radius": 4}),
				p.call("tail", "tail", "triangle", Vector2(-14, 2), Color(0.8, 0.4, 0.2), {"base": 8, "height": 12}),
			]
		"hylonomus":
			return [
				p.call("body", "body", "rect", Vector2(0, 0), Color(0.2, 0.7, 0.2), {"size": Vector2(24, 14)}),
				p.call("head", "head", "circle", Vector2(16, -2), Color(0.25, 0.75, 0.25), {"radius": 8}),
				p.call("leg", "leg_fl", "circle", Vector2(8, 8), Color(0.2, 0.7, 0.2), {"radius": 4}),
				p.call("leg", "leg_fr", "circle", Vector2(0, 8), Color(0.2, 0.7, 0.2), {"radius": 4}),
				p.call("leg", "leg_bl", "circle", Vector2(-8, 8), Color(0.2, 0.7, 0.2), {"radius": 4}),
				p.call("leg", "leg_br", "circle", Vector2(-16, 8), Color(0.2, 0.7, 0.2), {"radius": 4}),
				p.call("tail", "tail", "triangle", Vector2(-16, 0), Color(0.2, 0.7, 0.2), {"base": 8, "height": 14}),
			]
		"coelophysis":
			return [
				p.call("body", "body", "rect", Vector2(0, 0), Color(0.7, 0.3, 0.1), {"size": Vector2(28, 14)}),
				p.call("head", "head", "circle", Vector2(18, -4), Color(0.75, 0.35, 0.15), {"radius": 8}),
				p.call("mouth", "mouth", "triangle", Vector2(24, -2), Color(0.8, 0.1, 0.1), {"base": 8, "height": 10}),
				p.call("leg", "leg_l", "circle", Vector2(6, 10), Color(0.7, 0.3, 0.1), {"radius": 4}),
				p.call("leg", "leg_r", "circle", Vector2(-6, 10), Color(0.7, 0.3, 0.1), {"radius": 4}),
				p.call("tail", "tail", "triangle", Vector2(-18, 0), Color(0.7, 0.3, 0.1), {"base": 6, "height": 16}),
			]
		"scutosaurus":
			return [
				p.call("body", "body", "rect", Vector2(0, 0), Color(0.5, 0.35, 0.2), {"size": Vector2(36, 22)}),
				p.call("head", "head", "circle", Vector2(22, -2), Color(0.55, 0.4, 0.25), {"radius": 10}),
				p.call("leg", "leg_fl", "circle", Vector2(12, 12), Color(0.5, 0.35, 0.2), {"radius": 6}),
				p.call("leg", "leg_fr", "circle", Vector2(2, 12), Color(0.5, 0.35, 0.2), {"radius": 6}),
				p.call("leg", "leg_bl", "circle", Vector2(-8, 12), Color(0.5, 0.35, 0.2), {"radius": 6}),
				p.call("leg", "leg_br", "circle", Vector2(-18, 12), Color(0.5, 0.35, 0.2), {"radius": 6}),
				p.call("tail", "tail", "triangle", Vector2(-22, 0), Color(0.5, 0.35, 0.2), {"base": 10, "height": 18}),
				p.call("armor", "armor_body", "rect", Vector2(0, -10), Color(0.6, 0.45, 0.3), {"size": Vector2(30, 6)}),
			]
		"stegosaurus":
			return [
				p.call("body", "body", "rect", Vector2(0, 0), Color(0.4, 0.7, 0.2), {"size": Vector2(44, 26)}),
				p.call("head", "head", "circle", Vector2(28, -4), Color(0.45, 0.75, 0.25), {"radius": 10}),
				p.call("leg", "leg_fl", "circle", Vector2(14, 14), Color(0.4, 0.7, 0.2), {"radius": 7}),
				p.call("leg", "leg_fr", "circle", Vector2(2, 14), Color(0.4, 0.7, 0.2), {"radius": 7}),
				p.call("leg", "leg_bl", "circle", Vector2(-10, 14), Color(0.4, 0.7, 0.2), {"radius": 7}),
				p.call("leg", "leg_br", "circle", Vector2(-22, 14), Color(0.4, 0.7, 0.2), {"radius": 7}),
				p.call("tail", "tail", "triangle", Vector2(-28, 0), Color(0.4, 0.7, 0.2), {"base": 14, "height": 22}),
				p.call("armor", "armor_plate", "rect", Vector2(0, -14), Color(0.5, 0.6, 0.3), {"size": Vector2(36, 8)}),
			]
		"allosaurus":
			return [
				p.call("body", "body", "rect", Vector2(0, 0), Color(0.8, 0.2, 0.1), {"size": Vector2(34, 16)}),
				p.call("head", "head", "circle", Vector2(22, -4), Color(0.85, 0.25, 0.15), {"radius": 10}),
				p.call("mouth", "mouth", "triangle", Vector2(30, -2), Color(0.9, 0.1, 0.0), {"base": 12, "height": 14}),
				p.call("leg", "leg_fl", "circle", Vector2(10, 10), Color(0.8, 0.2, 0.1), {"radius": 5}),
				p.call("leg", "leg_fr", "circle", Vector2(0, 10), Color(0.8, 0.2, 0.1), {"radius": 5}),
				p.call("leg", "leg_bl", "circle", Vector2(-10, 10), Color(0.8, 0.2, 0.1), {"radius": 5}),
				p.call("leg", "leg_br", "circle", Vector2(-20, 10), Color(0.8, 0.2, 0.1), {"radius": 5}),
				p.call("tail", "tail", "triangle", Vector2(-22, 0), Color(0.8, 0.2, 0.1), {"base": 8, "height": 18}),
			]
		_:
			return [p.call("body", "body", "circle", Vector2.ZERO, Color(0.5, 0.5, 0.5), {"radius": 14})]

func _on_mini_boss_killed(_mini_boss: Node2D, _position: Vector2) -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		push_error("[EvolutionManager] _on_mini_boss_killed: player node not found")
		return
	var form = get_current_form()
	var era = EraManager.era_index
	var choices = _generate_random_parts(form, era, 3)
	if choices.is_empty():
		GameManager.boss_wave_active = false
		GameManager.start_next_wave()
		return
	get_tree().paused = true
	var screen = load("res://ui/PartPickerUI.gd").new()
	var vp = get_viewport().get_visible_rect().size
	get_tree().current_scene.add_child(screen)
	screen.show_choices(choices, vp, func(data: Dictionary):
		var cfg: FormPartConfig = data.get("part")
		var unique_info = _roll_unique(cfg.slot_id)
		var entry = {
			"part": cfg,
			"rarity": data.get("rarity", 0),
			"common_mutation": data.get("common_mutation", {}).duplicate(),
			"unique_mods": unique_info.get("mods", []).duplicate(),
			"unique_effect": unique_info.get("effect", ""),
			"unique_tier": unique_info.get("tier", 1),
			"unique_applied": false,
		}
		_equipped_parts.append(entry)
		if not unique_info.is_empty():
			_part_unique_pool.append({
				"slot_id": cfg.slot_id,
				"effect": unique_info.get("effect", ""),
				"tier": unique_info.get("tier", 1),
				"mods": unique_info.get("mods", []).duplicate(),
				"name": unique_info.get("name", ""),
				"icon": unique_info.get("icon", "✦"),
				"desc": unique_info.get("desc", ""),
				"part_idx": _equipped_parts.size() - 1,
			})
		_apply_part_to_player(player, entry)
		GameManager.boss_wave_active = false
		GameManager.start_next_wave()
		get_tree().paused = false
		screen.queue_free()
	)

func _apply_part_entry(player: Player, entry: Dictionary) -> void:
	var p: FormPartConfig = entry.get("part")
	var rarity: int = entry.get("rarity", 0)
	var mult = RARITY_MULT[rarity]

	if p.weapon_behavior_id and not p.weapon_behavior_id.is_empty():
		var ws = player._weapon_map.get(p.weapon_behavior_id)
		if ws:
			player.weapon.add_behavior(ws.new(), p.weapon_behavior_id)
			if p.weapon_cooldown > 0:
				player._timer_cooldown_overrides[p.weapon_behavior_id] = p.weapon_cooldown
	for sm in p.stat_mods:
		var sm_stat = sm.get("stat", "")
		var sm_val = sm.get("val", 0.0)
		var sm_type = sm.get("type", StatsResource.ModType.FLAT)
		player.stats.add_modifier_raw(sm_stat, sm_val * mult, sm_type, "part")
	if entry.get("unique_applied", false):
		for um in entry.get("unique_mods", []):
			var um_stat = um.get("stat", "")
			var um_val = um.get("val", 0.0)
			var um_type = um.get("type", StatsResource.ModType.FLAT)
			player.stats.add_modifier_raw(um_stat, um_val, um_type, "part_unique")
	var cm = entry.get("common_mutation", {})
	if cm.get("stat", "") != "":
		_apply_common_mutation(player, cm)

func _reapply_equipped_parts(player: Player) -> void:
	var all_configs: Array = []
	for entry in _equipped_parts:
		all_configs.append(entry.get("part"))
	if not all_configs.is_empty():
		player._visual.apply_parts(all_configs)
	for entry in _equipped_parts:
		_apply_part_entry(player, entry)
	player.refresh_from_stats()

func _apply_part_to_player(player: Player, data: Dictionary) -> void:
	var cfg: FormPartConfig = data.get("part")
	var existing_configs: Array = []
	for pv in player._visual._parts.values():
		if pv.config:
			existing_configs.append(pv.config)
	existing_configs.append(cfg)
	player._visual.apply_parts(existing_configs)
	_apply_part_entry(player, data)
	player.refresh_from_stats()

func _apply_common_mutation(player: Player, cm: Dictionary) -> void:
	var stat = cm.get("stat", "")
	var val = cm.get("val", 0.0)
	var mod_type = cm.get("mod_type", StatsResource.ModType.FLAT)
	if stat == "gp_mult":
		GameManager.gp_multiplier += val
	elif stat == "collect_range":
		GameManager.gp_collect_range += val
	else:
		player.stats.add_modifier_raw(stat, val, mod_type, "part")

func _generate_random_parts(form: Dictionary, era: int, count: int) -> Array[Dictionary]:
	var pool = _get_era_part_pool(era)
	pool.shuffle()
	var chosen = pool.slice(0, mini(count, pool.size()))
	var result: Array[Dictionary] = []
	for p in chosen:
		var r = _roll_rarity()
		var category = PART_CATEGORIES.get(p.slot_id, "attack")
		var common_pool = PART_COMMON_MUTATIONS.get(category, [])
		var common = common_pool[randi() % common_pool.size()] if not common_pool.is_empty() else {}
		var entry = {"part": p, "rarity": r, "common_mutation": common.duplicate()}
		result.append(entry)
	return result

func _roll_unique(slot_id: String) -> Dictionary:
	var cfg = PART_UNIQUES.get(slot_id)
	if not cfg:
		return {}
	var tier_idx = randi() % 3
	var tier = cfg["tiers"][tier_idx]
	return {
		"name": cfg["name"] + " " + ["I", "II", "III"][tier_idx],
		"icon": cfg.get("icon", "✦"),
		"desc": tier["desc"],
		"mods": tier["mods"],
		"effect": cfg.get("effect", ""),
		"tier": tier_idx + 1,
	}

func _roll_rarity() -> int:
	var roll = randf()
	var cum = 0.0
	for i in RARITY_CHANCES.size():
		cum += RARITY_CHANCES[i]
		if roll < cum:
			return i
	return RARITY_CHANCES.size() - 1

func _get_era_part_pool(era: int) -> Array[FormPartConfig]:
	match era:
		0:
			return [
				_make_part("spike_tail", "tail", Color(0.7, 0.1, 0.1), "tail_sweep", [{"stat": "damage", "val": 4, "type": StatsResource.ModType.FLAT}], "triangle", Vector2(16, 0), {"base": 14, "height": 20}, 0.8),
				_make_part("stinger", "tail", Color(0.9, 0.8, 0.1), "sting_dart", [], "triangle", Vector2(-18, 0), {"base": 6, "height": 16}, 1.2),
				_make_part("pincer", "arm", Color(0.5, 0.1, 0.1), "pincer_claw", [{"stat": "armor", "val": 2, "type": StatsResource.ModType.FLAT}], "polygon", Vector2(14, -8), {"points": [Vector2(0,0), Vector2(12,-4), Vector2(14,6), Vector2(0,10)]}, 1.0),
				_make_part("crushing_jaw", "mouth", Color(0.6, 0.0, 0.0), "crushing_bite", [], "triangle", Vector2(22, 0), {"base": 18, "height": 12}, 1.5),
				_make_part("barbed_tentacle", "leg", Color(0.8, 0.2, 0.5), "tongue_lash", [], "line", Vector2(8, -14), {"length": 20, "width": 4}, 0.7),
				_make_part("radiant_eye", "head", Color(0.8, 0.8, 0.1), "stare", [], "circle", Vector2(20, -6), {"radius": 7}, 1.8),
				_make_part("venom_gland", "organ", Color(0.4, 0.8, 0.2), "swarm_shot", [], "circle", Vector2(-10, 12), {"radius": 7}, 1.0),
			]
		1:
			return [
				_make_part("armor_plate", "armor", Color(0.6, 0.4, 0.2), "", [{"stat": "max_hp", "val": 30, "type": StatsResource.ModType.FLAT}], "rect", Vector2(6, -14), {"size": Vector2(28, 8)}),
				_make_part("speed_gland", "organ", Color(0.2, 0.8, 0.6), "", [{"stat": "speed", "val": 35, "type": StatsResource.ModType.FLAT}], "circle", Vector2(-16, -4), {"radius": 6}),
				_make_part("venom_sac", "organ", Color(0.8, 0.2, 0.6), "", [{"stat": "damage", "val": 8, "type": StatsResource.ModType.FLAT}], "circle", Vector2(-10, 14), {"radius": 7}),
				_make_part("quick_fiber", "muscle", Color(0.9, 0.6, 0.1), "", [{"stat": "fire_cooldown", "val": -0.13, "type": StatsResource.ModType.PERCENT}], "line", Vector2(-4, -16), {"length": 20, "width": 3}),
				_make_part("shell", "armor", Color(0.3, 0.3, 0.5), "", [{"stat": "armor", "val": 2, "type": StatsResource.ModType.FLAT}], "rect", Vector2(0, -16), {"size": Vector2(36, 10)}),
				_make_part("hydro_jet", "mouth", Color(0.1, 0.4, 0.9), "water_jet", [], "triangle", Vector2(26, 0), {"base": 8, "height": 18}, 0.6),
				_make_part("charge_cell", "organ", Color(0.1, 0.9, 0.4), "cell_burst", [], "circle", Vector2(-8, -10), {"radius": 8}, 1.5),
			]
		2:
			return [
				_make_part("armor_plate", "armor", Color(0.6, 0.4, 0.2), "", [{"stat": "max_hp", "val": 50, "type": StatsResource.ModType.FLAT}], "rect", Vector2(6, -18), {"size": Vector2(36, 10)}),
				_make_part("speed_gland", "organ", Color(0.2, 0.8, 0.6), "", [{"stat": "speed", "val": 55, "type": StatsResource.ModType.FLAT}], "circle", Vector2(-20, -4), {"radius": 7}),
				_make_part("venom_sac", "organ", Color(0.8, 0.2, 0.6), "", [{"stat": "damage", "val": 12, "type": StatsResource.ModType.FLAT}], "circle", Vector2(-12, 18), {"radius": 8}),
				_make_part("quick_fiber", "muscle", Color(0.9, 0.6, 0.1), "", [{"stat": "fire_cooldown", "val": -0.16, "type": StatsResource.ModType.PERCENT}], "line", Vector2(-4, -20), {"length": 26, "width": 4}),
				_make_part("shell", "armor", Color(0.3, 0.3, 0.5), "", [{"stat": "armor", "val": 3, "type": StatsResource.ModType.FLAT}], "rect", Vector2(0, -20), {"size": Vector2(44, 12)}),
				_make_part("dragon_maw", "mouth", Color(0.9, 0.3, 0.0), "fire_breath", [], "triangle", Vector2(30, 0), {"base": 22, "height": 16}, 2.0),
				_make_part("psychic_node", "head", Color(0.6, 0.2, 1.0), "psychic_blast", [], "circle", Vector2(24, -8), {"radius": 9}, 2.5),
			]
		_:
			return [
				_make_part("armor_plate", "armor", Color(0.6, 0.4, 0.2), "", [{"stat": "max_hp", "val": 70, "type": StatsResource.ModType.FLAT}], "rect", Vector2(6, -22), {"size": Vector2(44, 12)}),
				_make_part("speed_gland", "organ", Color(0.2, 0.8, 0.6), "", [{"stat": "speed", "val": 75, "type": StatsResource.ModType.FLAT}], "circle", Vector2(-24, -4), {"radius": 8}),
				_make_part("venom_sac", "organ", Color(0.8, 0.2, 0.6), "", [{"stat": "damage", "val": 16, "type": StatsResource.ModType.FLAT}], "circle", Vector2(-14, 22), {"radius": 9}),
				_make_part("quick_fiber", "muscle", Color(0.9, 0.6, 0.1), "", [{"stat": "fire_cooldown", "val": -0.20, "type": StatsResource.ModType.PERCENT}], "line", Vector2(-4, -24), {"length": 32, "width": 5}),
				_make_part("shell", "armor", Color(0.3, 0.3, 0.5), "", [{"stat": "armor", "val": 4, "type": StatsResource.ModType.FLAT}], "rect", Vector2(0, -24), {"size": Vector2(52, 14)}),
				_make_part("chaos_eye", "head", Color(0.9, 0.0, 0.9), "chaos_beam", [], "circle", Vector2(28, -10), {"radius": 10}, 3.0),
				_make_part("bouncy_chitin", "armor", Color(0.3, 0.8, 0.8), "bouncy_shot", [], "rect", Vector2(-6, -20), {"size": Vector2(40, 14)}, 0.9),
			]

func _make_part(slot_id: String = "", slot_type: String = "body", color: Color = Color.WHITE,
	weapon: String = "", stat_mods: Array[Dictionary] = [], draw_type: String = "circle", draw_pos: Vector2 = Vector2.ZERO,
	draw_params: Dictionary = {}, weapon_cooldown: float = 0.0) -> FormPartConfig:
	var cfg = FormPartConfigScript.new()
	cfg.slot_id = slot_id
	cfg.slot_type = slot_type
	cfg.draw_type = draw_type
	cfg.color = color
	cfg.position = draw_pos
	cfg.draw_params = draw_params
	if not weapon.is_empty():
		cfg.weapon_behavior_id = weapon
	if weapon_cooldown > 0:
		cfg.weapon_cooldown = weapon_cooldown
	if not stat_mods.is_empty():
		cfg.stat_mods = stat_mods
	return cfg

func _log(msg: String) -> void:
	print_rich("[color=gray][DEBUG] " + msg + "[/color]")
