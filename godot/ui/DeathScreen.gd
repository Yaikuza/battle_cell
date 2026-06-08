extends CanvasLayer
class_name DeathScreen

var _buttons: Array[Button] = []
var _selected: int = 0

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	var vp = get_viewport().get_visible_rect().size

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.size = vp
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var title = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.25)
	title.size = Vector2(vp.x, 50)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	add_child(title)

	var info = Label.new()
	info.text = "Score: %d   Wave: %d" % [GameManager.score, GameManager.wave]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.position = Vector2(0, vp.y * 0.25 + 55)
	info.size = Vector2(vp.x, 25)
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(info)

	var retry = Button.new()
	retry.text = "  Retry (R)"
	retry.position = Vector2(vp.x / 2 - 100, vp.y * 0.42)
	retry.size = Vector2(200, 50)
	retry.add_theme_font_size_override("font_size", 20)
	retry.pressed.connect(_retry)
	add_child(retry)
	_buttons.append(retry)

	var menu = Button.new()
	menu.text = "  Main Menu (ESC)"
	menu.position = Vector2(vp.x / 2 - 100, vp.y * 0.42 + 70)
	menu.size = Vector2(200, 50)
	menu.add_theme_font_size_override("font_size", 20)
	menu.pressed.connect(_quit)
	add_child(menu)
	_buttons.append(menu)

	_update_highlight()

func _update_highlight() -> void:
	for i in _buttons.size():
		var btn = _buttons[i]
		var s = StyleBoxFlat.new()
		if i == _selected:
			s.bg_color = Color(0.15, 0.15, 0.25)
			s.border_color = Color(1.0, 0.2, 0.2)
			s.set_border_width_all(2)
		else:
			s.bg_color = Color(0.08, 0.08, 0.15)
			s.border_color = Color(0.1, 0.1, 0.2)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", s)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		if Input.is_action_just_pressed("move_up"):
			_selected = (_selected - 1 + _buttons.size()) % _buttons.size()
			_update_highlight(); AudioManager.play_sfx("click"); get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("move_down"):
			_selected = (_selected + 1) % _buttons.size()
			_update_highlight(); AudioManager.play_sfx("click"); get_viewport().set_input_as_handled()
		return
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
		_quit()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_viewport().set_input_as_handled()
		_retry()

func _retry() -> void:
	AudioManager.play_sfx("click")
	GameManager.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _quit() -> void:
	AudioManager.play_sfx("click")
	GameManager.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
