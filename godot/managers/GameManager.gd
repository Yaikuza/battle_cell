extends Node

var score := 0
var gp := 0
var gp_to_next := 25
var wave := 0
var era_index := 0
var enemies_alive := 0
var game_over := false
var gp_multiplier: float = 1.0
var elapsed_time: float = 0.0
var kills_this_wave := 0

func _enter_tree() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	EventBus.gp_collected.connect(_on_gp_collected)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)

func _exit_tree() -> void:
	if EventBus.gp_collected.is_connected(_on_gp_collected):
		EventBus.gp_collected.disconnect(_on_gp_collected)
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)
	if EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.disconnect(_on_player_died)

func reset() -> void:
	PoolManager.clear()
	score = 0
	gp = 0
	gp_to_next = 25
	wave = 0
	era_index = 0
	enemies_alive = 0
	game_over = false
	gp_multiplier = 1.0
	elapsed_time = 0.0
	kills_this_wave = 0

func _on_gp_collected(amount: int) -> void:
	if game_over:
		return
	gp += ceili(amount * gp_multiplier * MetaManager.get_gp_multiplier())
	if gp >= gp_to_next:
		gp -= gp_to_next
		gp_to_next = ceili(gp_to_next * 1.6)
		EventBus.evolution_ready.emit()
	EventBus.gp_changed.emit(gp, gp_to_next)

func _on_enemy_died(_enemy: Node2D, _pos: Vector2, _gp: int) -> void:
	if game_over:
		return
	score += 10
	EventBus.score_changed.emit(score)
	enemies_alive -= 1
	kills_this_wave += 1
	if kills_this_wave >= 5 + wave * 3:
		kills_this_wave = 0
		start_next_wave()

func _on_player_died() -> void:
	end_game()

func register_enemy() -> void:
	enemies_alive += 1

func start_next_wave() -> void:
	wave += 1
	_update_era()
	EventBus.wave_changed.emit(wave)

func _update_era() -> void:
	var new_idx := 0
	if wave >= 15: new_idx = 4
	elif wave >= 10: new_idx = 3
	elif wave >= 6: new_idx = 2
	elif wave >= 4: new_idx = 1
	if new_idx != era_index:
		era_index = new_idx
		var db = load("res://data/game_database.tres")
		var era = db.get_era(era_index)
		EventBus.era_changed.emit(era.display_name if era else "Unknown", era_index)

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_M) and not game_over:
		print("DEBUG M: wave", wave, "alive", enemies_alive, "go", game_over)
		start_next_wave()
	if not game_over:
		elapsed_time += delta
		return
	if Input.is_key_pressed(KEY_R):
		reset()
		get_tree().paused = false
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_ESCAPE):
		reset()
		get_tree().paused = false
		get_tree().change_scene_to_file("res://Scenes/Menu.tscn")

func end_game() -> void:
	game_over = true
	var evo = get_tree().get_first_node_in_group("evolution_manager") as EvolutionManager
	if evo:
		SaveManager.add_highscore(score, wave, evo.current_form_id)
		for form_id in evo._evolution_path:
			SaveManager.unlock_form(form_id)
		SaveManager.unlock_form(evo.current_form_id)
		var dna_reward = maxi(1, score / 100) + GameManager.wave * 2
		MetaManager.add_dna(dna_reward)
	EventBus.game_over.emit()
	get_tree().paused = true

func get_save_data() -> Dictionary:
	return {
		"score": score, "gp": gp, "gp_to_next": gp_to_next,
		"wave": wave, "era_index": era_index,
		"kills_this_wave": kills_this_wave, "elapsed_time": elapsed_time,
		"gp_multiplier": gp_multiplier,
	}

func restore_from_save(data: Dictionary) -> void:
	score = data.get("score", 0)
	gp = data.get("gp", 0)
	gp_to_next = data.get("gp_to_next", 25)
	wave = data.get("wave", 0)
	era_index = data.get("era_index", 0)
	kills_this_wave = data.get("kills_this_wave", 0)
	elapsed_time = data.get("elapsed_time", 0.0)
	gp_multiplier = data.get("gp_multiplier", 1.0)

func get_era_name() -> String:
	var db = load("res://data/game_database.tres")
	var era = db.get_era(era_index)
	return era.display_name if era else "Unknown"
