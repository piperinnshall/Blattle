extends Character

@export_group("Input")
@export var input_left: String = "left"
@export var input_right: String = "right"
@export var input_jump: String = "up"
@export var input_dash: String = "dash"
@export var input_light: String = "light"
@export var input_heavy: String = "heavy"

func _get_movement_input() -> float:
	return Input.get_axis(input_left, input_right)

func _get_jump_input() -> bool:
	return Input.is_action_just_pressed(input_jump)

func _get_dash_input() -> bool:
	return Input.is_action_just_pressed(input_dash)

func _get_light_input() -> bool:
	return Input.is_action_just_pressed(input_light)

func _get_heavy_input() -> bool:
	return Input.is_action_just_pressed(input_heavy)
