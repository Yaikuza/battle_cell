extends CanvasLayer
class_name MutationPickerUI

const BRANCH_COLORS: Dictionary = {
	"PREDATOR": Color(1.0, 0.2, 0.2),
	"ARMORED": Color(0.2, 0.4, 1.0),
	"SWIFT": Color(0.2, 1.0, 0.4),
	"HYBRID": Color(0.8, 0.2, 1.0),
}
const BRANCH_ICONS: Dictionary = {
	"PREDATOR": "🦷",
	"ARMORED": "🛡",
	"SWIFT": "💨",
	"HYBRID": "🧬",
}

var _callback: Callable
var _cards: Array[Button] = []
var _key_map = [KEY_1, KEY_2, KEY_3]
var _viewport_size: Vector2

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		for i in _cards.size():
			if i < _key_map.size() and event.keycode == _key_map[i]:
				_cards[i].emit_signal("pressed")
				get_viewport().set_input_as_handled()
				return

	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		_reroll()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_reroll()
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
	_viewport_size = viewport

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.size = viewport
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(overlay)

	var title = Label.new()
	title.text = "GENETIC MUTATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, viewport.y * 0.10)
	title.size = Vector2(viewport.x, 50)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	add_child(title)

	var subtitle = Label.new()
	subtitle.text = "เลือกการกลายพันธุ์เพื่อปรับร่างกาย"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, viewport.y * 0.10 + 46)
	subtitle.size = Vector2(viewport.x, 25)
	subtitle.add_theme_font_size_override("font_size", 14)
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
	key_hint.position = Vector2(0, viewport.y * 0.33 + 260)
	key_hint.size = Vector2(viewport.x, 20)
	key_hint.add_theme_font_size_override("font_size", 12)
	key_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(key_hint)

	var reroll = Button.new()
	reroll.text = "⟳ REROLL (TEST)"
	reroll.position = Vector2(viewport.x / 2 - 60, viewport.y * 0.33 + 290)
	reroll.size = Vector2(120, 28)
	reroll.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	reroll.add_theme_font_size_override("font_size", 13)
	reroll.pressed.connect(_reroll)
	add_child(reroll)

	_cards.clear()
	for i in range(count):
		var data = choices[i]
		var card = _make_card(data, Vector2(start_x + i * (card_w + gap), card_y), card_w)
		add_child(card)
		_cards.append(card)

	for i in range(count):
		if i > 0:
			_cards[i].focus_neighbor_left = _cards[i-1].get_path()
		if i < count - 1:
			_cards[i].focus_neighbor_right = _cards[i+1].get_path()
	if count > 0:
		_cards[0].grab_focus()

func _reroll() -> void:
	var new_choices = MutationManager.get_random_choices(3)
	if new_choices.is_empty():
		return
	for card in _cards:
		card.queue_free()
	_cards.clear()
	var count = new_choices.size()
	var card_w = 200.0
	var gap = 25.0
	var total_w = count * card_w + (count - 1) * gap
	var start_x = (_viewport_size.x - total_w) / 2
	var card_y = _viewport_size.y * 0.33
	for i in range(count):
		var data = new_choices[i]
		var card = _make_card(data, Vector2(start_x + i * (card_w + gap), card_y), card_w)
		add_child(card)
		_cards.append(card)
	for i in range(count):
		if i > 0:
			_cards[i].focus_neighbor_left = _cards[i - 1].get_path()
		if i < count - 1:
			_cards[i].focus_neighbor_right = _cards[i + 1].get_path()
	if count > 0:
		_cards[0].grab_focus()

func _make_card(data: Dictionary, pos: Vector2, width: float) -> Button:
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(width, 240)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var branch = data.get("branch", "PREDATOR") if data.get("type", "") != "unique" else "HYBRID"
	var clr = BRANCH_COLORS.get(branch, Color.WHITE)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.set_border_width_all(1)
	s.border_color = Color(clr.r, clr.g, clr.b, 0.2)
	btn.add_theme_stylebox_override("normal", s)
	var h = StyleBoxFlat.new()
	h.bg_color = Color(clr.r, clr.g, clr.b, 0.06)
	h.set_border_width_all(2)
	h.border_color = Color(clr.r, clr.g, clr.b, 0.4)
	btn.add_theme_stylebox_override("hover", h)
	var p = StyleBoxFlat.new()
	p.bg_color = Color(clr.r, clr.g, clr.b, 0.12)
	p.set_border_width_all(2)
	p.border_color = Color(clr.r, clr.g, clr.b, 0.8)
	btn.add_theme_stylebox_override("pressed", p)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if data.get("type", "") == "unique":
		_make_unique_card(btn, data, width)
	else:
		_make_mutation_card(btn, data, width)

	btn.pressed.connect(func():
		_callback.call(data)
		queue_free()
	)
	return btn

func _make_mutation_card(btn: Button, data: Dictionary, width: float) -> void:
	var branch = data.get("branch", "PREDATOR")
	var color = BRANCH_COLORS.get(branch, Color.WHITE)
	var tier = data.get("tier", 1)

	var border = ColorRect.new()
	border.color = color
	border.color.a = 0.3
	border.size = Vector2(width, 238)
	border.position = Vector2(0, 0)
	btn.add_child(border)

	var tier_badge = ColorRect.new()
	tier_badge.color = color
	tier_badge.size = Vector2(30, 20)
	tier_badge.position = Vector2(width - 34, 6)
	btn.add_child(tier_badge)

	var tier_text = Label.new()
	tier_text.text = "T%d" % tier
	tier_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_text.position = Vector2(width - 34, 6)
	tier_text.size = Vector2(30, 20)
	tier_text.add_theme_font_size_override("font_size", 11)
	tier_text.add_theme_color_override("font_color", Color(0, 0, 0, 0.9))
	btn.add_child(tier_text)

	var icon = Label.new()
	icon.text = BRANCH_ICONS.get(branch, "🧬")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.position = Vector2(width / 2 - 28, 28)
	icon.size = Vector2(56, 56)
	icon.add_theme_font_size_override("font_size", 32)
	btn.add_child(icon)

	var branch_label = Label.new()
	branch_label.text = branch
	branch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	branch_label.position = Vector2(0, 88)
	branch_label.size = Vector2(width, 18)
	branch_label.add_theme_font_size_override("font_size", 10)
	branch_label.add_theme_color_override("font_color", color)
	btn.add_child(branch_label)

	var name_label = Label.new()
	name_label.text = data.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 104)
	name_label.size = Vector2(width, 26)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	btn.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = data.get("desc", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.position = Vector2(8, 132)
	desc_label.size = Vector2(width - 16, 50)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", color)
	btn.add_child(desc_label)

	var existing = MutationManager.current_mutations
	var chain_label = Label.new()
	var chain_text = _get_chain_text(data.get("id", ""), existing)
	chain_label.text = chain_text
	chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chain_label.position = Vector2(0, 186)
	chain_label.size = Vector2(width, 30)
	chain_label.add_theme_font_size_override("font_size", 10)
	chain_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	btn.add_child(chain_label)

func _make_unique_card(btn: Button, data: Dictionary, width: float) -> void:
	var color = Color(1.0, 0.4, 0.8)

	var border = ColorRect.new()
	border.color = color
	border.color.a = 0.3
	border.size = Vector2(width, 238)
	border.position = Vector2(0, 0)
	btn.add_child(border)

	var tier_badge = ColorRect.new()
	tier_badge.color = color
	tier_badge.size = Vector2(30, 20)
	tier_badge.position = Vector2(width - 34, 6)
	btn.add_child(tier_badge)

	var tier_text = Label.new()
	tier_text.text = "T%d" % data.get("tier", 1)
	tier_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_text.position = Vector2(width - 34, 6)
	tier_text.size = Vector2(30, 20)
	tier_text.add_theme_font_size_override("font_size", 11)
	tier_text.add_theme_color_override("font_color", Color(0, 0, 0, 0.9))
	btn.add_child(tier_text)

	var icon = Label.new()
	icon.text = data.get("icon", "✦")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.position = Vector2(width / 2 - 28, 28)
	icon.size = Vector2(56, 56)
	icon.add_theme_font_size_override("font_size", 32)
	btn.add_child(icon)

	var slot_label = Label.new()
	slot_label.text = data.get("slot_id", "").capitalize()
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.position = Vector2(0, 88)
	slot_label.size = Vector2(width, 18)
	slot_label.add_theme_font_size_override("font_size", 10)
	slot_label.add_theme_color_override("font_color", color)
	btn.add_child(slot_label)

	var name_label = Label.new()
	name_label.text = data.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 104)
	name_label.size = Vector2(width, 26)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	btn.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = data.get("desc", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.position = Vector2(8, 132)
	desc_label.size = Vector2(width - 16, 50)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", color)
	btn.add_child(desc_label)

	var hint_label = Label.new()
	hint_label.text = "PART UNIQUE UPGRADE"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.position = Vector2(0, 186)
	hint_label.size = Vector2(width, 30)
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	btn.add_child(hint_label)

func _get_chain_text(mid: String, existing: Dictionary) -> String:
	var data = MutationManager.get_mutation_data(mid)
	if data.is_empty():
		return ""
	var parts: Array[String] = []
	parts.append("◇" if not existing.has(mid) else "◆")
	var next = data.get("next", "")
	if next != "":
		parts.append("→")
		parts.append("◇" if not existing.has(next) else "◆")
		var next2 = MutationManager.get_mutation_data(next).get("next", "")
		if next2 != "":
			parts.append("→")
			parts.append("◇" if not existing.has(next2) else "◆")
	return " ".join(parts)
