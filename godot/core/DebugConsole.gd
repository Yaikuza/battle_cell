extends Node

var _panel: Control = null
var _god_mode: bool = false
var _mutation_index: int = 0
var _form_index: int = 0

func _ready() -> void:
	if not OS.is_debug_build():
		set_process_input(false)
		return
	process_mode = PROCESS_MODE_ALWAYS
	print("[DebugConsole] Ready — debug features enabled")

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	_handle_debug_shortcuts(event)

func _handle_debug_shortcuts(event: InputEventKey) -> void:
	match event.keycode:
		KEY_F1:
			if not _panel or not is_instance_valid(_panel): return
			_debug_spawn_enemy()
			get_viewport().set_input_as_handled()
		KEY_F2:
			if not _panel or not is_instance_valid(_panel): return
			_debug_add_gp(100)
			get_viewport().set_input_as_handled()
		KEY_F3:
			if not _panel or not is_instance_valid(_panel): return
			_debug_force_evolution()
			get_viewport().set_input_as_handled()
		KEY_F4:
			if not _panel or not is_instance_valid(_panel): return
			_debug_toggle_god_mode()
			get_viewport().set_input_as_handled()
		KEY_F5:
			if not _panel or not is_instance_valid(_panel): return
			_debug_cycle_mutation()
			get_viewport().set_input_as_handled()
		KEY_F6:
			if not _panel or not is_instance_valid(_panel): return
			_debug_cycle_form()
			get_viewport().set_input_as_handled()
		KEY_F7:
			if not _panel or not is_instance_valid(_panel): return
			_debug_next_wave()
			get_viewport().set_input_as_handled()
		KEY_F12:
			_toggle_debug_panel()
			get_viewport().set_input_as_handled()

func _debug_spawn_enemy() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	print("[Debug] F1 — spawn enemy (alive: ", enemies.size(), ")")

func _debug_add_gp(amount: int) -> void:
	if GameManager.game_over:
		return
	EventBus.gp_collected.emit(amount)
	print("[Debug] F2 — +", amount, " GP (total: ", GameManager.gp, ")")

func _debug_force_evolution() -> void:
	if GameManager.game_over:
		return
	EventBus.evolution_ready.emit()
	print("[Debug] F3 — force evolution")

func _debug_toggle_god_mode() -> void:
	_god_mode = not _god_mode
	var player = get_tree().get_first_node_in_group("player") as Node
	if player and player.has_method("_toggle_god_mode"):
		player._toggle_god_mode(_god_mode)
	print("[Debug] F4 — god mode: ", _god_mode)
	_refresh_panel()

func _debug_cycle_mutation() -> void:
	var mutation_ids = MutationManager._mutations.keys()
	if mutation_ids.is_empty():
		print("[Debug] F5 — no mutations available")
		return
	_mutation_index = (_mutation_index + 1) % mutation_ids.size()
	var mid = mutation_ids[_mutation_index]
	var mutation_applied = MutationManager.get_mutation_data(mid)
	if not mutation_applied.is_empty():
		EventBus.mutation_applied.emit(mid)
		print("[Debug] F5 — mutation applied: ", mid)

func _debug_cycle_form() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node
	if not player or not player.has_method("apply_form"):
		return
	var evo = get_tree().get_first_node_in_group("evolution_manager") as Node
	if not evo or not evo.has_method("get_current_form"):
		return
	var all_forms: Array = _get_all_form_ids()
	if all_forms.is_empty():
		return
	_form_index = (_form_index + 1) % all_forms.size()
	var form_id = all_forms[_form_index]
	var form_data = evo.get_current_form()
	var new_form = form_data.duplicate(true)
	new_form["id"] = form_id
	player.apply_form(new_form, true)
	evo._evolution_path.append(form_id)
	EventBus.evolution_chosen.emit(form_id)
	print("[Debug] F6 — switched to form: ", form_id)
	_refresh_panel()

func _debug_next_wave() -> void:
	if GameManager.game_over:
		return
	GameManager.kills_this_wave = 0
	GameManager.start_next_wave()
	print("[Debug] F7 — next wave: ", GameManager.wave)

func _get_all_form_ids() -> Array:
	var evo = get_tree().get_first_node_in_group("evolution_manager") as Node
	if not evo or not evo.has_method("get_current_form"):
		return []
	var forms = evo.get("_tree")
	if not forms is Dictionary:
		return []
	var ids: Array = []
	for k in forms:
		ids.append(k)
	ids.sort()
	return ids

func _toggle_debug_panel() -> void:
	if _panel and is_instance_valid(_panel):
		_panel.queue_free()
		_panel = null
		return
	var root = get_tree().root
	_panel = _build_panel()
	if _panel:
		root.add_child(_panel)

func _build_panel() -> Control:
	var layer = CanvasLayer.new()
	layer.layer = 128
	var panel = Panel.new()
	panel.size = Vector2(300, 260)
	panel.position = Vector2(10, 10)
	panel.modulate = Color(0.1, 0.1, 0.1, 0.8)
	var lbl = Label.new()
	lbl.name = "InfoLabel"
	lbl.position = Vector2(8, 8)
	lbl.size = Vector2(284, 244)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	panel.add_child(lbl)
	layer.add_child(panel)
	return layer

func _refresh_panel() -> void:
	if not _panel or not is_instance_valid(_panel):
		return
	var lbl = _panel.get_node("Panel/InfoLabel") as Label
	if not lbl:
		return
	var player = get_tree().get_first_node_in_group("player") as Node
	var evo = get_tree().get_first_node_in_group("evolution_manager") as Node
	var form_name = ""
	var hp_info = ""
	var speed_info = ""
	var cd_info = ""
	var dmg_info = ""
	if player:
		var stats = player.get("stats")
		if stats:
			form_name = evo.get("current_form_id") if evo else "?"
			hp_info = "HP:  %.0f / %.0f" % [player.health.hp, player.health.max_hp] if player.get("health") else "HP:  ?"
			speed_info = "SPD: %.0f" % stats.get_stat("speed") if stats.has_method("get_stat") else ""
			dmg_info = "DMG: %.0f" % stats.get_stat("damage") if stats.has_method("get_stat") else ""
			cd_info = "ROF: %.2fs" % stats.get_stat("fire_cooldown") if stats.has_method("get_stat") else ""
	var text = "== DEBUG PANEL ==\n"
	text += "Form: %s\n" % form_name
	text += "Wave: %d\n" % GameManager.wave
	text += "%s\n" % hp_info
	text += "%s\n" % speed_info
	text += "%s\n" % dmg_info
	text += "%s\n" % cd_info
	text += "God:  %s\n" % _god_mode
	text += "\nF1=Spawn F2=+GP F3=Evo\n"
	text += "F4=God F5=Mu F6=Form\n"
	text += "F7=Wave F12=Close"
	lbl.text = text

func _process(_delta: float) -> void:
	if _panel and is_instance_valid(_panel):
		_refresh_panel()
