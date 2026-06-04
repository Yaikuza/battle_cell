extends Node
class_name DodgeController

signal dodge_started()
signal dodge_ended()

@export var dodge_duration: float = 0.25
@export var cooldown: float = 0.8
@export var dodge_distance: float = 200.0

var is_dodging: bool = false
var _can_dodge: bool = true
var _dodge_timer: Timer
var _cooldown_timer: Timer

func _ready() -> void:
	_dodge_timer = Timer.new()
	_dodge_timer.one_shot = true
	_dodge_timer.timeout.connect(_on_dodge_finished)
	add_child(_dodge_timer)

	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(_cooldown_timer)

func try_dodge(override_dir: Vector2 = Vector2.ZERO) -> void:
	if not _can_dodge or is_dodging:
		return
	is_dodging = true
	_can_dodge = false

	var parent = get_parent() as Node2D
	if parent and override_dir.length_squared() > 0:
		var target = parent.global_position + override_dir.normalized() * dodge_distance
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		tween.tween_property(parent, "global_position", target, dodge_duration)

	dodge_started.emit()
	_dodge_timer.start(dodge_duration)

func _on_dodge_finished() -> void:
	is_dodging = false
	dodge_ended.emit()
	_cooldown_timer.start(cooldown)

func _on_cooldown_finished() -> void:
	_can_dodge = true
