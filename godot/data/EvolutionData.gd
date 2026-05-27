extends Resource
class_name EvolutionData

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var era_unlock: int = 0
@export var base_stats: Dictionary = {
	"speed": 300, "max_hp": 100, "damage": 15,
	"fire_cooldown": 0.8, "projectile_speed": 500, "range": 400
}
@export var color: Color = Color.GREEN
@export var size: float = 1.0
@export var next_evolution_ids: Array[String] = []
