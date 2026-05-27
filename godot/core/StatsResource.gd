extends Resource
class_name StatsResource

enum ModType { FLAT, PERCENT }

class StatModifier:
	var stat: String
	var value: float
	var type: ModType
	var source: String

	func _init(s: String, v: float, t: ModType, src: String = ""):
		stat = s
		value = v
		type = t
		source = src

var _base: Dictionary = {}
var _modifiers: Array[StatModifier] = []

func set_base(stat: String, value: float) -> void:
	_base[stat] = value

func load_from_dict(data: Dictionary) -> void:
	for key in data:
		_base[key] = data[key]

func get_stat(stat: String, default: float = 0.0) -> float:
	if not _base.has(stat):
		return default
	var val = _base[stat]
	var flat := 0.0
	var pct := 0.0
	for m in _modifiers:
		if m.stat == stat:
			match m.type:
				ModType.FLAT:
					flat += m.value
				ModType.PERCENT:
					pct += m.value
	return (val + flat) * (1.0 + pct)

func get_base(stat: String, default: float = 0.0) -> float:
	return _base.get(stat, default)

func add_modifier(mod: StatModifier) -> void:
	_modifiers.append(mod)

func add_modifier_raw(stat: String, value: float, type: ModType, source: String = "") -> void:
	_modifiers.append(StatModifier.new(stat, value, type, source))

func remove_modifiers_from(source: String) -> void:
	var remaining: Array[StatModifier] = []
	for m in _modifiers:
		if m.source != source:
			remaining.append(m)
	_modifiers = remaining

func clear_modifiers() -> void:
	_modifiers.clear()

func duplicate_stats() -> StatsResource:
	var dup = StatsResource.new()
	for key in _base:
		dup._base[key] = _base[key]
	for m in _modifiers:
		dup._modifiers.append(StatModifier.new(m.stat, m.value, m.type, m.source))
	return dup
