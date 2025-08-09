extends Node2D

# Spawning parameters
@export var enemy_scene: PackedScene  # Drag enemy scene here in inspector
@export var spawn_interval: float = 3.0
@export var max_enemies: int = 10
@export var spawn_radius: float = 500.0  # Random spawn area around spawn point
@export var spawn_enabled: bool = true

# Node references
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var enemy_container: Node2D = $EnemyContainer
@onready var moon_light: PointLight2D = $PointLight2D
@onready var sprite: Sprite2D = $Sprite2D

# State variables
var current_enemy_count: int = 0

func _ready():
	# Setup spawn timer
	if spawn_timer:
		spawn_timer.wait_time = spawn_interval
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		if spawn_enabled:
			spawn_timer.start()
	
	# Debug info
	print("Moon spawner initialized")
	print("Enemy scene loaded: ", enemy_scene != null)
	print("Spawn interval: ", spawn_interval, " seconds")
	print("Max enemies: ", max_enemies)

func _process(delta):
	# Update enemy count
	update_enemy_count()

func _on_spawn_timer_timeout():
	if spawn_enabled and can_spawn_enemy():
		spawn_enemy()

func can_spawn_enemy() -> bool:
	# Check if we haven't exceeded max enemies
	if current_enemy_count >= max_enemies:
		return false
	
	# Check if enemy scene is loaded
	if not enemy_scene:
		print("Warning: No enemy scene assigned to moon spawner!")
		return false
	
	return true

func spawn_enemy():
	if not enemy_scene or not spawn_point:
		return
	
	# Instantiate enemy
	var enemy = enemy_scene.instantiate()
	if not enemy:
		print("Failed to instantiate enemy!")
		return
	
	# Calculate spawn position with randomness only on Y-axis
	var spawn_position = spawn_point.global_position
	var random_offset = Vector2(
		randf_range(-spawn_radius, spawn_radius),  # No X-axis randomness
		  0# Only Y-axis randomness
	)
	spawn_position += random_offset
	
	# Add enemy to container and set position
	enemy_container.add_child(enemy)
	enemy.global_position = spawn_position
	
	current_enemy_count += 1
	
	print("Spawned enemy at: ", spawn_position)
	print("Current enemy count: ", current_enemy_count)

func update_enemy_count():
	# Count current enemies in container
	var actual_count = 0
	for child in enemy_container.get_children():
		if child.is_queued_for_deletion():
			continue
		actual_count += 1
	
	current_enemy_count = actual_count

func _on_enemy_died():
	# This gets called when an enemy dies (if the signal exists)
	current_enemy_count = max(0, current_enemy_count - 1)
	print("Enemy died. Remaining enemies: ", current_enemy_count)

func _on_enemy_removed():
	# Fallback for when enemies are removed from scene
	current_enemy_count = max(0, current_enemy_count - 1)

# Utility functions for external control
func set_spawn_enabled(enabled: bool):
	spawn_enabled = enabled
	if spawn_timer:
		if enabled:
			spawn_timer.start()
		else:
			spawn_timer.stop()

func set_spawn_interval(interval: float):
	spawn_interval = interval
	if spawn_timer:
		spawn_timer.wait_time = interval

func clear_all_enemies():
	for child in enemy_container.get_children():
		child.queue_free()
	current_enemy_count = 0

func get_enemy_count() -> int:
	return current_enemy_count

# Debug function
func _input(event):
	# Debug: Press 'M' to manually spawn enemy
	if event.is_action_pressed("ui_cancel"):  # ESC key for testing
		if can_spawn_enemy():
			spawn_enemy()
		else:
			print("Cannot spawn enemy - limit reached or no scene assigned")
