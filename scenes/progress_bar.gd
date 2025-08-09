extends ProgressBar

# Reference to the player
@export var player: CharacterBody2D
@export var offset_above_player: Vector2 = Vector2(0, -40)

# Styling
@export var bar_size: Vector2 = Vector2(60, 8)
@export var ready_color: Color = Color.DARK_BLUE
@export var background_color: Color = Color.BLACK

func _ready():
	# Setup bar appearance
	setup_bar_style()
	
	# Initially hidden
	visible = false
	show_percentage = false
	
	# Auto-find player if not assigned
	if not player:
		player = get_parent()
		if not player is CharacterBody2D:
			player = find_player_in_tree()

func _process(_delta):
	if player:
		# Center bar above player
		global_position = player.global_position + offset_above_player - Vector2(bar_size.x / 2, 0)
		
		# Update cooldown display
		update_cooldown_display()

func setup_bar_style():
	# Set size
	size = bar_size
	
	# Create and apply fill style
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = ready_color
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("fill", fill_style)
	
	# Create and apply background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = background_color
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("background", bg_style)

func update_cooldown_display():
	if not player:
		return
		
	# Check if player has dodge cooldown properties
	if not player.has_method("get_dodge_cooldown_progress"):
		return
		
	var cooldown_progress = player.get_dodge_cooldown_progress()
	
	if cooldown_progress <= 0:
		# Cooldown complete, hide bar
		visible = false
	else:
		# Show and update bar (inverted so it fills instead of empties)
		visible = true
		max_value = 1.0
		value = 1.0 - cooldown_progress

func find_player_in_tree() -> CharacterBody2D:
	# Try to find a CharacterBody2D in the scene tree
	var root = get_tree().current_scene
	return find_character_body_recursive(root)

func find_character_body_recursive(node: Node) -> CharacterBody2D:
	if node is CharacterBody2D:
		return node
	
	for child in node.get_children():
		var result = find_character_body_recursive(child)
		if result:
			return result
	
	return null
