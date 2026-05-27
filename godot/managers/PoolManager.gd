extends Node

const BulletScript = preload("res://entities/projectiles/Bullet.gd")
const EnemyScript = preload("res://entities/enemies/Enemy.gd")
const GeneticOrbScript = preload("res://entities/pickups/GeneticOrb.gd")

var _bullet_pool: Array[Bullet] = []
var _enemy_pool: Array[Enemy] = []
var _orb_pool: Array[GeneticOrb] = []

func _ready() -> void:
	for i in range(30):
		var b = BulletScript.new()
		b._pool_reset()
		_bullet_pool.append(b)
	for i in range(10):
		var e = EnemyScript.new()
		e._pool_reset()
		_enemy_pool.append(e)
	for i in range(20):
		var o = GeneticOrbScript.new()
		o._pool_reset()
		_orb_pool.append(o)

func clear() -> void:
	_clear_pool(_bullet_pool)
	_clear_pool(_enemy_pool)
	_clear_pool(_orb_pool)

func _clear_pool(pool: Array) -> void:
	for obj in pool:
		if is_instance_valid(obj):
			if obj.get_parent():
				obj.get_parent().remove_child(obj)
			obj.free()
	pool.clear()

func get_bullet() -> Bullet:
	var b: Bullet
	if _bullet_pool.size() > 0:
		b = _bullet_pool.pop_back()
		if b.get_parent():
			b.get_parent().remove_child(b)
	else:
		b = BulletScript.new()
	b._pool_init()
	return b

func release_bullet(b: Bullet) -> void:
	b._pool_reset()
	if _bullet_pool.size() < 60:
		_bullet_pool.append(b)
	else:
		if b.get_parent():
			b.get_parent().remove_child(b)
		b.free()

func get_enemy() -> Enemy:
	var e: Enemy
	if _enemy_pool.size() > 0:
		e = _enemy_pool.pop_back()
		if e.get_parent():
			e.get_parent().remove_child(e)
	else:
		e = EnemyScript.new()
	e._pool_init()
	return e

func release_enemy(e: Enemy) -> void:
	e._pool_reset()
	if _enemy_pool.size() < 20:
		_enemy_pool.append(e)
	else:
		if e.get_parent():
			e.get_parent().remove_child(e)
		e.free()

func get_orb() -> GeneticOrb:
	var o: GeneticOrb
	if _orb_pool.size() > 0:
		o = _orb_pool.pop_back()
		if o.get_parent():
			o.get_parent().remove_child(o)
	else:
		o = GeneticOrbScript.new()
	o._pool_init()
	return o

func release_orb(o: GeneticOrb) -> void:
	o._pool_reset()
	if _orb_pool.size() < 40:
		_orb_pool.append(o)
	else:
		if o.get_parent():
			o.get_parent().remove_child(o)
		o.free()
