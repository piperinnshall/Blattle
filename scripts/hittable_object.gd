extends RigidBody2D

# Knockback parameters
@export var knockback_force: float = 600.0
@export var knockback_upward_bias: float = 0.3  # Adds slight upward force
@export var health: float = 100.0

# Damage parameters
@export var base_damage: float = 1
@export var damage_multiplier: float = 0.05  # Damage per unit of speed
@export var min_damage_speed: float = 100.0  # Minimum speed to deal damage
@export var max_damage: float = 80.0  # Maximum damage cap

# Damage cooldown
@export var damage_cooldown: float = 1.0
var damage_cooldown_timer: float = 0.0
var can_deal_damage: bool = true

# Color settings
@export var safe_color: Color = Color.WHITE
@export var medium_damage_color: Color = Color.YELLOW
@export var high_damage_color: Color = Color.RED

# References
@onready var hit_area: Area2D = $HitArea
@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D  # Assuming you have a Sprite2D node

var contacted_players: Array = []

func _ready():
	# Connect the hit area to detect attacks (only area-to-area)
	hit_area.area_entered.connect(_on_hit_area_entered)
	
	# Enable contact monitoring for RigidBody2D
	contact_monitor = true
	max_contacts_reported = 10
	
	# Connect body detection for player damage
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta):
	update_damage_cooldown(delta)
	update_damage_label()
	update_object_color()
	check_player_contact_damage()
	label.rotation = -rotation

func update_damage_cooldown(delta):
	if damage_cooldown_timer > 0:
		damage_cooldown_timer -= delta
	else:
		can_deal_damage = true

func _on_hit_area_entered(area):
	# Only respond to attack areas that are currently monitoring (active)
	if area.monitoring and is_attack_area(area):
		handle_attack_hit(area)

func is_attack_area(area: Area2D) -> bool:
	# Check if this area is one of the player's attack areas
	var parent = area.get_parent()
	return parent != null and parent.name == "AttackSystem"

func handle_attack_hit(attacker):
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

func _on_body_entered(body):
	if body.is_in_group("Players"):
		contacted_players.append(body)

func _on_body_exited(body):
	if body.is_in_group("Players"):
		contacted_players.erase(body)

func check_player_contact_damage():
	if contacted_players.is_empty() or not can_deal_damage:
		return
	
	var current_speed = linear_velocity.length()
	
	# Only deal damage if moving fast enough
	if current_speed < min_damage_speed:
		return
	
	var damage = calculate_damage_from_speed(current_speed)
	
	# Deal damage to all players in contact
	for player in contacted_players:
		if player.has_method("take_damage"):
			player.take_damage(damage)
	
	# Start damage cooldown after dealing damage
	start_damage_cooldown()

func start_damage_cooldown():
	can_deal_damage = false
	damage_cooldown_timer = damage_cooldown
	print("Damage cooldown started - can't deal damage for ", damage_cooldown, " seconds")

func calculate_damage_from_speed(speed: float) -> float:
	var damage = base_damage + (speed * damage_multiplier)
	return min(damage, max_damage)

func update_damage_label():
	if not label:
		return
	
	var current_speed = linear_velocity.length()
	var potential_damage = 0.0
	
	if current_speed >= min_damage_speed and can_deal_damage:
		potential_damage = calculate_damage_from_speed(current_speed)
	
	# Add cooldown indicator to label
	var label_text = str(int(potential_damage))
	if not can_deal_damage:
		label_text += "..."
	
	label.text = label_text

func update_object_color():
	var current_speed = linear_velocity.length()
	var potential_damage = 0.0
	
	if current_speed >= min_damage_speed and can_deal_damage:
		potential_damage = calculate_damage_from_speed(current_speed)
	
	# Calculate color based on damage potential
	var damage_ratio = potential_damage / max_damage
	var target_color: Color
	
	if potential_damage <= 0:
		target_color = safe_color
	elif damage_ratio <= 0.5:
		# Interpolate between safe and medium danger
		target_color = safe_color.lerp(medium_damage_color, damage_ratio * 2.0)
	else:
		# Interpolate between medium and high danger
		target_color = medium_damage_color.lerp(high_damage_color, (damage_ratio - 0.5) * 2.0)
	
	# If on cooldown, desaturate the color
	if not can_deal_damage:
		target_color = target_color.lerp(Color.GRAY, 0.7)
	
	# Apply color to both sprite and label
	if sprite:
		sprite.modulate = target_color
	
	if label:
		label.modulate = target_color

# Standard damage function for compatibility with attack system
func take_damage(damage: float):
	health -= damage
	print("Object took ", damage, " damage. Health: ", health)
	
	if health <= 0:
		handle_death()

func handle_death():
	# Handle object destruction
	print("Object destroyed!")
	#queue_free()

# Alternative method: If you want to use the attack system's body detection
func on_hit(damage: float):
	# This gets called by the attack system if using body detection
	take_damage(damage)
	
	# For this method, we need to get the player reference differently
	var player = get_tree().get_first_node_in_group("Players")
	if player:
		var direction = calculate_knockback_direction(player)
		apply_knockback(direction)
