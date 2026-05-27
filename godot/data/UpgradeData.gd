extends Resource
class_name UpgradeData

@export var display_name: String = "Damage Up"
@export var description: String = "Increase damage by 20%"
@export var icon: Texture2D
@export var stat: String = "damage"
@export var modifier_value: float = 0.2
@export var modifier_type: StatsResource.ModType = StatsResource.ModType.PERCENT
@export var rarity: int = 1
