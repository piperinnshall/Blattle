extends Node

var music_player: AudioStreamPlayer
var is_muted := false
var last_volume_db := 0.0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"  # Or your music bus
	music_player.autoplay = false
	music_player.stream_paused = false
	add_child(music_player)

func play_music(music_stream: AudioStream) -> void:
	if music_stream:
		# Enable looping on the AudioStream resource
		music_stream.loop = true
		music_player.stream = music_stream
		music_player.play()

func toggle_mute() -> void:
	is_muted = !is_muted
	var master_bus = AudioServer.get_bus_index("Master")
	if is_muted:
		last_volume_db = AudioServer.get_bus_volume_db(master_bus)
		AudioServer.set_bus_volume_db(master_bus, -80)  # Mute (silence)
	else:
		AudioServer.set_bus_volume_db(master_bus, last_volume_db)

func set_volume(value: float) -> void:
	var db = linear_to_db(value)
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, db)
	if not is_muted:
		last_volume_db = db
