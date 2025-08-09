extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://leos/scenes/testlevel.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://piper/scenes/menu/options_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
