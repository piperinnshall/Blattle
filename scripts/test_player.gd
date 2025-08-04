extends CharacterBody2D

# Movement parameters
@export var speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

# Jump system
@export var max_jumps: int = 2
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.2

# Dodge roll
@export var dodge_speed: float = 600.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 1.0

# Input buffering
@export var input_buffer_time: float = 0.1

# Health system
@export var max_health: float = 100.0
var health: float = 100.0

@onready var attack_system: Node2D = $AttackSystem

# State variables
var jumps_remaining: int = 0
var is_dodging: bool = false
var can_dodge: bool = true
var facing_direction: int = 1

# Invincibility during dash
var original_collision_layer: int
var original_collision_mask: int

# Timers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var input_buffer_timer: float = 0.0

# Input buffer
var buffered_jump: bool = false
var buffered_dodge: bool = false

func _ready():
	jumps_remaining = max_jumps
	health = max_health
	# Store original collision settings
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	
	# Add to Players group
	add_to_group("Players")

func _physics_process(delta):
	handle_gravity(delta)
	handle_input_buffering(delta)
	handle_coyote_time(delta)
	handle_dodge(delta)
	
	if not is_dodging:
		handle_movement(delta)
		handle_jump()
	
	handle_attack_restrictions()
	move_and_slide()
	update_facing_direction()

func handle_attack_restrictions():
	if attack_system.is_attacking:
		velocity.x *= 0.8
		velocity.x *= 0.9

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_input_buffering(delta):
	# Update timers
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if input_buffer_timer > 0:
		input_buffer_timer -= delta
	
	# Check for jump input
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		buffered_jump = true
		jump_buffer_timer = jump_buffer_time
		input_buffer_timer = input_buffer_time
	
	# Check for dodge input
	if Input.is_action_just_pressed("dodge"):
		buffered_dodge = true
		input_buffer_timer = input_buffer_time
	
	# Clear buffers when timers expire
	if jump_buffer_timer <= 0:
		buffered_jump = false
	if input_buffer_timer <= 0:
		buffered_dodge = false

func handle_coyote_time(delta):
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_remaining = max_jumps
	else:
		coyote_timer -= delta

func handle_movement(delta):
	var direction = Input.get_axis("left","right")
	
	if direction != 0:
		# Accelerate towards target speed
		var target_velocity = direction * speed
		velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
	else:
		# Apply friction
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_jump():
	var can_jump = false
	
	# Check if we can jump (on ground, coyote time, or have air jumps)
	if is_on_floor() or coyote_timer > 0:
		can_jump = true
	elif jumps_remaining > 0:
		can_jump = true
	
	# Execute jump if buffered and possible
	if buffered_jump and can_jump:
		perform_jump()
		buffered_jump = false
		jump_buffer_timer = 0.0

func perform_jump():
	velocity.y = jump_velocity
	
	# Consume jump
	if not is_on_floor() and coyote_timer <= 0:
		jumps_remaining -= 1
	
	# Reset coyote time after jumping
	coyote_timer = 0.0

func handle_dodge(delta):
	# Update dodge cooldown
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta
	else:
		can_dodge = true
	
	# Start dodge if buffered and possible
	if buffered_dodge and can_dodge and not is_dodging:
		start_dodge()
		buffered_dodge = false
	
	# Update dodge duration and apply dodge friction
	if is_dodging:
		dodge_timer -= delta
		
		# Apply stronger friction during dodge for more control
		if abs(velocity.x) > speed:
			velocity.x = move_toward(velocity.x, sign(velocity.x) * speed, friction * 2.0 * delta)
		
		if dodge_timer <= 0:
			end_dodge()

func start_dodge():
	is_dodging = true
	can_dodge = false
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	
	# Set dodge velocity
	var dodge_direction = get_dodge_direction()
	velocity.x = dodge_direction * dodge_speed
	velocity.y = -200  # sends player up a bit
	
	# Make player invincible during dash
	enable_dash_invincibility()

func get_dodge_direction() -> int:
	var input_direction = Input.get_axis("left", "right")
	
	if input_direction != 0:
		return sign(input_direction)
	else:
		return facing_direction

func end_dodge():
	is_dodging = false
	
	# Restore normal collision
	disable_dash_invincibility()

func enable_dash_invincibility():
	# Store current collision settings
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	
	# Remove from layer 1 (so enemies can't detect player)
	collision_layer = 0
	
	# Keep only floor collision (layer 3) in the mask, remove enemy collision
	collision_mask = 4  # Binary: 100 (only layer 3)
	
	print("Dash invincibility enabled")

func disable_dash_invincibility():
	# Restore original collision settings
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
	
	print("Dash invincibility disabled")

func update_facing_direction():
	var input_direction = Input.get_axis("left", "right")
	if input_direction != 0:
		facing_direction = sign(input_direction)

# Health system methods
func get_health() -> float:
	return health

func get_max_health() -> float:
	return max_health

func take_damage(damage: float):
	if is_invincible():
		print("Player is invincible - damage ignored!")
		return
	
	health -= damage
	health = max(0, health)
	print("Player took ", damage, " damage. Health: ", health, "/", max_health)
	
	if health <= 0:
		die()

func heal(amount: float):
	health += amount
	health = min(max_health, health)
	print("Player healed ", amount, ". Health: ", health, "/", max_health)

func die():
	print("Player died!")
	# Add death logic here - respawn, game over screen, etc.

# Utility functions
func is_jumping() -> bool:
	return velocity.y < 0

func is_falling() -> bool:
	return velocity.y > 0 and not is_on_floor()

func get_speed() -> float:
	return velocity.length()

func get_dodge_cooldown_progress() -> float:
	if dodge_cooldown_timer > 0:
		return dodge_cooldown_timer / dodge_cooldown
	else:
		return 0.0

func is_attacking() -> bool:
	return attack_system.is_attacking if attack_system else false

func can_attack() -> bool:
	return attack_system.is_attack_ready() if attack_system else false

# Check if player is invincible (can be called by enemies or damage systems)
func is_invincible() -> bool:
	return is_dodging

# Debug information
func _on_debug_info():
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
