extends Node

var music_player: AudioStreamPlayer
var is_muted := false
var last_volume_db := 0.0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.autoplay = false
	add_child(music_player)
	
	var master_bus = AudioServer.get_bus_index("Music")
	last_volume_db = AudioServer.get_bus_volume_db(master_bus)

func play_music(music_stream: AudioStream) -> void:
	if music_stream:
		if "loop" in music_stream:
			music_stream.loop = true
		music_player.stream = music_stream
		music_player.play()

func toggle_mute() -> void:
	is_muted = !is_muted
	var master_bus = AudioServer.get_bus_index("Music")
	if is_muted:
		last_volume_db = AudioServer.get_bus_volume_db(master_bus)
		AudioServer.set_bus_volume_db(master_bus, -80)
	else:
		AudioServer.set_bus_volume_db(master_bus, last_volume_db)

func set_volume(value: float) -> void:
	var normalized_value = clamp(value / 100.0, 0.0, 1.0)
	var db = linear_to_db(normalized_value)
	var master_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(master_bus, db)
	if not is_muted:
		last_volume_db = db
