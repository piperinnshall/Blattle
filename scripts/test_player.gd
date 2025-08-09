extends CharacterBody2D

signal player_died(player: Node)

# Movement constants
@export var speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var jump_velocity: float = -500.0
@export var gravity: float = 880.0

# Jump system constants
@export var max_jumps: int = 1
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.2

# Dodge system constants
@export var dodge_speed: float = 900.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 1.0
@export var dodge_vertical_boost: float = -200.0

# Input buffering constants
@export var input_buffer_time: float = 0.1

# Health system constants
@export var max_health: float = 100.0

# Attack movement restrictions
const ATTACK_HORIZONTAL_SLOWDOWN: float = 0.8
const ATTACK_FRICTION_MULTIPLIER: float = 0.9
const DODGE_FRICTION_MULTIPLIER: float = 2.0
const FLOOR_COLLISION_LAYER: int = 4

# Current health
var health: float = 100.0

# Node references
@onready var attack_system: Node2D = $AttackSystem

# Jump state
var jumps_remaining: int = 0
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Dodge state
var is_dodging: bool = false
var can_dodge: bool = true
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0

# Movement state
var facing_direction: int = 1

# Collision backup for invincibility
var original_collision_layer: int
var original_collision_mask: int

# Input buffering
var input_buffer_timer: float = 0.0
var buffered_jump: bool = false
var buffered_dodge: bool = false

func _ready():
	# Initialize systems
	jumps_remaining = max_jumps
	health = max_health
	
	# Store collision settings for dodge invincibility
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	
	# Add to game groups
	add_to_group("Players")

func _physics_process(delta):
	# Process all systems in order
	handle_gravity(delta)
	handle_input_buffering(delta)
	handle_coyote_time(delta)
	handle_dodge(delta)
	
	# Only handle normal movement when not dodging
	if not is_dodging:
		handle_movement(delta)
		handle_jump()
	
	# Apply attack movement restrictions
	handle_attack_restrictions()
	
	# Execute movement and update facing
	move_and_slide()
	update_facing_direction()

func handle_attack_restrictions():
	# Slow down horizontal movement during attacks
	if attack_system.is_attacking:
		velocity.x *= ATTACK_HORIZONTAL_SLOWDOWN
		velocity.x *= ATTACK_FRICTION_MULTIPLIER

func handle_gravity(delta):
	# Apply gravity when not grounded
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_input_buffering(delta):
	# Decrease buffer timers
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if input_buffer_timer > 0:
		input_buffer_timer -= delta
	
	# Buffer jump input
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		buffered_jump = true
		jump_buffer_timer = jump_buffer_time
		input_buffer_timer = input_buffer_time
	
	# Buffer dodge input
	if Input.is_action_just_pressed("dodge"):
		buffered_dodge = true
		input_buffer_timer = input_buffer_time
	
	# Clear expired buffers
	if jump_buffer_timer <= 0:
		buffered_jump = false
	if input_buffer_timer <= 0:
		buffered_dodge = false

func handle_coyote_time(delta):
	# Reset coyote time and jumps when grounded
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_remaining = max_jumps
	else:
		# Decrease coyote time when airborne
		coyote_timer -= delta

func handle_movement(delta):
	var direction = Input.get_axis("left", "right")
	
	if direction != 0:
		# Accelerate towards target speed
		var target_velocity = direction * speed
		velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	else:
		# Apply friction when no input
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_jump():
	var can_jump = false
	
	# Check jump conditions
	if is_on_floor() or coyote_timer > 0:
		can_jump = true
	elif jumps_remaining > 0:
		can_jump = true
	
	# Execute buffered jump if possible
	if buffered_jump and can_jump:
		perform_jump()
		buffered_jump = false
		jump_buffer_timer = 0.0

func perform_jump():
	# Set upward velocity
	velocity.y = jump_velocity
	
	# Consume air jump if not grounded and past coyote time
	if not is_on_floor() and coyote_timer <= 0:
		jumps_remaining -= 1
	
	# End coyote time
	coyote_timer = 0.0

func handle_dodge(delta):
	# Update dodge cooldown
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta
	else:
		can_dodge = true
	
	# Start dodge if buffered and available
	if buffered_dodge and can_dodge and not is_dodging:
		start_dodge()
		buffered_dodge = false
	
	# Update active dodge
	if is_dodging:
		dodge_timer -= delta
		
		# Apply extra friction for control during dodge
		if abs(velocity.x) > speed:
			velocity.x = move_toward(velocity.x, sign(velocity.x) * speed, 
									friction * DODGE_FRICTION_MULTIPLIER * delta)
		
		# End dodge when timer expires
		if dodge_timer <= 0:
			end_dodge()

func start_dodge():
	# Set dodge state
	is_dodging = true
	can_dodge = false
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	
	# Apply dodge velocity
	var dodge_direction = get_dodge_direction()
	velocity.x = dodge_direction * dodge_speed
	velocity.y = dodge_vertical_boost
	
	# Enable invincibility during dodge
	enable_dash_invincibility()

func get_dodge_direction() -> int:
	# Use input direction if available, otherwise use facing direction
	var input_direction = Input.get_axis("left", "right")
	
	if input_direction != 0:
		return sign(input_direction)
	else:
		return facing_direction

func end_dodge():
	# Clear dodge state
	is_dodging = false
	
	# Remove invincibility
	disable_dash_invincibility()

func enable_dash_invincibility():
	# Store current collision settings
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	
	# Remove from enemy detection layer
	collision_layer = 0
	
	# Keep only floor collision
	collision_mask = FLOOR_COLLISION_LAYER
	
	print("Dash invincibility enabled")

func disable_dash_invincibility():
	# Restore original collision settings
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
	
	print("Dash invincibility disabled")

func update_facing_direction():
	# Update facing based on input
	var input_direction = Input.get_axis("left", "right")
	if input_direction != 0:
		facing_direction = sign(input_direction)

# Health system
func get_health() -> float:
	return health

func get_max_health() -> float:
	return max_health

func take_damage(damage: float):
	# Ignore damage if invincible
	if is_invincible():
		print("Player is invincible - damage ignored!")
		return
	
	# Apply damage
	health -= damage
	health = max(0, health)
	print("Player took ", damage, " damage. Health: ", health, "/", max_health)
	
	# Check for death
	if health <= 0:
		die()

func heal(amount: float):
	# Apply healing with max cap
	health += amount
	health = min(max_health, health)
	print("Player healed ", amount, ". Health: ", health, "/", max_health)

func die():
	# Handle player death
	print("Player died!")
	player_died.emit(self)
	set_physics_process(false)
	set_process_input(false)

# State queries
func is_jumping() -> bool:
	return velocity.y < 0

func is_falling() -> bool:
	return velocity.y > 0 and not is_on_floor()

func get_speed() -> float:
	return velocity.length()

func get_dodge_cooldown_progress() -> float:
	# Return cooldown progress (1.0 = full cooldown, 0.0 = ready)
	if dodge_cooldown_timer > 0:
		return dodge_cooldown_timer / dodge_cooldown
	else:
		return 0.0

func is_attacking() -> bool:
	return attack_system.is_attacking if attack_system else false

func can_attack() -> bool:
	return attack_system.is_attack_ready() if attack_system else false

func is_invincible() -> bool:
	# Currently only invincible during dodge
	return is_dodging

# Debug output
func _on_debug_info():
	print("=== Player Debug Info ===")
	print("Health: ", health, "/", max_health)
	print("Jumps remaining: ", jumps_remaining)
	print("Coyote time: ", coyote_timer)
	print("Is dodging: ", is_dodging)
	print("Can dodge: ", can_dodge)
	print("Buffered jump: ", buffered_jump)
	print("Buffered dodge: ", buffered_dodge)
	print("Is invincible: ", is_invincible())
	print("Collision layer: ", collision_layer)
	print("Collision mask: ", collision_mask)
	print("=========================")
