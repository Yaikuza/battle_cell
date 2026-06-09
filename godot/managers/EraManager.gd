extends Node

var era_index := 0

func _enter_tree() -> void:
	process_mode = PROCESS_MODE_ALWAYS

func get_current_era() -> EraData:
	var db = load("res://data/game_database.tres") as GameDatabase
	if not db:
		return null
	return db.get_era(era_index)

func get_era_name() -> String:
	var era = get_current_era()
	return era.display_name if era else "Unknown"

func check_progression(wave: int) -> void:
	var new_idx := 0
	if wave >= 30: new_idx = 3
	elif wave >= 20: new_idx = 2
	elif wave >= 10: new_idx = 1
	if new_idx != era_index:
		era_index = new_idx
		var era = get_current_era()
		EventBus.era_changed.emit(era.display_name if era else "Unknown", era_index)

func get_save_data() -> Dictionary:
	return {"era_index": era_index}

func reset() -> void:
	era_index = 0

func restore_from_save(data: Dictionary) -> void:
	if data.has("era_index"):
		era_index = data["era_index"]
