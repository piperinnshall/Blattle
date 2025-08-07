extends Character

@export_group("Input")
@export var input_left: String = "ui_left"
@export var input_right: String = "ui_right"
@export var input_jump: String = "ui_up"
@export var input_dash: String = "ui_accept"

func _get_movement_input() -> float:
	return Input.get_axis(input_left, input_right)

func _get_jump_input() -> bool:
	return Input.is_action_just_pressed(input_jump)

func _get_dash_input() -> bool:
	return Input.is_action_just_pressed(input_dash)
