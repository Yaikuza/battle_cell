@tool
extends SceneTree

const SIZE := 64
const DIR := "res://art/forms/"

func _init() -> void:
	_generate_all()
	print("Sprites generated to ", DIR)
	quit()

func _generate_all() -> void:
	var forms = {
		"cell": _draw_cell,
		"fish": _draw_fish,
		"amphibian": _draw_amphibian,
		"arthropod": _draw_arthropod,
		"apex_hunter": _draw_apex_hunter,
		"synapsid": _draw_synapsid,
		"reptile": _draw_reptile,
		"winged_insect": _draw_winged_insect,
		"cynodont": _draw_cynodont,
		"primeval_dino": _draw_primeval_dino,
		"swarm_lord": _draw_swarm_lord,
		"mammal": _draw_mammal,
		"primate": _draw_primate,
		"human": _draw_human,
		"tyrant_king": _draw_tyrant_king,
		"chitin_beetle": _draw_chitin_beetle,
		"crab_like": _draw_crab_like,
		"dragon": _draw_dragon,
		"chimera": _draw_chimera,
		"rubber_chicken": _draw_rubber_chicken,
		"roomba_lord": _draw_roomba_lord,
		"t_pose_tyrant": _draw_t_pose_tyrant,
	}
	for form_id in forms:
		var img = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		forms[form_id].call(img)
		img.save_png(DIR + form_id + ".png")

	var extras = [
		["bullet", _draw_bullet], ["orb", _draw_orb], ["enemy", _draw_enemy_generic],
		["trilobite", _draw_trilobite], ["anomalocaris", _draw_anomalocaris],
		["jellyfish", _draw_jellyfish], ["placoderm", _draw_placoderm],
		["ammonite", _draw_ammonite], ["temnospondyl", _draw_temnospondyl],
		["dilophosaurus", _draw_dilophosaurus], ["stegosaurus", _draw_stegosaurus],
		["pterosaur", _draw_pterosaur], ["velociraptor", _draw_velociraptor],
		["triceratops", _draw_triceratops], ["pachycephalosaurus", _draw_pachycephalosaurus],
		["mutant", _draw_mutant], ["crystal_entity", _draw_crystal_entity],
		["void_walker", _draw_void_walker],
		["dimetrodon", _draw_dimetrodon], ["allosaurus", _draw_allosaurus],
		["omega_mutant", _draw_omega_mutant],
	]
	for pair in extras:
		var img = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		pair[1].call(img)
		img.save_png(DIR + pair[0] + ".png")

static func _fc(img: Image, x: float, y: float, r: float, c: Color) -> void:
	var cx := int(x); var cy := int(y); var rr := ceili(r)
	for py in range(cy - rr, cy + rr + 1):
		for px in range(cx - rr, cx + rr + 1):
			if Vector2(px - cx, py - cy).length_squared() <= r * r:
				img.set_pixel(px, py, c)

static func _fe(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var icx := int(cx); var icy := int(cy); var irx := ceili(rx); var iry := ceili(ry)
	for py in range(icy - iry, icy + iry + 1):
		for px in range(icx - irx, icx + irx + 1):
			var dx := (px - icx) / rx; var dy := (py - icy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(px, py, c)

static func _ft(img: Image, p1: Vector2, p2: Vector2, p3: Vector2, c: Color) -> void:
	var min_y := mini(p1.y, mini(p2.y, p3.y)); var max_y := maxi(p1.y, maxi(p2.y, p3.y))
	for py in range(int(min_y), int(max_y) + 1):
		var xs: Array[float] = []
		for pair in [[p1, p2], [p2, p3], [p3, p1]]:
			var a := pair[0] as Vector2; var b := pair[1] as Vector2
			if a.y == b.y: continue
			var t := (py - a.y) / (b.y - a.y)
			if t >= 0.0 and t <= 1.0: xs.append(a.x + t * (b.x - a.x))
		if xs.size() >= 2:
			xs.sort()
			for px in range(int(xs[0]), int(xs[xs.size() - 1]) + 1):
				img.set_pixel(px, py, c)

static func _fl(img: Image, x1: float, y1: float, x2: float, y2: float, r: float, c: Color) -> void:
	var steps := ceili(Vector2(x2 - x1, y2 - y1).length() / 0.5)
	for i in range(steps):
		var t := float(i) / steps
		img.set_pixel(int(x1 + t * (x2 - x1)), int(y1 + t * (y2 - y1)), c)
		if r > 0.5: _fc(img, x1 + t * (x2 - x1), y1 + t * (y2 - y1), r, c)

# --- Form drawing functions ---

static func _draw_cell(img: Image) -> void:
	var g := Color(0.2, 0.9, 0.3); var dg := Color(0.1, 0.6, 0.2); var w := Color(1, 1, 1, 0.5)
	_fc(img, 32, 32, 22, g); _fc(img, 32, 32, 18, dg)
	_fc(img, 32, 32, 7, Color(0.4, 1.0, 0.5)); _fc(img, 32, 32, 4, w)
	_fc(img, 22, 24, 2, Color(0.3, 1.0, 0.4, 0.7)); _fc(img, 42, 26, 2, Color(0.3, 1.0, 0.4, 0.7))
	_fc(img, 44, 38, 1.5, Color(0.3, 1.0, 0.4, 0.7)); _fc(img, 20, 40, 1.5, Color(0.3, 1.0, 0.4, 0.7))

static func _draw_fish(img: Image) -> void:
	var b := Color(0.0, 0.7, 1.0); var db := Color(0.0, 0.4, 0.7)
	_fe(img, 26, 34, 16, 9, b); _ft(img, Vector2(42, 34), Vector2(56, 22), Vector2(56, 46), b)
	_ft(img, Vector2(18, 24), Vector2(26, 24), Vector2(18, 32), b); _ft(img, Vector2(18, 44), Vector2(26, 44), Vector2(18, 36), b)
	_fc(img, 20, 30, 3, Color.WHITE); _fc(img, 19, 30, 1.5, Color.BLACK)

static func _draw_amphibian(img: Image) -> void:
	var o := Color(1.0, 0.55, 0.0); var do_ := Color(0.7, 0.35, 0.0)
	_fe(img, 32, 36, 13, 9, o); _fc(img, 30, 28, 6, o)
	_fc(img, 28, 27, 1.5, Color.BLACK); _fc(img, 31, 27, 1.2, Color.WHITE)
	_fe(img, 24, 42, 4, 2, do_); _fe(img, 40, 42, 4, 2, do_)
	_fe(img, 22, 46, 3, 2, do_); _fe(img, 42, 46, 3, 2, do_)

static func _draw_arthropod(img: Image) -> void:
	var p := Color(0.65, 0.15, 0.85); var dp := Color(0.4, 0.1, 0.6)
	_fe(img, 32, 36, 12, 9, p); _fc(img, 26, 26, 5, p)
	_fc(img, 24, 25, 1.2, Color.WHITE); _fc(img, 27, 25, 1.2, Color.WHITE)
	_fc(img, 25, 24, 0.8, Color.BLACK); _fc(img, 28, 24, 0.8, Color.BLACK)
	_fl(img, 22, 20, 26, 24, 1, dp); _fl(img, 30, 20, 28, 24, 1, dp)
	_fl(img, 24, 34, 12, 30, 1.5, dp); _fl(img, 40, 34, 52, 30, 1.5, dp)
	_fl(img, 24, 38, 12, 42, 1.5, dp); _fl(img, 40, 38, 52, 42, 1.5, dp)
	_fl(img, 26, 42, 18, 48, 1.5, dp); _fl(img, 38, 42, 46, 48, 1.5, dp)

static func _draw_apex_hunter(img: Image) -> void:
	var r := Color(0.85, 0.25, 0.05); var dr := Color(0.6, 0.15, 0.0)
	_fe(img, 32, 34, 12, 11, r); _fe(img, 32, 24, 10, 8, r)
	_ft(img, Vector2(24, 22), Vector2(40, 22), Vector2(32, 16), dr)
	_fc(img, 28, 22, 2, Color.WHITE); _fc(img, 36, 22, 2, Color.WHITE)
	_fc(img, 28, 22, 1, Color.RED); _fc(img, 36, 22, 1, Color.RED)
	_ft(img, Vector2(26, 28), Vector2(38, 28), Vector2(32, 34), Color(1, 0.5, 0.5, 0.6))

static func _draw_synapsid(img: Image) -> void:
	var b := Color(0.55, 0.25, 0.05); var db := Color(0.4, 0.15, 0.0)
	_fe(img, 32, 36, 14, 10, b); _fc(img, 22, 30, 7, b)
	_fc(img, 20, 28, 1.5, Color(1, 0.8, 0.2)); _fc(img, 20, 28, 0.8, Color.BLACK)
	_ft(img, Vector2(26, 22), Vector2(30, 22), Vector2(28, 4), db)
	_ft(img, Vector2(30, 22), Vector2(34, 22), Vector2(32, 2), Color(0.6, 0.3, 0.05))
	_ft(img, Vector2(34, 22), Vector2(38, 22), Vector2(36, 4), db)
	_fe(img, 22, 46, 4, 3, db); _fe(img, 30, 46, 4, 3, db); _fe(img, 44, 36, 8, 4, b)

static func _draw_reptile(img: Image) -> void:
	var g := Color(0.15, 0.75, 0.15); var dg := Color(0.1, 0.5, 0.1)
	_fe(img, 34, 34, 14, 8, g); _fc(img, 26, 28, 6, g)
	_fc(img, 24, 27, 1.2, Color(1, 0.8, 0.2)); _fc(img, 26, 27, 0.6, Color.BLACK)
	_fl(img, 24, 40, 18, 46, 2, dg); _fl(img, 30, 40, 26, 46, 2, dg)
	_fl(img, 38, 40, 34, 46, 2, dg); _fl(img, 44, 40, 48, 46, 2, dg)
	_fe(img, 48, 36, 8, 3, g)

static func _draw_winged_insect(img: Image) -> void:
	var p := Color(0.45, 0.0, 0.75); var dp := Color(0.3, 0.0, 0.5)
	_fe(img, 32, 36, 11, 8, p); _fc(img, 28, 28, 4, p)
	_fc(img, 26, 27, 1, Color.WHITE); _fc(img, 29, 27, 1, Color.WHITE)
	_fc(img, 27, 26, 0.6, Color.BLACK); _fc(img, 30, 26, 0.6, Color.BLACK)
	_fe(img, 20, 32, 8, 4, Color(0.7, 0.3, 0.9, 0.5)); _fe(img, 44, 32, 8, 4, Color(0.7, 0.3, 0.9, 0.5))
	_fl(img, 24, 20, 28, 26, 1, dp); _fl(img, 32, 20, 30, 26, 1, dp)
	_fl(img, 26, 44, 20, 52, 1, dp); _fl(img, 38, 44, 44, 52, 1, dp)

static func _draw_cynodont(img: Image) -> void:
	var br := Color(0.7, 0.4, 0.15); var db := Color(0.5, 0.25, 0.05)
	_fe(img, 32, 34, 12, 9, br); _fc(img, 22, 28, 6, br)
	_fe(img, 28, 22, 5, 4, db); _fc(img, 20, 26, 1.5, Color(1, 0.8, 0.2))
	_fc(img, 20, 26, 0.8, Color.BLACK)
	_fl(img, 18, 32, 8, 34, 1.5, db); _fl(img, 46, 32, 56, 34, 1.5, db)
	_fe(img, 20, 44, 3, 3, db); _fe(img, 26, 44, 3, 3, db)
	_fe(img, 34, 44, 3, 3, db); _fe(img, 40, 44, 3, 3, db)

static func _draw_primeval_dino(img: Image) -> void:
	var r := Color(0.75, 0.15, 0.05); var dr := Color(0.5, 0.1, 0.0)
	_fe(img, 30, 36, 16, 12, r); _fc(img, 20, 30, 8, r)
	_fe(img, 22, 46, 5, 4, dr); _fe(img, 36, 46, 5, 4, dr)
	_fe(img, 44, 38, 10, 4, r); _fc(img, 18, 28, 2, Color(1, 0.9, 0.2))
	_fc(img, 18, 28, 1, Color.BLACK); _ft(img, Vector2(14, 38), Vector2(18, 38), Vector2(16, 26), dr)

static func _draw_swarm_lord(img: Image) -> void:
	var o := Color(0.85, 0.35, 0.0); var do_ := Color(0.6, 0.2, 0.0)
	_fe(img, 32, 36, 14, 10, o); _fc(img, 26, 26, 6, o)
	_fc(img, 24, 25, 1.5, Color(1, 0.9, 0.2)); _fc(img, 28, 25, 1.5, Color(1, 0.9, 0.2))
	_ft(img, Vector2(24, 30), Vector2(18, 26), Vector2(24, 28), do_); _ft(img, Vector2(40, 30), Vector2(46, 26), Vector2(40, 28), do_)
	_fl(img, 22, 34, 8, 30, 1.5, do_); _fl(img, 42, 34, 56, 30, 1.5, do_)
	_fl(img, 24, 42, 14, 48, 1.5, do_); _fl(img, 40, 42, 50, 48, 1.5, do_)

static func _draw_mammal(img: Image) -> void:
	var g := Color(0.25, 0.45, 0.35); var dg := Color(0.15, 0.3, 0.2)
	_fe(img, 32, 34, 10, 7, g); _fc(img, 24, 28, 5, g)
	_fc(img, 22, 26, 1.2, Color(0.9, 0.9, 0.9)); _fc(img, 22, 26, 0.5, Color.BLACK)
	_fc(img, 26, 26, 1, Color(0.9, 0.9, 0.9)); _fc(img, 26, 26, 0.5, Color.BLACK)
	_fc(img, 32, 26, 1.5, Color(0.9, 0.6, 0.4, 0.7)); _fl(img, 24, 40, 16, 46, 1.5, dg)
	_fl(img, 30, 40, 22, 46, 1.5, dg); _fl(img, 36, 40, 30, 46, 1.5, dg)
	_fl(img, 42, 40, 50, 46, 1.5, dg)

static func _draw_primate(img: Image) -> void:
	var br := Color(0.2, 0.5, 0.5); var db := Color(0.1, 0.3, 0.35)
	_fc(img, 32, 28, 9, br); _fe(img, 32, 36, 11, 9, br)
	_fc(img, 28, 26, 1.5, Color(1, 0.9, 0.8)); _fc(img, 36, 26, 1.5, Color(1, 0.9, 0.8))
	_fc(img, 28, 26, 0.7, Color.BLACK); _fc(img, 36, 26, 0.7, Color.BLACK)
	_fc(img, 32, 24, 2, Color(1, 0.9, 0.6)); _fc(img, 32, 29, 2, Color(1, 0.9, 0.6))
	_fl(img, 22, 30, 14, 32, 2, db); _fl(img, 42, 30, 50, 32, 2, db)
	_fl(img, 24, 42, 16, 48, 2, db); _fl(img, 40, 42, 48, 48, 2, db)
	_fl(img, 36, 44, 42, 50, 2, db)

static func _draw_human(img: Image) -> void:
	var s := Color(0.85, 0.7, 0.55); var ds := Color(0.6, 0.5, 0.4)
	_fc(img, 32, 22, 8, s); _fc(img, 28, 20, 1.5, Color.WHITE); _fc(img, 36, 20, 1.5, Color.WHITE)
	_fc(img, 28, 20, 0.6, Color(0.2, 0.2, 0.3)); _fc(img, 36, 20, 0.6, Color(0.2, 0.2, 0.3))
	_fe(img, 32, 30, 5, 7, s); _fe(img, 32, 38, 10, 7, s)
	_fe(img, 26, 38, 3, 7, s); _fe(img, 38, 38, 3, 7, s)
	_fe(img, 22, 40, 3, 5, ds); _fe(img, 42, 40, 3, 5, ds)
	_fl(img, 24, 44, 18, 52, 2, ds); _fl(img, 40, 44, 46, 52, 2, ds)
	_fl(img, 30, 44, 26, 52, 2, ds); _fl(img, 34, 44, 38, 52, 2, ds)
	_fc(img, 32, 34, 8, Color(1, 1, 1, 0.15))

static func _draw_tyrant_king(img: Image) -> void:
	var r := Color(0.95, 0.05, 0.0); var dr := Color(0.6, 0.0, 0.0)
	_fe(img, 28, 34, 16, 14, r); _fc(img, 18, 26, 10, r)
	_fe(img, 20, 48, 6, 4, dr); _fe(img, 28, 48, 6, 4, dr); _fe(img, 36, 48, 5, 3, dr)
	_ft(img, Vector2(12, 30), Vector2(16, 38), Vector2(8, 24), Color(0.8, 0.1, 0.0))
	_fc(img, 16, 24, 2.5, Color(1, 0.8, 0.2)); _fc(img, 16, 24, 1.2, Color.BLACK)
	_fe(img, 40, 36, 10, 6, r); _fl(img, 10, 16, 6, 22, 1.5, dr); _fl(img, 40, 18, 44, 24, 1, dr)

static func _draw_chitin_beetle(img: Image) -> void:
	var y := Color(0.85, 0.65, 0.05); var dy := Color(0.6, 0.4, 0.0)
	_fc(img, 32, 34, 16, y); _fc(img, 32, 34, 13, dy)
	_fe(img, 32, 34, 10, 2, Color(0.9, 0.7, 0.1, 0.5))
	_fc(img, 28, 28, 4, dy); _fc(img, 26, 27, 1, Color.WHITE); _fc(img, 29, 27, 1, Color.WHITE)
	_fl(img, 22, 34, 8, 30, 2, dy); _fl(img, 42, 34, 56, 30, 2, dy)
	_fl(img, 24, 40, 14, 46, 2, dy); _fl(img, 40, 40, 50, 46, 2, dy)
	_fl(img, 28, 46, 24, 52, 1.5, dy); _fl(img, 36, 46, 40, 52, 1.5, dy)

static func _draw_crab_like(img: Image) -> void:
	var o := Color(0.95, 0.45, 0.05); var do_ := Color(0.7, 0.3, 0.0)
	_fe(img, 32, 34, 14, 11, o); _fc(img, 30, 30, 6, Color(0.9, 0.5, 0.1))
	_fc(img, 28, 29, 1.5, Color.BLACK); _fc(img, 32, 29, 1.5, Color.BLACK)
	_ft(img, Vector2(20, 30), Vector2(6, 18), Vector2(20, 38), o); _ft(img, Vector2(44, 30), Vector2(58, 18), Vector2(44, 38), o)
	_fe(img, 8, 18, 5, 3, do_); _fe(img, 56, 18, 5, 3, do_)
	_fl(img, 22, 34, 12, 40, 1.5, do_); _fl(img, 42, 34, 52, 40, 1.5, do_)
	_fl(img, 22, 42, 14, 46, 1.5, do_); _fl(img, 42, 42, 50, 46, 1.5, do_)
	_fl(img, 36, 44, 40, 50, 1.5, do_); _fl(img, 28, 44, 24, 50, 1.5, do_)

static func _draw_dragon(img: Image) -> void:
	var r := Color(0.95, 0.15, 0.0); var dr := Color(0.6, 0.1, 0.0); var y := Color(1.0, 0.85, 0.1)
	_fe(img, 30, 34, 15, 10, r); _fc(img, 22, 28, 7, r)
	_fc(img, 20, 26, 2, y); _fc(img, 22, 26, 1, Color.BLACK)
	_ft(img, Vector2(26, 24), Vector2(30, 16), Vector2(28, 24), dr); _ft(img, Vector2(34, 24), Vector2(38, 16), Vector2(36, 24), dr)
	_fe(img, 44, 30, 14, 5, r); _fe(img, 20, 32, 10, 3, Color(1, 0.5, 0.0, 0.6))
	_fe(img, 44, 32, 10, 3, Color(1, 0.5, 0.0, 0.6)); _fe(img, 32, 46, 8, 3, dr)
	_fe(img, 28, 46, 5, 2, dr); _fe(img, 20, 46, 5, 2, dr)

static func _draw_chimera(img: Image) -> void:
	var p := Color(0.75, 0.0, 0.75); var dp := Color(0.5, 0.0, 0.5)
	var r := Color(0.95, 0.1, 0.0); var g := Color(0.15, 0.75, 0.15)
	_fe(img, 32, 36, 16, 12, p); _ft(img, Vector2(16, 28), Vector2(26, 32), Vector2(20, 22), p)
	_ft(img, Vector2(48, 28), Vector2(38, 32), Vector2(44, 22), p); _ft(img, Vector2(30, 28), Vector2(34, 28), Vector2(32, 20), p)
	_fc(img, 20, 22, 4, r); _fc(img, 32, 20, 4, g); _fc(img, 44, 22, 4, p)
	_fc(img, 18, 20, 1.2, Color.WHITE); _fc(img, 22, 20, 1.2, Color.WHITE)
	_fc(img, 30, 18, 1.2, Color.WHITE); _fc(img, 34, 18, 1.2, Color.WHITE)
	_fc(img, 42, 20, 1.2, Color.WHITE); _fc(img, 46, 20, 1.2, Color.WHITE)
	_fe(img, 24, 48, 5, 3, dp); _fe(img, 32, 48, 5, 3, dp); _fe(img, 40, 48, 5, 3, dp)

static func _draw_rubber_chicken(img: Image) -> void:
	var y := Color(1.0, 0.85, 0.1); var o := Color(1.0, 0.6, 0.0)
	_fc(img, 32, 32, 12, y); _fc(img, 30, 26, 7, y)
	_ft(img, Vector2(24, 20), Vector2(36, 20), Vector2(30, 12), o)
	_fc(img, 26, 24, 1.2, Color.BLACK); _fc(img, 34, 24, 1.2, Color.BLACK)
	_fc(img, 26, 24, 0.5, Color.WHITE); _fc(img, 34, 24, 0.5, Color.WHITE)
	_fl(img, 24, 30, 14, 32, 2, o); _fl(img, 40, 30, 50, 32, 2, o)
	_fl(img, 26, 38, 18, 44, 2, o); _fl(img, 38, 38, 46, 44, 2, o)
	_fc(img, 30, 38, 2, o)

static func _draw_roomba_lord(img: Image) -> void:
	var dk := Color(0.2, 0.2, 0.2); var lt := Color(0.4, 0.4, 0.4)
	_fc(img, 32, 34, 18, dk); _fc(img, 32, 34, 14, lt)
	_fc(img, 32, 34, 10, dk); _fc(img, 32, 34, 7, Color(0.3, 0.6, 0.9, 0.6))
	_fc(img, 32, 34, 3, Color(0.2, 0.8, 0.3, 0.5))
	_fl(img, 16, 34, 6, 34, 1, Color(0.6, 0.6, 0.6)); _fl(img, 48, 34, 58, 34, 1, Color(0.6, 0.6, 0.6))
	_fe(img, 32, 34, 2, 18, Color(0.3, 0.3, 0.3, 0.3))

static func _draw_t_pose_tyrant(img: Image) -> void:
	var r := Color(0.95, 0.2, 0.0); var dr := Color(0.6, 0.1, 0.0)
	_fe(img, 30, 34, 14, 16, r); _fc(img, 24, 26, 8, r)
	_fc(img, 22, 24, 2, Color(1, 0.8, 0.2)); _fc(img, 22, 24, 1, Color.BLACK)
	_ft(img, Vector2(10, 20), Vector2(6, 28), Vector2(14, 28), dr)
	_ft(img, Vector2(54, 20), Vector2(50, 28), Vector2(58, 28), dr)
	_fl(img, 8, 24, 18, 24, 2, r); _fl(img, 46, 24, 56, 24, 2, r)
	_fe(img, 24, 48, 4, 3, dr); _fe(img, 32, 48, 4, 3, dr)

static func _draw_bullet(img: Image) -> void:
	var y := Color(1.0, 0.85, 0.1); var w := Color(1, 1, 1)
	_fc(img, 32, 32, 7, y); _fc(img, 32, 32, 4, w)

static func _draw_orb(img: Image) -> void:
	var g := Color(0.2, 0.9, 0.3); var lg := Color(0.5, 1.0, 0.6)
	_fc(img, 32, 32, 6, g); _fc(img, 32, 32, 3, lg)

static func _draw_trilobite(img: Image) -> void:
	var b := Color(0.5, 0.35, 0.15)
	_fe(img, 30, 32, 16, 8, b); _fc(img, 30, 28, 5, b)
	_fc(img, 28, 27, 1, Color.WHITE); _fc(img, 31, 27, 1, Color.WHITE)
	_fl(img, 24, 32, 10, 32, 1.5, Color(0.35, 0.2, 0.05)); _fl(img, 22, 36, 8, 36, 1.5, Color(0.35, 0.2, 0.05))
	_fl(img, 26, 40, 14, 40, 1.5, Color(0.35, 0.2, 0.05))
	_fl(img, 34, 32, 44, 32, 1, b); _fl(img, 36, 36, 48, 36, 1, b); _fl(img, 38, 40, 50, 40, 1, b)

static func _draw_anomalocaris(img: Image) -> void:
	var o := Color(0.7, 0.35, 0.15)
	_fe(img, 34, 32, 20, 7, o); _fc(img, 24, 28, 6, o)
	_fc(img, 22, 27, 1.5, Color(1, 0.9, 0.3)); _fc(img, 24, 27, 0.8, Color.BLACK)
	_ft(img, Vector2(52, 32), Vector2(60, 24), Vector2(60, 40), o)
	_ft(img, Vector2(14, 24), Vector2(20, 24), Vector2(18, 18), o); _ft(img, Vector2(14, 40), Vector2(20, 40), Vector2(18, 46), o)
	_ft(img, Vector2(30, 22), Vector2(34, 22), Vector2(32, 16), o); _ft(img, Vector2(40, 22), Vector2(44, 22), Vector2(42, 16), o)

static func _draw_jellyfish(img: Image) -> void:
	var b := Color(0.15, 0.55, 0.75); var lb := Color(0.3, 0.7, 0.9)
	_fe(img, 32, 28, 14, 10, b); _fe(img, 32, 28, 12, 8, lb)
	_fl(img, 26, 34, 18, 48, 1, Color(0.2, 0.6, 0.8, 0.6)); _fl(img, 30, 36, 28, 50, 1, Color(0.2, 0.6, 0.8, 0.6))
	_fl(img, 34, 36, 36, 50, 1, Color(0.2, 0.6, 0.8, 0.6)); _fl(img, 38, 34, 46, 48, 1, Color(0.2, 0.6, 0.8, 0.6))
	_fc(img, 28, 26, 1.5, Color.WHITE); _fc(img, 36, 26, 1.5, Color.WHITE)

static func _draw_placoderm(img: Image) -> void:
	var g := Color(0.35, 0.35, 0.45)
	_fe(img, 30, 34, 18, 10, g); _fc(img, 26, 30, 6, g)
	_fc(img, 22, 28, 2.5, Color(0.6, 0.6, 0.7)); _fc(img, 22, 28, 1.2, Color.BLACK)
	_fe(img, 28, 44, 6, 4, g); _fe(img, 38, 44, 6, 4, g)
	_ft(img, Vector2(18, 44), Vector2(26, 44), Vector2(24, 50), g); _ft(img, Vector2(38, 44), Vector2(48, 44), Vector2(40, 50), g)
	_fe(img, 48, 34, 10, 6, g)

static func _draw_ammonite(img: Image) -> void:
	var y := Color(0.85, 0.55, 0.15)
	_fc(img, 32, 32, 16, y); _fc(img, 32, 32, 12, Color(0.9, 0.65, 0.25))
	_fc(img, 32, 32, 8, Color(0.7, 0.4, 0.1)); _fc(img, 32, 32, 4, Color(0.5, 0.25, 0.05))
	_fc(img, 32, 32, 1.5, Color.WHITE)
	_fl(img, 18, 32, 34, 32, 1, Color(0.7, 0.4, 0.1)); _fl(img, 18, 36, 34, 36, 1, Color(0.7, 0.4, 0.1))
	_fl(img, 18, 28, 34, 28, 1, Color(0.7, 0.4, 0.1))

static func _draw_temnospondyl(img: Image) -> void:
	var g := Color(0.25, 0.55, 0.25); var dg := Color(0.15, 0.4, 0.15)
	_fe(img, 32, 34, 18, 8, g); _fc(img, 22, 30, 7, g)
	_fc(img, 20, 28, 1.5, Color(1, 0.9, 0.3)); _fc(img, 22, 28, 0.8, Color.BLACK)
	_fe(img, 18, 42, 4, 3, dg); _fe(img, 26, 42, 4, 3, dg)
	_fe(img, 36, 42, 4, 3, dg); _fe(img, 44, 42, 4, 3, dg)

static func _draw_dilophosaurus(img: Image) -> void:
	var g := Color(0.65, 0.45, 0.05); var dg := Color(0.45, 0.3, 0.0)
	_fe(img, 30, 36, 14, 10, g); _fc(img, 22, 30, 6, g)
	_fc(img, 20, 28, 1.5, Color(1, 0.8, 0.2)); _fc(img, 20, 28, 0.8, Color.BLACK)
	_ft(img, Vector2(24, 24), Vector2(32, 24), Vector2(28, 14), dg)
	_fe(img, 22, 46, 4, 3, dg); _fe(img, 32, 46, 4, 3, dg); _fe(img, 40, 38, 8, 4, g)

static func _draw_stegosaurus(img: Image) -> void:
	var g := Color(0.45, 0.65, 0.15); var dg := Color(0.3, 0.5, 0.1)
	_fe(img, 30, 36, 16, 12, g); _fc(img, 22, 30, 6, g)
	_fc(img, 20, 28, 1.5, Color(1, 0.9, 0.2)); _fc(img, 20, 28, 0.8, Color.BLACK)
	_ft(img, Vector2(24, 22), Vector2(28, 22), Vector2(26, 14), dg); _ft(img, Vector2(30, 22), Vector2(34, 22), Vector2(32, 12), dg)
	_ft(img, Vector2(36, 22), Vector2(40, 22), Vector2(38, 14), dg)
	_fe(img, 24, 48, 4, 3, dg); _fe(img, 32, 48, 4, 3, dg); _fe(img, 44, 38, 6, 4, g)

static func _draw_pterosaur(img: Image) -> void:
	var p := Color(0.35, 0.25, 0.65); var dp := Color(0.2, 0.15, 0.45)
	_fe(img, 28, 34, 8, 6, p); _fc(img, 22, 28, 4, p)
	_fc(img, 20, 26, 1, Color(1, 0.8, 0.2)); _fc(img, 20, 26, 0.6, Color.BLACK)
	_fe(img, 20, 32, 14, 3, Color(0.5, 0.4, 0.8, 0.6)); _fe(img, 36, 32, 14, 3, Color(0.5, 0.4, 0.8, 0.6))
	_fe(img, 28, 40, 4, 3, dp); _fe(img, 32, 40, 4, 3, dp)
	_ft(img, Vector2(26, 34), Vector2(34, 34), Vector2(30, 42), dp)

static func _draw_velociraptor(img: Image) -> void:
	var g := Color(0.55, 0.65, 0.05); var dg := Color(0.35, 0.45, 0.0)
	_fe(img, 28, 36, 12, 8, g); _fc(img, 18, 30, 5, g)
	_fc(img, 16, 28, 1.5, Color(1, 0.9, 0.2)); _fc(img, 16, 28, 0.8, Color.BLACK)
	_fe(img, 20, 44, 3, 3, dg); _fe(img, 26, 44, 3, 3, dg); _fe(img, 32, 44, 3, 3, dg)
	_ft(img, Vector2(38, 32), Vector2(44, 24), Vector2(44, 40), g)

static func _draw_triceratops(img: Image) -> void:
	var b := Color(0.45, 0.35, 0.25); var db := Color(0.3, 0.2, 0.15)
	_fe(img, 32, 36, 16, 14, b); _fc(img, 20, 30, 7, b)
	_fc(img, 18, 28, 2, Color(1, 0.8, 0.2)); _fc(img, 18, 28, 1, Color.BLACK)
	_ft(img, Vector2(16, 28), Vector2(22, 28), Vector2(22, 14), db); _ft(img, Vector2(12, 32), Vector2(16, 32), Vector2(14, 20), db)
	_ft(img, Vector2(24, 28), Vector2(28, 28), Vector2(26, 16), db)
	_fe(img, 24, 50, 4, 3, db); _fe(img, 32, 50, 4, 3, db); _fe(img, 40, 50, 4, 3, db)

static func _draw_pachycephalosaurus(img: Image) -> void:
	var b := Color(0.55, 0.25, 0.35); var db := Color(0.4, 0.15, 0.2)
	_fe(img, 30, 36, 14, 10, b); _fc(img, 24, 30, 6, b)
	_fc(img, 20, 24, 6, db); _fc(img, 22, 22, 2, Color(1, 0.8, 0.2))
	_fc(img, 22, 22, 1, Color.BLACK)
	_fe(img, 22, 46, 3, 3, db); _fe(img, 30, 46, 4, 3, db); _fe(img, 38, 40, 6, 3, b)

static func _draw_mutant(img: Image) -> void:
	var g := Color(0.15, 0.75, 0.25); var dg := Color(0.1, 0.5, 0.15)
	_fc(img, 32, 34, 15, g); _fc(img, 28, 36, 10, dg)
	_fc(img, 22, 28, 4, g); _fc(img, 20, 26, 1.5, Color(1, 0.9, 0.1)); _fc(img, 20, 26, 0.8, Color.BLACK)
	_fc(img, 44, 28, 3, g); _fc(img, 42, 26, 0.8, Color(1, 0.2, 0.1))
	_fe(img, 22, 44, 5, 3, dg); _fe(img, 34, 44, 4, 3, dg); _ft(img, Vector2(40, 32), Vector2(46, 34), Vector2(44, 28), g)

static func _draw_crystal_entity(img: Image) -> void:
	var b := Color(0.4, 0.15, 0.85); var lb := Color(0.6, 0.3, 1.0)
	_ft(img, Vector2(32, 12), Vector2(18, 32), Vector2(32, 32), b); _ft(img, Vector2(32, 12), Vector2(46, 32), Vector2(32, 32), b)
	_ft(img, Vector2(18, 32), Vector2(32, 52), Vector2(32, 32), Color(0.5, 0.2, 0.9)); _ft(img, Vector2(46, 32), Vector2(32, 52), Vector2(32, 32), Color(0.5, 0.2, 0.9))
	_fc(img, 30, 28, 1, Color.WHITE); _fc(img, 34, 28, 1, Color.WHITE)
	_fl(img, 24, 22, 32, 30, 1, Color(0.7, 0.5, 1.0, 0.5))

static func _draw_void_walker(img: Image) -> void:
	var dk := Color(0.05, 0.05, 0.15); var dp := Color(0.1, 0.05, 0.2)
	_ft(img, Vector2(32, 18), Vector2(16, 34), Vector2(32, 38), dk); _ft(img, Vector2(32, 18), Vector2(48, 34), Vector2(32, 38), dk)
	_fe(img, 20, 38, 6, 10, dk); _fe(img, 44, 38, 6, 10, dk)
	_fc(img, 28, 28, 1.5, Color(0.8, 0.2, 0.9, 0.7)); _fc(img, 36, 28, 1.5, Color(0.8, 0.2, 0.9, 0.7))

static func _draw_dimetrodon(img: Image) -> void:
	var r := Color(0.7, 0.3, 0.1); var dr := Color(0.5, 0.2, 0.05)
	_fe(img, 30, 36, 16, 10, r); _fc(img, 20, 28, 7, r)
	_fc(img, 18, 26, 1.5, Color(1, 0.8, 0.2)); _fc(img, 18, 26, 0.8, Color.BLACK)
	_ft(img, Vector2(24, 20), Vector2(28, 20), Vector2(26, 4), dr); _ft(img, Vector2(28, 20), Vector2(32, 20), Vector2(30, 2), dr)
	_ft(img, Vector2(32, 20), Vector2(36, 20), Vector2(34, 4), dr)
	_fe(img, 22, 46, 4, 3, dr); _fe(img, 32, 46, 4, 3, dr); _fe(img, 42, 36, 8, 4, r)

static func _draw_allosaurus(img: Image) -> void:
	var r := Color(0.75, 0.15, 0.05); var dr := Color(0.5, 0.1, 0.0)
	_fe(img, 28, 34, 16, 12, r); _fc(img, 18, 28, 8, r)
	_fc(img, 16, 26, 2, Color(1, 0.8, 0.2)); _fc(img, 16, 26, 1, Color.BLACK)
	_ft(img, Vector2(12, 32), Vector2(16, 38), Vector2(8, 26), dr)
	_fe(img, 20, 46, 5, 4, dr); _fe(img, 26, 46, 5, 4, dr); _fe(img, 34, 46, 4, 3, dr); _fe(img, 42, 36, 10, 6, r)

static func _draw_omega_mutant(img: Image) -> void:
	var g := Color(0.0, 0.85, 0.45); var dg := Color(0.0, 0.55, 0.25)
	_fc(img, 32, 32, 18, g); _fc(img, 32, 32, 14, dg)
	_fc(img, 26, 26, 5, g); _fc(img, 24, 24, 2, Color(1, 1, 0.3)); _fc(img, 24, 24, 1, Color.BLACK)
	_fc(img, 40, 26, 5, g); _fc(img, 38, 24, 2, Color(1, 0.2, 0.1)); _fc(img, 38, 24, 1, Color.BLACK)
	_ft(img, Vector2(18, 36), Vector2(28, 40), Vector2(22, 28), dg); _ft(img, Vector2(46, 36), Vector2(36, 40), Vector2(42, 28), dg)
	_fe(img, 22, 48, 5, 4, dg); _fe(img, 30, 48, 5, 4, dg); _fe(img, 38, 48, 5, 4, dg)
	_fc(img, 32, 32, 8, Color(0.2, 1.0, 0.6, 0.3))

static func _draw_enemy_generic(img: Image) -> void:
	var r := Color(0.9, 0.15, 0.1); var dr := Color(0.6, 0.05, 0.0)
	_fc(img, 32, 32, 14, r); _fc(img, 32, 32, 10, dr)
	_fc(img, 26, 28, 2.5, Color.WHITE); _fc(img, 38, 28, 2.5, Color.WHITE)
	_fc(img, 26, 28, 1.2, Color.BLACK); _fc(img, 38, 28, 1.2, Color.BLACK)
	_ft(img, Vector2(30, 34), Vector2(34, 34), Vector2(32, 40), dr)
