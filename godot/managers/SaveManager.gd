extends Node

const SAVE_PATH := "user://battle_cell.cfg"
const MAX_HIGHSCORES := 10

var gallery: Dictionary = {}
var highscores: Array[Dictionary] = []
var settings: Dictionary = {
	"volume": 80.0,
	"fullscreen": false,
}

func _ready() -> void:
	load_save()

func load_save() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return

	if cfg.has_section("gallery"):
		for k in cfg.get_section_keys("gallery"):
			gallery[k] = cfg.get_value("gallery", k, false)

	if cfg.has_section("highscores"):
		var raw = cfg.get_value("highscores", "entries", [])
		if raw is Array:
			for e in raw:
				if e is Dictionary:
					highscores.append(e)

	if cfg.has_section("settings"):
		settings.volume = cfg.get_value("settings", "volume", 80.0)
		settings.fullscreen = cfg.get_value("settings", "fullscreen", false)

func save() -> void:
	var cfg = ConfigFile.new()
	cfg.load(SAVE_PATH)
	for k in gallery:
		cfg.set_value("gallery", k, gallery[k])
	cfg.set_value("highscores", "entries", highscores)
	cfg.set_value("settings", "volume", settings.volume)
	cfg.set_value("settings", "fullscreen", settings.fullscreen)
	cfg.save(SAVE_PATH)

func unlock_form(form_id: String) -> void:
	if gallery.has(form_id) and gallery[form_id]:
		return
	gallery[form_id] = true
	save()

func is_form_unlocked(form_id: String) -> bool:
	return gallery.get(form_id, false)

func add_highscore(score: int, wave: int, form_id: String) -> void:
	var entry = {
		"score": score,
		"wave": wave,
		"form": form_id,
		"date": Time.get_unix_time_from_system(),
	}
	highscores.append(entry)
	highscores.sort_custom(func(a, b): return a.score > b.score)
	if highscores.size() > MAX_HIGHSCORES:
		highscores.resize(MAX_HIGHSCORES)
	save()

func save_settings(volume: float, fullscreen: bool) -> void:
	settings.volume = volume
	settings.fullscreen = fullscreen
	save()

func get_form_name(form_id: String) -> String:
	match form_id:
		"cell": return "Single Cell"
		"fish": return "Ancient Fish"
		"amphibian": return "Primitive Amphibian"
		"arthropod": return "Early Arthropod"
		"synapsid": return "Pelycosaur"
		"apex_hunter": return "Convergent Predator"
		"reptile": return "Early Reptile"
		"winged_insect": return "Winged Insect"
		"cynodont": return "Cynodont"
		"primeval_dino": return "Primeval Dino"
		"swarm_lord": return "Swarm Lord"
		"mammal": return "Early Mammal"
		"tyrant_king": return "Tyrant King"
		"chitin_beetle": return "Chitin Beetle"
		"primate": return "Primate"
		"human": return "Human"
		"crab_like": return "Crab-like"
		"dragon": return "Dragon"
		"chimera": return "Chimera"
		"rubber_chicken": return "Rubber Chicken"
		"roomba_lord": return "Roomba Lord"
		"t_pose_tyrant": return "T-Pose Tyrant"
	return "???"
