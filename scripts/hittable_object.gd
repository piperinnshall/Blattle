extends RigidBody2D

# Knockback parameters
@export var knockback_force: float = 600.0
@export var knockback_upward_bias: float = 0.3  # Adds slight upward force
@export var health: float = 100.0

# References
@onready var hit_area: Area2D = $HitArea

func _ready():
	# Connect the hit area to detect attacks (only area-to-area)
	hit_area.area_entered.connect(_on_hit_area_entered)

func _on_hit_area_entered(area):
	# Only respond to attack areas that are currently monitoring (active)
	if area.monitoring and is_attack_area(area):
		handle_hit(area)

func is_attack_area(area: Area2D) -> bool:
	# Check if this area is one of the player's attack areas
	var parent = area.get_parent()
	return parent != null and parent.name == "AttackSystem"

func handle_hit(attacker):
	# Calculate knockback direction
	var knockback_direction = calculate_knockback_direction(attacker)
	
	# Apply knockback force
	apply_knockback(knockback_direction)
	
	# Handle damage if you want
	take_damage(10.0)  # Or get damage from attacker
	
	print("Object hit! Knockback applied.")

func calculate_knockback_direction(attacker) -> Vector2:
	# Get direction from attacker to this object
	var direction = Vector2.ZERO
	
	# If attacker is an attack area, use its parent (AttackSystem) position
	if attacker.get_parent() and attacker.get_parent().name == "AttackSystem":
		var player = attacker.get_parent().get_parent()  # AttackSystem -> Player
		direction = global_position - player.global_position
	else:
		direction = global_position - attacker.global_position
	
	direction = direction.normalized()
	
	# Add slight upward bias to make it feel more dynamic
	direction.y -= knockback_upward_bias
	direction = direction.normalized()
	
	return direction

func apply_knockback(direction: Vector2):
	# Apply impulse to the rigidbody
	apply_central_impulse(direction * knockback_force)
	
	# Optional: Add some angular impulse for spinning effect
	apply_torque_impulse(randf_range(-200, 200))

# Standard damage function for compatibility with attack system
func take_damage(damage: float):
	health -= damage
	print("Object took ", damage, " damage. Health: ", health)
	
	if health <= 0:
		handle_death()

func handle_death():
	# Handle object destruction
	print("Object destroyed!")
	queue_free()

# Alternative method: If you want to use the attack system's body detection
func on_hit(damage: float):
	# This gets called by the attack system if using body detection
	take_damage(damage)
	
	# For this method, we need to get the player reference differently
	var player = get_tree().get_first_node_in_group("player")  # Add player to "player" group
	if player:
		var direction = calculate_knockback_direction(player)
		apply_knockback(direction)
