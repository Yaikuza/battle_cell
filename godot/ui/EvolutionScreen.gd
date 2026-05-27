extends CanvasLayer
class_name EvolutionScreen

const TAG_COLORS: Dictionary = {
	"evolution": Color(0.2, 1.0, 0.3),
	"atk": Color(1.0, 0.2, 0.2),
	"def": Color(0.2, 0.4, 1.0),
	"speed": Color(0.2, 1.0, 0.8),
	"weapon": Color(1.0, 0.6, 0.0),
	"misc": Color(0.7, 0.3, 1.0),
	"boss": Color(1.0, 0.8, 0.0),
	"hybrid": Color(1.0, 0.3, 0.8),
	"wtf": Color(1.0, 0.6, 0.0),
}
const TAG_LABELS: Dictionary = {
	"evolution": "EVOLVE",
	"atk": "ATTACK",
	"def": "DEFENSE",
	"speed": "SPEED",
	"weapon": "WEAPON",
	"misc": "MISC",
	"boss": "BOSS",
	"hybrid": "FUSION",
	"wtf": "WTF?!",
}

var _callback: Callable

func show_choices(choices: Array[Dictionary], viewport: Vector2, on_chosen: Callable) -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_callback = on_chosen

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.size = viewport
	add_child(overlay)

	var title = Label.new()
	title.text = "EVOLVE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, viewport.y * 0.10)
	title.size = Vector2(viewport.x, 50)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	add_child(title)

	var subtitle = Label.new()
	subtitle.text = "เลือกเส้นทางวิวัฒนาการ"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, viewport.y * 0.10 + 48)
	subtitle.size = Vector2(viewport.x, 25)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(subtitle)

	var count = choices.size()
	var card_w = 200.0
	var gap = 25.0
	var total_w = count * card_w + (count - 1) * gap
	var start_x = (viewport.x - total_w) / 2
	var card_y = viewport.y * 0.33

	for i in range(count):
		var data = choices[i]
		var card = _make_card(data, Vector2(start_x + i * (card_w + gap), card_y), card_w)
		add_child(card)

func _make_card(data: Dictionary, pos: Vector2, width: float) -> Button:
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(width, 270)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var empty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var data_type = data.get("type", "form")
	var tags: Array = data.get("tags", [])
	var primary_tag = tags[0] if tags.size() > 0 else "evolution"
	var tag_color = TAG_COLORS.get(primary_tag, Color.WHITE)
	var tag_label_text = TAG_LABELS.get(primary_tag, "")

	var tag_badge = ColorRect.new()
	tag_badge.color = Color(tag_color.r, tag_color.g, tag_color.b, 0.9)
	tag_badge.size = Vector2(width - 20, 22)
	tag_badge.position = Vector2(10, 8)
	btn.add_child(tag_badge)

	var tag_text = Label.new()
	tag_text.text = tag_label_text
	tag_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_text.position = Vector2(10, 8)
	tag_text.size = Vector2(width - 20, 22)
	tag_text.add_theme_font_size_override("font_size", 11)
	tag_text.add_theme_color_override("font_color", Color(0, 0, 0, 0.9))
	btn.add_child(tag_text)

	if data_type in ["form", "hybrid"]:
		_make_form_card(btn, data, width, tag_color)
	else:
		_make_upgrade_card(btn, data, width, tag_color)

	btn.pressed.connect(func():
		_callback.call(data)
		queue_free()
	)
	return btn

func _make_form_card(btn: Button, data: Dictionary, width: float, tag_color: Color) -> void:
	var color = data.get("color", Color.WHITE)
	var size_mod = data.get("size", 1.0)

	var visual = ColorRect.new()
	visual.color = color
	visual.size = Vector2(50 * size_mod, 50 * size_mod)
	visual.position = Vector2(width / 2 - 25 * size_mod, 35)
	btn.add_child(visual)

	var name_label = Label.new()
	name_label.text = data.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 95)
	name_label.size = Vector2(width, 28)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", color)
	btn.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = data.get("desc", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.position = Vector2(8, 125)
	desc_label.size = Vector2(width - 16, 55)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	btn.add_child(desc_label)

	var s = data.get("stats", {})
	var stats_label = Label.new()
	stats_label.text = "HP:%.0f SPD:%.0f\nDMG:%.0f ROF:%.2f" % [
		s.get("max_hp", 0), s.get("speed", 0),
		s.get("damage", 0), 1.0 / max(s.get("fire_cooldown", 1), 0.1)
	]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.position = Vector2(0, 190)
	stats_label.size = Vector2(width, 40)
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	btn.add_child(stats_label)

	var weapon_label = Label.new()
	var w = data.get("weapon", "")
	weapon_label.text = _weapon_desc(w)
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.position = Vector2(0, 225)
	weapon_label.size = Vector2(width, 30)
	weapon_label.add_theme_font_size_override("font_size", 10)
	weapon_label.add_theme_color_override("font_color", tag_color)
	btn.add_child(weapon_label)

func _make_upgrade_card(btn: Button, data: Dictionary, width: float, tag_color: Color) -> void:
	var visual = ColorRect.new()
	visual.color = tag_color
	visual.color.a = 0.15
	visual.size = Vector2(44, 44)
	visual.position = Vector2(width / 2 - 22, 38)
	btn.add_child(visual)

	var icon = Label.new()
	icon.text = _tag_icon(data.get("tags", []))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.position = Vector2(width / 2 - 22, 38)
	icon.size = Vector2(44, 44)
	icon.add_theme_font_size_override("font_size", 26)
	icon.add_theme_color_override("font_color", tag_color)
	btn.add_child(icon)

	var name_label = Label.new()
	name_label.text = data.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 90)
	name_label.size = Vector2(width, 28)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	btn.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = data.get("desc", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.position = Vector2(8, 120)
	desc_label.size = Vector2(width - 16, 50)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", tag_color)
	btn.add_child(desc_label)

func _tag_icon(tags: Array) -> String:
	match tags[0] if tags.size() > 0 else "":
		"atk": return "⚔"
		"def": return "🛡"
		"speed": return "💨"
		"weapon": return "🏹"
		"misc": return "✦"
		"boss": return "👑"
	return "◆"

func _weapon_desc(weapon_id: String) -> String:
	match weapon_id:
		"cell_burst": return "Nova Burst (360°)"
		"water_jet": return "Water Jet (3-spread)"
		"tongue_lash": return "Tongue Lash (fast)"
		"sting_dart": return "Sting Dart (precise)"
		"tail_sweep": return "Tail Sweep (arc)"
		"piercing_sting": return "Piercing Sting"
		"crushing_bite": return "Crushing Bite (AoE)"
		"swarm_shot": return "Swarm Shot (spread)"
		"pincer_claw": return "Pincer Claw (piercing)"
		"fire_breath": return "Fire Breath (cone)"
		"chaos_beam": return "Chaos Beam (random)"
		"slash": return "Slash (melee arc)"
		"psychic_blast": return "Psychic Blast (piercing)"
		"bouncy_shot": return "Bouncy Shot (ricochet)"
		"suction": return "Suction (pull enemies)"
		"stare": return "Stare (slow + DoT)"
	return weapon_id
