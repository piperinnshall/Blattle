extends CharacterBody2D

# Movement constants
const FOLLOW_SPEED: float = 100.0
const FOLLOW_ACCELERATION: float = 100.0
const DECELERATION: float = 80.0

# Rotation constants
const ROTATION_SPEED: float = 5.0
const ANGLE_THRESHOLD: float = 0.01
const RETURN_TO_UPRIGHT_MULTIPLIER: float = 0.5

# Knockback constants
const KNOCKBACK_FORCE: float = 300.0
const KNOCKBACK_DURATION: float = 0.3
const KNOCKBACK_DECAY: float = 8.0

# Health constants
const DEATH_DAMAGE_THRESHOLD: float = 30.0

# Damage constants - fast and responsive
const DAMAGE_PER_SECOND: float = 20.0
const DAMAGE_TICK_INTERVAL: float = 0.1

# Export parameters for designer tweaking
@export var knockback_resistance: float = 1.0
@export var enable_rotation: bool = true

# State variables
var player: CharacterBody2D = null
var is_following: bool = false
var knockback_timer: float = 0.0
var knockback_force_vector: Vector2 = Vector2.ZERO
var total_damage: float = 0.0
var is_damaging_player: bool = false
var damage_tick_timer: float = 0.0

# Node references
@onready var player_detector: Area2D = $PlayerDetector
@onready var hit_area: Area2D = $HitArea
@onready var sprite: Sprite2D = $CollisionShape2D/NpcSprite

func _ready():
	_connect_signals()
	_debug_collision_setup()

func _connect_signals():
	player_detector.body_entered.connect(_on_player_detected)
	player_detector.body_exited.connect(_on_player_lost)
	hit_area.body_entered.connect(_on_hit_by_player)
	
	# Connect damage area signals for dealing damage to player
	var damage_area = get_node_or_null("DamageArea")
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_entered)
		damage_area.body_exited.connect(_on_damage_area_exited)

func _debug_collision_setup():
	print("=== ENEMY COLLISION SETUP ===")
	print("HitArea collision layer: ", hit_area.collision_layer)
	print("HitArea collision mask: ", hit_area.collision_mask)
	print("PlayerDetector collision layer: ", player_detector.collision_layer)
	print("PlayerDetector collision mask: ", player_detector.collision_mask)

func _physics_process(delta):
	if _is_in_knockback():
		_handle_knockback(delta)
	elif is_following and player:
		_follow_player(delta)
	else:
		_decelerate(delta)
	
	# Handle damage over time
	_handle_damage_over_time(delta)
	
	move_and_slide()
	_update_sprite_rotation(delta)

func _is_in_knockback() -> bool:
	return knockback_timer > 0

func _handle_knockback(delta):
	knockback_timer -= delta
	velocity = knockback_force_vector
	knockback_force_vector = knockback_force_vector.move_toward(
		Vector2.ZERO, 
		KNOCKBACK_DECAY * knockback_force_vector.length() * delta
	)

func _follow_player(delta):
	var direction = (player.global_position - global_position).normalized()
	var target_velocity = direction * FOLLOW_SPEED
	velocity = velocity.move_toward(target_velocity, FOLLOW_ACCELERATION * delta)

func _decelerate(delta):
	velocity = velocity.move_toward(Vector2.ZERO, DECELERATION * delta)

func _update_sprite_rotation(delta):
	if not sprite or not enable_rotation:
		return
	
	if is_following and player:
		_rotate_to_face_player(delta)
	else:
		_return_to_upright(delta)

func _rotate_to_face_player(delta):
	var direction = player.global_position - global_position
	var target_angle = direction.angle() - PI/2
	_smooth_rotate_to_angle(target_angle, delta, ROTATION_SPEED)

func _return_to_upright(delta):
	var target_angle = 0.0
	_smooth_rotate_to_angle(target_angle, delta, ROTATION_SPEED * RETURN_TO_UPRIGHT_MULTIPLIER)

func _smooth_rotate_to_angle(target_angle: float, delta: float, speed: float):
	var current_angle = sprite.rotation
	var angle_diff = _normalize_angle_difference(target_angle - current_angle)
	
	if abs(angle_diff) > ANGLE_THRESHOLD:
		sprite.rotation += sign(angle_diff) * min(abs(angle_diff), speed * delta)

func _normalize_angle_difference(angle_diff: float) -> float:
	while angle_diff > PI:
		angle_diff -= 2 * PI
	while angle_diff < -PI:
		angle_diff += 2 * PI
	return angle_diff

func _on_player_detected(body):
	if body.is_in_group("Players"):
		player = body
		is_following = true
		print("Player detected - starting to follow: ", body.name)

func _on_player_lost(body):
	if body == player and body.is_in_group("Players"):
		player = null
		is_following = false
		print("Player lost - stopping follow")

func _on_hit_by_player(body):
	print("=== HIT DETECTED ===")
	print("Hit by body: ", body.name)
	
	var knockback_direction = _calculate_knockback_direction(body)
	if knockback_direction != Vector2.ZERO:
		_apply_knockback(knockback_direction)

func _calculate_knockback_direction(body) -> Vector2:
	if body.is_in_group("Players"):
		return (global_position - body.global_position).normalized()
	elif _is_attack_object(body):
		if player and player.is_in_group("Players"):
			return (global_position - player.global_position).normalized()
		else:
			return (global_position - body.global_position).normalized()
	elif body.has_method("get_owner") and body.get_owner():
		var owner = body.get_owner()
		if owner.is_in_group("Players"):
			return (global_position - owner.global_position).normalized()
	
	return Vector2.ZERO

func _is_attack_object(body) -> bool:
	return body.name.begins_with("RigidBody2D") or body.get_class() == "RigidBody2D"

func _apply_knockback(direction: Vector2):
	knockback_force_vector = direction * KNOCKBACK_FORCE * knockback_resistance
	knockback_timer = KNOCKBACK_DURATION
	print("Knockback applied: ", knockback_force_vector)

func take_damage(damage: float):
	print("Enemy took ", damage, " damage")
	total_damage += damage
	
	if total_damage >= DEATH_DAMAGE_THRESHOLD:
		print("Enemy died from accumulated damage: ", total_damage)
		queue_free()
		return
	
	if player and player.is_in_group("Players"):
		var knockback_direction = (global_position - player.global_position).normalized()
		_apply_knockback(knockback_direction)

func take_damage_with_knockback(damage: float, knockback_direction: Vector2):
	print("Enemy took ", damage, " damage with directional knockback")
	_apply_knockback(knockback_direction)
	take_damage(damage)

func on_hit(damage: float):
	take_damage(damage)

# Fast responsive damage when in damage area
func _handle_damage_over_time(delta):
	if is_damaging_player:
		damage_tick_timer -= delta
		if damage_tick_timer <= 0:
			_deal_damage_to_player()
			damage_tick_timer = DAMAGE_TICK_INTERVAL

func _deal_damage_to_player():
	if player and player.has_method("take_damage"):
		var damage_amount = DAMAGE_PER_SECOND * DAMAGE_TICK_INTERVAL
		player.take_damage(damage_amount)
		print("Enemy dealing ", damage_amount, " damage to player")

func _on_damage_area_entered(body):
	if body.is_in_group("Players"):
		print("Player entered damage area - starting damage over time")
		is_damaging_player = true
		damage_tick_timer = 0.0  # Start dealing damage immediately

func _on_damage_area_exited(body):
	if body.is_in_group("Players"):
		print("Player left damage area - stopping damage over time")
		is_damaging_player = false
		damage_tick_timer = 0.0

# Utility functions
func is_player_detected() -> bool:
	return is_following and player != null and player.is_in_group("Players")

func get_distance_to_player() -> float:
	if player and player.is_in_group("Players"):
		return global_position.distance_to(player.global_position)
	return 0.0

func set_rotation_enabled(enabled: bool):
	enable_rotation = enabled

func get_angle_to_player() -> float:
	if player and player.is_in_group("Players"):
		var direction = player.global_position - global_position
		return direction.angle()
	return 0.0

func has_valid_player_target() -> bool:
	return player != null and is_instance_valid(player) and player.is_in_group("Players")
