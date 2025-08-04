extends Node2D

# Attack parameters
@export var attack_damage: float = 10.0
@export var attack_duration: float = 0.2
@export var attack_cooldown: float = 0.5
@export var knockback_force: float = 400.0
@export var knockback_override_strength: float = 0.8

# Attack directions
enum AttackDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

# State variables
var is_attacking: bool = false
var can_attack: bool = true
var current_attack_direction: AttackDirection
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0

# References to attack areas
@onready var up_attack: Area2D = $UpAttack
@onready var down_attack: Area2D = $DownAttack
@onready var left_attack: Area2D = $LeftAttack
@onready var right_attack: Area2D = $RightAttack

# References to attack sprites
@onready var up_sprite: AnimatedSprite2D = $UpAttack/AttackSprite
@onready var down_sprite: AnimatedSprite2D = $DownAttack/AttackSprite
@onready var left_sprite: AnimatedSprite2D = $LeftAttack/AttackSprite
@onready var right_sprite: AnimatedSprite2D = $RightAttack/AttackSprite

# Reference to player
var player: CharacterBody2D

func _ready():
	player = get_parent()
	setup_attack_areas()
	setup_attack_sprites()
	
	# Connect area signals
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
	# Disable monitoring for all attack areas
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
	is_attacking = true
	can_attack = false
	attack_timer = attack_duration
	cooldown_timer = attack_cooldown
	
	# Determine attack direction
	current_attack_direction = get_attack_direction()
	
	# Activate appropriate attack area and play animation
	activate_attack_area(current_attack_direction)
	play_attack_animation(current_attack_direction)
	
	print("Attacking ", AttackDirection.keys()[current_attack_direction])

func get_attack_direction() -> AttackDirection:
	# Check for directional input first (Hollow Knight style)
	if Input.is_action_pressed("jump"):
		return AttackDirection.UP
	elif Input.is_action_pressed("down"):
		return AttackDirection.DOWN
	elif Input.is_action_pressed("left"):
		return AttackDirection.LEFT
	elif Input.is_action_pressed("right"):
		return AttackDirection.RIGHT
	else:
		# No directional input, use facing direction
		if player.facing_direction > 0:
			return AttackDirection.RIGHT
		else:
			return AttackDirection.LEFT

func activate_attack_area(direction: AttackDirection):
	# Deactivate all attack areas first
	deactivate_all_attack_areas()
	
	# Activate the appropriate area
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
	
	# Show and play the appropriate animation
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
	up_attack.monitoring = false
	down_attack.monitoring = false
	left_attack.monitoring = false
	right_attack.monitoring = false

func hide_all_attack_sprites():
	up_sprite.visible = false
	down_sprite.visible = false
	left_sprite.visible = false
	right_sprite.visible = false

func end_attack():
	is_attacking = false
	deactivate_all_attack_areas()
	hide_all_attack_sprites()

func _on_attack_animation_finished():
	# Optional: End attack when animation finishes instead of using timer
	# This ensures the visual effect matches the actual attack duration
	if is_attacking:
		end_attack()

func _on_attack_hit(body):
	# Only process hits during active attacks
	if not is_attacking:
		return
	
	# Handle hitting enemies or destructible objects
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
	elif body.has_method("on_hit"):
		body.on_hit(attack_damage)
	
	# Apply knockback to player in opposite direction
	apply_player_knockback(body)
	
	print("Hit: ", body.name)

func apply_player_knockback(hit_body):
	# Calculate direction from hit object to player
	var knockback_direction = Vector2.ZERO
	
	# Get direction based on which attack area was used
	match current_attack_direction:
		AttackDirection.UP:
			knockback_direction = Vector2(0, 1)  # Push player down
		AttackDirection.DOWN:
			knockback_direction = Vector2(0, -1)  # Push player up
		AttackDirection.LEFT:
			knockback_direction = Vector2(1, 0)  # Push player right
		AttackDirection.RIGHT:
			knockback_direction = Vector2(-1, 0)  # Push player left
	
	# Apply impulse-style knockback with velocity override
	var knockback_velocity = knockback_direction * knockback_force
	
	# Override existing velocity partially for more responsive knockback
	if current_attack_direction == AttackDirection.UP or current_attack_direction == AttackDirection.DOWN:
		# For vertical attacks, override Y velocity more strongly
		player.velocity.y = lerp(player.velocity.y, knockback_velocity.y, knockback_override_strength)
	else:
		# For horizontal attacks, override X velocity more strongly
		player.velocity.x = lerp(player.velocity.x, knockback_velocity.x, knockback_override_strength)
	
	# Always add some impulse on top for extra "spring"
	player.velocity += knockback_velocity * 0.3

# Utility functions
func is_attack_ready() -> bool:
	return can_attack

func get_attack_cooldown_progress() -> float:
	if cooldown_timer > 0:
		return cooldown_timer / attack_cooldown
	else:
		return 0.0

func get_current_attack_direction() -> AttackDirection:
	return current_attack_direction
