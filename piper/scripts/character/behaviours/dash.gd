extends Resource
class_name Dash

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

var _is_dashing := false
var _last_direction := 1
var _dash_time := 0.0
var _cooldown_time := 0.0

func is_busy() -> bool:
	return _is_dashing or _cooldown_time > 0.0

func perform(character) -> void:
	if _cooldown_time > 0.0 or _is_dashing:
		return
	
	_is_dashing = true
	_dash_time = dash_duration
	character.velocity.x = _last_direction * dash_speed

func update(character, delta: float) -> void:
	var input_direction = character.get_movement_input()
	if input_direction != 0:
		_last_direction = sign(input_direction)
	
	if _cooldown_time > 0.0:
		_cooldown_time = max(_cooldown_time - delta, 0.0)
	
	if _is_dashing:
		_dash_time -= delta
		character.velocity.x = _last_direction * dash_speed
		
		if _dash_time <= 0.0:
			_is_dashing = false
			_cooldown_time = dash_cooldown
