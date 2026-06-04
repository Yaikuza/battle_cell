extends Node
class_name DamageCalculator

enum DamageType { PHYSICAL, MAGIC, TRUE }

static func calculate(base_damage: float, multiplier: float, armor: int, damage_type: int) -> int:
	var dmg = base_damage * multiplier
	match damage_type:
		DamageType.PHYSICAL:
			dmg = maxf(dmg - armor, 1)
		DamageType.MAGIC:
			dmg = dmg * maxf(1.0 - armor * 0.01, 0.1)
		DamageType.TRUE:
			pass
	return ceili(dmg)
