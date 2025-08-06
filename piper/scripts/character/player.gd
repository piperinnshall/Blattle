extends Character

func _get_movement_input() -> float:
	return Input.get_axis("ui_left", "ui_right")

func _get_jump_input() -> bool:
	return Input.is_action_just_pressed("ui_up")
