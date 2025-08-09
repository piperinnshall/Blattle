extends Control

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://piper/scenes/menu/main_menu.tscn")

func _on_mute_pressed() -> void:
	pass # Replace with function body.

func _on_h_slider_value_changed(value: float) -> void:
	pass # Replace with function body.
