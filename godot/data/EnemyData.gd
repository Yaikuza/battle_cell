extends Resource
class_name EnemyData

@export var id: String = ""
@export var display_name: String = ""
@export var base_hp: float = 20.0
@export var base_speed: float = 60.0
@export var damage: float = 10.0
@export var gp_value: int = 5
@export var size: float = 14.0
@export var color: Color = Color.RED
@export var sprite_id: String = "enemy"
@export var behavior_id: String = "chase"
@export var fire_interval: float = 1.5
@export var preferred_range: float = 180.0
@export var charge_mult: float = 3.0
@export var is_boss: bool = false
