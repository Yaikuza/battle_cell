extends CanvasLayer
class_name Menu

const TreeCanvasScript = preload("res://ui/TreeCanvas.gd")

var _current_view: Node = null
var _volume: float = 80.0

var _menu_grid: Array[Array] = []
var _grid_pos: Vector2i = Vector2i(0, 0)
var _in_main_menu: bool = false
var _quit_popup: Node = null
var _quit_btns: Array[Button] = []
var _quit_sel: int = 0

var _sub_btns: Array[Button] = []
var _sub_idx: int = 0
var _sub_back: Callable = Callable()
var _in_sub: bool = false

const _tree_data: Dictionary = {
	"cell":          {"name": "Single Cell",       "desc": "จุดเริ่มต้นของทุกชีวิต",                              "color": Color(0.2, 1.0, 0.3)},
	"fish":          {"name": "Ancient Fish",      "desc": "สัตว์มีกระดูกสันหลังชนิดแรก",                         "color": Color(0.0, 0.8, 1.0)},
	"arthropod":     {"name": "Early Arthropod",   "desc": "สัตว์ขาปล้องยุคแคมเบรียน",                           "color": Color(0.7, 0.2, 0.9)},
	"synapsid":      {"name": "Pelycosaur",        "desc": "สัตว์คล้ายสัตว์เลี้ยงลูกด้วยนมยุคแรก",                "color": Color(0.6, 0.3, 0.0)},
	"amphibian":     {"name": "Primitive Amphibian","desc": "เททราโพดยุคแรก",                                   "color": Color(1.0, 0.6, 0.0)},
	"apex_hunter":   {"name": "Convergent Predator","desc": "นักล่าแบบลู่เข้าจากหลายสายพันธุ์",                    "color": Color(0.9, 0.3, 0.1)},
	"reptile":       {"name": "Early Reptile",     "desc": "สัตว์เลื้อยคลานยุคแรก",                              "color": Color(0.2, 0.8, 0.2)},
	"winged_insect": {"name": "Winged Insect",     "desc": "แมลงมีปีกยุคคาร์บอนิเฟอรัส",                         "color": Color(0.5, 0.0, 0.8)},
	"cynodont":      {"name": "Cynodont",          "desc": "สัตว์เลื้อยคลานคล้ายสัตว์เลี้ยงลูกด้วยนม",            "color": Color(0.8, 0.5, 0.2)},
	"primeval_dino": {"name": "Primeval Dino",     "desc": "ไดโนเสาร์ยุคแรกเริ่ม",                               "color": Color(0.8, 0.2, 0.1)},
	"swarm_lord":    {"name": "Swarm Lord",        "desc": "จอมแมลงสังคม",                                     "color": Color(0.9, 0.4, 0.0)},
	"mammal":        {"name": "Early Mammal",      "desc": "สัตว์เลี้ยงลูกด้วยนมยุคแรก",                         "color": Color(0.3, 0.5, 0.4)},
	"primate":       {"name": "Primate",           "desc": "สัตว์ตระกูลลิง",                                   "color": Color(0.15, 0.45, 0.55)},
	"human":         {"name": "Human",             "desc": "โฮโม เซเปียนส์",                                   "color": Color(0.85, 0.7, 0.55)},
	"tyrant_king":   {"name": "Tyrant King",       "desc": "ไทแรนโนซอรัส เร็กซ์",                               "color": Color(1.0, 0.1, 0.0)},
	"chitin_beetle": {"name": "Chitin Beetle",     "desc": "แมลงปีกแข็งยักษ์",                                 "color": Color(0.9, 0.7, 0.1)},
	"crab_like":     {"name": "Crab-like",         "desc": "ลูกผสมปลา-แมลง",                                  "color": Color(1.0, 0.5, 0.1)},
	"dragon":        {"name": "Dragon",            "desc": "สัตว์เลื้อยคลานมีปีก",                             "color": Color(1.0, 0.2, 0.0)},
	"chimera":       {"name": "Chimera",           "desc": "ลูกผสมไดโนเสาร์-แมลง",                             "color": Color(0.8, 0.0, 0.8)},
	"rubber_chicken":{"name": "Rubber Chicken",    "desc": "ไก่ยางเด้งดึ๋ง ?!",                                 "color": Color(1.0, 0.8, 0.0)},
	"roomba_lord":   {"name": "Roomba Lord",       "desc": "หุ่นดูดฝุ่นครองโลก",                                "color": Color(0.3, 0.3, 0.3)},
	"t_pose_tyrant": {"name": "T-Pose Tyrant",     "desc": "T-Pose ข่มขวัญศัตรู",                               "color": Color(1.0, 0.3, 0.0)},
}

const _tree_layout: Dictionary = {
	"cell":          Vector2(0.50, 0.08),
	"fish":          Vector2(0.08, 0.22),
	"amphibian":     Vector2(0.26, 0.22),
	"arthropod":     Vector2(0.50, 0.22),
	"synapsid":      Vector2(0.72, 0.22),
	"apex_hunter":   Vector2(0.92, 0.22),
	"reptile":       Vector2(0.18, 0.36),
	"winged_insect": Vector2(0.50, 0.36),
	"cynodont":      Vector2(0.82, 0.36),
	"primeval_dino": Vector2(0.18, 0.50),
	"swarm_lord":    Vector2(0.50, 0.50),
	"mammal":        Vector2(0.82, 0.50),
	"tyrant_king":   Vector2(0.18, 0.63),
	"chitin_beetle": Vector2(0.50, 0.63),
	"primate":       Vector2(0.82, 0.63),
	"human":         Vector2(0.82, 0.76),
	"crab_like":     Vector2(0.34, 0.30),
	"dragon":        Vector2(0.34, 0.44),
	"chimera":       Vector2(0.34, 0.58),
}

const _tree_connections: Array[Array] = [
	["cell", "fish"], ["cell", "amphibian"], ["cell", "arthropod"], ["cell", "synapsid"], ["cell", "apex_hunter"],
	["fish", "amphibian"], ["amphibian", "reptile"], ["arthropod", "winged_insect"],
	["synapsid", "cynodont"], ["apex_hunter", "cynodont"],
	["reptile", "primeval_dino"], ["winged_insect", "swarm_lord"], ["cynodont", "mammal"],
	["primeval_dino", "tyrant_king"], ["swarm_lord", "chitin_beetle"],
	["mammal", "primate"], ["primate", "human"],
]

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.02, 0.02, 0.08))
	_setup_input_map()
	var s = SaveManager.settings
	if s.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var db = linear_to_db(s.volume / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	show_main_menu()

func _clear_view() -> void:
	if _current_view:
		_current_view.queue_free()
		_current_view = null

func _make_bg_cells(vp: Vector2, parent: Node) -> void:
	for i in range(6):
		var cell = ColorRect.new()
		var s = randf_range(12, 40)
		cell.size = Vector2(s, s)
		cell.color = Color(0.2, 1.0, 0.3, 0.06)
		cell.position = Vector2(randf_range(0, vp.x), randf_range(0, vp.y))
		parent.add_child(cell)
		_animate_bg_cell(cell, vp)

func _animate_bg_cell(cell: ColorRect, vp: Vector2) -> void:
	if not is_instance_valid(cell):
		return
	var tween = create_tween().set_parallel(true)
	tween.tween_property(cell, "position", Vector2(randf_range(0, vp.x), randf_range(0, vp.y)), randf_range(6, 12))
	tween.tween_property(cell, "color", Color(randf_range(0.1, 0.3), 1.0, randf_range(0.2, 0.5), 0.06), randf_range(3, 6))
	tween.tween_callback(_animate_bg_cell.bind(cell, vp))

func show_main_menu() -> void:
	_clear_view()
	_in_sub = false
	_sub_btns = []
	_menu_grid = []
	_grid_pos = Vector2i(0, 0)
	_in_main_menu = true
	var view = Node.new()
	view.name = "MainMenu"
	var vp = get_viewport().get_visible_rect().size

	_make_bg_cells(vp, view)

	var title = Label.new()
	title.text = "F.E.W"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.12)
	title.size = Vector2(vp.x, 80)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	view.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Flat Earth Wonders"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, vp.y * 0.12 + 70)
	subtitle.size = Vector2(vp.x, 36)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	view.add_child(subtitle)

	var tagline = Label.new()
	tagline.text = "450 million years in 30 minutes"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.position = Vector2(0, vp.y * 0.12 + 105)
	tagline.size = Vector2(vp.x, 24)
	tagline.add_theme_font_size_override("font_size", 14)
	tagline.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	view.add_child(tagline)

	_menu_grid = [[], [], []]

	var btn_y = vp.y * 0.38
	var has_continue = SaveManager.has_saved_run()
	var run_data = SaveManager.load_run() if has_continue else {}
	if has_continue:
		var continue_btn = Button.new()
		var wave_info = run_data.get("game", {}).get("wave", 0)
		continue_btn.text = "  CONTINUE (Wave %d)" % wave_info
		continue_btn.position = Vector2(vp.x / 2 - 150, btn_y - 60)
		continue_btn.size = Vector2(300, 46)
		continue_btn.add_theme_font_size_override("font_size", 18)
		continue_btn.pressed.connect(func(): _exec_continue())
		_menu_grid[0].append(continue_btn)
		view.add_child(continue_btn)

	var btn2_y = btn_y + 60 if has_continue else btn_y

	var play_btn = Button.new()
	play_btn.text = "  PLAY"
	play_btn.position = Vector2(vp.x / 2 - 150, btn2_y)
	play_btn.size = Vector2(300, 56)
	play_btn.add_theme_font_size_override("font_size", 24)
	play_btn.pressed.connect(func(): _exec_play())
	_menu_grid[0].append(play_btn)
	view.add_child(play_btn)

	var tree_btn = Button.new()
	tree_btn.text = "  Evolution Tree"
	tree_btn.position = Vector2(vp.x * 0.05, vp.y * 0.54)
	tree_btn.size = Vector2(vp.x * 0.42, 46)
	tree_btn.add_theme_font_size_override("font_size", 16)
	tree_btn.pressed.connect(func(): _exec_tree())
	_menu_grid[1].append(tree_btn)
	view.add_child(tree_btn)

	var meta_btn = Button.new()
	meta_btn.text = "  Genetic Memory"
	meta_btn.position = Vector2(vp.x * 0.53, vp.y * 0.54)
	meta_btn.size = Vector2(vp.x * 0.42, 46)
	meta_btn.add_theme_font_size_override("font_size", 16)
	meta_btn.pressed.connect(func(): _exec_meta())
	_menu_grid[1].append(meta_btn)
	view.add_child(meta_btn)

	var scores_btn = Button.new()
	scores_btn.text = "  High Scores"
	scores_btn.position = Vector2(vp.x * 0.05, vp.y * 0.68)
	scores_btn.size = Vector2(vp.x * 0.42, 46)
	scores_btn.add_theme_font_size_override("font_size", 16)
	scores_btn.pressed.connect(func(): _exec_scores())
	_menu_grid[2].append(scores_btn)
	view.add_child(scores_btn)

	var opt_btn = Button.new()
	opt_btn.text = "  Options"
	opt_btn.position = Vector2(vp.x * 0.53, vp.y * 0.68)
	opt_btn.size = Vector2(vp.x * 0.42, 46)
	opt_btn.add_theme_font_size_override("font_size", 16)
	opt_btn.pressed.connect(func(): _exec_options())
	_menu_grid[2].append(opt_btn)
	view.add_child(opt_btn)

	_update_highlight()

	var ver = Label.new()
	ver.text = "v0.6.0"
	ver.position = Vector2(10, vp.y - 25)
	ver.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	ver.add_theme_font_size_override("font_size", 12)
	view.add_child(ver)

	_current_view = view
	add_child(view)

func _update_highlight() -> void:
	for ri in _menu_grid.size():
		for ci in _menu_grid[ri].size():
			var btn = _menu_grid[ri][ci] as Button
			if not btn:
				continue
			if ri == _grid_pos.x and ci == _grid_pos.y:
				btn.modulate = Color(1.3, 1.3, 1.3)
				var s = StyleBoxFlat.new()
				s.bg_color = Color(0.15, 0.15, 0.25)
				s.border_color = Color(0.2, 1.0, 0.3)
				s.set_border_width_all(2)
				btn.add_theme_stylebox_override("normal", s)
			else:
				btn.modulate = Color.WHITE
				var s2 = StyleBoxFlat.new()
				s2.bg_color = Color(0.08, 0.08, 0.15)
				s2.border_color = Color(0.1, 0.1, 0.2)
				s2.set_border_width_all(1)
				btn.add_theme_stylebox_override("normal", s2)

func _nav(dr: int, dc: int) -> void:
	var nr = _grid_pos.x + dr
	var nc = _grid_pos.y + dc
	nr = clampi(nr, 0, _menu_grid.size() - 1)
	nc = clampi(nc, 0, _menu_grid[nr].size() - 1)
	if nr == _grid_pos.x and nc == _grid_pos.y:
		return
	_grid_pos = Vector2i(nr, nc)
	_update_highlight()
	AudioManager.play_sfx("click")

func _activate() -> void:
	var btn = _menu_grid[_grid_pos.x][_grid_pos.y] as Button
	if btn:
		btn.emit_signal("pressed")

func _exec_continue() -> void:
	AudioManager.play_sfx("click")
	_in_main_menu = false
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _exec_play() -> void:
	AudioManager.play_sfx("click")
	SaveManager.delete_saved_run()
	_on_play()

func _exec_tree() -> void:
	AudioManager.play_sfx("click")
	_on_evolution_tree()

func _exec_meta() -> void:
	AudioManager.play_sfx("click")
	_on_genetic_memory()

func _exec_scores() -> void:
	AudioManager.play_sfx("click")
	show_high_scores_view()

func _exec_options() -> void:
	AudioManager.play_sfx("click")
	show_options_view()

func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if _quit_popup:
		if event is InputEventJoypadMotion:
			if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
				_quit_sel = (_quit_sel + 1) % _quit_btns.size()
				_quit_highlight()
				AudioManager.play_sfx("click")
				get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			_quit_sel = (_quit_sel + 1) % _quit_btns.size()
			_quit_highlight()
			AudioManager.play_sfx("click")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_quit_btns[_quit_sel].emit_signal("pressed")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			_dismiss_quit()
			get_viewport().set_input_as_handled()
		return
	if _in_sub:
		if event is InputEventJoypadMotion:
			if Input.is_action_just_pressed("move_up"):
				_sub_idx = (_sub_idx - 1 + _sub_btns.size()) % _sub_btns.size()
				_update_sub_highlight()
				get_viewport().set_input_as_handled()
			elif Input.is_action_just_pressed("move_down"):
				_sub_idx = (_sub_idx + 1) % _sub_btns.size()
				_update_sub_highlight()
				get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_up"):
			_sub_idx = (_sub_idx - 1 + _sub_btns.size()) % _sub_btns.size()
			_update_sub_highlight()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down"):
			_sub_idx = (_sub_idx + 1) % _sub_btns.size()
			_update_sub_highlight()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			AudioManager.play_sfx("click")
			_sub_btns[_sub_idx].emit_signal("pressed")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			AudioManager.play_sfx("click")
			_sub_back.call()
			get_viewport().set_input_as_handled()
		return
	if _in_main_menu:
		if event is InputEventJoypadMotion:
			if Input.is_action_just_pressed("move_up"):
				_nav(-1, 0); get_viewport().set_input_as_handled()
			elif Input.is_action_just_pressed("move_down"):
				_nav(1, 0); get_viewport().set_input_as_handled()
			elif Input.is_action_just_pressed("move_left"):
				_nav(0, -1); get_viewport().set_input_as_handled()
			elif Input.is_action_just_pressed("move_right"):
				_nav(0, 1); get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("move_up"):
			_nav(-1, 0)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down"):
			_nav(1, 0)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_left"):
			_nav(0, -1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_right"):
			_nav(0, 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_activate()
		elif event.is_action_pressed("ui_cancel"):
			_show_quit_popup()
			get_viewport().set_input_as_handled()

func _update_sub_highlight() -> void:
	for i in _sub_btns.size():
		var btn = _sub_btns[i]
		if i == _sub_idx:
			var s = StyleBoxFlat.new()
			s.bg_color = Color(0.15, 0.15, 0.25)
			s.border_color = Color(0.2, 1.0, 0.3)
			s.set_border_width_all(2)
			btn.add_theme_stylebox_override("normal", s)
		else:
			var s2 = StyleBoxFlat.new()
			s2.bg_color = Color(0.08, 0.08, 0.15)
			s2.border_color = Color(0.1, 0.1, 0.2)
			s2.set_border_width_all(1)
			btn.add_theme_stylebox_override("normal", s2)

func _show_quit_popup() -> void:
	if _quit_popup:
		return
	_in_main_menu = false
	_quit_popup = Node.new()
	_quit_btns = []
	_quit_sel = 0
	var vp = get_viewport().get_visible_rect().size

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = vp
	_quit_popup.add_child(overlay)

	var box = ColorRect.new()
	box.color = Color(0.05, 0.05, 0.15)
	box.size = Vector2(360, 160)
	box.position = vp / 2 - box.size / 2
	_quit_popup.add_child(box)

	var q = Label.new()
	q.text = "Exit to desktop?"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.position = Vector2(0, -40)
	q.size = Vector2(360, 40)
	q.add_theme_font_size_override("font_size", 22)
	q.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(q)

	var yes_btn = Button.new()
	yes_btn.name = "YesBtn"
	yes_btn.text = "  YES"
	yes_btn.position = Vector2(30, 30)
	yes_btn.size = Vector2(130, 46)
	yes_btn.add_theme_font_size_override("font_size", 18)
	yes_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		get_tree().quit())
	box.add_child(yes_btn)
	_quit_btns.append(yes_btn)

	var no_btn = Button.new()
	no_btn.name = "NoBtn"
	no_btn.text = "  NO"
	no_btn.position = Vector2(200, 30)
	no_btn.size = Vector2(130, 46)
	no_btn.add_theme_font_size_override("font_size", 18)
	no_btn.pressed.connect(func():
		AudioManager.play_sfx("click")
		_dismiss_quit())
	box.add_child(no_btn)
	_quit_btns.append(no_btn)

	add_child(_quit_popup)
	_quit_highlight()

func _quit_highlight() -> void:
	for i in _quit_btns.size():
		var btn = _quit_btns[i]
		var s = StyleBoxFlat.new()
		if i == _quit_sel:
			s.bg_color = Color(0.15, 0.15, 0.25)
			s.border_color = Color(0.2, 1.0, 0.3)
			s.set_border_width_all(2)
		else:
			s.bg_color = Color(0.08, 0.08, 0.15)
			s.border_color = Color(0.1, 0.1, 0.2)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", s)

func _dismiss_quit() -> void:
	if _quit_popup:
		_quit_popup.queue_free()
		_quit_popup = null
	_quit_btns = []
	_in_main_menu = true

func _on_play() -> void:
	_in_main_menu = false
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_evolution_tree() -> void:
	show_evolution_tree_view()

func _on_genetic_memory() -> void:
	if not _in_main_menu:
		return
	_in_main_menu = false
	var meta_screen = load("res://ui/MetaScreen.gd").new()
	meta_screen.tree_exited.connect(func(): _in_main_menu = true, CONNECT_ONE_SHOT)
	get_tree().root.call_deferred("add_child", meta_screen)

func _on_options() -> void:
	show_options_view()

func show_evolution_tree_view() -> void:
	_in_main_menu = false
	_clear_view()
	var view = Node.new()
	view.name = "TreeView"
	var vp = get_viewport().get_visible_rect().size

	var title = Label.new()
	title.text = "EVOLUTION TREE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.04)
	title.size = Vector2(vp.x, 36)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	view.add_child(title)

	var canvas = TreeCanvasScript.new()
	canvas.position = Vector2.ZERO
	canvas.size = vp
	view.add_child(canvas)

	var form_ids = ["cell", "fish", "amphibian", "arthropod", "synapsid", "apex_hunter", "reptile", "winged_insect", "cynodont", "primeval_dino", "swarm_lord", "mammal", "tyrant_king", "chitin_beetle", "primate", "human"]
	var pos_map: Dictionary = {}
	for form_id in form_ids:
		var rel = _tree_layout[form_id]
		var pos = Vector2(vp.x * rel.x, vp.y * rel.y)
		pos_map[form_id] = pos

	for conn in _tree_connections:
		var a = pos_map[conn[0]]
		var b = pos_map[conn[1]]
		canvas.add_line(a + Vector2(0, 14), b - Vector2(0, 14))

	for form_id in form_ids:
		var data = _tree_data[form_id]
		var pos = pos_map[form_id]
		var unlocked = SaveManager.is_form_unlocked(form_id)

		var card = ColorRect.new()
		card.size = Vector2(150, 28)
		card.position = pos - Vector2(75, 14)
		card.color = Color(data.color.r, data.color.g, data.color.b, 0.25 if unlocked else 0.06)
		view.add_child(card)

		var name_label = Label.new()
		name_label.text = data.name
		name_label.position = pos - Vector2(72, 10)
		name_label.size = Vector2(144, 16)
		name_label.add_theme_font_size_override("font_size", 9)
		var nc = Color(data.color.r, data.color.g, data.color.b, 1.0) if unlocked else Color(0.3, 0.3, 0.3)
		name_label.add_theme_color_override("font_color", nc)
		view.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = data.desc if unlocked else "???"
		desc_label.position = pos - Vector2(72, 2)
		desc_label.size = Vector2(144, 14)
		desc_label.add_theme_font_size_override("font_size", 7)
		var dc = Color(0.6, 0.6, 0.6) if unlocked else Color(0.2, 0.2, 0.2)
		desc_label.add_theme_color_override("font_color", dc)
		view.add_child(desc_label)

	var back = Button.new()
	back.text = "  Back"
	back.position = Vector2(vp.x / 2 - 60, vp.y * 0.88)
	back.size = Vector2(120, 36)
	back.add_theme_font_size_override("font_size", 16)
	back.pressed.connect(func():
		show_main_menu())
	view.add_child(back)

	_current_view = view
	add_child(view)

	_sub_btns = [back]
	_sub_idx = 0
	_sub_back = Callable(show_main_menu)
	_in_sub = true
	_update_sub_highlight()

func show_high_scores_view() -> void:
	_in_main_menu = false
	_clear_view()
	var view = Node.new()
	view.name = "HighScoresView"
	var vp = get_viewport().get_visible_rect().size

	var title = Label.new()
	title.text = "HIGH SCORES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.06)
	title.size = Vector2(vp.x, 40)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	view.add_child(title)

	var scores = SaveManager.highscores
	if scores.is_empty():
		var empty = Label.new()
		empty.text = "No scores yet"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.position = Vector2(0, vp.y * 0.35)
		empty.size = Vector2(vp.x, 30)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty.add_theme_font_size_override("font_size", 18)
		view.add_child(empty)
	else:
		var header = Label.new()
		header.text = "%-4s %8s %4s %-20s" % ["#", "Score", "Wave", "Form"]
		header.position = Vector2(vp.x * 0.15, vp.y * 0.14)
		header.size = Vector2(vp.x * 0.7, 22)
		header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		header.add_theme_font_size_override("font_size", 12)
		view.add_child(header)

		for i in range(scores.size()):
			var e = scores[i]
			var fname = SaveManager.get_form_name(e.get("form", ""))
			var row = Label.new()
			row.text = "%-4s %8s %4s %-20s" % [i + 1, e.score, e.wave, fname]
			row.position = Vector2(vp.x * 0.15, vp.y * 0.14 + 28 + i * 24)
			row.size = Vector2(vp.x * 0.7, 22)
			row.add_theme_color_override("font_color", Color.WHITE if i < 3 else Color(0.6, 0.6, 0.6))
			row.add_theme_font_size_override("font_size", 13)
			view.add_child(row)

	var back = Button.new()
	back.text = "  Back"
	back.position = Vector2(vp.x / 2 - 60, vp.y * 0.88)
	back.size = Vector2(120, 36)
	back.add_theme_font_size_override("font_size", 16)
	back.pressed.connect(func():
		show_main_menu())
	view.add_child(back)

	_current_view = view
	add_child(view)

	_sub_btns = [back]
	_sub_idx = 0
	_sub_back = Callable(show_main_menu)
	_in_sub = true
	_update_sub_highlight()

func show_options_view() -> void:
	_in_main_menu = false
	_clear_view()
	var view = Node.new()
	view.name = "OptionsView"
	var vp = get_viewport().get_visible_rect().size

	var title = Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.10)
	title.size = Vector2(vp.x, 50)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	view.add_child(title)

	var vol_label = Label.new()
	vol_label.text = "Master Volume"
	vol_label.position = Vector2(vp.x / 2 - 170, vp.y * 0.30)
	vol_label.size = Vector2(160, 30)
	vol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vol_label.add_theme_color_override("font_color", Color.WHITE)
	view.add_child(vol_label)

	var saved_vol = SaveManager.settings.volume
	var saved_fs = SaveManager.settings.fullscreen

	var fs_check = CheckBox.new()
	fs_check.text = "Fullscreen"
	fs_check.position = Vector2(vp.x / 2 - 100, vp.y * 0.42)
	fs_check.size = Vector2(200, 30)
	fs_check.button_pressed = saved_fs
	fs_check.toggled.connect(_on_fullscreen_toggled)
	view.add_child(fs_check)

	var vol_slider = HSlider.new()
	vol_slider.position = Vector2(vp.x / 2, vp.y * 0.30)
	vol_slider.size = Vector2(160, 30)
	vol_slider.min_value = 0.0
	vol_slider.max_value = 100.0
	vol_slider.value = saved_vol
	vol_slider.value_changed.connect(_on_volume_changed)
	view.add_child(vol_slider)

	var vol_value = Label.new()
	vol_value.text = str(vol_slider.value as int)
	vol_value.position = Vector2(vp.x / 2 + 170, vp.y * 0.30)
	vol_value.size = Vector2(40, 30)
	vol_value.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	view.add_child(vol_value)
	vol_slider.value_changed.connect(func(v):
		vol_value.text = str(v as int)
		SaveManager.save_settings(vol_slider.value, fs_check.button_pressed))

	var back = Button.new()
	back.text = "  Back"
	back.position = Vector2(vp.x / 2 - 60, vp.y * 0.70)
	back.size = Vector2(120, 45)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(func():
		show_main_menu())
	view.add_child(back)

	_current_view = view
	add_child(view)

	_sub_btns = [fs_check, back]
	_sub_idx = 0
	_sub_back = Callable(show_main_menu)
	_in_sub = true
	_update_sub_highlight()

func _on_volume_changed(value: float) -> void:
	_volume = value
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	SaveManager.save_settings(_volume, toggled)

func _setup_input_map() -> void:
	var pairs = {
		"ui_accept": [JOY_BUTTON_A],
		"ui_cancel": [JOY_BUTTON_B],
		"ui_up": [10],
		"ui_down": [11],
		"ui_left": [12],
		"ui_right": [13],
	}
	for action in pairs:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var has_joy_btn = false
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton:
				has_joy_btn = true
				break
		if not has_joy_btn:
			for btn in pairs[action]:
				var je = InputEventJoypadButton.new()
				je.button_index = btn
				InputMap.action_add_event(action, je)

	var nav_actions = ["move_left", "move_right", "move_up", "move_down"]
	for action in nav_actions:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action)

	var left_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	left_events[0].keycode = KEY_A
	left_events[1].keycode = KEY_LEFT
	left_events[2].axis = JOY_AXIS_LEFT_X
	left_events[2].axis_value = -1.0
	left_events[3].button_index = 12
	for e in left_events:
		InputMap.action_add_event("move_left", e)

	var right_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	right_events[0].keycode = KEY_D
	right_events[1].keycode = KEY_RIGHT
	right_events[2].axis = JOY_AXIS_LEFT_X
	right_events[2].axis_value = 1.0
	right_events[3].button_index = 13
	for e in right_events:
		InputMap.action_add_event("move_right", e)

	var up_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	up_events[0].keycode = KEY_W
	up_events[1].keycode = KEY_UP
	up_events[2].axis = JOY_AXIS_LEFT_Y
	up_events[2].axis_value = -1.0
	up_events[3].button_index = 10
	for e in up_events:
		InputMap.action_add_event("move_up", e)

	var down_events = [
		InputEventKey.new(), InputEventKey.new(), InputEventJoypadMotion.new(), InputEventJoypadButton.new()
	]
	down_events[0].keycode = KEY_S
	down_events[1].keycode = KEY_DOWN
	down_events[2].axis = JOY_AXIS_LEFT_Y
	down_events[2].axis_value = 1.0
	down_events[3].button_index = 11
	for e in down_events:
		InputMap.action_add_event("move_down", e)
