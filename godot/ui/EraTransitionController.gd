extends CanvasLayer
class_name EraTransitionController

var _container: Control
var _label: Label
var _bg: ColorRect

func _ready() -> void:
	layer = 128

	_container = Control.new()
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.6)
	_bg.size = get_viewport().get_visible_rect().size
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_bg)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = get_viewport().get_visible_rect().size
	_label.add_theme_font_size_override("font_size", 64)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_label)

	_container.modulate = Color(1, 1, 1, 0)
	EventBus.era_changed.connect(_on_era_changed)

func _exit_tree() -> void:
	if EventBus.era_changed.is_connected(_on_era_changed):
		EventBus.era_changed.disconnect(_on_era_changed)

func _on_era_changed(era_name: String, _idx: int) -> void:
	_label.text = era_name.to_upper()

	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_container, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.tween_interval(1.5)
	tween.tween_property(_container, "modulate", Color(1, 1, 1, 0), 0.8)
