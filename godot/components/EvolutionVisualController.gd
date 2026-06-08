extends Node2D
class_name EvolutionVisualController

const PartVisualScript = preload("res://components/PartVisual.gd")
const MORPH_DURATION: float = 0.4
const FADE_DURATION: float = 0.25

var _parts: Dictionary = {}

func apply_parts(configs: Array) -> void:
	var new_ids = {}
	for cfg in configs:
		new_ids[cfg.slot_id] = true
		var existing = _parts.get(cfg.slot_id) as Node2D
		if existing:
			existing.tween_to(cfg, MORPH_DURATION)
		else:
			var pv = PartVisualScript.new()
			pv.name = "Part_" + cfg.slot_id
			pv.apply_config(cfg)
			add_child(pv)
			_parts[cfg.slot_id] = pv
			pv.fade_in(FADE_DURATION)

	for sid in _parts.keys():
		if not new_ids.has(sid):
			var old = _parts[sid] as Node2D
			_parts.erase(sid)
			old.fade_out(FADE_DURATION)


func clear_all() -> void:
	for pv in _parts.values():
		pv.queue_free()
	_parts.clear()

func get_weapon_ids() -> Array[String]:
	var result: Array[String] = []
	for pv in _parts.values():
		var cfg = pv.config
		if cfg and not cfg.weapon_behavior_id.is_empty():
			result.append(cfg.weapon_behavior_id)
	return result

func get_stat_mods() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pv in _parts.values():
		var cfg = pv.config
		if cfg and not cfg.stat_mods.is_empty():
			result.append_array(cfg.stat_mods)
	return result
