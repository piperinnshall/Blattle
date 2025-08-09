extends Label

# Reference to the player
@export var player: CharacterBody2D

# Face offset settings
@export var base_offset: Vector2 = Vector2(-20, -20)  # Base position above player
@export var movement_offset_strength: float = 1.0   # How much the face moves with direction
@export var bounce_amplitude: float = 3.0           # Vertical bounce when moving
@export var bounce_speed: float = 8.0               # Speed of the bounce animation

# Animation settings
@export var transition_speed: float = 13.0          # Speed of position transitions
@export var face_change_duration: float = 0.1       # How long faces stay when changing

# Internal variables
var target_offset: Vector2
var current_bounce_time: float = 0.0
var last_face: String = ""
var face_timer: float = 0.0

# Emoticon faces for different states
var faces = {
	"idle": "O_O",
	"moving": "0_0",
	"jumping": "O-O",
	"falling": ">-<",
	"dashing": ">-<",
	"attacking": "*_*",
	"hurt": "X_X",
	"happy": "^w^"
}

func _ready():
	# If player not assigned, try to find it
	if not player:
		player = get_parent()
	
	# Set initial face
	text = faces["idle"]
	
	# Set label properties for better visibility
	add_theme_font_size_override("font_size", 24)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER 
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER 
	
	# Make sure the label is visible
	z_index = 100

func _process(delta):
	if not player:
		return
	
	update_face_based_on_state()
	update_position(delta)
	handle_face_timer(delta)

func update_face_based_on_state():
	var new_face = get_face_for_current_state()
	
	if new_face != last_face:
		text = new_face
		last_face = new_face
		face_timer = face_change_duration

func get_face_for_current_state() -> String:
	# Check states in priority order
	
	# Invincibility/hurt state
	if player.is_invincible():
		return faces["dashing"]
	
	# Attacking state
	if player.is_attacking():
		return faces["attacking"]
	
	# Jumping/falling states
	if player.is_jumping():
		return faces["jumping"]
	elif player.is_falling():
		return faces["falling"]
	
	# Movement states
	elif abs(player.velocity.x) > 50:  # Moving threshold
		return faces["moving"]
	
	# Default idle state
	return faces["idle"]

func update_position(delta):
	if not player:
		return
	
	# Calculate target offset based on movement direction
	var movement_direction = sign(player.velocity.x)
	var horizontal_offset = movement_direction * movement_offset_strength
	
	# Add bounce effect when moving
	var bounce_offset = 0.0
	if abs(player.velocity.x) > 10:  # Only bounce when actually moving
		current_bounce_time += delta * bounce_speed
		bounce_offset = sin(current_bounce_time) * bounce_amplitude
	else:
		current_bounce_time = 0.0
	
	# Set target offset
	target_offset = base_offset + Vector2(horizontal_offset, bounce_offset)
	
	# Smooth transition to target position
	var current_offset = position - player.position
	var new_offset = current_offset.lerp(target_offset, transition_speed * delta)
	
	# Update position
	position = player.position + new_offset

func handle_face_timer(delta):
	if face_timer > 0:
		face_timer -= delta

# Public methods to change face manually if needed
func set_face(face_key: String):
	if face_key in faces:
		text = faces[face_key]
		last_face = faces[face_key]
		face_timer = face_change_duration

func set_custom_face(face_text: String):
	text = face_text
	last_face = face_text
	face_timer = face_change_duration

# Add more emoticons
func add_face(key: String, face_text: String):
	faces[key] = face_text

# Utility function to make face flash temporarily
func flash_face(face_key: String, duration: float = 0.3):
	var original_face = text
	set_face(face_key)
	
	# Create a timer to revert back
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_flash_timeout.bind(original_face, timer))
	timer.start()

func _on_flash_timeout(original_face: String, timer: Timer):
	text = original_face
	timer.queue_free()
