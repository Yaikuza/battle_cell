extends Node2D

var config
var _sprite: Sprite2D

func apply_config(cfg) -> void:
	config = cfg
	position = cfg.position
	scale = cfg.scale
	rotation = cfg.rotation
	z_index = cfg.z_index

	if not _sprite:
		_sprite = Sprite2D.new()
		_sprite.name = "PartSprite"
		add_child(_sprite)

	_sprite.texture = _generate(cfg.draw_type, cfg.draw_params)
	_sprite.modulate = cfg.color

func tween_to(cfg, duration: float) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", cfg.position, duration)
	tween.tween_property(self, "scale", cfg.scale, duration)
	tween.tween_property(self, "rotation", cfg.rotation, duration)
	tween.tween_property(self, "modulate", cfg.color, duration)

	var half = duration * 0.5
	get_tree().create_timer(half).timeout.connect(func():
		if _sprite:
			_sprite.texture = _generate(cfg.draw_type, cfg.draw_params)
	)

	config = cfg

func fade_in(duration: float) -> void:
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, duration)

func fade_out(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

static func _generate(draw_type: String, p: Dictionary) -> Texture2D:
	match draw_type:
		"circle":
			return _make_circle(int(p.get("radius", 16)))
		"rect":
			var sz = p.get("size", Vector2(32, 24))
			return _make_rect(sz)
		"triangle":
			var base = p.get("base", 20)
			var height = p.get("height", 20)
			return _make_triangle(base, height)
		"line":
			return _make_line(p.get("length", 20), p.get("width", 3))
		"polygon":
			return _make_polygon(p.get("points", []))
	return _make_circle(16)

static func _make_circle(r: int) -> Texture2D:
	var d = r * 2 + 2
	var img = Image.create(d, d, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx = r + 0.5
	var cy = r + 0.5
	for y in d:
		for x in d:
			if (Vector2(x, y) - Vector2(cx, cy)).length() <= r:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static func _make_rect(sz: Vector2) -> Texture2D:
	var w = maxi(1, int(sz.x))
	var h = maxi(1, int(sz.y))
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)

static func _make_triangle(base: float, height: float) -> Texture2D:
	var w = maxi(1, int(base))
	var h = maxi(1, int(height))
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		var t = float(y) / h
		var half = int((base * 0.5) * (1.0 - t))
		var cx = int(w * 0.5)
		for x in range(cx - half, cx + half + 1):
			if x >= 0 and x < w:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

static func _make_line(length: float, width: float) -> Texture2D:
	var w = maxi(1, int(length))
	var h = maxi(1, int(width))
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)

static func _make_polygon(points: Array) -> Texture2D:
	if points.is_empty():
		return _make_circle(8)
	var min_x = 0.0
	var max_x = 0.0
	var min_y = 0.0
	var max_y = 0.0
	for p in points:
		min_x = mini(min_x, p.x)
		max_x = maxi(max_x, p.x)
		min_y = mini(min_y, p.y)
		max_y = maxi(max_y, p.y)
	var w = maxi(1, int(max_x - min_x + 2))
	var h = maxi(1, int(max_y - min_y + 2))
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for p in points:
		var px = int(p.x - min_x + 0.5)
		var py = int(p.y - min_y + 0.5)
		if px >= 0 and px < w and py >= 0 and py < h:
			img.set_pixel(px, py, Color.WHITE)
	return ImageTexture.create_from_image(img)
