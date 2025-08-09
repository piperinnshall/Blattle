extends Control

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://piper/scenes/menu/main_menu.tscn")

func _on_mute_pressed() -> void:
	Audio.toggle_mute()

func _on_h_slider_value_changed(value: float) -> void:
	Audio.set_volume(value)
