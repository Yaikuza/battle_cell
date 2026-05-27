extends Resource
class_name EnemyData

@export var display_name: String = "Zombie"
@export var base_hp: float = 20.0
@export var base_speed: float = 60.0
@export var damage: float = 10.0
@export var xp_value: int = 5
@export var size: float = 1.0
@export var color: Color = Color.RED

func apply_wave_scaling(wave: int) -> EnemyData:
	var scaled = duplicate()
	var factor = 1.0 + (wave - 1) * 0.15
	scaled.base_hp = base_hp * factor
	scaled.base_speed = base_speed + wave * 8
	scaled.damage = damage + wave * 2
	scaled.xp_value = xp_value + wave
	return scaled
