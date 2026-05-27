extends Node

var _particle_texture: Texture2D

func _ready() -> void:
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 4:
		for y in 4:
			var dx = x - 3.5
			var dy = y - 3.5
			if sqrt(dx * dx + dy * dy) < 3.5:
				img.set_pixel(x, y, Color.WHITE)
				img.set_pixel(7 - x, y, Color.WHITE)
				img.set_pixel(x, 7 - y, Color.WHITE)
				img.set_pixel(7 - x, 7 - y, Color.WHITE)
	_particle_texture = ImageTexture.create_from_image(img)

func _particles(process_material: ParticleProcessMaterial, lifetime: float = 0.5, amount: int = 8) -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.one_shot = true
	p.lifetime = lifetime
	p.amount = amount
	p.explosiveness = 0.9
	p.process_material = process_material
	p.texture = _particle_texture
	p.finished.connect(p.queue_free, CONNECT_ONE_SHOT)
	return p

func _add(p: Node2D) -> void:
	get_tree().current_scene.add_child(p)

func hit(pos: Vector2, color: Color = Color(1.0, 0.85, 0.1)) -> void:
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180
	mat.initial_velocity_min = 40
	mat.initial_velocity_max = 120
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	mat.lifetime_randomness = 0.4
	var grad = Gradient.new()
	grad.colors = [color, color, Color(color.r, color.g, color.b, 0)]
	mat.color_ramp = grad
	var p = _particles(mat, 0.35, 6)
	p.global_position = pos
	_add(p)

func explosion(pos: Vector2, radius: float = 40) -> void:
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180
	mat.initial_velocity_min = 50
	mat.initial_velocity_max = 200
	mat.scale_min = 3.0
	mat.scale_max = 8.0
	mat.lifetime_randomness = 0.3
	var grad = Gradient.new()
	grad.colors = [Color(1, 0.9, 0.3), Color(1, 0.5, 0.1), Color(0.8, 0.1, 0), Color(0.5, 0, 0, 0)]
	mat.color_ramp = grad
	mat.gravity = Vector3(0, -80, 0)
	mat.angular_velocity_min = -180
	mat.angular_velocity_max = 180
	var p = _particles(mat, 0.6, 24)
	p.global_position = pos
	p.scale = Vector2.ONE * (radius / 40.0)
	_add(p)

func death(pos: Vector2, color: Color = Color(0.2, 0.9, 0.3)) -> void:
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180
	mat.initial_velocity_min = 30
	mat.initial_velocity_max = 100
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.lifetime_randomness = 0.5
	var grad = Gradient.new()
	grad.colors = [color, Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0)]
	mat.color_ramp = grad
	var p = _particles(mat, 0.5, 12)
	p.global_position = pos
	_add(p)

func evolution(pos: Vector2) -> void:
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180
	mat.initial_velocity_min = 80
	mat.initial_velocity_max = 250
	mat.scale_min = 4.0
	mat.scale_max = 12.0
	mat.lifetime_randomness = 0.2
	var grad = Gradient.new()
	grad.colors = [Color(1, 1, 1), Color(0.5, 0.8, 1), Color(0.2, 0.4, 1, 0)]
	mat.color_ramp = grad
	mat.gravity = Vector3(0, -150, 0)
	mat.angular_velocity_min = -360
	mat.angular_velocity_max = 360
	var p = _particles(mat, 0.8, 40)
	p.global_position = pos
	_add(p)

func collect(pos: Vector2) -> void:
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 60
	mat.initial_velocity_min = 60
	mat.initial_velocity_max = 150
	mat.scale_min = 1.5
	mat.scale_max = 3.5
	mat.lifetime_randomness = 0.3
	var grad = Gradient.new()
	grad.colors = [Color(0.3, 1, 0.4), Color(0.6, 1, 0.2, 0)]
	mat.color_ramp = grad
	var p = _particles(mat, 0.4, 8)
	p.global_position = pos
	_add(p)
