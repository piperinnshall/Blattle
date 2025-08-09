extends CharacterBody2D
class_name Character

# Add the player_died signal
signal player_died(player: Node)

# --- Exported Variables ---

@export_group("Behaviours")
@export var jump: Jump
@export var dash: Dash
@export var attack: Attack

@export_group("Movement")
@export var speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 1200.0
@export var gravity: float = 800.0
@export var buffer_time: float = 0.1

@export_group("Health")
@export var max_health: float = 100.0

# --- State ---

var _health := 100.0
var input_buffer := {}

# --- Built-in ---

func _ready():
	# Initialize health
	_health = max_health
	
	# Add to Players group for GameManager detection
	add_to_group("Players")
	
	print("Character ", name, " initialized with health: ", _health)

func _physics_process(delta):
	handle_movement(delta)
	handle_behaviour(delta, jump, "jump", get_jump_input())
	handle_behaviour(delta, dash, "dash", get_dash_input())
	handle_behaviour(delta, attack, "light", get_light_input())
	handle_behaviour(delta, attack, "heavy", get_heavy_input())
	
	update_input_buffer(delta)
	
	move_and_slide()

# --- Abstract ---

func get_movement_input() -> float:  return 0
func get_jump_input() -> bool:  return false
func get_dash_input() -> bool: return false
func get_light_input() -> bool: return false
func get_heavy_input() -> bool: return false

# --- Health System ---
func get_health() -> float:
	return _health

func get_max_health() -> float:
	return max_health

func take_damage(damage: float):
	_health -= damage
	_health = max(0, _health)
	print("Player ", name, " took ", damage, " damage. Health: ", _health, "/", max_health)
	
	if _health <= 0:
		die()

func heal(amount: float):
	_health += amount
	_health = min(max_health, _health)
	print("Player ", name, " healed ", amount, ". Health: ", _health, "/", max_health)

func die():
	print("Player ", name, " died!")
	player_died.emit(self)
	set_physics_process(false)
	set_process_input(false)

# Keep the old method name for compatibility
func apply_damage(damage: float): 
	take_damage(damage)

# --- Movement ---

func handle_movement(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	var input_dir = get_movement_input()
	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

# --- Behaviours ---
func handle_behaviour(delta, behaviour, behaviour_str, input):
	behaviour.update(self, delta)
	if input and not behaviour.is_busy():
		buffer_input(behaviour_str)
	if input_buffer.has(behaviour_str):
		behaviour.perform(self)
		input_buffer.erase(behaviour_str)

# --- Input Buffer ---
func buffer_input(action: String):
	input_buffer[action] = buffer_time

func update_input_buffer(delta: float):
	var to_remove := []
	for action in input_buffer.keys():
		input_buffer[action] -= delta
		if input_buffer[action] <= 0:
			to_remove.append(action)
	for action in to_remove:
		input_buffer.erase(action)

# --- State Queries ---
func is_jumping() -> bool:
	return velocity.y < 0

func is_falling() -> bool:
	return velocity.y > 0 and not is_on_floor()

func get_speed() -> float:
	return velocity.length()
