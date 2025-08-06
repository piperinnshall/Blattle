extends CharacterBody2D
class_name Character

# --- Exported Variables ---

@export_group("Properties")
@export var speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 1200.0

@export_subgroup("Jump")
@export var gravity: float = 800.0
@export var jump_force: float = 400.0
@export var max_jumps: int = 2
@export var jump_buffer_time: float = 0.1
@export var coyote_time: float = 0.1

# --- State ---

var _jumps_left := 0
var _input_buffer := {}
var _coyote_timer := 0.0

# --- Built-in ---

func _physics_process(delta):
	var was_on_floor = is_on_floor()
	
	_apply_gravity(delta)
	_handle_movement_input(delta)
	_handle_jump_input()
	_update_input_buffer(delta)
	_update_coyote_timer(delta)
	
	move_and_slide()
	
	if is_on_floor():
		_jumps_left = max_jumps
		_coyote_timer = coyote_time
	elif was_on_floor and _coyote_timer > 0:
		_jumps_left = max(0, max_jumps - 1)

# --- Abstract ---

func _get_movement_input() -> float: 
	return 0

func _get_jump_input() -> bool: 
	return false

# --- Movement ---

func _apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta

func _handle_movement_input(delta: float):
	var input_dir = _get_movement_input()
	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _handle_jump_input():
	if _get_jump_input(): 
		_buffer_input("jump")
	
	if _input_buffer.has("jump") and _can_jump():
		_perform_jump()
		_input_buffer.erase("jump")

func _can_jump() -> bool:
	return _jumps_left > 0 or _coyote_timer > 0.0
	
func _perform_jump():
	velocity.y = -jump_force
	if _coyote_timer > 0.0:
		_jumps_left = max_jumps - 1
	else:
		_jumps_left -= 1
	_coyote_timer = 0.0

# --- Input Buffer ---

func _buffer_input(action: String):
	_input_buffer[action] = jump_buffer_time

func _update_input_buffer(delta: float):
	var to_remove := []
	for action in _input_buffer.keys():
		_input_buffer[action] -= delta
		if _input_buffer[action] <= 0:
			to_remove.append(action)
	for action in to_remove:
		_input_buffer.erase(action)

# --- Coyote Time ---

func _update_coyote_timer(delta: float):
	if not is_on_floor():
		_coyote_timer = max(_coyote_timer - delta, 0.0)
