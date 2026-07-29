extends Node

const SAMPLE_RATE := 22050


func _ready() -> void:
	var ambient := AudioStreamPlayer.new()
	ambient.name = "Ambient"
	ambient.stream = _make_ambient_stream()
	ambient.volume_db = -24.0
	add_child(ambient)
	ambient.play()


func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null


func play_sound(kind: StringName) -> void:
	match kind:
		&"jump":
			_play_tone(220.0, 0.13, -13.0, 0.32)
		&"special_jump":
			_play_tone(330.0, 0.28, -8.0, 0.6)
		&"wall_jump":
			_play_tone(270.0, 0.18, -10.0, 0.45)
		&"slide":
			_play_tone(92.0, 0.22, -16.0, 0.85)
		&"skid":
			_play_tone(118.0, 0.16, -14.0, 0.95)
		&"collect":
			_play_tone(660.0, 0.24, -7.0, 0.2)
		&"hurt":
			_play_tone(72.0, 0.32, -8.0, 1.0)


func _play_tone(
	frequency: float,
	duration: float,
	volume_db: float,
	roughness: float
) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = _make_tone_stream(frequency, duration, roughness)
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(_on_one_shot_finished.bind(player))
	player.play()


func _on_one_shot_finished(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null
	player.queue_free()


func _make_tone_stream(
	frequency: float,
	duration: float,
	roughness: float
) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var time := float(index) / SAMPLE_RATE
		var progress := float(index) / sample_count
		var envelope := minf(progress * 14.0, 1.0)
		envelope *= pow(1.0 - progress, 1.8)
		var sweep := frequency * lerpf(1.08, 0.82, progress * roughness)
		var sample := sin(TAU * sweep * time)
		sample += sin(TAU * sweep * 2.03 * time) * roughness * 0.28
		var value := int(clampf(sample * envelope * 0.58, -1.0, 1.0) * 32767.0)
		data.encode_s16(index * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _make_ambient_stream() -> AudioStreamWAV:
	var duration := 4.0
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var time := float(index) / SAMPLE_RATE
		var fade := minf(time * 1.5, 1.0)
		fade *= minf((duration - time) * 1.5, 1.0)
		var sample := sin(TAU * 55.0 * time) * 0.34
		sample += sin(TAU * 82.5 * time) * 0.19
		sample += sin(TAU * 110.0 * time) * 0.1
		sample *= 0.55 + sin(TAU * 0.18 * time) * 0.12
		var value := int(clampf(sample * fade, -1.0, 1.0) * 32767.0)
		data.encode_s16(index * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = data
	return stream
