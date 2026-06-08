extends Resource
class_name BossSkillData

enum SkillType {
	CHARGE,
	SPREAD,
	SUMMON,
	AOE,
	BUFF,
	DASH,
	CLAW_SNAP,
	EYE_BEAM,
	TAIL_FLAIL,
	ROLL_UP,
	SPINE_SHOT,
	GROUND_POUND,
	SLAM_WAVE,
	JELLY_SPAWN,
	VENOM_SPIT,
	POUNCE_MARK,
	PACK_CALL,
	TAIL_SWEEP,
	BONE_RAIN,
	FURY_ROAR,
}

@export var skill_id: String
@export var skill_name: String = ""
@export var type: SkillType = SkillType.CHARGE
@export var cooldown: float = 3.0
@export var damage_mult: float = 1.0
@export var telegraph_time: float = 0.5
@export var telegraph_color: Color = Color(1.0, 0.2, 0.0)
@export var params: Dictionary = {}
