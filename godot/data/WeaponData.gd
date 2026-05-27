extends Resource
class_name WeaponData

@export var display_name: String = "Magic Bolt"
@export var damage: float = 10.0
@export var fire_cooldown: float = 0.8
@export var range: float = 400.0
@export var projectile_speed: float = 500.0
@export var behavior_path: String = "res://behaviors/weapons/AimedShot.gd"
