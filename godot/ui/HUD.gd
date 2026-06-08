extends CanvasLayer
class_name HUD

enum ComboState { IDLE, FULL, BROKEN }

const COMBO_COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6),
	Color(0.4, 0.8, 0.4),
	Color(0.2, 0.9, 0.2),
	Color(0.1, 1.0, 0.6),
	Color(1.0, 0.9, 0.2),
]

var hp_label: Label
var gp_label: Label
var score_label: Label
var era_label: Label
var wave_label: Label
var gp_bar: ProgressBar
var _combo_containers: Array[ColorRect] = []
var _combo_state: int = ComboState.IDLE

func _ready() -> void:
	hp_label = Label.new()
	hp_label.position = Vector2(10, 10)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(hp_label)

	gp_label = Label.new()
	gp_label.position = Vector2(10, 30)
	gp_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	add_child(gp_label)

	score_label = Label.new()
	score_label.position = Vector2(10, 50)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(score_label)

	era_label = Label.new()
	era_label.position = Vector2(10, 70)
	era_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	add_child(era_label)

	var vp = get_viewport().get_visible_rect().size
	wave_label = Label.new()
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.position = Vector2(vp.x / 2 - 60, 10)
	wave_label.size = Vector2(120, 20)
	wave_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(wave_label)

	gp_bar = ProgressBar.new()
	gp_bar.position = Vector2(10, 95)
	gp_bar.size = Vector2(200, 12)
	gp_bar.show_percentage = false
	gp_bar.modulate = Color(0.2, 1.0, 0.3)
	add_child(gp_bar)

	_build_combo_display(vp)

	EventBus.gp_changed.connect(_on_gp_changed)
	EventBus.era_changed.connect(_on_era_changed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.wave_changed.connect(_on_wave_changed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.wave_announcement.connect(_on_wave_announcement)
	EventBus.combo_changed.connect(_on_combo_changed)
	EventBus.combo_full.connect(_on_combo_full)
	EventBus.combo_broken.connect(_on_combo_broken)

func _build_combo_display(vp: Vector2) -> void:
	var start_x = vp.x - 140
	var start_y = vp.y - 30
	for i in 5:
		var rect = ColorRect.new()
		rect.size = Vector2(20, 20)
		rect.position = Vector2(start_x + i * 26, start_y)
		rect.color = Color(0.3, 0.3, 0.3, 0.6)
		add_child(rect)
		_combo_containers.append(rect)

func _exit_tree() -> void:
	if EventBus.gp_changed.is_connected(_on_gp_changed):
		EventBus.gp_changed.disconnect(_on_gp_changed)
	if EventBus.era_changed.is_connected(_on_era_changed):
		EventBus.era_changed.disconnect(_on_era_changed)
	if EventBus.score_changed.is_connected(_on_score_changed):
		EventBus.score_changed.disconnect(_on_score_changed)
	if EventBus.wave_changed.is_connected(_on_wave_changed):
		EventBus.wave_changed.disconnect(_on_wave_changed)
	if EventBus.game_over.is_connected(_on_game_over):
		EventBus.game_over.disconnect(_on_game_over)
	if EventBus.wave_announcement.is_connected(_on_wave_announcement):
		EventBus.wave_announcement.disconnect(_on_wave_announcement)
	if EventBus.combo_changed.is_connected(_on_combo_changed):
		EventBus.combo_changed.disconnect(_on_combo_changed)
	if EventBus.combo_full.is_connected(_on_combo_full):
		EventBus.combo_full.disconnect(_on_combo_full)
	if EventBus.combo_broken.is_connected(_on_combo_broken):
		EventBus.combo_broken.disconnect(_on_combo_broken)

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		hp_label.text = "HP: %d/%d" % [player.health.hp, player.health.max_hp]

func refresh() -> void:
	gp_bar.max_value = GameManager.gp_to_next
	gp_bar.value = GameManager.gp
	gp_label.text = "GP: %d/%d" % [GameManager.gp, GameManager.gp_to_next]
	score_label.text = "Score: %d" % GameManager.score
	era_label.text = "Era: %s" % EraManager.get_era_name()
	wave_label.text = "Wave: %d" % GameManager.wave

func _on_gp_changed(current: int, max_value: int) -> void:
	gp_bar.max_value = max_value
	gp_bar.value = current
	gp_label.text = "GP: %d/%d" % [current, max_value]

func _on_era_changed(era_name: String, _idx: int) -> void:
	era_label.text = "Era: %s" % era_name

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score

func _on_wave_changed(new_wave: int) -> void:
	wave_label.text = "Wave: %d" % new_wave

func _on_wave_announcement(wave: int, era: String) -> void:
	var vp = get_viewport().get_visible_rect().size
	var label = Label.new()
	var is_boss = wave > 0 and wave % 5 == 0
	if is_boss:
		label.text = "⚠ Wave %d — BOSS ⚠" % wave
	else:
		label.text = "Wave %d — %s" % [wave, era]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(vp.x, 40)
	label.position = Vector2(0, vp.y * 0.35)
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	label.modulate.a = 0.0
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.4)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)

func _on_combo_changed(value: int) -> void:
	for i in 5:
		if i < _combo_containers.size():
			if i < value:
				_combo_containers[i].color = COMBO_COLORS[i]
			else:
				_combo_containers[i].color = Color(0.3, 0.3, 0.3, 0.6)
	_combo_state = ComboState.IDLE

func _on_combo_full(_bar_index: int) -> void:
	_combo_state = ComboState.FULL
	for rect in _combo_containers:
		var tw = create_tween()
		tw.tween_property(rect, "color", Color(1, 1, 1), 0.1)
		tw.tween_property(rect, "color", COMBO_COLORS[4], 0.1)

func _on_combo_broken() -> void:
	_combo_state = ComboState.BROKEN
	for rect in _combo_containers:
		rect.color = Color(1, 0.2, 0.2, 0.8)
		var tw = create_tween()
		tw.tween_interval(0.3)
		tw.tween_property(rect, "color", Color(0.3, 0.3, 0.3, 0.6), 0.2)

func _on_game_over() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		hp_label.text = "HP: 0/%d" % player.health.max_hp

	var vp = get_viewport().get_visible_rect().size
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = vp
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var go_label = Label.new()
	go_label.text = "EXTINCTION EVENT\nScore: %d" % GameManager.score
	go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	go_label.size = vp
	go_label.add_theme_font_size_override("font_size", 48)
	go_label.add_theme_color_override("font_color", Color.RED)
	add_child(go_label)

	var best = SaveManager.highscores[0] if SaveManager.highscores.size() > 0 else null
	if best:
		var best_label = Label.new()
		best_label.text = "Best: %d (Wave %d — %s)" % [best.score, best.wave, SaveManager.get_form_name(best.get("form", ""))]
		best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		best_label.position = Vector2(0, vp.y / 2 + 30)
		best_label.size = vp
		best_label.add_theme_font_size_override("font_size", 14)
		best_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		add_child(best_label)

	var restart_label = Label.new()
	restart_label.text = "R — Restart | ESC — Menu"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.position = Vector2(0, vp.y / 2 + 60)
	restart_label.size = vp
	restart_label.add_theme_font_size_override("font_size", 20)
	restart_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(restart_label)
