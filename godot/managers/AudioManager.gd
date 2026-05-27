extends Node

const RATE: int = 22050

var _sfx_players: Array[AudioStreamPlayer2D]
var _bgm_player: AudioStreamPlayer
var _sfx_volume: float = 0.8
var _bgm_volume: float = 0.4
var _bus_index: int

var _sfx_library: Dictionary = {}
var _bgm_stream: AudioStreamWAV

func _ready() -> void:
	_bus_index = AudioServer.get_bus_count()
	_build_library()
	_setup_players()
	_connect_events()
	_setup_bgm()

func _build_library() -> void:
	_sfx_library = {
		"shoot": _gen_burst(800, 0.08, 0.5),
		"hit": _gen_noise(0.06, 0.3),
		"explosion": _gen_sweep(200, 60, 0.25, 0.6),
		"death": _gen_burst(400, 0.12, 0.4),
		"collect": _gen_chime(880, 0.1, 0.5),
		"evolution": _gen_sweep(300, 900, 0.4, 0.7),
		"player_hurt": _gen_sweep(150, 80, 0.12, 0.5),
		"game_over": _gen_sweep(400, 50, 0.8, 0.6),
		"click": _gen_burst(1000, 0.04, 0.3),
		"swing": _gen_sweep(300, 120, 0.08, 0.4),
	}
	_bgm_stream = _gen_drone(0.5)

func _setup_players() -> void:
	for i in 8:
		var p = AudioStreamPlayer2D.new()
		p.name = "SFX_%d" % i
		p.max_distance = 1200
		p.volume_db = linear_to_db(_sfx_volume)
		add_child(p)
		_sfx_players.append(p)

func _connect_events() -> void:
	EventBus.enemy_died.connect(func(_enemy, pos, _gp):
		play_sfx("death", pos))
	EventBus.gp_collected.connect(func(_amt):
		play_sfx("collect"))
	EventBus.player_damaged.connect(func(_chp, _mhp):
		play_sfx("player_hurt"))
	EventBus.player_died.connect(func():
		play_sfx("game_over"))
	EventBus.evolution_chosen.connect(func(_id):
		play_sfx("evolution"))
	EventBus.game_over.connect(func():
		play_sfx("game_over"))

func _setup_bgm() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGM"
	_bgm_player.stream = _gen_bgm()
	_bgm_player.volume_db = linear_to_db(_bgm_volume)
	_bgm_player.autoplay = false
	add_child(_bgm_player)

func play_sfx(sfx_id: String, position: Vector2 = Vector2.ZERO) -> void:
	var stream = _sfx_library.get(sfx_id)
	if not stream:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.global_position = position
			p.play()
			return

func play_bgm() -> void:
	if _bgm_player and not _bgm_player.playing:
		_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player:
		_bgm_player.stop()

func set_sfx_volume(v: float) -> void:
	_sfx_volume = clampf(v, 0, 1)
	for p in _sfx_players:
		p.volume_db = linear_to_db(_sfx_volume)

func set_bgm_volume(v: float) -> void:
	_bgm_volume = clampf(v, 0, 1)
	if _bgm_player:
		_bgm_player.volume_db = linear_to_db(_bgm_volume)

# --- Procedural audio generation ---

static func _make_stream(data: PackedByteArray, stereo: bool = false) -> AudioStreamWAV:
	var s = AudioStreamWAV.new()
	s.data = data
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = stereo
	return s

static func _gen_sine(freq: float, dur: float, vol: float = 0.5) -> PackedByteArray:
	var n = ceili(RATE * dur)
	var out := PackedByteArray()
	out.resize(n * 2)
	for i in n:
		var v = sin(2 * PI * freq * i / RATE) * vol * 32767
		var s = roundi(clampi(int(v), -32768, 32767))
		out.encode_s16(i * 2, s)
	return out

static func _gen_sweep(f_start: float, f_end: float, dur: float, vol: float = 0.5) -> AudioStreamWAV:
	var n = ceili(RATE * dur)
	var out := PackedByteArray()
	out.resize(n * 2)
	for i in n:
		var t = float(i) / n
		var f = lerp(f_start, f_end, t)
		var v = sin(2 * PI * f * i / RATE) * vol * 32767
		var s = roundi(clampi(int(v), -32768, 32767))
		out.encode_s16(i * 2, s)
	return _make_stream(out)

static func _gen_noise(dur: float, vol: float = 0.5) -> AudioStreamWAV:
	var n = ceili(RATE * dur)
	var out := PackedByteArray()
	out.resize(n * 2)
	var env = 1.0
	for i in n:
		env = maxf(0, env - 1.0 / n)
		var v = randf_range(-1, 1) * vol * env * 32767
		var s = roundi(clampi(int(v), -32768, 32767))
		out.encode_s16(i * 2, s)
	return _make_stream(out)

static func _gen_burst(freq: float, dur: float, vol: float = 0.5) -> AudioStreamWAV:
	return _make_stream(_gen_sine(freq, dur, vol))

static func _gen_chime(freq: float, dur: float, vol: float = 0.5) -> AudioStreamWAV:
	var n = ceili(RATE * dur)
	var out := PackedByteArray()
	out.resize(n * 2)
	for i in n:
		var t = float(i) / n
		var env = exp(-t * 8)
		var v = sin(2 * PI * freq * i / RATE) * vol * env * 32767
		var s = roundi(clampi(int(v), -32768, 32767))
		out.encode_s16(i * 2, s)
	return _make_stream(out)

static func _gen_drone(vol: float = 0.3) -> AudioStreamWAV:
	var dur = 4.0
	var n = ceili(RATE * dur)
	var out := PackedByteArray()
	out.resize(n * 2)
	for i in n:
		var v = 0.0
		v += sin(2 * PI * 55 * i / RATE) * 0.4
		v += sin(2 * PI * 82.5 * i / RATE) * 0.25
		v += sin(2 * PI * 110 * i / RATE) * 0.2
		v *= vol * 32767
		var s = roundi(clampi(int(v), -32768, 32767))
		out.encode_s16(i * 2, s)
	return _make_stream(out)

static func _gen_bgm() -> AudioStreamWAV:
	var dur = 8.0
	var n = ceili(RATE * dur)
	var out := PackedByteArray()
	out.resize(n * 2)
	for i in n:
		var t = float(i) / n
		var v = 0.0
		v += sin(2 * PI * 60 * i / RATE) * 0.3
		v += sin(2 * PI * 90 * i / RATE) * 0.2
		v += sin(2 * PI * 120 * i / RATE) * 0.15 * sin(PI * t)
		v += sin(2 * PI * 180 * i / RATE) * 0.08 * (1 + sin(2 * PI * 0.5 * t))
		v *= 0.25 * 32767
		var s = roundi(clampi(int(v), -32768, 32767))
		out.encode_s16(i * 2, s)
	return _make_stream(out)
