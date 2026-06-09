extends Node
class_name DodgeController

signal dodge_started()
signal dodge_ended()
signal charges_changed(new_charges: int, max_charges: int)

@export var dodge_duration: float = 0.25
@export var recharge_time: float = 5.0
@export var dodge_distance: float = 200.0
@export var max_charges: int = 1

var is_dodging: bool = false
var charges: int = 1
var _dodge_timer: Timer
var _recharge_timer: Timer

func _ready() -> void:
	charges = max_charges
	_dodge_timer = Timer.new()
	_dodge_timer.one_shot = true
	_dodge_timer.timeout.connect(_on_dodge_finished)
	add_child(_dodge_timer)

	_recharge_timer = Timer.new()
	_recharge_timer.one_shot = true
	_recharge_timer.timeout.connect(_on_recharge)
	add_child(_recharge_timer)

func try_dodge(override_dir: Vector2 = Vector2.ZERO) -> void:
	if charges <= 0 or is_dodging:
		return
	is_dodging = true
	charges -= 1
	charges_changed.emit(charges, max_charges)

	var parent = get_parent() as Node2D
	if parent and override_dir.length_squared() > 0:
		var target = parent.global_position + override_dir.normalized() * dodge_distance
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		tween.tween_property(parent, "global_position", target, dodge_duration)

	dodge_started.emit()
	_dodge_timer.start(dodge_duration)

	if not _recharge_timer.time_left:
		_recharge_timer.start(recharge_time)

func _on_dodge_finished() -> void:
	is_dodging = false
	dodge_ended.emit()

func _on_recharge() -> void:
	charges = mini(charges + 1, max_charges)
	charges_changed.emit(charges, max_charges)
	if charges < max_charges:
		_recharge_timer.start(recharge_time)
