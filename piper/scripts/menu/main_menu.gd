extends Control

func _ready() -> void:
	var music_stream = load("res://piper/scenes/menu/trending-vlogs-background-music-384737.mp3")
	Audio.play_music(music_stream)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://leos/scenes/testlevel.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://piper/scenes/menu/options_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
