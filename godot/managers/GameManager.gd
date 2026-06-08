extends Node

var score := 0
var gp := 0
var gp_to_next := 25
var wave := 0
var enemies_alive := 0
var game_over := false
var gp_multiplier: float = 1.0
var elapsed_time: float = 0.0
var kills_this_wave := 0
var boss_wave_active: bool = false
var extinction_active: bool = false
var gp_collect_range: float = 100.0

func _enter_tree() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	EventBus.gp_collected.connect(_on_gp_collected)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.boss_killed.connect(_on_boss_killed)
	EventBus.combo_full.connect(_on_combo_full)
	EventBus.extinction_ended.connect(_on_extinction_ended)

func _exit_tree() -> void:
	if EventBus.gp_collected.is_connected(_on_gp_collected):
		EventBus.gp_collected.disconnect(_on_gp_collected)
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)
	if EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.disconnect(_on_player_died)
	if EventBus.boss_killed.is_connected(_on_boss_killed):
		EventBus.boss_killed.disconnect(_on_boss_killed)
	if EventBus.combo_full.is_connected(_on_combo_full):
		EventBus.combo_full.disconnect(_on_combo_full)
	if EventBus.extinction_ended.is_connected(_on_extinction_ended):
		EventBus.extinction_ended.disconnect(_on_extinction_ended)

func reset() -> void:
	PoolManager.clear()
	MutationManager.reset_run()
	score = 0
	gp = 0
	gp_to_next = 25
	wave = 0
	EraManager.reset()
	enemies_alive = 0
	game_over = false
	gp_multiplier = 1.0
	elapsed_time = 0.0
	kills_this_wave = 0
	boss_wave_active = false
	extinction_active = false
	gp_collect_range = 100.0

func _on_gp_collected(amount: int) -> void:
	if game_over:
		return
	gp += ceili(amount * gp_multiplier * MetaManager.get_gp_multiplier())

	while gp >= gp_to_next:
		gp -= gp_to_next
		gp_to_next = maxi(ceili(gp_to_next * 1.15), 1)
		EventBus.mutation_ready.emit()

	EventBus.gp_changed.emit(gp, gp_to_next)

func _on_enemy_died(_enemy: Node2D, _pos: Vector2, _gp: int) -> void:
	if game_over:
		return
	score += 10
	EventBus.score_changed.emit(score)
	enemies_alive -= 1
	kills_this_wave += 1
	if boss_wave_active or extinction_active:
		return
	if kills_this_wave >= 5 + wave * 3:
		kills_this_wave = 0
		start_next_wave()

func _on_player_died() -> void:
	end_game()

func _on_combo_full(_bar_index: int) -> void:
	EventBus.gp_collected.emit(10)

func _on_boss_killed() -> void:
	if game_over:
		return
	if boss_wave_active:
		boss_wave_active = false
		var old_wave = wave
		start_next_wave()
		if old_wave > 0 and old_wave % 10 == 0:
			EventBus.evolution_ready.emit()

func _on_extinction_ended() -> void:
	extinction_active = false
	start_next_wave()

func register_enemy() -> void:
	enemies_alive += 1

func start_next_wave() -> void:
	wave += 1
	EraManager.check_progression(wave)
	EventBus.wave_changed.emit(wave)

func _process(delta: float) -> void:
	if OS.is_debug_build() and Input.is_key_pressed(KEY_M) and not game_over:
		print_rich("[color=yellow][DEBUG-M] wave=%d alive=%d[/color]" % [wave, enemies_alive])
		start_next_wave()
	if not game_over:
		elapsed_time += delta

func end_game() -> void:
	if game_over:
		return
	game_over = true
	var evo = get_tree().get_first_node_in_group("evolution_manager") as EvolutionManager
	if evo:
		SaveManager.add_highscore(score, wave, evo.current_form_id)
	else:
		push_error("[GameManager] end_game: EvolutionManager not found — cannot save progress")
		for form_id in evo._evolution_path:
			SaveManager.unlock_form(form_id)
		SaveManager.unlock_form(evo.current_form_id)
		var dna_reward = maxi(1, score / 100) + GameManager.wave * 2
		MetaManager.add_dna(dna_reward)
	EventBus.game_over.emit()
	get_tree().paused = true
	var ds = load("res://ui/DeathScreen.gd").new()
	get_tree().current_scene.add_child(ds)

func get_save_data() -> Dictionary:
	return {
		"score": score, "gp": gp, "gp_to_next": gp_to_next,
		"wave": wave,
		"kills_this_wave": kills_this_wave, "elapsed_time": elapsed_time,
		"gp_multiplier": gp_multiplier,
	}

func restore_from_save(data: Dictionary) -> void:
	score = data.get("score", 0)
	gp = data.get("gp", 0)
	gp_to_next = data.get("gp_to_next", 25)
	wave = data.get("wave", 0)
	kills_this_wave = data.get("kills_this_wave", 0)
	elapsed_time = data.get("elapsed_time", 0.0)
	gp_multiplier = data.get("gp_multiplier", 1.0)
