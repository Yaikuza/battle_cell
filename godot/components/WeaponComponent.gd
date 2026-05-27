extends Node
class_name WeaponComponent

@export var fire_cooldown: float = 0.8

var behavior: Resource = null
var stats_ref: StatsResource = null
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = fire_cooldown
	_timer.autostart = true
	_timer.timeout.connect(_on_fire)
	add_child(_timer)

func _on_fire() -> void:
	if GameManager.game_over or not behavior:
		return
	if not behavior.has_method("fire"):
		return
	if behavior.fire(get_parent(), stats_ref, get_tree().current_scene):
		AudioManager.play_sfx("shoot", get_parent().global_position)
