extends Resource
class_name FormPartConfig

@export var slot_id: String = ""
@export var slot_type: String = "body"
@export var position: Vector2 = Vector2.ZERO
@export var scale: Vector2 = Vector2.ONE
@export var rotation: float = 0.0
@export var color: Color = Color.WHITE
@export var z_index: int = 0
@export var draw_type: String = "circle"
@export var draw_params: Dictionary = { "radius": 16 }
@export var weapon_behavior_id: String = ""
@export var weapon_cooldown: float = 0.0
@export var stat_mods: Array[Dictionary] = []
