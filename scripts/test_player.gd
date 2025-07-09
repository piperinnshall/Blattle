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
@export var dodge_speed: float = 500.0
@export var dodge_duration: float = 0.3
@export var dodge_cooldown: float = 1.0

# Input buffering
@export var input_buffer_time: float = 0.1

# State variables
var jumps_remaining: int = 0
var is_dodging: bool = false
var can_dodge: bool = true
var facing_direction: int = 1

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

func _physics_process(delta):
	handle_gravity(delta)
	handle_input_buffering(delta)
	handle_coyote_time(delta)
	handle_dodge(delta)
	
	if not is_dodging:
		handle_movement(delta)
		handle_jump()
	
	move_and_slide()
	update_facing_direction()

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
	var direction =  Input.get_axis("left","right")
	
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
	
	# Optional: Add jump sound or effect here
	# AudioManager.play_sound("jump")

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
	
	# Optional: Add dodge sound or effect here
	# AudioManager.play_sound("dodge")

func get_dodge_direction() -> int:
	var input_direction = Input.get_axis("left", "right")
	
	if input_direction != 0:
		return sign(input_direction)
	else:
		return facing_direction

func end_dodge():
	is_dodging = false
	# Optional: Add any end dodge effects here

func update_facing_direction():
	var input_direction = Input.get_axis("left", "right")
	if input_direction != 0:
		facing_direction = sign(input_direction)

# Utility functions
func is_jumping() -> bool:
	return velocity.y < 0

func is_falling() -> bool:
	return velocity.y > 0 and not is_on_floor()

func get_speed() -> float:
	return velocity.length()

# Debug information (optional)
func _on_debug_info():
	print("Jumps remaining: ", jumps_remaining)
	print("Coyote time: ", coyote_timer)
	print("Is dodging: ", is_dodging)
	print("Can dodge: ", can_dodge)
	print("Buffered jump: ", buffered_jump)
	print("Buffered dodge: ", buffered_dodge)
