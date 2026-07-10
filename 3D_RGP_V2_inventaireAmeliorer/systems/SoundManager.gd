## Lightweight procedural SFX: synthesizes short tones at runtime (no audio assets needed).
extends Node

const POOL_SIZE := 8
const SAMPLE_RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}
var _next: int = 0


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	# freq, duration, volume, waveform
	_sounds["hit"] = _make_tone(200.0, 0.10, 0.45, "square")
	_sounds["skill"] = _make_tone(640.0, 0.18, 0.40, "sine")
	_sounds["death"] = _make_tone(130.0, 0.28, 0.45, "saw")
	_sounds["pickup"] = _make_tone(880.0, 0.12, 0.35, "sine")
	_sounds["portal"] = _make_tone(420.0, 0.40, 0.40, "sine")
	_sounds["level"] = _make_tone(740.0, 0.30, 0.40, "sine")
	_sounds["shoot"] = _make_tone(320.0, 0.07, 0.45, "square")
	_sounds["staff"] = _make_tone(520.0, 0.14, 0.40, "sine")
	_sounds["buy"] = _make_tone(990.0, 0.15, 0.35, "sine")
	_sounds["deny"] = _make_tone(160.0, 0.15, 0.35, "square")


func play(sound_name: String) -> void:
	if not _sounds.has(sound_name) or _players.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[sound_name]
	p.play()


func _make_tone(freq: float, duration: float, volume: float, wave: String) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := 1.0 - (float(i) / float(count))  # linear decay envelope
		var phase := fmod(t * freq, 1.0)
		var s := 0.0
		match wave:
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"saw":
				s = phase * 2.0 - 1.0
			_:
				s = sin(t * freq * TAU)
		var v := int(clampf(s * env * volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav
