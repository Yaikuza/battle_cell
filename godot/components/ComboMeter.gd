extends Node
class_name ComboMeter

const MAX_COMBO: int = 5
const DECAY_INTERVAL: float = 0.25

var combo_value: int = 0
var _decay_timer: Timer

signal combo_changed(value: int)
signal combo_full(max_reached: int)
signal combo_broken()

func _ready() -> void:
	_decay_timer = Timer.new()
	_decay_timer.one_shot = false
	_decay_timer.wait_time = DECAY_INTERVAL
	_decay_timer.timeout.connect(_on_decay)
	add_child(_decay_timer)
	_decay_timer.start()

func add_hit() -> void:
	if combo_value < MAX_COMBO:
		combo_value += 1
		combo_changed.emit(combo_value)
		if combo_value >= MAX_COMBO:
			combo_full.emit(combo_value)
			combo_value = 0
			combo_changed.emit(combo_value)
	_decay_timer.stop()
	_decay_timer.start()

func add_perfect() -> void:
	var target = mini(combo_value + 2, MAX_COMBO)
	if target > combo_value:
		combo_value = target
		combo_changed.emit(combo_value)
		if combo_value >= MAX_COMBO:
			combo_full.emit(combo_value)
			combo_value = 0
			combo_changed.emit(combo_value)
	_decay_timer.stop()
	_decay_timer.start()

func reset() -> void:
	if combo_value > 0:
		combo_value = 0
		combo_changed.emit(0)
		combo_broken.emit()
	_decay_timer.stop()
	_decay_timer.start()

func _on_decay() -> void:
	if combo_value > 0:
		combo_value -= 1
		combo_changed.emit(combo_value)
