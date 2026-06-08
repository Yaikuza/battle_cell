extends Area2D
class_name PartPickup

var part_id: String = ""
var _lifetime: float = 0.0

func _init() -> void:
	add_to_group("items")
	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 8
	add_child(collision)
	var spr = Sprite2D.new()
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 16:
		for y in 16:
			var dx = x - 7.5
			var dy = y - 7.5
			var d = sqrt(dx * dx + dy * dy)
			if d < 8:
				var diamond = abs(dx) + abs(dy) < 7
				if diamond:
					img.set_pixel(x, y, Color(0.6, 0.2, 1.0))
			if d < 4:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0))
	spr.texture = ImageTexture.create_from_image(img)
	add_child(spr)
	area_entered.connect(_on_collected)

func _pool_init() -> void:
	_lifetime = 0.0
	visible = true
	set_process(true)

func _pool_reset() -> void:
	visible = false
	set_process(false)
	part_id = ""

func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime > 30.0:
		var evo = get_tree().get_first_node_in_group("evolution_manager") as EvolutionManager
		if evo and part_id != "":
			evo._pending_drops.append(part_id)
		PoolManager.release_part(self)
		return
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist < 300:
		global_position += (player.global_position - global_position).normalized() * 200.0 * delta

func _on_collected(area: Area2D) -> void:
	if not area.is_in_group("player"):
		return
	var player = area as Player
	if not player:
		return
	if player.get_equipped_parts().size() >= 6:
		return
	_show_part_popup(player)

func _show_part_popup(player: Player) -> void:
	var evo = get_tree().get_first_node_in_group("evolution_manager") as EvolutionManager
	if not evo:
		return
	var pd: Dictionary = evo._body_part_pool.get(part_id, {})
	var vp = get_viewport().get_visible_rect().size

	var overlay = CanvasLayer.new()
	overlay.process_mode = PROCESS_MODE_WHEN_PAUSED
	get_tree().current_scene.add_child(overlay)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = vp
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	var card = ColorRect.new()
	card.color = Color(0.15, 0.15, 0.2)
	card.size = Vector2(280, 240)
	card.position = Vector2(vp.x / 2 - 140, vp.y / 2 - 120)
	overlay.add_child(card)

	var name_lbl = Label.new()
	name_lbl.text = pd.get("name", "???")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(vp.x / 2 - 120, vp.y / 2 - 105)
	name_lbl.size = Vector2(240, 30)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	overlay.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = pd.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.position = Vector2(vp.x / 2 - 120, vp.y / 2 - 70)
	desc_lbl.size = Vector2(240, 40)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	overlay.add_child(desc_lbl)

	var mods: Array = pd.get("mods", [])
	var mod_text = ""
	for m: Dictionary in mods:
		var stat_name = m.get("stat", "?")
		var val = m.get("val", 0)
		var num = val * (100 if m.get("type", 0) == 1 else 1)
		mod_text += "+%d%s %s\n" % [num, "%" if m.get("type", 0) == 1 else "", stat_name]
	if pd.get("special", "") != "":
		mod_text += "Special: %s" % pd.get("special", "")
	var mod_lbl = Label.new()
	mod_lbl.text = mod_text
	mod_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mod_lbl.position = Vector2(vp.x / 2 - 120, vp.y / 2 - 30)
	mod_lbl.size = Vector2(240, 60)
	mod_lbl.add_theme_font_size_override("font_size", 12)
	mod_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	overlay.add_child(mod_lbl)

	var pick_btn = Button.new()
	pick_btn.text = "PICK"
	pick_btn.position = Vector2(vp.x / 2 - 100, vp.y / 2 + 55)
	pick_btn.size = Vector2(90, 32)
	pick_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	pick_btn.pressed.connect(func():
		if not player.health:
			return
		player.equip_part(part_id)
		for m: Dictionary in mods:
			player.stats.add_modifier_raw(m.stat, m.val, m.type, "body_part")
		if pd.get("special", "") == "regen":
			player._has_regen = true
		player.refresh_from_stats()
		EventBus.part_equipped.emit(part_id)
		EffectManager.collect(global_position)
		get_tree().paused = false
		overlay.queue_free()
		PoolManager.release_part(self)
	)
	overlay.add_child(pick_btn)

	var disc_btn = Button.new()
	disc_btn.text = "DISCARD"
	disc_btn.position = Vector2(vp.x / 2 + 10, vp.y / 2 + 55)
	disc_btn.size = Vector2(90, 32)
	disc_btn.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	disc_btn.pressed.connect(func():
		get_tree().paused = false
		overlay.queue_free()
		PoolManager.release_part(self)
	)
	overlay.add_child(disc_btn)

	get_tree().paused = true
