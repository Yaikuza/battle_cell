extends Area2D
class_name Player

const AimedShotScript = preload("res://behaviors/weapons/AimedShot.gd")
const CellBurstScript = preload("res://behaviors/weapons/CellBurst.gd")
const WaterJetScript = preload("res://behaviors/weapons/WaterJet.gd")
const TongueLashScript = preload("res://behaviors/weapons/TongueLash.gd")
const StingDartScript = preload("res://behaviors/weapons/StingDart.gd")
const TailSweepScript = preload("res://behaviors/weapons/TailSweep.gd")
const PiercingStingScript = preload("res://behaviors/weapons/PiercingSting.gd")
const CrushingBiteScript = preload("res://behaviors/weapons/CrushingBite.gd")
const SwarmShotScript = preload("res://behaviors/weapons/SwarmShot.gd")
const PincerClawScript = preload("res://behaviors/weapons/PincerClaw.gd")
const FireBreathScript = preload("res://behaviors/weapons/FireBreath.gd")
const ChaosBeamScript = preload("res://behaviors/weapons/ChaosBeam.gd")
const SlashBehaviorScript = preload("res://behaviors/weapons/SlashBehavior.gd")
const PsychicBlastScript = preload("res://behaviors/weapons/PsychicBlast.gd")
const BouncyShotScript = preload("res://behaviors/weapons/BouncyShot.gd")
const SuctionBehaviorScript = preload("res://behaviors/weapons/SuctionBehavior.gd")
const StareBehaviorScript = preload("res://behaviors/weapons/StareBehavior.gd")
const EvolutionVisualControllerScript = preload("res://components/EvolutionVisualController.gd")
const _weapon_map: Dictionary = {
	"aimed_shot": AimedShotScript,
	"cell_burst": CellBurstScript,
	"water_jet": WaterJetScript,
	"tongue_lash": TongueLashScript,
	"sting_dart": StingDartScript,
	"tail_sweep": TailSweepScript,
	"piercing_sting": PiercingStingScript,
	"crushing_bite": CrushingBiteScript,
	"swarm_shot": SwarmShotScript,
	"pincer_claw": PincerClawScript,
	"fire_breath": FireBreathScript,
	"chaos_beam": ChaosBeamScript,
	"slash": SlashBehaviorScript,
	"psychic_blast": PsychicBlastScript,
	"bouncy_shot": BouncyShotScript,
	"suction": SuctionBehaviorScript,
	"stare": StareBehaviorScript,
}

var stats: StatsResource
var health: HealthComponent
var movement: MovementComponent
var weapon: WeaponComponent
var _sprite: Sprite2D
var _hurtbox: HurtboxComponent
var _dodge: DodgeController
var _visual
var _camera: Camera2D
var _timer_cooldown_overrides: Dictionary = {}
var _mutation_bonuses: Array[Dictionary] = []
var _part_effects: PartEffectHandler
var _combo: ComboMeter
var _last_hit_time: float = -1.0
var _regen_timer: Timer
var _debug_god_mode: bool = false

func _ready() -> void:
	add_to_group("player")
	EventBus.mutation_applied.connect(_on_mutation_applied)

	stats = StatsResource.new()
	stats.load_from_dict({
		"speed": 80.0, "max_hp": 100.0,
		"damage": 18.0, "fire_cooldown": 0.8,
		"projectile_speed": 500.0, "range": 400.0,
		"armor": 0, "dodge_cooldown": 5.0, "dodge_charges": 1.0
	})
	_log("PLAYER_READY init fire_cooldown=" + str(stats.get_stat("fire_cooldown")))

	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 18
	add_child(collision)

	_sprite = Sprite2D.new()
	_sprite.name = "FormSprite"
	var tex = _load_texture("cell")
	if tex:
		_sprite.texture = tex
	add_child(_sprite)

	health = HealthComponent.new()
	health.max_hp = ceili(stats.get_stat("max_hp"))
	add_child(health)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)

	movement = MovementComponent.new()
	movement.mode = MovementComponent.Mode.PLAYER
	movement.speed = stats.get_stat("speed")
	add_child(movement)

	weapon = WeaponComponent.new()
	weapon.fire_cooldown = stats.get_stat("fire_cooldown")
	weapon.stats_ref = stats
	print("=== PLAYER INIT weapon_map keys: ", _weapon_map.keys())
	weapon.add_behavior(SlashBehaviorScript.new())
	add_child(weapon)

	_hurtbox = HurtboxComponent.new()
	_hurtbox.owner_group = "player"
	_hurtbox._shape_radius = 18.0
	_hurtbox.name = "PlayerHurtbox"
	add_child(_hurtbox)
	_hurtbox.damage_taken.connect(_on_hurtbox_damage_taken)

	_dodge = DodgeController.new()
	_dodge.name = "DodgeController"
	add_child(_dodge)
	_dodge.dodge_started.connect(_on_dodge_started)
	_dodge.dodge_ended.connect(_on_dodge_ended)

	_visual = EvolutionVisualControllerScript.new()
	_visual.name = "EvolutionVisualController"
	add_child(_visual)

	_camera = Camera2D.new()
	_camera.name = "PlayerCamera"
	_camera.enabled = true
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 5.0
	add_child(_camera)

	_part_effects = PartEffectHandler.new()
	_part_effects.name = "PartEffectHandler"
	add_child(_part_effects)

	_combo = ComboMeter.new()
	_combo.name = "ComboMeter"
	add_child(_combo)
	_combo.combo_changed.connect(_on_combo_changed)
	_combo.combo_full.connect(_on_combo_full)
	_combo.combo_broken.connect(_on_combo_broken)

	_regen_timer = Timer.new()
	_regen_timer.one_shot = false
	_regen_timer.wait_time = 1.0
	_regen_timer.timeout.connect(_on_regen_tick)
	add_child(_regen_timer)
	_regen_timer.start()

	_apply_meta_stats()
	_validate_weapon_map()

func _validate_weapon_map() -> void:
	for wid in _weapon_map:
		var scr = _weapon_map[wid]
		if not scr:
			push_error("Player._weapon_map[", wid, "] resolves to null")

func _apply_meta_stats() -> void:
	for up_id in MetaManager.TRAITS:
		var d = MetaManager.TRAITS[up_id]
		var lv = MetaManager.get_upgrade_level(up_id)
		if lv > 0 and d.has("stat"):
			stats.add_modifier_raw(d.stat, d.val * lv, 1, "meta")

func take_damage(amount: int) -> void:
	if _hurtbox and not _hurtbox.invulnerable:
		health.take_damage(amount)
		_hurtbox.set_invulnerable(0.5)
		_damage_flash()

func _toggle_god_mode(enabled: bool) -> void:
	_debug_god_mode = enabled
	if _hurtbox:
		_hurtbox.set_invulnerable(999.0 if enabled else 0.0)

func _on_hurtbox_damage_taken(damage: int, _damage_type: int) -> void:
	if _debug_god_mode:
		return
	var dc = stats.get_stat("dodge_chance", 0.0)
	if dc > 0 and randf() < dc:
		return
	health.take_damage(damage)
	_damage_flash()
	_last_hit_time = Time.get_ticks_msec() / 1000.0
	if _combo:
		_combo.reset()

func _damage_flash() -> void:
	modulate = Color(2, 1.5, 1.5)
	await get_tree().create_timer(0.08).timeout
	if not GameManager.game_over:
		modulate = Color.WHITE

func _on_dodge_started() -> void:
	_hurtbox.set_invulnerable(_dodge.dodge_duration)
	var now = Time.get_ticks_msec() / 1000.0
	if _last_hit_time > 0 and now - _last_hit_time < 0.3 and _combo:
		_combo.add_perfect()

func _on_dodge_ended() -> void:
	pass

func _on_regen_tick() -> void:
	if GameManager.game_over:
		return
	var regen = stats.get_stat("hp_regen", 0.0)
	if regen > 0 and health.hp < health.max_hp:
		health.heal(ceili(regen))

func _on_combo_changed(value: int) -> void:
	EventBus.combo_changed.emit(value)

func _on_combo_full(bar_index: int) -> void:
	EventBus.combo_full.emit(bar_index)

func _on_combo_broken() -> void:
	EventBus.combo_broken.emit()

func _exit_tree() -> void:
	if EventBus.mutation_applied.is_connected(_on_mutation_applied):
		EventBus.mutation_applied.disconnect(_on_mutation_applied)
	if _combo:
		if _combo.combo_changed.is_connected(_on_combo_changed):
			_combo.combo_changed.disconnect(_on_combo_changed)
		if _combo.combo_full.is_connected(_on_combo_full):
			_combo.combo_full.disconnect(_on_combo_full)
		if _combo.combo_broken.is_connected(_on_combo_broken):
			_combo.combo_broken.disconnect(_on_combo_broken)

func _on_mutation_applied(mutation_id: String) -> void:
	var data = MutationManager.get_mutation_data(mutation_id)
	if data.is_empty():
		push_error("[Player] _on_mutation_applied: empty data for mutation_id=" + mutation_id)
		return
	var applied = _apply_mutation_mod(data)
	_mutation_bonuses.append({"stat": data.get("stat", ""), "val": applied, "mod_type": data.get("mod_type", StatsResource.ModType.FLAT)})
	var extra = data.get("extra_mod", {})
	if not extra.is_empty():
		var extra_applied = _apply_mutation_mod(extra)
		_mutation_bonuses.append({"stat": extra.get("stat", ""), "val": extra_applied, "mod_type": extra.get("mod_type", StatsResource.ModType.FLAT)})
	refresh_from_stats()
	_log("MUTATION_APPLIED " + mutation_id + " stat=" + str(data.get("stat", "")) + " val=" + str(data.get("val", 0)))

func _apply_mutation_mod(data: Dictionary) -> float:
	var stat = data.get("stat", "")
	var val = data.get("val", 0.0) / 5.0
	var mod_type = data.get("mod_type", StatsResource.ModType.FLAT)
	stats.add_modifier_raw(stat, val, mod_type, "mutation")
	return val

func _reapply_mutation_bonuses() -> void:
	for bonus in _mutation_bonuses:
		stats.add_modifier_raw(bonus.stat, bonus.val, bonus.mod_type, "mutation")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge"):
		var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		_dodge.try_dodge(dir)
		get_viewport().set_input_as_handled()

func _on_health_changed(current: int, max_hp: int) -> void:
	pass

var _used_second_chance: bool = false

func _on_died() -> void:
	if MetaManager.has_second_chance() and not _used_second_chance:
		_used_second_chance = true
		var hp_pct = MetaManager.get_second_chance_hp()
		health.hp = maxi(1, ceili(health.max_hp * hp_pct / 100.0))
		_hurtbox.set_invulnerable(2.0)
		modulate = Color.WHITE
		EffectManager.evolution(global_position)
		return
	EventBus.player_died.emit()

func reset_second_chance() -> void:
	_used_second_chance = false

func _log(msg: String) -> void:
	print_rich("[color=gray][DEBUG] " + msg + "[/color]")

func refresh_from_stats() -> void:
	health.max_hp = maxi(ceili(stats.get_stat("max_hp")), 1)
	health.hp = mini(health.hp, health.max_hp)
	movement.speed = stats.get_stat("speed")
	weapon.fire_cooldown = stats.get_stat("fire_cooldown")
	_hurtbox.armor = maxi(0, ceili(stats.get_stat("armor")))
	_dodge.recharge_time = maxf(stats.get_stat("dodge_cooldown", 5.0), 1.0)
	_dodge.max_charges = maxi(ceili(stats.get_stat("dodge_charges", 1.0)), 1)
	_dodge.charges = mini(_dodge.charges, _dodge.max_charges)
	var stat_cd = stats.get_stat("fire_cooldown")
	var base_cd = stats.get_base("fire_cooldown", stat_cd)
	var ratio = stat_cd / base_cd if base_cd > 0 else 1.0
	_log("REFRESH_STATS stat_cd=" + str(stat_cd) + " base_cd=" + str(base_cd) + " ratio=" + str(ratio) + " timers=" + str(weapon._timers.size()))
	for i in weapon._timers.size():
		var t = weapon._timers[i]
		var tb = weapon._timer_base_cooldowns[i] if i < weapon._timer_base_cooldowns.size() else stat_cd
		t.wait_time = maxf(tb * ratio, 0.1)
		var bid = weapon.behavior_ids[i] if i < weapon.behavior_ids.size() else ""
		if bid != "" and _timer_cooldown_overrides.has(bid):
			t.wait_time = _timer_cooldown_overrides[bid]

func apply_form(form_data: Dictionary, effect: bool = false) -> void:
	var form_stats = form_data.get("stats", {})
	for stat in form_stats:
		stats.set_base(stat, form_stats[stat])

	health.max_hp = ceili(stats.get_stat("max_hp"))
	health.hp = health.max_hp
	movement.speed = stats.get_stat("speed")
	weapon.fire_cooldown = stats.get_stat("fire_cooldown")
	_log("APPLY_FORM fire_cooldown=" + str(weapon.fire_cooldown) + " form_id=" + form_data.get("id", "?"))
	_hurtbox.armor = maxi(0, ceili(stats.get_stat("armor")))
	_dodge.recharge_time = maxf(stats.get_stat("dodge_cooldown", 5.0), 1.0)
	_dodge.max_charges = maxi(ceili(stats.get_stat("dodge_charges", 1.0)), 1)
	_dodge.charges = mini(_dodge.charges, _dodge.max_charges)

	weapon.clear_behaviors()
	_timer_cooldown_overrides.clear()
	stats.remove_modifiers_from("part")
	stats.remove_modifiers_from("part_unique")
	var weapon_id = form_data.get("weapon", "aimed_shot")
	var behavior_script = _weapon_map.get(weapon_id, AimedShotScript)
	weapon.add_behavior(behavior_script.new(), weapon_id)

	var parts_arr: Array = form_data.get("parts", [])
	_visual.apply_parts(parts_arr)
	for pcfg in parts_arr:
		if pcfg.get("weapon_behavior_id") and not pcfg.weapon_behavior_id.is_empty():
			var ws = _weapon_map.get(pcfg.weapon_behavior_id)
			if ws:
				weapon.add_behavior(ws.new(), pcfg.weapon_behavior_id)
		if pcfg.get("stat_mods") and not pcfg.stat_mods.is_empty():
			for sm in pcfg.stat_mods:
				var sm_stat = sm.get("stat", "")
				var sm_val = sm.get("val", 0.0)
				var sm_type = sm.get("type", StatsResource.ModType.FLAT)
				stats.add_modifier_raw(sm_stat, sm_val, sm_type, "part")
	refresh_from_stats()

	var form_id = form_data.get("id", "")
	var tex = _load_texture(form_id)
	if tex:
		_sprite.texture = tex

	modulate = form_data.get("color", Color.GREEN)
	var size = form_data.get("size", 1.0)
	scale = Vector2.ONE * size

	_reapply_mutation_bonuses()

	if effect:
		_animate_evolution()

func _animate_evolution() -> void:
	movement.set_process(false)
	weapon.set_process(false)

	var target_scale = scale
	var target_color = modulate

	var t1 = create_tween()
	t1.tween_property(self, "modulate", Color.WHITE, 0.08)
	t1.parallel().tween_property(self, "scale", target_scale * 0.5, 0.12).set_ease(Tween.EASE_IN)
	await t1.finished

	EffectManager.evolution(global_position)
	_spawn_evolution_ring()

	var t2 = create_tween()
	t2.tween_property(self, "scale", target_scale * 1.5, 0.15).set_ease(Tween.EASE_OUT)
	await t2.finished

	var t3 = create_tween()
	t3.set_parallel(true)
	t3.tween_property(self, "scale", target_scale, 0.15).set_ease(Tween.EASE_OUT)
	t3.tween_property(self, "modulate", target_color, 0.15)
	await t3.finished

	movement.set_process(true)
	weapon.set_process(true)

func _spawn_evolution_ring() -> void:
	var ring = Sprite2D.new()
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in 64:
		for y in 64:
			var dx = x - 31.5
			var dy = y - 31.5
			var d = sqrt(dx * dx + dy * dy)
			if d >= 28 and d < 32:
				img.set_pixel(x, y, Color.WHITE)
	ring.texture = ImageTexture.create_from_image(img)
	ring.centered = true
	ring.modulate = Color(1, 1, 1, 0.6)
	ring.scale = Vector2.ZERO
	add_child(ring)
	var t = create_tween()
	t.tween_property(ring, "scale", Vector2(3, 3), 0.4).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
	t.tween_callback(ring.queue_free)

func _load_texture(form_id: String) -> Texture2D:
	var path = "res://art/forms/" + form_id + ".png"
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path)
		if tex:
			return tex
	var img = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null
