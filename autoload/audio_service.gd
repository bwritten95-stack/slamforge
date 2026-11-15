extends Node

const BUS_SFX := "SFX"
var _players: Array[AudioStreamPlayer] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if AudioServer.get_bus_index(BUS_SFX) < 0:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_SFX)
		AudioServer.set_bus_send(idx, "Master")
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_players.append(p)
	SettingsStore.apply()

func play_slam() -> void:
	_noise(0.08, 0.4)
	_tone(90.0, 0.12, 0.35, "down")

func play_jump() -> void:
	_tone(320.0, 0.06, 0.18, "up")

func play_land() -> void:
	_tone(160.0, 0.05, 0.2, "down")

func play_combo(n: int) -> void:
	_tone(400.0 + float(n) * 45.0, 0.07, 0.2, "up")

func play_win() -> void:
	_tone(523.0, 0.1, 0.22, "none")
	_tone(659.0, 0.1, 0.22, "none")
	_tone(784.0, 0.16, 0.28, "none")

func play_die() -> void:
	_tone(70.0, 0.28, 0.4, "down")

func play_ui() -> void:
	_tone(700.0, 0.04, 0.12, "none")

func _acquire() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

func _tone(freq: float, dur: float, vol: float, slide: String) -> void:
	var player := _acquire()
	var rate := 22050.0
	var frames := int(dur * rate)
	var data := PackedVector2Array()
	data.resize(frames)
	for i in frames:
		var t := float(i) / rate
		var env := pow(1.0 - float(i) / float(frames), 1.4)
		var f := freq
		if slide == "up":
			f = lerpf(freq, freq * 1.6, float(i) / float(frames))
		elif slide == "down":
			f = lerpf(freq, freq * 0.4, float(i) / float(frames))
		var s := sin(TAU * f * t) * vol * env
		data[i] = Vector2(s, s)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = int(rate)
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = _pcm(data)
	player.stream = stream
	player.play()

func _noise(dur: float, vol: float) -> void:
	var player := _acquire()
	var rate := 22050.0
	var frames := int(dur * rate)
	var data := PackedVector2Array()
	data.resize(frames)
	var lp := 0.0
	for i in frames:
		var env := pow(1.0 - float(i) / float(frames), 2.0)
		lp = lerpf(lp, _rng.randf_range(-1.0, 1.0), 0.4)
		var s := lp * vol * env
		data[i] = Vector2(s, s)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = int(rate)
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = _pcm(data)
	player.stream = stream
	player.play()

func _pcm(samples: PackedVector2Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 4)
	var i := 0
	for s in samples:
		var l := int(clampf(s.x, -1.0, 1.0) * 32767.0)
		var r := int(clampf(s.y, -1.0, 1.0) * 32767.0)
		bytes[i] = l & 0xFF
		bytes[i + 1] = (l >> 8) & 0xFF
		bytes[i + 2] = r & 0xFF
		bytes[i + 3] = (r >> 8) & 0xFF
		i += 4
	return bytes
