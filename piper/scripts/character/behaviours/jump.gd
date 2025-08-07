extends Resource
class_name Jump

@export var jump_force: float = 400.0
@export var max_jumps: int = 2
@export var coyote_time: float = 0.1

var _jumps_left := 0
var _coyote_timer := 0.0

func perform(character):
	if _jumps_left > 0 or _coyote_timer > 0.0:
		return
	
	character.velocity.y = -jump_force
	if _coyote_timer > 0.0:
		_jumps_left = max_jumps - 1
	else:
		_jumps_left -= 1
	_coyote_timer = 0.0

func update(character, delta):
	if character.is_on_floor():
		_jumps_left = max_jumps
		_coyote_timer = coyote_time
	elif _coyote_timer > 0.0:
		_coyote_timer = max(_coyote_timer - delta, 0.0)
