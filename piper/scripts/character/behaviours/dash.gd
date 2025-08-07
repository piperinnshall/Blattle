extends Resource
class_name Dash

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

var _is_dashing := false
var _direction := 0
var _dash_time := 0.0
var _cooldown_time := 0.0

func perform(character) -> void:
	var input_direction = character._get_movement_input()
	if _cooldown_time > 0.0 or _is_dashing or input_direction == 0.0:
		return
	
	_is_dashing = true
	_dash_time = dash_duration
	_direction = sign(input_direction)
	character.velocity.x = _direction * dash_speed

func update(character, delta: float) -> void:
	if _cooldown_time > 0.0:
		_cooldown_time = max(_cooldown_time - delta, 0.0)
	if _is_dashing:
		_dash_time -= delta
		character.velocity.x = _direction * dash_speed
		if _dash_time <= 0.0:
			_is_dashing = false
			_cooldown_time = dash_cooldown
