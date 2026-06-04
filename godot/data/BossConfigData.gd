extends Resource
class_name BossConfigData

@export var boss_id: String
@export var display_name: String = ""
@export var is_mini: bool = false
@export var base_hp: int = 200
@export var base_damage: int = 25
@export var base_speed: float = 40.0
@export var size: float = 32.0
@export var sprite_id: String = "tyrant_king"
@export var color: Color = Color(0.8, 0.1, 0.0)
@export var skill_ids: Array = []
@export var max_concurrent_skills: int = 1
@export var gp_value: int = 50
@export var era_min: int = 0
