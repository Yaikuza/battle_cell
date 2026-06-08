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

func save_run(data: Dictionary) -> void:
	var cfg = ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("run", "data", data)
	cfg.save(SAVE_PATH)

func load_run() -> Dictionary:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	return cfg.get_value("run", "data", {})

func has_saved_run() -> bool:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return cfg.has_section_key("run", "data")

func delete_saved_run() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	if cfg.has_section("run"):
		cfg.erase_section("run")
		cfg.save(SAVE_PATH)

func get_form_name(form_id: String) -> String:
	match form_id:
		"cell": return "Single Cell"
		"dunkleosteus": return "Dunkleosteus"
		"tiktaalik": return "Tiktaalik"
		"scutosaurus": return "Scutosaurus"
		"stegosaurus": return "Stegosaurus"
		"hylonomus": return "Hylonomus"
		"coelophysis": return "Coelophysis"
		"allosaurus": return "Allosaurus"
	return "???"
