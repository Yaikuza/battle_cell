extends SceneTree
func _initialize() -> void:
	var ok = true
	for path in ["res://managers/EvolutionManager.gd", "res://managers/WaveManager.gd", "res://managers/GameManager.gd"]:
		var s = load(path)
		if s:
			print("OK: ", path)
		else:
			print("FAIL: ", path)
			ok = false
	quit()
