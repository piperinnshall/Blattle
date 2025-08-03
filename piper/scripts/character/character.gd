extends CharacterBody2D
class_name Character

@export_group("Properties")
@export var speed: float = 200.0

@export_subgroup("Jump")
@export var gravity: float = 800.0
@export var jump_force: float = 400.0
@export var max_jumps: int = 2
@export var jump_buffer_time: float = 0.1

# --- State ---

var _buffered_jump: bool = false
var _jumps_left: int
var _jump_buffer_timer: float = 0.0
var input_dir: int = 0

# --- Builtin ---

func _ready():
	_jumps_left = max_jumps

func _physics_process(delta):
	_update_jump_buffer(delta)
	_apply_gravity(delta)
	_process_jump()
	_handle_movement(delta)
	_update_state()
	
	move_and_slide()

# --- Abstract ---

func _handle_movement(_delta):
	pass

# --- Default ---

func buffer_jump():
	_buffered_jump = true
	_jump_buffer_timer = jump_buffer_time

func _update_jump_buffer(delta):
	if _buffered_jump:
		_jump_buffer_timer -= delta
		if _jump_buffer_timer <= 0.0:
			_buffered_jump = false

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

func _process_jump():
	if _buffered_jump:
		if _jumps_left > 0:
			_do_jump()
			_buffered_jump = false

func _do_jump():
	velocity.y = -jump_force
	_jumps_left -= 1

func _update_state():
	if is_on_floor():
		_jumps_left = max_jumps
