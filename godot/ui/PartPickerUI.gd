extends CanvasLayer
class_name PartPickerUI

const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS := {
	0: Color(0.7, 0.7, 0.7),
	1: Color(0.2, 0.9, 0.2),
	2: Color(0.2, 0.5, 1.0),
	3: Color(0.7, 0.2, 1.0),
	4: Color(1.0, 0.7, 0.1),
}
const RARITY_MULT := [1.0, 1.4, 2.0, 3.0, 5.0]

var _callback: Callable
var _cards: Array[Button] = []
var _key_map = [KEY_1, KEY_2, KEY_3]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		for i in _cards.size():
			if i < _key_map.size() and event.keycode == _key_map[i]:
				_cards[i].emit_signal("pressed")
				get_viewport().set_input_as_handled()
				return

	if event is InputEventJoypadMotion:
		var nav_dir = 0
		if Input.is_action_just_pressed("ui_left"): nav_dir = -1
		elif Input.is_action_just_pressed("ui_right"): nav_dir = 1
		if nav_dir != 0:
			var fi = -1
			for i in _cards.size():
				if _cards[i].has_focus(): fi = i; break
			if fi < 0:
				if _cards.size() > 0: _cards[0].grab_focus()
			else:
				fi = (fi + nav_dir + _cards.size()) % _cards.size()
				_cards[fi].grab_focus()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"ui_accept"):
		for i in _cards.size():
			if _cards[i].has_focus():
				_cards[i].emit_signal("pressed")
				get_viewport().set_input_as_handled()
				return

	var focused_idx = -1
	for i in _cards.size():
		if _cards[i].has_focus():
			focused_idx = i
			break
	if focused_idx < 0:
		if _cards.size() > 0:
			_cards[0].grab_focus()
		return

	if event.is_action_pressed(&"ui_left") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_LEFT, KEY_A]):
		var prev = (focused_idx - 1 + _cards.size()) % _cards.size()
		_cards[prev].grab_focus()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_right") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_RIGHT, KEY_D]):
		var next = (focused_idx + 1) % _cards.size()
		_cards[next].grab_focus()
		get_viewport().set_input_as_handled()
		return

func show_choices(choices: Array[Dictionary], viewport: Vector2, on_chosen: Callable) -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	_callback = on_chosen

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.size = viewport
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(overlay)

	var title = Label.new()
	title.text = "BODY PART DROP!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, viewport.y * 0.10)
	title.size = Vector2(viewport.x, 50)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	add_child(title)

	var subtitle = Label.new()
	subtitle.text = "เลือกอวัยวะที่จะพัฒนา"
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

	var key_hint = Label.new()
	key_hint.text = "WASD/ลูกศรเลื่อน  Space/Enter เลือก  1-3 เลือกตรงๆ"
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_hint.position = Vector2(0, viewport.y * 0.33 + 300)
	key_hint.size = Vector2(viewport.x, 20)
	key_hint.add_theme_font_size_override("font_size", 12)
	key_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(key_hint)

	_cards.clear()
	for i in range(count):
		var card = _make_part_card(choices[i], Vector2(start_x + i * (card_w + gap), card_y), card_w)
		add_child(card)
		_cards.append(card)

	for i in range(count):
		if i > 0:
			_cards[i].focus_neighbor_left = _cards[i-1].get_path()
		if i < count - 1:
			_cards[i].focus_neighbor_right = _cards[i+1].get_path()
	if count > 0:
		_cards[0].grab_focus()

func _make_part_card(data: Dictionary, pos: Vector2, width: float) -> Button:
	var cfg = data.get("part")
	var rarity: int = data.get("rarity", 0)
	var mult = RARITY_MULT[rarity]
	var rarity_color = RARITY_COLORS.get(rarity, Color.WHITE)

	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(width, 280)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.set_border_width_all(1)
	s.border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.2)
	btn.add_theme_stylebox_override("normal", s)
	var h = StyleBoxFlat.new()
	h.bg_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.06)
	h.set_border_width_all(2)
	h.border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.4)
	btn.add_theme_stylebox_override("hover", h)
	var p = StyleBoxFlat.new()
	p.bg_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.12)
	p.set_border_width_all(2)
	p.border_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.8)
	btn.add_theme_stylebox_override("pressed", p)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var rarity_badge = ColorRect.new()
	rarity_badge.color = rarity_color
	rarity_badge.size = Vector2(width - 20, 22)
	rarity_badge.position = Vector2(10, 8)
	btn.add_child(rarity_badge)

	var rarity_text = Label.new()
	rarity_text.text = RARITY_NAMES[rarity]
	rarity_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_text.position = Vector2(10, 8)
	rarity_text.size = Vector2(width - 20, 22)
	rarity_text.add_theme_font_size_override("font_size", 11)
	rarity_text.add_theme_color_override("font_color", Color(0, 0, 0, 0.9))
	btn.add_child(rarity_text)

	var preview = ColorRect.new()
	preview.color = cfg.color
	preview.size = Vector2(50, 50)
	preview.position = Vector2(width / 2 - 25, 35)
	btn.add_child(preview)

	var slot_name = Label.new()
	slot_name.text = cfg.slot_id.capitalize()
	slot_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_name.position = Vector2(0, 90)
	slot_name.size = Vector2(width, 28)
	slot_name.add_theme_font_size_override("font_size", 16)
	slot_name.add_theme_color_override("font_color", rarity_color)
	btn.add_child(slot_name)

	var y_off = 120
	if not cfg.weapon_behavior_id.is_empty():
		var wep_label = Label.new()
		var wep_name = cfg.weapon_behavior_id.replace("_", " ").capitalize()
		wep_label.text = "อาวุธ: " + wep_name
		wep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wep_label.position = Vector2(8, y_off)
		wep_label.size = Vector2(width - 16, 20)
		wep_label.add_theme_font_size_override("font_size", 11)
		wep_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		btn.add_child(wep_label)
		y_off += 22

	if not cfg.stat_mods.is_empty():
		var stat_text = ""
		for sm in cfg.stat_mods:
			var stat_name = sm.get("stat", "")
			var v = sm.get("val", 0.0) * mult
			var prefix = "+" if v >= 0 else ""
			stat_text += stat_name.capitalize() + " " + prefix + str(v) + "  "
		var stat_label = Label.new()
		stat_label.text = stat_text
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_label.position = Vector2(8, y_off)
		stat_label.size = Vector2(width - 16, 20)
		stat_label.add_theme_font_size_override("font_size", 11)
		stat_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
		btn.add_child(stat_label)
		y_off += 22

	if mult > 1.0:
		var mult_label = Label.new()
		mult_label.text = "x" + str(mult) + " " + RARITY_NAMES[rarity]
		mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mult_label.position = Vector2(8, y_off)
		mult_label.size = Vector2(width - 16, 18)
		mult_label.add_theme_font_size_override("font_size", 10)
		mult_label.add_theme_color_override("font_color", rarity_color)
		btn.add_child(mult_label)

	btn.pressed.connect(func():
		_callback.call(data)
		queue_free()
	)
	return btn
