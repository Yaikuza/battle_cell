extends Resource
class_name MutationData

enum Branch { PREDATOR, ARMORED, SWIFT, HYBRID }
enum EffectType { STAT_MOD, WEAPON_MOD, UTILITY }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var tier: int = 0
@export var branch: Branch = Branch.PREDATOR
@export var effect_type: EffectType = EffectType.STAT_MOD
@export var stat: String = "damage"
@export var modifier_value: float = 0.0
@export var modifier_type: StatsResource.ModType = StatsResource.ModType.PERCENT
@export var next_tier_id: String = ""
