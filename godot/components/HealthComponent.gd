extends Node
class_name HealthComponent

signal died()
signal health_changed(current: int, max_hp: int)

@export var max_hp: int = 100
var hp: int
var invulnerable: bool = false

func _ready() -> void:
	hp = max_hp

func take_damage(amount: int) -> void:
	if invulnerable:
		return
	hp = max(0, hp - amount)
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)

func set_invulnerable(duration: float) -> void:
	invulnerable = true
	await get_tree().create_timer(duration).timeout
	invulnerable = false
