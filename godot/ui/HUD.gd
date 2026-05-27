extends CanvasLayer
class_name HUD

var hp_label: Label
var gp_label: Label
var score_label: Label
var era_label: Label
var wave_label: Label
var gp_bar: ProgressBar

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

	wave_label = Label.new()
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 60, 10)
	wave_label.size = Vector2(120, 20)
	wave_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(wave_label)

	gp_bar = ProgressBar.new()
	gp_bar.position = Vector2(10, 95)
	gp_bar.size = Vector2(200, 12)
	gp_bar.show_percentage = false
	gp_bar.modulate = Color(0.2, 1.0, 0.3)
	add_child(gp_bar)

	EventBus.gp_changed.connect(_on_gp_changed)
	EventBus.era_changed.connect(_on_era_changed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.wave_changed.connect(_on_wave_changed)
	EventBus.game_over.connect(_on_game_over)

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

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		hp_label.text = "HP: %d/%d" % [player.health.hp, player.health.max_hp]

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

func _on_game_over() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		hp_label.text = "HP: 0/%d" % player.health.max_hp

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var go_label = Label.new()
	go_label.text = "EXTINCTION EVENT\nScore: %d" % GameManager.score
	go_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	go_label.size = get_viewport().get_visible_rect().size
	go_label.add_theme_font_size_override("font_size", 48)
	go_label.add_theme_color_override("font_color", Color.RED)
	add_child(go_label)

	var restart_label = Label.new()
	restart_label.text = "R — Restart | ESC — Menu"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.position = Vector2(0, get_viewport().get_visible_rect().size.y / 2 + 60)
	restart_label.size = get_viewport().get_visible_rect().size
	restart_label.add_theme_font_size_override("font_size", 20)
	restart_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(restart_label)
