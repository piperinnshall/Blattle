extends CharacterBody2D
class_name Character

# --- Exported Variables ---

@export_group("Behaviours")
@export var jump: Jump
@export var dash: Dash

@export_group("Movement")
@export var speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 1200.0
@export var gravity: float = 800.0
@export var buffer_time: float = 0.1

# --- State ---

var _health := 0
var _input_buffer := {}

# --- Built-in ---

func _physics_process(delta):
	_handle_movement(delta)
	_handle_behaviour(delta, jump, "jump", _get_jump_input())
	_handle_behaviour(delta, dash, "dash", _get_dash_input())
	_update_input_buffer(delta)
	
	move_and_slide()

# --- Abstract ---

func _get_movement_input() -> float:  return 0
func _get_jump_input() -> bool:  return false
func _get_dash_input() -> bool: return false
func _get_light_attack_input() -> bool: return false
func _get_heavy_attack_input() -> bool: return false

# --- Attack ---

func _apply_damage(damage): 
	_health += damage

# --- Movement ---

func _handle_movement(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	var input_dir = _get_movement_input()
	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

# --- Behaviours ---

func _handle_behaviour(delta, behaviour, behaviour_str, input):
	behaviour.update(self, delta)
	if input:
		_buffer_input(behaviour_str, behaviour)
	if _input_buffer.has(behaviour_str):
		behaviour.perform(self)
		_input_buffer.erase(name)

# --- Input Buffer ---

func _buffer_input(action: String, behaviour):
	_input_buffer[action] = buffer_time

func _update_input_buffer(delta: float):
	var to_remove := []
	for action in _input_buffer.keys():
		_input_buffer[action] -= delta
		if _input_buffer[action] <= 0:
			to_remove.append(action)
	for action in to_remove:
		_input_buffer.erase(action)
