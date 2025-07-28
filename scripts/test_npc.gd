extends CharacterBody2D

# Movement parameters
@export var follow_speed: float = 100.0
@export var follow_acceleration: float = 100.0
@export var deceleration: float = 80.0  # How fast enemy slows down when stopping

# Knockback parameters
@export var knockback_resistance: float = 1.0
@export var knockback_decay: float = 8.0  # Higher = faster decay

# State variables
var player: CharacterBody2D = null
var is_following: bool = false
var knockback_timer: float = 0.0
var knockback_force: Vector2 = Vector2.ZERO

# Node references
@onready var player_detector: Area2D = $PlayerDetector
@onready var hit_area: Area2D = $HitArea
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	# Connect detector signals
	player_detector.body_entered.connect(_on_player_detected)
	player_detector.body_exited.connect(_on_player_lost)
	
	# Connect hit area signal with debug info
	hit_area.body_entered.connect(_on_hit_by_player)
	
	# Debug: Print collision setup
	print("=== ENEMY COLLISION SETUP ===")
	print("HitArea collision layer: ", hit_area.collision_layer)
	print("HitArea collision mask: ", hit_area.collision_mask)
	print("PlayerDetector collision layer: ", player_detector.collision_layer)
	print("PlayerDetector collision mask: ", player_detector.collision_mask)

func _physics_process(delta):
	# Handle knockback first - this takes priority over everything
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_force
		knockback_force = knockback_force.move_toward(Vector2.ZERO, knockback_decay * knockback_force.length() * delta)
		print("KNOCKBACK ACTIVE: ", knockback_force, " Timer: ", knockback_timer)
	else:
		# Normal movement logic only when not in knockback
		if is_following and player:
			follow_player(delta)
		else:
			# Smooth deceleration when not following
			velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
	# Apply physics
	move_and_slide()
	
	# Update facing direction
	update_facing_direction()

func follow_player(delta):
	if not player:
		return
	
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	
	# Move towards player
	var target_velocity = direction * follow_speed
	velocity = velocity.move_toward(target_velocity, follow_acceleration * delta)

func update_facing_direction():
	if not sprite:
		return
		
	if is_following and player:
		var direction = player.global_position.x - global_position.x
		if abs(direction) > 10:
			sprite.scale.x = 1 if direction > 0 else -1
	elif velocity.x != 0:
		sprite.scale.x = 1 if velocity.x > 0 else -1

func _on_player_detected(body):
	print("Body detected: ", body.name)
	if body.name == "Player" or body.has_method("is_player") or body is CharacterBody2D:
		player = body
		is_following = true
		print("Player detected - starting to follow")

func _on_player_lost(body):
	print("Body lost: ", body.name)
	if body == player:
		player = null
		is_following = false
		print("Player lost - stopping follow")

func _on_hit_by_player(body):
	print("=== HIT DETECTED ===")
	print("Hit by body: ", body.name, " | Body type: ", body.get_class())
	
	# Check for different types of attack objects
	if body.name == "Player" or body.name == "Node2D" or body.has_method("is_player"):
		# Direct player hit
		var knockback_direction = (global_position - body.global_position).normalized()
		apply_knockback(knockback_direction, 300.0)
	elif body.name.begins_with("RigidBody2D") or body.get_class() == "RigidBody2D":
		# Attack object hit - find the player to calculate knockback direction
		if player:
			var knockback_direction = (global_position - player.global_position).normalized()
			apply_knockback(knockback_direction, 300.0)
		else:
			# Fallback: knockback away from the attack object
			var knockback_direction = (global_position - body.global_position).normalized()
			apply_knockback(knockback_direction, 300.0)
	elif body.has_method("get_owner") and body.get_owner():
		# Check if the attack object has an owner (likely the player)
		var owner = body.get_owner()
		if owner.name == "Player" or owner.has_method("is_player"):
			var knockback_direction = (global_position - owner.global_position).normalized()
			apply_knockback(knockback_direction, 300.0)

func apply_knockback(direction: Vector2, force: float):
	print("APPLYING KNOCKBACK: Direction=", direction, " Force=", force)
	
	# Set knockback force and timer
	knockback_force = direction * force * knockback_resistance
	knockback_timer = 0.3  # 0.3 seconds of knockback
	
	print("Knockback force set to: ", knockback_force)
	print("Knockback timer set to: ", knockback_timer)

# Alternative method that can be called from attack system with direction
func take_damage_with_knockback(damage: float, knockback_direction: Vector2):
	print("Enemy took ", damage, " damage with directional knockback")
	apply_knockback(knockback_direction, 300.0)
	take_damage(damage)

# Method for taking damage
func take_damage(damage: float):
	print("Enemy took ", damage, " damage")
	
	# Apply knockback when taking damage
	if player:
		var knockback_direction = (global_position - player.global_position).normalized()
		apply_knockback(knockback_direction, 300.0)
	else:
		print("No player reference for knockback!")

# Method for generic hit detection
func on_hit(damage: float):
	take_damage(damage)

# Utility functions
func is_player_detected() -> bool:
	return is_following and player != null

func get_distance_to_player() -> float:
	if player:
		return global_position.distance_to(player.global_position)
	return 0.0
