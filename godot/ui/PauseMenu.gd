extends CanvasLayer
class_name PauseMenu

var _buttons: Array[Button] = []
var _selected: int = 0

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	var vp = get_viewport().get_visible_rect().size

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.size = vp
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.25)
	title.size = Vector2(vp.x, 50)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	add_child(title)

	var resume = Button.new()
	resume.text = "  Resume"
	resume.position = Vector2(vp.x / 2 - 100, vp.y * 0.42)
	resume.size = Vector2(200, 50)
	resume.add_theme_font_size_override("font_size", 20)
	resume.pressed.connect(_resume)
	add_child(resume)
	_buttons.append(resume)

	var savequit = Button.new()
	savequit.text = "  Save & Quit"
	savequit.position = Vector2(vp.x / 2 - 100, vp.y * 0.42 + 70)
	savequit.size = Vector2(200, 50)
	savequit.add_theme_font_size_override("font_size", 20)
	savequit.pressed.connect(_save_and_quit)
	add_child(savequit)
	_buttons.append(savequit)

	var quit = Button.new()
	quit.text = "  Back to Main Menu"
	quit.position = Vector2(vp.x / 2 - 100, vp.y * 0.42 + 140)
	quit.size = Vector2(200, 50)
	quit.add_theme_font_size_override("font_size", 20)
	quit.pressed.connect(_quit)
	add_child(quit)
	_buttons.append(quit)

	_update_highlight()

func _update_highlight() -> void:
	for i in _buttons.size():
		var btn = _buttons[i]
		var s = StyleBoxFlat.new()
		if i == _selected:
			s.bg_color = Color(0.15, 0.15, 0.25)
			s.border_color = Color(0.2, 1.0, 0.3)
			s.set_border_width_all(2)
		else:
			s.bg_color = Color(0.08, 0.08, 0.15)
			s.border_color = Color(0.1, 0.1, 0.2)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", s)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_selected = (_selected - 1 + _buttons.size()) % _buttons.size()
		_update_highlight()
		AudioManager.play_sfx("click")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_selected = (_selected + 1) % _buttons.size()
		_update_highlight()
		AudioManager.play_sfx("click")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_buttons[_selected].emit_signal("pressed")
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_resume()

func _resume() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	queue_free()

func _save_and_quit() -> void:
	AudioManager.play_sfx("click")
	var data: Dictionary = {}
	data["game"] = GameManager.get_save_data()
	var evo = get_tree().get_first_node_in_group("evolution_manager") as EvolutionManager
	if evo:
		data["evolution"] = evo.get_save_data()
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		data["player"] = {
			"hp": player.health.hp,
			"max_hp": player.health.max_hp,
			"position_x": player.position.x,
			"position_y": player.position.y,
			"used_second_chance": player._used_second_chance,
		}
	SaveManager.save_run(data)
	GameManager.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")

func _quit() -> void:
	AudioManager.play_sfx("click")
	GameManager.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
