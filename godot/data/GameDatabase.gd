extends Resource
class_name GameDatabase

@export var forms: Array = []
@export var enemies: Array = []
@export var upgrades: Array = []
@export var hybrid_recipes: Array = []
@export var eras: Array = []

func get_form(id: String):
	for f in forms:
		if f.id == id:
			return f
	return null

func get_enemy(id: String):
	for e in enemies:
		if e.id == id:
			return e
	return null

func get_upgrade(id: String):
	for u in upgrades:
		if u.id == id:
			return u
	return null

func get_era(index: int):
	if index >= 0 and index < eras.size():
		return eras[index]
	return null

func get_hybrid_recipe(result_id: String):
	for r in hybrid_recipes:
		if r.result_form_id == result_id:
			return r
	return null
