extends CanvasLayer
class_name Menu

const TreeCanvasScript = preload("res://ui/TreeCanvas.gd")

var _current_view: Node = null
var _volume: float = 80.0

const _tree_data: Dictionary = {
	"cell":          {"name": "Single Cell",       "desc": "จุดเริ่มต้นของทุกชีวิต",                        "color": Color(0.2, 1.0, 0.3)},
	"fish":          {"name": "Ancient Fish",      "desc": "สัตว์มีกระดูกสันหลังชนิดแรก",                    "color": Color(0.0, 0.8, 1.0)},
	"amphibian":     {"name": "Primitive Amphibian","desc": "ก้าวแรกสู่พื้นดิน",                            "color": Color(1.0, 0.6, 0.0)},
	"bug":           {"name": "Giant Insect",      "desc": "แมลงยุคคาร์บอนิเฟอรัส",                        "color": Color(0.7, 0.2, 0.9)},
	"predator":      {"name": "Simple Predator",   "desc": "นักล่ายุคแรก — จู่โจมด้วยคมฟัน",               "color": Color(0.9, 0.3, 0.1)},
	"reptile":       {"name": "Early Reptile",     "desc": "สัตว์เลื้อยคลานยุคแรก — สมดุลทุกด้าน",          "color": Color(0.2, 0.8, 0.2)},
	"winged_insect": {"name": "Winged Insect",     "desc": "แมลงมีปีก — เร้นลับและแม่นยำ",                 "color": Color(0.5, 0.0, 0.8)},
	"primeval_dino": {"name": "Primeval Dino",     "desc": "ไดโนเสาร์ยุคแรกเริ่ม — พลังทำลายล้างสูง",        "color": Color(0.8, 0.2, 0.1)},
	"swarm_lord":    {"name": "Swarm Lord",        "desc": "จอมแมลง — เร็ว จัดหนัก จัดเบา",                "color": Color(0.9, 0.4, 0.0)},
	"tyrant_king":   {"name": "Tyrant King",       "desc": "จ้าวไดโนเสาร์ — พิบัติแก่ศัตรู",                 "color": Color(1.0, 0.1, 0.0)},
	"chitin_beetle": {"name": "Chitin Beetle",     "desc": "แมลงปีกแข็งยักษ์ — เกราะหนาทนทาน",            "color": Color(0.9, 0.7, 0.1)},
	"crab_like":     {"name": "Crab-like",         "desc": "ลูกผสมปลา-แมลง — เกราะแข็ง ก้ามทะลวง",        "color": Color(1.0, 0.5, 0.1)},
	"dragon":        {"name": "Dragon",            "desc": "สัตว์เลื้อยคลานมีปีก — เพลิงผลาญทุกสิ่ง",       "color": Color(1.0, 0.2, 0.0)},
	"chimera":       {"name": "Chimera",           "desc": "ลูกผสมไดโนเสาร์-แมลง — หัวสามหัว สามอาวุธ",    "color": Color(0.8, 0.0, 0.8)},
}

const _tree_layout: Dictionary = {
	"cell":          Vector2(0.50, 0.12),
	"fish":          Vector2(0.14, 0.27),
	"amphibian":     Vector2(0.38, 0.27),
	"bug":           Vector2(0.62, 0.27),
	"predator":      Vector2(0.86, 0.27),
	"reptile":       Vector2(0.30, 0.42),
	"winged_insect": Vector2(0.70, 0.42),
	"crab_like":     Vector2(0.50, 0.42),
	"primeval_dino": Vector2(0.30, 0.56),
	"swarm_lord":    Vector2(0.70, 0.56),
	"dragon":        Vector2(0.50, 0.56),
	"tyrant_king":   Vector2(0.30, 0.69),
	"chitin_beetle": Vector2(0.70, 0.69),
	"chimera":       Vector2(0.50, 0.69),
}

const _tree_connections: Array[Array] = [
	["cell", "fish"],
	["cell", "amphibian"],
	["cell", "bug"],
	["cell", "predator"],
	["fish", "reptile"],
	["amphibian", "reptile"],
	["bug", "winged_insect"],
	["predator", "reptile"],
	["fish", "crab_like"],
	["bug", "crab_like"],
	["reptile", "primeval_dino"],
	["winged_insect", "swarm_lord"],
	["reptile", "dragon"],
	["winged_insect", "dragon"],
	["primeval_dino", "tyrant_king"],
	["swarm_lord", "chitin_beetle"],
	["primeval_dino", "chimera"],
	["swarm_lord", "chimera"],
]

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.02, 0.02, 0.08))
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
		cell.name = "bg_cell_" + str(i)
		parent.add_child(cell)
		var tween = create_tween().set_loops().set_parallel(true)
		tween.tween_property(cell, "position", Vector2(randf_range(0, vp.x), randf_range(0, vp.y)), randf_range(6, 12))
		tween.tween_property(cell, "color", Color(randf_range(0.1, 0.3), 1.0, randf_range(0.2, 0.5), 0.06), randf_range(3, 6))

func show_main_menu() -> void:
	_clear_view()
	var view = Node.new()
	view.name = "MainMenu"
	var vp = get_viewport().get_visible_rect().size

	_make_bg_cells(vp, view)

	var title = Label.new()
	title.text = "BATTLE CELL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.18)
	title.size = Vector2(vp.x, 80)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	view.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "EVOLUTION"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, vp.y * 0.18 + 75)
	subtitle.size = Vector2(vp.x, 40)
	subtitle.add_theme_font_size_override("font_size", 32)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	view.add_child(subtitle)

	var tagline = Label.new()
	tagline.text = "450 million years in 30 minutes"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.position = Vector2(0, vp.y * 0.18 + 112)
	tagline.size = Vector2(vp.x, 30)
	tagline.add_theme_font_size_override("font_size", 16)
	tagline.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	view.add_child(tagline)

	var btn_defs = [
		{"text": "  PLAY", "cb": _on_play},
		{"text": "  Evolution Tree", "cb": _on_evolution_tree},
		{"text": "  Options", "cb": _on_options},
	]
	var start_y = vp.y * 0.55
	for i in range(btn_defs.size()):
		var btn = Button.new()
		btn.text = btn_defs[i].text
		btn.position = Vector2(vp.x / 2 - 130, start_y + i * 60)
		btn.size = Vector2(260, 50)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(btn_defs[i].cb)
		view.add_child(btn)

	var ver = Label.new()
	ver.text = "v0.3.0"
	ver.position = Vector2(10, vp.y - 25)
	ver.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	ver.add_theme_font_size_override("font_size", 12)
	view.add_child(ver)

	_current_view = view
	add_child(view)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_evolution_tree() -> void:
	show_evolution_tree_view()

func _on_options() -> void:
	show_options_view()

func show_evolution_tree_view() -> void:
	_clear_view()
	var view = Node.new()
	view.name = "TreeView"
	var vp = get_viewport().get_visible_rect().size

	var title = Label.new()
	title.text = "EVOLUTION TREE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.06)
	title.size = Vector2(vp.x, 40)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	view.add_child(title)

	var canvas = TreeCanvasScript.new()
	canvas.position = Vector2.ZERO
	canvas.size = vp
	view.add_child(canvas)

	var form_ids = ["cell", "fish", "amphibian", "bug", "predator", "reptile", "winged_insect", "crab_like", "primeval_dino", "swarm_lord", "dragon", "tyrant_king", "chitin_beetle", "chimera"]
	var pos_map: Dictionary = {}
	for form_id in form_ids:
		var rel = _tree_layout[form_id]
		var pos = Vector2(vp.x * rel.x, vp.y * rel.y)
		pos_map[form_id] = pos

	for conn in _tree_connections:
		var a = pos_map[conn[0]]
		var b = pos_map[conn[1]]
		canvas.add_line(a + Vector2(0, 19), b - Vector2(0, 19))

	for form_id in form_ids:
		var data = _tree_data[form_id]
		var pos = pos_map[form_id]

		var card = ColorRect.new()
		card.size = Vector2(160, 38)
		card.position = pos - Vector2(80, 19)
		card.color = Color(data.color.r, data.color.g, data.color.b, 0.25)
		view.add_child(card)

		var name_label = Label.new()
		name_label.text = data.name
		name_label.position = pos - Vector2(76, 14)
		name_label.size = Vector2(152, 18)
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color(data.color.r, data.color.g, data.color.b, 1.0))
		view.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = data.desc
		desc_label.position = pos - Vector2(76, 2)
		desc_label.size = Vector2(152, 16)
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		view.add_child(desc_label)

	var back = Button.new()
	back.text = "  Back"
	back.position = Vector2(vp.x / 2 - 60, vp.y * 0.88)
	back.size = Vector2(120, 40)
	back.pressed.connect(show_main_menu)
	view.add_child(back)

	_current_view = view
	add_child(view)

func show_options_view() -> void:
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
	vol_label.add_theme_color_override("font_color", Color.WHITE)
	view.add_child(vol_label)

	var vol_slider = HSlider.new()
	vol_slider.position = Vector2(vp.x / 2, vp.y * 0.30)
	vol_slider.size = Vector2(160, 30)
	vol_slider.min_value = 0.0
	vol_slider.max_value = 100.0
	vol_slider.value = _volume
	vol_slider.value_changed.connect(_on_volume_changed)
	view.add_child(vol_slider)

	var vol_value = Label.new()
	vol_value.text = str(vol_slider.value as int)
	vol_value.position = Vector2(vp.x / 2 + 170, vp.y * 0.30)
	vol_value.size = Vector2(40, 30)
	vol_value.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	view.add_child(vol_value)
	vol_slider.value_changed.connect(func(v): vol_value.text = str(v as int))

	var fs_check = CheckBox.new()
	fs_check.text = "Fullscreen"
	fs_check.position = Vector2(vp.x / 2 - 100, vp.y * 0.42)
	fs_check.size = Vector2(200, 30)
	fs_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_check.toggled.connect(_on_fullscreen_toggled)
	view.add_child(fs_check)

	var back = Button.new()
	back.text = "  Back"
	back.position = Vector2(vp.x / 2 - 60, vp.y * 0.70)
	back.size = Vector2(120, 45)
	back.pressed.connect(show_main_menu)
	view.add_child(back)

	_current_view = view
	add_child(view)

func _on_volume_changed(value: float) -> void:
	_volume = value
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
