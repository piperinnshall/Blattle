extends Node2D

# Attack parameters
@export var attack_damage: float = 10.0
@export var attack_duration: float = 0.2
@export var attack_cooldown: float = 0.5
@export var knockback_force: float = 400.0
@export var knockback_override_strength: float = 0.8

# Knockback constants
const KNOCKBACK_IMPULSE_MULTIPLIER: float = 0.3

# Attack directions enum
enum AttackDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

# Attack state
var is_attacking: bool = false
var can_attack: bool = true
var current_attack_direction: AttackDirection
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0

# Attack area references
@onready var up_attack: Area2D = $UpAttack
@onready var down_attack: Area2D = $DownAttack
@onready var left_attack: Area2D = $LeftAttack
@onready var right_attack: Area2D = $RightAttack

# Attack sprite references
@onready var up_sprite: AnimatedSprite2D = $UpAttack/AttackSprite
@onready var down_sprite: AnimatedSprite2D = $DownAttack/AttackSprite
@onready var left_sprite: AnimatedSprite2D = $LeftAttack/AttackSprite
@onready var right_sprite: AnimatedSprite2D = $RightAttack/AttackSprite

# Audio references
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

# Player reference
var player: CharacterBody2D

func _ready():
	# Get player reference
	player = get_parent()
	
	# Initialize attack systems
	setup_attack_areas()
	setup_attack_sprites()
	connect_signals()

func connect_signals():
	# Connect hit detection signals
	up_attack.body_entered.connect(_on_attack_hit)
	down_attack.body_entered.connect(_on_attack_hit)
	left_attack.body_entered.connect(_on_attack_hit)
	right_attack.body_entered.connect(_on_attack_hit)
	
	# Connect animation finished signals
	up_sprite.animation_finished.connect(_on_attack_animation_finished)
	down_sprite.animation_finished.connect(_on_attack_animation_finished)
	left_sprite.animation_finished.connect(_on_attack_animation_finished)
	right_sprite.animation_finished.connect(_on_attack_animation_finished)

func setup_attack_areas():
	# Disable all attack area monitoring initially
	up_attack.monitoring = false
	down_attack.monitoring = false
	left_attack.monitoring = false
	right_attack.monitoring = false

func setup_attack_sprites():
	# Hide all attack sprites initially
	up_sprite.visible = false
	down_sprite.visible = false
	left_sprite.visible = false
	right_sprite.visible = false

func _process(delta):
	# Update timers
	handle_attack_timers(delta)
	
	# Check for attack input
	if Input.is_action_just_pressed("attack") and can_attack:
		start_attack()

func handle_attack_timers(delta):
	# Update cooldown timer
	if cooldown_timer > 0:
		cooldown_timer -= delta
	else:
		can_attack = true
	
	# Update attack duration timer
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			end_attack()

func start_attack():
	# Set attack state
	is_attacking = true
	can_attack = false
	attack_timer = attack_duration
	cooldown_timer = attack_cooldown
	
	# Determine and execute attack direction
	current_attack_direction = get_attack_direction()
	activate_attack_area(current_attack_direction)
	play_attack_animation(current_attack_direction)
	
	print("Attacking ", AttackDirection.keys()[current_attack_direction])

func get_attack_direction() -> AttackDirection:
	# Check directional input (Hollow Knight style)
	if Input.is_action_pressed("jump"):
		return AttackDirection.UP
	elif Input.is_action_pressed("down"):
		return AttackDirection.DOWN
	elif Input.is_action_pressed("left"):
		return AttackDirection.LEFT
	elif Input.is_action_pressed("right"):
		return AttackDirection.RIGHT
	else:
		# No directional input - use facing direction
		if player.facing_direction > 0:
			return AttackDirection.RIGHT
		else:
			return AttackDirection.LEFT

func activate_attack_area(direction: AttackDirection):
	# Deactivate all areas first
	deactivate_all_attack_areas()
	
	# Activate the appropriate attack area
	match direction:
		AttackDirection.UP:
			up_attack.monitoring = true
		AttackDirection.DOWN:
			down_attack.monitoring = true
		AttackDirection.LEFT:
			left_attack.monitoring = true
		AttackDirection.RIGHT:
			right_attack.monitoring = true

func play_attack_animation(direction: AttackDirection):
	# Hide all sprites first
	hide_all_attack_sprites()
	
	# Show and play appropriate animation
	match direction:
		AttackDirection.UP:
			up_sprite.visible = true
			up_sprite.play("up_attack")
		AttackDirection.DOWN:
			down_sprite.visible = true
			down_sprite.play("down_attack")
		AttackDirection.LEFT:
			left_sprite.visible = true
			left_sprite.play("left_attack")
		AttackDirection.RIGHT:
			right_sprite.visible = true
			right_sprite.play("right_attack")

func deactivate_all_attack_areas():
	# Turn off all attack area monitoring
	up_attack.monitoring = false
	down_attack.monitoring = false
	left_attack.monitoring = false
	right_attack.monitoring = false

func hide_all_attack_sprites():
	# Hide all attack visual effects
	up_sprite.visible = false
	down_sprite.visible = false
	left_sprite.visible = false
	right_sprite.visible = false

func end_attack():
	# Clear attack state
	is_attacking = false
	deactivate_all_attack_areas()
	hide_all_attack_sprites()

func _on_attack_animation_finished():
	# End attack when animation completes
	if is_attacking:
		end_attack()

func _on_attack_hit(body):
	# Only process hits during active attacks
	if not is_attacking:
		return
	
	# Play hit sound effect
	if hit_sound:
		hit_sound.play()
	
	# Apply damage to hit targets
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
	elif body.has_method("on_hit"):
		body.on_hit(attack_damage)
	
	# Apply knockback to player (pogo effect)
	apply_player_knockback(body)
	
	print("Hit: ", body.name)

func apply_player_knockback(hit_body):
	# Calculate knockback direction based on attack direction
	var knockback_direction = get_knockback_direction()
	var knockback_velocity = knockback_direction * knockback_force
	
	# Apply velocity override for responsive knockback
	if current_attack_direction == AttackDirection.UP or current_attack_direction == AttackDirection.DOWN:
		# Override Y velocity for vertical attacks
		player.velocity.y = lerp(player.velocity.y, knockback_velocity.y, knockback_override_strength)
	else:
		# Override X velocity for horizontal attacks
		player.velocity.x = lerp(player.velocity.x, knockback_velocity.x, knockback_override_strength)
	
	# Add impulse for extra bounce effect
	player.velocity += knockback_velocity * KNOCKBACK_IMPULSE_MULTIPLIER

func get_knockback_direction() -> Vector2:
	# Return knockback direction based on attack direction
	match current_attack_direction:
		AttackDirection.UP:
			return Vector2(0, 1)    # Push player down
		AttackDirection.DOWN:
			return Vector2(0, -1)   # Push player up
		AttackDirection.LEFT:
			return Vector2(1, 0)    # Push player right
		AttackDirection.RIGHT:
			return Vector2(-1, 0)   # Push player left
		_:
			return Vector2.ZERO

# Public interface
func is_attack_ready() -> bool:
	return can_attack

func get_attack_cooldown_progress() -> float:
	# Return cooldown progress (1.0 = full cooldown, 0.0 = ready)
	if cooldown_timer > 0:
		return cooldown_timer / attack_cooldown
	else:
		return 0.0

func get_current_attack_direction() -> AttackDirection:
	return current_attack_direction
