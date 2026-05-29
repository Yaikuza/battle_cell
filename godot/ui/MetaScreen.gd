extends CanvasLayer
class_name MetaScreen

var _tab_index: int = 0
var _tab_btns: Array[Button] = []
var _content: Node = null
var _back_btn: Button = null

const TAB_LABELS := ["Traits", "Start Perks", "Legacy", "WTF Edge", "Titles"]
const TAB_COLORS := [
	Color(0.2, 1.0, 0.6),
	Color(1.0, 0.6, 0.2),
	Color(1.0, 0.2, 0.8),
	Color(1.0, 0.8, 0.0),
	Color(0.6, 0.4, 1.0),
]

func _ready() -> void:
	var vp = get_viewport().get_visible_rect().size

	offset = Vector2(vp.x, 0)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.25)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = vp
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var title = Label.new()
	title.text = "GENETIC MEMORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.03)
	title.size = Vector2(vp.x, 32)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	add_child(title)

	var dna_label = Label.new()
	dna_label.name = "DnaLabel"
	dna_label.text = "DNA Balance: %d" % MetaManager.dna_balance
	dna_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dna_label.position = Vector2(0, vp.y * 0.03 + 32)
	dna_label.size = Vector2(vp.x, 16)
	dna_label.add_theme_font_size_override("font_size", 12)
	dna_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	add_child(dna_label)

	var title_tid = MetaManager.active_title
	if title_tid.is_empty():
		title_tid = MetaManager.get_title_for_dna()
	var tid_name = MetaManager.get_title_name(title_tid)
	if tid_name:
		var tid_label = Label.new()
		tid_label.text = "Title: %s" % tid_name
		tid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tid_label.position = Vector2(0, vp.y * 0.03 + 50)
		tid_label.size = Vector2(vp.x, 14)
		tid_label.add_theme_font_size_override("font_size", 10)
		tid_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
		add_child(tid_label)

	var tab_bar = Node2D.new()
	var tw = vp.x / TAB_LABELS.size()
	for i in TAB_LABELS.size():
		var btn = Button.new()
		btn.text = TAB_LABELS[i]
		btn.position = Vector2(i * tw, vp.y * 0.10)
		btn.size = Vector2(tw - 4, 28)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_tab.bind(i))
		tab_bar.add_child(btn)
		_tab_btns.append(btn)
	add_child(tab_bar)

	_content = Node.new()
	add_child(_content)
	_show_tab(0)

	var back = Button.new()
	back.name = "BackBtn"
	back.text = "  Back"
	back.position = Vector2(10, 10)
	back.size = Vector2(80, 30)
	back.add_theme_font_size_override("font_size", 14)
	back.pressed.connect(_slide_out)
	_back_btn = back
	add_child(back)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		_on_tab(maxi(0, _tab_index - 1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		_on_tab(mini(TAB_LABELS.size() - 1, _tab_index + 1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_slide_out()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()

func _slide_out() -> void:
	AudioManager.play_sfx("click")
	var vpx = get_viewport().get_visible_rect().size.x
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "offset", Vector2(vpx, 0), 0.2)
	tween.tween_callback(queue_free)

func _on_tab(idx: int) -> void:
	AudioManager.play_sfx("click")
	_show_tab(idx)

func _show_tab(idx: int) -> void:
	_tab_index = idx
	for i in _tab_btns.size():
		_tab_btns[i].modulate = Color(1, 1, 1, 0.6) if i != idx else Color.WHITE

	if _content:
		_content.queue_free()
	_content = Node.new()
	add_child(_content)
	_update_dna()

	match idx:
		0: _show_traits()
		1: _show_starters()
		2: _show_legacy()
		3: _show_wtf()
		4: _show_titles()

func _update_dna() -> void:
	var dl = get_node_or_null("DnaLabel") as Label
	if dl:
		dl.text = "DNA Balance: %d" % MetaManager.dna_balance

func _make_card(parent: Node, up_id: String, name: String, desc: String, lv: int, max_lv: int, cost: int, y: float, vp: Vector2, on_buy: Callable) -> void:
	var card = ColorRect.new()
	card.color = Color(0.1, 0.1, 0.2, 0.8)
	card.position = Vector2(vp.x * 0.05, y)
	card.size = Vector2(vp.x * 0.9, 50)
	parent.add_child(card)

	var nm = Label.new()
	nm.text = "%s Lv.%d/%d" % [name, lv, max_lv]
	nm.position = Vector2(vp.x * 0.07, y + 4)
	nm.size = Vector2(vp.x * 0.5, 18)
	nm.add_theme_font_size_override("font_size", 12)
	nm.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(nm)

	var dc = Label.new()
	dc.text = desc
	dc.position = Vector2(vp.x * 0.07, y + 24)
	dc.size = Vector2(vp.x * 0.55, 18)
	dc.add_theme_font_size_override("font_size", 9)
	dc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	parent.add_child(dc)

	if lv < max_lv:
		var buy = Button.new()
		buy.text = "%d DNA" % cost
		buy.position = Vector2(vp.x * 0.82, y + 8)
		buy.size = Vector2(vp.x * 0.14, 34)
		buy.add_theme_font_size_override("font_size", 11)
		buy.disabled = MetaManager.dna_balance < cost
		buy.pressed.connect(func():
			AudioManager.play_sfx("click")
			if on_buy.call():
				_update_dna()
				_show_tab(_tab_index))
		parent.add_child(buy)
	else:
		var max_l = Label.new()
		max_l.text = "MAX"
		max_l.position = Vector2(vp.x * 0.82, y + 10)
		max_l.size = Vector2(vp.x * 0.14, 28)
		max_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		max_l.add_theme_font_size_override("font_size", 13)
		max_l.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		parent.add_child(max_l)

func _show_traits() -> void:
	var vp = get_viewport().get_visible_rect().size
	var y = vp.y * 0.16
	for up_id in MetaManager.TRAITS:
		var d = MetaManager.TRAITS[up_id]
		var lv = MetaManager.get_upgrade_level(up_id)
		var cost = MetaManager.get_upgrade_cost(up_id, MetaManager.TRAITS)
		_make_card(_content, up_id, d.name, d.desc, lv, d.max_lv, cost, y, vp, func(): return MetaManager.purchase_upgrade(up_id, MetaManager.TRAITS))
		y += 56

func _show_starters() -> void:
	var vp = get_viewport().get_visible_rect().size
	var y = vp.y * 0.16
	for up_id in MetaManager.STARTERS:
		var d = MetaManager.STARTERS[up_id]
		var lv = MetaManager.get_upgrade_level(up_id)
		var cost = MetaManager.get_upgrade_cost(up_id, MetaManager.STARTERS)
		_make_card(_content, up_id, d.name, "%s %d" % [d.desc, d.vals[mini(lv, d.max_lv - 1)]], lv, d.max_lv, cost, y, vp, func(): return MetaManager.purchase_upgrade(up_id, MetaManager.STARTERS))
		y += 56

func _show_legacy() -> void:
	var vp = get_viewport().get_visible_rect().size
	var y = vp.y * 0.16
	for form_id in MetaManager.LEGACY:
		var d = MetaManager.LEGACY[form_id]
		var unlocked = MetaManager.is_legacy_unlocked(form_id)
		var nm = Label.new()
		nm.text = d.name
		nm.position = Vector2(vp.x * 0.07, y + 4)
		nm.size = Vector2(vp.x * 0.55, 18)
		nm.add_theme_font_size_override("font_size", 12)
		nm.add_theme_color_override("font_color", Color.WHITE)
		_content.add_child(nm)

		var dc = Label.new()
		dc.text = d.desc
		dc.position = Vector2(vp.x * 0.07, y + 24)
		dc.size = Vector2(vp.x * 0.55, 18)
		dc.add_theme_font_size_override("font_size", 9)
		dc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_content.add_child(dc)

		if unlocked:
			var ul = Label.new()
			ul.text = "UNLOCKED"
			ul.position = Vector2(vp.x * 0.82, y + 8)
			ul.size = Vector2(vp.x * 0.14, 28)
			ul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ul.add_theme_font_size_override("font_size", 11)
			ul.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
			_content.add_child(ul)
		else:
			var buy = Button.new()
			buy.text = "%d DNA" % d.cost
			buy.position = Vector2(vp.x * 0.82, y + 6)
			buy.size = Vector2(vp.x * 0.14, 34)
			buy.add_theme_font_size_override("font_size", 11)
			buy.disabled = MetaManager.dna_balance < d.cost
			buy.pressed.connect(func():
				AudioManager.play_sfx("click")
				if MetaManager.purchase_legacy(form_id):
					_update_dna()
					_show_tab(_tab_index))
			_content.add_child(buy)
		y += 50

func _show_wtf() -> void:
	var vp = get_viewport().get_visible_rect().size
	var y = vp.y * 0.16
	for up_id in MetaManager.WTF_SHORTCUTS:
		var d = MetaManager.WTF_SHORTCUTS[up_id]
		var lv = MetaManager.get_upgrade_level(up_id)
		var cost = MetaManager.get_upgrade_cost(up_id, MetaManager.WTF_SHORTCUTS)
		var needed = MetaManager.get_first_wtf_needed_lv(up_id)
		_make_card(_content, up_id, d.name, "%s (need: %s)" % [d.desc, str(needed) if needed > 0 else "none"], lv, d.max_lv, cost, y, vp, func(): return MetaManager.purchase_upgrade(up_id, MetaManager.WTF_SHORTCUTS))
		y += 56

func _show_titles() -> void:
	var vp = get_viewport().get_visible_rect().size
	var y = vp.y * 0.16
	for t in MetaManager.TITLES:
		var unlocked = MetaManager.dna_total >= t.dna
		var is_active = MetaManager.active_title == t.id

		var card = ColorRect.new()
		card.color = Color(0.1, 0.1, 0.2, 0.8)
		card.position = Vector2(vp.x * 0.05, y)
		card.size = Vector2(vp.x * 0.9, 44)
		_content.add_child(card)

		var nm = Label.new()
		nm.text = t.name
		nm.position = Vector2(vp.x * 0.07, y + 4)
		nm.size = Vector2(vp.x * 0.4, 18)
		nm.add_theme_font_size_override("font_size", 13)
		nm.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.4, 0.4, 0.4))
		_content.add_child(nm)

		var need = Label.new()
		need.text = "%s: %d DNA" % ["Unlocked at" if not unlocked else "Requires", t.dna]
		need.position = Vector2(vp.x * 0.07, y + 22)
		need.size = Vector2(vp.x * 0.5, 16)
		need.add_theme_font_size_override("font_size", 9)
		need.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_content.add_child(need)

		if unlocked and not is_active:
			var equip = Button.new()
			equip.text = "Equip"
			equip.position = Vector2(vp.x * 0.82, y + 6)
			equip.size = Vector2(vp.x * 0.14, 32)
			equip.add_theme_font_size_override("font_size", 11)
			equip.pressed.connect(func():
				AudioManager.play_sfx("click")
				MetaManager.active_title = t.id
				MetaManager.save_meta()
				_show_tab(_tab_index))
			_content.add_child(equip)
		elif is_active:
			var active_l = Label.new()
			active_l.text = "ACTIVE"
			active_l.position = Vector2(vp.x * 0.82, y + 8)
			active_l.size = Vector2(vp.x * 0.14, 28)
			active_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			active_l.add_theme_font_size_override("font_size", 11)
			active_l.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
			_content.add_child(active_l)

		y += 50
